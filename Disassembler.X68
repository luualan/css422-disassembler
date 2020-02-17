*-----------------------------------------------------------
* Title      :  Disassembler for the Motorola MC68000 Microprocessor
* Written by :  Avery Mortenson & Alan Luu
* Date       :  2/12/2020
* Description:  An inverse assembler (disassembler) that will 
* convert a memory image of instructions and data back 
* to the MC68000 assembly code and that will output the 
* disassembled code to the display.
*-----------------------------------------------------------
    ORG    $1000
START:     move.b   #14,d0	Display instructions
	       lea	    WELCOME,a1
	       trap	    #15
    

    SIMHALT             ; halt simulator

* Put variables and constants here

CR         EQU          $0D
LF         EQU          $0A

WELCOME    DC.B         'Welcome to the 68k Disassembler of Avery and Alan',CR,LF,CR,LF,0

USER_INST  DC.B         'Please follow the proper input instructions below: ',CR,LF
           DC.B         '- Starting address must be lower than ending address.'CR,LF
           DC.B         '- The values for the starting and ending address must be an even value.',CR,LF
           DC.B         '- Starting and ending address must be inputted as hexadecimal value.',CR,LF
           DC.B         '- Do not put spaces in between input characters.',CR,LF
           DC.B         '- Valid charachters include: 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, A, B, C, D, E, F',CR,LF,0
           

    END    START        ; last line of source


*~Font name~Courier New~
*~Font size~10~
*~Tab type~1~
*~Tab size~4~
