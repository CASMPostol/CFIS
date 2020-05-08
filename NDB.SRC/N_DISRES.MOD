(*.F- *)
(**********************************************************************
|  Title   : Wyswietla rezultaty analizy dla NDB
|  Author  : M.Postol
|  System  : LOGITECH MODULA-2/86
|  History :
|    11-12-96: created
|
|  Copyright (C), CAS LODZ POLAND.
|  TEL: 42' 862 547, 42' 87 80 44 FAX/TEL: 42' 84 48 40
|
**********************************************************************)
(*.F+ *)

IMPLEMENTATION MODULE N_DisResults;

  IMPORT
    DisResUtilities;

  FROM HiLevGraf IMPORT
    WrStr;

  FROM GrafTypes IMPORT
    YELLOW, LT_GREEN, LT_RED;

  FROM CommonTypes IMPORT
    GlownyOdbiornikT;

  FROM N_CommonTypes IMPORT
    ProceduraT;

  FROM SpecConv IMPORT
    Int2Str, ToStringProcT, Ang100Str36, Card500Str;

  FROM N_results IMPORT
    anRes, OdcinekNr;

  FROM DisResUtilities IMPORT
    WrS, Szerokosc, LineNumT;

  CONST
    delatKol = 160;  (* odleglosc pomiedzy kolumnami w tabelce *)

  PROCEDURE WriteTab
            (     phase : CARDINAL;
              VAR line  : LineNumT );

  CONST
    NaglowekPX = 40 + 2 * 160;
  VAR
    lineH : LineNumT;

  BEGIN
    DisResUtilities.WriteTab(lineH, line);
    WrStr("WYNIK ANALIZY DLA NDB", NaglowekPX, lineH + 2, YELLOW, YELLOW);
    INC(lineH, Szerokosc);
    WrStr("Odcinek     ", 0, lineH, YELLOW, YELLOW);
    WrStr("Sygnaˆ min [uV]", 6 * delatKol DIV 5, lineH, YELLOW, YELLOW);
    WITH anRes DO
      CASE procedure OF
        pOrbita :
          WrStr("Poczatek [ø]", 3 * delatKol, lineH, YELLOW, YELLOW);
          WrStr("Koniec   [ø]", 4 * delatKol, lineH, YELLOW, YELLOW);
        |
        pPromien :
          WrStr("Poczatek [NM]", 3 * delatKol, lineH, YELLOW, YELLOW);
          WrStr("Koniec   [NM]", 4 * delatKol, lineH, YELLOW, YELLOW);
      END (* case procedura *);
    END (* with anRes *);
    INC(lineH, Szerokosc);
    WrStr("ODB A", 1 * delatKol, lineH, LT_GREEN, LT_GREEN);
    WrStr("ODB B", 2 * delatKol, lineH, LT_RED, LT_RED);
  END WriteTab;

  PROCEDURE DispResults
            (    GlownyOdbiornik : GlownyOdbiornikT );
  VAR
    line : CARDINAL;

    PROCEDURE WriteMod
              ( VAR line    : CARDINAL;
                    converP : ToStringProcT );
    VAR
      str    : ARRAY [0 .. 50] OF CHAR;
      col    : CARDINAL;
      sektor : OdcinekNr;

    BEGIN (* WriteMod *)
      col := 0;
      WITH anRes DO
        IF a_IleOd = 0
        THEN
          RETURN
        END (* if a_IleOd *);
        FOR sektor := 0 TO a_IleOd - 1 DO
          IF (line >= MAX(LineNumT) - Szerokosc)
          THEN
            RETURN;
          END (* if *);
          Int2Str(sektor + 1, str, 4);
          WrS(str, line, col);
          WITH analiza[sektor] DO
            Int2Str(SSmin[goA].val, str, 5);
            WrS(str, line, delatKol);
            Int2Str(SSmin[goB].val, str, 5);
            WrS(str, line, 2 * delatKol);
            converP(INTEGER(pocz), str, 6);
            WrS(str, line, 3 * delatKol);
            converP(INTEGER(kon), str, 6);
            WrS(str, line, 4 * delatKol);
            INC(line, Szerokosc);
          END (* with analiza *);
        END (* for sektor *);
      END (* with anRes *);
    END WriteMod;

  BEGIN
    WriteTab(2, line);
    WITH anRes DO
      CASE procedure OF
        pOrbita :
          WriteMod(line, Ang100Str36);
        |
        pPromien :
          WriteMod(line, ToStringProcT(Card500Str));
      END (* case procedura *);
    END (* with anRes *);
  END DispResults;

END N_DisResults.
