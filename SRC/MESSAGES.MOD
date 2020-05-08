(*.F- *)
(**********************************************************************
|  Title   :  Messages Collector / Manager
|  Author  : D.A.
|  System  : LOGITECH MODULA-2/86
|  History :
|    13 May 1991: M.Postol
|      SaveScreen, RestoreScreen, OUTMessage were rewriten;
|    11 Sep 1991/D.A
:      SoundDefinition and two options of message order selectable (FIFO/LIFO)
|    10 Oct 1995/DA
|     New Version without Gdriver
|  Copyright (C), Inwit - Optimal Control Laboratory.
**********************************************************************)
(*.F+ *)
(*$R- *)
(*$S- *)
(*$T- *)
(*$O+ *)
IMPLEMENTATION MODULE Messages;

  FROM Storage IMPORT
    ALLOCATE, DEALLOCATE;

  IMPORT
    Strings, ShortCuts;

  FROM SYSTEM IMPORT
    ADDRESS;
  FROM GrafUtil IMPORT Info;  
(*********************************
  FROM GDriver IMPORT
    BuffSize, XMaxGlb, CharHeight, GetWindow, SetWindow, SetBackground, GoToXY,
    InvertW, Pattern, CharWidth, SaveTPos, RestoreTPos;
**********************************)
  IMPORT
    MANAGER, Sounds, Timer;

  TYPE
    MessageOrder =
      ( LIFO,
        FIFO );
        (* LastIn - FirstOut, FirstIn - FirstOut *)

  CONST
    VERSION = LIFO;  (* select as you need *)

  TYPE
    Message =
      POINTER TO MDescr;
    MDescr  =
      RECORD
        MTXT   :
          ARRAY [0 .. 80] OF CHAR;
        ENAB   :
          BOOLEAN;
        melody :
          BITSET;
        next   :
          Message;
      END;

  VAR
    MList        : Message;
    MDispl       : Message;
    MessageSound : BITSET;
    TurnBeepOn   : MANAGER.SIGNAL;
    
  PROCEDURE DisableDisplay
            ( VAR Mess : Message );

  BEGIN
    IF Mess = NIL
    THEN
      RETURN
    END (* if Mess *);
    Mess^.ENAB := FALSE;
    ShowFirst;
  END DisableDisplay;

  PROCEDURE EnableDisplay
            ( VAR Mess : Message );

  BEGIN
    IF Mess = NIL
    THEN
      RETURN
    END (* if Mess *);
    Mess^.ENAB := TRUE;
    ShowFirst;
  END EnableDisplay;

  PROCEDURE ACKMess
            ( VAR Mess : Message );
  VAR
    Mptr : Message;

  BEGIN
    IF Mess = NIL
    THEN
      RETURN
    END (* if Mess *);
    IF Mess = MList
    THEN
      MList := MList^.next;
    ELSE
      Mptr := MList;
      WHILE (Mptr # NIL) AND (Mptr^.next # Mess) DO
        Mptr := Mptr^.next;
      END (* while *);
      IF Mptr # NIL
      THEN   (* un link *)
        Mptr^.next := Mess^.next;
      END (* if Mptr *);
    END (* if Mess *);
    Mess^.next := NIL;
  END ACKMess;

  PROCEDURE NewMessage
            ( VAR Mess        : Message;
                  messageTEXT : ARRAY OF CHAR;
                  pip         : BITSET        );

  BEGIN
    NEW(Mess);
    WITH Mess^ DO
      Strings.Assign(messageTEXT, MTXT);
      ENAB := TRUE;   (* initial state *)
      melody := pip;
      next := NIL;
    END (* with *);
  END NewMessage;

  PROCEDURE DisposeMessage
            ( VAR Mess : Message );

  BEGIN
    ACKMess(Mess);
    DISPOSE(Mess);
  END DisposeMessage;

  PROCEDURE Display
            ( VAR Mess : Message );
  VAR
    Mptr : Message;

  BEGIN
    IF Mess = NIL
    THEN
      RETURN
    END (* if Mess *);
    IF VERSION = FIFO
    THEN
      IF MList = NIL
      THEN   (* queue empty place on top and display *)
        MList := Mess;
        Mess^.next := NIL;
      ELSE   (* insert at the end if not in queue *)
        Mptr := MList;
        WHILE (Mptr^.next # NIL) AND (Mptr # Mess) DO
          Mptr := Mptr^.next;
        END (* while *);
        IF Mptr # Mess
        THEN   (* link ; else this is known message don't link it*)
          Mptr^.next := Mess;
          Mess^.next := NIL;
        END (* if Mptr *);
      END (* if MList *);
    ELSE   (* LIFO *)
      IF MList = NIL
      THEN   (* queue empty place on top and display *)
        MList := Mess;
        Mess^.next := NIL;
      ELSIF MList = Mess
      THEN   (* is already on top so nothing to do *);
      ELSE   (* search if already in *)
        Mptr := MList;
        WHILE (Mptr # NIL) AND (Mptr^.next # Mess) DO
          Mptr := Mptr^.next;
        END (* while *);
        IF Mptr # NIL
        THEN
        (* this is known message unlink it here and later place on top*)
          Mptr^.next := Mess^.next;   (* un link here *)
        END (* if Mptr *);
        Mess^.next := MList;   (* place on top *)
        MList := Mess;
      END (* if MList *);
    END (* if VERSION *);
    ShowFirst;
  END Display;

  PROCEDURE ShowFirst;
  VAR
    Mptr : Message;
  BEGIN
    IF (MList = NIL)
    THEN
      Info("");
      MessageSound := {};
    ELSE
      Mptr := MList;
      WHILE (Mptr # NIL) AND (NOT Mptr^.ENAB) DO
        Mptr := Mptr^.next;
      END (* while *);
      MDispl := Mptr;
      IF (Mptr # NIL)
      THEN
        OUTMessage(Mptr^.MTXT, Mptr^.melody);
      ELSE
        Info("");
        MessageSound := {};
      END (* if Mptr *);
    END (* if *);
  END ShowFirst;

  PROCEDURE AcknowledgeFirst;

  BEGIN
    IF MDispl # NIL
    THEN
      ACKMess(MDispl);
      ShowFirst;
    END (* if MDispl *);
  END AcknowledgeFirst;

  PROCEDURE Acknowledge
            ( VAR Mess : Message );

  BEGIN
    IF Mess # NIL
    THEN
      ACKMess(Mess);
      ShowFirst;
    END (* if not NIL *);
  END Acknowledge;

(****************************
  PROCEDURE SaveScreen
            ( VAR CurrWindow : ADDRESS );
  VAR
    Length : CARDINAL;
    Dumm   : BOOLEAN;

  BEGIN
    Dumm := BuffSize(XTopLeft, YTopLeft, XBottomRight, YBottomRight, Length);
    ALLOCATE(CurrWindow, Length);
    GetWindow(CurrWindow, XTopLeft, YTopLeft, XBottomRight, YBottomRight);
  END SaveScreen;

  PROCEDURE RestoreScreen;

  BEGIN
    MessageSound := {};
    Sounds.NoSound();
    SetWindow(CurrWindow, XTopLeft, YTopLeft, XBottomRight, YBottomRight);
  END RestoreScreen;

*******)

  PROCEDURE OUTMessage
            ( VAR TXT : ARRAY OF CHAR; pip : BITSET        );
  BEGIN
    Info(TXT);
    MessageSound := pip;
    MANAGER.SEND(TurnBeepOn);
  END OUTMessage;

  PROCEDURE Beep;
  VAR
    idx : CARDINAL;

  BEGIN
    LOOP
      IF MessageSound = {}
      THEN
        MANAGER.WAITS(TurnBeepOn);
      ELSE
        FOR idx := 0 TO 15 DO
          IF idx IN MessageSound
          THEN
            Sounds.Sound(1000);
          ELSE
            Sounds.NoSound;
          END (* if *);
          Timer.Wait(100);
        END (* for *);
        Sounds.NoSound;
        Timer.Wait(Timer.TInOneSecond()*4);
      END (* if MessageSound *);
    END (* loop *);
  END Beep;
  
  PROCEDURE KbdAck(a:ADDRESS);
  BEGIN
    AcknowledgeFirst;
  END KbdAck;

  PROCEDURE KbdDsp(a:ADDRESS);
  BEGIN
    ShowFirst;
  END KbdDsp;

BEGIN
  MList := NIL;
  MDispl := NIL;
  MessageSound := {};
  MANAGER.InitS(TurnBeepOn);
(*  MANAGER.STARTPROCESS(Beep, 450H, 0); *)
  ShortCuts.DefineShortCut(ShortCuts.kbF10,KbdAck,NIL);
  ShortCuts.DefineShortCut(ShortCuts.kbShiftF10,KbdDsp,NIL);
END Messages.
