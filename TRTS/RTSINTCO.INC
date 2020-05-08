.XLIST
;******************************************************************************
;
;       MODULA2    Run-Time Support  ( RTS )
;
;              LOGITECH SA,   CH-1122 Romanel    (Switzerland)
;              LOGITECH Inc,  Fremont, CA 94555  (USA)
;
;       Module  :    Interrupt controller handling for RTS:
;                    - constant and macro definitions
;
;                    Note that this include-file is also used by
;                    the Target Monitor (TMON) of the LOGITECH
;                    Modula-2 ROM TOOLS.
;
;       Release :    3.05 (c) - September 88
;
;       Copyright (C)  1987, 1988 Logitech, All rights reserved
;
;       Permission is hereby granted to registered users to use or abstract
;       the following program in the implementation of customized versions.
;       This permission does not include the right to redistribute the source
;       code of this program.
;
;       History:
;          Jul-87:      Original version (macro definitions in file MACRO.RTS)
;       02-May-88/akg:  StackCheck marco removed (not needed any more)
;       06-May-88/akg:  Renamed to RTSINTCO.INC, interrupt controller
;                       definitions and macros. Extended for adaptability
;                       to a different target hardware.
;       22-Sep-88/akg:  Some comments added and corrected.
;       04-Jul-89/akg:  Version 3.10 (no changes).
;
;       31-Aug-90/D.A:  Prio level to 8 and adaptations V.3.05 to
;                       concepts checked in V.2.05 and 'DTC' target computer
;                       PriorityMask is WORD ; PriorityDecrementError
;
;       18-Mar-91/D.A: Update in Version 3.10 (TRTM concept )
;
;       29-Jun-91/M.Postol:
;                       Adaptation to IAPX186 family and MAP controller
;                       SwitchOffNMI macro was added.
;       04-Nov-91/M.Postol:
;         constants concerninig DMA were added
;       25-Nov-91/M.Postol
;       UpperMemoryCSCW(wait) and LowerMemoryCSCW(128k) was changed.
;       02-Mar-92/M.Postol
;       UpperMemoryCSCW ( 64 ) was changed.
;       9 Mar 1992/ M.M.
;       Priority Int0 Control Word added
;       03 Apr 1992/ M.P
;       PeripheralCSCW was changed - external RDY and 1 Wait state.
;       19 Jun 1992/ M.P some definitions moved in scope of own IF's
;
;******************************************************************************
        SUBTTL  Interrupt Controller Handling for RTS and TMON

; The following definitions relate to input/output and interrupt
; handling. The values given are valid for an IBM-PC/AT or a compatible
; target system. If your target system is different, it is likely,
; that the values in the declarations below must be modified.
;
; Note that this include-file is used by the modules of the Modula-2
; Run-Time Support (RTS), as well as by the modules of the Target
; Monitor (TMON) of the LOGITECH Modula-2 ROM TOOLS.
;
; If you have to adapt these definitions to your target hardware, then
; you should also check the corresponding RTS and TMON modules that use
; the macros defined in this include-file.

; Remark: If your target hardware is different and contains an 80x87
;         coprocessor that you use for REAL arithmetic, then you might
;         also need to adapt the modules RTS87 or RTSM87 of the RTS.


;------------------------------------------------------------
; The following points should be checked out:
;
; a) Is there an interrupt controller in your target computer (chip
;    number is typically 8259)?
;
; b) Is input/output from/to the interrupt controller done through
;    i/o-ports or is it memory-mapped (i.e. the registers of the
;    interrupt controller have fixed memory addresses)?
;
; c) Which ports (or memory addresses) are used for the interrupt
;    controller? The declarations below must be changed accordingly.


