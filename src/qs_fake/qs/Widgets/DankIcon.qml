// SPDX-FileCopyrightText: Elias Mueller
//
// SPDX-License-Identifier: MIT

import QtQuick

// Test fake of the DMS icon widget: takes up the icon's box without
// rendering a glyph.
Item {
    property string name
    property real size: 24
    property color color: "white"

    implicitWidth: size
    implicitHeight: size
    width: size
    height: size
}
