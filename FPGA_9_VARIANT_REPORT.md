# Nine-Variant PID CPU FPGA Analysis

Date: 9 August 2026  
FPGA: Cyclone V `5CSEMA5F31C6`  
Tool: Quartus Prime Lite 25.1std.0 Build 1129  
Timing constraint: 50 MHz (`20 ns`)

## Executive conclusion

Nine CPUs were implemented and tested: three implementation profiles for each
of the Baseline, SAR, and SAR+CMP/branch ISA levels. Every build passed a
1,000-update functional simulation and every Quartus build fitted with positive
setup slack at 50 MHz.

The main conclusions are:

1. **Sixteen registers are the workload-compatible minimum for the current
   32-bit design.** The existing PID programs use registers through `r11` (and
   the actuator program uses `r12`), so eight registers cannot run them without
   rewriting the program and encoding.
2. **The current asynchronous data memory is the dominant FPGA cost.** Neither
   the Current nor Compatible Minimum profile inferred block RAM. Reducing the
   memory and register count helps greatly, but the memory remains implemented
   in logic and registers.
3. **The Reworked Minimum is the smallest credible FPGA architecture tested.**
   Its synchronous 512-byte data RAM inferred one M10K block. The cores occupy
   only 128, 158, and 200 ALMs for Baseline, SAR, and CMP respectively.
4. **The Reworked Minimum CMP CPU is the best small actuator-oriented result:**
   200 ALMs, 126 registers, one DSP, one M10K, 88.83 MHz Fmax, and a measured
   average of 32.036 cycles per safe PID update.
5. **Baseline remains a reference, not a complete software-controlled actuator
   CPU.** Its unnormalised product and negative actuator word were deliberately
   observed. SAR fixes the fixed-point scale. CMP/branches then clamp the
   negative command to zero.

The tiny result is not a universal 16-bit PID CPU: it uses a range-analysed
Q4.4 workload whose raw products fit 16 bits. A general-purpose 16-bit design
must add a standard widening `16 x 16 -> 32` multiply and 32-bit product state.

## The nine configurations

| Profile | Registers | Data width | Instruction width | IMEM | DMEM | Program compatibility |
|---|---:|---:|---:|---:|---:|---|
| Current | 32 | 32 | 32 | 256 words | 1,024 B | Existing FPGA analysis reference |
| Compatible Minimum | 16 | 32 | 32 | 64 words | 512 B | Runs the existing workload unchanged |
| Reworked Minimum | 8 | 16 | 16 | 64 words | 512 B | New encoding and rewritten PID |

The Compatible Minimum retains the five-bit register fields in the current
binary encoding. Addresses `r16-r31` read as zero and ignore writes. It is
therefore compatible with the tested PID program, not with arbitrary programs
that use all 32 registers.

The Reworked Minimum is a separate compact architecture:

- three-bit register addresses for `r0-r7`;
- nine-bit byte addresses;
- compact 16-bit arithmetic, memory, immediate, and branch formats;
- synchronous data memory and a two-cycle `LOAD`;
- Q4.4 arithmetic for the bounded test workload;
- compare flags in the CMP build, avoiding a reserved condition register when
  only eight registers exist.

## ISA capability levels

### Baseline

Baseline implements `ADD`, `SUB`, `MUL`, `LOAD`, `STORE`, `LI`, and `JMP`.
Multiplication returns the low architectural-width result without fixed-point
normalisation.

In the 32-bit test, Q8.8 inputs multiply into Q16.16 outputs. In the tiny test,
Q4.4 inputs produce Q8.8 products. The numeric result is meaningful, but its
scale differs from the PID state and from a direct PWM command. A hardware
peripheral could perform the missing conversion, but the CPU cannot do it by
itself.

### SAR

SAR adds signed arithmetic right shift. Three `SAR` instructions follow the P,
I, and D multiplications, returning every term to the controller's fixed-point
scale. This costs three instructions per update but gives consistent values
for continued controller arithmetic.

### SAR + CMP and conditional branches

CMP adds signed comparison and `JZ`, `JNZ`, `JLT`, and `JGT`. The measured PID
program uses these instructions to clamp its output to a unipolar actuator
range. The calculated negative controller output remains visible internally,
while the memory-mapped actuator word is zero.

The current CMP core writes `-1`, `0`, or `+1` to reserved register `r5`. The
tiny core instead uses three one-bit flags. This is an intentional architectural
rework: reserving one of only eight registers would cause unnecessary spills.

## Functional methodology and results

The Current and Compatible Minimum profiles run the same Q8.8 program. The
Baseline retains Q16.16 products; SAR returns products to Q8.8; CMP additionally
executes the actuator clamp.

