(*.F- *)
(**********************************************************************
|  Title   : Rejestracja danych dla GS
|  Author  : M.Morawski
|  System  : LOGITECH MODULA-2/86
|  History :
|    25-03-97:
|      odleglosc jest mierzona od progu, tzn. G_Odb.RefDis
|
|  Copyright (C), CAS LODZ POLAND.
|  TEL: 42' 862 547, 42' 87 80 44 FAX/TEL: 42' 84 48 40
|
**********************************************************************)
(*.F+ *)

IMPLEMENTATION MODULE G_DAcquizition;

  IMPORT
    MANAGER, DataCollect, G_Odb, G_Oblot, L_DataBase;

  FROM CommonData IMPORT
    SciezkaOpisuPomiaru, OdnDlaPomOdl;

  FROM DataCollect IMPORT
    (* PROCEDURE *) UpdTab800, ResetDataCollect;

  FROM EventsMng IMPORT
    (* TYPE *) EventKind, NewEvent, NewTeoEvent, EventType,
    (* PROCEDURE *) NewConsoleEvent, NewPilotEvent, Events;

  FROM CommonTypes IMPORT
    (* CONST *) NilValC, NAVA_flg, NAVB_flg, NAVA_Aud_flg, NAVB_Aud_flg,
                GSA_flg, GSB_flg, iMkrFlgPosA, iMkrFlgPosB, mMkrFlgPosA,
                mMkrFlgPosB, oMkrFlgPosA, oMkrFlgPosB, Com_Aud_flg,
    (* TYPE *) zoneBIdx_T, GlownyOdbiornikT;

  FROM L_CommonTypes IMPORT
    (* TYPE *) NumPunktu, NumStrefy;

  FROM G_CommonTypes IMPORT
    ProceduraT, Procedura;

  FROM MANAGER IMPORT
    STARTPROCESS;

  FROM ScannerI IMPORT
    (* TYPE *) DtaSignType,
    (* PROCEDURE *) NewDataAvailable, GetPilotEvent, InitPilotEventId,
    (* VAR *) RefAlfa, ABOVESL;

  FROM G_Odb IMPORT
    (* TYPE *) SigEval,
    (* VAR *) devL, EvalVal, WykMainVal, Wyk1Val, Wyk2Val, Wyk3Val, navOdbFlg,
              RefDis,
    (* PROCEDURE *) NastStrefa, Zatrzymaj, Wznow;

  FROM G_Files IMPORT
    OpenFiles, LoadData, CloseFiles;

  FROM Timer IMPORT
    Wait, TInOneSecond;

  FROM G_results IMPORT
    anRes;

  FROM L_Slupek IMPORT
    InitSlupek, DoneSlupek, WykMainProc, Wyk1Proc, Wyk2Proc, Wyk3Proc;

  FROM G_CntProcedures IMPORT
    InZoneAnalyse;

  FROM ILS_ZoneMngmnt IMPORT
    (* TYPE *) ZoneContainer_T,IdPunktowArr_T, zoneBDisIdx_T,
    (* PROCEDURE *) ZoneBDisIdx_Init, ZoneConClear, ZoneAnalyse;

  FROM L_DataBase IMPORT
    Lotnisko;

  FROM RTSMain IMPORT
    Terminate, Status;

  FROM Pomiar IMPORT
    CallStopButton;

  FROM SimScanner IMPORT
    Simulate, LoadEvents, OdtworzEventy;



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
    currUpdMarks          : PROC;
    currGlownyOdbiornik   : GlownyOdbiornikT;
    TrwaPomiarPolaryzacji : BOOLEAN;
    polvfaza              : CARDINAL;
    pom2sek               : CARDINAL;

  PROCEDURE PolV
            (    phase : CARDINAL );
  BEGIN (* PolV *)
    Terminate( Warning );
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
    posDif           : CARDINAL;
    pointPosDis      : CARDINAL;
    currPilotEv      : BOOLEAN;
    currPilotEvBlock : CARDINAL;

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
                          pointFound       : NumPunktu);
          BEGIN
            CASE currPilotEvBlock OF
              0 :
                currPilotEvBlock := 10 *5;
              |
              1 :
                currPilotEvBlock :=  5 * 5;
              |
              2, 3, 4:
                currPilotEvBlock :=  3 * 5;
              |
              5:
                currPilotEvBlock :=  NilValC;
            END;
          END AssignPilotEvBlock;

  CONST
    AzymutNieElewacja = FALSE;
  VAR
    KPoffset : INTEGER;
  BEGIN (* Acquire *)
    KPoffset := L_DataBase.Lotnisko.KierunekPasa;
    KPoffset := (KPoffset-180)*100;
    newSeg := FALSE;
    redraw := TRUE;
    CollectData := FALSE;
    currPilotEv := FALSE;
    currPilotEvBlock := 0;
    LOOP
      Wait( TInOneSecond() DIV 5 ); (* NewDataAvailable *)
      CASE GetEvent() OF
        NoComm :
          ;
        |
        StartREQ :
