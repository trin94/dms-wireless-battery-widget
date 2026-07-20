# Core consumes an internal device model, UPower is an adapter

The core (view models, monitoring, notifications) never touches `UPowerDevice` directly. It
consumes an internal device shape — id, class, name, battery level, charge state, liveness —
produced by a source adapter, with UPower as the only source at ship. Two reasons: tests feed
fake devices into the core without a D-Bus/UPower fake underneath, and devices invisible to
UPower can be added later as another adapter without reshaping the model. Concrete case: the
Steam Controller (2026, "Steam Controller Puck" dongle) has no kernel battery driver, so UPower
cannot see it; its battery is only readable via Valve's proprietary HID protocol. Steam
Controller support is out of scope for v1, but the seam is designed for it.
