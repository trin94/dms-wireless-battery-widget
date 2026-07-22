// SPDX-FileCopyrightText: Elias Mueller
//
// SPDX-License-Identifier: MIT

pragma Singleton

import QtQuick

// Test fake of the DMS theme singleton: fixed metrics and colors so view
// tests get deterministic sizes.
QtObject {
    readonly property int spacingXS: 4
    readonly property int spacingS: 8
    readonly property int shortDuration: 200
    readonly property int standardEasing: Easing.OutCubic
    readonly property color outline: "#888888"
    readonly property color primary: "#5588ff"
    readonly property color error: "#ff5555"
    readonly property color surfaceText: "#ffffff"
    readonly property color surfaceTextMedium: "#bbbbbb"

    function withAlpha(baseColor: color, alpha: real): color {
        return Qt.rgba(baseColor.r, baseColor.g, baseColor.b, alpha);
    }

    function barTextSize(barThickness: real, fontScale: var, maximizeWidgetText: var): int {
        return 14;
    }
}
