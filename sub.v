module sub (
    output [15:0] subout,
    input  [15:0] in1,
    input  [15:0] in2
);
    assign subout = in1 - in2;
endmodule