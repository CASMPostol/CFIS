(*.F- *)
(**********************************************************************
|  Title   : Procedury realizujace analyse
|  Author  : M.Postol
|  System  : LOGITECH MODULA-2/86
|  History :
|    26-10-96: M.Postol
|      created
|    13-11-96: M.Postol
|      field version added.
|    12-18-96 08:07pm: MM
|      dodane pole orbita;
|    12-23-96 10:07am: MM
|      Blad w inicjalizacji - niezainicjowane pole NazwaInsp.
|    13-03-97:M.P.
|      dane z polowki pomiaru byly zapamietywane bez informacji nadajniku,
|      dla ktorego zostaly wyznaczone.
|    13-05-97: M.Postol
|      zmiana sposobu weryfikacji wersji danych.
|
|  Copyright (C), CAS LODZ POLAND.
|  TEL: 42' 862 547, 42' 87 80 44 FAX/TEL: 42' 84 48 40
|
**********************************************************************)
(*.F+ *)

IMPLEMENTATION MODULE L_results;

  FROM L_CommonTypes IMPORT
    ProceduraT, StronaT, NumStrefy, SignalDsc, MkrLengthT,
    (* PROCEDURE *) InitSignalDsc;

  FROM Files IMPORT
    DateKind, SaveAResult, LoadAResult;

  FROM SYSTEM IMPORT
    WORD;

  FROM CommonTypes IMPORT
    SigNilVal, OdnDlaPomBleduT, OdnDlaPomOdlT, GlownyOdbiornikT, NilValI,
    NilValC, TimeAndDate, ZoneBoundPt, NadajnikT, Version;

  FROM Czas IMPORT
    Data, Godzina;

  FROM ILS_ZoneMngmnt IMPORT
    IdPunktowArr_T, Fill_IdPunktowArr_T, Fill_zoneBDisIdx;

  FROM Strings IMPORT
    Assign;

  FROM MsgBox IMPORT
    Info;

  FROM FlagAnal IMPORT
    F_TablicaOdci, InitFlagErr;

  CONST
    Pomiar      = FALSE;

  VAR
    currDT  : TimeAndDate;
    s       : CARDINAL;
    idPnkt  : IdPunktowArr_T;
    pnktIdx : ZoneBoundPt;

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
      Init(0,' ', ' ', MIN(ProceduraT), currDT, MIN(OdnDlaPomOdlT), SigNilVal,
           SigNilVal, SigNilVal, MIN(StronaT), idPnkt, goA, pbTeodolit, nA);
    END (* if *);
    RETURN TRUE;
  END GetAnRes;

  PROCEDURE Init
            (    OrbitaProfB     : CARDINAL;
                 currNazwaOblotu : ARRAY OF CHAR;
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
                 PBledu          : OdnDlaPomBleduT;
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
      ref : OdnDlaPomBleduT;
      sec : NumStrefy;

    BEGIN (* Init_an_OpisOsi *)
      WITH an_OpisOsi DO
        FOR ref := pbTeodolit TO pbGPS DO
          FOR rec := MIN(GlownyOdbiornikT) TO MAX(GlownyOdbiornikT) DO
            FOR sec := MIN(NumStrefy) TO MAX(NumStrefy) DO
              InitSignalDsc(difAv_PO[sec, ref, rec]);
              InitSignalDsc(AzAv_PO[sec, ref, rec]);
              InitSignalDsc(difMax_PO[sec, ref, rec]);
              InitSignalDsc(difMin_PO[sec, ref, rec]);
              InitSignalDsc(roughness_PO[sec, ref, rec]);
            END (* for sec *);
            InitSignalDsc(difAvPolL_PO[ref, rec]);
            InitSignalDsc(difAvPolR_PO[ref, rec]);
            InitSignalDsc(alig_PO[ref, rec]);
            InitSignalDsc(difAvTotal_PO[ref, rec]);
            InitFlagErr(roughErr_PO[ref, rec]);
          END (* for rec *);
        END (* for ref *);
        InitMkrLength(mkrLength);
        Fill_zoneBDisIdx(zonesBeg);
      END (* with an_OpisOsi *);
    END Init_an_OpisOsi;

    PROCEDURE Init_an_OpisSektora
              ( VAR an_OpisSektora : An_OpisSektoraT );
    VAR
      rec : GlownyOdbiornikT;
      ref : OdnDlaPomBleduT;
      sec : NumStrefy;

    BEGIN (* Init_an_OpisSektora *)
      WITH an_OpisSektora DO
        FOR ref := pbTeodolit TO pbGPS DO
          FOR rec := MIN(GlownyOdbiornikT) TO MAX(GlownyOdbiornikT) DO
            FOR sec := MIN(NumStrefy) TO MAX(NumStrefy) DO
              InitSignalDsc(AzMax_OSA[sec, ref, rec]);
              InitSignalDsc(AzMin_OSA[sec, ref, rec]);
              InitSignalDsc(AzAv_OS[sec, ref, rec]);
            END (* for sec *);
            InitSignalDsc(ChiLoc[ref, rec]);
            InitSignalDsc(PhiLoc[ref, rec]);
          END (* for rec *);
        END (* for ref *);
      END (* with an_OpisOsi *)
    END Init_an_OpisSektora;

    PROCEDURE Init_an_OpisProfilB
              ( VAR an_OpisProfilB : An_OpisProfilBT );
    VAR
      rec : GlownyOdbiornikT;
      ref : OdnDlaPomBleduT;

    BEGIN (* Init_an_OpisProfilB *)
      WITH an_OpisProfilB DO
        FOR ref := pbTeodolit TO pbGPS DO
          FOR rec := MIN(GlownyOdbiornikT) TO MAX(GlownyOdbiornikT) DO
            InitSignalDsc(difAv0_PB[ref, rec]);
            InitSignalDsc(az0_PB[ref, rec]);
            InitSignalDsc(az150_150_PB[ref, rec]);
            InitSignalDsc(az75_150_PB[ref, rec]);
            InitSignalDsc(az150_90_PB[ref, rec]);
            InitSignalDsc(az75_90_PB[ref, rec]);
            InitSignalDsc(ChiLoc[ref, rec]);
            InitSignalDsc(PhiLoc[ref, rec]);
            InitSignalDsc(H175Mn[ref, rec]);
            InitSignalDsc(H175Mx[ref, rec]);
            InitSignalDsc(H150mn[ref, rec]);
            InitSignalDsc(HM175Mn[ref, rec]);
            InitSignalDsc(HM175Mx[ref, rec]);
            InitSignalDsc(HM150mn[ref, rec]);
          END (* for rec *);
        END (* for ref *);
      END (* with an_OpisOsi *)
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

    PROCEDURE Init_an_OpisZasieg_do_10
              ( VAR an_OpisZasieg_do_10 : An_OpisZasieg_do_10T );
    VAR
      rec : GlownyOdbiornikT;
      ref : OdnDlaPomBleduT;

    BEGIN
      WITH an_OpisZasieg_do_10 DO
        FOR ref := pbTeodolit TO pbGPS DO
          FOR rec := MIN(GlownyOdbiornikT) TO MAX(GlownyOdbiornikT) DO
            InitSignalDsc(sS0_Min_ZW[ref, rec]);
          END (* for rec *);
        END (* for ref *);
      END (* with an_OpisZasieg_do_10 *);
    END Init_an_OpisZasieg_do_10;

    PROCEDURE Init_an_OpisZasiegSzer
              ( VAR an_OpisZasiegSzer : An_OpisZasiegSzerT );
    VAR
      rec : GlownyOdbiornikT;
      ref : OdnDlaPomBleduT;

    BEGIN
      WITH an_OpisZasiegSzer DO
        FOR ref := pbTeodolit TO pbGPS DO
          FOR rec := MIN(GlownyOdbiornikT) TO MAX(GlownyOdbiornikT) DO
            InitSignalDsc(sS150_Min_ZS[ref, rec]);
            InitSignalDsc(sS90_Min_ZS[ref, rec]);
          END (* for rec *);
        END (* for ref *);
      END (* with an_OpisZasiegSzer *);
    END Init_an_OpisZasiegSzer;

    PROCEDURE InitAnalizaDsc
              ( VAR anRes : AnalizaDsc );
    VAR
      rec : GlownyOdbiornikT;

    BEGIN
      WITH anRes DO
        FOR rec := MIN(GlownyOdbiornikT) TO MAX(GlownyOdbiornikT) DO
          InitSignalDsc(modLocMin_PO[rec]);
          InitSignalDsc(modLocAv_PO[rec]);
          InitSignalDsc(SSMin_PO[rec]);
        END (* for rec *);
      END (* with anRes *);
    END InitAnalizaDsc;

  BEGIN (* Init *)
    WITH anRes DO
      version := Version;
      Orbita := OrbitaProfB;
      glownyOdbiornik := GOdbiornik;
      odnDlaPomBledu := PBledu;
      Assign(currNazwaOblotu, NazwaInsp );
      Assign(currNazwa, Nazwa);
      data := Data;
      odnDlaPomOdl := OdnDlaPomOdl;
      offset := Offset;
      ustawOsi := UstawOsi;
      secWith := SecWith;
      strona := Strona;
      procedure := Procedure;
      identPunktow := IdentPunktow;
      InitFlagErrForARec(flagErr);
      InitAnalizaDsc(anRes);
      Nadajnik := currNadajnik;
      CASE Procedure OF
        pUstawienieOsi_Struktura, pAlarmOsi, pUstawienieOsi_Szer_pA,
        pUstawienieOsi_Waski_pA :
          Init_an_OpisOsi(an_OpisOsi);
        |
        pSzerSektora_pA, pAlarmSzeroki_pA, pAlarmWaski_pA :
          Init_an_OpisSektora(an_OpisSektora);
        |
        pSzer_i_Osi_pB, pAlarmSzer_pB, pAlarmWaski_pB, pWyrazistosc_na_d_katach
        :
          Init_an_OpisProfilB(an_OpisProfilB);;
        |
        pRownowagaModulacji, pFazowanie :
          Init_an_OpisBadDod(an_OpisBadDod);
        |
        pZasieg_do_10 :
          Init_an_OpisZasieg_do_10(an_OpisZasieg_do_10);
        |
        pZasieg_10_35, pZasieg_ponad_35 :
          Init_an_OpisZasiegSzer(an_OpisZasiegSzer);
        |
        pMarker :
          InitMkrLength(an_OpisMarker.mkrLength);
      END (* case Procedure *);
    END (* with anRes *);
  END Init;

  VAR
    rec : GlownyOdbiornikT;
    ref : OdnDlaPomBleduT;
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
      FOR ref := pbTeodolit TO pbGPS DO
        InitSignalDsc(lastAzAv_A[trn, ref, rec]);
        InitSignalDsc(lastEta_150_A[trn, ref, rec]);
        InitSignalDsc(lastEta_90_A[trn, ref, rec]);
        InitSignalDsc(lastAzAv_ANr[trn, ref, rec]);
        InitSignalDsc(lastEta_150_ANr[trn, ref, rec]);
        InitSignalDsc(lastEta_90_ANr[trn, ref, rec]);
        InitSignalDsc(lastAzAv_AWd[trn, ref, rec]);
        InitSignalDsc(lastEta_150_AWd[trn, ref, rec]);
        InitSignalDsc(lastEta_90_AWd[trn, ref, rec]);
      END (* for ref *);
    END (* for rec *);
  END (* for trn *);
  Init(0,' ', ' ', MIN(ProceduraT), currDT, MIN(OdnDlaPomOdlT), SigNilVal,
       SigNilVal, SigNilVal, MIN(StronaT), idPnkt, MIN(GlownyOdbiornikT), MIN(
       OdnDlaPomBleduT), nA);
END L_results.
