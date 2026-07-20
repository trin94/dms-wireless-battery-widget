// SPDX-FileCopyrightText: Elias Mueller
//
// SPDX-License-Identifier: MIT

import QtQuick
import QtTest

import Quickshell.Services.UPower
import WirelessBatteryWidget.Test

TestCase {
    id: testCase

    name: "WirelessBatteryUPowerSource"

    property WirelessBatteryTestBridge bridge: WirelessBatteryTestBridge {}

    function init() {
        testCase.bridge.reset();
    }

    function makeSource(): WirelessBatteryUPowerSource {
        const source = createTemporaryObject(sourceFactory, testCase);
        verify(source);
        return source;
    }

    function addMouse(overrides = {}) {
        return testCase.bridge.addDevice(Object.assign({
            "type": UPowerDeviceType.Mouse,
            "state": UPowerDeviceState.Discharging,
            "percentage": 0.75,
            "model": "MX Master 3S",
            "nativePath": "hidpp_battery_0"
        }, overrides));
    }

    function test_liveMouseIsDiscovered() {
        testCase.addMouse();

        const source = makeSource();

        compare(source.devices.length, 1);
        const device = source.devices[0];
        compare(device.deviceId, "hidpp_battery_0");
        compare(device.deviceClass, WirelessBatteryDevice.DeviceClass.Mouse);
        compare(device.name, "MX Master 3S");
        compare(device.level, 0.75);
        compare(device.chargeState, WirelessBatteryDevice.ChargeState.Discharging);
        verify(device.live);
    }

    function test_mouseAppearingLaterIsDiscovered() {
        const source = makeSource();
        compare(source.devices.length, 0);

        testCase.addMouse();

        compare(source.devices.length, 1);
    }

    function test_removedMouseDisappears() {
        const upowerDevice = testCase.addMouse();
        const source = makeSource();
        compare(source.devices.length, 1);

        testCase.bridge.remove(upowerDevice);

        compare(source.devices.length, 0);
    }

    function test_unsupportedTypesAreIgnored() {
        testCase.bridge.addDevice({
            "type": UPowerDeviceType.Battery,
            "state": UPowerDeviceState.Discharging,
            "percentage": 0.5
        });
        testCase.bridge.addDevice({
            "type": UPowerDeviceType.LinePower,
            "state": UPowerDeviceState.Discharging,
            "percentage": 0.5
        });

        const source = makeSource();

        compare(source.devices.length, 0);
    }

    function test_liveness_data() {
        return [
            {
                tag: "unknownState",
                overrides: {
                    "state": UPowerDeviceState.Unknown
                },
                expectedLive: false
            },
            {
                tag: "zeroPercentage",
                overrides: {
                    "percentage": 0
                },
                expectedLive: false
            },
            {
                tag: "notReady",
                overrides: {
                    "ready": false
                },
                expectedLive: false
            },
            {
                tag: "reportedReading",
                overrides: {},
                expectedLive: true
            }
        ];
    }

    function test_liveness(data) {
        testCase.addMouse(data.overrides);

        const source = makeSource();

        compare(source.devices.length, 1);
        compare(source.devices[0].live, data.expectedLive);
    }

    function test_wakingMouseBecomesLive() {
        const upowerDevice = testCase.addMouse({
            "state": UPowerDeviceState.Unknown,
            "percentage": 0
        });
        const source = makeSource();
        verify(!source.devices[0].live);

        testCase.bridge.update(upowerDevice, {
            "state": UPowerDeviceState.Discharging,
            "percentage": 0.6
        });

        verify(source.devices[0].live);
        compare(source.devices[0].level, 0.6);
    }

    function test_chargeStateMapping_data() {
        return [
            {
                tag: "charging",
                state: UPowerDeviceState.Charging,
                expected: WirelessBatteryDevice.ChargeState.Charging
            },
            {
                tag: "pendingCharge",
                state: UPowerDeviceState.PendingCharge,
                expected: WirelessBatteryDevice.ChargeState.Charging
            },
            {
                tag: "fullyCharged",
                state: UPowerDeviceState.FullyCharged,
                expected: WirelessBatteryDevice.ChargeState.FullyCharged
            },
            {
                tag: "discharging",
                state: UPowerDeviceState.Discharging,
                expected: WirelessBatteryDevice.ChargeState.Discharging
            }
        ];
    }

    function test_chargeStateMapping(data) {
        testCase.addMouse({
            "state": data.state
        });

        const source = makeSource();

        compare(source.devices[0].chargeState, data.expected);
    }

    Component {
        id: sourceFactory

        WirelessBatteryUPowerSource {}
    }
}
