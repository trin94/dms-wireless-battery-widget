# SPDX-FileCopyrightText: Elias Mueller
#
# SPDX-License-Identifier: MIT

from dbus_fast.service import PropertyAccess, ServiceInterface, dbus_property, method, signal

UPOWER_BUS_NAME = "org.freedesktop.UPower"
UPOWER_PATH = "/org/freedesktop/UPower"
DEVICE_IFACE = "org.freedesktop.UPower.Device"
DEVICE_PATH_PREFIX = "/org/freedesktop/UPower/devices/"
DISPLAY_DEVICE_NAME = "DisplayDevice"

DEVICE_DEFAULTS = {
    "Type": 0,
    "State": 0,
    "Percentage": 0.0,
    "IsPresent": True,
    "IsRechargeable": True,
    "PowerSupply": False,
    "Online": False,
    "Model": "",
    "NativePath": "",
    "IconName": "",
    "Energy": 0.0,
    "EnergyFull": 0.0,
    "EnergyRate": 0.0,
    "TimeToEmpty": 0,
    "TimeToFull": 0,
    "WarningLevel": 1,
}


class DeviceService(ServiceInterface):
    def __init__(self, values):
        super().__init__(DEVICE_IFACE)
        self.values = values

    @dbus_property(access=PropertyAccess.READ)
    def Type(self) -> "u":
        return self.values["Type"]

    @dbus_property(access=PropertyAccess.READ)
    def State(self) -> "u":
        return self.values["State"]

    @dbus_property(access=PropertyAccess.READ)
    def Percentage(self) -> "d":
        return self.values["Percentage"]

    @dbus_property(access=PropertyAccess.READ)
    def IsPresent(self) -> "b":
        return self.values["IsPresent"]

    @dbus_property(access=PropertyAccess.READ)
    def IsRechargeable(self) -> "b":
        return self.values["IsRechargeable"]

    @dbus_property(access=PropertyAccess.READ)
    def PowerSupply(self) -> "b":
        return self.values["PowerSupply"]

    @dbus_property(access=PropertyAccess.READ)
    def Online(self) -> "b":
        return self.values["Online"]

    @dbus_property(access=PropertyAccess.READ)
    def Model(self) -> "s":
        return self.values["Model"]

    @dbus_property(access=PropertyAccess.READ)
    def NativePath(self) -> "s":
        return self.values["NativePath"]

    @dbus_property(access=PropertyAccess.READ)
    def IconName(self) -> "s":
        return self.values["IconName"]

    @dbus_property(access=PropertyAccess.READ)
    def Energy(self) -> "d":
        return self.values["Energy"]

    @dbus_property(access=PropertyAccess.READ)
    def EnergyFull(self) -> "d":
        return self.values["EnergyFull"]

    @dbus_property(access=PropertyAccess.READ)
    def EnergyRate(self) -> "d":
        return self.values["EnergyRate"]

    @dbus_property(access=PropertyAccess.READ)
    def TimeToEmpty(self) -> "x":
        return self.values["TimeToEmpty"]

    @dbus_property(access=PropertyAccess.READ)
    def TimeToFull(self) -> "x":
        return self.values["TimeToFull"]

    @dbus_property(access=PropertyAccess.READ)
    def WarningLevel(self) -> "u":
        return self.values["WarningLevel"]


class RootService(ServiceInterface):
    def __init__(self):
        super().__init__(UPOWER_BUS_NAME)
        self.device_paths = []

    @method()
    def EnumerateDevices(self) -> "ao":
        return list(self.device_paths)

    @method()
    def GetDisplayDevice(self) -> "o":
        return DEVICE_PATH_PREFIX + DISPLAY_DEVICE_NAME

    @method()
    def GetCriticalAction(self) -> "s":
        return "HybridSleep"

    @dbus_property(access=PropertyAccess.READ)
    def DaemonVersion(self) -> "s":
        return "0.99"

    @dbus_property(access=PropertyAccess.READ)
    def OnBattery(self) -> "b":
        return False

    @signal()
    def DeviceAdded(self, path) -> "o":
        return path

    @signal()
    def DeviceRemoved(self, path) -> "o":
        return path
