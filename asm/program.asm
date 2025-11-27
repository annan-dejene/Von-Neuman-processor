MOV R1, #0 ; sum = 0
MOV R2, #10 ; i = 10
MOV R3, #1 ; val = 1
MOV R4, #15 ; memory address we will write to

"loop": ADD R1, R1, R2 ; sum += i
SUB R2, R2, R3 ; i--
BEQZ R2, "endloop" ;; (R2 == 0 ??) yes -> exit 
JMP "loop" ;; else loop back
"endloop": STR R4, R1 ;; memory[15]
HLT ;; end (expect R1 = 55)