;.387
;******************************************************************************
;
;       MODULA-2    Run-Time Support   ( RTS )
;
;              LOGITECH SA,   CH-1122 Romanel    (Switzerland)
;              LOGITECH Inc,  Fremont, CA 94555  (USA)
;
;       Module  :    RTSInterrupt, implementation of IOTRANSFER
;
;       Release :    3.10 - July 89
;
;       Copyright (C)  1987 - 1989 Logitech, All rights reserved
;
;       Permission is hereby granted to registered users to use or abstract
;       the following program in the implementation of customized versions.
;       This permission does not include the right to redistribute the source
;       code of this program.
;
;       History:
;          Jul-87:      Original version
;       05-May-88/akg:  Stack check at beginning of IOTRANSFER removed.
;                       Use M2TRUE.
;       06-May-88/akg:  Use RTSINTCO.INC instead of MACRO.RTS.
;       07-Jul-88/akg:  Declaration of interrupt descriptor table moved
;                       to module RTSMain and must not use any direct
;                       references "SEG RTSMain_DATA" (both conditions
;                       necessary for overlay/overlay linker)!
;       04-Jul-89/akg:  Some labels renamed conformant to usual rules (i.e.
;                       with terminating "__RTSMain"): "Error_RTS",
;                       "DescInt0", "freeList".
;
;       03-Sep-90/DA : automatic device mask removed on IOTRANSFER
;                      and placed on Interrupt Service  ( modification of ver 3.05 )
;                      problems with end of program with IOTRANSFERS fixed for
;                      TRTS and left unsolved for IBM PC
;       18-Mar-91/DA : modification of 03sep90 in this version
;
;******************************************************************************
               TITLE   RTSInterrupt

               PUBLIC  KEY__00xxx00_0000_OF_RTSInterrupt
               PUBLIC  $OK__10jul87_1402_OF_RTSInterrupt
               PUBLIC  $INIT__RTSInterrupt
               PUBLIC  IOTransfer__RTSInterrupt

;============= FROM RTSMain    IMPORT

               EXTRN   Error__RTSMain              : FAR
               EXTRN   L__InstallTermProc__RTSMain : FAR
RTSMain_DATA   SEGMENT WORD PUBLIC 'FAR_DATA'
               EXTRN   activProcess__RTSMain      : DWORD
               EXTRN   deviceMask__RTSMain        : WORD
               EXTRN   DescInt0__RTSMain          : BYTE
               EXTRN   freeList__RTSMain          : WORD
RTSMain_DATA   ENDS

;============= Constants definitions

               INCLUDE  CONFIG.RTS
               INCLUDE  RTS.INC
               INCLUDE  RTSINTDE.INC

;============= Interrupt controller handling

               INCLUDE  RTSINTCO.INC

KEY__00xxx00_0000_OF_RTSInterrupt EQU 0

MODULE_TABLE_DATA SEGMENT WORD PUBLIC 'FAR_DATA'
$OK__10jul87_1402_OF_RTSInterrupt  DW 0AEEAH,034AH,0
MODULE_TABLE_DATA ENDS


RTSInterrupt_TEXT   SEGMENT BYTE PUBLIC 'CODE'

               ASSUME  CS : RTSInterrupt_TEXT

; 18-Mar-91/D.A.
INTRR_MASK      DW       1H, 2H, 4H, 8H, 10H, 20H, 40H, 80H

;===========================================================
;
; Interrupt service routines

ISR0:
               PUSH  AX
               MOV   AX, 0*ID_LENGTH
               JMP   SHORT ComISR
ISR1:
               PUSH  AX
               MOV   AX, 1*ID_LENGTH
               JMP   SHORT ComISR
ISR2:
               PUSH  AX
               MOV   AX, 2*ID_LENGTH
               JMP   SHORT ComISR
ISR3:
               PUSH  AX
               MOV   AX, 3*ID_LENGTH
               JMP   SHORT ComISR
