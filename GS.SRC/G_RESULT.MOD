(*.F- *)
(**********************************************************************
|  Title   : Procedury realizujace analyse
|  Author  : M.Postol
|  System  : LOGITECH MODULA-2/86
|  History :
|    26-10-96: M.Postol
|      created
|    27-01-96: M.Postol
|      zmiana defa
|    13-03-97:M.P.
|      dane z polowki pomiaru byly zapamietywane bez informacji nadajniku,
|      dla ktorego zostaly wyznaczone.
|    12-05-97: M.Morawski
|      zmiana sposobu sprawdzania wersji
|
|  Copyright (C), CAS LODZ POLAND.
|  TEL: 42' 862 547, 42' 87 80 44 FAX/TEL: 42' 84 48 40
|
**********************************************************************)
(*.F+ *)

IMPLEMENTATION MODULE G_results;

  FROM G_CommonTypes IMPORT
    ProceduraT, StronaT;

  FROM L_CommonTypes IMPORT
    NumStrefy, SignalDsc, MkrLengthT,
    (* PROCEDURE *) InitSignalDsc;

  FROM Files IMPORT
    DateKind, SaveAResult, LoadAResult;

  FROM SYSTEM IMPORT
    WORD;

  FROM CommonTypes IMPORT
    SigNilVal, OdnDlaPomOdlT, GlownyOdbiornikT, NilValI, NilValC, TimeAndDate,
    NadajnikT, DisNilVal, Version;

  FROM Czas IMPORT
    Data, Godzina;

  FROM ILS_ZoneMngmnt IMPORT
    IdPunktowArr_T, Fill_IdPunktowArr_T, Fill_zoneBDisIdx;

  FROM Strings IMPORT
    Assign;

  FROM MsgBox IMPORT
    Info;

  FROM FlagAnal IMPORT
    F_TablicaOdci,  InitFlagErr;

  CONST
    Pomiar = FALSE;

  VAR
    currDT : TimeAndDate;
    s      : CARDINAL;
    idPnkt : IdPunktowArr_T;

  PROCEDURE SaveAnRes
            (    res : AnalizaDsc );

  BEGIN
    SaveAResult(res, Analiza, Pomiar);
  END SaveAnRes;

  PROCEDURE GetAnRes() : BOOLEAN;
  VAR
    void : BOOLEAN;
  BEGIN
    IF NOT LoadAResult(anRes, Analiza, Pomiar, LastChanged_anRes_Ver, Version)
    THEN
      Init(' ', ' ', MIN(ProceduraT), currDT, MIN(OdnDlaPomOdlT), SigNilVal,
           SigNilVal, SigNilVal, MIN(StronaT), idPnkt, goA, nA);
      RETURN FALSE;
    END (* if *);
    RETURN TRUE;
  END GetAnRes;

  PROCEDURE Init
            (    currNazwaOblotu : ARRAY OF CHAR;
                 currNazwa       : ARRAY OF CHAR;
                 Procedure       : ProceduraT;
                 Data            : TimeAndDate;
                 OdnDlaPomOdl    : OdnDlaPomOdlT;
                 Offset          : INTEGER;
                 UstawOsi        : INTEGER;
                 SecWith         : INTEGER;
                 Strona          : StronaT;
                 IdentPunktow    : IdPunktowArr_T;
                 GOdbiornik      : GlownyOdbiornikT;
                 currNadajnik    : NadajnikT        );

    PROCEDURE InitFlagErrForARec
              ( VAR flagErr : F_TablicaOdci );
    VAR
      rec : GlownyOdbiornikT;

    BEGIN
      FOR rec := MIN(GlownyOdbiornikT) TO MAX(GlownyOdbiornikT) DO
        InitFlagErr(flagErr[rec]);
      END (* for rec *);
    END InitFlagErrForARec;

    PROCEDURE InitMkrLength
              ( VAR mkrLength : MkrLengthT );
    VAR
      rec : GlownyOdbiornikT;

    BEGIN
      FOR rec := MIN(GlownyOdbiornikT) TO MAX(GlownyOdbiornikT) DO
        InitSignalDsc(mkrLength.oMkrL_OM[rec]);
        InitSignalDsc(mkrLength.mMkrL_OM[rec]);
        InitSignalDsc(mkrLength.iMkrL_OM[rec]);
        InitSignalDsc(mkrLength.oMkrA_OM[rec]);
        InitSignalDsc(mkrLength.mMkrA_OM[rec]);
        InitSignalDsc(mkrLength.iMkrA_OM[rec]);
      END (* for rec *);
    END InitMkrLength;

    PROCEDURE Init_an_OpisOsi
              ( VAR an_OpisOsi : An_OpisOsiT );
    VAR
      rec : GlownyOdbiornikT;
      sec : NumStrefy;

    BEGIN (* Init_an_OpisOsi *)
      WITH an_OpisOsi DO
        FOR rec := MIN(GlownyOdbiornikT) TO MAX(GlownyOdbiornikT) DO
          FOR sec := MIN(NumStrefy) TO MAX(NumStrefy) DO
            InitSignalDsc(difAv_PO[sec, rec]);
            InitSignalDsc(roughness_PO[sec, rec]);
            InitSignalDsc(azAv_PO[sec, rec]);
            InitSignalDsc(azMax_PO[sec, rec]);
            InitSignalDsc(azMin_PO[sec, rec]);
          END (* for sec *);
          InitSignalDsc(alig_PO[rec]);
          InitFlagErr(roughErr_PO[rec])
        END (* for rec *);
        InitMkrLength(mkrLength);
        Fill_zoneBDisIdx(zonesBeg);
      END (* with an_OpisOsi *);
    END Init_an_OpisOsi;

    PROCEDURE Init_an_OpisSektora
              ( VAR an_OpisSektora : An_OpisSektoraT );
    VAR
      rec : GlownyOdbiornikT;
      sec : NumStrefy;

    BEGIN (* Init_an_OpisSektora *)
      WITH an_OpisSektora DO
        FOR rec := MIN(GlownyOdbiornikT) TO MAX(GlownyOdbiornikT) DO
          FOR sec := MIN(NumStrefy) TO MAX(NumStrefy) DO
            InitSignalDsc(AzMax_OS[sec, rec]);
            InitSignalDsc(AzMin_OS[sec, rec]);
            InitSignalDsc(AzAv_OS[sec, rec]);
          END (* for sec *);
          InitSignalDsc(Chi_OS[rec]);
          InitSignalDsc(Phi_OS[rec]);
        END (* for rec *);
        Fill_zoneBDisIdx(zonesBeg_OS);
      END (* with an_OpisOsi *)
    END Init_an_OpisSektora;

    PROCEDURE Init_an_OpisProfilB
              ( VAR an_OpisProfilB : An_OpisProfilBT );
    VAR
      rec : GlownyOdbiornikT;

    BEGIN (* Init_an_OpisProfilB *)
      WITH an_OpisProfilB DO
        FOR rec := MIN(GlownyOdbiornikT) TO MAX(GlownyOdbiornikT) DO
          InitSignalDsc(az75_G_PB[rec]);
          InitSignalDsc(az75_D_PB[rec]);
          InitSignalDsc(az0_PB[rec]);
          InitSignalDsc(Chi_PB[rec]);
          InitSignalDsc(Phi_PB[rec]);
          InitSignalDsc(az190_D_PB[rec]);
          InitSignalDsc(az150_G_PB[rec]);
        END (* for rec *);
        WysokoscAv_PB := SigNilVal;
      END (* with an_OpisOsi *);
    END Init_an_OpisProfilB;

    PROCEDURE Init_an_OpisBadDod
              ( VAR an_OpisBadDod : An_OpisBadDodT );
    VAR
      rec : GlownyOdbiornikT;

    BEGIN
      WITH an_OpisBadDod DO
        FOR rec := MIN(GlownyOdbiornikT) TO MAX(GlownyOdbiornikT) DO
          InitSignalDsc(dewAv[rec]);
        END (* for rec *);
      END (* with an_OpisBadDod *);
    END Init_an_OpisBadDod;

    PROCEDURE Init_an_OpisZabezpieczenie
              (VAR an_OpisZabezpieczenie : An_OpisZabezpieczenieT);
    VAR
      rec : GlownyOdbiornikT;
      sec : NumStrefy;
    BEGIN
      WITH an_OpisZabezpieczenie DO
        FOR rec := MIN(GlownyOdbiornikT) TO MAX(GlownyOdbiornikT) DO
          FOR sec := MIN(NumStrefy) TO MAX(NumStrefy) DO
            InitSignalDsc(az180Av[sec, rec]);
          END
        END;
        InitFlagErrForARec(_odcinki180_OZ);
        InitFlagErrForARec(_odcinki150_OZ);
        Fill_zoneBDisIdx(zonesBeg_OZ);
      END;
    END Init_an_OpisZabezpieczenie;

    PROCEDURE Init_an_OpisPokrycia
              ( VAR an_OpisPokrycia : An_OpisPokryciaT );
    VAR
      rec : GlownyOdbiornikT;

    BEGIN
      WITH an_OpisPokrycia DO
        InitFlagErrForARec(odcinki_20uV);
        run_Start_OP := SigNilVal;
      END;
    END Init_an_OpisPokrycia;

    PROCEDURE InitAnalizaDsc
              ( VAR anRes : AnalizaDsc );
    VAR
      rec : GlownyOdbiornikT;

    BEGIN
      WITH anRes DO
        InitFlagErrForARec(flagErr);
        FOR rec := MIN(GlownyOdbiornikT) TO MAX(GlownyOdbiornikT) DO
          InitSignalDsc(modMin_PO[rec]);
          InitSignalDsc(modAv_PO[rec]);
          InitSignalDsc(SSMin_PO[rec]);
        END (* for rec *);
      END (* with anRes *);
    END InitAnalizaDsc;

  BEGIN (* Init *)
    WITH anRes DO
      version := Version;
      Assign(currNazwaOblotu, NazwaInsp);
      Assign(currNazwa, Nazwa);
      data := Data;
      glownyOdbiornik := GOdbiornik;
      odnDlaPomOdl := OdnDlaPomOdl;
      offset := Offset;
      ustawOsi := UstawOsi;
      secWith := SecWith;
      strona := Strona;
      identPunktow := IdentPunktow;
      nadajnik := currNadajnik;
      procedure := Procedure;
      InitAnalizaDsc(anRes);
      CASE Procedure OF
        pUstawienieOsi_Struktura, pAlarmOsi, pUstawienieOsi_Szer_pA,
        pUstawienieOsi_Waski_pA :
          Init_an_OpisOsi(an_OpisOsi);
        |
        pSzerSektora_pA, pAlarmSzeroki_pA, pAlarmWaski_pA :
          Init_an_OpisSektora(an_OpisSektora);
        |
        pSzer_i_Osi_pB, pAlarmSzer_pB, pAlarmWaski_pB :
          Init_an_OpisProfilB(an_OpisProfilB);;
        |
        pRownowagaModulacji, pFazowanie :
          Init_an_OpisBadDod(an_OpisBadDod);
        |
        pZabezpieczenie :
          Init_an_OpisZabezpieczenie(an_OpisZabezpieczenie);
        |
        pPokrycieWOsi, pPokrycie8stP, pPokrycie8stL :
          Init_an_OpisPokrycia(an_OpisPokrycia);
      END (* case Procedure *);
    END (* with anRes *);
  END Init;

  VAR
    rec : GlownyOdbiornikT;
    trn : NadajnikT;

