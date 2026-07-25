// SPDX-FileCopyrightText: Elias Mueller
//
// SPDX-License-Identifier: MIT

pragma Singleton

import QtQuick

import Quickshell.Io

// One helper process for the whole plugin: the daemon switches `enabled`
// from the settings, daemon and widget both merge `source` into their
// pipelines.
QtObject {
    id: root

    readonly property WirelessBatterySteamControllerSource source: WirelessBatterySteamControllerSource {}

    property bool enabled: false

    readonly property Process _helper: Process {
        command: root.source.helperCommand()
        running: root.enabled
        stdout: SplitParser {
            onRead: data => root.source.consumeLine(data)
        }

        onRunningChanged: {
            if (!running && root.enabled)
                console.warn("WirelessBatteryWidget: Steam Controller helper stopped; is python3 installed?");
        }

        Component.onDestruction: running = false
    }

    onEnabledChanged: {
        if (!root.enabled)
            root.source.withdraw();
    }
}
