(*.F- *)
(**********************************************************************
|  Title   : Wyswietla rezultaty analizy dla DME
|  Author  : M.Postol
|  System  : LOGITECH MODULA-2/86
|  History :
|    09-12-96: M.Postol
|      zmiana w naglowku
|
|  Copyright (C), CAS LODZ POLAND.
|  TEL: 42' 862 547, 42' 87 80 44 FAX/TEL: 42' 84 48 40
|
**********************************************************************)
(*.F+ *)

IMPLEMENTATION MODULE D_DisResults;

  IMPORT
    DisResUtilities;

  FROM HiLevGraf IMPORT
    WrStr;

  FROM GrafTypes IMPORT
    RECT, YELLOW, BLUE, BROWN, LT_RED, LT_BLUE, GREEN, LT_GREEN, WHITE;

  FROM CommonTypes IMPORT
    GlownyOdbiornikT, OdnDlaPomBleduT;

  FROM D_CommonTypes  IMPORT
    ProceduraT;

  FROM SpecConv IMPORT
    Card500Str, Int100Str, Ang100Str36, ToStringProcT, Int2Str;

  FROM D_results IMPORT
    anRes, OdcinekNr;

  FROM DisResUtilities  IMPORT
    WrS, Szerokosc, WrSPlus, LineNumT, WrF_TablicaOdci;

  FROM FlagAnal IMPORT
    FlagsTable, F_TablicaOdci;

  CONST
    kolPT     = 32;  (* kolumna rozpoczecia wypisywania tekstu *)
    delatKol  = 800 DIV 7;  (* odleglosc pomiedzy kolumnami w tabelce *)

  PROCEDURE WriteTab
            (     phase : CARDINAL;
              VAR line  : LineNumT );

  CONST
    Szerokosc  = 16;
    NaglowekPX = 2 * 160;
  VAR
    lineH : CARDINAL;

  BEGIN
    DisResUtilities.WriteTab(lineH, line);
    CASE phase OF
      0 :
        WrStr(" TRWA INTERPOLACJA FAZA 1 z 3 ", NaglowekPX, lineH + 2, YELLOW, YELLOW);
      |
      1 :
        WrStr("TRWA ANALIZA DANYCH",            NaglowekPX, lineH + 2, YELLOW, YELLOW);
      |
      2 :
        WrStr("       GOTOWE      ", NaglowekPX, lineH + 2, YELLOW, YELLOW);
        INC(lineH, Szerokosc);
        WrStr("Odcinek     ", 0, lineH, YELLOW, YELLOW);
        WrStr("Sila syg min", 2 * delatKol - delatKol DIV 2, lineH, YELLOW,
              YELLOW);
        WrStr("Poczatek    ", 3 * delatKol, lineH, YELLOW, YELLOW);
        WrStr("Koniec      ", 4 * delatKol, lineH, YELLOW, YELLOW);
        INC(lineH, Szerokosc);
        WrStr("ODB A", 1 * delatKol, lineH, LT_GREEN, LT_GREEN);
        WrStr("ODB B", 2 * delatKol, lineH, LT_RED, LT_RED);
    END (* case phase *);
  END WriteTab;

  PROCEDURE DispResults
            (    GlownyOdbiornik : GlownyOdbiornikT;
                 OdnDlaPomBledu  : OdnDlaPomBleduT  );
  VAR
    line : CARDINAL;

    PROCEDURE WriteMod
              ( VAR line    : CARDINAL;
                    converP    : ToStringProcT );
    VAR
      rec    : GlownyOdbiornikT;
      str    : ARRAY [0 .. 50] OF CHAR;
      col    : CARDINAL;
      sektor : OdcinekNr;

    BEGIN (* WriteMod *)
      col := 0;
      WITH anRes DO
        IF a_IleOd = 0  THEN
          RETURN
        END;
        FOR sektor := 0 TO a_IleOd - 1 DO
          IF (line >= MAX( LineNumT ) - Szerokosc) THEN
            RETURN;
          END;
          Int2Str(sektor + 1, str, 4);
          WrS(str, line, col);
          WITH analiza[sektor] DO
            FOR rec := goA TO goB DO
              Int2Str(SSmin[rec].val, str, 5);
              WrS(str, line, delatKol + delatKol * ORD(rec));
            END (* for rec *);
            converP(INTEGER(pocz), str, 6);
            WrS(str, line, 3 * delatKol);
            converP(INTEGER(kon), str, 6);
            WrS(str, line, 4 * delatKol);
            INC(line, Szerokosc);
            (* WrSPlus('', line, 0); *)
            WrF_TablicaOdci("Zestawienie odcink¢w wyst¥pienia flagi SRC",
                             wykluczenia,
                             line, converP);
          END (* with analiza *);
        END (* for sektor *);
      END (* with anRes *);
    END WriteMod;

  BEGIN
    WriteTab(2, line);
    WITH anRes DO
      CASE procedure OF
        pOkragBlad, pOkragZakres :
          IF DMEforLOC  THEN
            WriteMod(line, Int100Str);
          ELSE
            WriteMod(line, Ang100Str36);
          END;
        |
        pPromienBlad, pPromienZakres :
          WriteMod(line, ToStringProcT(Card500Str));
      END (* case procedura *);
    END; (* WITH anRes *)
  END DispResults;

END D_DisResults.
