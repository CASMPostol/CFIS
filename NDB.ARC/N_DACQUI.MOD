(*.F- *)
(**********************************************************************
|  Title   : Rejestracja danych dla NDB
|  Author  : M.Morawski
|  System  : LOGITECH MODULA-2/86
|  History :
|
|  Copyright (C), CAS LODZ POLAND.
|  TEL: 42' 862 547, 42' 87 80 44 FAX/TEL: 42' 84 48 40
|
**********************************************************************)
(*.F+ *)

IMPLEMENTATION MODULE N_DAcquizition;

  IMPORT
    MANAGER, DataCollect, N_Odb, N_Oblot;

  FROM CommonData IMPORT
    SciezkaOpisuPomiaru, OdnDlaPomOdl;

  FROM DataCollect IMPORT
    (* PROCEDURE *) UpdTab800, ResetDataCollect;

  FROM EventsMng IMPORT
    (* TYPE *) EventKind, NewEvent, NewTeoEvent, EventType,
    (* PROCEDURE *) NewConsoleEvent, NewPilotEvent;

  FROM CommonTypes IMPORT
    (* CONST *) NilValC, NDBA_Aud_Flg, NDBB_Aud_Flg,
    (* TYPE *)  GlownyOdbiornikT, signTab, SigNilVal;

  FROM N_CommonTypes IMPORT
    (* TYPE *) ProceduraT;

  FROM MANAGER IMPORT
    STARTPROCESS;

  FROM ScannerI IMPORT
    (* TYPE *) DtaSignType,
    (* PROCEDURE *) NewDataAvailable, GetPilotEvent, InitPilotEventId,
    (* VAR *) RefDis, RefAlfa, ABOVESL;

  FROM N_Odb IMPORT
    (* VAR *) audio_N, agc, DEVVAL,
    (* PROCEDURE *) Zatrzymaj, Wznow;

  FROM N_Files IMPORT
    OpenFiles, LoadData, CloseFiles;

  FROM Timer IMPORT
    Wait, TInOneSecond;

  FROM N_results IMPORT
    anRes;

  FROM N_Slupek IMPORT
    InitSlupek, DoneSlupek;

  FROM N_DataBase IMPORT
    NadajnikNDB;

  FROM RTSMain IMPORT
    Terminate, Status;

  FROM Pomiar IMPORT
    CallStopButton;

  FROM SimScanner IMPORT
    Simulate, LoadEvents, OdtworzEventy;

  FROM SpecConv IMPORT
    GorszeBoMniejsze, GorszeBoWieksze;



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
    signTabNil            : signTab;

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


  BEGIN (* Acquire *)
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
          N_Odb.Start;
          CollectData := TRUE;
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
        Simulate( TRUE, Pomiar, 0 );
        (* dane dla V_Odb *)
        N_Odb.audio_N[goA]   := NDBA_Aud_Flg IN N_Odb.flg;
        N_Odb.audio_N[goB]   := NDBB_Aud_Flg IN N_Odb.flg;
        N_Odb.PoprawDane( goA );
        N_Odb.PoprawDane( goB );
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
    UpdTab800(Pomiar, agc, DEVVAL, signTabNil, signTabNil, redraw, redrawM,
              RefAlfa, ImportantDiv, TRUE);
  END UpdateMarksOrbit;

  PROCEDURE UpdateMarksRadial;

  BEGIN
    UpdTab800(Pomiar, agc, DEVVAL, signTabNil, signTabNil, redraw, redrawM,
              RefDis, ImportantDiv, FALSE);
  END UpdateMarksRadial;


  PROCEDURE IniData;

  BEGIN
    redraw := FALSE;
    redrawM := FALSE;
    ImportantDiv := NilValC;
    N_Odb.IniData();
    N_Odb.Start;
    InitSlupek;
    LoadEvents(Pomiar);
    ResetDataCollect(Pomiar, GorszeBoMniejsze, GorszeBoWieksze, GorszeBoWieksze
                     , GorszeBoWieksze);
    currGlownyOdbiornik := anRes.glownyOdbiornik;
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
    ResetDataCollect(Pomiar, GorszeBoMniejsze, GorszeBoWieksze, GorszeBoWieksze
                     , GorszeBoWieksze);
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
  signTabNil[goA] := SigNilVal;
  signTabNil[goB] := SigNilVal;
END N_DAcquizition.
