// SPDX-FileCopyrightText: Elias Mueller
//
// SPDX-License-Identifier: MIT

import QtQuick

QtObject {
    id: root

    required property WirelessBatterySource source

    // One bar entry per device: key, iconName, percentText, showsBolt, tone.
    // Fixed order: mouse, keyboard, controller, headset; name as tiebreak.
    readonly property var entries: WirelessBatteryFixedOrder.sorted(root.source?.devices ?? []).map(device => {
        const percent = Math.round(device.level * 100);
        const charging = device.live && device.chargeState !== WirelessBatteryDevice.ChargeState.Discharging;
        const low = !charging && percent <= (root.lowThresholds[device.deviceClass] ?? -1);
        return {
            "key": device.deviceId,
            "iconName": root._iconName(device.deviceClass),
            "percentText": percent + "%",
            "showsBolt": charging,
            "tone": root._tone(device.live, charging, low)
        };
    })

    property var lowThresholds: WirelessBatteryDefaults.lowThresholds(null)

    enum Tone {
        Normal,
        Charging,
        Stale,
        Low
    }

    function _tone(live: bool, charging: bool, low: bool): int {
        if (!live)
            return WirelessBatteryViewModel.Tone.Stale;
        if (charging)
            return WirelessBatteryViewModel.Tone.Charging;
        return low ? WirelessBatteryViewModel.Tone.Low : WirelessBatteryViewModel.Tone.Normal;
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
