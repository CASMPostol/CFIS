(*.F- *)
(**********************************************************************
|  Title   : Rejestracja danych dla VOR
|  Author  : M.Postol
|  System  : LOGITECH MODULA-2/86
|  History :
|    01-02-97: M.Postol
|      V_Odb.Start - jest wywolywany po starcie rejestracji a niw Wznow -
|      zmiany w V_odb
|    Rel.3.0 MPostol
|      blad w przy wznawianiu pomiaru - nie byl ustawiany newSeg w 
|      procedurze Acquire
|
|  Copyright (C), CAS LODZ POLAND.
|  TEL: 42' 686 25 47
|  mailto: techsupp@cas.com.pl
|  http: www.cas.com.pl
|
**********************************************************************)
(*.F+ *)

IMPLEMENTATION MODULE V_DAcquizition;

  IMPORT
    MANAGER, DataCollect, Czas, V_Odb, CommonData;

  FROM TheodolitRead IMPORT
    InitTeoEventId, TeoEvSignType, GetTeoEvent;

  FROM DataCollect IMPORT
    (* PROCEDURE *) UpdTab800, ResetDataCollect;

  FROM EventsMng IMPORT
    (* TYPE *) EventKind, NewEvent, NewTeoEvent, EventType,
    (* PROCEDURE *) EventsMngInit, NewConsoleEvent, NewPilotEvent;

  FROM CommonTypes IMPORT
    (* CONST *) NilValC,
    (* TYPE *) GlownyOdbiornikT;

  FROM SpecConv IMPORT
    GorszeBoMniejsze300, GorszeBoMniejsze, GorszeBoDalszeOdZera;

  FROM MANAGER IMPORT
    STARTPROCESS;

  FROM ScannerI IMPORT
    (* TYPE *) DtaSignType,
    (* PROCEDURE *) NewDataAvailable, GetPilotEvent, InitPilotEventId,
    (* VAR *) RefDis, RefAlfa, ABOVESL;

  FROM V_Odb IMPORT
    agc, obr, var, sub, DEVVAL;

  FROM V_Files IMPORT
    CreateFiles, SaveData, CloseFiles;

  FROM V_Slupek IMPORT
    InitSlupek, DoneSlupek;

  FROM Timer IMPORT
    Wait;

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
    teoEvId               : TeoEvSignType;
    currUpdMarks          : PROC;
    TrwaPomiarPolaryzacji : BOOLEAN;
    polvfaza              : CARDINAL;
    pom2sek               : CARDINAL;

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
      redrawM := TRUE;
      dummy := NewEvent(Pomiar, StopPomiaru, ev);
    ELSIF (phase >= 11) AND (phase <= 13)
    THEN   (* lewo , zero, prawo*)
      pom2sek := 10;
      WHILE pom2sek # 0 DO
        Wait(500);
      END (* while pom2sek *);
    ELSE
      TrwaPomiarPolaryzacji := FALSE;
      redrawM := TRUE;
      ev.Wysokosc := ABOVESL;
      dummy := NewEvent(FALSE, StartPomiaru, ev);
    END (* if phase *);
  END PolV;

  MODULE Monitor [ 0 ];

    IMPORT
      AcqireProcStatType;

    FROM MANAGER IMPORT
      STARTPROCESS, Condition, InitC, WAITC, Notify;

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
    ev             : EventType;
    ok             : CARDINAL;
    newSeg         : BOOLEAN;
    CollectData    : BOOLEAN;
    AcqireProcStat : AcqireProcStatType;

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

    PROCEDURE InitEvent
              ( VAR ev : EventType );
    VAR
      go : GlownyOdbiornikT;

    BEGIN
      WITH ev DO
        FOR go := MIN(GlownyOdbiornikT) TO MAX(GlownyOdbiornikT) DO
          WITH T_Par[go] DO
            brG := obr[go];
            blad := DEVVAL[go];
          END (* with T_Par *);
        END (* for go *);
      END (* with ev *);
    END InitEvent;

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
          Czas.GetTimeAndDate(ev.DatICas);
          redrawM := TRUE;
          ok := NewEvent(Pomiar, PoczatekPomiaru, ev);
          ev.Wysokosc := ABOVESL;
          ok := NewEvent(Pomiar, StartPomiaru, ev);
          newSeg := TRUE;
          V_Odb.Start;
          CollectData := TRUE;
        |
        StopREQ :
          redrawM := TRUE;
          ok := NewEvent(Pomiar, StopPomiaru, ev);
          CollectData := FALSE;
          V_Odb.Zatrzymaj;
        |
        RestartREQ :
          ev.Wysokosc := ABOVESL;
          redrawM := TRUE;
          ok := NewEvent(Pomiar, StartPomiaru, ev);
          CollectData := TRUE;
          V_Odb.Wznow;
          newSeg := TRUE; (* Rel. 3.0. tego nie bylo ?! *)
        |
        AbortREQ :
          V_Odb.Zatrzymaj;
          EXIT;
        |
        ConsoleEventReq :
          IF CollectData
          THEN
            InitEvent(ev);
            NewConsoleEvent(Pomiar, ev);
          END (* if CollectData *);
      END (* case AcqireProcStat *);
      IF CollectData
      THEN
        currUpdMarks;
        SaveData(newSeg);
        newSeg := FALSE;
        IF GetPilotEvent(pilotEvId)
        THEN
          InitEvent(ev);
          NewPilotEvent(Pomiar, ev);
        END (* if GetPilotEvent *);
        IF GetTeoEvent(teoEvId)
        THEN
          NewTeoEvent(Pomiar, ev);
        END (* if GetEvent *);
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
    UpdTab800(Pomiar, DEVVAL, var, agc, sub, redraw, redrawM, RefAlfa,
              ImportantDiv, TRUE);
  END UpdateMarksOrbit;

  PROCEDURE UpdateMarksRadial;

  BEGIN
    UpdTab800(Pomiar, DEVVAL, var, agc, sub, redraw, redrawM, RefDis,
              ImportantDiv, FALSE);
  END UpdateMarksRadial;

  PROCEDURE IniData;

  BEGIN
    redraw := FALSE;
    redrawM := FALSE;
    ImportantDiv := NilValC;
    V_Odb.IniData(CommonData.OdnDlaPomBledu);
    ResetDataCollect(Pomiar, GorszeBoDalszeOdZera, GorszeBoMniejsze300,
                     GorszeBoMniejsze, GorszeBoMniejsze300);
    InitSlupek;
    EventsMngInit(Pomiar);
    InitPilotEventId(pilotEvId);
    InitTeoEventId(teoEvId);
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

  VAR
    filesNotEmpty : BOOLEAN;

  PROCEDURE Start;
    (* zacznij rejestracje od poczatku *)

  BEGIN
    ResetDataCollect(Pomiar, GorszeBoDalszeOdZera, GorszeBoMniejsze300,
                     GorszeBoMniejsze, GorszeBoMniejsze300);
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
END V_DAcquizition.
