# SPDX-FileCopyrightText: Elias Mueller
#
# SPDX-License-Identifier: MIT

"""Generate the QML tooling files for the DMS qs.* imports."""

import re
import shutil
import subprocess
import sys
import tempfile
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parent.parent
SHIM_ROOT = REPO_ROOT / ".qmllint-imports"

BRIDGE_MODULE = "WirelessBatteryWidget.Test"
BRIDGE_SOURCE = REPO_ROOT / "src" / "qml_test_bridge.py"

DMS_ROOTS = (
    Path.home() / ".config" / "quickshell" / "dms",
    Path("/usr/share/quickshell/dms"),
)
SYSTEM_QML_DIRS = (
    Path("/usr/lib64/qt6/qml"),
    Path("/usr/lib/qt6/qml"),
)

SINGLETON_PRAGMA = re.compile(r"^\s*pragma\s+Singleton", re.MULTILINE)
MODULE_IDENTIFIER = re.compile(r"^[A-Za-z_][A-Za-z0-9_]*$")


def find_dms_root() -> Path | None:
    for root in DMS_ROOTS:
        if (root / "shell.qml").is_file():
            return root
    return None


def is_singleton(file: Path) -> bool:
    return file.suffix == ".qml" and SINGLETON_PRAGMA.search(file.read_text(encoding="utf-8")) is not None


def qmldir_content(module: str, files: list[Path]) -> str:
    lines = [f"module {module}"]
    lines.extend(f"{'singleton ' if is_singleton(file) else ''}{file.stem} 1.0 {file.name}" for file in files)
    return "\n".join(lines) + "\n"


def generate_shims(dms_root: Path) -> None:
    qs_root = SHIM_ROOT / "qs"
    if qs_root.is_symlink():
        qs_root.unlink()
    elif qs_root.exists():
        shutil.rmtree(qs_root)

    for directory in (dms_root, *sorted(dms_root.rglob("*/"))):
        relative = directory.relative_to(dms_root)
        if not all(MODULE_IDENTIFIER.match(part) for part in relative.parts):
            continue

        files = sorted(
            file for file in directory.iterdir() if file.suffix in {".qml", ".js"} and file.name[0].isupper()
        )
        if not files:
            continue

        shim = qs_root / relative
        shim.mkdir(parents=True, exist_ok=True)
        for file in files:
            (shim / file.name).symlink_to(file)

        module = ".".join(["qs", *relative.parts])
        (shim / "qmldir").write_text(qmldir_content(module, files), encoding="utf-8")


def run_tool(name: str, *args: str) -> None:
    tool = shutil.which(name)
    if tool is None:
        message = f"required tool not found: {name}"
        raise FileNotFoundError(message)
    result = subprocess.run([tool, *args], check=False, capture_output=True, text=True)
    if result.returncode != 0:
        message = f"{name} failed:\n{result.stdout}{result.stderr}"
        raise RuntimeError(message)


def generate_bridge_types() -> None:
    """Generate qmldir and qmltypes for the QML types registered from Python."""
    target = SHIM_ROOT.joinpath(*BRIDGE_MODULE.split("."))
    shutil.rmtree(SHIM_ROOT / BRIDGE_MODULE.split(".", maxsplit=1)[0], ignore_errors=True)
    target.mkdir(parents=True)

    qmltypes = target / "qml_test_bridge.qmltypes"
    with tempfile.TemporaryDirectory() as scratch:
        metatypes = Path(scratch) / "metatypes.json"
        run_tool("pyside6-metaobjectdump", str(BRIDGE_SOURCE), "-o", str(metatypes))
        run_tool(
            "pyside6-qmltyperegistrar",
            f"--import-name={BRIDGE_MODULE}",
            "--major-version=1",
            f"--generate-qmltypes={qmltypes}",
            "-o",
            str(Path(scratch) / "registration.cpp"),
            str(metatypes),
        )
    (target / "qmldir").write_text(f"module {BRIDGE_MODULE}\ntypeinfo {qmltypes.name}\n", encoding="utf-8")


def import_paths() -> list[Path]:
    return [SHIM_ROOT, *(path for path in SYSTEM_QML_DIRS if path.is_dir())]


def write_qmlls_ini() -> None:
    ini = REPO_ROOT / ".qmlls.ini"
    ini.unlink(missing_ok=True)
    paths = ":".join(str(path) for path in import_paths())
    ini.write_text(f"[General]\nno-cmake-calls=true\nimportPaths={paths}\n", encoding="utf-8")


def generate(dms_root: Path) -> None:
    generate_shims(dms_root)
    generate_bridge_types()
    write_qmlls_ini()


def main() -> int:
    dms_root = find_dms_root()
    if dms_root is None:
        sys.stderr.write("error: no DMS installation found\n")
        return 1
    generate(dms_root)
    return 0


if __name__ == "__main__":
    sys.exit(main())
