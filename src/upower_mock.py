# SPDX-FileCopyrightText: Elias Mueller
#
# SPDX-License-Identifier: MIT

"""A fake upowerd serving a private bus."""

import asyncio
import subprocess
import threading
from typing import TYPE_CHECKING, Any

if TYPE_CHECKING:
    from collections.abc import Coroutine, Mapping

from dbus_fast.aio import MessageBus

from upower_service import (
    DEVICE_DEFAULTS,
    DEVICE_PATH_PREFIX,
    DISPLAY_DEVICE_NAME,
    UPOWER_BUS_NAME,
    UPOWER_PATH,
    DeviceService,
    RootService,
)


class UPowerMock:
    """A fake upowerd owning org.freedesktop.UPower on its own private bus."""

    def __init__(self) -> None:
        self._bus: MessageBus | None = None
        self._devices: dict[str, DeviceService] = {}
        self._daemon = subprocess.Popen(
            ["dbus-daemon", "--session", "--print-address=1", "--nofork"],
            stdout=subprocess.PIPE,
            text=True,
        )
        self._loop = asyncio.new_event_loop()
        self._thread = threading.Thread(target=self._loop.run_forever, daemon=True)
        self._thread.start()

        stdout = self._daemon.stdout
        self.address = stdout.readline().strip() if stdout is not None else ""
        if not self.address:
            self.close()
            message = "dbus-daemon did not report a bus address"
            raise RuntimeError(message)

        try:
            self._run(self._serve())
        except Exception:
            self.close()
            raise

    def add_device(self, name: str, **props: object) -> str:
        unknown = set(props) - set(DEVICE_DEFAULTS)
        if unknown:
            message = f"unknown UPower device properties: {sorted(unknown)}"
            raise ValueError(message)
        return self._run(self._add_device(name, {**DEVICE_DEFAULTS, **props}))

    def update_device(self, path: str, **props: object) -> None:
        self._run(self._update_device(path, props))

    def remove_device(self, path: str) -> None:
        self._run(self._remove_device(path))

    def client_env(self, base: Mapping[str, str]) -> dict[str, str]:
        env = dict(base)
        env["DBUS_SYSTEM_BUS_ADDRESS"] = self.address
        return env

    def close(self) -> None:
        self._loop.call_soon_threadsafe(self._loop.stop)
        self._thread.join(timeout=5)
        self._daemon.terminate()
        try:
            self._daemon.wait(timeout=5)
        except subprocess.TimeoutExpired:
            self._daemon.kill()
        if self._daemon.stdout is not None:
            self._daemon.stdout.close()

    def _run[T](self, coroutine: Coroutine[Any, Any, T]) -> T:
        return asyncio.run_coroutine_threadsafe(coroutine, self._loop).result(timeout=10)

    def _require_bus(self) -> MessageBus:
        if self._bus is None:
            message = "mock bus is not connected"
            raise RuntimeError(message)
        return self._bus

    async def _serve(self) -> None:
        self._bus = await MessageBus(bus_address=self.address).connect()
        self._root = RootService()
        self._bus.export(UPOWER_PATH, self._root)
        await self._add_device(DISPLAY_DEVICE_NAME, {**DEVICE_DEFAULTS, "IsPresent": False})
        await self._bus.request_name(UPOWER_BUS_NAME)

    async def _add_device(self, name: str, values: dict[str, object]) -> str:
        path = DEVICE_PATH_PREFIX + name
        if path in self._devices:
            message = f"device already exists: {path}"
            raise ValueError(message)
        device = DeviceService(values)
        self._require_bus().export(path, device)
        self._devices[path] = device
        if name != DISPLAY_DEVICE_NAME:
            self._root.device_paths.append(path)
            self._root.DeviceAdded(path)
        return path

    async def _update_device(self, path: str, props: dict[str, object]) -> None:
        device = self._devices[path]
        device.values.update(props)
        device.emit_properties_changed({name: device.values[name] for name in props})

    async def _remove_device(self, path: str) -> None:
        self._root.device_paths.remove(path)
        self._root.DeviceRemoved(path)
        self._require_bus().unexport(path)
        del self._devices[path]
