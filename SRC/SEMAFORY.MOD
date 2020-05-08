(*.F- *)
(**********************************************************************
|  Title   : Implementacja semaforow
|  Author  : M.Morawski
|  System  : LOGITECH MODULA-2/86
|  History :
|    25-06-96: M.Postol
|      Kardynalny blad - Condition tu sie kompletnie nie nadaje- puszczasz
|      proces, jest gotowy, ale inny tez, aktualny wychodzi z monitora i sa
|      dwa, z ktorych jeden wie, za semafor jest jego, a szeregowany jest
|      wlasnie drugi i co - blady trup
|
|  Copyright (C), CAS LODZ POLAND.
|  TEL: 42' 862 547, 42' 87 80 44 FAX/TEL: 42' 84 48 40
|
**********************************************************************)
(*.F+ *)

IMPLEMENTATION MODULE Semafory [ 8 ];

  FROM SYSTEM IMPORT
    ADR;

  FROM MANAGER IMPORT
    WAITC, WAITS, InitS, SEND, STARTPROCESS, ErrorHandler, ErrorQueue,
    ProcessPtr, CurrentProcess, Assert;

  CONST
    Alive = 31415;
    Dead  = 27182;

  TYPE
    SemaforPtr =
      POINTER TO Semafor;

  VAR
    TablicaSemaforow : ARRAY [0 .. 20] OF SemaforPtr;

  PROCEDURE Set
            ( VAR s : Semafor );
  VAR
    owner : ProcessPtr;

  BEGIN
    Assert(s.activity = Alive);
    owner := CurrentProcess();
    WITH s DO
      IF (Lock # 0) & (owner # Owner)
      THEN
        WAITS(SemaforWolny);
        Assert(s.Lock = 0);
        INC(Lock);
      ELSE
        INC(Lock);
      END (* if *);
      Owner := owner;
    END (* with s *);
  END Set;

  PROCEDURE Free
            ( VAR s : Semafor );

  BEGIN
    Assert(s.activity = Alive);
    WITH s DO
      Assert(s.Lock > 0);
      DEC(Lock);
      IF Lock = 0
      THEN
        Owner := NIL;
        SEND(SemaforWolny)
      END (* if Lock *);
    END (* with s *);
  END Free;

  PROCEDURE Register
            ( VAR sm : Semafor );
  VAR
    i : CARDINAL;

  BEGIN
    i := 0;
    (* $R+,T+*)   (* ma sie wywalic jakby bylo za duzo semaforow *)
    WHILE (TablicaSemaforow[i] # NIL) DO
    (* $R=,T=*)
      INC(i);
    END (* while *);
    TablicaSemaforow[i] := ADR(sm);
  END Register;

  PROCEDURE Init
            ( VAR s : Semafor );

  BEGIN
    WITH s DO
      InitS(SemaforWolny);
      Lock := 0;;
      Owner := CurrentProcess();
      activity := Alive;
    END (* with s *);
    Register(s);
  END Init;

  PROCEDURE Unregister
            ( VAR sm : Semafor );
  VAR
    i : CARDINAL;

  BEGIN
    Assert(sm.activity = Alive);
    sm.activity := Dead;
    i := 0;
    (* $R+,T+*)   (* ma sie wywalic jakby bylo za duzo semaforow *)
    WHILE (TablicaSemaforow[i] # ADR(sm)) DO
    (* $R=,T=*)
      INC(i);
    END (* while *);
    TablicaSemaforow[i] := NIL;
  END Unregister;

  PROCEDURE ExceptionHandler;
  VAR
    i : CARDINAL;
    a : ProcessPtr;

  BEGIN
    LOOP
      WAITC(ErrorHandler);
      a := ErrorQueue;
      WHILE a # NIL DO
        FOR i := 0 TO HIGH(TablicaSemaforow) DO
          IF TablicaSemaforow[i] # NIL
          THEN
            WITH TablicaSemaforow[i]^ DO
              IF a = Owner
              THEN
                Lock := 0;
                SEND(SemaforWolny);
              END (* if a *);
            END (* with TablicaSemaforow *);
          END (* if TablicaSemaforow *);
        END (* for i *);
        a := a^.NEXT;
      END (* while a *);
    END (* loop *);
  END ExceptionHandler;

  PROCEDURE InitTbl();
  VAR
    i : CARDINAL;

  BEGIN
    FOR i := 0 TO HIGH(TablicaSemaforow) DO
      TablicaSemaforow[i] := NIL;
    END (* for i *);
  END InitTbl;

BEGIN
  InitTbl;
  (* STARTPROCESS( ExceptionHandler, 400H, 0 ); *)
END Semafory.
