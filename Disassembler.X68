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

       
PROMPT_START    LEA     stack, SP          ; SP = stack ($A0000)
                LEA     START_IN,A1        ; Display starting address message
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
                     MOVEA.L A4, A5  ; Store starting address into current address
                    BRA DECODE_MEMORY


ODD     LEA     ERROR_MESSAGE, A1 
        MOVE.B  #14, D0
        TRAP    #15

*--------------------------------------------------------------------------------------
* param D2 data size to convert into ASCII
* param A2 a pointer to decode_buf
* param A5 the current address
* itoa (D2, A2, A5) {
* D0 byte data in ACII
* D1 #sfhit
* D7 long data to convert into ASCII
* }
        
ITOA    
        MOVEM.L D0-D1,-(SP) ; convert integer to ASCII
        
        CMP.B   #%00, D2    ; byte
        BEQ     ITOA_BYTE
        CMP.B   #%01, D2    ; word
        BEQ     ITOA_WORD
        CMP.B   #%10, D2    ; long
        BEQ     ITOA_LONG
        JMP     ITOA_LONGADDRESS    ; long address
        
ITOA_MOVE
        MOVEM.L D0-D1,-(SP)

        CMP.B   #%01, D2    ; byte
        BEQ     ITOA_BYTE
        CMP.B   #%11, D2    ; word
        BEQ     ITOA_WORD
        CMP.B   #%10,D2     ; long
        BEQ     ITOA_LONG
        JMP     ITOA_LONGADDRESS ; long address

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
        MOVE.W  (A5),D7
        MOVE.B  #right8, D1
        LSR.W   D1, D7
        JSR     ITOA_BYTE_CONVERT
        MOVE.W  (A5)+, D7
        JSR     ITOA_BYTE_CONVERT
        
        MOVE.W  (A5),D7
        MOVE.B  #right8, D1
        LSR.W   D1, D7
        JSR     ITOA_BYTE_CONVERT
        MOVE.W  (A5)+, D7
        JSR     ITOA_BYTE_CONVERT
        JMP     ITOA_DONE

ITOA_LONGADDRESS
        MOVE.W  A5,D7
        MOVE.B  #right24,D1
        LSR.W   D1,D7
        JSR     ITOA_BYTE_CONVERT
        MOVE.W  A5,D7
        MOVE.B  #right16,D1
        LSR.W   D1,D7
        JSR     ITOA_BYTE_CONVERT
        MOVE.W  A5,D7
        MOVE.B  #right8,D1
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
        
        MOVE.W  D7, D0
        ANDI.W  #$0F, D0
        JSR     ITOA_NIBBLE_CONVERT
        RTS
        
ITOA_NIBBLE_CONVERT
        CMP.B   #9, D0
        BGT     ITOA_CONVERT_A_TO_F
        ADD.B   #$30, D0
        MOVE.B  D0, (A2)+   ; store D0 into decode buffer
        RTS
        
ITOA_CONVERT_A_TO_F
        SUBI.B  #10, D0
        ADDI.B  #$41, D0
        MOVE.B  D0, (A2)+   ; store D0 into decode buffer
        RTS

ITOA_DONE
        MOVEM.L (SP)+, D0-D1
        BRA DO

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
        LEA     decoded_buffer, A2  Load decode buffer into A2
                
        ;print out the current address
        MOVE.L  #$0003, D2
        BRA      ITOA
        
DO      MOVE.B  #$9, (A2)+  ; Add space after long address
                
        ;load the next instruction and jump to the opcode table entry
        LEA     OP_TABLE, A0
        CLR.L   D0
        MOVE.W  (A5)+, D0       ; increment A5 store value into D0
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
        
code0000:                           ; Opcodes ADDI and SUBI
        MOVE.L  D0,D1               ; D0 is current instruction word
        ANDI.W  #second_nibble,D1   ; Extract 2nd nibble from instruction word
        MOVE.B  #right8,D2          ; Used to shift 8 times to right
        LSR.W   D2,D1               ; Shift nibble into LSB position
        MULU    #6, D1              ; Set displacement 
        LEA     OP_0000_TABLE,A0    ; Load table into A0
        JMP     0(A0,D1)            ; go to displacement (A0 + xxxx * 6)

code0001:                           ; Opcode MOVE.B
        BRA     OP_MOVE             ; Go to opcode MOVE

code0010:                           ; Opcodes MOVE.L and MOVEA.L 
        MOVE.L  D0,D1               ; D0 is current instruction word
        ANDI.W  #dst_mode,D1        ; Extract dst mode position from instruction word
        MOVE.B  #right6,D2          ; Used to shift 6 times to right
        LSR.W   D2,D1               ; Shift dst mode into LSB position
        CMP.B   #1, D1              ; When 001 in destination mode
        BEQ     OP_MOVEA            ; Go to opcode MOVEA
        BRA     OP_MOVE             ; Otherwise, go to opcode MOVE

