(*.F- *)
(**********************************************************************
|  Title   : Funkcje obslugi slupkow dla VOR
|  Author  : M.Postol
|  System  : LOGITECH MODULA-2/86
|  History :
|    19-01-97:M.Postol
|      zmieniona poczatkowa skala dla %RPL
|
|  Copyright (C), CAS LODZ POLAND.
|  TEL: 42' 862 547, 42' 87 80 44 FAX/TEL: 42' 84 48 40
|
**********************************************************************)
(*.F+ *)

IMPLEMENTATION MODULE D_Slupek;

  IMPORT
    SpecConv;

  FROM D_Odb IMPORT
    Mem, distErr, Reply, Squitter, SSmin, Trace, DisI, Agc;

  FROM CommonTypes IMPORT
    SlupekNr, GlownyOdbiornikT;

  FROM Slupek IMPORT
    (* TYPE *) Baund;

  FROM SpecConv IMPORT
    Int10Str, Int2Str, Int500Str, Int100Str;

  FROM HiLevGraf IMPORT
    HDIB, LoadDIB, ShowDIB, CloseDIB, WrStrXY, Wr2StrXY;

  FROM GrafTypes IMPORT
    BLACK, GREEN, RED, WHITE, RECT, POINT;

  FROM ScreenCTypes IMPORT
    SkalaWpionieOpis, RodzWykr;

  FROM RTSMain IMPORT
    Terminate, Status;

  CONST
    spac5  = '     ';
    SRCFLG = "-SRC-";
    MEMFLG = "-MEM-";

  VAR
    screeenDIB : HDIB;  (* dolna czes ekranu *)
    cursorDIB  : HDIB;  (* obrazek pod kursorem *)


  PROCEDURE ShowScreenDIB
            (     Src        : RECT;
                  Dest       : POINT;
              VAR ScreeenDIB : HDIB  );

  BEGIN
    ScreeenDIB := screeenDIB;
    ShowDIB( screeenDIB, Src, Dest, TRUE );
  END ShowScreenDIB;


  PROCEDURE ShowCursorDIB
            (    Src  : RECT;
                 Dest : POINT );

  BEGIN
    ShowDIB( cursorDIB, Src, Dest, FALSE );
  END ShowCursorDIB;


  PROCEDURE UnverslVal
            (     slupek : SlupekNr;
                  rec    : GlownyOdbiornikT;
              VAR s      : ARRAY OF CHAR;
              VAR val    : INTEGER          );

  BEGIN
    CASE slupek OF
      SlLewy :
        val := distErr[rec];
        Int500Str( val, s, 5 ); |
      SlSrodkowy :
        val := Reply[rec];
        Int10Str( val, s, 5 ); |
      SlPrawy :
        val := Squitter[rec];
        Int2Str( val, s, 5 );
    END (* case slupek *);
  END UnverslVal;


  PROCEDURE Init;

  BEGIN
    parSlupkow[SlLewy, Min] := -150;
    parSlupkow[SlLewy, Max] := 150;
    parSlupkow[SlLewy, minAlarm] := -25;
    parSlupkow[SlLewy, maxAlarm] := 25;
    parSlupkow[SlSrodkowy, Min] := 0;
    parSlupkow[SlSrodkowy, Max] := 1000;
    parSlupkow[SlSrodkowy, minAlarm] := 0;
    parSlupkow[SlSrodkowy, maxAlarm] := 1000;
    parSlupkow[SlPrawy, Min] := 0;
    parSlupkow[SlPrawy, Max] := 3000;
    parSlupkow[SlPrawy, minAlarm] := 0;
    parSlupkow[SlPrawy, maxAlarm] := 3000;
  END Init;


  PROCEDURE NapiszSygnaly;

  VAR
    str : ARRAY [ 0 .. 10 ] OF CHAR;

  BEGIN
    IF Mem[goA]
    THEN
      WrStrXY( MEMFLG, 425, 564, GREEN, WHITE );
    ELSE
      WrStrXY( spac5, 425, 564, GREEN, WHITE );
    END (* if DME *);
    IF NOT Trace[goA]
    THEN
      str := SRCFLG;
      WrStrXY( str, 425, 542, GREEN, WHITE );
    ELSE
      WrStrXY( spac5, 425, 542, GREEN, WHITE );
      Int100Str( DisI[goA], str, 5 );
    END (* if *);
    WrStrXY( str, 260, 562, GREEN, WHITE );
    IF Mem[goB]
    THEN
      WrStrXY( MEMFLG, 545, 564, RED, WHITE );
    ELSE
      WrStrXY( spac5, 545, 564, RED, WHITE );
    END (* if DME *);
    IF NOT Trace[goB]
    THEN
      str := SRCFLG;
      WrStrXY( str, 545, 542, RED, WHITE );
    ELSE
      WrStrXY( spac5, 545, 542, RED, WHITE );
      Int100Str( DisI[goB], str, 5 );
    END (* if *);
    WrStrXY( str, 330, 562, RED, WHITE );
    Int2Str( Agc[goA], str, 5 );
    Wr2StrXY( str, 236, 491, GREEN, WHITE );
    Int2Str( Agc[goB], str, 5 );
    Wr2StrXY( str, 317, 491, RED, WHITE );
    Int2Str( SSmin[goA], str, 5 );
    WrStrXY( str, 425, 481, BLACK, WHITE );
    Int2Str( SSmin[goB], str, 5 );
    WrStrXY( str, 545, 481, BLACK, WHITE );
  END NapiszSygnaly;


  PROCEDURE IniSkale
            ( VAR skalaWpionie : SkalaWpionieOpis );

  BEGIN
    WITH skalaWpionie[WykMain] DO
      cecha := 2;
      mantysa := 10.0;
      magni := 1.0;
      convertProc := SpecConv.Int2Str;
      currOffset := -60.0;
      log := FALSE;
      poziom := 1;
    END (* with skalaWpionie *);
    WITH skalaWpionie[Wyk1] DO
      cecha := 5;
      mantysa := 10.0;
      magni := 100.0;
      convertProc := SpecConv.Int100Str;
      currOffset := 50.0;
      log := FALSE;
      poziom := 1;
    END (* with skalaWpionie *);
    WITH skalaWpionie[Wyk2] DO
      cecha := 1;
      mantysa := 100.0;
      magni := 10.0;
      convertProc := SpecConv.Int10Str;
      currOffset := 50.0;
      log := FALSE;
      poziom := 0;
    END (* with skalaWpionie *);
    WITH skalaWpionie[Wyk3] DO
      cecha := 2;
      mantysa := 1000.0;
      magni := 1.0;
      convertProc := SpecConv.Int2Str;
      currOffset := 1500.0;
      log := FALSE;
      poziom := 1;
    END (* with skalaWpionie *);
  END IniSkale;


  PROCEDURE InitSlupek;

  BEGIN
    cursorDIB := LoadDIB( "kursor.dib" );
    screeenDIB := LoadDIB( 'dodme1.dib' );
  END InitSlupek;


  PROCEDURE DoneSlupek;

  BEGIN
    CloseDIB( cursorDIB );
    CloseDIB( screeenDIB );
  END DoneSlupek;

BEGIN
  cursorDIB := HDIB( NIL );
  screeenDIB := HDIB( NIL );
  Init;
END D_Slupek.
