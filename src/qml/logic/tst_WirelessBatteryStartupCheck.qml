// SPDX-FileCopyrightText: Elias Mueller
//
// SPDX-License-Identifier: MIT

import QtQuick
import QtTest

import ".."

TestCase {
    id: testCase

    name: "WirelessBatteryStartupCheck"

    function makeStartupCheck(initProperties = {}): WirelessBatteryStartupCheck {
        const control = createTemporaryObject(objectUnderTest, testCase, initProperties);
        verify(control);
        return control;
    }

    function test_defaultTargetsAreTheEntryPoints() {
        const control = makeStartupCheck();

        compare(control.targets, ["WirelessBatteryWidget.qml", "WirelessBatteryDaemon.qml", "WirelessBatterySettings.qml"]);
    }

    function test_compilableTargetsReturnNull() {
        const control = makeStartupCheck({
            "targets": ["logic/WirelessBatteryDefaults.qml"]
        });

        compare(control.check(), null);
    }

    function test_failingTargetReportsError() {
        const control = makeStartupCheck({
            "targets": ["DoesNotExist.qml"]
        });

        ignoreWarning(new RegExp("WirelessBatteryWidget: startup check failed: .+"));
        const result = control.check();

        verify(result !== null);
        verify(result.title.length > 0);
        verify(result.details.length > 0);
    }

    Component {
        id: objectUnderTest

        WirelessBatteryStartupCheck {}
    }
}
