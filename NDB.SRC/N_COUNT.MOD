(*.F- *)
(**********************************************************************
|  Title   : Definicja typow potrzebnych do analizy
|  Author  : M. Postol
|  System  : LOGITECH MODULA-2/86
|  History :
|    11-12-96: created
|
|  Copyright (C), CAS LODZ POLAND.
|  TEL: 42' 862 547, 42' 87 80 44 FAX/TEL: 42' 84 48 40
|
**********************************************************************)
(*.F+ *)

IMPLEMENTATION MODULE N_Count;

  FROM N_CommonTypes IMPORT
    ProceduraT;

  FROM EventsMng IMPORT
    GetUpdNextEvent, EventKind, SaveDistEvents;

  FROM N_Files IMPORT
    (* PROCEDURE *) OpenSignalFiles, ReadAllSignals, WriteFileRes,
                    CloseSignalFiles,
                    OpenFileRes, CloseFileRes, GetSigFileName,
    (* TYPE *) SignalsCVDsc, Signals;

  FROM SYSTEM IMPORT
    WORD;

  FROM Files IMPORT
    XRefKind, SigInterpolacja, GetCommSigFName, CommSig, FInterpolacja;

  FROM CommonTypes IMPORT
    (* TYPE *) SignalDsc, GlownyOdbiornikT, DisNilVal, Str40,
    (* CONST *) SigNilVal;

  FROM N_results IMPORT
    OdcinekNr, anRes, SaveAnRes;

  FROM N_DisResults IMPORT
    WriteTab;

  FROM DisResUtilities IMPORT
    WrSPlus;

  FROM WorseBecause IMPORT
    WorseBLess;

  FROM SpecConv IMPORT
    SubAngle100, AddAngle100;

  CONST
    Pomiar = FALSE;

  PROCEDURE Analiza
            ( VAR SyntResult : INTEGER;
              VAR podzielnik : INTEGER );
  VAR
    currNil : WORD;
    line    : CARDINAL;

    PROCEDURE DoAnaliza;

    TYPE
      myEvent =
        ( StartPomiaruME,
          StopPomiaruME,
          KoniecDanychME,
          DaneME,
          NicME );
    VAR
      dataLngth : CARDINAL;
      evidx     : CARDINAL;
      smpIdx    : CARDINAL;
      signalsCV : SignalsCVDsc;
      RefDisCV  : WORD;
      minSSSyn  : SignalDsc;
      rec       : GlownyOdbiornikT;
      dir       : INTEGER;
      refAlfaCV : INTEGER;

      PROCEDURE GetEvent
                (     currSmpl : CARDINAL;
                  VAR evidx    : CARDINAL;
                      position : WORD     ) : myEvent;

      BEGIN
        CASE GetUpdNextEvent(Pomiar, currSmpl, evidx, position) OF
          StartPomiaru :
            RETURN StartPomiaruME;
          |
          StopPomiaru :
            RETURN StopPomiaruME;
          |
          BrakZnacznika :
            IF currSmpl + 1 > dataLngth
            THEN
              RETURN KoniecDanychME;
            END (* if position *);
            RETURN DaneME;
        ELSE
          RETURN NicME;
        END (* case GetUpdNextEvent *);
      END GetEvent;

      PROCEDURE ClearAllCont;

      BEGIN
        WITH minSSSyn DO
          val := SigNilVal;
          pos := currNil;
        END (* with minSSSyn *);
      END ClearAllCont;

    BEGIN (* DoAnaliza *)
      ClearAllCont;
      evidx := 0;
      smpIdx := 0;
      OpenFileRes(TRUE);
      WITH anRes DO
        dataLngth := OpenSignalFiles(procedure);
        ReadAllSignals(signalsCV, refAlfaCV, RefDisCV);
        ReadAllSignals(signalsCV, refAlfaCV, RefDisCV);   (* !!!! blad w interpolacji *)
        LOOP
          CASE GetEvent(smpIdx, evidx, RefDisCV) OF
            StartPomiaruME :
              IF a_IleOd < MAX(OdcinekNr)
              THEN
                INC(a_IleOd);
              END (* if a_IleOd *);
              analiza[a_IleOd - 1].pocz := RefDisCV;
            |
            StopPomiaruME :
              IF RefDisCV <> currNil THEN
                analiza[a_IleOd - 1].kon := RefDisCV;
              END;
            |
            KoniecDanychME :
              EXIT
            |
            DaneME :
              WorseBLess(minSSSyn, signalsCV[agc_Sg, glownyOdbiornik],
                         RefDisCV);
              FOR rec := MIN(GlownyOdbiornikT) TO MAX(GlownyOdbiornikT) DO
                WITH analiza[a_IleOd - 1] DO
                  IF pocz = currNil THEN
                    pocz := RefDisCV;
                  END;
                  IF RefDisCV <> currNil THEN
                    kon := RefDisCV;
                  END;
                  WorseBLess(SSmin[rec], signalsCV[agc_Sg, rec], RefDisCV);
                END (* with analiza *);
                dir := SubAngle100(refAlfaCV, signalsCV[dir_Sg, rec]);
                dir := AddAngle100(dir, 18000);
                dir := SubAngle100(signalsCV[obr_Sg, rec], dir);
                WriteFileRes(rec, dir);
              END (* for rec *);
              ReadAllSignals(signalsCV, refAlfaCV, RefDisCV);
              INC(smpIdx)
            |
            NicME :
              ;
          END (* case GetEvent *);
        END (* loop *);
      END (* with anRes *);
      CloseSignalFiles;
      CloseFileRes;
      podzielnik := 1;
      SyntResult := minSSSyn.val
    END DoAnaliza;

    PROCEDURE Interpolacja;
    VAR
      FileName : Str40;
      FlagName : Str40;
      rec      : GlownyOdbiornikT;
      void     : INTEGER;
    BEGIN
      SigInterpolacja(GPSRxref, Pomiar, void );
      SigInterpolacja(GPSAxref, Pomiar, void );
      GetCommSigFName(CS_Flags, FALSE, FlagName);
      FOR rec := MIN(GlownyOdbiornikT) TO MAX(GlownyOdbiornikT) DO
        GetSigFileName(dir_Sg, rec, FileName);
        FInterpolacja(FileName, FlagName, anRes.procedure = pOrbita, void );
      END;
    END Interpolacja;

  BEGIN (* Analiza *)
    WriteTab(0, line);
    WrSPlus("Trwa interpolacja wynikow", line, 0);
    Interpolacja;
    CASE anRes.procedure OF
      pOrbita :
        WrSPlus("Zaczynam analiz© NDB na okr©gu", line, 0);
        currNil := WORD(SigNilVal);
      |
      pPromien :
        WrSPlus("Zaczynam analiz© NDB na promieniu", line, 0);
        currNil := WORD(DisNilVal);
    END (* case procedura *);
    DoAnaliza;
    WrSPlus("Trwa zachowywanie wynikow", line, 0);
    SaveAnRes(anRes);
    SaveDistEvents(Pomiar);
    WrSPlus("Analiza zakonczona", line, 0);
  END Analiza;

END N_Count.
