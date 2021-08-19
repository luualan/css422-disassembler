*-----------------------------------------------------------
* Title      :
* Written by :
* Date       :
* Description:
*-----------------------------------------------------------
    ORG    $1000
START:                  ; first instruction of program

* Put program code here
    MOVEA.L #$4E75, A5
    JMP JSR_NOP_RTS
    MOVE.B  #45, D1


JSR_NOP_RTS:
    MOVE.L  A5,D1               ; A5 is current instruction word
    ANDI.W  #dst_mode,D1        ; Extract dst mode position from instruction word
    MOVE.B  #right6,D2          ; Used to shift 6 times to right
    LSR.W   D2,D1               ; Shift dst mode into LSB position
    CMP.B   #2, D1              ; When 010 in destination mode
    BEQ     OP_JSR              ; Go to opcode JSR
    MOVE.L  A5,D1               ; A5 is current instruction word
    ANDI.W  #src_reg ,D1        ; Extract src reg position from instruction word
    CMP.B   #1, D1              ; When 001 in src register
    BEQ     OP_NOP              ; Go to opcode NOP
    CMP.B   #5, D1              ; When 005 in src register
    BEQ     OP_RTS              ; Go to opcode RTS
    BRA     OP_UNSUPPORTED      ; Otherwise, go to opcode unsupported 

OP_JSR
    LEA     JSR,A1        ; Display starting address message
    MOVE.B  #14,D0
    TRAP    #15
    BRA     DONE  
    
OP_NOP
    LEA     NOP,A1        ; Display starting address message
    MOVE.B  #14,D0
    TRAP    #15
    BRA     DONE

OP_RTS
    LEA     RTS,A1        ; Display starting address message
    MOVE.B  #14,D0
    TRAP    #15 
     BRA     DONE   
    
OP_UNSUPPORTED
    LEA     UNSUPPORTED,A1        ; Display starting address message
    MOVE.B  #14,D0
    TRAP    #15  
     BRA     DONE

DONE
    SIMHALT             ; halt simulator

* Put variables and constants here
src_reg         EQU         $0007
dst_mode        EQU         $00C0
right6          EQU         6


JSR             DC.B        'JSR',0
NOP             DC.B        'OP_NOP',0 
RTS             DC.B        'OP_RTS',0 
UNSUPPORTED     DC.B        'SSSSSSSS',0 


    END    START        ; last line of source

*~Font name~Courier New~
*~Font size~10~
*~Tab type~1~
*~Tab size~4~
