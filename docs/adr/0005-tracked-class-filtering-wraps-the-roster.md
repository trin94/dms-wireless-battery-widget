# Tracked-class filtering wraps the roster, not the raw source

Turning off a device class is meant to make its devices cease to exist for the plugin
immediately, including ones already sitting in the bar as stale entries. Tracked-class filtering
is a source decorator, `WirelessBatteryTrackedClassFilter`, the same shape as the roster: it wraps
another source and re-exposes only devices whose class the user tracks. For the bar and popout it
wraps the roster's output rather than the raw UPower source, because the roster never forgets a
device it has seen live — it only marks it stale — so filtering upstream of the roster would leave
an untracked class's already-stale devices sitting in the roster's memory, still rendered. Wrapping
the roster's output instead makes the filter re-evaluate on every roster change, dropping the class
immediately regardless of staleness. The daemon's monitor has no roster and only reacts to
currently-live readings, so it filters the raw source directly.
