; Test 1: core arithmetic and memory operations.
;
; Expected final state:
;   r2 = 20   (LOAD)
;   r3 = 14   (SUB)
;   r4 = 34   (ADD)
;   r6 = 42   (MUL)
;   r7 = 42   (STORE/LOAD round trip)

LI    r1, #20
STORE r1, [0x0100]
LOAD  r2, [0x0100]
SUB   r3, r2, #6
ADD   r4, r2, r3
MUL   r6, r3, #3
STORE r6, [0x0104]
LOAD  r7, [0x0104]
HALT
