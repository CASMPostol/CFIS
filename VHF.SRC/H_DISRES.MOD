(*.F- *)
(**********************************************************************
|  Title   : Wyswietla rezultaty analizy dla VHF
|  Author  : M.Postol
|  System  : LOGITECH MODULA-2/86
|  History :
|    08-12-96: Created
|
|  Copyright (C), CAS LODZ POLAND.
|  TEL: 42' 862 547, 42' 87 80 44 FAX/TEL: 42' 84 48 40
|
**********************************************************************)
(*.F+ *)

IMPLEMENTATION MODULE H_DisResults;

  IMPORT
    DisResUtilities;

  FROM HiLevGraf IMPORT
    WrStr;

  FROM GrafTypes IMPORT
    YELLOW, LT_GREEN;

  FROM H_CommonTypes IMPORT
    ProceduraT;

  FROM SpecConv IMPORT
    Int2Str, ToStringProcT, Ang100Str36, Card500Str;

  FROM H_results IMPORT
    anRes, OdcinekNr;

  FROM DisResUtilities IMPORT
    WrS, Szerokosc, LineNumT;

  CONST
    delatKol = 160;  (* odleglosc pomiedzy kolumnami w tabelce *)

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
    WrStr("WYNIK ANALIZY DLA VHF",  NaglowekPX, lineH + 2, YELLOW, YELLOW);
    INC(lineH, Szerokosc);
    WrStr("Odcinek     ", 0, lineH, YELLOW, YELLOW);
    WrStr("Sygnaˆ min [uV]", 1 * delatKol, lineH, YELLOW,
           YELLOW);
    WITH anRes DO
      CASE procedure OF
        pOrbita :
          WrStr("Pocz¥tek [ø]", 2 * delatKol, lineH, YELLOW, YELLOW);
          WrStr("Koniec   [ø]", 3 * delatKol, lineH, YELLOW, YELLOW);
        |
        pPromien :
          WrStr("Pocz¥tek [NM]", 2 * delatKol, lineH, YELLOW, YELLOW);
          WrStr("Koniec   [NM]", 3 * delatKol, lineH, YELLOW, YELLOW);
      END (* case procedura *);
    END;
    INC(lineH, Szerokosc);
    WrStr("ODB A", 1 * delatKol, lineH, LT_GREEN, LT_GREEN);
  END WriteTab;

  PROCEDURE DispResults();
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
            Int2Str(SSmin.val, str, 5);
            WrS(str, line, delatKol);
            converP(INTEGER(pocz), str, 6);
            WrS(str, line, 2 * delatKol);
            converP(INTEGER(kon), str, 6);
            WrS(str, line, 3 * delatKol);
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

END H_DisResults.
