# Basic Arithmetic CPU

This is a Stage 1 implementation built around the supplied two-format ISA
template.  It is a single-cycle, 32-bit CPU with 32 registers. `r0` is hard
wired to zero; `r2` is reserved for the future stack pointer.

Implemented instructions are `LI`, `ADD`, `SUB`, and `MOV`. `HALT` is an
assembler pseudo-instruction, encoded as `JMP #0`; the CPU recognizes that
encoding and stops.

## Run the hardware test

From this directory, first assemble the program and then run the provided
simulation helper:

```bash
python3 tools/asm.py tests/test_add.asm -o build/test_add.hex
python3 ../resources/software/scripts/simulate.py my_cpu.simulate.yml
```

The test checks `r8 == 42`, `r10 == 40`, and `r11 == 40`.

The compiler-backend template is included in `llvm-backend/` for the next
step, but has intentionally not been completed: the hardware-first test above
is the Stage 1 starting point.  Once the backend TODOs are completed, the
provided `build_compiler.py` and `compile.py` helpers can compile C programs
through it.
