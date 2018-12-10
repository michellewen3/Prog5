; Main.asm
; Name: Andrew Wu and Michelle Wen
; UTEid: amw5468 and mw37583
; Continuously reads from x4600 making sure its not reading duplicate
; symbols. Processes the symbol based on the program description
; of mRNA processing.

               .ORIG x4000
; initialize the stack pointer
		LD R6, stack_start	;R6 = x2600


; set up the keyboard interrupt vector table entry
		LD R0, ISR_ADDR		;R0 = x2600
		STI R0, IVT_ADDR	;writes x2600 to the memory location x0180


; enable keyboard interrupts
		LD R0, KBSR_bitmask  	;now R0 = x4000 bitmask
		STI R0, KBSR_ADDR 	;now KBSR bit 14 is set to 1 and interrupts are now enabled with keystroke
		
		AND R0, R0, #0		;now R0 = 0
		STI R0, Input_ADDR	;now x4600 location has a '0'
		BRnzp cleararray


zerothindexisA  LD R4, array_pointer	;R4 = x3000 (start of array)
		AND R0, R0, #0
		ADD R0, R0, #-1
		STR R2, R4, 0		;array zero index is set to 'A'
		STR R0, R4, 1		;array first index is initialized to -1
		STR R0, R4, 2		;array second index is initialized to -1
		BRnzp loop


cleararray	LD R4, array_pointer	;R4 = x3000 (start of array)
		AND R0, R0, #0
		ADD R0, R0, #-1
		STR R0, R4, 0		;array zero index is initialized to -1
		STR R0, R4, 1		;array first index is initialized to -1
		STR R0, R4, 2		;array second index is initialized to -1

;START OF ACTUAL PROGRAM

loop		AND R0, R0, #0
		STI R0, Input_ADDR	;clear x4600 to 0 if looping back		

loop1		LDI R2, Input_ADDR	;R2 = contents of x4600
		BRz loop1		;if x4600 has 0 (input is not valid) then keep looking for valid character
		ADD R0, R2, #0		;now R0 = R2
		TRAP x21		;prints character to console
		
;start of branch algorithm checks
;case 1: array empty
		LD R4, array_pointer	;R4 = x3000 (start of array)
		LDR R0, R4, 0		;RO = first index contents
		BRzp case2		;will only fall through if R0 = -1 but jumps to case 2 if not -1
		LD R0, nascii_A		;now R0 = -65		
		ADD R3, R2, R0
		BRnp loop		;if not zero --> the character is not A so don't store to array
		STR R2, R4, 0		;stores A to first index of array--> now array contains A	
		BRnzp loop

;case2: array currently has A
case2		LDR R3, R4, 1		;R3 = contents in second index
		BRzp case3		;if -1 fall through and write U; otherwise already has AU and goes to case3
		LD R0, nascii_U 	;R0 = -85
		ADD R3, R2, R0
		BRnp isinputA		;if neg/pos result then input is not U--> need to test if it is A
		STR R2, R4, 1		;now array contains A-U
		BRnzp loop

isinputA	LD R0, nascii_A		;R0 = -65
		ADD R3, R2, R0
		BRz zerothindexisA
		BRnzp cleararray

;case3; array currently has AU
case3		LD R0, nascii_G 	
		ADD R3, R2, R0
		BRnp isinputA		
		STR R2, R4, 2		
		LD R0, ascii_pipe	
		TRAP x21
		BRnzp clearstoparray

zerothindexisU  AND R0, R0, #0
		ADD R0, R0, #-1
		STR R2, R4, 3		
		STR R0, R4, 4		
		STR R0, R4, 5		
		BRnzp loop2

clearstoparray	AND R0, R0, #0
		ADD R0, R0, #-1		
		STR R0, R4, 3		
		STR R0, R4, 4		
		STR R0, R4, 5		


;loop2: at this point in the code, it starts the actual coding sequence and we only need to check for stop codons
loop2		AND R0, R0, #0
		STI R0, Input_ADDR	

loop_2		LDI R2, Input_ADDR	
		BRz loop_2		
		ADD R0, R2, #0		
		TRAP x21		
	
		
;case1 should only store U to first index if array is empty 
		LDR R0, R4, 3		
		BRzp case_2		
		LD R0, nascii_U		
		ADD R3, R2, R0
		BRnp clearstoparray
		STR R2, R4, 3		
		BRnzp loop2

;case_2 (can only run if array only has U right now) should only store the input if it is A or G
case_2		LDR R0, R4, 4		
		BRzp case_3		
		LD R0, nascii_A		
		ADD R3, R2, R0
		BRz writesecond		
		LD R0, nascii_G		
		ADD R3, R2, R0
		BRz writesecond		
		BRnp isinputU		
writesecond	STR R2, R4, 4		
		BRnzp loop2

isinputU	LD R0, nascii_U		
		ADD R3, R2, R0
		BRz zerothindexisU
		BRnzp clearstoparray

;case_3(can only run if array already has either UA or UG) and should only store if it makes UAG, UAA, or UGA stop codon
case_3		LDR R0, R4, 4		
		LD R3, nascii_A		
		ADD R5, R0, R3
		BRz secondisA		
		ADD R5, R2, R3		
		BRnp isinputU		
		STR R2, R4, 5		
		BRnzp DONE		

;at this point in code the array must contain UA and we are checking the third letter
secondisA	ADD R5, R2, R3
		BRnp checkG
		STR R2, R4, 5		
		BRnzp DONE
checkG		LD R3, nascii_G		
		ADD R5, R2, R3
		BRnp isinputU		
		STR R2, R4, 5		
		BRnzp DONE
	

DONE		AND R0, R0, #0		
		ADD R0, R0, #-1
		STR R0, R4, 0
		STR R0, R4, 1		
		STR R0, R4, 2	
		STR R0, R4, 3		
		STR R0, R4, 4	
		STR R0, R4, 5		
		TRAP x25

stack_start .FILL x2600
ISR_ADDR .FILL X2600
IVT_ADDR .FILL x0180
KBSR_bitmask .FILL x4000
KBSR_ADDR .FILL xFE00
Input_ADDR .FILL x4600
nascii_A .FILL -65
nascii_C .FILL -67
nascii_G .FILL -71
nascii_U .FILL -85
ascii_pipe .FILL 124
array_pointer .FILL x3000
;stoparray_pointer .FILL x3100
		.END
