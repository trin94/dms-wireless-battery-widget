# SPDX-FileCopyrightText: Elias Mueller
#
# SPDX-License-Identifier: MIT

"""QML-facing bridge for driving the fake UPower service from QML tests."""

from PySide6.QtCore import QObject, Slot
from PySide6.QtQml import QmlElement

from upower_fake import UPowerDevice, device_model

QML_IMPORT_NAME = "WirelessBatteryWidget.Test"
QML_IMPORT_MAJOR_VERSION = 1


def register() -> None:
    """Importing this module already registers the bridge QML type."""


@QmlElement
class WirelessBatteryTestBridge(QObject):
    def __init__(self, parent: QObject | None = None) -> None:
        super().__init__(parent)
        self._devices = device_model()

    @Slot(dict, result=UPowerDevice)
    def addDevice(self, properties: dict[str, object]) -> UPowerDevice:
        device = UPowerDevice(self._devices)
        _apply(device, properties)
        self._devices.add(device)
        return device

    @Slot(UPowerDevice, dict)
    def update(self, device: UPowerDevice, overrides: dict[str, object]) -> None:
        if not self._devices.contains(device):
            message = "cannot update a device that is not registered"
            raise ValueError(message)
        _apply(device, overrides)

    @Slot(UPowerDevice)
    def remove(self, device: UPowerDevice) -> None:
        self._devices.remove(device)

    @Slot()
    def reset(self) -> None:
        self._devices.clear()


def _apply(device: UPowerDevice, properties: dict[str, object]) -> None:
    for name, value in properties.items():
        if device.metaObject().indexOfProperty(name) < 0:
            message = f"UPowerDevice has no property named {name!r}"
            raise ValueError(message)
        device.setProperty(name, value)
