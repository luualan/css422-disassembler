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
START:            
*------------------------------------------------------------*
* D0: used for the tasks
* D1: used to hold the size of the input obtained. 
* D5: used to store the starting and ending address 
* temporarily before moving them to A4 and A6 correspondingly. 
* D6: used to check the last digit to see if the input 
* for the starting and ending address causes a bus error. 
* A1: a pointer to the message to print out. 
*------------------------------------------------------------*

DISP_W      MOVE.B  #14,D0	                ; Display Welcome Message. 
            LEA	    WELCOME,A1
            TRAP    #15

* Put program code here

DISP_UI         MOVE.B  #14,D0              ; Display User Instructions. 
                LEA	    USER_INST,A1
                TRAP    #15	   

PROMPT_START    LEA     stack, SP           ; SP = stack ($A0000)
                LEA     START_IN,A1         ; Display starting address message
                MOVE.B  #14,D0
                TRAP    #15       
     
READ_START      LEA     START_ADDRESS,A1    ; Store user's starting address input
                MOVE.B  #2,D0               ; Read user's input into A1; length is stored into D1
                TRAP    #15
                MOVE.B  #0,D6               ; Used to indicate we are at start address

VALIDATE_START  BRA     ATOI

PROMPT_END      LEA     END_IN,A1           ; Display starting address message
                MOVE.B  #14,D0
                TRAP    #15            
READ_END        LEA     END_ADDRESS,A1      ; Store user's starting address input
                MOVE.B  #2,D0               ; Read user's input into A1; length is stored into D1
                TRAP    #15
                MOVE.B  #1,D6               ; Used to indicate we are at end address

VALIDATE_END    BRA     ATOI
               
* D0 stores the value to pushed from A1.

ATOI            MOVE.B  (A1)+,D0    ; Move to next character in A1 and store in D0			
                CMP.B   #$30,D0
                BLT     INPUT_INVALID
                CMP.B   #$39,D0
                BGT     ASCII_TO_HEX_LETTER
                SUB.B   #$30,D0     ; Subtract by 30 to get the numbers 0-9
                ADD.L   D0,D5
                SUBI    #1,D1       ; Decrement input's length to move to next character          
                CMP.B   #0,D1       ; Compare to see if we're at the last digit
                BEQ     LAST_DIGIT_CHECK
                LSL.L   #4,D5
                BRA	    ATOI

  
ASCII_TO_HEX_LETTER     CMP.B   #$41,D0
                        BLT     INPUT_INVALID
                        CMP.B   #$46, D0
                        BGT     INPUT_INVALID 
                        SUB.B   #$31,D0     ; Subtract by 31 to get the numbers A-F
                        SUB.B   #6,D0
                        ADD.L   D0,D5
                        SUBI    #1,D1
                        BEQ     LAST_DIGIT_CHECK
                        LSL.L   #4,D5
                        BRA     ATOI     

                    
INPUT_INVALID   LEA     ERROR_MESSAGE, A1   ; Display error message
                MOVE.B  #14, D0
                TRAP    #15
                CLR.B   D6
                
                CMP.B   #0,D6           ; When D6 is 0
                BEQ     PROMPT_START    ; Go back to start prompt
                CMP.B   #1,D6           ; When D6 is 1
                BEQ     PROMPT_END      ; Go back to end prompt

                          
LAST_DIGIT_CHECK    MOVE.L  D5, D7          ; D7 used as temporary storage
                    LSR.B   #1, D7          ; Check for carry bit to see if last digit is odd
                    BCS     LAST_DIGIT_ODD  ; branch when there is a carry; this indicates odd last digit 
                    CLR.L   D7
                    CMP.B   #0,D6
                    BEQ     COMPLETE_START  
                    CMP.B   #1,D6
                    BEQ     COMPLETE_END

COMPLETE_START      MOVEA.L D5, A4  ; A4 holds the starting address
                    CLR.L   D5 
                    BRA PROMPT_END

COMPLETE_END        MOVEA.L D5, A6  ; A6 holds the ending address
                    MOVEA.L A4, A5  ; Store starting address into current address
                    
                    *Clear the data and address registers used to obtain the starting and ending address 
                    CLR.L   D0
                    CLR.L   D5
                    CLR.L   D6
                    MOVEA   #0, A1
                    BRA     START_DECODING  ; All inputs are valid, go to the decode process
                    
LAST_DIGIT_ODD      LEA     ODD_ERROR_MESSAGE, A1 
                    MOVE.B  #14, D0
                    TRAP    #15
                    
                    CMP.B   #0,D6           ; When D6 is 0
                    BEQ     PROMPT_START    ; Go back to start prompt
                    CMP.B   #1,D6           ; When D6 is 1
                    BEQ     PROMPT_END      ; Go back to end prompt

*--------------------------------------------------------------------------------------
* param D2 data size to convert into ASCII
* param A2 a pointer to decode_buf
* param A5 the current address
* itoa (D2, A2, A5) {
* D0 byte data in ACII
* D1 #sfhit
* D7 long data to convert into ASCII
* }
        
ITOA                                ; convert integer to ASCII  
        MOVEM.L D0-D1,-(SP) 
        CMP.B   #%00, D2            ; byte
        BEQ     ITOA_BYTE
        CMP.B   #%01, D2            ; word
        BEQ     ITOA_WORD
        CMP.B   #%10, D2            ; long
        BEQ     ITOA_LONG
        JMP     ITOA_LONGADDRESS    ; long address
        
ITOA_MOVE                           ; convert integer to ASCII
        MOVEM.L D0-D1,-(SP) 
        CMP.B   #%01, D2            ; byte
        BEQ     ITOA_BYTE
        CMP.B   #%11, D2            ; word
        BEQ     ITOA_WORD
        CMP.B   #%10,D2             ; long
        BEQ     ITOA_LONG
        JMP     ITOA_LONGADDRESS    ; long address
        
ITOA_OPMODE                         ; convert integer to ASCII
        MOVEM.L D0-D1,-(SP) 
        CMP.B   #%000,D2            ; When 0 then byte
        BEQ     ITOA_BYTE
        CMP.B   #%100,D2            ; When 4 then byte
        BEQ     ITOA_BYTE 
        CMP.B   #%001,D2            ; When 1 then word
        BEQ     ITOA_WORD
        CMP.B   #%011,D2            ; When 3 then word
        BEQ     ITOA_WORD
        CMP.B   #%101,D2            ; When 5 then word
        BEQ     ITOA_WORD 
        CMP.B   #%010,D2            ; When 2 then long
        BEQ     ITOA_LONG
        CMP.B   #%110,D2            ; When 6 then long
        BEQ     ITOA_LONG
        CMP.B   #%111,D2            ; When 7 then long
        BEQ     ITOA_LONG
        
ITOA_BYTE
        MOVE.W  (A5)+,D7
        JSR     ITOA_BYTE_CONVERT
        JMP     ITOA_DONE

ITOA_BYTE_BRANCH
        MOVEM.L D0-D1,-(SP)
        MOVE.W  D5,D7
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
        
ITOA_WORD_BRANCH
        MOVEM.L D0-D1,-(SP) 
        MOVE.W  D5,D7
        MOVE.B  #right8, D1
        LSR.W   D1,D7
        JSR     ITOA_BYTE_CONVERT
        MOVE.W  D5, D7
        MOVE.W  (A5)+, D3
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
        
        ;check if decoding has finished or if the screen is filled 
        CMP.L   A5, A6
        BLE     CONTINUE_OR_END     ; If A6-A5 <= 0, go to CONTINUE_OR_END 
        
        ;have yet to reach the ending address
        ADDQ.B  #1, D2              ; D2 (screen_line_counter)++
        CMP.B   #lines_p_screen, D2
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
        BRA     DONE             
*---------------------------------------------------------------------------------*
* D0: the current instruction. 
* D1: used as temp storage
* D2: data size 
* D3: loop counter for the amount of lines per screen. 
* D4: 
* D5: #shifts
* D6: store first nibble
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
        MOVEM.L D2/A6, -(SP)
                
        ;zero clear the decode_buffer
        JSR     OP_CLEAR_DATA
        LEA     decoded_buffer, A2  Load decode buffer into A2
                
        ;print out the current address
        MOVE.L  #$0003, D2
        JSR      ITOA
        
        MOVE.B  #$9, (A2)+  ; Add space after long address
                
        ;load the next instruction and jump to the opcode table entry
        LEA     OP_TABLE, A0
        CLR.L   D0
        MOVE.W  (A5)+, D0       ; Store A5's value into D0, then increment A5
        MOVE.L  D0, D1          ; Store A5's value from D0 into D1
        MOVE.B  #right12, D5    ; Store 12 into D5
        LSR.W   D5, D1          ; Shift first nibble into LSB position
        MOVE.L  D1, D6          ; Store first nibble into D6
        MULU    #6, D1          ; Multiply 6 to D1
        JMP     0(A0, D1)       ; Go to displacement (A0 + D1 * 6)      
OP_FINISH
        MOVEM.L (SP)+, D2/A6,
        RTS

*------------------------------------------------------------------------------------*
*Clear the 32 bits within the decoded_buffer       
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
        
code0000                            ; Opcodes ADDI and SUBI
        MOVE.L  D0,D1               ; D0 is current instruction word
        ANDI.W  #second_nibble,D1   ; Extract 2nd nibble from instruction word
        MOVE.B  #right8,D5          ; Used to shift 8 times to right
        LSR.W   D5,D1               ; Shift nibble into LSB position
        MULU    #6, D1              ; Set displacement 
        LEA     OP_0000_TABLE,A0    ; Load table into A0
        JMP     0(A0,D1)            ; go to displacement (A0 + D1 * 6)

code0001                            ; Opcode MOVE.B
        BRA     OP_MOVE             ; Go to opcode MOVE

code0010                            ; Opcodes MOVE.L and MOVEA.L 
        MOVE.L  D0,D1               ; D0 is current instruction word
        ANDI.W  #dst_mode,D1        ; Extract dst mode position from instruction word
        MOVE.B  #right6,D5          ; Used to shift 6 times to right
        LSR.W   D5,D1               ; Shift dst mode into LSB position
        CMP.B   #1, D1              ; When 001 in destination mode
        BEQ     OP_MOVEA            ; Go to opcode MOVEA
        BRA     OP_MOVE             ; Otherwise, go to opcode MOVE

code0011                            ; Opcodes MOVE.W and MOVEA.W 
        MOVE.L  D0,D1               ; D0 is current instruction word
        ANDI.W  #dst_mode,D1        ; Extract dst mode position from instruction word
        MOVE.B  #right6,D5          ; Used to shift 6 times to right
        LSR.W   D5,D1               ; Shift dst mode into LSB position
        CMP.B   #1, D1              ; When 001 in destination mode
        BEQ     OP_MOVEA            ; Go to opcode MOVEA
        BRA     OP_MOVE             ; Otherwise, go to opcode MOVE

code0100                            ; Opcodes CLR, JSR, LEA, MOVEM, NOP, RTS
        MOVE.L  D0,D1               ; D0 is current instruction word
        ANDI.W  #second_nibble,D1   ; Extract 2nd nibble from instruction word
        MOVE.B  #right8,D5          ; Used to shift 8 times to right
        LSR.W   D5,D1               ; Shift nibble into LSB position
        MULU    #6, D1              ; Set displacement 
        LEA     OP_0100_TABLE,A0    ; Load table into A0
        JMP     0(A0,D1)            ; go to displacement (A0 + D1 * 6)

code0101                            ; Opcode ADDQ.B/W/L
        BRA     OP_ADDQ             ; Go to opcode ADDQ

code0110                            ; Opcodes BRA / BSR / BHI
        MOVE.L  D0,D1               ; D0 is current instruction word
        ANDI.W  #second_nibble,D1   ; Extract 2nd 4 bits from instruction word
        MOVE.B  #right8,D5          ; Used to shift 8 times to right
        LSR.W   D5,D1               ; Shift nibble into LSB position
        CMP.B   #0, D1              ; When 0000 in second nibble 
        BEQ     OP_BRA              ; Go to opcode BRA
        CMP.B   #1, D1              ; When 0001 in second nibble 
        BEQ     OP_BSR              ; Go to opcode BSR
        CMP.B   #2, D1              ; When 0010 in second nibble 
        BEQ     OP_BHI              ; Go to opcode BHI
        CMP.B   #3, D1              ; When 0011 in second nibble
        BEQ     OP_BLS              ; Go to opcode BLS
        CMP.B   #4, D1              ; When 0100 in second nibble
        BEQ     OP_BCC              ; Go to opcode BCC
        CMP.B   #5, D1              ; When 0101 in second nibble
        BEQ     OP_BCS              ; Go to opcode BCS
        CMP.B   #6, D1              ; When 0110 in second nibble
        BEQ     OP_BNE              ; Go to opcode BNE
        CMP.B   #7, D1              ; When 0111 in second nibble
        BEQ     OP_BEQ              ; Go to opcode BEQ
        CMP.B   #8, D1              ; When 1000 in second nibble
        BEQ     OP_BVC              ; Go to opcode BVC
        CMP.B   #9, D1              ; When 1001 in second nibble
        BEQ     OP_BVS              ; Go to opcode BVS
        CMP.B   #10, D1             ; When 1010 in second nibble
        BEQ     OP_BPL              ; Go to opcode BPL
        CMP.B   #11, D1             ; When 1011 in second nibble
        BEQ     OP_BMI              ; Go to opcode BMI
        CMP.B   #12, D1             ; When 1100 in second nibble
        BEQ     OP_BGE              ; Go to opcode BGE
        CMP.B   #13, D1             ; When 1101 in second nibble
        BEQ     OP_BLT              ; Go to opcode BLT
        CMP.B   #14, D1             ; When 1110 in second nibble
        BEQ     OP_BGT              ; Go to opcode BGT
        CMP.B   #15, D1             ; When 1111 in second nibble
        BEQ     OP_BLE              ; Go to opcode BLE

