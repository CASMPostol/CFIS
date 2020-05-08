(*.F- *)
(**********************************************************************
|  Title   : Definicja typow potrzebnych do analizy
|  Author  : M. Postol
|  System  : LOGITECH MODULA-2/86
|  History :
|    11-12-96: created
|    Rel 3.14: MPostol
|      - zmieniono sposob licznia odcinkow z odchyleniami namiaru
|        > 5 i 10 deg. Odchylenia sa liczone w stosunku do sredniej z 2 NM
|
|  Copyright (C), CAS LODZ POLAND.
|  TEL: 42' 862 547, 42' 87 80 44 FAX/TEL: 42' 84 48 40
|
**********************************************************************)
(*.F+ *)

IMPLEMENTATION MODULE N_Count;

  FROM FlagAnal IMPORT
    FlagErr_Anal;
    
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
    (* TYPE *) SignalDsc, GlownyOdbiornikT, DisNilVal, Str40, flgTab, 
               NumStrefy,
    (* CONST *) SigNilVal,
    (* PROCEDURE *) Init_flgTab, InitSignalDsc;

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

  FROM VORR_Average IMPORT
    Bend_Descriptor, Bend_ClearContainer, Bend_AddSample;
    
  CONST
    Pomiar = FALSE;
 
  TYPE
    BendsArr     =
      ARRAY GlownyOdbiornikT OF Bend_Descriptor;

  PROCEDURE Analiza
            ( VAR SyntResult : INTEGER;
              VAR podzielnik : INTEGER );
  VAR
    currNil  : WORD;
    line     : CARDINAL;
    bendsCon : BendsArr;
    
    PROCEDURE DoAnaliza;

    TYPE
      myEvent =
        ( StartPomiaruME,
          StopPomiaruME,
          KoniecDanychME,
          DaneME,
          NicME );
    VAR
      dataLngth  : CARDINAL;
      evidx      : CARDINAL;
      smpIdx     : CARDINAL;
      signalsCV  : SignalsCVDsc;
      RefDisCV   : WORD;
      minSSSyn   : SignalDsc;
      rec        : GlownyOdbiornikT;
      dir        : INTEGER;
      refAlfaCV  : INTEGER;
      blad5Con   : flgTab;
      blad10Con  : flgTab;
      avrMoving  : INTEGER;

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
        rec :GlownyOdbiornikT;
        
      BEGIN
        InitSignalDsc(minSSSyn, currNil);
        Init_flgTab(blad5Con);
        Init_flgTab(blad10Con);
        FOR rec := MIN(GlownyOdbiornikT) TO MAX(GlownyOdbiornikT) DO
          Bend_ClearContainer( bendsCon[ rec ]);
        END;
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
              Init_flgTab(blad5Con);
              Init_flgTab(blad10Con);
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
              WorseBLess(minSSSyn, signalsCV[agc_Sg, glownyOdbiornik], RefDisCV);
              WITH analiza[a_IleOd - 1] DO
                IF pocz = currNil THEN
                  pocz := RefDisCV;
                END;
                IF RefDisCV <> currNil THEN
                  kon := RefDisCV;
                END;
                FOR rec := MIN(GlownyOdbiornikT) TO MAX(GlownyOdbiornikT) DO
                  WorseBLess( SSMin_PO[rec], signalsCV[agc_Sg, rec],
                              RefDisCV);
                  WorseBLess( SSmin[rec],    signalsCV[agc_Sg, rec], 
                              RefDisCV);
                  IF procedure = pPromien THEN
                    dir := SubAngle100(refAlfaCV, signalsCV[dir_Sg, rec]);
                    dir := AddAngle100(dir, 18000);
                    dir := SubAngle100(signalsCV[obr_Sg, rec], dir);
                    WriteFileRes(rec, dir);
                    IF RefDisCV = currNil
                    THEN
                      Bend_ClearContainer( bendsCon[ rec ] );
                    ELSE
                      IF Bend_AddSample( dir, CARDINAL(RefDisCV), avrMoving, 
                                         bendsCon[rec] )
                      THEN
                        FlagErr_Anal( blad5Con[rec],  ABS(avrMoving) >=  500, 
                                      blad5[rec],  
                                      RefDisCV, ns_no);
                        FlagErr_Anal( blad10Con[rec], ABS(avrMoving) >= 1000, 
                                      blad10[rec], 
                                      RefDisCV, ns_no);
                      END
                    END (* if RefDisCV *); 
                  END (* IF *);
                END (* for rec *);
              END (* with analiza *);
              ReadAllSignals(signalsCV, refAlfaCV, RefDisCV);
              INC(smpIdx);
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
    SaveAnRes;
    SaveDistEvents(Pomiar);
    WrSPlus("Analiza zakonczona", line, 0);
  END Analiza;

END N_Count.
