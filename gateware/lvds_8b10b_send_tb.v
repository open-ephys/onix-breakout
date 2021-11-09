`timescale 1 ns / 100 ps

module lvds_8b10b_send_tb ();

    parameter SYSCLK_PERIOD = 20; // 50MHZ
    parameter NUM_BYTES = 2;

    reg i_clk;
    reg i_reset;
    reg [8 * NUM_BYTES - 1 : 0] i_data;
    wire o_serial;
    wire o_data_read;

    initial begin
        i_clk = 1'b0;
        i_reset = 1'b1;
    end

    // Start-up reset
    initial #(SYSCLK_PERIOD * 10 ) i_reset = 1'b0;

    // Clock
    always #(SYSCLK_PERIOD / 2.0) i_clk = ~i_clk;

    lvds_8b10b_send # (
        .NUM_BYTES(NUM_BYTES)
    ) uut (.*);

    // Stimulus
    reg [1:0] count = 'b0;
    reg [8 * NUM_BYTES - 1 : 0] sample [0:2];

    initial begin
        $dumpfile("lvds_8b10b_send_tb.vcd");
        $dumpvars;

        sample[0] = 16'h0001;
        sample[1] = 16'habcd;
        sample[2] = 16'habcd;
    end

    always @(posedge i_clk) begin
        if (o_data_read) begin
            if (count == 2'd3) $stop;
            else begin
                i_data <= sample[count];
                count <= count + 1'b1;
            end
        end
   end

endmodule
