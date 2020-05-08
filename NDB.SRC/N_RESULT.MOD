(*.F- *)
(**********************************************************************
|  Title   : Procedury realizujace analyse
|  Author  : M.Postol
|  System  : LOGITECH MODULA-2/86
|  History :
|    13-11-96: M.Postol
|      field version added.
|    13-05-97: M.Postol
|      zmiana sposobu weryfikacji wersji danych
|
|  Copyright (C), CAS LODZ POLAND.
|  TEL: 42' 862 547, 42' 87 80 44 FAX/TEL: 42' 84 48 40
|
**********************************************************************)
(*.F+ *)

IMPLEMENTATION MODULE N_results;

  FROM N_CommonTypes IMPORT
    ProceduraT;

  FROM Files IMPORT
    DateKind, SaveAResult, LoadAResult;

  FROM SYSTEM IMPORT
    WORD;

  FROM CommonTypes IMPORT
    SigNilVal, OdnDlaPomOdlT, GlownyOdbiornikT, NilValI, NilValC, TimeAndDate,
    NadajnikT, SignalDsc, DisNilVal, Version;

  FROM Czas IMPORT
    Data, Godzina;

  FROM Strings IMPORT
    Assign;

  FROM FlagAnal IMPORT
    InitFlagErr;

  FROM MANAGER IMPORT
    Assert;

  FROM MsgBox IMPORT
    Info;

  CONST
    Pomiar = FALSE;

  VAR
    currDT  : TimeAndDate;
    s       : CARDINAL;

  PROCEDURE SaveAnRes
            (    res : AnalizaDsc );

  BEGIN
    SaveAResult(res, Analiza, Pomiar);
  END SaveAnRes;

  PROCEDURE GetAnRes() : BOOLEAN;
  VAR
    void : BOOLEAN;
  BEGIN
    IF NOT LoadAResult(anRes, Analiza, Pomiar, LastChanged_anRes_Ver, Version )
    THEN
      Init(' ', ' ', currDT, MIN(ProceduraT), 0, goA, 1013.0, nA);
      RETURN FALSE;
    END (* if *);
    RETURN TRUE;
  END GetAnRes;

  PROCEDURE InitSignalDsc
            ( VAR signal : SignalDsc );

  BEGIN
    WITH signal DO
      val := NilValI;
      pos := WORD(NilValC);
    END (* with signal *);
  END InitSignalDsc;

  PROCEDURE Init
            (    currNazwaInsp : ARRAY OF CHAR;
                 currNazwa       : ARRAY OF CHAR;
                 currData            : TimeAndDate;
                 currProcedure       : ProceduraT;
                 currPromienLubOrbita   : WORD;
                 currGlownyOdbiornik      : GlownyOdbiornikT;
                 currCisnienieOdniesienia       : REAL             ;
                 currNadajnik              : NadajnikT);


  VAR
    rec     : GlownyOdbiornikT;
    sek        : OdcinekNr;
    currNilVal : WORD;

    PROCEDURE Init_A_OpisOdcinka
              ( VAR odc : A_OpisOdcinka );
    VAR
      rec: GlownyOdbiornikT;
    BEGIN
      WITH odc DO
        FOR rec := MIN(GlownyOdbiornikT) TO MAX(GlownyOdbiornikT)
        DO
          WITH SSmin[rec] DO
            val := SigNilVal;
            pos := currNilVal;
          END (* with SSmin *);
        END;
        pocz := currNilVal;
        kon := currNilVal;
      END (* with odc *);
    END Init_A_OpisOdcinka;

  BEGIN (* Init *)
    WITH anRes DO
      version := Version;
      Assign(currNazwaInsp, NazwaInsp);
      Assign(currNazwa, Nazwa);
      data := currData;
      procedure := currProcedure;
      promienLubOrbita := currPromienLubOrbita;
      glownyOdbiornik := currGlownyOdbiornik;
      cisnienieOdniesienia := currCisnienieOdniesienia;
      nadajnik := currNadajnik;
      a_IleOd := 0;
      CASE currProcedure  OF
        pPromien :
          currNilVal := WORD(DisNilVal);
        |
        pOrbita:
          currNilVal := WORD(SigNilVal);
      END;
      FOR sek := MIN(OdcinekNr) TO MAX(OdcinekNr) DO
        Init_A_OpisOdcinka(analiza[sek]);
      END (* for sek *);
    END (* with anRes *);
  END Init;

BEGIN
  WITH currDT DO
    WITH t DO
      Godzina(h, m, s);
    END (* with t *);
    WITH d DO
      Data(y, m, d);
    END (* with d *);
  END (* with currDT *);
  Init(' ', ' ', currDT, MIN(ProceduraT), 0, goA, 1013.0, nA);
END N_results.
