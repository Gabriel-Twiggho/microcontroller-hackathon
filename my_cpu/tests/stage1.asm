; Stage 1 smoke test — exercises ADD, SUB, MOV, LI, and HALT.
; Expected: r8=7, r9=3, r10=10, r11=4, r12=10
LI   r8, #7
LI   r9, #3
ADD  r10, r8, r9      ; r10 = 7 + 3 = 10
SUB  r11, r8, r9      ; r11 = 7 - 3 = 4
MOV  r12, r10         ; r12 = r10 = 10
HALT
