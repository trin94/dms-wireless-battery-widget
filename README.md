<!--
SPDX-FileCopyrightText: Elias Mueller

SPDX-License-Identifier: MIT
-->

# 🔋 Wireless Battery Widget

A [Dank Material Shell](https://github.com/AvengeMedia/DankMaterialShell) plugin that shows the
battery levels of wireless peripherals — mice, keyboards, game controllers, and headsets — in
the bar.

Work in progress: a live mouse reported through UPower already shows up in the horizontal bar
pill with its class icon, battery percentage, and a charging bolt while it charges. The
remaining device classes, stale entries, notifications, the popout, and settings are not
implemented yet. The product spec lives in
[issue #1](https://github.com/trin94/dms-wireless-battery-widget/issues/1),
the domain glossary in [CONTEXT.md](CONTEXT.md), and the architectural decisions in
[docs/adr](docs/adr). This plugin will supersede
[mouse-battery-widget](https://github.com/trin94/mouse-battery-widget).

## Contributing

Run `just` to see the common commands. Set up the dev environment with `just init`.
