# PID CPU mini audit — performance and correctness evidence

Date: 9 August 2026  
FPGA: Cyclone V `5CSEMA5F31C6`  
Quartus: Prime Lite 25.1std.0 Build 1129

## Audit summary

- **Performance evidence:** six 32-bit CPU builds completed 1,000 PID updates and
  passed Quartus timing at 50 MHz.
- **Correctness evidence:** Basic and SAR passed four matched PID calculation
  tests.
- **Main result:** Basic executes fewer instructions because it omits general
  fixed-point scaling and actuator clamping.
- **Main result:** SAR performs runtime signed fixed-point scaling.
- **Main result:** CMP and conditional branches allow software to clamp an
  actuator command.
- These are CPU and memory-mapped-output tests, not a physical motor test.

# 1. Performance audit

## Major ISA configuration parameters

These are the main values from `config.vh` used in the six-build mini audit.

| `config.vh` setting | Current | Compatible Minimum |
|---|---:|---:|
| `DATA_WIDTH` | 32 | 32 |
| `ADDR_WIDTH` | 16 | 16 |
| `INSTR_WIDTH` | 32 | 32 |
| `REG_COUNT` | 32 | 16 |
| `REG_ADDR_W` | 5 | 5 |
| `IMEM_DEPTH` | 256 words | 64 words |
| `DMEM_DEPTH` | 1,024 bytes | 512 bytes |

### Why these values were chosen

- **Current:** the original 32-bit/32-register configuration is kept as the
  reference result.
- **Compatible Minimum:** keeps 32-bit data and instructions so the existing
  program does not need rewriting. The workload uses registers through `r12`,
  making 16 registers the tested compatible minimum.
- **64-word IMEM:** all tested PID programs fit within this size.
- **512-byte DMEM:** covers the tested PID state and memory-mapped actuator
  addresses without unused capacity.
- The Current test keeps 256 instruction words and 1,024 data bytes as the
  original FPGA analysis reference.

### FPGA confirmation

| Configuration | Basic FPGA build | SAR FPGA build | CMP/branch FPGA build | 50 MHz timing |
|---|---:|---:|---:|---:|
| Current | PASS | PASS | PASS | PASS |
| Compatible Minimum | PASS | PASS | PASS | PASS |

Both configurations therefore work on the Cyclone V FPGA with the memory sizes
shown in the configuration table.

## ISA capability levels

| ISA level | Major addition | Why it was chosen |
|---|---|---|
| Basic | Original PID arithmetic and memory operations | Reference for the smallest instruction set and raw speed |
| SAR | Arithmetic right shift | Returns signed fixed-point products to the controller scale |
| CMP/branch | Signed compare and conditional branches | Allows software to clamp actuator outputs and make runtime decisions |

- Basic does the least work, so it is expected to use fewer instructions.
- SAR performs three extra shifts per update: one each for P, I, and D.
- CMP/branch adds required actuator behavior rather than arithmetic speed.

## What the performance test does

- Initializes PID state and fixed-point gains.
- Runs **1,000 PID updates**.
- Calculates error, integral, derivative, P, I, D, and controller output.
- Basic retains the raw multiplication scale.
- SAR normalizes P, I, and D with three `SAR` instructions.
- CMP/branch also checks the signed output and clamps a negative actuator word
  to zero.
- Records pass/fail, executed cycles, FPGA resources, and post-fit Fmax.
- All six simulations passed and all six FPGA builds met the 50 MHz timing
  constraint.

## Major speed evidence table

How to read this table:

- A **cycle** is one CPU clock tick.
- Fewer cycles means a faster update when the clock frequency is the same.
- The time shown assumes every CPU runs at the same 50 MHz clock.
- Every entry represents a passing 1,000-update simulation.

| ISA workload | What the CPU does | Current | Compatible Minimum |
|---|---|---:|---:|
| Basic | PID calculation; no normalization or clamp | **19 cycles** / 0.380 us | **19 cycles** / 0.380 us |
| SAR | PID calculation plus three scale corrections | **22 cycles** / 0.440 us | **22 cycles** / 0.440 us |
| CMP/branch | Scale-corrected PID plus actuator clamp | **24.009 cycles average** / 0.480 us | **24.009 cycles average** / 0.480 us |

This layout contains all six results: three ISA workloads multiplied by two
FPGA-capable 32-bit configurations.

## FPGA implementation evidence

How to read this table:

- **ALMs** are the main physical logic blocks in this Cyclone V FPGA.
- **ALUTs** are the lookup-table logic used to implement CPU operations.
- Lower ALM/ALUT usage generally means a smaller implementation.
- **Fmax** is the highest post-fit clock reported by Quartus at the worst tested
  timing corner. It must be above the required 50 MHz.

| ISA | Configuration | FPGA logic blocks (ALMs) | Logic LUTs (ALUTs) | Fmax | 50 MHz result |
|---|---|---:|---:|---:|---:|
| Basic | Current | 4,814 | 4,144 | 57.83 MHz | PASS |
| Basic | Compatible Minimum | 1,281 | 1,467 | 63.81 MHz | PASS |
| SAR | Current | 4,890 | 4,285 | 56.82 MHz | PASS |
| SAR | Compatible Minimum | 1,032 | 1,414 | 63.32 MHz | PASS |
| CMP/branch | Current | 2,565 | 3,456 | 56.33 MHz | PASS |
| CMP/branch | Compatible Minimum | 1,493 | 1,935 | 61.61 MHz | PASS |

This table proves that Quartus synthesized, placed, and fitted all six CPU
builds for the target Cyclone V and that every build passed the 50 MHz timing
requirement. Registers, RAM blocks, and DSP details remain in the full FPGA
report so this audit table stays readable.

