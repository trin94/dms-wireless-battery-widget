# Steam Controller batteries come from a read-only listener

The 2nd generation Steam Controller (2026) has no kernel driver, so it never appears in UPower,
the plugin's only source until now. We add a second, opt-in source: the daemon spawns a
stdlib-only Python helper that passively reads the battery reports the controller already
broadcasts on its hidraw nodes, with the report layout learned from SDL's zlib-licensed Triton
driver. The helper never writes to the device, so it cannot conflict with Steam, and it only
touches nodes the kernel left to hid-generic — the day hid-steam claims the hardware and UPower
reports it, the source stands down by itself. Liveness comes from the documented
connect/disconnect events with a battery-report timeout as fallback, so a firmware change
degrades detection instead of breaking it. We rejected waiting for kernel support because its
timeline is unknown, an SDL-linked helper because SDL writes to the device and fights Steam for
it, and an out-of-tree kernel module because building per distro is a separate project. The
cost we accept: we own a reverse-engineered protocol Valve may change, a python3 (>= 3.10)
runtime dependency, and an off-by-default toggle owners must find.
