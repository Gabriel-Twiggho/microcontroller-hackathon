; Stage 1 calling-convention smoke test.
; r8 and r9 carry the two arguments; r8 carries the return value.
LI r8, #21
LI r9, #21
CALL add
HALT

add:
ADD r8, r8, r9
RET
