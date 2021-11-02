// serialized output q0: [X, X, but5, ...., but1, but0, pow0, pow1]
// serialized output q1: [din7, ...., din1, din0, pow2, pow3]

//This module transmits data through 2 serialized lines transmitting 16-bits
//words using 8b/10b, plus a control code, for a total of 30 coded bits at 60MHz
//This results in 2MHz per line. However, digital inputs are sent in both lines, sampled
//at an offset, so digital input bandwidth can be 4MHz, while button and power status is 2MHz
//
//Data words are:
//D0: [din7, ..., din1, din0, X, X, but5, ..., but1, but0]
//D1: [din7, ..., din1, din0, X, X, X, X, pow3, pow2, pow1, pow0]

`include "clk_div.v"

module breakout_to_host (

    input   wire        i_clk,

    // Parallel inputs
    input   wire [7:0]  i_port,
    input   wire [5:0]  i_button,
    input   wire [3:0]  i_link_pow,

    // Serial outputs (2x i_clk frequency due to DDR)
    output  wire        o_clk_s,
    output  wire        o_d0_s,
    output  wire        o_d1_s
);

wire d0_s, d1_s;
wire d0_reset, d1_reset;
reg [15:0] d0_data;
reg [15:0] d1_data;
wire d0_data_rq, d1_data_rq;

//Reset sequence. Since each transmission takes 30 cycles, we can sample the digital
//inputs at twice the speed by starting both lines with a 15 cycle offset
reg [4:0] count;
initial begin
  count <= 5'b0;
end
always @(posedge i_clk)
begin
  if (count < 5'd20) count <= count + 1'b1;
end
//Start the first line at 5 cycles, to give time to other parts to start producing data
assign d0_reset = (count < 5) ? 1'b1 : 1'b0;
//Start the second line 15 cycles after that
assign d1_reset = (count < 20) ? 1'b1 : 1'b0;

lvds_8b10b_send #(
  .NUM_BYTES(NUM_BYTES)
  ) d0 (
    .clk(i_clk),
    .reset(d0_reset),
    .data(d0_data),
    .data_read_o(d0_data_rq),
    .serial_o(d0_s)
    );

  lvds_8b10b_send #(
    .NUM_BYTES(NUM_BYTES)
    ) d1 (
      .clk(i_clk),
      .reset(d1_reset),
      .data(d1_data),
      .data_read_o(d1_data_rq),
      .serial_o(d1_s)
      );

//Port sampling
always @(posedge i_clk)
begin
  if (d0_data_rq) begin
    d0_data <= {port, 2'b00, button};
  end

  if (d1_data_rq) begin
    d1_data <= {port, 4'b0000, link_pow};
  end
end

//Simple unregistered output buffers
SB_IO # (
    .PIN_TYPE(6'b011000),
    .IO_STANDARD("SB_LVCMOS")
) clk_ddr (
    .PACKAGE_PIN(o_clk_s),
    .D_OUT_0(i_clk)
);

SB_IO # (
    .PIN_TYPE(6'b011000),
    .IO_STANDARD("SB_LVCMOS")
) d0_ddr (
    .PACKAGE_PIN(o_d0_s),
    .D_OUT_0(d0_s)
);

SB_IO # (
    .PIN_TYPE(6'b011000),
    .IO_STANDARD("SB_LVCMOS")
) d1_ddr (
    .PACKAGE_PIN(o_d1_s),
    .D_OUT_0(d1_s)
);

endmodule
