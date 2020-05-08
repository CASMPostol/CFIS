MODULE TstTeo;

FROM Graphics IMPORT
  _Wr2fStrXY;
FROM GrafTypes IMPORT
  WHITE, BLACK;
FROM SpecConv IMPORT
  Int100Str;
IMPORT
    DebugPMD, DOSEntry, Timer;

  FROM FIO IMPORT
    Close, Create, Open, Write, Read, Delete, Rename, CD, GetDir, Length, 
    MkDir;
  
  FROM MANAGER IMPORT
    Assert;
  
  FROM TheodolitRead IMPORT
    GetTheoI, DtaSignType, GetCurrDataSign;

  FROM SYSTEM  IMPORT ADR, SIZE;

  VAR
    dtaSign  : DtaSignType;
    azymut   : INTEGER;
    elewacja : INTEGER;
    outLoop  : Timer.Metronome;
    clicks   : CARDINAL;
    file     : CARDINAL;
    str      : ARRAY[0..80] OF CHAR;
    CONST
      tstCount = 3;
BEGIN
  Timer.NewMetronome( outLoop,  Timer.TInOneSecond() DIV tstCount);(* 200 *)
  file := Create('TST_TEO.DAT');
  dtaSign := GetCurrDataSign();
  LOOP 
    GetTheoI(dtaSign, azymut, elewacja);
    Timer.WaitMetronome( outLoop, clicks, Timer.TInOneSecond() DIV tstCount );(* 200 *)

    Assert(Write(file, ADR(azymut), SIZE(azymut)));
    
    _Wr2fStrXY( "Azymuth:", 0, 0, WHITE, BLACK );
    Int100Str(azymut, str, 7);
    _Wr2fStrXY( str,      300, 0, WHITE, BLACK );
    
    _Wr2fStrXY( "Elevation:", 0, 50, WHITE, BLACK );
    Int100Str(elewacja, str, 7);
    _Wr2fStrXY( str, 300, 50, WHITE, BLACK );
    
  END (* loop *);
  Close(file);
  Assert(FALSE);
END TstTeo.