The Reworked Minimum profiles run the same bounded Q4.4 controller state and
gains. The input error is `-0.0625`, small enough that all 1,000 updates and all
raw multiplications remain valid in 16 bits. Loads take two clocks because the
RAM read is synchronous.

| ISA level | Current cycles/update | Compatible cycles/update | Reworked cycles/update | Result |
|---|---:|---:|---:|---|
| Baseline | 19.000 | 19.000 | 26.000 | Passed |
| SAR | 22.000 | 22.000 | 29.000 | Passed |
| CMP/branch | 24.009 average | 24.009 average | 32.036 average | Passed, clamped |

The fractional CMP averages occur because the taken clamp path changes as the
integral evolves. The simulator's integer display rounds these to 24 and 32,
but the totals were 24,009 and 32,036 clocks for 1,000 updates.

Direct actuator observations after the run were:

| Build | Calculated output | Actuator memory word | Meaning |
|---|---:|---:|---|
| Tiny Baseline | `0xE128` | `0xE128` | Negative, unnormalised command reaches output |
| Tiny SAR | `0xFE12` | `0xFE12` | Scale corrected, but still negative |
| Tiny CMP | `0xFE12` | `0x0000` | Negative command safely clamped to zero |
| 32-bit CMP | `0xFFFD14E0` | `0x00000000` | Q8.8 command safely clamped to zero |

This is why CMP and branches are not arithmetic accelerators. Their value is
that the controller can enforce a physical output range in software.

## Quartus post-fit results

The following numbers come from the post-fit resource summaries and the slow
1100 mV, 85 C timing model. `Max updates/s` is `Fmax / measured cycles` and is a
theoretical core limit, not a sensor or actuator system rate.

| ISA | Profile | ALMs | ALUTs | Registers | RAM bits / blocks | DSP | Fmax | Setup slack | Max updates/s |
|---|---|---:|---:|---:|---:|---:|---:|---:|---:|
| Baseline | Current | 4,814 | 4,144 | 9,233 | 0 / 0 | 2 | 57.83 MHz | +2.708 ns | 3.044 M/s |
| Baseline | Compatible | 1,281 | 1,467 | 1,649 | 0 / 0 | 2 | 63.81 MHz | +4.329 ns | 3.358 M/s |
| Baseline | Reworked | 128 | 175 | 123 | 4,096 / 1 | 1 | 90.67 MHz | +8.971 ns | 3.487 M/s |
| SAR | Current | 4,890 | 4,285 | 9,233 | 0 / 0 | 2 | 56.82 MHz | +2.401 ns | 2.583 M/s |
| SAR | Compatible | 1,032 | 1,414 | 1,105 | 0 / 0 | 2 | 63.32 MHz | +4.208 ns | 2.878 M/s |
| SAR | Reworked | 158 | 199 | 122 | 4,096 / 1 | 1 | 89.97 MHz | +8.885 ns | 3.102 M/s |
| CMP | Current | 2,565 | 3,456 | 3,569 | 0 / 0 | 2 | 56.33 MHz | +2.249 ns | 2.346 M/s |
| CMP | Compatible | 1,493 | 1,935 | 1,777 | 0 / 0 | 2 | 61.61 MHz | +3.768 ns | 2.566 M/s |
| CMP | Reworked | 200 | 255 | 126 | 4,096 / 1 | 1 | 88.83 MHz | +8.742 ns | 2.773 M/s |

All designs meet the requested 50 MHz clock. At exactly 50 MHz, the update
rates are determined only by cycle count:

| ISA | Current/Compatible | Reworked Minimum |
|---|---:|---:|
| Baseline | 2.632 M updates/s | 1.923 M updates/s |
| SAR | 2.273 M updates/s | 1.724 M updates/s |
| CMP | approximately 2.083 M updates/s | approximately 1.561 M updates/s |

The tiny cores have more cycles because seven loads per PID update each require
an additional RAM clock. Their higher Fmax more than compensates when comparing
the theoretical maximum rate, but not when every CPU is fixed at 50 MHz.

## What caused the area reductions?

### Current to Compatible Minimum

The Compatible profile reduces the Baseline from 4,814 to 1,281 ALMs and the
SAR core from 4,890 to 1,032 ALMs. It halves the architectural register storage,
reduces instruction memory from 256 to 64 words, and halves data memory from
1,024 to 512 bytes.

The reduction is not simply the register file. The current data memory has an
asynchronous read, so Quartus implements it using logic and registers instead
of M10K memory. Program-ROM constant propagation also changes how much unused
storage remains after synthesis.

### Compatible to Reworked Minimum

The decisive change is not merely 32 bits to 16 bits or 16 registers to eight.
The data memory read becomes synchronous, allowing Quartus to infer a single
4,096-bit M10K. The compact instruction encoding also eliminates large unused
opcode and register fields. The 16-bit multiplier uses one DSP instead of two.