;------------------------------------------------------------
; The following definitions may be modified in order to adapt
; the RTS and the TMON to the specific configuration of the
; target system.

        INTERRUPT_CTRL  EQU     TRUE
        ; This switch must be set to TRUE if an interrupt controller
        ; is present in the target system, and to FALSE otherwise.
        ; The code used below refers to an 8259 interrupt controller.
        ; If a different controller is used, this code must be
        ; adapted accordingly. In that case, it may also be necessary
        ; to adapt the RTS and TMON modules that use the macros
        ; defined in this include-file.
        ; If no interrupt controller is present in the target
        ; computer, then the use of priorities in the heading of
        ; a Modula-2 module has no effect.

        CTRL_PORT_IO    EQU     TRUE
        ; If this switch is TRUE, then input/output from/to the
        ; interrupt controller on the target system is through ports.
        ; If it is FALSE, then memory-mapped input/output is used
        ; to access the interrupter controller. This switch has
        ; no effect, if INTERRUPT_CTRL = FALSE.


IF INTERRUPT_CTRL
;------------------------------------------------------------
; Constants used for handling the interrupt controller
; ====================================================

; Note that the modules of the RTS and of the TMON do NOT
; refer to these constants directly. Instead, they only use
; the macros defined below, which is the only place where
; these constants are used.


IF  RUN_ON_PC
;       interrupt controller addressses
        PIC_8259A_EVEN  EQU     20H
        PIC_8259A_ODD   EQU     21H
        IsIAPX186       EQU     FALSE
ELSE
  IF IsIAPX186
        RelRegBase              EQU     0FF00H          ; Default value after processor reset
        DMA0_ControlWord        EQU     RelRegBase+0CAH
        DMA1_ControlWord        EQU     RelRegBase+0DAH
        UpperMemoryCSAddr       EQU     RelRegBase+0A0H
        LowerMemoryCSAddr       EQU     RelRegBase+0A2H
        PeripheralCSAddr        EQU     RelRegBase+0A4H
        MMMidRangeMemoryCSAddr  EQU     RelRegBase+0A6H
        MPMidRangeMemoryCSAddr  EQU     RelRegBase+0A8H
        Int0ControlReg          EQU     RelRegBase+038H
        PIC_StatusReg           EQU     RelRegBase+030H
        PIC_RequestReg          EQU     RelRegBase+02EH
        PIC_InServiceReg        EQU     RelRegBase+02CH
        PIC_PriorityMaskReg     EQU     RelRegBase+02AH
        PIC_MaskReg             EQU     RelRegBase+028H
        PIC_PollStatReg         EQU     RelRegBase+026H
        PIC_PollRegReg          EQU     RelRegBase+024H
        PIC_EOIReg              EQU     RelRegBase+022H
        UpperMemoryCSCW         EQU     0F000H+38H+6H           ;64 kB, 0 wait, ext ready also used
        LowerMemoryCSCW         EQU     01FF8H                  ;128kB, 0 Wait, ext ready also used
        MMMidRangeMemoryCSCW    EQU     04000H+0F8H             ;Begin MM at 256kB, 0Wait
        MPMidRangeMemoryCSCW    EQU     0A000H+38H              ;4 x 64kB (256), I/O MAP, 5 PCS 
        PeripheralCSCW          EQU     038H+01H                ;I/O at 0, 1 wait, ext ready also used
        PC0Offset               EQU     PeripheralCSCW AND 0FFC8H * 10H
        PC1Offset               EQU     PC0Offset+128
        PC2Offset               EQU     PC0Offset+2*128
        PC3Offset               EQU     PC0Offset+3*128
        PC4Offset               EQU     PC0Offset+4*128
        CommandReg              EQU     PC0Offset+0;
  ELSE
    ;;;;    -DTC -V20 card inerrupt controler addresses
    ;;;;
        IsIAPX186       EQU     FALSE
        PIC_8259A_EVEN  EQU     0FFFCH
        PIC_8259A_ODD   EQU     0FFFFH
  ENDIF
