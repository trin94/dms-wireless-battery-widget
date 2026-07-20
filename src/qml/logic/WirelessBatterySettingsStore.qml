// SPDX-FileCopyrightText: Elias Mueller
//
// SPDX-License-Identifier: MIT

import QtQuick

QtObject {
    id: root

    property string pluginId
    property var pluginService: null
    property var lowThresholds: WirelessBatteryDefaults.lowThresholds(null)
    property var trackedClasses: WirelessBatteryDefaults.trackedClasses(null)
    property bool notificationsEnabled: WirelessBatteryDefaults.notificationsEnabled

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
        root.trackedClasses = WirelessBatteryDefaults.trackedClasses({
            "mouseTracked": root._stored("mouseTracked"),
            "keyboardTracked": root._stored("keyboardTracked"),
            "controllerTracked": root._stored("controllerTracked"),
            "headsetTracked": root._stored("headsetTracked")
        });
        root.notificationsEnabled = root._stored("notificationsEnabled") ?? WirelessBatteryDefaults.notificationsEnabled;
    }

    function _stored(key: string): var {
        return root.pluginService?.loadPluginData(root.pluginId, key, undefined);
    }

    onPluginIdChanged: _reload()
    onPluginServiceChanged: _reload()

    Component.onCompleted: _reload()
}
