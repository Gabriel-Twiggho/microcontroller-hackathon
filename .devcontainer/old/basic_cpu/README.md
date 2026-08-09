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
step. The Stage 1 portions define the 32 registers, ADD/SUB/MOV/LI/RET,
argument registers r8-r15, return register r8, and the 16-bit pointer data
layout. A minimal leaf CALL/RET path lets the generated startup stub invoke
`tests/test_add.c`; nested calls and stack frames remain Stage 3 work.

## Complete Stage 1 compiler path

Run these inside the dev container, from `basic_cpu/`, one at a time:

```bash
# 1. Check the Stage 1 leaf CALL/RET path before building LLVM.
python3 tools/asm.py tests/test_leaf_call.asm \
  -o build/test_leaf_call.hex
python3 ../resources/software/scripts/simulate.py my_cpu.call-simulate.yml -v

# 2. Register/build the MYISA backend and install the rebuilt LLVM tools.
python3 ../resources/software/scripts/build_compiler.py my_cpu.build-compiler.yml

# 3. Confirm LLVM lists the custom target.
/opt/llvm/bin/llc --version

# 4. Compile test_add.c -> LLVM IR -> MYISA assembly -> program.hex.
python3 ../resources/software/scripts/compile.py my_cpu.compile.yml -v

# 5. Inspect the generated assembly before executing it.
sed -n '1,160p' build/compile/program.asm

# 6. Execute the compiled C program and check that r8 contains 42.
python3 ../resources/software/scripts/simulate.py my_cpu.c-simulate.yml -v
```

At Stage 1, programs must remain small leaf functions: no locals requiring
spills, memory access, branches, loops, or nested calls yet.
