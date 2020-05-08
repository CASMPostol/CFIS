(*.F- *)
(**********************************************************************
|  Title   : Rezultaty analizy dla DME
|  Author  : M.Postol
|  System  : LOGITECH MODULA-2/86
|  History :
|    13-11-96: M.Postol
|      field version added.
|    12-05-97: M.Postol
|      zmiana sposobu sprawdzania wersji
|
|  Copyright (C), CAS LODZ POLAND.
|  TEL: 42' 862 547, 42' 87 80 44 FAX/TEL: 42' 84 48 40
|
**********************************************************************)
(*.F+ *)

IMPLEMENTATION MODULE D_results;

  FROM Files  IMPORT
    DateKind, SaveAResult, LoadAResult;

  FROM SYSTEM IMPORT
    WORD;

  FROM CommonTypes IMPORT
    GlownyOdbiornikT, NilValI, NilValC, TimeAndDate, OdnDlaPomOdlT,
    NadajnikT, Version;

  FROM D_CommonTypes IMPORT
    ProceduraT;

  FROM Czas IMPORT
    Data, Godzina;

  FROM Strings IMPORT
    Assign;

  FROM FlagAnal IMPORT
    InitFlagErr;

  FROM MsgBox IMPORT
    Info;

  CONST
    Pomiar      = TRUE;

  VAR
    currDT : TimeAndDate;
    sec    : CARDINAL;

  PROCEDURE SaveAnRes
            (    res : AnalizaDsc );
  BEGIN
    SaveAResult(res, Analiza, Pomiar);
  END SaveAnRes;

  PROCEDURE GetAnRes
            ( VAR res : AnalizaDsc ): BOOLEAN;
  VAR
    void : BOOLEAN;

  BEGIN
    IF NOT LoadAResult(res, Analiza, Pomiar, LastChanged_anRes_Ver, Version)  THEN
      Init(anRes, ' ', ' ', ' ', currDT, MIN(ProceduraT), 0,
           MIN(OdnDlaPomOdlT), MIN(GlownyOdbiornikT), MIN(NadajnikT),
           MIN(NadajnikT), 0.0, 1013.0);
      RETURN FALSE;
    END;
    RETURN TRUE;
  END GetAnRes;

  PROCEDURE Init
            ( VAR anRes                    : AnalizaDsc;
                  currNazwaOblotu          : ARRAY OF CHAR;
                  currNazwa                : ARRAY OF CHAR;
                  currNazwa2               : ARRAY OF CHAR;
                  currData                 : TimeAndDate;
                  currProcedure            : ProceduraT;
                  currPromienLubOrbita     : WORD;
                  currOdnDlaPomOdl         : OdnDlaPomOdlT;
                  currglownyOdbiornik      : GlownyOdbiornikT;
                  currNadajnik1            : NadajnikT;
                  currNadajnik2            : NadajnikT;
                  currPredkosc             : REAL;
                  currCisnienieOdniesienia : REAL );
  VAR
    sek  : OdcinekNr;
    rec  : GlownyOdbiornikT;

  BEGIN
    WITH anRes DO
      version := Version;
      Assign(currNazwaOblotu, NazwaInsp);
      Assign(currNazwa, Nazwa);
      Assign(currNazwa2, Nazwa2);
      data := currData;
      procedure := currProcedure;
      PromienLubOrbita := currPromienLubOrbita;
      odnDlaPomOdl := currOdnDlaPomOdl;
      GlownyOdbiornik := currglownyOdbiornik;
      Nadajnik1 := currNadajnik1;
      Nadajnik2 := currNadajnik2;
      Predkosc  := currPredkosc;
      CisnienieOdniesienia := currCisnienieOdniesienia;
      a_IleOd := 0;
      FOR sek := MIN(OdcinekNr) TO MAX(OdcinekNr) DO
        WITH analiza[sek] DO
          FOR rec := goA TO goB DO
            WITH SSmin[rec] DO
              val := NilValI;
              pos := WORD(NilValC);
            END (* with SSmin *);
          END (* for rec *);
          pocz := WORD(NilValC);
          kon := WORD(NilValC);
          FOR rec := goA TO goB DO
            InitFlagErr(wykluczenia[rec]);
          END (* for rec *);
        END;
      END;
    END;
  END Init;

BEGIN
  WITH currDT DO
    WITH t DO
      Godzina(h, m, sec);
    END (* with t *);
    WITH d DO
      Data(y, m, d);
    END (* with d *);
  END (* with currDT *);
  Init(anRes, ' ', ' ', ' ', currDT, MIN(ProceduraT), 0, MIN(OdnDlaPomOdlT),
       MIN(GlownyOdbiornikT), MIN(NadajnikT), MIN(NadajnikT), 0.0, 1013.0 );
END D_results.
