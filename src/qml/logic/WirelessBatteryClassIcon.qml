// SPDX-FileCopyrightText: Elias Mueller
//
// SPDX-License-Identifier: MIT

pragma Singleton

import QtQuick

// The icon a device class drives.
QtObject {
    function forClass(deviceClass: int): string {
        switch (deviceClass) {
        case WirelessBatteryDevice.DeviceClass.Keyboard:
            return "keyboard";
        case WirelessBatteryDevice.DeviceClass.Controller:
            return "sports_esports";
        case WirelessBatteryDevice.DeviceClass.Headset:
            return "headset";
        default:
            return "mouse";
        }
    }
}
