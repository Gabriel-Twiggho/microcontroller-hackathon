; Signed CMP and conditional-branch test.
; CMP writes -1, 0, or +1 to the implicit condition register r5.

    LI   r20, #0          ; failure flag
    LI   r1, #5
    LI   r2, #5

    CMP  r1, r2           ; equal -> r5 = 0
    JZ   equal_ok
    LI   r20, #1
equal_ok:
    LI   r10, #1
    JNZ  fail             ; must not branch

    SUB  r3, r0, r1       ; r3 = -5
    CMP  r3, r0           ; less -> r5 = -1
    JLT  less_ok
    JMP  fail
less_ok:
    LI   r11, #2
    JGT  fail             ; must not branch

    CMP  r1, r0           ; greater -> r5 = +1
    JGT  greater_ok
    JMP  fail
greater_ok:
    LI   r12, #3
    JZ   fail             ; must not branch

    CMP  r1, #4           ; register/immediate, not equal
    JNZ  not_equal_ok
    JMP  fail
not_equal_ok:
    LI   r13, #4

    CMP  r1, #5           ; final condition is equal
    JLT  fail             ; neither signed relation may branch
    JGT  fail
    JMP  done

fail:
    LI   r20, #1
done:
    HALT
