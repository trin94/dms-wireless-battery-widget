// SPDX-FileCopyrightText: Elias Mueller
//
// SPDX-License-Identifier: MIT

pragma Singleton

import QtQuick

import qs.Common

import "../logic"

QtObject {
    function forTone(tone: int): color {
        switch (tone) {
        case WirelessBatteryTone.Tone.Charging:
            return Theme.primary;
        case WirelessBatteryTone.Tone.Stale:
            return Theme.surfaceTextMedium;
        case WirelessBatteryTone.Tone.Low:
            return Theme.error;
        default:
            return Theme.surfaceText;
        }
    }

    function fillForTone(tone: int): color {
        switch (tone) {
        case WirelessBatteryTone.Tone.Stale:
            return Theme.withAlpha(Theme.primary, 0.4);
        case WirelessBatteryTone.Tone.Low:
            return Theme.error;
        default:
            return Theme.primary;
        }
    }
}
