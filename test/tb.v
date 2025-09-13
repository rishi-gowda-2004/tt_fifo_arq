`default_nettype none
`timescale 1ns / 1ps

module tb ();
   
  reg clk;
  reg rst_n;
 
  reg wr_en;
  reg rd_en;
  reg [3:0] data_in;
  reg [1:0] err_mode;

  wire [7:0] ui_in;     // inputs to DUT
  reg  [7:0] uio_in;
  wire [7:0] uo_out;
  wire [7:0] uio_out;
  wire [7:0] uio_oe;
  reg ena;

  // Power pins for GL sims
  wire VPWR = 1'b1;
  wire VGND = 1'b0;

  // ✅ Fix: ui_in is a wire, driven by TB signals
  assign ui_in = {wr_en, rd_en, data_in, err_mode};
   
  // Instantiate DUT
  tt_um_tx_fsm user_project (
    `ifdef USE_POWER_PINS   // ✅ FIX: match DUT wrapper
      .VPWR(VPWR),
      .VGND(VGND),
    `endif
    .ui_in  (ui_in),
    .uo_out (uo_out),
    .uio_in (uio_in),
    .uio_out(uio_out),
    .uio_oe (uio_oe),
    .ena    (ena),
    .clk    (clk),
    .rst_n  (rst_n)   // active-low reset
  );

  // Clock generation
  initial begin
    clk = 0;
    forever #5 clk = ~clk;  // 10ns period
  end

  // VCD dump
  initial begin
    $dumpfile("tb.vcd");
    $dumpvars(0, tb);
  end

  // Stimulus
  initial begin
    // init
    ena     = 1;
    uio_in  = 8'h00;
    rst_n   = 0;
    wr_en   = 0; 
    rd_en   = 0; 
    data_in = 0; 
    err_mode= 0;

    // Release reset
    #12 rst_n = 1;

    // --- Write 4 values into FIFO ---
    @(posedge clk); wr_en = 1; data_in = 4'h0;
    @(posedge clk); data_in = 4'hA;
    @(posedge clk); data_in = 4'h3;
    @(posedge clk); data_in = 4'h2;
    @(posedge clk); wr_en = 0;

    // --- Normal read (ack=1) ---
    @(posedge clk); rd_en = 1; err_mode = 2'b00;
    @(posedge clk); rd_en = 0;

    // --- Corrupted read (ack=1, but data considered bad) ---
    @(posedge clk); rd_en = 1; err_mode = 2'b01;
    @(posedge clk); rd_en = 0;

    // --- Retransmission (nack=1) ---
    @(posedge clk); rd_en = 1; err_mode = 2'b10;
    @(posedge clk); rd_en = 0;

    // Back to good transmission
    @(posedge clk); rd_en = 1; err_mode = 2'b00;
    @(posedge clk); rd_en = 0;

    // Few more reads
    @(posedge clk); rd_en = 1; err_mode = 2'b00;
    @(posedge clk); rd_en = 0;

    @(posedge clk); rd_en = 1; err_mode = 2'b10;
    @(posedge clk); rd_en = 0;

    @(posedge clk); rd_en = 1; err_mode = 2'b01;
    @(posedge clk); rd_en = 0;

    @(posedge clk); rd_en = 1; err_mode = 2'b00;
    @(posedge clk); rd_en = 0;

    #50 $finish;
  end

endmodule
