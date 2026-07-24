# SPDX-FileCopyrightText: Elias Mueller
#
# SPDX-License-Identifier: MIT

export PYTHONPATH := source_directory() / '..'

DMS_ROOT := if path_exists(config_directory() / 'quickshell' / 'dms' / 'shell.qml') == 'true' { config_directory() / 'quickshell' / 'dms' } else { '/usr/share/quickshell/dms' }
LOG := env('XDG_RUNTIME_DIR', '/tmp') / 'wireless-battery-mock.log'
CONTROL := 'io.github.trin94.WirelessBatteryWidget.Mock'
SERVE := source_directory() / 'serve.py'
PREVIEW := source_directory() / 'preview'

[private]
@default:
    just --unsorted --list mock

# Start a mock bar containing only the widget
[group('bar')]
start: _links
    #!/usr/bin/env sh
    if pgrep -f 'src/mock/serve[.]py' >/dev/null; then
        echo 'mock bar already running'
        exit 0
    fi
    setsid --fork sh -c 'exec uv run "{{ SERVE }}" >"{{ LOG }}" 2>&1'
    echo 'mock bar started, log: {{ LOG }}'

# Replay a cold boot: zero every reading, then forget the session
[group('bar')]
cold:
    #!/usr/bin/env sh
    busctl --user call {{ CONTROL }} / {{ CONTROL }} RunPreset s cold-boot >/dev/null || { echo 'hint: start the mock bar with `just mock start`'; exit 1; }
    qs -p '{{ PREVIEW }}' ipc call bar reset || { echo 'hint: start the mock bar with `just mock start`'; exit 1; }

# Stop the mock bar
[group('bar')]
stop:
    #!/usr/bin/env sh
    pkill -f 'src/mock/serve[.]py' || { echo 'mock bar is not running'; exit 0; }
    echo 'mock bar stopped'

# Turn the mock bar into a vertical (left) bar, or back (true, false)
[group('bar')]
@vertical value:
    qs -p '{{ PREVIEW }}' ipc call bar vertical '{{ value }}' || { echo 'hint: start the mock bar with `just mock start`'; exit 1; }

# Toggle the widget popout on the mock bar
[group('bar')]
@popout:
    qs -p '{{ PREVIEW }}' ipc call bar popout || { echo 'hint: start the mock bar with `just mock start`'; exit 1; }

# List the mock devices and their current readings
[group('device')]
devices:
    #!/usr/bin/env sh
    reply=$(busctl --user call {{ CONTROL }} / {{ CONTROL }} ListDevices) || { echo 'hint: start the mock bar with `just mock start`'; exit 1; }
    reply=${reply#'s "'}
    printf '%b\n' "${reply%'"'}"

# Wake a mock device with its first reading (pairs with `cold`)
[group('device')]
@wake device:
    busctl --user call {{ CONTROL }} / {{ CONTROL }} Wake s {{ device }} || { echo 'hint: start the mock bar with `just mock start`'; exit 1; }

# Plug a mock device back in
[group('device')]
@connect device:
    busctl --user call {{ CONTROL }} / {{ CONTROL }} SetConnected sb {{ device }} true || { echo 'hint: start the mock bar with `just mock start`'; exit 1; }

# Unplug a mock device to preview the stale state
[group('device')]
@disconnect device:
    busctl --user call {{ CONTROL }} / {{ CONTROL }} SetConnected sb {{ device }} false || { echo 'hint: start the mock bar with `just mock start`'; exit 1; }

# Set a mock device's battery percentage on the running bar
[group('device')]
@percentage device value:
    busctl --user call {{ CONTROL }} / {{ CONTROL }} SetPercentage sd {{ device }} {{ value }} || { echo 'hint: start the mock bar with `just mock start`'; exit 1; }

# Set a mock device's charge state on the running bar (unknown, charging, discharging, empty, full, pending-charge)
[group('device')]
@state device value:
    busctl --user call {{ CONTROL }} / {{ CONTROL }} SetState ss {{ device }} {{ value }} || { echo 'hint: start the mock bar with `just mock start`'; exit 1; }

# Set a mock device's name on the running bar (empty previews the fallback name)
[group('device')]
@name device value:
    busctl --user call {{ CONTROL }} / {{ CONTROL }} SetModel ss {{ device }} '{{ value }}' || { echo 'hint: start the mock bar with `just mock start`'; exit 1; }

# Set a mock device's seconds until empty on the running bar (0 hides the estimate)
[group('device')]
@time-to-empty device seconds:
    busctl --user call {{ CONTROL }} / {{ CONTROL }} SetTimeToEmpty sx {{ device }} {{ seconds }} || { echo 'hint: start the mock bar with `just mock start`'; exit 1; }

# Set a mock device's seconds until full on the running bar (0 hides the estimate)
[group('device')]
@time-to-full device seconds:
    busctl --user call {{ CONTROL }} / {{ CONTROL }} SetTimeToFull sx {{ device }} {{ seconds }} || { echo 'hint: start the mock bar with `just mock start`'; exit 1; }

# List the plugin settings the mock accepts and their defaults
[group('plugin')]
@settings:
    qs -p '{{ PREVIEW }}' ipc call settings list || { echo 'hint: start the mock bar with `just mock start`'; exit 1; }

# Change a plugin setting on the running bar (e.g. lowBatteryPercent 40)
[group('plugin')]
@setting key value:
    qs -p '{{ PREVIEW }}' ipc call settings set '{{ key }}' '{{ value }}' || { echo 'hint: start the mock bar with `just mock start`'; exit 1; }

# Replay a scripted scenario on the running bar (bare: list the presets)
[group('preset')]
preset name='':
    #!/usr/bin/env sh
    if [ -z '{{ name }}' ]; then
        reply=$(busctl --user call {{ CONTROL }} / {{ CONTROL }} ListPresets) || { echo 'hint: start the mock bar with `just mock start`'; exit 1; }
    else
        reply=$(busctl --user call {{ CONTROL }} / {{ CONTROL }} RunPreset s '{{ name }}') || { echo 'hint: start the mock bar with `just mock start`'; exit 1; }
    fi
    reply=${reply#'s "'}
    echo "${reply%'"'}"

[private]
@_links:
    for entry in '{{ DMS_ROOT }}'/*/; do ln -sfn "${entry%/}" preview/; done
    ln -sfn ../../qml preview/WirelessBattery
