MODULE TstGeo;

FROM HiLevGraf IMPORT
  Wr2fStrXY;
FROM GrafTypes IMPORT
  WHITE, BLACK;
FROM SpecConv IMPORT
  Int100Str;
FROM CommonTypes IMPORT
  PolozenieGeo;
FROM StdIO IMPORT
  sprintf;
IMPORT
    DebugPMD, DOSEntry, Timer;

  FROM FIO IMPORT
    Close, Create, Open, Write, Read, Delete, Rename, CD, GetDir, Length,
    MkDir;

  FROM MANAGER IMPORT
    Assert;

  FROM GPSRead IMPORT
    GPSReceive, StanGPS, StanyGPS;

  FROM SYSTEM  IMPORT ADR, SIZE;

  VAR
    outLoop  : Timer.Metronome;
    clicks   : CARDINAL;
    str      : ARRAY[0..80] OF CHAR;
    pg       : PolozenieGeo;
    gdop,
    nos,
    epe      : CARDINAL;
  CONST
    tstCount = 7;
BEGIN
  Timer.NewMetronome( outLoop,  Timer.TInOneSecond() DIV tstCount);(* 200 *)
  LOOP
    Timer.WaitMetronome( outLoop, clicks, Timer.TInOneSecond() DIV tstCount );(* 200 *)
    IF GPSReceive( pg, gdop, nos, epe ) = StanGPS{SaNoweDane} THEN
      sprintf( str, "%d.%02d.%02dE %d.%02d.%02dN   ", pg );
    ELSE
      str := '************';
    END;
    Wr2fStrXY( str, 0, 0, WHITE, BLACK );
  END (* loop *);
  Assert(FALSE);
END TstGeo.
