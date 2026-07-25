// SPDX-FileCopyrightText: Elias Mueller
//
// SPDX-License-Identifier: MIT

import QtQuick

import Quickshell.Io

WirelessBatterySteamControllerSource {
    id: root

    readonly property Process _helper: Process {
        command: ["python3", root._helperPath()]
        running: true
        stdout: SplitParser {
            onRead: data => root.consumeLine(data)
        }

        Component.onDestruction: running = false
    }

    function _helperPath(): string {
        return decodeURIComponent(Qt.resolvedUrl("../../steam_controller_helper.py").toString().replace(/^file:\/\//, ""));
    }
}