code0011:                           ; Opcodes MOVE.W and MOVEA.W 
        MOVE.L  D0,D1               ; D0 is current instruction word
        ANDI.W  #dst_mode,D1        ; Extract dst mode position from instruction word
        MOVE.B  #right6,D2          ; Used to shift 6 times to right
        LSR.W   D2,D1               ; Shift dst mode into LSB position
        CMP.B   #1, D1              ; When 001 in destination mode
        BEQ     OP_MOVEA            ; Go to opcode MOVEA
        BRA     OP_MOVE             ; Otherwise, go to opcode MOVE

code0100:                           ; Opcodes CLR, JSR, LEA, MOVEM, NOP, RTS
        MOVE.L  D0,D1               ; D0 is current instruction word
        ANDI.W  #second_nibble,D1   ; Extract 2nd nibble from instruction word
        MOVE.B  #right8,D2          ; Used to shift 8 times to right
        LSR.W   D2,D1               ; Shift nibble into LSB position
        MULU    #6, D1              ; Set displacement 
        LEA     OP_0100_TABLE,A0    ; Load table into A0
        JMP     0(A0,D1)            ; go to displacement (A0 + xxxx * 6)

code0101:                           ; Opcode ADDQ.B/W/L
        BRA     OP_ADDQ             ; Go to opcode ADDQ

code0110:                           ; Opcodes BRA and BSR
        MOVE.L  D0,D1               ; D0 is current instruction word
        ANDI.W  #second_nibble,D1   ; Extract 2nd 4 bits from instruction word
        MOVE.B  #right8,D2          ; Used to shift 8 times to right
        LSR.W   D2,D1               ; Shift nibble into LSB position
        CMP.B   #0, D1              ; When 0000 in destination mode
        BEQ     OP_BRA              ; Go to opcode BRA
        BRA     OP_BSR              ; Otherwise, go to opcode BSR

code0111:                           ; Opcode MOVEQ
        BRA     OP_MOVEQ            ; Go to opcode MOVEQ

code1000:                           ; Opcodes DIVU word and OR.B/W/L
        MOVE.L  D0,D1               ; D0 is current instruction word
        ANDI.W  #dst_mode,D1        ; Extract dst mode position from instruction word
        MOVE.B  #right6,D2          ; Used to shift 6 times to right
        LSR.W   D2,D1               ; Shift dst mode into LSB position
        CMP.B   #3, D1              ; When 011 in destination mode
        BEQ     OP_DIVU             ; Go to opcode DIVU word
        BRA     OP_OR               ; Otherwise, go to opcode OR

code1001:                           ; Opcode SUB.B/W/L
        BRA     OP_SUB              ; Go to opcode SUB   

code1010:                           ; Opcode not supported 
        BRA     OP_UNSUPPORTED      ; Go to opcode unsupported   
     
code1011:                           ; Opcode CMP.B/W/L
        BRA     OP_CMP              ; Go to opcode CMP

code1100:                           ; Opcodes MULS, MULU, AND.B/W/L
        MOVE.L  D0,D1               ; D0 is current instruction word
        ANDI.W  #dst_mode,D1        ; Extract dst mode position from instruction word
        MOVE.B  #right6,D2          ; Used to shift 6 times to right
        LSR.W   D2,D1               ; Shift dst mode into LSB position
        MULU    #6, D1              ; Set displacement 
        LEA     OP_1100_TABLE,A0    ; Load table into A0
        JMP     0(A0,D1)            ; go to displacement (A0 + xxxx * 6)

code1101:                           ; Opcodes ADD.B/W/L, ADDA.B/W/L
        MOVE.L  D0,D1               ; D0 is current instruction word
        ANDI.W  #dst_mode,D1        ; Extract dst mode position from instruction word
        MOVE.B  #right6,D2          ; Used to shift 6 times to right
        LSR.W   D2,D1               ; Shift dst mode into LSB position
        MULU    #6, D1              ; Set displacement 
        LEA     OP_1101_TABLE,A0    ; Load table into A0
        JMP     0(A0,D1)            ; go to displacement (A0 + xxxx * 6)

code1110:                           ; Opcodes ASL.B/W/L, ASR.B/W/L, LSL.B/W/L, LSR.B/W/L, ROL.B/W/L, ROR.B/W/L   
        MOVE.L  D0,D1               ; D0 is current instruction word
        ANDI.W  #dst_mode,D1        ; Extract 8-6 bits from instruction word
        MOVE.B  #right6,D2          ; Used to shift 6 times to right
        LSR.W   D2,D1               ; Shift dst mode into LSB position
   
        ; Check Memory Shifts
        CMP.B   #7, D1              ; When 111
        BEQ     MEMORY_1110_LEFT    ; Go to Memory Shift Left Side
    
        CMP.B   #3, D1              ; When 011
        BEQ     MEMORY_1110_RIGHT   ; Go Memory Shift Right Side
    
        ; Check Register Shifts
        MOVE.L  D0,D1                       ; D0 is current instruction word
        ANDI.W  #src_mode,D1                ; Extract 5-3 bits from instruction word
        MOVE.B  #right3,D2                  ; Used to shift 3 times to right
        LSR.W   D2,D1                       ; Shift 5-3 bits into LSB position
        MULU    #6, D1                      ; Set displacement 
        LEA     OP_1110_TABLE_REGISTER,A0   ; Load table into A0
        JMP     0(A0,D1)                    ; go to displacement (A0 + xxxx * 6)

