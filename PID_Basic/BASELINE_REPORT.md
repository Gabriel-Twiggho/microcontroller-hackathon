# PID_Basic baseline report

Date: 2026-08-09

This report describes the current single-cycle PID_Basic CPU running
`tests/PID_Performance_test.asm`. The workload performs 1000 complete PID
updates after initialization.

## Simulation baseline

| Metric | Baseline |
| --- | ---: |
| Correctness | PASS (7/7 checks) |
| PID iterations tested | 1000 |
| Cycles / PID update | 19 |
| Total measured PID cycles | 19000 |
| Simulation/board clock | 50 MHz (20 ns period) |
| Time / PID update at 50 MHz | 0.380 µs |
| PID loop rate at 50 MHz | 2,631,579 updates/s |

The 50 MHz value is the clock selected by the testbench. It provides a stable
time scale for reporting simulation throughput; it is not a measured Fmax.
The architecture-independent result to use when comparing CPU revisions is
19 cycles per PID update.

```text
time_per_update_us = 19 / selected_clock_MHz
simulated_loop_rate = selected_clock_MHz * 1,000,000 / 19
```

## Quartus FPGA baseline

Quartus Prime Lite 25.1std.0 Build 1129 successfully completed analysis,
fitting, assembly, and timing analysis for the DE1-SoC Cyclone V
`5CSEMA5F31C6`. The build uses a 20 ns (50 MHz) clock constraint.

| Metric | Baseline |
| --- | ---: |
| Logic utilization | 4,814 / 32,070 ALMs (15%) |
| Combinational ALUTs | 4,144 |
| Registers | 9,233 |
| DSP blocks | 2 / 87 |
| Block-memory bits | 0 |
| Worst-corner Fmax | 57.83 MHz |
| Setup slack at 50 MHz | +2.708 ns |
| Hold slack at 50 MHz | +0.609 ns |
| PID time at Fmax | 0.329 us/update |
| PID rate at Fmax | 3.044 million updates/s |

This FPGA analysis uses a 256-word instruction ROM initialized with the
decimal PID program and a 1 KiB data memory. The normal simulation profile
continues to use its original 8,192-word instruction memory and 32 KiB data
memory. The reduced FPGA profile is necessary because the CPU's combinational
memory reads do not infer Cyclone V block RAM. Even the 1 KiB data memory is
implemented as 8,192 registers; the original 32 KiB asynchronous data memory
does not fit this FPGA as written.

The 57.83 MHz value is a post-fit estimate, but this is an analysis build
rather than a board-ready top level: pins and external I/O delays are not
assigned. The positive setup and hold slack confirms that the internal 50 MHz
clock target is met.

## Correctness and cycle measurement

Run from the repository root:

```bash
python3 resources/software/scripts/simulate.py \
  PID_Basic/PID_Basic.simulate.yml
```

Measured output:

```text
PID iterations: 1000
Total PID cycles: 19000
Cycles per PID update: 19
Result: ALL 7 checks PASSED
```

Run the FPGA build from the repository root:

```bash
python3 resources/software/scripts/synthesize.py \
  PID_Basic/PID_Basic.synthesize.yml
```

After 1000 updates, the test verifies error `r3 = 6`, integral `r4 = 6010`,
derivative `r6 = 0`, P `r8 = 12`, I `r9 = 6010`, D `r10 = 0`, and output
`r11 = 6022`.
