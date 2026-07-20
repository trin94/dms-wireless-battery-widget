// SPDX-FileCopyrightText: Elias Mueller
//
// SPDX-License-Identifier: MIT

import QtTest

TestCase {
    id: testCase

    name: "WirelessBatteryDefaults"

    function test_notificationsAreOnByDefault() {
        compare(WirelessBatteryDefaults.notificationsEnabled, true);
    }

    function test_lowThresholdsWithoutPluginDataAreTheDefaults() {
        const thresholds = WirelessBatteryDefaults.lowThresholds(null);

        compare(thresholds[WirelessBatteryDevice.DeviceClass.Mouse], 10);
        compare(thresholds[WirelessBatteryDevice.DeviceClass.Keyboard], 10);
        compare(thresholds[WirelessBatteryDevice.DeviceClass.Controller], 20);
        compare(thresholds[WirelessBatteryDevice.DeviceClass.Headset], 20);
    }

    function test_pluginDataOverridesPerClass() {
        const thresholds = WirelessBatteryDefaults.lowThresholds({
            "controllerLowThreshold": 35
        });

        compare(thresholds[WirelessBatteryDevice.DeviceClass.Controller], 35);
        compare(thresholds[WirelessBatteryDevice.DeviceClass.Mouse], 10);
    }

    function test_allClassesAreTrackedByDefault() {
        const tracked = WirelessBatteryDefaults.trackedClasses(null);

        compare(tracked[WirelessBatteryDevice.DeviceClass.Mouse], true);
        compare(tracked[WirelessBatteryDevice.DeviceClass.Keyboard], true);
        compare(tracked[WirelessBatteryDevice.DeviceClass.Controller], true);
        compare(tracked[WirelessBatteryDevice.DeviceClass.Headset], true);
    }

    function test_pluginDataOverridesTrackedClasses() {
        const tracked = WirelessBatteryDefaults.trackedClasses({
            "keyboardTracked": false
        });

        compare(tracked[WirelessBatteryDevice.DeviceClass.Keyboard], false);
        compare(tracked[WirelessBatteryDevice.DeviceClass.Mouse], true);
    }

    function test_barDisplayTogglesAreOnByDefault() {
        compare(WirelessBatteryDefaults.showPercentage, true);
        compare(WirelessBatteryDefaults.showBolt, true);
    }
}