MEMORY_1110_LEFT:    
        MOVE.L  D0,D1               ; D0 is current instruction word
        ANDI.W  #dst_reg,D1         ; Extract 11-9 position from instruction word
        MOVE.B  #right9,D2          ; Used to shift 9 times to right
        LSR.W   D2,D1               ; Shift dst reg into LSB position
        CMP.B   #0,D1               ; When D1 is 0
        BEQ     OP_ASL              ; Go to opcode ASL
        CMP.B   #1, D1              ; when D1 is 1
        BEQ     OP_LSL              ; Go to opcode LSL
        CMP.B   #3, D1              ; When D1 is 3
        BEQ     OP_ROL              ; Go to opcode ROL

MEMORY_1110_RIGHT:
        MOVE.L  D0,D1               ; D0 is current instruction word
        ANDI.W  #dst_reg,D1         ; Extract 11-9 position from instruction word
        MOVE.B  #right9,D2          ; Used to shift 9 times to right
        LSR.W   D2,D1               ; Shift dst reg into LSB position
        CMP.B   #0,D1               ; When D1 is 0
        BEQ     OP_ASR              ; Go to opcode ASR
        CMP.B   #1, D1              ; when D1 is 1
        BEQ     OP_LSR              ; Go to opcode LSR
        CMP.B   #3, D1              ; When D1 is 3
        BEQ     OP_ROR              ; Go to opcode ROR

code1111:                           ; Opcode not supported 
        BRA     OP_UNSUPPORTED      ; Go to opcode unsupported   
         
OP_0000_TABLE:
        JMP     OP_UNSUPPORTED  ; 0 Go to opcode unsupported  
        JMP     OP_UNSUPPORTED  ; 1 Go to opcode unsupported  
        JMP     OP_UNSUPPORTED  ; 2 Go to opcode unsupported  
        JMP     OP_UNSUPPORTED  ; 3 Go to opcode unsupported  
        JMP     OP_SUBI         ; 4 Go to opcode SUBI
        JMP     OP_UNSUPPORTED  ; 5 Go to opcode unsupported  
        JMP     OP_ADDI         ; 6 Go to opcode ADDI
        JMP     OP_UNSUPPORTED  ; 7 Go to opcode unsupported  
        JMP     OP_UNSUPPORTED  ; 8 Go to opcode unsupported  
        JMP     OP_UNSUPPORTED  ; 9 Go to opcode unsupported  
        JMP     OP_UNSUPPORTED  ; A Go to opcode unsupported  
        JMP     OP_UNSUPPORTED  ; B Go to opcode unsupported  
        JMP     OP_UNSUPPORTED  ; C Go to opcode unsupported  
        JMP     OP_UNSUPPORTED  ; D Go to opcode unsupported  
        JMP     OP_UNSUPPORTED  ; E Go to opcode unsupported  
        JMP     OP_UNSUPPORTED  ; F Go to opcode unsupported  
    
OP_0100_TABLE:
        JMP     OP_UNSUPPORTED      ; 0 Go to opcode unsupported  
        JMP     OP_LEA              ; 1 Go to opcode LEA
        JMP     OP_CLR              ; 2 Go to opcode CLR
        JMP     OP_LEA              ; 3 Go to opcode LEA
        JMP     OP_UNSUPPORTED      ; 4 Go to opcode unsupported  
        JMP     OP_LEA              ; 5 Go to opcode LEA
        JMP     OP_ADDI             ; 6 Go to opcode ADDI
        JMP     OP_LEA              ; 7 Go to opcode LEA
        JMP     OP_MOVEM            ; 8 Go to opcode MOVEM
        JMP     OP_LEA              ; 9 Go to opcode LEA
        JMP     OP_UNSUPPORTED      ; A Go to opcode unsupported  
        JMP     OP_LEA              ; B Go to opcode LEA
        JMP     OP_MOVEM            ; C Go to opcode MOVEM
        JMP     OP_LEA              ; D Go to opcode LEA
        JMP     JSR_NOP_RTS         ; E Go to opcode JSR, NOP, or RTS
        JMP     OP_UNSUPPORTED      ; F Go to opcode unsupported  
    
OP_1100_TABLE:
        JMP     OP_AND              ; 0 Go to opcode AND 
        JMP     OP_AND              ; 1 Go to opcode AND
        JMP     OP_AND              ; 2 Go to opcode AND
        JMP     OP_MULU             ; 3 Go to opcode MULU
        JMP     OP_AND              ; 4 Go to opcode AND 
        JMP     OP_AND              ; 5 Go to opcode AND
        JMP     OP_AND              ; 6 Go to opcode AND
        JMP     OP_MULS             ; 7 Go to opcode MULS
        JMP     OP_UNSUPPORTED      ; 8 Go to opcode unsupported  
        JMP     OP_UNSUPPORTED      ; 9 Go to opcode unsupported  
        JMP     OP_UNSUPPORTED      ; A Go to opcode unsupported  
        JMP     OP_UNSUPPORTED      ; B Go to opcode unsupported  
        JMP     OP_UNSUPPORTED      ; C Go to opcode unsupported  
        JMP     OP_UNSUPPORTED      ; D Go to opcode unsupported  
        JMP     OP_UNSUPPORTED      ; E Go to opcode unsupported  
        JMP     OP_UNSUPPORTED      ; F Go to opcode unsupported  
    
