; ============================================================
; PID test 2 of 4: whole numbers, one sign flip from test 1.
; Identical to PID_WholePositive_test.asm (same error, same
; integral, same gains) except previous_error is now larger than
; error, so derivative -- and only derivative -- comes out
; negative. Isolates exactly one variable at a time against test 1.
;
; Expected final values:
;   error       = 20
;   integral    = 120
;   derivative  = -5   (0xFFFFFFFB)
;   P           = 40
;   I           = 360
;   D           = -20  (0xFFFFFFEC)
;   output      = 380
; ============================================================

LI    r1, #30
STORE r1, [0x0100]       ; setpoint = 30

LI    r1, #10
STORE r1, [0x0104]       ; measured = 10

LI    r1, #100
STORE r1, [0x0108]       ; integral = 100 (initial)

LI    r1, #25
STORE r1, [0x010C]       ; previous_error = 25 (> error -> negative derivative)

LI    r1, #2
STORE r1, [0x0110]       ; Kp = 2

LI    r1, #3
STORE r1, [0x0114]       ; Ki = 3

LI    r1, #4
STORE r1, [0x0118]       ; Kd = 4

LOAD  r1, [0x0100]
LOAD  r2, [0x0104]
SUB   r3, r1, r2         ; error = 30 - 10 = 20

LOAD  r4, [0x0108]
ADD   r4, r4, r3         ; integral = 100 + 20 = 120

LOAD  r5, [0x010C]
SUB   r6, r3, r5         ; derivative = 20 - 25 = -5

LOAD  r7, [0x0110]
MUL   r8, r7, r3         ; P = 2 * 20 = 40

LOAD  r7, [0x0114]
MUL   r9, r7, r4         ; I = 3 * 120 = 360

LOAD  r7, [0x0118]
MUL   r10, r7, r6        ; D = 4 * -5 = -20

ADD   r11, r8, r9        ; 400
ADD   r11, r11, r10      ; output = 400 + (-20) = 380

STORE r4,  [0x0108]
STORE r3,  [0x010C]
STORE r11, [0x011C]

HALT
