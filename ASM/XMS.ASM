.286
        TITLE    XMS

        PUBLIC  L__XmsInstalled__XMS
;        PUBLIC  L__RequestHMA__XMS
;        PUBLIC  L__ReleaseHMA__XMS
;        PUBLIC  L__GlobalEnableA20__XMS
;        PUBLIC  L__GlobalDisableA20__XMS
;        PUBLIC  L__LocalEnableA20__XMS
;        PUBLIC  L__LocalDisableA20__XMS
;        PUBLIC  L__QueryA20__XMS
        PUBLIC  L__QueryFreeExtMem__XMS
        PUBLIC  L__AllocateExtMem__XMS
        PUBLIC  L__FreeExtMem__XMS
        PUBLIC  L__MoveExtMemBlock__XMS
        PUBLIC  L__LockExtMemBlock__XMS
        PUBLIC  L__UnlockExtMemBlock__XMS
 ;       PUBLIC  L__GetHandleInfo__XMS
        PUBLIC  L__ResizeExtMemBlock__XMS
        PUBLIC  L__AllocUpperMemBlock__XMS
        PUBLIC  L__FreeUpperMemBlock__XMS

        PUBLIC  KEY__21aug96_1223_OF_XMS

KEY__21aug96_1223_OF_XMS EQU 0

        PUBLIC  $INIT__XMS
        PUBLIC  $BM__XMS, $EM__XMS
        PUBLIC  $BD__XMS, $ED__XMS

;MODULE_TABLE_DATA SEGMENT WORD PUBLIC 'FAR_DATA'
;$OK__31jul87_1000_OF_BitBlockOps DW 0AEFFH,0258H,0
;MODULE_TABLE_DATA ENDS

XMS_DATA         SEGMENT WORD PUBLIC 'FAR_BSS'
                         ASSUME  CS : XMS_TEXT
$BD__XMS         LABEL   FAR
		HiMemService	DD ?
$ED__XMS         LABEL   FAR
XMS_DATA         ENDS


XMS_TEXT SEGMENT BYTE PUBLIC 'CODE'
                ASSUME  CS:XMS_TEXT
                ASSUME  DS:XMS_DATA
$BM__XMS:

;-----------------------------------------------------------
L__XmsInstalled__XMS 	PROC    FAR
;-----------------------------------------------------------
.386
        XOR     AX,AX
      mov es,ax
;      mov di,dx
;      shl edi,16
;      mov di,bx
      mov es:[edi],cx
      mov cx,es:[edi]
	mov 	ax, XMS_DATA
	mov	ds, ax
	mov 	bx, offset HiMemService
	mov	ax, [bx]
	or	ax, [bx+2]
	jz	XmsInstalled_NO		; ax eq=0 == FALSE
	inc	ax
XmsInstalled_NO:
	RET
L__XmsInstalled__XMS	ENDP

;-----------------------------------------------------------
L__QueryFreeExtMem__XMS 	PROC    FAR
;-----------------------------------------------------------
LargestBlock = 6
TotalFree    = LargestBlock+4

        push	BP
        mov	BP, sp
        mov	ah, 8		; funct

        push	XMS_DATA
        pop	ds
        push	BP
        call    HiMemService
        pop	BP
        or      ax, ax
        jnz     QueryFreeExtMem_ok
        jmp     short QueryFreeExtMem_fail
QueryFreeExtMem_ok:
        les    	bx, [bp+LargestBlock]
        mov	es:[bx], ax
        les    	bx, [bp+TotalFree]
        mov	es:[bx], dx
        xor	ax, ax
        jmp     short QueryFreeExtMem_end
QueryFreeExtMem_fail:
        mov	ax, bx
QueryFreeExtMem_end:
        pop	BP
	RET	8
L__QueryFreeExtMem__XMS	ENDP


;-----------------------------------------------------------
L__AllocateExtMem__XMS 	PROC    FAR
;-----------------------------------------------------------
XmsHandle = 6
SizeInK   = XmsHandle+4
        push	BP
        mov	BP, sp
        mov	ah, 9		; funct
        mov	dx, [bp+SizeInK]

        push	XMS_DATA
        pop	ds
        push	BP
        call    HiMemService
        pop	BP

        and     ax, 0001
        jnz     AllocateExtMem_ok
        jmp     short AllocateExtMem_fail
