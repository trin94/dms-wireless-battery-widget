// SPDX-FileCopyrightText: Elias Mueller
//
// SPDX-License-Identifier: MIT

pragma Singleton

import QtQuick

// The fixed entry order, identical in bar and popout: mouse, keyboard,
// controller, headset; name as tiebreak.
QtObject {
    function sorted(devices: var): var {
        return devices.slice().sort((left, right) => left.deviceClass - right.deviceClass || left.name.localeCompare(right.name) || left.deviceId.localeCompare(right.deviceId));
    }
}
