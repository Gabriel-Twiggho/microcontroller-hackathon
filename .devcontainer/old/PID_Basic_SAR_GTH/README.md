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

Quartus report builds use a workload-sized 256-word instruction memory and
1,024-byte data memory; the larger capacities above remain the simulation
profile.

The full instruction encoding, semantics, and PID-loop example are in
[ISA.md](ISA.md). The machine-readable opcode definitions are kept in sync in
`rtl/include/opcodes.vh` and `tools/isa_config.py`.

## Simulation naming contract

The supplied simulation tooling expects these names:

- `u_imem` / `mem` for instruction memory
- `u_regfile` / `regs` for the register file
- `dbg_halt` on the CPU top level

They are present in the CPU and are used by the supplied simulation tooling.

## Run the validation workloads

Run the core arithmetic tests from the repository root:

```bash
python3 resources/software/scripts/simulate.py \
  PID_Basic_SAR_GTH/PID_C_Equivalent.simulate.yml

python3 resources/software/scripts/simulate.py \
  PID_Basic_SAR_GTH/PID_Basic.simulate.yml
```

The matched whole-number and fractional PID commands are listed in
[COMPARISON_REPORT.md](COMPARISON_REPORT.md).

Results and FPGA analysis are recorded in:

- [COMPARISON_REPORT.md](COMPARISON_REPORT.md)
- [C_EQUIVALENT_REPORT.md](C_EQUIVALENT_REPORT.md)
- [FIXED_POINT_REPORT.md](FIXED_POINT_REPORT.md)
- [TEAM_TALKING_POINTS.md](TEAM_TALKING_POINTS.md)
- [MINI_AUDIT_REPORT.md](../MINI_AUDIT_REPORT.md)
