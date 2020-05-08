(*.F- *)
(**********************************************************************
|  Title   : Rejestracja danych dla DME
|  Author  : M.Postol
|  System  : LOGITECH MODULA-2/86
|  History :
|    04-10-96: M.Postol
|      zmieniono obsluge znacznika z teo
|    09-12-96: M.Postol
|      zle wyznacza odcinki bo nie zapamietuje konca
|    01-02-97: M.Postol
|      V_Odb.Start - jest wywolywany po starcie rejestracji a niw Wznow -
|      zmiany w V_odb
|    17-07-97: M.Postol
|      znacznik zapamietuje Agc zawsze odbiornik A
|    Rel. 3.14. MPostol
|      Wywalilem niepotrzebne obiekty i importy
|
|  Copyright (C), CAS LODZ POLAND.
|  TEL: 42' 862 547, 42' 87 80 44 FAX/TEL: 42' 84 48 40
|
**********************************************************************)
(*.F+ *)

IMPLEMENTATION MODULE D_DAcquizition;

  IMPORT
    MANAGER, DataCollect, Czas, D_Odb;

  FROM TheodolitRead  IMPORT
    InitTeoEventId, TeoEvSignType, GetTeoEvent;
    
  FROM DataCollect IMPORT
    (* PROCEDURE *) UpdTab800, ResetDataCollect;

  FROM EventsMng IMPORT
    (* TYPE *) EventKind, NewEvent, NewTeoEvent, EventType,
    (* PROCEDURE *) EventsMngInit, NewConsoleEvent, NewPilotEvent;

  FROM CommonTypes IMPORT
    (* CONST *) NilValC;

  FROM SpecConv IMPORT
    GorszeBoMniejszeM60, GorszeBoMniejsze500,
    GorszeBoMniejsze1500, GorszeBoWieksze;

  FROM MANAGER IMPORT
    STARTPROCESS;

  FROM ScannerI IMPORT
    (* TYPE *) DtaSignType,
    (* PROCEDURE *) NewDataAvailable, GetPilotEvent, InitPilotEventId,
    (* VAR *) RefDis, RefAlfa, ABOVESL;

  FROM D_Odb IMPORT
    Agc, distErrF, Reply, Squitter;

  FROM D_Files IMPORT
    CreateFiles, SaveData, CloseFiles;

  FROM D_Slupek  IMPORT
    InitSlupek, DoneSlupek;

  FROM CommonData IMPORT
    GlownyOdbiornik;

  CONST
    Pomiar = TRUE;  (* Zestaw Danych *)

  TYPE
    AcqireProcStatType =
      ( NoComm,
        StartREQ,
        StopREQ,
        RestartREQ,
        AbortREQ,
        ConsoleEventReq );

  VAR
    ImportantDiv : CARDINAL;
    redraw       : BOOLEAN;
    redrawM      : BOOLEAN;
    pilotEvId    : DtaSignType;
    teoEvId      : TeoEvSignType;
    currUpdMarks : PROC;
    filesNotEmpty: BOOLEAN;

  MODULE Monitor [ 0 ];

    IMPORT
      AcqireProcStatType;

    FROM MANAGER IMPORT
      Condition, InitC, WAITC, Notify;

    EXPORT
      CommReq, Stop, ConsoleEv, Restart, GetEvent;

    VAR
      notify : Condition;
      lastComm               : AcqireProcStatType;

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
    ev             : EventType;
    ok             : CARDINAL;
    newSeg         : BOOLEAN;
    CollectData    : BOOLEAN;

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
          Czas.GetTimeAndDate( ev.DatICas );
          redrawM := TRUE;
          ok := NewEvent(Pomiar, PoczatekPomiaru, ev);
          ev.Wysokosc := ABOVESL;
          ok := NewEvent(Pomiar, StartPomiaru, ev);
          newSeg := TRUE;
          D_Odb.Start;
          CollectData := TRUE;
        |
        StopREQ :
          redrawM := TRUE;
          ok := NewEvent(Pomiar, StopPomiaru, ev);
          CollectData := FALSE;
          D_Odb.Zatrzymaj;
          currUpdMarks;
          SaveData(newSeg);
          newSeg := FALSE;
        |
        RestartREQ :
          ev.Wysokosc := ABOVESL;
          redrawM := TRUE;
          ok := NewEvent(Pomiar, StartPomiaru, ev);
          CollectData := TRUE;
          D_Odb.Wznow;
        |
        AbortREQ :
          D_Odb.Zatrzymaj;
          EXIT;
        |
        ConsoleEventReq :
          IF CollectData
          THEN
            ev.D_SilaSyg := Agc[GlownyOdbiornik];
            NewConsoleEvent(Pomiar, ev);
          END;
      END (* case AcqireProcStat *);
      IF CollectData
      THEN
        currUpdMarks;
        SaveData(newSeg);
        newSeg := FALSE;
        IF GetPilotEvent(pilotEvId)
        THEN
          NewPilotEvent(Pomiar, ev);
        END (* if GetPilotEvent *);
        IF GetTeoEvent(teoEvId)
        THEN
          NewTeoEvent(Pomiar, ev);
        END (* if TheodolitRead.GetEvent *);
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
    UpdTab800(Pomiar, Agc, distErrF, Reply, Squitter, redraw, redrawM, 
              RefAlfa, ImportantDiv, TRUE);
  END UpdateMarksOrbit;

  PROCEDURE UpdateMarksRadial;

  BEGIN
    UpdTab800(Pomiar, Agc, distErrF, Reply, Squitter, redraw, redrawM, 
              RefDis, ImportantDiv, FALSE);
  END UpdateMarksRadial;

  PROCEDURE IniData;

  BEGIN
    redraw := FALSE;
    redrawM := FALSE;
    ImportantDiv := NilValC;
    D_Odb.IniData;
    InitSlupek;
    ResetDataCollect(Pomiar, GorszeBoMniejszeM60, GorszeBoWieksze,
                     GorszeBoMniejsze500, GorszeBoMniejsze1500);
    EventsMngInit(Pomiar);
    InitPilotEventId(pilotEvId);
    InitTeoEventId(teoEvId);
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
    ResetDataCollect(Pomiar, GorszeBoMniejszeM60, GorszeBoWieksze,
                     GorszeBoMniejsze500, GorszeBoMniejsze1500);
    EventsMngInit(Pomiar);
    IF filesNotEmpty  THEN
      CloseFiles;
      CreateFiles;
    END;
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
END D_DAcquizition.