ENDIF        

        ; Port address of control word 1 in Interrupt Controller.
        ; This port is used to read and write the interrupt mask.
        ; See routines 'GET_INTERRUPT_MASK' and 'SET_INTERRUPT_MASK'
        ; below.
     IF  IsIAPX186
        MASK_8259       EQU     PIC_MaskReg
     ELSE
        MASK_8259       EQU     PIC_8259A_ODD
     ENDIF
     
        ; Port address of control word 2 in Interrupt Controller.
        ; This port is used to send the End-Of-Interrupt code.
        ; See routine SEND_EOI below.
     IF  IsIAPX186
        CTRL_W2_8259    EQU     PIC_EOIReg
     ELSE
        CTRL_W2_8259    EQU     PIC_8259A_EVEN
     ENDIF
        ; End-Of-Interrupt code to be sent to the interrupt controller.
     IF  IsIAPX186
        EOI_8259        EQU      8000H
     ELSE
        EOI_8259        EQU      20H
     ENDIF

        ; PIC initialization command words
        ; INTERRUPT VECTOR NUMBERS FROM 8 to 0FH
        INT_Base        EQU     8
     IF  IsIAPX186
     ELSE
        ICW1            EQU     1BH
        ICW2            EQU     INT_Base
        ICW4            EQU     1
     ENDIF

  IF NOT CTRL_PORT_IO
        CTRL_IO_SEGMENT EQU       0H
        ; Segment address to be used for memory-mapped input/output
        ; from/to the interrupt controller. If memory-mapped i/o is
        ; used, this value must be set accordingly.
  ENDIF

ENDIF ; INTERRUPT_CTRL


;------------------------------------------------------------
IN_AL   MACRO   PortAddr
;=======================
        ; Input of a byte from a port into AL.
        ; The following registers might be used: AL, DX.

IF PortAddr LT 100H
        IN      AL, PortAddr
ELSE
        MOV     DX, PortAddr
        IN      AL, DX
ENDIF

ENDM ; IN_AL


;------------------------------------------------------------
OUT_AL  MACRO   PortAddr
;=======================
        ; Output of the byte in AL to a port.
        ; The following registers might be used: AL, DX.

IF PortAddr LT 100H
        OUT     PortAddr, AL
ELSE
        MOV     DX, PortAddr
        OUT     DX, AL
ENDIF

ENDM ; OUT_AL; 


;------------------------------------------------------------
SetInterruptMask  MACRO    DSstate
;=================================

IFDEF ISTMON    ; we are assembling a TMON module
  IFNB <DSstate>
        .ERR    ; DSstate macro argument must not be used in case of TMON!
  ENDIF
        ; This macro sends the interrupt mask (passed in AL) to the
        ; interrupt controller mask register.
        ; The following registers might be used: AL, DX, ES.

ELSE            ; we are assembling a RTS module

        ; DSstate is DSset if DS is segment RTSMain_DATA
        ; else it is DSunset.
        ;
        ; This macro sends the logical OR between the process
        ; priority mask (passed in AL) and the RTS device mask
        ; to the interrupt controller mask register.
        ; The following registers might be used: AX, DX, ES, DS.

  IFIDN <DSstate>, <DSunset>    ; DS is not yet set to RTSMain_DATA
        MOV     DX, SEG RTSMain_DATA
        MOV     DS, DX
  ELSE
    IFIDN <DSstate>, <DSset>    ; DS is already set to RTSMain_DATA
    ELSE
        .ERR
    ENDIF
  ENDIF
        ASSUME  DS : RTSMain_DATA

        ; Mask all interrupts which are disabled either in the
        ; priority mask (in AL) or in the device mask.
        OR      AX, WORD PTR deviceMask__RTSMain
ENDIF ; ISTMON

IF INTERRUPT_CTRL
  IF CTRL_PORT_IO
;        OUT_AL  MASK_8259       ; might use DX

; On some machines with a very fast processor, there may be
; some problem with the interrupt controller. During the 
; modification of the mask, the interrupt controller may not
; be able to respond to the acknowledge of the processor.
; In that case, you may use the following code instead of
; the one above:
       PUSHF
       CLI
       OUT_AL  MASK_8259       ; might use DX
       NOP
       NOP
       POPF

  ELSE ; memory-mapped i/o
        MOV     DX, CTRL_IO_SEGMENT
        MOV     ES, DX
        MOV     BYTE PTR ES:[MASK_8259], AL
  ENDIF