ISR4:
               PUSH  AX
               MOV   AX, 4*ID_LENGTH
               JMP   SHORT ComISR
ISR5:
               PUSH  AX
               MOV   AX, 5*ID_LENGTH
               JMP   SHORT ComISR
ISR6:
               PUSH  AX
               MOV   AX, 6*ID_LENGTH
               JMP   SHORT ComISR
ISR7:
               PUSH  AX
               MOV   AX, 7*ID_LENGTH
               JMP   SHORT ComISR

ISR8:
               PUSH  AX
               MOV   AX, 8*ID_LENGTH
               JMP   SHORT ComISR
ISR9:
               PUSH  AX
               MOV   AX, 9*ID_LENGTH
               JMP   SHORT ComISR
ISR10:
               PUSH  AX
               MOV   AX, 10*ID_LENGTH
               JMP   SHORT ComISR
ISR11:
               PUSH  AX
               MOV   AX, 11*ID_LENGTH
               JMP   SHORT ComISR
ISR12:
               PUSH  AX
               MOV   AX, 12*ID_LENGTH
               JMP   SHORT ComISR
ISR13:
               PUSH  AX
               MOV   AX, 13*ID_LENGTH
               JMP   SHORT ComISR
ISR14:
               PUSH  AX
               MOV   AX, 14*ID_LENGTH
               JMP   SHORT ComISR
ISR15:
               PUSH  AX
               MOV   AX, 15*ID_LENGTH
               JMP   SHORT ComISR

ISR_LENGTH     EQU   ISR1 - ISR0


ComISR:
               PUSH  CX
               PUSH  DX
               PUSH  BX
               PUSH  AX
               PUSH  BP
               PUSH  SI
               PUSH  DI
               PUSH  DS
               PUSH  ES

               ASSUME  DS : RTSMain_DATA

               MOV   CX, SEG activProcess__RTSMain
               MOV   DS, CX
               MOV   BX, OFFSET RTSMain_DATA:DescInt0__RTSMain
               ADD   BX, AX                       ; BX = ^interrupt descriptor
               SendEOI                            ; might use AX, DX and ES
               MOV   SI, WORD PTR [BX+ID_OWNER]
               LES   DI, DWORD PTR [BX+ID_SAVEI]  ; ES:DI ^variable that shall
                                                  ; hold the ^process descriptor
                                                  ; of the interrupted process

               MOV   AX, WORD PTR RTSMain_DATA:activProcess__RTSMain+2
               MOV   WORD PTR RTSMain_DATA:activProcess__RTSMain+2, SI

               ASSUME  DS : NOTHING

               MOV   DS, AX

             FNSAVE   ds:[FP_STACK]                ; DA'95

               MOV   WORD PTR DS:[PD_SS], SS
               MOV   WORD PTR DS:[PD_SP], SP
               MOV   WORD PTR ES:[DI], 0          ; save the ^process descriptor
               MOV   WORD PTR ES:[DI+2], DS       ; of the interrupted process

               ; restore the interrupt vector if needed

               ASSUME  DS : RTSMain_DATA

               MOV   DS, CX                       ; RTSMain_DATA segment

               ; tests if interrupt restore needed

               TEST  BYTE PTR [BX+ID_INSTALLED], 0FFH
               JNE   NoIntRestore

               XOR   AX, AX
               MOV   ES, AX
               MOV   DI, WORD PTR [BX+ID_INTOFF]  ; offset of interrupt vector
               MOV   AX, WORD PTR ES:[DI]
               XCHG  AX, WORD PTR [BX+ID_OLDISR]
               MOV   WORD PTR ES:[DI], AX
               MOV   AX, WORD PTR ES:[DI+2]
               XCHG  WORD PTR [BX+ID_OLDISR+2], AX
               MOV   WORD PTR ES:[DI+2], AX
               ;
               ; mask this interrupt   18-Mar-91/D.A.
               SHR   DI, 1
               SUB   DI, 2*INT_Base
               JS    Skip_MaskSet
               CMP   DI, 2*8
               JAE   Skip_MaskSet
               MOV   AX, SEG deviceMask__RTSMain
               MOV   ES, AX
               MOV   AX, CS: INTRR_MASK [DI]
               OR    ES : deviceMask__RTSMain, AX
