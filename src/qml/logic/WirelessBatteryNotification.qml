// SPDX-FileCopyrightText: Elias Mueller
//
// SPDX-License-Identifier: MIT

pragma Singleton

import QtQuick

import qs.Common

QtObject {
    id: root

    readonly property string appName: "Wireless Battery Widget"

    function lowBatteryCommand(deviceName: string, percent: int): var {
        return ["notify-send", "--app-name", root.appName, deviceName, I18n.tr("Battery low: %1%").arg(percent)];
    }
}
