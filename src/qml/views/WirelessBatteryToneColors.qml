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
        case WirelessBatteryViewModel.Tone.Charging:
            return Theme.primary;
        case WirelessBatteryViewModel.Tone.Stale:
            return Theme.surfaceTextMedium;
        case WirelessBatteryViewModel.Tone.Low:
            return Theme.error;
        default:
            return Theme.surfaceText;
        }
    }
}
