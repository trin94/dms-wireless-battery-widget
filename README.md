<!--
SPDX-FileCopyrightText: Elias Mueller

SPDX-License-Identifier: MIT
-->

# 🔋 Wireless Battery Widget

[![Pipeline](https://github.com/trin94/dms-wireless-battery-widget/actions/workflows/verify.yml/badge.svg)](https://github.com/trin94/dms-wireless-battery-widget/actions/workflows/verify.yml)
[![REUSE status](https://api.reuse.software/badge/github.com/trin94/dms-wireless-battery-widget)](https://api.reuse.software/info/github.com/trin94/dms-wireless-battery-widget)
[![License: MIT](https://img.shields.io/github/license/trin94/dms-wireless-battery-widget)](LICENSES/MIT.txt)

A [Dank Material Shell](https://github.com/AvengeMedia/DankMaterialShell) plugin that shows the
battery levels of your wireless peripherals (mice, keyboards, game controllers, and headsets)
in the bar.

> [!IMPORTANT]
> 🤖 AI agents wrote this plugin entirely, with a human directing the agents
> using skills from the [AI Hero skills catalog](https://www.aihero.dev/skills-catalog).

![Preview](docs/preview.webp)

- 🔋 Every device gets its own entry in a single bar pill: class icon, percentage, and a bolt while charging.
- 💤 A device of a retained class stays visible when no longer live, dimmed at its last reading, until the session ends.
- 🚨 Low readings turn red, and a desktop notification fires when a device drops to its class's low threshold.
- 🪟 Click the pill for a popout with per-device detail.
- ⚙️ Settings cover tracked classes, retention, low thresholds, notifications, and appearance. Changes apply live.
- ↕️ The widget renders in horizontal and vertical bars.
- 🔌 Battery data comes straight from `Quickshell.Services.UPower`. The widget never polls.
- 🎮 An opt-in toggle adds the 2nd generation Steam Controller, which UPower cannot see yet.

## Requirements

You need Dank Material Shell 1.5.0 or newer, `notify-send` for the notifications, and devices
whose batteries UPower reports. Steam Controller support is optional and needs `python3`
(3.10 or newer). To check which of your devices qualify:

```sh
for d in $(upower -e); do
    upower -i "$d" | grep -qE '^  (mouse|touchpad|keyboard|gaming-input|headset|headphones)$' && echo "$d"
done
```

If a device is missing from the output, its driver does not expose the battery to UPower and the widget cannot see it.

## Steam Controller (2nd gen)

The 2nd generation Steam Controller (2026) has no kernel driver yet, so UPower does not report
its battery. The widget can follow it anyway: enable **Track Steam Controller batteries
(2nd gen)** in the plugin settings. While the toggle is on, a `python3` helper only listens
to the battery reports the controller already broadcasts. It never writes to the device, so
it cannot interfere with Steam or your games. The controller then behaves like any other
tracked device: pill entry, charging bolt, tones, low-battery notification.

The toggle is off by default. Turning it on or off takes effect right away, without restarting
the shell. Once a future kernel reports the controller through UPower, the helper stops by
itself and UPower takes over.

## Installation

This plugin is not yet in the official third-party plugin repository, so install it manually.

Clone the repo into the DMS plugins directory:

```sh
git clone https://github.com/trin94/dms-wireless-battery-widget.git ~/.config/DankMaterialShell/plugins/dms-wireless-battery-widget
```

Or clone it anywhere and symlink it in:

```sh
git clone https://github.com/trin94/dms-wireless-battery-widget.git
mkdir -p ~/.config/DankMaterialShell/plugins
ln -s "$PWD/dms-wireless-battery-widget" ~/.config/DankMaterialShell/plugins/dms-wireless-battery-widget
```

Then add the widget to the bar from [the plugin settings](https://danklinux.com/docs/dankmaterialshell/plugin-development#5-load-it).

## Roadmap

- Devices whose batteries UPower does not report.

## Alternatives

- [dms-mouse-battery](https://github.com/Ripolin99/dms-mouse-battery) also shows the mouse
  battery in DMS and adds DPI preset switching via Solaar or ratbagctl.

## Contributing

Set up the dev environment per the official [plugin development guide](https://danklinux.com/docs/dankmaterialshell/plugin-development#development-environment),
with one change: this is a standalone repo, so don't create a directory under `dms-plugins/`.

Instead, clone the repo into a directory of your choice, then run `just init`.

Required tools:

- [just](https://github.com/casey/just) runs the development tasks.
- [uv](https://docs.astral.sh/uv/) manages the Python environment and installs all dev dependencies itself.
- `dbus-daemon` hosts the private bus the mock bar fakes UPower on.
- `dms` drives the hot-reload recipes. It comes with Dank Material Shell.

The most important recipes (run `just` for the full list):

```sh
just init        # Set up the development environment
just fmt         # Run all formatting and lint hooks
just test        # Run the QML unit tests
just test-python # Run the Python unit tests
just reload      # Reload the plugin after making changes
just mock start  # Show the widget in a mock bar with fake devices for every class
```

`just test` runs the `tst_*.qml` files through Qt Quick Test on a PySide6 engine. A fake
UPower service stands in for the real daemon, and QML fakes of the DMS `qs.*` modules
(`src/qs_fake`) let the pill views render under test.

The product spec lives in
[issue #1](https://github.com/trin94/dms-wireless-battery-widget/issues/1), the domain glossary
in [CONTEXT.md](CONTEXT.md), and the architectural decisions in [docs/adr](docs/adr).
