(*.F- *)
(**********************************************************************
|  Title   : Utilities to compare and choose an apropriate value. 
|  Author  : M.Postol
|  System  : LOGITECH MODULA-2/86 
|  History :
|     01-02-97: M.Postol
|       new procedure WorseBLessDis
|
|  Copyright (C), CAS LODZ POLAND.
|  TEL: 42' 862 547, 42' 87 80 44 FAX/TEL: 42' 84 48 40
|
**********************************************************************)
(*.F+ *)
IMPLEMENTATION MODULE WorseBecause;

  FROM CommonTypes  IMPORT
    SigNilVal, SignalDsc, DisNilVal;

  FROM SYSTEM  IMPORT
    WORD;
    
  PROCEDURE WorseBLess
            ( VAR sig   : SignalDsc;
                  cv    : INTEGER;
                  index : WORD      );

  BEGIN
    WITH sig DO
      IF (cv # SigNilVal) AND ((val = SigNilVal) OR (val > cv))
      THEN
        val := cv;
        pos := index
      END (* if *);
    END (* with sig *);
  END WorseBLess;

  PROCEDURE WorseBLessDis
            ( VAR sig   : CARDINAL;
                  cv    : CARDINAL );

  BEGIN
    IF (cv # DisNilVal) AND (( sig = DisNilVal ) OR ( sig> cv))
    THEN
      sig := cv;
    END (* if *);
  END WorseBLessDis;

  PROCEDURE WorseBGreater
            ( VAR sig   : SignalDsc;
                  cv    : INTEGER;
                  index : WORD        );

  BEGIN
    WITH sig DO
      IF (cv # SigNilVal) AND ((val = SigNilVal) OR (val < cv))
      THEN
        val := cv;
        pos := index
      END (* if *);
    END (* with sig *);
  END WorseBGreater;

END WorseBecause.
