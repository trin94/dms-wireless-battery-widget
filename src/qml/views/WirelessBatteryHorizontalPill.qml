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

    // The model is the entry count, not the entries list: entries is rebuilt
    // on every reading change, and a fresh list model would recreate the
    // delegates and cut the bolt slot animation short.
    Repeater {
        model: root.viewModel.entries.length

        delegate: Row {
            id: entry

            required property int index

            readonly property var entryData: root.viewModel.entries[entry.index]
            readonly property color entryColor: WirelessBatteryToneColors.forTone(entry.entryData.tone)

            spacing: Theme.spacingS

            StyledText {
                text: "•"
                font.pixelSize: root.textSize
                color: Theme.outline
                opacity: 0.3
                visible: entry.index > 0
                anchors.verticalCenter: parent.verticalCenter
            }

            Row {
                spacing: 0
                anchors.verticalCenter: parent.verticalCenter

                DankIcon {
                    name: entry.entryData.iconName
                    size: root.iconSize
                    color: entry.entryColor
                    anchors.verticalCenter: parent.verticalCenter
                }

                Item {
                    width: entry.entryData.showsBolt ? Theme.spacingXS + root.iconSize : 0
                    height: root.iconSize
                    visible: root.showBolt
                    clip: true
                    anchors.verticalCenter: parent.verticalCenter

                    DankIcon {
                        name: "bolt"
                        size: root.iconSize
                        color: Theme.primary
                        opacity: entry.entryData.showsBolt ? 1 : 0
                        anchors.left: parent.left
                        anchors.leftMargin: Theme.spacingXS
                        anchors.verticalCenter: parent.verticalCenter

                        Behavior on opacity {
                            NumberAnimation {
                                duration: Theme.shortDuration
                                easing.type: Theme.standardEasing
                            }
                        }
                    }

                    Behavior on width {
                        NumberAnimation {
                            duration: Theme.shortDuration
                            easing.type: Theme.standardEasing
                        }
                    }
                }

                StyledText {
                    text: entry.entryData.percentText
                    font.pixelSize: root.textSize
                    color: entry.entryColor
                    leftPadding: Theme.spacingXS
                    visible: root.showPercentage
                    anchors.verticalCenter: parent.verticalCenter
                }
            }
        }
    }
}
