// SPDX-FileCopyrightText: Elias Mueller
//
// SPDX-License-Identifier: MIT

import QtTest

TestCase {
    id: testCase

    name: "WirelessBatteryDefaults"

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
}