AllocateExtMem_ok:
        xor	ax, ax
        jmp     short AllocateExtMem_end
AllocateExtMem_fail:
        mov	dx, -1
        mov	ax, bx
AllocateExtMem_end:
        les    	di, [bp+XmsHandle]
        mov	es:[di], dx
        pop	BP

	RET	6
L__AllocateExtMem__XMS	ENDP

;-----------------------------------------------------------
L__FreeExtMem__XMS 	PROC    FAR
;-----------------------------------------------------------
XmsHandle = 6

        push	BP
        mov	BP, sp
        mov	ah, 10		; funct
        mov	dx, [bp+XmsHandle]

        push	XMS_DATA
        pop	ds
        push	BP
        call    HiMemService
        pop	BP

        and     ax, 0001
        jnz     freeExtMem_ok
        jmp     short freeExtMem_fail
freeExtMem_ok:
        xor	ax, ax
        jmp     short freeExtMem_end
freeExtMem_fail:
        mov	ax, bx
freeExtMem_end:
        pop	BP

	RET	2
L__FreeExtMem__XMS	ENDP

;-----------------------------------------------------------
L__MoveExtMemBlock__XMS 	PROC    FAR
;-----------------------------------------------------------
XmsCTRLStructofs = 6
XmsCTRLStructseg = 8

        push	BP
        mov	BP, sp
        mov	ah, 11		; funct
        mov 	ds, [bp+XmsCTRLStructseg]
        mov 	si, [bp+XmsCTRLStructofs]

        push	XMS_DATA
        pop	es
		ASSUME ES : XMS_DATA
        push	BP
        call    es:HiMemService
        pop	BP
		ASSUME ES : NOTHING

        and     ax, 0001
        jnz     MoveExtMemBlock_ok
        jmp     short MoveExtMemBlock_fail
MoveExtMemBlock_ok:
        xor	ax, ax
        jmp     short MoveExtMemBlock_end
MoveExtMemBlock_fail:
        mov	ax, bx
MoveExtMemBlock_end:
        pop	BP

	RET	4
L__MoveExtMemBlock__XMS	ENDP

;-----------------------------------------------------------
L__ResizeExtMemBlock__XMS 	PROC    FAR
;-----------------------------------------------------------
SizeInK     = 6
XmsHandle   = SizeInK +2
        push	BP
        mov	BP, sp
        mov	ah, 15		; funct
        mov	dx, [bp+XmsHandle]
        mov	bx, [bp+SizeInK]

        push	XMS_DATA
        pop	ds
        push	BP
        call    HiMemService
        pop	BP

        and     ax, 0001
        jnz     resizeExtMem_ok
        jmp     short resizeExtMem_fail
resizeExtMem_ok:
        xor	ax, ax
        jmp     short resizeExtMem_end
resizeExtMem_fail:
        mov	ax, bx
resizeExtMem_end:
        pop	BP

	RET	6
L__ResizeExtMemBlock__XMS	ENDP


;-----------------------------------------------------------
L__AllocUpperMemBlock__XMS  PROC    FAR
;-----------------------------------------------------------
ReturnSize  = 6
SegmentBase = ReturnSize+4
ReqSize     = SegmentBase+4

        push    BP
        mov	BP, sp
        mov     ah, 16           ; funct
        mov     dx, [bp+ReqSize]

        push	XMS_DATA
        pop	ds
        push	BP
        call    HiMemService
        pop	BP

        and     ax, 0001
        jnz     AllocateUMBMem_ok
        jmp     short AllocateUMBMem_fail
AllocateUMBMem_ok:
        xor     ax, ax
        jmp     short AllocateUMBMem_end
AllocateUMBMem_fail:
        mov     ax, bx
AllocateUMBMem_end:
        lea     di,[bp+SegmentBase]
        mov     ss:[di], bx
        les     di, [bp+ReturnSize]
        mov	es:[di], dx
        pop	BP

        RET     2+4+4
