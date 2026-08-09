; Test 2: signed arithmetic right shift and Q8.8 conversion.
;
; Expected final state:
;   r2 = 125          (1000 >>> 3)
;   r4 = -4           (-1000 >>> 8, rounded toward -infinity)
;   r6 = 50           (50.0 encoded as Q8.8, converted to integer)

LI    r1, #1000
SAR   r2, r1, #3

SUB   r3, r0, r1
SAR   r4, r3, #8

LI    r5, #12800      ; 50.0 * 256
SAR   r6, r5, #8
HALT
