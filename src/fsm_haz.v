/*
 * Copyright (c) 2025 Rishi Gowda
 * SPDX-License-Identifier: Apache-2.0
 */

`default_nettype none

module tt_um_fsmhaz (
    input  wire [7:0] ui_in,    // Dedicated inputs
    output wire [7:0] uo_out,   // Dedicated outputs
    input  wire [7:0] uio_in,   // IOs: Input path
    output wire [7:0] uio_out,  // IOs: Output path
    output wire [7:0] uio_oe,   // IOs: Enable path (active high: 0=input, 1=output)
    input  wire       ena,      // always 1 when the design is powered, so you can ignore it
    input  wire       clk,      // clock
    input  wire       rst_n     // reset_n - low to reset
);

  // Active-high reset for your FSM
  wire rst = ~rst_n;

  // Map TinyTapeout pins to your FSM signals
  wire wr_en    = ui_in[0];
  wire rd_en    = ui_in[1];
  wire [7:0] data_in = uio_in;   // use bidirectional IOs as data input
  wire [1:0] err_mode = ui_in[3:2];

  wire [7:0] data_out;
  wire ack, nack;

  // Instantiate your FSM with ECC
  fsm_haz #(.DATA_WIDTH(8), .FIFO_DEPTH(4)) dut (
    .clk(clk),
    .rst(rst),
    .wr_en(wr_en),
    .rd_en(rd_en),
    .data_in(data_in),
    .data_out(data_out),
    .ack(ack),
    .nack(nack),
    .err_mode(err_mode)
  );

  // Drive dedicated outputs
  assign uo_out  = data_out;

  // Use two of the bidirectional IOs as handshake outputs
  assign uio_out[0] = ack;
  assign uio_out[1] = nack;
  assign uio_oe[0]  = 1'b1; // enable as output
  assign uio_oe[1]  = 1'b1; // enable as output

  // Remaining uio outputs disabled (inputs)
  assign uio_out[7:2] = 6'b0;
  assign uio_oe[7:2]  = 6'b0;

  // List all unused inputs to prevent warnings
  wire _unused = &{ena, 1'b0};

endmodule