OP_1101_TABLE:
        JMP     OP_ADD              ; 0 Go to opcode ADD 
        JMP     OP_ADD              ; 1 Go to opcode ADD
        JMP     OP_ADD              ; 2 Go to opcode ADD
        JMP     OP_ADDA             ; 3 Go to opcode ADDA
        JMP     OP_ADD              ; 4 Go to opcode ADD 
        JMP     OP_ADD              ; 5 Go to opcode ADD
        JMP     OP_ADD              ; 6 Go to opcode ADD
        JMP     OP_ADDA             ; 7 Go to opcode ADDA
        JMP     OP_UNSUPPORTED      ; 8 Go to opcode unsupported  
        JMP     OP_UNSUPPORTED      ; 9 Go to opcode unsupported  
        JMP     OP_UNSUPPORTED      ; A Go to opcode unsupported  
        JMP     OP_UNSUPPORTED      ; B Go to opcode unsupported  
        JMP     OP_UNSUPPORTED      ; C Go to opcode unsupported  
        JMP     OP_UNSUPPORTED      ; D Go to opcode unsupported  
        JMP     OP_UNSUPPORTED      ; E Go to opcode unsupported  
        JMP     OP_UNSUPPORTED      ; F Go to opcode unsupported  
    
OP_1110_TABLE_REGISTER:
        JMP     OP_ASR              ; 0 Go to opcode ASR
        JMP     OP_LSR              ; 1 Go to opcode LSR
        JMP     OP_UNSUPPORTED      ; 2 Go to opcode unsupported  
        JMP     OP_ROR              ; 3 Go to opcode ROR
        JMP     OP_ASL              ; 4 Go to opcode ASL 
        JMP     OP_LSL              ; 5 Go to opcode LSL
        JMP     OP_UNSUPPORTED      ; 6 Go to opcode unsupported 
        JMP     OP_ROL              ; 7 Go to opcode ROL
        JMP     OP_UNSUPPORTED      ; 8 Go to opcode unsupported  
        JMP     OP_UNSUPPORTED      ; 9 Go to opcode unsupported  
        JMP     OP_UNSUPPORTED      ; A Go to opcode unsupported  
        JMP     OP_UNSUPPORTED      ; B Go to opcode unsupported  
        JMP     OP_UNSUPPORTED      ; C Go to opcode unsupported  
        JMP     OP_UNSUPPORTED      ; D Go to opcode unsupported  
        JMP     OP_UNSUPPORTED      ; E Go to opcode unsupported  
        JMP     OP_UNSUPPORTED      ; F Go to opcode unsupported  

JSR_NOP_RTS:
        MOVE.L  D0,D1               ; D0 is current instruction word
        ANDI.W  #dst_mode,D1        ; Extract dst mode position from instruction word
        MOVE.B  #right6,D2          ; Used to shift 6 times to right
        LSR.W   D2,D1               ; Shift dst mode into LSB position
        CMP.B   #2, D1              ; When 010 in destination mode
        BEQ     OP_JSR              ; Go to opcode JSR
        MOVE.L  D0,D1               ; D0 is current instruction word
        ANDI.W  #src_reg ,D1        ; Extract src reg position from instruction word
        CMP.B   #1, D1              ; When 001 in src register
        BEQ     OP_NOP              ; Go to opcode NOP
        CMP.B   #5, D1              ; When 005 in src register
        BEQ     OP_RTS              ; Go to opcode RTS
        BRA     OP_UNSUPPORTED      ; Otherwise, go to opcode unsupported 

OP_UNSUPPORTED
        LEA     ERROR_MESSAGE, A1 
        MOVE.B  #14, D0
        TRAP    #15
        BRA     DONE
        
*----------------------------------------------------------------------------------------------*
* param D0 the current instruction in word
* param D1 the EA type
* param A2 a pointer to the decode_buffer
* param A5 current address
* ea_start(D0, D1, A2, A5){
* D2: size
* D3: src moe, dst mode
* D4: src regs, dst regs
* D5: #shifts
* D7: immediate data
* A0: EA_TYPE_TABLE
*       0 = ea_immediate
* }

*----------------------------------------------------------------------------------------------*
* First 4 bits: 0000

OP_SUBI
        MOVE.B  #'S', (A2)+
        MOVE.B  #'U', (A2)+
        MOVE.B  #'B', (A2)+
        MOVE.B  #'I', (A2)+
        MOVE.L  #ea_type_immediate, D1
        JSR     EA_START
        JMP     OP_FINISH
        