code0111                            ; Opcode MOVEQ
        BRA     OP_MOVEQ            ; Go to opcode MOVEQ

code1000                            ; Opcodes DIVU word and OR.B/W/L
        MOVE.L  D0,D1               ; D0 is current instruction word
        ANDI.W  #dst_mode,D1        ; Extract dst mode position from instruction word
        MOVE.B  #right6,D5          ; Used to shift 6 times to right
        LSR.W   D5,D1               ; Shift dst mode into LSB position
        CMP.B   #3,D1               ; When 011 in destination mode
        BEQ     OP_DIVU             ; Go to opcode DIVU word
        CMP.B   #7,D1               ; When 111
        BEQ     OP_UNSUPPORTED      ; Go to opcode unsupported
        BRA     OP_OR               ; Otherwise, go to opcode OR

code1001                            ; Opcode SUB.B/W/L
        BRA     OP_SUB              ; Go to opcode SUB   

code1010                            ; Opcode not supported 
        BRA     OP_UNSUPPORTED      ; Go to opcode unsupported   
     
code1011                            ; Opcode CMP.B/W/L
        BRA     OP_CMP              ; Go to opcode CMP

code1100                            ; Opcodes MULS, MULU, AND.B/W/L
        MOVE.L  D0,D1               ; D0 is current instruction word
        ANDI.W  #dst_mode,D1        ; Extract dst mode position from instruction word
        MOVE.B  #right6,D5          ; Used to shift 6 times to right
        LSR.W   D5,D1               ; Shift dst mode into LSB position
        MULU    #6, D1              ; Set displacement 
        LEA     OP_1100_TABLE,A0    ; Load table into A0
        JMP     0(A0,D1)            ; Go to displacement (A0 + D1 * 6)

code1101                            ; Opcodes ADD.B/W/L, ADDA.B/W/L
        MOVE.L  D0,D1               ; D0 is current instruction word
        ANDI.W  #dst_mode,D1        ; Extract dst mode position from instruction word
        MOVE.B  #right6,D5          ; Used to shift 6 times to right
        LSR.W   D5,D1               ; Shift dst mode into LSB position
        MULU    #6, D1              ; Set displacement 
        LEA     OP_1101_TABLE,A0    ; Load table into A0
        JMP     0(A0,D1)            ; Go to displacement (A0 + D1 * 6)

code1110                            ; Opcodes ASL.B/W/L, ASR.B/W/L, LSL.B/W/L, LSR.B/W/L, ROL.B/W/L, ROR.B/W/L   
        MOVE.L  D0,D1               ; D0 is current instruction word
        ANDI.W  #dst_mode,D1        ; Extract 8-6 bits from instruction word
        MOVE.B  #right6,D5          ; Used to shift 6 times to right
        LSR.W   D5,D1               ; Shift dst mode into LSB position
   
        ; Check Memory Shifts
        CMP.B   #7, D1              ; When 111
        BEQ     MEMORY_1110_LEFT    ; Go to Memory Shift Left Side
    
        CMP.B   #3, D1              ; When 011
        BEQ     MEMORY_1110_RIGHT   ; Go Memory Shift Right Side
    
        ; Check Register Shifts
        MOVE.L  D0,D1                       ; D0 is current instruction word
        ANDI.W  #src_mode,D1                ; Extract 5-3 bits from instruction word
        MOVE.B  #right3,D5                  ; Used to shift 3 times to right
        LSR.W   D5,D1                       ; Shift 5-3 bits into LSB position
        MULU    #6,D1                       ; Set displacement 
        LEA     OP_1110_TABLE_REGISTER,A0   ; Load table into A0
        JMP     0(A0,D1)                    ; go to displacement (A0 + D1 * 6)

MEMORY_1110_LEFT    
        MOVE.L  D0,D1               ; D0 is current instruction word
        ANDI.W  #dst_reg,D1         ; Extract 11-9 position from instruction word
        MOVE.B  #right9,D5          ; Used to shift 9 times to right
        LSR.W   D5,D1               ; Shift dst reg into LSB position
        CMP.B   #0,D1               ; When D1 is 0
        BEQ     OP_ASL              ; Go to opcode ASL
        CMP.B   #1, D1              ; when D1 is 1
        BEQ     OP_LSL              ; Go to opcode LSL
        CMP.B   #3, D1              ; When D1 is 3
        BEQ     OP_ROL              ; Go to opcode ROL

MEMORY_1110_RIGHT
        MOVE.L  D0,D1               ; D0 is current instruction word
        ANDI.W  #dst_reg,D1         ; Extract 11-9 position from instruction word
        MOVE.B  #right9,D5          ; Used to shift 9 times to right
        LSR.W   D5,D1               ; Shift dst reg into LSB position
        CMP.B   #0,D1               ; When D1 is 0
        BEQ     OP_ASR              ; Go to opcode ASR
        CMP.B   #1, D1              ; when D1 is 1
        BEQ     OP_LSR              ; Go to opcode LSR
        CMP.B   #3, D1              ; When D1 is 3
        BEQ     OP_ROR              ; Go to opcode ROR

code1111                            ; Opcode not supported 
        BRA     OP_UNSUPPORTED      ; Go to opcode unsupported   
         
OP_0000_TABLE
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
    
OP_0100_TABLE
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
    
OP_1100_TABLE
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
    
OP_1101_TABLE
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
    
OP_1110_TABLE_REGISTER
        JMP     OP_AS_CHECK         ; 0 Check if AS is left or right
        JMP     OP_LS_CHECK         ; 1 Check if LS is left or right
        JMP     OP_UNSUPPORTED      ; 2 Go to opcode unsupported  
        JMP     OP_RO_CHECK         ; 3 Check if RO is left or right
        JMP     OP_AS_CHECK         ; 4 Check if AS is left or right
        JMP     OP_LS_CHECK         ; 5 Check if LS is left or right
        JMP     OP_UNSUPPORTED      ; 6 Go to opcode unsupported 
        JMP     OP_RO_CHECK         ; 7 Check if RO is left or right
        JMP     OP_UNSUPPORTED      ; 8 Go to opcode unsupported  
        JMP     OP_UNSUPPORTED      ; 9 Go to opcode unsupported  
        JMP     OP_UNSUPPORTED      ; A Go to opcode unsupported  
        JMP     OP_UNSUPPORTED      ; B Go to opcode unsupported  
        JMP     OP_UNSUPPORTED      ; C Go to opcode unsupported  
        JMP     OP_UNSUPPORTED      ; D Go to opcode unsupported  
        JMP     OP_UNSUPPORTED      ; E Go to opcode unsupported  
        JMP     OP_UNSUPPORTED      ; F Go to opcode unsupported  

OP_AS_CHECK
        MOVE.L  D0,D1               ; D0 is current instruction word
        ANDI.W  #dst_mode,D1        ; Extract 8-6 bits from instruction word
        MOVE.B  #right6,D5          ; Used to shift 6 times to right
        LSR.W   D5,D1               ; Shift dst mode into LSB position
        ANDI.B  #4,D1               ; Get only bit 8 (dr)
        LSR.W   #2,D1

        CMP.B   #1,D1               ; Go left
        BEQ     OP_ASL              ; 1 Go to opcode ASL
        CMP.B   #0,D1               ; Go right
        BEQ     OP_ASR              ; 0 Go to opcode ASR
        
OP_LS_CHECK
        MOVE.L  D0,D1               ; D0 is current instruction word
        ANDI.W  #dst_mode,D1        ; Extract 8-6 bits from instruction word
        MOVE.B  #right6,D5          ; Used to shift 6 times to right
        LSR.W   D5,D1               ; Shift dst mode into LSB position
        ANDI.B  #4,D1               ; Get only bit 8 (dr)
        LSR.W   #2,D1

        CMP.B   #1,D1               ; Go left
        BEQ     OP_LSL              ; 1 Go to opcode LSL
        CMP.B   #0,D1               ; Go right
        BEQ     OP_LSR              ; 0 Go to opcode LSR
        
OP_RO_CHECK
        MOVE.L  D0,D1               ; D0 is current instruction word
        ANDI.W  #dst_mode,D1        ; Extract 8-6 bits from instruction word
        MOVE.B  #right6,D5          ; Used to shift 6 times to right
        LSR.W   D5,D1               ; Shift dst mode into LSB position
        ANDI.B  #4,D1               ; Get only bit 8 (dr)
        LSR.W   #2,D1

        CMP.B   #1,D1               ; Go left
        BEQ     OP_ROL              ; 1 Go to opcode ROL
        CMP.B   #0,D1               ; Go right
        BEQ     OP_ROR              ; 0 Go to opcode ROR
        
JSR_NOP_RTS
        MOVE.L  D0,D1               ; D0 is current instruction word
        ANDI.W  #dst_mode,D1        ; Extract dst mode position from instruction word
        MOVE.B  #right6,D5          ; Used to shift 6 times to right
        LSR.W   D5,D1               ; Shift dst mode into LSB position
        CMP.B   #2, D1              ; When 010 in destination mode
        BEQ     OP_JSR              ; Go to opcode JSR
        MOVE.L  D0,D1               ; D0 is current instruction word
        ANDI.W  #src_reg,D1         ; Extract src reg position from instruction word
        CMP.B   #1,D1               ; When 001 in src register
        BEQ     OP_NOP              ; Go to opcode NOP
        CMP.B   #5,D1               ; When 005 in src register
        BEQ     OP_RTS              ; Go to opcode RTS
        BRA     OP_UNSUPPORTED      ; Otherwise, go to opcode unsupported 

OP_UNSUPPORTED
        LEA     OPCODE_INVALID,A1 
        MOVE.B  #14,D0
        TRAP    #15
        BRA     DONE
        
*----------------------------------------------------------------------------------------------*
* param D0 the current instruction in word
* param D1 the EA type
* param A2 a pointer to the decode_buffer
* param A5 current address
* ea_start(D0, D1, A2, A5){
* D2: size
* D3: src mode, dst mode
* D4: src regs, dst regs
* D5: #shifts
* D7: immediate data
* A0: EA_TYPE_TABLE
*       0 = ea_immediate
* }

*----------------------------------------------------------------------------------------------*
* First 4 bits: 0000
OP_SUBI
        MOVE.B  #'S',(A2)+
        MOVE.B  #'U',(A2)+
        MOVE.B  #'B',(A2)+
        MOVE.B  #'I',(A2)+
        MOVE.L  #ea_type_immediate,D1
        JSR     EA_START
        JMP     OP_FINISH
        
OP_ADDI
        MOVE.B  #'A',(A2)+
        MOVE.B  #'D',(A2)+
        MOVE.B  #'D',(A2)+
        MOVE.B  #'I',(A2)+
        MOVE.L  #ea_type_immediate,D1
        JSR     EA_START
        JMP     OP_FINISH

*-----------------------------------------------------------------------------------------------*
* First 4 bits: 0001
OP_MOVEA
        MOVE.B  #'M',(A2)+
        MOVE.B  #'O',(A2)+
        MOVE.B  #'V',(A2)+
        MOVE.B  #'E',(A2)+
        MOVE.B  #'A',(A2)+
        MOVE.L  #ea_type_movea,D1
        JSR     EA_START
        JMP     OP_FINISH

*------------------------------------------------------------------------------------------------*
* First 4 bits: 0011
OP_MOVE
        MOVE.B  #'M',(A2)+
        MOVE.B  #'O',(A2)+
        MOVE.B  #'V',(A2)+
        MOVE.B  #'E',(A2)+
        MOVE.L  #ea_type_move,D1
        JSR     EA_START
        JMP     OP_FINISH

*------------------------------------------------------------------------------------------------*
* First 4 bits: 0100
OP_CLR
        MOVE.B  #'C',(A2)+
        MOVE.B  #'L',(A2)+
        MOVE.B  #'R',(A2)+
        MOVE.L  #ea_type_dstonly,D1
        JSR     EA_START
        JMP     OP_FINISH
        
OP_NOP
        MOVE.B  #'N',(A2)+
        MOVE.B  #'O',(A2)+
        MOVE.B  #'P',(A2)+
        MOVE.L  #ea_type_immediate,D1
        JSR     EA_START
        JMP     OP_FINISH
        
OP_RTS
        MOVE.B  #'R',(A2)+
        MOVE.B  #'T',(A2)+
        MOVE.B  #'S',(A2)+
        JMP     OP_FINISH
        
OP_JSR
        MOVE.B  #'J',(A2)+
        MOVE.B  #'S',(A2)+
        MOVE.B  #'R',(A2)+
        MOVE.L  #ea_type_dstonly,D1
        JSR     EA_START
        JMP     OP_FINISH

