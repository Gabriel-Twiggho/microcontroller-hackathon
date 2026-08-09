; ============================================================
; Fixed-point Q8 rescaling without SAR
;
; Input:
;   r1 = scaled_output (-1000 in this test)
;
; Expected result:
;   r2 = floor(-1000 / 256) = -4
;
; NOTE: This is the intended software fallback sequence. The
; current PID_Basic RTL does not yet implement CMP, JLT, or SHR.
; ============================================================

; Create scaled_output = -1000.
LI    r1, #1000
SUB   r1, r0, r1

; Select the positive or negative rescaling path.
CMP   r5, r1, r0
JLT   negative_value

positive_value:
SHR   r2, r1, #8
JMP   finished

negative_value:
; Convert the input to its positive magnitude.
SUB   r3, r0, r1

; Adding 255 before the logical shift reproduces the rounding
; of an arithmetic right shift for negative values.
LI    r4, #255
ADD   r3, r3, r4
SHR   r3, r3, #8

; Restore the negative sign.
SUB   r2, r0, r3

finished:
STORE r2, [0x011C]
HALT
