; Compact Q4.4 PID with an actuator-safe 0..255 raw PWM clamp. CMP updates
; three one-bit flags; conditional jumps consume the flags without reserving
; one of the eight architectural registers.
LI    r1, #320
STORE r1, [0x100]
LI    r1, #321
STORE r1, [0x102]
LI    r1, #16
STORE r1, [0x104]
LI    r1, #1
SUB   r1, r0, r1
STORE r1, [0x106]
LI    r1, #24
STORE r1, [0x108]
LI    r1, #8
STORE r1, [0x10A]
LI    r1, #4
STORE r1, [0x10C]

pid_loop:
LOAD  r1, [0x100]
LOAD  r2, [0x102]
SUB   r3, r1, r2
LOAD  r4, [0x104]
ADD   r4, r4, r3
LOAD  r5, [0x106]
SUB   r5, r3, r5
LOAD  r2, [0x108]
MUL   r6, r2, r3
SAR   r6, r6, #4
LOAD  r2, [0x10A]
MUL   r7, r2, r4
SAR   r7, r7, #4
ADD   r6, r6, r7
LOAD  r2, [0x10C]
MUL   r7, r2, r5
SAR   r7, r7, #4
ADD   r7, r6, r7
STORE r4, [0x104]
STORE r3, [0x106]

CMP   r7, r0
JLT   clamp_low
LI    r2, #255
CMP   r7, r2
JGT   clamp_high
ADD   r6, r7, r0
STORE r6, [0x10E]
JMP   pid_loop

clamp_low:
ADD   r6, r0, r0
STORE r6, [0x10E]
JMP   pid_loop

clamp_high:
ADD   r6, r2, r0
STORE r6, [0x10E]
JMP   pid_loop
