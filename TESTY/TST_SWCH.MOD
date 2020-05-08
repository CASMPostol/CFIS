(*.F- *)
(**********************************************************************
|  Title   : Test przelacznika w.cz. 
|  Author  : M.Postol
|  System  : LOGITECH MODULA-2/86 
|  History :
|
|  Copyright (C), CAS LODZ POLAND.
|  TEL: 42' 862 547, 42' 87 80 44 FAX/TEL: 42' 84 48 40
|
**********************************************************************)
(*.F+ *)
MODULE  tst_swch;

  IMPORT DebugPMD;
  
  FROM SwitchCntrl IMPORT
      SwState, SwitchTo;
    
  FROM ASCII IMPORT
      esc;
    
  FROM Terminal IMPORT
    Write, Read, KeyPressed;

   FROM GrafTypes  IMPORT
     WHITE, BLACK;
  FROM HiLevGraf  IMPORT
    WrStr;
 VAR
   Ch : CHAR;
  
BEGIN
  SwitchTo(Antena);
  (* 
  LOOP
    WrStr('Przelaczam na marker', 10, 10, WHITE, BLACK);
    SwitchTo(MKRa);
    SwitchTo(MKRb);
    WrStr('Przelaczylem na marker', 10, 10, WHITE, BLACK);
    Read(Ch);
    IF Ch= esc THEN
      EXIT
    END;
    WrStr("Przelaczam na VOR'a ", 10, 10, WHITE, BLACK);
    SwitchTo(VORa);
    SwitchTo(VORb);
    WrStr("Przelaczylem na VOR'a ", 10, 10, WHITE, BLACK);
    Read(Ch);
    IF Ch = esc THEN
      EXIT
    END;
  END (* loop *);
  *)
END tst_swch.
