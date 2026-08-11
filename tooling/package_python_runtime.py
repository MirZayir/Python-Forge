"""Build and verify the deterministic Serious Python runtime archive.

Usage:
    python tooling/package_python_runtime.py --write
    python tooling/package_python_runtime.py --check

The Flutter assets at app/app.zip and app/runtime_manifest.json are generated
from the exact bytes of python_src/main.py. Keeping this check in the
repository prevents a source change from silently shipping with an older
embedded interpreter and lets the app verify the packaged archive at startup.
"""

import argparse
import hashlib
import json
import sys
import zipfile
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / "python_src" / "main.py"
ARCHIVE = ROOT / "app" / "app.zip"
MANIFEST = ROOT / "app" / "runtime_manifest.json"
MANIFEST_VERSION = 1


def _source_bytes():
    if not SOURCE.is_file():
        raise FileNotFoundError("Missing runtime source: {}".format(SOURCE))
    return SOURCE.read_bytes()


def _sha256(data):
    return hashlib.sha256(data).hexdigest()


def _manifest(source_hash, archive_hash):
    return {
        "manifest_version": MANIFEST_VERSION,
        "source_path": "python_src/main.py",
        "source_sha256": source_hash,
        "archive_path": "app/app.zip",
        "archive_sha256": archive_hash,
    }


def _write_manifest(source_hash, archive_hash):
    MANIFEST.write_text(
        json.dumps(_manifest(source_hash, archive_hash), indent=2, sort_keys=True)
        + "\n",
        encoding="utf-8",
    )


def write_archive():
    source = _source_bytes()
    ARCHIVE.parent.mkdir(parents=True, exist_ok=True)
    with zipfile.ZipFile(
        ARCHIVE,
        mode="w",
        compression=zipfile.ZIP_DEFLATED,
        compresslevel=9,
    ) as archive:
        info = zipfile.ZipInfo("main.py", date_time=(1980, 1, 1, 0, 0, 0))
        info.compress_type = zipfile.ZIP_DEFLATED
        info.create_system = 3
        info.external_attr = 0o100644 << 16
        archive.writestr(info, source)

    source_hash = _sha256(source)
    archive_hash = _sha256(ARCHIVE.read_bytes())
    _write_manifest(source_hash, archive_hash)
    print(
        "wrote {} and {} (source_sha256={}, archive_sha256={})".format(
            ARCHIVE.relative_to(ROOT),
            MANIFEST.relative_to(ROOT),
            source_hash,
            archive_hash,
        )
    )


def check_archive():
    source = _source_bytes()
    if not ARCHIVE.is_file():
        raise FileNotFoundError("Missing runtime archive: {}".format(ARCHIVE))
    with zipfile.ZipFile(ARCHIVE) as archive:
        names = archive.namelist()
        if names != ["main.py"]:
            raise ValueError(
                "Runtime archive must contain exactly main.py; found {}".format(
                    names
                )
            )
        packaged = archive.read("main.py")
    if packaged != source:
        raise ValueError(
            "app/app.zip is stale: its main.py does not match python_src/main.py"
        )

    if not MANIFEST.is_file():
        raise FileNotFoundError("Missing runtime manifest: {}".format(MANIFEST))
    try:
        manifest = json.loads(MANIFEST.read_text(encoding="utf-8"))
    except json.JSONDecodeError as error:
        raise ValueError("Runtime manifest is not valid JSON.") from error
    if not isinstance(manifest, dict):
        raise ValueError("Runtime manifest must be a JSON object.")

    source_hash = _sha256(source)
    archive_hash = _sha256(ARCHIVE.read_bytes())
    expected = _manifest(source_hash, archive_hash)
    if manifest != expected:
        raise ValueError(
            "Runtime manifest is stale or does not match the packaged archive."
        )

    print(
        "runtime archive is current (source_sha256={}, archive_sha256={})".format(
            source_hash, archive_hash
        )
    )


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    mode = parser.add_mutually_exclusive_group(required=True)
    mode.add_argument("--write", action="store_true", help="rebuild app/app.zip")
    mode.add_argument("--check", action="store_true", help="verify archive freshness")
    args = parser.parse_args()
    try:
        if args.write:
            write_archive()
            check_archive()
        else:
            check_archive()
    except (OSError, ValueError, zipfile.BadZipFile) as error:
        print("ERROR: {}".format(error), file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
