# PID_Basic versus PID_Basic_SAR_GTH correctness report

Date: 9 August 2026

## Result

Both CPUs pass all four matched PID correctness cases. The whole-number cases
take exactly the same number of cycles. For fractional gains, the Basic CPU can
produce the expected answer only because each test contains a hardcoded number
of `SUB`/`ADD` pairs. Those tests take 21 and 11 more cycles than the equivalent
runtime `SAR` operation.

| Matched case | Expected output | PID_Basic | SAR_GTH | Extra Basic cycles |
|---|---:|---:|---:|---:|
| Whole-number, positive terms | 420 | 7/7 PASS, 33 cycles | 7/7 PASS, 33 cycles | 0 |
| Whole-number, negative derivative | 380 | 7/7 PASS, 33 cycles | 7/7 PASS, 33 cycles | 0 |
| Fractional gains, positive terms | 9 | 8/8 PASS, 56 cycles | 8/8 PASS, 35 cycles | **21** |
| Fractional gains, negative integral term | 4 | 8/8 PASS, 48 cycles | 8/8 PASS, 37 cycles | **11** |

The assembled word counts equal the measured cycles in these straight-line
tests: 33/33, 56/35, and 48/37 respectively. There are no taken branches or
loops in these four programs.

## What the tests do

Each program performs one PID update using the same sequence:

```text
error      = setpoint - measured
integral   = initial_integral + error
derivative = error - previous_error
P          = Kp * error
I          = Ki * integral
D          = Kd * derivative
output     = P + I + D
```

The programs load the controller inputs and gains into data memory, calculate
the values above, and store the updated integral, error, and output. The YAML
checks then inspect the error, integral, derivative, P, I, D, and output
registers. The fractional tests additionally check both the raw scale-256 sum
and its downscaled integer result.

### Test 1: positive whole-number PID

Files: `PID_WholeNumbers_test.asm` on both CPUs.

This is the simplest control case. Every input, gain, intermediate term, and
output is a positive whole number, so it checks the ordinary load, subtract,
add, multiply, store, and halt path without fixed-point scaling or negative
arithmetic.

| Quantity | Test value |
|---|---:|
| Setpoint / measured value | 30 / 10 |
| Initial integral / previous error | 100 / 15 |
| `Kp`, `Ki`, `Kd` | 2, 3, 4 |
| Error / updated integral / derivative | 20 / 120 / 5 |
| P / I / D | 40 / 360 / 20 |
| Final output | **420** |

Both CPUs execute identical assembly and pass all seven checked result
registers in 33 cycles.

### Test 2: whole-number PID with a negative derivative

Files: `PID_WholeNumbersMixed_test.asm` on both CPUs.

This test keeps Test 1's setpoint, measurement, integral, and gains, but changes
the previous error from 15 to 25. The current error is therefore smaller than
the previous error, producing a negative derivative. It isolates signed
subtraction, signed multiplication, and adding a negative D term.

| Quantity | Test value |
|---|---:|
| Setpoint / measured value | 30 / 10 |
| Initial integral / previous error | 100 / 25 |
| `Kp`, `Ki`, `Kd` | 2, 3, 4 |
| Error / updated integral / derivative | 20 / 120 / -5 |
| P / I / D | 40 / 360 / -20 |
| Final output | **380** |

Both CPUs again pass all seven checks in 33 cycles. This confirms that merely
adding SAR support does not change the common signed integer PID path.

### Test 3: positive fractional-gain PID

Files: `PID_Fraction_test.asm` on Basic and
`tests/PID_Fraction_SAR_test.asm` on SAR_GTH.

This test represents the binary-fraction gains with a scale of 256. The gains
0.5, 0.25, and 0.125 are stored as 128, 64, and 32. The state variables remain
whole numbers, so multiplying a scaled gain by a state value produces a result
that is still scaled by 256.

| Quantity | Real value | Stored/calculated value |
|---|---:|---:|
| Setpoint / measured | 18 / 10 | 18 / 10 |
| Initial integral / previous error | 8 / 0 | 8 / 0 |
| `Kp`, `Ki`, `Kd` | 0.5 / 0.25 / 0.125 | 128 / 64 / 32 |
| Error / integral / derivative | 8 / 16 / 8 | 8 / 16 / 8 |
| P / I / D | 4 / 4 / 1 | 1024 / 1024 / 256 |
| Output | **9** | **2304 before downscaling** |

The test checks eight registers, including raw output `r11 = 2304` and final
output `r12 = 9`. Basic reaches 9 using nine hardcoded subtraction/count pairs;
SAR_GTH obtains 9 from the calculated `r11` with one `SAR #8`.

### Test 4: fractional PID with a negative integral gain

Files: `PID_FractionMixed_test.asm` on Basic and
`tests/PID_FractionMixed_SAR_test.asm` on SAR_GTH.

This case adds signed fixed-point arithmetic. `Ki` is negative while P and D
remain positive. The combined output is deliberately kept positive so the
Basic program's unsigned, hardcoded repeated-subtraction demonstration can
still be used.

| Quantity | Real value | Stored/calculated value |
|---|---:|---:|
| Setpoint / measured | 20 / 4 | 20 / 4 |
| Initial integral / previous error | 4 / 8 | 4 / 8 |
| `Kp`, `Ki`, `Kd` | 0.5 / -0.25 / 0.125 | 128 / -64 / 32 |
| Error / integral / derivative | 16 / 20 / 8 | 16 / 20 / 8 |
| P / I / D | 8 / -5 / 1 | 2048 / -1280 / 256 |
| Output | **4** | **1024 before downscaling** |

