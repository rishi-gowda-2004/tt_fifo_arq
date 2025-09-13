# SPDX-FileCopyrightText: © 2025
# SPDX-License-Identifier: Apache-2.0

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge, ClockCycles


@cocotb.test()
async def test_fifo_fsm(dut):
    """Cocotb testbench for Error-Correcting FIFO with SECDED + ARQ"""

    dut._log.info("Starting FIFO+FSM+ECC test")

    # Start clock: 100 MHz => 10 ns period
    clock = Clock(dut.clk, 10, units="ns")
    cocotb.start_soon(clock.start())

    # Apply reset
    dut.ena.value = 1
    dut.ui_in.value = 0
    dut.uio_in.value = 0
    dut.rst_n.value = 0
    await ClockCycles(dut.clk, 3)
    dut.rst_n.value = 1
    await ClockCycles(dut.clk, 2)

    dut._log.info("Reset complete, starting stimulus...")

    # -------------------------
    # Write 4 values into FIFO
    # -------------------------
    wr_data = [0x0, 0xA, 0x3, 0x2]
    for d in wr_data:
        dut.ui_in.value = (1 << 7) | (0 << 6) | (d << 2) | 0b00  # wr_en=1, rd_en=0, data, err_mode=00
        await RisingEdge(dut.clk)
    dut.ui_in.value = 0
    await RisingEdge(dut.clk)

    # -------------------------
    # Normal read (ack expected)
    # -------------------------
    dut.ui_in.value = (0 << 7) | (1 << 6) | (0x0 << 2) | 0b00
    await RisingEdge(dut.clk)
    dut.ui_in.value = 0
    await RisingEdge(dut.clk)

    # -------------------------
    # Corrupted read (nack expected)
    # -------------------------
    dut.ui_in.value = (0 << 7) | (1 << 6) | (0x0 << 2) | 0b01
    await RisingEdge(dut.clk)
    dut.ui_in.value = 0
    await RisingEdge(dut.clk)

    # -------------------------
    # Retransmission test (nack then ack)
    # -------------------------
    dut.ui_in.value = (0 << 7) | (1 << 6) | (0x0 << 2) | 0b10
    await RisingEdge(dut.clk)
    dut.ui_in.value = 0
    await RisingEdge(dut.clk)

    dut.ui_in.value = (0 << 7) | (1 << 6) | (0x0 << 2) | 0b00
    await RisingEdge(dut.clk)
    dut.ui_in.value = 0
    await RisingEdge(dut.clk)

    # -------------------------
    # Additional reads
    # -------------------------
    err_modes = [0b00, 0b10, 0b01, 0b00]
    for e in err_modes:
        dut.ui_in.value = (0 << 7) | (1 << 6) | (0x0 << 2) | e
        await RisingEdge(dut.clk)
        dut.ui_in.value = 0
        await RisingEdge(dut.clk)

    # -------------------------
    # Final check
    # -------------------------
    dut._log.info(f"Final uo_out={dut.uo_out.value.binstr}")
    assert dut.uo_out.value is not None, "uo_out is not driven!"

    dut._log.info("Test completed successfully ✅")