OP_ADDI
        MOVE.B  #'A', (A2)+
        MOVE.B  #'D', (A2)+
        MOVE.B  #'D', (A2)+
        MOVE.B  #'I', (A2)+
        MOVE.L  #ea_type_immediate, D1
        JSR     EA_START
        JMP     OP_FINISH

*-----------------------------------------------------------------------------------------------*
* First 4 bits: 0001
OP_MOVEA
        MOVE.B  #'M', (A2)+
        MOVE.B  #'O', (A2)+
        MOVE.B  #'V', (A2)+
        MOVE.B  #'E', (A2)+
        MOVE.B  #'A', (A2)+
        MOVE.L  #ea_type_immediate, D1
        JSR     EA_START
        JMP     OP_FINISH

*------------------------------------------------------------------------------------------------*
* First 4 bits: 0011
OP_MOVE
        MOVE.B  #'M', (A2)+
        MOVE.B  #'O', (A2)+
        MOVE.B  #'V', (A2)+
        MOVE.B  #'E', (A2)+
        MOVE.L  #ea_type_immediate, D1
        JSR     EA_START
        JMP     OP_FINISH

*------------------------------------------------------------------------------------------------*
* First 4 bits: 0100
OP_CLR
        MOVE.B  #'C', (A2)+
        MOVE.B  #'L', (A2)+
        MOVE.B  #'R', (A2)+
        MOVE.L  #ea_type_immediate, D1
        JSR     EA_START
        JMP     OP_FINISH
        
OP_NOP
        MOVE.B  #'N', (A2)+
        MOVE.B  #'O', (A2)+
        MOVE.B  #'P', (A2)+
        MOVE.L  #ea_type_immediate, D1
        JSR     EA_START
        JMP     OP_FINISH
        
OP_RTS
        MOVE.B  #'R', (A2)+
        MOVE.B  #'T', (A2)+
        MOVE.B  #'S', (A2)+
        MOVE.L  #ea_type_immediate, D1
        JSR     EA_START
        JMP     OP_FINISH
        
OP_JSR
        MOVE.B  #'J', (A2)+
        MOVE.B  #'S', (A2)+
        MOVE.B  #'R', (A2)+
        MOVE.L  #ea_type_immediate, D1
        JSR     EA_START
        JMP     OP_FINISH

OP_MOVEM
        MOVE.B  #'M', (A2)+
        MOVE.B  #'O', (A2)+
        MOVE.B  #'V', (A2)+
        MOVE.B  #'E', (A2)+
        MOVE.B  #'M', (A2)+
        MOVE.L  #ea_type_immediate, D1
        JSR     EA_START
        JMP     OP_FINISH
        
OP_LEA
        MOVE.B  #'L', (A2)+
        MOVE.B  #'E', (A2)+
        MOVE.B  #'A', (A2)+
        MOVE.L  #ea_type_immediate, D1
        JSR     EA_START
        JMP     OP_FINISH

*------------------------------------------------------------------------------------------------*
* First 4 bits: 0101
OP_ADDQ
        MOVE.B  #'A', (A2)+
        MOVE.B  #'D', (A2)+
        MOVE.B  #'D', (A2)+
        MOVE.B  #'Q', (A2)+
        MOVE.L  #ea_type_immediate, D1
        JSR     EA_START
        JMP     OP_FINISH
        
*------------------------------------------------------------------------------------------------*
* First 4 bits: 0110
OP_BRA
        MOVE.B  #'B', (A2)+
        MOVE.B  #'R', (A2)+
        MOVE.B  #'A', (A2)+
        MOVE.L  #ea_type_immediate, D1
        JSR     EA_START
        JMP     OP_FINISH

OP_BCC
        MOVE.B  #'B', (A2)+
        MOVE.B  #'C', (A2)+
        MOVE.B  #'C', (A2)+
        MOVE.L  #ea_type_immediate, D1
        JSR     EA_START
        JMP     OP_FINISH
        
OP_BGT
        MOVE.B  #'B', (A2)+
        MOVE.B  #'G', (A2)+
        MOVE.B  #'T', (A2)+
        MOVE.L  #ea_type_immediate, D1
        JSR     EA_START
        JMP     OP_FINISH

OP_BLE
        MOVE.B  #'B', (A2)+
        MOVE.B  #'L', (A2)+
        MOVE.B  #'E', (A2)+
        MOVE.L  #ea_type_immediate, D1
        JSR     EA_START
        JMP     OP_FINISH
        
OP_BSR
        MOVE.B  #'B', (A2)+
        MOVE.B  #'S', (A2)+
        MOVE.B  #'R', (A2)+
        MOVE.L  #ea_type_immediate, D1
        JSR     EA_START
        JMP     OP_FINISH
*------------------------------------------------------------------------------------------------*
* First 4 bits: 0111
OP_MOVEQ
        MOVE.B  #'M', (A2)+
        MOVE.B  #'O', (A2)+
        MOVE.B  #'V', (A2)+
        MOVE.B  #'V', (A2)+
        MOVE.B  #'E', (A2)+
        MOVE.B  #'Q', (A2)+
        MOVE.L  #ea_type_immediate, D1
        JSR     EA_START
        JMP     OP_FINISH
        
