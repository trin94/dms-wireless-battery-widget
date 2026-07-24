// SPDX-FileCopyrightText: Elias Mueller
//
// SPDX-License-Identifier: MIT

import QtQuick

QtObject {
    id: root

    required property WirelessBatterySource source

    // One bar entry per device: key, iconName, percentText, verticalPercentText,
    // showsPercent, showsBolt, tone. Vertical bars drop the percent sign to
    // fit their width. Fixed order: mouse, keyboard, controller, headset;
    // name as tiebreak.
    readonly property var entries: {
        const devices = WirelessBatteryFixedOrder.sorted(root.source?.devices ?? []);
        if (devices.length === 0)
            return root.showsPlaceholder ? [root._placeholder] : [];
        return devices.map(device => {
            const percent = Math.round(device.level * 100);
            const tone = WirelessBatteryTone.forDevice(device, root.lowThresholds);
            return {
                "key": device.deviceId,
                "iconName": WirelessBatteryClassIcon.forClass(device.deviceClass),
                "percentText": percent + "%",
                "verticalPercentText": percent.toString(),
                "showsPercent": true,
                "showsBolt": tone === WirelessBatteryTone.Tone.Charging,
                "tone": tone
            };
        });
    }

    property var lowThresholds: WirelessBatteryDefaults.lowThresholds(null)
    property bool showsPlaceholder: WirelessBatteryDefaults.showPlaceholder

    readonly property var _placeholder: ({
            "key": "placeholder",
            "iconName": "battery_unknown",
            "percentText": "",
            "verticalPercentText": "",
            "showsPercent": false,
            "showsBolt": false,
            "tone": WirelessBatteryTone.Tone.Stale
        })
}
