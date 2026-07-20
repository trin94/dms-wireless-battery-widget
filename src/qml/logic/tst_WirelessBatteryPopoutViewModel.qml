// SPDX-FileCopyrightText: Elias Mueller
//
// SPDX-License-Identifier: MIT

import QtQuick
import QtTest

TestCase {
    id: testCase

    name: "WirelessBatteryPopoutViewModel"

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

    function makeViewModel(roster: WirelessBatterySource, source: WirelessBatterySource): WirelessBatteryPopoutViewModel {
        const viewModel = createTemporaryObject(viewModelFactory, testCase, {
            "roster": roster,
            "source": source ?? makeSource()
        });
        verify(viewModel);
        return viewModel;
    }

    function makeMouse(overrides = {}): WirelessBatteryDevice {
        return makeDevice(Object.assign({
            "deviceId": "mouse-1",
            "deviceClass": WirelessBatteryDevice.DeviceClass.Mouse,
            "name": "MX Master 3S",
            "level": 0.75,
            "chargeState": WirelessBatteryDevice.ChargeState.Discharging,
            "live": true
        }, overrides));
    }

    function test_rowsShowFullDetailInFixedOrder() {
        const roster = makeSource();
        roster.devices = [makeDevice({
                "deviceId": "keyboard-1",
                "deviceClass": WirelessBatteryDevice.DeviceClass.Keyboard,
                "name": "MX Keys",
                "level": 0.5,
                "chargeState": WirelessBatteryDevice.ChargeState.Discharging,
                "timeToEmpty": 3600,
                "live": true
            }), makeMouse({
                "chargeState": WirelessBatteryDevice.ChargeState.Charging,
                "timeToFull": 1800
            })];

        const viewModel = makeViewModel(roster);

        compare(viewModel.rows.length, 2);
        compare(viewModel.rows[0].key, "mouse-1");
        compare(viewModel.rows[0].name, "MX Master 3S");
        compare(viewModel.rows[0].chargeStateText, "Charging");
        compare(viewModel.rows[0].levelText, "75%");
        compare(viewModel.rows[0].level, 0.75);
        compare(viewModel.rows[0].timeText, "30m");
        compare(viewModel.rows[0].detailText, "Charging · 30m");
        compare(viewModel.rows[0].stale, false);
        compare(viewModel.rows[1].key, "keyboard-1");
        compare(viewModel.rows[1].chargeStateText, "Discharging");
        compare(viewModel.rows[1].timeText, "1h 0m");
    }

    function test_sameClassRowsOrderedByName() {
        const roster = makeSource();
        roster.devices = [makeMouse({
                "deviceId": "mouse-b",
                "name": "Pro Click"
            }), makeMouse({
                "deviceId": "mouse-a",
                "name": "MX Master 3S"
            })];

        const viewModel = makeViewModel(roster);

        compare(viewModel.rows.map(row => row.key), ["mouse-a", "mouse-b"]);
    }

    function test_chargeStateTexts_data() {
        return [
            {
                tag: "discharging",
                chargeState: WirelessBatteryDevice.ChargeState.Discharging,
                expectedText: "Discharging"
            },
            {
                tag: "charging",
                chargeState: WirelessBatteryDevice.ChargeState.Charging,
                expectedText: "Charging"
            },
            {
                tag: "fullyCharged",
                chargeState: WirelessBatteryDevice.ChargeState.FullyCharged,
                expectedText: "Fully charged"
            }
        ];
    }

    function test_chargeStateTexts(data) {
        const roster = makeSource();
        roster.devices = [makeMouse({
                "chargeState": data.chargeState
            })];

        const viewModel = makeViewModel(roster);

        compare(viewModel.rows[0].chargeStateText, data.expectedText);
    }

    function test_timeEstimates_data() {
        return [
            {
                tag: "drainingUsesTimeToEmpty",
                chargeState: WirelessBatteryDevice.ChargeState.Discharging,
                timeToEmpty: 7200,
                timeToFull: 900,
                expectedText: "2h 0m"
            },
            {
                tag: "chargingUsesTimeToFull",
                chargeState: WirelessBatteryDevice.ChargeState.Charging,
                timeToEmpty: 900,
                timeToFull: 2700,
                expectedText: "45m"
            },
            {
                tag: "fullyChargedHasNoEstimate",
                chargeState: WirelessBatteryDevice.ChargeState.FullyCharged,
                timeToEmpty: 3600,
                timeToFull: 3600,
                expectedText: ""
            },
            {
                tag: "missingEstimateStaysBlank",
                chargeState: WirelessBatteryDevice.ChargeState.Discharging,
                timeToEmpty: 0,
                timeToFull: 0,
                expectedText: ""
            }
        ];
    }

    function test_timeEstimates(data) {
        const roster = makeSource();
        roster.devices = [makeMouse({
                "chargeState": data.chargeState,
                "timeToEmpty": data.timeToEmpty,
                "timeToFull": data.timeToFull
            })];

        const viewModel = makeViewModel(roster);

        compare(viewModel.rows[0].timeText, data.expectedText);
    }

    function test_thresholdSplitFollowsClassAndToggle() {
        const roster = makeSource();
        roster.devices = [makeMouse(), makeDevice({
                "deviceId": "controller-1",
                "deviceClass": WirelessBatteryDevice.DeviceClass.Controller,
                "name": "DualSense",
                "level": 0.5,
                "live": true
            })];
        const viewModel = makeViewModel(roster);

        compare(viewModel.rows[0].thresholdFraction, 0.1);
        compare(viewModel.rows[1].thresholdFraction, 0.2);
        compare(viewModel.rows[0].showsSplit, true);

        viewModel.showsThresholdSplit = false;

        compare(viewModel.rows[0].showsSplit, false);
        compare(viewModel.rows[1].showsSplit, false);
    }

    function test_lowThresholdsFollowSettings() {
        const roster = makeSource();
        roster.devices = [makeMouse()];
        const viewModel = makeViewModel(roster);

        const thresholds = {};
        thresholds[WirelessBatteryDevice.DeviceClass.Mouse] = 50;
        viewModel.lowThresholds = thresholds;

        compare(viewModel.rows[0].thresholdFraction, 0.5);
    }

    function test_staleRowKeepsReadingWithoutEstimate() {
        const roster = makeSource();
        roster.devices = [makeMouse({
                "level": 0.4,
                "timeToEmpty": 3600,
                "live": false
            })];

        const viewModel = makeViewModel(roster);

        compare(viewModel.rows[0].stale, true);
        compare(viewModel.rows[0].levelText, "40%");
        compare(viewModel.rows[0].chargeStateText, "Discharging");
        compare(viewModel.rows[0].timeText, "");
        compare(viewModel.rows[0].detailText, "Discharging");
    }

    function test_emptyStateDistinguishesWaitingFromNoSupportedDevice() {
        const roster = makeSource();
        const source = makeSource();
        const viewModel = makeViewModel(roster, source);

        compare(viewModel.emptyState, WirelessBatteryPopoutViewModel.EmptyState.NoSupportedDevice);
        compare(viewModel.emptyText, "No supported device present");

        source.devices = [makeMouse({
                "live": false
            })];

        compare(viewModel.emptyState, WirelessBatteryPopoutViewModel.EmptyState.WaitingForKnownDevice);
        compare(viewModel.emptyText, "Waiting for a known device");
    }

    function test_rowsClearTheEmptyState() {
        const roster = makeSource();
        roster.devices = [makeMouse()];

        const viewModel = makeViewModel(roster);

        compare(viewModel.emptyState, WirelessBatteryPopoutViewModel.EmptyState.None);
        compare(viewModel.emptyText, "");
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

        WirelessBatteryPopoutViewModel {}
    }
}
