(*.F- *)
(**********************************************************************
|  Title   : Rejestracja danych dla LOC
|  Author  : M.Postol
|  System  : LOGITECH MODULA-2/86
|  History :
|    26-10-96: M.Postol
|      created
|
|  Copyright (C), CAS LODZ POLAND.
|  TEL: 42' 862 547, 42' 87 80 44 FAX/TEL: 42' 84 48 40
|
**********************************************************************)
(*.F+ *)

IMPLEMENTATION MODULE L_DAcquizition;

  IMPORT
    MANAGER, DataCollect, Czas, L_Odb;

  FROM TheodolitRead IMPORT
    InitTeoEventId, TeoEvSignType, GetTeoEvent;

  FROM SYSTEM IMPORT
    WORD;

  FROM DataCollect IMPORT
    (* PROCEDURE *) UpdTab800, ResetDataCollect;

  FROM EventsMng IMPORT
    (* TYPE *) EventKind, NewEvent, NewTeoEvent, EventType,
    (* PROCEDURE *) EventsMngInit, NewPilotEvent;

  FROM CommonTypes IMPORT
    (* CONST *) NilValC,
    (* TYPE *) GlownyOdbiornikT, zoneBIdx_T;

  FROM L_CommonTypes IMPORT
    (* TYPE *) NumPunktu, ProceduraT;

  FROM MANAGER IMPORT
    STARTPROCESS;

  FROM ScannerI IMPORT
    (* TYPE *) DtaSignType,
    (* PROCEDURE *) NewDataAvailable, GetPilotEvent, InitPilotEventId,
    (* VAR *) RefDis, RefAlfa, ABOVESL;

  FROM L_Odb IMPORT
    (* TYPE *) SigEval,
    (* VAR *) devL, EvalVal, WykMainVal, Wyk1Val, Wyk2Val, Wyk3Val, navOdbFlg,
    (* PROCEDURE *) NastStrefa;

  FROM L_Files IMPORT
    CreateFiles, SaveData, CloseFiles;

  FROM Timer IMPORT
    Wait;

  FROM L_results IMPORT
    anRes;

  FROM L_Slupek IMPORT
    InitSlupek, DoneSlupek, WykMainProc, Wyk1Proc, Wyk2Proc, Wyk3Proc;

  FROM L_CntProcedures IMPORT
    InZoneAnalyse;

  FROM ILS_ZoneMngmnt IMPORT
    (* TYPE *) ZoneContainer_T, IdPunktowArr_T, zoneBDisIdx_T,
    (* PROCEDURE *) ZoneBDisIdx_Init, ZoneConClear, ZoneAnalyse;

  FROM L_DataBase IMPORT
    Lotnisko;

  CONST
    Pomiar = FALSE;

  TYPE
    AcqireProcStatType =
      ( NoComm,
        StartREQ,
        StopREQ,
        RestartREQ,
        AbortREQ,
        ConsoleEventReq );

  VAR
    ImportantDiv          : CARDINAL;
    redraw                : BOOLEAN;
    redrawM               : BOOLEAN;
    pilotEvId             : DtaSignType;
    currUpdMarks          : PROC;
    currGlownyOdbiornik   : GlownyOdbiornikT;
    TrwaPomiarPolaryzacji : BOOLEAN;
    polvfaza              : CARDINAL;
    pom2sek               : CARDINAL;
    filesNotEmpty         : BOOLEAN;

  PROCEDURE PolV
            (    phase : CARDINAL );
  VAR
    ev    : EventType;
    dummy : CARDINAL;

  BEGIN (* PolV *)
    polvfaza := phase;
    IF phase = 10
    THEN   (* nie liczyc normalnie *)
      TrwaPomiarPolaryzacji := TRUE;
      dummy := NewEvent(Pomiar, StopPomiaru, ev);
    ELSIF (phase >= 11) AND (phase <= 13)
    THEN   (* lewo , zero, prawo*)
      pom2sek := 10;
      WHILE pom2sek # 0 DO
        Wait(500);
      END (* while pom2sek *);
    ELSE
      TrwaPomiarPolaryzacji := FALSE;
      dummy := NewEvent(FALSE, StartPomiaru, ev);
    END (* if phase *);
  END PolV;

  MODULE Monitor [ 0 ];

    IMPORT
      AcqireProcStatType;

    FROM MANAGER IMPORT
      Condition, InitC, WAITC, Notify;

    EXPORT
      CommReq, Stop, ConsoleEv, Restart, GetEvent;

    VAR
      notify   : Condition;
      lastComm : AcqireProcStatType;

    PROCEDURE CommReq
              (    comm : AcqireProcStatType );

    BEGIN
      lastComm := comm;
      WAITC(notify);
    END CommReq;

    PROCEDURE Stop;
      (* zatrzymaj rejestracje *)

    BEGIN
      lastComm := StopREQ;
      WAITC(notify);
    END Stop;

    PROCEDURE ConsoleEv;

    BEGIN
      lastComm := ConsoleEventReq;
      WAITC(notify);
    END ConsoleEv;

    PROCEDURE Restart;
      (* wznow rejestracje *)

    BEGIN
      lastComm := RestartREQ;
      WAITC(notify);
    END Restart;

    PROCEDURE GetEvent() : AcqireProcStatType;
    VAR
      comm : AcqireProcStatType;

    BEGIN
      IF lastComm <> NoComm
      THEN
        comm := lastComm;
        lastComm := NoComm;
        Notify(notify);
        RETURN comm;
      END (* if lastComm *);
      RETURN NoComm;
    END GetEvent;

  BEGIN
    lastComm := NoComm;
    InitC(notify);
  END Monitor;

  PROCEDURE Acquire;
  VAR
    ev               : EventType;
    ok               : CARDINAL;
    newSeg           : BOOLEAN;
    CollectData      : BOOLEAN;
    zoneBDisIdx_DB   : zoneBDisIdx_T;
    mkrNrIdent_DB    : zoneBIdx_T;
    identPunktow     : IdPunktowArr_T;
    zoneAnCon        : ZoneContainer_T;
    makeZoneAnalyse  : BOOLEAN;
    pointFound       : NumPunktu;
    posDif           : CARDINAL;
    pointPosDis      : CARDINAL;
    currPilotEv      : BOOLEAN;
    currPilotEvBlock : CARDINAL;
    identnewSeg      : TeoEvSignType;

    PROCEDURE ZnacznikiPol;
    VAR
      ev      : EventType;
      dummy   : CARDINAL;
      EventID : EventKind;

    BEGIN
      IF pom2sek = 10
      THEN
        IF (polvfaza >= 11) AND (polvfaza <= 13)
        THEN
          EventID := PolVLewo;
          INC(EventID, polvfaza - 11);
          redrawM := TRUE;
          dummy := NewEvent(Pomiar, EventID, ev);
        END (* if *);
      END (* if pom2sek *);
      IF pom2sek # 0
      THEN
        DEC(pom2sek);
      END (* if pom2sek *);
    END ZnacznikiPol;

    PROCEDURE AssignPilotEvBlock
              ( VAR currPilotEvBlock : CARDINAL;
                    pointFound       : NumPunktu );

    BEGIN
      CASE pointFound OF
        np_A :
          currPilotEvBlock := 10 * 5;
        |
        np_B :
          currPilotEvBlock := 5 * 5;
        |
        np_CorT, np_D, np_E :
          currPilotEvBlock := 3 * 5;
      ELSE
        currPilotEvBlock := 0;
      END (* case pointFound *);
    END AssignPilotEvBlock;

  BEGIN (* Acquire *)
    InitTeoEventId(identnewSeg);
    newSeg := FALSE;
    redraw := TRUE;
    CollectData := FALSE;
    currPilotEv := FALSE;
    currPilotEvBlock := 0;
    LOOP
      NewDataAvailable;
      CASE GetEvent() OF
        NoComm :
          ;
        |
        StartREQ :
          Czas.GetTimeAndDate(ev.DatICas);
          ok := NewEvent(Pomiar, PoczatekPomiaru, ev);
          ev.Wysokosc := ABOVESL;
          ok := NewEvent(Pomiar, StartPomiaru, ev);
          redrawM := TRUE;
          newSeg := TRUE;
          L_Odb.Start;
          CollectData := TRUE;
          makeZoneAnalyse := InZoneAnalyse(identPunktow);
          IF makeZoneAnalyse
          THEN
            ZoneBDisIdx_Init(zoneBDisIdx_DB, mkrNrIdent_DB, 
                             currGlownyOdbiornik, TRUE );
            ZoneConClear( zoneAnCon, zoneBDisIdx_DB, identPunktow, 
                          mkrNrIdent_DB );
          END (* if makeZoneAnalyse *);
        |
        StopREQ :
          redrawM := TRUE;
          ok := NewEvent(Pomiar, StopPomiaru, ev);
          CollectData := FALSE;
          L_Odb.Zatrzymaj;
        |
        RestartREQ :
          redrawM := TRUE;
          ev.Wysokosc := ABOVESL;
          ok := NewEvent(Pomiar, StartPomiaru, ev);
          CollectData := TRUE;
          L_Odb.Wznow;
        |
        AbortREQ :
          L_Odb.Zatrzymaj;
          EXIT;
        |
        ConsoleEventReq :
          IF currPilotEvBlock = 0
          THEN
            WITH ev DO
              L_dev := devL[currGlownyOdbiornik];
              L_blad := EvalVal[Dif_OS, currGlownyOdbiornik];
              L_kat := RefAlfa;
            END (* with ev *);
            NewPilotEvent(Pomiar, ev);
            AssignPilotEvBlock(currPilotEvBlock, pointFound);
            currPilotEv := TRUE;
          END (* if currPilotEvBlock *);
      END (* case AcqireProcStat *);
      IF makeZoneAnalyse
      THEN
        IF ZoneAnalyse(zoneAnCon, pointFound, posDif, pointPosDis, RefDis,
                       navOdbFlg, currPilotEv)
        THEN
          WITH ev DO
            XRef := WORD(RefDis);
            L_Strefa := pointFound;
          END (* with ev *);
          ok := NewEvent(Pomiar, Strefa, ev);
          NastStrefa(pointFound);
        END (* if ZoneAnalyse *);
      END (* if makeZoneAnalyse *);
      currPilotEv := FALSE;
      IF currPilotEvBlock > 0
      THEN
        DEC(currPilotEvBlock);
      END (* if currPilotEvBlock *);
      IF CollectData
      THEN
        currUpdMarks;
        SaveData(newSeg);
        newSeg := FALSE;
        IF GetPilotEvent(pilotEvId)
        THEN
          IF currPilotEvBlock = 0
          THEN
            WITH ev DO
              L_dev := devL[currGlownyOdbiornik];
              L_blad := EvalVal[Dif_OS, currGlownyOdbiornik];
              L_kat := RefAlfa;
            END (* with ev *);
            NewPilotEvent(Pomiar, ev);
            currPilotEv := TRUE;
            redrawM := TRUE;
          END (* if currPilotEvBlock *);
        END (* if GetPilotEvent *);
        IF GetTeoEvent(identnewSeg)
        THEN
          WITH ev DO
            L_dev := devL[currGlownyOdbiornik];
            L_blad := EvalVal[Dif_OS, currGlownyOdbiornik];
            L_kat := RefAlfa;
          END (* with ev *);
          NewTeoEvent(Pomiar, ev);
        END (* if TheodolitRead.GetEvent *);
        redrawM := TRUE;
        IF TrwaPomiarPolaryzacji
        THEN
          ZnacznikiPol;
        END (* if TrwaPomiarPolaryzacji *);
      END (* if CollectData *);
    END (* process loop *);
  END Acquire;

  PROCEDURE RedrawReq
            ( VAR ix            : CARDINAL;
              VAR by2or3        : CARDINAL;
              VAR currSamplediv : CARDINAL ) : BOOLEAN;
    (* czy przerysowac ekran *)

  BEGIN
    IF DataCollect.RedrawReq(ix, by2or3, currSamplediv, Pomiar) OR redraw
    THEN
      redraw := FALSE;
      RETURN TRUE;
    END (* if redraw *);
    RETURN FALSE;
  END RedrawReq;

  PROCEDURE RedrawMarksReq
            (    waiting : CARDINAL ) : BOOLEAN;

  BEGIN
    ImportantDiv := waiting;
    IF redrawM
    THEN
      redrawM := FALSE;
      RETURN TRUE;
    END (* if redrawM *);
    RETURN FALSE;
  END RedrawMarksReq;

  PROCEDURE UpdateMarksOrbit;

  BEGIN
    UpdTab800(Pomiar, WykMainVal^, Wyk1Val^, Wyk2Val^, Wyk3Val^, redraw,
              redrawM, RefAlfa, ImportantDiv, TRUE);
  END UpdateMarksOrbit;

  PROCEDURE UpdateMarksRadial;

  BEGIN
    UpdTab800(Pomiar, WykMainVal^, Wyk1Val^, Wyk2Val^, Wyk3Val^, redraw,
              redrawM, RefDis, ImportantDiv, FALSE);
  END UpdateMarksRadial;

  PROCEDURE IniData;
  VAR
    covSecMax : INTEGER;
    covSecMin : INTEGER;

  BEGIN
    redraw := FALSE;
    redrawM := FALSE;
    ImportantDiv := NilValC;
    WITH anRes DO
      CASE procedure OF
        pZasieg_do_10 :
          covSecMax := 1000;
          covSecMin := 0;
        |
        pZasieg_10_35 :
          covSecMax := 3500;
          covSecMin := 1000;
        |
        pZasieg_ponad_35 :
          covSecMax := 17900;
          covSecMin := 3500;
      ELSE
        covSecMax := 0;
        covSecMin := 0;
      END (* case procedure *);
      L_Odb.IniData(secWith, offset, covSecMax, covSecMin, Lotnisko.ProgPasa);
      currGlownyOdbiornik := glownyOdbiornik;
    END (* with anRes *);
    InitSlupek;
    ResetDataCollect(Pomiar, WykMainProc, Wyk1Proc, Wyk2Proc, Wyk3Proc);
    EventsMngInit(Pomiar);
    InitPilotEventId(pilotEvId);
    polvfaza := 0;
    TrwaPomiarPolaryzacji := FALSE;
    filesNotEmpty := FALSE;
    CreateFiles;
    STARTPROCESS(Acquire, 0C00H, 0);
  END IniData;

  PROCEDURE IniDataOrbit;

  BEGIN
    IniData;
    currUpdMarks := UpdateMarksOrbit;
  END IniDataOrbit;

  PROCEDURE IniDataRadial;

  BEGIN
    IniData;
    currUpdMarks := UpdateMarksRadial;
  END IniDataRadial;

  PROCEDURE Start;
    (* zacznij rejestracje od poczatku *)

  BEGIN
    redraw := FALSE;
    redrawM := FALSE;
    ImportantDiv := NilValC;
    ResetDataCollect(Pomiar, WykMainProc, Wyk1Proc, Wyk2Proc, Wyk3Proc);
    EventsMngInit(Pomiar);
    IF filesNotEmpty
    THEN
      CloseFiles;
      CreateFiles;
    END (* if filesNotEmpty *);
    filesNotEmpty := TRUE;
    CommReq(StartREQ);
  END Start;

  PROCEDURE Abort;
    (* zakoncz proces rejestracji *)

  BEGIN
    filesNotEmpty := FALSE;
    CommReq(AbortREQ);
    CloseFiles;
    DoneSlupek;
  END Abort;

BEGIN
  filesNotEmpty := FALSE;
  ImportantDiv := NilValC;
  redraw := FALSE;
  redrawM := FALSE;
END L_DAcquizition.