OP_MOVEM
        MOVE.B  #'M',(A2)+
        MOVE.B  #'O',(A2)+
        MOVE.B  #'V',(A2)+
        MOVE.B  #'E',(A2)+
        MOVE.B  #'M',(A2)+
        MOVE.L  #ea_type_movem,D1
        JSR     EA_START
        JMP     OP_FINISH
        
OP_LEA
        MOVE.B  #'L',(A2)+
        MOVE.B  #'E',(A2)+
        MOVE.B  #'A',(A2)+
        MOVE.L  #ea_type_lea,D1
        JSR     EA_START
        JMP     OP_FINISH

*------------------------------------------------------------------------------------------------*
* First 4 bits: 0101
OP_ADDQ
        MOVE.B  #'A',(A2)+
        MOVE.B  #'D',(A2)+
        MOVE.B  #'D',(A2)+
        MOVE.B  #'Q',(A2)+
        MOVE.L  #ea_type_quick,D1
        JSR     EA_START
        JMP     OP_FINISH
        
*------------------------------------------------------------------------------------------------*
* First 4 bits: 0110
OP_BRA
        MOVE.B  #'B',(A2)+
        MOVE.B  #'R',(A2)+
        MOVE.B  #'A',(A2)+
        MOVE.L  #ea_type_branch,D1
        JSR     EA_START
        JMP     OP_FINISH

OP_BSR
        MOVE.B  #'B',(A2)+
        MOVE.B  #'S',(A2)+
        MOVE.B  #'R',(A2)+
        MOVE.L  #ea_type_branch,D1
        JSR     EA_START
        JMP     OP_FINISH
        
OP_BHI
        MOVE.B  #'B',(A2)+
        MOVE.B  #'H',(A2)+
        MOVE.B  #'I',(A2)+
        MOVE.L  #ea_type_branch,D1
        JSR     EA_START
        JMP     OP_FINISH

OP_BLS
        MOVE.B  #'B',(A2)+
        MOVE.B  #'L',(A2)+
        MOVE.B  #'S',(A2)+
        MOVE.L  #ea_type_branch,D1
        JSR     EA_START
        JMP     OP_FINISH

OP_BCC
        MOVE.B  #'B',(A2)+
        MOVE.B  #'C',(A2)+
        MOVE.B  #'C',(A2)+
        MOVE.L  #ea_type_branch,D1
        JSR     EA_START
        JMP     OP_FINISH
        
OP_BCS
        MOVE.B  #'B',(A2)+
        MOVE.B  #'C',(A2)+
        MOVE.B  #'S',(A2)+
        MOVE.L  #ea_type_branch,D1
        JSR     EA_START
        JMP     OP_FINISH

OP_BNE
        MOVE.B  #'B',(A2)+
        MOVE.B  #'N',(A2)+
        MOVE.B  #'E',(A2)+
        MOVE.L  #ea_type_branch,D1
        JSR     EA_START
        JMP     OP_FINISH

OP_BEQ
        MOVE.B  #'B',(A2)+
        MOVE.B  #'E',(A2)+
        MOVE.B  #'Q',(A2)+
        MOVE.L  #ea_type_branch,D1
        JSR     EA_START
        JMP     OP_FINISH

OP_BVC
        MOVE.B  #'B',(A2)+
        MOVE.B  #'V',(A2)+
        MOVE.B  #'C',(A2)+
        MOVE.L  #ea_type_branch,D1
        JSR     EA_START
        JMP     OP_FINISH

OP_BVS
        MOVE.B  #'B',(A2)+
        MOVE.B  #'V',(A2)+
        MOVE.B  #'S',(A2)+
        MOVE.L  #ea_type_branch,D1
        JSR     EA_START
        JMP     OP_FINISH

OP_BPL
        MOVE.B  #'B',(A2)+
        MOVE.B  #'P',(A2)+
        MOVE.B  #'L',(A2)+
        MOVE.L  #ea_type_branch,D1
        JSR     EA_START
        JMP     OP_FINISH

OP_BMI
        MOVE.B  #'B',(A2)+
        MOVE.B  #'M',(A2)+
        MOVE.B  #'I',(A2)+
        MOVE.L  #ea_type_branch,D1
        JSR     EA_START
        JMP     OP_FINISH

OP_BGE
        MOVE.B  #'B',(A2)+
        MOVE.B  #'G',(A2)+
        MOVE.B  #'E',(A2)+
        MOVE.L  #ea_type_branch,D1
        JSR     EA_START
        JMP     OP_FINISH

OP_BLT
        MOVE.B  #'B',(A2)+
        MOVE.B  #'L',(A2)+
        MOVE.B  #'T',(A2)+
        MOVE.L  #ea_type_branch,D1
        JSR     EA_START
        JMP     OP_FINISH

OP_BGT
        MOVE.B  #'B',(A2)+
        MOVE.B  #'G',(A2)+
        MOVE.B  #'T',(A2)+
        MOVE.L  #ea_type_branch,D1
        JSR     EA_START
        JMP     OP_FINISH

OP_BLE
        MOVE.B  #'B',(A2)+
        MOVE.B  #'L',(A2)+
        MOVE.B  #'E',(A2)+
        MOVE.L  #ea_type_branch,D1
        JSR     EA_START
        JMP     OP_FINISH
*------------------------------------------------------------------------------------------------*
* First 4 bits: 0111
OP_MOVEQ
        MOVE.B  #'M',(A2)+
        MOVE.B  #'O',(A2)+
        MOVE.B  #'V',(A2)+
        MOVE.B  #'V',(A2)+
        MOVE.B  #'E',(A2)+
        MOVE.B  #'Q',(A2)+
        MOVE.L  #ea_type_quick,D1
        JSR     EA_START
        JMP     OP_FINISH
        
*------------------------------------------------------------------------------------------------*
* First 4 bits: 1000
OP_DIVU
        MOVE.B  #'D',(A2)+
        MOVE.B  #'I',(A2)+
        MOVE.B  #'V',(A2)+
        MOVE.B  #'U',(A2)+
        MOVE.L  #ea_type_ext,D1
        JSR     EA_START
        JMP     OP_FINISH
  
OP_OR
        MOVE.B  #'O',(A2)+
        MOVE.B  #'R',(A2)+
        MOVE.L  #ea_type_ext,D1
        JSR     EA_START
        JMP     OP_FINISH

*------------------------------------------------------------------------------------------------*
* First 4 bits: 1001
OP_SUB
        MOVE.B  #'S',(A2)+
        MOVE.B  #'U',(A2)+
        MOVE.B  #'B',(A2)+
        MOVE.L  #ea_type_ext,D1
        JSR     EA_START
        JMP     OP_FINISH
        
*------------------------------------------------------------------------------------------------*
* First 4 bits: 1011
OP_CMP
        MOVE.B  #'C',(A2)+
        MOVE.B  #'M',(A2)+
        MOVE.B  #'P',(A2)+
        MOVE.L  #ea_type_ext,D1
        JSR     EA_START
        JMP     OP_FINISH
        
*------------------------------------------------------------------------------------------------*
* First 4 bits: 1100
OP_MULU
        MOVE.B  #'M',(A2)+
        MOVE.B  #'U',(A2)+
        MOVE.B  #'L',(A2)+
        MOVE.B  #'U',(A2)+
        MOVE.L  #ea_type_ext,D1
        JSR     EA_START
        JMP     OP_FINISH
        
OP_MULS
        MOVE.B  #'M',(A2)+
        MOVE.B  #'U',(A2)+
        MOVE.B  #'L',(A2)+
        MOVE.B  #'S',(A2)+
        MOVE.L  #ea_type_ext,D1
        JSR     EA_START
        JMP     OP_FINISH
        
OP_AND
        MOVE.B  #'A',(A2)+
        MOVE.B  #'N',(A2)+
        MOVE.B  #'D',(A2)+
        MOVE.L  #ea_type_ext,D1
        JSR     EA_START
        JMP     OP_FINISH
        
*------------------------------------------------------------------------------------------------*
* First 4 bits: 1101
OP_ADD
        MOVE.B  #'A',(A2)+
        MOVE.B  #'D',(A2)+
        MOVE.B  #'D',(A2)+
        MOVE.L  #ea_type_ext,D1
        JSR     EA_START
        JMP     OP_FINISH

OP_ADDA
        MOVE.B  #'A',(A2)+
        MOVE.B  #'D',(A2)+
        MOVE.B  #'D',(A2)+
        MOVE.B  #'A',(A2)+
        MOVE.L  #ea_type_ext,D1
        JSR     EA_START
        JMP     OP_FINISH
        
*------------------------------------------------------------------------------------------------*
* First 4 bits: 1110
OP_ASR
        MOVE.B  #'A',(A2)+
        MOVE.B  #'S',(A2)+
        MOVE.B  #'R',(A2)+
        MOVE.L  #ea_type_shifts,D1
        JSR     EA_START
        JMP     OP_FINISH
OP_ASL
        MOVE.B  #'A',(A2)+
        MOVE.B  #'S',(A2)+
        MOVE.B  #'L',(A2)+
        MOVE.L  #ea_type_shifts,D1
        JSR     EA_START
        JMP     OP_FINISH
        
OP_LSR
        MOVE.B  #'L',(A2)+
        MOVE.B  #'S',(A2)+
        MOVE.B  #'R',(A2)+
        MOVE.L  #ea_type_shifts,D1
        JSR     EA_START
        JMP     OP_FINISH
       
OP_LSL
        MOVE.B  #'L',(A2)+
        MOVE.B  #'S',(A2)+
        MOVE.B  #'L',(A2)+
        MOVE.L  #ea_type_shifts,D1
        JSR     EA_START
        JMP     OP_FINISH
        
OP_ROR
        MOVE.B  #'R',(A2)+
        MOVE.B  #'O',(A2)+
        MOVE.B  #'R',(A2)+
        MOVE.L  #ea_type_shifts,D1
        JSR     EA_START
        JMP     OP_FINISH
        
OP_ROL
        MOVE.B  #'R',(A2)+
        MOVE.B  #'O',(A2)+
        MOVE.B  #'L',(A2)+
        MOVE.L  #ea_type_shifts,D1
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
        JMP     EA_IMMEDIATE        ; 0: ea_immediate
        JMP     EA_MOVE             ; 1: ea_move
        JMP     EA_MOVEA            ; 2: ea_movea
        JMP     EA_LEA              ; 3: ea_lea
        JMP     EA_DSTONLY          ; 4: ea_dstonly
        JMP     EA_EXT              ; 5: ea_ext
        JMP     EA_MOVEM            ; 6: ea_movem
        JMP     EA_SHIFTS           ; 7: ea_shifts
        JMP     EA_QUICK            ; 8: ea_quick
        JMP     EA_branch           ; 9: ea_branch
        JMP     EA_FINISH
        
EA_SIZE_GENERAL
        CMP.B   #%00,D2             ; .b
        BEQ     EA_SIZE_B       
        CMP.B   #%01,D2             ; .w
        BEQ     EA_SIZE_W       
        CMP.B   #%10,D2             ; .l
        BEQ     EA_SIZE_L
        BRA     EA_WRONG_SIZE       ; wrong size

EA_SIZE_MOVE
        CMP.B   #%01,D2             ; .b
        BEQ     EA_SIZE_B       
        CMP.B   #%11,D2             ; .w
        BEQ     EA_SIZE_W       
        CMP.B   #%10,D2             ; .l
        BEQ     EA_SIZE_L
        BRA     EA_WRONG_SIZE       ; wrong size

EA_SIZE_MOVEA     
        CMP.B   #%11,D2             ; .w
        BEQ     EA_SIZE_W       
        CMP.B   #%10,D2             ; .l
        BEQ     EA_SIZE_L
        BRA     EA_WRONG_SIZE       ; wrong size
        
EA_SIZE_MOVEM     
        CMP.B   #%0000,D2              ; .w
        BEQ     EA_SIZE_W       
        CMP.B   #%0100,D2              ; .l
        BEQ     EA_SIZE_L
        BRA     EA_WRONG_SIZE       ; wrong size

EA_SIZE_OPMODE_012456               ; Check opmode field for size
        CMP.B   #%000,D2            ; When 0 then .b
        BEQ     EA_SIZE_B
        CMP.B   #%100,D2            ; When 4 then .b
        BEQ     EA_SIZE_B  
        CMP.B   #%001,D2            ; When 1 then .w
        BEQ     EA_SIZE_W
        CMP.B   #%101,D2            ; When 5 then .w
        BEQ     EA_SIZE_W 
        CMP.B   #%010,D2            ; When 2 then .l
        BEQ     EA_SIZE_L
        CMP.B   #%110,D2            ; When 6 then .l
        BEQ     EA_SIZE_L
        BRA     EA_WRONG_SIZE       ; wrong size

EA_SIZE_ADDA                        ; Check opmode field for size
        CMP.B   #%011,D2            ; When 3 then .w
        BEQ     EA_SIZE_W       
        CMP.B   #%111,D2            ; When 7 then .l
        BEQ     EA_SIZE_L
        BRA     EA_WRONG_SIZE       ; wrong size
        
EA_SIZE_MULS_MULU_DIV               ; Check opmode field for size
        CMP.B   #%011,D2            ; When 3 then .w MULU, DIVU
        BEQ     EA_SIZE_W       
        CMP.B   #%111,D2            ; When 7 then .l MULS
        BEQ     EA_SIZE_W
        BRA     EA_WRONG_SIZE       ; wrong size
        
