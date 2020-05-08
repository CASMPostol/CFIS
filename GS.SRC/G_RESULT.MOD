(*.F- *)
(**********************************************************************
|  Title   : Procedury realizujace analize
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
|    Rel. 3.0: MPostol
|      Dostosowalem do nowej definicji FlagAnal.
|      Dostosowalem do nowej definicji Czas
|
|  Copyright (C), CAS LODZ POLAND.
|  TEL: 42' 862 547, 42' 87 80 44 FAX/TEL: 42' 84 48 40
|
**********************************************************************)
(*.F+ *)

IMPLEMENTATION MODULE G_results;

  FROM G_CommonTypes IMPORT
    znakGora, ProceduraT, StronaT;

  FROM L_CommonTypes IMPORT
    NumStrefy, MkrLengthT,
    (* PROCEDURE *) InitSignalDsc;

  FROM Files IMPORT
    DateKind, SaveAResult, LoadAResult;

  FROM CommonTypes IMPORT
    SigNilVal, OdnDlaPomOdlT, GlownyOdbiornikT, 
    NadajnikT, Version, SignalDsc;

  FROM ILS_ZoneMngmnt IMPORT
    IdPunktowArr_T, Fill_IdPunktowArr_T, Fill_zoneBDisIdx;

  FROM Strings IMPORT
    Assign;

  FROM FlagAnal IMPORT
    F_TablicaOdci,  InitFlagErr;

  FROM Czas IMPORT
    TimeAndDate, GetTimeAndDate;
  
  FROM MathLib0 IMPORT
    real;

  FROM SpecConv IMPORT
    entierCheck;

  CONST
    Pomiar           = FALSE;
    KatANieOdleglosc = TRUE;
    
  VAR
    currDT : TimeAndDate;
    idPnkt : IdPunktowArr_T;

  PROCEDURE SaveAnRes
            (    res : AnalizaDsc );

  BEGIN
    SaveAResult(res, Analiza, Pomiar);
  END SaveAnRes;

  PROCEDURE GetAnRes() : BOOLEAN;
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
              ( VAR flagErr          : F_TablicaOdci;
                    katANieOdleglosc : BOOLEAN );
    VAR
      rec : GlownyOdbiornikT;

    BEGIN
      FOR rec := MIN(GlownyOdbiornikT) TO MAX(GlownyOdbiornikT) DO
        InitFlagErr(flagErr[rec], katANieOdleglosc);
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
            InitSignalDsc(difMax_PO[sec, rec]);
            InitSignalDsc(difMin_PO[sec, rec]);
          END (* for sec *);
          InitSignalDsc(alig_PO[rec]);
          InitFlagErr(roughErr_PO[rec], NOT KatANieOdleglosc)
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
        InitFlagErrForARec(_odcinki180_OZ, NOT KatANieOdleglosc);
        InitFlagErrForARec(_odcinki150_OZ, NOT KatANieOdleglosc);
        Fill_zoneBDisIdx(zonesBeg_OZ);
      END;
    END Init_an_OpisZabezpieczenie;

    PROCEDURE Init_an_OpisPokrycia
              ( VAR an_OpisPokrycia : An_OpisPokryciaT );

    BEGIN
      WITH an_OpisPokrycia DO
        InitFlagErrForARec(odcinki_20uV, NOT KatANieOdleglosc);
        run_Start_OP := SigNilVal;
      END;
    END Init_an_OpisPokrycia;

    PROCEDURE InitAnalizaDsc
              ( VAR anRes : AnalizaDsc );
    VAR
      rec : GlownyOdbiornikT;

    BEGIN
      WITH anRes DO
        InitFlagErrForARec(flagErr, NOT KatANieOdleglosc);
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

  PROCEDURE AktualnyKatProcedury (): REAL;
  BEGIN
    WITH anRes DO
      RETURN
        real(ustawOsi) + real(znakGora) * real(secWith) * real(offset)/1500.0
    END;
  END AktualnyKatProcedury;

    PROCEDURE Count_ChiLoc
              ( VAR ChiLoc : SignalDsc;
                    Eta1   : SignalDsc;
                    Eta2   : SignalDsc );

    BEGIN
      IF ( Eta1.val = SigNilVal ) OR ( Eta2.val = SigNilVal )
      THEN
        ChiLoc.val := SigNilVal;
      ELSE
        ChiLoc.val := ABS( Eta1.val - Eta2.val );
      END (* if *);
    END Count_ChiLoc;

    PROCEDURE Count_PhiLoc
              ( VAR PhiLoc : SignalDsc;
                    Eta0   : SignalDsc;
                    Eta    : SignalDsc;
                    ChiLoc : SignalDsc );

    VAR
      Eta0R   : REAL;
      EtaR    : REAL;
      ChiLocR : REAL;

    BEGIN
      IF ( Eta0.val = SigNilVal ) OR ( Eta.val = SigNilVal ) OR
         ( ChiLoc.val = SigNilVal )
      THEN
        PhiLoc.val := SigNilVal;
      ELSE
        Eta0R := real( Eta0.val );
        EtaR := real( Eta.val );
        ChiLocR := real( ChiLoc.val );
        IF NOT entierCheck( ABS( ( EtaR - Eta0R ) / ChiLocR * 1000.0 ) + 0.5,
                            PhiLoc.val )
        THEN
          PhiLoc.val := SigNilVal;
        END (* if *);
      END (* if *);
    END Count_PhiLoc;

BEGIN
  Fill_IdPunktowArr_T(idPnkt);
  GetTimeAndDate( currDT);
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
