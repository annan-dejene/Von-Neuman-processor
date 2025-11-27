; Calculate Fibonacci Sequence and store in memory
; Sequence: 0, 1, 1, 2, 3, 5, 8, 13, 21, 34...
; Store starting from memory address: 0x32 (50)

; --- Initial Setup ---
MOV R1, #0      ; Fib[n]   (Current number to store)
MOV R2, #1      ; Fib[n+1] (Next number)
MOV R3, #0x32   ; Memory Pointer (Start at 50)
MOV R6, #20     ; Counter (First 50 fib numbers)
MOV R5, #1      ; Constant 1

; --- Loop ---
"loop":
    BEQZ R6, "endloop" ; If Counter is 0, Exit the loop

    ; 1. Store Current Number (R1)
    STR R3, R1      ; Mem[R3] = R1

    ; 2. Calculate Next Number (Temp = R1 + R2)
    ADD R4, R1, R2  ; R4 = R1 + R2

    ; 3. Shift (R1 = R2, R2 = R4)
    ; Since we don't have MOV Reg, Reg, we use ADD with 0
    ADD R1, R2, R0  ; R1 = R2 + 0
    ADD R2, R4, R0  ; R2 = R4 + 0

    ; 4. Increment Memory Pointer
    ADD R3, R3, R5  ; R3++

    ; 5. Decrement Counter
    SUB R6, R6, R5  ; R6--

    JMP "loop"        ; Repeat

"endloop":
    HLT