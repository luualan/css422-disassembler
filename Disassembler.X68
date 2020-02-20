*-----------------------------------------------------------
* Title      :  Disassembler for the Motorola MC68000 Microprocessor
* Written by :  Avery Mortenson & Alan Luu
* Date       :  2/12/2020
* Description:  An inverse assembler (disassembler) that will 
* convert a memory image of instructions and data back 
* to the MC68000 assembly code and that will output the 
* disassembled code to the display.
* Title      : CSS 422
* Written by : Alan Luu and Avery Mortenson
* Date       : 2/16/2020
* Description: Disassembler
*-----------------------------------------------------------
    ORG    $1000
START:      JSR     DISP_W          ; Display Welcome Message. 
            JSR     DISP_UI         ; Display User Instructions.
            JSR     PROMPT_START    ; Prompt the user for starting address. 

DISP_W      MOVE.B  #14,D0	        ; Display Welcome Message. 
            LEA	    WELCOME,A1
            TRAP    #15

* Put program code here

DISP_UI         MOVE.B  #14,D0             ; Display User Instructions. 
                LEA	    USER_INST,A1
                TRAP    #15	   

       
PROMPT_START    LEA     START_IN,A1        ; Display starting address message
                MOVE.B  #14,D0
                TRAP    #15       
     
READ_START      LEA     START_ADDRESS,A1        ; Store user's starting address input
                MOVE.B  #2,D0                   ; Read user's input into A1; length is stored into D1
                TRAP    #15
                MOVE.B  #0,D6

VALIDATE_START  BRA     ATOI

PROMPT_END      LEA     END_IN,A1        ; Display starting address message
                MOVE.B  #14,D0
                TRAP    #15            
READ_END        LEA     END_ADDRESS,A1        ; Store user's starting address input
                MOVE.B  #2,D0                   ; Read user's input into A1; length is stored into D1
                TRAP    #15
                MOVE.B  #1,D6

VALIDATE_END    BRA     ATOI

ATOI            MOVE.B  (A1)+,D0    ; Move to next character in A1 and store in D0			
                CMP.B   #$30,D0
                BLT     INVALID
                CMP.B   #$39,D0
                BGT     ASCII_TO_HEX_LETTER
                SUB.B   #$30,D0     ; Subtract by 30 to get the numbers 0-9
                ADD.L   D0,D5
                SUBI    #1,D1       ; Decrement input's length to move to next character          
                CMP.B   #0,D1       ; Compare to see if we're at the last digit
                BEQ     LASTDIGITCHECK
                LSL.L   #4,D5
                BRA	    ATOI

  
ASCII_TO_HEX_LETTER     CMP.B   #$41,D0
                        BLT     INVALID
                        CMP.B   #$46, D0
                        BGT     INVALID 
                        SUB.B   #$31,D0     ; Subtract by 31 to get the numbers A-F
                        SUB.B   #6,D0
                        ADD.L   D0,D5
                        SUBI    #1,D1
                        BEQ     LASTDIGITCHECK
                        LSL.L   #4,D5
                        BRA     ATOI     

                    
INVALID     LEA     ERROR_MESSAGE, A1   ; Display error message
            MOVE.B  #14, D0
            TRAP    #15
            CLR.B   D6
 
                
LASTDIGITCHECK      MOVE.L  D5, D7  ; D7 used as temporary storage
                    LSR.B   #1, D7  ; Check for carry bit to see if last digit is odd
                    BCS     ODD
                    CLR.L   D7
                    CMP.B   #0,D6
                    BEQ     COMPLETE_STARTA  ; When even, go to prompt for end address
                    CMP.B   #1,D6
                    BEQ     COMPLETE_ENDA

COMPLETE_STARTA     MOVEA.L D5, A4  ; A4 holds the starting address.
                    CLR.L   D5 
                    BRA PROMPT_END


COMPLETE_ENDA       MOVEA.L D5, A6  ; A6 holds the ending address. 
                    BRA DECODE_MEMORY


ODD     LEA     ERROR_MESSAGE, A1 
        MOVE.B  #14, D0
        TRAP    #15

                              
DECODE_MEMORY                
          
                

    SIMHALT             ; halt simulator

* Put variables and constants here
   
CR              EQU         $0D
LF              EQU         $0A


WELCOME         DC.B        'Welcome to the 68k Disassembler of Avery and Alan',CR,LF,CR,LF,0


USER_INST       DC.B        'Please follow the proper input instructions below: ',CR,LF
                DC.B        '- Starting address must be lower than ending address.',CR,LF
                DC.B        '- The values for the starting and ending address must be an even value.',CR,LF
                DC.B        '- Starting and ending address must be inputted as hexadecimal value.',CR,LF
                DC.B        '- Do not put spaces in between input characters.',CR,LF
                DC.B        '- Valid characters include: 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, A, B, C, D, E, F',CR,LF,0

      
START_IN        DC.B        'Enter a starting address: ',CR,LF,0 
END_IN          DC.B        'Enter an ending address: ',CR,LF,0 
START_ADDRESS   DS.B        64     
END_ADDRESS     DS.B        64 
ERROR_MESSAGE   DC.B        'Error, the input is Invalid.',CR,LF,0       


    END    START        ; last line of source
