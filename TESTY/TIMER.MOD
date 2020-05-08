(*.f- *)
(**********************************************************************
|     Title   : Timer support library for IBM.
|     Author  : M.Postol.
|     System  : LOGITECH MODULA-2/86
|  History
|    29 Jun 1990 - original version
|    03 Oct 1990 M.Postol
|      referece to storage in the Wait procedure was removed.
|    13 Mar 1991 M.Postol
|      internal monitor was added
|    16 Apr 1991 M.Postol
|      - aligned to new dwfinition
|      - error concerned with initiation of PeriodicProcedure and
|        PeriodCount was cleared up
|      - the module was aligned to the IBM-PC requirements (org. GDCX).
|      - an error concerning the Previous field in the IntHandler was removed
|     18 Apr 1991 M.Postol
|        error in the Wait procedure was cleared up
|  Copyright (C), Optimal Control Laboratory.
***********************************************************************)
(*.f+ *)

IMPLEMENTATION MODULE Timer;

  FROM Storage IMPORT
    ALLOCATE, DEALLOCATE;

  IMPORT
    MANAGER, SYSTEM, RTSMain;

  FROM MANAGER IMPORT
    Condition, Release, WAITC, InitC, StartTimeSlicing, Assert;

  FROM SYSTEM IMPORT
    INBYTE, OUTBYTE, ADR;
  FROM Sounds IMPORT Sound, NoSound;


  CONST
    IBMLevel  = 0;
    DefPeriod = 1000;  (* in milliseconds *)
    Created   = 61363;
    Destroyed = 11111;
