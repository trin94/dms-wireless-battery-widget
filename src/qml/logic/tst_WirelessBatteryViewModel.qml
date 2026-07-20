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

    function test_chargeState_data() {
        return [
            {
                tag: "charging",
                chargeState: WirelessBatteryDevice.ChargeState.Charging,
                expectedShowsBolt: true,
                expectedTone: WirelessBatteryViewModel.Tone.Charging
            },
            {
                tag: "discharging",
                chargeState: WirelessBatteryDevice.ChargeState.Discharging,
                expectedShowsBolt: false,
                expectedTone: WirelessBatteryViewModel.Tone.Normal
            },
            {
                tag: "fullyCharged",
                chargeState: WirelessBatteryDevice.ChargeState.FullyCharged,
                expectedShowsBolt: true,
                expectedTone: WirelessBatteryViewModel.Tone.Charging
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

    function test_onlyLiveDevicesBecomeEntries() {
        const source = makeSource();
        source.devices = [makeDevice({
                "deviceId": "mouse-1",
                "deviceClass": WirelessBatteryDevice.DeviceClass.Mouse,
                "level": 0.75,
                "live": true
            }), makeDevice({
                "deviceId": "mouse-2",
                "deviceClass": WirelessBatteryDevice.DeviceClass.Mouse,
                "level": 0.4,
                "live": false
            })];

        const viewModel = makeViewModel(source);

        compare(viewModel.entries.length, 1);
        compare(viewModel.entries[0].key, "mouse-1");
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
        compare(viewModel.entries.length, 0);
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
        id: viewModelFactory

        WirelessBatteryViewModel {}
    }
}
