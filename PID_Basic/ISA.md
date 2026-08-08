# PID_Basic ISA, revision 1

This initial instruction set is designed for a PID-control loop: arithmetic
creates the proportional, integral, and derivative terms; memory holds input,
state, gains, and output; `JMP` repeats the loop. All arithmetic is 32-bit
two's-complement modular arithmetic. Fixed-point scaling is software-defined.

## Registers and addresses

- 32 general-purpose, 32-bit registers: `r0`–`r31`.
- `r0` always reads as zero and ignores writes.
- Instruction and data addresses are 16 bits. Instruction memory is
  word-addressed; the initial `LOAD`/`STORE` use absolute word addresses.

## Encoding formats

### Type 1 — arithmetic

`[31]=1 | [30:17] opcode | [16] a-is-immediate | [15:11] a | [10] b-is-immediate | [9:5] b | [4:0] rd`

`a` and `b` name source registers when their immediate flag is clear. When a
flag is set, the corresponding five-bit field is an unsigned immediate
(`0`–`31`). The result is written to `rd`.

### Type 2 — immediate, memory, and control

`[31]=0 | [30:22] opcode | [21] mode | [20:16] reg | [15:0] payload`

`mode` is operation-specific. `payload` is a signed 16-bit value for `LI` and
PC-relative `JMP`; it is an unsigned 16-bit absolute address for `LOAD`,
`STORE`, and absolute `JMP`.

## Instructions

| Instruction | Opcode | Syntax | Meaning |
| --- | ---: | --- | --- |
| `ADD` | Type 1 `0x0000` | `ADD rd, a, b` | `rd = a + b`; combines PID terms. |
| `SUB` | Type 1 `0x0001` | `SUB rd, a, b` | `rd = a - b`; computes error and derivative. |
| `MUL` | Type 1 `0x0002` | `MUL rd, a, b` | `rd = a * b` (low 32 bits); applies PID gains. |
| `LI` | Type 2 `0x003` | `LI rd, #imm16` | `rd = sign_extend(imm16)`; loads constants and gains. |
| `LOAD` | Type 2 `0x000` | `LOAD rd, [#address]` | `rd = data_mem[address]`. |
| `STORE` | Type 2 `0x001` | `STORE rs, [#address]` | `data_mem[address] = rs`. |
| `JMP` | Type 2 `0x002` | `JMP label` / `JMP #address` | Relative target when `mode=0`; absolute target when `mode=1`. |
| `HALT` | Type 2 `0x004` | `HALT` | Stops the CPU for simulation/testing. |

`NOP` is retained as an assembler pseudo-instruction for `ADD r0, r0, r0`.

## Example PID loop shape

```asm
loop:
    LOAD r1, [#0x0000]     ; setpoint
    LOAD r2, [#0x0001]     ; measured input
    SUB  r3, r1, r2        ; error
    LOAD r4, [#0x0010]     ; Kp
    MUL  r5, r3, r4        ; proportional term
    STORE r5, [#0x0020]    ; output
    JMP loop
```

This is the ISA contract for the upcoming decoder, ALU, data-memory, and
next-PC implementation.
