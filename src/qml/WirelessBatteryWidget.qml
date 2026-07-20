// SPDX-FileCopyrightText: Elias Mueller
//
// SPDX-License-Identifier: MIT

pragma ComponentBehavior: Bound

import QtQuick

import qs.Modules.Plugins

import "logic"
import "views"

PluginComponent {
    id: root

    readonly property WirelessBatterySource source: WirelessBatteryUPowerSource {}

    readonly property WirelessBatterySource roster: WirelessBatteryRoster {
        source: root.source
    }

    readonly property WirelessBatteryViewModel viewModel: WirelessBatteryViewModel {
        source: root.roster
        lowThresholds: WirelessBatteryDefaults.lowThresholds(root.pluginData)
    }

    horizontalBarPill: Component {
        WirelessBatteryHorizontalPill {
            viewModel: root.viewModel
            iconSize: root.iconSize
            barThickness: root.barThickness
            barConfig: root.barConfig
        }
    }
}
