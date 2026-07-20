// SPDX-FileCopyrightText: Elias Mueller
//
// SPDX-License-Identifier: MIT

import QtQml

import Quickshell.Services.UPower

WirelessBatterySource {
    id: root

    readonly property Connections _upowerWatcher: Connections {
        target: UPower.devices

        function onValuesChanged() {
            root._syncDevices();
        }
    }

    readonly property Component _deviceFactory: Component {
        WirelessBatteryDevice {
            required property UPowerDevice upowerDevice

            deviceId: upowerDevice.nativePath
            deviceClass: root._deviceClassOf(upowerDevice.type)
            name: upowerDevice.model
            level: upowerDevice.percentage
            chargeState: {
                if (upowerDevice.state === UPowerDeviceState.FullyCharged)
                    return WirelessBatteryDevice.ChargeState.FullyCharged;
                if (upowerDevice.state === UPowerDeviceState.Charging || upowerDevice.state === UPowerDeviceState.PendingCharge)
                    return WirelessBatteryDevice.ChargeState.Charging;
                return WirelessBatteryDevice.ChargeState.Discharging;
            }
            live: upowerDevice.ready && upowerDevice.state !== UPowerDeviceState.Unknown && upowerDevice.percentage > 0
        }
    }

    function _deviceClassOf(type: int): int {
        return type === UPowerDeviceType.Mouse ? WirelessBatteryDevice.DeviceClass.Mouse : -1;
    }

    function _syncDevices(): void {
        const tracked = UPower.devices.values.filter(upowerDevice => root._deviceClassOf(upowerDevice.type) >= 0);
        const next = tracked.map(upowerDevice => root.devices.find(device => device.upowerDevice === upowerDevice) ?? root._deviceFactory.createObject(root, {
                "upowerDevice": upowerDevice
            }));
        for (const device of root.devices) {
            if (!next.includes(device))
                device.destroy();
        }
        root.devices = next;
    }

    Component.onCompleted: _syncDevices()
}
