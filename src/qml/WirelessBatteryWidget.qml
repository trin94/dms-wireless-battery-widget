// SPDX-FileCopyrightText: Elias Mueller
//
// SPDX-License-Identifier: MIT

pragma ComponentBehavior: Bound

import QtQuick

import qs.Common
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

    readonly property int _popoutRowHeight: 53
    readonly property int _popoutEmptyTextHeight: 20
    // Own edge padding plus the spacingS inset PluginPopout adds around plugin content
    readonly property real _popoutFramePadding: Theme.spacingM * 2 + Theme.spacingS * 2

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

    verticalBarPill: Component {
        WirelessBatteryVerticalPill {
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

    popoutWidth: 340
    popoutHeight: {
        const rowCount = root.popoutViewModel.rows.length;
        if (rowCount === 0)
            return root._popoutFramePadding + root._popoutEmptyTextHeight;
        return root._popoutFramePadding + rowCount * root._popoutRowHeight + (rowCount - 1) * Theme.spacingL;
    }
}
