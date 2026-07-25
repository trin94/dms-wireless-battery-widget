// SPDX-FileCopyrightText: Elias Mueller
//
// SPDX-License-Identifier: MIT

import QtQuick

import Quickshell.Io

WirelessBatterySteamControllerSource {
    id: root

    readonly property Process _helper: Process {
        command: root.helperCommand()
        running: true
        stdout: SplitParser {
            onRead: data => root.consumeLine(data)
        }

        Component.onDestruction: running = false
    }
}