Skip_MaskSet:

               ; put the interrupt descriptor entry into the free list

               MOV   AX, WORD PTR RTSMain_DATA:freeList__RTSMain
               MOV   WORD PTR [BX], AX
               MOV   WORD PTR RTSMain_DATA:freeList__RTSMain, BX
NoIntRestore:
               ; get the TO process descriptor stack

               MOV   ES, SI
               MOV   SS, WORD PTR ES:[PD_SS]
               MOV   SP, WORD PTR ES:[PD_SP]

             FRSTOR ES:[FP_STACK]  ; DA'95 zbedne jesli w przerwaniach nie ma REALS

               MOV   AX, WORD PTR ES:[PD_PRIO_MASK]
               SetInterruptMask DSset        ; might use DX and ES

               ; restore registers of TO process and start it

               POP   ES
               POP   DS
               POP   DI
               POP   SI
               POP   BP
               POP   AX                      ; OSP is rubish here
               POP   BX
               POP   DX
               POP   CX
               POP   AX
               IRET

;-----------------------------------------------------------
IOTransfer__RTSInterrupt  PROC  FAR
;-----------------------------------------------------------
; in    : DS:SI      address of FROM process variable
;         ES:DI      address of TO process variable
;         DX         interrupt vector number

; 02-May-88/akg
                 ; stack check is not necessary here, as long
                 ; as interrupts are off while the register block
                 ; is saved on the stack

                 MOV   WORD PTR [SI],0         ; current process offset
                 MOV   WORD PTR [SI+2],SS      ; current process segment
                 POP   AX
                 POP   BX
                 PUSHF
                 CLI                           ; no interrupt now

              FnSAVE   SS:[FP_STACK]         ; DA'95

                 PUSH  BX
                 PUSH  AX
                 SUB   SP, SO_SIZE - 6         ; 3 words are already pushed
                 MOV   BX, SP
                 MOV   WORD PTR SS:[BX+SO_BP], BP
                 MOV   WORD PTR SS:[PD_SP], SP
                 MOV   WORD PTR SS:[PD_SS], SS

                 ; saving of FROM process terminated, make the work

                 ASSUME  DS : RTSMain_DATA

                 MOV   AX, SEG deviceMask__RTSMain
                 MOV   DS, AX
                 MOV   BX, WORD PTR SS:[PD_INT_DESC]
                 OR    BX,BX
                 JNE   Installed

                 ; interrupt was not installed, find an entry and save vector

                 MOV   BX, WORD PTR freeList__RTSMain
                 CMP   BX, NIL_CARD
                 JNE   IOTransfer2
;; 18-Mar-91 after changes it's too short  JMP   SHORT FreeIntError
                 JMP   FreeIntError
IOTransfer2:
                 MOV   AX, WORD PTR [BX]
                 MOV   WORD PTR freeList__RTSMain, AX

                 ; save the process that owns the interrupt ( segment only )

                 MOV   WORD PTR [BX+ID_OWNER], SS

                 ; set up the address of the variable where we save the
                 ; interrupted process pointer

                 MOV   WORD PTR [BX+ID_SAVEI], DI
                 MOV   WORD PTR [BX+ID_SAVEI+2], ES

                 ; restore the to process stack

                 MOV   ES, ES:[DI+2]           ; process address segment is
                                               ; SS too
                 MOV   SS, ES:[PD_SS]          ; SS could be different if the
                                               ; process was interrupted outside
                 MOV   SP, ES:[PD_SP]          ; Modula code

                 ; install and save interrupt

                 PUSH  ES
                 XOR   AX, AX
                 MOV   ES, AX
                 MOV   DI, DX
                 ADD   DI, DI
