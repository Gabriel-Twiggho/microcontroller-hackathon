; ============================================================
; Assembly equivalent of the C PID-style loop
;
; Expected:
;   error       = 100 - 120 = -20
;   raw output  = (384 + 64 + 200) * -20
;               = -12960
;   scaled      = -12960 >>> 8
;               = -51
; ============================================================

; Initialise memory exactly like the C program.

LI    r1, #100
STORE r1, [0x0100]       ; target

LI    r1, #120
STORE r1, [0x0104]       ; measured

LI    r1, #384
STORE r1, [0x0110]       ; kp

LI    r1, #64
STORE r1, [0x0114]       ; ki

LI    r1, #200
STORE r1, [0x0118]       ; kd


pid_loop:
    ; error = target - measured

    LOAD  r1, [0x0100]
    LOAD  r2, [0x0104]
    SUB   r3, r1, r2     ; r3 = -20


    ; scaled_output = kp * error

    LOAD  r4, [0x0110]
    MUL   r5, r4, r3     ; r5 = 384 * -20


    ; scaled_output += ki * error

    LOAD  r4, [0x0114]
    MUL   r6, r4, r3
    ADD   r5, r5, r6


    ; scaled_output += kd * error

    LOAD  r4, [0x0118]
    MUL   r6, r4, r3
    ADD   r5, r5, r6     ; r5 = -12960


    ; Gains are Q8.8 and error is integer, so the product sum is Q8.8.
    ; Convert that Q8.8 result back to an integer output.

    SAR   r8, r5, #8     ; r8 = -51
    STORE r8, [0x011C]


    ; Diagnostic read-back to prove STORE worked.

    LOAD  r9, [0x011C]   ; r9 should also equal -51

    JMP   pid_loop
