(*.F- *)
(**********************************************************************
|  Title   : Funkcje obslugi slupkow dla VHF
|  Author  : M.Postol
|  System  : LOGITECH MODULA-2/86
|  History :
|    08-12-96: created
|
|  Copyright (C), CAS LODZ POLAND.
|  TEL: 42' 862 547, 42' 87 80 44 FAX/TEL: 42' 84 48 40
|
**********************************************************************)
(*.F+ *)

IMPLEMENTATION MODULE H_Slupek;

  IMPORT
     SpecConv;

  FROM H_Odb IMPORT
    agc, audio_H;

  FROM CommonTypes IMPORT
    SlupekNr, GlownyOdbiornikT, SigNilVal;

  FROM Slupek IMPORT
    (* TYPE *) Baund;

  FROM SpecConv IMPORT
    Int10Str, Int100Str, Int2Str;

  FROM HiLevGraf IMPORT
    HDIB, LoadDIB, ShowDIB, CloseDIB;

  FROM GrafTypes IMPORT
    BLACK, GREEN, RED, WHITE, RECT, POINT;

  FROM HiLevGraf IMPORT
    Wr2StrXY;

  FROM ScreenCTypes  IMPORT
    SkalaWpionieOpis, RodzWykr;

  FROM Strings IMPORT
    ConstAssign;
  
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
    Int2Str(agc, str, 5);
    Wr2StrXY(str, 263+5, 90+10+600-160, GREEN, WHITE);   (* AGC *)
    IF audio_H  THEN
       Wr2StrXY('JEST', 263+5, 30+10+600-160, GREEN, WHITE);
    ELSE
       Wr2StrXY('BRAK', 263+5, 30+10+600-160, RED, WHITE);
    END;
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
  END  IniSkale;

  PROCEDURE InitSlupek;
  BEGIN
    cursorDIB :=  LoadDIB("kursor.dib");
    screeenDIB := LoadDIB('VHF.dib');
  END InitSlupek;

  PROCEDURE DoneSlupek;
  BEGIN
    CloseDIB(cursorDIB);
    CloseDIB(screeenDIB);
  END DoneSlupek;

BEGIN
  Init;
END H_Slupek.
