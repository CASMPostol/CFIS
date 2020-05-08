(*.F- *) 
(**********************************************************************
|  Title   : Modul strojenia odbiornikow nawigacyjnych 
|  Author  : M.Postol
|  System  : LOGITECH MODULA-2/86 
|  History :
|
|
|  Copyright (C), CAS LODZ POLAND.
|  TEL: 42' 86 58 12, 42' 87 80 44 FAX/TEL: 42' 84 48 40
|
**********************************************************************)
(*.F+ *)

MODULE DME;

FROM  Terminal IMPORT Read, Write, WriteString, WriteLn;
FROM Conversions IMPORT ConvertCardinal;

FROM SYSTEM  IMPORT BYTE, INBYTE, OUTBYTE;
CONST
  PortA    = 230H;
  PortB    = PortA+1;
  PortC    = PortA+2;
  PortCont = PortA+3;
  Mode     = 200C;(*  233C; *)
  WDLimit  = 100H;
  
TYPE
  set8 = SET OF [0..7];
VAR
  c      : CARDINAL;
  lastCh : CHAR;
  
BEGIN
  OUTBYTE(PortCont, Mode);
  LOOP
    Read(lastCh);
    IF lastCh ="*" THEN
      RETURN; 
    END (* if *);
    OUTBYTE(PortA, 252C);
    OUTBYTE(PortB, 252C);
    OUTBYTE(PortC, 12C);
    FOR c:= 0 TO 100 DO
      c := c;
    END;
    OUTBYTE(PortC, 52C);
    OUTBYTE(PortA, 0C);
    OUTBYTE(PortB, 0C);
    Read(lastCh);
    IF lastCh ="*" THEN
      RETURN; 
    END (* if *);
    OUTBYTE(PortA, 125C);
    OUTBYTE(PortB, 125C);
    OUTBYTE(PortC, 5C);
    FOR c:= 0 TO 100 DO
      c := c;
    END;
    OUTBYTE(PortC, 45C);
    OUTBYTE(PortA, 0C);
    OUTBYTE(PortB, 0C);
  END;
END DME.