; 18-Mar-91/D.A. automatic mask removal
                 MOV   SI, DI                  ; save 2*INT_VECT_NUM
;;;;;;;;;;;;;;;;; it'll be usefull later
                 ADD   DI, DI                  ; ES:DI is vector address
                 MOV   AX, WORD PTR ES:[DI]
                 XCHG  WORD PTR [BX+ID_OLDISR], AX
                 MOV   WORD PTR ES:[DI],AX
                 MOV   AX, WORD PTR ES:[DI+2]
                 XCHG  WORD PTR [BX+ID_OLDISR+2], AX
                 MOV   WORD PTR ES:[DI+2], AX
                 MOV   WORD PTR [BX+ID_INTOFF], DI
; ============================
; 18-Mar-91/D.A. automatic mask removal
; provided that SI hold 2*interrupt vector number (see above ) determine
; if it is IoTransfer to H/W interrupt and if so remove mask
                 SUB   SI, 2*INT_Base
                 JS    Skip_MaskRemove
                 CMP   SI, 2*8
                 JAE   Skip_MaskRemove
                 MOV   AX, SEG deviceMask__RTSMain
                 MOV   ES, AX
                 MOV   AX, CS : INTRR_MASK [SI]
                 NOT   AX
                 AND   ES : deviceMask__RTSMain, AX
Skip_MaskRemove:
; ============================
                 POP   ES
                 JMP   SHORT RestoreProcess

Installed:
                 ; the process is installed
                 ; set up the address of the variable where we save the
                 ; interrupted process pointer

                 MOV   WORD PTR [BX+ID_SAVEI], DI
                 MOV   WORD PTR [BX+ID_SAVEI+2], ES

                 ; restore the to process stack

                 MOV   ES, ES:[DI+2]           ; process address segment is
                                               ; SS too
                 MOV   SS, ES:[PD_SS]          ; SS could be different if the
                                               ; process was interrupted outside
                 MOV   SP, ES:[PD_SP]          ; Modula code


RestoreProcess:
                 ; set up curProcess

                 MOV   WORD PTR activProcess__RTSMain+2, ES

              FRSTOR ES:[FP_STACK]        ; DA'95

                 MOV   AX, WORD PTR ES:[PD_PRIO_MASK]
                 SetInterruptMask DSset        ; might use DX and ES

                 ; now we restore the TO process

                 POP   ES
                 POP   DS
                 POP   DI
                 POP   SI
                 POP   BP
                 POP   AX                      ; OSP is rubish here
                 POP   BX
                 POP   DX
                 POP   CX
                 POP   AX
                 IRET

FreeIntError:
                 PUSH  AX
                 MOV   AX, INT_ERR_CODE
                 JMP   Error__RTSMain
IOTransfer__RTSInterrupt  ENDP


;-----------------------------------------------------------
Termine_RTSInterrupt  PROC  FAR
;-----------------------------------------------------------
;
; NOTE :   this termination procedure can restore bad interrupt vector
;          if more than one interrupt procedure has been installed for
;          the same interrupt vector. If they were installed one after the
;          other, without freeing any between, it will still work,
;          but be careful, with this kind of things.
;
                 MOV   AX, SS:[PD_PROG_LEVEL]
                 CMP   AX, 1                      ; main program id
                 JE    Termin                     ; correct level, we execute
                                                  ; the termination procedure
                 RET
Termin:
                 ASSUME  DS : RTSMain_DATA

                 MOV   AX, SEG freeList__RTSMain
                 MOV   DS, AX
IF RUN_ON_PC
ELSE
; 18-MAR-91/D.A. Problems when interrupt procedure terminate on PC
;
; mask all interrupts, not allowed if old vectors restored and new mask active
;

                 MOV   deviceMask__RTSMain, 00FFH
                 SetInterruptMask DSset                ; might use DX and ES
