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

    required property WirelessBatteryPopoutViewModel viewModel

    padding: Theme.spacingM
    spacing: Theme.spacingL

    component BarSegment: Rectangle {
        id: segment

        required property real fill
        required property color fillColor

        radius: height / 2

        Rectangle {
            width: parent.width * segment.fill
            height: parent.height
            radius: parent.radius
            color: segment.fillColor
        }
    }

    StyledText {
        text: root.viewModel.emptyText
        font.pixelSize: Theme.fontSizeMedium
        color: Theme.surfaceTextMedium
        visible: root.viewModel.rows.length === 0
    }

    Repeater {
        model: root.viewModel.rows

        delegate: Item {
            id: row

            required property var modelData

            readonly property color rowTextColor: modelData.stale ? Theme.surfaceTextMedium : Theme.surfaceText
            readonly property color fillColor: WirelessBatteryToneColors.fillForTone(modelData.tone)

            width: root.width - 2 * root.padding
            height: details.implicitHeight

            DankIcon {
                id: classIcon

                name: row.modelData.iconName
                size: Theme.iconSize
                color: WirelessBatteryToneColors.forTone(row.modelData.tone)
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
            }

            Column {
                id: details

                spacing: Theme.spacingXS
                anchors.left: classIcon.right
                anchors.leftMargin: Theme.spacingM
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter

                Item {
                    width: parent.width
                    height: nameText.implicitHeight

                    StyledText {
                        id: nameText

                        text: row.modelData.name
                        font.pixelSize: Theme.fontSizeMedium
                        color: row.rowTextColor
                        elide: Text.ElideRight
                        anchors.left: parent.left
                        anchors.right: levelText.left
                        anchors.rightMargin: Theme.spacingS
                    }

                    StyledText {
                        id: levelText

                        text: row.modelData.levelText
                        font.pixelSize: Theme.fontSizeMedium
                        color: row.rowTextColor
                        anchors.right: parent.right
                    }
                }

                Item {
                    width: parent.width
                    height: 8

                    BarSegment {
                        id: lowSegment

                        width: Math.max(0, (parent.width - Theme.spacingXS) * row.modelData.splitFraction)
                        height: parent.height
                        color: Theme.withAlpha(Theme.error, 0.2)
                        fill: row.modelData.lowSegmentFill
                        fillColor: row.fillColor
                    }

                    BarSegment {
                        x: lowSegment.width > 0 ? lowSegment.width + Theme.spacingXS : 0
                        width: Math.max(0, parent.width - x)
                        height: parent.height
                        color: Theme.surfaceContainerHigh
                        fill: row.modelData.highSegmentFill
                        fillColor: row.fillColor
                    }
                }

                StyledText {
                    text: row.modelData.detailText
                    font.pixelSize: Theme.fontSizeSmall
                    color: row.modelData.stale ? Theme.surfaceTextAlpha : Theme.surfaceTextMedium
                }
            }
        }
    }
}
