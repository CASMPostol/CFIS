MODULE TZL;

IMPORT
  DebugPMD, DOSEntry, MANAGER, SimScanner, Strings;

  FROM Timer IMPORT
    Wait, TInOneSecond;

  FROM ZoomInterface IMPORT
    Show;

  FROM L_CommonTypes IMPORT
    ProceduraT;

  FROM CommonTypes IMPORT
    OdnDlaPomBleduT, OdnDlaPomOdlT;

  FROM L_Oblot IMPORT
    Procedura, SciezkaOpisuPomiaru, OdnDlaPomBledu, OdnDlaPomOdl;


BEGIN
  Procedura := pAlarmOsi;
  SciezkaOpisuPomiaru := "g:\ils\003\004_a.loc\";
  Strings.Assign( SciezkaOpisuPomiaru, SimScanner.SciezkaOpisu );
  OdnDlaPomBledu := pbGPS;
  OdnDlaPomOdl := poZadanaPredkosc;
  SimScanner.OdnDlaPomBledu := OdnDlaPomBledu;
  SimScanner.OdnDlaPomOdl   := OdnDlaPomOdl;
  Show( TRUE );
  Wait( TInOneSecond()*3 );
END TZL.
