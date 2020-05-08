TITLE LowLevel
.286


PUBLIC KEY__19nov94_1800_OF_LowLevel
PUBLIC $INIT__LowLevel
PUBLIC L__Dos__LowLevel
PUBLIC L__Intr__LowLevel

ASSUME CS: LowLevel_TEXT
ASSUME DS: LowLevel_TEXT

KEY__19nov94_1800_OF_LowLevel	equ	0

LowLevel_TEXT SEGMENT WORD PUBLIC 'CODE'

rAX	equ	0
rBX	equ	2
rCX	equ	4
rDX	equ	6
rBP	equ	8
rSI	equ	10
rDI	equ	12
rDS	equ	14
rES	equ	16
rFlags	equ	18
 
SaveReg PROC NEAR
;	Wskaznik do struktury w DS:SI
	push	word ptr [si+rFlags]
	popf
	mov	es,[si+rES]
	mov	di,[si+rDI]
	mov	dx,[si+rDX]
	mov	bp,[si+rBP]
	mov	cx,[si+rCX]
	mov	bx,[si+rBX]
	mov	ax,[si+rAX]
	push	[si+rDS]
	mov	si,[si+rSI]
	pop	ds
	ret
SaveReg ENDP


RestoreReg PROC NEAR
        push	ds
	push	si
	mov	si,sp
	lds	si,ss:[si+12]	; (6=bylo) +(2=RET) + (ds+si=4)
        pop     [si+rSI]
        pop	[si+rDS]
	mov	[si+rBP],bp
	mov	[si+rES],es
	mov	[si+rDI],di
	mov	[si+rDX],dx
	mov	[si+rCX],cx
	mov	[si+rBX],bx
	mov	[si+rAX],ax
	pushf
	pop	word ptr [si+rFlags]
	ret	
RestoreReg ENDP



L__Dos__LowLevel	PROC FAR
	push	bp
	mov	bp,sp
	lds	si,[bp+6]
	call	SaveReg
	int	21h
	call	RestoreReg
	pop	bp
	ret	4
L__Dos__LowLevel	ENDP


L__Intr__LowLevel	PROC FAR
	push	bp
	mov	bp,sp
	mov	ax,[bp+10]
	mov	byte ptr cs:IntNu,al
	lds	si,[bp+6]
	call	SaveReg
	db	0cdh
	IntNu:
	db 	0
	call	RestoreReg
	pop	bp
	ret	6
L__Intr__LowLevel	ENDP


$INIT__LowLevel PROC FAR
	ret
$INIT__LowLevel ENDP


LowLevel_TEXT	ENDS


END
