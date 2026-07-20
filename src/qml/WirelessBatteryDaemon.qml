// SPDX-FileCopyrightText: Elias Mueller
//
// SPDX-License-Identifier: MIT

import QtQuick

import Quickshell

import "logic"

QtObject {
    id: root

    property string pluginId
    property var pluginService: null

    readonly property WirelessBatterySettingsStore _settings: WirelessBatterySettingsStore {
        pluginId: root.pluginId
        pluginService: root.pluginService
    }

    readonly property WirelessBatterySource _source: WirelessBatteryUPowerSource {}

    readonly property WirelessBatteryMonitor _monitor: WirelessBatteryMonitor {
        source: root._source
        lowThresholds: root._settings.lowThresholds

        onLowReading: (deviceName, percent) => Quickshell.execDetached(WirelessBatteryNotification.lowBatteryCommand(deviceName, percent))
    }
}
