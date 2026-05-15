# Custom GCD Accelerator

## Project Overview

This project implements a custom hardware accelerator for computing the greatest common divisor (GCD) of two 16-bit values using the subtraction-based Euclidean algorithm.

The design emphasizes a clean separation between the datapath and control path, enabling deterministic latency and efficient FPGA-friendly execution.

## Key Features

- Subtraction-based Euclidean GCD algorithm
- 16-bit parallel datapath with PIPO registers
- FSM controller for exact cycle sequencing
- Comparator-driven decision logic using `gt`, `lt`, and `eq`
- Modular Verilog with reusable arithmetic building blocks
- Testbench with multiple vectors and VCD waveform generation

## Architecture

### Datapath

- `PIPO` registers hold operands `A` and `B`
- `mux` modules select initial input versus feedback data
- `compare` module generates `lt`, `gt`, and `eq` status flags
- `sub` unit computes `A - B` or `B - A`

### Control Path

- FSM controller loads inputs, compares values, and drives subtraction cycles
- Control signals: `ldA`, `ldB`, `sel1`, `sel2`, `sel_in`, `done`
- Output `done` indicates when the final GCD is available

## Files

- `datapath.v` — top-level datapath module with registers, muxes, comparator, and subtractor
- `controller.v` — finite-state machine controlling the GCD iteration
- `testbench.v` — simulation environment with automated test vectors and waveform dump
- `mux.v` — 16-bit 2-to-1 multiplexer
- `sub.v` — 16-bit subtractor
- `pipo.v` — 16-bit parallel-in parallel-out register
- `compare.v` — comparator producing `lt`, `gt`, and `eq`

## Architecture Image

```
+-------------------+     +-------------------+
|   Control Path    |     |    Datapath       |
|   (FSM)           |     |                   |
|                   |     |  +-------------+  |
|  +-------------+  |     |  |  PIPO A     |  |
|  |   State     |  |     |  +-------------+  |
|  |  Machine    |  |     |         |        |
|  +-------------+  |     |  +-------------+  |
|                   |     |  |   MUX       |  |
|  ldA, ldB         |     |  +-------------+  |
|  sel1, sel2       |     |         |        |
|  sel_in, done     |     |  +-------------+  |
|                   |     |  |  Compare    |  |
+-------------------+     |  +-------------+  |
          |               |         |        |
          |               |  +-------------+  |
          |               |  |   MUX       |  |
          |               |  +-------------+  |
          |               |         |        |
          |               |  +-------------+  |
          |               |  |  PIPO B     |  |
          |               |  +-------------+  |
          |               |         |        |
          |               |  +-------------+  |
          |               |  |   Sub       |  |
          |               |  +-------------+  |
          +---------------+         |        |
                            +-------------+
```

## Control Path Signal Generation Table

| State | ldA | ldB | sel1 | sel2 | sel_in | Done | Operation            |
| ----- | --- | --- | ---- | ---- | ------ | ---- | -------------------- |
| S0    | 1   | 0   | X    | X    | 1      | 0    | Load Operand A       |
| S1    | 0   | 1   | X    | X    | 1      | 0    | Load Operand B       |
| S2    | 0   | 0   | X    | X    | X      | 0    | Wait/Stabilize       |
| S3    | 0   | 0   | X    | X    | X      | 0    | Compare (lt, gt, eq) |
| S4    | 0   | 1   | 1    | 0    | 0      | 0    | B = B - A            |
| S5    | 1   | 0   | 0    | 1    | 0      | 0    | A = A - B            |
| S6    | 0   | 0   | X    | X    | X      | 1    | Assert Done Flag     |

## FSM Controller Hardware Architecture

The FSM controller is implemented as a Moore machine with 7 states (S0-S6). It uses synchronous state transitions on the positive edge of the clock and combinational output logic. The state machine reads the status signals (gt, lt, eq) from the datapath to determine the next state and drives the control signals to manipulate the datapath registers and multiplexers.

State transitions:

- S0 (Idle/Start): Wait for start signal, then load A
- S1: Load B
- S2: Stabilize
- S3: Compare A and B
  - If A == B, go to S6 (Done)
  - If A < B, go to S4 (Subtract B - A)
  - If A > B, go to S5 (Subtract A - B)
- S4/S5: Perform subtraction, then back to S3
- S6: Assert done, reset to S0 on next start

## Verification

The testbench runs several GCD cases, including:

- 143 and 78 → 13
- 50 and 10 → 10
- 17 and 13 → 1
- 100 and 100 → 100
- 24 and 60 → 12
- 1 and 255 → 1
- 1024 and 128 → 128

A VCD trace file `gcd.vcd` is generated for waveform inspection in GTKWave or similar viewers.

## Simulation Results

The testbench runs multiple GCD computations and verifies the results:

```
--------------------------------------------------
Testing GCD of 143 and 78
Result : 13
--------------------------------------------------
Testing GCD of 50 and 10
Result : 10
--------------------------------------------------
Testing GCD of 17 and 13
Result : 1
--------------------------------------------------
Testing GCD of 100 and 100
Result : 100
--------------------------------------------------
Testing GCD of 24 and 60
Result : 12
--------------------------------------------------
Testing GCD of 1 and 255
Result : 1
--------------------------------------------------
Testing GCD of 1024 and 128
Result : 128
All test cases completed.
```

## GTKWave Inspection

The generated `gcd.vcd` file can be opened in GTKWave to visualize the waveforms. Key signals to observe:

- `start`: Initiates the computation
- `ldA`, `ldB`: Pulses when loading operands
- `gt`, `lt`, `eq`: Comparison results driving the FSM
- `state`: FSM state progression (0-6)
- `done`: Asserts when GCD is computed
- `DP.aOut`, `DP.bOut`: Register values during iteration
- `data_in`: Input data bus

The waveform shows the iterative subtraction process, with registers updating every few clock cycles until equality is reached.

## How to Run

1. Compile and simulate with Icarus Verilog:
   ```sh
   iverilog -o gcd_tb testbench.v datapath.v controller.v mux.v sub.v pipo.v compare.v
   vvp gcd_tb
   ```
2. Open the waveform file:
   ```sh
   gtkwave gcd.vcd
   ```

## Showcase Tips

- Highlight the modular datapath/control separation.
- Show the FSM state progression and how `gt`, `lt`, and `eq` drive the subtraction path.
- Explain the design choice for subtraction-based GCD: no divider units, simple comparator/subtractor logic, and deterministic behavior.
- Use waveform screenshots to illustrate handshake signals `ldA`, `ldB`, and final `done`.

## Notes

This design is easily scalable to wider bit-widths by updating the 16-bit vector widths in each module without changing the FSM logic.
