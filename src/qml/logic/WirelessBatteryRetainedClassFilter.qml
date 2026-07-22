// SPDX-FileCopyrightText: Elias Mueller
//
// SPDX-License-Identifier: MIT

import QtQuick

// Re-exposes another source with devices that are neither live nor of a
// retained class removed, so devices of a non-retained class vanish the
// moment they are not live.
WirelessBatterySource {
    id: root

    required property WirelessBatterySource source
    property var retainedClasses: WirelessBatteryDefaults.retainedClasses(null)

    devices: (root.source?.devices ?? []).filter(device => device.live || (root.retainedClasses[device.deviceClass] ?? true))
}
