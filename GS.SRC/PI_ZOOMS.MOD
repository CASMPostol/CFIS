IMPLEMENTATION MODULE PI_ZoomSpecific;

FROM CommonTypes IMPORT
  GlownyOdbiornikT, OdnDlaPomBleduT;
FROM G_CommonTypes IMPORT
  ProceduraT, Procedura;
FROM G_Files IMPORT
  GetSigFileName, GetResFileName, resultT, Signals;
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
          OpisTekstowy := "Dew. GS (G)";
          GetSigFileName( devG_Sg, goA, NazwaPliku[0] );
          Logarytmiczny := FALSE;
          Podzielnik := 10;
        END;
        WITH Opisy[1] DO
          OpisTekstowy := "Dew. GS (Z)";
          GetSigFileName( devG_Sg, goB, NazwaPliku[0] );
          Logarytmiczny := FALSE;
          Podzielnik := 10;
        END;
        WITH Opisy[2] DO
          OpisTekstowy := "Dew. LOC (G)";
          GetSigFileName( devL_Sg, goA, NazwaPliku[0] );
          Logarytmiczny := FALSE;
          Podzielnik := 10;
        END;
        WITH Opisy[3] DO
          OpisTekstowy := "Dew. LOC (Z)";
          GetSigFileName( devL_Sg, goB, NazwaPliku[0] );
          Logarytmiczny := FALSE;
          Podzielnik := 10;
        END;
        WITH Opisy[4] DO
          OpisTekstowy := "%MOD (G)";
          GetSigFileName( modG_Sg, goA, NazwaPliku[0] );
          Logarytmiczny := FALSE;
          Podzielnik := 10;
        END;
        WITH Opisy[5] DO
          OpisTekstowy := "%MOD (Z)";
          GetSigFileName( modG_Sg, goB, NazwaPliku[0] );
          Logarytmiczny := FALSE;
          Podzielnik := 10;
        END;
        WITH Opisy[6] DO
          OpisTekstowy := "AGC (G)";
          GetSigFileName( agcG_Sg, goA, NazwaPliku[0] );
          Logarytmiczny := TRUE;
          Podzielnik := 1;
        END;
        WITH Opisy[7] DO
          OpisTekstowy := "AGC (Z)";
          GetSigFileName( agcG_Sg, goB, NazwaPliku[0] );
          Logarytmiczny := TRUE;
          Podzielnik := 1;
        END;
        WITH Opisy[8] DO
          OpisTekstowy := "AGC-marker (G)";
          GetSigFileName( agcM_Sg, goA, NazwaPliku[0] );
          Logarytmiczny := TRUE;
          Podzielnik := 1;
        END;
        WITH Opisy[9] DO
          OpisTekstowy := "AGC-marker (Z)";
          GetSigFileName( agcM_Sg, goB, NazwaPliku[0] );
          Logarytmiczny := TRUE;
          Podzielnik := 1;
        END;
        WITH Opisy[10] DO
          OpisTekstowy := "Dif (G)";
          GetResFileName( Dif, goA, NazwaPliku[0] );
          GetResFileName( DifAV, goA, NazwaPliku[1] );
          GetResFileName( boundP, goA, NazwaPliku[2] );
          GetResFileName( boundM, goA, NazwaPliku[3] );
          Logarytmiczny := FALSE;
          Podzielnik := 10;
        END;
        WITH Opisy[11] DO
          OpisTekstowy := "Dif (Z)";
          GetResFileName( Dif, goB, NazwaPliku[0] );
          GetResFileName( DifAV, goB, NazwaPliku[1] );
          GetResFileName( boundP, goB, NazwaPliku[2] );
          GetResFileName( boundM, goB, NazwaPliku[3] );
          Logarytmiczny := FALSE;
          Podzielnik := 10;
        END;
        WITH Opisy[12] DO
          OpisTekstowy := "Szer.sekt.(G)";
          GetResFileName( SecWith, goA, NazwaPliku[0] );
          Logarytmiczny := FALSE;
          Podzielnik := 100;
        END;
        WITH Opisy[13] DO
          OpisTekstowy := "Szer.sekt.(Z)";
          GetResFileName( SecWith, goB, NazwaPliku[0] );
          Logarytmiczny := FALSE;
          Podzielnik := 100;
        END;
        i := 14;
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
        OpisTekstowy := "Wysoko˜†";
        GetCommSigFName( CS_Alt_Sg, KtoryPomiar, NazwaPliku[0] );
        Logarytmiczny := FALSE;
        Podzielnik := 1;
      END;
    END InitNames;

  PROCEDURE NazwaOdniesienia( KtoryPomiar : BOOLEAN; VAR s : ARRAY OF CHAR );
    BEGIN
      IF KtoryPomiar THEN
        Strings.ConstAssign( "Dla GS", s );
      ELSE
        HALT;
      END;
    END NazwaOdniesienia;

END PI_ZoomSpecific.
