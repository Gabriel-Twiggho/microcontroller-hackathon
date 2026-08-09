# PID_Basic_SAR CPU

This directory began as the Stage 0 project scaffold from the Tutorial
Workbook. It now has an agreed initial PID instruction-set contract and a
single-cycle RTL implementation of that contract.

## Chosen starting architecture

| Parameter | Value |
| --- | --- |
| Data and instruction width | 32 bits |
| Address width | 16 bits |
| Registers | 32 (`r0` is reserved as zero) |
| Instruction-memory depth | 8192 words |
| Data-memory depth | 32768 bytes |
| Reset vector | `0x0000` |

The full instruction encoding, semantics, and PID-loop example are in
[ISA.md](ISA.md). The machine-readable opcode definitions are kept in sync in
`rtl/include/opcodes.vh` and `tools/isa_config.py`.

## Simulation naming contract

The supplied simulation tooling expects these names:

- `u_imem` / `mem` for instruction memory
- `u_regfile` / `regs` for the register file
- `dbg_halt` on the CPU top level

They are present in the CPU and are used by the supplied simulation tooling.

## Run the comparison workload

Run the PID instruction test from the repository root:

```bash
python3 resources/software/scripts/simulate.py PID_Basic_SAR/PID_Basic.simulate.yml
```

The simulation comparison against the baseline is recorded in
[COMPARISON_REPORT.md](COMPARISON_REPORT.md).
