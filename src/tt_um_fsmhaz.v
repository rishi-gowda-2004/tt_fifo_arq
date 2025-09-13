/*
 * TinyTapeout Project: FSM Hazard Detection with ECC + FIFO
 * Author: Rishi Gowda
 * SPDX-License-Identifier: Apache-2.0
 */

`default_nettype none

module tt_um_fsmhaz (
    input  wire [7:0] ui_in,    // dedicated inputs
    output wire [7:0] uo_out,   // dedicated outputs
    input  wire [7:0] uio_in,   // IOs: input path
    output wire [7:0] uio_out,  // IOs: output path
    output wire [7:0] uio_oe,   // IOs: enable path (1=output)
    input  wire       ena,      // always 1 when powered
    input  wire       clk,      // system clock
    input  wire       rst_n     // reset (active low)
);

    // ---------------------------------------------------------
    // Map TinyTapeout inputs to your design signals
    // ---------------------------------------------------------
    wire wr_en     = ui_in[0];
    wire rd_en     = ui_in[1];
    wire [1:0] err_mode = ui_in[3:2];   // error mode from 2 bits
    wire [3:0] data_in  = ui_in[7:4];   // 4-bit data input

    // ---------------------------------------------------------
    // Outputs
    // ---------------------------------------------------------
    wire [3:0] data_out;
    wire ack, nack;

    // ---------------------------------------------------------
    // Instantiate your FSM design
    // ---------------------------------------------------------
    fsm_haz dut (
        .clk     (clk),
        .rst     (~rst_n),   // rst_n is active-low
        .wr_en   (wr_en),
        .rd_en   (rd_en),
        .data_in (data_in),
        .err_mode(err_mode),
        .data_out(data_out),
        .ack     (ack),
        .nack    (nack)
    );

    // ---------------------------------------------------------
    // Drive TinyTapeout outputs
    // ---------------------------------------------------------
    assign uo_out[3:0] = data_out; // lower 4 bits = data_out
    assign uo_out[4]   = ack;
    assign uo_out[5]   = nack;
    assign uo_out[7:6] = 2'b00;    // unused

    // No bidirectional IOs used
    assign uio_out = 8'b0;
    assign uio_oe  = 8'b0;

    // Prevent unused warnings
    wire _unused = &{ena, uio_in};

endmodule
