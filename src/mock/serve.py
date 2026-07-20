# SPDX-FileCopyrightText: Elias Mueller
#
# SPDX-License-Identifier: MIT

"""Serve a controllable mock device and run the preview bar against it."""

import asyncio
import os
import signal
import subprocess
import sys
import threading
from dataclasses import dataclass
from enum import IntEnum
from pathlib import Path

from dbus_fast.aio import MessageBus
from dbus_fast.service import ServiceInterface, method

from upower_mock import UPowerMock

PREVIEW_DIR = Path(__file__).resolve().parent / "preview"

CONTROL_NAME = "io.github.trin94.WirelessBatteryWidget.Mock"


class State(IntEnum):
    UNKNOWN = 0
    CHARGING = 1
    DISCHARGING = 2
    EMPTY = 3
    FULL = 4
    PENDING_CHARGE = 5


STATES = {member.name.lower().replace("_", "-"): int(member) for member in State}

DEVICE_TYPE = 5
DEVICE_NAME = "mock_device"


@dataclass(frozen=True)
class Delay:
    seconds: float


@dataclass(frozen=True)
class Connected:
    plugged: bool


@dataclass(frozen=True)
class Update:
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
        Connected(True),
        Update(state=State.UNKNOWN, percentage=0),
    ],
    "wake": [
        Update(state=State.DISCHARGING),
        Delay(0.4),
        Update(percentage=77),
    ],
    "wake-low": [
        Update(state=State.DISCHARGING, percentage=80),
        Delay(0.6),
        Update(state=State.UNKNOWN, percentage=0),
        Delay(0.6),
        Update(state=State.DISCHARGING),
        Delay(0.4),
        Update(percentage=15),
    ],
    "drain": [
        Update(state=State.DISCHARGING, percentage=75),
        Delay(0.5),
        Update(percentage=60),
        Delay(0.5),
        Update(percentage=45),
        Delay(0.5),
        Update(percentage=30),
        Delay(0.5),
        Update(percentage=19),
    ],
    "charging-bounce": [
        Update(state=State.DISCHARGING, percentage=75),
        Delay(0.5),
        Update(percentage=18),
        Delay(0.6),
        Update(state=State.CHARGING),
        Delay(0.6),
        Update(state=State.DISCHARGING),
    ],
    "sleep": [
        Update(state=State.UNKNOWN),
    ],
}
MOCK_DEVICE: dict[str, object] = {
    "Type": DEVICE_TYPE,
    "State": int(State.DISCHARGING),
    "Percentage": 75.0,
    "Model": "Mock Device",
    "NativePath": "hidpp_battery_mock",
    "TimeToEmpty": 4500,
    "TimeToFull": 2700,
}


class MockDevice:
    """The mock device device, which can be unplugged and plugged back in.

    Property updates while unplugged are kept and applied on replug.
    """

    def __init__(self, mock: UPowerMock):
        self._mock = mock
        self._props = dict(MOCK_DEVICE)
        self._path: str | None = mock.add_device(DEVICE_NAME, **self._props)

    def update(self, **props: object) -> None:
        self._props.update(props)
        if self._path is not None:
            self._mock.update_device(self._path, **props)

    def set_connected(self, connected: bool) -> None:
        if connected and self._path is None:
            self._path = self._mock.add_device(DEVICE_NAME, **self._props)
        elif not connected and self._path is not None:
            self._mock.remove_device(self._path)
            self._path = None


class MockControlService(ServiceInterface):
    """Session-bus control surface to adjust the mock device at runtime."""

    def __init__(self, device: MockDevice):
        super().__init__(CONTROL_NAME)
        self._device = device

    @method()
    def SetPercentage(self, percentage: "d"):
        self._device.update(Percentage=percentage)

    @method()
    def SetState(self, state: "s"):
        self._device.update(State=STATES[state])

    @method()
    def SetConnected(self, connected: "b"):
        self._device.set_connected(connected)

    @method()
    def SetModel(self, model: "s"):
        self._device.update(Model=model)

    @method()
    def SetTimeToEmpty(self, seconds: "x"):
        self._device.update(TimeToEmpty=seconds)

    @method()
    def SetTimeToFull(self, seconds: "x"):
        self._device.update(TimeToFull=seconds)

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

    async def _apply(self, step: Step) -> None:
        match step:
            case Delay(seconds):
                await asyncio.sleep(seconds)
            case Connected(plugged):
                self._device.set_connected(plugged)
            case Update():
                self._device.update(**step.props())


def export_control(device: MockDevice) -> None:
    loop = asyncio.new_event_loop()
    threading.Thread(target=loop.run_forever, daemon=True).start()

    async def export() -> None:
        bus = await MessageBus().connect()
        bus.export("/", MockControlService(device))
        await bus.request_name(CONTROL_NAME)

    asyncio.run_coroutine_threadsafe(export(), loop).result(timeout=10)


def run() -> int:
    mock = UPowerMock()
    try:
        export_control(MockDevice(mock))
        process = subprocess.Popen(["qs", "-p", str(PREVIEW_DIR)], env=mock.client_env(os.environ))

        def terminate(_signum: int, _frame: object) -> None:
            process.terminate()

        signal.signal(signal.SIGTERM, terminate)
        signal.signal(signal.SIGINT, terminate)
        return process.wait()
    finally:
        mock.close()


if __name__ == "__main__":
    sys.exit(run())
