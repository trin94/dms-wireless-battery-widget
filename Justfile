# SPDX-FileCopyrightText: Elias Mueller
#
# SPDX-License-Identifier: MIT

set lazy

PLUGIN_ID := 'wirelessBatteryWidget'
LINK := config_directory() / 'DankMaterialShell' / 'plugins' / file_name(justfile_directory())

alias fmt := format

# Preview the widget in a mock bar against mocked devices
mod mock 'src/mock'

[private]
@default:
    just --list --unsorted

# Set up the development environment
[group('dev')]
init:
    uv sync
    uv run src/qml_tooling.py

# Run all formatting and lint hooks
[group('dev')]
format:
    uv run prek run --all-files

# Update the pre-commit hook versions
[group('dev')]
update-hooks:
    uv run prek auto-update

# Upgrade all Python dependencies
[group('dev')]
update-dependencies:
    uv sync --upgrade

# Run the QML unit tests
[group('dev')]
test *args:
    uv run src/qml_test_main.py {{ args }}

# Run the Python unit tests
[group('dev')]
test-python *args:
    uv run pytest src {{ args }}

# List all plugins and their state
[group('dms')]
list:
    dms ipc call plugins list

# Check whether the plugin is running
[group('dms')]
status:
    dms ipc call plugins status {{ PLUGIN_ID }}

# Reload the plugin after making changes
[group('dms')]
reload:
    dms ipc call plugins reload {{ PLUGIN_ID }}

# Restart DMS with a fresh plugin symlink
[group('dms')]
restart:
    rm -f {{ LINK }}
    dms restart
    ln -s {{ justfile_directory() }} {{ LINK }}
