`timescale 1 ns / 100 ps

`include "lvds_8b10b_send.v"

module lvds_8b10b_receive_tb ();

    parameter SYSCLK_PERIOD = 20;// 50MHZ
    parameter NUM_BYTES = 2;

    // System
    reg i_clk;
    reg i_reset;

    // Send module
    reg [8 * NUM_BYTES - 1 : 0] i_data;
    wire o_serial;
    wire o_data_read;

    // Receive module
    reg i_serial;
    wire [8*NUM_BYTES - 1 : 0] o_data;
    wire o_data_rdy;
    wire o_disp_err;
    wire o_code_err;
    wire o_sync_err;

    initial begin
        i_clk = 1'b0;
        i_reset = 1'b1;
    end

    // Start-up reset
    initial #(SYSCLK_PERIOD * 10 ) i_reset = 1'b0;

    // Clock
    always #(SYSCLK_PERIOD / 2.0) i_clk = ~i_clk;

    // Send
    lvds_8b10b_send #(
        .NUM_BYTES(NUM_BYTES)
    ) send (.*);

    // Receive (uut)
    lvds_8b10b_receive # (
        .NUM_BYTES(NUM_BYTES)
    ) uut (.*);

    // Stimulus
    reg [8 * NUM_BYTES - 1 : 0] sample [0:3];
    reg [1:0] count = 'b0;
    reg [1:0] reps = 'b0;
    reg [31:0] clkcount = 'b0;

    initial begin
        $dumpfile("lvds_8b10b_receive_tb.vcd");
        $dumpvars;

        sample[0] = 16'h0001;
        sample[1] = 16'habcd;
        sample[2] = 16'habcd;
        sample[3] = 16'hFF67;
    end

    always @ (posedge i_clk) begin

        clkcount <= clkcount + 1'b1;
        if (reps == 2'd3) $stop;

        if (o_data_read) begin
            clkcount <= 'b0;
            i_data <= sample[count];
            if (count == 2'd3) begin
                count <= 'b0;
                reps <= reps + 1'b1;
            end else begin
                count <= count + 1'b1;
            end
        end
    end

   always @(*) begin
        i_serial <= #2 o_serial;

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
