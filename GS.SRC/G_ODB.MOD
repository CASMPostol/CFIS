(*.F- *)
(**********************************************************************
|  Title   : Procedury wyliczajace parametry online dla dobiornika GS.
|  Author  : M.Postol
|  System  : LOGITECH MODULA-2/86
|  History :
|    27-10-96: M.Postol
|      created
|    30-01-97: M.Postol
|      Sektor - wartosci kata min i max sa liczone w strefach
|    01-02-97: M.Postol
|      Inicja danych przeniesiona do ClearContiners
|   26-02-97: M.Postol
|    wprowadzilem mozliwosc ustawiania procedur dla obliczania predkosci i kata 
|    dla symulatora wew.
|    RefDis zle wyliczany dla programow arch.
|
|  Copyright (C), CAS LODZ POLAND.
|  TEL: 42' 862 547, 42' 87 80 44 FAX/TEL: 42' 84 48 40
|
**********************************************************************)
(*.F+ *)

IMPLEMENTATION MODULE G_Odb [ 0 ];

  IMPORT ScannerI;
  
  FROM CommonTypes IMPORT
    (* TYPE *) GlownyOdbiornikT, signTab, OdnDlaPomOdlT,
    (* CONST *) NilValI, NAVA_Aud_flg, GSA_flg, SigNilVal, Com_Aud_flg,
                iMkrFlgPosA, iMkrFlgPosB, mMkrFlgPosA, mMkrFlgPosB, oMkrFlgPosA
                , oMkrFlgPosB, DisNilVal;

  FROM ScannerI IMPORT
    (* VAR *) RefAlfa, Simul, Delta, ABOVESL,
    (* PROCEDURE *) SetEvalPROC, AssSim_Dis, AssSim_Alfa;

  FROM MathLib0 IMPORT
    real;

  FROM DGH_utils IMPORT
    ReadValue, BinInputSignal, TurnOnGSSig, BinaryValSet;

  FROM SpecConv IMPORT
    GorszeBoMniejsze, GorszeBoWieksze, GorszeBoBlisze, entierCheck;

  FROM ILS_EvalProcedures IMPORT
    (* PROCEDURE *) Azym_Addsmpl, Azym_Clear, AzDif0_Addsmpl, Az0_Clear,
                    Dif0_Clear, MkrLnth_Clear, AzymAV_Addsmpl, AzymAV_Clear,
                    CountAzym, AV_Clear, AV_Addsmpl, CountDelAzym, CountAzymOsi
                    , SetPathAngle,
    (* TYPE *) Azym_ConT, AzDif0_ConT, AzymAV_ConT, MkrLnth_ConT, CountDif,
               Avr_ConT;

  FROM G_results IMPORT
    anRes;

  FROM ScreenCTypes IMPORT
    RodzWykr;

  FROM SYSTEM IMPORT
    ADR;

  FROM L_CommonTypes IMPORT
    NumStrefy, NumPunktu, GetNumStrefy;

  FROM G_CommonTypes IMPORT
    znakGora;

  FROM ILS_ZoneMngmnt IMPORT
    G_LstPToBeTraced;

  FROM Random IMPORT
    RandomInt;

  FROM Kalibracja IMPORT
    InputSignal;

  FROM MathLib0 IMPORT
    entier;
    
  CONST
    locAlignment = 0.0;
    MaxPos       = 12;
    CZAS_PROBKI  = 1.0/3600.0 (*s*) / 5.0 (*probek/s*) *500.0;

  TYPE
    ProcIdxT =
      [0 .. MaxPos];

  VAR
    CollectData  : BOOLEAN;
    displSens    : REAL;
    pathAng      : REAL;
    secWith      : REAL;
    currOffR     : REAL;
    currOffI     : INTEGER;
    currZone     : NumStrefy;
    procTable    : ARRAY [0 .. MaxPos] OF PROC;
    procIdx      : ProcIdxT;
    covSecMin    : INTEGER;
    covSecMax    : INTEGER;
    Az75_150_Con : ARRAY GlownyOdbiornikT OF Azym_ConT;
    Az75_90_Con  : ARRAY GlownyOdbiornikT OF Azym_ConT;
    Az0_Con      : ARRAY GlownyOdbiornikT OF AzDif0_ConT;
    Dif0_Con     : ARRAY GlownyOdbiornikT OF AzDif0_ConT;
    AzymAV_Con   : ARRAY GlownyOdbiornikT OF AzymAV_ConT;
    oMkrL_Con    : ARRAY GlownyOdbiornikT OF MkrLnth_ConT;
    mMkrL_Con    : ARRAY GlownyOdbiornikT OF MkrLnth_ConT;
    iMkrL_Con    : ARRAY GlownyOdbiornikT OF MkrLnth_ConT;
    DifAv_Con    : ARRAY GlownyOdbiornikT OF Avr_ConT;
    AzOsiAv_Con  : ARRAY GlownyOdbiornikT OF Avr_ConT;
    sigNilVal    : signTab;
    newZone      : BOOLEAN;
    myDistTT     : INTEGER;
    DisSigma     : REAL;
    currPredkosc : REAL;
    simEl        : INTEGER;
    
  PROCEDURE DummyProc;

  BEGIN
  END DummyProc;

  PROCEDURE Dif_CP;
  VAR
    rec : GlownyOdbiornikT;

  BEGIN
    FOR rec := goA TO goB DO
      EvalVal[Dif_OS, rec] := CountDif(RefAlfa, devG[rec], displSens, pathAng);
    END (* for rec *);
  END Dif_CP;

  PROCEDURE SS_CP;

  BEGIN
    EvalVal[SS_OS] := agc;
  END SS_CP;

  PROCEDURE ModG_CP;
  VAR
    rec : GlownyOdbiornikT;

  BEGIN
    FOR rec := goA TO goB DO
      EvalVal[Mod_OS, rec] := mod[rec];
    END (* for rec *);
  END ModG_CP;

  PROCEDURE Dew_CP;
  VAR
    rec : GlownyOdbiornikT;

  BEGIN
    FOR rec := goA TO goB DO
      EvalVal[Dew_OS, rec] := devG[rec];
    END (* for rec *);
  END Dew_CP;

  PROCEDURE DewLoc_CP;
  VAR
    rec : GlownyOdbiornikT;

  BEGIN
    FOR rec := goA TO goB DO
      EvalVal[DewLoc_OS, rec] := devL[rec];
    END (* for rec *);
  END DewLoc_CP;

  PROCEDURE AzOsiAv_CP;
  VAR
    rec  : GlownyOdbiornikT;
    azym : INTEGER;

  BEGIN
    FOR rec := goA TO goB DO
      azym := CountAzymOsi(RefAlfa, devG[rec], displSens);
      EvalVal[AzOsiAv_OS, rec] := AV_Addsmpl(AzOsiAv_Con[rec], azym, newZone);
      IF newZone  THEN
        EvalVal[AzOsiMin_OS, rec] := SigNilVal;
        EvalVal[AzOsiMax_OS, rec] := SigNilVal;
      END;
      GorszeBoMniejsze(EvalVal[AzOsiMin_OS, rec], azym);
      GorszeBoWieksze(EvalVal[AzOsiMax_OS, rec], azym);
    END (* for rec *);
  END AzOsiAv_CP;

  PROCEDURE DewOff_CP;
  VAR
    rec : GlownyOdbiornikT;

  BEGIN
    FOR rec := goA TO goB DO
      IF devG[rec] = SigNilVal
      THEN
        EvalVal[DewOff_OS, rec] := SigNilVal;
      ELSE
        EvalVal[DewOff_OS, rec] := devG[rec] - currOffI;
      END (* if devG *);
    END (* for rec *);
  END DewOff_CP;

  PROCEDURE DifAv0_CP;
  VAR
    rec : GlownyOdbiornikT;
    ang : INTEGER;

  BEGIN
    FOR rec := goA TO goB DO
      ang := SigNilVal;
      AzDif0_Addsmpl(Dif0_Con[rec], RefAlfa, devG[rec], ang);
      GorszeBoBlisze(EvalVal[DifAv0_OS, rec], ang, 0);
    END (* for rec *);
  END DifAv0_CP;

  PROCEDURE DifAZ_CP;
  VAR
    rec : GlownyOdbiornikT;

  BEGIN
    FOR rec := goA TO goB DO
      EvalVal[DifAZ_OS, rec] := CountDelAzym(RefAlfa, devG[rec], currOffR,
                                             locAlignment, secWith);
    END (* for rec *);
  END DifAZ_CP;

  PROCEDURE Az75_150_CP;
  VAR
    rec : GlownyOdbiornikT;
    ang : INTEGER;

  BEGIN
    FOR rec := goA TO goB DO
      ang := SigNilVal;
      Azym_Addsmpl(Az75_150_Con[rec], RefAlfa, devG[rec], ang);
      GorszeBoBlisze(EvalVal[Az75_150_OS, rec], ang, 0);
    END (* for rec *);
  END Az75_150_CP;

  PROCEDURE Az75_90_CP;
  VAR
    rec : GlownyOdbiornikT;
    ang : INTEGER;

  BEGIN
    FOR rec := goA TO goB DO
      ang := SigNilVal;
      Azym_Addsmpl(Az75_90_Con[rec], RefAlfa, devG[rec], ang);
      GorszeBoBlisze(EvalVal[Az75_90_OS, rec], ang, 0);
    END (* foor rec *);
  END Az75_90_CP;

  PROCEDURE Az0_CP;
  VAR
    rec : GlownyOdbiornikT;
    ang : INTEGER;

  BEGIN
    FOR rec := goA TO goB DO
      ang := SigNilVal;
      IF RefAlfa <> SigNilVal
      THEN
        AzDif0_Addsmpl(Az0_Con[rec], RefAlfa, devG[rec], ang);
      END (* if RefAlfa *);
      GorszeBoBlisze(EvalVal[Az0_OS, rec], ang, anRes.ustawOsi);
    END (* for rec *);
  END Az0_CP;

  PROCEDURE Ofset_CP;

  BEGIN
    (* procedura intencjonalnie pusta *)
  END Ofset_CP;

  (*.F- *)
  PROCEDURE AzAv_CP;
  VAR
    rec    : GlownyOdbiornikT;
    currAz : INTEGER;
  BEGIN
    FOR rec := goA TO goB DO
      AzymAV_Addsmpl( AzymAV_Con[rec], RefAlfa, devG[rec],
                      EvalVal[AzAv_OS, rec], newZone
                     );
      IF newZone THEN
        EvalVal[AzMax_OS, rec] := SigNilVal;
        EvalVal[AzMin_OS, rec] := SigNilVal;
      END (* if *);
      currAz := CountAzym(RefAlfa, devG[rec], currOffR, locAlignment);
      GorszeBoWieksze(EvalVal[AzMax_OS, rec],  currAz);
      GorszeBoMniejsze(EvalVal[AzMin_OS, rec], currAz);
    END (* for rec *);
  END AzAv_CP;
  (*.F+ *)

  PROCEDURE Alt_CP;

  BEGIN
    EvalVal[Alt_OS, goA] := ABOVESL;
    EvalVal[Alt_OS, goB] := ABOVESL;
  END Alt_CP;

  PROCEDURE Zone_CP;

  BEGIN
    IF CollectData
    THEN
      EvalVal[Zone_OS, goA] := ORD(currZone);
      EvalVal[Zone_OS, goB] := ORD(currZone);
    ELSE
      EvalVal[Zone_OS, goA] := ORD(ns_no);
      EvalVal[Zone_OS, goB] := ORD(ns_no);
    END (* if CollectData *);
  END Zone_CP;

  PROCEDURE Elew_CP;

  BEGIN
    IF RefAlfa = SigNilVal THEN
      EvalVal[Elew_OS, goA] := SigNilVal;
      EvalVal[Elew_OS, goB] := SigNilVal;
    ELSE
      EvalVal[Elew_OS, goA] := RefAlfa - anRes.ustawOsi;
      EvalVal[Elew_OS, goB] := RefAlfa - anRes.ustawOsi;
    END;
  END Elew_CP;

  PROCEDURE ClearContiners
            (    offset : INTEGER);
  VAR
    rec    : GlownyOdbiornikT;
    sigIdx : SigEval;

  BEGIN
    WITH anRes DO
      FOR rec := goA TO goB DO
        FOR sigIdx := MIN(SigEval) TO MAX(SigEval) DO
          EvalVal[sigIdx, rec] := SigNilVal;
        END (* for sigIdx *);
        Azym_Clear(Az75_150_Con[rec], -znakGora * 750, 0);
        Azym_Clear(Az75_90_Con[rec], znakGora * 750, 0);
        Az0_Clear(Az0_Con[rec], displSens);
        Dif0_Clear(Dif0_Con[rec], displSens);
        AzymAV_Clear(AzymAV_Con[rec], offset, 0);
        MkrLnth_Clear(oMkrL_Con[rec]);
        MkrLnth_Clear(mMkrL_Con[rec]);
        MkrLnth_Clear(iMkrL_Con[rec]);
        AV_Clear(DifAv_Con[rec]);
        AV_Clear(AzOsiAv_Con[rec]);
        EvalVal[Ofset_OS, rec] := offset;
      END (* for rec *);
    END (* with anRes *);
  END ClearContiners;

  PROCEDURE PoprawDane();
  VAR
    idx : INTEGER;

  BEGIN
    Dif_CP;
    SS_CP;
    Dew_CP;
    ModG_CP;
    Zone_CP;
    IF ScannerI.RefDis = DisNilVal  THEN
      RefDis := DisNilVal;
    ELSIF ScannerI.RefDis > CARDINAL(myDistTT) THEN
      RefDis := ScannerI.RefDis - CARDINAL(myDistTT);
    ELSE
      RefDis := CARDINAL(myDistTT) - ScannerI.RefDis;
    END;
    IF CollectData THEN
      FOR idx := MIN(ProcIdxT) TO INTEGER(procIdx) - 1 DO
        procTable[idx];
      END (* for idx *);
    END;
  END PoprawDane;

  PROCEDURE Oblicz;

    PROCEDURE ReadNAV;
    VAR
      rec : GlownyOdbiornikT;

    BEGIN (* ReadNAV *)
      navOdbFlg := {};
      FOR rec := goA TO goB DO
        navFlg[rec] := BinaryValSet(SFLGforNAV, rec);
        gsFlg[rec] := BinaryValSet(SFLGforGS, rec);
        iMkrFlg[rec] := BinaryValSet(InnMKR, rec);
        mMkrFlg[rec] := BinaryValSet(MidMKR, rec);
        oMkrFlg[rec] := BinaryValSet(OutMKR, rec);
        audio_L[rec] := BinaryValSet(NAVAudio, rec);
        IF audio_L[rec]
        THEN
          INCL(navOdbFlg, NAVA_Aud_flg + ORD(rec));
        END (* if NAV *);
        audio_V[rec] := BinaryValSet(COMAudio, rec);
        IF iMkrFlg[rec]
        THEN
          IF rec = goA
          THEN
            INCL(navOdbFlg, iMkrFlgPosA);
          ELSE
            INCL(navOdbFlg, iMkrFlgPosB);
          END (* if rec *);
        END (* if NAV *);
        IF mMkrFlg[rec]
        THEN
          IF rec = goA
          THEN
            INCL(navOdbFlg, mMkrFlgPosA);
          ELSE
            INCL(navOdbFlg, mMkrFlgPosB);
          END (* if rec *);
        END (* if NAV *);
        IF oMkrFlg[rec]
        THEN
          IF rec = goA
          THEN
            INCL(navOdbFlg, oMkrFlgPosA);
          ELSE
            INCL(navOdbFlg, oMkrFlgPosB);
          END (* if rec *);
        END (* if NAV *);
        IF audio_V[rec]
        THEN
          INCL(navOdbFlg, Com_Aud_flg + ORD(rec));
        END (* if NAV *);
        IF NOT Simul
        THEN
          IF NOT navFlg[rec]
          THEN
            devL[rec] := NilValI;
          ELSE
            ReadValue(devL[rec], LocDev, rec, 10.0);
          END (* if NAV *);
          IF NOT gsFlg[rec]
          THEN
            devG[rec] := NilValI;
            INCL(navOdbFlg, GSA_flg + ORD(rec));
          ELSE
            ReadValue(devG[rec], GsDev, rec, 10.0);
          END (* if NAV *);
          ReadValue(mod[rec], GsPrcMod, rec, 10.0);
          ReadValue(agc[rec], GsAgc, rec, 1.0);
          ReadValue(agcM[rec], MkrAgc, rec, 1.0);
        ELSE
          navFlg[rec] := TRUE;
          gsFlg[rec] := TRUE;
          devL[rec] := RandomInt(100);
          devG[rec] := currOffI + RefDisTT (* RandomInt(100) *);
          mod[rec] := RandomInt(30)+800;
          IF FALSE AND ODD(RefDisTT  DIV 10) THEN
            agc[rec] := 10(* + RandomInt(1000)+ 3000*);
          ELSE
            agc[rec] := 1000(* + RandomInt(1000)+ 3000*);
          END;
          agcM[rec] := RandomInt(1000) + 3000;
        END (* if Simul *);
      END (* for rec *);
      IF (Delta[poGPS] = DisNilVal) OR (Delta[poGPS] > MAX(INTEGER))
      THEN
        RefDisTT := SigNilVal;
      ELSE
        RefDisTT := (INTEGER(Delta[poGPS]) - myDistTT) DIV 50;
      END (* if *);
      
    END ReadNAV;

  BEGIN (* Oblicz *)
    ReadNAV;
    PoprawDane;
    newZone := FALSE;
  END Oblicz;

  PROCEDURE TurnOn
            (    val  : SigEval;
                 wykr : RodzWykr );

  BEGIN
    IF val = Non_OS
    THEN
      RETURN;
    END (* if val *);
    CASE wykr OF
      WykMain :
        WykMainVal := ADR(EvalVal[val]);
      |
      Wyk1 :
        Wyk1Val := ADR(EvalVal[val]);
      |
      Wyk2 :
        Wyk2Val := ADR(EvalVal[val]);
      |
      Wyk3 :
        Wyk3Val := ADR(EvalVal[val]);
    ELSE
    END (* case wykr *);
    CASE val OF
      SS_OS :
        RETURN;
      |
      Mod_OS :
        RETURN;
        procTable[procIdx] := ModG_CP;
      |
      Dif_OS :
        RETURN;
      |
      Dew_OS :
        RETURN;
      |
      DewLoc_OS :
        procTable[procIdx] := DewLoc_CP;
      |
      AzOsiAv_OS :
        procTable[procIdx] := AzOsiAv_CP;
      |
      AzOsiMin_OS, AzOsiMax_OS :
        RETURN;
        (* parametry liczone razem w AzOsiAv_CP *);
      |
      DewOff_OS :
        procTable[procIdx] := DewOff_CP;
      |
      DifAZ_OS :
        procTable[procIdx] := DifAZ_CP;
      |
      Ofset_OS :
        procTable[procIdx] := Ofset_CP;
      |
      AzMin_OS, AzMax_OS :
        (* wartosci wyznaczane w AzAv_OS *);
      |
      AzAv_OS :
        procTable[procIdx] := AzAv_CP;
      |
      DifAv0_OS :
        procTable[procIdx] := DifAv0_CP;
      |
      Az75_90_OS :
        procTable[procIdx] := Az75_90_CP;
      |
      Az75_150_OS :
        procTable[procIdx] := Az75_150_CP;
      |
      Az0_OS :
        procTable[procIdx] := Az0_CP;
      |
      Alt_OS :
        procTable[procIdx] := Alt_CP;
      |
      Zone_OS :
        RETURN;
      |
      Elew_OS :
        procTable[procIdx] := Elew_CP;
    END (* case anRes.procedure *);
    INC(procIdx);
  END TurnOn;

  PROCEDURE Start;

  BEGIN
    ClearContiners(currOffI);
    CollectData := TRUE;
    currZone := ns_toA;
  END Start;

  PROCEDURE Zatrzymaj;
    (* zatrzymuje zliczanie AV,MP,MM *)

  BEGIN
    CollectData := FALSE;
  END Zatrzymaj;

  PROCEDURE Wznow;
    (* wznawia zliczanie AV,MP,MM *)

  BEGIN
    CollectData := TRUE;
  END Wznow;

  PROCEDURE Sim_Dis() : CARDINAL;
  VAR
    res: INTEGER;
  BEGIN
    DisSigma := DisSigma - CZAS_PROBKI * currPredkosc;
    IF entierCheck(DisSigma, res) AND (res > 0) THEN
      RETURN res;
    ELSE
      RETURN DisNilVal;
    END;
  END Sim_Dis;

  PROCEDURE Sim_Alfa() : INTEGER;
  VAR
    res: INTEGER;
  BEGIN
    RETURN simEl;
  END Sim_Alfa;

  PROCEDURE IniData
            (    szerSektora  : INTEGER;
                 offset       : INTEGER;
                 curCovSecMax : INTEGER;
                 curCovSecMin : INTEGER;
                 distTT       : INTEGER );
  VAR
    rec    : GlownyOdbiornikT;
    idx    : CARDINAL;

  BEGIN (* IniData *)
    covSecMax := curCovSecMax;
    covSecMin := curCovSecMin;
    FOR idx := 0 TO MaxPos DO
      procTable[idx] := DummyProc;
    END (* for idx *);
    myDistTT := distTT;
    procIdx := 0;
    Zatrzymaj;
    FOR rec := goA TO goB DO
      navFlg[rec] := FALSE;
      gsFlg[rec] := FALSE;
      iMkrFlg[rec] := FALSE;
      mMkrFlg[rec] := FALSE;
      oMkrFlg[rec] := FALSE;
      audio_L[rec] := FALSE;
      audio_V[rec] := FALSE;
      devL[rec] := NilValI;
      devG[rec] := NilValI;
      mod[rec] := NilValI;
      agcM[rec] := NilValI;
    END (* for rec *);
    currZone := ns_toA;
    currOffR := real(offset);
    currOffI := offset;
    secWith := 2.0 * FLOAT(szerSektora);
    displSens := 3000.0 / secWith;
    SetPathAngle(anRes.ustawOsi, znakGora);
    pathAng := FLOAT(anRes.ustawOsi);
    WykMainVal := ADR(sigNilVal);
    Wyk1Val := ADR(sigNilVal);
    Wyk2Val := ADR(sigNilVal);
    Wyk3Val := ADR(sigNilVal);
    ClearContiners(currOffI);
    TurnOnGSSig;
    currPredkosc := 150.0;
    WITH anRes DO
      simEl := entier( real(ustawOsi)+
                       real(znakGora)*real(secWith)*real(offset)/1500.0);
    END;
    DisSigma  := 6.0 * 500.0;
    AssSim_Dis( Sim_Dis );
    AssSim_Alfa( Sim_Alfa );
    SetEvalPROC(Oblicz, TRUE);
  END IniData;
  
  PROCEDURE AktStrefa() : NumStrefy;

  BEGIN
    RETURN currZone
  END AktStrefa;

  PROCEDURE NastStrefa
            (    zne : NumPunktu );

  BEGIN
    IF zne = G_LstPToBeTraced()
    THEN
      currZone := ns_no;
      Zatrzymaj;
    ELSE
      newZone := currZone <> GetNumStrefy(zne);
      currZone := GetNumStrefy(zne)
    END (* if zne *);
  END NastStrefa;

  VAR
    rec : GlownyOdbiornikT;

BEGIN
  RefDis := DisNilVal;
  RefDisTT := SigNilVal;
  currZone := ns_no;
  newZone := FALSE;
  FOR rec := goA TO goB DO
    sigNilVal[rec] := SigNilVal;
  END (* for rec *);
END G_Odb.