ELSE ; no interrupt controller
ENDIF ; INTERRUPT_CTRL

ENDM ; SetInterruptMask


;------------------------------------------------------------
GetInterruptMask  MACRO
;======================
        ; This macro returns in AX the currently valid interrupt mask.
        ; The following registers might be used: AX, DX, ES.

IF INTERRUPT_CTRL
  IF CTRL_PORT_IO
        IN_AL   MASK_8259       ; might use DX
        XOR     AH, AH
  ELSE ; memory-mapped i/o
        MOV     AX, CTRL_IO_SEGMENT
        MOV     ES, AX
        MOV     AL, BYTE PTR ES:[MASK_8259]
        XOR     AH, AH
  ENDIF
ELSE ; no interrupt controller
        XOR     AX, AX          ; return zero
ENDIF ; INTERRUPT_CTRL

ENDM ; GetInterruptMask


;------------------------------------------------------------
SendEOI  MACRO
;=============
        ; This macro sends an End-Of-Interrupt code (EOI) to the
        ; interrupt controller.
        ; The following registers might be used: AX, DX, ES.

IF INTERRUPT_CTRL
  IF CTRL_PORT_IO
        MOV     AX, EOI_8259
        OUT_AL  CTRL_W2_8259    ; might use DX
  ELSE ; memory-mapped i/o
        MOV     AX, CTRL_IO_SEGMENT
        MOV     ES, AX
        MOV     BYTE PTR ES:[CTRL_W2_8259], EOI_8259
  ENDIF
ELSE ; no interrupt controller
ENDIF ; INTERRUPT_CTRL

ENDM ; SendEOI



;------------------------------------------------------------
INITIALIZE_PIC_8259A  MACRO
;=============
        ; initialize interrupt controller.
        ; The following registers might be used: AX, DX, ES.


IF  RUN_ON_PC
  ; empty ,leave controller as was
ELSE
  IF IsIAPX186
  ; initialize processor registers for MAP card

        Select_ROM_TYPE_PORT EQU PC0Offset+2

        ;Upper Memory CS
        MOV     AX,     UpperMemoryCSCW         ;
        OUT_AL  UpperMemoryCSAddr               ;
        ;Lower Memory CS
        MOV     AX,     LowerMemoryCSCW         ;
        OUT_AL  LowerMemoryCSAddr               ;
        ;MidRange Memory CS
        MOV     AX,     MPMidRangeMemoryCSCW    ;
        OUT_AL  MPMidRangeMemoryCSAddr          ;
        MOV     AX,     MMMidRangeMemoryCSCW    ;
        OUT_AL  MMMidRangeMemoryCSAddr          ;
        ;Peripheral CS
        MOV     AX,     PeripheralCSCW          ;
        OUT_AL  PeripheralCSAddr
        MOV     AL, 16H;                        ; LTM=1; Priority = 6;
        OUT_AL  Int0ControlReg
        ; Control register of the card
        MOV     AL,     40H                     ; NOT RESET, 64KB,
        OUT_AL  Select_ROM_TYPE_PORT
  ELSE
        MOV     DX , PIC_8259A_EVEN
        MOV     AL , ICW1
        OUT     DX , AL
        MOV     DX , PIC_8259A_ODD
        MOV     AL , ICW2
        OUT     DX , AL
        MOV     AL , ICW4
        OUT     DX , AL
  ENDIF
ENDIF
ENDM ; INITIALIZE_PIC_8259A

;------------------------------------------------------------
SwitchOffNMI  MACRO
;=============
        ; Switch off the NMI which is coupled with the MAP Command register.
        ; The following registers might be used: AX.
  IF  RUN_ON_PC
        ; empty ,leave controller as was
  ELSE
    IF IsIAPX186
        IN_AL   CommandReg    ENDIF
  ENDIF

ENDM ; SwitchOffNMI

.LIST
