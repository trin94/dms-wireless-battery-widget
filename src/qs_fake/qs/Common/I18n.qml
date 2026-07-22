// SPDX-FileCopyrightText: Elias Mueller
//
// SPDX-License-Identifier: MIT

pragma Singleton

import QtQuick

// Test fake of the DMS i18n singleton: returns the source text untranslated.
QtObject {
    function tr(sourceText: string): string {
        return sourceText;
    }
}
