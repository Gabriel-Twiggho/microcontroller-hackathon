; ============================================================
; Basic PID ISA test
;
; Expected final values:
;   error       = 6
;   integral    = 16
;   derivative  = 2
;   P           = 12
;   I           = 16
;   D           = 6
;   output      = 34
; ============================================================

; Set up fake PID state in memory.
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

; One PID update: error = target - measured.
LOAD  r1, [0x0100]
LOAD  r2, [0x0104]
SUB   r3, r1, r2         ; error = 6

; integral = integral + error.
LOAD  r4, [0x0108]
ADD   r4, r4, r3         ; integral = 16

; derivative = error - previous_error.
LOAD  r5, [0x010C]
SUB   r6, r3, r5         ; derivative = 2

; P = Kp * error.
LOAD  r7, [0x0110]
MUL   r8, r7, r3         ; P = 12

; I = Ki * integral.
LOAD  r7, [0x0114]
MUL   r9, r7, r4         ; I = 16

; D = Kd * derivative.
LOAD  r7, [0x0118]
MUL   r10, r7, r6        ; D = 6

; output = P + I + D.
ADD   r11, r8, r9        ; 28
ADD   r11, r11, r10      ; output = 34

; Save updated PID state.
STORE r4,  [0x0108]      ; integral = 16
STORE r3,  [0x010C]      ; previous_error = 6
STORE r11, [0x011C]      ; output = 34

; A taken jump must skip the poison value.
JMP   finished
LI    r11, #99           ; MUST NOT execute

finished:
HALT
