// SPDX-FileCopyrightText: Elias Mueller
//
// SPDX-License-Identifier: MIT

import QtQuick

QtObject {
    id: root

    required property WirelessBatterySource source

    // One bar entry per device: key, iconName, percentText, showsBolt, tone.
    readonly property var entries: (root.source?.devices ?? []).filter(device => device.live).map(device => {
        const charging = device.chargeState !== WirelessBatteryDevice.ChargeState.Discharging;
        return {
            "key": device.deviceId,
            "iconName": root._iconName(device.deviceClass),
            "percentText": Math.round(device.level * 100) + "%",
            "showsBolt": charging,
            "tone": charging ? WirelessBatteryViewModel.Tone.Charging : WirelessBatteryViewModel.Tone.Normal
        };
    })

    enum Tone {
        Normal,
        Charging
    }

    function _iconName(deviceClass: int): string {
        return "mouse";
    }
}
