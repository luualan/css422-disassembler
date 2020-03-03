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
START:      JSR     DISP_W          ; Display Welcome Message. 
            JSR     DISP_UI         ; Display User Instructions.
            JSR     PROMPT_START    ; Prompt the user for starting address. 
            
*------------------------------------------------------------*
* D0: used for the tasks
* D1: used to hold the size of the input obtained. 
* D5: used to store the starting and ending address 
* temporarily before moving them to A4 and A6 correspondingly. 
* D6: used to check the last digit to see if the input 
* for the starting and ending address causes a bus error. 
* A1: a pointer to the message to print out. 
*------------------------------------------------------------*

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

* D0 stores the value to pushed from A1.

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
        
ITOA    MOVEM.L D0-D1, -(SP)
        CMP.B   #$00, D2
        BEQ     ITOA_BYTE
        CMP.B   #$01, D2
        BEQ     ITOA_WORD
        CMP.B   #$10, D2
        BEQ     ITOA_LONG
        JMP     ITOA_LONGADDRESS
        
ITOA_MOVE
        MOVEM.L D0-D1, -(SP)
        
        CMP.B   #%01, D2
        BEQ     ITOA_BYTE
        CMP.B   #%11, D2
        BEQ     ITOA_WORD
        CMP.B   #%10,D2
        BEQ     ITOA_LONG
        JMP     ITOA_LONGADDRESS

ITOA_BYTE
        MOVE.W  (A5)+,D7
        JSR     ITOA_BYTE_CONVERT
        JMP     ITOA_DONE
        
ITOA_WORD
        MOVE.W  (A5),D7
        MOVE.B  #right8, D1
        LSR.W   D1,D7
        JSR     ITOA_BYTE_CONVERT
        MOVE.W  (A5)+, D7
        JSR     ITOA_BYTE_CONVERT
        JMP     ITOA_DONE
        
ITOA_LONG
        MOVE.W  (A5), D7
        MOVE.B  #right8, D1
        LSR.W   D1, D7
        JSR     ITOA_BYTE_CONVERT
        MOVE.W  (A5)+, D7
        JSR     ITOA_BYTE_CONVERT
        
        MOVE.W  (A5), D7
        MOVE.B  #right8, D1
        LSR.W   D1, D7
        JSR     ITOA_BYTE_CONVERT
        MOVE.W  (A5)+, D7
        JSR     ITOA_BYTE_CONVERT
        JMP     ITOA_DONE

ITOA_LONGADDRESS
        MOVE.W  A5, A7
        MOVE.B  #right24, D1
        LSR.W   D1,D7
        JSR     ITOA_BYTE_CONVERT
        MOVE.W  A5,A7
        MOVE.B  #right16,D1
        LSR.W   D1,D7
        JSR     ITOA_BYTE_CONVERT
        MOVE.W  A5,D7
        MOVE.B  #right8, D1
        LSR.W   D1,D7
        JSR     ITOA_BYTE_CONVERT
        MOVE.W  A5,D7
        JSR     ITOA_BYTE_CONVERT   
        JMP     ITOA_DONE   

ITOA_BYTE_CONVERT
        MOVE.W  D7, D0 
        ANDI.W  #$F0, D0
        MOVE.B  #right4, D1
        LSR.W   D1, D0
        JSR     ITOA_NIBBLE_CONVERT
        
ITOA_NIBBLE_CONVERT
        CMP.B   #9, D0
        BGT     ITOA_CONVERT_A_TO_F
        ADD.B   #$30, D0
        MOVE.B  D0, (A2)+
        RTS
        
ITOA_CONVERT_A_TO_F
        SUBI.B  #10, D0
        ADDI.B  #$41, D0
        MOVE.B  D0, (A2)+
        RTS

ITOA_DONE
        MOVEM.L (SP)+, D0-D1
        RTS

*-------------------------------------------------------------------------------*

START_DECODING
        CLR.L   D2
        
DECODING_ITERATION
        ;decoding the current address
        JSR     DECODE_MEMORY
        MOVE.B  #task13, D0
        LEA     decoded_buffer, A1
        TRAP    #15
        
        ;check if decoding has finished or if the screen is filled. 
        CMP.L   A5, A6
        BLE     CONTINUE_OR_END
        ;have yet to reach the ending address
        ADDQ.B  #1, D2
        CMP.B   lines_p_screen, D2
        BGE     DECODE_PAUSE
        ;not yet reached the maximum lines per screen. 
        BRA     DECODING_ITERATION

