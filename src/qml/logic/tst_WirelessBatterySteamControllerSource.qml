// SPDX-FileCopyrightText: Elias Mueller
//
// SPDX-License-Identifier: MIT

import QtQuick
import QtTest

TestCase {
    id: testCase

    name: "WirelessBatterySteamControllerSource"

    function makeSource(initProperties = {}): WirelessBatterySteamControllerSource {
        const source = createTemporaryObject(sourceFactory, testCase, initProperties);
        verify(source);
        return source;
    }

    function makeWithdrawnSpy(source: WirelessBatterySteamControllerSource): SignalSpy {
        const spy = createTemporaryObject(spyFactory, testCase, {
            "target": source
        });
        verify(spy);
        return spy;
    }

    function feed(source: WirelessBatterySteamControllerSource, event: var) {
        source.consumeLine(JSON.stringify(event));
    }

    function feedBattery(source: WirelessBatterySteamControllerSource, overrides = {}) {
        testCase.feed(source, Object.assign({
            "event": "battery",
            "level": 78,
            "state": "discharging",
            "serial": "FXB995480177F",
            "slot": 0
        }, overrides));
    }

    function test_deviceIsBornOnFirstReading() {
        const source = makeSource();

        testCase.feedBattery(source);

        compare(source.devices.length, 1);
        const device = source.devices[0];
        compare(device.deviceId, "steam-controller:FXB995480177F:0");
        compare(device.deviceClass, WirelessBatteryDevice.DeviceClass.Controller);
        compare(device.name, "Steam Controller");
        compare(device.level, 0.78);
        compare(device.chargeState, WirelessBatteryDevice.ChargeState.Discharging);
        verify(device.live);
    }

    function test_readingCarriesNoTimeEstimate() {
        const source = makeSource();

        testCase.feedBattery(source);

        compare(source.devices[0].timeToEmpty, 0);
        compare(source.devices[0].timeToFull, 0);
    }

    function test_connectAloneCreatesNothing() {
        const source = makeSource();

        testCase.feed(source, {
            "event": "connect",
            "serial": "FXB995480177F",
            "slot": 0
        });

        compare(source.devices.length, 0);
    }

    function test_eventsForUnknownDevicesCreateNothing() {
        const source = makeSource();

        for (const event of ["disconnect", "removed"]) {
            testCase.feed(source, {
                "event": event,
                "serial": "FXB995480177F",
                "slot": 0
            });
        }

        compare(source.devices.length, 0);
    }

    function test_malformedLinesAreIgnored() {
        const source = makeSource();

        source.consumeLine("");
        source.consumeLine("not json");
        source.consumeLine("{\"event\": \"battery\", \"level\": 50, \"state\": \"discharging\"}");

        compare(source.devices.length, 0);
    }

    function test_chargeStateMapping_data() {
        return [
            {
                tag: "discharging",
                state: "discharging",
                expected: WirelessBatteryDevice.ChargeState.Discharging
            },
            {
                tag: "charging",
                state: "charging",
                expected: WirelessBatteryDevice.ChargeState.Charging
            },
            {
                tag: "chargingDone",
                state: "chargingDone",
                expected: WirelessBatteryDevice.ChargeState.FullyCharged
            },
            {
                tag: "srcValidate",
                state: "srcValidate",
                expected: WirelessBatteryDevice.ChargeState.Discharging
            },
            {
                tag: "reset",
                state: "reset",
                expected: WirelessBatteryDevice.ChargeState.Discharging
            },
            {
                tag: "unknown",
                state: "unknown",
                expected: WirelessBatteryDevice.ChargeState.Discharging
            }
        ];
    }

    function test_chargeStateMapping(data) {
        const source = makeSource();

        testCase.feedBattery(source, {
            "state": data.state
        });

        compare(source.devices[0].chargeState, data.expected);
    }

    function test_freshReadingUpdatesTheDevice() {
        const source = makeSource();
        testCase.feedBattery(source);

        testCase.feedBattery(source, {
            "level": 55,
            "state": "charging"
        });

        compare(source.devices.length, 1);
        compare(source.devices[0].level, 0.55);
        compare(source.devices[0].chargeState, WirelessBatteryDevice.ChargeState.Charging);
    }

    function test_disconnectEndsLivenessImmediately() {
        const source = makeSource();
        testCase.feedBattery(source);

        testCase.feed(source, {
            "event": "disconnect",
            "serial": "FXB995480177F",
            "slot": 0
        });

        compare(source.devices.length, 1);
        verify(!source.devices[0].live);
        compare(source.devices[0].level, 0.78);
    }

    function test_connectRevivesTheDeviceAtItsLastReading() {
        const source = makeSource();
        testCase.feedBattery(source);
        testCase.feed(source, {
            "event": "disconnect",
            "serial": "FXB995480177F",
            "slot": 0
        });

        testCase.feed(source, {
            "event": "connect",
            "serial": "FXB995480177F",
            "slot": 0
        });

        verify(source.devices[0].live);
        compare(source.devices[0].level, 0.78);
    }

    function test_readingOlderThanTimeoutEndsLiveness() {
        const source = makeSource({
            "readingTimeoutMs": 50
        });

        testCase.feedBattery(source);

        verify(source.devices[0].live);
        tryVerify(() => !source.devices[0].live);
    }

    function test_freshReadingRestartsTheTimeout() {
        const source = makeSource({
            "readingTimeoutMs": 400
        });

        testCase.feedBattery(source);
        wait(250);
        testCase.feedBattery(source);
        wait(250);

        verify(source.devices[0].live);
    }

    function test_timeoutArmsAgainAfterConnect() {
        const source = makeSource({
            "readingTimeoutMs": 50
        });
        testCase.feedBattery(source);
        tryVerify(() => !source.devices[0].live);

        testCase.feed(source, {
            "event": "connect",
            "serial": "FXB995480177F",
            "slot": 0
        });

        verify(source.devices[0].live);
        tryVerify(() => !source.devices[0].live);
    }

    function test_identityIsStableAcrossReplugs() {
        const source = makeSource();
        const spy = makeWithdrawnSpy(source);
        testCase.feedBattery(source);
        const deviceId = source.devices[0].deviceId;

        testCase.feed(source, {
            "event": "removed",
            "serial": "FXB995480177F",
            "slot": 0
        });
        compare(source.devices.length, 0);
        testCase.feedBattery(source, {
            "level": 42
        });

        compare(source.devices.length, 1);
        compare(source.devices[0].deviceId, deviceId);
        compare(source.devices[0].level, 0.42);
        compare(spy.count, 0);
    }

    function test_secondSlotGetsANumberedName() {
        const source = makeSource();

        testCase.feedBattery(source);
        testCase.feedBattery(source, {
            "slot": 1
        });

        compare(source.devices.map(device => device.name), ["Steam Controller", "Steam Controller 2"]);
        verify(source.devices[0].deviceId !== source.devices[1].deviceId);
    }

    function test_controllersLiveIndependently() {
        const source = makeSource();
        testCase.feedBattery(source);
        testCase.feedBattery(source, {
            "slot": 1
        });

        testCase.feed(source, {
            "event": "disconnect",
            "serial": "FXB995480177F",
            "slot": 0
        });

        verify(!source.devices[0].live);
        verify(source.devices[1].live);
    }

    function test_removalLeavesOtherControllersTracked() {
        const source = makeSource();
        testCase.feedBattery(source);
        testCase.feedBattery(source, {
            "slot": 1
        });

        testCase.feed(source, {
            "event": "removed",
            "serial": "FXB995480177F",
            "slot": 0
        });

        compare(source.devices.length, 1);
        compare(source.devices[0].name, "Steam Controller 2");
        verify(source.devices[0].live);
    }

    Component {
        id: sourceFactory

        WirelessBatterySteamControllerSource {}
    }

    Component {
        id: spyFactory

        SignalSpy {
            signalName: "devicesWithdrawn"
        }
    }
}
