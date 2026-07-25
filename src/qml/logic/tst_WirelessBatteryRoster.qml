// SPDX-FileCopyrightText: Elias Mueller
//
// SPDX-License-Identifier: MIT

import QtQuick
import QtTest

TestCase {
    id: testCase

    name: "WirelessBatteryRoster"

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

    function makeRoster(source: WirelessBatterySource): WirelessBatteryRoster {
        const roster = createTemporaryObject(rosterFactory, testCase, {
            "source": source
        });
        verify(roster);
        return roster;
    }

    function makeRetainedFilter(source: WirelessBatterySource, retainedClasses): WirelessBatteryRetainedClassFilter {
        const filter = createTemporaryObject(retainedFilterFactory, testCase, {
            "source": source,
            "retainedClasses": retainedClasses
        });
        verify(filter);
        return filter;
    }

    function test_liveDeviceIsTracked() {
        const source = makeSource();
        source.devices = [makeDevice({
                "deviceId": "mouse-1",
                "deviceClass": WirelessBatteryDevice.DeviceClass.Mouse,
                "name": "MX Master 3S",
                "level": 0.75,
                "chargeState": WirelessBatteryDevice.ChargeState.Discharging,
                "timeToEmpty": 7200,
                "timeToFull": 1800,
                "live": true
            })];

        const roster = makeRoster(source);

        compare(roster.devices.length, 1);
        compare(roster.devices[0].deviceId, "mouse-1");
        compare(roster.devices[0].deviceClass, WirelessBatteryDevice.DeviceClass.Mouse);
        compare(roster.devices[0].name, "MX Master 3S");
        compare(roster.devices[0].level, 0.75);
        compare(roster.devices[0].chargeState, WirelessBatteryDevice.ChargeState.Discharging);
        compare(roster.devices[0].timeToEmpty, 7200);
        compare(roster.devices[0].timeToFull, 1800);
        compare(roster.devices[0].live, true);
    }

    function test_neverLiveDeviceIsNotTracked() {
        const source = makeSource();
        source.devices = [makeDevice({
                "deviceId": "mouse-1",
                "deviceClass": WirelessBatteryDevice.DeviceClass.Mouse,
                "level": 0,
                "live": false
            })];

        const roster = makeRoster(source);

        compare(roster.devices.length, 0);
    }

    function test_readingChangesFollowWhileLive() {
        const source = makeSource();
        const device = makeDevice({
            "deviceId": "mouse-1",
            "deviceClass": WirelessBatteryDevice.DeviceClass.Mouse,
            "level": 0.75,
            "chargeState": WirelessBatteryDevice.ChargeState.Discharging,
            "live": true
        });
        source.devices = [device];
        const roster = makeRoster(source);

        device.level = 0.42;
        device.chargeState = WirelessBatteryDevice.ChargeState.Charging;
        device.timeToFull = 900;
        wait(0);

        compare(roster.devices[0].level, 0.42);
        compare(roster.devices[0].chargeState, WirelessBatteryDevice.ChargeState.Charging);
        compare(roster.devices[0].timeToFull, 900);
    }

    function test_deviceNoLongerLiveIsStaleAtLastReading() {
        const source = makeSource();
        const device = makeDevice({
            "deviceId": "mouse-1",
            "deviceClass": WirelessBatteryDevice.DeviceClass.Mouse,
            "level": 0.75,
            "live": true
        });
        source.devices = [device];
        const roster = makeRoster(source);

        device.live = false;
        wait(0);
        device.level = 0;
        wait(0);

        compare(roster.devices.length, 1);
        compare(roster.devices[0].live, false);
        compare(roster.devices[0].level, 0.75);
    }

    function test_readingNoiseWhileGoingStaleIsNotCaptured() {
        const source = makeSource();
        const device = makeDevice({
            "deviceId": "mouse-1",
            "deviceClass": WirelessBatteryDevice.DeviceClass.Mouse,
            "level": 0.75,
            "chargeState": WirelessBatteryDevice.ChargeState.Charging,
            "live": true
        });
        source.devices = [device];
        const roster = makeRoster(source);

        device.level = 0;
        device.chargeState = WirelessBatteryDevice.ChargeState.Discharging;
        device.live = false;
        wait(0);

        compare(roster.devices.length, 1);
        compare(roster.devices[0].live, false);
        compare(roster.devices[0].level, 0.75);
        compare(roster.devices[0].chargeState, WirelessBatteryDevice.ChargeState.Charging);
    }

    function test_droppedDeviceIsStaleAtLastReading() {
        const source = makeSource();
        source.devices = [makeDevice({
                "deviceId": "mouse-1",
                "deviceClass": WirelessBatteryDevice.DeviceClass.Mouse,
                "level": 0.75,
                "live": true
            })];
        const roster = makeRoster(source);

        source.devices = [];
        wait(0);

        compare(roster.devices.length, 1);
        compare(roster.devices[0].live, false);
        compare(roster.devices[0].level, 0.75);
    }

    function test_staleDeviceGoingLiveAgainShowsLiveData() {
        const source = makeSource();
        const device = makeDevice({
            "deviceId": "mouse-1",
            "deviceClass": WirelessBatteryDevice.DeviceClass.Mouse,
            "level": 0.75,
            "live": true
        });
        source.devices = [device];
        const roster = makeRoster(source);
        device.live = false;
        wait(0);
        compare(roster.devices[0].live, false);

        device.level = 0.6;
        device.live = true;
        wait(0);

        compare(roster.devices.length, 1);
        compare(roster.devices[0].live, true);
        compare(roster.devices[0].level, 0.6);
    }

    function test_droppedDeviceReturningGoesLiveAgain() {
        const source = makeSource();
        source.devices = [makeDevice({
                "deviceId": "mouse-1",
                "deviceClass": WirelessBatteryDevice.DeviceClass.Mouse,
                "level": 0.75,
                "live": true
            })];
        const roster = makeRoster(source);
        source.devices = [];
        wait(0);
        compare(roster.devices[0].live, false);

        source.devices = [makeDevice({
                "deviceId": "mouse-1",
                "deviceClass": WirelessBatteryDevice.DeviceClass.Mouse,
                "level": 0.2,
                "live": true
            })];
        wait(0);

        compare(roster.devices.length, 1);
        compare(roster.devices[0].live, true);
        compare(roster.devices[0].level, 0.2);
    }

    function test_devicesAppearingLaterAreTracked() {
        const source = makeSource();
        const roster = makeRoster(source);

        source.devices = [makeDevice({
                "deviceId": "keyboard-1",
                "deviceClass": WirelessBatteryDevice.DeviceClass.Keyboard,
                "level": 0.5,
                "live": true
            })];
        wait(0);

        compare(roster.devices.length, 1);
        compare(roster.devices[0].deviceId, "keyboard-1");
        compare(roster.devices[0].live, true);
    }

    function test_removedSourceDeviceIsForgotten() {
        const source = makeSource();
        source.devices = [makeDevice({
                "deviceId": "controller-1",
                "deviceClass": WirelessBatteryDevice.DeviceClass.Controller,
                "level": 0.75,
                "live": true
            })];
        const roster = makeRoster(source);
        compare(roster.devices.length, 1);

        source.devices = [];
        source.devicesWithdrawn(["controller-1"]);
        wait(0);

        compare(roster.devices.length, 0);
    }

    function test_removedSourceStaleDeviceIsForgotten() {
        const source = makeSource();
        const device = makeDevice({
            "deviceId": "controller-1",
            "deviceClass": WirelessBatteryDevice.DeviceClass.Controller,
            "level": 0.75,
            "live": true
        });
        source.devices = [device];
        const roster = makeRoster(source);
        device.live = false;
        wait(0);
        compare(roster.devices.length, 1);

        source.devices = [];
        source.devicesWithdrawn(["controller-1"]);
        wait(0);

        compare(roster.devices.length, 0);
    }

    function test_removedSourceLeavesOtherDevicesTracked() {
        const source = makeSource();
        const mouse = makeDevice({
            "deviceId": "mouse-1",
            "deviceClass": WirelessBatteryDevice.DeviceClass.Mouse,
            "level": 0.5,
            "live": true
        });
        source.devices = [mouse, makeDevice({
                "deviceId": "controller-1",
                "deviceClass": WirelessBatteryDevice.DeviceClass.Controller,
                "level": 0.75,
                "live": true
            })];
        const roster = makeRoster(source);
        compare(roster.devices.length, 2);

        source.devices = [mouse];
        source.devicesWithdrawn(["controller-1"]);
        wait(0);

        compare(roster.devices.map(device => device.deviceId), ["mouse-1"]);
        compare(roster.devices[0].live, true);
    }

    function test_forgottenDeviceDoesNotReappearWhenRetentionIsGranted() {
        const source = makeSource();
        const device = makeDevice({
            "deviceId": "controller-1",
            "deviceClass": WirelessBatteryDevice.DeviceClass.Controller,
            "level": 0.75,
            "live": true
        });
        source.devices = [device];
        const roster = makeRoster(source);
        const retainedClasses = WirelessBatteryDefaults.retainedClasses(null);
        retainedClasses[WirelessBatteryDevice.DeviceClass.Controller] = false;
        const filter = makeRetainedFilter(roster, retainedClasses);
        device.live = false;
        wait(0);
        compare(filter.devices.length, 0);
        compare(roster.devices.length, 1);

        source.devices = [];
        source.devicesWithdrawn(["controller-1"]);
        wait(0);

        const grantedClasses = WirelessBatteryDefaults.retainedClasses(null);
        grantedClasses[WirelessBatteryDevice.DeviceClass.Controller] = true;
        filter.retainedClasses = grantedClasses;

        compare(filter.devices.length, 0);
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
        id: retainedFilterFactory

        WirelessBatteryRetainedClassFilter {}
    }
}
