# Retention filters the roster's output, it never forgets

Whether a device that stopped being live stays shown depends on its class being retained. That
decision is a source decorator, `WirelessBatteryRetainedClassFilter`, the same shape as the
tracked-class filter: it wraps another source and re-exposes a device if the device is live or
its class is retained. It sits between the roster and the tracked-class filter in the chain
feeding both view models, so the tracked-class filter still operates on the roster's output as
ADR 0005 intends. Retention filters, never forgets — the roster's session memory stays intact,
which is what lets a vanished device reappear at its last reading when it is live again or when
its class becomes retained again. We rejected evicting non-retained devices from the roster
because eviction would lose the last reading and make reappearing impossible without a fresh
live report.
