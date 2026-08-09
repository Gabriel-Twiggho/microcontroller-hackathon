# PID_Tiny reworked minimum

This directory contains the deliberately reworked minimum configuration used
by the nine-build FPGA experiment. It is not binary-compatible with the
32-bit CPUs.

- 16-bit data and instructions
- eight registers (`r0` is hard-wired to zero)
- 64 instruction words
- 512 bytes of synchronous data RAM
- signed Q4.4 bounded PID workload
- two-cycle loads so Quartus can infer FPGA block RAM
- compact compare flags in the CMP variant rather than a reserved register

The 16-bit multiplier returns the low 16 bits. The supplied Q4.4 workload is
range-analysed so every raw multiplication fits. A general-purpose Q8.8 PID
would instead require a widening 16x16-to-32 multiply and 32-bit product state.