EA_SIZE_MEMORY_SHIFTS
        CMP.B   #%00,D2             ; .w
        BEQ     EA_SIZE_W_MEMORY      
        CMP.B   #%01,D2             ; .l
        BEQ     EA_SIZE_L      
        BRA     EA_WRONG_SIZE       ; wrong size

EA_SIZE_B
        MOVE.B  #'.',(A2)+
        MOVE.B  #'B',(A2)+
        RTS
EA_SIZE_W
        MOVE.B  #'.',(A2)+
        MOVE.B  #'W',(A2)+
        RTS     
EA_SIZE_W_MEMORY
        RTS        
EA_SIZE_L
        MOVE.B  #'.',(A2)+
        MOVE.B  #'L',(A2)+
        RTS
EA_SIZE_DONE
        RTS
        
EA_IMMEDIATE                        ; 0 ea_immediate
        MOVE.L  D0,D1
        ANDI.W  #dst_mode,D1        ; Get bits 8-6 from D1
        MOVE.B  #right6,D5          ; Store 6 into D5
        LSR.W   D5,D1               ; Shift D1 six times to the LSB position
        ANDI.B  #3,D1               ; Remove the front bit from D1
        MOVE.B  D1,D2               ; Store D1 into D2 (D2 is used to check size)
        JSR     EA_SIZE_GENERAL     ; Get size 
        
        MOVE.B  #$20,(A2)+          ; Add space after size
        MOVE.B  #$20,(A2)+          ; Add space 

        ; Get source and store into decode buffer
        MOVE.L  #4,D4               ; Store 100 into D4 (Used to jump to immediate)
        MOVE.L  #7,D3               ; Store 111 into D3 (Go to absolute and immediate)
        JSR     EA_GEN_SRC          ; Get EA src print 

        MOVE.B  #$2C,(A2)+          ; Add comma after size print
        MOVE.B  #$20,(A2)+          ; Add space after comma

        ; Get desination and store into decode buffer
        MOVE.L  D0,D4               ; Store the current address into D4 
        ANDI.W  #src_reg,D4         ; get the bits at 2-0 (D4 stores EA reg)
        
        MOVE.L  D0,D3               ; Store the current address into D3 
        ANDI.W  #src_mode,D3        ; get bits 5-3 (D3 stores EA mode)
        MOVE.B  #right3,D5          ; shift the bits 5-3 to the LSB position
        LSR.W   D5,D3               ; do the actual shift 
        CMP.B   #1,D3               ; If dest mode is 001: An
        BEQ     DST_INVALID         ; Go to invalid message 
        JSR     EA_GEN_SRC          ; When a valid dst, get EA dst print

        JMP     EA_FINISH           ; Opcode is finish

EA_MOVE                             ; 1: ea_move
        MOVE.L  D0,D1
        ANDI.W  #first_nibble,D1
        MOVE.B  #right12,D5 
        LSR.W   D5,D1
        ANDI.B  #3,D1
        MOVE.B  D1,D2
        JSR     EA_SIZE_MOVE
        
        MOVE.B  #$20,(A2)+          ; Print out a space after the size
        MOVE.B  #$20,(A2)+          ; Print out a space
        
        ; Get source and store into decode buffer
        MOVE.L  D0,D4               ; Store the src reg in D4
        ANDI.W  #src_reg,D4         ; Get the bits at 2-0
        
        MOVE.L  D0,D3               ; Store the src mode in D3
        ANDI.W  #src_mode,D3        ; Get bits 5-3
        MOVE.B  #right3,D5          ; Shift the bits 5-3 to the LSB
        LSR.W   D5,D3               ; Do the actual shift 
        JSR     EA_GEN_SRC
        
        MOVE.B  #$2C,(A2)+          ; Add comma after size print
        MOVE.B  #$20,(A2)+          ; Add space after comma
        
        ; Get desination and store into decode buffer
        MOVE.L  D0,D4               ; Store the dest reg in D4
        ANDI.W  #dst_reg,D4         ; Get the bits at 11-9
        MOVE.B  #right9,D5          ; Shift the bits 11-9 to the LSB
        LSR.W   D5,D4               ; Do the actual shift
        
        MOVE.L  D0,D3               ; D0 does not change, D3 is used to store the dst mode and src mode 
        ANDI.W  #dst_mode,D3        ; Get bits 8-6
        MOVE.B  #right6,D5          ; Shift the bits 8-6 to the LSB
        LSR.W   D5,D3               ; Do the actual shift 
        CMP.B   #1,D3               ; If dest mode is 001: An
        BEQ     DST_INVALID         ; Go to invalid message 
        JSR     EA_GEN_SRC          ; Get EA print
        
        JMP     EA_FINISH           ; Opcode is finish

           
EA_MOVEA                            ; 2: ea_movea
        MOVE.L  D0,D1
        ANDI.W  #first_nibble,D1
        MOVE.B  #right12,D5 
        LSR.W   D5,D1
        ANDI.B  #3,D1
        MOVE.B  D1,D2
        JSR     EA_SIZE_MOVEA 
        
        MOVE.B  #$20,(A2)+          ; Print out a space after the size
        
        ; Get source and store into decode buffer
        MOVE.L  D0,D4               ; Store the src reg in D4
        ANDI.W  #src_reg,D4         ; Get the bits at 2-0
        
        MOVE.L  D0,D3               ; Store the src mode in D3
        ANDI.W  #src_mode,D3        ; Get bits 5-3
        MOVE.B  #right3,D5          ; Shift the bits 5-3 to the LSB
        LSR.W   D5,D3               ; Do the actual shift 
        JSR     EA_GEN_SRC
        
        MOVE.B  #$2C,(A2)+          ; Add comma after size print
        MOVE.B  #$20,(A2)+          ; Add space after comma
        
        ; Get desination and store into decode buffer
        MOVE.L  D0,D4               ; Store the dest reg in D4
        ANDI.W  #dst_reg,D4         ; Get the bits at 11-9
        MOVE.B  #right9,D5          ; Shift the bits 11-9 to the LSB
        LSR.W   D5,D4               ; Do the actual shift
        
        MOVE.L  D0,D3               ; D0 does not change, D3 is used to store the dst mode and src mode 
        ANDI.W  #dst_mode,D3        ; Get bits 8-6
        MOVE.B  #right6,D5          ; Shift the bits 8-6 to the LSB
        LSR.W   D5,D3               ; Do the actual shift 
        CMP.B   #1,D3               ; If dst mode is 001: An 
        BEQ     MOVEA_DST_VALID     ; dst is valid, so branch 
        BRA     DST_INVALID         ; Otherwise, go to invalid message 
        
MOVEA_DST_VALID
        JSR     EA_GEN_SRC          ; Get EA print
        JMP     EA_FINISH           ; Opcode is finish

EA_LEA                              ; 3: ea_lea
        MOVE.B  #$20,(A2)+          ; print out a space after the LEA
        MOVE.B  #$20,(A2)+          ; print out a space after the LEA
        MOVE.B  #$20,(A2)+          ; print out a space after the LEA
        MOVE.B  #$20,(A2)+          ; print out a space after the LEA
        
        MOVE.L  D0,D4               ; Store the src reg in D4
        ANDI.W  #src_reg,D4         ; get the bits at 2-0
        
        MOVE.L  D0,D3               ; Store the src mode in D3
        ANDI.W  #src_mode,D3        ; get bits 5-3
        MOVE.B  #right3,D5          ; shift the bits 5-3 to the LSB
        LSR.W   D5,D3               ; do the actual shift 
        CMP     #2,D3               ; If D3 (src mode) is 010 (An)
        BEQ     LEA_SRC_VALID
        CMP     #7,D3               ; If D3 (src mode) is 111 (W or L)
        BEQ     LEA_SRC_VALID
        BRA     SRC_INVALID         ; when src mode is not 010 or 111, branch to error message
        
LEA_SRC_VALID        
        JSR     EA_GEN_SRC          ; Go to function 
 
        MOVE.B  #$2C,(A2)+          ; Add comma after size print
        MOVE.B  #$20,(A2)+          ; Add space after comma

        MOVE.L  D0,D3               ; D0 does not change, D3 is used to store the dst mode and src mode 
        ANDI.W  #dst_mode,D3        ; Get bits 8-6
        MOVE.B  #right6,D5          ; Shift the bits 8-6 to the LSB
        LSR.W   D5,D3               ; Do the actual shift
        CMP.B   #7,D3               ; Check if D3 is 111
        BEQ     CHANGE_TO_001       ; change the D3 bits to 001 
        BRA     DST_INVALID         ; Print out an error message if bits 8-6 (dst mode) are not 111
  
CHANGE_TO_001
        MOVE.B  #%001,D3            ; set D3 to 001 to ensure the print out A 
        
        MOVE.L  D0,D4               ; Store the dest reg in D4 to get the Address register number
        ANDI.W  #dst_reg,D4         ; get the bits at 11-9
        MOVE.B  #right9,D5          ; shift the bits 11-9 to the LSB
        LSR.W   D5,D4               ; do the actual shift
        JSR     EA_GEN_SRC          ; Print out the address register
        JMP     EA_FINISH           ; Opcode is finish

EA_DSTONLY                          ; 4: ea_dstonly
        MOVE.L  D0,D1
        ANDI.W  #second_nibble,D1   ; get second nibble from D1
        MOVE.B  #right8,D5 
        LSR.W   D5,D1     
        CMP.B   #2, D1              ; When 0010 for second nibble
        BEQ     EA_CLEAR            ; Then do EA_CLEAR
        CMP.B   #$E, D1             ; When 1110 for second nibble
        BEQ     EA_JSR              ; Then do EA_JSR
        BRA     DST_INVALID     
        
EA_CLEAR
        MOVE.L  D0,D1
        ANDI.W  #dst_mode,D1        ; Get bits 8-6 from D1
        MOVE.B  #right6,D5          ; Store 6 into D5
        LSR.W   D5,D1               ; Shift D1 six times to the LSB position
        ANDI.B  #3,D1               ; Remove the front bit from D1
        MOVE.B  D1,D2               ; Store D1 into D2 (D2 is used to check size)
        JSR     EA_SIZE_GENERAL     ; Get size 
        
        MOVE.B  #$20,(A2)+          ; Add space after size
        MOVE.B  #$20,(A2)+          ; Add space 
        MOVE.B  #$20,(A2)+          ; Add space 
        
        ; Get desination and store into decode buffer
        MOVE.L  D0,D4               ; Store the current address into D4 
        ANDI.W  #src_reg,D4         ; get the bits at 2-0 (D4 stores EA reg)
        
        MOVE.L  D0,D3               ; Store the current address into D3 
        ANDI.W  #src_mode,D3        ; get bits 5-3 (D3 stores EA mode)
        MOVE.B  #right3,D5          ; shift the bits 5-3 to the LSB position
        LSR.W   D5,D3               ; do the actual shift 
        CMP.B   #1,D3               ; If dest mode is 001: An
        BEQ     DST_INVALID         ; Go to invalid message 
        JSR     EA_GEN_SRC          ; When a valid dst, get EA dst print
        JMP     EA_FINISH           ; Opcode is finish
        
EA_JSR  MOVE.B  #$20,(A2)+          ; Add space 
        MOVE.B  #$20,(A2)+          ; Add space 
        MOVE.B  #$20,(A2)+          ; Add space 
        MOVE.B  #$20,(A2)+          ; Add space 
        MOVE.B  #$20,(A2)+          ; Add space 

        ; Get EA and store into decode buffer   
        MOVE.L  D0,D4               ; Store the current address into D4 
        ANDI.W  #src_reg,D4         ; get the bits at 2-0 (D4 stores EA reg)
        
        MOVE.L  D0,D3               ; Store the current address into D3 
        ANDI.W  #src_mode,D3        ; get bits 5-3 (D3 stores EA mode)
        MOVE.B  #right3,D5          ; shift the bits 5-3 to the LSB position
        LSR.W   D5,D3               ; do the actual shift 
        CMP     #2,D3               ; If D3 (src mode) is 010: (An)
        BEQ     JSR_EA_VALID
        CMP     #7,D3               ; If D3 (src mode) is 111: (W or L)
        BEQ     JSR_EA_VALID
        BRA     EA_INVALID          ; Otherwise, branch to invalid message
        
JSR_EA_VALID
        JSR     EA_GEN_SRC          ; When a valid dst, get EA dst print
        JMP     EA_FINISH           ; Opcode is finish

EA_EXT                              ; 5: ea_ext
        MOVE.L  D0,D1
        ANDI.W  #dst_mode,D1        ; Get bits 8-6 from D1 (get opmode)
        MOVE.B  #right6,D5          ; Store 6 into D5
        LSR.W   D5,D1               ; Shift D1 six times to the LSB position
        MOVE.B  D1,D2               ; Store D1 into D2 (D2 is used to check size)
        MULU    #6, D1              ; Multiply 6 to D1 
        LEA     EA_EXT_TABLE,A0     ; Load table into A0
        JMP     0(A0,D1)            ; go to displacement (A0 + D1 * 6)

