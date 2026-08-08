# PID_Basic — Stage 0 CPU Scaffold

This directory began as the Stage 0 project scaffold from the Tutorial
Workbook. It now has an agreed initial PID instruction-set contract; the RTL
datapath implementation remains the next stage.

## Chosen starting architecture

| Parameter | Value |
| --- | --- |
| Data and instruction width | 32 bits |
| Address width | 16 bits |
| Registers | 32 (`r0` is reserved as zero) |
| Instruction-memory depth | 8192 words |
| Data-memory depth | 32768 bytes (planned for Stage 3) |
| Reset vector | `0x0000` |

The full instruction encoding, semantics, and PID-loop example are in
[ISA.md](ISA.md). The machine-readable opcode definitions are kept in sync in
`rtl/include/opcodes.vh` and `tools/isa_config.py`.

## Stage 0 naming contract

The supplied simulation tooling expects these names:

- `u_imem` / `mem` for instruction memory
- `u_regfile` / `regs` for the register file
- `dbg_halt` on the CPU top level

They are present in the scaffold. `dbg_halt` remains low until the CPU decoder
and control path are implemented, so a current simulation will time out by
design.

## Next step

Proceed with the datapath: implement the decoder, ADD/SUB/MUL ALU operations,
register write-back, data memory, `JMP`, and `HALT` from [ISA.md](ISA.md).
