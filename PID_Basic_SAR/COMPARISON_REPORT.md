# Decimal PID CPU performance comparison

Date: 2026-08-08

This report compares only the performance of `PID_Basic` and
`PID_Basic_SAR`. Each CPU runs its own assembly program for the same decimal
PID workload over 1000 updates.

## Test programs

| CPU | Assembly program | Product/output format |
| --- | --- | --- |
| PID_Basic | `PID_Basic/tests/PID_Decimal_Performance_test.asm` | Q16.16 |
| PID_Basic_SAR | `PID_Basic_SAR/tests/PID_Decimal_Performance_test.asm` | Q8.8 after `SAR #8` |

Both programs use the same Q8.8 input values and gains:

| Value | Decimal | Stored Q8.8 value |
| --- | ---: | ---: |
| Target | 20.00 | 5120 |
| Measured | 21.50 | 5504 |
| Initial integral | 10.25 | 2624 |
| Previous error | 1.00 | 256 |
| Kp | 1.50 | 384 |
| Ki | 0.50 | 128 |
| Kd | 0.25 | 64 |

The baseline leaves multiplication results in Q16.16. The SAR CPU executes
three `SAR #8` instructions per update so its P, I, D, and output values return
to Q8.8. Although the raw register encodings differ, both represent the same
final decimal result of `-747.125`.

## Measured results

| Metric | PID_Basic | PID_Basic_SAR | SAR difference |
| --- | ---: | ---: | ---: |
| Correctness | PASS (7/7) | PASS (7/7) | None |
| PID updates | 1000 | 1000 | 0 |
| Instructions / update | 19 | 22 | +3 |
| Total measured cycles | 19,000 | 22,000 | +3,000 |
| Cycles / update | 19 | 22 | +15.79% |
| Time / update at 50 MHz | 0.380 us | 0.440 us | +15.79% |
| Loop rate at 50 MHz | 2,631,579/s | 2,272,727/s | -13.64% |
| Yosys generic cells | 155 | 158 | +3 (+1.94%) |
| Inferred memory bits | 525,312 | 525,312 | 0 |
| Cycles x generic cells | 2,945 | 3,476 | +531 (+18.03%) |

## Result

For this decimal PID workload, `PID_Basic` has the better raw CPU performance:
it completes an update in 19 cycles instead of 22 and has three fewer generic
Yosys cells. `PID_Basic_SAR` spends one extra instruction on each of the three
PID products to normalize them from Q16.16 to Q8.8.

The performance result is therefore:

```text
PID_Basic:      19 cycles/update, 155 cells, score 2945
PID_Basic_SAR:  22 cycles/update, 158 cells, score 3476
```

The 50 MHz clock is the common simulation clock, not a measured FPGA Fmax.
Yosys generic cells are used only for relative comparison; they are not
physical Cyclone V LUT or ALM counts.

## Reproduce

Run from the repository root:

```bash
# Baseline CPU decimal workload
python3 resources/software/scripts/simulate.py \
  PID_Basic/PID_Decimal.simulate.yml

# SAR CPU decimal workload
python3 resources/software/scripts/simulate.py \
  PID_Basic_SAR/PID_Decimal.simulate.yml
```

Measured simulation summaries:

```text
PID_Basic
PID iterations: 1000
Total PID cycles: 19000
Cycles per PID update: 19
Result: ALL 7 checks PASSED

PID_Basic_SAR
PID iterations: 1000
Total PID cycles: 22000
Cycles per PID update: 22
Result: ALL 7 checks PASSED
```