EA_EXT_TABLE
        JMP     EA_OPMODE_012456    ; 000: ADD/SUB/CMP/OR/AND
        JMP     EA_OPMODE_012456    ; 001: ADD/SUB/CMP/OR/AND
        JMP     EA_OPMODE_012456    ; 010: ADD/SUB/CMP/OR/AND
        JMP     EA_OPMODE_37        ; 011: ADDA/MULS/MULU/DIVU
        JMP     EA_OPMODE_012456    ; 100: ADD/SUB/CMP/OR/AND
        JMP     EA_OPMODE_012456    ; 101: ADD/SUB/CMP/OR/AND
        JMP     EA_OPMODE_012456    ; 110: ADD/SUB/CMP/OR/AND
        JMP     EA_OPMODE_37        ; 111: ADDA/MULS/MULU/DIVU

EA_OPMODE_012456
        JSR     EA_SIZE_OPMODE_012456    
        
        MOVE.B  #$20,(A2)+          ; Print out a space after the size
        MOVE.B  #$20,(A2)+          ; Print out a space 
        MOVE.B  #$20,(A2)+          ; Print out a space
        
        ; Operation: <ea> + Dn -> Dn
        CMP.B   #%000,D2            ; When 0 then Dn is destination
        BEQ     Dn_DST
        CMP.B   #%001,D2            ; When 1 then Dn is destination
        BEQ     Dn_DST
        CMP.B   #%010,D2            ; When 2 then Dn is destination
        BEQ     Dn_DST
        
        ; Operation: Dn + <ea> -> <ea>
        CMP.B   #%100,D2            ; When 4 then Dn is source
        BEQ     Dn_SRC  
        CMP.B   #%101,D2            ; When 5 then Dn is source
        BEQ     Dn_SRC 
        CMP.B   #%110,D2            ; When 6 then Dn is source
        BEQ     Dn_SRC 
        
        BRA     EA_INVALID

Dn_DST
        ; Get source and store into decode buffer
        MOVE.L  D0,D4               ; Store the src reg in D4
        ANDI.W  #src_reg,D4         ; Get the bits at 2-0
        
        MOVE.L  D0,D3               ; Store the src mode in D3
        ANDI.W  #src_mode,D3        ; Get bits 5-3
        MOVE.B  #right3,D5          ; Shift the bits 5-3 to the LSB
        LSR.W   D5,D3               ; Do the actual shift 
        JSR     AND_OR_CHECK 
        JSR     EA_GEN_SRC          ; Get EA print
        
        MOVE.B  #$2C,(A2)+          ; Add comma after size print
        MOVE.B  #$20,(A2)+          ; Add space after comma
        
        ; Get desination and store into decode buffer
        MOVE.L  D0,D4               ; Store the dest reg in D4
        ANDI.W  #dst_reg,D4         ; Get the bits at 11-9
        MOVE.B  #right9,D5          ; Shift the bits 11-9 to the LSB
        LSR.W   D5,D4               ; Do the actual shift
        
        MOVE.L  #0,D3               ; Store 000 into D3, so it can jump to Dn 
        JSR     EA_GEN_SRC          ; Get the Dn print
        JMP     EA_FINISH           ; Opcode is finish
          
Dn_SRC  
        CMP.B   #11,D6              ; If first nibble is 1011 (indicates CMP opcode)
        BEQ     EA_INVALID          ; Then branch to error message
     
        ; Get source and store into decode buffer
        MOVE.L  D0,D4               ; Store the src reg in D4
        ANDI.W  #dst_reg,D4         ; Get the bits at 11-9
        MOVE.B  #right9,D5          ; Shift the bits 11-9 to the LSB
        LSR.W   D5,D4               ; Do the actual shift
        
        MOVE.L  #0,D3               ; Store 000 into D3, so it can jump to Dn 
        JSR     EA_GEN_SRC          ; Get the Dn print
        
        MOVE.B  #$2C,(A2)+          ; Add comma after size print
        MOVE.B  #$20,(A2)+          ; Add space after comma

        ; Get destination and store into decode buffer
        MOVE.L  D0,D4               ; Store the dst reg in D4
        ANDI.W  #src_reg,D4         ; Get the bits at 2-0
        
        MOVE.L  D0,D3               ; Store the dest mode in D3
        ANDI.W  #src_mode,D3        ; Get bits 5-3
        MOVE.B  #right3,D5          ; Shift the bits 5-3 to the LSB
        LSR.W   D5,D3               ; Do the actual shift
        JSR     An_CHECK            ; Check if mode is An
       
        JSR     EA_GEN_SRC          ; Get EA print
        JMP     EA_FINISH           ; Opcode is finish

AND_OR_CHECK
        CMP.B   #12,D6              ; If first nibble is 1100 (indicates AND opcode)
        BEQ     EA_AND              
        CMP.B   #8,D6               ; If first nibble is 1000 (indicates OR opcode)
        BEQ     EA_OR 
        RTS
EA_AND
        JMP     An_CHECK            ; Go check if mode is An 
    
EA_OR
        MOVE.B  #$20,(A2)+          ; Print out a space
        JMP     An_CHECK            ; Check if mode is An
        
EA_OPMODE_37
        CMP.B   #8,D6               ; If first nibble 1000: DIVU
        BEQ     EA_MULS_MULU_DIV
        CMP.B   #12,D6              ; If first nibble 1100: MULS/MULU
        BEQ     EA_MULS_MULU_DIV
        CMP.B   #13,D6              ; If first nibble 1101: ADDA
        BEQ     EA_ADDA                

EA_MULS_MULU_DIV
        JSR     EA_SIZE_MULS_MULU_DIV 
        MOVE.B  #1,D2               ; Set D2 to 1, since we know size is word   

        MOVE.B  #$20,(A2)+          ; Print out a space after the size
        MOVE.B  #$20,(A2)+          ; Print out a space
        
        ; Get source and store into decode buffer
        MOVE.L  D0,D4               ; Store the src reg in D4
        ANDI.W  #src_reg,D4         ; Get the bits at 2-0
        
        MOVE.L  D0,D3               ; Store the src mode in D3
        ANDI.W  #src_mode,D3        ; Get bits 5-3
        MOVE.B  #right3,D5          ; Shift the bits 5-3 to the LSB
        LSR.W   D5,D3               ; Do the actual shift
        JSR     An_CHECK            ; Check if mode is An 
        JSR     EA_GEN_SRC          ; Go get EA print
        
        MOVE.B  #$2C,(A2)+          ; Add comma after size print
        MOVE.B  #$20,(A2)+          ; Add space after comma
        
        ; Get desination and store into decode buffer
        MOVE.L  D0,D4               ; Store the dest reg in D4
        ANDI.W  #dst_reg,D4         ; Get the bits at 11-9
        MOVE.B  #right9,D5          ; Shift the bits 11-9 to the LSB
        LSR.W   D5,D4               ; Do the actual shift
        
        MOVE.L  #0,D3               ; Store 000 into D3, so it can jump to Dn 
        JSR     EA_GEN_SRC          ; Go get EA print
        JMP     EA_FINISH           ; Opcode is finish

EA_ADDA
        JSR     EA_SIZE_ADDA        ; Get size    

        MOVE.B  #$20,(A2)+          ; Print out a space after the size
        MOVE.B  #$20,(A2)+          ; Print out a space
        
        ; Get source and store into decode buffer
        MOVE.L  D0,D4               ; Store the src reg in D4
        ANDI.W  #src_reg,D4         ; Get the bits at 2-0
        
        MOVE.L  D0,D3               ; Store the src mode in D3
        ANDI.W  #src_mode,D3        ; Get bits 5-3
        MOVE.B  #right3,D5          ; Shift the bits 5-3 to the LSB
        LSR.W   D5,D3               ; Do the actual shift 
        JSR     EA_GEN_SRC
        
        MOVE.B  #$2C,(A2)+          ; Add comma after size print
        MOVE.B  #$20,(A2)+          ; Add space after comma
        
        ; Get desination and store into decode buffer
        MOVE.L  D0,D4               ; Store the dest reg in D4
        ANDI.W  #dst_reg,D4         ; Get the bits at 11-9
        MOVE.B  #right9,D5          ; Shift the bits 11-9 to the LSB
        LSR.W   D5,D4               ; Do the actual shift
        
        MOVE.L  #1,D3               ; Store 001 into D3, so it can jump to An 
        JSR     EA_GEN_SRC          ; Go get EA print
        JMP     EA_FINISH           ; Opcode is finish

EA_MOVEM        ; 6: ea_movem
        MOVE.L  D0, D1
        ANDI.W  #third_nibble,D1
        MOVE.B  #right4,D5 
        LSR.W   D5,D1
        ANDI.B  #4,D1
        MOVE.B  D1,D2
        JSR     EA_SIZE_MOVEM       ; get the size of the MOVEM as .W or .L 

        MOVE.B  #$20,(A2)+          ; Print out a space after the size
        MOVE.B  #$20,(A2)+          ; Print out a space
        
*-----------------------------------------------------------------------------------*
* HANDLE the case where src mode is 010. 
        MOVE.L  D0,D3               ; Store the src mode in D3
        ANDI.W  #src_mode,D3        ; Get bits 5-3
        MOVE.B  #right3,D5          ; Shift the bits 5-3 to the LSB
        LSR.W   D5,D3 

        CMP.B   #2, D3
        BEQ     MEM_TO_REG        

*-----------------------------------------------------------------------------------*

        MOVE.L  D0, D1
        ANDI.W  #second_nibble,D1
        MOVE.B  #right8,D5 
        LSR.W   D5,D1
        ANDI.B  #6, D1              ; Get the Dr field
        
        CMP.B   #0, D1              ; check if Dr field is 0. 
        BEQ     REG_TO_MEM

        CMP.B   #4, D1              ; check if Dr field is 1. 
        BEQ     MEM_TO_REG

REG_TO_MEM                          ; pre-decrement - D7-D0,A7-A0
        MOVE.W  (A5), D6            ; store the register list mask field for REG to MEM
        
* Print out the proper data and address registers. 
* FIRST NIBBLE CHECK D0 - D3
*-----------------------------------------------------------------------------------*
* Print out D0 if mask field states to. 

        MOVE.W  D6, D3
        ANDI.W  #first_nibble,D3
        MOVE.B  #right12,D5 
        LSR.W   D5,D3
        ANDI.B  #8,D3
        CMP.B   #8,D3
        BEQ     D4_Dn_SETONE_0      ; SETONE refers to the set for reg to mem branch. 
        BRA     CHECK1_BIT_14
D4_Dn_SETONE_0
        MOVE.B  #$0, D4
        
        BRA     PRINT1_D0
        
PRINT1_D0
        JSR     EA_Dn
        MOVE.B  #$2F,(A2)+
        
*-----------------------------------------------------------------------------------*
* Print out D1 if mask field states to. 

CHECK1_BIT_14
        MOVE.W  D6, D3
        ANDI.W  #first_nibble,D3
        MOVE.B  #right12,D5 
        LSR.W   D5,D3
        ANDI.B  #4,D3
        CMP.B   #4,D3
        BEQ     D4_Dn_SETONE_1      ; SETONE refers to the set for reg to mem branch. 
        BRA     CHECK1_BIT_13
D4_Dn_SETONE_1
        MOVE.B  #$1, D4
        
        BRA     PRINT1_D1
        
PRINT1_D1
        JSR     EA_Dn
        MOVE.B  #$2F,(A2)+

*-----------------------------------------------------------------------------------*
* Print out D2 if mask field states to. 

CHECK1_BIT_13
        MOVE.W  D6, D3
        ANDI.W  #first_nibble,D3
        MOVE.B  #right12,D5 
        LSR.W   D5,D3
        ANDI.B  #2,D3
        CMP.B   #2,D3
        BEQ     D4_Dn_SETONE_2      ; SETONE refers to the set for reg to mem branch. 
        BRA     CHECK1_BIT_12
D4_Dn_SETONE_2
        MOVE.B  #$2, D4
        
        BRA     PRINT1_D2
        
PRINT1_D2
        JSR     EA_Dn
        MOVE.B  #$2F,(A2)+       

*-----------------------------------------------------------------------------------*
* Print out D3 if mask field states to. 

CHECK1_BIT_12
        MOVE.W  D6, D3
        ANDI.W  #first_nibble,D3
        MOVE.B  #right12,D5 
        LSR.W   D5,D3
        ANDI.B  #1,D3
        CMP.B   #1,D3
        BEQ     D4_Dn_SETONE_3      ; SETONE refers to the set for reg to mem branch. 
        BRA     CHECK1_BIT_11
D4_Dn_SETONE_3
        MOVE.B  #$3, D4
        
        BRA     PRINT1_D3
        
PRINT1_D3
        JSR     EA_Dn
        MOVE.B  #$2F,(A2)+ 
        
* SECOND NIBBLE CHECK D4 - D7
*-----------------------------------------------------------------------------------*
* Print out D4 if mask field states to. 


CHECK1_BIT_11
        MOVE.W  D6, D3
        ANDI.W  #second_nibble,D3
        MOVE.B  #right8,D5 
        LSR.W   D5,D3
        ANDI.B  #8,D3
        CMP.B   #8,D3
        BEQ     D4_Dn_SETONE_4       ; SETONE refers to the set for reg to mem branch. 
        BRA     CHECK1_BIT_10
D4_Dn_SETONE_4
        MOVE.B  #$4, D4
        
        BRA     PRINT1_D4
        
PRINT1_D4
        JSR     EA_Dn
        MOVE.B  #$2F,(A2)+ 

