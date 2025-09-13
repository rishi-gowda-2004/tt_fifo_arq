`default_nettype none
`timescale 1ns / 1ps

module tb;
  reg clk;
  reg rst_n;
 
  reg wr_en;
  reg rd_en;
  reg [3:0] data_in;
  reg [1:0] err_mode;

  wire [7:0] ui_in;
  reg  [7:0] uio_in;
  wire [7:0] uo_out;
  wire [7:0] uio_out;
  wire [7:0] uio_oe;
  reg ena;

`ifdef USE_POWER_PINS
  wire VPWR = 1'b1;
  wire VGND = 1'b0;
`endif

  assign ui_in = {wr_en, rd_en, data_in, err_mode};
   
  tt_um_tx_fsm dut (
    .ui_in  (ui_in),
    .uo_out (uo_out),
    .uio_in (uio_in),
    .uio_out(uio_out),
    .uio_oe (uio_oe),
    .ena    (ena),
    .clk    (clk),
    .rst_n  (rst_n)
`ifdef USE_POWER_PINS
    ,.VPWR(VPWR),
    .VGND(VGND)
`endif
  );

  // Clock
  initial begin
    clk = 0;
    forever #5 clk = ~clk;
  end

  // Dump VCD
  initial begin
    $dumpfile("tb.vcd");
    $dumpvars(0, dut);
  end

  // Stimulus
  initial begin
    ena     = 1;
    uio_in  = 0;
    rst_n   = 0;
    wr_en   = 0; 
    rd_en   = 0; 
    data_in = 0; 
    err_mode= 0;

    #12 rst_n = 1;

    // Write 4 values
    @(posedge clk); wr_en = 1; data_in = 4'h0;
    @(posedge clk); data_in = 4'hA;
    @(posedge clk); data_in = 4'h3;
    @(posedge clk); data_in = 4'h2;
    @(posedge clk); wr_en = 0;

    // Normal read
    @(posedge clk); rd_en = 1; err_mode = 2'b00;
    @(posedge clk); rd_en = 0;

    // Corrupted read
    @(posedge clk); rd_en = 1; err_mode = 2'b01;
    @(posedge clk); rd_en = 0;

    // Retransmission
    @(posedge clk); rd_en = 1; err_mode = 2'b10;
    @(posedge clk); rd_en = 0;

    // Back to good transmission
    @(posedge clk); rd_en = 1; err_mode = 2'b00;
    @(posedge clk); rd_en = 0;

    // Few more reads
    repeat (4) begin
      @(posedge clk); rd_en = 1; err_mode = $random % 3;
      @(posedge clk); rd_en = 0;
    end

    #50 $finish;
  end

endmodule
