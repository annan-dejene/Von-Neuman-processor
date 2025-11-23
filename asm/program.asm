MOV R1, #0 ; sum = 0
MOV R2, #10 ; i = 10
MOV R3, #1 ; val = 1

ADD R1, R1, R2 ; sum += i
SUB R2, R2, R3 ; i--
BEQZ R2, 0x07 ;; (R2 == 0 ??) yes -> exit 
JMP 0x03 ;; else loop back
HLT ;; end (expect R1 = 55)