*-----------------------------------------------------------------------------------*
* Print out D5 if mask field states to. 

CHECK1_BIT_10
        MOVE.W  D6, D3
        ANDI.W  #second_nibble,D3
        MOVE.B  #right8,D5 
        LSR.W   D5,D3
        ANDI.B  #4,D3
        CMP.B   #4,D3
        BEQ     D4_Dn_SETONE_5       ; SETONE refers to the set for reg to mem branch. 
        BRA     CHECK1_BIT_9
D4_Dn_SETONE_5
        MOVE.B  #$5, D4
        
        BRA     PRINT1_D5
        
PRINT1_D5
        JSR     EA_Dn
        MOVE.B  #$2F,(A2)+ 

*-----------------------------------------------------------------------------------*
* Print out D6 if mask field states to. 

CHECK1_BIT_9
        MOVE.W  D6, D3
        ANDI.W  #second_nibble,D3
        MOVE.B  #right8,D5 
        LSR.W   D5,D3
        ANDI.B  #2,D3
        CMP.B   #2,D3
        BEQ     D4_Dn_SETONE_6       ; SETONE refers to the set for reg to mem branch. 
        BRA     CHECK1_BIT_8
D4_Dn_SETONE_6
        MOVE.B  #$6, D4
        
        BRA     PRINT1_D6
        
PRINT1_D6
        JSR     EA_Dn
        MOVE.B  #$2F,(A2)+ 
        
*-----------------------------------------------------------------------------------*
* Print out D7 if mask field states to. 

CHECK1_BIT_8
        MOVE.W  D6, D3
        ANDI.W  #second_nibble,D3
        MOVE.B  #right8,D5 
        LSR.W   D5,D3
        ANDI.B  #1,D3
        CMP.B   #1,D3
        BEQ     D4_Dn_SETONE_7       ; SETONE refers to the set for reg to mem branch. 
        BRA     CHECK1_BIT_7
D4_Dn_SETONE_7
        MOVE.B  #$7, D4
        
        BRA     PRINT1_D7
        
PRINT1_D7
        JSR     EA_Dn
        MOVE.B  #$2F,(A2)+ 

* THIRD NIBBLE CHECK - A0 / A3
*-----------------------------------------------------------------------------------*
* Print out A0 if mask field states to. 

CHECK1_BIT_7
        MOVE.W  D6, D3
        ANDI.W  #third_nibble,D3
        MOVE.B  #right4,D5 
        LSR.W   D5,D3
        ANDI.B  #8,D3
        CMP.B   #8,D3
        BEQ     D4_An_SETONE_0       ; SETONE refers to the set for reg to mem branch. 
        BRA     CHECK1_BIT_6
D4_An_SETONE_0
        MOVE.B  #$0, D4
        
        BRA     PRINT1_A0
        
PRINT1_A0
        JSR     EA_An
        MOVE.B  #$2F,(A2)+ 
        
*-----------------------------------------------------------------------------------*
* Print out A1 if mask field states to. 

CHECK1_BIT_6
        MOVE.W  D6, D3
        ANDI.W  #third_nibble,D3
        MOVE.B  #right4,D5 
        LSR.W   D5,D3
        ANDI.B  #4,D3
        CMP.B   #4,D3
        BEQ     D4_An_SETONE_1       ; SETONE refers to the set for reg to mem branch. 
        BRA     CHECK1_BIT_5
D4_An_SETONE_1
        MOVE.B  #$1, D4
        
        BRA     PRINT1_A1
        
PRINT1_A1
        JSR     EA_An
        MOVE.B  #$2F,(A2)+ 

*-----------------------------------------------------------------------------------*
* Print out A2 if mask field states to. 

CHECK1_BIT_5
        MOVE.W  D6, D3
        ANDI.W  #third_nibble,D3
        MOVE.B  #right4,D5 
        LSR.W   D5,D3
        ANDI.B  #2,D3
        CMP.B   #2,D3
        BEQ     D4_An_SETONE_2       ; SETONE refers to the set for reg to mem branch. 
        BRA     CHECK1_BIT_4
D4_An_SETONE_2
        MOVE.B  #$2, D4
        
        BRA     PRINT1_A2
        
PRINT1_A2
        JSR     EA_An
        MOVE.B  #$2F,(A2)+ 

*-----------------------------------------------------------------------------------*
* Print out A3 if mask field states to. 

CHECK1_BIT_4
        MOVE.W  D6, D3
        ANDI.W  #third_nibble,D3
        MOVE.B  #right4,D5 
        LSR.W   D5,D3
        ANDI.B  #1,D3
        CMP.B   #1,D3
        BEQ     D4_An_SETONE_3       ; SETONE refers to the set for reg to mem branch. 
        BRA     CHECK1_BIT_3
D4_An_SETONE_3
        MOVE.B  #$3, D4
        
        BRA     PRINT1_A3
        
PRINT1_A3
        JSR     EA_An
        MOVE.B  #$2F,(A2)+ 

* FOURTH NIBBLE CHECK A4 - A7 
*-----------------------------------------------------------------------------------*
* Print out A4 if mask field states to. 

CHECK1_BIT_3
        MOVE.W  D6, D3
        ANDI.W  #fourth_nibble,D3
        ANDI.B  #8,D3
        CMP.B   #8,D3
        BEQ     D4_An_SETONE_4       ; SETONE refers to the set for reg to mem branch. 
        BRA     CHECK1_BIT_2
D4_An_SETONE_4
        MOVE.B  #$4, D4
        
        BRA     PRINT1_A4
        
PRINT1_A4
        JSR     EA_An
        MOVE.B  #$2F,(A2)+ 

*-----------------------------------------------------------------------------------*
* Print out A5 if mask field states to. 

CHECK1_BIT_2
        MOVE.W  D6, D3
        ANDI.W  #fourth_nibble,D3
        ANDI.B  #4,D3
        CMP.B   #4,D3
        BEQ     D4_An_SETONE_5       ; SETONE refers to the set for reg to mem branch. 
        BRA     CHECK1_BIT_1
D4_An_SETONE_5
        MOVE.B  #$5, D4
        
        BRA     PRINT1_A5
        
PRINT1_A5
        JSR     EA_An
        MOVE.B  #$2F,(A2)+ 

*-----------------------------------------------------------------------------------*
* Print out A6 if mask field states to. 

CHECK1_BIT_1
        MOVE.W  D6, D3
        ANDI.W  #fourth_nibble,D3
        ANDI.B  #2,D3
        CMP.B   #2,D3
        BEQ     D4_An_SETONE_6       ; SETONE refers to the set for reg to mem branch. 
        BRA     CHECK1_BIT_0
D4_An_SETONE_6
        MOVE.B  #$6, D4
        
        BRA     PRINT1_A6
        
PRINT1_A6
        JSR     EA_An
        MOVE.B  #$2F,(A2)+ 

*-----------------------------------------------------------------------------------*
* Print out A7 if mask field states to. 

CHECK1_BIT_0
        MOVE.W  D6, D3
        ANDI.W  #fourth_nibble,D3
        ANDI.B  #1,D3
        CMP.B   #1,D3
        BEQ     D4_An_SETONE_7       ; SETONE refers to the set for reg to mem branch. 
        BRA     FINISH_REG_TO_MEM
D4_An_SETONE_7
        MOVE.B  #$7, D4
        
        BRA     PRINT1_A7
        
PRINT1_A7
        JSR     EA_An
        MOVE.B  #$2F,(A2)+ 

FINISH_REG_TO_MEM
        MOVE.B  #$2C,(A2)+          ; Add comma after size print
        MOVE.B  #$20,(A2)+          ; Add space after comma

        MOVE.L  D0,D4               ; Store the src reg in D4
        ANDI.W  #src_reg,D4         ; Get the bits at 2-0
        
        MOVE.L  D0,D3               ; Store the src mode in D3
        ANDI.W  #src_mode,D3        ; Get bits 5-3
        MOVE.B  #right3,D5          ; Shift the bits 5-3 to the LSB
        LSR.W   D5,D3               ; Do the actual shift 
        JSR     EA_GEN_SRC
        
        MOVE.W  (A5)+, D0 

        JMP     EA_FINISH

MEM_TO_REG                          ; post-increment + A7-A0,D7-D0

        CMP.B   #2, D3              ; check if the destination is (An)
        BEQ     MEM_TO_REG_CONTINUE ; branch to print out the address and data registers. 
        
        MOVE.L  D0,D4               ; Store the src reg in D4
        ANDI.W  #src_reg,D4         ; Get the bits at 2-0
        
        MOVE.L  D0,D3               ; Store the src mode in D3
        ANDI.W  #src_mode,D3        ; Get bits 5-3
        MOVE.B  #right3,D5          ; Shift the bits 5-3 to the LSB
        LSR.W   D5,D3               ; Do the actual shift 
        JSR     EA_GEN_SRC
        
        MOVE.B  #$2C,(A2)+          ; Add comma after size print
        MOVE.B  #$20,(A2)+          ; Add space after comma

        
* Print out the proper data and address registers. 
* FIRST NIBBLE CHECK A7 - A4
*-----------------------------------------------------------------------------------*
* Print out A7 if mask field states to. 
MEM_TO_REG_CONTINUE
        MOVE.W  (A5), D6            ; store the register list mask field for MEM to REG
        
        MOVE.W  D6, D3
        ANDI.W  #first_nibble,D3
        MOVE.B  #right12,D5 
        LSR.W   D5,D3
        ANDI.B  #8,D3
        CMP.B   #8,D3
        BEQ     D4_An_SET_7
        BRA     CHECK_BIT_14
D4_An_SET_7
        MOVE.B  #$7, D4
        
        BRA     PRINT_A7
        
PRINT_A7
        JSR     EA_An
        MOVE.B  #$2F,(A2)+
        
*-----------------------------------------------------------------------------------*
* Print out A6 if mask field states to. 

CHECK_BIT_14
        MOVE.W  D6, D3
        ANDI.W  #first_nibble,D3
        MOVE.B  #right12,D5 
        LSR.W   D5,D3
        ANDI.B  #4,D3
        CMP.B   #4,D3
        BEQ     D4_An_SET_6
        BRA     CHECK_BIT_13
D4_An_SET_6
        MOVE.B  #$6, D4
        
        BRA     PRINT_A6
        
PRINT_A6
        JSR     EA_An
        MOVE.B  #$2F,(A2)+

*-----------------------------------------------------------------------------------*
* Print out A5 if mask field states to. 

CHECK_BIT_13
        MOVE.W  D6, D3
        ANDI.W  #first_nibble,D3
        MOVE.B  #right12,D5 
        LSR.W   D5,D3
        ANDI.B  #2,D3
        CMP.B   #2,D3
        BEQ     D4_An_SET_5
        BRA     CHECK_BIT_12
D4_An_SET_5
        MOVE.B  #$5, D4
        
        BRA     PRINT_A5
        
PRINT_A5
        JSR     EA_An
        MOVE.B  #$2F,(A2)+

*-----------------------------------------------------------------------------------*
* Print out A4 if mask field states to. 
        
CHECK_BIT_12
        MOVE.W  D6, D3
        ANDI.W  #first_nibble,D3
        MOVE.B  #right12,D5 
        LSR.W   D5,D3
        ANDI.B  #1,D3
        CMP.B   #1,D3
        BEQ     D4_An_SET_4
        BRA     CHECK_BIT_11
D4_An_SET_4
        MOVE.B  #$4, D4
        
        BRA     PRINT_A4
        
PRINT_A4
        JSR     EA_An
        MOVE.B  #$2F,(A2)+

*-----------------------------------------------------------------------------------*
* Print out A3 if mask field states to. 
* SECOND NIBBLE CHECK A7 - A4
  
CHECK_BIT_11
        MOVE.W  D6, D3
        ANDI.W  #second_nibble,D3
        MOVE.B  #right8,D5 
        LSR.W   D5,D3
        ANDI.B  #8,D3
        CMP.B   #8,D3
        BEQ     D4_An_SET_3
        BRA     CHECK_BIT_10
D4_An_SET_3
        MOVE.B  #$3, D4
        
        BRA     PRINT_A3
        
PRINT_A3
        JSR     EA_An
        MOVE.B  #$2F,(A2)+     

*-----------------------------------------------------------------------------------*
* Print out A2 if mask field states to. 
  
CHECK_BIT_10
        MOVE.W  D6, D3
        ANDI.W  #second_nibble,D3
        MOVE.B  #right8,D5 
        LSR.W   D5,D3
        ANDI.B  #4,D3
        CMP.B   #4,D3
        BEQ     D4_An_SET_2
        BRA     CHECK_BIT_9
D4_An_SET_2
        MOVE.B  #$2, D4
        
        BRA     PRINT_A2
        
PRINT_A2
        JSR     EA_An
        MOVE.B  #$2F,(A2)+  

*-----------------------------------------------------------------------------------*
* Print out A1 if mask field states to. 
  
CHECK_BIT_9
        MOVE.W  D6, D3
        ANDI.W  #second_nibble,D3
        MOVE.B  #right8,D5 
        LSR.W   D5,D3
        ANDI.B  #2,D3
        CMP.B   #2,D3
        BEQ     D4_An_SET_1
        BRA     CHECK_BIT_8
D4_An_SET_1
        MOVE.B  #$1, D4
        
        BRA     PRINT_A2
        
