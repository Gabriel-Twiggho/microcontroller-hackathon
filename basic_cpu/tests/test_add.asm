; Stage 1 arithmetic test: 21 + 21 = 42, then subtraction and MOV.
LI   r8, #21
LI   r9, #21
ADD  r8, r8, r9
SUB  r10, r8, #2
MOV  r11, r10
HALT
