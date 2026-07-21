// SPDX-FileCopyrightText: Elias Mueller
//
// SPDX-License-Identifier: MIT

pragma Singleton

import QtQuick

// The at-a-glance coloring of a tracked device's entry.
QtObject {
    enum Tone {
        Normal,
        Charging,
        Stale,
        Low
    }

    function forDevice(device: WirelessBatteryDevice, lowThresholds: var): int {
        if (!device.live)
            return WirelessBatteryTone.Tone.Stale;
        if (device.chargeState !== WirelessBatteryDevice.ChargeState.Discharging)
            return WirelessBatteryTone.Tone.Charging;
        const percent = Math.round(device.level * 100);
        const low = percent <= (lowThresholds[device.deviceClass] ?? -1);
        return low ? WirelessBatteryTone.Tone.Low : WirelessBatteryTone.Tone.Normal;
    }
}