L__AllocUpperMemBlock__XMS  ENDP

;-----------------------------------------------------------
L__FreeUpperMemBlock__XMS  PROC    FAR
;-----------------------------------------------------------
UMBSegment     = 6

        push    BP
        mov	BP, sp
        mov     ah, 17           ; funct
        mov     dx, [bp+UMBSegment]

        push	XMS_DATA
        pop	ds
        push	BP
        call    HiMemService
        pop	BP

        and     ax, 0001
        jnz     FreeUMBMem_ok
        jmp     short FreeUMBMem_fail
FreeUMBMem_ok:
        xor     ax, ax
        jmp     short FreeUMBMem_end
FreeUMBMem_fail:
        mov     ax, bx
FreeUMBMem_end:
        pop	BP

        RET     2
L__FreeUpperMemBlock__XMS  ENDP


;-----------------------------------------------------------
L__LockExtMemBlock__XMS  PROC    FAR
;-----------------------------------------------------------
Lock_LockedBlock = 6
Lock_XmsHandle = Lock_LockedBlock+4

        push    BP
        mov	BP, sp
        mov     ah, 0ch           ; funct
        mov     dx, [bp+Lock_XmsHandle]

        push	XMS_DATA
        pop	ds
        push	BP
        call    HiMemService
        pop	BP

        and     ax, 0001
        jnz     Lock_ok
        jmp     short Lock_fail
Lock_ok:
        lds     si,[bp+Lock_LockedBlock]
        mov     ds:[si],bx
        mov     ds:[si+2],dx
        xor     ax, ax
        jmp     short Lock_end
Lock_fail:
        mov     ax, bx
Lock_end:
        pop	BP

        RET     6
L__LockExtMemBlock__XMS  ENDP


;-----------------------------------------------------------
L__UnlockExtMemBlock__XMS  PROC    FAR
;-----------------------------------------------------------
Unlock_XmsHandle = 6

        push    BP
        mov	BP, sp
        mov     ah, 0dh           ; funct
        mov     dx, [bp+Lock_XmsHandle]

        push	XMS_DATA
        pop	ds
        push	BP
        call    HiMemService
        pop	BP

        and     ax, 0001
        jnz     Unlock_ok
        jmp     short Unlock_fail
Unlock_ok:
        xor     ax, ax
        jmp     short Unlock_end
Unlock_fail:
        mov     ax, bx
Unlock_end:
        pop	BP

        RET     2
L__UnlockExtMemBlock__XMS  ENDP




$EM__XMS:
XMS_TEXT ENDS

INIT_FLAG_DATA       SEGMENT WORD PUBLIC 'FAR_DATA'
$FLAG_XMS           DB      0           ; initialization flag of
INIT_FLAG_DATA       ENDS


XMS_INIT_TEXT   SEGMENT BYTE PUBLIC 'CODE'

               ASSUME  CS : XMS_INIT_TEXT
               ASSUME  DS : INIT_FLAG_DATA

$INIT__XMS   PROC  FAR

               MOV   AX, SEG INIT_FLAG_DATA
               MOV   DS, AX
               MOV   AL, 1                       ; TRUE
               XCHG  AL, BYTE PTR $FLAG_XMS
               OR    AL, AL                         ; is it FALSE or TRUE ?
               JE    Init0
               JMP   EndInit                        ; skip if TRUE
Init0:
;;;            	TryToInstall
  push es
  push ds
  push si
  mov  ax,4300H
  int  2FH;
  cmp  al,80H
  jnz  NotInst
  mov  ax,4310H
  int  2FH
 	 ASSUME DS : XMS_DATA
  mov  ax,XMS_DATA
  mov  ds,ax
  mov  si,OFFSET HiMemService
  mov  [si],bx
  mov  [si][2],es
  jmp  short TryToInstallEnd
NotInst:
  xor  ax,ax
  mov  si,OFFSET HiMemService
  mov  [si],ax
  mov  [si+2],ax
TryToInstallEnd:
  pop  si
  pop  ds
  pop  es
EndInit:
               RET
$INIT__XMS	ENDP

XMS_INIT_TEXT  ENDS

        END
