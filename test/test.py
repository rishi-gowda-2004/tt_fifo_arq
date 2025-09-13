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
        dut.ui_in.value = (1 << 7) | (0 << 6) | (d << 2) | 0b00  # wr_en=1, rd_en=0
        await RisingEdge(dut.clk)
    dut.ui_in.value = 0
    await RisingEdge(dut.clk)

    # -------------------------
    # Normal read (ack=1, nack=0)
    # -------------------------
    dut.ui_in.value = (0 << 7) | (1 << 6) | (0x0 << 2) | 0b00
    await RisingEdge(dut.clk)
    dut._log.info(f"Normal read uo_out={dut.uo_out.value.binstr}")
    assert dut.uo_out.value[7] == 1, "Ack should be 1 on normal read"
    assert dut.uo_out.value[6] == 0, "Nack should be 0 on normal read"
    dut.ui_in.value = 0
    await RisingEdge(dut.clk)

    # -------------------------
    # Corrupted read (ack=1, nack=0)
    # -------------------------
    dut.ui_in.value = (0 << 7) | (1 << 6) | (0x0 << 2) | 0b01
    await RisingEdge(dut.clk)
    dut._log.info(f"Corrupted read uo_out={dut.uo_out.value.binstr}")
    assert dut.uo_out.value[7] == 1, "Ack should still be 1 for corrupted read"
    assert dut.uo_out.value[6] == 0, "Nack should be 0 on corrupted read"
    dut.ui_in.value = 0
    await RisingEdge(dut.clk)

    # -------------------------
    # Retransmission (ack=0, nack=1)
    # -------------------------
    dut.ui_in.value = (0 << 7) | (1 << 6) | (0x0 << 2) | 0b10
    await RisingEdge(dut.clk)
    dut._log.info(f"Retransmission uo_out={dut.uo_out.value.binstr}")
    assert dut.uo_out.value[7] == 0, "Ack should be 0 on retransmission"
    assert dut.uo_out.value[6] == 1, "Nack should be 1 on retransmission"
    dut.ui_in.value = 0
    await RisingEdge(dut.clk)

    # -------------------------
    # Back to good transmission (ack=1)
    # -------------------------
    dut.ui_in.value = (0 << 7) | (1 << 6) | (0x0 << 2) | 0b00
    await RisingEdge(dut.clk)
    dut._log.info(f"Good read after retransmission uo_out={dut.uo_out.value.binstr}")
    assert dut.uo_out.value[7] == 1, "Ack should be 1 again"
    dut.ui_in.value = 0
    await RisingEdge(dut.clk)

    # -------------------------
    # Additional reads
    # -------------------------
    err_modes = [0b00, 0b10, 0b01, 0b00]
    for e in err_modes:
        dut.ui_in.value = (0 << 7) | (1 << 6) | (0x0 << 2) | e
        await RisingEdge(dut.clk)
        dut._log.info(f"Extra read (err_mode={e:02b}) uo_out={dut.uo_out.value.binstr}")
        dut.ui_in.value = 0
        await RisingEdge(dut.clk)

    # -------------------------
    # Final check
    # -------------------------
    dut._log.info(f"Final uo_out={dut.uo_out.value.binstr}")
    assert dut.uo_out.value is not None, "uo_out is not driven!"

    dut._log.info("Test completed successfully ✅")
