(*.F- *)
(**********************************************************************
|  Title   : Analiza dla GS
|  Author  : M. Postol
|  System  : LOGITECH MODULA-2/86
|  History :
|    26-01-87: M.Postol
|      nieistotne poprawki edycyjne
|     23-02-97: M.Postol
|       nie zainicjowana currPilotEv w AnalyseZoneLa 
|       zminy dla nowej def ZoneBDisIdx_Init
|
|  Copyright (C), CAS LODZ POLAND.
|  TEL: 42' 862 547, 42' 87 80 44 FAX/TEL: 42' 84 48 40
|
**********************************************************************)
(*.F+ *)

IMPLEMENTATION MODULE L_Count;

  FROM EventsMng IMPORT
    GetUpdNextEvent, EventKind, SaveDistEvents, UpdateStrefa;

  FROM G_Files IMPORT
    (* TYPE *) Signals, SignalsCVDsc,
    (* PROCEDURE *) OpenSignalFiles, ReadAllSignals, CloseSignalFiles;

  FROM SYSTEM IMPORT
    WORD;

  FROM Files IMPORT
    XRefKind, SigInterpolacja, ReadFlgs, ReadXref, OpenCommSigFName,
    ReadCommSigFName, CloseCommSigFName, CommSig;

  FROM CommonTypes IMPORT
    (* TYPE *) zoneBIdx_T,
    (* CONST *) SigNilVal;

  FROM L_CommonTypes IMPORT
    (* TYPE *) NumStrefy, NumPunktu;

  FROM G_DisResults IMPORT
    WriteTab;

  FROM ILS_ZoneMngmnt IMPORT
    (* TYPE *) TraceZoneCont_T, ZoneContainer_T, zoneBDisIdx_T, IdPunktowArr_T,
               zoneSet_T,
    (* PROCEDURE *) TraceZoneCont_Clear, TraceZone, Fill_zoneBIdx,
                    Fill_zoneBDisIdx, ZoneBDisIdx_Init, ZoneConClear,
                    ZoneAnalyse, L_LstPToBeTraced;

  FROM G_CntProcedures IMPORT
    CntProcedures_Prolog, DoCountProcedures, InZoneAnalyse, Close_CntProcedures
    , CntProcedures_Epilog, DoBendAnalyse;

  FROM G_results IMPORT
    anRes, SaveAnRes;

  FROM MANAGER IMPORT
    Assert;

  FROM DisResUtilities IMPORT
    WrSPlus;

  FROM L_DataBase IMPORT
    GsMoveDis;

  CONST
    Pomiar = FALSE;

  TYPE
    myEvent =
      ( StartPomiaruME,
        KoniecDanychME,
        PolVLewoME,
        PolVZeroME,
        PolVPrawoME,
        DaneME,
        PilotEvME,
        NicME );

  VAR
    PolVLewoC  : CARDINAL;
    PolVZeroC  : CARDINAL;
    PolVPrawoC : CARDINAL;

  PROCEDURE Analiza
            ( VAR SyntResult      : INTEGER;
              VAR podzielnik      : INTEGER);
  VAR
    line : CARDINAL;

    PROCEDURE Interpolacja;
    VAR
      sig  : XRefKind;
      last : WORD;
    BEGIN
      FOR sig := TEOAxref TO DME_Bxref DO
        SigInterpolacja(sig, Pomiar, last);
      END (* for sig *);
    END Interpolacja;

    PROCEDURE Do_Analiza
              ( VAR SyntResult : INTEGER );

    TYPE
      TyppomiaruT =
        ( pNORM,
          pOFF,
          pLEFT,
          pZERO,
          pRIGHT );
    VAR
      currZoneBDisIdx : zoneBDisIdx_T;
      currZoneBIdx    : zoneBIdx_T;
      doInZoneAnalyse : BOOLEAN;
      doStructAn      : BOOLEAN;
      zoneExluded     : zoneSet_T;

      PROCEDURE GetEvent
                (     currSmpl  : CARDINAL;
                  VAR evidx     : CARDINAL;
                      position  : WORD;
                      dataLngth : CARDINAL ) : myEvent;

      BEGIN
        CASE GetUpdNextEvent(Pomiar, currSmpl, evidx, position) OF
          StartPomiaru :
            RETURN StartPomiaruME;
          |
          PolVLewo :
            RETURN PolVLewoME;
          |
          PolVZero :
            RETURN PolVZeroME;
          |
          PolVPrawo :
            RETURN PolVPrawoME;
          |
          ZnacznikP :
            RETURN PilotEvME;
          |
          BrakZnacznika :
            IF currSmpl + 1 >= dataLngth
            THEN
              RETURN KoniecDanychME;
            END (* if position *);
            RETURN DaneME;
        ELSE
          RETURN NicME;
        END (* case GetUpdNextEvent *);
      END GetEvent;

      PROCEDURE AnalyseZoneLa
                ( VAR currZoneBDisIdx : zoneBDisIdx_T;
                  VAR currZoneBIdx    : zoneBIdx_T;
                  VAR doInZoneAnalyse : BOOLEAN       );
      VAR
        evidx          : CARDINAL;
        smpIdx         : CARDINAL;
        identPunktow   : IdPunktowArr_T;
        dataLngth      : CARDINAL;
        pointFound     : NumPunktu;
        zoneBDisIdx_DB : zoneBDisIdx_T;
        mkrNrIdent_DB  : zoneBIdx_T;
        zoneAnCon      : ZoneContainer_T;
        posDif         : CARDINAL;
        pointPosDis    : CARDINAL;
        flgsCV         : BITSET;
        currPilotEv    : BOOLEAN;
        refDisCV       : CARDINAL;

      BEGIN (* AnalyseZoneLa *)
        evidx := 0;
        smpIdx := 0;
        currPilotEv := FALSE;
        Fill_zoneBIdx(currZoneBIdx);
        Fill_zoneBDisIdx(currZoneBDisIdx);
        doInZoneAnalyse := InZoneAnalyse(identPunktow);
        IF NOT doInZoneAnalyse
        THEN
          RETURN
        END (* if doInZoneAnalyse *);
        dataLngth := OpenSignalFiles(anRes.odnDlaPomOdl);
        pointFound := MIN(NumPunktu);
        ZoneBDisIdx_Init(zoneBDisIdx_DB, mkrNrIdent_DB, anRes.glownyOdbiornik, 
                         FALSE);
        ZoneConClear(zoneAnCon, zoneBDisIdx_DB, identPunktow, mkrNrIdent_DB);
        ReadFlgs(flgsCV, Pomiar);
        ReadXref(refDisCV, Pomiar);
        LOOP
          CASE GetEvent(smpIdx, evidx, smpIdx, dataLngth) OF
            PilotEvME :
              currPilotEv := TRUE;
            |
            DaneME :
              IF ZoneAnalyse(zoneAnCon, pointFound, posDif, pointPosDis,
                             refDisCV, flgsCV, currPilotEv)
              THEN
                currZoneBDisIdx[pointFound] := GsMoveDis(pointPosDis);
                currZoneBIdx[pointFound] := smpIdx - posDif;
              END (* if ZoneAnalyse *);
              currPilotEv := FALSE;
              INC(smpIdx);
              ReadFlgs(flgsCV, Pomiar);
              ReadXref(refDisCV, Pomiar);
            |
            KoniecDanychME :
              Assert(smpIdx + 1 = dataLngth);
              EXIT;
          ELSE
          END (* case GetEvent *);
        END (* loop *);
        CloseSignalFiles;
      END AnalyseZoneLa;

      PROCEDURE AnalizeMain
                (     currZoneBIdx : zoneBIdx_T;
                  VAR zoneExluded  : zoneSet_T  );
      VAR
        evidx      : CARDINAL;
        smpIdx     : CARDINAL;
        liczdo10   : CARDINAL;
        currZone   : NumStrefy;
        ChangeZone : BOOLEAN;
        TraceCon   : TraceZoneCont_T;
        dataLngth  : CARDINAL;
        state      : TyppomiaruT;
        signalsCV  : SignalsCVDsc;
        elewCV     : INTEGER;
        refDisCV   : CARDINAL;
        flgsCV     : BITSET;
        AltFile    : CARDINAL;
        WysokoscCV : INTEGER;

        PROCEDURE CheckZone
                  ( VAR currZone        : NumStrefy;
                        currPoint       : CARDINAL;
                    VAR ChangeZone      : BOOLEAN;
                        doInZoneAnalyse : BOOLEAN   ) : BOOLEAN;
        VAR
          oldZone : NumStrefy;
          res     : BOOLEAN;

        BEGIN
          IF doInZoneAnalyse
          THEN
            oldZone := currZone;
            res := TraceZone(TraceCon, currZone, currPoint);
            ChangeZone := oldZone <> currZone;
            RETURN res
          ELSE
            RETURN TRUE
          END (* if InZoneAnalyse *);
        END CheckZone;

      BEGIN (* AnalizeMain *)
        zoneExluded := zoneSet_T {};
        evidx := 0;
        smpIdx := 0;
        liczdo10 := 0;
        currZone := MIN(NumStrefy);
        ChangeZone := FALSE;
        TraceZoneCont_Clear(TraceCon, currZoneBIdx, L_LstPToBeTraced());
        dataLngth := OpenSignalFiles(anRes.odnDlaPomOdl);
        OpenCommSigFName(CS_Alt_Sg, Pomiar, AltFile);
        refDisCV := MAX(CARDINAL);
        ReadAllSignals(signalsCV, elewCV, refDisCV);
        ReadFlgs(flgsCV, Pomiar);
        ReadCommSigFName(WysokoscCV, AltFile);
        refDisCV := GsMoveDis(refDisCV);
        LOOP
          CASE GetEvent(smpIdx, evidx, refDisCV, dataLngth) OF
            StartPomiaruME :
              state := pNORM;
            |
            PolVLewoME :
              INCL(zoneExluded, currZone);
              INC(PolVLewoC);
              state := pLEFT;
              liczdo10 := 0;
            |
            PolVZeroME :
              INCL(zoneExluded, currZone);
              INC(PolVZeroC);
              state := pZERO;
              liczdo10 := 0;
            |
            PolVPrawoME :
              INCL(zoneExluded, currZone);
              INC(PolVPrawoC);
              state := pRIGHT;
              liczdo10 := 0;
            |
            KoniecDanychME :
              EXIT;
            |
            DaneME :
              IF CheckZone(currZone, smpIdx, ChangeZone, doInZoneAnalyse)
              THEN
                CASE state OF
                  pOFF :
                  |
                  pNORM :
                    DoCountProcedures(signalsCV, elewCV, refDisCV, flgsCV,
                                      WysokoscCV, currZone);
                END (* case state *);
                INC(smpIdx);
                ReadAllSignals(signalsCV, elewCV, refDisCV);
                ReadFlgs(flgsCV, Pomiar);
                refDisCV := GsMoveDis(refDisCV);
              ELSE
                EXIT
              END (* if CheckZone *);
          ELSE
          END (* case GetEvent *);
        END (* loop *);
        CloseSignalFiles;
        CloseCommSigFName(AltFile);
      END AnalizeMain;

      PROCEDURE Do_StructAnalyse
                (    currZoneBIdx : zoneBIdx_T;
                     zoneExluded  : zoneSet_T  );
      VAR
        dataLngth : CARDINAL;
        smpIdx    : CARDINAL;
        TraceCon  : TraceZoneCont_T;
        newZone   : NumStrefy;
        signalsCV : SignalsCVDsc;
        elewCV    : INTEGER;
        refDisCV  : CARDINAL;

      BEGIN (* Do_StructAnalyse *)
        dataLngth := OpenSignalFiles(anRes.odnDlaPomOdl);
        smpIdx := 0;
        newZone := MIN(NumStrefy);
        TraceZoneCont_Clear(TraceCon, currZoneBIdx, L_LstPToBeTraced());
        WHILE TraceZone(TraceCon, newZone, smpIdx) AND (smpIdx <= dataLngth) DO
          ReadAllSignals(signalsCV, elewCV, refDisCV);
          refDisCV := GsMoveDis(refDisCV);
          DoBendAnalyse(signalsCV[devG_Sg], smpIdx, elewCV, refDisCV, newZone,
                        newZone IN zoneExluded);
          INC(smpIdx);
        END (* while TraceZone *);
        CloseSignalFiles;
      END Do_StructAnalyse;

    BEGIN (* Do_Analiza *)
      SyntResult := SigNilVal;
      WrSPlus('Trwa analiza poˆo¾enia stref', line, 0);
      AnalyseZoneLa(currZoneBDisIdx, currZoneBIdx, doInZoneAnalyse);
      UpdateStrefa(currZoneBIdx);
      CntProcedures_Prolog;
      WrSPlus('Trwa zasadnicza analiza danych', line, 0);
      AnalizeMain(currZoneBIdx, zoneExluded);
      WrSPlus('Zasadnicza analiza danych zakoäczona', line, 0);
      CntProcedures_Epilog(currZoneBIdx, currZoneBDisIdx, doStructAn);
      IF doStructAn
      THEN
        WrSPlus('Trwa analiza przekroczeä', line, 0);
        Do_StructAnalyse(currZoneBIdx, zoneExluded);
      END (* if doStructAn *);
      WrSPlus('Analiza danych zakoäczona', line, 0);
      Close_CntProcedures(SyntResult, podzielnik, currZoneBDisIdx);
      IF SyntResult <> SigNilVal
      THEN
        WrSPlus('Wyznaczono rezultat koäcowy', line, 0);
      ELSE
        WrSPlus('Brak rezultatu koäcowego', line, 0);
      END (* if SyntResult *);
    END Do_Analiza;

  BEGIN
    WriteTab(0, line);
    WrSPlus('Trwa interpolacja danych pomiarowych', line, 0);
    Interpolacja;
    Do_Analiza(SyntResult);
    SaveAnRes(anRes);
    SaveDistEvents(Pomiar);
  END Analiza;

BEGIN
  PolVLewoC := 0;
  PolVZeroC := 0;
  PolVPrawoC := 0;
END L_Count.
