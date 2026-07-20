// SPDX-FileCopyrightText: Elias Mueller
//
// SPDX-License-Identifier: MIT

import QtQuick
import QtTest

TestCase {
    id: testCase

    name: "WirelessBatteryTrackedClassFilter"

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

    function makeFilter(source: WirelessBatterySource, trackedClasses = undefined): WirelessBatteryTrackedClassFilter {
        const initProperties = {
            "source": source
        };
        if (trackedClasses !== undefined)
            initProperties.trackedClasses = trackedClasses;
        const filter = createTemporaryObject(filterFactory, testCase, initProperties);
        verify(filter);
        return filter;
    }

    function test_everyClassIsTrackedByDefault() {
        const source = makeSource();
        source.devices = [makeDevice({
                "deviceId": "mouse-1",
                "deviceClass": WirelessBatteryDevice.DeviceClass.Mouse
            }), makeDevice({
                "deviceId": "keyboard-1",
                "deviceClass": WirelessBatteryDevice.DeviceClass.Keyboard
            }), makeDevice({
                "deviceId": "controller-1",
                "deviceClass": WirelessBatteryDevice.DeviceClass.Controller
            }), makeDevice({
                "deviceId": "headset-1",
                "deviceClass": WirelessBatteryDevice.DeviceClass.Headset
            })];

        const filter = makeFilter(source);

        compare(filter.devices.length, 4);
    }

    function test_untrackedClassDeviceIsExcluded() {
        const source = makeSource();
        source.devices = [makeDevice({
                "deviceId": "mouse-1",
                "deviceClass": WirelessBatteryDevice.DeviceClass.Mouse
            }), makeDevice({
                "deviceId": "keyboard-1",
                "deviceClass": WirelessBatteryDevice.DeviceClass.Keyboard
            })];
        const trackedClasses = {};
        trackedClasses[WirelessBatteryDevice.DeviceClass.Mouse] = true;
        trackedClasses[WirelessBatteryDevice.DeviceClass.Keyboard] = false;

        const filter = makeFilter(source, trackedClasses);

        compare(filter.devices.map(device => device.deviceId), ["mouse-1"]);
    }

    function test_classMissingFromTheMapDefaultsToTracked() {
        const source = makeSource();
        source.devices = [makeDevice({
                "deviceId": "controller-1",
                "deviceClass": WirelessBatteryDevice.DeviceClass.Controller
            })];

        const filter = makeFilter(source, {});

        compare(filter.devices.length, 1);
    }

    function test_untrackingAClassLiveDropsItsDevices() {
        const source = makeSource();
        source.devices = [makeDevice({
                "deviceId": "mouse-1",
                "deviceClass": WirelessBatteryDevice.DeviceClass.Mouse
            }), makeDevice({
                "deviceId": "headset-1",
                "deviceClass": WirelessBatteryDevice.DeviceClass.Headset
            })];
        const filter = makeFilter(source);
        compare(filter.devices.length, 2);

        const trackedClasses = WirelessBatteryDefaults.trackedClasses(null);
        trackedClasses[WirelessBatteryDevice.DeviceClass.Headset] = false;
        filter.trackedClasses = trackedClasses;

        compare(filter.devices.map(device => device.deviceId), ["mouse-1"]);
    }

    function test_retrackingAClassBringsItsDevicesBack() {
        const source = makeSource();
        source.devices = [makeDevice({
                "deviceId": "headset-1",
                "deviceClass": WirelessBatteryDevice.DeviceClass.Headset
            })];
        const untracked = WirelessBatteryDefaults.trackedClasses(null);
        untracked[WirelessBatteryDevice.DeviceClass.Headset] = false;
        const filter = makeFilter(source, untracked);
        compare(filter.devices.length, 0);

        filter.trackedClasses = WirelessBatteryDefaults.trackedClasses(null);

        compare(filter.devices.map(device => device.deviceId), ["headset-1"]);
    }

    function test_staleDeviceOfAnUntrackedClassIsAlsoExcluded() {
        const source = makeSource();
        source.devices = [makeDevice({
                "deviceId": "mouse-1",
                "deviceClass": WirelessBatteryDevice.DeviceClass.Mouse,
                "live": false
            })];
        const untracked = WirelessBatteryDefaults.trackedClasses(null);
        untracked[WirelessBatteryDevice.DeviceClass.Mouse] = false;

        const filter = makeFilter(source, untracked);

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
        id: filterFactory

        WirelessBatteryTrackedClassFilter {}
    }
}
