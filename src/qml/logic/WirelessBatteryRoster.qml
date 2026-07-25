// SPDX-FileCopyrightText: Elias Mueller
//
// SPDX-License-Identifier: MIT

import QtQuick

WirelessBatterySource {
    id: root

    required property WirelessBatterySource source

    // Reading every live device's properties here re-evaluates the binding on
    // any reading change, which schedules _sync. The sync runs once the
    // change has settled, so a reading that zeroes out in the same burst
    // that ends liveness never contaminates the frozen last reading.
    readonly property var _liveSnapshots: (root.source?.devices ?? []).filter(device => device.live).map(device => ({
                "deviceId": device.deviceId,
                "deviceClass": device.deviceClass,
                "name": device.name,
                "level": device.level,
                "chargeState": device.chargeState,
                "timeToEmpty": device.timeToEmpty,
                "timeToFull": device.timeToFull
            }))

    readonly property Component _snapshotFactory: Component {
        WirelessBatteryDevice {}
    }

    readonly property Connections _sourceRemovals: Connections {
        target: root.source

        function onSourceRemoved(deviceIds: list<string>) {
            root._forget(deviceIds);
        }
    }

    function _forget(deviceIds: list<string>): void {
        const removed = new Set(deviceIds);
        const forgotten = root.devices.filter(device => removed.has(device.deviceId));
        if (forgotten.length === 0)
            return;
        root.devices = root.devices.filter(device => !removed.has(device.deviceId));
        for (const device of forgotten)
            device.destroy();
    }

    function _sync(): void {
        const liveIds = new Set(root._liveSnapshots.map(snapshot => snapshot.deviceId));
        for (const snapshot of root._liveSnapshots) {
            const tracked = root.devices.find(device => device.deviceId === snapshot.deviceId);
            if (tracked)
                Object.assign(tracked, snapshot);
            else
                root.devices = [...root.devices, root._snapshotFactory.createObject(root, snapshot)];
        }
        for (const device of root.devices)
            device.live = liveIds.has(device.deviceId);
    }

    on_LiveSnapshotsChanged: Qt.callLater(root._sync)

    Component.onCompleted: _sync()
}
