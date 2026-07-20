// SPDX-FileCopyrightText: Elias Mueller
//
// SPDX-License-Identifier: MIT

import QtQuick

import qs.Common
import qs.Modules.Plugins
import qs.Widgets

import "logic"

PluginSettings {
    id: root

    pluginId: "wirelessBatteryWidget"

    StyledText {
        text: I18n.tr("Bar")
        font.pixelSize: Theme.fontSizeMedium
        font.weight: Font.Medium
        color: Theme.surfaceText
    }

    ToggleSetting {
        settingKey: "showPercentage"
        label: I18n.tr("Show battery percentage")
        defaultValue: WirelessBatteryDefaults.showPercentage
    }

    ToggleSetting {
        settingKey: "showBolt"
        label: I18n.tr("Show charging indicator")
        defaultValue: WirelessBatteryDefaults.showBolt
    }

    Rectangle {
        width: parent.width
        height: 1
        color: Theme.outline
        opacity: 0.3
    }

    StyledText {
        text: I18n.tr("Notifications")
        font.pixelSize: Theme.fontSizeMedium
        font.weight: Font.Medium
        color: Theme.surfaceText
    }

    ToggleSetting {
        settingKey: "notificationsEnabled"
        label: I18n.tr("Notify on low battery")
        description: I18n.tr("Send a desktop notification when a tracked device drops to its class's low threshold")
        defaultValue: WirelessBatteryDefaults.notificationsEnabled
    }

    Rectangle {
        width: parent.width
        height: 1
        color: Theme.outline
        opacity: 0.3
    }

    StyledText {
        text: I18n.tr("Mouse")
        font.pixelSize: Theme.fontSizeMedium
        font.weight: Font.Medium
        color: Theme.surfaceText
    }

    ToggleSetting {
        id: mouseTrackedToggle

        settingKey: "mouseTracked"
        label: I18n.tr("Track mouse battery")
        defaultValue: WirelessBatteryDefaults.mouseTracked
    }

    SliderSetting {
        settingKey: "mouseLowThreshold"
        label: I18n.tr("Low threshold")
        description: I18n.tr("Battery percentage at or below which a draining mouse counts as low")
        defaultValue: WirelessBatteryDefaults.mouseLowThreshold
        minimum: 0
        maximum: 100
        unit: "%"
        enabled: mouseTrackedToggle.value
    }

    Rectangle {
        width: parent.width
        height: 1
        color: Theme.outline
        opacity: 0.3
    }

    StyledText {
        text: I18n.tr("Keyboard")
        font.pixelSize: Theme.fontSizeMedium
        font.weight: Font.Medium
        color: Theme.surfaceText
    }

    ToggleSetting {
        id: keyboardTrackedToggle

        settingKey: "keyboardTracked"
        label: I18n.tr("Track keyboard battery")
        defaultValue: WirelessBatteryDefaults.keyboardTracked
    }

    SliderSetting {
        settingKey: "keyboardLowThreshold"
        label: I18n.tr("Low threshold")
        description: I18n.tr("Battery percentage at or below which a draining keyboard counts as low")
        defaultValue: WirelessBatteryDefaults.keyboardLowThreshold
        minimum: 0
        maximum: 100
        unit: "%"
        enabled: keyboardTrackedToggle.value
    }

    Rectangle {
        width: parent.width
        height: 1
        color: Theme.outline
        opacity: 0.3
    }

    StyledText {
        text: I18n.tr("Controller")
        font.pixelSize: Theme.fontSizeMedium
        font.weight: Font.Medium
        color: Theme.surfaceText
    }

    ToggleSetting {
        id: controllerTrackedToggle

        settingKey: "controllerTracked"
        label: I18n.tr("Track controller battery")
        defaultValue: WirelessBatteryDefaults.controllerTracked
    }

    SliderSetting {
        settingKey: "controllerLowThreshold"
        label: I18n.tr("Low threshold")
        description: I18n.tr("Battery percentage at or below which a draining controller counts as low")
        defaultValue: WirelessBatteryDefaults.controllerLowThreshold
        minimum: 0
        maximum: 100
        unit: "%"
        enabled: controllerTrackedToggle.value
    }

    Rectangle {
        width: parent.width
        height: 1
        color: Theme.outline
        opacity: 0.3
    }

    StyledText {
        text: I18n.tr("Headset")
        font.pixelSize: Theme.fontSizeMedium
        font.weight: Font.Medium
        color: Theme.surfaceText
    }

    ToggleSetting {
        id: headsetTrackedToggle

        settingKey: "headsetTracked"
        label: I18n.tr("Track headset battery")
        defaultValue: WirelessBatteryDefaults.headsetTracked
    }

    SliderSetting {
        settingKey: "headsetLowThreshold"
        label: I18n.tr("Low threshold")
        description: I18n.tr("Battery percentage at or below which a draining headset counts as low")
        defaultValue: WirelessBatteryDefaults.headsetLowThreshold
        minimum: 0
        maximum: 100
        unit: "%"
        enabled: headsetTrackedToggle.value
    }
}
