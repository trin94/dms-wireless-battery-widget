# SPDX-FileCopyrightText: Elias Mueller
#
# SPDX-License-Identifier: MIT

"""In-process fake of the Quickshell.Io QML module for QML tests.

The components using Quickshell.Io are thin, untested process shells; the
fake only exists so the logic module compiles on the test engine.
"""

from PySide6.QtCore import Property, QObject, Signal
from PySide6.QtQml import QmlElement

QML_IMPORT_NAME = "Quickshell.Io"
QML_IMPORT_MAJOR_VERSION = 1


def register() -> None:
    """Importing this module already registers the fake QML types."""


@QmlElement
class SplitParser(QObject):
    read = Signal(str)


@QmlElement
class Process(QObject):
    commandChanged = Signal()
    runningChanged = Signal(bool)
    stdoutChanged = Signal()

    def __init__(self, parent: QObject | None = None) -> None:
        super().__init__(parent)
        self._command: list[str] = []
        self._running = False
        self._stdout: QObject | None = None

    @Property(list, notify=commandChanged)
    def command(self) -> list[str]:
        return list(self._command)

    @command.setter
    def command(self, value: list[str]) -> None:
        if self._command != value:
            self._command = list(value)
            self.commandChanged.emit()

    @Property(bool, notify=runningChanged)
    def running(self) -> bool:
        return self._running

    @running.setter
    def running(self, value: bool) -> None:
        if self._running != value:
            self._running = value
            self.runningChanged.emit(value)

    @Property(QObject, notify=stdoutChanged)
    def stdout(self) -> QObject | None:
        return self._stdout

    @stdout.setter
    def stdout(self, value: QObject | None) -> None:
        if self._stdout is not value:
            self._stdout = value
            self.stdoutChanged.emit()
