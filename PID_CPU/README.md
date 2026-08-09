# PID Basic CMP video demo

This folder is a clean, recording-ready version of the CMP/branch CPU. It
contains only the RTL, assembler, focused assembly tests, and the two configs
needed for simulation and Cyclone V implementation.

## How the tests build up

1. `01_arithmetic_memory_test.asm` checks `LI`, `LOAD`, `STORE`, `ADD`, `SUB`,
   and `MUL`.
2. `02_signed_fixed_point_test.asm` checks signed `SAR` and Q8.8-to-integer
   conversion.
3. `03_cmp_branch_test.asm` checks equal, less-than, greater-than, and
   not-equal control flow.
4. `04_pwm_saturation_test.asm` checks negative, in-range, and over-range PID
   values against the raw PWM range `0..255`.
5. `05_full_pid_pwm_demo.asm` combines the operations into the one workflow
   run during the recording.

The full demo performs 1,000 stable PID updates and produces a Q8.8 controller
output of `50.0`. It saturates the result to `0..255`, converts it from Q8.8,
and writes the raw PWM value `50` to address `0x011C`.
The measured simulation result is 28,000 total cycles, or 28.000 cycles per
PID update.

## Selected configuration

Both YAML files use the tested compatible-minimum profile: 32-bit data and
instructions, 16 registers, 64 instruction words, and 512 data-memory bytes.
The testbench stops after exactly 1,000 visits around `pid_loop`; the
35,000-cycle YAML value is an independent safety timeout.

The FPGA command runs Quartus synthesis, placement, routing, and timing
analysis for a Cyclone V `5CSEMA5F31C6` constrained to 50 MHz. These are
post-fit hardware implementation results, not a physical motor or board run.
With Quartus Prime Lite 25.1, this exact demo fitted successfully using 1,553
ALMs, reported a 58.41 MHz worst-corner Fmax, and had +2.881 ns setup slack at
50 MHz.

Use [`RECORDING_COMMANDS.md`](../RECORDING_COMMANDS.md) from the repository root.