PRINT_A1
        JSR     EA_An
        MOVE.B  #$2F,(A2)+ 

*-----------------------------------------------------------------------------------*
* Print out A0 if mask field states to. 
  
CHECK_BIT_8
        MOVE.W  D6, D3
        ANDI.W  #second_nibble,D3
        MOVE.B  #right8,D5 
        LSR.W   D5,D3
        ANDI.B  #1,D3
        CMP.B   #1,D3
        BEQ     D4_An_SET_0
        BRA     CHECK_BIT_7
D4_An_SET_0
        MOVE.B  #$0, D4
        
        BRA     PRINT_A0
        
PRINT_A0
        JSR     EA_An
        MOVE.B  #$2F,(A2)+        

*-----------------------------------------------------------------------------------*
* Print out D7 if mask field states to. 
* THIRD NIBBLE CHECK D7-D0

CHECK_BIT_7
        MOVE.W  D6, D3
        ANDI.W  #third_nibble,D3
        MOVE.B  #right4,D5 
        LSR.W   D5,D3
        ANDI.B  #8,D3
        CMP.B   #8,D3
        BEQ     D4_Dn_SET_7
        BRA     CHECK_BIT_6
D4_Dn_SET_7
        MOVE.B  #$7, D4
        
        BRA     PRINT_D7
        
PRINT_D7
        JSR     EA_Dn
        MOVE.B  #$2F,(A2)+

*-----------------------------------------------------------------------------------*
* Print out D6 if mask field states to. 

CHECK_BIT_6
        MOVE.W  D6, D3
        ANDI.W  #third_nibble,D3
        MOVE.B  #right4,D5 
        LSR.W   D5,D3
        ANDI.B  #4,D3
        CMP.B   #4,D3
        BEQ     D4_Dn_SET_6
        BRA     CHECK_BIT_5
D4_Dn_SET_6
        MOVE.B  #$6, D4
        
        BRA     PRINT_D6
        
PRINT_D6
        JSR     EA_Dn
        MOVE.B  #$2F,(A2)+

*-----------------------------------------------------------------------------------*
* Print out D5 if mask field states to. 

CHECK_BIT_5
        MOVE.W  D6, D3
        ANDI.W  #third_nibble,D3
        MOVE.B  #right4,D5 
        LSR.W   D5,D3
        ANDI.B  #2,D3
        CMP.B   #2,D3
        BEQ     D4_Dn_SET_5
        BRA     CHECK_BIT_4
D4_Dn_SET_5
        MOVE.B  #$5, D4
        
        BRA     PRINT_D5
        
PRINT_D5
        JSR     EA_Dn
        MOVE.B  #$2F,(A2)+

*-----------------------------------------------------------------------------------*
* Print out D4 if mask field states to. 

CHECK_BIT_4
        MOVE.W  D6, D3
        ANDI.W  #third_nibble,D3
        MOVE.B  #right4,D5 
        LSR.W   D5,D3
        ANDI.B  #1,D3
        CMP.B   #1,D3
        BEQ     D4_Dn_SET_4
        BRA     CHECK_BIT_3
D4_Dn_SET_4
        MOVE.B  #$4, D4
        
        BRA     PRINT_D4
        
PRINT_D4
        JSR     EA_Dn
        MOVE.B  #$2F,(A2)+

*-----------------------------------------------------------------------------------*
* Print out D3 if mask field states to. 
* FOURTH NIBBLE CHECK / D3 - D0

CHECK_BIT_3
        MOVE.W  D6, D3
        ANDI.W  #fourth_nibble,D3
        ANDI.B  #8,D3
        CMP.B   #8,D3
        BEQ     D4_Dn_SET_3
        BRA     CHECK_BIT_2
D4_Dn_SET_3
        MOVE.B  #$3, D4
        
        BRA     PRINT_D3
        
PRINT_D3
        JSR     EA_Dn
        MOVE.B  #$2F,(A2)+

*-----------------------------------------------------------------------------------*
* Print out D2 if mask field states to. 

CHECK_BIT_2
        MOVE.W  D6, D3
        ANDI.W  #fourth_nibble,D3
        ANDI.B  #4,D3
        CMP.B   #4,D3
        BEQ     D4_Dn_SET_2
        BRA     CHECK_BIT_1
D4_Dn_SET_2
        MOVE.B  #$2, D4
        
        BRA     PRINT_D2
        
PRINT_D2
        JSR     EA_Dn
        MOVE.B  #$2F,(A2)+

*-----------------------------------------------------------------------------------*
* Print out D1 if mask field states to. 

CHECK_BIT_1
        MOVE.W  D6, D3
        ANDI.W  #fourth_nibble,D3
        ANDI.B  #2,D3
        CMP.B   #2,D3
        BEQ     D4_Dn_SET_1
        BRA     CHECK_BIT_0
D4_Dn_SET_1
        MOVE.B  #$1, D4
        
        BRA     PRINT_D1
        
PRINT_D1
        JSR     EA_Dn
        MOVE.B  #$2F,(A2)+

*-----------------------------------------------------------------------------------*
* Print out D0 if mask field states to. 

CHECK_BIT_0
        MOVE.W  D6, D3
        ANDI.W  #fourth_nibble,D3
        ANDI.B  #1,D3
        CMP.B   #1,D3
        BEQ     D4_Dn_SET_0
        BRA     FINISH_MOVEM_MEM_TO_REG
D4_Dn_SET_0
        MOVE.B  #$0, D4
        
        BRA     PRINT_D0
        
PRINT_D0
        JSR     EA_Dn
        MOVE.B  #$2F,(A2)+

FINISH_MOVEM_MEM_TO_REG
        
        MOVE.L  D0,D3               ; Store the src mode in D3
        ANDI.W  #src_mode,D3        ; Get bits 5-3
        MOVE.B  #right3,D5          ; Shift the bits 5-3 to the LSB
        LSR.W   D5,D3               ; Do the actual shift

        MOVE.L  D0,D4               ; Store the dst reg in D4
        ANDI.W  #src_reg,D4         ; Get the bits at 2-0
 
        CMP.B   #2, D3
        BEQ     An_FINISH           ; branch to print out (An) 
        BRA     NORMAL_FINISH       ; branch to the normal finish

An_FINISH
        MOVE.B  #$2C,(A2)+          ; Add comma after size print
        MOVE.B  #$20,(A2)+          ; Add space after comma
        
                    
        JSR     EA_GEN_SRC

NORMAL_FINISH
        MOVE.W  (A5)+, D0
        
        JMP     EA_FINISH


EA_SHIFTS       ; 7: ea_shifts
        MOVE.L  D0,D1               ; D0 is current instruction word
        ANDI.W  #dst_mode,D1        ; Extract 8-6 bits from instruction word
        MOVE.B  #right6,D5          ; Used to shift 6 times to right
        LSR.W   D5,D1               ; Shift dst mode into LSB position
        MULU    #6, D1              ; Set displacement 
        LEA     EA_SHIFTS_TABLE,A0  ; Load table into A0
        JMP     0(A0,D1)            ; go to displacement (A0 + D1 * 6)

EA_SHIFTS_TABLE
        JMP     EA_REGISTER_SHIFTS  ; 000 Register
        JMP     EA_REGISTER_SHIFTS  ; 001 Register
        JMP     EA_REGISTER_SHIFTS  ; 010 Register
        JMP     EA_MEMORY_SHIFTS    ; 011 Memory
        JMP     EA_REGISTER_SHIFTS  ; 100 Register
        JMP     EA_REGISTER_SHIFTS  ; 101 Register
        JMP     EA_REGISTER_SHIFTS  ; 110 Register
        JMP     EA_MEMORY_SHIFTS    ; 111 Memory
        
EA_MEMORY_SHIFTS
        ; Get EA and store into decode buffer
        MOVE.L  D0,D4               ; Store the EA reg in D4
        ANDI.W  #src_reg,D4         ; Get the bits at 2-0
        
        MOVE.L  D0,D3               ; Store the EA mode in D3
        ANDI.W  #src_mode,D3        ; Get bits 5-3
        MOVE.B  #right3,D5          ; Shift the bits 5-3 to the LSB
        LSR.W   D5,D3               ; Do the actual shift
        JSR     An_CHECK            ; Check if mode is An 
        JSR     Dn_CHECK            ; Check if mode is Dn
        JSR     IMMEDIATE_CHECK     ; Check if mode is immediate
        
        MOVE.B  #$20,(A2)+          ; Print out a space 
        MOVE.B  #$20,(A2)+          ; Print out a space
        MOVE.B  #$20,(A2)+          ; Print out a space
        MOVE.B  #$20,(A2)+          ; Print out a space
        
        JSR     FRONT_FORMAT
        JSR     EA_GEN_SRC          ; Go get EA print
        CMP.B   #$2A,D3             ; When mode is 111 * 6 (2A)
        BEQ     BACK_PARENTHESIS  
        JMP     EA_FINISH           ; Opcode is finish

FRONT_FORMAT
        CMP.B   #7,D3               ; When mode is 111
        BEQ     ADD_PARENTHESIS
        MOVE.B  #$20,(A2)+          ; Print out a space
        RTS
        
ADD_PARENTHESIS
        MOVE.B  #$20,(A2)+          ; Print out a space
        MOVE.B  #'(',(A2)+
        RTS
        
BACK_PARENTHESIS            
        MOVE.B  #')',(A2)+
        MOVE.B  D4,D2
        JSR     EA_SIZE_MEMORY_SHIFTS
        JMP     EA_FINISH           ; Opcode is finish
    
EA_REGISTER_SHIFTS
        MOVE.L  D0,D1
        ANDI.W  #dst_mode,D1
        MOVE.B  #right6,D5 
        LSR.W   D5,D1
        ANDI.B  #3,D1               ; Remove bit 8 and get bits 7-6
        MOVE.B  D1,D2
        JSR     EA_SIZE_GENERAL
        
        MOVE.L  D0,D3               ; Store the instruction in D3
        ANDI.W  #src_mode,D3        ; Get bits 5-3
        MOVE.B  #right3,D5          ; Shift the bits 5-3 to the LSB
        LSR.W   D5,D3               ; Do the actual shift 
        ANDI.B  #4,D3               ; Get bit 5(ir) from bits 5-3
        LSR.W   #2,D3

        CMP.B   #0,D3               ; When D1 is 0 (immediate)
        BEQ     IMMEDIATE_SRC
        BRA     REGISTER_SRC        ; When D1 is 1 (register)
        
IMMEDIATE_SRC
        MOVE.B  #$20,(A2)+          ; Add space
        MOVE.B  #$20,(A2)+          ; Add space
        MOVE.B  #$20,(A2)+          ; Add space
        
        ; Get source and store into decode buffer
        MOVE.L  D0,D4               ; Store the src reg in D4
        ANDI.W  #dst_reg,D4         ; Get the bits at 11-9
        MOVE.B  #right9,D5          ; Shift the bits 11-9 to the LSB
        LSR.W   D5,D4               ; Do the actual shift
        JSR     CHECK_IF_ZERO       ; Check if register is 0
        
        MOVE.B  #$23,(A2)+          ; Add # symbol
        ADDI.B  #$30,D4             ; Convert hex to ASCII
        MOVE.B  D4,(A2)+            ; Store into buffer
        
        MOVE.B  #$2C,(A2)+          ; Add comma after size print
        MOVE.B  #$20,(A2)+          ; Add space after comma

        ; Get destination and store into decode buffer
        MOVE.L  D0,D4               ; Store the src reg in D4
        ANDI.W  #src_reg,D4         ; Get the bits at 2-0
        JSR     EA_Dn               ; store Dn into decode buffer
        JMP     EA_FINISH           ; Opcode is finish
              
CHECK_IF_ZERO
        CMP.B   #0,D4               ; When D4 is 0 
        BEQ     IMMEDIATE_EIGHT     ; Branch
        RTS

IMMEDIATE_EIGHT
        MOVE.B  #8,D4               ; Store 8 into D4 
        RTS

REGISTER_SRC        
        MOVE.B  #$20,(A2)+          ; Add space
        MOVE.B  #$20,(A2)+          ; Add space
        MOVE.B  #$20,(A2)+          ; Add space
        
        ; Get source and store into decode buffer
        MOVE.L  D0,D4               ; Store the src reg in D4
        ANDI.W  #dst_reg,D4         ; Get the bits at 11-9
        MOVE.B  #right9,D5          ; Shift the bits 11-9 to the LSB
        LSR.W   D5,D4               ; Do the actual shift
        JSR     EA_Dn               ; store Dn into decode buffer
        
        MOVE.B  #$2C,(A2)+          ; Add comma after size print
        MOVE.B  #$20,(A2)+          ; Add space after comma

        ; Get destination and store into decode buffer
        MOVE.L  D0,D4               ; Store the src reg in D4
        ANDI.W  #src_reg,D4         ; Get the bits at 2-0
        JSR     EA_Dn               ; store Dn into decode buffer
        JMP     EA_FINISH           ; Opcode is finish

EA_QUICK        ; 8: ea_quick
        CMP.B   #5, D6              ; check if the first nibble is 5 for ADDQ
        BEQ     ADDQ_EA_CALC
        
        CMP.B   #7, D6              ; check if the first nibble is 7 for MOVEQ
        BEQ     MOVEQ_EA_CALC
        
