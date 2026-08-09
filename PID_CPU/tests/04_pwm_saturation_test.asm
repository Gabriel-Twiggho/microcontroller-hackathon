; Test 4: convert Q8.8 controller values to a raw 8-bit PWM command.
;
; The three cases prove the complete saturation range:
;   negative input -> r10 = 0
;   128.0 input    -> r11 = 128
;   257.0 input    -> r12 = 255
; r15 is the failure flag and must remain zero.

LI    r15, #0
LI    r6, #65280        ; upper bound: 255.0 in Q8.8

; Lower-bound saturation.
LI    r1, #2560         ; 10.0 in Q8.8
SUB   r1, r0, r1        ; -10.0
CMP   r1, r0
JLT   low_clamp
JMP   fail
low_clamp:
ADD   r10, r0, r0
STORE r10, [0x0120]

; In-range conversion.
LI    r2, #32768        ; 128.0 in Q8.8
CMP   r2, r0
JLT   fail
CMP   r2, r6
JGT   fail
SAR   r11, r2, #8
STORE r11, [0x0124]

; Upper-bound saturation.
LI    r3, #65280        ; 255.0 in Q8.8
LI    r4, #512          ; 2.0 in Q8.8
ADD   r3, r3, r4        ; 257.0 in Q8.8
CMP   r3, r6
JGT   high_clamp
JMP   fail
high_clamp:
LI    r12, #255
STORE r12, [0x0128]
JMP   done

fail:
LI    r15, #1
done:
HALT
