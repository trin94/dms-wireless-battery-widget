// SPDX-FileCopyrightText: Elias Mueller
//
// SPDX-License-Identifier: MIT

import QtQuick
import QtTest

TestCase {
    id: testCase

    name: "WirelessBatteryViewModel"

    function makeSource(): WirelessBatterySource {
        const source = createTemporaryObject(sourceFactory, testCase);
        verify(source);
        return source;
    }

    function makeDevice(initProperties = {}): WirelessBatteryDevice {
        const device = createTemporaryObject(deviceFactory, testCase, initProperties);
        verify(device);
        return device;
    }

    function makeViewModel(source: WirelessBatterySource): WirelessBatteryViewModel {
        const viewModel = createTemporaryObject(viewModelFactory, testCase, {
            "source": source
        });
        verify(viewModel);
        return viewModel;
    }

    function test_liveMouseBecomesEntryWithIconAndPercentage() {
        const source = makeSource();
        source.devices = [makeDevice({
                "deviceId": "mouse-1",
                "deviceClass": WirelessBatteryDevice.DeviceClass.Mouse,
                "name": "MX Master 3S",
                "level": 0.75,
                "live": true
            })];

        const viewModel = makeViewModel(source);

        compare(viewModel.entries.length, 1);
        compare(viewModel.entries[0].iconName, "mouse");
        compare(viewModel.entries[0].percentText, "75%");
    }

    function test_verticalPercentTextIsTheBareNumber() {
        const source = makeSource();
        source.devices = [makeDevice({
                "deviceId": "mouse-1",
                "deviceClass": WirelessBatteryDevice.DeviceClass.Mouse,
                "level": 1.0,
                "live": true
            })];

        const viewModel = makeViewModel(source);

        compare(viewModel.entries[0].percentText, "100%");
        compare(viewModel.entries[0].verticalPercentText, "100");
    }

    function test_chargeState_data() {
        return [
            {
                tag: "charging",
                chargeState: WirelessBatteryDevice.ChargeState.Charging,
                expectedShowsBolt: true,
                expectedTone: WirelessBatteryTone.Tone.Charging
            },
            {
                tag: "discharging",
                chargeState: WirelessBatteryDevice.ChargeState.Discharging,
                expectedShowsBolt: false,
                expectedTone: WirelessBatteryTone.Tone.Normal
            },
            {
                tag: "fullyCharged",
                chargeState: WirelessBatteryDevice.ChargeState.FullyCharged,
                expectedShowsBolt: true,
                expectedTone: WirelessBatteryTone.Tone.Charging
            }
        ];
    }

    function test_chargeState(data) {
        const source = makeSource();
        source.devices = [makeDevice({
                "deviceId": "mouse-1",
                "deviceClass": WirelessBatteryDevice.DeviceClass.Mouse,
                "level": 0.5,
                "live": true,
                "chargeState": data.chargeState
            })];

        const viewModel = makeViewModel(source);

        compare(viewModel.entries[0].showsBolt, data.expectedShowsBolt);
        compare(viewModel.entries[0].tone, data.expectedTone);
    }

    function test_iconNameFollowsDeviceClass_data() {
        return [
            {
                tag: "mouse",
                deviceClass: WirelessBatteryDevice.DeviceClass.Mouse,
                expectedIconName: "mouse"
            },
            {
                tag: "keyboard",
                deviceClass: WirelessBatteryDevice.DeviceClass.Keyboard,
                expectedIconName: "keyboard"
            },
            {
                tag: "controller",
                deviceClass: WirelessBatteryDevice.DeviceClass.Controller,
                expectedIconName: "sports_esports"
            },
            {
                tag: "headset",
                deviceClass: WirelessBatteryDevice.DeviceClass.Headset,
                expectedIconName: "headset"
            }
        ];
    }

    function test_iconNameFollowsDeviceClass(data) {
        const source = makeSource();
        source.devices = [makeDevice({
                "deviceId": "device-1",
                "deviceClass": data.deviceClass,
                "level": 0.5,
                "live": true
            })];

        const viewModel = makeViewModel(source);

        compare(viewModel.entries[0].iconName, data.expectedIconName);
    }

    function test_lowTone_data() {
        return [
            {
                tag: "lowDraining",
                level: 0.1,
                chargeState: WirelessBatteryDevice.ChargeState.Discharging,
                live: true,
                expectedTone: WirelessBatteryTone.Tone.Low
            },
            {
                tag: "drainingAboveThreshold",
                level: 0.11,
                chargeState: WirelessBatteryDevice.ChargeState.Discharging,
                live: true,
                expectedTone: WirelessBatteryTone.Tone.Normal
            },
            {
                tag: "lowButCharging",
                level: 0.1,
                chargeState: WirelessBatteryDevice.ChargeState.Charging,
                live: true,
                expectedTone: WirelessBatteryTone.Tone.Charging
            },
            {
                tag: "lowButStale",
                level: 0.1,
                chargeState: WirelessBatteryDevice.ChargeState.Discharging,
                live: false,
                expectedTone: WirelessBatteryTone.Tone.Stale
            }
        ];
    }

    function test_lowTone(data) {
        const source = makeSource();
        source.devices = [makeDevice({
                "deviceId": "mouse-1",
                "deviceClass": WirelessBatteryDevice.DeviceClass.Mouse,
                "level": data.level,
                "chargeState": data.chargeState,
                "live": data.live
            })];

        const viewModel = makeViewModel(source);

        compare(viewModel.entries[0].tone, data.expectedTone);
    }

    function test_lowThresholdsFollowSettings() {
        const source = makeSource();
        source.devices = [makeDevice({
                "deviceId": "mouse-1",
                "deviceClass": WirelessBatteryDevice.DeviceClass.Mouse,
                "level": 0.4,
                "chargeState": WirelessBatteryDevice.ChargeState.Discharging,
                "live": true
            })];
        const viewModel = makeViewModel(source);
        compare(viewModel.entries[0].tone, WirelessBatteryTone.Tone.Normal);

        const thresholds = {};
        thresholds[WirelessBatteryDevice.DeviceClass.Mouse] = 50;
        viewModel.lowThresholds = thresholds;

        compare(viewModel.entries[0].tone, WirelessBatteryTone.Tone.Low);
    }

    function test_sameClassDevicesGetOwnEntriesOrderedByName() {
        const source = makeSource();
        source.devices = [makeDevice({
                "deviceId": "mouse-b",
                "deviceClass": WirelessBatteryDevice.DeviceClass.Mouse,
                "name": "Pro Click",
                "level": 0.6,
                "live": true
            }), makeDevice({
                "deviceId": "mouse-a",
                "deviceClass": WirelessBatteryDevice.DeviceClass.Mouse,
                "name": "MX Master 3S",
                "level": 0.75,
                "live": true
            })];

        const viewModel = makeViewModel(source);

        compare(viewModel.entries.map(entry => entry.key), ["mouse-a", "mouse-b"]);
    }

    function test_entriesFollowFixedClassOrder() {
        const source = makeSource();
        source.devices = [makeDevice({
                "deviceId": "headset-1",
                "deviceClass": WirelessBatteryDevice.DeviceClass.Headset,
                "name": "Arctis Nova",
                "level": 0.5,
                "live": true
            }), makeDevice({
                "deviceId": "controller-1",
                "deviceClass": WirelessBatteryDevice.DeviceClass.Controller,
                "name": "DualSense",
                "level": 0.5,
                "live": true
            }), makeDevice({
                "deviceId": "keyboard-1",
                "deviceClass": WirelessBatteryDevice.DeviceClass.Keyboard,
                "name": "MX Keys",
                "level": 0.5,
                "live": true
            }), makeDevice({
                "deviceId": "mouse-1",
                "deviceClass": WirelessBatteryDevice.DeviceClass.Mouse,
                "name": "MX Master 3S",
                "level": 0.5,
                "live": true
            })];

        const viewModel = makeViewModel(source);

        compare(viewModel.entries.map(entry => entry.key), ["mouse-1", "keyboard-1", "controller-1", "headset-1"]);
    }

    function test_livenessChangesNeverReshuffleEntries() {
        const source = makeSource();
        const flickeringDevice = makeDevice({
            "deviceId": "mouse-a",
            "deviceClass": WirelessBatteryDevice.DeviceClass.Mouse,
            "name": "MX Master 3S",
            "level": 0.75,
            "live": true
        });
        source.devices = [flickeringDevice, makeDevice({
                "deviceId": "mouse-b",
                "deviceClass": WirelessBatteryDevice.DeviceClass.Mouse,
                "name": "Pro Click",
                "level": 0.6,
                "live": true
            }), makeDevice({
                "deviceId": "keyboard-1",
                "deviceClass": WirelessBatteryDevice.DeviceClass.Keyboard,
                "name": "MX Keys",
                "level": 0.5,
                "live": true
            })];
        const viewModel = makeViewModel(source);
        compare(viewModel.entries.map(entry => entry.key), ["mouse-a", "mouse-b", "keyboard-1"]);

        flickeringDevice.live = false;
        compare(viewModel.entries.map(entry => entry.key), ["mouse-a", "mouse-b", "keyboard-1"]);
        compare(viewModel.entries[0].tone, WirelessBatteryTone.Tone.Stale);

        flickeringDevice.live = true;
        compare(viewModel.entries.map(entry => entry.key), ["mouse-a", "mouse-b", "keyboard-1"]);
        compare(viewModel.entries[0].tone, WirelessBatteryTone.Tone.Normal);
    }

    function test_devicesLeavingAndReturningNeverReshuffle() {
        const source = makeSource();
        const leaverProperties = {
            "deviceId": "mouse-a",
            "deviceClass": WirelessBatteryDevice.DeviceClass.Mouse,
            "name": "MX Master 3S",
            "level": 0.75,
            "live": true
        };
        const remaining = [makeDevice({
                "deviceId": "mouse-b",
                "deviceClass": WirelessBatteryDevice.DeviceClass.Mouse,
                "name": "Pro Click",
                "level": 0.6,
                "live": true
            }), makeDevice({
                "deviceId": "keyboard-1",
                "deviceClass": WirelessBatteryDevice.DeviceClass.Keyboard,
                "name": "MX Keys",
                "level": 0.5,
                "live": true
            })];
        source.devices = [makeDevice(leaverProperties), ...remaining];
        const viewModel = makeViewModel(source);
        compare(viewModel.entries.map(entry => entry.key), ["mouse-a", "mouse-b", "keyboard-1"]);

        source.devices = remaining;
        compare(viewModel.entries.map(entry => entry.key), ["mouse-b", "keyboard-1"]);

        source.devices = [...remaining, makeDevice(leaverProperties)];
        compare(viewModel.entries.map(entry => entry.key), ["mouse-a", "mouse-b", "keyboard-1"]);
    }

    function test_staleDeviceBecomesDimmedEntryAtLastReading() {
        const source = makeSource();
        source.devices = [makeDevice({
                "deviceId": "mouse-1",
                "deviceClass": WirelessBatteryDevice.DeviceClass.Mouse,
                "name": "MX Master 3S",
                "level": 0.75,
                "live": true
            }), makeDevice({
                "deviceId": "mouse-2",
                "deviceClass": WirelessBatteryDevice.DeviceClass.Mouse,
                "name": "Pro Click",
                "level": 0.4,
                "chargeState": WirelessBatteryDevice.ChargeState.Charging,
                "live": false
            })];

        const viewModel = makeViewModel(source);

        compare(viewModel.entries.length, 2);
        compare(viewModel.entries[0].tone, WirelessBatteryTone.Tone.Normal);
        compare(viewModel.entries[1].key, "mouse-2");
        compare(viewModel.entries[1].tone, WirelessBatteryTone.Tone.Stale);
        compare(viewModel.entries[1].percentText, "40%");
        compare(viewModel.entries[1].showsBolt, false);
    }

    function test_readingUpdatesPropagateToEntries() {
        const source = makeSource();
        const device = makeDevice({
            "deviceId": "mouse-1",
            "deviceClass": WirelessBatteryDevice.DeviceClass.Mouse,
            "level": 0.75,
            "live": true,
            "chargeState": WirelessBatteryDevice.ChargeState.Discharging
        });
        source.devices = [device];
        const viewModel = makeViewModel(source);
        compare(viewModel.entries[0].percentText, "75%");
        compare(viewModel.entries[0].showsBolt, false);

        device.level = 0.42;
        compare(viewModel.entries[0].percentText, "42%");

        device.chargeState = WirelessBatteryDevice.ChargeState.Charging;
        compare(viewModel.entries[0].showsBolt, true);

        device.chargeState = WirelessBatteryDevice.ChargeState.Discharging;
        compare(viewModel.entries[0].showsBolt, false);

        device.live = false;
        compare(viewModel.entries.length, 1);
        compare(viewModel.entries[0].tone, WirelessBatteryTone.Tone.Stale);
        compare(viewModel.entries[0].percentText, "42%");
    }

    function test_liveToStaleToLiveLoopThroughRoster() {
        const source = makeSource();
        source.devices = [makeDevice({
                "deviceId": "mouse-1",
                "deviceClass": WirelessBatteryDevice.DeviceClass.Mouse,
                "name": "MX Master 3S",
                "level": 0.75,
                "live": true
            })];
        const roster = createTemporaryObject(rosterFactory, testCase, {
            "source": source
        });
        verify(roster);
        const viewModel = makeViewModel(roster);
        compare(viewModel.entries.length, 1);
        compare(viewModel.entries[0].tone, WirelessBatteryTone.Tone.Normal);
        compare(viewModel.entries[0].percentText, "75%");

        source.devices = [];
        wait(0);
        compare(viewModel.entries.length, 1);
        compare(viewModel.entries[0].tone, WirelessBatteryTone.Tone.Stale);
        compare(viewModel.entries[0].percentText, "75%");

        source.devices = [makeDevice({
                "deviceId": "mouse-1",
                "deviceClass": WirelessBatteryDevice.DeviceClass.Mouse,
                "name": "MX Master 3S",
                "level": 0.6,
                "live": true
            })];
        wait(0);
        compare(viewModel.entries.length, 1);
        compare(viewModel.entries[0].tone, WirelessBatteryTone.Tone.Normal);
        compare(viewModel.entries[0].percentText, "60%");
    }

    Component {
        id: sourceFactory

        WirelessBatterySource {}
    }

    Component {
        id: deviceFactory

        WirelessBatteryDevice {}
    }

    Component {
        id: rosterFactory

        WirelessBatteryRoster {}
    }

    Component {
        id: viewModelFactory

        WirelessBatteryViewModel {}
    }
}
