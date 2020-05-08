(*.F- *)
(**********************************************************************
|  Title   : Testowanie modulu  FlagAnal
|  Author  : Mariusz Postol
|  System  : LOGITECH MODULA-2/86 
|  History :
|    Rel.3.0 - utworzony
|
|  Copyright (C), CAS LODZ POLAND.
|  TEL: 42' 686 25 47
|  mailto: techsupp@cas.com.pl
|  http: www.cas.com.pl
|
**********************************************************************)
(*.F+ *)
MODULE TST_FLGAnalize;

  FROM FlagAnal IMPORT 
    FlagsTable, FlagErr_Anal, InitFlagErr;

  FROM CommonTypes IMPORT
    NumStrefy;
    
VAR
  flagi : FlagsTable;
  idx   : CARDINAL;
  dl    : CARDINAL;
  flaga : BOOLEAN;
  
BEGIN
  InitFlagErr(flagi, FALSE);
  idx := 0;
  dl := 10;
  flaga := FALSE;
  LOOP
    FlagErr_Anal( flaga, idx MOD 100 < dl, flagi, idx, ns_no );
    IF idx > 2000 THEN
      EXIT
    END;
    INC(idx);
    IF idx MOD 100 = 0  THEN
      dl := dl + 1;
    END;
  END (* loop *);
END TST_FLGAnalize.
