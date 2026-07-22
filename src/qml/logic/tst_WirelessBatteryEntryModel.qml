// SPDX-FileCopyrightText: Elias Mueller
//
// SPDX-License-Identifier: MIT

import QtQuick
import QtTest

TestCase {
    id: testCase

    name: "WirelessBatteryEntryModel"

    function makeEntry(key, overrides = {}) {
        return Object.assign({
            "key": key,
            "iconName": "mouse",
            "percentText": "50%",
            "verticalPercentText": "50",
            "showsBolt": false,
            "tone": 0
        }, overrides);
    }

    function makeModel(entries): WirelessBatteryEntryModel {
        const model = createTemporaryObject(entryModelFactory, testCase, {
            "entries": entries
        });
        verify(model);
        return model;
    }

    function makeSpy(model: WirelessBatteryEntryModel, signalName: string): SignalSpy {
        const spy = createTemporaryObject(spyFactory, testCase, {
            "target": model,
            "signalName": signalName
        });
        verify(spy);
        verify(spy.valid);
        return spy;
    }

    function makeRepeater(model: WirelessBatteryEntryModel): Repeater {
        const repeater = createTemporaryObject(repeaterFactory, testCase, {
            "model": model
        });
        verify(repeater);
        return repeater;
    }

    function keys(model: WirelessBatteryEntryModel): var {
        const result = [];
        for (let i = 0; i < model.count; i++)
            result.push(model.get(i).key);
        return result;
    }

    function test_mirrorsEntriesInOrder() {
        const model = makeModel([makeEntry("mouse-1"), makeEntry("keyboard-1", {
                "iconName": "keyboard",
                "percentText": "80%"
            })]);

        compare(keys(model), ["mouse-1", "keyboard-1"]);
        compare(model.get(1).iconName, "keyboard");
        compare(model.get(1).percentText, "80%");
    }

    function test_joiningDeviceInsertsOnlyItsEntryMidPill() {
        const model = makeModel([makeEntry("mouse-1"), makeEntry("headset-1")]);
        const inserted = makeSpy(model, "rowsInserted");
        const removed = makeSpy(model, "rowsRemoved");

        model.entries = [makeEntry("mouse-1"), makeEntry("keyboard-1"), makeEntry("headset-1")];

        compare(keys(model), ["mouse-1", "keyboard-1", "headset-1"]);
        compare(inserted.count, 1);
        compare(removed.count, 0);
    }

    function test_readingChangeUpdatesTheEntryInPlace() {
        const model = makeModel([makeEntry("mouse-1", {
                "percentText": "75%"
            }), makeEntry("keyboard-1")]);
        const inserted = makeSpy(model, "rowsInserted");
        const removed = makeSpy(model, "rowsRemoved");

        model.entries = [makeEntry("mouse-1", {
                "percentText": "42%",
                "showsBolt": true
            }), makeEntry("keyboard-1")];

        compare(model.get(0).percentText, "42%");
        compare(model.get(0).showsBolt, true);
        compare(inserted.count, 0);
        compare(removed.count, 0);
    }

    function test_leavingDeviceRemovesOnlyItsEntry() {
        const model = makeModel([makeEntry("mouse-1"), makeEntry("keyboard-1"), makeEntry("headset-1")]);
        const inserted = makeSpy(model, "rowsInserted");
        const removed = makeSpy(model, "rowsRemoved");

        model.entries = [makeEntry("mouse-1"), makeEntry("headset-1")];

        compare(keys(model), ["mouse-1", "headset-1"]);
        compare(removed.count, 1);
        compare(inserted.count, 0);
    }

    function test_allDevicesLeavingEmptiesTheModel() {
        const model = makeModel([makeEntry("mouse-1")]);

        model.entries = [];

        compare(model.count, 0);
    }

    function test_reorderMovesEntriesInsteadOfRecreatingThem() {
        const model = makeModel([makeEntry("keyboard-1"), makeEntry("mouse-1")]);
        const inserted = makeSpy(model, "rowsInserted");
        const removed = makeSpy(model, "rowsRemoved");

        model.entries = [makeEntry("mouse-1"), makeEntry("keyboard-1")];

        compare(keys(model), ["mouse-1", "keyboard-1"]);
        compare(inserted.count, 0);
        compare(removed.count, 0);
    }

    function test_survivingDelegatesOutliveAMidPillJoin() {
        const model = makeModel([makeEntry("mouse-1"), makeEntry("headset-1")]);
        const repeater = makeRepeater(model);
        const mouseDelegate = repeater.itemAt(0);
        const headsetDelegate = repeater.itemAt(1);

        model.entries = [makeEntry("mouse-1"), makeEntry("keyboard-1"), makeEntry("headset-1")];

        compare(repeater.count, 3);
        verify(repeater.itemAt(0) === mouseDelegate);
        verify(repeater.itemAt(2) === headsetDelegate);
        verify(repeater.itemAt(1) !== mouseDelegate);
        verify(repeater.itemAt(1) !== headsetDelegate);
    }

    function test_survivingDelegatesOutliveALeave() {
        const model = makeModel([makeEntry("mouse-1"), makeEntry("keyboard-1"), makeEntry("headset-1")]);
        const repeater = makeRepeater(model);
        const mouseDelegate = repeater.itemAt(0);
        const headsetDelegate = repeater.itemAt(2);

        model.entries = [makeEntry("mouse-1"), makeEntry("headset-1")];

        compare(repeater.count, 2);
        verify(repeater.itemAt(0) === mouseDelegate);
        verify(repeater.itemAt(1) === headsetDelegate);
    }

    function test_readingChangeKeepsTheDelegate() {
        const model = makeModel([makeEntry("mouse-1", {
                "percentText": "75%"
            })]);
        const repeater = makeRepeater(model);
        const mouseDelegate = repeater.itemAt(0);

        model.entries = [makeEntry("mouse-1", {
                "percentText": "42%"
            })];

        compare(repeater.count, 1);
        verify(repeater.itemAt(0) === mouseDelegate);
    }

    Component {
        id: entryModelFactory

        WirelessBatteryEntryModel {}
    }

    Component {
        id: spyFactory

        SignalSpy {}
    }

    Component {
        id: repeaterFactory

        Repeater {
            delegate: Item {}
        }
    }
}
