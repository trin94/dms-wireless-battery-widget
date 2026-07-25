# SPDX-FileCopyrightText: Elias Mueller
#
# SPDX-License-Identifier: MIT

"""QML unit tests running the components against a fake UPower service."""

import os
import sys
from pathlib import Path

from PySide6.QtQuickTest import QUICK_TEST_MAIN

import qml_test_bridge
import quickshell_io_fake
import upower_fake

QML_DIR = Path(__file__).parent / "qml"
QS_FAKE_DIR = Path(__file__).parent / "qs_fake"


def main() -> int:
    os.environ["QML_XHR_ALLOW_FILE_READ"] = "1"
    upower_fake.register()
    quickshell_io_fake.register()
    qml_test_bridge.register()
    argv = [
        sys.argv[0],
        "-platform",
        "offscreen",
        "-import",
        str(QS_FAKE_DIR),
        "-input",
        str(QML_DIR),
        *sys.argv[1:],
    ]
    return QUICK_TEST_MAIN("wireless-battery-widget", argv)


if __name__ == "__main__":
    sys.exit(main())
