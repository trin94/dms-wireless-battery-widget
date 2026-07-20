<!--
SPDX-FileCopyrightText: Elias Mueller

SPDX-License-Identifier: MIT
-->

# 🔋 Wireless Battery Widget

A [Dank Material Shell](https://github.com/AvengeMedia/DankMaterialShell) plugin that shows the
battery levels of wireless peripherals — mice, keyboards, game controllers, and headsets — in
the bar.

Work in progress: every live device reported through UPower shows up in the horizontal bar
pill with its class icon, battery percentage, and a charging bolt while it charges, in a fixed
order (mouse, keyboard, controller, headset) that never reshuffles. A device that is no longer
live stays as a dimmed stale entry at its last reading until the session ends. A draining device
that drops to its class's low threshold turns red in the bar and raises one desktop notification
through notify-send, re-arming only after the battery recovers past a margin. The popout and the
settings page are not implemented yet. The product spec lives in
[issue #1](https://github.com/trin94/dms-wireless-battery-widget/issues/1),
the domain glossary in [CONTEXT.md](CONTEXT.md), and the architectural decisions in
[docs/adr](docs/adr). This plugin will supersede
[mouse-battery-widget](https://github.com/trin94/mouse-battery-widget).

## Contributing

Run `just` to see the common commands. Set up the dev environment with `just init`.