(*
          Czas.Godzina(ev.h, ev.m, ev.s);
          Czas.Data(ev.Y, ev.M, ev.D);
          ok := NewEvent(Pomiar, PoczatekPomiaru, ev);
          ev.Wysokosc := ABOVESL;
          ok := NewEvent(Pomiar, StartPomiaru, ev);
*)
          redrawM := TRUE;
          newSeg := TRUE;
          G_Odb.Start;
          CollectData := TRUE;
          makeZoneAnalyse := InZoneAnalyse(identPunktow);
          IF makeZoneAnalyse
          THEN
            ZoneBDisIdx_Init(zoneBDisIdx_DB, mkrNrIdent_DB,
            currGlownyOdbiornik, FALSE );
            ZoneConClear(zoneAnCon, zoneBDisIdx_DB, identPunktow, mkrNrIdent_DB
            );
          END (* if makeZoneAnalyse *);
        |
        StopREQ :
          OdtworzEventy( Pomiar );
          redrawM := TRUE;
(*          ok := NewEvent(Pomiar, StopPomiaru, ev);*)
          CollectData := FALSE;
          Zatrzymaj;
        |
        RestartREQ :
          redrawM := TRUE;
(*
          ev.Wysokosc := ABOVESL;
          ok := NewEvent(Pomiar, StartPomiaru, ev);
*)
          CollectData := TRUE;
          Wznow;
        |
        AbortREQ :
          Zatrzymaj;
          EXIT;
        |
        ConsoleEventReq :
