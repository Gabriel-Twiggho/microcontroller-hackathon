; ============================================================
; SAR instruction test
;
; Expected final values:
;   r2 = 16
;   r4 = -4
;   r6 = 8
;   r7 = -1
;   r8 = 64
;   r9 = -1
; ============================================================

; Positive value with immediate shift.
LI   r1, #64
SAR  r2, r1, #2        ; 64 >>> 2 = 16

; Create a negative value using subtraction.
SUB  r3, r0, #16       ; r3 = -16
SAR  r4, r3, #2        ; -16 >>> 2 = -4

; Shift amount supplied through a register.
LI   r5, #3
SAR  r6, r1, r5        ; 64 >>> 3 = 8

; Confirm that the sign bit is preserved.
SAR  r7, r3, #4        ; -16 >>> 4 = -1

; Shift by zero should leave the value unchanged.
SAR  r8, r1, #0        ; 64 >>> 0 = 64

; Test the maximum 5-bit shift amount.
SAR  r9, r3, #31       ; negative value >>> 31 = -1

HALT