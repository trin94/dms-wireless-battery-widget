# Liveness gates on presence, not charge state

A device is live while its source is ready, UPower reports it present, and it reports a
non-zero percentage. Charge state is deliberately not a liveness signal: Bluetooth's battery
interface exposes only a percentage, so UPower keeps headsets at state Unknown permanently,
and the old `state !== Unknown` gate kept them from ever becoming live — and, because the
roster only admits a device the first time it is live, from ever appearing at all. We rejected
exempting only headset classes from the state check because charge state is untrustworthy as a
liveness signal for any class; transient unknowns (a sleeping mouse) are already caught by the
ready and percentage clauses. Consequence: a live device with unknown charge state counts as
discharging, so it gets low tones and notifications but never shows as charging; in practice
headsets drop off UPower while charging and simply go stale.
