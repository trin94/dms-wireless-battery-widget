// SPDX-FileCopyrightText: Elias Mueller
//
// SPDX-License-Identifier: MIT

import QtQuick
import QtTest

import qs.Common

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

    function recordUntilSettled(changeSignals, takeSample) {
        let dirty = false;
        const markDirty = () => {
            dirty = true;
        };
        changeSignals.forEach(changeSignal => changeSignal.connect(markDirty));
        const samples = [];
        let quietFrames = 0;
        for (let elapsed = 0; quietFrames < 3 && elapsed < 4 * Theme.shortDuration; elapsed += 16) {
            wait(16);
            samples.push(takeSample());
            if (dirty) {
                dirty = false;
                quietFrames = 0;
            } else {
                quietFrames += 1;
            }
        }
        changeSignals.forEach(changeSignal => changeSignal.disconnect(markDirty));
        return samples;
    }

    function maxContentOverflow(pill: WirelessBatteryHorizontalPill): real {
        const content = findChild(pill, "content");
        const samples = recordUntilSettled([content.widthChanged, pill.widthChanged], () => content.width - pill.width);
        return Math.max(...samples);
    }

    function test_placeholderIsABareIcon() {
        const pill = makePill([]);

        const entries = findChild(pill, "entries");
        compare(entries.count, 1);
        compare(pill.implicitWidth, pill.iconSize);
    }

    function test_entryIsWiderThanTheBareIcon() {
        const pill = makePill([makeDevice("mouse-1")]);

        verify(pill.implicitWidth > pill.iconSize, "percent text never widened the entry");
    }

    function test_placeholderSwapKeepsTheEntryInsideTheCapsule() {
        const pill = makePill([]);

        pill.viewModel.source.devices = [makeDevice("mouse-1")];

        const overflow = maxContentOverflow(pill);
        compare(findChild(pill, "entries").count, 1);
        verify(pill.width > pill.iconSize + 1, "joining entry never grew in");
        verify(overflow <= 1, "content overflowed the capsule by " + overflow.toFixed(1) + "px during the placeholder swap");
    }

    function test_boltRevealKeepsEntriesInsideTheCapsule() {
        const mouse = makeDevice("mouse-1");
        const pill = makePill([mouse]);
        const widthBefore = pill.width;

        mouse.chargeState = WirelessBatteryDevice.ChargeState.Charging;

        const overflow = maxContentOverflow(pill);
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

        const gaps = recordUntilSettled([mouseEntry.xChanged, mouseEntry.widthChanged, keyboardEntry.xChanged], () => keyboardEntry.x - (mouseEntry.x + mouseEntry.width));
        const maxDeviation = Math.max(...gaps.map(gap => Math.abs(gap - restingGap)));
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

        const overflow = maxContentOverflow(pill);
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

        const samples = recordUntilSettled([pill.widthChanged, keyboardEntry.xChanged], () => ({
                    "width": pill.width,
                    "x": keyboardEntry.x
                }));
        const widthSamples = samples.map(sample => sample.width);
        const xSamples = samples.map(sample => sample.x);
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
