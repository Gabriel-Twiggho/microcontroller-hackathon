; Test 3: signed CMP and taken/not-taken conditional branches.
;
; r15 is the failure flag and must remain zero.
; Expected markers: r10 = 1, r11 = 2, r12 = 3, r13 = 4.

LI    r15, #0
LI    r1, #5
LI    r2, #5

CMP   r1, r2
JZ    equal_ok
JMP   fail
equal_ok:
LI    r10, #1
JNZ   fail

SUB   r3, r0, r1
CMP   r3, r0
JLT   less_ok
JMP   fail
less_ok:
LI    r11, #2
JGT   fail

CMP   r1, r0
JGT   greater_ok
JMP   fail
greater_ok:
LI    r12, #3
JZ    fail

CMP   r1, #4
JNZ   not_equal_ok
JMP   fail
not_equal_ok:
LI    r13, #4
JMP   done

fail:
LI    r15, #1
done:
HALT
