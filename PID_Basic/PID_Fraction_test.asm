; ============================================================
; PID fractional-gain test using Q8 fixed-point (scale = 256,
; 8 fractional bits) with real on-chip downscaling.
;
; Q8 only gives exact results for BINARY fractions (halves,
; quarters, eighths, ...) -- not decimal ones like 0.1, which is
; why the gains here are chosen differently from the x10 test:
;
;   Kp_real = 0.5    (1/2) -> Kp_scaled = 0.5   * 256 = 128
;   Ki_real = 0.25   (1/4) -> Ki_scaled = 0.25  * 256 = 64
;   Kd_real = 0.125  (1/8) -> Kd_scaled = 0.125 * 256 = 32
;
; error/integral/derivative are chosen so every downscale (the
; final divide-by-256) comes out exact, same discipline as the
; x10 test.
;
; There is still no DIVIDE or SHIFT instruction in this ISA (Q8
; does not remove that limitation -- it just avoids rounding
; error for binary fractions specifically), so the downscale is
; still done by unrolled repeated subtraction -- 9 times, since
; we already know that's the exact answer.
;
; Expected final values:
;   error       = 8
;   integral    = 16
;   derivative  = 8
;   P           = 1024   (scaled; real 4)
;   I           = 1024   (scaled; real 4)
;   D           = 256    (scaled; real 1)
;   output      = 2304   (r11: stays intact, still the scaled value)
;   real_output = 9      (r12: the actual answer, computed entirely
;                          on-chip, via a separate countdown copy)
; ============================================================

LI    r1, #18
STORE r1, [0x0100]       ; setpoint = 18

LI    r1, #10
STORE r1, [0x0104]       ; measured = 10

LI    r1, #8
STORE r1, [0x0108]       ; integral = 8 (initial)

LI    r1, #0
STORE r1, [0x010C]       ; previous_error = 0

LI    r1, #128
STORE r1, [0x0110]       ; Kp_scaled = 128 (real 0.5, Q8)

LI    r1, #64
STORE r1, [0x0114]       ; Ki_scaled = 64  (real 0.25, Q8)

LI    r1, #32
STORE r1, [0x0118]       ; Kd_scaled = 32  (real 0.125, Q8)

LOAD  r1, [0x0100]
LOAD  r2, [0x0104]
SUB   r3, r1, r2         ; error = 18 - 10 = 8

LOAD  r4, [0x0108]
ADD   r4, r4, r3         ; integral = 8 + 8 = 16

LOAD  r5, [0x010C]
SUB   r6, r3, r5         ; derivative = 8 - 0 = 8

LOAD  r7, [0x0110]
MUL   r8, r7, r3         ; P = 128 * 8 = 1024

LOAD  r7, [0x0114]
MUL   r9, r7, r4         ; I = 64 * 16 = 1024

LOAD  r7, [0x0118]
MUL   r10, r7, r6        ; D = 32 * 8 = 256

ADD   r11, r8, r9        ; 2048
ADD   r11, r11, r10      ; output = 2048 + 256 = 2304 (scaled, Q8)

STORE r4,  [0x0108]
STORE r3,  [0x010C]
STORE r11, [0x011C]

; ------------------------------------------------------------
; Downscale: divide the scaled output (2304) by 256 using
; repeated subtraction. r12 counts how many times we subtracted
; -- that count is the real answer, produced entirely by real
; instructions.
;
; r11 (the scaled "output") is deliberately left untouched --
; the countdown happens in a *copy* (r15) instead, via
; "ADD r15, r11, r0" (this ISA's copy-a-register trick, since
; there is no MOV instruction -- adding zero is a no-op add).
; That way the scaled and downscaled values are both still
; visible in the final register dump, instead of the scaled one
; being overwritten down to 0.
; ------------------------------------------------------------
ADD   r15, r11, r0       ; r15 = copy of the scaled output (2304)
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
SUB   r15, r15, r13
ADD   r12, r12, r14
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
