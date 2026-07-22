// SPDX-FileCopyrightText: Elias Mueller
//
// SPDX-License-Identifier: MIT

import QtQuick

// The pill's keyed entry model: mirrors the bound entries in place, so the
// delegates of surviving entries are never recreated.
ListModel {
    id: root

    property var entries: []

    function _sync(): void {
        const desired = root.entries ?? [];
        for (let i = root.count - 1; i >= 0; i--) {
            const key = root.get(i).key;
            if (!desired.some(entry => entry.key === key))
                root.remove(i);
        }
        for (let target = 0; target < desired.length; target++) {
            const entry = desired[target];
            let current = -1;
            for (let i = target; i < root.count; i++) {
                if (root.get(i).key === entry.key) {
                    current = i;
                    break;
                }
            }
            if (current === -1) {
                root.insert(target, entry);
            } else {
                if (current !== target)
                    root.move(current, target, 1);
                root.set(target, entry);
            }
        }
    }

    onEntriesChanged: root._sync()

    Component.onCompleted: root._sync()
}
