(*.F- *)
(**********************************************************************
|  Title   : Inicjacja danych dla danych statycznych 
|  Author  : M.Morawski
|  System  : LOGITECH MODULA-2/86 
|  History :
|    10-05-97: M.Postol
|      poprawilem napisy, wspolczynniki dla zmiennych i blad zwiazany z 
|      rysowaniem bledu pilota
|
|  Copyright (C), CAS LODZ POLAND.
|  TEL: 42' 86 58 12, 42' 87 80 44 FAX/TEL: 42' 84 48 40
|
**********************************************************************)
(*.F+ *)
IMPLEMENTATION MODULE PI_ZoomSpecific;

FROM CommonTypes IMPORT
  GlownyOdbiornikT, OdnDlaPomBleduT;
FROM L_CommonTypes IMPORT
  Signals, ProceduraT,
  (* PROCEDURE *) CzyToJestPromien;
FROM L_Files IMPORT
  GetSigFileName, GetResFileName, resultT;
FROM Files IMPORT
  CommSig, GetCommSigFName, GetALfaRefFName, GetDisRefFName;
FROM L_CommonTypes IMPORT
  Procedura;
FROM CommonData IMPORT
  SciezkaOpisuPomiaru, OdnDlaPomBledu, OdnDlaPomOdl;
FROM RTSMain IMPORT
  Terminate, Status;
FROM D_Files IMPORT
  GetFileName;
