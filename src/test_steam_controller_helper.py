# SPDX-FileCopyrightText: Elias Mueller
#
# SPDX-License-Identifier: MIT

"""Unit tests for the pure core of the Steam Controller helper."""

from steam_controller_helper import parse_report, plan_nodes

# Reports captured from a real Steam Controller Puck
BATTERY_DISCHARGING = bytes.fromhex("43 01 4f 990f b40f 0000 0000 0000 8b6a")
BATTERY_CHARGING = bytes.fromhex("43 02 4f e90f 1810 c012 a401 ec01 8b6a")
WIRELESS_CONNECT = bytes.fromhex("79 02")
WIRELESS_DISCONNECT = bytes.fromhex("79 01")
CONTROLLER_STATE = bytes.fromhex("42") + bytes(53)


def puck_uevent(
    phys: str = "usb-0000:0f:00.0-5.2/input2",
    driver: str = "hid-generic",
    hid_id: str = "0003:000028DE:00001304",
    uniq: str = "FXB995480177F",
) -> str:
    return f"DRIVER={driver}\nHID_ID={hid_id}\nHID_NAME=Valve Software Steam Controller Puck\nHID_PHYS={phys}\nHID_UNIQ={uniq}\nMODALIAS=hid:b0003g0001v000028DEp00001304\n"


def test_captured_discharging_report_yields_a_reading() -> None:
    assert parse_report(BATTERY_DISCHARGING) == {"event": "battery", "level": 79, "state": "discharging"}


def test_captured_charging_report_yields_a_reading() -> None:
    assert parse_report(BATTERY_CHARGING) == {"event": "battery", "level": 79, "state": "charging"}


def test_charging_done_state_is_named() -> None:
    report = bytes([0x43, 0x04]) + BATTERY_DISCHARGING[2:]
    assert parse_report(report) == {"event": "battery", "level": 79, "state": "chargingDone"}


def test_unknown_charge_state_is_passed_as_unknown() -> None:
    report = bytes([0x43, 0x09]) + BATTERY_DISCHARGING[2:]
    assert parse_report(report) == {"event": "battery", "level": 79, "state": "unknown"}


def test_captured_connect_event() -> None:
    assert parse_report(WIRELESS_CONNECT) == {"event": "connect"}


def test_captured_disconnect_event() -> None:
    assert parse_report(WIRELESS_DISCONNECT) == {"event": "disconnect"}


def test_alternate_wireless_report_id_is_handled() -> None:
    assert parse_report(bytes([0x46, 0x01])) == {"event": "disconnect"}


def test_pair_event_is_ignored() -> None:
    assert parse_report(bytes([0x79, 0x03])) is None


def test_controller_state_report_is_ignored() -> None:
    assert parse_report(CONTROLLER_STATE) is None


def test_truncated_battery_report_is_ignored() -> None:
    assert parse_report(BATTERY_DISCHARGING[:10]) is None


def test_truncated_wireless_report_is_ignored() -> None:
    assert parse_report(bytes([0x79])) is None


def test_empty_report_is_ignored() -> None:
    assert parse_report(b"") is None


def test_puck_node_gets_an_identity() -> None:
    plan = plan_nodes({"hidraw0": puck_uevent()})
    identity = plan["hidraw0"]
    assert identity.serial == "FXB995480177F"
    assert identity.slot == 0


def test_node_bound_to_a_real_driver_is_skipped() -> None:
    assert plan_nodes({"hidraw0": puck_uevent(driver="hid-steam")}) == {}


def test_foreign_vendor_is_skipped() -> None:
    logitech = "DRIVER=logitech-djreceiver\nHID_ID=0003:0000046D:0000C54D\nHID_NAME=Logitech USB Receiver\nHID_PHYS=usb-0000:0f:00.0-10/input0\nHID_UNIQ=\n"
    assert plan_nodes({"hidraw10": logitech}) == {}


def test_foreign_valve_product_is_skipped() -> None:
    assert plan_nodes({"hidraw0": puck_uevent(hid_id="0003:000028DE:00001142")}) == {}


def test_wired_product_matches() -> None:
    plan = plan_nodes({"hidraw0": puck_uevent(hid_id="0003:000028DE:00001302")})
    assert plan["hidraw0"].serial == "FXB995480177F"


def test_bluetooth_product_matches() -> None:
    uevent = puck_uevent(hid_id="0005:000028DE:00001303", phys="e8:9c:25:aa:bb:cc", uniq="ff:ee:dd:cc:bb:aa")
    plan = plan_nodes({"hidraw6": uevent})
    assert plan["hidraw6"].serial == "ff:ee:dd:cc:bb:aa"


def test_malformed_uevent_is_skipped() -> None:
    assert plan_nodes({"hidraw0": "garbage\n"}) == {}


def test_receiver_interfaces_get_slots_in_phys_order() -> None:
    nodes = {f"hidraw{n}": puck_uevent(phys=f"usb-0000:0f:00.0-5.2/input{i}") for n, i in enumerate((6, 2, 4, 5, 3))}
    plan = plan_nodes(nodes)
    assert [plan[f"hidraw{n}"].slot for n in range(5)] == [4, 0, 2, 3, 1]


def test_interface_order_is_numeric_not_lexical() -> None:
    nodes = {
        "hidraw1": puck_uevent(phys="usb-0000:0f:00.0-5.2/input10"),
        "hidraw2": puck_uevent(phys="usb-0000:0f:00.0-5.2/input9"),
    }
    plan = plan_nodes(nodes)
    assert plan["hidraw2"].slot == 0
    assert plan["hidraw1"].slot == 1


def test_two_receivers_get_independent_slots() -> None:
    nodes = {
        "hidraw0": puck_uevent(phys="usb-0000:0f:00.0-5.2/input2"),
        "hidraw1": puck_uevent(phys="usb-0000:0f:00.0-5.2/input3"),
        "hidraw2": puck_uevent(phys="usb-0000:0f:00.0-7/input2", uniq="FXB000000000A"),
    }
    plan = plan_nodes(nodes)
    assert (plan["hidraw0"].serial, plan["hidraw0"].slot) == ("FXB995480177F", 0)
    assert (plan["hidraw1"].serial, plan["hidraw1"].slot) == ("FXB995480177F", 1)
    assert (plan["hidraw2"].serial, plan["hidraw2"].slot) == ("FXB000000000A", 0)


def test_missing_serial_falls_back_to_the_port() -> None:
    nodes = {
        "hidraw0": puck_uevent(hid_id="0003:000028DE:00001302", phys="usb-0000:0f:00.0-10/input0", uniq=""),
        "hidraw1": puck_uevent(hid_id="0003:000028DE:00001302", phys="usb-0000:0f:00.0-10/input1", uniq=""),
    }
    plan = plan_nodes(nodes)
    assert plan["hidraw0"].serial == plan["hidraw1"].serial
    assert plan["hidraw0"].serial
    assert [plan["hidraw0"].slot, plan["hidraw1"].slot] == [0, 1]
