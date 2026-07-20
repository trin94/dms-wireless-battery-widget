// SPDX-FileCopyrightText: Elias Mueller
//
// SPDX-License-Identifier: MIT

pragma ComponentBehavior: Bound

import QtQuick

import Quickshell
import Quickshell.Io

import qs.Common

import "WirelessBattery"
import "WirelessBattery/logic"

ShellRoot {
    id: root

    readonly property string pluginId: "wirelessBatteryWidget"

    property bool verticalBar: false

    function _settingKeys(): var {
        const keys = [];
        for (const key in WirelessBatteryDefaults) {
            if (key !== "objectName" && typeof WirelessBatteryDefaults[key] !== "function")
                keys.push(key);
        }
        return keys;
    }

    MockPluginService {
        id: mockPluginService
    }

    IpcHandler {
        id: settingsIpc

        target: "settings"

        function list(): string {
            return root._settingKeys().map(key => key + " (" + typeof WirelessBatteryDefaults[key] + ") = " + JSON.stringify(WirelessBatteryDefaults[key])).join("\n");
        }

        function set(key: string, value: string): string {
            if (!root._settingKeys().includes(key))
                return "unknown setting: " + key + "\nvalid settings, with their defaults:\n" + settingsIpc.list();
            const defaultValue = WirelessBatteryDefaults[key];
            let parsed = value;
            if (typeof defaultValue === "boolean") {
                if (value !== "true" && value !== "false")
                    return key + " expects true or false";
                parsed = value === "true";
            } else if (typeof defaultValue === "number") {
                parsed = Number(value);
                if (Number.isNaN(parsed))
                    return key + " expects a number";
            }
            mockPluginService.savePluginData(root.pluginId, key, parsed);
            return key + " = " + JSON.stringify(parsed);
        }
    }

    IpcHandler {
        target: "bar"

        function vertical(value: string): string {
            if (value !== "true" && value !== "false")
                return "vertical expects true or false";
            root.verticalBar = value === "true";
            return "vertical = " + value;
        }

        function popout(): string {
            widget.triggerPopout();
            return "popout toggled";
        }
    }

    Connections {
        target: mockPluginService

        function onPluginDataChanged(changedPluginId: string) {
            widget.pluginData = mockPluginService.data[changedPluginId] ?? {};
        }
    }

    PanelWindow {
        id: bar

        anchors {
            left: true
            top: root.verticalBar
            right: !root.verticalBar
            bottom: true
        }
        implicitWidth: widget.barThickness
        implicitHeight: widget.barThickness
        color: Theme.surfaceContainer

        WirelessBatteryWidget {
            id: widget
            parentScreen: bar.screen
            axis: root.verticalBar ? ({
                    "isVertical": true,
                    "edge": "left"
                }) : null
            anchors.centerIn: parent
        }
    }

    WirelessBatteryDaemon {
        pluginId: root.pluginId
        pluginService: mockPluginService
    }
}
