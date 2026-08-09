; ============================================================
; PID performance test
;
; The testbench measures 1000 complete passes through pid_loop.
; Each pass contains 19 instructions, including the final JMP.
; ============================================================

; ---------- Setup ----------
LI    r1, #20
STORE r1, [0x0100]       ; target = 20

LI    r1, #14
STORE r1, [0x0104]       ; measured = 14

LI    r1, #10
STORE r1, [0x0108]       ; integral = 10

LI    r1, #4
STORE r1, [0x010C]       ; previous_error = 4

LI    r1, #2
STORE r1, [0x0110]       ; Kp = 2

LI    r1, #1
STORE r1, [0x0114]       ; Ki = 1

LI    r1, #3
STORE r1, [0x0118]       ; Kd = 3

; ========================================
; PERFORMANCE MEASUREMENT STARTS HERE
; pid_loop is instruction address 0x000E.
; ========================================
pid_loop:
LOAD  r1, [0x0100]       ; target
LOAD  r2, [0x0104]       ; measured
SUB   r3, r1, r2         ; error

LOAD  r4, [0x0108]       ; integral
ADD   r4, r4, r3         ; integral += error

LOAD  r5, [0x010C]       ; previous_error
SUB   r6, r3, r5         ; derivative

LOAD  r7, [0x0110]       ; Kp
MUL   r8, r7, r3         ; P

LOAD  r7, [0x0114]       ; Ki
MUL   r9, r7, r4         ; I

LOAD  r7, [0x0118]       ; Kd
MUL   r10, r7, r6        ; D

ADD   r11, r8, r9
ADD   r11, r11, r10      ; output = P + I + D

STORE r4,  [0x0108]      ; save integral
STORE r3,  [0x010C]      ; save previous_error
STORE r11, [0x011C]      ; save output

JMP   pid_loop
