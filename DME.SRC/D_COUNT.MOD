(*.F- *)
(**********************************************************************
|  Title   : Definicja typow potrzebnych do analizy
|  Author  : M. Postol
|  System  : LOGITECH MODULA-2/86
|  History :
|    07-10-96: M.Postol
|      jesli flaga SRC wystepowala na koncu jednego odcinka i na poczatku 
|      nastepnego to powstawal blad
|    08-12-96: M.Postol
|      skorzystalem z nowego modulu WorseBecause, zmiany spowodowane zmianami w 
|      D_result.
|      byl blad - zle wyznaczal konce odcinkow
|    19-01-97: M.Postol
|      nowy def Files
|    29-01-97: M.Postol
|      modyfikacja w zwiazku z przekazywaniem precyzji
|    30-05-97: M.Postol
|      dostosowanie do nowej def FlagAnal
|
|  Copyright (C), CAS LODZ POLAND.
|  TEL: 42' 862 547, 42' 87 80 44 FAX/TEL: 42' 84 48 40
|
**********************************************************************)
(*.F+ *)

IMPLEMENTATION MODULE D_Count;

  FROM EventsMng IMPORT
    GetUpdNextEvent, EventKind, SaveDistEvents;

  FROM D_Files IMPORT
    (* TYPE *) SignalsCVDsc,
    (* PROCEDURE *) OpenSignalFiles, ReadAllSignals, CloseSignalFiles;

  FROM SYSTEM IMPORT
    WORD;

  FROM D_results IMPORT
    (* TYPE *) Signals, OdcinekNr, 
    (* VAR *) anRes,
    (* PROCEDURE *) SaveAnRes;

  FROM Files IMPORT
    XRefKind, SigInterpolacja;

  FROM CommonTypes IMPORT
    (* TYPE *) GlownyOdbiornikT, OdnDlaPomOdlT, signTabC, OdnDlaPomBleduT,
               NumStrefy, SignalDsc,
    (* CONST *) SigNilVal, DisNilVal;

  FROM  D_CommonTypes IMPORT
    ProceduraT;
    
  FROM D_DisResults IMPORT
    WriteTab;

  FROM FlagAnal IMPORT
    FlagErr_Anal;
    
  FROM DisResUtilities IMPORT
    WrSPlus;

  FROM WorseBecause  IMPORT
    WorseBLess;
  
  CONST
    Pomiar = TRUE;

  PROCEDURE Analiza
            (     procedura       : ProceduraT;
                  odnDlaOdl       : OdnDlaPomOdlT;
                  OdnDlaPomBledu  : OdnDlaPomBleduT;
                  GlownyOdbiornik : GlownyOdbiornikT;
              VAR SyntResult      : INTEGER;
              VAR precision       : INTEGER);

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
      odb       : GlownyOdbiornikT;
      evidx     : CARDINAL;
      smpIdx    : CARDINAL;
      signalsCV : SignalsCVDsc;
      RefDisCV  : WORD;
      Search    : ARRAY GlownyOdbiornikT OF BOOLEAN;
      dmeDistCV : signTabC;
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
      VAR
        odb : GlownyOdbiornikT;

      BEGIN
        WITH minSSSyn DO
          val := SigNilVal;
          pos := currNil;
        END (* with minSSSyn *);
        FOR odb := goA TO goB DO
          Search[odb] := FALSE;
        END (* for odb *);
      END ClearAllCont;

    BEGIN (* DoAnaliza *)
      ClearAllCont;
      dataLngth := OpenSignalFiles(procedura);
      evidx := 0;
      smpIdx := 0;
      ReadAllSignals(signalsCV, dmeDistCV, RefDisCV); (* blad w interpolacji *)
      ReadAllSignals(signalsCV, dmeDistCV, RefDisCV);
      WITH anRes DO
        LOOP
          CASE GetEvent(smpIdx, evidx, RefDisCV) OF
            StartPomiaruME :
              IF a_IleOd < MAX(OdcinekNr)
              THEN
                INC(a_IleOd);
                Search[goA] := FALSE;
                Search[goB] := FALSE;
              END (* if a_IleOd *);
              analiza[a_IleOd - 1].pocz := RefDisCV;
            |
            StopPomiaruME :
              IF RefDisCV <> currNil  THEN
                analiza[a_IleOd - 1].kon := RefDisCV;
              END;
            |
            KoniecDanychME :
              EXIT
            |
            DaneME :
              WorseBLess(minSSSyn, signalsCV[AGC, GlownyOdbiornik],
                               RefDisCV);
              FOR odb := goA TO goB DO
                WITH analiza[a_IleOd - 1] DO
                  IF pocz = currNil THEN
                    pocz := RefDisCV;
                  END;
                  IF RefDisCV <> currNil THEN
                    kon := RefDisCV;
                  END;
                  WorseBLess(SSmin[odb], signalsCV[AGC, odb], RefDisCV);
                  FlagErr_Anal(Search[odb], 
                               dmeDistCV[odb] = DisNilVal, 
                               wykluczenia[odb],
                               RefDisCV,
                               currNil,
                               ns_no);
                END (* with analiza *);
              END (* for odb *);
              ReadAllSignals(signalsCV, dmeDistCV, RefDisCV);
              INC(smpIdx)
            |
            NicME :
            ;
          END (* case GetEvent *);
        END (* loop *);
      END (* with anRes *);
      CloseSignalFiles;
      precision := 1;
      SyntResult := minSSSyn.val
    END DoAnaliza;

    PROCEDURE Interpolacja;
    VAR
      sig : XRefKind;
      dumm: WORD;
    BEGIN
      FOR sig := TEOAxref TO DME_Bxref DO
        SigInterpolacja(sig, Pomiar, dumm);
      END (* for sig *);
    END Interpolacja;
  VAR
    line : CARDINAL;

  BEGIN (* Analiza *)
    WriteTab(0, line);
    WrSPlus("Trwa interpolacja wynikow", line, 0);
    Interpolacja;
    CASE procedura OF
      pOkragBlad, pOkragZakres :
        WrSPlus("Zaczynam analiz© DME na okr©gu", line, 0);
        currNil := WORD(SigNilVal);
      |
      pPromienBlad, pPromienZakres :
        WrSPlus("Zaczynam analiz© DME na promieniu", line, 0);
        currNil := WORD(DisNilVal);
    END (* case procedura *);
    DoAnaliza;
    WrSPlus("Trwa zachowywanie wynikow", line, 0);
    SaveAnRes(anRes);
    SaveDistEvents(Pomiar);
    WrSPlus("Analiza zakonczona", line, 0);
  END Analiza;

END D_Count.