BEGIN
  Fill_IdPunktowArr_T(idPnkt);
  WITH currDT DO
    WITH t DO
      Godzina(h, m, s);
    END (* with t *);
    WITH d DO
      Data(y, m, d);
    END (* with d *);
  END (* with currDT *);
  FOR  trn := MIN(NadajnikT) TO MAX(NadajnikT) DO
    FOR rec := MIN(GlownyOdbiornikT) TO MAX(GlownyOdbiornikT) DO
      InitSignalDsc(lastAzAv_A[trn, rec]);
      InitSignalDsc(lastEta_G_A[trn, rec]);
      InitSignalDsc(lastEta_D_A[trn, rec]);
      InitSignalDsc(lastAzAv_ANr[trn, rec]);
      InitSignalDsc(lastEta_G_ANr[trn, rec]);
      InitSignalDsc(lastEta_D_ANr[trn, rec]);
      InitSignalDsc(lastAzAv_AWd[trn, rec]);
      InitSignalDsc(lastEta_G_AWd[trn, rec]);
      InitSignalDsc(lastEta_D_AWd[trn, rec]);
    END (* for rec *);
  END (* for trn *);
  Init(' ', ' ', MIN(ProceduraT), currDT, MIN(OdnDlaPomOdlT), 0, 300, 300, MIN(
       StronaT), idPnkt, MIN(GlownyOdbiornikT), nA);
END G_results.
