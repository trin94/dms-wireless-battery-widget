// SPDX-FileCopyrightText: Elias Mueller
//
// SPDX-License-Identifier: MIT

import QtQuick

QtObject {
    id: root

    property var data: ({})

    signal pluginDataChanged(pluginId: string)

    function loadPluginData(pluginId: string, key: string, defaultValue) {
        return data[pluginId]?.[key] ?? defaultValue;
    }

    function savePluginData(pluginId: string, key: string, value): bool {
        const next = Object.assign({}, data);
        next[pluginId] = Object.assign({}, data[pluginId], {
            [key]: value
        });
        data = next;
        pluginDataChanged(pluginId);
        return true;
    }
}
