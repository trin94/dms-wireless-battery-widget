// SPDX-FileCopyrightText: Elias Mueller
//
// SPDX-License-Identifier: MIT

import QtQuick

QtObject {
    property list<WirelessBatteryDevice> devices

    // A backing source was removed for good; carries the device ids it
    // reported so session memory downstream forgets them.
    signal devicesWithdrawn(deviceIds: list<string>)
}