VAR
    TIOS      : CARDINAL;
    ClockPer  : CARDINAL;

  MODULE Monitor [ 8 - IBMLevel ];

    FROM MANAGER IMPORT
      (* TYPE *) Condition,
      (* PROCEDURE *) STARTPROCESS, DOIO, WAITC, Notify, InitC, Release,
                      StartTimeSlicing, Assert;

    FROM SYSTEM IMPORT
      INBYTE, OUTBYTE, ADR, CODE;

    IMPORT
      (* CONST *) IBMLevel, Created, DefPeriod, ClockPer,
      (* TYPE *) ConditionPtr, Watchdog,
      (* PROCEDURE *) Dummy, StartProtectedOperation, DefinePeriod,
      (* VAR *) TIOS,
      (* MODULE *) RTSMain;
     IMPORT MANAGER,Sound, NoSound, BreakKey;
    EXPORT
      (* TYPE *) Watchdog, Metronome, TODesPtr, TODes, DescrKind,
      (* PROCEDURE *) Remove, Insert, Wait, WaitMetronomeBefProtOper,
                      AssignPeriodicProc, CurrentPeriod, DefinePeriod,
                      WaitBefProtOper, WaitMetronome,
                      SetCount;

    TYPE
      TODesPtr  =
        POINTER TO TODes;
      Watchdog  =
        TODesPtr;
      Metronome =
        TODesPtr;
      DescrKind =
        ( DelayDSC,
          MetronomeDSC,
          WatchdogDSC );
      TODes     =
        RECORD (* Time out descriptor *)
          Control    :
            CARDINAL;
          Previous   :
            TODesPtr;
          Next       :
            TODesPtr;
          ProcessPtr :
            ConditionPtr;
          Count      :
            CARDINAL;
          InQueue    :
            BOOLEAN;
          CASE Descriptor : DescrKind OF
            MetronomeDSC :
              NOClicks   : CARDINAL;
              Period     : CARDINAL;
            |
            WatchdogDSC :
            |
            DelayDSC :
          END (* case *);
        END (* record *);

    VAR
      TOQueue           : TODesPtr;
      Period            : CARDINAL;
      PeriodCount       : CARDINAL;
      PeriodicProcedure : PROC;

    PROCEDURE Insert
              (     OwnTODes : TODesPtr;
                VAR Previous : TODesPtr;
                VAR Next     : TODesPtr;
                VAR Count    : CARDINAL );

    BEGIN
      Next := TOQueue;
      IF (TOQueue = NIL) OR (Count <= TOQueue^.Count)
      THEN
        Previous := NIL;
        TOQueue := OwnTODes;
      ELSE
        REPEAT
          Previous := Next;
          Count := Count - Next^.Count;
          Next := Next^.Next;
        UNTIL (Next = NIL) OR (Next^.Count >= Count);
        Previous^.Next := OwnTODes;
      END (* if *);
      IF Next # NIL
      THEN
        Next^.Count := Next^.Count - Count;
        Next^.Previous := OwnTODes;
      END (* if Next *);
    END Insert;

    PROCEDURE Remove
              (    OwnTODes : TODesPtr );

    BEGIN
      WITH OwnTODes^ DO
        IF InQueue
        THEN
          IF Previous = NIL
          THEN
            TOQueue := Next;
          ELSE
            Previous^.Next := Next;
          END (* if Previous *);
          IF Next # NIL
          THEN
            Next^.Count := Next^.Count + Count;
            Next^.Previous := Previous;
          END (* if Next *);
          WHILE Previous <> NIL DO
            Count := Previous^.Count;
            Previous := Previous^.Previous;
          END (* while Previous *);
        END (* if InQueue *);
      END (* with OwnTODes *);
    END Remove;

    PROCEDURE Wait
              (    Ticks : CARDINAL );
    VAR
      Process     : (* COMPILER ERROR *) RECORD
                                           P :
                                             Condition
                                         END (* record *);
      OwnTODes    : TODesPtr;
      OwnTODesRec : TODes;

    BEGIN
      IF Ticks # 0
      THEN
        OwnTODes := ADR(OwnTODesRec);
        WITH OwnTODes^ DO
          Control := Created;
          InitC(Process.P);
          ProcessPtr := ADR(Process);
          Count := Ticks;
          Descriptor := DelayDSC;
          InQueue := TRUE;
          Insert(OwnTODes, Previous, Next, Count);
        END (* with OwnTODes *);
        WAITC(Process.P);
      END (* if Ticks *);
    END Wait;

    PROCEDURE WaitBefProtOper
              (    Ticks        : CARDINAL;
                   W            : Watchdog;
                   AlarmProcess : ConditionPtr;
                   Deadline     : CARDINAL     );
    VAR
      Process : (* COMPILER ERROR *) RECORD
                                       P :
                                         Condition
                                     END (* record *);

    BEGIN
      WITH W^ DO
        Assert(Control = Created);
        IF Ticks # 0
        THEN
          InitC(Process.P);
          ProcessPtr := ADR(Process);
          Descriptor := DelayDSC;
          Count := Ticks;
          InQueue := TRUE;
          Insert(W, Previous, Next, Count);
          WAITC(Process.P);
        END (* if Ticks *);
        Descriptor := WatchdogDSC;
      END (* with W *);
      StartProtectedOperation(W, AlarmProcess, Deadline);
    END WaitBefProtOper;

    PROCEDURE WaitMetronomeBefProtOper
              (     M            : Metronome;
                VAR NuOClicks    : CARDINAL;
                    NewPeriod    : CARDINAL;
                    W            : Watchdog;
                    AlarmProcess : ConditionPtr;
                    Deadline     : CARDINAL     );
    VAR
      Process : (* COMPILER ERROR *) RECORD
                                       P :
                                         Condition
                                     END (* record *);

    BEGIN
      WITH M^ DO
        Assert((Control = Created));
        InitC(Process.P);
        ProcessPtr := ADR(Process);
        WAITC(Process.P);
        NuOClicks := NOClicks;
        NOClicks := 0;
      END (* with M *);
      StartProtectedOperation(W, AlarmProcess, Deadline);
    END WaitMetronomeBefProtOper;

    PROCEDURE WaitMetronome
              (     M         : Metronome;
                VAR NuOClicks : CARDINAL;
                    NewPeriod : CARDINAL  );
    VAR
      Process : (* COMPILER ERROR *) RECORD
                                       P :
                                         Condition
                                     END (* record *);

    BEGIN
      WITH M^ DO
        Assert(Control = Created);
        InitC(Process.P);
        ProcessPtr := ADR(Process);
        WAITC(Process.P);
        NuOClicks := NOClicks;
        NOClicks := 0;
      END (* with *);
    END WaitMetronome;

    PROCEDURE DefinePeriod
              (    Milliseconds : CARDINAL ) : CARDINAL;

    BEGIN
      IF Milliseconds < ClockPer
      THEN
        Milliseconds := ClockPer;
      END (* if Milliseconds *);
      Period := Milliseconds DIV ClockPer;
      PeriodCount := Period;
      RETURN Period * ClockPer;
    END DefinePeriod;

    PROCEDURE CurrentPeriod() : CARDINAL;

    BEGIN
      RETURN Period * ClockPer;
    END CurrentPeriod;

    PROCEDURE AssignPeriodicProc
              (    PeriodicProc : PROC );

    BEGIN
      PeriodicProcedure := PeriodicProc;
    END AssignPeriodicProc;

    PROCEDURE IBMIntHandler;
      (* process *)

      PROCEDURE Count;
      VAR
        CurrTODes : TODesPtr;

      BEGIN
        IF TOQueue # NIL
        THEN
          DEC(TOQueue^.Count);
          WHILE (TOQueue # NIL) AND (TOQueue^.Count = 0) DO
            CurrTODes := TOQueue;
            TOQueue := TOQueue^.Next;
            IF TOQueue <> NIL  THEN
              TOQueue^.Previous := NIL;
            END;
            WITH CurrTODes^ DO
              CASE Descriptor OF
                MetronomeDSC :
                  INC(NOClicks);
                  Count := Period;
                  Insert(CurrTODes, Previous, Next, Count);
              ELSE
                InQueue := FALSE;
              END (* case *);
              IF ProcessPtr # NIL
              THEN
                Notify(ProcessPtr^);
                ProcessPtr := NIL;
              END (* if *);
            END (* with CurrTODes *);
          END (* while *);
        END (* if TOQueue *);
      END Count;
    VAR
       ok : CARDINAL;
       Hz : CARDINAL;
    BEGIN
      ok := 0;
      LOOP
        DOIO(IBMLevel);
        IF MANAGER.ReadyFirst#NIL THEN
(*$R-*)
          INC(MANAGER.Statistic[MANAGER.ReadyFirst^.OrdNr].time);
(*$R=*)
        ELSE
          ok := ok;
        END;
        IF ok >= TIOS THEN
          (* NoSound; *)
          Hz := 0;
          ok := 0;
          BreakKey;
        ELSIF ok = TIOS - TIOS DIV 5 THEN
          Hz := 1500;
          (* Sound(Hz); *)
        END;
        IF (ok MOD (TIOS DIV 5) = 1) THEN
          OUTBYTE(21H,0FAH);
          CODE( 0CDH, 08H );
          CODE(0FAH);
          OUTBYTE(21H,0FFH);
          CODE(0FBH);
        END;  
        INC(ok);
        Count;
        DEC(PeriodCount);
        IF PeriodCount = 0
        THEN
          PeriodicProcedure;
          PeriodCount := Period;
        END (* if PeriodCount *);
      END (* loop *);
    END IBMIntHandler;

  PROCEDURE SetCount (count: CARDINAL);
  CONST
    channel0            = 40H;
    TimerControlPort    = channel0+3;
  BEGIN
    OUTBYTE (TimerControlPort, 036H);
    OUTBYTE (channel0, CHR(count MOD 256));
    OUTBYTE (channel0, CHR(count DIV 256));
    TIOS := VAL(CARDINAL,
                VAL(LONGINT,1764)*VAL(LONGINT,0FFFFH) DIV
                VAL(LONGINT,count) DIV 100L
                );
    ClockPer := 1000 DIV TIOS;
    IF ClockPer=0 THEN
      ClockPer := 1;
    END;
  END SetCount;

  PROCEDURE RestoreTimer();
  BEGIN
    NoSound;
    SetCount(0FFFFH); (* std. 18.2 razy na sekunde dla n=0FFFFH *)
  END RestoreTimer;

    VAR
      Dumm : CARDINAL;

  BEGIN (* Monitor *)
    RTSMain.InstallTermProc(RestoreTimer);
    (* SetCount(1156); (* 1156 DA == 1ms *) *)
    SetCount(0FFFFH); (* std. 18.2 razy na sekunde dla n=0FFFFH *)
    Dumm := DefinePeriod(DefPeriod);
    TOQueue := NIL;
    PeriodicProcedure := Dummy;
    STARTPROCESS(IBMIntHandler, 0A00H, 0);
  END Monitor;

  PROCEDURE TInOneSecond() : CARDINAL;

  BEGIN
    RETURN TIOS;
  END TInOneSecond;

  PROCEDURE NewMetronome
            ( VAR M       : Metronome;
                  MPeriod : CARDINAL  );

  BEGIN
    NEW(M);
    WITH M^ DO
      Control := Created;
      ProcessPtr := NIL;
      Count := MPeriod;
      InQueue := TRUE;
      NOClicks := 0;
      Period := MPeriod;
      Descriptor := MetronomeDSC;
      Insert(M, Previous, Next, Count);
    END (* with M *);
  END NewMetronome;

  PROCEDURE ResetMetronome
            (    M : Metronome );

  BEGIN
    WITH M^ DO
      Assert(Control = Created);
      Assert(InQueue);
      Remove(M);
      Count := Period;
      InQueue := TRUE;
      NOClicks := 0;
      Descriptor := MetronomeDSC;
      Insert(M, Previous, Next, Count);
    END (* with *);
  END ResetMetronome;

  PROCEDURE DisposeMetronome
            ( VAR M : Metronome );

  BEGIN
    WITH M^ DO
      Assert((Control = Created) AND InQueue);
      Remove(M);
      Control := Destroyed;
    END (* with *);
    DISPOSE(M);
  END DisposeMetronome;

  PROCEDURE NewWatchdog
            ( VAR W : Watchdog );

  BEGIN
    NEW(W);
    WITH W^ DO
      Control := Created;
      ProcessPtr := NIL;
      Count := 0;
      Descriptor := WatchdogDSC;
      InQueue := FALSE;
    END (* with W *);
  END NewWatchdog;

  PROCEDURE StartProtectedOperation
            (    W            : Watchdog;
                 AlarmProcess : ConditionPtr;
                 Deadline     : CARDINAL     );

  BEGIN
    WITH W^ DO
      Assert((Control = Created) AND (Descriptor = WatchdogDSC));
      ProcessPtr := AlarmProcess;
      Count := Deadline;
      Insert(W, Previous, Next, Count);
    END (* with OwnTODes *);
    Release;
  END StartProtectedOperation;

  PROCEDURE StopProtectedOperation
            (    W : Watchdog );

  BEGIN
    WITH W^ DO
      Assert((Control = Created) AND (Descriptor = WatchdogDSC));
      Remove(W);
    END (* with *);
  END StopProtectedOperation;

  PROCEDURE DisposeWatchdog
            ( VAR W : Watchdog );

  BEGIN
    WITH W^ DO
      Assert((Control = Created) AND (Descriptor = WatchdogDSC) AND NOT InQueue
      );
      Remove(W);
      Control := Destroyed;
    END (* with *);
    DISPOSE(W);
  END DisposeWatchdog;

  PROCEDURE Dummy;

  BEGIN
  END Dummy;
  
  PROCEDURE BreakKey;
  VAR
       SpecKeys [40H:17H] : CHAR;
       SpecKeys1[40H:18H] : CHAR;
       BreakPoint  : CARDINAL;
  BEGIN
    IF (ORD(SpecKeys) MOD 16)=15 THEN (* RIGHTSHIFT + LEFTSHIFT + CTRL + ALT *)
      SetCount(0FFFFH);
(* ===> *)  BreakPoint:= BreakPoint;         (* <===  szansa na break point *)     
      IF ((ORD(SpecKeys) MOD 16)=15) THEN 
        IF ((ORD(SpecKeys1) MOD 4)=3) THEN
          RTSMain.Terminate(RTSMain.Warning);(* gdy CTRL i ALT lewe to *)
        ELSE
          RTSMain.Terminate(RTSMain.Stopped);
        END;
      END;
      SetCount(1156); (* 1156 DA == 1ms *)
    END;
  END BreakKey;
  
BEGIN (* initialization *)
  StartTimeSlicing(IBMLevel, 0FFFFH);
END Timer.