The test checks eight registers, including the negative raw I term, raw output
`r11 = 1024`, and final output `r12 = 4`. Basic contains four hardcoded
subtraction/count pairs; SAR_GTH uses one runtime `SAR #8`.

## How the Basic test obtains the answer

The fractional Basic programs first calculate a scale-256 result. For example,
the positive test leaves `2304` in `r11`, representing the real result `9`.
Because Basic has no shift, divide, comparison, or conditional branch, the test
contains this setup:

```asm
ADD r15, r11, r0    ; copy the scaled result
LI  r13, #256       ; fixed-point scale
LI  r14, #1
LI  r12, #0         ; quotient counter
```

It then physically repeats these two instructions exactly as many times as the
answer was already known to require:

```asm
SUB r15, r15, r13
ADD r12, r12, r14
```

- For `2304 / 256 = 9`, the assembly file contains nine copies of the pair.
- For `1024 / 256 = 4`, it contains four copies of the pair.

This is real on-chip arithmetic and is a valid correctness demonstration for
those exact inputs. It is not a general downscaling algorithm: there is no
runtime decision to stop when the value reaches zero, and no instruction checks
whether another subtraction is valid. If the PID input or gain changes, `r12`
still becomes the hardcoded `9` or `4`.

The technique also does not handle a remainder, rounding, saturation, or a
negative final output. A negative output would need a different sign-specific
sequence. A usable repeated-subtraction implementation would at least require
comparison and conditional branching, and its execution time would still grow
with the quotient.

## How SAR_GTH obtains the answer

SAR_GTH executes the same PID arithmetic and applies the scale conversion to
the value actually calculated at runtime:

```asm
SAR r12, r11, #8    ; signed division by 256 for this fixed-point scale
```

This is one instruction regardless of whether the current result is `2304`,
`1024`, or a different signed value. Arithmetic shifting also preserves the
sign of negative two's-complement results. For values not exactly divisible by
256, its defined behavior is a signed floor-style power-of-two scaling; a
specific round-to-nearest or saturation policy would require extra logic.

## Exact cycle accounting

### Positive fractional case

The common PID calculation and state stores use 32 instructions.

| Tail | Instructions |
|---|---:|
| Basic copy and constants | 4 |
| Basic nine `SUB`/`ADD` pairs | 18 |
| Basic result store | 1 |
| Basic halt | 1 |
| **Basic total** | **32 + 24 = 56** |
| SAR_GTH `SAR`, store, and halt | 3 |
| **SAR_GTH total** | **32 + 3 = 35** |

The difference is `18 + 4 + 1 - 2 = 21` cycles: Basic spends 23 instructions
on conversion and its store, whereas SAR_GTH spends two.

### Mixed-sign fractional case

Constructing the negative gain adds two instructions, so the common PID path is
34 instructions.

| Tail | Instructions |
|---|---:|
| Basic copy and constants | 4 |
| Basic four `SUB`/`ADD` pairs | 8 |
| Basic result store | 1 |
| Basic halt | 1 |
| **Basic total** | **34 + 14 = 48** |
| SAR_GTH `SAR`, store, and halt | 3 |
| **SAR_GTH total** | **34 + 3 = 37** |

The difference is 11 cycles. In general, for a hardcoded positive quotient
`N`, this exact Basic pattern costs `2N + 3` more instructions than the SAR
tail. The program also grows by the same amount.

## Why the whole-number controls matter

Both CPUs take 33 cycles in both whole-number tests because no scale conversion
is needed and both run the identical assembly. This establishes that SAR_GTH is
not inherently faster in the simulator. Its advantage appears specifically
when scale-256 fixed-point results must be converted for subsequent controller
or actuator arithmetic.

## Scope of the conclusion

This report tests correctness and records instruction/cycle cost. It does not
replace the full CPU performance and FPGA comparison. The final performance
report for three CPU configurations across the three ISA levels is
[`FPGA_9_VARIANT_REPORT.md`](../FPGA_9_VARIANT_REPORT.md).

Additional arithmetic checks are retained as appendices:

- [C_EQUIVALENT_REPORT.md](C_EQUIVALENT_REPORT.md) checks the original C-style
  weighted calculation.
- [FIXED_POINT_REPORT.md](FIXED_POINT_REPORT.md) checks signed multiplication,
  four SAR normalization cases, memory, jump, and halt behavior.

## Reproduce

From the repository root:

```bash
# PID_Basic
python3 resources/software/scripts/simulate.py PID_Basic/PID_Basic.simulate.wholenumbers.yml
python3 resources/software/scripts/simulate.py PID_Basic/PID_Basic.simulate.wholenumbersmixed.yml
python3 resources/software/scripts/simulate.py PID_Basic/PID_Basic.simulate.fraction.yml
python3 resources/software/scripts/simulate.py PID_Basic/PID_Basic.simulate.fractionmixed.yml

# PID_Basic_SAR_GTH
python3 resources/software/scripts/simulate.py PID_Basic_SAR_GTH/Whole_Numbers.simulate.yml
python3 resources/software/scripts/simulate.py PID_Basic_SAR_GTH/Whole_Numbers_Mixed.simulate.yml
python3 resources/software/scripts/simulate.py PID_Basic_SAR_GTH/Fraction_SAR.simulate.yml
python3 resources/software/scripts/simulate.py PID_Basic_SAR_GTH/Fraction_Mixed_SAR.simulate.yml
```
