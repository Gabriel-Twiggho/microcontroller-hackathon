# Decimal PID CPU performance comparison

Date: 2026-08-09

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

## Quartus FPGA implementation

Both CPUs were compiled with Quartus Prime Lite 25.1std.0 Build 1129 for the
DE1-SoC Cyclone V `5CSEMA5F31C6`, using the same 20 ns (50 MHz) clock
constraint and independent project directories. Both passed analysis and
synthesis, fitting, assembly, setup timing, and hold timing.

| Post-fit metric | PID_Basic | PID_Basic_SAR | SAR difference |
| --- | ---: | ---: | ---: |
| Logic utilization | 4,814 ALMs | 4,890 ALMs | +76 (+1.58%) |
| Device utilization | 15% | 15% | 0 percentage points |
| Combinational ALUTs | 4,144 | 4,285 | +141 (+3.40%) |
| Registers | 9,233 | 9,233 | 0 |
| DSP blocks | 2 | 2 | 0 |
| Block-memory bits | 0 | 0 | 0 |
| Worst-corner Fmax | 57.83 MHz | 56.82 MHz | -1.01 MHz (-1.75%) |
| Setup slack at 50 MHz | +2.708 ns | +2.401 ns | -0.307 ns |
| Hold slack at 50 MHz | +0.609 ns | +0.675 ns | +0.066 ns |
| PID time at post-fit Fmax | 0.329 us | 0.387 us | +17.85% |
| PID rate at post-fit Fmax | 3.044 M/s | 2.583 M/s | -15.15% |
| Cycles x ALMs | 91,466 | 107,580 | +16,114 (+17.62%) |

The SAR instruction adds physical decode and shift-selection logic. Quartus
reports 79 ALUTs in the baseline ALU versus 118 in the SAR-capable ALU, and
30 ALUTs in the baseline decoder versus 40 in the SAR decoder. It does not
add registers or DSP blocks. After placement, the complete SAR CPU needs 76
more ALMs and its worst-corner Fmax is 1.75% lower.

### FPGA analysis profile and limitation

The synthesis-only FPGA profile uses a 256-word instruction ROM initialized
with each CPU's decimal PID program and a 1 KiB data memory. Simulation and
the Yosys figures above retain the architectural 8,192-word instruction
memory and 32 KiB data memory.

This profile is required because the RTL uses combinational reads for the
instruction memory, data memory, and register file. In particular, the data
memory cannot map to synchronous Cyclone V block RAM. Quartus implements the
1 KiB data memory as 8,192 registers, which accounts for most of the 9,233
registers and much of the ALM usage. The original 32 KiB asynchronous data
memory exceeds the device's available registers and does not fit as written.

The FPGA builds have no board pin assignments or external I/O-delay
constraints, so the Fmax values are comparative post-fit estimates rather
than board sign-off results. The constrained internal clock paths pass both
setup and hold timing at 50 MHz.

## Result

For this decimal PID workload, `PID_Basic` has the better raw and FPGA
performance: it completes an update in 19 cycles instead of 22, uses 76 fewer
post-fit ALMs, and has a 1.01 MHz higher worst-corner Fmax. `PID_Basic_SAR`
spends one extra instruction on each of the three PID products to normalize
them from Q16.16 to Q8.8.

The performance result is therefore:

```text
PID_Basic:      19 cycles/update, 155 cells, score 2945
PID_Basic_SAR:  22 cycles/update, 158 cells, score 3476

PID_Basic FPGA:      4814 ALMs, 57.83 MHz, 3.044 M updates/s
PID_Basic_SAR FPGA:  4890 ALMs, 56.82 MHz, 2.583 M updates/s
```

Yosys generic cells are used only for relative comparison; they are not
physical Cyclone V LUT or ALM counts. The Quartus results provide the physical
implementation comparison for the stated FPGA analysis profile.

## Reproduce

Run from the repository root:

```bash
# Baseline CPU decimal workload
python3 resources/software/scripts/simulate.py \
  PID_Basic/PID_Decimal.simulate.yml

# SAR CPU decimal workload
python3 resources/software/scripts/simulate.py \
  PID_Basic_SAR/PID_Decimal.simulate.yml

# Baseline Quartus build
python3 resources/software/scripts/synthesize.py \
  PID_Basic/PID_Basic.synthesize.yml

# SAR Quartus build
python3 resources/software/scripts/synthesize.py \
  PID_Basic_SAR/PID_Basic_SAR.synthesize.yml
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
