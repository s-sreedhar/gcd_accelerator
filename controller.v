`timescale 1ns/1ps


// State encoding
//   S0 IDLE     – wait for start; do nothing
//   S1 LOAD_A   – assert sel_in=1, ldA=1  → A ← data_in
//   S2 LOAD_B   – assert sel_in=1, ldB=1  → B ← data_in
//   S3 COMPARE  – wait one cycle for comparator to settle
//   S4 SUB_B    – B ← B − A  (when A < B, i.e. gt=1 from A>B perspective)
//   S5 SUB_A    – A ← A − B  (when A > B)
//   S6 DONE     – pulse done for one cycle, return to IDLE
//
// Timing note
//   Every state's OUTPUT is captured by the register on the NEXT posedge.
//   Example: S1 asserts ldA + sel_in; the posedge at the end of S1 loads A.
//   The FSM then moves to S2 on that same edge. This is correct.


module HCF_controller (
    input  clk,
    input  rst,         // active-high synchronous reset
    input  lt,          // A < B
    input  gt,          // A > B
    input  eq,          // A == B
    input  start,       // begin a new computation
    output reg ldA,
    output reg ldB,
    output reg sel1,
    output reg sel2,
    output reg sel_in,
    output reg done
);

    // State encoding
    localparam [2:0]
        S0 = 3'd0,   // IDLE
        S1 = 3'd1,   // LOAD_A
        S2 = 3'd2,   // LOAD_B
        S3 = 3'd3,   // COMPARE
        S4 = 3'd4,   // SUB_B  (B = B − A)
        S5 = 3'd5,   // SUB_A  (A = A − B)
        S6 = 3'd6;   // DONE

    reg [2:0] state, next_state;

    //  State register (synchronous reset) 
    always @(posedge clk) begin
        if (rst) state <= S0;
        else     state <= next_state;
    end

    //  Next-state logic (combinational) 
    always @(*) begin
        case (state)
            S0: next_state = start ? S1 : S0;

            // S1 output asserts ldA + sel_in; register captures on the
            // posedge that exits S1, so A is loaded as we enter S2.
            S1: next_state = S2;

            // Similarly B is loaded as we enter S3.
            S2: next_state = S3;

            S3: begin
                if      (eq) next_state = S6;
                else if (lt) next_state = S4;   // A < B → B = B − A
                else if (gt) next_state = S5;   // A > B → A = A − B
                else         next_state = S3;   // X state guard
            end

            // Subtraction result is captured on posedge leaving S4/S5
            S4: next_state = S3;
            S5: next_state = S3;

            S6: next_state = S0;

            default: next_state = S0;
        endcase
    end

    // Output logic (Moore) 
    always @(*) begin
        // Safe defaults – no register is loaded, bus selects subOut
        ldA    = 1'b0;
        ldB    = 1'b0;
        sel1   = 1'b0;   // x = A
        sel2   = 1'b0;   // y = A  (irrelevant when no load)
        sel_in = 1'b0;   // bus = subOut
        done   = 1'b0;

        case (state)
            // S0: IDLE
            //   No register is loaded here; we just wait for start.
            //   (Loading happens in S1/S2 so the testbench can present
            //    fresh data before the rising edge.)
            S0: begin
                /* nothing – outputs at default */
            end

            // S1: LOAD_A
            //   bus = data_in, latch into A on the posedge at end of S1.
            S1: begin
                sel_in = 1'b1;   // bus ← data_in
                ldA    = 1'b1;   // A ← bus on next posedge
            end

            // S2: LOAD_B
            //   bus = data_in, latch into B on the posedge at end of S2.
            S2: begin
                sel_in = 1'b1;   // bus ← data_in
                ldB    = 1'b1;   // B ← bus on next posedge
            end

            // S3: COMPARE
            //   Outputs stay at default – comparator outputs (lt/gt/eq) are
            //   combinationally derived from the register outputs, so they
            //   are already valid; we just read them in next-state logic.
            S3: begin
                /* nothing */
            end

            // S4: B = B − A
            //   x = B (sel1=1), y = A (sel2=0)  →  subOut = B − A
            //   bus = subOut (sel_in=0), load B.
            S4: begin
                sel1 = 1'b1;   // x = B
                sel2 = 1'b0;   // y = A
                ldB  = 1'b1;   // B ← (B − A) on next posedge
            end

            // S5: A = A − B
            //   x = A (sel1=0), y = B (sel2=1)  →  subOut = A − B
            //   bus = subOut (sel_in=0), load A.
            S5: begin
                sel1 = 1'b0;   // x = A
                sel2 = 1'b1;   // y = B
                ldA  = 1'b1;   // A ← (A − B) on next posedge
            end

            // S6: DONE
            //   Pulse done for one cycle. A holds the GCD result.
            S6: begin
                done = 1'b1;
            end

            default: begin
                /* safe defaults already set */
            end
        endcase
    end

endmodule