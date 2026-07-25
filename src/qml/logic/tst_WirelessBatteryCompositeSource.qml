// SPDX-FileCopyrightText: Elias Mueller
//
// SPDX-License-Identifier: MIT

import QtQuick
import QtTest

TestCase {
    id: testCase

    name: "WirelessBatteryCompositeSource"

    function makeSource(): WirelessBatterySource {
        const source = createTemporaryObject(sourceFactory, testCase);
        verify(source);
        return source;
    }

    function makeDevice(deviceId: string): WirelessBatteryDevice {
        const device = createTemporaryObject(deviceFactory, testCase, {
            "deviceId": deviceId,
            "live": true
        });
        verify(device);
        return device;
    }

    function makeComposite(sources: var): WirelessBatteryCompositeSource {
        const composite = createTemporaryObject(compositeFactory, testCase, {
            "sources": sources
        });
        verify(composite);
        return composite;
    }

    function makeWithdrawnSpy(composite: WirelessBatteryCompositeSource): SignalSpy {
        const spy = createTemporaryObject(spyFactory, testCase, {
            "target": composite
        });
        verify(spy);
        return spy;
    }

    function test_mergesTheDevicesOfAllSources() {
        const upower = makeSource();
        upower.devices = [makeDevice("mouse-1")];
        const steam = makeSource();
        steam.devices = [makeDevice("steam-controller:serial:0")];

        const composite = makeComposite([upower, steam]);

        compare(composite.devices.map(device => device.deviceId), ["mouse-1", "steam-controller:serial:0"]);
    }

    function test_emptySourcesYieldNoDevices() {
        const composite = makeComposite([makeSource(), makeSource()]);

        compare(composite.devices.length, 0);
    }

    function test_followsDeviceListChangesOfEachSource() {
        const upower = makeSource();
        const steam = makeSource();
        const composite = makeComposite([upower, steam]);

        steam.devices = [makeDevice("steam-controller:serial:0")];

        compare(composite.devices.map(device => device.deviceId), ["steam-controller:serial:0"]);

        steam.devices = [];

        compare(composite.devices.length, 0);
    }

    function test_forwardsWithdrawalsFromEverySource() {
        const upower = makeSource();
        const steam = makeSource();
        const composite = makeComposite([upower, steam]);
        const spy = makeWithdrawnSpy(composite);

        steam.devicesWithdrawn(["steam-controller:serial:0", "steam-controller:serial:1"]);

        compare(spy.count, 1);
        compare(spy.signalArguments[0][0], ["steam-controller:serial:0", "steam-controller:serial:1"]);

        upower.devicesWithdrawn(["mouse-1"]);

        compare(spy.count, 2);
        compare(spy.signalArguments[1][0], ["mouse-1"]);
    }

    function test_replacedSourcesStopForwardingAndNewOnesStart() {
        const original = makeSource();
        const replacement = makeSource();
        const composite = makeComposite([original]);
        const spy = makeWithdrawnSpy(composite);

        composite.sources = [replacement];
        original.devicesWithdrawn(["mouse-1"]);

        compare(spy.count, 0);

        replacement.devicesWithdrawn(["mouse-2"]);

        compare(spy.count, 1);
        compare(spy.signalArguments[0][0], ["mouse-2"]);
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
        id: compositeFactory

        WirelessBatteryCompositeSource {}
    }

    Component {
        id: spyFactory

        SignalSpy {
            signalName: "devicesWithdrawn"
        }
    }
}
