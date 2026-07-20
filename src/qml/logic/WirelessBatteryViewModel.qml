// SPDX-FileCopyrightText: Elias Mueller
//
// SPDX-License-Identifier: MIT

import QtQuick

QtObject {
    id: root

    required property WirelessBatterySource source

    // One bar entry per device: key, iconName, percentText, showsBolt, tone.
    // Fixed order: mouse, keyboard, controller, headset; name as tiebreak.
    readonly property var entries: (root.source?.devices ?? []).slice().sort((left, right) => left.deviceClass - right.deviceClass || left.name.localeCompare(right.name) || left.deviceId.localeCompare(right.deviceId)).map(device => {
        const charging = device.live && device.chargeState !== WirelessBatteryDevice.ChargeState.Discharging;
        return {
            "key": device.deviceId,
            "iconName": root._iconName(device.deviceClass),
            "percentText": Math.round(device.level * 100) + "%",
            "showsBolt": charging,
            "tone": root._tone(device.live, charging)
        };
    })

    enum Tone {
        Normal,
        Charging,
        Stale
    }

    function _tone(live: bool, charging: bool): int {
        if (!live)
            return WirelessBatteryViewModel.Tone.Stale;
        return charging ? WirelessBatteryViewModel.Tone.Charging : WirelessBatteryViewModel.Tone.Normal;
    }

    function _iconName(deviceClass: int): string {
        switch (deviceClass) {
        case WirelessBatteryDevice.DeviceClass.Keyboard:
            return "keyboard";
        case WirelessBatteryDevice.DeviceClass.Controller:
            return "sports_esports";
        case WirelessBatteryDevice.DeviceClass.Headset:
            return "headset";
        default:
            return "mouse";
        }
    }
}
