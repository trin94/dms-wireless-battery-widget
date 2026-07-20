// SPDX-FileCopyrightText: Elias Mueller
//
// SPDX-License-Identifier: MIT

pragma ComponentBehavior: Bound

import QtQuick

import qs.Common
import qs.Widgets

import "../logic"

Row {
    id: root

    required property WirelessBatteryViewModel viewModel
    required property int iconSize
    required property real barThickness
    required property var barConfig
    required property bool showPercentage
    required property bool showBolt

    readonly property int textSize: Theme.barTextSize(barThickness, barConfig?.fontScale, barConfig?.maximizeWidgetText)

    spacing: Theme.spacingS

    Repeater {
        model: root.viewModel.entries

        delegate: Row {
            id: entry

            required property var modelData

            readonly property color entryColor: {
                switch (modelData.tone) {
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

            spacing: Theme.spacingXS

            DankIcon {
                name: entry.modelData.iconName
                size: root.iconSize
                color: entry.entryColor
                anchors.verticalCenter: parent.verticalCenter
            }

            DankIcon {
                name: "bolt"
                size: root.iconSize
                color: Theme.primary
                visible: entry.modelData.showsBolt && root.showBolt
                anchors.verticalCenter: parent.verticalCenter
            }

            StyledText {
                text: entry.modelData.percentText
                font.pixelSize: root.textSize
                color: entry.entryColor
                visible: root.showPercentage
                anchors.verticalCenter: parent.verticalCenter
            }
        }
    }
}
