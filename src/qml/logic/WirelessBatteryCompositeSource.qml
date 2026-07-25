// SPDX-FileCopyrightText: Elias Mueller
//
// SPDX-License-Identifier: MIT

pragma ComponentBehavior: Bound

import QtQml.Models
import QtQuick

// Merges several sources into one, so everything downstream keeps
// consuming a single source.
WirelessBatterySource {
    id: root

    property list<WirelessBatterySource> sources

    readonly property Instantiator _withdrawalForwarders: Instantiator {
        model: root.sources

        delegate: Connections {
            required property WirelessBatterySource modelData

            target: modelData

            function onDevicesWithdrawn(deviceIds: list<string>) {
                root.devicesWithdrawn(deviceIds);
            }
        }
    }

    devices: {
        const merged = [];
        for (const source of root.sources)
            merged.push(...source.devices);
        return merged;
    }
}
