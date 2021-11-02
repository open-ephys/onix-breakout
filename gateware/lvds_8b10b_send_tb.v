`timescale 1ns/100ps

module lvds_8b10b_send_tb ();

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
 wire data_out;
 wire data_read;

lvds_8b10b_send #(
  .NUM_BYTES(NUM_BYTES)
  ) dut (
    .clk(clk),
    .reset(reset),
    .data(data),
    .data_read_o(data_read),
    .serial_o(data_out)
    );

    reg [8*NUM_BYTES - 1 : 0] sample [0:2];

    initial
    begin
      sample[0] = 16'h0001;
      sample[1] = 16'habcd;
      sample[2] = 16'habcd;
    end

   reg [1:0] count = 'b0;

   always @ (posedge clk)
   begin
          if (data_read) begin
            if (count == 2'd3) $stop;
            else begin
              data <= sample[count];
              count <= count + 1'b1;
            end
          end
   end

endmodule
