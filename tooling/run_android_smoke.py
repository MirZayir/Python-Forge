"""Run a non-destructive Android launch smoke test and capture evidence.

The harness installs over the existing package with ``adb install -r``. It
never clears app data, uninstalls the app, or changes mission progress.
"""

from __future__ import annotations

import argparse
import json
import re
import subprocess
import sys
import time
from datetime import datetime, timezone
from pathlib import Path
from typing import Any


ROOT = Path(__file__).resolve().parents[1]
DEFAULT_APK = "build/app/outputs/flutter-apk/app-debug.apk"
DEFAULT_OUTPUT_DIR = "build/android-smoke"
FATAL_LOG_PATTERN = re.compile(r"(?:FATAL EXCEPTION|AndroidRuntime):", re.IGNORECASE)


def _resolve_from_root(value: str) -> Path:
    path = Path(value)
    return path if path.is_absolute() else ROOT / path


def _run_adb(
    serial: str,
    arguments: list[str],
    *,
    timeout: float = 30,
    text: bool = True,
) -> subprocess.CompletedProcess[str] | subprocess.CompletedProcess[bytes] | None:
    try:
        return subprocess.run(
            ["adb", "-s", serial, *arguments],
            cwd=ROOT,
            capture_output=True,
            check=False,
            text=text,
            timeout=timeout,
        )
    except (FileNotFoundError, OSError, subprocess.TimeoutExpired):
        return None


def _text_output(result: subprocess.CompletedProcess[Any] | None) -> str:
    if result is None:
        return ""
    value = result.stdout
    if isinstance(value, bytes):
        return value.decode("utf-8", errors="replace")
    return value or ""


def _stderr_output(result: subprocess.CompletedProcess[Any] | None) -> str:
    if result is None:
        return ""
    value = result.stderr
    if isinstance(value, bytes):
        return value.decode("utf-8", errors="replace")
    return value or ""


def _record_failure(
    errors: list[str],
    label: str,
    result: subprocess.CompletedProcess[Any] | None,
) -> None:
    if result is None:
        errors.append(f"{label} could not be executed; verify adb and the device.")
    elif result.returncode != 0:
        detail = _text_output(result).strip() or _stderr_output(result).strip()
        errors.append(
            f"{label} failed with exit code {result.returncode}"
            + (f": {detail[:400]}" if detail else ".")
        )


