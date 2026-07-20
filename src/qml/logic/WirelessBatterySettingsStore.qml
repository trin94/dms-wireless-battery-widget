// SPDX-FileCopyrightText: Elias Mueller
//
// SPDX-License-Identifier: MIT

import QtQuick

QtObject {
    id: root

    property string pluginId
    property var pluginService: null
    property var lowThresholds: WirelessBatteryDefaults.lowThresholds(null)

    readonly property Connections _dataWatcher: Connections {
        target: root.pluginService

        function onPluginDataChanged(changedPluginId: string) {
            if (changedPluginId === root.pluginId)
                root._reload();
        }
    }

    function _reload(): void {
        root.lowThresholds = WirelessBatteryDefaults.lowThresholds({
            "mouseLowThreshold": root._stored("mouseLowThreshold"),
            "keyboardLowThreshold": root._stored("keyboardLowThreshold"),
            "controllerLowThreshold": root._stored("controllerLowThreshold"),
            "headsetLowThreshold": root._stored("headsetLowThreshold")
        });
    }

    function _stored(key: string): var {
        return root.pluginService?.loadPluginData(root.pluginId, key, undefined);
    }

    onPluginIdChanged: _reload()
    onPluginServiceChanged: _reload()

    Component.onCompleted: _reload()
}
