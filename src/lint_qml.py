# SPDX-FileCopyrightText: Elias Mueller
#
# SPDX-License-Identifier: MIT

"""Run qmllint on QML files with the DMS qs.* imports resolved."""

import shutil
import subprocess
import sys
from pathlib import Path

import qml_tooling

QMLLINT_FALLBACKS = (
    Path("/usr/lib64/qt6/bin/qmllint"),
    Path("/usr/lib/qt6/bin/qmllint"),
)


def find_qmllint() -> str | None:
    qmllint = shutil.which("qmllint")
    if qmllint is not None:
        return qmllint
    for fallback in QMLLINT_FALLBACKS:
        if fallback.is_file():
            return str(fallback)
    return None


def main(files: list[str]) -> int:
    if not files:
        return 0

    dms_root = qml_tooling.find_dms_root()
    if dms_root is None:
        sys.stderr.write("error: no DMS installation found\n")
        return 1

    qmllint = find_qmllint()
    if qmllint is None:
        sys.stderr.write("error: no qmllint executable found\n")
        return 1

    qml_tooling.generate(dms_root)

    flags = [flag for path in qml_tooling.import_paths() for flag in ("-I", str(path))]
    return subprocess.run([qmllint, "-W", "0", *flags, *files], check=False).returncode


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
