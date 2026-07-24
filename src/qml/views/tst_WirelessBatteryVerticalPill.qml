// SPDX-FileCopyrightText: Elias Mueller
//
// SPDX-License-Identifier: MIT

import QtQuick
import QtTest

import qs.Common

import "../logic"

TestCase {
    id: testCase

    name: "WirelessBatteryVerticalPill"
    when: windowShown
    width: 100
    height: 400

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

    function makePill(devices): WirelessBatteryVerticalPill {
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

    function maxContentOverflow(pill: WirelessBatteryVerticalPill): real {
        const content = findChild(pill, "content");
        const samples = recordUntilSettled([content.heightChanged, pill.heightChanged], () => content.height - pill.height);
        return Math.max(...samples);
    }

    function test_placeholderIsABareIcon() {
        const pill = makePill([]);

        const entries = findChild(pill, "entries");
        compare(entries.count, 1);
        compare(pill.implicitHeight, pill.iconSize);
    }

    function test_entryIsTallerThanTheBareIcon() {
        const pill = makePill([makeDevice("mouse-1")]);

        verify(pill.implicitHeight > pill.iconSize, "percent text never grew the entry");
    }

    function test_placeholderSwapKeepsTheEntryInsideTheCapsule() {
        const pill = makePill([]);

        pill.viewModel.source.devices = [makeDevice("mouse-1")];

        const overflow = maxContentOverflow(pill);
        compare(findChild(pill, "entries").count, 1);
        verify(pill.height > pill.iconSize + 1, "joining entry never grew in");
        verify(overflow <= 1, "content overflowed the capsule by " + overflow.toFixed(1) + "px during the placeholder swap");
    }

    function test_boltRevealKeepsEntriesInsideTheCapsule() {
        const mouse = makeDevice("mouse-1");
        const pill = makePill([mouse]);
        const heightBefore = pill.height;

        mouse.chargeState = WirelessBatteryDevice.ChargeState.Charging;

        const overflow = maxContentOverflow(pill);
        verify(pill.height > heightBefore + 1, "bolt slot never opened");
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
        const restingGap = keyboardEntry.y - (mouseEntry.y + mouseEntry.height);
        const heightBefore = pill.height;

        mouse.chargeState = WirelessBatteryDevice.ChargeState.Charging;

        const gaps = recordUntilSettled([mouseEntry.yChanged, mouseEntry.heightChanged, keyboardEntry.yChanged], () => keyboardEntry.y - (mouseEntry.y + mouseEntry.height));
        const maxDeviation = Math.max(...gaps.map(gap => Math.abs(gap - restingGap)));
        verify(pill.height > heightBefore + 1, "bolt slot never opened");
        verify(maxDeviation <= 1, "gap to the neighbor entry deviated by " + maxDeviation.toFixed(1) + "px during the bolt reveal");
    }

    function test_joinKeepsEntriesInsideTheCapsule() {
        const mouse = makeDevice("mouse-1");
        const pill = makePill([mouse]);
        const heightBefore = pill.height;
        const keyboard = makeDevice("keyboard-1", {
            "deviceClass": WirelessBatteryDevice.DeviceClass.Keyboard
        });

        pill.viewModel.source.devices = [mouse, keyboard];

        const overflow = maxContentOverflow(pill);
        verify(pill.height > heightBefore + 1, "joining entry never grew in");
        verify(overflow <= 1, "content overflowed the capsule by " + overflow.toFixed(1) + "px during the join");
    }

    function test_leaveEasesTheLayoutClosed() {
        const mouse = makeDevice("mouse-1");
        const keyboard = makeDevice("keyboard-1", {
            "deviceClass": WirelessBatteryDevice.DeviceClass.Keyboard
        });
        const pill = makePill([mouse, keyboard]);
        const keyboardEntry = findChild(pill, "entries").itemAt(1);
        const tallHeight = pill.height;
        const keyboardYBefore = keyboardEntry.y;

        pill.viewModel.source.devices = [keyboard];

        const samples = recordUntilSettled([pill.heightChanged, keyboardEntry.yChanged], () => ({
                    "height": pill.height,
                    "y": keyboardEntry.y
                }));
        const heightSamples = samples.map(sample => sample.height);
        const ySamples = samples.map(sample => sample.y);
        const shortHeight = pill.height;
        const keyboardYAfter = keyboardEntry.y;
        verify(shortHeight < tallHeight - 4, "capsule never closed after the leave");
        verify(heightSamples.some(height => height < tallHeight - 2 && height > shortHeight + 2), "capsule snapped closed instead of easing");
        verify(keyboardYAfter < keyboardYBefore - 4, "surviving entry never slid closed");
        verify(ySamples.some(y => y < keyboardYBefore - 2 && y > keyboardYAfter + 2), "surviving entry snapped closed instead of sliding");
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

        WirelessBatteryVerticalPill {
            width: implicitWidth
            height: implicitHeight
        }
    }
}
