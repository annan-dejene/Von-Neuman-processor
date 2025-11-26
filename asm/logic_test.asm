; Initialize registers
MOV R1, #0x000F ; R1 = 0000 0000 0000 1111 (15)
MOV R2, #0x0003 ; R2 = 0000 0000 0000 0011 (3)

; Perform Logical Operations
AND R3, R1, R2  ; R3 = R1 & R2 = 0011 (3)
OR  R4, R1, R2  ; R4 = R1 | R2 = 1111 (15)
XOR R5, R1, R2  ; R5 = R1 ^ R2 = 1100 (12)
NOT R6, R1      ; R6 = ~R1 = 1111 1111 1111 0000 (-16 or 0xFFF0)

HLT             ; Stop execution