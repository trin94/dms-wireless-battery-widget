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

# Stop the mock bar
[group('bar')]
stop:
    #!/usr/bin/env sh
    pkill -f 'src/mock/serve[.]py' || { echo 'mock bar is not running'; exit 0; }
    echo 'mock bar stopped'

# Plug the mock device back in
[group('device')]
@connect:
    busctl --user call {{ CONTROL }} / {{ CONTROL }} SetConnected b true || { echo 'hint: start the mock bar with `just mock start`'; exit 1; }

# Unplug the mock device to preview the stale state
[group('device')]
@disconnect:
    busctl --user call {{ CONTROL }} / {{ CONTROL }} SetConnected b false || { echo 'hint: start the mock bar with `just mock start`'; exit 1; }

# Set the mock battery percentage on the running bar
[group('device')]
@percentage value:
    busctl --user call {{ CONTROL }} / {{ CONTROL }} SetPercentage d {{ value }} || { echo 'hint: start the mock bar with `just mock start`'; exit 1; }

# Set the mock charge state on the running bar (unknown, charging, discharging, empty, full, pending-charge)
[group('device')]
@state value:
    busctl --user call {{ CONTROL }} / {{ CONTROL }} SetState s {{ value }} || { echo 'hint: start the mock bar with `just mock start`'; exit 1; }

# Set the mock product name on the running bar (empty previews the fallback name)
[group('device')]
@model value:
    busctl --user call {{ CONTROL }} / {{ CONTROL }} SetModel s '{{ value }}' || { echo 'hint: start the mock bar with `just mock start`'; exit 1; }

# Set the mock seconds until empty on the running bar (0 hides the estimate)
[group('device')]
@time-to-empty seconds:
    busctl --user call {{ CONTROL }} / {{ CONTROL }} SetTimeToEmpty x {{ seconds }} || { echo 'hint: start the mock bar with `just mock start`'; exit 1; }

# Set the mock seconds until full on the running bar (0 hides the estimate)
[group('device')]
@time-to-full seconds:
    busctl --user call {{ CONTROL }} / {{ CONTROL }} SetTimeToFull x {{ seconds }} || { echo 'hint: start the mock bar with `just mock start`'; exit 1; }

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