ADDQ_EA_CALC
        MOVE.L  D0,D1
        ANDI.W  #dst_mode,D1        ; Get bits 8-6 from D1
        MOVE.B  #right6,D5          ; Store 6 into D5
        LSR.W   D5,D1               ; Shift D1 six times to the LSB position
        ANDI.B  #3,D1               ; Remove the front bit from D1
        MOVE.B  D1,D2               ; Store D1 into D2 (D2 is used to check size)
        JSR     EA_SIZE_GENERAL     ; Get size and print size.
        
        MOVE.B  #$20,(A2)+          ; Add space after size
        MOVE.B  #$20,(A2)+          ; Add space
        
        MOVE.B  #$23,(A2)+          ; Add # symbol
        MOVE.B  #$24,(A2)+          ; Add $ symbol
        
        MOVE.L  D0,D4               ; Store the data in D4
        ANDI.W  #dst_reg,D4         ; Get the bits at 11-9
        MOVE.B  #right9,D5          ; Shift the bits 11-9 to the LSB
        LSR.W   D5,D4               ; Do the actual shift
        
        CMP.B   #0, D4
        BEQ     CHANGE_TO_EIGHT
        
        BRA     DONT_CHANGE

CHANGE_TO_EIGHT
        MOVE.B  #8, D4

DONT_CHANGE        
        ADDI.B  #$30, D4
        MOVE.B  D4, (A2)+      
        
        MOVE.B  #$2C,(A2)+          ; Add comma after size print
        MOVE.B  #$20,(A2)+          ; Add space after comma
        
        MOVE.L  D0,D4               ; Store the src reg in D4
        ANDI.W  #src_reg,D4         ; Get the bits at 2-0
        
        MOVE.L  D0,D3               ; Store the src mode in D3
        ANDI.W  #src_mode,D3        ; Get bits 5-3
        MOVE.B  #right3,D5          ; Shift the bits 5-3 to the LSB
        LSR.W   D5,D3               ; Do the actual shift 
        JSR     EA_GEN_SRC
        
        JMP     EA_FINISH

MOVEQ_EA_CALC
        MOVE.B  #$20,(A2)+          ; print out a space after the LEA
        MOVE.B  #$20,(A2)+          ; print out a space after the LEA
        MOVE.B  #$20,(A2)+          ; print out a space after the LEA
        MOVE.B  #$20,(A2)+          ; print out a space after the LEA
        MOVE.B  #$23,(A2)+          ; Add # symbol
        MOVE.B  #$24,(A2)+          ; Add $ symbol
        
        MOVE.L  D0, D1              ; move D0 to D1
        ANDI.W  #second_half, D1    ; get the second 8 bits of D1
        MOVE.B  D1, D5              ; move D1 to D5 to convert it to ASCII
        
        JSR     ITOA_BYTE_BRANCH    ; print out the bit of data
        
        MOVE.B  #$2C,(A2)+          ; Add comma after size print
        MOVE.B  #$20,(A2)+          ; Add space after comma
        
        MOVE.L  D0,D4               ; Store the data in D4
        ANDI.W  #dst_reg,D4         ; Get the bits at 11-9
        MOVE.B  #right9,D5          ; Shift the bits 11-9 to the LSB
        LSR.W   D5,D4               ; Do the actual shift
        JSR     EA_GEN_SRC
        
        JMP     EA_FINISH

EA_BRANCH       ; 9: ea_branch
        MOVE.B  #$20,(A2)+          ; print out a space after the Branch
        MOVE.B  #$20,(A2)+          ; print out a space after the Branch
        MOVE.B  #$20,(A2)+          ; print out a space after the Branch
        MOVE.B  #$20,(A2)+          ; print out a space after the Branch

        MOVE.L  D0,D3               ; D0 is current instruction word
        ANDI.W  #third_nibble,D3   ; Extract 3rd nibble from instruction word
        MOVE.B  #right4,D5
        
        MOVE.L  D0,D4               ; D0 is current instruction word
        ANDI.W  #fourth_nibble,D4   ; Extract 4th nibble from instruction word
         
        CMP.B   #0,D3               ; check if 3rd nibble is 0. 
        BEQ     FOURTH_NIBBLE_CHECK
        
        BRA     BRANCH_WORD_CHECK
        
FOURTH_NIBBLE_CHECK                 
        CMP.B   #0,D4               ; check if the 4th nibble is 0. 
        
        MOVE.W  (A5), D5            ; store the 16-bit displacement into D5
        
        MOVE.L  A5, D3              ; Store A5 address into D3
        
        ADD.W   D3, D5              ; Add the address to D5 to get the displacement. 
        
        MOVE.B  #$24,(A2)+          ; Add $ symbol
        
        JSR     ITOA_WORD_BRANCH    ; Print. 

        JMP     EA_FINISH

BRANCH_WORD_CHECK
        CLR     D5                  ; handles 8-bit displacement. 
        ADD.B   D3,D5               ; add d3 and d4 to d5
        ADD.B   D4,D5
        
        JSR     ITOA_BYTE_BRANCH    ; Print. 

        JMP     EA_FINISH

EA_REG

EA_GEN_SRC
        LEA     EA_GEN_TABLE_SRC, A0
        MULU    #6, D3              ; use D3 to jump to the proper src mode and dst mode. 
        JMP     0(A0,D3)            ; jump to each ea src generation table entry 

EA_GEN_TABLE_SRC
        JMP     EA_Dn                       ; 000: Dn
        JMP     EA_An                       ; 001: An
        JMP     EA_An_Indirect              ; 010: (An)
        JMP     EA_An_Indirect_Inc          ; 011: (An)+
        JMP     EA_An_Indirect_Dec          ; 100: -(An)
        JMP     EA_UNSUPPORTED              ; 101: Unsupported EA
        JMP     EA_UNSUPPORTED              ; 110: Unsupported EA
        JMP     EA_Absolute_And_Immediate   ; 111: (xxx).W,(xxx).L, or #<data>

EA_Dn               ; 000: Dn
        MOVE.B  #'D',(A2)+
        ADDI.B  #$30,D4
        MOVE.B  D4,(A2)+
        RTS

EA_An               ; 001: An
        MOVE.B  #'A',(A2)+
        ADDI.B  #$30,D4
        MOVE.B  D4,(A2)+
        RTS

EA_An_Indirect      ; 010: (An)
        MOVE.B  #'(',(A2)+
        MOVE.B  #'A',(A2)+
        ADDI.B  #$30,D4
        MOVE.B  D4,(A2)+
        MOVE.B  #')',(A2)+
        RTS
        
EA_An_Indirect_Inc  ; 011: (An)+
        MOVE.B  #'(',(A2)+
        MOVE.B  #'A',(A2)+
        ADDI.B  #$30, D4
        MOVE.B  D4,(A2)+
        MOVE.B  #')',(A2)+
        MOVE.B  #'+',(A2)+
        RTS
        
EA_An_Indirect_Dec  ; 100: -(An)
        MOVE.B  #'-',(A2)+
        MOVE.B  #'(',(A2)+
        MOVE.B  #'A',(A2)+
        ADDI.B  #$30,D4
        MOVE.B  D4,(A2)+
        MOVE.B  #')',(A2)+
        RTS

EA_UNSUPPORTED
        LEA     EA_TYPE_ERROR,A1
        MOVE.B  #14,D0
        TRAP    #15  
        RTS 
        
EA_Absolute_And_Immediate           ; 111: (xxx).W,(xxx).L, or #<data>
        CMP.B   #0,D4               ; If D4 is (xxx).W
        BEQ     ABSOLUTE_WORD
        
        CMP.B   #1,D4               ; If D4 is (xxx).L
        BEQ     ABSOLUTE_LONG
        
        CMP.B   #4,D4               ; If D4 is #<data>  
        BEQ     IMMEDIATE
        
        BRA     ABSOLUTE_IMMEDIATE_ERROR    

ABSOLUTE_WORD
        MOVE.B  #$24,(A2)+          ; Add $ symbol
        MOVE.L  #1,D2               ; Insert 1 to D2 
        JSR     ITOA                ; Convert word hex values to ITOA
        RTS
        
ABSOLUTE_LONG
        MOVE.B  #$24,(A2)+          ; Add $ symbol
        MOVE.L  #2,D2               ; Insert 2 to D2
        JSR     ITOA                ; Convert long hex values to ITOA
        RTS
   
IMMEDIATE
        MOVE.B  #$23,(A2)+          ; Add # symbol
        MOVE.B  #$24,(A2)+          ; Add $ symbol

        CMP.B   #1,D6               ; If MOVE.b (code0001)
        BEQ     DO_ITOA_MOVE
        CMP.B   #2, D6              ; If MOVE.l / MOVEA.l (code0010)
        BEQ     DO_ITOA_MOVE
        CMP.B   #3, D6              ; If MOVE.w / MOVEA.w (code0011)
        BEQ     DO_ITOA_MOVE        
        CMP.B   #13, D6             ; If ADD / ADDA (code1101)
        BEQ     DO_ITOA_OPMODE
        
        JSR     ITOA                ; Go to ITOA when not a move instruction
        RTS
        
DO_ITOA_MOVE
        JSR ITOA_MOVE
        RTS
              
DO_ITOA_OPMODE
        JSR ITOA_OPMODE
        RTS

An_CHECK 
        CMP.B   #1,D3               ; If mode is An     
        BEQ     EA_INVALID          ; Then branch to error message
        RTS   
      
Dn_CHECK 
        CMP.B   #0,D3               ; If mode is An     
        BEQ     EA_INVALID          ; Then branch to error message
        RTS    
     
IMMEDIATE_CHECK
        CMP.B   #7,D3
        BEQ     REGISTER_CHECK
        RTS
        
REGISTER_CHECK
        CMP.B   #4,D3               ; If 100 in register
        BEQ     EA_INVALID          ; Branch to invalid
        RTS   
              
EA_WRONG_SIZE 
        LEA     WRONG_SIZE_MESSAGE, A1 
        MOVE.B  #14, D0
        TRAP    #15
        BRA     DONE
        
ABSOLUTE_IMMEDIATE_ERROR  
        LEA     ABSOLUTE_WRONGREG, A1 
        MOVE.B  #14, D0
        TRAP    #15
        BRA     DONE
        
DST_INVALID
        LEA     DST_INVALID_MSG, A1 
        MOVE.B  #14, D0
        TRAP    #15
        BRA     DONE
        
SRC_INVALID 
        LEA     SRC_INVALID_MSG, A1 
        MOVE.B  #14, D0
        TRAP    #15
        BRA     DONE
        
EA_INVALID  
        LEA     EA_INVALID_MSG, A1 
        MOVE.B  #14, D0
        TRAP    #15
        BRA     DONE
         
DONE    SIMHALT             ; halt simulator

* Put variables and constants here
   
       
buffer_size         EQU         64 
decoded_buffer      EQU         $5000
   
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
second_half         EQU         $00FF
dst_mode            EQU         $01C0
dst_reg             EQU         $0E00
src_mode            EQU         $0038
src_reg             EQU         $0007
bit8                EQU         $0100

ea_type_immediate   EQU     0       ; EA Type = immediate
ea_type_move        EQU     1       ; EA Type = move
ea_type_movea       EQU     2       ; EA Type = movea
ea_type_movea6      EQU     12      ; EA Type = movea * 6
ea_type_lea         EQU     3       ; EA Type = lea
ea_type_dstonly     EQU     4       ; EA Type = clr, neg, not, jsr, jmp
ea_type_ext         EQU     5       ; EA Type = ext, add, adda
ea_type_movem       EQU     6       ; EA Type = movem
ea_type_shifts      EQU     7       ; EA Type = ASL/ASR/LSL/LSR/ROL/ROR
; ea_type_trap        EQU     7       ; EA Type = trap
ea_type_quick       EQU     8       ; EA Type = addq, subq
ea_type_branch      EQU     9       ; EA Type = bra, bsr, bcc
ea_bcc_flag         EQU     0       ; EA Type = branch, flag = bcc
ea_dbcc_flag        EQU     1       ; EA Type = branch, flag = dbcc
ea_scc_flag         EQU     2       ; EA Type = branch, flag = scc
ea_type_shifts      EQU     7

WRONG_SIZE_MESSAGE  DC.B    'Wrong size.',CR,LF,0
ABSOLUTE_WRONGREG   DC.B    'ERROR: Register does not exist for Absolute and immediate',CR,LF,0
EA_TYPE_ERROR       DC.B    'ERROR: EA type is not supported',CR,LF,0
DST_INVALID_MSG     DC.B    'ERROR: Destination effective address is invalid',CR,LF,0
SRC_INVALID_MSG     DC.B    'ERROR: Source effective address is invalid',CR,LF,0
EA_INVALID_MSG      DC.B    'ERROR: Invalid addressing mode',CR,LF,0
OPCODE_INVALID      DC.B    'ERROR: Opcode is invalid',CR,LF,0
ERROR_MESSAGE       DC.B    'ERROR: The input is invalid',CR,LF,0  
ODD_ERROR_MESSAGE   DC.B    'ERROR: The last digit of the address is odd, which is invalid',CR,LF,0  
             
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
     

    END    START        ; last line of source



*~Font name~Courier New~
*~Font size~10~
*~Tab type~1~
*~Tab size~4~







*~Font name~Courier New~
*~Font size~10~
*~Tab type~1~
*~Tab size~4~