DECODE_PAUSE
        MOVE.B  #task14, D0
        LEA     ENTER_PROMPT, A1
        TRAP    #15
        MOVE.B  #task5, D0
        TRAP    #15
        BRA     START_DECODING

CONTINUE_OR_END
        MOVE.B  #task14, D0
        LEA     PROMPT_AGAIN, A1
        TRAP    #15
        
        MOVE.B  #task2, D0
        LEA     ascii_y_n, A1
        TRAP    #15
        
        MOVE.B  ascii_y_n, D3
        CMPI.B  #y_uppercase, D3
        BEQ     PROMPT_START
        CMPI.B  #y_lowercase, D3
        BEQ     PROMPT_START
        CMPI.B  #n_uppercase, D3
        BEQ     EXIT
        CMPI.B  #n_lowercase, D3
        BEQ     EXIT

        BRA     CONTINUE_OR_END 
        
EXIT
        MOVE.B  #task14, D0
        LEA     EXIT_PROMPT, A1
        TRAP    #15
        
        MOVE.B  #task9, D0
        TRAP    #15

        
        
*---------------------------------------------------------------------------------*
* D0: the current instruction. 
* D1: 
* D2: data size / shift count
* D3: loop counter for the amount of lines per screen. 
* D4: 
* D5: 
* D6: 
* D7: 
* A0: 
* A1: A pointer to the message to print out. 
* A2: A pointer to the decode_buffer. 
* A3: 
* A4: Store the starting address and increment to the ending address. 
* A5: The current address. 
* A6: Store the ending address. 
* A7: Stack pointer. 
*---------------------------------------------------------------------------------*
                              
DECODE_MEMORY     

*Clear the data and address registers used to obtain the starting and ending address. 
        CLR.L   D0
        CLR.L   D5
        CLR.L   D6
        MOVEA   #0, A1
        
        MOVEM.L D2/A6, -(SP)
                
        ;zero clear the decode_buffer
        JSR     OP_CLEAR_DATA
        LEA     decoded_buffer, A2
                
        ;print out the current address
        MOVE.L  #$0003, D2
        JSR     ITOA
        MOVE.B  #$9, (A2)+
                
        ;load the next instruction and jump to the opcode table entry
        LEA     OP_TABLE, A0
        CLR.L   D0
        MOVE.W  (A5)+, D0
        MOVE.L  D0, D1
        MOVE.B  #right12, D2
        LSR.W   D2, D1
        MULU    #6, D1
        JMP     0(A0, D1)
OP_FINISH
        MOVEM.L (SP)+, D2/A6
        RTS

*------------------------------------------------------------------------------------*
        ;clear the 32 bits within the decoded_buffer       
OP_CLEAR_DATA
        CLR.L   D3
        MOVE.B  #buffer_size, D3
        LEA     decoded_buffer, A2
OP_CLEAR_DATA_LOOP
        MOVE.B  #0, (A2)+
        SUBI    #1, D3
        BGT     OP_CLEAR_DATA_LOOP
        RTS

*------------------------------------------------------------------------------------*

OP_TABLE
        JMP     code0000    ; ADDI.bwl/ ANDI.bwl / CMPI.bwl / EORI.bwl / ORI.bwl / SUBI.bwl 
        JMP     code0001    ; MOVE.b
        JMP     code0010    ; MOVE.l / MOVEA.l
        JMP     code0011    ; MOVE.w / MOVEA.w
        JMP     code0100    ; CLR.bwl / JMP / JSR / LEA / MOVEM.wl / NOP / NOT.bwl / RTS / STOP / TRAP
        JMP     code0101    ; ADDQ.bwl / SUBQ.bwl / Scc / Dbcc
        JMP     code0110    ; BRA.bw / BSR.bw / Bcc.bw
        JMP     code0111    ; MOVEQ
        JMP     code1000    ; DIVS / DIVU / CR.bwl
        JMP     code1001    ; SUB.bwl / SUBA.wl
        JMP     code1010    ;   [unassigned]
        JMP     code1011    ; CMP.bwl / CMPA.wl / EOR.bwl
        JMP     code1100    ; MULS / MULU / AND.bwl
        JMP     code1101    ; ADD.bwl / ADDA.wl / ADDX.bwl
        JMP     code1110    ; ASL.bwl / ASR.bwl / LSL.bwl / LSR.bwl / ROR.bwl / ROL.bwl
        JMP     code1111    ;   [unassigned]
        
