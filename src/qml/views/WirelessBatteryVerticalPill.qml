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
    // Only a leave snap is eased; see ADR 0010.
    property bool _easeLeave: false

    implicitWidth: content.implicitWidth
    implicitHeight: content.implicitHeight
    clip: true

    // Initial delegates complete before the root arms, so the initial
    // population renders without a reveal.
    Component.onCompleted: root._revealArmed = true

    Column {
        id: content

        objectName: "content"
        spacing: Theme.spacingS
        anchors.horizontalCenter: parent.horizontalCenter

        move: Transition {
            enabled: root._easeLeave

            NumberAnimation {
                properties: "x,y"
                duration: Theme.shortDuration
                easing.type: Theme.standardEasing
            }
        }

        Repeater {
            objectName: "entries"
            model: WirelessBatteryEntryModel {
                // The view model can be destroyed before the pill on teardown.
                entries: root.viewModel?.entries

                onRowsRemoved: root._easeLeave = true
                onRowsInserted: root._easeLeave = false
            }

            delegate: Column {
                id: entry

                required property int index
                required property string iconName
                required property string verticalPercentText
                required property bool showsPercent
                required property bool showsBolt
                required property int tone

                readonly property color entryColor: WirelessBatteryToneColors.forTone(entry.tone)

                property real _revealFactor: 1

                spacing: Theme.spacingS
                height: implicitHeight * _revealFactor
                opacity: _revealFactor * _revealFactor
                clip: true
                anchors.horizontalCenter: parent.horizontalCenter

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
                    anchors.horizontalCenter: parent.horizontalCenter
                }

                Column {
                    spacing: 0
                    anchors.horizontalCenter: parent.horizontalCenter

                    DankIcon {
                        name: entry.iconName
                        size: root.iconSize
                        color: entry.entryColor
                        anchors.horizontalCenter: parent.horizontalCenter
                    }

                    Item {
                        width: root.iconSize
                        height: entry.showsBolt ? Theme.spacingXS + root.iconSize : 0
                        visible: root.showBolt
                        clip: true
                        anchors.horizontalCenter: parent.horizontalCenter

                        DankIcon {
                            name: "bolt"
                            size: root.iconSize
                            color: Theme.primary
                            opacity: entry.showsBolt ? 1 : 0
                            anchors.top: parent.top
                            anchors.topMargin: Theme.spacingXS
                            anchors.horizontalCenter: parent.horizontalCenter

                            Behavior on opacity {
                                NumberAnimation {
                                    duration: Theme.shortDuration
                                    easing.type: Theme.standardEasing
                                }
                            }
                        }

                        Behavior on height {
                            NumberAnimation {
                                duration: Theme.shortDuration
                                easing.type: Theme.standardEasing
                            }
                        }
                    }

                    StyledText {
                        text: entry.verticalPercentText
                        font.pixelSize: root.textSize
                        color: entry.entryColor
                        topPadding: Theme.spacingXS
                        visible: root.showPercentage && entry.showsPercent
                        anchors.horizontalCenter: parent.horizontalCenter
                    }
                }
            }
        }
    }

    Behavior on implicitHeight {
        enabled: root._easeLeave

        NumberAnimation {
            duration: Theme.shortDuration
            easing.type: Theme.standardEasing

            onRunningChanged: {
                if (!running)
                    root._easeLeave = false;
            }
        }
    }
}
