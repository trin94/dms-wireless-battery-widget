// SPDX-FileCopyrightText: Elias Mueller
//
// SPDX-License-Identifier: MIT

import QtQuick

import qs.Common

QtObject {
    id: root

    required property WirelessBatterySource roster
    required property WirelessBatterySource source

    // One popout row per tracked device, in the bar's fixed order. Stale
    // rows keep the last reading but never a time estimate.
    readonly property var rows: WirelessBatteryFixedOrder.sorted(root.roster?.devices ?? []).map(device => {
        const stale = !device.live;
        const chargeStateText = root._chargeStateText(device.chargeState);
        const timeText = stale ? "" : root._timeText(device);
        const thresholdFraction = (root.lowThresholds[device.deviceClass] ?? 0) / 100;
        return {
            "key": device.deviceId,
            "name": device.name,
            "stale": stale,
            "level": device.level,
            "levelText": Math.round(device.level * 100) + "%",
            "chargeStateText": chargeStateText,
            "timeText": timeText,
            "detailText": timeText ? chargeStateText + " · " + timeText : chargeStateText,
            "thresholdFraction": thresholdFraction,
            "showsSplit": root.showsThresholdSplit && thresholdFraction > 0
        };
    })

    readonly property int emptyState: {
        if (root.rows.length > 0)
            return WirelessBatteryPopoutViewModel.EmptyState.None;
        if ((root.source?.devices ?? []).length > 0)
            return WirelessBatteryPopoutViewModel.EmptyState.WaitingForKnownDevice;
        return WirelessBatteryPopoutViewModel.EmptyState.NoSupportedDevice;
    }

    readonly property string emptyText: {
        switch (root.emptyState) {
        case WirelessBatteryPopoutViewModel.EmptyState.WaitingForKnownDevice:
            return I18n.tr("Waiting for a known device");
        case WirelessBatteryPopoutViewModel.EmptyState.NoSupportedDevice:
            return I18n.tr("No supported device present");
        default:
            return "";
        }
    }

    property var lowThresholds: WirelessBatteryDefaults.lowThresholds(null)
    property bool showsThresholdSplit: WirelessBatteryDefaults.notificationsEnabled

    enum EmptyState {
        None,
        WaitingForKnownDevice,
        NoSupportedDevice
    }

    function _chargeStateText(chargeState: int): string {
        switch (chargeState) {
        case WirelessBatteryDevice.ChargeState.Charging:
            return I18n.tr("Charging");
        case WirelessBatteryDevice.ChargeState.FullyCharged:
            return I18n.tr("Fully charged");
        default:
            return I18n.tr("Discharging");
        }
    }

    function _timeText(device: WirelessBatteryDevice): string {
        let seconds = 0;
        if (device.chargeState === WirelessBatteryDevice.ChargeState.Discharging)
            seconds = device.timeToEmpty;
        else if (device.chargeState === WirelessBatteryDevice.ChargeState.Charging)
            seconds = device.timeToFull;
        if (seconds <= 0)
            return "";
        const hours = Math.floor(seconds / 3600);
        const minutes = Math.floor((seconds % 3600) / 60);
        return hours > 0 ? hours + "h " + minutes + "m" : minutes + "m";
    }
}
