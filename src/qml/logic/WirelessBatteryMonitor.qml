// SPDX-FileCopyrightText: Elias Mueller
//
// SPDX-License-Identifier: MIT

import QtQuick

QtObject {
    id: root

    required property WirelessBatterySource source

    readonly property int rearmMargin: 5

    property var lowThresholds: WirelessBatteryDefaults.lowThresholds(null)

    // Reading every live device's properties here re-evaluates the binding on
    // any reading change, which schedules _evaluate on settled state.
    readonly property var _readings: (root.source?.devices ?? []).filter(device => device.live).map(device => ({
                "deviceId": device.deviceId,
                "deviceClass": device.deviceClass,
                "name": device.name,
                "percent": Math.round(device.level * 100),
                "draining": device.chargeState === WirelessBatteryDevice.ChargeState.Discharging
            }))

    property var _disarmed: ({})

    signal lowReading(deviceName: string, percent: int)

    function _evaluate(): void {
        for (const reading of root._readings) {
            const threshold = root.lowThresholds[reading.deviceClass];
            if (threshold === undefined)
                continue;
            if (reading.percent > threshold + root.rearmMargin) {
                delete root._disarmed[reading.deviceId];
            } else if (reading.draining && reading.percent <= threshold && !root._disarmed[reading.deviceId]) {
                root._disarmed[reading.deviceId] = true;
                root.lowReading(reading.name, reading.percent);
            }
        }
    }

    onLowThresholdsChanged: Qt.callLater(root._evaluate)
    on_ReadingsChanged: Qt.callLater(root._evaluate)

    Component.onCompleted: _evaluate()
}
