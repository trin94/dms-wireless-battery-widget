// SPDX-FileCopyrightText: Elias Mueller
//
// SPDX-License-Identifier: MIT

import QtQuick

QtObject {
    property string deviceId
    property int deviceClass
    property string name
    property real level
    property int chargeState
    property bool live

    enum DeviceClass {
        Mouse,
        Keyboard,
        Controller,
        Headset
    }

    enum ChargeState {
        Discharging,
        Charging,
        FullyCharged
    }
}