(*
          IF currPilotEvBlock = 0  THEN
            WITH ev DO
              brG := devL[currGlownyOdbiornik];
              L_blad := EvalVal[Dif_OS, currGlownyOdbiornik];
            END (* with ev *);
            NewPilotEvent(Pomiar, ev);
            AssignPilotEvBlock(currPilotEvBlock, pointFound);
            currPilotEv := TRUE;
          END;
*)
      END (* case AcqireProcStat *);
      IF makeZoneAnalyse
      THEN
        WITH Events[FALSE] DO
          IF EventIDX # 0 THEN
            WITH events[EventIDX-1]  DO
              IF EventID = Strefa THEN
                NastStrefa(L_Strefa);
              END;
            END;
          END;
        END (* if ZoneAnalyse *);
      END (* if makeZoneAnalyse *);
      currPilotEv := FALSE;
      IF currPilotEvBlock > 0  THEN
        DEC(currPilotEvBlock);
      END;
      IF CollectData
      THEN
        IF NOT LoadData(newSeg) THEN
          CallStopButton;
        END;
        (* dane dla ScannerI *)
        Simulate( AzymutNieElewacja,
                  Pomiar,
                  KPoffset );
        (* dane dla V_Odb *)
        G_Odb.navFlg[goA]   := NAVA_flg IN G_Odb.navOdbFlg;
        G_Odb.navFlg[goB]   := NAVB_flg IN G_Odb.navOdbFlg;
        G_Odb.gsFlg[goA]    := GSA_flg IN G_Odb.navOdbFlg;
        G_Odb.gsFlg[goB]    := GSB_flg IN G_Odb.navOdbFlg;
        G_Odb.iMkrFlg[goA]  := iMkrFlgPosA IN G_Odb.navOdbFlg;
        G_Odb.iMkrFlg[goB]  := iMkrFlgPosB IN G_Odb.navOdbFlg;
        G_Odb.mMkrFlg[goA]  := mMkrFlgPosA IN G_Odb.navOdbFlg;
        G_Odb.mMkrFlg[goB]  := mMkrFlgPosB IN G_Odb.navOdbFlg;
        G_Odb.oMkrFlg[goA]  := oMkrFlgPosA IN G_Odb.navOdbFlg;
        G_Odb.oMkrFlg[goB]  := oMkrFlgPosB IN G_Odb.navOdbFlg;
        G_Odb.audio_L[goA]  := NAVA_Aud_flg IN G_Odb.navOdbFlg;
        G_Odb.audio_L[goB]  := NAVB_Aud_flg IN G_Odb.navOdbFlg;
        G_Odb.audio_V[goA]  := Com_Aud_flg IN G_Odb.navOdbFlg;
        G_Odb.audio_V[goB]  := Com_Aud_flg IN G_Odb.navOdbFlg;
        G_Odb.PoprawDane;
        (**)
        currUpdMarks;
        newSeg := FALSE;
(*
        IF GetPilotEvent(pilotEvId)
        THEN
          IF currPilotEvBlock = 0  THEN
            WITH ev DO
              brG := devL[currGlownyOdbiornik];
              L_blad := EvalVal[Dif_OS, currGlownyOdbiornik];
            END (* with ev *);
            NewPilotEvent(Pomiar, ev);
            currPilotEv := TRUE;
            redrawM := TRUE;
          END;
        END (* if GetPilotEvent *);
        IF TheodolitRead.GetEvent()
        THEN
          WITH ev DO
            brG := devL[currGlownyOdbiornik];
            L_blad := EvalVal[Dif_OS, currGlownyOdbiornik];
          END (* with ev *);
          NewTeoEvent(Pomiar, ev);
        END (* if TheodolitRead.GetEvent *);
*)
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
  CONST
    covSecMax = 0;
    covSecMin = 0;

  BEGIN
    redraw := FALSE;
    redrawM := FALSE;
    ImportantDiv := NilValC;
    WITH anRes DO
      G_Odb.IniData(secWith, offset, covSecMax, covSecMin,
                    Lotnisko.ProgPasa);
    END (* with anRes *);
    InitSlupek;
    ResetDataCollect(Pomiar, WykMainProc, Wyk1Proc, Wyk2Proc, Wyk3Proc);
    LoadEvents(Pomiar);
    currGlownyOdbiornik := anRes.glownyOdbiornik;
    polvfaza := 0;
    TrwaPomiarPolaryzacji := FALSE;
    filesNotEmpty := FALSE;
    OpenFiles;
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

  VAR
    filesNotEmpty : BOOLEAN;

  PROCEDURE Start;
    (* zacznij rejestracje od poczatku *)

  BEGIN
    ResetDataCollect(Pomiar, WykMainProc, Wyk1Proc, Wyk2Proc, Wyk3Proc);
    LoadEvents(Pomiar);
    IF filesNotEmpty
    THEN
      CloseFiles;
      OpenFiles;
    END (* if filesNotEmpty *);
    filesNotEmpty := TRUE;
    CommReq(StartREQ);
  END Start;

  PROCEDURE Abort;
    (* zakoncz proces rejestracji *)

  BEGIN
    OdtworzEventy( Pomiar );
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
END G_DAcquizition.
