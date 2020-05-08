(*.F- *)
(**********************************************************************
|  Title   : Rejestracja znacznikow
|  Author  : M.Postol
|  System  : LOGITECH MODULA-2/86
|  History :
|    12-18-96 06:23pm: MM
|       Zapisuje ratunkowe eventy
|    12-10-97: M.Morawski
|      zmiana def LoadResult
|
|  Copyright (C), CAS LODZ POLAND.
|  TEL: 42' 862 547, 42' 87 80 44 FAX/TEL: 42' 84 48 40
|
**********************************************************************)
(*.F+ *)

IMPLEMENTATION MODULE EventsMng;

  FROM Files IMPORT
    SaveAResult, LoadAResult;

  FROM SYSTEM IMPORT
    WORD;

  FROM CommonTypes IMPORT
    NilValC, zoneBIdx_T;

  FROM SYSTEM IMPORT
    ADR, SIZE;

  FROM DataCollect IMPORT
    SampleNr;

  FROM Messages IMPORT
    Message, NewMessage, Display;

  FROM RTSMain IMPORT
    InstallTermProc;

  FROM Strings IMPORT
    Length;

  IMPORT
    BlockOps, Files, FIO, CommonData, PI_PA;

  VAR
    pilEnr  : ARRAY BOOLEAN OF CARDINAL;
    conEnr  : ARRAY BOOLEAN OF CARDINAL;
    teoEnr  : ARRAY BOOLEAN OF CARDINAL;

  PROCEDURE NewEvent
            (    pomiar   : BOOLEAN;
                 evID     : EventKind;
                 eve      : EventType ) : CARDINAL;
  VAR
    mess        : Message;
  BEGIN
    WITH Events[pomiar] DO
      IF EventIDX >= MaxEvents
      THEN
        NewMessage(mess, 'Brak pamieci na zdarzenia', {15, 14, 9, 8, 7});
        Display(mess);
        RETURN NilValC;
      ELSE
        events[EventIDX] := eve;
        WITH events[EventIDX] DO
          atSample := SampleNr(pomiar);
          EventID := evID;
        END (* with events *);
        INC(EventIDX);
        RETURN EventIDX;
      END (* if EventIDX *);
    END (* with Events *);
  END NewEvent;

  PROCEDURE NewTeoEvent
            (    Pomiar   : BOOLEAN;
                 eve      : EventType );
  VAR
    n  : CARDINAL;

  BEGIN
    eve.OrdNr := teoEnr[Pomiar];
    INC(teoEnr[Pomiar]);
    n := NewEvent(Pomiar, ZnacznikT, eve);
  END NewTeoEvent;

  PROCEDURE NewPilotEvent
            (    Pomiar   : BOOLEAN;
                 eve      : EventType );
  VAR
    n  : CARDINAL;

  BEGIN
    eve.OrdNr := pilEnr[Pomiar];
    n := NewEvent(Pomiar, ZnacznikP, eve);
    INC(pilEnr[Pomiar]);
  END NewPilotEvent;

  PROCEDURE NewConsoleEvent
            (    Pomiar   : BOOLEAN;
                 eve      : EventType );
  VAR
    n  : CARDINAL;

  BEGIN
    eve.OrdNr := conEnr[Pomiar];
    INC(conEnr[Pomiar]);
    n := NewEvent(Pomiar, ZnacznikK, eve);
  END NewConsoleEvent;

  PROCEDURE FindNextEvent
            (    pomiar    : BOOLEAN;
                 ID        : EventKind;
                 startfrom : CARDINAL  ) : CARDINAL;

  BEGIN
    WITH Events[pomiar] DO
      WHILE startfrom < EventIDX DO
        IF (events[startfrom].EventID = ID)
        THEN
          RETURN startfrom
        END (* if *);
        INC(startfrom);
      END (* while startfrom *);
      RETURN NilValC
    END (* with Events *);
  END FindNextEvent;

  PROCEDURE GetUpdNextEvent
            (     Pomiar   : BOOLEAN;
                  sample   : CARDINAL;
              VAR evidx    : CARDINAL;
                  position : WORD     ) : EventKind;

  BEGIN
    WITH Events[Pomiar] DO
      IF evidx >= EventIDX
      THEN
        RETURN BrakZnacznika;
      END (* if evidx *);
      WITH events[evidx] DO
        IF sample = atSample
        THEN
          XRef := position;
          INC(evidx);
          RETURN EventID
        ELSE
          RETURN BrakZnacznika
        END (* if sample *);
      END (* with Events *);
    END (* with Events *);
  END GetUpdNextEvent;

  PROCEDURE GetEventInfo (* do wywalenia po modyfikacj V_Count *)
            (     pomiar : BOOLEAN;
                  EvIDX  : CARDINAL;
              VAR EvPOS  : CARDINAL    ) : EventKind;

  BEGIN
    WITH Events[pomiar] DO
      IF EvIDX < EventIDX
      THEN
        WITH events[EvIDX]  DO
          EvPOS := atSample;
          RETURN EventID;
        END;
      ELSE
        EvPOS := NilValC;
        RETURN MAX(EventKind);
      END (* if EvIDX *);
    END (* with Events *);
  END GetEventInfo;

  PROCEDURE SaveDistEvents
            (    pomiar : BOOLEAN );

  BEGIN
    SaveAResult(Events[pomiar], Files.Events, pomiar);
  END SaveDistEvents;

  PROCEDURE InitEvents
            ( VAR evnts : EventsDsc );

  BEGIN
    BlockOps.BlockClear(ADR(evnts), SIZE(evnts));
    evnts.EventIDX := 0;
  END InitEvents;

  PROCEDURE LoadDistEvents
            ( VAR eve    : EventsDsc;
                  pomiar : BOOLEAN   ): BOOLEAN;

  BEGIN
    IF NOT LoadAResult(eve, Files.Events, pomiar, NilValC, NilValC)
    THEN
      InitEvents(eve);
      RETURN FALSE;
    END (* if *);
    RETURN TRUE;
  END LoadDistEvents;

  PROCEDURE EventsMngInit
            (    Pomiar   : BOOLEAN );
  BEGIN
    pilEnr[Pomiar] := 0;
    conEnr[Pomiar] := 0;
    teoEnr[Pomiar] := 0;
    InitEvents(Events[Pomiar]);
  END EventsMngInit;

  PROCEDURE UpdateStrefa
            ( currZoneBIdx : zoneBIdx_T);
  VAR
    evIdx  : EventsIdxTyp;
    tmpEl  : EventType;
    sorted : BOOLEAN;
  BEGIN
    WITH Events[FALSE] DO
      FOR evIdx := 0 TO EventIDX - 1 DO
        WITH events[evIdx] DO
          IF EventID= Strefa THEN
            atSample := currZoneBIdx[L_Strefa];
          END;
        END;
      END;
      IF EventIDX = 1 THEN
        RETURN
      END;
      REPEAT
        sorted := TRUE;
        FOR evIdx := 0 TO EventIDX - 2 DO
          WITH events[evIdx] DO
          IF events[evIdx].atSample > events[evIdx+1].atSample
          THEN
            tmpEl := events[evIdx];
            events[evIdx] := events[evIdx+1];
            events[evIdx+1] := tmpEl;
            sorted := FALSE;
          END;
        END;
      END;
      UNTIL  sorted;
    END;
  END UpdateStrefa;

  PROCEDURE Terminator(  );
    VAR
      f : FIO.File;
      b : BOOLEAN;
    BEGIN
      f := FIO.Create('rat_evco.dat');
      b := FIO.Write( f, ADR( CommonData.NazwaPlikuOpisu ), Length(CommonData.NazwaPlikuOpisu));
      FIO.Close( f );
      f := FIO.Create('rat_event.dat');
      FOR b := FALSE TO TRUE DO
        WITH Events[b] DO
          IF EventIDX > 0 THEN
            IF events[EventIDX-1].EventID # StopPomiaru THEN
              events[EventIDX].EventID := StopPomiaru;
              INC(EventIDX);
            END;
          END;
        END;
      END;
      b := FIO.Write( f, ADR( Events ), SIZE( Events ));
      FIO.Close( f );
    END Terminator;

BEGIN
  Events[FALSE].EventIDX := 0;
  Events[TRUE].EventIDX := 0;
  IF PI_PA.PomiarANieArchiwum THEN
    InstallTermProc( Terminator );
  END;
END EventsMng.
