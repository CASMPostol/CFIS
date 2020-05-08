.186
FP_TXT      SEGMENT WORD PUBLIC 'FAR_TXT'
        ASSUME  CS : FP_TXT
        ASSUME  DS : FP_DATA
  	ASSUME  SS : FP_DATA
        
        mov   	ax, FP_DATA
        mov	ds, ax
        fnsave	fpstack  	; to pomija WAIT
        fsave	SS:fpstack		; tu masm doklada WAIT
        mov	ax, 4C00H
        INT	21H
FP_TXT      ENDS

FP_DATA      SEGMENT WORD PUBLIC 'FAR_DATA'
fpstack      DB		100 DUP (?)
FP_DATA      ENDS

END

