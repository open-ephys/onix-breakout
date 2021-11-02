// A packet is a 2-bit command, 2-bit slow data, and 8-bit high-speed digital
// out:
//
//  [cmd1, cmd0, slow1, slow0, dout7, dout6, ..., dout0]
//
// Cmd          | Action
// -------------------------------------------------------------------------
// 00           | Shift slow bits into slow shift register
// 01           | Validate and move slow shift register to outputs and set inital
//              | state to [0, ..., 0, slow1, slow0]. slow1 should be the desired MSB at next
//              | cmd.
// 10           | Reserved, same as 00 currently. Don't use.
// 11           | Reset
// -------------------------------------------------------------------------
//
// Packets are sent through 8b10b encoding including a control code and a 16-bit words
// 4 MSB bits are zero-paded
//
// The full slow word is 48 bits and consists of the following elements:
//
//  MSB [acq_running,
//       acq_rst_done,
//       reserved1, reserved0,
//       ledlevel3, ledlevel2, ledlevel1, ledlevel0,
//       ledmode1, ledmod0,
//       porta_status1, porta_status0,
//       portb_status1, portb_status0,
//       portc_status1, portc_status0,
//       portd_status1, portd_status0,
//       aio_dir11, aio_dir10, ..., aio_dir0,
//       harp_conf1, harp_conf0,
//       gpio_dir15, gpio_dir14, ..., gpio_dir0] LSB
//
// which are decoded as follows:
//
// Signal       | Description
// -------------------------------------------------------------------------
// acq_running  | Host hardware run state. 0 = not running, 1 = running
// acq_rst_done | Host reset state. 0 = reset not complete, 1 = reset complete
// reserved     | NA
// ledlevel     | 4 bit register for general LED brighness. 0 = dimmest, 16 = brightest
// ledmode      | 2 bit register for LED mode. 0 = all off, 1 = only power/running, 2 = power/running, pll, harp, 3 = all on
// portx_status | 2 bit register describing the headstage port state. 00: power off, 01: power on, 10: locked, 11: device map good.
// aio_dir      | 12 bit register describing the direcitonality of each of the analog inputs. 0 = input, 1 = output.
// harp_conf    | 2 bit register for possible future harp configuration.
// gpio_dir     | 16 bit register for possible future digital io directionality configuration.
// -------------------------------------------------------------------------

module host_to_breakout
(
    // Local clk
    // Must be have 180 phase alignment with the input data
    input   wire            i_clk,

    input   wire            i_d0_s,

    // Complete slow word
    output  reg             o_slow_valid,
    output  reg     [47:0]  o_slow_value,

    // Slow outputs (broken up version of o_slow_value)
    output reg              o_acq_running,
    output reg              o_acq_reset_done,
    output reg      [1:0]   o_reserved,
    output reg      [3:0]   o_ledlevel,
    output reg      [1:0]   o_ledmode,
    output reg      [1:0]   o_porta_status,
    output reg      [1:0]   o_portb_status,
    output reg      [1:0]   o_portc_status,
    output reg      [1:0]   o_portd_status,
    output reg      [11:0]  o_aio_dir,
    output reg      [1:0]   o_harp_conf,
    output reg      [15:0]  o_gpio_dir,

    // Host to breakout reset
    output  reg             o_reset,

    // Parallel outputs
    output  reg     [7:0]   o_port

    // Debug
    //output  reg     [1:0]   o_ddr_debug,
    //output  reg     [47:0]  o_slow_shift_debug,
    //output  reg     [11:0]  o_shift_d0_debug
);

// Data
wire d0_s;
wire [15:0] data_recvd;
wire data_rdy;

//Error detection
wire disp_err;
wire code_err;
wire sync_err;
wire comm_error;
reg had_error = 1'b0;
reg [4:0] slow_count = 5'b0;
localparam SLOW_TRANSFERS = 5'd24;
assign comm_error = disp_err | code_err | sync_err;


// Shift register state
reg [47:0] slow_shift = 0;

// Debug
//assign o_ddr_debug = ~ddr_d0_s;
//assign o_slow_shift_debug = slow_shift;
//assign o_shift_d0_debug  = shift_d0;

lvds_8b10b_receive #(
      .NUM_BYTES(2)
    ) dut (
      .clk(i_clk),
      .reset(1'b0),
      .serial(d0_s),
      .data_o(data_recvd),
      .data_rdy_o(data_rdy),
      .disp_err_o(disp_err),
      .code_err_o(code_err),
      .sync_err_o(sync_err)
      );

// Initialize
initial begin
    o_acq_reset_done <= 1'b0;
    o_acq_running <= 1'b0;
    o_reserved <= 2'b00;
    o_ledlevel <= 4'b0011;
    o_ledmode <= 2'b11;
end

//Act when received data
always @ (posedge i_clk) begin

    if (data_rdy == 1'b1) begin
      if (comm_error == 1'b1) had_error <= 1'b1; //Ignore everything if there was a reception error
      else begin
      // Update fast output port
        o_port <= {data_recvd[7:0]};

        // Feed slow word
        slow_shift <= {slow_shift[45:0], data_recvd[9:8]};
      // Check slow word control bits
        case (data_recvd[11:10])
            2'b00 : begin // Shift slow data in
                o_reset <= 'b0;
                o_slow_valid <= 'b0;
                slow_count <= slow_count + 1'b1;

            end
            2'b01 : begin // Set outputs
                o_reset <= 1'b0;
                had_error <= 1'b0;

                //only process serial register if all transfers have been successful since last validation
                if (had_error == 1'b0 && slow_count == SLOW_TRANSFERS - 1) begin
                  o_slow_valid <= 1'b1;
                  o_slow_value <= slow_shift;

                  o_acq_running <= slow_shift[47];
                  o_acq_reset_done <= slow_shift[46];
                  o_reserved <= slow_shift[45:44];
                  o_ledlevel <= slow_shift[43:40];
                  o_ledmode <= slow_shift[39:38];
                  o_porta_status <= slow_shift[37:36];
                  o_portb_status <= slow_shift[35:34];
                  o_portc_status <= slow_shift[33:32];
                  o_portd_status <= slow_shift[31:30];
                  o_aio_dir <= slow_shift[29:18];
                  o_harp_conf <= slow_shift[17:16];
                  o_gpio_dir <= slow_shift[15:0];
                end

            end
            2'b10 : begin // Reserved
                o_reset <= 'b0;
                o_slow_valid <= 'b0;
                slow_count <= 'b0;
                had_error <= 'b0;
            end
            2'b11 : begin // Signal reset
                o_reset <= 'b1;
                o_slow_valid <= 'b0;
                slow_count <= 'b0;
                had_error <= 'b0;
            end
        endcase
      end
    end
end

SB_IO # (
    .PIN_TYPE(6'b000010),
    .IO_STANDARD("SB_LVCMOS")
) d0_ddr (
    .PACKAGE_PIN(i_d0_s),
    .CLOCK_ENABLE(1'b1),
    .INPUT_CLK(i_clk),
    .D_IN_0(d0_s])
);
endmodule
