(*.F- *)
(**********************************************************************
|  Title   : Rejestracja danych dla NDB
|  Author  : M.Morawski
|  System  : LOGITECH MODULA-2/86
|  History :
|    Rel 3.0. MPostol
|      wywalilem z LoadData czytanie newseg
|    Rel 3.14: MPostol
|      - dostosowanie do nowej definicji N_Odb, gdzie na orbicie
|        nie jest liczony blad namiaru
|      - wywalilem cala mase niepotrzebnych rzczy
|
|  Copyright (C), CAS LODZ POLAND.
|  TEL: 42' 862 547, 42' 87 80 44 FAX/TEL: 42' 84 48 40
|
**********************************************************************)
(*.F+ *)

IMPLEMENTATION MODULE N_DAcquizition;

  IMPORT
    MANAGER, DataCollect, N_Odb;

  FROM DataCollect IMPORT
    (* PROCEDURE *) UpdTab800, ResetDataCollect;

  FROM EventsMng IMPORT
    (* TYPE *) EventKind, NewEvent, EventType;

  FROM CommonTypes IMPORT
    (* CONST *) NilValC, NDBA_Aud_Flg, NDBB_Aud_Flg,
    (* TYPE *)  GlownyOdbiornikT, signTab, SigNilVal;

  FROM MANAGER IMPORT
    STARTPROCESS;

  FROM ScannerI IMPORT
    (* VAR *) RefDis, RefAlfa;

  FROM N_Odb IMPORT
    (* VAR *) agc, DEVVAL,
    (* PROCEDURE *) Zatrzymaj, Wznow;

  FROM N_Files IMPORT
    OpenFiles, LoadData, CloseFiles;

  FROM Timer IMPORT
    Wait, TInOneSecond;

  FROM N_results IMPORT
    anRes;

  FROM N_Slupek IMPORT
    InitSlupek, DoneSlupek;

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
    CollectData      : BOOLEAN;
    currPilotEv      : BOOLEAN;
    currPilotEvBlock : CARDINAL;

  BEGIN (* Acquire *)
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
        IF NOT LoadData() THEN
          CallStopButton;
        END;
        (* dane dla ScannerI *)
        Simulate( TRUE, Pomiar, 0 );
        (* dane dla N_Odb *)
        N_Odb.audio_N[goA]   := NDBA_Aud_Flg IN N_Odb.flg;
        N_Odb.audio_N[goB]   := NDBB_Aud_Flg IN N_Odb.flg;
        N_Odb.CountDevErr(N_Odb.dir[goA], N_Odb.berN, RefAlfa, N_Odb.DEVVAL);
        (* dir[goA] = dir[goB] - wprowadzono dwa dir dla kompatybilnosci 
           przy zachowywaniu plikow *)
        N_Odb.PoprawDane( goA );
        N_Odb.PoprawDane( goB );
        (**)
        currUpdMarks;
(*
        IF GetPilotEvent(pilotEvId)
        THEN
          WITH ev DO
            N_SilaSyg := agc[currGlownyOdbiornik];
            C_kat := RefAlfa;
          END (* with ev *);
          NewPilotEvent(Pomiar, ev);
          redrawM := TRUE;
        END (* if GetPilotEvent *);
*)
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
    UpdTab800(Pomiar, agc, DEVVAL, signTabNil, signTabNil, redraw, redrawM,
              RefAlfa, ImportantDiv, TRUE);
  END UpdateMarksOrbit;

  PROCEDURE UpdateMarksRadial;

  BEGIN
    UpdTab800(Pomiar, agc, DEVVAL, signTabNil, signTabNil, redraw, redrawM,
              RefDis, ImportantDiv, FALSE);
  END UpdateMarksRadial;

  VAR
    filesNotEmpty : BOOLEAN;

  PROCEDURE IniData;

  BEGIN
    redraw := FALSE;
    redrawM := FALSE;
    ImportantDiv := NilValC;
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
    N_Odb.IniData( FALSE );
    IniData;
    currUpdMarks := UpdateMarksOrbit;
  END IniDataOrbit;

  PROCEDURE IniDataRadial;

  BEGIN
    N_Odb.IniData( TRUE );
    IniData;
    currUpdMarks := UpdateMarksRadial;
  END IniDataRadial;


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
