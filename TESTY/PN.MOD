MODULE PN;

  IMPORT
    DebugPMD, MANAGER, DOSEntry;
  FROM N_Inspekcja IMPORT
    InspekcjaEP, InspekcjaEvent;
  FROM N_Oblot IMPORT
    InitLot, Zapisz;

VAR
  i : InspekcjaEvent;
  ok : BOOLEAN;
BEGIN
  i := InspekcjaEP( TRUE );
  ok := InitLot( TRUE );
  Zapisz( FALSE, 123 );
END PN.
