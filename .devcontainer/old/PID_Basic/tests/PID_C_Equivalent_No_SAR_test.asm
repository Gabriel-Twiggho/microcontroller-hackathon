; PID_Basic version of the SAR_GTH C-equivalent correctness workload.
; Basic has no SAR, so it stores the raw Q8.8 result (-12960) instead of
; converting it to the integer result (-51).

LI    r1, #100
STORE r1, [0x0100]
LI    r1, #120
STORE r1, [0x0104]
LI    r1, #384
STORE r1, [0x0110]
LI    r1, #64
STORE r1, [0x0114]
LI    r1, #200
STORE r1, [0x0118]

pid_loop:
LOAD  r1, [0x0100]
LOAD  r2, [0x0104]
SUB   r3, r1, r2
LOAD  r4, [0x0110]
MUL   r5, r4, r3
LOAD  r4, [0x0114]
MUL   r6, r4, r3
ADD   r5, r5, r6
LOAD  r4, [0x0118]
MUL   r6, r4, r3
ADD   r5, r5, r6
STORE r5, [0x011C]
LOAD  r9, [0x011C]
JMP   pid_loop