code0000:                       ; Opcodes ADDI and SUBI
    MOVE.L  A5,D1               ; A5 is current instruction word
    ANDI.W  #second_nibble,D1   ; Extract 2nd nibble from instruction word
    MOVE.B  #right8,D2          ; Used to shift 8 times to right
    LSR.W   D2,D1               ; Shift nibble into LSB position
    MULU    #6, D1              ; Set displacement 
    LEA     OP_0000_TABLE,A0    ; Load table into A0
    JMP     0(A0,D1)            ; go to displacement (A0 + xxxx * 6)

code0001:                       ; Opcode MOVE.B
    BRA     OP_MOVE             ; Go to opcode MOVE

code0010:                       ; Opcodes MOVE.L and MOVEA.L 
    MOVE.L  A5,D1               ; A5 is current instruction word
    ANDI.W  #dst_mode,D1        ; Extract dst mode position from instruction word
    MOVE.B  #right6,D2          ; Used to shift 6 times to right
    LSR.W   D2,D1               ; Shift dst mode into LSB position
    CMP.B   #1, D1              ; When 001 in destination mode
    BEQ     OP_MOVEA            ; Go to opcode MOVEA
    BRA     OP_MOVE             ; Otherwise, go to opcode MOVE

code0011:                       ; Opcodes MOVE.W and MOVEA.W 
    MOVE.L  A5,D1               ; A5 is current instruction word
    ANDI.W  #dst_mode,D1        ; Extract dst mode position from instruction word
    MOVE.B  #right6,D2          ; Used to shift 6 times to right
    LSR.W   D2,D1               ; Shift dst mode into LSB position
    CMP.B   #1, D1              ; When 001 in destination mode
    BEQ     OP_MOVEA            ; Go to opcode MOVEA
    BRA     OP_MOVE             ; Otherwise, go to opcode MOVE

code0100:                       ; Opcodes CLR, JSR, LEA, MOVEM, NOP, RTS
; fill


code0101:                       ; Opcode ADDQ.B/W/L
    BRA     OP_ADDQ             ; Go to opcode ADDQ

code0110:                       ; Opcodes BRA and BSR
    MOVE.L  A5,D1               ; A5 is current instruction word
    ANDI.W  #second_nibble,D1   ; Extract 2nd 4 bits from instruction word
    MOVE.B  #right8,D2          ; Used to shift 8 times to right
    LSR.W   D2,D1               ; Shift nibble into LSB position
    CMP.B   #0, D1              ; When 0000 in destination mode
    BEQ     OP_BRA              ; Go to opcode BRA
    BRA     OP_BSR              ; Otherwise, go to opcode BSR

code0111:                       ; Opcode MOVEQ
    BRA     OP_MOVEQ            ; Go to opcode MOVEQ

code1000:                       ; Opcodes DIVU word and OR.B/W/L
    MOVE.L  A5,D1               ; A5 is current instruction word
    ANDI.W  #dst_mode,D1        ; Extract dst mode position from instruction word
    MOVE.B  #right6,D2          ; Used to shift 6 times to right
    LSR.W   D2,D1               ; Shift dst mode into LSB position
    CMP.B   #3, D1              ; When 011 in destination mode
    BEQ     OP_DIVU             ; Go to opcode DIVU word
    BRA     OP_OR               ; Otherwise, go to opcode OR

code1001:                       ; Opcode SUB.B/W/L
    BRA     OP_SUB              ; Go to opcode SUB   

code1010:                       ; Opcode not supported 
    BRA     OP_UNSUPPORTED      ; Go to opcode unsupported   
     
code1011:                       ; Opcode CMP.B/W/L
    BRA     OP_CMP              ; Go to opcode CMP

code1100:                       ; Opcodes MULS, MULU, AND.B/W/L

code1101:                       ; Opcodes ADD.B/W/L, ADDA.B/W/L

code1110:                       ; Opcodes ASL.B/W/L, ASR.B/W/L, LSL.B/W/L, LSR.B/W/L, ROL.B/W/L, ROR.B/W/L                       

