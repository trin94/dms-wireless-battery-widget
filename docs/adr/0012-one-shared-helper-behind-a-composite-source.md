# One shared helper behind a composite source

The Steam Controller Source's devices are needed twice: the daemon feeds them to the monitor
for notifications, and every widget instance feeds them to its roster for pill and popout. Yet
only one helper process should ever run, and only while the opt-in toggle is on. The source
therefore lives in a module singleton, `WirelessBatterySteamController`: the daemon binds the
`steamControllerEnabled` setting to its `enabled` switch, the singleton runs the helper process
while enabled, and daemon and widget each merge the singleton's source with their own UPower
source through `WirelessBatteryCompositeSource`. The composite re-exposes the Source contract —
merged device list, forwarded withdrawals — so everything downstream stays single-source and
unaware of the change, as ADR 0003 and 0005 intend. Disabling the toggle stops the helper and
withdraws the source's devices, which the roster forgets per ADR 0008's scope. We rejected one
helper per component because several bars would each spawn a process for the same read-only
hidraw nodes, and a daemon-only source because plugin components share nothing but the QML
engine, leaving no channel to hand devices to the widgets. We also rejected merging below QML
by feeding the controller into UPower itself: stock UPower has no API for userland devices, so
every route in — a kernel module, a uhid ghost device, or proxying the whole system bus — is a
privileged component larger than the merge plumbing it would delete. The cost we accept: singleton state
is shared engine-wide, so the process shell stays a thin, untested wrapper around the tested
line-consumer source.
