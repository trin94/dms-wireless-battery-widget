# SPDX-FileCopyrightText: Elias Mueller
#
# SPDX-License-Identifier: MIT

"""Serve a controllable mock device per class and run the preview bar against them."""

import asyncio
import os
import signal
import subprocess
import sys
import threading
from dataclasses import dataclass
from enum import IntEnum
from pathlib import Path

from dbus_fast import DBusError
from dbus_fast.aio import MessageBus
from dbus_fast.service import ServiceInterface, method

from upower_mock import UPowerMock

PREVIEW_DIR = Path(__file__).resolve().parent / "preview"

CONTROL_NAME = "io.github.trin94.WirelessBatteryWidget.Mock"
ERROR_NAME = CONTROL_NAME + ".Error"


class State(IntEnum):
    UNKNOWN = 0
    CHARGING = 1
    DISCHARGING = 2
    EMPTY = 3
    FULL = 4
    PENDING_CHARGE = 5


STATES = {member.name.lower().replace("_", "-"): int(member) for member in State}
STATE_NAMES = {number: name for name, number in STATES.items()}

MOUSE_TYPE = 5
KEYBOARD_TYPE = 6
GAMING_INPUT_TYPE = 12
HEADSET_TYPE = 17

MOCK_DEVICES: dict[str, dict[str, object]] = {
    "mouse": {
        "Type": MOUSE_TYPE,
        "State": int(State.DISCHARGING),
        "Percentage": 75.0,
        "Model": "Mock Mouse",
        "NativePath": "mock_battery_mouse",
        "TimeToEmpty": 4500,
        "TimeToFull": 2700,
    },
    "keyboard": {
        "Type": KEYBOARD_TYPE,
        "State": int(State.DISCHARGING),
        "Percentage": 60.0,
        "Model": "Mock Keyboard",
        "NativePath": "mock_battery_keyboard",
        "TimeToEmpty": 86400,
        "TimeToFull": 3600,
    },
    "controller": {
        "Type": GAMING_INPUT_TYPE,
        "State": int(State.DISCHARGING),
        "Percentage": 45.0,
        "Model": "Mock Controller",
        "NativePath": "mock_battery_controller",
        "TimeToEmpty": 9000,
        "TimeToFull": 5400,
    },
    "headset": {
        "Type": HEADSET_TYPE,
        "State": int(State.DISCHARGING),
        "Percentage": 30.0,
        "Model": "Mock Headset",
        "NativePath": "mock_battery_headset",
        "TimeToEmpty": 7200,
        "TimeToFull": 4500,
    },
    "mouse2": {
        "Type": MOUSE_TYPE,
        "State": int(State.DISCHARGING),
        "Percentage": 55.0,
        "Model": "Mock Travel Mouse",
        "NativePath": "mock_battery_mouse2",
        "TimeToEmpty": 5400,
        "TimeToFull": 3000,
    },
}

STALE_DEVICE = "mouse2"
STALE_AFTER_SECONDS = 6.0


@dataclass(frozen=True)
class Delay:
    seconds: float


@dataclass(frozen=True)
class Connected:
    device: str
    plugged: bool


@dataclass(frozen=True)
class Update:
    device: str
    state: State | None = None
    percentage: float | None = None
    model: str | None = None
    time_to_empty: int | None = None
    time_to_full: int | None = None

    def props(self) -> dict[str, object]:
        named = {
            "State": None if self.state is None else int(self.state),
            "Percentage": self.percentage,
            "Model": self.model,
            "TimeToEmpty": self.time_to_empty,
            "TimeToFull": self.time_to_full,
        }
        return {key: value for key, value in named.items() if value is not None}


Step = Delay | Connected | Update

PRESETS: dict[str, list[Step]] = {
    "fresh-login": [
        Update("mouse", state=State.UNKNOWN, percentage=0),
        Update("keyboard", state=State.UNKNOWN, percentage=0),
        Update("controller", state=State.UNKNOWN, percentage=0),
        Update("headset", state=State.UNKNOWN, percentage=0),
        Delay(1.0),
        Update("mouse", state=State.DISCHARGING, percentage=75),
        Delay(0.4),
        Update("keyboard", state=State.DISCHARGING, percentage=60),
        Delay(0.4),
        Update("controller", state=State.DISCHARGING, percentage=45),
        Delay(0.4),
        Update("headset", state=State.DISCHARGING, percentage=30),
    ],
    "wake-low": [
        Update("keyboard", state=State.DISCHARGING, percentage=80),
        Delay(0.6),
        Update("keyboard", state=State.UNKNOWN, percentage=0),
        Delay(0.6),
        Update("keyboard", state=State.DISCHARGING),
        Delay(0.4),
        Update("keyboard", percentage=8),
    ],
    "drain": [
        Update("controller", state=State.DISCHARGING, percentage=75),
        Delay(0.5),
        Update("controller", percentage=60),
        Delay(0.5),
        Update("controller", percentage=45),
        Delay(0.5),
        Update("controller", percentage=30),
        Delay(0.5),
        Update("controller", percentage=19),
    ],
    "charging-bounce": [
        Update("mouse", state=State.DISCHARGING, percentage=75),
        Delay(0.5),
        Update("mouse", percentage=18),
        Delay(0.6),
        Update("mouse", state=State.CHARGING),
        Delay(0.6),
        Update("mouse", state=State.DISCHARGING),
    ],
    "travel-mouse": [
        Connected("mouse2", plugged=True),
        Update("mouse2", state=State.DISCHARGING, percentage=55),
        Delay(1.5),
        Update("mouse2", percentage=54),
        Delay(1.5),
        Connected("mouse2", plugged=False),
    ],
    "sleep": [
        Update("mouse", state=State.UNKNOWN),
        Update("keyboard", state=State.UNKNOWN),
        Update("controller", state=State.UNKNOWN),
        Update("headset", state=State.UNKNOWN),
    ],
}


