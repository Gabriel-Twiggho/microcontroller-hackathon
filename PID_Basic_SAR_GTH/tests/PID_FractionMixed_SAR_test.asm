; Same mixed-sign fractional PID case as PID_Basic/PID_FractionMixed_test.asm.
; The output is Q8.8 raw 1024 (real 4), normalized by one runtime SAR.

LI r1, #20
STORE r1, [0x0100]
LI r1, #4
STORE r1, [0x0104]
LI r1, #4
STORE r1, [0x0108]
LI r1, #8
STORE r1, [0x010C]
LI r1, #128
STORE r1, [0x0110]
LI r1, #0
LI r2, #64
SUB r1, r1, r2
STORE r1, [0x0114]
LI r1, #32
STORE r1, [0x0118]

LOAD r1, [0x0100]
LOAD r2, [0x0104]
SUB  r3, r1, r2
LOAD r4, [0x0108]
ADD  r4, r4, r3
LOAD r5, [0x010C]
SUB  r6, r3, r5
LOAD r7, [0x0110]
MUL  r8, r7, r3
LOAD r7, [0x0114]
MUL  r9, r7, r4
LOAD r7, [0x0118]
MUL  r10, r7, r6
ADD  r11, r8, r9
ADD  r11, r11, r10
STORE r4, [0x0108]
STORE r3, [0x010C]
STORE r11, [0x011C]

SAR   r12, r11, #8
STORE r12, [0x0120]
HALT
