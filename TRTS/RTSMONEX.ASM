  TITLE   RTSMonExit
;================================================================
; implementation for definition of RTSMonExit
; has only defined the Key and an empty Init label
; exported variable    MonitorExitPro__RTSMonExit double word type
; is defined and initated in RTSMain , and used in RTSPriority
;================================================================

        PUBLIC $INIT__RTSMonExit
        PUBLIC KEY__10jul87_1035_OF_RTSMonExit

KEY__10jul87_1035_OF_RTSMonExit EQU 0


RTSMain_TEXT   SEGMENT BYTE PUBLIC 'CODE' 
; segment of RTSMain ;to save memory
$INIT__RTSMonExit  PROC FAR
;=================
               RET
$INIT__RTSMonExit  ENDP
RTSMain_TEXT   ENDS

END
