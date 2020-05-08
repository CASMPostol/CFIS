(*.F- *)
(**********************************************************************
|  Title   : Rejestracja danych dla VHF
|  Author  : M.Postol
|  System  : LOGITECH MODULA-2/86
|  History :
|    11-12-96: created
|    28-01-97: M.Postol
|      podstawienie pod nowe pole C_kat
|
|  Copyright (C), CAS LODZ POLAND.
|  TEL: 42' 862 547, 42' 87 80 44 FAX/TEL: 42' 84 48 40
|
**********************************************************************)
(*.F+ *)

IMPLEMENTATION MODULE H_DAcquizition;

  IMPORT
    MANAGER, DataCollect, Czas, H_Odb;

  FROM DataCollect IMPORT
    (* PROCEDURE *) UpdTab800, ResetDataCollect;

  FROM EventsMng IMPORT
    (* TYPE *) EventKind, NewEvent, EventType,
    (* PROCEDURE *) EventsMngInit, NewConsoleEvent, NewPilotEvent;

  FROM CommonTypes IMPORT
    (* CONST *) NilValC, SigNilVal,
    (* TYPE *) GlownyOdbiornikT, signTab;

  FROM MANAGER IMPORT
    STARTPROCESS;

  FROM ScannerI IMPORT
    (* TYPE *) DtaSignType,
    (* PROCEDURE *) NewDataAvailable, GetPilotEvent, InitPilotEventId,
    (* VAR *) RefDis, RefAlfa, ABOVESL;

  FROM H_Odb IMPORT
    (* VAR *) agc,
    (* PROCEDURE *) Zatrzymaj, Wznow;

  FROM H_Files IMPORT
    CreateFiles, SaveData, CloseFiles;

  FROM H_Slupek IMPORT
    InitSlupek, DoneSlupek;

  FROM SpecConv IMPORT
    GorszeBoMniejsze;

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
    ImportantDiv  : CARDINAL;
    redraw        : BOOLEAN;
    redrawM       : BOOLEAN;
    pilotEvId     : DtaSignType;
    currUpdMarks  : PROC;
    signTabNil    : signTab;
    agcExt        : signTab;
    filesNotEmpty : BOOLEAN;

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
    ev          : EventType;
    ok          : CARDINAL;
    newSeg      : BOOLEAN;
    CollectData : BOOLEAN;

  BEGIN (* Acquire *)
    newSeg := FALSE;
    redraw := TRUE;
    CollectData := FALSE;
    LOOP
      NewDataAvailable;
      CASE GetEvent() OF
        NoComm :
          ;
        |
        StartREQ :
          Czas.Godzina(ev.h, ev.m, ev.s);
          Czas.Data(ev.Y, ev.M, ev.D);
          ok := NewEvent(Pomiar, PoczatekPomiaru, ev);
          ev.Wysokosc := ABOVESL;
          ok := NewEvent(Pomiar, StartPomiaru, ev);
          redrawM := TRUE;
          newSeg := TRUE;
          CollectData := TRUE;
        |
        StopREQ :
          redrawM := TRUE;
          CollectData := FALSE;
          ok := NewEvent(Pomiar, StopPomiaru, ev);
          currUpdMarks;
          SaveData(newSeg);
          newSeg := FALSE;
          Zatrzymaj;
        |
        RestartREQ :
          redrawM := TRUE;
          ev.Wysokosc := ABOVESL;
          ok := NewEvent(Pomiar, StartPomiaru, ev);
          CollectData := TRUE;
          Wznow;
        |
        AbortREQ :
          Zatrzymaj;
          EXIT;
        |
        ConsoleEventReq :
          WITH ev DO
            C_SilaSyg := agc;
            C_kat := RefAlfa;
          END (* with ev *);
          NewConsoleEvent(Pomiar, ev);
      END (* case AcqireProcStat *);
      IF CollectData
      THEN
        currUpdMarks;
        SaveData(newSeg);
        newSeg := FALSE;
        IF GetPilotEvent(pilotEvId)
        THEN
          WITH ev DO
            C_SilaSyg := agc;
            C_kat := RefAlfa;
          END (* with ev *);
          NewPilotEvent(Pomiar, ev);
          redrawM := TRUE;
        END (* if GetPilotEvent *);
        redrawM := TRUE;
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
    agcExt[goA] := agc;
    UpdTab800(Pomiar, agcExt, signTabNil, signTabNil, signTabNil, redraw,
              redrawM, RefAlfa, ImportantDiv, TRUE);
  END UpdateMarksOrbit;

  PROCEDURE UpdateMarksRadial;

  BEGIN
    agcExt[goA] := agc;
    UpdTab800(Pomiar, agcExt, signTabNil, signTabNil, signTabNil, redraw,
              redrawM, RefDis, ImportantDiv, FALSE);
  END UpdateMarksRadial;

  PROCEDURE IniData;

  BEGIN
    redraw := FALSE;
    redrawM := FALSE;
    ImportantDiv := NilValC;
    H_Odb.IniData();
    H_Odb.Start;
    InitSlupek;
    ResetDataCollect(Pomiar, GorszeBoMniejsze, GorszeBoMniejsze,
                     GorszeBoMniejsze, GorszeBoMniejsze);
    EventsMngInit(Pomiar);
    InitPilotEventId(pilotEvId);
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
    ResetDataCollect(Pomiar, GorszeBoMniejsze, GorszeBoMniejsze,
                     GorszeBoMniejsze, GorszeBoMniejsze);
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

  PROCEDURE PolV
            (    phase : CARDINAL );
  END PolV;

BEGIN
  filesNotEmpty := FALSE;
  ImportantDiv := NilValC;
  redraw := FALSE;
  redrawM := FALSE;
  signTabNil[goA] := SigNilVal;
  signTabNil[goB] := SigNilVal;
  agcExt[goA] := SigNilVal;
  agcExt[goB] := SigNilVal;
END H_DAcquizition.
