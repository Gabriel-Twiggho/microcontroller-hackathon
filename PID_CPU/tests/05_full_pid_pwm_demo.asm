; Test 5: complete Q8.8 PID update with a raw 0..255 PWM output.
;
; This is the recording workflow. The testbench measures 1,000 complete
; updates. A zero error keeps the controller stable: the integral term
; produces 50.0 in Q8.8, which is stored as the raw PWM value 50.

; Exactly 14 setup instructions keep pid_loop at address 0x000E.
LI    r1, #5120
STORE r1, [0x0100]       ; target = 20.0
LI    r1, #5120
STORE r1, [0x0104]       ; measured = 20.0
LI    r1, #25600
STORE r1, [0x0108]       ; integral = 100.0
LI    r1, #0
STORE r1, [0x010C]       ; previous error = 0.0
LI    r1, #384
STORE r1, [0x0110]       ; Kp = 1.5
LI    r1, #128
STORE r1, [0x0114]       ; Ki = 0.5
LI    r1, #64
STORE r1, [0x0118]       ; Kd = 0.25

pid_loop:
LOAD  r1, [0x0100]
LOAD  r2, [0x0104]
SUB   r3, r1, r2         ; error
LOAD  r4, [0x0108]
ADD   r4, r4, r3         ; integral
LOAD  r5, [0x010C]
SUB   r6, r3, r5         ; derivative

LOAD  r7, [0x0110]
MUL   r8, r7, r3
SAR   r8, r8, #8         ; P, Q8.8
LOAD  r7, [0x0114]
MUL   r9, r7, r4
SAR   r9, r9, #8         ; I, Q8.8
LOAD  r7, [0x0118]
MUL   r10, r7, r6
SAR   r10, r10, #8       ; D, Q8.8

ADD   r11, r8, r9
ADD   r11, r11, r10      ; controller output, Q8.8
STORE r4, [0x0108]
STORE r3, [0x010C]

; Saturate in Q8.8, then convert to the raw PWM register format.
CMP   r11, r0
JLT   clamp_low
LI    r12, #65280        ; 255.0 in Q8.8
CMP   r11, r12
JGT   clamp_high
SAR   r13, r11, #8
STORE r13, [0x011C]
JMP   pid_loop

clamp_low:
ADD   r13, r0, r0
STORE r13, [0x011C]
JMP   pid_loop

clamp_high:
LI    r13, #255
STORE r13, [0x011C]
JMP   pid_loop