The PID programs themselves ran in RTL simulation. The Quartus results are
post-fit FPGA implementation and timing evidence; they are not a physical
board execution test.

## What this table proves

- At 50 MHz, Basic is fastest: 0.380 us versus 0.440 us for SAR and about 0.480
  us for CMP on the 32-bit versions.
- That does **not** make Basic the most complete controller. It is faster
  because it omits normalization and clamping.
- Compatible Minimum runs the same program at the same speed as Current while
  using fewer FPGA logic blocks.
- Compatible Minimum CMP is the smallest actuator-oriented build retained in
  this audit: 1,493 FPGA logic blocks (ALMs).
- Every design meets the common 50 MHz requirement.
- FPGA size comparisons across different ISA programs can be affected by
  Quartus removing unused fixed-program logic. Cycle counts are the clearer
  evidence for the amount of work each test performs.
- The 32-bit CMP test shows the actuator behavior directly: the calculated
  negative Q8.8 output is `0xFFFD14E0`, while the clamped actuator word is
  `0x00000000`.

# 2. Correctness and scaling audit

## CPUs compared

| CPU | Capability used by this test | Limitation shown by the test |
|---|---|---|
| PID_Basic | Signed two's-complement `ADD`, `SUB`, and low-word `MUL` | No general runtime fixed-point downscaling |
| PID_Basic_SAR_GTH | Same arithmetic plus `SAR` | Scales at runtime, but this test does not add actuator clamping |

- The folder is named `PID_Basic_SAR_GTH`, but these comparison programs
  exercise `SAR`; they do not exercise a GTH/CMP instruction.
- Neither CPU in this correctness table clamps the output to a motor/PWM range.

## What the comparison test does

- Runs one PID calculation for each of four selected input sets.
- Checks error, integral, derivative, P, I, D, and output registers.
- Two tests use whole numbers.
- Two tests use scale-256 fractional gains.
- One whole-number test produces a negative derivative.
- One fractional test produces a negative I term but keeps the final output
  positive.
- Basic scales the two known positive fractional answers using a hardcoded
  number of `SUB`/`ADD` pairs.
- SAR scales the value calculated at runtime using one `SAR #8`.
- The cycle values here show instruction cost for the correctness programs;
  the 1,000-update table above is the dedicated performance evidence.

## Major correctness comparison table

| Test | What it checks | Expected output | PID_Basic | PID_Basic_SAR_GTH | Basic extra cycles |
|---|---|---:|---:|---:|---:|
| Positive whole numbers | Normal positive PID arithmetic | 420 | 7/7 PASS, 33 cycles | 7/7 PASS, 33 cycles | 0 |
| Negative derivative | Signed subtraction, multiply, and addition | 380 | 7/7 PASS, 33 cycles | 7/7 PASS, 33 cycles | 0 |
| Positive fractional gains | Scale-256 P, I, D and output 9 | 9 | 8/8 PASS, 56 cycles | 8/8 PASS, 35 cycles | **21** |
| Negative fractional I term | Signed fixed-point intermediate and output 4 | 4 | 8/8 PASS, 48 cycles | 8/8 PASS, 37 cycles | **11** |

## What this table proves

- Both CPUs handle the tested positive and negative two's-complement arithmetic.
- Whole-number performance is identical because no scaling is needed.
- Basic passes the fractional cases only because the expected quotient is
  written into the program as four or nine subtraction/count pairs.
- If Basic receives a different runtime output, its hardcoded quotient does not
  change.
- In this table, SAR scales the two positive final results from the actual
  runtime values rather than from a hardcoded quotient.
- The separate signed fixed-point validation proves negative SAR behavior:
  `-819200 SAR #8 = -3200`, with all 18 checks passing.
- The Basic fractional cases therefore prove only those exact examples, while
  the combined SAR evidence proves signed runtime power-of-two conversion.
- The table does not prove Basic can scale a negative final output, handle a
  remainder, round, saturate, or clamp an actuator command.

# 3. Audit conclusion

- **Raw speed winner:** Basic, because it performs the fewest operations.
- **Runtime fixed-point winner:** SAR, because it normalizes the calculated
  signed value instead of using a hardcoded answer.
- **Smallest retained actuator-oriented CPU:** Compatible Minimum CMP/branch.
- **Safe motor-use limitation:** the CPU still needs real PWM/sensor hardware,
  timing, overflow bounds, and anti-windup; the tests model the actuator as a
  memory word.
- The evidence supports capability claims, but Basic, SAR, and CMP are not
  functionally identical workloads: each ISA level performs additional useful
  work.

## Source reports

- Full FPGA analysis source:
  [FPGA_9_VARIANT_REPORT.md](FPGA_9_VARIANT_REPORT.md)
- Full Basic-versus-SAR correctness evidence:
  [PID_Basic_SAR_GTH/COMPARISON_REPORT.md](PID_Basic_SAR_GTH/COMPARISON_REPORT.md)
- Signed SAR validation:
  [PID_Basic_SAR_GTH/FIXED_POINT_REPORT.md](PID_Basic_SAR_GTH/FIXED_POINT_REPORT.md)
- Two-CPU 1,000-update performance detail:
  [PID_Basic_SAR/COMPARISON_REPORT.md](PID_Basic_SAR/COMPARISON_REPORT.md)
- Presentation constraints:
  [PID_Basic_SAR_GTH/TEAM_TALKING_POINTS.md](PID_Basic_SAR_GTH/TEAM_TALKING_POINTS.md)
