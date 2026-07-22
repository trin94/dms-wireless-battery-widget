// SPDX-FileCopyrightText: Elias Mueller
//
// SPDX-License-Identifier: MIT

import QtQuick
import QtTest

import Quickshell.Services.UPower
import WirelessBatteryWidget.Test

TestCase {
    id: testCase

    name: "Harness"

    property WirelessBatteryTestBridge bridge: WirelessBatteryTestBridge {}

    function init() {
        testCase.bridge.reset();
    }

    function test_fakeUPowerIsDrivableFromQml() {
        const device = testCase.bridge.addDevice({
            "type": UPowerDeviceType.Mouse,
            "state": UPowerDeviceState.Discharging,
            "percentage": 0.5,
            "model": "Test Device"
        });
        verify(device !== null);
        compare(UPower.devices.values.length, 1);
        compare(UPower.devices.values[0].percentage, 0.5);
        testCase.bridge.remove(device);
        compare(UPower.devices.values.length, 0);
    }

    function test_fakeDevicePresenceIsOverridablePerDevice() {
        const device = testCase.bridge.addDevice({});
        const sibling = testCase.bridge.addDevice({});
        const spy = createTemporaryObject(presenceSpyComponent, testCase, {
            "target": device
        });
        testCase.bridge.update(device, {
            "isPresent": false
        });
        compare(device.isPresent, false);
        compare(spy.count, 1);
        compare(sibling.isPresent, true);
    }

    function test_fakeDeviceIsPresentByDefault() {
        const device = testCase.bridge.addDevice({});
        compare(device.isPresent, true);
    }

    Component {
        id: presenceSpyComponent

        SignalSpy {
            signalName: "isPresentChanged"
        }
    }
}
