// SPDX-FileCopyrightText: Elias Mueller
//
// SPDX-License-Identifier: MIT

pragma Singleton

import QtQuick

// Every value property doubles as a plugin-data settings key with its
// default; the mock preview's settings IPC enumerates them by name.
QtObject {
    id: root

    readonly property int mouseLowThreshold: 10
    readonly property int keyboardLowThreshold: 10
    readonly property int controllerLowThreshold: 20
    readonly property int headsetLowThreshold: 20

    function lowThresholds(pluginData: var): var {
        const data = pluginData ?? {};
        const thresholds = {};
        thresholds[WirelessBatteryDevice.DeviceClass.Mouse] = data.mouseLowThreshold ?? root.mouseLowThreshold;
        thresholds[WirelessBatteryDevice.DeviceClass.Keyboard] = data.keyboardLowThreshold ?? root.keyboardLowThreshold;
        thresholds[WirelessBatteryDevice.DeviceClass.Controller] = data.controllerLowThreshold ?? root.controllerLowThreshold;
        thresholds[WirelessBatteryDevice.DeviceClass.Headset] = data.headsetLowThreshold ?? root.headsetLowThreshold;
        return thresholds;
    }
}