code1111:                       ; Opcode not supported 
    BRA     OP_UNSUPPORTED      ; Go to opcode unsupported   
    
    
        
OP_0000_TABLE:
    JMP     OP_UNSUPPORTED  ; 0 
    JMP     OP_UNSUPPORTED  ; 1
    JMP     OP_UNSUPPORTED  ; 2
    JMP     OP_UNSUPPORTED  ; 3
    JMP     OP_SUBI         ; 4 Go to opcode SUBI
    JMP     OP_UNSUPPORTED  ; 5
    JMP     OP_ADDI         ; 6 Go to opcode ADDI
    JMP     OP_UNSUPPORTED  ; 7
    JMP     OP_UNSUPPORTED  ; 8
    JMP     OP_UNSUPPORTED  ; 9
    JMP     OP_UNSUPPORTED  ; A
    JMP     OP_UNSUPPORTED  ; B
    JMP     OP_UNSUPPORTED  ; C
    JMP     OP_UNSUPPORTED  ; D
    JMP     OP_UNSUPPORTED  ; E
    JMP     OP_UNSUPPORTED  ; F
    

 OP_0100_TABLE:
    JMP     OP_UNSUPPORTED      ; 0 
    JMP     OP_LEA              ; 1
    JMP     OP_CLR              ; 2
    JMP     OP_LEA              ; 3
    JMP     OP_UNSUPPORTED      ; 4 Go to opcode SUBI
    JMP     OP_LEA              ; 5
    JMP     OP_ADDI             ; 6 Go to opcode ADDI
    JMP     OP_LEA              ; 7
    JMP     OP_MOVEM            ; 8
    JMP     OP_LEA              ; 9 
    JMP     OP_UNSUPPORTED      ; A
    JMP     OP_LEA              ; B
    JMP     OP_MOVEM            ; C
    JMP     OP_LEA              ; D
    JMP     CHECK_NIBBLE_TWO    ; E JSR, NOP, or RTS
    JMP     OP_UNSUPPORTED      ; F  


    SIMHALT             ; halt simulator

* Put variables and constants here
   
CR              EQU         $0D
LF              EQU         $0A
stack           EQU         $000A0000
buffer_size     EQU         64 
decoded_buffer  EQU         32
lines_p_screen  EQU         20
right4          EQU         4
right8          EQU         8
right12         EQU         12
right16         EQU         16
right24         EQU         24
ascii_y_n       DC.B        32
y_uppercase     EQU         $59         
y_lowercase     EQU         $79
n_uppercase     EQU         $4E
n_lowercase     EQU         $6E
task2           EQU         $02
task5           EQU         $05
task9           EQU         $09
task13          EQU         $0D
task14          EQU         $0E
first_nibble    EQU         $F000
second_nibble   EQU         $0F00   
third_nibble    EQU         $00F0
fourth_nibble   EQU         $000F
dst_mode        EQU         $00C0
dst_reg         EQU         $0E00
src_mode        EQU         $0018
src_reg         EQU         $0007
bit8            EQU         $0100


WELCOME         DC.B        'Welcome to the 68k Disassembler of Avery and Alan',CR,LF,CR,LF,0

USER_INST       DC.B        'Please follow the proper input instructions below: ',CR,LF
                DC.B        '- Starting address must be lower than ending address.',CR,LF
                DC.B        '- The values for the starting and ending address must be an even value.',CR,LF
                DC.B        '- Starting and ending address must be inputted as hexadecimal value.',CR,LF
                DC.B        '- Do not put spaces in between input characters.',CR,LF
                DC.B        '- Valid characters include: 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, A, B, C, D, E, F',CR,LF,0
                
ENTER_PROMPT    DC.B        'Press enter to continue...',CR,LF,0
PROMPT_AGAIN    DC.B        'Press Y to continue / N to exit.',CR,LF,0
EXIT_PROMPT     DC.B        'Program has execution has stopped.',CR,LF,0

      
START_IN        DC.B        'Enter a starting address: ',CR,LF,0 
END_IN          DC.B        'Enter an ending address: ',CR,LF,0 
START_ADDRESS   DS.B        64     
END_ADDRESS     DS.B        64 
ERROR_MESSAGE   DC.B        'Error, the input is Invalid.',CR,LF,0       


    END    START        ; last line of source




*~Font name~Courier New~
*~Font size~10~
*~Tab type~1~
*~Tab size~4~