*------------------------------------------------------------------------------------------------*
* First 4 bits: 1000
OP_DIVU
        MOVE.B  #'D', (A2)+
        MOVE.B  #'I', (A2)+
        MOVE.B  #'V', (A2)+
        MOVE.B  #'U', (A2)+
        MOVE.L  #ea_type_immediate, D1
        JSR     EA_START
        JMP     OP_FINISH
  
OP_OR
        MOVE.B  #'O', (A2)+
        MOVE.B  #'R', (A2)+
        MOVE.L  #ea_type_immediate, D1
        JSR     EA_START
        JMP     OP_FINISH

*------------------------------------------------------------------------------------------------*
* First 4 bits: 1001
OP_SUB
        MOVE.B  #'S', (A2)+
        MOVE.B  #'U', (A2)+
        MOVE.B  #'B', (A2)+
        MOVE.L  #ea_type_immediate, D1
        JSR     EA_START
        JMP     OP_FINISH
        
*------------------------------------------------------------------------------------------------*
* First 4 bits: 1011
OP_CMP
        MOVE.B  #'C', (A2)+
        MOVE.B  #'M', (A2)+
        MOVE.B  #'P', (A2)+
        MOVE.L  #ea_type_immediate, D1
        JSR     EA_START
        JMP     OP_FINISH
        
*------------------------------------------------------------------------------------------------*
* First 4 bits: 1100
OP_MULU
        MOVE.B  #'M', (A2)+
        MOVE.B  #'U', (A2)+
        MOVE.B  #'L', (A2)+
        MOVE.B  #'U', (A2)+
        MOVE.L  #ea_type_immediate, D1
        JSR     EA_START
        JMP     OP_FINISH
        
OP_MULS
        MOVE.B  #'M', (A2)+
        MOVE.B  #'U', (A2)+
        MOVE.B  #'L', (A2)+
        MOVE.B  #'S', (A2)+
        MOVE.L  #ea_type_immediate, D1
        JSR     EA_START
        JMP     OP_FINISH
        
OP_AND
        MOVE.B  #'A', (A2)+
        MOVE.B  #'N', (A2)+
        MOVE.B  #'D', (A2)+
        MOVE.L  #ea_type_immediate, D1
        JSR     EA_START
        JMP     OP_FINISH
        
*------------------------------------------------------------------------------------------------*
* First 4 bits: 1101
OP_ADD
        MOVE.B  #'A', (A2)+
        MOVE.B  #'D', (A2)+
        MOVE.B  #'D', (A2)+
        MOVE.L  #ea_type_immediate, D1
        JSR     EA_START
        JMP     OP_FINISH

OP_ADDA
        MOVE.B  #'A', (A2)+
        MOVE.B  #'D', (A2)+
        MOVE.B  #'D', (A2)+
        MOVE.B  #'A', (A2)+
        MOVE.L  #ea_type_immediate, D1
        JSR     EA_START
        JMP     OP_FINISH
        
*------------------------------------------------------------------------------------------------*
* First 4 bits: 1110
OP_ASR
        MOVE.B  #'A', (A2)+
        MOVE.B  #'S', (A2)+
        MOVE.B  #'R', (A2)+
        MOVE.L  #ea_type_immediate, D1
        JSR     EA_START
        JMP     OP_FINISH
OP_ASL
        MOVE.B  #'A', (A2)+
        MOVE.B  #'S', (A2)+
        MOVE.B  #'L', (A2)+
        MOVE.L  #ea_type_immediate, D1
        JSR     EA_START
        JMP     OP_FINISH
        
OP_LSR
        MOVE.B  #'L', (A2)+
        MOVE.B  #'S', (A2)+
        MOVE.B  #'R', (A2)+
        MOVE.L  #ea_type_immediate, D1
        JSR     EA_START
        JMP     OP_FINISH
       
OP_LSL
        MOVE.B  #'L', (A2)+
        MOVE.B  #'S', (A2)+
        MOVE.B  #'L', (A2)+
        MOVE.L  #ea_type_immediate, D1
        JSR     EA_START
        JMP     OP_FINISH
        
OP_ROR
        MOVE.B  #'R', (A2)+
        MOVE.B  #'O', (A2)+
        MOVE.B  #'R', (A2)+
        MOVE.L  #ea_type_immediate, D1
        JSR     EA_START
        JMP     OP_FINISH
        
OP_ROL
        MOVE.B  #'R', (A2)+
        MOVE.B  #'O', (A2)+
        MOVE.B  #'L', (A2)+
        MOVE.L  #ea_type_immediate, D1
        JSR     EA_START
        JMP     OP_FINISH
        
*-----------------------------------------------------------------------*
        
EA_START
        MOVEM.L D2-D4/A0-A1, -(SP)
        
        LEA     EA_TYPE_TABLE, A0
        MULU    #6, D1
        JMP     0(A0, D1)
        
EA_FINISH
        MOVEM.L (SP)+, D2-D4/A0-A1
        RTS
        
