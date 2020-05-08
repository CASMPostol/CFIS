MODULE TZV;

IMPORT
  DebugPMD, DOSEntry, MANAGER, SimScanner;

  FROM ZoomInterface IMPORT
    Show;

  FROM V_CommonTypes IMPORT
    ProceduraT;

  FROM CommonTypes IMPORT
    OdnDlaPomBleduT, OdnDlaPomOdlT;

  FROM V_Oblot IMPORT
    Procedura, SciezkaOpisuPomiaru, OdnDlaPomBledu, OdnDlaPomOdl;

  FROM Strings IMPORT
    Assign;


BEGIN
  Procedura := pOkragBlad;
  SciezkaOpisuPomiaru := "g:\vor\005\blad.a\";
  Assign( SciezkaOpisuPomiaru, SimScanner.SciezkaOpisuPomiaru );
  OdnDlaPomBledu := pbGPS;
  OdnDlaPomOdl := poZadanaPredkosc;
  SimScanner.OdnDlaPomBledu := OdnDlaPomBledu;
  SimScanner.OdnDlaPomOdl   := OdnDlaPomOdl;
  Show( TRUE );
END TZV.
