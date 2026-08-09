; ============================================================
; PID_Basic_SAR decimal PID performance test
;
; Inputs, state, products, and output use signed Q8.8 fixed point
; (value * 256). SAR #8 normalizes each Q16.16 multiplication.
;
; The testbench measures 1000 complete 22-instruction updates.
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
MUL   r8, r7, r3         ; Q16.16 product
SAR   r8, r8, #8         ; P, Q8.8

LOAD  r7, [0x0114]       ; Ki, Q8.8
MUL   r9, r7, r4         ; Q16.16 product
SAR   r9, r9, #8         ; I, Q8.8

LOAD  r7, [0x0118]       ; Kd, Q8.8
MUL   r10, r7, r6        ; Q16.16 product
SAR   r10, r10, #8       ; D, Q8.8

ADD   r11, r8, r9
ADD   r11, r11, r10      ; output, Q8.8

STORE r4,  [0x0108]      ; integral, Q8.8
STORE r3,  [0x010C]      ; previous_error, Q8.8
STORE r11, [0x011C]      ; output, Q8.8

JMP   pid_loop
