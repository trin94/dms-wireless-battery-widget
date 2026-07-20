// SPDX-FileCopyrightText: Elias Mueller
//
// SPDX-License-Identifier: MIT

import QtQuick
import QtTest

TestCase {
    id: testCase

    name: "WirelessBatteryMonitor"

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

    function makeMonitor(source: WirelessBatterySource): WirelessBatteryMonitor {
        const monitor = createTemporaryObject(monitorFactory, testCase, {
            "source": source
        });
        verify(monitor);
        return monitor;
    }

    function makeSpy(monitor: WirelessBatteryMonitor): SignalSpy {
        const spy = createTemporaryObject(spyFactory, testCase, {
            "target": monitor
        });
        verify(spy);
        return spy;
    }

    function makeDrainingMouse(level: real): WirelessBatteryDevice {
        return makeDevice({
            "deviceId": "mouse-1",
            "deviceClass": WirelessBatteryDevice.DeviceClass.Mouse,
            "name": "MX Master 3S",
            "level": level,
            "chargeState": WirelessBatteryDevice.ChargeState.Discharging,
            "live": true
        });
    }

    function test_crossingThresholdWhileDrainingFiresOnceWithNameAndPercent() {
        const source = makeSource();
        const device = makeDrainingMouse(0.5);
        source.devices = [device];
        const monitor = makeMonitor(source);
        const spy = makeSpy(monitor);

        device.level = 0.1;
        wait(0);

        compare(spy.count, 1);
        compare(spy.signalArguments[0][0], "MX Master 3S");
        compare(spy.signalArguments[0][1], 10);

        device.level = 0.08;
        wait(0);

        compare(spy.count, 1);
    }

    function test_deviceFirstSeenLowNotifies() {
        const source = makeSource();
        const monitor = makeMonitor(source);
        const spy = makeSpy(monitor);

        source.devices = [makeDrainingMouse(0.08)];
        wait(0);

        compare(spy.count, 1);
        compare(spy.signalArguments[0][1], 8);
    }

    function test_hoveringAtThresholdDoesNotSpam() {
        const source = makeSource();
        const device = makeDrainingMouse(0.5);
        source.devices = [device];
        const monitor = makeMonitor(source);
        const spy = makeSpy(monitor);

        device.level = 0.1;
        wait(0);
        device.level = 0.12;
        wait(0);
        device.level = 0.09;
        wait(0);

        compare(spy.count, 1);
    }

    function test_recoveryPastThresholdPlusMarginRearms() {
        const source = makeSource();
        const device = makeDrainingMouse(0.5);
        source.devices = [device];
        const monitor = makeMonitor(source);
        const spy = makeSpy(monitor);

        device.level = 0.1;
        wait(0);
        device.level = 0.16;
        wait(0);
        device.level = 0.1;
        wait(0);

        compare(spy.count, 2);
    }

    function test_chargingDeviceNeverNotifies() {
        const source = makeSource();
        const device = makeDevice({
            "deviceId": "mouse-1",
            "deviceClass": WirelessBatteryDevice.DeviceClass.Mouse,
            "name": "MX Master 3S",
            "level": 0.5,
            "chargeState": WirelessBatteryDevice.ChargeState.Charging,
            "live": true
        });
        source.devices = [device];
        const monitor = makeMonitor(source);
        const spy = makeSpy(monitor);

        device.level = 0.05;
        wait(0);
        compare(spy.count, 0);

        device.chargeState = WirelessBatteryDevice.ChargeState.Discharging;
        wait(0);
        compare(spy.count, 1);
    }

    function test_staleDeviceNeverNotifies() {
        const source = makeSource();
        const device = makeDrainingMouse(0.5);
        source.devices = [device];
        const monitor = makeMonitor(source);
        const spy = makeSpy(monitor);

        device.live = false;
        wait(0);
        device.level = 0.05;
        wait(0);

        compare(spy.count, 0);
    }

    function test_thresholdsFollowDeviceClass() {
        const source = makeSource();
        const controller = makeDevice({
            "deviceId": "controller-1",
            "deviceClass": WirelessBatteryDevice.DeviceClass.Controller,
            "name": "DualSense",
            "level": 0.5,
            "chargeState": WirelessBatteryDevice.ChargeState.Discharging,
            "live": true
        });
        const mouse = makeDrainingMouse(0.5);
        source.devices = [controller, mouse];
        const monitor = makeMonitor(source);
        const spy = makeSpy(monitor);

        controller.level = 0.15;
        mouse.level = 0.15;
        wait(0);

        compare(spy.count, 1);
        compare(spy.signalArguments[0][0], "DualSense");
    }

    function test_devicesArmIndependently() {
        const source = makeSource();
        const mouseA = makeDrainingMouse(0.5);
        const mouseB = makeDevice({
            "deviceId": "mouse-2",
            "deviceClass": WirelessBatteryDevice.DeviceClass.Mouse,
            "name": "Pro Click",
            "level": 0.5,
            "chargeState": WirelessBatteryDevice.ChargeState.Discharging,
            "live": true
        });
        source.devices = [mouseA, mouseB];
        const monitor = makeMonitor(source);
        const spy = makeSpy(monitor);

        mouseA.level = 0.1;
        wait(0);
        mouseB.level = 0.1;
        wait(0);

        compare(spy.count, 2);
        compare(spy.signalArguments[0][0], "MX Master 3S");
        compare(spy.signalArguments[1][0], "Pro Click");
    }

    function test_raisingThresholdPastCurrentReadingNotifies() {
        const source = makeSource();
        const device = makeDrainingMouse(0.3);
        source.devices = [device];
        const monitor = makeMonitor(source);
        const spy = makeSpy(monitor);
        wait(0);
        compare(spy.count, 0);

        const thresholds = {};
        thresholds[WirelessBatteryDevice.DeviceClass.Mouse] = 50;
        monitor.lowThresholds = thresholds;
        wait(0);

        compare(spy.count, 1);
        compare(spy.signalArguments[0][1], 30);
    }

    function test_customThresholdsOverrideDefaults() {
        const source = makeSource();
        const device = makeDrainingMouse(0.5);
        source.devices = [device];
        const monitor = makeMonitor(source);
        const thresholds = {};
        thresholds[WirelessBatteryDevice.DeviceClass.Mouse] = 50;
        monitor.lowThresholds = thresholds;
        const spy = makeSpy(monitor);

        device.level = 0.4;
        wait(0);

        compare(spy.count, 1);
        compare(spy.signalArguments[0][1], 40);
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
        id: monitorFactory

        WirelessBatteryMonitor {}
    }

    Component {
        id: spyFactory

        SignalSpy {
            signalName: "lowReading"
        }
    }
}
