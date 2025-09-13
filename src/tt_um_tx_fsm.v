`default_nettype none
`timescale 1ns / 1ps

module tt_um_tx_fsm (
    input  wire [7:0] ui_in,    // Dedicated inputs
    output wire [7:0] uo_out,   // Dedicated outputs
    input  wire [7:0] uio_in,   // IOs: Input path
    output wire [7:0] uio_out,  // IOs: Output path
    output wire [7:0] uio_oe,   // IOs: Enable path
    input  wire       ena,      // Always 1 when powered
    input  wire       clk,      // Clock
    input  wire       rst_n     // Active-low reset
`ifdef USE_POWER_PINS
    ,input  wire VPWR,
     input  wire VGND
`endif
);

  // Unused IOs
  assign uio_out = 8'b0;
  assign uio_oe  = 8'b0;
  wire _unused = &{ena, uio_in};

  // Parameters
  parameter DATA_WIDTH = 4, DEPTH = 4;

  // Decode inputs
  wire wr_en               = ui_in[7];
  wire rd_en               = ui_in[6];
  wire [DATA_WIDTH-1:0] data_in = ui_in[5:2];
  wire [1:0] err_mode      = ui_in[1:0];

  // Outputs
  reg  [DATA_WIDTH-1:0] data_out;
  reg  ack, nack;

  assign uo_out[7]   = ack;
  assign uo_out[6]   = nack;
  assign uo_out[5:2] = data_out;
  assign uo_out[1:0] = 2'b00;

  // FIFO storage
  reg [DATA_WIDTH-1:0] fifo [0:DEPTH-1];
  reg [$clog2(DEPTH)-1:0] wr_ptr, rd_ptr;
  reg [DATA_WIDTH-1:0] last_data;

  // Write
  always @(posedge clk) begin
    if (~rst_n) begin
      wr_ptr <= 0;
    end else if (wr_en) begin
      fifo[wr_ptr] <= data_in;
      wr_ptr <= wr_ptr + 1;
    end
  end

  // Read & Error handling
  always @(posedge clk) begin
    if (~rst_n) begin
      rd_ptr   <= 0;
      data_out <= 0;
      last_data<= 0;
      ack      <= 0;
      nack     <= 0;
    end else begin
      ack  <= 0;
      nack <= 0;

      if (rd_en) begin
        case (err_mode)
          2'b00: begin // normal transmit
            data_out  <= fifo[rd_ptr];
            last_data <= fifo[rd_ptr];
            rd_ptr    <= rd_ptr + 1;
            ack       <= 1;
          end
          2'b01: begin // corrupted transmit
            data_out <= fifo[rd_ptr];
            ack      <= 1;
          end
          2'b10: begin // retransmit
            data_out <= last_data;
            nack     <= 1;
          end
          default: begin
            data_out  <= fifo[rd_ptr];
            last_data <= fifo[rd_ptr];
            rd_ptr    <= rd_ptr + 1;
            ack       <= 1;
          end
        endcase
      end
    end
  end

endmodule