EA_TYPE_TABLE
        JMP     EA_IMMEDIATE    ; 0: ea_immediate
        JMP     EA_MOVE         ; 1: ea_move
        JMP     EA_MOVEA        ; 2: ea_movea
        JMP     EA_LEA          ; 3: ea_lea
        JMP     EA_DSTONLY      ; 4: ea_dstonly
        JMP     EA_EXT          ; 5: ea_ext
        JMP     EA_MOVEM        ; 6: ea_movem
        JMP     EA_TRAP         ; 7: ea_trap
        JMP     EA_QUICK        ; 8: ea_quick
        JMP     EA_branch       ; 9: ea_branch
        JMP     EA_FINISH
        
EA_SIZE_IMMEDIATE
        CMP.B   #%00, D2        ; .b
        BEQ     EA_SIZE_B       
        CMP.B   #%01, D2        ; .w
        BEQ     EA_SIZE_W       
        CMP.B   #%10, D2        ; .l
        BEQ     EA_SIZE_L
        JMP     EA_WRONGSIZE    ; wrong size

EA_SIZE_MOVE
        CMP.B   #%01, D2        ; .b
        BEQ     EA_SIZE_B       
        CMP.B   #%11, D2        ; .w
        BEQ     EA_SIZE_W       
        CMP.B   #%10, D2        ; .l
        BEQ     EA_SIZE_L
        JMP     EA_WRONGSIZE    ; wrong size

EA_SIZE_B
        MOVE.B  #'.', (A2)+
        MOVE.B  #'B', (A2)+
        RTS
EA_SIZE_W
        MOVE.B  #'.', (A2)+
        MOVE.B  #'W', (A2)+
        RTS
EA_SIZE_L
        MOVE.B  #'.', (A2)+
        MOVE.B  #'L', (A2)+
        RTS
EA_SIZE_DONE
        RTS
        
EA_IMMEDIATE    ; 0 ea_immediate
        MOVE.L  D0, D1
        ANDI.W  #dst_mode, D1
        MOVE.B  #right6, D2
        LSR.W   D2, D1
        ANDI.B  #3, D1
        MOVE.B  D1, D2
        JSR     EA_SIZE_IMMEDIATE

        MOVE.L  D0, D3          ; Store the dst mode in D3
        ANDI.W  #dst_mode, D3    ; get bits 5-3
        MOVE.B  right3, D2      ; shift the bits 5-3 to the LSB
        LSR.W   D2, D3          ; do the actual shift 
        BRA     EA_GEN_SRC

        MOVE.L  D0, D4          ; Store the dst reg in D4
        ANDI.W  #dst_reg, D4     ; get the bits at 2-0

 
EA_MOVE         ; 1: ea_move
        MOVE.L  D0, D1
        ANDI.W  #first_nibble, D1
        MOVE.B  right12, D2 
        LSR.W   D2, D1
        ANDI.B  #3, D1
        MOVE.B  D1, D2
        JSR     EA_SIZE_MOVE
        
        MOVE.L  D0, D3          ; Store the src mode in D3
        ANDI.W  #src_mode, D3    ; get bits 5-3
        MOVE.B  right3, D2      ; shift the bits 5-3 to the LSB
        LSR.W   D2, D3          ; do the actual shift 
        JSR     EA_GEN_SRC
        
        MOVE.L  D0, D4          ; Store the src reg in D4
        ANDI.W  #src_reg, D4     ; get the bits at 2-0
        
        MOVE.L  D0, D3          ; D0 does not change, D3 is used to store the dst mode and src mode. 
        ANDI.W  #dst_mode, D3    ; get bits 11-9
        MOVE.B  right9, D2      ; shift the bits 11-9 to the LSB
        LSR.W   D2, D3          ; do the actual shift 
        JSR     EA_GEN_SRC
        
        
EA_MOVEA        ; 2: ea_movea
EA_LEA          ; 3: ea_lea
EA_DSTONLY      ; 4: ea_dstonly
EA_EXT          ; 5: ea_ext
EA_MOVEM        ; 6: ea_movem
EA_TRAP         ; 7: ea_trap
EA_QUICK        ; 8: ea_quick
EA_branch       ; 9: ea_branch

EA_REG

EA_GEN_SRC
        LEA     EA_GEN_TABLE_SRC, A0
        MULU    #6, D3              ; use D3 to jump to the proper src mode and dst mode. 
        JMP     0(A0,D3)            ; jump to each ea src generation table entry 

EA_GEN_TABLE_SRC
        JMP     EA_Dn               ; 000: Dn
        JMP     EA_An               ; 001: An
        JMP     EA_An_Indirect      ; 010: (An)
        JMP     EA_An_Indirect_Inc  ; 011: (An)+
        JMP     EA_An_Indirect_Dec  ; 100: -(An)
        JMP     EA_d16_An_Indirect  ; 101: (D16, An)
        JMP     EA_d8_An_X_Indirect ; 110: (D8, An, Xn)
        JMP     EA_Absolute         ; 111: (xxx).W,(xxx).L, or #<data>

EA_Dn               ; 000: Dn
        MOVE.B  #'D', (A2)+
        ADDI.B  #$30, D4
        MOVE.B  D4, (A2)+
        RTS
      

