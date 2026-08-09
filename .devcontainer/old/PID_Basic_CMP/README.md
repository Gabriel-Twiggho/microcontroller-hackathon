# PID_Basic_CMP CPU

This directory began as the Stage 0 project scaffold from the Tutorial
Workbook. It now has an agreed initial PID instruction-set contract and a
single-cycle RTL implementation of that contract. It extends the SAR variant
with signed comparison and conditional control flow for actuator clamping,
anti-windup, timer polling, and safety checks.

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

## Added control instructions

`CMP lhs, rhs` writes `-1`, `0`, or `+1` to the dedicated condition register
`r5`. `JZ`, `JNZ`, `JLT`, and `JGT` branch from that signed result. Branch
targets can be PC-relative labels or absolute addresses, matching `JMP`.

## Run the tests

Run the PID instruction test from the repository root:

```bash
python3 resources/software/scripts/simulate.py \
  PID_Basic_CMP/CMP_Branch.simulate.yml

python3 resources/software/scripts/simulate.py \
  PID_Basic_CMP/PID_Decimal.simulate.yml
```

The first test covers taken and not-taken forms of all four conditional jumps.
The second confirms that the existing 22-cycle Q8.8 PID workload remains
unchanged.

## FPGA check

Quartus Prime Lite 25.1std.0 successfully fits the CMP/branch validation build
for the Cyclone V `5CSEMA5F31C6`. It meets the 50 MHz constraint with +2.164 ns
worst-corner setup slack and a 56.07 MHz post-fit Fmax estimate. This compact
validation build uses the branch test program in ROM, so its resource count is
not directly comparable with the decimal-PID FPGA figures.
