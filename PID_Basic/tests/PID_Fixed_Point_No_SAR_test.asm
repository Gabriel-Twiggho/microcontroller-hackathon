; PID_Basic counterpart of the SAR_GTH fixed-point test. It verifies the same
; three raw Q16.16 products, memory path, ADD, JMP and HALT. Without SAR it
; cannot normalize those products back to Q8.8.

LI    r1, #6400

LI    r11, #128
SUB   r2, r0, r11
MUL   r3, r1, r2
STORE r3, [0x0100]
LOAD  r13, [0x0100]

LI    r5, #128
MUL   r6, r1, r5
STORE r6, [0x0104]
LOAD  r14, [0x0104]

LI    r8, #768
MUL   r9, r1, r8
STORE r9, [0x0108]
LOAD  r15, [0x0108]

ADD   r17, r3, r6
JMP   jump_worked
LI    r16, #1

jump_worked:
HALT
