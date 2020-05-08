(*.F- *)
(**********************************************************************
|  Title   : Wyswietla rezultaty analizy dla DME
|  Author  : M.Postol
|  System  : LOGITECH MODULA-2/86
|  History :
|    28-01-97: M.Postol
|      nieistotne edycje
|    15-06-97: M.Postol
|      wykreslilem % dla REF
|
|  Copyright (C), CAS LODZ POLAND.
|  TEL: 42' 862 547, 42' 87 80 44 FAX/TEL: 42' 84 48 40
|
**********************************************************************)
(*.F+ *)

IMPLEMENTATION MODULE V_DisResults;

  IMPORT
    DisResUtilities, StdIO;

  FROM DisResUtilities IMPORT
    ColNumT, LineNumT, WrSPlus, WrF_TablicaOdci;

  FROM GrafTypes IMPORT
    RECT, YELLOW, RED, BLUE, BROWN, LT_RED, LT_BLUE, GREEN, LT_GREEN, WHITE;

  FROM CommonTypes IMPORT
    GlownyOdbiornikT, OdnDlaPomBleduT, GetRecName;

  FROM SpecConv IMPORT
    Int100Str, Int2Str, Int10Str, Ang100Str36, Card500Str, ToStringProcT;

  FROM V_results IMPORT
    Parametr, anRes, Signals;

  FROM HiLevGraf IMPORT
    WrStrXY;

  FROM Strings  IMPORT
    Concat, Length;

  FROM V_CommonTypes IMPORT
    ProceduraT;

  FROM FlagAnal IMPORT
    FlagsTable, OdcinekNr, F_TablicaOdci;

  FROM SYSTEM IMPORT
    ADDRESS, ADR;

  CONST
    kolSN    = 2 * 160 + 30;  (* kolumna srodkowych napisow *)
    kolPT    = 32;  (* kolumna rozpoczecia wypisywania tekstu *)
    deltaKol = 160;  (* odleglosc pomiedzy kolumnami w tabelce *)
    NameStrL = 15;

  TYPE
    colRec =
      ARRAY GlownyOdbiornikT OF ColNumT;
    colRef =
      ARRAY OdnDlaPomBleduT OF colRec;
  VAR
    colPos : colRef;

  PROCEDURE WriteTab
            (     phase : CARDINAL;
              VAR line  : LineNumT );

  CONST
    Szerokosc  = 16;
    NaglowekPX = 40 + 2 * 160;

  VAR
    lineH : LineNumT;

  BEGIN
    DisResUtilities.WriteTab(lineH, line);
    CASE phase OF
      0 :
        WrStrXY("TRWA ANALIZA DANYCH Z POMIARU", NaglowekPX, lineH + 2,
                BROWN, BROWN);
      |
      2 :
        WrStrXY("WYNIKI DLA VOR GOTOWE", NaglowekPX, lineH + 2,
                BROWN, BROWN);
        WrStrXY("TEO", 11 * 8 + 40, lineH + 2, YELLOW, YELLOW);
        WrStrXY("GPS", 11 * 8 + 40 + 3 * 160, lineH + 2, YELLOW, YELLOW);
        WrStrXY("ODB A", colPos[pbTeodolit, goA],
                lineH + Szerokosc * 4 DIV 3,
                LT_GREEN, LT_GREEN);
        WrStrXY("ODB B", colPos[pbTeodolit, goB],
                 lineH + Szerokosc * 4 DIV 3,
                 LT_RED, LT_RED);
        WrStrXY("ODB A", colPos[pbGPS, goA],
                lineH + Szerokosc * 4 DIV 3,
                LT_GREEN, LT_GREEN);
        WrStrXY("ODB B", colPos[pbGPS, goB],
                 lineH + Szerokosc * 4 DIV 3,
                 LT_RED, LT_RED);
    END (* case phase *);
  END WriteTab;

  PROCEDURE DispResults
            (    GlownyOdbiornik : GlownyOdbiornikT;
                 OdnDlaPomBledu  : OdnDlaPomBleduT  );
  VAR
    line : CARDINAL;

    PROCEDURE WriteBends
              ( VAR line : CARDINAL );
    VAR
      rec      : GlownyOdbiornikT;
      ref      : OdnDlaPomBleduT;
      saveline : CARDINAL;
      str      : ARRAY [0 .. 50] OF CHAR;
      id       : Parametr;

    BEGIN
      WrSPlus("", line, kolSN);
      saveline := line;
      WrSPlus("Wyz©bienia   [ø]", line, kolSN);
      WrSPlus("Ugi©cie Max  [ø]", line, kolSN);
      WrSPlus("Ugi©cie Min  [ø]", line, kolSN);
      WrSPlus("Pol Lewo     [ø]", line, kolSN);
      WrSPlus("Pol Prawo    [ø]", line, kolSN);
      FOR ref := pbTeodolit TO pbGPS DO
        FOR rec := goA TO goB DO
          line := saveline;
          FOR id := FAL TO PolPrawo DO
            str := '*****';
            Int100Str(anRes.devDet[id, ref, rec].val, str, 5);
            WrSPlus(str, line, colPos[ref, rec]);
          END (* for id *);
        END (* for rec *);
      END (* for ref *);
    END WriteBends;

    PROCEDURE WriteDev
              ( VAR line : CARDINAL );
    VAR
      rec      : GlownyOdbiornikT;
      ref      : OdnDlaPomBleduT;
      saveline : CARDINAL;
      str      : ARRAY [0 .. 50] OF CHAR;
      id       : Parametr;

    BEGIN
      WrSPlus("", line, kolSN);
      saveline := line;
      WrSPlus("—redni bˆ¥d [ ø]", line, kolSN);
      WrSPlus("Max  + bˆ¥d [ ø]", line, kolSN);
      WrSPlus("Max  - bˆ¥d [ ø]", line, kolSN);
      FOR ref := pbTeodolit TO pbGPS DO
        FOR rec := goA TO goB DO
          line := saveline;
          Int100Str(anRes.devDet[AV, ref, rec].val, str, 5);
          WrSPlus(str, line, colPos[ref, rec]);
          FOR id := MP TO MM DO
            str := '*****';
            Int100Str(anRes.devDet[id, ref, rec].val, str, 5);
            WrSPlus(str, line, colPos[ref, rec]);
          END (* for id *);
        END (* for rec *);
      END (* for ref *);
    END WriteDev;

    PROCEDURE WriteMod
              ( VAR line : CARDINAL );
    VAR
      rec      : GlownyOdbiornikT;
      sign     : Signals;
      saveline : CARDINAL;
      str      : ARRAY [0 .. 50] OF CHAR;

    BEGIN (* WriteMod *)
      WrSPlus("", line, kolSN);
      saveline := line;
      WrSPlus("Minimum VAR [ %]", line, kolSN);
      WrSPlus("—redni  VAR [ %]", line, kolSN);
      WrSPlus("Minimum REF     ", line, kolSN);
      WrSPlus("—redni  REF     ", line, kolSN);
      WrSPlus("Minimum SUB [ %]", line, kolSN);
      WrSPlus("—redni  SUB [ %]", line, kolSN);
      WrSPlus("Minimum SYG [uV]", line, kolSN);
      FOR rec := goA TO goB DO
        line := saveline;
        FOR sign := Var TO Sub DO
          WITH anRes.signalGen[MM, sign, rec] DO
            Int10Str(val, str, 5);
            WrSPlus(str, line, colPos[pbTeodolit, rec]);
          END (* with anRes.signalGen *);
          WITH anRes.signalGen[AV, sign, rec] DO
            Int10Str(val, str, 5);
            WrSPlus(str, line, colPos[pbTeodolit, rec]);
          END (* with anRes.signalGen *);
        END (* for sign *);
        WITH anRes.signalGen[MM, Agc, rec] DO
          Int2Str(val, str, 5);
          WrSPlus(str, line, colPos[pbTeodolit, rec]);
        END (* with anRes.signalGen *);
      END (* for rec *);
    END WriteMod;

    PROCEDURE WriteDevOrbit
              ( VAR line : CARDINAL;
                    ref  : OdnDlaPomBleduT  );

    VAR
      idx1    : CARDINAL;
      idx2    : CARDINAL;
      str     : ARRAY [0 .. 12 ] OF CHAR;
      lineStr : ARRAY [0 .. 100] OF CHAR;

    BEGIN
      WrSPlus('', line, 0);
      IF ref = pbTeodolit  THEN
        WrSPlus(" Zestawienie bl©d¢w na okr©gu dla teodolitu", line, kolPT);
      ELSE
        WrSPlus(" Zestawienie bl©d¢w na okr©gu dla GPS", line, kolPT);
      END;
      WITH anRes  DO
        FOR idx2 := 0 TO 8 DO
          lineStr := '';
          FOR idx1 := 0 TO 3 DO
            Int2Str((idx1 * 9 + idx2)*10, str, 4);
            Concat(lineStr, str, lineStr);
            Concat(lineStr, "ø   ", lineStr);
            Int100Str(DevOrbit[ref, goA,  idx1 * 9 + idx2], str, 5);
            Concat(lineStr, str, lineStr);
            Concat(lineStr, "   ", lineStr);
            Int100Str(DevOrbit[ref, goB,  idx1 * 9 + idx2], str, 5);
            Concat(lineStr, str, lineStr);
            Concat(lineStr, "   ", lineStr);
          END;
          WrSPlus(lineStr, line, colPos[pbTeodolit, goA]);
        END;
      END;
    END WriteDevOrbit;

    PROCEDURE WriteFlgAndLowSignal
              ( VAR line       : CARDINAL;
                    converP    : ToStringProcT);
    BEGIN
      WITH anRes DO
        WrSPlus('', line, 0);
        WrF_TablicaOdci("Zestawienie odcink¢w dla SYG < 5 uV", lowSigTab, 
                         line, converP); 
        WrSPlus('', line, 0);
        WrF_TablicaOdci("Zestawienie odcink¢w wyst¥pienia flagi", flagTab, 
                         line, converP);
      END;
    END WriteFlgAndLowSignal;
  VAR
     promANieOr : BOOLEAN;
  BEGIN
    WriteTab(2, line);
    WriteDev(line);
    WriteMod(line);
    WITH anRes DO
      CASE procedure OF
        pOkragBlad, pOkragZakres :
          promANieOr := FALSE;
          WriteDevOrbit(line, OdnDlaPomBledu);
          WriteFlgAndLowSignal(line, Ang100Str36);
        |
        pPromienBlad, pPromienZakres :
          promANieOr := TRUE;
          WriteBends(line);
          WriteFlgAndLowSignal(line, ToStringProcT(Card500Str) );
      END (* case procedura *);
    END;
  END DispResults;

BEGIN
  colPos[pbTeodolit, goA] := kolPT;
  colPos[pbTeodolit, goB] := kolPT + deltaKol;
  colPos[pbGPS, goA] := kolPT + 3 * deltaKol;
  colPos[pbGPS, goB] := colPos[pbGPS, goA] + deltaKol;
END V_DisResults.
