; Compact Q4.4 PID. Products intentionally remain Q8.8 because this baseline
; has no normalization instruction. An external actuator scaler is required.
LI    r1, #320
STORE r1, [0x100]        ; target = 20.0000
LI    r1, #321
STORE r1, [0x102]        ; measured = 20.0625
LI    r1, #16
STORE r1, [0x104]        ; integral = 1.0000
LI    r1, #1
SUB   r1, r0, r1
STORE r1, [0x106]        ; previous_error = -0.0625
LI    r1, #24
STORE r1, [0x108]        ; Kp = 1.5000
LI    r1, #8
STORE r1, [0x10A]        ; Ki = 0.5000
LI    r1, #4
STORE r1, [0x10C]        ; Kd = 0.2500

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
LOAD  r2, [0x10A]
MUL   r7, r2, r4
ADD   r6, r6, r7
LOAD  r2, [0x10C]
MUL   r7, r2, r5
ADD   r7, r6, r7
STORE r4, [0x104]
STORE r3, [0x106]
STORE r7, [0x10E]
JMP   pid_loop
