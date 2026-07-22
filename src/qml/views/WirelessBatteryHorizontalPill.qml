// SPDX-FileCopyrightText: Elias Mueller
//
// SPDX-License-Identifier: MIT

pragma ComponentBehavior: Bound

import QtQuick

import qs.Common
import qs.Widgets

import "../logic"

// The wrapper Item is load-bearing: a Behavior on a positioner's own
// implicit size never fires, so the capsule animates here instead.
Item {
    id: root

    required property WirelessBatteryViewModel viewModel
    required property int iconSize
    required property real barThickness
    required property var barConfig
    required property bool showPercentage
    required property bool showBolt

    readonly property int textSize: Theme.barTextSize(barThickness, barConfig?.fontScale, barConfig?.maximizeWidgetText)

    property bool _revealArmed: false

    implicitWidth: content.implicitWidth
    implicitHeight: content.implicitHeight
    clip: true

    // Initial delegates complete before the root arms, so the initial
    // population renders without a reveal.
    Component.onCompleted: root._revealArmed = true

    Row {
        id: content

        spacing: Theme.spacingS

        move: Transition {
            NumberAnimation {
                properties: "x,y"
                duration: Theme.shortDuration
                easing.type: Theme.standardEasing
            }
        }

        Repeater {
            model: WirelessBatteryEntryModel {
                entries: root.viewModel.entries
            }

            delegate: Row {
                id: entry

                required property int index
                required property string iconName
                required property string percentText
                required property bool showsBolt
                required property int tone

                readonly property color entryColor: WirelessBatteryToneColors.forTone(entry.tone)

                property real _revealFactor: 1

                spacing: Theme.spacingS
                width: implicitWidth * _revealFactor
                opacity: _revealFactor * _revealFactor
                clip: true

                Component.onCompleted: {
                    if (root._revealArmed) {
                        entry._revealFactor = 0;
                        revealAnimation.start();
                    }
                }

                NumberAnimation {
                    id: revealAnimation

                    target: entry
                    property: "_revealFactor"
                    to: 1
                    duration: Theme.shortDuration
                    easing.type: Theme.standardEasing
                }

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
                        name: entry.iconName
                        size: root.iconSize
                        color: entry.entryColor
                        anchors.verticalCenter: parent.verticalCenter
                    }

                    Item {
                        width: entry.showsBolt ? Theme.spacingXS + root.iconSize : 0
                        height: root.iconSize
                        visible: root.showBolt
                        clip: true
                        anchors.verticalCenter: parent.verticalCenter

                        DankIcon {
                            name: "bolt"
                            size: root.iconSize
                            color: Theme.primary
                            opacity: entry.showsBolt ? 1 : 0
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
                        text: entry.percentText
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

    Behavior on implicitWidth {
        NumberAnimation {
            duration: Theme.shortDuration
            easing.type: Theme.standardEasing
        }
    }
}
