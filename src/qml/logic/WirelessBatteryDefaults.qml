// SPDX-FileCopyrightText: Elias Mueller
//
// SPDX-License-Identifier: MIT

pragma Singleton

import QtQuick

// Every value property doubles as a plugin-data settings key with its
// default; the mock preview's settings IPC enumerates them by name.
QtObject {
    id: root

    readonly property bool notificationsEnabled: true
    readonly property int mouseLowThreshold: 10
    readonly property int keyboardLowThreshold: 10
    readonly property int controllerLowThreshold: 20
    readonly property int headsetLowThreshold: 20
    readonly property bool mouseTracked: true
    readonly property bool keyboardTracked: true
    readonly property bool controllerTracked: true
    readonly property bool headsetTracked: true
    readonly property bool mouseRetained: true
    readonly property bool keyboardRetained: true
    readonly property bool controllerRetained: false
    readonly property bool headsetRetained: false
    readonly property bool showPercentage: true
    readonly property bool showBolt: true

    function lowThresholds(pluginData: var): var {
        const data = pluginData ?? {};
        const thresholds = {};
        thresholds[WirelessBatteryDevice.DeviceClass.Mouse] = data.mouseLowThreshold ?? root.mouseLowThreshold;
        thresholds[WirelessBatteryDevice.DeviceClass.Keyboard] = data.keyboardLowThreshold ?? root.keyboardLowThreshold;
        thresholds[WirelessBatteryDevice.DeviceClass.Controller] = data.controllerLowThreshold ?? root.controllerLowThreshold;
        thresholds[WirelessBatteryDevice.DeviceClass.Headset] = data.headsetLowThreshold ?? root.headsetLowThreshold;
        return thresholds;
    }

    function trackedClasses(pluginData: var): var {
        const data = pluginData ?? {};
        const tracked = {};
        tracked[WirelessBatteryDevice.DeviceClass.Mouse] = data.mouseTracked ?? root.mouseTracked;
        tracked[WirelessBatteryDevice.DeviceClass.Keyboard] = data.keyboardTracked ?? root.keyboardTracked;
        tracked[WirelessBatteryDevice.DeviceClass.Controller] = data.controllerTracked ?? root.controllerTracked;
        tracked[WirelessBatteryDevice.DeviceClass.Headset] = data.headsetTracked ?? root.headsetTracked;
        return tracked;
    }

    function retainedClasses(pluginData: var): var {
        const data = pluginData ?? {};
        const retained = {};
        retained[WirelessBatteryDevice.DeviceClass.Mouse] = data.mouseRetained ?? root.mouseRetained;
        retained[WirelessBatteryDevice.DeviceClass.Keyboard] = data.keyboardRetained ?? root.keyboardRetained;
        retained[WirelessBatteryDevice.DeviceClass.Controller] = data.controllerRetained ?? root.controllerRetained;
        retained[WirelessBatteryDevice.DeviceClass.Headset] = data.headsetRetained ?? root.headsetRetained;
        return retained;
    }
}
