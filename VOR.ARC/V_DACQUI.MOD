(*.F- *)
(**********************************************************************
|  Title   : Pokazywanie danych dla VOR
|  Author  : M.Morawski
|  System  : LOGITECH MODULA-2/86
|  History :
|    03-06-97: M.Postol
|      zmienilem znak bledu przy odtwarzaniu danych dynamicznych
|
|  Copyright (C), CAS LODZ POLAND.
|  TEL: 42' 862 547, 42' 87 80 44 FAX/TEL: 42' 84 48 40
|
**********************************************************************)
(*.F+ *)

IMPLEMENTATION MODULE V_DAcquizition;

  IMPORT
    MANAGER, DataCollect, V_Odb, CommonData;

  FROM DataCollect IMPORT
    (* PROCEDURE *) UpdTab800, ResetDataCollect;

  FROM EventsMng IMPORT
    (* TYPE *) EventKind, NewEvent, NewTeoEvent, EventType,
    (* PROCEDURE *) NewConsoleEvent, NewPilotEvent;

  FROM CommonTypes IMPORT
    (* CONST *) NilValC, NAVA_flg, NAVB_flg, NAVA_Aud_flg, NAVB_Aud_flg,
    (* TYPE *) GlownyOdbiornikT;

  FROM SpecConv IMPORT
    GorszeBoMniejsze300, GorszeBoMniejsze, GorszeBoDalszeOdZera,
    SubAngle100;

  FROM MANAGER IMPORT
    STARTPROCESS;

  FROM ScannerI IMPORT
    (* TYPE *) DtaSignType,
    (* PROCEDURE *) NewDataAvailable, GetPilotEvent, InitPilotEventId,
                    LocationsTogether,
    (* VAR *) RefDis, RefAlfa, ABOVESL, AlfaF;

  FROM SimScanner IMPORT
    Simulate, LoadEvents, OdtworzEventy;

  FROM V_Odb IMPORT
    obr, var, agc, sub, DEVVAL;

  FROM V_Files IMPORT
    OpenFiles, LoadData, CloseFiles;

  FROM V_Slupek  IMPORT
    InitSlupek, DoneSlupek;

  FROM Timer IMPORT
    Wait, TInOneSecond;

  FROM RTSMain IMPORT
    Terminate, Status;

  FROM Pomiar IMPORT
    CallStopButton;



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
(*    pilotEvId             : DtaSignType;*)
    currUpdMarks          : PROC;
    currGlownyOdbiornik   : GlownyOdbiornikT;
    TrwaPomiarPolaryzacji : BOOLEAN;
    polvfaza              : CARDINAL;
    pom2sek               : CARDINAL;


  PROCEDURE PolV(    phase : CARDINAL );
    BEGIN
      Terminate( Warning );
    END PolV;

  MODULE Monitor [ 0 ];

    IMPORT
      AcqireProcStatType;

    FROM MANAGER IMPORT
      STARTPROCESS, Condition, InitC, WAITC, Notify;

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
    rec            : GlownyOdbiornikT;
    ok             : CARDINAL;
    newSeg         : BOOLEAN;
    CollectData    : BOOLEAN;
    AcqireProcStat : AcqireProcStatType;
  BEGIN (* Acquire *)
    newSeg := FALSE;
    redraw := TRUE;
    CollectData := FALSE;
    LOOP
      Wait( TInOneSecond() DIV 5 ); (* WaitForNewdata *)
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

          V_Odb.Wznow;

          newSeg := TRUE;
          redrawM := TRUE;
          CollectData := TRUE;
        |
        StopREQ :
          redrawM := TRUE;
          CollectData := FALSE;
(*
          ok := NewEvent(Pomiar, StopPomiaru, ev);
*)
          V_Odb.Zatrzymaj;
          OdtworzEventy( Pomiar );
        |
        RestartREQ :
(*
          ev.Wysokosc := ABOVESL;
          ok := NewEvent(Pomiar, StartPomiaru, ev);
*)
          V_Odb.Wznow;
          CollectData := TRUE;
          redrawM := TRUE;
        |
        AbortREQ :

          V_Odb.Zatrzymaj;

          EXIT;
        |
        ConsoleEventReq :
(*
          WITH ev DO
            brG := obr[currGlownyOdbiornik];
            V_blad := DEVVAL[currGlownyOdbiornik];
          END (* with ev *);
          NewConsoleEvent(Pomiar, ev);
*)
      END (* case AcqireProcStat *);
      IF CollectData
      THEN
        IF NOT LoadData(newSeg) THEN
          CallStopButton;
        END;
        (* dane dla ScannerI *)
        Simulate( TRUE, Pomiar, 0 );
        (* dane dla V_Odb *)
        V_Odb.navFlg[goA] := NAVA_flg IN V_Odb.flg;
        V_Odb.navFlg[goB] := NAVB_flg IN V_Odb.flg;
        FOR rec := goA TO goB DO
          IF LocationsTogether() THEN
            DEVVAL[rec] := 
                        SubAngle100(AlfaF.Together[CommonData.OdnDlaPomBledu],
                                    obr[rec] );
          ELSE
            DEVVAL[rec] := SubAngle100(AlfaF.Spread[rec], obr[rec]);
          END;
        END;
        V_Odb.audio[goA]  := NAVA_Aud_flg IN V_Odb.flg;
        V_Odb.audio[goB]  := NAVB_Aud_flg IN V_Odb.flg;
        V_Odb.PoprawDane(goA);
        V_Odb.PoprawDane(goB);
        (**)
        currUpdMarks;
        newSeg := FALSE;
(*
        IF GetPilotEvent(pilotEvId)
        THEN
          WITH ev DO
            brG := obr[currGlownyOdbiornik];
            V_blad := DEVVAL[currGlownyOdbiornik];
          END (* with ev *);
          NewPilotEvent(Pomiar, ev);
        END (* if GetPilotEvent *);
        IF TheodolitRead.GetEvent()
        THEN
          WITH ev DO
            brG := obr[currGlownyOdbiornik];
            V_blad := DEVVAL[currGlownyOdbiornik];
          END (* with ev *);
          NewTeoEvent(Pomiar, ev);
        END (* if TheodolitRead.GetEvent *);
        IF TrwaPomiarPolaryzacji
        THEN
          ZnacznikiPol;
        END (* if TrwaPomiarPolaryzacji *);
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
    V_Odb.Start;
    ResetDataCollect(Pomiar, GorszeBoDalszeOdZera, GorszeBoMniejsze300,
                     GorszeBoMniejsze, GorszeBoMniejsze300);
    InitSlupek;
    LoadEvents( Pomiar );
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
    filesNotEmpty: BOOLEAN;

  PROCEDURE Start;
    (* zacznij rejestracje od poczatku *)

  BEGIN
    ResetDataCollect( Pomiar, GorszeBoDalszeOdZera, GorszeBoMniejsze300,
                      GorszeBoMniejsze, GorszeBoMniejsze300 );
    IF filesNotEmpty  THEN
      CloseFiles;
      OpenFiles;
    END;
    LoadEvents( Pomiar );
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
END V_DAcquizition.
