# SPDX-FileCopyrightText: Elias Mueller
#
# SPDX-License-Identifier: MIT

"""In-process fake of the Quickshell.Services.UPower QML module for QML tests."""

from enum import IntEnum

from PySide6.QtCore import Property, QEnum, QObject, Signal
from PySide6.QtQml import QmlElement, QmlSingleton, QmlUncreatable

QML_IMPORT_NAME = "Quickshell.Services.UPower"
QML_IMPORT_MAJOR_VERSION = 1


def register() -> None:
    """Importing this module already registers the fake QML types."""


@QmlElement
@QmlUncreatable("UPowerDeviceState only holds enum values")
class UPowerDeviceState(QObject):
    @QEnum
    class State(IntEnum):
        Unknown = 0
        Charging = 1
        Discharging = 2
        Empty = 3
        FullyCharged = 4
        PendingCharge = 5
        PendingDischarge = 6


@QmlElement
@QmlUncreatable("UPowerDeviceType only holds enum values")
class UPowerDeviceType(QObject):
    @QEnum
    class Type(IntEnum):
        Unknown = 0
        LinePower = 1
        Battery = 2
        Ups = 3
        Monitor = 4
        Mouse = 5
        Keyboard = 6


@QmlElement
class UPowerDevice(QObject):
    typeChanged = Signal(int)
    stateChanged = Signal(int)
    percentageChanged = Signal(float)
    modelChanged = Signal(str)
    timeToEmptyChanged = Signal(float)
    timeToFullChanged = Signal(float)
    readyChanged = Signal(bool)

    def __init__(self, parent: QObject | None = None) -> None:
        super().__init__(parent)
        self._type = int(UPowerDeviceType.Type.Unknown)
        self._state = int(UPowerDeviceState.State.Unknown)
        self._percentage = 0.0
        self._model = ""
        self._time_to_empty = 0.0
        self._time_to_full = 0.0
        self._ready = True

    @Property(int, notify=typeChanged)
    def type(self) -> int:
        return self._type

    @type.setter
    def type(self, value: int) -> None:
        if self._type != value:
            self._type = value
            self.typeChanged.emit(value)

    @Property(int, notify=stateChanged)
    def state(self) -> int:
        return self._state

    @state.setter
    def state(self, value: int) -> None:
        if self._state != value:
            self._state = value
            self.stateChanged.emit(value)

    @Property(float, notify=percentageChanged)
    def percentage(self) -> float:
        return self._percentage

    @percentage.setter
    def percentage(self, value: float) -> None:
        if self._percentage != value:
            self._percentage = value
            self.percentageChanged.emit(value)

    @Property(str, notify=modelChanged)
    def model(self) -> str:
        return self._model

    @model.setter
    def model(self, value: str) -> None:
        if self._model != value:
            self._model = value
            self.modelChanged.emit(value)

    @Property(float, notify=timeToEmptyChanged)
    def timeToEmpty(self) -> float:
        return self._time_to_empty

    @timeToEmpty.setter
    def timeToEmpty(self, value: float) -> None:
        if self._time_to_empty != value:
            self._time_to_empty = value
            self.timeToEmptyChanged.emit(value)

    @Property(float, notify=timeToFullChanged)
    def timeToFull(self) -> float:
        return self._time_to_full

    @timeToFull.setter
    def timeToFull(self, value: float) -> None:
        if self._time_to_full != value:
            self._time_to_full = value
            self.timeToFullChanged.emit(value)

    @Property(bool, notify=readyChanged)
    def ready(self) -> bool:
        return self._ready

    @ready.setter
    def ready(self, value: bool) -> None:
        if self._ready != value:
            self._ready = value
            self.readyChanged.emit(value)


class FakeDeviceModel(QObject):
    """Stands in for Quickshell's ObjectModel holding the UPower devices."""

    valuesChanged = Signal()

    def __init__(self, parent: QObject | None = None) -> None:
        super().__init__(parent)
        self._values: list[UPowerDevice] = []

    @Property(list, notify=valuesChanged)
    def values(self) -> list[UPowerDevice]:
        return list(self._values)

    def add(self, device: UPowerDevice) -> None:
        self._values = [*self._values, device]
        self.valuesChanged.emit()

    def contains(self, device: UPowerDevice) -> bool:
        return any(d is device for d in self._values)

    def remove(self, device: UPowerDevice) -> None:
        self._values = [d for d in self._values if d is not device]
        self.valuesChanged.emit()

    def clear(self) -> None:
        for device in self._values:
            device.deleteLater()
        self._values = []
        self.valuesChanged.emit()


_DEVICE_MODEL = FakeDeviceModel()


def device_model() -> FakeDeviceModel:
    return _DEVICE_MODEL


@QmlElement
@QmlSingleton
class UPower(QObject):
    def __init__(self, parent: QObject | None = None) -> None:
        super().__init__(parent)
        self._devices = _DEVICE_MODEL

    @Property(QObject, constant=True)
    def devices(self) -> FakeDeviceModel:
        return self._devices
