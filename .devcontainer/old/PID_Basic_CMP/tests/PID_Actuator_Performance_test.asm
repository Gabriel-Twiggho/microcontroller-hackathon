; Q8.8 PID with signed output clamping for a unipolar actuator.
; The arithmetic matches PID_Basic_SAR. CMP/JLT/JGT add the minimum
; software safety path needed to prevent negative or over-range PWM commands.

LI    r1, #5120
STORE r1, [0x0100]       ; target = 20.00
LI    r1, #5504
STORE r1, [0x0104]       ; measured = 21.50
LI    r1, #2624
STORE r1, [0x0108]       ; integral = 10.25
LI    r1, #256
STORE r1, [0x010C]       ; previous_error = 1.00
LI    r1, #384
STORE r1, [0x0110]       ; Kp = 1.50
LI    r1, #128
STORE r1, [0x0114]       ; Ki = 0.50
LI    r1, #64
STORE r1, [0x0118]       ; Kd = 0.25

pid_loop:
LOAD  r1, [0x0100]
LOAD  r2, [0x0104]
SUB   r3, r1, r2
LOAD  r4, [0x0108]
ADD   r4, r4, r3
LOAD  r5, [0x010C]
SUB   r6, r3, r5

LOAD  r7, [0x0110]
MUL   r8, r7, r3
SAR   r8, r8, #8
LOAD  r7, [0x0114]
MUL   r9, r7, r4
SAR   r9, r9, #8
LOAD  r7, [0x0118]
MUL   r10, r7, r6
SAR   r10, r10, #8

ADD   r11, r8, r9
ADD   r11, r11, r10
STORE r4, [0x0108]
STORE r3, [0x010C]

CMP   r11, r0
JLT   clamp_low
LI    r12, #65280        ; 255.0 in Q8.8
CMP   r11, r12
JGT   clamp_high
STORE r11, [0x011C]
JMP   pid_loop

clamp_low:
STORE r0, [0x011C]
JMP   pid_loop

clamp_high:
STORE r12, [0x011C]
JMP   pid_loop
