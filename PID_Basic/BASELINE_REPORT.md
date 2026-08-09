# PID_Basic baseline report

Date: 2026-08-08

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

After 1000 updates, the test verifies error `r3 = 6`, integral `r4 = 6010`,
derivative `r6 = 0`, P `r8 = 12`, I `r9 = 6010`, D `r10 = 0`, and output
`r11 = 6022`.
