(*.F- *)
(**********************************************************************
|  Title   : Definicja typow potrzebnych do analizy
|  Author  : M. Postol
|  System  : LOGITECH MODULA-2/86
|  History :
|    08-12-96: created
|
|  Copyright (C), CAS LODZ POLAND.
|  TEL: 42' 862 547, 42' 87 80 44 FAX/TEL: 42' 84 48 40
|
**********************************************************************)
(*.F+ *)

IMPLEMENTATION MODULE H_Count;

  FROM EventsMng IMPORT
    GetUpdNextEvent, EventKind, SaveDistEvents;

  FROM SYSTEM IMPORT
    WORD;

  FROM Files IMPORT
    XRefKind, SigInterpolacja;

  FROM CommonTypes IMPORT
    (* CONST *) SigNilVal, DisNilVal,
    (* TYPE *) SignalDsc;

  FROM H_DisResults IMPORT
    WriteTab;

  FROM H_results IMPORT
    OdcinekNr, anRes, SaveAnRes;

  FROM DisResUtilities IMPORT
    WrSPlus;

  FROM H_Files IMPORT
    (* PROCEDURE *) OpenSignalFiles, ReadAllSignals, CloseSignalFiles;

  FROM WorseBecause IMPORT
    WorseBLess;

  FROM H_CommonTypes IMPORT
    ProceduraT;

  CONST
    Pomiar = FALSE;

  PROCEDURE Analiza
            ( VAR SyntResult : INTEGER;
              VAR podzielnik : INTEGER    );
  VAR
    currNil : WORD;

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
      signalsCV : INTEGER;
      RefDisCV  : WORD;
      minSSSyn  : SignalDsc;

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
      WITH anRes DO
        dataLngth := OpenSignalFiles(procedure);
        ReadAllSignals(signalsCV, RefDisCV);
        ReadAllSignals(signalsCV, RefDisCV); (* !!!! blad w interpolacji *)
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
              WorseBLess(minSSSyn, signalsCV, RefDisCV);
              WITH analiza[a_IleOd - 1] DO
                IF pocz = currNil THEN
                  pocz := RefDisCV;
                END;
                IF RefDisCV <> currNil THEN
                  kon := RefDisCV;
                END;
                WorseBLess(SSmin, signalsCV, RefDisCV);
              END (* with analiza *);
              ReadAllSignals(signalsCV, RefDisCV);
              INC(smpIdx)
            |
            NicME :
              ;
          END (* case GetEvent *);
        END (* loop *);
      END (* with anRes *);
      CloseSignalFiles;
      podzielnik := 1;
      SyntResult := minSSSyn.val
    END DoAnaliza;

    PROCEDURE Interpolacja;
    VAR
      void : INTEGER;
    BEGIN
      SigInterpolacja(GPSRxref, Pomiar, void );
      SigInterpolacja(GPSAxref, Pomiar, void );
    END Interpolacja;
  VAR
    line : CARDINAL;

  BEGIN (* Analiza *)
    WriteTab(0, line);
    WrSPlus("Trwa interpolacja wynikow", line, 0);
    Interpolacja;
    CASE anRes.procedure OF
      pOrbita :
        WrSPlus("Zaczynam analiz© VHF na okr©gu", line, 0);
        currNil := WORD(SigNilVal);
      |
      pPromien :
        WrSPlus("Zaczynam analiz© VHF na promieniu", line, 0);
        currNil := WORD(DisNilVal);
    END (* case procedura *);
    DoAnaliza;
    WrSPlus("Trwa zachowywanie wynikow", line, 0);
    SaveAnRes(anRes);
    SaveDistEvents(Pomiar);
    WrSPlus("Analiza zakonczona", line, 0);
  END Analiza;

END H_Count.
