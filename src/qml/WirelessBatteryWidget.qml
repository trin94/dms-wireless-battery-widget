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

    readonly property WirelessBatterySource _upowerSource: WirelessBatteryUPowerSource {}

    readonly property WirelessBatterySource source: WirelessBatteryCompositeSource {
        sources: [root._upowerSource, WirelessBatterySteamController.source]
    }

    readonly property WirelessBatterySource roster: WirelessBatteryRoster {
        source: root.source
    }

    readonly property var _retainedClasses: WirelessBatteryDefaults.retainedClasses(root.pluginData)

    readonly property WirelessBatterySource retainedRoster: WirelessBatteryRetainedClassFilter {
        source: root.roster
        retainedClasses: root._retainedClasses
    }

    readonly property var _trackedClasses: WirelessBatteryDefaults.trackedClasses(root.pluginData)

    readonly property WirelessBatterySource trackedRoster: WirelessBatteryTrackedClassFilter {
        source: root.retainedRoster
        trackedClasses: root._trackedClasses
    }

    readonly property WirelessBatteryViewModel viewModel: WirelessBatteryViewModel {
        source: root.trackedRoster
        lowThresholds: WirelessBatteryDefaults.lowThresholds(root.pluginData)
        showsPlaceholder: root.pluginData.showPlaceholder ?? WirelessBatteryDefaults.showPlaceholder
    }

    readonly property WirelessBatteryPopoutViewModel popoutViewModel: WirelessBatteryPopoutViewModel {
        roster: root.trackedRoster
        source: root.source
        lowThresholds: WirelessBatteryDefaults.lowThresholds(root.pluginData)
        showsThresholdSplit: root.pluginData.notificationsEnabled ?? WirelessBatteryDefaults.notificationsEnabled
    }

    // With the placeholder disabled the pill has nothing to show while the
    // roster is empty, so the whole capsule hides.
    readonly property bool _pillPopulated: root.viewModel.entries.length > 0

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

    on_PillPopulatedChanged: root.setVisibilityOverride(root._pillPopulated)

    Component.onCompleted: root.setVisibilityOverride(root._pillPopulated)
}