This is why the Baseline drops from 1,281 ALMs to 128 ALMs. Calling the tiny
result a parameter change alone would be misleading; it is an architectural
redesign.

### Cost of SAR and CMP in the tiny architecture

The Reworked Minimum provides the cleanest ISA-cost comparison because the
three designs share the same memory architecture and widths:

- adding SAR costs 30 ALMs over Baseline (`128 -> 158`);
- adding compare flags and conditional branching costs another 42 ALMs
  (`158 -> 200`);
- the full actuator-capable ISA is 72 ALMs larger than tiny Baseline;
- Fmax falls only from 90.67 to 88.83 MHz.

That 72-ALM cost buys consistent fixed-point arithmetic and software-enforced
actuator limits. It does not buy fewer instructions; the safe update performs
more required work.

## Why some raw cross-ISA area results look surprising

Quartus synthesises a CPU together with a fixed initialized program ROM. It can
propagate ROM constants, remove unreachable behaviour, and reduce storage that
the particular program cannot address. The current CMP build therefore reports
fewer ALMs and registers than the current SAR build even though CMP adds logic.

This must not be interpreted as “CMP hardware is free” or “CMP makes the CPU
smaller.” It is an application-specialised fitted result. The tiny series is a
better view of marginal ISA cost because all three share the same compact
architecture and their programs exercise the corresponding capability.

For a pure opcode-cost study, the next experiment should either expose the
instruction bus at the synthesis top level, apply carefully reviewed
preservation attributes, or use an all-opcode validation ROM. The present
numbers answer the more practical question: “How large is this CPU when built
for this PID application?”

## Fixed-point and range reasoning

The 32-bit SAR and CMP cores use Q8.8 values. A Q8.8 multiplication creates a
Q16.16 raw product, which fits the current 32-bit register for the tested range.
`SAR #8` returns it to Q8.8.

The tiny core cannot safely multiply every pair of signed 16-bit Q4.4 values,
because a general 16-by-16 product needs 32 bits. Its test deliberately bounds
the operands so every raw product fits the low 16-bit result. This proves that
an eight-register, 16-bit CPU can implement a useful constrained controller; it
does not prove unrestricted numeric range.

There are two honest ways to deploy it:

1. Perform system-level range analysis and guarantee that gains, error,
   integral state, and products cannot exceed the 16-bit bounds.
2. Add a conventional widening multiplier with 32-bit product state, then use
   arithmetic shifting before returning the result to a 16-bit register.

The second choice is safer for a reusable CPU and does not require a custom
`QMUL` instruction. It can use standard widening multiply, product access, and
shift operations.

## What is still required for real hardware

The CMP ISA supplies the minimum software control flow for clamping, faults,
and anti-windup decisions, but the synthesized CPU is not yet a complete motor
or actuator controller. A deployable system still needs:

- a timer or fixed-rate sample interrupt/event;
- ADC, encoder, or sensor input registers;
- a PWM or DAC output peripheral;
- a defined memory-mapped I/O bus;
- integral anti-windup and fault handling policy;
- reset/clock-domain design and a safe output during reset;
- board pin assignments and external I/O timing constraints;
- numeric range analysis for the selected gains, sample time, and actuator.

The tests model the actuator as a memory-mapped word. They prove CPU arithmetic
and clamp behaviour, not a physical PWM waveform.

## Recommendation

For continued work, keep two candidates:

- **Compatible Minimum CMP** when preserving the existing Q8.8 software and
  32-bit arithmetic matters. It uses 1,493 ALMs and reaches 61.61 MHz, but its
  asynchronous data memory should be redesigned before deployment.
- **Reworked Minimum CMP** when minimum FPGA area matters. It is the strongest
  experimental result at 200 ALMs, one DSP, and one M10K. Add widening multiply
  support if the final range analysis cannot guarantee 16-bit products.

Do not select Baseline merely because it has the fewest instructions or ALMs.
It omits work that a software-controlled physical actuator requires. SAR is a
valid middle step for fixed-point arithmetic, while CMP/branches form the
smallest tested ISA that can also enforce output limits.

## Reproduction files

The Current and Compatible configurations are under:

- `PID_Basic/`
- `PID_Basic_SAR/`
- `PID_Basic_CMP/`

The compact RTL, assembler, programs, simulation configurations, and Quartus
configurations are under `PID_Tiny/`.

Simulation uses `resources/software/scripts/simulate.py`; synthesis uses
`resources/software/scripts/synthesize.py`. Both scripts now accept an
`rtl.defines` mapping so every profile is built independently without copying
the existing RTL.
