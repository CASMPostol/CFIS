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
|    Rel 3.0. M.Postol
|      Zmiana definicji Czas
|      nie bylo inicjowane pole SSMin_PO
|
|  Copyright (C), CAS LODZ POLAND.
|  TEL: 42' 686 25 47
|  mailto: techsupp@cas.com.pl
|  http: www.cas.com.pl
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
    SigNilVal, OdnDlaPomOdlT, GlownyOdbiornikT, NilValI, NilValC, 
    NadajnikT, SignalDsc, DisNilVal, Version, InitSignalDsc;

  FROM Czas IMPORT
    TimeAndDate, GetTimeAndDate;

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
    lastline : INTEGER;

  PROCEDURE SaveAnRes;

  BEGIN
    lastline:=62;
    SaveAResult(anRes, Analiza, Pomiar);
    lastline:=64;
  END SaveAnRes;

  PROCEDURE GetAnRes() : BOOLEAN;
  VAR
    void : BOOLEAN;
  BEGIN
    IF NOT LoadAResult(anRes, Analiza, Pomiar, LastChanged_anRes_Ver, Version )
    THEN
      lastline:=74;
      Init(' ', ' ', currDT, MIN(ProceduraT), 0, goA, 1013.0, nA);
      lastline:=76;
      RETURN FALSE;
    END (* if *);
    RETURN TRUE;
  END GetAnRes;

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
    rec        : GlownyOdbiornikT;
    sek        : OdcinekNr;
    currNilVal : WORD;

    PROCEDURE Init_A_OpisOdcinka
              ( VAR odc              : A_OpisOdcinka;
                    katANieOdleglosc : BOOLEAN);
    VAR
      rec: GlownyOdbiornikT;
    BEGIN
      WITH odc DO
        FOR rec := MIN(GlownyOdbiornikT) TO MAX(GlownyOdbiornikT)
        DO
          InitSignalDsc(SSmin[rec], currNilVal);
          InitFlagErr(blad5[rec], katANieOdleglosc);
          InitFlagErr(blad10[rec], katANieOdleglosc);
        END;
        pocz := currNilVal;
        kon  := currNilVal;
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
      FOR rec := MIN(GlownyOdbiornikT) TO MAX(GlownyOdbiornikT)
      DO
        InitSignalDsc(SSMin_PO[rec], currNilVal);
      END;
      a_IleOd := 0;
      CASE currProcedure  OF
        pPromien :
          currNilVal := WORD(DisNilVal);
        |
        pOrbita:
          lastline := 133;
          currNilVal := WORD(SigNilVal);
      END;
      FOR sek := MIN(OdcinekNr) TO MAX(OdcinekNr) DO
        Init_A_OpisOdcinka(analiza[sek], currProcedure = pOrbita);
      lastline:= 137;
      END (* for sek *);
    lastline := 139;
    END (* with anRes *);
  END Init;

BEGIN
  GetTimeAndDate(currDT);
  Init(' ', ' ', currDT, MIN(ProceduraT), 0, goA, 1013.0, nA);
END N_results.
