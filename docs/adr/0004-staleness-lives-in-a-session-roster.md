# Staleness lives in a session roster decorating the source

Staleness is handled by a session roster that is itself a source: it consumes the real source
and re-exposes every device that has been live this session, frozen at its last reading while
the device is not live. The UPower source keeps reporting only what UPower currently sees, and
view models stay memory-free and render whatever source they are given. We rejected remembering
last readings inside the bar view model because the popout needs the same session memory, and
duplicating it per consumer would let the surfaces disagree. Since the roster is a source,
everything downstream stays testable against a fake source, and the roster itself is tested the
same way.
