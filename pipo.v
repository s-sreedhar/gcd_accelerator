module PIPO (
    output reg [15:0] data_out,
    input      [15:0] data_in,
    input             load,
    input             clk,
    input             rst          // active-high synchronous reset
);
    always @(posedge clk) begin
        if (rst)       data_out <= 16'd0;
        else if (load) data_out <= data_in;
    end
endmodule