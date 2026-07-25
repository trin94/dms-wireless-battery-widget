// SPDX-FileCopyrightText: Elias Mueller
//
// SPDX-License-Identifier: MIT

pragma ComponentBehavior: Bound

import QtQuick

WirelessBatterySource {
    id: root

    readonly property url helperUrl: Qt.resolvedUrl("../../steam_controller_helper.py")

    property int readingTimeoutMs: 15000

    readonly property Component _deviceFactory: Component {
        WirelessBatteryDevice {
            id: device

            readonly property Timer readingTimeout: Timer {
                interval: root.readingTimeoutMs
                onTriggered: device.live = false
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
                root._applyReading(device ?? root._bornDevice(event), event);
            break;
        case "connect":
            if (device) {
                device.live = true;
                device.readingTimeout.restart();
            }
            break;
        case "disconnect":
            if (device) {
                device.live = false;
                device.readingTimeout.stop();
            }
            break;
        case "removed":
            if (device) {
                root.devices = root.devices.filter(candidate => candidate !== device);
                device.destroy();
            }
            break;
        }
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

    function _bornDevice(event: var): var {
        const device = root._deviceFactory.createObject(root, {
            "deviceId": event.deviceId,
            "name": event.slot === 0 ? "Steam Controller" : `Steam Controller ${event.slot + 1}`
        });
        root.devices = [...root.devices, device];
        return device;
    }

    function _applyReading(device: var, event: var): void {
        device.level = event.level / 100;
        device.chargeState = root._chargeStateOf(event.state);
        device.live = true;
        device.readingTimeout.restart();
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
