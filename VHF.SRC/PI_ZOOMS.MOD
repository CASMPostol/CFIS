IMPLEMENTATION MODULE PI_ZoomSpecific;

FROM CommonTypes IMPORT
  GlownyOdbiornikT, OdnDlaPomBleduT;
FROM H_CommonTypes IMPORT
  ProceduraT, Procedura;
FROM H_Files IMPORT
  GetSigFileName;
FROM Files IMPORT
  CommSig, GetCommSigFName, GetALfaRefFName, GetDisRefFName;
FROM CommonData IMPORT
  SciezkaOpisuPomiaru, OdnDlaPomOdl;
FROM RTSMain IMPORT
  Terminate, Status;
IMPORT
  Strings, Zoom;



  PROCEDURE ZmiennaNiezalezna(KtoryPomiar : BOOLEAN) : BOOLEAN;
    VAR
      str : ARRAY[0..99] OF CHAR;
    BEGIN
      Strings.Assign( SciezkaOpisuPomiaru, Sciezka );
      GetDisRefFName( OdnDlaPomOdl, KtoryPomiar, str );
      Strings.Insert( SciezkaOpisuPomiaru, str, 0 );
      RETURN Zoom.ZmiennaNiezalezna( str, FALSE );
    END ZmiennaNiezalezna;

  PROCEDURE InitNames( KtoryPomiar : BOOLEAN );
    VAR
      i, j : CARDINAL;
    BEGIN
      FOR i := 0 TO HIGH( Opisy ) DO
        FOR j := 0 TO MAX_NR_WYKR-1 DO
          Opisy[i].NazwaPliku[j][0] := 0C;
        END;
      END;
      IF NOT KtoryPomiar THEN
        WITH Opisy[0] DO
          OpisTekstowy := "AGC";
          GetSigFileName( NazwaPliku[0] );
          Logarytmiczny := TRUE;
          Podzielnik := 1;
        END;
        i := 1;
      ELSE
        HALT; (* nie ma DME *)
      END;
      WITH Opisy[i+0] DO
        OpisTekstowy := "EPE";
        GetCommSigFName( CS_GPS_EPE, KtoryPomiar, NazwaPliku[0] );
        Logarytmiczny := FALSE;
        Podzielnik := 100;
      END;
      WITH Opisy[i+1] DO
        OpisTekstowy := "Liczba satelit¢w";
        GetCommSigFName( CS_GPS_NOS, KtoryPomiar, NazwaPliku[0] );
        Logarytmiczny := FALSE;
        Podzielnik := 1;
      END;
      WITH Opisy[i+2] DO
        OpisTekstowy := "Bˆ¥d pilota";
        GetCommSigFName( CS_PilError, KtoryPomiar, NazwaPliku[0] );
        Logarytmiczny := FALSE;
        Podzielnik := 100;
      END;
      WITH Opisy[i+3] DO
        OpisTekstowy := "Wysoko˜†";
        GetCommSigFName( CS_Alt_Sg, KtoryPomiar, NazwaPliku[0] );
        Logarytmiczny := FALSE;
        Podzielnik := 1;
      END;
    END InitNames;

  PROCEDURE NazwaOdniesienia( KtoryPomiar : BOOLEAN; VAR s : ARRAY OF CHAR );
    BEGIN
      IF KtoryPomiar THEN
        HALT;
      ELSE
        Strings.ConstAssign( "Dla VHF", s );
      END;
    END NazwaOdniesienia;

END PI_ZoomSpecific.
