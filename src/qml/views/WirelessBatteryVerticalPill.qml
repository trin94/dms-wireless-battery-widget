// SPDX-FileCopyrightText: Elias Mueller
//
// SPDX-License-Identifier: MIT

pragma ComponentBehavior: Bound

import QtQuick

import qs.Common
import qs.Widgets

import "../logic"

Column {
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

        delegate: Column {
            id: entry

            required property var modelData
            required property int index

            readonly property color entryColor: WirelessBatteryToneColors.forTone(modelData.tone)

            spacing: Theme.spacingS
            anchors.horizontalCenter: parent.horizontalCenter

            Rectangle {
                width: root.iconSize
                height: 1
                color: Theme.outline
                opacity: 0.3
                visible: entry.index > 0
                anchors.horizontalCenter: parent.horizontalCenter
            }

            Column {
                spacing: Theme.spacingXS
                anchors.horizontalCenter: parent.horizontalCenter

                DankIcon {
                    name: entry.modelData.iconName
                    size: root.iconSize
                    color: entry.entryColor
                    anchors.horizontalCenter: parent.horizontalCenter
                }

                DankIcon {
                    name: "bolt"
                    size: root.iconSize
                    color: Theme.primary
                    visible: entry.modelData.showsBolt && root.showBolt
                    anchors.horizontalCenter: parent.horizontalCenter
                }

                StyledText {
                    text: entry.modelData.verticalPercentText
                    font.pixelSize: root.textSize
                    color: entry.entryColor
                    visible: root.showPercentage
                    anchors.horizontalCenter: parent.horizontalCenter
                }
            }
        }
    }
}
