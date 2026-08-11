"""Verify the repository-owned roadmap evidence index.

The verifier intentionally uses only the Python standard library so it can run
in local development and in CI before the rest of the quality gates.
"""

from __future__ import annotations

import argparse
import hashlib
import json
import subprocess
import sys
from pathlib import Path
from typing import Any


ROOT = Path(__file__).resolve().parents[1]
SHA256_LENGTH = 64
VALID_STATUSES = {"implemented", "partial", "planned", "blocked", "evidence_gap"}
EXPECTED_PHASE_IDS = {f"phase-{number}" for number in range(7)}


def _repo_path(value: Any, errors: list[str], label: str) -> Path | None:
    if not isinstance(value, str) or not value.strip():
        errors.append(f"{label} must be a non-empty repository-relative path")
        return None

    candidate = (ROOT / value).resolve()
    try:
        candidate.relative_to(ROOT)
    except ValueError:
        errors.append(f"{label} escapes the repository: {value}")
        return None
    return candidate


def _sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as source:
        for chunk in iter(lambda: source.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def _canonical_json(value: Any) -> str:
    return json.dumps(
        value,
        ensure_ascii=False,
        sort_keys=True,
        separators=(",", ":"),
        allow_nan=False,
    )


def _verify_curriculum_manifest(
    index: dict[str, Any],
    errors: list[str],
    verified: list[str],
) -> None:
    config = index.get("curriculum_manifest")
    if not isinstance(config, dict):
        errors.append("curriculum_manifest must be an object")
        return

    manifest_path = _repo_path(
        config.get("manifest_path"),
        errors,
        "curriculum_manifest.manifest_path",
    )
    content_path = _repo_path(
        config.get("content_path"),
        errors,
        "curriculum_manifest.content_path",
    )
    if manifest_path is None or content_path is None:
        return
    if not manifest_path.is_file():
        errors.append(
            "curriculum_manifest references a missing manifest: "
            f"{config.get('manifest_path')}"
        )
        return
    if not content_path.is_file():
        errors.append(
            "curriculum_manifest references missing content: "
            f"{config.get('content_path')}"
        )
        return

    try:
        manifest = json.loads(manifest_path.read_text(encoding="utf-8"))
        content = json.loads(content_path.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as error:
        errors.append(f"Unable to read curriculum manifest/content: {error}")
        return
    if not isinstance(manifest, dict):
        errors.append("curriculum manifest must be a JSON object")
        return

    for field in (
        "manifest_version",
        "curriculum_id",
        "curriculum_version",
        "content_path",
        "content_sha256",
        "canonicalization",
        "migration_policy",
    ):
        if manifest.get(field) != config.get(field):
            errors.append(
                "curriculum manifest field mismatch for "
                f"{field}: index={config.get(field)!r}, "
                f"manifest={manifest.get(field)!r}"
            )

    expected_hash = config.get("content_sha256")
    if not isinstance(expected_hash, str) or len(expected_hash) != SHA256_LENGTH:
        errors.append("curriculum_manifest.content_sha256 must be a SHA-256 digest")
        return
    try:
        int(expected_hash, 16)
    except ValueError:
        errors.append("curriculum_manifest.content_sha256 must be a SHA-256 digest")
        return

    actual_hash = hashlib.sha256(
        _canonical_json(content).encode("utf-8")
    ).hexdigest()
    if actual_hash != expected_hash.lower():
        errors.append(
            "curriculum content hash mismatch: "
            f"expected {expected_hash.lower()}, got {actual_hash}"
        )
        return

    verified.append(config["manifest_path"])
    verified.append(config["content_path"])


def _verify_hashed_files(
    index: dict[str, Any],
    key: str,
    errors: list[str],
    verified: list[dict[str, str]],
) -> None:
    entries = index.get(key)
    if not isinstance(entries, list) or not entries:
        errors.append(f"{key} must be a non-empty list")
        return

    for position, entry in enumerate(entries):
        label = f"{key}[{position}]"
        if not isinstance(entry, dict):
            errors.append(f"{label} must be an object")
            continue

        path = _repo_path(entry.get("path"), errors, f"{label}.path")
        expected = entry.get("sha256")
        if not isinstance(expected, str) or len(expected) != SHA256_LENGTH:
            errors.append(f"{label}.sha256 must be a 64-character hex digest")
            continue
        try:
            int(expected, 16)
        except ValueError:
            errors.append(f"{label}.sha256 must be a 64-character hex digest")
            continue
        if path is None:
            continue
        if not path.is_file():
            errors.append(f"{label} references a missing file: {entry['path']}")
            continue

        actual = _sha256(path)
        if actual != expected.lower():
            errors.append(
                f"{label} hash mismatch for {entry['path']}: "
                f"expected {expected.lower()}, got {actual}"
            )
            continue
        verified.append({"path": entry["path"], "sha256": actual})


def _verify_phases(
    index: dict[str, Any],
    errors: list[str],
    verified: list[str],
) -> None:
    phases = index.get("phases")
    if not isinstance(phases, list):
        errors.append("phases must be a list")
        return

    seen: set[str] = set()
    for position, phase in enumerate(phases):
        label = f"phases[{position}]"
        if not isinstance(phase, dict):
            errors.append(f"{label} must be an object")
            continue

        phase_id = phase.get("id")
        if not isinstance(phase_id, str) or not phase_id:
            errors.append(f"{label}.id must be a non-empty string")
        elif phase_id in seen:
            errors.append(f"Duplicate phase ID: {phase_id}")
        else:
            seen.add(phase_id)

        status = phase.get("status")
        if status not in VALID_STATUSES:
            errors.append(
                f"{label}.status must be one of {sorted(VALID_STATUSES)}"
            )

        evidence = phase.get("evidence")
        if not isinstance(evidence, list) or not evidence:
            errors.append(f"{label}.evidence must contain at least one reference")
            continue

        for evidence_position, reference in enumerate(evidence):
            reference_label = f"{label}.evidence[{evidence_position}]"
            if not isinstance(reference, dict):
                errors.append(f"{reference_label} must be an object")
                continue
            path = _repo_path(
                reference.get("path"),
                errors,
                f"{reference_label}.path",
            )
            claim = reference.get("claim")
            if not isinstance(claim, str) or not claim.strip():
                errors.append(f"{reference_label}.claim must be non-empty")
            if path is not None and not path.is_file():
                errors.append(
                    f"{reference_label} references a missing file: "
                    f"{reference.get('path')}"
                )
            elif path is not None:
                verified.append(reference["path"])

    missing = EXPECTED_PHASE_IDS - seen
    unexpected = seen - EXPECTED_PHASE_IDS
    if missing:
        errors.append(f"Missing phase IDs: {sorted(missing)}")
    if unexpected:
        errors.append(f"Unexpected phase IDs: {sorted(unexpected)}")


def _git_head() -> str | None:
    try:
        result = subprocess.run(
            ["git", "rev-parse", "HEAD"],
            cwd=ROOT,
            check=True,
            capture_output=True,
            text=True,
        )
    except (OSError, subprocess.CalledProcessError):
        return None
    return result.stdout.strip() or None


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--index",
        default="docs/evidence-index.json",
        help="Repository-relative evidence index path",
    )
    parser.add_argument(
        "--report",
        help="Optional repository-relative JSON report output path",
    )
    args = parser.parse_args()

    errors: list[str] = []
    warnings: list[str] = []
    verified_hashes: list[dict[str, str]] = []
    verified_evidence: list[str] = []
    verified_contracts: list[str] = []
    index_path = _repo_path(args.index, errors, "--index")
    index: dict[str, Any] = {}

    if index_path is not None:
        if not index_path.is_file():
            errors.append(f"Evidence index does not exist: {args.index}")
        else:
            try:
                decoded = json.loads(index_path.read_text(encoding="utf-8"))
            except (OSError, json.JSONDecodeError) as error:
                errors.append(f"Unable to read {args.index}: {error}")
            else:
                if not isinstance(decoded, dict):
                    errors.append("Evidence index root must be a JSON object")
                else:
                    index = decoded

    if index:
        if index.get("schema_version") != 1:
            errors.append("schema_version must be 1")
        if not isinstance(index.get("captured_on"), str):
            errors.append("captured_on must be a string")

        repository = index.get("repository")
        if not isinstance(repository, dict):
            errors.append("repository must be an object")
        else:
            captured_head = repository.get("git_head_at_capture")
            if not isinstance(captured_head, str) or len(captured_head) != 40:
                errors.append(
                    "repository.git_head_at_capture must be a 40-character SHA-1"
                )
            current_head = _git_head()
            if current_head and captured_head and current_head != captured_head:
                warnings.append(
                    "Evidence was captured at a different git HEAD: "
                    f"{captured_head} -> {current_head}"
                )

        _verify_hashed_files(index, "source_documents", errors, verified_hashes)
        _verify_hashed_files(index, "artifacts", errors, verified_hashes)
        _verify_curriculum_manifest(index, errors, verified_contracts)
        _verify_phases(index, errors, verified_evidence)

    status = "pass" if not errors else "fail"
    report = {
        "schema_version": 1,
        "status": status,
        "index": args.index,
        "current_git_head": _git_head(),
        "verified_hashes": verified_hashes,
        "verified_contracts": verified_contracts,
        "verified_evidence_count": len(verified_evidence),
        "warnings": warnings,
        "errors": errors,
    }

    if args.report:
        report_path = _repo_path(args.report, errors, "--report")
        if report_path is not None:
            try:
                report_path.parent.mkdir(parents=True, exist_ok=True)
                report_path.write_text(
                    json.dumps(report, indent=2) + "\n",
                    encoding="utf-8",
                )
            except OSError as error:
                errors.append(f"Unable to write {args.report}: {error}")
                report["status"] = "fail"

    if errors:
        print("Roadmap evidence verification: FAIL")
        for error in errors:
            print(f"- {error}")
        return 1

    print(
        "Roadmap evidence verification: PASS "
        f"({len(verified_hashes)} hashed files, "
        f"{len(verified_evidence)} evidence references)"
    )
    for warning in warnings:
        print(f"Warning: {warning}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
