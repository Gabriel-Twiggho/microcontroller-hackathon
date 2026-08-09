; ============================================================
; PID mixed-sign fractional-gain test, Q8 fixed-point (scale =
; 256, 8 fractional bits), with real on-chip downscaling.
;
; Same technique as PID_Fraction_test.asm, but Ki is negative
; this time -- isolating the effect of a negative gain while
; keeping the same Q8 scale and downscale method.
;
;   Kp_real =  0.5    (1/2) -> Kp_scaled =  0.5   * 256 =  128
;   Ki_real = -0.25   (1/4) -> Ki_scaled = -0.25  * 256 = -64   (negative)
;   Kd_real =  0.125  (1/8) -> Kd_scaled =  0.125 * 256 =  32
;
; error/integral/derivative are chosen so every downscale comes
; out exact, and the combined output stays positive overall
; (even though I is negative), so the same "repeated subtract
; 256" downscale routine works unmodified.
;
; Expected final values:
;   error       = 16
;   integral    = 20
;   derivative  = 8
;   P           = 2048    (scaled; real  8)
;   I           = -1280   (scaled; real -5)  (0xFFFFFB00)
;   D           = 256     (scaled; real  1)
;   output      = 1024   (r11: stays intact, still the scaled value)
;   real_output = 4      (r12: the actual answer, computed entirely
;                          on-chip, via a separate countdown copy)
; ============================================================

LI    r1, #20
STORE r1, [0x0100]       ; setpoint = 20

LI    r1, #4
STORE r1, [0x0104]       ; measured = 4

LI    r1, #4
STORE r1, [0x0108]       ; integral = 4 (initial)

LI    r1, #8
STORE r1, [0x010C]       ; previous_error = 8

LI    r1, #128
STORE r1, [0x0110]       ; Kp_scaled = 128 (real 0.5, Q8)

; Ki_scaled = -64 (real -0.25, Q8): computed as 0 - 64, since LI
; cannot load a negative value.
LI    r1, #0
LI    r2, #64
SUB   r1, r1, r2
STORE r1, [0x0114]       ; Ki_scaled = -64 (real -0.25, Q8)

LI    r1, #32
STORE r1, [0x0118]       ; Kd_scaled = 32 (real 0.125, Q8)

LOAD  r1, [0x0100]
LOAD  r2, [0x0104]
SUB   r3, r1, r2         ; error = 20 - 4 = 16

LOAD  r4, [0x0108]
ADD   r4, r4, r3         ; integral = 4 + 16 = 20

LOAD  r5, [0x010C]
SUB   r6, r3, r5         ; derivative = 16 - 8 = 8

LOAD  r7, [0x0110]
MUL   r8, r7, r3         ; P = 128 * 16 = 2048

LOAD  r7, [0x0114]
MUL   r9, r7, r4         ; I = -64 * 20 = -1280

LOAD  r7, [0x0118]
MUL   r10, r7, r6        ; D = 32 * 8 = 256

ADD   r11, r8, r9        ; 2048 + (-1280) = 768
ADD   r11, r11, r10      ; output = 768 + 256 = 1024 (scaled, Q8)

STORE r4,  [0x0108]
STORE r3,  [0x010C]
STORE r11, [0x011C]

; ------------------------------------------------------------
; Downscale: divide the scaled output (1024) by 256 using
; repeated subtraction. r11 is left untouched (still the scaled
; value) -- the countdown happens in a copy (r15) instead, via
; "ADD r15, r11, r0" (this ISA's copy-a-register trick, since
; there is no MOV instruction).
; ------------------------------------------------------------
ADD   r15, r11, r0       ; r15 = copy of the scaled output (1024)
LI    r13, #256          ; amount to subtract each time
LI    r14, #1            ; amount to count up each time
LI    r12, #0            ; real_output starts at 0, counts up

SUB   r15, r15, r13
ADD   r12, r12, r14
SUB   r15, r15, r13
ADD   r12, r12, r14
SUB   r15, r15, r13
ADD   r12, r12, r14
SUB   r15, r15, r13
ADD   r12, r12, r14

STORE r12, [0x0120]      ; save the real, downscaled output

HALT
