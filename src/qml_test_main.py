# SPDX-FileCopyrightText: Elias Mueller
#
# SPDX-License-Identifier: MIT

"""QML unit tests running the components against a fake UPower service."""

import sys
from pathlib import Path

from PySide6.QtQuickTest import QUICK_TEST_MAIN

import qml_test_bridge
import qs_common_fake
import upower_fake

QML_DIR = Path(__file__).parent / "qml"


def main() -> int:
    upower_fake.register()
    qs_common_fake.register()
    qml_test_bridge.register()
    argv = [sys.argv[0], "-platform", "offscreen", "-input", str(QML_DIR), *sys.argv[1:]]
    return QUICK_TEST_MAIN("wireless-battery-widget", argv)


if __name__ == "__main__":
    sys.exit(main())
