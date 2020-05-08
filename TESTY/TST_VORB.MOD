(*.F- *)
(**********************************************************************
|  Title   : Testowanie pomiaru na orbicie - luki 
|  Author  : M.Postol
|  System  : LOGITECH MODULA-2/86 
|  History :
|    Rel.3.0. Utworzony
|
|  Copyright (C), CAS LODZ POLAND.
|  TEL: 42' 686 25 47
|  mailto: techsupp@cas.com.pl
|  http: www.cas.com.pl
|
**********************************************************************)
(*.F+ *)
MODULE tst_vorb;

FROM VORO_avrage IMPORT
  SegmentZakonczony, InicjujOpisStanuLuku, OpisStanuLuku, PartIdx;
  
VAR
  continer  : OpisStanuLuku;
  idx       : CARDINAL;
  kat       : INTEGER;
  kompletny : BOOLEAN;
  currIndex : PartIdx;
  
BEGIN
  idx := 0;
  kat := MIN( INTEGER );
  InicjujOpisStanuLuku(continer);
  LOOP 
    IF SegmentZakonczony( kat, continer, kompletny, currIndex)
    THEN
      idx := idx;
    END;
    IF idx = MAX( CARDINAL ) THEN
      EXIT
    END;
    INC( idx );
    INC( kat )
  END (* loop *);
END tst_vorb.
