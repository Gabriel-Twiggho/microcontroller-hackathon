# PID_Basic ISA, revision 2

This initial instruction set is designed for a PID-control loop: arithmetic
creates the proportional, integral, and derivative terms; memory holds input,
state, gains, and output; `JMP` repeats the loop. All arithmetic is 32-bit
two's-complement modular arithmetic. Fixed-point scaling is software-defined.

## Registers and addresses

- 32 general-purpose, 32-bit registers: `r0`–`r31`.
- `r0` always reads as zero and ignores writes.
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
PC-relative `JMP`; it is an unsigned 16-bit absolute address for `LOAD`,
and `STORE`; it is an instruction address for absolute `JMP`.

## Instructions

| Instruction | Opcode | Syntax | Meaning |
| --- | ---: | --- | --- |
| `ADD` | Type 1 `0x0000` | `ADD rd, a, b` | `rd = a + b`; combines PID terms. |
| `SUB` | Type 1 `0x0001` | `SUB rd, a, b` | `rd = a - b`; computes error and derivative. |
| `MUL` | Type 1 `0x000E` | `MUL rd, a, b` | `rd = a * b` (low 32 bits); applies PID gains. |
| `LI` | Type 2 `0x00D` | `LI rd, #imm16` | `rd = zero_extend(imm16)`; loads constants and gains. |
| `LOAD` | Type 2 `0x000` | `LOAD rd, [#address]` | Load the aligned 32-bit word at byte `address`. |
| `STORE` | Type 2 `0x001` | `STORE rs, [#address]` | Store `rs` as the aligned 32-bit word at byte `address`. |
| `JMP` | Type 2 `0x004` | `JMP label` / `JMP #address` | Relative target when `mode=0`; absolute target when `mode=1`. |
| `HALT` | Pseudo | `HALT` | Encodes a relative `JMP 0` (jump to self) for testing. |
| `SAR` | Type 1 `0x000C` | `SAR rd, value, shift` | Arithmetic right shift: `rd = signed(value) >>> shift | [4:0]`; preserves the sign of negative values. |

### Arithmetic shift right

`SAR` shifts a signed value to the right while preserving its sign bit.

```asm
SAR r3, r2, #8    ; r3 = signed(r2) >>> 8
SAR r3, r2, r4    ; shift amount comes from r4[4:0]
```

`NOP` is retained as an assembler pseudo-instruction for `ADD r0, r0, r0`.

## Example PID loop shape

```asm
loop:
    LOAD r1, [#0x0000]     ; setpoint
    LOAD r2, [#0x0004]     ; measured input
    SUB  r3, r1, r2        ; error
    LOAD r4, [#0x0010]     ; Kp
    MUL  r5, r3, r4        ; proportional term
    STORE r5, [#0x0020]    ; output
    JMP loop
```

This is the ISA contract for the upcoming decoder, ALU, data-memory, and
next-PC implementation.
