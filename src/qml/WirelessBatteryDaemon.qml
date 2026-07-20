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

    readonly property WirelessBatterySource _trackedSource: WirelessBatteryTrackedClassFilter {
        source: root._source
        trackedClasses: root._settings.trackedClasses
    }

    readonly property WirelessBatteryMonitor _monitor: WirelessBatteryMonitor {
        source: root._trackedSource
        lowThresholds: root._settings.lowThresholds

        onLowReading: (deviceName, percent) => {
            if (root._settings.notificationsEnabled)
                Quickshell.execDetached(WirelessBatteryNotification.lowBatteryCommand(deviceName, percent));
        }
    }
}
