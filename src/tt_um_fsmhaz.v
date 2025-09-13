/*
 * FSM Hazard Detection with FIFO + SECDED ECC (4-bit optimized)
 * Author: Rishi Gowda
 * TinyTapeout 1x1 tile
 * SPDX-License-Identifier: Apache-2.0
 */

`default_nettype none
`timescale 1ns / 1ps

// =============================================
// Top Module Wrapper
// =============================================
module tt_um_fsmhaz (
    input  wire [7:0] ui_in,
    output wire [7:0] uo_out,
    input  wire [7:0] uio_in,
    output wire [7:0] uio_out,
    output wire [7:0] uio_oe,
    input  wire       ena,
    input  wire       clk,
    input  wire       rst_n
);

  wire wr_en    = ui_in[0];
  wire rd_en    = ui_in[1];
  wire [1:0] err_mode = ui_in[3:2];
  wire [3:0] data_in  = ui_in[7:4];

  wire [3:0] data_out;
  wire ack, nack;

  fsm_haz_opt dut (
    .clk(clk),
    .rst(~rst_n),
    .wr_en(wr_en),
    .rd_en(rd_en),
    .data_in(data_in),
    .data_out(data_out),
    .ack(ack),
    .nack(nack),
    .err_mode(err_mode)
  );

  assign uo_out  = {2'b0, ack, nack, data_out};
  assign uio_out = 8'b0;
  assign uio_oe  = 8'b0;

  wire _unused = &{uio_in, ena};

endmodule

// =============================================
// Optimized FSM + FIFO + SECDED ECC (4-bit data)
// =============================================
module fsm_haz_opt (
    input  wire       clk,
    input  wire       rst,
    input  wire       wr_en,
    input  wire       rd_en,
    input  wire [3:0] data_in,
    output reg  [3:0] data_out,
    output reg        ack,
    output reg        nack,
    input  wire [1:0] err_mode
);

  // --------- Simplified Hamming(7,4) Encoder ---------
  wire p1 = data_in[0] ^ data_in[1] ^ data_in[3];
  wire p2 = data_in[0] ^ data_in[2] ^ data_in[3];
  wire p4 = data_in[1] ^ data_in[2] ^ data_in[3];

  wire [6:0] cw = {p4, p2, p1, data_in};

  // --------- Simple 4-entry FIFO ---------
  reg [6:0] fifo_mem [0:3];
  reg [1:0] wptr, rptr;
  reg [2:0] count;

  wire fifo_full  = (count == 4);
  wire fifo_empty = (count == 0);

  // Write logic
  always @(posedge clk) begin
    if (rst) begin
      wptr <= 0;
      count <= 0;
    end else if (wr_en && !fifo_full) begin
      fifo_mem[wptr] <= cw;
      wptr <= wptr + 1;
      count <= count + 1;
    end
  end

  // Read logic
  reg [6:0] read_data;
  always @(posedge clk) begin
    if (rst) begin
      rptr <= 0;
      read_data <= 0;
    end else if (rd_en && !fifo_empty) begin
      read_data <= fifo_mem[rptr];
      rptr <= rptr + 1;
      count <= count - 1;
    end
  end

  // --------- Error Injection ---------
  wire [6:0] corrupted =
      (err_mode == 2'b01) ? (read_data ^ 7'b0000100) :
      (err_mode == 2'b10) ? (read_data ^ 7'b0010100) :
                            read_data;

  // --------- Hamming(7,4) Decoder ---------
  wire d0 = corrupted[0];
  wire d1 = corrupted[1];
  wire d2 = corrupted[2];
  wire d3 = corrupted[3];
  wire p1_rx = corrupted[4];
  wire p2_rx = corrupted[5];
  wire p4_rx = corrupted[6];

  wire s1 = p1_rx ^ d0 ^ d1 ^ d3;
  wire s2 = p2_rx ^ d0 ^ d2 ^ d3;
  wire s4 = p4_rx ^ d1 ^ d2 ^ d3;

  wire [2:0] syndrome = {s4, s2, s1};
  wire parity_err = |syndrome;

  reg [6:0] corrected;
  always @* begin
    corrected = corrupted;
    if (parity_err) begin
      case(syndrome)
        3'b001: corrected[0] = ~corrected[0];
        3'b010: corrected[1] = ~corrected[1];
        3'b011: corrected[2] = ~corrected[2];
        3'b100: corrected[3] = ~corrected[3];
        3'b101: corrected[4] = ~corrected[4];
        3'b110: corrected[5] = ~corrected[5];
        3'b111: corrected[6] = ~corrected[6];
      endcase
    end
  end

  assign decoded_data = corrected[3:0];

  // --------- Output handshake ---------
  always @(posedge clk) begin
    if (rst) begin
      data_out <= 0;
      ack <= 0;
      nack <= 0;
    end else begin
      ack <= 0;
      nack <= 0;
      if (rd_en && !fifo_empty) begin
        data_out <= decoded_data;
        if (parity_err && syndrome != 3'b000) nack <= 1;
        else ack <= 1;
      end
    end
  end

  wire [3:0] decoded_data; // for output
endmodule
