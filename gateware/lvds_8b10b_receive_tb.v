`timescale 1ns/100ps

module lvds_8b10b_receive_tb ();

  parameter SYSCLK_PERIOD = 20;// 50MHZ
  reg clk;
  reg reset;

  initial
  begin
      clk = 1'b0;
      reset = 1'b1;
  end

  //////////////////////////////////////////////////////////////////////
  // Reset Pulse
  //////////////////////////////////////////////////////////////////////
  initial
  begin
      #(SYSCLK_PERIOD * 10 )
          reset = 1'b0;
  end


  //////////////////////////////////////////////////////////////////////
  // Clock Driver
  //////////////////////////////////////////////////////////////////////
  always @(clk)
      #(SYSCLK_PERIOD / 2.0) clk <= !clk;

 parameter NUM_BYTES = 2;

 reg [8*NUM_BYTES - 1 : 0] data;
 wire serial_o;
 reg serial_i;
 wire data_read_en;

lvds_8b10b_send #(
  .NUM_BYTES(NUM_BYTES)
  ) send (
    .clk(clk),
    .reset(reset),
    .data(data),
    .data_read_o(data_read_en),
    .serial_o(serial_o)
    );

    wire [8*NUM_BYTES - 1 : 0] data_out;
    wire data_rdy;
    wire disp_err;
    wire code_err;
    wire sync_err;

    lvds_8b10b_receive #(
      .NUM_BYTES(NUM_BYTES)
    ) dut (
      .clk(~clk),
      .reset(reset),
      .serial(serial_i),
      .data_o(data_out),
      .data_rdy_o(data_rdy),
      .disp_err_o(disp_err),
      .code_err_o(code_err),
      .sync_err_o(sync_err)
      );

    reg [8*NUM_BYTES - 1 : 0] sample [0:3];

    initial
    begin
      sample[0] = 16'h0001;
      sample[1] = 16'habcd;
      sample[2] = 16'habcd;
      sample[3] = 16'hFF67;
    end

   reg [1:0] count = 'b0;
   reg [1:0] reps = 'b0;
   reg [31:0] clkcount = 'b0;

   always @ (posedge clk)
   begin
          clkcount <= clkcount + 1'b1;
          if (reps == 2'd3) $stop;
          if (data_read_en) begin
            clkcount <= 'b0;
            data <= sample[count];
            if (count == 2'd3) begin
              count <= 'b0;
              reps <= reps + 1'b1;
            end else begin
              count <= count + 1'b1;
            end
          end
   end

   always @(*) begin
    serial_i <= #2 serial_o;

    //uncomment for manual alterations
/*    if (count == 2'd1 && reps == 2'd0 && clkcount == 'd9) serial_i <= 1'b0;
    if (count == 2'd1 && reps == 2'd0 && clkcount == 'd10) serial_i <= 1'b0;
    if (count == 2'd1 && reps == 2'd0 && clkcount == 'd11) serial_i <= 1'b0;
    if (count == 2'd1 && reps == 2'd0 && clkcount == 'd12) serial_i <= 1'b0;
    if (count == 2'd1 && reps == 2'd0 && clkcount == 'd13) serial_i <= 1'b1;
    if (count == 2'd1 && reps == 2'd0 && clkcount == 'd14) serial_i <= 1'b1;
    if (count == 2'd1 && reps == 2'd0 && clkcount == 'd15) serial_i <= 1'b1;
    if (count == 2'd1 && reps == 2'd0 && clkcount == 'd16) serial_i <= 1'b1;
    if (count == 2'd1 && reps == 2'd0 && clkcount == 'd17) serial_i <= 1'b0;
    if (count == 2'd1 && reps == 2'd0 && clkcount == 'd18) serial_i <= 1'b0;*/
   end

endmodule
