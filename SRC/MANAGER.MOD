(*V1=OnAssert *)
(*$S+*)
(*$T+*)
(*$R+*)
(*.F- *)
(**********************************************************************
|  Title    : Concurrent programming with monitors and SEND/WAIT/DOIO
|  Author   : M.Postol
|  System   : LOGITECH MODULA-2/86
|  History  :
|    01 Jan 1990 (D.Arendt):
|       Addaptation for DTC-V20 hardware and Modula-2 Rom Tools Rel 2.X
|       was made.
|    13 Mar 1990 (M.Postol):
|       Time-scharing was added.
|    14 May 1990 (M.Postol):
|       Heap control after process termination was added.
|    30 Sep 1990 (M.Postol, D.Arendt):
|       Adaptation to Modula-2 Rom Tools Rel 3.0 was made.
|    04 Oct 1990 M.Postol
|      STARTPROCESS - Storage is now used only outside the internal monitor.
|      DUMMYPRO     - addition condition for program termination
|    31 Oct 1990 (M.Postol)
|      new scheduling policy
|                  priority value of 0 distinguisch the process as
|                  the most important.
|      STOPPROCESS - never used part of code was removed.
|  22 Nov 1990 (M.Postol)
|      An error from the RemoveRedy procedure was withdrawn.
|  07 Dec 1991 (M.postol)
|      Error concernning PRIRTBitset in Send, WAITC, WAITS, STARTPROCESS,
|      RemoveReady was fixed
|      PriorityDecrease is called with disabled interrupts - changes in
|      RTSPririty
|   12 May 1992: M.Postol
|      new Assert in WAITS, and ASSERT in PriorityDecrease was removed.
|   03 Jun 1992: M.Postol
|      error concerned with stack overflow - stack check must be turned
|      off for Broadcast and all called procedures.
|   03 Apr 1995 (D.Arendt):
|      error in StartProcess Dummy - Main program SP not initialized before
|      call to STARTPROCESS; BTW. Dummy stacksize increased to 800H
|   26 June 1996: M.Postol
|      Terminator turns off time slicing
|   17.12.96: M.Morawski
|      Assert przeniesiony do monitora
|   18-01-2001: MPOstol
|      Zamienilem w Terminator warunki z petla na ASSERT
|
|   Copyright (C), Optimal Control Laboratory.
|
**********************************************************************)
(*.F+ *)

