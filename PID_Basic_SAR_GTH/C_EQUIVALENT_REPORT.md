# PID_Basic_SAR_GTH C-equivalent test report

Date: 9 August 2026  
Simulation: Icarus Verilog  
FPGA: Cyclone V `5CSEMA5F31C6`  
Quartus: Prime Lite 25.1std.0 Build 1129

## Result

The C-style PID calculation test passes all four register checks and completes
1,000 measured loop iterations in 15,000 clocks: **15 cycles per update**.

The program-specific Quartus build fits successfully and meets the 50 MHz
constraint with `+2.261 ns` worst-case setup slack. Post-fit Fmax is
`56.37 MHz` in the slow 1100 mV, 85 C timing model.

This report's purpose is functional correctness. The cycle count describes the
instruction cost of the checked calculation; it is not a replacement for the
existing full PID performance benchmark. FPGA figures are included only as a
build/timing sanity check.

## Comparison with PID_Basic

A matching Basic program was run without `SAR`:

| Check | PID_Basic | PID_Basic_SAR_GTH |
|---|---:|---:|
| Error | -20 | -20 |
| Raw weighted result | -12960 | -12960 |
| Final stored value | -12960 raw Q8.8 | -51 integer |
| Loop cycles | 14 | 15 |
| Verification | 3/3 PASS | 4/4 PASS |

The one-cycle difference is exactly the single `SAR #8`. Basic is not producing
the wrong multiplication result; it stops one operation earlier and leaves the
value in its raw fixed-point scale.

## What the program calculates

The program initializes:

| Quantity | Raw value | Interpreted value |
|---|---:|---:|
| target | 100 | integer 100 |
| measured | 120 | integer 120 |
| `kp` | 384 | 1.5 in Q8.8 |
| `ki` | 64 | 0.25 in Q8.8 |
| `kd` | 200 | 0.78125 in Q8.8 |

The loop then evaluates:

```text
error = 100 - 120 = -20
gain sum = 384 + 64 + 200 = 648
raw output = 648 * -20 = -12960
scaled output = -12960 >>> 8 = -51
```

This is a mixed-format calculation: the error is an integer and each gain is
Q8.8. Therefore the multiplication result is Q8.8, not Q16.16. Shifting by
eight converts the result back to an integer output.

Because arithmetic right shift rounds a negative fractional result downward,
`-50.625` becomes `-51`. A C expression using signed integer division by 256
would truncate toward zero and produce `-50`. The test is exactly equivalent
to C only when the C implementation uses arithmetic signed `>> 8` with the
same two's-complement behavior.

## Simulation evidence

Configuration: `PID_C_Equivalent.simulate.yml`  
Program: `tests/PID_C_Equivalent_test.asm`

| Check | Expected | Actual | Result |
|---|---:|---:|---|
| `r3`, error | `0xFFFFFFEC` (-20) | `0xFFFFFFEC` | PASS |
| `r5`, accumulated raw output | `0xFFFFCD60` (-12960) | `0xFFFFCD60` | PASS |
| `r8`, shifted output | `0xFFFFFFCD` (-51) | `0xFFFFFFCD` | PASS |
| `r9`, memory read-back | `0xFFFFFFCD` (-51) | `0xFFFFFFCD` | PASS |

Measured output:

```text
PID iterations: 1000
Total PID cycles: 15000
Cycles per PID update: 15
Result: ALL 4 checks PASSED
```

The loop starts at instruction `0x000A`. The shared testbench observes PC
`0x000E`, which is inside the loop and is reached exactly once per update. It
therefore still measures the complete 15-instruction loop correctly.

At 50 MHz:

- time per update: `15 / 50 MHz = 300 ns`;
- loop rate: `3.333 million updates/s`.

At the post-fit Fmax of 56.37 MHz, the theoretical core-only rate is
approximately `3.758 million updates/s`.

## FPGA results

Configuration: `C_Equivalent.synthesize.yml`

| Metric | Post-fit result |
|---|---:|
| Logic utilization | 1,648 ALMs |
| Combinational ALUTs | 2,326 |
| Registers | 1,937 |
| DSP blocks | 2 |
| Block memory bits / RAM blocks | 0 / 0 |
| Fmax, slow 85 C | 56.37 MHz |
| Setup slack at 50 MHz | +2.261 ns |

The FPGA analysis uses a 256-word instruction ROM and 1,024-byte data memory.
The data memory has an asynchronous read port, so Quartus implements it in
logic/register resources instead of an M10K block.

## Interpretation

The test proves that the implemented `LI`, `LOAD`, `SUB`, `MUL`, `ADD`, `SAR`,
`STORE`, and `JMP` path can repeatedly execute the intended calculation. It
also proves that a negative stored result survives a memory write and read.

It validates the supplied expression `(kp + ki + kd) * error`; it is not a
complete stateful PID algorithm. `ki` does not multiply an accumulated error,
and `kd` does not multiply a current-minus-previous error derivative.

It does not prove equivalence to a compiled C binary or C ABI. The program is
handwritten assembly matching the intended algorithm, and no C source or
compiler-generated instruction stream is part of this test.

The output is not actuator-safe by itself: `-51` is written without clamping.
The SAR_GTH ISA has scaling but no compare/conditional-branch path for enforcing
a unipolar PWM range in software.

## Reproduce

From the repository root:

```bash
docker compose -f resources/docker/docker-compose.yml exec dev \
  python3 resources/software/scripts/simulate.py \
  PID_Basic/PID_C_Equivalent.simulate.yml

docker compose -f resources/docker/docker-compose.yml exec dev \
  python3 resources/software/scripts/simulate.py \
  PID_Basic_SAR_GTH/PID_C_Equivalent.simulate.yml

docker compose -f resources/docker/docker-compose.yml exec dev \
  python3 resources/software/scripts/synthesize.py \
  PID_Basic_SAR_GTH/C_Equivalent.synthesize.yml
```