ENDIF

                 ; 1. we set the free list vector offset to NIL

                 MOV   BX, WORD PTR freeList__RTSMain
Termine0:
                 CMP   BX, NIL_CARD
                 JE    Termine1
                 MOV   WORD PTR [BX+ID_INTOFF], NIL_CARD
                 MOV   BX, WORD PTR [BX]
                 JMP   Termine0
Termine1:
                 ; 2. we follow sequentialy the entries and reset the used ones
                 ;    in reversed order

                 XOR   AX, AX
                 MOV   ES, AX               ; set ES to interrupt vector segment
                 MOV   BX, OFFSET freeList__RTSMain
Termine2:
                 SUB   BX, ID_LENGTH
                 MOV   DI, WORD PTR [BX+ID_INTOFF]
                 CMP   DI, NIL_CARD         ; is this entry free
                 JE    PrevEntry

                 ; free the entry and restore old vector

                 MOV   AX, WORD PTR ES:[DI]
                 XCHG  AX, WORD PTR [BX+ID_OLDISR]
                 MOV   WORD PTR ES:[DI], AX
                 MOV   AX, WORD PTR ES:[DI+2]
                 XCHG  AX, WORD PTR [BX+ID_OLDISR+2]
                 MOV   WORD PTR ES:[DI+2], AX
PrevEntry:
                 CMP   BX, OFFSET DescInt0__RTSMain
                 JNE   Termine2
                 RET
Termine_RTSInterrupt  ENDP

RTSInterrupt_TEXT   ENDS


RTSInterrupt_INIT_TEXT   SEGMENT BYTE PUBLIC 'CODE'

               ASSUME  CS : RTSInterrupt_INIT_TEXT
               ASSUME  DS : INIT_FLAG_DATA

$INIT__RTSInterrupt   PROC  FAR

               MOV   AX, INIT_FLAG_DATA
               MOV   DS, AX
               MOV   AL, M2TRUE                     ; TRUE
               XCHG  AL, BYTE PTR $FLAG_RTSInterrupt
               OR    AL, AL                         ; is it FALSE or TRUE ?
               JNE   End_init                       ; skip if TRUE

               ; Execution of the init code
               ; Initialize the free interrupt list

               ASSUME  DS : RTSMain_DATA

               MOV   AX, SEG freeList__RTSMain
               MOV   DS, AX
               MOV   AX, RTSInterrupt_TEXT
               MOV   SI, OFFSET DescInt0__RTSMain
               MOV   WORD PTR freeList__RTSMain, SI
               MOV   DI, OFFSET RTSInterrupt_TEXT:ISR0
Init0:
               MOV   BX, SI
               ADD   SI, ID_LENGTH

               ; initialize the entry

               MOV   WORD PTR [BX+ID_OLDISR], DI
               MOV   WORD PTR [BX+ID_OLDISR+2], AX
               MOV   WORD PTR [BX], SI
               MOV   BYTE PTR [BX+ID_INSTALLED], 0    ; default is IOTranfer
               ADD   DI, ISR_LENGTH
               CMP   SI, OFFSET freeList__RTSMain
               JNE   Init0
               MOV WORD PTR [BX], NIL_CARD

               ; Install the termination procedure that will restore
               ; the interrupt vectors

               MOV   AX, SEG RTSInterrupt_TEXT
               PUSH  AX
               MOV   AX, OFFSET RTSInterrupt_TEXT:Termine_RTSInterrupt
               PUSH  AX
               CALL  L__InstallTermProc__RTSMain

End_init:
               RET
$INIT__RTSInterrupt   ENDP

RTSInterrupt_INIT_TEXT   ENDS


INIT_FLAG_DATA SEGMENT WORD PUBLIC 'FAR_DATA'
$FLAG_RTSInterrupt   DB      0          ; initialization flag of RTSInterrupt
INIT_FLAG_DATA ENDS

; 07-Jul-88/akg: Declaration of int. descr. table moved to RTSMain.ASM.

              END
