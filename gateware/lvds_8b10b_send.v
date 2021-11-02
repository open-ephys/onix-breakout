module lvds_8b10b_send #(
    parameter NUM_BYTES = 2,
    parameter COMMA_CODE = 9'b100111100, //K28.1

    parameter BYTES_COUNT_BITS = $clog2(NUM_BYTES)
  )(
    input clk,
    input reset,

    input [8*NUM_BYTES - 1 : 0] data,
    output reg data_read_o,

    output reg serial_o
  );

  localparam FIRST_OUTPUT = 10'b1010101010; //Invalid but 0 disparity code for the first cycle

  reg [8*NUM_BYTES - 1 : 0] data_r = 'b0;
  reg [BYTES_COUNT_BITS : 0] next_byte = 'd0;
  reg [3:0] bit_count = 'b0;

  reg [8:0] code_input = COMMA_CODE;
  reg [8:0] next_code;
  wire [9:0] code_output;
  reg [9:0] serial_output = FIRST_OUTPUT;

  reg dispin = 1'b0;
  reg dispin_next = 1'b0;
  wire dispout;

  encode8b10b encoder
  (
    .datain(code_input),
    .dispin(dispin),
    .dataout(code_output),
    .dispout(dispout)
  );

  always @(posedge clk or posedge reset)
  begin
    if (reset) begin
      data_r <= 'b0;
      next_byte <= 'd0;
      bit_count <= 'b0;
      code_input <= COMMA_CODE;
      data_read_o <= 1'b0;
      dispin <= 1'b0;
      dispin_next <= 1'b0;
      serial_output <= FIRST_OUTPUT;
      serial_o <= 1'b0;
    end else begin
      serial_o <= serial_output[bit_count];
      bit_count <= bit_count + 1'b1;
      data_read_o <= 1'b0;
      if (bit_count == 4'd0) begin
        if (next_byte == 'd1) begin //Latch data on comma symbol using a simple FIFO interface
          data_read_o <= 1'b1; //Request data
        end
      end else if (bit_count == 4'd2) begin
        if (next_byte == 'd1) begin
          data_r <= data; //Latch data
        end
      end else if (bit_count == 4'd4) begin //begin encoding. This position is arbitrary, so we let a little leeway
        code_input <= next_code;
        dispin <= dispin_next;
      end else if (bit_count == 4'd9) begin
        bit_count <= 'b0;
        serial_output <= code_output;
        dispin_next <= dispout;
        if (next_byte == NUM_BYTES) next_byte <= 'b0;
        else next_byte <= next_byte + 1'b1;
      end
    end
  end

  always @(next_byte, data_r)
  begin
    if (next_byte == 'b0) begin
      next_code <= COMMA_CODE;
    end else begin
      next_code <= data_r[8*(next_byte-1) +: 8];
    end
  end


  endmodule
