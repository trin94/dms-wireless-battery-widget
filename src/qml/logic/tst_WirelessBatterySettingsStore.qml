// SPDX-FileCopyrightText: Elias Mueller
//
// SPDX-License-Identifier: MIT

import QtQuick
import QtTest

TestCase {
    id: testCase

    name: "WirelessBatterySettingsStore"

    readonly property string pluginId: "wirelessBatteryWidget"

    function makePluginService(data = {}): QtObject {
        const service = createTemporaryObject(pluginServiceFactory, testCase, {
            "data": data
        });
        verify(service);
        return service;
    }

    function makeStore(pluginService: QtObject): WirelessBatterySettingsStore {
        const store = createTemporaryObject(storeFactory, testCase, {
            "pluginId": testCase.pluginId,
            "pluginService": pluginService
        });
        verify(store);
        return store;
    }

    function test_defaultsWhenNothingStored() {
        const store = makeStore(makePluginService());

        compare(store.lowThresholds[WirelessBatteryDevice.DeviceClass.Mouse], 10);
        compare(store.lowThresholds[WirelessBatteryDevice.DeviceClass.Keyboard], 10);
        compare(store.lowThresholds[WirelessBatteryDevice.DeviceClass.Controller], 20);
        compare(store.lowThresholds[WirelessBatteryDevice.DeviceClass.Headset], 20);
    }

    function test_missingServiceFallsBackToDefaults() {
        const store = makeStore(null);

        compare(store.lowThresholds[WirelessBatteryDevice.DeviceClass.Mouse], 10);
    }

    function test_storedThresholdsOverrideDefaults() {
        const store = makeStore(makePluginService({
            [testCase.pluginId]: {
                "mouseLowThreshold": 33
            }
        }));

        compare(store.lowThresholds[WirelessBatteryDevice.DeviceClass.Mouse], 33);
        compare(store.lowThresholds[WirelessBatteryDevice.DeviceClass.Keyboard], 10);
    }

    function test_changesApplyLive() {
        const service = makePluginService();
        const store = makeStore(service);

        service.savePluginData(testCase.pluginId, "headsetLowThreshold", 42);

        compare(store.lowThresholds[WirelessBatteryDevice.DeviceClass.Headset], 42);
    }

    function test_otherPluginsDataIsIgnored() {
        const service = makePluginService();
        const store = makeStore(service);

        service.savePluginData("otherPlugin", "mouseLowThreshold", 99);

        compare(store.lowThresholds[WirelessBatteryDevice.DeviceClass.Mouse], 10);
    }

    Component {
        id: pluginServiceFactory

        QtObject {
            property var data: ({})

            signal pluginDataChanged(pluginId: string)

            function loadPluginData(pluginId: string, key: string, defaultValue) {
                return data[pluginId]?.[key] ?? defaultValue;
            }

            function savePluginData(pluginId: string, key: string, value): bool {
                const next = Object.assign({}, data);
                next[pluginId] = Object.assign({}, data[pluginId], {
                    [key]: value
                });
                data = next;
                pluginDataChanged(pluginId);
                return true;
            }
        }
    }

    Component {
        id: storeFactory

        WirelessBatterySettingsStore {}
    }
}