IMPORT
  Strings, D_results, Zoom;

  FROM L_results IMPORT
    anRes;
  

  PROCEDURE ZmiennaNiezalezna(KtoryPomiar : BOOLEAN) : BOOLEAN;
    VAR
      str : ARRAY[0..99] OF CHAR;
    BEGIN
      Strings.Assign( SciezkaOpisuPomiaru, Sciezka );
      IF (Procedura < pSzer_i_Osi_pB)      OR
         (Procedura = pMarker)             OR
         (Procedura = pRownowagaModulacji) OR
         (Procedura = pFazowanie)
      THEN
        GetDisRefFName( OdnDlaPomOdl, KtoryPomiar, str );
        Strings.Insert( SciezkaOpisuPomiaru, str, 0 );
        RETURN Zoom.ZmiennaNiezalezna( str, FALSE );
      ELSE
        GetALfaRefFName( OdnDlaPomBledu, KtoryPomiar, str );
        Strings.Insert( SciezkaOpisuPomiaru, str, 0 );
        RETURN Zoom.ZmiennaNiezalezna( str, TRUE );
      END;
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
          OpisTekstowy := "DEW (G) [uA]";
          GetSigFileName( devL_Sg, goA, NazwaPliku[0] );
          Logarytmiczny := FALSE;
          Podzielnik := 10;
        END;
        WITH Opisy[1] DO
          OpisTekstowy := "DEW (Z) [uA]";
          GetSigFileName( devL_Sg, goB, NazwaPliku[0] );
          Logarytmiczny := FALSE;
          Podzielnik := 10;
        END;
        WITH Opisy[2] DO
          OpisTekstowy := "%MOD (G) [%]";
          GetSigFileName( modL_Sg, goA, NazwaPliku[0] );
          Logarytmiczny := FALSE;
          Podzielnik := 10;
        END;
        WITH Opisy[3] DO
          OpisTekstowy := "%MOD (Z) [%]";
          GetSigFileName( modL_Sg, goB, NazwaPliku[0] );
          Logarytmiczny := FALSE;
          Podzielnik := 10;
        END;
        WITH Opisy[4] DO
          OpisTekstowy := "AGC (G) [uV]";
          GetSigFileName( agcL_Sg, goA, NazwaPliku[0] );
          Logarytmiczny := TRUE;
          Podzielnik := 1;
        END;
        WITH Opisy[5] DO
          OpisTekstowy := "AGC (Z) [uV]";
          GetSigFileName( agcL_Sg, goB, NazwaPliku[0] );
          Logarytmiczny := TRUE;
          Podzielnik := 1;
        END;
        WITH Opisy[6] DO
          OpisTekstowy := "MKR.AGC (G) [uV]";
          GetSigFileName( agcM_Sg, goA, NazwaPliku[0] );
          Logarytmiczny := TRUE;
          Podzielnik := 1;
        END;
        WITH Opisy[7] DO
          OpisTekstowy := "MKR.AGC (Z) uV]";
          GetSigFileName( agcM_Sg, goB, NazwaPliku[0] );
          Logarytmiczny := TRUE;
          Podzielnik := 1;
        END;
        WITH Opisy[8] DO
          OpisTekstowy := "DIF (GPS)(G) [uA]";
          GetResFileName( Dif, pbGPS, goA, NazwaPliku[0] );
          GetResFileName( DifAV, pbGPS, goA, NazwaPliku[1] );
          GetResFileName( boundP, pbGPS, goA, NazwaPliku[2] );
          GetResFileName( boundM, pbGPS, goA, NazwaPliku[3] );
          Logarytmiczny := FALSE;
          Podzielnik := 10;
        END;
        WITH Opisy[9] DO
          OpisTekstowy := "DIF (GPS)(Z) [uA]";
          GetResFileName( Dif, pbGPS, goB, NazwaPliku[0] );
          GetResFileName( DifAV, pbGPS, goB, NazwaPliku[1] );
          GetResFileName( boundP, pbGPS, goB, NazwaPliku[2] );
          GetResFileName( boundM, pbGPS, goB, NazwaPliku[3] );
          Logarytmiczny := FALSE;
          Podzielnik := 10;
        END;
        WITH Opisy[10] DO
          OpisTekstowy := "DIF (TEO)(G) [uA]";
          GetResFileName( Dif, pbTeodolit, goA, NazwaPliku[0] );
          GetResFileName( DifAV, pbTeodolit, goA, NazwaPliku[1] );
          GetResFileName( boundP, pbTeodolit, goA, NazwaPliku[2] );
          GetResFileName( boundM, pbTeodolit, goA, NazwaPliku[3] );
          Logarytmiczny := FALSE;
          Podzielnik := 10;
        END;
        WITH Opisy[11] DO
          OpisTekstowy := "DIF (TEO)(Z) [uA]";
          GetResFileName( Dif, pbTeodolit, goB, NazwaPliku[0] );
          GetResFileName( DifAV, pbTeodolit, goB, NazwaPliku[1] );
          GetResFileName( boundP, pbTeodolit, goB, NazwaPliku[2] );
          GetResFileName( boundM, pbTeodolit, goB, NazwaPliku[3] );
          Logarytmiczny := FALSE;
          Podzielnik := 10;
        END;
        WITH Opisy[12] DO
          OpisTekstowy := "Sekt.(GPS)(G)[ø]";
          GetResFileName( SecWith, pbGPS, goA, NazwaPliku[0] );
          Logarytmiczny := FALSE;
          Podzielnik := 100;
        END;
        WITH Opisy[13] DO
          OpisTekstowy := "Sekt.(GPS)(Z)[ø]";
          GetResFileName( SecWith, pbGPS, goB, NazwaPliku[0] );
          Logarytmiczny := FALSE;
          Podzielnik := 100;
        END;
        WITH Opisy[14] DO
          OpisTekstowy := "Sekt.(TEO)(G)[ø]";
          GetResFileName( SecWith, pbTeodolit, goA, NazwaPliku[0] );
          Logarytmiczny := FALSE;
          Podzielnik := 100;
        END;
        WITH Opisy[15] DO
          OpisTekstowy := "Sekt.(TEO)(Z)[ø]";
          GetResFileName( SecWith, pbTeodolit, goB, NazwaPliku[0] );
          Logarytmiczny := FALSE;
          Podzielnik := 100;
        END;
        i := 16;
      ELSE
        WITH Opisy[0] DO
          OpisTekstowy := "DME %Rep (G) [%]";
          GetFileName( D_results.Replay, goA, NazwaPliku[0] );
          Logarytmiczny := FALSE;
          Podzielnik := 10;
        END;
        WITH Opisy[1] DO
          OpisTekstowy := "DME %Rep (Z) [%]";
          GetFileName( D_results.Replay, goB, NazwaPliku[0] );
          Logarytmiczny := FALSE;
          Podzielnik := 10;
        END;
        WITH Opisy[2] DO
          OpisTekstowy := "Squitter (G)";
          GetFileName( D_results.Squiter, goA, NazwaPliku[0] );
          Logarytmiczny := FALSE;
          Podzielnik := 1;
        END;
        WITH Opisy[3] DO
          OpisTekstowy := "Squitter (Z)";
          GetFileName( D_results.Squiter, goB, NazwaPliku[0] );
          Logarytmiczny := FALSE;
          Podzielnik := 1;
        END;
        WITH Opisy[4] DO
          OpisTekstowy := "DME.AGC (G) [dBm]";
          GetFileName( D_results.AGC, goA, NazwaPliku[0] );
          Logarytmiczny := FALSE;
          Podzielnik := 1;
        END;
        WITH Opisy[5] DO
          OpisTekstowy := "DME.AGC (Z) [dBm]";
          GetFileName( D_results.AGC, goB, NazwaPliku[0] );
          Logarytmiczny := FALSE;
          Podzielnik := 1;
        END;
        WITH Opisy[6] DO
          OpisTekstowy := "Bˆ¥d odl.(G) [Nm]";
          GetFileName( D_results.DistErr, goA, NazwaPliku[0] );
          Logarytmiczny := FALSE;
          Podzielnik := 500;
        END;
        WITH Opisy[7] DO
          OpisTekstowy := "Bˆ¥d odl.(Z) [Nm]";
          GetFileName( D_results.DistErr, goB, NazwaPliku[0] );
          Logarytmiczny := FALSE;
          Podzielnik := 500;
        END;
        i := 8;
      END;
      WITH Opisy[i+0] DO
        OpisTekstowy := "EPE x 100 [NM]";
        GetCommSigFName( CS_GPS_EPE, KtoryPomiar, NazwaPliku[0] );
        Logarytmiczny := FALSE;
        Podzielnik := 1;
      END;
      WITH Opisy[i+1] DO
        OpisTekstowy := "Liczba satelit¢w";
        GetCommSigFName( CS_GPS_NOS, KtoryPomiar, NazwaPliku[0] );
        Logarytmiczny := FALSE;
        Podzielnik := 1;
      END;
      WITH Opisy[i+2] DO
        GetCommSigFName( CS_PilError, KtoryPomiar, NazwaPliku[0] );
        Logarytmiczny := FALSE;
        WITH anRes  DO
          IF CzyToJestPromien(anRes.procedure)  THEN
            OpisTekstowy := "Bˆ¥d pilota [uA]";
            Podzielnik := 10;
          ELSE
            OpisTekstowy := "Bˆ¥d pilota [NM]";
            Podzielnik := 500;
          END;
        END;
      END;
      WITH Opisy[i+3] DO
        OpisTekstowy := "Wysoko˜† [ft]";
        GetCommSigFName( CS_Alt_Sg, KtoryPomiar, NazwaPliku[0] );
        Logarytmiczny := FALSE;
        Podzielnik := 1;
      END;
    END InitNames;

  PROCEDURE NazwaOdniesienia( KtoryPomiar : BOOLEAN; VAR s : ARRAY OF CHAR );
    BEGIN
      IF KtoryPomiar THEN
        Strings.ConstAssign( "Dla LOC", s );
      ELSE
        Strings.ConstAssign( "Dla DME", s );
      END;
    END NazwaOdniesienia;

END PI_ZoomSpecific.
