# Wireless Peripheral Battery

Battery levels of wireless peripherals (mice, keyboards, game controllers, headsets) shown in the
DMS bar. One widget instance, one entry per device.

## Language

**Tracked Device**:
A device of a tracked class whose battery the plugin follows. Every tracked device gets its own
entry; there is no per-class aggregation.
*Avoid*: peripheral, gadget

**Tracked Class**:
A device class the user has enabled. Devices of untracked classes do not exist for the plugin —
no entry, no notification.
*Avoid*: visible class, enabled class

**Device Class**:
The kind of tracked device — mouse, keyboard, controller, or headset. An attribute of a device
that drives its icon and visibility toggles, never identity or grouping.
*Avoid*: device type, category

**Source**:
A backend that discovers devices and reports their battery. UPower is the only source at ship.
*Avoid*: provider, backend, adapter

**Reading**:
A device's battery level and charge state as reported by a source at a moment in time.
*Avoid*: measurement, sample

**Live**:
A tracked device is live while a source is currently reporting its battery.
*Avoid*: reporting, online, connected

**Stale**:
A tracked device is stale while it is shown at its last reading without being live. Stale devices
are forgotten when the session ends.
*Avoid*: sleeping, disconnected, offline

**Low Threshold**:
The per-class percentage at or below which a draining tracked device counts as low, driving the
low tone in the bar and the desktop notification.
*Avoid*: warning level, alarm level

**Re-arm Margin**:
How far above its low threshold a device must recover before another notification may fire.
*Avoid*: hysteresis, debounce

**Time Estimate**:
The remaining time a source predicts for a live device: to empty while draining, to full while
charging. Stale devices have no time estimate.
*Avoid*: runtime, battery life
