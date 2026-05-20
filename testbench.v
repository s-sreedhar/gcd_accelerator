
`timescale 1ns/1ps
`include "top.v"

module hcf_tb;

    // DUT interface 
    reg         clk, rst, start;
    reg  [15:0] data_in;
    wire        done;
    wire [15:0] result;

    // Instantiate top 
    hcf_top DUT (
        .clk     (clk),
        .rst     (rst),
        .start   (start),
        .data_in (data_in),
        .done    (done),
        .result  (result)
    );

    //  Clock: 10 ns period 
    initial clk = 1'b0;
    always  #5 clk = ~clk;

    //  Error counter 
    integer errors = 0;

    // Task: load_and_run
    //   Drives data_in at the right time and waits for done.
    //
    // Protocol (matches the FSM):
    //   FSM enters S1 → asserts ldA + sel_in for one full cycle.
    //   We must have data_in = valA BEFORE the posedge that exits S1.
    //   Same for S2 / valB.
    //
    //   The safe approach: present valA as soon as we see ldA rise,
    //   then present valB as soon as we see ldB rise.  Both waits are
    //   combinationally true during the state, so setup hold is met
    //   with respect to the posedge that follows.
    
    task load_and_run;
        input [15:0] valA;
        input [15:0] valB;
        input [15:0] expected;
        begin
            $display("--------------------------------------------");
            $display("HCF(%0d, %0d)  expected = %0d", valA, valB, expected);

            // Trigger the FSM from IDLE (S0 → S1 on the next posedge
            // after start is sampled high).
            @(negedge clk);          // drive inputs between clock edges
            start   = 1'b1;
            data_in = valA;          // pre-load so it is valid in S1

            // Wait until the FSM is in S1 (ldA asserted).
            // Because start was set on a negedge, the FSM advances to S1
            // on the very next posedge.  We wait for ldA here as a sanity
            // check and to be robust against multi-cycle IDLE.
            @(posedge clk);          // FSM: S0 → S1
            // ldA is now asserted (S1 output); A will be captured on the
            // NEXT posedge (end of S1).
            // data_in is already valA – nothing to change.

            @(posedge clk);          // FSM: S1 → S2, A is now loaded
            // S2 asserts ldB + sel_in.  We must present valB before the
            // posedge that ends S2.
            @(negedge clk);          // set data_in safely between edges
            data_in = valB;
            start   = 1'b0;          // de-assert; FSM no longer needs it

            @(posedge clk);          // FSM: S2 → S3, B is now loaded

            // Wait for completion 
            wait (done == 1'b1);
            @(negedge clk);          // sample result mid-cycle (stable)

            // Check
            if (result === expected) begin
                $display("PASS  result = %0d", result);
            end else begin
                $display("FAIL  result = %0d  (expected %0d)", result, expected);
                errors = errors + 1;
            end

            // Wait for FSM to return to IDLE (done pulse is one cycle)
            @(posedge clk);
            @(posedge clk);          // extra slack
        end
    endtask

    // Stimulus 
    initial begin
        // Initialise
        rst     = 1'b1;
        start   = 1'b0;
        data_in = 16'd0;

        // Hold reset for two clock cycles
        @(posedge clk);
        @(posedge clk);
        @(negedge clk);
        rst = 1'b0;

        
        // Test vectors
       

        // General case
        load_and_run(16'd143, 16'd78,   16'd13);

        // One is a multiple of the other
        load_and_run(16'd50,  16'd10,   16'd10);

        // Co-prime / prime
        load_and_run(16'd17,  16'd13,   16'd1);

        // Equal numbers
        load_and_run(16'd100, 16'd100,  16'd100);

        // A < B (asymmetric ordering)
        load_and_run(16'd24,  16'd60,   16'd12);

        // Edge: one operand is 1
        load_and_run(16'd1,   16'd255,  16'd1);

        // Powers of 2
        load_and_run(16'd1024, 16'd128, 16'd128);

        // Large values with non-trivial GCD (272 subtract steps)
        load_and_run(16'd65520, 16'd65280, 16'd240);

        // Consecutive integers (always co-prime)
        load_and_run(16'd89,  16'd55,   16'd1);   // Fibonacci

        
        $display("============================================");
        if (errors == 0)
            $display("ALL TESTS PASSED");
        else
            $display("%0d TEST(S) FAILED", errors);
        $display("============================================");
        $finish;
    end

    //  VCD dump (full hierarchy) 
    initial begin
        $dumpfile("hcf.vcd");
        $dumpvars(0, hcf_tb);   // depth=0 dumps everything
    end

    // Timeout watchdog 
    initial begin
        #2000000;
        $display("TIMEOUT – simulation did not finish in time");
        $finish;
    end

endmodule