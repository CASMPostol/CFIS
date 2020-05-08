(*.F- *)
(**********************************************************************
|  Title   : Funkcje obslugi slupkow dla VOR
|  Author  : M.Postol
|  System  : LOGITECH MODULA-2/86
|  History :
|    17-02-97:M.Postol
|      zmiana kolorow wyswietlania
|
|  Copyright (C), CAS LODZ POLAND.
|  TEL: 42' 862 547, 42' 87 80 44 FAX/TEL: 42' 84 48 40
|
**********************************************************************)
(*.F+ *)

IMPLEMENTATION MODULE V_Slupek;

  FROM V_Odb IMPORT
    DEVMAX, DEVMIN, DEVAV, agc, var, ref, sub, navFlg, DEVVAL;

  FROM CommonTypes IMPORT
    SlupekNr, GlownyOdbiornikT;

  FROM Slupek IMPORT
    (* TYPE *) Baund;

  FROM SpecConv IMPORT
    Int10Str, Int100Str, Int2Str;

  FROM HiLevGraf IMPORT
    HDIB, LoadDIB, ShowDIB, CloseDIB, WrStrXY, Wr2StrXY;

  FROM GrafTypes IMPORT
    BLACK, GREEN, RED, WHITE, RECT, POINT;

  FROM ScreenCTypes  IMPORT
    SkalaWpionieOpis, RodzWykr;

  CONST
    SPFLG = "-FLG-";
  VAR
    screeenDIB       : HDIB;  (* dolna czes ekranu *)
    cursorDIB        : HDIB;  (* obrazek pod kursorem *)

  PROCEDURE ShowScreenDIB
            (    Src        : RECT;
                 Dest       : POINT;
             VAR ScreeenDIB : HDIB );

  BEGIN
    ScreeenDIB := screeenDIB;
    ShowDIB(screeenDIB, Src, Dest, TRUE);
  END ShowScreenDIB;

  PROCEDURE ShowCursorDIB
            (    Src        : RECT;
                 Dest       : POINT );

  BEGIN
    ShowDIB(cursorDIB, Src, Dest, FALSE);
  END ShowCursorDIB;

  PROCEDURE UnverslVal
            (     slupek : SlupekNr;
                  ChNR   : GlownyOdbiornikT;
              VAR s      : ARRAY OF CHAR;
              VAR val    : INTEGER          );

  BEGIN
    CASE slupek OF
      SlLewy :
        val := var[ChNR];
      |
      SlSrodkowy :
        val := ref[ChNR];
      |
      SlPrawy :
        val := sub[ChNR];
    END (* case slupek *);
    Int10Str(val, s, 5);
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
    IF navFlg[goA]
    THEN
      Int100Str(DEVVAL[goA], str, 5);   (* dev *)
    ELSE
      str := SPFLG;
    END (* if navFlg *);
    Wr2StrXY(str, 236, 491, GREEN, WHITE);
    IF navFlg[goB]
    THEN
      Int100Str(DEVVAL[goB], str, 5);
    ELSE
      str := SPFLG;
    END (* if NAV *);
    Wr2StrXY(str, 317, 491, RED, WHITE);
    Int2Str(agc[goA], str, 5);
    WrStrXY(str, 260, 542, GREEN, WHITE);   (* AGC *)
    Int2Str(agc[goB], str, 5);
    WrStrXY(str, 260, 564, RED, WHITE);
    Int100Str(DEVAV[goA], str, 5);   (* srednie dev *)
    WrStrXY(str, 425, 481, BLACK, WHITE);
    Int100Str(DEVAV[goB], str, 5);   (* srednie dev *)
    WrStrXY(str, 545, 481, BLACK, WHITE);
    Int100Str(DEVMAX[goA], str, 5);
    WrStrXY(str, 425, 542, BLACK, WHITE);
    Int100Str(DEVMAX[goB], str, 5);
    WrStrXY(str, 545, 542, BLACK, WHITE);   (* MAX. gora *)
    Int100Str(DEVMIN[goA], str, 5);
    WrStrXY(str, 425, 564, BLACK, WHITE);
    Int100Str(DEVMIN[goB], str, 5);
    WrStrXY(str, 545, 564, BLACK, WHITE);   (* MAX. dol *)
  END NapiszSygnaly;

  PROCEDURE IniSkale
            (VAR skalaWpionie : SkalaWpionieOpis);
  BEGIN
        WITH skalaWpionie[WykMain] DO
          cecha := 5;
          mantysa := 1.0;
          magni := 100.0;
          convertProc := Int100Str;
          currOffset := 0.0;
          log := FALSE;
          poziom := 1;
        END (* with skalaWpionie *);
        WITH skalaWpionie[Wyk1] DO
          cecha := 5;
          mantysa := 1.0;
          magni := 10.0;
          convertProc := Int10Str;
          currOffset := 30.0;
          log := FALSE;
          poziom := 1;
        END (* with skalaWpionie *);
        WITH skalaWpionie[Wyk2] DO
          cecha := 5;
          mantysa := 1000.0;
          magni := 1.0;
          convertProc := Int2Str;
          currOffset := 0.0;
          log := TRUE;
          poziom := 1;
        END (* with skalaWpionie *);
        WITH skalaWpionie[Wyk3] DO
          cecha := 5;
          mantysa := 1.0;
          magni := 10.0;
          convertProc := Int10Str;
          currOffset := 30.0;
          log := FALSE;
          poziom := 1;
        END (* with skalaWpionie *);
  END  IniSkale;

  PROCEDURE InitSlupek;
  BEGIN
    IF cursorDIB # HDIB(NIL) THEN
      HALT;
    END;
    cursorDIB :=  LoadDIB("kursor.dib");
    screeenDIB := LoadDIB('dowora1.dib');
  END InitSlupek;

  PROCEDURE DoneSlupek;
  BEGIN
    CloseDIB(cursorDIB);
    CloseDIB(screeenDIB);
  END DoneSlupek;

BEGIN
  cursorDIB := HDIB(NIL);
  screeenDIB := HDIB(NIL);
  Init;
END V_Slupek.



