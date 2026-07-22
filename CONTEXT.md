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

**Retained Class**:
A tracked class whose devices remain shown as stale entries when they stop being live. Devices
of a non-retained class vanish the moment they are not live; they reappear at their last reading
if the class becomes retained again during the session.
*Avoid*: sticky, persistent, lingering, keep-on-disconnect

**Source**:
A backend that discovers devices and reports their battery. UPower is the only source at ship.
*Avoid*: provider, backend, adapter

**Reading**:
A device's battery level and charge state as reported by a source at a moment in time.
*Avoid*: measurement, sample

**Live**:
A tracked device is live while a source is currently reporting its battery. A reported level
is enough; a device whose charge state is unknown is still live.
*Avoid*: reporting, online, connected

**Stale**:
A tracked device is stale while it is shown at its last reading without being live. Only devices
of a retained class go stale. Stale devices are forgotten when the session ends.
*Avoid*: sleeping, disconnected, offline

**Pill**:
The widget's face in the bar: a row or column of entries, one per tracked device.
*Avoid*: applet, indicator, bar widget

**Capsule**:
The pill's outer bounds in the bar; no part of an entry ever shows outside it. It hugs the
entries while they animate and eases closed only after a leave.
*Avoid*: frame, outline, background

**Entry**:
One tracked device's slice of the pill: class icon, bolt slot, and percent.
*Avoid*: item, cell, row

**Bolt Slot**:
The space in an entry between class icon and percent that holds the bolt while the device
charges; closed otherwise.
*Avoid*: charging icon, bolt gap

**Reveal**:
A joining entry's grow-in at its sorted position, fading in as it expands.
*Avoid*: fade-in, pop-in, appear animation

**Popout**:
The panel opened from the pill, showing each tracked device in detail.
*Avoid*: popup, flyout, dropdown

**Tone**:
The at-a-glance coloring of a tracked device's entry: normal, low, charging, or stale.
*Avoid*: status color, severity

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
