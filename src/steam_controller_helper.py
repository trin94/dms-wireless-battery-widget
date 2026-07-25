# SPDX-FileCopyrightText: Elias Mueller
#
# SPDX-License-Identifier: MIT

"""Watches 2nd generation Steam Controllers and prints battery JSON lines.

Written by Claude Fable 5.

Standard library only, compatible with Python 3.10 and newer. Matching hidraw
nodes are opened read-only; the helper never writes to a device. It only opens
nodes still bound to the generic HID driver, so it stands down by itself once a
real kernel driver claims the hardware. The report layout is derived from SDL's
zlib-licensed Steam Controller driver (SDL_hidapi_steam_triton.c), used as
protocol reference only; no SDL code is copied.

One JSON object per line on stdout, each carrying the receiver serial and the
interface slot that identify the controller:

    {"event": "battery", "level": 78, "state": "discharging", "serial": "FXB995480177F", "slot": 0}
    {"event": "connect", "serial": "FXB995480177F", "slot": 0}
    {"event": "disconnect", "serial": "FXB995480177F", "slot": 0}
    {"event": "removed", "serial": "FXB995480177F", "slot": 0}

Battery states: discharging, charging, chargingDone, srcValidate, reset, or
unknown. A removed line means the node disappeared, e.g. the dongle was
unplugged. For nodes that report no serial the USB port path stands in, so the
identity holds within a session but not across ports.
"""

import contextlib
import json
import os
import re
import select
import time
from dataclasses import dataclass
from pathlib import Path

VALVE_VENDOR = 0x28DE
SECOND_GEN_PRODUCTS = frozenset({0x1302, 0x1303, 0x1304, 0x1305})
GENERIC_HID_DRIVER = "hid-generic"
HID_ID_FIELDS = 3

BATTERY_REPORT = 0x43
BATTERY_REPORT_SIZE = 15
WIRELESS_REPORTS = frozenset({0x46, 0x79})
WIRELESS_REPORT_SIZE = 2
CHARGE_STATES = {0: "reset", 1: "discharging", 2: "charging", 3: "srcValidate", 4: "chargingDone"}
WIRELESS_EVENTS = {1: "disconnect", 2: "connect"}

SYSFS_HIDRAW = Path("/sys/class/hidraw")
RESCAN_INTERVAL_S = 5.0
READ_SIZE = 64


@dataclass(frozen=True, slots=True)
class Identity:
    serial: str
    slot: int


@dataclass(frozen=True, slots=True)
class OpenNode:
    fd: int
    identity: Identity


def parse_report(data: bytes) -> dict[str, str | int] | None:
    if not data:
        return None
    if data[0] == BATTERY_REPORT and len(data) >= BATTERY_REPORT_SIZE:
        return {"event": "battery", "level": data[2], "state": CHARGE_STATES.get(data[1], "unknown")}
    if data[0] in WIRELESS_REPORTS and len(data) >= WIRELESS_REPORT_SIZE and data[1] in WIRELESS_EVENTS:
        return {"event": WIRELESS_EVENTS[data[1]]}
    return None


def plan_nodes(uevents: dict[str, str]) -> dict[str, Identity]:
    matches = {node: facts for node, uevent in uevents.items() if (facts := _second_gen_facts(uevent))}
    plan = {}
    next_slot: dict[str, int] = {}
    for node, (serial, _) in sorted(matches.items(), key=lambda match: (_natural_order(match[1][1]), match[0])):
        slot = next_slot.get(serial, 0)
        next_slot[serial] = slot + 1
        plan[node] = Identity(serial, slot)
    return plan


def _second_gen_facts(uevent: str) -> tuple[str, str] | None:
    fields = dict(line.split("=", 1) for line in uevent.splitlines() if "=" in line)
    hid_id = fields.get("HID_ID", "").split(":")
    if len(hid_id) != HID_ID_FIELDS:
        return None
    try:
        vendor, product = int(hid_id[1], 16), int(hid_id[2], 16)
    except ValueError:
        return None
    if vendor != VALVE_VENDOR or product not in SECOND_GEN_PRODUCTS:
        return None
    if fields.get("DRIVER") != GENERIC_HID_DRIVER:
        return None
    phys = fields.get("HID_PHYS", "")
    serial = fields.get("HID_UNIQ") or phys.partition("/")[0]
    if not serial:
        return None
    return serial, phys


def _natural_order(phys: str) -> list[str | int]:
    return [int(part) if part.isdigit() else part for part in re.split(r"(\d+)", phys)]


def _read_uevent(entry: Path) -> str:
    try:
        return (entry / "device" / "uevent").read_text()
    except OSError:
        return ""


def _scan() -> dict[str, Identity]:
    entries = SYSFS_HIDRAW.iterdir() if SYSFS_HIDRAW.is_dir() else ()
    return plan_nodes({entry.name: _read_uevent(entry) for entry in entries})


def _emit(event: dict[str, str | int], identity: Identity) -> None:
    print(json.dumps({**event, "serial": identity.serial, "slot": identity.slot}), flush=True)


def _drop(node: str, open_nodes: dict[str, OpenNode]) -> None:
    opened = open_nodes.pop(node)
    with contextlib.suppress(OSError):
        os.close(opened.fd)
    _emit({"event": "removed"}, opened.identity)


def _apply_scan(plan: dict[str, Identity], open_nodes: dict[str, OpenNode]) -> None:
    for node in list(open_nodes):
        if node not in plan:
            _drop(node, open_nodes)
    for node, identity in plan.items():
        if node in open_nodes:
            continue
        try:
            fd = os.open(f"/dev/{node}", os.O_RDONLY | os.O_NONBLOCK)
        except OSError:
            continue
        open_nodes[node] = OpenNode(fd, identity)


def _pump(node: str, open_nodes: dict[str, OpenNode]) -> None:
    opened = open_nodes[node]
    try:
        data = os.read(opened.fd, READ_SIZE)
    except BlockingIOError:
        return
    except OSError:
        _drop(node, open_nodes)
        return
    if not data:
        _drop(node, open_nodes)
        return
    event = parse_report(data)
    if event:
        _emit(event, opened.identity)


def main() -> None:
    open_nodes: dict[str, OpenNode] = {}
    next_scan = 0.0
    while True:
        now = time.monotonic()
        if now >= next_scan:
            _apply_scan(_scan(), open_nodes)
            next_scan = now + RESCAN_INTERVAL_S
        nodes_by_fd = {opened.fd: node for node, opened in open_nodes.items()}
        ready, _, _ = select.select(list(nodes_by_fd), [], [], max(next_scan - time.monotonic(), 0.0))
        for fd in ready:
            _pump(nodes_by_fd[fd], open_nodes)


if __name__ == "__main__":
    with contextlib.suppress(KeyboardInterrupt, BrokenPipeError):
        main()
