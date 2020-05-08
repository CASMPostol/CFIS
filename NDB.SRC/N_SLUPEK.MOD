(*.F- *)
(**********************************************************************
|  Title   : Funkcje obslugi slupkow dla NDB
|  Author  : M.Postol
|  System  : LOGITECH MODULA-2/86
|  History :
|    12-12-96: created
|
|  Copyright (C), CAS LODZ POLAND.
|  TEL: 42' 862 547, 42' 87 80 44 FAX/TEL: 42' 84 48 40
|
**********************************************************************)
(*.F+ *)

IMPLEMENTATION MODULE N_Slupek;

  IMPORT
     SpecConv;

  FROM N_Odb IMPORT
    DEVMAX, DEVMIN, DEVAV, DEVVAL, agc, berN;

  FROM CommonTypes IMPORT
    SlupekNr, GlownyOdbiornikT, SigNilVal;

  FROM Slupek IMPORT
    (* TYPE *) Baund;

  FROM SpecConv IMPORT
    Int10Str, Int100Str, Int2Str, Ang100Str36;

  FROM HiLevGraf IMPORT
    HDIB, LoadDIB, ShowDIB, CloseDIB, WrStrXY, Wr2StrXY;

  FROM GrafTypes IMPORT
    BLACK, GREEN, RED, WHITE, RECT, POINT;

  FROM ScreenCTypes  IMPORT
    SkalaWpionieOpis, RodzWykr;

  FROM Strings IMPORT
    ConstAssign;
  
  VAR
    screeenDIB       : HDIB;  (* dolna czes ekranu *)
    cursorDIB        : HDIB;  (* obrazek pod kursorem *)

  PROCEDURE ShowScreenDIB
            (    Src        : RECT;
                 Dest       : POINT;
             VAR ScreeenDIB : HDIB );

  BEGIN
    ScreeenDIB := screeenDIB;
    ShowDIB(screeenDIB, Src, Dest, TRUE );
  END ShowScreenDIB;

  PROCEDURE ShowCursorDIB
            (    Src        : RECT;
                 Dest       : POINT );

  BEGIN
    ShowDIB(cursorDIB, Src, Dest, FALSE );
  END ShowCursorDIB;

  PROCEDURE UnverslVal
            (     slupek : SlupekNr;
                  ChNR   : GlownyOdbiornikT;
              VAR s      : ARRAY OF CHAR;
              VAR val    : INTEGER          );

  BEGIN
    val := SigNilVal;
    ConstAssign('', s);
  END UnverslVal;
    
  PROCEDURE Init;

  BEGIN
    parSlupkow[SlLewy, Min] := 250;
    parSlupkow[SlLewy, Max] := 350;
    parSlupkow[SlLewy, minAlarm] := 280;
    parSlupkow[SlLewy, maxAlarm] := 320;
    parSlupkow[SlSrodkowy, Min] := 130;
    parSlupkow[SlSrodkowy, Max] := 190;
    parSlupkow[SlSrodkowy, minAlarm] := 150;
    parSlupkow[SlSrodkowy, maxAlarm] := 170;
    parSlupkow[SlPrawy, Min] := 250;
    parSlupkow[SlPrawy, Max] := 350;
    parSlupkow[SlPrawy, minAlarm] := 280;
    parSlupkow[SlPrawy, maxAlarm] := 320;
  END Init;

  PROCEDURE NapiszSygnaly;
  VAR
    str : ARRAY [0 .. 10] OF CHAR;

  BEGIN
    Int100Str(DEVVAL[goA], str, 5);   (* dev *)
    Wr2StrXY(str, 236, 491, GREEN, WHITE);
    Int100Str(DEVVAL[goB], str, 5);
    Wr2StrXY(str, 317, 491, RED, WHITE);

    Ang100Str36(berN[goA], str, 5);   (* dev *)
    Wr2StrXY(str, 36, 491, GREEN, WHITE);
    Ang100Str36(berN[goB], str, 5);
    Wr2StrXY(str, 117, 491, RED, WHITE);

    Int2Str(agc[goA], str, 5);
    WrStrXY(str, 260, 542, GREEN, WHITE);   (* AGC *)
    Int2Str(agc[goB], str, 5);
    WrStrXY(str, 260, 564, RED, WHITE);
    Int100Str(DEVAV[goA], str, 5);   (* srednie dev *)
    WrStrXY(str, 425, 481, GREEN, WHITE);
    Int100Str(DEVAV[goB], str, 5);   (* srednie dev *)
    WrStrXY(str, 545, 481, RED, WHITE);
    Int100Str(DEVMAX[goA], str, 5);
    WrStrXY(str, 425, 542, GREEN, WHITE);
    Int100Str(DEVMAX[goB], str, 5);
    WrStrXY(str, 545, 542, RED, WHITE);   (* MAX. gora *)
    Int100Str(DEVMIN[goA], str, 5);
    WrStrXY(str, 425, 564, GREEN, WHITE);
    Int100Str(DEVMIN[goB], str, 5);
    WrStrXY(str, 545, 564, RED, WHITE);   (* MAX. dol *)
  END NapiszSygnaly;

  PROCEDURE IniSkale
            (VAR skalaWpionie : SkalaWpionieOpis);
  BEGIN
    WITH skalaWpionie[WykMain] DO
      cecha := 5;
      mantysa := 1000.0;
      magni := 1.0;
      convertProc := SpecConv.Int2Str;
      currOffset := 0.0;
      log := TRUE;
      poziom := 1;
    END (* with skalaWpionie *);
    WITH skalaWpionie[Wyk1] DO
      cecha := 5;
      mantysa := 1.0;
      magni := 100.0;
      convertProc := Int100Str;
      currOffset := 0.0;
      log := FALSE;
      poziom := 1;
    END (* with skalaWpionie *);
  END  IniSkale;

  PROCEDURE InitSlupek;
  BEGIN
    cursorDIB :=  LoadDIB("kursor.dib");
    screeenDIB := LoadDIB('ndb.dib');
  END InitSlupek;

  PROCEDURE DoneSlupek;
  BEGIN
    CloseDIB(cursorDIB);
    CloseDIB(screeenDIB);
  END DoneSlupek;

BEGIN
  Init;
END N_Slupek.
