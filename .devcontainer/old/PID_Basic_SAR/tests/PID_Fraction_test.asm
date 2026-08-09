; ============================================================
; Fixed-point Q8 rescaling with SAR
;
; Input:
;   r1 = scaled_output (-1000 in this test)
;
; Expected result:
;   r2 = floor(-1000 / 256) = -4
; ============================================================

; Create scaled_output = -1000.
LI    r1, #1000
SUB   r1, r0, r1

; Divide the signed Q8 value by 256 in one instruction.
SAR   r2, r1, #8

STORE r2, [0x011C]
HALT
