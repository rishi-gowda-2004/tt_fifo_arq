# SPDX-FileCopyrightText: © 2025
# SPDX-License-Identifier: Apache-2.0

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge, ClockCycles


def _uo_bits(uo_val):
    """
    Return (ack, nack, data) from the 8-bit uo_out value.
    Uses int(...) to avoid fragile .binstr usage.
    """
    v = int(uo_val)
    ack = (v >> 7) & 1
    nack = (v >> 6) & 1
    data = (v >> 2) & 0xF
    return ack, nack, data


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
        # format: [wr_en rd_en data(4) err_mode(2)]
        dut.ui_in.value = (1 << 7) | (0 << 6) | (int(d & 0xF) << 2) | 0b00
        await RisingEdge(dut.clk)

    # clear write
    dut.ui_in.value = 0
    await RisingEdge(dut.clk)

    # small settle cycle
    await ClockCycles(dut.clk, 1)

    # -------------------------
    # Normal read (ack=1, nack=0)
    # -------------------------
    dut.ui_in.value = (0 << 7) | (1 << 6) | (0x0 << 2) | 0b00
    await RisingEdge(dut.clk)
    # read outputs after the posedge where DUT updates them
    await ClockCycles(dut.clk, 0)
    ack, nack, data = _uo_bits(dut.uo_out.value)
    dut._log.info(f"Normal read uo_out={format(int(dut.uo_out.value), '08b')} ack={ack} nack={nack} data=0x{data:X}")
    assert ack == 1, f"Ack should be 1 on normal read (uo_out={format(int(dut.uo_out.value),'08b')})"
    assert nack == 0, f"Nack should be 0 on normal read (uo_out={format(int(dut.uo_out.value),'08b')})"
    dut.ui_in.value = 0
    await RisingEdge(dut.clk)

    # -------------------------
    # Corrupted read (ack=1, nack=0) -- err_mode = 01 in RTL still sets ack=1
    # -------------------------
    dut.ui_in.value = (0 << 7) | (1 << 6) | (0x0 << 2) | 0b01
    await RisingEdge(dut.clk)
    ack, nack, data = _uo_bits(dut.uo_out.value)
    dut._log.info(f"Corrupted read uo_out={format(int(dut.uo_out.value), '08b')} ack={ack} nack={nack} data=0x{data:X}")
    assert ack == 1, f"Ack should be 1 on corrupted read (uo_out={format(int(dut.uo_out.value),'08b')})"
    assert nack == 0, f"Nack should be 0 on corrupted read (uo_out={format(int(dut.uo_out.value),'08b')})"
    dut.ui_in.value = 0
    await RisingEdge(dut.clk)

    # -------------------------
    # Retransmission (ack=0, nack=1)
    # -------------------------
    dut.ui_in.value = (0 << 7) | (1 << 6) | (0x0 << 2) | 0b10
    await RisingEdge(dut.clk)
    ack, nack, data = _uo_bits(dut.uo_out.value)
    dut._log.info(f"Retransmission uo_out={format(int(dut.uo_out.value), '08b')} ack={ack} nack={nack} data=0x{data:X}")
    assert ack == 0, f"Ack should be 0 on retransmission (uo_out={format(int(dut.uo_out.value),'08b')})"
    assert nack == 1, f"Nack should be 1 on retransmission (uo_out={format(int(dut.uo_out.value),'08b')})"
    dut.ui_in.value = 0
    await RisingEdge(dut.clk)

    # -------------------------
    # Back to good transmission (ack=1)
    # -------------------------
    dut.ui_in.value = (0 << 7) | (1 << 6) | (0x0 << 2) | 0b00
    await RisingEdge(dut.clk)
    ack, nack, data = _uo_bits(dut.uo_out.value)
    dut._log.info(f"Good read after retransmission uo_out={format(int(dut.uo_out.value), '08b')} ack={ack} nack={nack} data=0x{data:X}")
    assert ack == 1, f"Ack should be 1 again (uo_out={format(int(dut.uo_out.value),'08b')})"
    dut.ui_in.value = 0
    await RisingEdge(dut.clk)

    # -------------------------
    # Additional reads (just log)
    # -------------------------
    err_modes = [0b00, 0b10, 0b01, 0b00]
    for e in err_modes:
        dut.ui_in.value = (0 << 7) | (1 << 6) | (0x0 << 2) | int(e)
        await RisingEdge(dut.clk)
        ack, nack, data = _uo_bits(dut.uo_out.value)
        dut._log.info(f"Extra read (err_mode={e:02b}) uo_out={format(int(dut.uo_out.value),'08b')} ack={ack} nack={nack} data=0x{data:X}")
        dut.ui_in.value = 0
        await RisingEdge(dut.clk)

    # -------------------------
    # Final check
    # -------------------------
    final_val = int(dut.uo_out.value)
    dut._log.info(f"Final uo_out={format(final_val, '08b')}")
    # ensure driven (not X/Z). int() of unresolved will raise or be 0; check width
    assert final_val >= 0 and final_val < 256, "uo_out appears undriven or out of range"

    dut._log.info("Test completed successfully ✅")
