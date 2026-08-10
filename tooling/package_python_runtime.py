"""Build and verify the deterministic Serious Python runtime archive.

Usage:
    python tooling/package_python_runtime.py --write
    python tooling/package_python_runtime.py --check

The Flutter asset at app/app.zip must contain the exact bytes of
python_src/main.py. Keeping this check in the repository prevents a source
change from silently shipping with an older embedded interpreter.
"""

import argparse
import hashlib
import sys
import zipfile
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / "python_src" / "main.py"
ARCHIVE = ROOT / "app" / "app.zip"


def _source_bytes():
    if not SOURCE.is_file():
        raise FileNotFoundError("Missing runtime source: {}".format(SOURCE))
    return SOURCE.read_bytes()


def _sha256(data):
    return hashlib.sha256(data).hexdigest()


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
    print("wrote {} (sha256={})".format(ARCHIVE.relative_to(ROOT), _sha256(source)))


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
    print(
        "runtime archive is current (sha256={})".format(_sha256(source))
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
