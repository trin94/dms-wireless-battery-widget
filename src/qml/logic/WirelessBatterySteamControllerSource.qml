// SPDX-FileCopyrightText: Elias Mueller
//
// SPDX-License-Identifier: MIT

pragma ComponentBehavior: Bound

import QtQuick

WirelessBatterySource {
    id: root

    readonly property url helperUrl: Qt.resolvedUrl("../../steam_controller_helper.py")

    property int readingTimeoutMs: 15000

    // Ids of every device this source ever reported, so a withdrawal also
    // names devices that left on a "removed" event and only linger as
    // session memory downstream.
    property var _reportedDeviceIds: new Set()

    readonly property Component _deviceFactory: Component {
        WirelessBatteryDevice {
            id: device

            readonly property Timer _readingTimeout: Timer {
                interval: root.readingTimeoutMs
                onTriggered: device.expire()
            }

            function revive(): void {
                device.live = true;
                device._readingTimeout.restart();
            }

            function expire(): void {
                device.live = false;
                device._readingTimeout.stop();
            }

            deviceClass: WirelessBatteryDevice.DeviceClass.Controller
        }
    }

    function consumeLine(line: string): void {
        const event = root._parseLine(line);
        if (!event)
            return;
        const device = root.devices.find(candidate => candidate.deviceId === event.deviceId);
        switch (event.event) {
        case "battery":
            if (typeof event.level === "number")
                root._applyReading(device ?? root._createDevice(event), event);
            break;
        case "connect":
            device?.revive();
            break;
        case "disconnect":
            device?.expire();
            break;
        case "removed":
            if (device) {
                root.devices = root.devices.filter(candidate => candidate !== device);
                device.destroy();
            }
            break;
        }
    }

    function withdraw(): void {
        const withdrawn = [...root.devices];
        const deviceIds = [...root._reportedDeviceIds];
        if (deviceIds.length === 0)
            return;
        root._reportedDeviceIds = new Set();
        root.devices = [];
        for (const device of withdrawn)
            device.destroy();
        root.devicesWithdrawn(deviceIds);
    }

    function helperCommand(): var {
        return ["python3", decodeURIComponent(root.helperUrl.toString().replace(/^file:\/\//, ""))];
    }

    function _parseLine(line: string): var {
        let event = null;
        try {
            event = JSON.parse(line);
        } catch (error) {
            return null;
        }
        if (typeof event?.serial !== "string" || typeof event?.slot !== "number")
            return null;
        event.deviceId = `steam-controller:${event.serial}:${event.slot}`;
        return event;
    }

    function _createDevice(event: var): var {
        const device = root._deviceFactory.createObject(root, {
            "deviceId": event.deviceId,
            "name": event.slot === 0 ? "Steam Controller" : `Steam Controller ${event.slot + 1}`
        });
        root._reportedDeviceIds.add(event.deviceId);
        root.devices = [...root.devices, device];
        return device;
    }

    function _applyReading(device: var, event: var): void {
        device.level = event.level / 100;
        device.chargeState = root._chargeStateOf(event.state);
        device.revive();
    }

    function _chargeStateOf(state: string): int {
        switch (state) {
        case "charging":
            return WirelessBatteryDevice.ChargeState.Charging;
        case "chargingDone":
            return WirelessBatteryDevice.ChargeState.FullyCharged;
        default:
            return WirelessBatteryDevice.ChargeState.Discharging;
        }
    }
}
