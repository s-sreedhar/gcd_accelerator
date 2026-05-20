`timescale 1ns/1ps

`include "datapath.v"
`include "controller.v"

module hcf_top (
    input         clk,
    input         rst,       // active-high synchronous reset
    input         start,     // pulse or level; FSM re-arms on each S0 visit
    input  [15:0] data_in,   // shared data bus for loading A then B
    output        done,      // high for one cycle when GCD is ready
    output [15:0] result     // GCD result (valid when done=1)
);

    // Internal control/status wires 
    wire ldA, ldB, sel1, sel2, sel_in;
    wire gt, lt, eq;

    // Datapath 
    HCF_datapath DP (
        .gt      (gt),
        .lt      (lt),
        .eq      (eq),
        .ldA     (ldA),
        .ldB     (ldB),
        .sel1    (sel1),
        .sel2    (sel2),
        .sel_in  (sel_in),
        .rst     (rst),
        .clk     (clk),
        .data_in (data_in)
    );

    //  Controller 
    HCF_controller CTR (
        .clk     (clk),
        .rst     (rst),
        .lt      (lt),
        .gt      (gt),
        .eq      (eq),
        .start   (start),
        .ldA     (ldA),
        .ldB     (ldB),
        .sel1    (sel1),
        .sel2    (sel2),
        .sel_in  (sel_in),
        .done    (done)
    );

    // GCD result lives in register A of the datapath
    assign result = DP.aOut;

endmodule