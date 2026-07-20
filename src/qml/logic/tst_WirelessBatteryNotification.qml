// SPDX-FileCopyrightText: Elias Mueller
//
// SPDX-License-Identifier: MIT

import QtTest

TestCase {
    id: testCase

    name: "WirelessBatteryNotification"

    function test_lowBatteryCommandRunsNotifySendAsThePlugin() {
        const command = WirelessBatteryNotification.lowBatteryCommand("MX Master 3S", 8);

        compare(command[0], "notify-send");
        compare(command[command.indexOf("--app-name") + 1], "Wireless Battery Widget");
    }

    function test_lowBatteryCommandNamesDeviceAndPercentage() {
        const command = WirelessBatteryNotification.lowBatteryCommand("MX Master 3S", 8);

        verify(command.includes("MX Master 3S"));
        verify(command.some(part => part.includes("8%")));
    }
}
