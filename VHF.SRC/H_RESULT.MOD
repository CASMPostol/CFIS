(*.F- *)
(**********************************************************************
|  Title   : Wyniki analizy dla stacji VHF
|  Author  : M.Postol
|  System  : LOGITECH MODULA-2/86
|  History :
|    08-12-96: created
|    12-05-97: M.Morawski
|      zmaina sposobu sprawdzania wersji danych
|
|  Copyright (C), CAS LODZ POLAND.
|  TEL: 42' 862 547, 42' 87 80 44 FAX/TEL: 42' 84 48 40
|
**********************************************************************)
(*.F+ *)

IMPLEMENTATION MODULE H_results;

  FROM H_CommonTypes IMPORT
    ProceduraT;

  FROM Files IMPORT
    DateKind, SaveAResult, LoadAResult;

  FROM SYSTEM IMPORT
    WORD;

  FROM CommonTypes IMPORT
    (* TYPE *) SigNilVal, DisNilVal, TimeAndDate, NadajnikT, Version;

  FROM Czas IMPORT
    Data, Godzina;

  FROM Strings IMPORT
    Assign;

  FROM MsgBox IMPORT
    Info;

  CONST
    Pomiar      = FALSE;

  VAR
    currDT : TimeAndDate;
    s      : CARDINAL;

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
      Init(' ', ' ', MIN(ProceduraT), currDT, 0, nA);
      RETURN FALSE;
    END (* if *);
    RETURN TRUE;
  END GetAnRes;

  PROCEDURE Init
            (    currNazwaInsp        : ARRAY OF CHAR;
                 currNazwa            : ARRAY OF CHAR;
                 currProcedure        : ProceduraT;
                 currData             : TimeAndDate;
                 currPromienLubOrbita : WORD;
                 currNadajnik         : NadajnikT     );
  VAR
    sek        : OdcinekNr;
    currNilVal : WORD;

    PROCEDURE Init_A_OpisOdcinka
              ( VAR odc : A_OpisOdcinka );

    BEGIN
      WITH odc DO
        WITH SSmin DO
          val := SigNilVal;
          pos := currNilVal;
        END (* with SSmin *);
        pocz := currNilVal;
        kon := currNilVal;
      END (* with odc *);
    END Init_A_OpisOdcinka;

  BEGIN (* Init *)
    WITH anRes DO
      version := Version;
      Assign(currNazwaInsp, nazwaInsp);
      Assign(currNazwa, nazwa);
      data := currData;
      procedure := currProcedure;
      promienLubOrbita := currPromienLubOrbita;
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
  Init(' ', ' ', MIN(ProceduraT), currDT, 0, nA);
END H_results.
