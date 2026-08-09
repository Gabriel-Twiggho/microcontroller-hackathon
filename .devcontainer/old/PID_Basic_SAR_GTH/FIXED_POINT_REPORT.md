# PID_Basic_SAR_GTH fixed-point validation report

Date: 9 August 2026  
Simulation: Icarus Verilog  
FPGA: Cyclone V `5CSEMA5F31C6`  
Quartus: Prime Lite 25.1std.0 Build 1129

## Result

The expanded fixed-point test passes **18/18 checks**, assembles to 27 words,
and halts after 26 executed cycles. It validates positive and negative Q8.8
multiplication, signed normalization with `SAR #8`, data-memory read-back,
addition, jump, and halt.

The matching Quartus build fits successfully at 1,909 ALMs and reaches
58.12 MHz Fmax. It meets the 50 MHz constraint with `+2.795 ns` setup slack.
This is a build sanity check, not an FPGA performance comparison.

## Arithmetic cases

Q8.8 stores a real value as `value * 256`. Multiplying two Q8.8 operands
produces a Q16.16 raw product, and `SAR #8` returns it to Q8.8.

| Calculation | Raw product | After `SAR #8` | Decimal result |
|---|---:|---:|---:|
| `25 * -0.5` | -819,200 | -3,200 | -12.5 |
| `25 * 0.5` | 819,200 | 3,200 | 12.5 |
| `25 * 3` | 4,915,200 | 19,200 | 75.0 |
| `-25 * -0.5` | 819,200 | 3,200 | 12.5 |

The negative cases are important SAR checks: an arithmetic right shift
preserves the sign, while a logical right shift would not.

## Simulation evidence

Configuration: `PID_Basic.simulate.yml`  
Program: `tests/PID_Fixed_Point_test.asm`

| Group | Registers checked | Result |
|---|---|---:|
| `25 * -0.5` | `r2`, `r3`, `r4` | 3/3 PASS |
| `25 * 0.5` | `r5`, `r6`, `r7` | 3/3 PASS |
| `25 * 3` | `r8`, `r9`, `r10` | 3/3 PASS |
| STORE/LOAD read-back | `r13`, `r14`, `r15` | 3/3 PASS |
| JMP skips failure write | `r16` | PASS |
| `-12.5 + 12.5` | `r17` | PASS |
| `-25 * -0.5` | `r18`-`r21` | 4/4 PASS |

Measured output:

```text
Assembled 27 instructions
CPU halted after 26 cycles
Result: ALL 18 checks PASSED
```

One instruction is deliberately skipped by `JMP`, which explains why the
27-word program halts after 26 cycles.

## Relationship to PID_Basic

The original Basic three-case sequence verifies the same raw multiplication,
memory, addition, jump, and halt behavior but cannot perform the three
normalizing shifts. It assembles to 18 words, halts after 17 cycles, and passes
11/11 checks. A matched SAR version of those same three cases uses 21 words and
20 cycles; the three added words/cycles are exactly the three `SAR #8`
instructions.

The current SAR_GTH test is longer because it now includes the fourth
negative-by-negative case. Its 27-word/26-cycle total should therefore not be
presented as a direct cycle comparison against the older three-case Basic test.
The matched PID comparison is documented in [COMPARISON_REPORT.md](COMPARISON_REPORT.md).

## FPGA build sanity check

Configuration: `Fixed_Point.synthesize.yml`

| Metric | Post-fit result |
|---|---:|
| Logic utilization | 1,909 ALMs |
| Combinational ALUTs | 2,392 |
| Registers | 2,577 |
| DSP blocks | 2 |
| Block memory bits / RAM blocks | 0 / 0 |
| Fmax, slow 85 C | 58.12 MHz |
| Setup slack at 50 MHz | +2.795 ns |

The application ROM is synthesized into logic and its contents allow Quartus
constant propagation, so these values describe this test image rather than a
general architectural ranking.

## Limits

These bounded products fit in the signed 32-bit datapath. The test does not
prove that every possible Q8.8 PID product or integral accumulator fits.
Overflow remains modular because the ISA has no saturation instruction, and a
production controller still needs explicit bounds and an actuator output
policy.

## Reproduce

```bash
docker compose -f resources/docker/docker-compose.yml exec dev \
  python3 resources/software/scripts/simulate.py \
  PID_Basic_SAR_GTH/PID_Basic.simulate.yml

docker compose -f resources/docker/docker-compose.yml exec dev \
  python3 resources/software/scripts/synthesize.py \
  PID_Basic_SAR_GTH/Fixed_Point.synthesize.yml
```
