`include "encode8b10b.v"

module lvds_8b10b_send # (
    parameter NUM_BYTES = 2,
    parameter COMMA_CODE = 9'b100111100, // K28.1
    parameter BYTES_COUNT_BITS = $clog2(NUM_BYTES)
) (
    input   wire                        i_clk,
    input   wire                        i_reset,

    input   wire[8 * NUM_BYTES - 1 : 0] i_data,
    output  reg                         o_data_read,

    output  reg                         o_serial
);

localparam FIRST_OUTPUT = 10'b1010101010; // Invalid but 0 disparity code for the first cycle

reg [8 * NUM_BYTES - 1 : 0] data_r = 'b0;
reg [BYTES_COUNT_BITS : 0] next_byte = 'd0;
reg [3:0] bit_count = 'b0;

reg [8:0] code_input = COMMA_CODE;
reg [8:0] next_code;
wire [9:0] code_output;
reg [9:0] serial_output = FIRST_OUTPUT;
reg dispin = 1'b0;
reg dispin_next = 1'b0;
wire dispout;

encode8b10b encoder (
    .datain(code_input),
    .dispin(dispin),
    .dataout(code_output),
    .dispout(dispout)
);

always @(posedge i_clk) begin

    if (i_reset) begin
        data_r <= 'b0;
        next_byte <= 'd0;
        bit_count <= 'b0;
        code_input <= COMMA_CODE;
        o_data_read <= 1'b0;
        dispin <= 1'b0;
        dispin_next <= 1'b0;
        serial_output <= FIRST_OUTPUT;
        o_serial <= 1'b0;
    end else begin
        o_serial <= serial_output[bit_count];
        bit_count <= bit_count + 1'b1;
        o_data_read <= 1'b0;
        if (bit_count == 4'd0 && next_byte == 'd1 ) begin
            //if (next_byte == 'd1) begin // Latch data on comma symbol using a simple FIFO interface
            o_data_read <= 1'b1; // Request data
            //end
        end else if (bit_count == 4'd2 && next_byte == 'd1) begin
            // if (next_byte == 'd1) begin
            data_r <= i_data; // Latch data
            //end
        end else if (bit_count == 4'd4) begin // Begin encoding. This position is arbitrary, so we give a little leeway
            code_input <= next_code;
            dispin <= dispin_next;
        end else if (bit_count == 4'd9) begin
            bit_count <= 'b0;
            serial_output <= code_output;
            dispin_next <= dispout;
            if (next_byte == NUM_BYTES) begin
                next_byte <= 'b0;
            end else begin
                next_byte <= next_byte + 1'b1;
            end
        end
    end
end

always @(next_byte, data_r) begin
    if (next_byte == 'b0) begin
        next_code <= COMMA_CODE;
    end else begin
        next_code <= data_r[8 * (next_byte - 1) +: 8];
    end
end

endmodule