IMPLEMENTATION MODULE MANAGER;

  FROM Sounds IMPORT Sound, NoSound;

  FROM RTSDevice IMPORT
    SetPrioMask, GetPrioMask;

  IMPORT
    SYSTEM, RTSMain, BlockOps;

  FROM Storage IMPORT
    ALLOCATE, DEALLOCATE;

  FROM SYSTEM IMPORT
    ADR, CODE, SETREG, AX, ES, DI, CX, BX, GETREG, TRANSFER, WORD, ADDRESS,
    PROCESS, NEWPROCESS;

  FROM RTSMain IMPORT
    Process, activProcess, DebuggerRecord, debuggerRecord, Terminate;

  FROM RTSMonExit IMPORT
    MonitorExitProc;

  
  CONST
    MonitorBitLSB  = 12;
    MonitorBitNInt = MonitorBitLSB - 1;
    MonitorBitMSB  = 15;
    MaxPriority    = { MonitorBitLSB..MonitorBitMSB };
    MaxPrioNI      = CARDINAL({ MonitorBitLSB..MonitorBitMSB, MonitorBitNInt});
    ODUMMY         = 800H;
    MAXCARD        = 0FFFFH;
    CheckValue     = 0FA50H; (* Value defined in RTSMain but unfortunately not 
                                exported *)
  TYPE
    SIGNAL    =
      ProcessPtr;
    Condition =
      ProcessPtr;

  VAR
    CP          : ProcessPtr;  (* CURRENT PROCESS *)
    ReadyLast   : ProcessPtr;  (* Pointer to last of ready to run processes *)
    DUMMY       : ProcessPtr;  (* Pointer to process restarted when there is no
                                  ready to run processes *)
    NuOfReady   : CARDINAL;  (* current number of the ready processes *)
    WaitForInt  : CARDINAL;  (* current number of the waiting for an innterupt
                                processes *)
    TSSInterval : CARDINAL;  (* Time interval for time sliced scheduler. *)
    MaxRecTime  : CARDINAL;  (* Recovery time (expressed in clock ticks) *)
    TimeIntNum  : CARDINAL;  (* interrupt used to count the time *)
        (* $S-*)
        (* The following procedures are defined outside the Monitor to improve
           efficiency - there are no MonitorEntry, MonitorExit calls - and so
           they have to be called exclusively from inside the monitor *)
    spTab       : ARRAY [0..50] OF Process;
    
  (*<OnAssert*)

  PROCEDURE ASSERT
            (    Ex : BOOLEAN );

  VAR
    X : CHAR;

  BEGIN
    IF NOT Ex
    THEN
      Sound(500);
      RTSMain.Terminate(RTSMain.Stopped);
      CODE( 0FFH, 0FFH, 0FFH, 0FAH (* cli ; clear interrupt flag *) );
      CODE( 0FAH (* cli ; clear interrupt flag *) );
      LOOP
        X := X;
      END (* loop *);
    END (* if *);
  END ASSERT;

  (*OnAssert>*)

  PROCEDURE InsertReady;
    (* Current process pointed by CP is inserted into Ready queue. *)

  VAR
    N1,
    N2 : ProcessPtr;

  BEGIN (* INSERT *)
    WITH CP^ DO
      IF ReadyFirst = NIL
      THEN
        (*<OnAssert*)
        ASSERT( ReadyLast = NIL );
        (*OnAssert>*)
        ReadyFirst := CP;
        ReadyLast := CP;
        NEXT := NIL;
      ELSIF ( PRIRT >= MaxPrioNI ) OR
            ( ReadyLast^.PRIRT <= PRIRT )
      THEN
        (*<OnAssert*)
        ASSERT( ReadyLast^.NEXT = NIL );
        (*OnAssert>*)
        ReadyLast^.NEXT := CP;
        ReadyLast := CP;
        NEXT := NIL;
      ELSIF ReadyFirst^.PRIRT > PRIRT
      THEN
        (*<OnAssert*)
        ASSERT( ReadyLast <> NIL );
        (*OnAssert>*)
        NEXT := ReadyFirst;
        ReadyFirst := CP;
      ELSE
        N2 := ReadyFirst;
        REPEAT
          N1 := N2;
          N2 := N2^.NEXT;
        UNTIL (* ( N2 = NIL ) MP OR *) ( N2^.PRIRT > PRIRT );
        N1^.NEXT := CP;
        NEXT := N2
      END (* if ReadyFirst *)
    END (* with *);
    INC( NuOfReady );
    IF NuOfReady > MaxNumOfReady
    THEN
      MaxNumOfReady := NuOfReady;
    END (* if NuOfReady *);
  END InsertReady;

  PROCEDURE RemoveReady;

  BEGIN
    IF ReadyFirst # NIL
    THEN
      CP := ReadyFirst;
      ReadyFirst := ReadyFirst^.NEXT;
      DEC( NuOfReady );
      IF ReadyFirst # NIL
      THEN
        (*<OnAssert*)
        ASSERT( ReadyLast # NIL );
        (*OnAssert>*)
        WITH CP^ DO
          IF ( Time >= MaxTime ) AND ( PRIRT >= CARDINAL( MaxPriority ) )
          THEN
            (* Assert: the process is not within any monitor *)
            INCL(PRIRTBitset, MonitorBitNInt);
            IF MaxRunTime < Time
            THEN
              MaxRunTime := Time;
              LongestProcess := CP;
            END (* if MaxRunTime *);
            Time := 0;
            InsertReady;
            DEC( NuOfReady );
            CP := ReadyFirst;
            ReadyFirst := ReadyFirst^.NEXT;
          ELSIF ( Time > MaxRecTime )
          THEN
            CP^.ProcessStatus := TimeError;
            CP^.NEXT := ErrorQueue;
            ErrorQueue := CP;
            INC( NuOfErrorProc );
            DEC( NuOfReady );
            CP := ReadyFirst;
            ReadyFirst := ReadyFirst^.NEXT;
            IF ReadyFirst = NIL
            THEN
              ReadyLast := NIL;
            END (* if ReadyFirst = NIL *);
            Broadcast( ErrorHandler );
          END (* if *);
        END (* with CP *);
      ELSE
        (*<OnAssert*)
        ASSERT( (ReadyLast = CP) AND (NuOfReady = 0) );
        (*OnAssert>*)
        ReadyLast := NIL;
        CP^.Time := 0;
      END (* if NuOfReady *);
    ELSE
      (*<OnAssert*)
      ASSERT( ( ReadyLast = NIL ) AND ( NuOfReady = 0 ) );
      (*OnAssert>*)
      CP := DUMMY;
      DUMMY := NIL;
    END (* if ReadyFirst *);
  END RemoveReady;

  PROCEDURE ClearQueue
            (    Parent : ProcessPtr );

  VAR
    Del     : ProcessPtr;
    (*OnAssert>*)
    DelPrsc : Process;
    (*OnAssert>*)
  BEGIN
    WITH Parent^ DO
      WHILE Ended # NIL DO
        Del := Ended;
        Ended := Ended^.NEXT;
        WITH Del^ DO
          (*<OnAssert*)
          DelPrsc := Process(SP);
          ASSERT( DelPrsc^.checkWord = CheckValue );
          (*OnAssert>*)
          (* remove from list *)
          PreviousOnList^.NextOnList := NextOnList;
          (* PreviousOnList is not NIL *)
          IF NextOnList = NIL
          THEN   (* last created *)
            LastCreated := PreviousOnList;
          ELSE
            NextOnList^.PreviousOnList := PreviousOnList;
          END (* if NextOnList *);
          DEALLOCATE( WArea, Size );
        END (* with *);
        DISPOSE( Del );
      END (* while *);
    END (* with *);
  END ClearQueue;

  PROCEDURE INSERT
            ( VAR QUEUE : ProcessPtr );
    (* Current process pointed by CP is inserted into QUEUE *)

  VAR
    N1,
    N2   : ProcessPtr;
    prio : CARDINAL;
    (*OnAssert>*)
    DelPrsc : Process;
    (*OnAssert>*)

  BEGIN (* INSERT*)
    prio := CP^.PRIRT;
    (*<OnAssert*)
    DelPrsc := Process(CP^.SP);
    ASSERT( DelPrsc^.checkWord = CheckValue );
    (*OnAssert>*)
    IF ( QUEUE = NIL ) OR ( QUEUE^.PRIRT > prio )
    THEN
      (*<OnAssert*)
      IF QUEUE <> NIL  THEN
        DelPrsc := Process(QUEUE^.SP);
        ASSERT( DelPrsc^.checkWord = CheckValue );
      END;
      (*OnAssert>*)
      CP^.NEXT := QUEUE;
      QUEUE := CP;
    ELSE
      N2 := QUEUE;
      (*<OnAssert*)
      DelPrsc := Process(QUEUE^.SP);
      ASSERT( DelPrsc^.checkWord = CheckValue );
      (*OnAssert>*)
      REPEAT
        N1 := N2;
        N2 := N2^.NEXT;
        (*<OnAssert*)
        IF N2 <> NIL  THEN
          DelPrsc := Process(N2^.SP);
          ASSERT( DelPrsc^.checkWord = CheckValue );
        END;
        (*OnAssert>*)
      UNTIL ( N2 = NIL ) OR ( N2^.PRIRT > prio );
      N1^.NEXT := CP;
      CP^.NEXT := N2
    END (* if *)
  END INSERT;

  PROCEDURE REMOVE
            ( VAR QUEUE : ProcessPtr );

  (*OnAssert>*)
  VAR
    DelPrsc : Process;
  (*OnAssert>*)
  
  BEGIN
    (*<OnAssert*)
    ASSERT( QUEUE <> NIL );
    (*OnAssert>*)
    CP := QUEUE;
    QUEUE := QUEUE^.NEXT;
    WITH CP^ DO
      (*<OnAssert*)
      DelPrsc := Process(SP);
      ASSERT( DelPrsc^.checkWord = CheckValue );
      (*OnAssert>*)
      IF MaxRunTime < Time
      THEN
        MaxRunTime := Time;
        LongestProcess := CP;
      END (* if MaxRunTime *);
      Time := 0;
    END (* with CP *);
  END REMOVE;

  (* $S=*)

  MODULE Scheduler [ 8 ];

    FROM SYSTEM IMPORT
      PROCESS, IOTRANSFER, TRANSFER, CODE, GETREG, BX, ADR, SIZE;

    FROM RTSMain IMPORT
      Process;

    FROM BlockOps IMPORT 
      BlockClear;
      
    IMPORT
      (* TYPE *) ProcessPtr,
      (* VAR *) LongestProcess, CP, ReadyFirst, ErrorQueue, LastCreated,
                WaitForInt, NuOfErrorProc, ErrorHandler, TimeIntNum, MaxRunTime
                , NumberOfProc, ReadyLast, NuOfReady, spTab, 
      (* CONST *) MonitorBitLSB, MonitorBitMSB, MonitorBitNInt, MaxPriority,
                  AssertError,
      (* PROCEDURE *) InsertReady, RemoveReady, ClearQueue, REMOVE, INSERT
                      (*<OnAssert*) , ASSERT  (*OnAssert>*),
                      Statistic;

    EXPORT
      SEND, Notify, Broadcast, WAITS, WAITC, DOIO, AWAITEDS, AWAITEDC,
      ActivateProcess, STOPPROCESS, StopAError, Assert;

    PROCEDURE SEND
              ( VAR S : ProcessPtr );

    VAR
      This         : ProcessPtr;
      LastPriority : BITSET;

    BEGIN
      This := CP;
      (* WARNING!!! Implementation dependent part of the program *)
      CODE( 089H, 0E3H, (* mov bx,sp *) 036H, 08BH, 01FH, (* mov bx,ss:[bx] *)
            081H, 0E3H, 000H, 0F0H (* and bx,F000 *) );
      GETREG( BX, LastPriority );
      WITH This^ DO
        PRIRTBitset := PRIRTBitset * { 0..MonitorBitNInt - 1 } + {
                       MonitorBitNInt } + LastPriority;
        IF MaxRunTime < Time
        THEN
          MaxRunTime := Time;
          LongestProcess := CP;
        END (* if MaxRunTime *);
        Time := 0;
        ASSERT( spTab[OrdNr] = Process(SP));
      END (* with *);
      InsertReady;
      IF S <> NIL
      THEN
        REMOVE( S );
      ELSE
        RemoveReady;
      END (* if S *);
      IF This # CP
      THEN
        TRANSFER( This^.SP, CP^.SP );
        ASSERT( spTab[This^.OrdNr] = Process(This^.SP));
        IF CP^.Ended # NIL
        THEN
          ClearQueue( CP );
        END (* if CP *);
      END (* if This *);
    END SEND;

    PROCEDURE Notify
              ( VAR S : ProcessPtr );

    VAR
      This : ProcessPtr;

    BEGIN
      IF S # NIL
      THEN
        This := CP;
        REMOVE( S );
        InsertReady;
        CP := This;
      END (* if S *);
    END Notify;

    (*$S- *)

    PROCEDURE Broadcast
              ( VAR S : ProcessPtr );

    VAR
      This : ProcessPtr;

    BEGIN
      This := CP;
      WHILE S # NIL DO
        REMOVE( S );
        InsertReady;;
      END (* while S *);
      CP := This;
    END Broadcast;

    (*$S= *)

    PROCEDURE WAITS
              ( VAR S : ProcessPtr );

    VAR
      This         : ProcessPtr;
      LastPriority : BITSET;

    BEGIN
      This := CP;
      (* WARNING!!! Implementation dependent part of the program *)
      CODE( 089H, 0E3H, (* mov bx,sp *) 036H, 08BH, 01FH, (* mov bx,ss:[bx] *)
            081H, 0E3H, 000H, 0F0H (* and bx,F000 *) );
      GETREG( BX, LastPriority );
      WITH This^ DO
        PRIRTBitset := PRIRTBitset * { 0..MonitorBitNInt - 1 } + {
                       MonitorBitNInt } + LastPriority;
        INSERT( S );
        RemoveReady;
        TRANSFER( SP, CP^.SP );
        ASSERT( spTab[OrdNr] = Process(SP));
        IF Ended # NIL
        THEN
          ClearQueue( CP );
        END (* if Ended *);
      END (* with This *);
    END WAITS;

    PROCEDURE WAITC
              ( VAR S : ProcessPtr );

    VAR
      This         : ProcessPtr;
      LastPriority : BITSET;

    BEGIN
      This := CP;
      (* WARNING!!! Implementation dependent part of the program *)
      CODE( 089H, 0E3H, (* mov bx,sp *) 036H, 08BH, 01FH, (* mov bx,ss:[bx] *)
            081H, 0E3H, 000H, 0F0H (* and bx,F000 *) );
      GETREG( BX, LastPriority );
      WITH This^ DO
        PRIRTBitset := PRIRTBitset * { 0..MonitorBitNInt - 1 } + {
                       MonitorBitNInt } + LastPriority;
        INSERT( S );
        RemoveReady;
        TRANSFER( SP, CP^.SP );
        ASSERT( spTab[OrdNr] = Process(SP));
        IF Ended # NIL
        THEN
          ClearQueue( CP );
        END (* if Ended *);
      END (* with This *);
    END WAITC;
    
    VAR
      expInter : ARRAY[0..8] OF CARDINAL;
      
    PROCEDURE DOIO
              (    V : CARDINAL );

    CONST
      INTBASE = 8;  (* as in 8259A *)

    VAR
      This       : ProcessPtr;
      TSP        : PROCESS;
      IntProcess : Process;
      sReadyFirst: ProcessPtr;
      sReadyLast : ProcessPtr;
      sCP        : ProcessPtr;
      
    BEGIN
      This := CP;
      CP^.Time := 0;
      (* removed for efficiency WITH CP^ DO IF MaxRunTime < Time THEN
         MaxRunTime := Time; LongestProcess := CP; END ; Time := 0; END ; *)
      RemoveReady;
      INC( WaitForInt );
      TSP := CP^.SP;
      INC(expInter[V]);
      IOTRANSFER( This^.SP, TSP, V + INTBASE );
      ASSERT( expInter[V] = 1 );
      DEC(expInter[V]);
      sReadyFirst := ReadyFirst;
      sReadyLast  := ReadyLast;
      sCP := CP;
      DEC( WaitForInt );
      WITH CP^ DO
        ASSERT( spTab[OrdNr] = Process(TSP));
        SP := TSP;
        IntProcess := Process( SP );
        PRIRTBitset := PRIRTBitset * { 0..MonitorBitNInt - 1 } + 
                       IntProcess^.priorityMask * MaxPriority;
        IF V = TimeIntNum
        THEN
          INC( Time );
        END (* if V *);
        IF ReadyFirst = NIL
        THEN
          (*<OnAssert*)
          ASSERT( ReadyLast = NIL );
          (*OnAssert>*)
          ReadyFirst := CP;
          ReadyLast := CP;
          NEXT := NIL;
        ELSE
        (*<OnAssert*)
          ASSERT( ( ReadyLast <> NIL ) AND ( ReadyFirst^.PRIRT >= PRIRT ) );
          (*OnAssert>*)
          NEXT := ReadyFirst;
          ReadyFirst := CP;
        END (* if ReadyFirst *);
      END (* with CP *);
      INC( NuOfReady );
      CP := This;
    END DOIO;

    PROCEDURE AWAITEDS
              (    S : ProcessPtr ) : BOOLEAN;

    BEGIN
      RETURN S # NIL;
    END AWAITEDS;

    PROCEDURE AWAITEDC
              (    C : ProcessPtr ) : BOOLEAN;

    BEGIN
      RETURN C # NIL;
    END AWAITEDC;

    (* $S-*)

    (* $R-*)

    (* $T-*)

    PROCEDURE STOPPROCESS;

    VAR
      This : ProcessPtr;
    BEGIN (* STOPPROCESS *)
      This := CP;
      This^.Halted := TRUE;
      DEC( NumberOfProc );
      LOOP
        WITH This^ DO
          IF ( ReadyFirst = NIL ) AND ( WaitForInt = 0 )
          THEN
            RETURN;   (* Halt program *)
          END (* if *);
          IF NDescen = 0
          THEN
            Statistic[OrdNr].id := PROC( 0FFFFH:0FFFFH );
            Statistic[OrdNr].time := 0L;
            EXIT
          END (* if This *);
          RemoveReady;
          TRANSFER( This^.SP, CP^.SP );
          ClearQueue( This );
        END (* with This *);
      END (* loop *);
      WITH This^.Parent^ DO   (* Assert T^.Parent # NIL *)
      (* This part of program cannot be executed by main process *)
        This^.NEXT := Ended;
        Ended := This;
        DEC( NDescen );
        IF Halted
        THEN
          CP := This^.Parent
        ELSE
          RemoveReady;
        END (* if Halted *);
      END (* with *);
      TRANSFER( This^.SP, CP^.SP );
    END STOPPROCESS;

    PROCEDURE StopAError;
      (* StopAError is called after detecting a run time error. This procedure
         must be executed with stack and heap control switched off. *)

    VAR
      This : ProcessPtr;

    BEGIN
      Broadcast( ErrorHandler );
      This := CP;
      This^.NEXT := ErrorQueue;
      ErrorQueue := This;
      INC( NuOfErrorProc );
      RemoveReady;
      TRANSFER( This^.SP, CP^.SP );
    END StopAError;

    (* $S=*)

    (* $R=*)

    (* $T=*)

    PROCEDURE ActivateProcess
              (    CurrentProc : ProcessPtr;
                   NewProc     : ProcessPtr );

    BEGIN
      LastCreated^.NextOnList := NewProc;
      LastCreated := NewProc;   (* new is at top *)
      INC( NumberOfProc );
      INC( CurrentProc^.NDescen );
      InsertReady;
      CP := NewProc;
      TRANSFER( CurrentProc^.SP, CP^.SP );
      ASSERT( spTab[CurrentProc^.OrdNr] = Process(CurrentProc^.SP));
      IF CP^.Ended # NIL
      THEN
        ClearQueue( CP );
      END (* if CP *);
    END ActivateProcess;

  PROCEDURE Assert
            (    BooleanExp : BOOLEAN );
    (* If BooleanExp is FALSE calling process is haled and inserted into
       ErrorQueue with AssertError*)

  BEGIN
    IF NOT BooleanExp
    THEN
      CP^.ProcessStatus := AssertError;
      Broadcast( ErrorHandler );
      INC( NuOfErrorProc );
      WAITS( ErrorQueue );
    END (* if *);
  END Assert;

  BEGIN
    BlockClear(ADR(expInter), SIZE(expInter));
  END Scheduler;
  (* $S+*)
  (* $T+*)

  PROCEDURE STARTPROCESS
            (    P        : PROC;
                 N        : CARDINAL;
                 PRIORITY : PriorityDomain );

  VAR
    A             : ADDRESS;
    This          : ProcessPtr;
    New           : ProcessPtr;
    IntProcess    : Process;
    NewIntProcess : Process;
    PROCNR        : CARDINAL;

  BEGIN
    This := CP;
    WITH This^ DO
      IntProcess := Process( SP );
      PRIRTBitset := PRIRTBitset * { 0..MonitorBitNInt - 1 } + { MonitorBitNInt
                     } + IntProcess^.priorityMask * { MonitorBitLSB..
                     MonitorBitMSB };
      IF MaxRunTime < Time
      THEN
        MaxRunTime := Time;
        LongestProcess := CP;
      END (* if MaxRunTime *);
      Time := 0;
    END (* with *);
    NEW( New );
    ALLOCATE( A, N );
    (* fill workspace with const 0FFH *)
    SETREG( ES, A.SEGMENT );
    SETREG( DI, A.OFFSET );
    SETREG( CX, N );
    SETREG( AX, 0FFFFH );
    CODE( 0FCH, 0F3H, 0AAH );   (* CLD REP STOSB *)
    PROCNR:=1;
    WHILE (Statistic[PROCNR].id#PROC( 0FFFFH:0FFFFH )) AND (PROCNR<30) DO
      INC(PROCNR);
    END;
    WITH New^ DO
      Statistic[PROCNR].id := P;
      OrdNr := PROCNR;
      ProcessBody := P;
      ProcessStatus := Normal;
      PRIRT := 0FFFH (* - PRIORITY *);
      PRIRTBitset := PRIRTBitset +
                     This^.PRIRTBitset * { MonitorBitLSB.. MonitorBitMSB };
      INC( PRIORITY );
      MaxTime := PRIORITY;
      NEXT := NIL;
      INTRR := FALSE;
      WArea := A;
      Size := N;
      NDescen := 0;
      NextOnList := NIL;
      PreviousOnList := LastCreated;   (* new at previous *)
      Parent := This;
      Ended := NIL;
      Halted := FALSE;
      ExecuteAtEnd := NIL;
      Time := 0;
    END (* with This *);
    NEWPROCESS( P, A, N, New^.SP );
    NewIntProcess := Process( New^.SP );
    spTab[PROCNR] := NewIntProcess;
    NewIntProcess^.priorityMask := IntProcess^.priorityMask;
    ActivateProcess( This, New );
  END STARTPROCESS;

  (* $S=*)

  (* $T=*)

  (* $S-*)

  PROCEDURE PriorityDecrease
            (    ExitLoc : ADDRESS );

  VAR
    This       : ProcessPtr;
    IntProcess : Process;

  BEGIN
    (*.F- *)
    (*************************************
    | removing trts return address
    **************************************)
    CODE(08BH, 046H, 006H, (* mov ax,[bp+6] ; ip *)
         089H, 046H, 002H, (* mov [bp+2],ax      *)
         08BH, 046H, 008H, (* mov ax,[bp+8] ; cs *)
         089H, 046H, 004H  (* mov [bp+4],ax      *)
        );
    (*.F+ *)
    This := CP;
    WITH This^ DO
      IntProcess := Process( SP );
      PRIRTBitset := PRIRTBitset * { 0..MonitorBitNInt - 1 } + 
                     { MonitorBitNInt} + 
                     IntProcess^.priorityMask * MaxPriority;
      IF ReadyFirst = NIL
      THEN
        CP^.Time := 0;
      ELSE
        IF ( ( ReadyFirst^.PRIRT < CARDINAL( MaxPriority ) ) AND
           ( PRIRT > ReadyFirst^.PRIRT ) ) OR ( ( PRIRT >= CARDINAL(
           MaxPriority ) ) AND ( Time >= MaxTime ) )
        THEN
          IF MaxRunTime < Time
          THEN
            MaxRunTime := Time;
            LongestProcess := CP;
          END (* if MaxRunTime *);
          Time := 0;
          InsertReady;
          RemoveReady;
          TRANSFER( This^.SP, CP^.SP );
        END (* if *);
      END (* if ReadyFirst *);
    END (* with This *);
    CODE( 0FBH (* sti ; enabling interrupts *) )
  END PriorityDecrease;

  (* $S=*)

  PROCEDURE InitC
            ( VAR C : ProcessPtr );

  BEGIN
    C := NIL;
  END InitC;

  PROCEDURE InitS
            ( VAR S : ProcessPtr );

  BEGIN
    S := NIL;
  END InitS;

  PROCEDURE Release;

  VAR
    NullSignal : ProcessPtr;

  BEGIN
    IF ReadyFirst # NIL
    THEN
      NullSignal := NIL;
      SEND( NullSignal )
    END (* if ReadyFirst *);
  END Release;

  PROCEDURE StartTimeSlicing
            (    IntNu        : CARDINAL;
                 RecoveryTime : CARDINAL );

  BEGIN
    TimeIntNum := IntNu;
    MaxRecTime := RecoveryTime;
  END StartTimeSlicing;

  PROCEDURE RecoveryTime
            (    Time : CARDINAL );
    (* If process occupes processor longer then RecoveryTime it will be halted
       as erroneous.*)

  BEGIN
    MaxRecTime := Time;
  END RecoveryTime;

  PROCEDURE CurrentProcess( ) : ProcessPtr;
  BEGIN
    RETURN CP;
  END CurrentProcess;

  (* $S+*)

  (* $T+*)

  PROCEDURE InstallTermProc
            (    P : PROC );

  VAR
    t : TermProcListPtr;

  BEGIN
    WITH CP^ DO
      NEW( t );
      t^.AtProcessEnd := P;
      t^.NextOnList := ExecuteAtEnd;
      ExecuteAtEnd := t;
    END (* with *);
  END InstallTermProc;

  PROCEDURE RemoveTermProc;

  VAR
    t : TermProcListPtr;

  BEGIN
    WITH CP^ DO
      t := ExecuteAtEnd;
      ExecuteAtEnd := t^.NextOnList;
      DISPOSE( t );
    END (* with *);
  END RemoveTermProc;

  PROCEDURE EnterProtectedOp
            (    Deadline : CARDINAL );

  BEGIN
  END EnterProtectedOp;

  PROCEDURE ExitProtectedOp
            (    Deadline : CARDINAL );

  BEGIN
  END ExitProtectedOp;

  (* $S=*)

  (* $T=*)

  PROCEDURE CallTerminatingProcedures;
    (* execute procedures on list *)

  VAR
    ToDispose : TermProcListPtr;

  BEGIN
    WITH CP^ DO
      WHILE ExecuteAtEnd # NIL DO
        ExecuteAtEnd^.AtProcessEnd;
        ToDispose := ExecuteAtEnd;
        ExecuteAtEnd := ExecuteAtEnd^.NextOnList;
        DISPOSE( ToDispose );
      END (* while *);
    END (* with *);
  END CallTerminatingProcedures;

  (* $S-*)

  (* $T-*)

  (* $R-*)

  VAR
    VarDR    : DebuggerRecord;

  PROCEDURE Terminator
            (    p : PROCESS;
                 A : ADDRESS );
    (*.F- *)
(*------------------------------------------------------------------*)
(* we arrive here just before termination of process;               *)
(* eq. when error then from error location to RTS and next here;    *)
(* debuggers can't recognise valid call sequence, so we'll help     *)
(* entering additional dynamic link on the process stack just       *)
(* beneath return address of call to RTS ;                          *)
(*------------------------------------------------------------------*)
(*.F+ *)

  VAR
    tmpA : ADDRESS;
    
  BEGIN
    (*.F- *)
(*-----------------------------------------------------------*)
(********* do NOT place any break-point, stack is bad ********)
(*-----------------------------------------------------------*)
(*.F+ *)
    (* location just beneath IP (return address) on stack *)
    tmpA := ADR( activProcess^.topStack^.AX );
    (* mov [bp],ax ; make link from this proc. to inserted *)
    SETREG( AX, tmpA.OFFSET );
    CODE( 89H, 46H, 00H );
    (* ; make link from insertion to previous BP *)
    tmpA^ := WORD( activProcess^.topStack^.BP );
    (*.F- *)
(*-----------------------------------------------------------*)
(********* from here debugger can find call list *************)
(*-----------------------------------------------------------*)
(*.F+ *)
    ASSERT( activProcess^.checkWord = 0FA50H );
    ASSERT( ORD(activProcess^.progStatus) < ORD(MAX(Status)) );

    CP^.ProcessStatus := Status( activProcess^.progStatus );
    activProcess^.progStatus := RTSMain.Normal;
    IF (* ( CP^.ProcessStatus = Status( RTSMain.Normal ) ) OR 
        MP program glowny konczy caly program *)
       ( CP^.ProcessStatus = Status( RTSMain.CoroutineEnd ) )
    THEN
      CallTerminatingProcedures;
      STOPPROCESS;
    ELSIF CP^.ProcessStatus <= Status( RTSMain.Stopped )
    THEN
      ; (* allows debugger to terminate this program simply *)
    ELSE
      StopAError;
    END (* if *);
    TimeIntNum := MAXCARD;
    debuggerRecord.beforeTermProc := VarDR.beforeTermProc;
    IF CP^.ProcessStatus # Status( Normal ) THEN  
      (* jesli byl pmd to da o sobie znac *)
      activProcess^.progStatus := RTSMain.Stopped;
      RTSMain.Terminate(RTSMain.Stopped); 
    END;  
  END Terminator;

  (* $T=*)

  (* $S=*)

  (* $R=*)

  PROCEDURE InstallTerminator;

  BEGIN
    VarDR := debuggerRecord;
    debuggerRecord.beforeTermProc := Terminator;
  END InstallTerminator;

  PROCEDURE DUMMYPRO;

  BEGIN
    IF NumberOfProc - NuOfErrorProc = WaitForInt
    THEN
      Terminate( RTSMain.Stopped );
    END (* if NumberOfProc *);
    REPEAT
      WHILE ( ReadyFirst = NIL ) AND
            ( NumberOfProc - NuOfErrorProc # WaitForInt ) DO
      END (* while *);
      WAITS( DUMMY )
    UNTIL ( ReadyFirst = NIL ) AND ( WaitForInt = 0 );
  END DUMMYPRO;

  VAR
    Count    : CARDINAL;
    LastMask : BITSET;

BEGIN
  FOR Count := 0 TO 8 DO
    LastMask := GetPrioMask( Count );
    LastMask := LastMask / MaxPriority;
    SetPrioMask( Count, LastMask );
  END (* for *);
  FOR Count:=0 TO 30 DO
    Statistic[Count].id := PROC( 0FFFFH:0FFFFH );
    Statistic[Count].time := 0L;
    spTab[Count] := NIL;
  END;
  LongestProcess := NIL;
  MonitorExitProc := PROC( PriorityDecrease );
  MaxNumOfReady := 0;
  NumberOfProc := 1;
  NuOfReady := 0;
  NuOfErrorProc := 0;
  ErrorHandler := NIL;
  TSSInterval := 0FFFFH;
  MaxRunTime := 0H;
  MaxRecTime := 0FFFFH;
  InstallTerminator;
  TimeIntNum := MAXCARD;
  ReadyFirst := NIL;
  ReadyLast := NIL;
  DUMMY := NIL;
  ErrorQueue := NIL;
  WaitForInt := 0;
  WITH activProcess^ DO
    priorityMask := priorityMask + MaxPriority;
  END (* with *);
  NEW( CP );
  LastCreated := CP;
  Statistic[0].id := PROC( 0:0 );
  WITH CP^ DO
    OrdNr := 0;
    ProcessBody := PROC( 0:0 );   (* MAIN process mark *)
    SP := PROCESS(activProcess);
    spTab[0] := activProcess;
    PRIRT := 0FFFFH;
    ProcessStatus := Normal;
    NEXT := NIL;
    INTRR := FALSE;
    WArea := NIL;
    Size := 0;
    NDescen := 0;
    NextOnList := NIL;
    PreviousOnList := NIL;
    Parent := NIL;
    Ended := NIL;
    Halted := FALSE;
    ExecuteAtEnd := NIL;
    MaxTime := 01H;
    Time := 0;
  END (* with CP *);
  CODE( 0FBH );   (* STI *)
  STARTPROCESS( DUMMYPRO, ODUMMY, 0 );
END MANAGER.
