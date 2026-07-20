# SPDX-FileCopyrightText: Elias Mueller
#
# SPDX-License-Identifier: MIT

"""In-process fake of the qs.Common QML module for QML tests."""

from typing import override

from PySide6.QtCore import QObject, Slot
from PySide6.QtQml import QmlElement, QmlSingleton

QML_IMPORT_NAME = "qs.Common"
QML_IMPORT_MAJOR_VERSION = 1


def register() -> None:
    """Importing this module already registers the fake QML types."""


@QmlElement
@QmlSingleton
class I18n(QObject):
    @Slot(str, result=str)
    @override
    def tr(self, sourceText: str, disambiguation: str | None = None, n: int = -1) -> str:
        return super().tr(sourceText, disambiguation, n)
