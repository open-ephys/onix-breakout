module lvds_8b10b_receive #(
    parameter NUM_BYTES = 2,
    parameter COMMA_CODE = 9'b100111100, //K28.1

    parameter BYTES_COUNT_BITS = $clog2(NUM_BYTES)

  )(
    input clk,
    input reset,

    input serial,
    output reg[8*NUM_BYTES - 1 : 0] data_o = 'b0,
    output reg data_rdy_o = 1'b0,

    output reg code_err_o = 1'b0,
    output reg disp_err_o = 1'b0,
    output reg sync_err_o = 1'b0
  );

  localparam  COMMA_SEQUENCE = 8'b01111100;

  reg [8:0] received_code;
  wire[8:0] code_output;
  reg [9:0] serial_input;
  reg [9:0] code_input;
  wire dispout;
  reg dispin = 1'b0;
  reg dispin_next = 1'b0;
  reg dispin_detected = 1'b0;
  wire code_err;
  wire disp_err;
  reg code_err_r = 1'b0;
  reg disp_err_r = 1'b0;
  reg sync_err_r = 1'b0;

  reg [3:0] bit_count = 'b0;
  reg comma = 1'b0;
  reg [BYTES_COUNT_BITS-1 : 0] cur_byte = 'd0;
  reg [8*NUM_BYTES - 1 : 0] data = 'b0;

  decode8b10b decoder (
    .datain(code_input),
    .dispin(dispin),
    .dataout(code_output),
    .dispout(dispout),
    .code_err(code_err),
    .disp_err(disp_err)
  ) ;

  localparam S_WAITSYNC = 3'd0,
             S_RECVSYNC = 3'd1,
             S_LATCHSYNC = 3'd2,
             S_CHECKSYNC = 3'd3,
             S_RECVBYTE = 3'd4,
             S_LATCHBYTE = 3'd5,
             S_CHECKBYTE = 3'd6,
             S_SEND = 3'd7;
  reg [2:0] state = S_WAITSYNC;

//serial input and align detect
  always @(posedge reset or posedge clk)
  begin
      if (reset) begin
        serial_input <= 'b0;
        bit_count <= 'b0;
        dispin_detected <= 1'b0;
        comma <= 1'b0;
      end else begin
        serial_input <= {serial, serial_input[9:1]};
        comma <= 1'b0;
        if ( {serial, serial_input[9:3]} == COMMA_SEQUENCE && state == S_WAITSYNC) begin
          comma <= 1'b1;
          dispin_detected = 1'b0;
          bit_count <= 4'd8;
        end else if ( {serial, serial_input[9:3]} == ~COMMA_SEQUENCE && state == S_WAITSYNC) begin
          comma <= 1'b1;
          dispin_detected = 1'b1;
          bit_count <= 4'd8;
        end else if (bit_count == 4'd9) begin
          bit_count <= 4'd0;
        end else begin
          bit_count <= bit_count + 1'b1;
        end
      end
  end

  //Data output state machine
  //Since we know that it takes 10 cycles to read a whole code, we can use different states
  //for decoding and storing data safely

  always @(posedge reset or posedge clk)
  begin
    if (reset) begin
      state <= S_WAITSYNC;
      data_rdy_o <= 1'b0;
      code_err_o <= 1'b0;
      code_err_r <= 1'b0;
      disp_err_o <= 1'b0;
      disp_err_r <= 1'b0;
      sync_err_r <= 1'b0;
      dispin_next <= 1'b0;
      cur_byte <= 'b0;
      data <= 'b0;
      data_o <= 'b0;
    end else begin
      data_rdy_o <= 1'b0;
      case (state)
        S_WAITSYNC: begin
          disp_err_r <= 1'b0;
          code_err_r <= 1'b0;
          sync_err_r <= 1'b0;
          if (comma) begin
            state <= S_RECVSYNC;
            dispin_next <= dispin_detected;
          end
        end
      S_RECVSYNC: begin
        if (bit_count == 4'd0) begin
          code_input <= serial_input;
          dispin <= dispin_next;
          state <= S_LATCHSYNC;
        end
      end
      S_LATCHSYNC: begin
        if (disp_err == 1'b1) disp_err_r <= 1'b1;
        if (code_err == 1'b1) code_err_r <= 1'b1;
        received_code <= code_output;
        dispin_next <= dispout;
        state <= S_CHECKSYNC;
      end
      S_CHECKSYNC: begin
        if (received_code != COMMA_CODE) begin //We received an invalid comma code. Send the error and reset
          sync_err_r <= 1'b1;
          state <= S_SEND;
        end else begin
          state <= S_RECVBYTE;
          cur_byte <= 'b0;
        end
      end
      S_RECVBYTE: begin
        if (bit_count == 4'd0) begin
          code_input <= serial_input;
          dispin <= dispin_next;
          state <= S_LATCHBYTE;
        end
      end
      S_LATCHBYTE: begin
        if (disp_err == 1'b1) disp_err_r <= 1'b1;
        if (code_err == 1'b1) code_err_r <= 1'b1;
        received_code <= code_output;
        dispin_next <= dispout;
        state <= S_CHECKBYTE;
      end
      S_CHECKBYTE: begin
        if (received_code[8] == 1'b1) begin //unexpected control code. Just reset just in case
          sync_err_r <= 1'b1;
          state <= S_SEND;
        end else begin
          data[cur_byte*8 +: 8] <= received_code[7:0];
          if (cur_byte == NUM_BYTES - 1) begin
            cur_byte <= 'b0;
            state <= S_SEND;
          end else begin
            cur_byte <= cur_byte + 1'b1;
            state <= S_RECVBYTE;
          end
        end
      end
      S_SEND: begin
        disp_err_o <= disp_err_r;
        code_err_o <= code_err_r;
        sync_err_o <= sync_err_r;
        data_o <= data;
        data_rdy_o <= 1'b1;
        state <= S_WAITSYNC;
      end
      endcase
    end
  end


  endmodule
