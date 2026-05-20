`timescale 1ns/1ps

`include "PIPO.v"
`include "mux.v"
`include "subtractor.v"

`include "comparator.v"
module HCF_datapath (
    // Status outputs to controller
    output        gt,
    output        lt,
    output        eq,
    // Control inputs from controller
    input         ldA,
    input         ldB,
    input         sel1,     // MUX selecting the minuend  (x): 0=A, 1=B
    input         sel2,     // MUX selecting the subtrahend (y): 0=A, 1=B
    input         sel_in,   // Bus MUX: 0=subOut, 1=data_in (external load)
    input         rst,
    input         clk,
    // External data
    input  [15:0] data_in
);

    wire [15:0] aOut, bOut;
    wire [15:0] x, y;
    wire [15:0] bus;
    wire [15:0] subOut;

    //  Registers 
    PIPO A (
        .data_out (aOut),
        .data_in  (bus),
        .load     (ldA),
        .clk      (clk),
        .rst      (rst)
    );

    PIPO B (
        .data_out (bOut),
        .data_in  (bus),
        .load     (ldB),
        .clk      (clk),
        .rst      (rst)
    );

    // Comparator 
    compare comp (
        .lt    (lt),
        .gt    (gt),
        .eq    (eq),
        .data1 (aOut),
        .data2 (bOut)
    );

    //  Operand MUXes 
    // sel1: chooses the value driven onto x (minuend)
    mux mux_in1 (
        .out  (x),
        .in1  (aOut),   // sel1=0 -> x = A
        .in0  (bOut),   // sel1=1 -> x = B
        .sel  (sel1)
    );

    // sel2: chooses the value driven onto y (subtrahend)
    mux mux_in2 (
        .out  (y),
        .in1  (aOut),   // sel2=0 -> y = A
        .in0  (bOut),   // sel2=1 -> y = B
        .sel  (sel2)
    );

    // Subtractor 
    sub sb (
        .subout (subOut),
        .in1    (x),
        .in2    (y)
    );

    //  Bus MUX 
    // sel_in=0 -> bus = subOut (computation result)
    // sel_in=1 -> bus = data_in (external input)
    mux mux_load (
        .out  (bus),
        .in1  (subOut),
        .in0  (data_in),
        .sel  (sel_in)
    );

endmodule