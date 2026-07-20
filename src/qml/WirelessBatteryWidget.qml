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

    readonly property var _trackedClasses: WirelessBatteryDefaults.trackedClasses(root.pluginData)

    readonly property WirelessBatterySource trackedRoster: WirelessBatteryTrackedClassFilter {
        source: root.roster
        trackedClasses: root._trackedClasses
    }

    readonly property WirelessBatteryViewModel viewModel: WirelessBatteryViewModel {
        source: root.trackedRoster
        lowThresholds: WirelessBatteryDefaults.lowThresholds(root.pluginData)
    }

    readonly property WirelessBatteryPopoutViewModel popoutViewModel: WirelessBatteryPopoutViewModel {
        roster: root.trackedRoster
        source: root.source
        lowThresholds: WirelessBatteryDefaults.lowThresholds(root.pluginData)
        showsThresholdSplit: root.pluginData.notificationsEnabled ?? WirelessBatteryDefaults.notificationsEnabled
    }

    horizontalBarPill: Component {
        WirelessBatteryHorizontalPill {
            viewModel: root.viewModel
            iconSize: root.iconSize
            barThickness: root.barThickness
            barConfig: root.barConfig
            showPercentage: root.pluginData.showPercentage ?? WirelessBatteryDefaults.showPercentage
            showBolt: root.pluginData.showBolt ?? WirelessBatteryDefaults.showBolt
        }
    }

    popoutContent: Component {
        WirelessBatteryPopout {
            viewModel: root.popoutViewModel
        }
    }

    readonly property int _popoutRowHeight: 72
    readonly property int _popoutPadding: 32
    readonly property int _popoutEmptyHeight: 80

    popoutWidth: 340
    popoutHeight: root.popoutViewModel.rows.length > 0 ? root.popoutViewModel.rows.length * root._popoutRowHeight + root._popoutPadding : root._popoutEmptyHeight
}
