module digital_in_sync(
    input   wire        i_clk,

    input   wire [7:0]  i_d,
    output  wire [7:0]  o_d
);

reg [7:0] sync [1:0];

initial begin
    sync[0] <= 8'h00;
    sync[1] <= 8'h00;
end

always @(posedge i_clk) begin
    sync[0] <= sync[1];
    sync[1] <= i_d;
end

assign o_d = sync[0];

endmodule

