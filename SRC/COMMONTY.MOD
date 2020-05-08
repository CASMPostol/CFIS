(*.F- *)
(**********************************************************************
|  Title   : Common types
|  Author  : M.Postol
|  System  : LOGITECH MODULA-2/86 
|  History :
|    Rel 3.0: MPostol
|      dolozylem procedure InitSignalDsc
|
|  Copyright (C), CAS LODZ POLAND.
|  TEL: 42' 686 25 47
|  mailto: techsupp@cas.com.pl
|  http: www.cas.com.pl
|
**********************************************************************)
(*.F+ *)
IMPLEMENTATION MODULE  CommonTypes;

  FROM Strings IMPORT
    ConstAssign;
  
  FROM SYSTEM IMPORT
    WORD;
    
  PROCEDURE GetRecName
            (VAR name : ARRAY OF CHAR; 
                 rec  : GlownyOdbiornikT);
  BEGIN
    IF rec = goA  THEN
      ConstAssign('A', name);
    ELSE
      ConstAssign('B', name);
    END;
  END GetRecName;

  PROCEDURE GetTranName
            (VAR name : ARRAY OF CHAR;
                 trn  : NadajnikT);
  BEGIN
    IF trn = nA  THEN
      ConstAssign('Nad: G', name);
    ELSE
      ConstAssign('Nad: Z', name);
    END;
  END GetTranName;

  PROCEDURE InitSignalDsc
            ( VAR sygnal    : SignalDsc;
                  PosNilVal : WORD);
  BEGIN
    WITH sygnal DO
      val := NilValI;
      pos := PosNilVal;
    END (* with AVcont *);
  END InitSignalDsc;

  PROCEDURE  Init_flgTab
             ( VAR flagi: flgTab);
  VAR
    odb : GlownyOdbiornikT;
       
  BEGIN
    FOR odb := goA TO goB DO
      flagi[odb] := FALSE;
    END (* for odb *);
  END Init_flgTab;

END CommonTypes.