class MockDevice:
    """A mock device, which can be unplugged and plugged back in.

    Property updates while unplugged are kept and applied on replug.
    """

    def __init__(self, mock: UPowerMock, handle: str, props: dict[str, object]):
        self._mock = mock
        self._handle = handle
        self._props = dict(props)
        self._path: str | None = mock.add_device(handle, **self._props)

    def update(self, **props: object) -> None:
        self._props.update(props)
        if self._path is not None:
            self._mock.update_device(self._path, **props)

    def set_connected(self, connected: bool) -> None:
        if connected and self._path is None:
            self._path = self._mock.add_device(self._handle, **self._props)
        elif not connected and self._path is not None:
            self._mock.remove_device(self._path)
            self._path = None

    def describe(self) -> str:
        state = self._props["State"]
        state_name = STATE_NAMES[state] if isinstance(state, int) and state in STATE_NAMES else "unknown"
        plugged = "plugged" if self._path is not None else "unplugged"
        return f"{self._handle}: {self._props['Model']}, {self._props['Percentage']:g}%, {state_name}, {plugged}"


class MockControlService(ServiceInterface):
    """Session-bus control surface to adjust the mock devices at runtime."""

    def __init__(self, devices: dict[str, MockDevice]):
        super().__init__(CONTROL_NAME)
        self._devices = devices

    @method()
    def SetPercentage(self, device: "s", percentage: "d"):
        self._device(device).update(Percentage=percentage)

    @method()
    def SetState(self, device: "s", state: "s"):
        number = STATES.get(state)
        if number is None:
            message = f"unknown state: {state}, valid: {', '.join(STATES)}"
            raise DBusError(ERROR_NAME, message)
        self._device(device).update(State=number)

    @method()
    def SetConnected(self, device: "s", connected: "b"):
        self._device(device).set_connected(connected)

    @method()
    def SetModel(self, device: "s", model: "s"):
        self._device(device).update(Model=model)

    @method()
    def SetTimeToEmpty(self, device: "s", seconds: "x"):
        self._device(device).update(TimeToEmpty=seconds)

    @method()
    def SetTimeToFull(self, device: "s", seconds: "x"):
        self._device(device).update(TimeToFull=seconds)

    @method()
    def ListDevices(self) -> "s":
        return "\n".join(device.describe() for device in self._devices.values())

    @method()
    def ListPresets(self) -> "s":
        return ", ".join(PRESETS)

    @method()
    async def RunPreset(self, name: "s") -> "s":
        steps = PRESETS.get(name)
        if steps is None:
            return f"unknown preset: {name}, valid: {', '.join(PRESETS)}"
        for step in steps:
            await self._apply(step)
        return f"{name} done"

    def _device(self, handle: str) -> MockDevice:
        device = self._devices.get(handle)
        if device is None:
            message = f"unknown device: {handle}, valid: {', '.join(self._devices)}"
            raise DBusError(ERROR_NAME, message)
        return device

    async def _apply(self, step: Step) -> None:
        match step:
            case Delay(seconds):
                await asyncio.sleep(seconds)
            case Connected(device, plugged):
                self._devices[device].set_connected(plugged)
            case Update():
                self._devices[step.device].update(**step.props())


def export_control(devices: dict[str, MockDevice]) -> asyncio.AbstractEventLoop:
    loop = asyncio.new_event_loop()
    threading.Thread(target=loop.run_forever, daemon=True).start()

    async def export() -> None:
        bus = await MessageBus().connect()
        bus.export("/", MockControlService(devices))
        await bus.request_name(CONTROL_NAME)

    asyncio.run_coroutine_threadsafe(export(), loop).result(timeout=10)
    return loop


def run() -> int:
    mock = UPowerMock()
    try:
        devices = {handle: MockDevice(mock, handle, props) for handle, props in MOCK_DEVICES.items()}
        control_loop = export_control(devices)
        process = subprocess.Popen(["qs", "-p", str(PREVIEW_DIR)], env=mock.client_env(os.environ))
        unplug_stale = devices[STALE_DEVICE].set_connected
        control_loop.call_soon_threadsafe(control_loop.call_later, STALE_AFTER_SECONDS, unplug_stale, False)

        def terminate(_signum: int, _frame: object) -> None:
            process.terminate()

        signal.signal(signal.SIGTERM, terminate)
        signal.signal(signal.SIGINT, terminate)
        return process.wait()
    finally:
        mock.close()


if __name__ == "__main__":
    sys.exit(run())
