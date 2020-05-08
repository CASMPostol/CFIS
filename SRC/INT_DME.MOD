(*.F- *)
(**********************************************************************
|  Title   : KDM 706 DME tranceiver interface
|  Author  : Mariusz Postol
|  System  : LOGITECH MODULA-2/86
|  History :
|
|  Copyright (C), CAS LODZ POLAND.
|  TEL: 42' 86 58 12, 42' 87 80 44 FAX/TEL: 42' 84 48 40
|
**********************************************************************)
(*.F+ *)

IMPLEMENTATION MODULE Int_DME;

  PROCEDURE DMEConvert
            (    dist : BITSET ) : INTEGER;

  VAR
    distance : CARDINAL;
    DIST     : CARDINAL;
    factor   : CARDINAL;
    forCount : CARDINAL;
    tmp      : CARDINAL;
  BEGIN (* DMEConvert *)
    distance := 0;
    factor := 4000H;
    EXCL(dist,15);
    DIST := CARDINAL( dist );
    FOR forCount := 0 TO 3 DO
      tmp := DIST DIV factor;
      IF tmp >9  THEN
        RETURN 0;
      END (* if *);
      distance := distance * 10 + tmp;
      DIST := DIST MOD factor;
      factor := factor DIV 16;
    END (* for forCount *);
    RETURN distance * 10 + DIST * 4;
  END DMEConvert;

END Int_DME.
