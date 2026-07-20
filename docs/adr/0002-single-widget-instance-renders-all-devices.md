# Single widget instance renders all devices

One widget instance shows every tracked device inside a single bar pill; the popout carries the
per-device detail. We rejected "one widget instance per device" because DMS stores plugin
settings per plugin id, not per widget instance, so there is no clean way to tell one instance
apart from another in configuration. Pill width growth is handled by per-class visibility toggles
in settings rather than by splitting into instances.
