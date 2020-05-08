(*.F- *)
(**********************************************************************
|  Title   : Procedury inicjacyjne dla obslugi wykresow statycznych 
|  Author  : M.Morawski
|  System  : LOGITECH MODULA-2/86 
|  History :
|    10-05-97: M.Postol
|      blad pilota moze byc w NM i ø.
|      dopisalem miana
|      zmiana nazwy
|
|  Copyright (C), CAS LODZ POLAND.
|  TEL: 42' 862 547, 42' 87 80 44 FAX/TEL: 42' 84 48 40
|
**********************************************************************)
(*.F+ *)
IMPLEMENTATION MODULE PI_ZoomSpecific;

FROM V_results IMPORT
  anRes;
FROM CommonTypes IMPORT
  GlownyOdbiornikT, OdnDlaPomBleduT;
FROM V_results IMPORT
  Signals;
FROM V_Files IMPORT
  GetSigFileName, GetResFileName;
FROM V_CommonTypes  IMPORT
  ProceduraT;
FROM V_CommonTypes IMPORT
  Procedura;
FROM CommonData IMPORT
  SciezkaOpisuPomiaru, OdnDlaPomBledu, OdnDlaPomOdl;
FROM RTSMain IMPORT
  Terminate, Status;
FROM D_Files IMPORT
  GetFileName;
FROM Files IMPORT
  CommSig, GetCommSigFName, GetALfaRefFName, GetDisRefFName;
FROM Zoom IMPORT
  Wykres;
IMPORT
  Strings, D_results, Zoom;



  PROCEDURE ZmiennaNiezalezna( KtoryPomiar : BOOLEAN ) : BOOLEAN;
    VAR
      str : ARRAY[0..99] OF CHAR;
    BEGIN
      Strings.Assign( SciezkaOpisuPomiaru, Sciezka );
      IF Procedura < pPromienBlad THEN
        GetALfaRefFName( OdnDlaPomBledu, KtoryPomiar, str );
        Strings.Insert( SciezkaOpisuPomiaru, str, 0 );
        RETURN Zoom.ZmiennaNiezalezna( str, TRUE );
      ELSE
        GetDisRefFName( OdnDlaPomOdl, KtoryPomiar, str );
        Strings.Insert( SciezkaOpisuPomiaru, str, 0 );
        RETURN Zoom.ZmiennaNiezalezna( str, FALSE );
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
          OpisTekstowy := "Namiar (G) [ø]";
          GetSigFileName( Obr, goA, NazwaPliku[0] );
          Logarytmiczny := FALSE;
          Podzielnik := 100;
        END;
        WITH Opisy[1] DO
          OpisTekstowy := "Namiar (Z) [ø]";
          GetSigFileName( Obr, goB, NazwaPliku[0] );
          Logarytmiczny := FALSE;
          Podzielnik := 100;
        END;
        WITH Opisy[2] DO
          OpisTekstowy := "%MOD VAR (G) [%]";
          GetSigFileName( Var, goA, NazwaPliku[0] );
          Logarytmiczny := FALSE;
          Podzielnik := 10;
        END;
        WITH Opisy[3] DO
          OpisTekstowy := "%MOD VAR (Z) [%]";
          GetSigFileName( Var, goB, NazwaPliku[0] );
          Logarytmiczny := FALSE;
          Podzielnik := 10;
        END;
        WITH Opisy[4] DO
          OpisTekstowy := "IDX MOD REF (G)";
          GetSigFileName( Ref, goA, NazwaPliku[0] );
          Logarytmiczny := FALSE;
          Podzielnik := 10;
        END;
        WITH Opisy[5] DO
          OpisTekstowy := "IDX MOD REF (Z)";
          GetSigFileName( Ref, goB, NazwaPliku[0] );
          Logarytmiczny := FALSE;
          Podzielnik := 10;
        END;
        WITH Opisy[6] DO
          OpisTekstowy := "%MOD SUB (G) [%]";
          GetSigFileName( Sub, goA, NazwaPliku[0] );
          Logarytmiczny := FALSE;
          Podzielnik := 10;
        END;
        WITH Opisy[7] DO
          OpisTekstowy := "%MOD SUB (Z) [%]";
          GetSigFileName( Sub, goB, NazwaPliku[0] );
          Logarytmiczny := FALSE;
          Podzielnik := 10;
        END;
        WITH Opisy[8] DO
          OpisTekstowy := "AGC (G) [uV]";
          GetSigFileName( Agc, goA, NazwaPliku[0] );
          Logarytmiczny := TRUE;
          Podzielnik := 1;
        END;
        WITH Opisy[9] DO
          OpisTekstowy := "AGC (Z)[uV]";
          GetSigFileName( Agc, goB, NazwaPliku[0] );
          Logarytmiczny := TRUE;
          Podzielnik := 1;
        END;
        WITH Opisy[10] DO
          OpisTekstowy := "Bˆ¥d (GPS)(G) [ø]";
          GetResFileName( pbGPS, goA, NazwaPliku[0] );
          Logarytmiczny := FALSE;
          Podzielnik := 100;
        END;
        WITH Opisy[11] DO
          OpisTekstowy := "Bˆ¥d (TEO)(G) [ø]";
          GetResFileName( pbTeodolit, goA, NazwaPliku[0] );
          Logarytmiczny := FALSE;
          Podzielnik := 100;
        END;
        WITH Opisy[12] DO
          OpisTekstowy := "Bˆ¥d (GPS)(Z) [ø]";
          GetResFileName( pbGPS, goB, NazwaPliku[0] );
          Logarytmiczny := FALSE;
          Podzielnik := 100;
        END;
        WITH Opisy[13] DO
          OpisTekstowy := "Bˆ¥d (TEO)(Z) [ø]";
          GetResFileName( pbTeodolit, goB, NazwaPliku[0] );
          Logarytmiczny := FALSE;
          Podzielnik := 100;
        END;
        i := 14;
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
          IF (procedure = pOkragBlad) OR (procedure = pOkragZakres)  THEN
            OpisTekstowy := "Bˆ¥d pilota [NM]";
            Podzielnik := 500;
          ELSE
            OpisTekstowy := "Bˆ¥d pilota [ø]";
            Podzielnik := 100;
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
        Strings.ConstAssign( "Dla VOR", s );
      ELSE
        Strings.ConstAssign( "Dla DME", s );
      END;
    END NazwaOdniesienia;


END PI_ZoomSpecific.
