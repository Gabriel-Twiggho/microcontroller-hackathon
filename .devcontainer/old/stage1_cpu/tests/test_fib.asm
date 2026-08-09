; Recursive Stage 3 test: fib(7) = 13.
; Calling convention:
;   r8 = argument and return value
;   r2 = stack pointer
;   r3/lr = return address

LI   sp, #31744
LI   r8, #7
CALL fib
HALT

fib:
; Base case: if n < 2, return n unchanged in r8.
CMP  r5, r8, #2
JLT  fib_base

; Preserve the caller's return address and the original n.
PUSH lr
PUSH r8

; First recursive result: fib(n - 1).
SUB  r8, r8, #1
CALL fib
MOV  r9, r8

; Restore n and preserve fib(n - 1) across the second call.
POP  r8
PUSH r9

; Second recursive result: fib(n - 2).
SUB  r8, r8, #2
CALL fib

; Combine both results and restore the caller's return address.
POP  r9
ADD  r8, r9, r8
POP  lr
RET

fib_base:
RET
