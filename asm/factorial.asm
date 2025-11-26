; Calculate Factorial of N (Result = N!)
; Using repeated addition for multiplication
;
; Registers:
; R1: N (The input number, e.g., 5)
; R2: Result (Accumulator, starts at 1)
; R3: Multiplier_Counter (Used for repeated add loop)
; R4: Temp_Sum (Holds partial sum during multiplication)
; R5: Constant 1 (For decrementing)
; R6: Constant 0 (For comparisons)

; --- Initialization ---
MOV R1, #5      ; Input: Calculate 5! (Expected: 120 or 0x78)
MOV R2, #1      ; Result = 1
MOV R5, #1      ; Constant 1
MOV R6, #0      ; Constant 0

; --- Main Loop (Count down N) ---
LOOP_MAIN:
    BEQZ R1, +12    ; If N == 0, we are done -> Jump to EXIT (Forward 12)
    
    ; Prepare for Multiplication: Result = Result * N
    ; We will do: Temp_Sum = 0; Counter = N;
    ; Inner Loop: Temp_Sum = Temp_Sum + Result; Counter--;
    
    MOV R4, #0      ; Temp_Sum = 0
    ADD R3, R1, R6  ; Multiplier_Counter = N (Copy R1 to R3)

    ; --- Inner Loop (Multiplication by Repeated Addition) ---
    LOOP_MUL:
        BEQZ R3, +3     ; If Counter == 0, Mult done -> Jump to NEXT_N
        ADD R4, R4, R2  ; Temp_Sum = Temp_Sum + Result
        SUB R3, R3, R5  ; Counter--
        JMP 0x09        ; Jump back to LOOP_MUL (Absolute Address 9)

    ; --- Next N ---
    NEXT_N:
    ADD R2, R4, R6  ; Result = Temp_Sum (Copy R4 to R2)
    SUB R1, R1, R5  ; N--
    JMP 0x04        ; Jump back to LOOP_MAIN (Absolute Address 4)

; --- Exit ---
EXIT:
    HLT             ; Stop. R2 should hold 120 (0x0078)