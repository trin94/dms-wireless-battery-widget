// SPDX-FileCopyrightText: Elias Mueller
//
// SPDX-License-Identifier: MIT

import QtQuick

QtObject {
    id: root

    required property WirelessBatterySource source

    // One bar entry per device: key, iconName, percentText, verticalPercentText,
    // showsBolt, tone. Vertical bars drop the percent sign to fit their width.
    // Fixed order: mouse, keyboard, controller, headset; name as tiebreak.
    readonly property var entries: WirelessBatteryFixedOrder.sorted(root.source?.devices ?? []).map(device => {
        const percent = Math.round(device.level * 100);
        const tone = WirelessBatteryTone.forDevice(device, root.lowThresholds);
        return {
            "key": device.deviceId,
            "iconName": WirelessBatteryClassIcon.forClass(device.deviceClass),
            "percentText": percent + "%",
            "verticalPercentText": percent.toString(),
            "showsBolt": tone === WirelessBatteryTone.Tone.Charging,
            "tone": tone
        };
    })

    property var lowThresholds: WirelessBatteryDefaults.lowThresholds(null)
}
