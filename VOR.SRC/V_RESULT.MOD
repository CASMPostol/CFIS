(*.F- *)
(**********************************************************************
|  Title   : Procedury realizujace analyse
|  Author  : M.Postol
|  System  : LOGITECH MODULA-2/86
|  History :
|    13-11-96: M.Postol
|      field version added.
|    12-05-97: M.Morawski
|      zmiana w weryfikacji wersji
|    Rel 3.0. M.Postol
|      Zmiana definicji InitFlagErr
|      Zmiana definicji Czas
|      Przy inicjacji zastosowalem puste napisy dla nazw
|
|  Copyright (C), CAS LODZ POLAND.
|  TEL: 42' 862 547, 42' 87 80 44 FAX/TEL: 42' 84 48 40
|
**********************************************************************)
(*.F+ *)

IMPLEMENTATION MODULE V_results;

  FROM Files IMPORT
    DateKind, SaveAResult, LoadAResult;

  FROM SYSTEM IMPORT
    WORD;

  FROM CommonTypes IMPORT
    OdnDlaPomBleduT, GlownyOdbiornikT, OdnDlaPomOdlT, IntCardRec,
    NilValI, NilValC, NadajnikT, Version;

  FROM VORO_avrage IMPORT
    OrbitDscClear;

  FROM Czas IMPORT
    TimeAndDate, GetTimeAndDate;

  FROM V_CommonTypes IMPORT
    ProceduraT;

  FROM FlagAnal IMPORT
    InitFlagErr;

  FROM Strings IMPORT
    Assign;

  FROM MsgBox IMPORT
    Info;

  FROM D_CommonTypes  IMPORT
    NilDlaPOdleglosci;
    
  CONST
    Pomiar      = FALSE;

  VAR
    currDT : TimeAndDate;
    sec    : CARDINAL;

  PROCEDURE SaveAnRes
            (    res : AnalizaDsc );

  BEGIN
    SaveAResult(res, Analiza, Pomiar);
  END SaveAnRes;

  PROCEDURE GetAnRes
            ( VAR res : AnalizaDsc ) : BOOLEAN;
  VAR
    void : BOOLEAN;

  BEGIN
    IF NOT LoadAResult(res, Analiza, Pomiar, LastChanged_anRes_Ver, Version)
    THEN
      Init(anRes, '', '', '', currDT, MIN(ProceduraT), 0, MIN(OdnDlaPomOdlT)
           , goA, nA, nA, 0.0, 1013.0, pbnieZdef);
      RETURN FALSE;
    END (* if *);
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
                  currGlownyOdbiornik      : GlownyOdbiornikT;
                  currNadajnik1            : NadajnikT;
                  currNadajnik2            : NadajnikT;
                  currPredkosc             : REAL;
                  currCisnienieOdniesienia : REAL;
                  currOdnDlaPomBledu       : OdnDlaPomBleduT  );


  PROCEDURE ClearAnRes
            ( NilDlaOdleglosci: WORD);
  VAR
    rec              : GlownyOdbiornikT;
    ref              : OdnDlaPomBleduT;
    par              : Parametr;
    signal           : Signals;
    katANieOdleglosc : BOOLEAN;
  
  BEGIN
    WITH anRes DO
      FOR rec := goA TO goB DO
        FOR ref := pbTeodolit TO pbGPS DO
          FOR par := AV TO PolPrawo DO
            WITH devDet[par, ref, rec] DO
              val := NilValI;
              pos := NilDlaOdleglosci;
            END (* with devDet *);
          END (* for par *);
          OrbitDscClear( DevOrbit[ref, rec] );
        END (* for ref *);
        FOR par := AV TO MM DO
          FOR signal := Var TO Agc DO
            WITH signalGen[par, signal, rec] DO
              val := NilValI;
              pos := NilDlaOdleglosci;
            END (* with signalGen *);
          END (* for signal *);
        END (* for par *);
        katANieOdleglosc := ( currProcedure = pOkragBlad   ) OR 
                            ( currProcedure = pOkragZakres );
        InitFlagErr(flagTab[rec],   katANieOdleglosc);
        InitFlagErr(lowSigTab[rec], katANieOdleglosc);
      END (* for rec *);
      InitFlagErr(brakPomNaorbicie, katANieOdleglosc);
    END (* with anRes *);
  END ClearAnRes;

  BEGIN (* Init *)
    ClearAnRes(NilDlaPOdleglosci(currProcedure));
    WITH anRes DO
      version := Version;
      Assign(currNazwaOblotu, NazwaInsp);
      Assign(currNazwa, Nazwa);
      Assign(currNazwa2, Nazwa2);
      dataPomiaru := currData;
      procedure := currProcedure;
      PromienLubOrbita := currPromienLubOrbita;
      odnDlaPomOdl := currOdnDlaPomOdl;
      GlownyOdbiornik := currGlownyOdbiornik;
      Nadajnik1 := currNadajnik1;
      Nadajnik2 := currNadajnik2;
      Predkosc := currPredkosc;
      CisnienieOdniesienia := currCisnienieOdniesienia;
      odnDlaPomBledu := currOdnDlaPomBledu;
    END (* with anRes *);
  END Init;

BEGIN
  GetTimeAndDate(currDT);
  Init(anRes, '', '', '', currDT, MIN(ProceduraT), 0, MIN(OdnDlaPomOdlT),
       goA, nA, nA, 0.0, 1013.0, pbnieZdef);
END V_results.
