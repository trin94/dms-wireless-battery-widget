// SPDX-FileCopyrightText: Elias Mueller
//
// SPDX-License-Identifier: MIT

import QtQuick

QtObject {
    id: root

    property list<string> targets: ["WirelessBatteryWidget.qml", "WirelessBatteryDaemon.qml", "WirelessBatterySettings.qml"]

    function check(): var {
        for (const target of root.targets) {
            const component = Qt.createComponent(target, Component.PreferSynchronous);
            if (component.status === Component.Error) {
                console.warn("WirelessBatteryWidget: startup check failed:", component.errorString());
                return {
                    title: "Incompatible DMS or Quickshell installation",
                    details: component.errorString()
                };
            }
        }
        console.info("WirelessBatteryWidget: startup check passed");
        return null;
    }
}