def _write_text(path: Path, content: str) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(content, encoding="utf-8")


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--serial", required=True, help="ADB device serial")
    parser.add_argument(
        "--apk",
        default=DEFAULT_APK,
        help=f"APK path relative to the repository (default: {DEFAULT_APK})",
    )
    parser.add_argument(
        "--package",
        default="com.example.python_forge",
        help="Android application package",
    )
    parser.add_argument(
        "--activity",
        default=".MainActivity",
        help="Launch activity name",
    )
    parser.add_argument(
        "--output-dir",
        default=DEFAULT_OUTPUT_DIR,
        help=f"Evidence output directory (default: {DEFAULT_OUTPUT_DIR})",
    )
    parser.add_argument(
        "--wait-seconds",
        type=float,
        default=3.0,
        help="Seconds to wait after launch before capture",
    )
    args = parser.parse_args()

    apk = _resolve_from_root(args.apk)
    output_dir = _resolve_from_root(args.output_dir)
    output_dir.mkdir(parents=True, exist_ok=True)
    errors: list[str] = []
    warnings: list[str] = []

    state = _run_adb(args.serial, ["get-state"])
    if state is None or state.returncode != 0 or _text_output(state).strip() != "device":
        _record_failure(errors, "ADB device state check", state)
        if state is not None and _text_output(state).strip() not in ("", "device"):
            errors.append(
                f"ADB device is not ready: {_text_output(state).strip()[:200]}"
            )
    elif not apk.is_file():
        errors.append(f"APK does not exist: {args.apk}")
    else:
        install = _run_adb(
            args.serial,
            ["install", "-r", str(apk)],
            timeout=180,
        )
        if install is None or install.returncode != 0:
            _record_failure(errors, "APK install with data preservation", install)

        clear_log = _run_adb(args.serial, ["shell", "logcat", "-c"])
        if clear_log is None or clear_log.returncode != 0:
            warnings.append("Could not clear logcat before the smoke run.")

        stop = _run_adb(
            args.serial,
            ["shell", "am", "force-stop", args.package],
        )
        if stop is None or stop.returncode != 0:
            _record_failure(errors, "Application force-stop", stop)

        start = _run_adb(
            args.serial,
            ["shell", "am", "start", "-n", f"{args.package}/{args.activity}"],
        )
        if start is None or start.returncode != 0:
            _record_failure(errors, "Application launch", start)

        time.sleep(max(args.wait_seconds, 0))

        pid_result = _run_adb(args.serial, ["shell", "pidof", args.package])
        pid = _text_output(pid_result).strip()
        if pid_result is None or pid_result.returncode != 0 or not pid:
            _record_failure(errors, "Application process check", pid_result)
            if not pid:
                errors.append(f"No running PID found for {args.package}.")

        activity_result = _run_adb(
            args.serial,
            ["shell", "dumpsys", "activity", "activities"],
        )
        activity_text = _text_output(activity_result)
        if activity_result is None or activity_result.returncode != 0:
            _record_failure(errors, "Activity state capture", activity_result)
        elif args.package not in activity_text:
            errors.append(f"Activity dump does not contain {args.package}.")

        remote_ui_path = "/sdcard/python_forge_smoke.xml"
        ui_dump = _run_adb(
            args.serial,
            ["shell", "uiautomator", "dump", remote_ui_path],
        )
        ui_content = _run_adb(
            args.serial,
            ["shell", "cat", remote_ui_path],
        )
        if (
            ui_dump is None
            or ui_dump.returncode != 0
            or ui_content is None
            or ui_content.returncode != 0
        ):
            _record_failure(errors, "UI hierarchy capture", ui_dump or ui_content)
        else:
            _write_text(output_dir / "ui-hierarchy.xml", _text_output(ui_content))

        screenshot = _run_adb(
            args.serial,
            ["exec-out", "screencap", "-p"],
            timeout=30,
            text=False,
        )
        screenshot_path = output_dir / "screenshot.png"
        if screenshot is None or screenshot.returncode != 0 or not screenshot.stdout:
            _record_failure(errors, "Screenshot capture", screenshot)
        else:
            screenshot_path.write_bytes(screenshot.stdout)

        logcat = _run_adb(
            args.serial,
            ["shell", "logcat", "-d", "-t", "300"],
        )
        logcat_text = _text_output(logcat)
        if logcat is None or logcat.returncode != 0:
            _record_failure(errors, "Logcat capture", logcat)
        _write_text(output_dir / "logcat.txt", logcat_text)
        if FATAL_LOG_PATTERN.search(logcat_text):
            errors.append("Captured logcat contains a fatal Android exception.")

    result = {
        "schema_version": 1,
        "status": "pass" if not errors else "fail",
        "captured_at": datetime.now(timezone.utc).isoformat(),
        "serial": args.serial,
        "package": args.package,
        "activity": args.activity,
        "apk": args.apk,
        "install_mode": "adb install -r (application data preserved)",
        "pid": pid if "pid" in locals() else "",
        "artifacts": {
            "ui_hierarchy": "ui-hierarchy.xml",
            "screenshot": "screenshot.png",
            "logcat": "logcat.txt",
        },
        "warnings": warnings,
        "errors": errors,
    }
    result_path = output_dir / "smoke-result.json"
    result_path.write_text(json.dumps(result, indent=2) + "\n", encoding="utf-8")

    if errors:
        print(f"Android smoke test: FAIL ({result_path})")
        for error in errors:
            print(f"- {error}")
        return 1

    print(f"Android smoke test: PASS ({result_path})")
    for warning in warnings:
        print(f"Warning: {warning}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