EA_An               ; 001: An
        MOVE.B  #'A', (A2)+
        ADDI.B  #$30, D4
        MOVE.B  D4, (A2)+
        RTS

EA_An_Indirect      ; 010: (An)
        MOVE.B  #'(', (A2)+
        MOVE.B  #'A', (A2)+
        ADDI.B  #$30, D4
        MOVE.B  D4, (A2)+
        MOVE.B  #')', (A2)+
        RTS
        
EA_An_Indirect_Inc  ; 011: (An)+
        MOVE.B  #'(', (A2)+
        MOVE.B  #'A', (A2)+
        ADDI.B  #$30, D4
        MOVE.B  D4, (A2)+
        MOVE.B  #')', (A2)+
        MOVE.B  #'+', (A2)+
        RTS
        
EA_An_Indirect_Dec  ; 100: -(An)
        MOVE.B  #'-', (A2)+
        MOVE.B  #'(', (A2)+
        MOVE.B  #'A', (A2)+
        ADDI.B  #$30, D4
        MOVE.B  D4, (A2)+
        MOVE.B  #')', (A2)+
        RTS
        
EA_d16_An_Indirect  ; 101: (D16, An)
RTS

EA_d8_An_X_Indirect ; 110: (D8, An, Xn)
RTS

EA_Absolute         ; 111: (xxx).W,(xxx).L, or #<data>
RTS
        




DONE        
    SIMHALT             ; halt simulator

* Put variables and constants here
   
       
buffer_size         EQU         64 
decoded_buffer      EQU         $2000
   
CR                  EQU         $0D
LF                  EQU         $0A
stack               EQU         $0000A000
lines_p_screen      EQU         20
right3              EQU         3
right4              EQU         4
right6              EQU         6
right8              EQU         8
right9              EQU         9
right12             EQU         12
right16             EQU         16
right24             EQU         24
ascii_y_n           DC.B        32
y_uppercase         EQU         $59         
y_lowercase         EQU         $79
n_uppercase         EQU         $4E
n_lowercase         EQU         $6E
task2               EQU         $02
task5               EQU         $05
task9               EQU         $09
task13              EQU         $0D
task14              EQU         $0E
first_nibble        EQU         $F000
second_nibble       EQU         $0F00   
third_nibble        EQU         $00F0
fourth_nibble       EQU         $000F
dst_mode            EQU         $00C0
dst_reg             EQU         $0E00
src_mode            EQU         $0018
src_reg             EQU         $0007
bit8                EQU         $0100

ea_type_immediate   EQU     0       ; EA Type = immediate
ea_type_move        EQU     1       ; EA Type = move
ea_type_movea       EQU     2       ; EA Type = movea
ea_type_movea6      EQU     12      ; EA Type = movea * 6
ea_type_lea         EQU     3       ; EA Type = lea
ea_type_dstonly     EQU     4       ; EA Type = clr, neg, not, jsr, jmp
ea_type_ext         EQU     5       ; EA Type = ext
ea_type_movem       EQU     6       ; EA Type = movem
ea_type_trap        EQU     7       ; EA Type = trap
ea_type_quick       EQU     8       ; EA Type = addq, subq
ea_type_branch      EQU     9       ; EA Type = bra, bsr, bcc
ea_bcc_flag         EQU     0       ; EA Type = branch, flag = bcc
ea_dbcc_flag        EQU     1       ; EA Type = branch, flag = dbcc
ea_scc_flag         EQU     2       ; EA Type = branch, flag = scc
EA_WRONGSIZE
                 
WELCOME             DC.B        'Welcome to the 68k Disassembler of Avery and Alan',CR,LF,CR,LF,0

USER_INST           DC.B        'Please follow the proper input instructions below: ',CR,LF
                    DC.B        '- Starting address must be lower than ending address.',CR,LF
                    DC.B        '- The values for the starting and ending address must be an even value.',CR,LF
                    DC.B        '- Starting and ending address must be inputted as hexadecimal value.',CR,LF
                    DC.B        '- Do not put spaces in between input characters.',CR,LF
                    DC.B        '- Valid characters include: 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, A, B, C, D, E, F',CR,LF,0
                
ENTER_PROMPT        DC.B        'Press enter to continue...',CR,LF,0
PROMPT_AGAIN        DC.B        'Press Y to continue / N to exit.',CR,LF,0
EXIT_PROMPT         DC.B        'Program has execution has stopped.',CR,LF,0
      
START_IN            DC.B        'Enter a starting address: ',CR,LF,0 
END_IN              DC.B        'Enter an ending address: ',CR,LF,0 
START_ADDRESS       DS.B        32     
END_ADDRESS         DS.B        32 
ERROR_MESSAGE       DC.B        'Error, the input is Invalid.',CR,LF,0       


    END    START        ; last line of source



*~Font name~Courier New~
*~Font size~10~
*~Tab type~1~
*~Tab size~4~



*~Font name~Courier New~
*~Font size~10~
*~Tab type~1~
*~Tab size~4~
