// SPDX-FileCopyrightText: Elias Mueller
//
// SPDX-License-Identifier: MIT

import QtQuick
import QtTest

TestCase {
    id: testCase

    name: "WirelessBatteryRetainedClassFilter"

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

    function makeFilter(source: WirelessBatterySource, retainedClasses = undefined): WirelessBatteryRetainedClassFilter {
        const initProperties = {
            "source": source
        };
        if (retainedClasses !== undefined)
            initProperties.retainedClasses = retainedClasses;
        const filter = createTemporaryObject(filterFactory, testCase, initProperties);
        verify(filter);
        return filter;
    }

    function test_liveDeviceOfANonRetainedClassPasses() {
        const source = makeSource();
        source.devices = [makeDevice({
                "deviceId": "headset-1",
                "deviceClass": WirelessBatteryDevice.DeviceClass.Headset,
                "live": true
            })];

        const filter = makeFilter(source);

        compare(filter.devices.map(device => device.deviceId), ["headset-1"]);
    }

    function test_notLiveDeviceOfANonRetainedClassIsExcluded() {
        const source = makeSource();
        source.devices = [makeDevice({
                "deviceId": "headset-1",
                "deviceClass": WirelessBatteryDevice.DeviceClass.Headset,
                "live": false
            }), makeDevice({
                "deviceId": "controller-1",
                "deviceClass": WirelessBatteryDevice.DeviceClass.Controller,
                "live": false
            })];

        const filter = makeFilter(source);

        compare(filter.devices.length, 0);
    }

    function test_notLiveDeviceOfARetainedClassPasses() {
        const source = makeSource();
        source.devices = [makeDevice({
                "deviceId": "mouse-1",
                "deviceClass": WirelessBatteryDevice.DeviceClass.Mouse,
                "live": false
            }), makeDevice({
                "deviceId": "keyboard-1",
                "deviceClass": WirelessBatteryDevice.DeviceClass.Keyboard,
                "live": false
            })];

        const filter = makeFilter(source);

        compare(filter.devices.map(device => device.deviceId), ["mouse-1", "keyboard-1"]);
    }

    function test_classMissingFromTheMapCountsAsRetained() {
        const source = makeSource();
        source.devices = [makeDevice({
                "deviceId": "controller-1",
                "deviceClass": WirelessBatteryDevice.DeviceClass.Controller,
                "live": false
            })];

        const filter = makeFilter(source, {});

        compare(filter.devices.length, 1);
    }

    function test_droppingRetentionRemovesAStaleDevice() {
        const source = makeSource();
        source.devices = [makeDevice({
                "deviceId": "mouse-1",
                "deviceClass": WirelessBatteryDevice.DeviceClass.Mouse,
                "live": false
            })];
        const filter = makeFilter(source);
        compare(filter.devices.length, 1);

        const retainedClasses = WirelessBatteryDefaults.retainedClasses(null);
        retainedClasses[WirelessBatteryDevice.DeviceClass.Mouse] = false;
        filter.retainedClasses = retainedClasses;

        compare(filter.devices.length, 0);
    }

    function test_grantingRetentionMakesAStaleDeviceReappear() {
        const source = makeSource();
        source.devices = [makeDevice({
                "deviceId": "headset-1",
                "deviceClass": WirelessBatteryDevice.DeviceClass.Headset,
                "live": false
            })];
        const filter = makeFilter(source);
        compare(filter.devices.length, 0);

        const retainedClasses = WirelessBatteryDefaults.retainedClasses(null);
        retainedClasses[WirelessBatteryDevice.DeviceClass.Headset] = true;
        filter.retainedClasses = retainedClasses;

        compare(filter.devices.map(device => device.deviceId), ["headset-1"]);
    }

    function test_excludedDeviceReappearsWhenItGoesLiveAgain() {
        const source = makeSource();
        const headset = makeDevice({
            "deviceId": "headset-1",
            "deviceClass": WirelessBatteryDevice.DeviceClass.Headset,
            "live": false
        });
        source.devices = [headset];
        const filter = makeFilter(source);
        compare(filter.devices.length, 0);

        headset.live = true;

        compare(filter.devices.map(device => device.deviceId), ["headset-1"]);
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
        id: filterFactory

        WirelessBatteryRetainedClassFilter {}
    }
}
