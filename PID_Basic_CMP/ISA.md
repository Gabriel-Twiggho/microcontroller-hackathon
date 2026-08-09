# PID_Basic_CMP ISA, revision 3

This initial instruction set is designed for a PID-control loop: arithmetic
creates the proportional, integral, and derivative terms; memory holds input,
state, gains, and output; `SAR` provides fixed-point scaling; signed `CMP` and
conditional jumps implement actuator limits, anti-windup, timer polling, and
fault decisions. All arithmetic is 32-bit two's-complement modular arithmetic.

## Registers and addresses

- 32 general-purpose, 32-bit registers: `r0`–`r31`.
- `r0` always reads as zero and ignores writes.
- `r5` is the condition register. `CMP` overwrites it with `-1`, `0`, or `+1`.
- Instruction and data addresses are 16 bits. Instruction memory is
  word-addressed. Data memory is byte-addressed and `LOAD`/`STORE` transfer
  aligned 32-bit words, so adjacent words are four addresses apart.

## Encoding formats

### Type 1 — arithmetic

`[31]=1 | [30:17] opcode | [16] a-is-immediate | [15:11] a | [10] b-is-immediate | [9:5] b | [4:0] rd`

`a` and `b` name source registers when their immediate flag is clear. When a
flag is set, the corresponding five-bit field is an unsigned immediate
(`0`–`31`). The result is written to `rd`.

### Type 2 — immediate, memory, and control

`[31]=0 | [30:22] opcode | [21] mode | [20:16] reg | [15:0] payload`

`mode` is operation-specific. `payload` is unsigned for `LI` and signed for
PC-relative jumps; it is an unsigned 16-bit absolute address for `LOAD` and
`STORE`; it is an instruction address for absolute jumps.

## Instructions

| Instruction | Opcode | Syntax | Meaning |
| --- | ---: | --- | --- |
| `ADD` | Type 1 `0x0000` | `ADD rd, a, b` | `rd = a + b`; combines PID terms. |
| `SUB` | Type 1 `0x0001` | `SUB rd, a, b` | `rd = a - b`; computes error and derivative. |
| `MUL` | Type 1 `0x000E` | `MUL rd, a, b` | `rd = a * b` (low 32 bits); applies PID gains. |
| `SAR` | Type 1 `0x000C` | `SAR rd, value, shift` | Arithmetic right shift; rescales signed fixed-point products. |
| `CMP` | Type 1 `0x000D` | `CMP a, b` | Signed comparison; writes `-1`, `0`, or `+1` to `r5`. |
| `LI` | Type 2 `0x00D` | `LI rd, #imm16` | `rd = zero_extend(imm16)`; loads constants and gains. |
| `LOAD` | Type 2 `0x000` | `LOAD rd, [#address]` | Load the aligned 32-bit word at byte `address`. |
| `STORE` | Type 2 `0x001` | `STORE rs, [#address]` | Store `rs` as the aligned 32-bit word at byte `address`. |
| `JMP` | Type 2 `0x004` | `JMP label` / `JMP #address` | Relative target when `mode=0`; absolute target when `mode=1`. |
| `JZ` | Type 2 `0x005` | `JZ label` | Jump when `r5 == 0`. |
| `JNZ` | Type 2 `0x006` | `JNZ label` | Jump when `r5 != 0`. |
| `JLT` | Type 2 `0x007` | `JLT label` | Jump when signed `r5 < 0`. |
| `JGT` | Type 2 `0x008` | `JGT label` | Jump when signed `r5 > 0`. |
| `HALT` | Pseudo | `HALT` | Encodes a relative `JMP 0` (jump to self) for testing. |

### Arithmetic shift right

`SAR` shifts a signed value to the right while preserving its sign bit.

```asm
SAR r3, r2, #8    ; r3 = signed(r2) >>> 8
SAR r3, r2, r4    ; shift amount comes from r4[4:0]
```

`NOP` is retained as an assembler pseudo-instruction for `ADD r0, r0, r0`.

### Signed comparison and branches

`CMP` accepts register or unsigned five-bit immediate operands. It has an
implicit destination so software must treat `r5` as clobbered.

```asm
CMP r8, r9       ; r5 = -1 when r8 < r9, 0 when equal, +1 when greater
JLT below_limit
CMP r8, #0
JZ  exactly_zero
```

All jumps use the same relative-label and absolute-address encoding rules as
`JMP`. A conditional jump that is not taken advances to the next instruction.

## Example PID loop shape

```asm
loop:
    LOAD r1, [#0x0000]     ; setpoint
    LOAD r2, [#0x0004]     ; measured input
    SUB  r3, r1, r2        ; error
    LOAD r4, [#0x0010]     ; Kp
    MUL  r8, r3, r4        ; proportional term, Q16.16
    SAR  r8, r8, #8        ; normalize to Q8.8
    CMP  r8, r0            ; actuator lower limit
    JLT  clamp_low
    STORE r8, [#0x0020]    ; memory-mapped actuator command
    JMP loop
clamp_low:
    STORE r0, [#0x0020]
    JMP loop
```

This ISA is implemented by the RTL decoder, datapath, assembler, and branch
tests in this directory.
