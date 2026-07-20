// SPDX-FileCopyrightText: Elias Mueller
//
// SPDX-License-Identifier: MIT

import QtQuick

// Re-exposes another source with devices of untracked classes removed, so an
// untracked class ceases to exist for whatever consumes this source.
WirelessBatterySource {
    id: root

    required property WirelessBatterySource source
    property var trackedClasses: WirelessBatteryDefaults.trackedClasses(null)

    devices: (root.source?.devices ?? []).filter(device => root.trackedClasses[device.deviceClass] ?? true)
}
