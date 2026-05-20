module mux (
    output [15:0] out,
    input  [15:0] in1,
    input  [15:0] in0,
    input         sel
);
    assign out = sel ? in0 : in1;
endmodule