/*
 * Copyright (c) 2024 Your Name
 * SPDX-License-Identifier: Apache-2.0
 */

`default_nettype none
`timescale 1ns / 1ps
module tt_um_tx_fsm (
    input  wire [7:0] ui_in,    // Dedicated inputs
    output wire [7:0] uo_out,   // Dedicated outputs
    input  wire [7:0] uio_in,   // IOs: Input path
    output wire [7:0] uio_out,  // IOs: Output path
    output wire [7:0] uio_oe,   // IOs: Enable path (active high: 0=input, 1=output)
    input  wire       ena,      // always 1 when the design is powered, so you can ignore it
    input  wire       clk,      // clock
    input  wire       rst_n     // reset_n - low to reset
);

  // All output pins must be assigned. If not used, assign to 0.
 
  assign uio_out = 8'b0;
  assign uio_oe  = 8'b0;

  // List all unused inputs to prevent warnings
  wire _unused = &{ena};

 parameter DATA_WIDTH = 4, DEPTH = 4;

 wire                  wr_en;
 wire                  rd_en;
    wire [DATA_WIDTH-1:0] data_in;
    wire [1:0]            err_mode;         // 00: no error, 01: corrupted, 10: retransmit
    reg  [DATA_WIDTH-1:0] data_out;
 reg                   ack;
 reg                   nack;

    assign ui_in[7]=wr_en;
    assign ui_in[6]=rd_en;
    assign ui_in[5:2] = data_in;
    assign ui_in[1:0] = err_mode;
    assign uo_out[1:0] = 2'b00;
    
    
    // FIFO storage
    reg [DATA_WIDTH-1:0] fifo [0:DEPTH-1];
    reg [$clog2(DEPTH)-1:0] wr_ptr, rd_ptr;
    reg [DATA_WIDTH-1:0] last_data;  // for retransmission

    // Write
    always @(posedge clk ) begin
        if (~rst_n) begin
            wr_ptr <= 0;
        end else if (wr_en) begin
            fifo[wr_ptr] <= data_in;
            wr_ptr <= wr_ptr + 1;
        end
    end

    // Read & Error handling
    always @(posedge clk ) begin
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
                        ack       <= 1; // correct transmission
                    end
                    2'b01: begin // corrupted transmit
                        data_out <= fifo[rd_ptr]; // corrupt data
                        ack     <= 1;
                    end
                    2'b10: begin // retransmit
                        data_out <= last_data;
                        nack     <= 1; // indicate retransmit needed
                    end
                    default:begin // normal transmit
                        data_out  <= fifo[rd_ptr];
                        last_data <= fifo[rd_ptr];
                        rd_ptr    <= rd_ptr + 1;
                        ack       <= 1; // correct transmission
                    end
                endcase
            end
        end
    end
    assign ack = uo_out[7] ;
    assign nack = uo_out [6];
    assign data_out = uo_out [5:2];
endmodule
    
