; ============================================================
; PID_Basic decimal PID performance test
;
; Inputs and state use signed Q8.8 fixed point (value * 256).
; Products remain Q16.16 because the baseline CPU has no SAR.
; The Q16.16 output still represents the correct decimal result.
;
; The testbench measures 1000 complete 19-instruction updates.
; ============================================================

; ---------- Identical decimal setup (14 instructions) ----------
LI    r1, #5120
STORE r1, [0x0100]       ; target = 20.00 in Q8.8

LI    r1, #5504
STORE r1, [0x0104]       ; measured = 21.50 in Q8.8

LI    r1, #2624
STORE r1, [0x0108]       ; integral = 10.25 in Q8.8

LI    r1, #256
STORE r1, [0x010C]       ; previous_error = 1.00 in Q8.8

LI    r1, #384
STORE r1, [0x0110]       ; Kp = 1.50 in Q8.8

LI    r1, #128
STORE r1, [0x0114]       ; Ki = 0.50 in Q8.8

LI    r1, #64
STORE r1, [0x0118]       ; Kd = 0.25 in Q8.8

; ========================================
; PERFORMANCE MEASUREMENT STARTS HERE
; pid_loop is instruction address 0x000E.
; ========================================
pid_loop:
LOAD  r1, [0x0100]       ; target, Q8.8
LOAD  r2, [0x0104]       ; measured, Q8.8
SUB   r3, r1, r2         ; error, Q8.8

LOAD  r4, [0x0108]       ; integral, Q8.8
ADD   r4, r4, r3         ; integral += error

LOAD  r5, [0x010C]       ; previous_error, Q8.8
SUB   r6, r3, r5         ; derivative, Q8.8

LOAD  r7, [0x0110]       ; Kp, Q8.8
MUL   r8, r7, r3         ; P, Q16.16

LOAD  r7, [0x0114]       ; Ki, Q8.8
MUL   r9, r7, r4         ; I, Q16.16

LOAD  r7, [0x0118]       ; Kd, Q8.8
MUL   r10, r7, r6        ; D, Q16.16

ADD   r11, r8, r9
ADD   r11, r11, r10      ; output, Q16.16

STORE r4,  [0x0108]      ; integral stays Q8.8
STORE r3,  [0x010C]      ; previous_error stays Q8.8
STORE r11, [0x011C]      ; output is Q16.16

JMP   pid_loop
