(*$S+*)
(*$T+*)
(*$R+*)
(**********************************************************************
|  Title   : Management and use of 'Chrono' objects.
|  Author  : M.Postol.
|  System  : LOGITECH MODULA-2/86 
|  Version : V.2.2.
|    23-05-97: M.Postol
|      bledy edycyjne w DurationToStr
|    Rel 3.0.MPostol
|      Godzina, Data zostaly przeniesione do HRD_Clock;
|
|  TEL: 42' 686 25 47
|  mailto: techsupp@cas.com.pl
|  http: www.cas.com.pl
|
**********************************************************************)
(*.F+ *)
IMPLEMENTATION MODULE Chronometer;

  FROM Strings     IMPORT Length, Concat;
  FROM Conversions IMPORT ConvertCardinal;
  FROM MANAGER     IMPORT Assert;
  FROM HRD_Clock   IMPORT Data;
  FROM Storage     IMPORT ALLOCATE, DEALLOCATE;

  CONST
    Active    = 31415;
    Created   = 61363;
    Destroyed = 11111;
  TYPE
    Time   = RECORD
                Y, M, D, H, Mn, S, S1000: CARDINAL;          
             END (* record *);
TYPE 
  Chrono = POINTER TO RECORD
                        Control     : CARDINAL;
                        StartTime   : Time;
                        ElapsedTime : Duration;
                      END; (* Chrono *)

PROCEDURE NewChrono (VAR chrono : Chrono);
BEGIN
  NEW (chrono);
  chrono^.Control := Created;
  ResetChrono(chrono);
END NewChrono;

PROCEDURE DisposeChrono (VAR chrono : Chrono);
BEGIN
  IF (chrono^.Control = Active) OR (chrono^.Control = Created) THEN
    chrono^.Control := Destroyed;
    DISPOSE (chrono);
    chrono := NIL;
  ELSE
    Assert(FALSE);
  END;
END DisposeChrono;

PROCEDURE ResetChrono (chrono : Chrono);
BEGIN
  IF (chrono^.Control = Active) OR (chrono^.Control = Created) THEN
    WITH chrono^.ElapsedTime DO
      Minute  := 0;
      Millisec:= 0;
    END (* with *);
    chrono^.Control := Created;
  ELSE
    Assert(FALSE);
  END;
END ResetChrono;

PROCEDURE StartChrono (chrono : Chrono);
BEGIN
  IF (chrono^.Control = Active) OR (chrono^.Control = Created) THEN
    chrono^.Control := Active;
    WITH chrono^.StartTime DO
      S1000 := 0;
      Data(Y, M, D, H, Mn, S);
    END;
  ELSE
    Assert(FALSE);
  END;
END StartChrono;

PROCEDURE DiffTime(EndTime, StartTime: Time; VAR Result: Duration);
VAR
    EndMin   : CARDINAL;
    StartMin : CARDINAL;
    EndSec   : CARDINAL;
    StartSec : CARDINAL;
BEGIN
  WITH Result DO
    WITH EndTime DO
      EndMin := H*60+Mn;
      EndSec := S*1000+S1000;
    END (* with *);
    WITH StartTime DO
      StartMin := H*60+Mn;
      StartSec := S*1000+S1000;
    END (* with *);
    IF (StartMin > EndMin) OR ((StartMin = EndMin) AND (StartSec > EndSec)) 
    THEN
      INC(EndMin, 60*24);
    END (* if *);
    IF StartSec > EndSec THEN
      Millisec := 60000 - (StartSec - EndSec);
      DEC(EndMin);
    ELSE
      Millisec := EndSec - StartSec;
    END (* if *);
    Minute := EndMin - StartMin;
  END (* with *);
END DiffTime;

PROCEDURE StopChrono (chrono : Chrono);
VAR
  EndTime : Time;
BEGIN
  IF (chrono^.Control = Active) THEN
    WITH chrono^ DO
      WITH EndTime DO
        S1000 := 0;
        Data(Y, M, D, H, Mn, S);
      END;
      DiffTime(EndTime, StartTime, ElapsedTime);
      chrono^.Control := Created;
    END (* with *);
  ELSIF (chrono^.Control <> Created) THEN
    Assert(FALSE);
  END;
END StopChrono;

PROCEDURE ReadChrono (    chrono : Chrono;
                      VAR ETime  : Duration);
VAR
  EndTime: Time;
BEGIN
  WITH chrono^ DO
    IF Control = Active THEN
      WITH EndTime DO
        S1000 := 0;
        Data(Y, M, D, H, Mn, S);
      END;
      DiffTime(EndTime, StartTime, ETime);
    ELSIF Control = Created THEN
      ETime := ElapsedTime;
    ELSE
      Assert(FALSE);
    END;
  END (* with *);
END ReadChrono;

PROCEDURE DurationToStr(Val: Duration; VAR Str: ARRAY OF CHAR);
VAR
    LocStr: ARRAY[0..10] OF CHAR;
BEGIN
  WITH Val DO
    ConvertCardinal(Minute,      7,  Str);
    Concat(Str, "'", Str);
    ConvertCardinal(Millisec DIV 1000, 2, LocStr);
    Concat(Str, LocStr, Str);
    Concat(Str, '.', Str);
    ConvertCardinal(Millisec MOD 1000, 0, LocStr);
    Assert((Length(LocStr) > 0) AND (Length(LocStr) < 4) );
    IF Length(LocStr) = 1 THEN
      Concat(Str, '00', Str);
    ELSIF Length(LocStr) = 2 THEN
      Concat(Str, '0', Str);
    END (* if *);
    Concat(Str, LocStr, Str);
    Concat(Str, '"', Str);
  END (* with *);
END DurationToStr;

END Chronometer.
