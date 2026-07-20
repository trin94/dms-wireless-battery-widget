# Wireless Peripheral Battery

Battery levels of wireless peripherals (mice, keyboards, game controllers, headsets) shown in the DMS bar. One widget instance, one entry per device.

## Language

**Tracked Device**:
A device of a tracked class whose battery the plugin follows. Every tracked device gets its own entry; there is no per-class aggregation.
_Avoid_: peripheral, gadget

**Tracked Class**:
A device class the user has enabled. Devices of untracked classes do not exist for the plugin — no entry, no notification.
_Avoid_: visible class, enabled class

**Device Class**:
The kind of tracked device — mouse, keyboard, controller, or headset. An attribute of a device that drives its icon and visibility toggles, never identity or grouping.
_Avoid_: device type, category

**Source**:
A backend that discovers devices and reports their battery. UPower is the only source at ship.
_Avoid_: provider, backend, adapter

**Reading**:
A device's battery level and charge state as reported by a source at a moment in time.
_Avoid_: measurement, sample

**Live**:
A tracked device is live while a source is currently reporting its battery.
_Avoid_: reporting, online, connected

**Stale**:
A tracked device is stale while it is shown at its last reading without being live. Stale devices are forgotten when the session ends.
_Avoid_: sleeping, disconnected, offline
