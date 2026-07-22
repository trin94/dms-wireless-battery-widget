// SPDX-FileCopyrightText: Elias Mueller
//
// SPDX-License-Identifier: MIT

import QtQuick
import QtTest

import "../logic"

TestCase {
    id: testCase

    name: "WirelessBatteryHorizontalPill"
    when: windowShown
    width: 400
    height: 100

    function makeDevice(deviceId, overrides = {}) {
        const device = createTemporaryObject(deviceFactory, testCase, Object.assign({
            "deviceId": deviceId,
            "deviceClass": WirelessBatteryDevice.DeviceClass.Mouse,
            "name": deviceId,
            "level": 0.8,
            "chargeState": WirelessBatteryDevice.ChargeState.Discharging,
            "live": true
        }, overrides));
        verify(device);
        return device;
    }

    function makePill(devices): WirelessBatteryHorizontalPill {
        const source = createTemporaryObject(sourceFactory, testCase, {
            "devices": devices
        });
        verify(source);
        const viewModel = createTemporaryObject(viewModelFactory, testCase, {
            "source": source
        });
        verify(viewModel);
        const pill = createTemporaryObject(pillFactory, testCase, {
            "viewModel": viewModel,
            "iconSize": 20,
            "barThickness": 30,
            "barConfig": null,
            "showPercentage": true,
            "showBolt": true
        });
        verify(pill);
        waitForRendering(pill);
        return pill;
    }

    function maxContentOverflow(pill: WirelessBatteryHorizontalPill, durationMs: int): real {
        const content = findChild(pill, "content");
        let maxOverflow = 0;
        for (let elapsed = 0; elapsed < durationMs; elapsed += 10) {
            wait(10);
            maxOverflow = Math.max(maxOverflow, content.width - pill.width);
        }
        return maxOverflow;
    }

    function test_boltRevealKeepsEntriesInsideTheCapsule() {
        const mouse = makeDevice("mouse-1");
        const pill = makePill([mouse]);
        const widthBefore = pill.width;

        mouse.chargeState = WirelessBatteryDevice.ChargeState.Charging;

        const overflow = maxContentOverflow(pill, 500);
        verify(pill.width > widthBefore + 1, "bolt slot never opened");
        verify(overflow <= 1, "content overflowed the capsule by " + overflow.toFixed(1) + "px during the bolt reveal");
    }

    function test_boltRevealKeepsTheNeighborGap() {
        const mouse = makeDevice("mouse-1");
        const keyboard = makeDevice("keyboard-1", {
            "deviceClass": WirelessBatteryDevice.DeviceClass.Keyboard
        });
        const pill = makePill([mouse, keyboard]);
        const entries = findChild(pill, "entries");
        const mouseEntry = entries.itemAt(0);
        const keyboardEntry = entries.itemAt(1);
        const restingGap = keyboardEntry.x - (mouseEntry.x + mouseEntry.width);
        const widthBefore = pill.width;

        mouse.chargeState = WirelessBatteryDevice.ChargeState.Charging;

        let maxDeviation = 0;
        for (let elapsed = 0; elapsed < 500; elapsed += 10) {
            wait(10);
            const gap = keyboardEntry.x - (mouseEntry.x + mouseEntry.width);
            maxDeviation = Math.max(maxDeviation, Math.abs(gap - restingGap));
        }
        verify(pill.width > widthBefore + 1, "bolt slot never opened");
        verify(maxDeviation <= 1, "gap to the neighbor entry deviated by " + maxDeviation.toFixed(1) + "px during the bolt reveal");
    }

    function test_joinKeepsEntriesInsideTheCapsule() {
        const mouse = makeDevice("mouse-1");
        const pill = makePill([mouse]);
        const widthBefore = pill.width;
        const keyboard = makeDevice("keyboard-1", {
            "deviceClass": WirelessBatteryDevice.DeviceClass.Keyboard
        });

        pill.viewModel.source.devices = [mouse, keyboard];

        const overflow = maxContentOverflow(pill, 500);
        verify(pill.width > widthBefore + 1, "joining entry never grew in");
        verify(overflow <= 1, "content overflowed the capsule by " + overflow.toFixed(1) + "px during the join");
    }

    function test_leaveEasesTheLayoutClosed() {
        const mouse = makeDevice("mouse-1");
        const keyboard = makeDevice("keyboard-1", {
            "deviceClass": WirelessBatteryDevice.DeviceClass.Keyboard
        });
        const pill = makePill([mouse, keyboard]);
        const keyboardEntry = findChild(pill, "entries").itemAt(1);
        const wideWidth = pill.width;
        const keyboardXBefore = keyboardEntry.x;

        pill.viewModel.source.devices = [keyboard];

        const widthSamples = [];
        const xSamples = [];
        for (let elapsed = 0; elapsed < 600; elapsed += 10) {
            wait(10);
            widthSamples.push(pill.width);
            xSamples.push(keyboardEntry.x);
        }
        const narrowWidth = pill.width;
        const keyboardXAfter = keyboardEntry.x;
        verify(narrowWidth < wideWidth - 4, "capsule never closed after the leave");
        verify(widthSamples.some(width => width < wideWidth - 2 && width > narrowWidth + 2), "capsule snapped closed instead of easing");
        verify(keyboardXAfter < keyboardXBefore - 4, "surviving entry never slid closed");
        verify(xSamples.some(x => x < keyboardXBefore - 2 && x > keyboardXAfter + 2), "surviving entry snapped closed instead of sliding");
    }

    Component {
        id: deviceFactory

        WirelessBatteryDevice {}
    }

    Component {
        id: sourceFactory

        WirelessBatterySource {}
    }

    Component {
        id: viewModelFactory

        WirelessBatteryViewModel {}
    }

    Component {
        id: pillFactory

        WirelessBatteryHorizontalPill {
            width: implicitWidth
            height: implicitHeight
        }
    }
}
