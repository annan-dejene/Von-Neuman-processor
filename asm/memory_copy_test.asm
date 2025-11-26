; Setup
MOV R1, #10 ; Value to store (Data = 10)
MOV R2, #32 ; Source Address (32)
MOV R3, #33 ; Destination Address (33)

; Store initial value to memory
STR R2, R1      ; Mem[32] = 10

; Load value back from memory
LDR R4, R2      ; R4 = Mem[32] (R4 should be 10)

; Store value to new location
STR R3, R4      ; Mem[33] = R4 (Mem[33] should be 10)

HLT             ; Stop execution