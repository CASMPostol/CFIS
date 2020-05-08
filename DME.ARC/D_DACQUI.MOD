(*.F- *)
(**********************************************************************
|  Title   : Rejestracja danych dla DME
|  Author  : M.Postol
|  System  : LOGITECH MODULA-2/86
|  History :
|    07-05-97: M.Postol
|      DME wymaga przesuniecia kata dla GPS w LOCarch
|      brak wywolania D_Odb.IniData
|      brak wywolania D_Odb.PoprawDane;
|    Rel. 3.14: MPostol
|      blad odleglosci nie byl wyswietlany
|
|  Copyright (C), CAS LODZ POLAND.
|  TEL: 42' 862 547, 42' 87 80 44 FAX/TEL: 42' 84 48 40
|
**********************************************************************)
(*.F+ *)

IMPLEMENTATION MODULE D_DAcquizition;

  IMPORT
    MANAGER, DataCollect, D_Odb;

  FROM DataCollect IMPORT
    (* PROCEDURE *) UpdTab800, ResetDataCollect;

  FROM CommonTypes IMPORT
    (* CONST *) NilValC, SigNilVal, DisNilVal;

  FROM SpecConv IMPORT
    GorszeBoMniejszeM60, GorszeBoMniejsze1500, GorszeBoWieksze, 
    GorszeBoMniejsze500;

  FROM MANAGER IMPORT
    STARTPROCESS;


  FROM ScannerI IMPORT
                    CurrGPSAlfaOffset,
    (* VAR *) RefDis, RefAlfa;

  FROM SimScanner IMPORT
    Simulate, LoadEvents, OdtworzEventy;

  FROM D_Odb IMPORT
    Agc, distErrF, Reply, Squitter, Trace, Mem, Audio, distErr, flg, 
    Dis, DisI, PoprawDane;


  FROM D_Files IMPORT
    OpenFiles, LoadData, CloseFiles;

  FROM D_Slupek  IMPORT
    InitSlupek, DoneSlupek;

  FROM CommonTypes IMPORT
    GlownyOdbiornikT, DMEA_trc, DMEB_trc, DMEA_mem, DMEB_mem, DMEA_Aud_flg,
    DMEB_Aud_flg;

  FROM Timer IMPORT
    Wait, TInOneSecond;

  FROM Pomiar IMPORT
    CallStopButton;

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
(*
    pilotEvId    : DtaSignType;
*)
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
    CollectData    : BOOLEAN;
    currGPSOffest  : INTEGER;
    
  BEGIN (* Acquire *)
    redraw := TRUE;
    CollectData := FALSE;
    currGPSOffest := CurrGPSAlfaOffset();
    LOOP
      Wait( TInOneSecond() DIV 5 ) (*NewDataAvailable*);
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
          D_Odb.Wznow;
          redrawM := TRUE;
          CollectData := TRUE;
        |
        StopREQ :
(*
          ok := NewEvent(Pomiar, StopPomiaru, ev);
*)
          D_Odb.Zatrzymaj;
          CollectData := FALSE;
          redrawM := TRUE;
          OdtworzEventy( Pomiar );
        |
        RestartREQ :
(*
          ev.Wysokosc := ABOVESL;
          ok := NewEvent(Pomiar, StartPomiaru, ev);
*)
          D_Odb.Wznow;
          CollectData := TRUE;
          redrawM := TRUE;
        |
        AbortREQ :
          D_Odb.Zatrzymaj;
          EXIT;
        |
        ConsoleEventReq :
(*
          ev.D_SilaSyg := Agc[goA];
          NewConsoleEvent(Pomiar, ev);
*)
      END (* case AcqireProcStat *);
      IF CollectData
      THEN
        IF NOT LoadData() THEN
          CallStopButton;
        END;
        (* dane dla ScannerI *)
        Simulate( TRUE, Pomiar, currGPSOffest );
        (* dane dla D_Odb *)
        Trace[goA] := NOT (DMEA_trc IN flg);
        Trace[goB] := NOT (DMEB_trc IN flg);
        Mem[goA]   := DMEA_mem IN flg;
        Mem[goB]   := DMEB_mem IN flg;
        Audio[goA] := DMEA_Aud_flg IN flg;
        Audio[goB] := DMEB_Aud_flg IN flg;
        distErrF   := distErr;
        IF Dis[goA] <> DisNilVal THEN
          DisI[goA] := Dis[goA] DIV 5;     
        ELSE
          DisI[goA] := SigNilVal;
        END (* IF *);
        IF Dis[goB] <> DisNilVal THEN
          DisI[goB] := Dis[goB] DIV 5;     
        ELSE
          DisI[goB] := SigNilVal;
        END (* IF *);
        PoprawDane(goA);
        PoprawDane(goB);
        (**)

        currUpdMarks;

(*
        IF GetPilotEvent(pilotEvId)
        THEN
          NewPilotEvent(Pomiar, ev);
        END (* if GetPilotEvent *);
        IF TheodolitRead.GetEvent()
        THEN
          NewTeoEvent(Pomiar, ev);
        END (* if TheodolitRead.GetEvent *);
*)
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
(*    InitPilotEventId(pilotEvId);*)
    filesNotEmpty := FALSE;
    LoadEvents( Pomiar );
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

  PROCEDURE Start;
    (* zacznij rejestracje od poczatku *)

  BEGIN
    ResetDataCollect(Pomiar, GorszeBoMniejszeM60, GorszeBoWieksze,
                     GorszeBoMniejsze500, GorszeBoMniejsze1500);
    IF filesNotEmpty  THEN
      CloseFiles;
      OpenFiles;
    END;
    LoadEvents(Pomiar);
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
    OdtworzEventy( Pomiar );
  END Abort;

BEGIN
  filesNotEmpty := FALSE;
  ImportantDiv := NilValC;
  redraw := FALSE;
  redrawM := FALSE;
END D_DAcquizition.
