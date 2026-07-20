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

    spacing: Theme.spacingM

    StyledText {
        text: root.viewModel.emptyText
        font.pixelSize: Theme.fontSizeMedium
        color: Theme.surfaceTextMedium
        visible: root.viewModel.rows.length === 0
    }

    Repeater {
        model: root.viewModel.rows

        delegate: Column {
            id: row

            required property var modelData

            readonly property color rowTextColor: modelData.stale ? Theme.surfaceTextMedium : Theme.surfaceText

            width: parent.width
            spacing: Theme.spacingXS

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
                height: 6

                Rectangle {
                    anchors.fill: parent
                    radius: height / 2
                    color: Theme.surfaceContainerHigh
                }

                Rectangle {
                    width: parent.width * row.modelData.level
                    height: parent.height
                    radius: height / 2
                    color: row.modelData.stale ? Theme.surfaceTextMedium : Theme.primary
                }

                Rectangle {
                    x: parent.width * row.modelData.thresholdFraction - width / 2
                    width: 2
                    height: parent.height
                    color: Theme.error
                    visible: row.modelData.showsSplit
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
