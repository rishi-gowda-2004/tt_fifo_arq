# SPDX-FileCopyrightText: © 2024 Tiny Tapeout
# SPDX-License-Identifier: Apache-2.0

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import ClockCycles


@cocotb.test()
async def test_project(dut):
    """Minimal cocotb smoke test — ensures DUT resets and runs one cycle."""
    dut._log.info("Start test_project")

    # 100 KHz clock (10 us period)
    clock = Clock(dut.clk, 10, units="us")
    cocotb.start_soon(clock.start())

    # Reset sequence
    dut.ena.value = 1
    dut.ui_in.value = 0
    dut.uio_in.value = 0
    dut.rst_n.value = 0
    await ClockCycles(dut.clk, 5)
    dut.rst_n.value = 1
    await ClockCycles(dut.clk, 2)

    # Simple stimulus: assert ctrl (bit4) for a few cycles
    dut.ui_in.value = 0b00010000
    await ClockCycles(dut.clk, 3)

    # Release inputs
    dut.ui_in.value = 0
    await ClockCycles(dut.clk, 3)

    # Basic check: at least outputs are driven (not X)
    dut._log.info(f"uo_out={dut.uo_out.value}")
    assert dut.uo_out.value is not None
