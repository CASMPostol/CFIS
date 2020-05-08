(*.F- *)
(**********************************************************************
|  Title   : Procedury wyliczajace parametry online dla dobiornika nav.
|  Author  : M.Postol
|  System  : LOGITECH MODULA-2/86
|  History :
|    27-10-96: M.Postol
|      created
|    12-21-96 00:09am: MM
|      Psiakrew, uprasza sie o zaniechanie bezmyslnego grzebania
|      Ktos (MP!) przeniosl czesc procedury PoprawDane i co? I 2h w plecy...
|    30-01-97: M.Postol
|      Sektor - wartosci kata min i max sa liczone w strefach
|    01-02-97: M.Postol
|      Inicja danych przeniesiona do ClearContiners
|    13-05-97: M.Postol
|      Zmiany dla symulatora wew.
|
|  Copyright (C), CAS LODZ POLAND.
|  TEL: 42' 862 547, 42' 87 80 44 FAX/TEL: 42' 84 48 40
|
**********************************************************************)
(*.F+ *)

IMPLEMENTATION MODULE L_Odb [ 0 ];

  FROM CommonTypes IMPORT
    (* TYPE *) GlownyOdbiornikT, signTab, OdnDlaPomOdlT,
    (* CONST *) NilValI, NAVA_flg, NAVA_Aud_flg, SigNilVal, Com_Aud_flg,
                iMkrFlgPosA, iMkrFlgPosB, mMkrFlgPosA, mMkrFlgPosB, oMkrFlgPosA
                , oMkrFlgPosB, DisNilVal, znakSL;

  FROM ScannerI IMPORT
    (* VAR *) RefAlfa, RefDis, Simul, Delta,
    (* PROCEDURE *) SetEvalPROC;

  FROM MathLib0 IMPORT
    real;

  FROM DGH_utils IMPORT
    ReadValue, BinInputSignal, TurnOnLOCSig, BinaryValSet;

  FROM SpecConv IMPORT
    GorszeBoMniejsze, GorszeBoWieksze, GorszeBoBlisze;

  FROM ILS_EvalProcedures IMPORT
    (* PROCEDURE *) Azym_Addsmpl, Azym_Clear, AzDif0_Addsmpl, Az0_Clear,
                    Dif0_Clear, MkrLnth_AddSmpl, MkrLnth_Clear, AzymAV_Addsmpl,
                    AzymAV_Clear, CountAzym, AV_Clear, AV_Addsmpl, SetPathAngle
                    , CountDelAzym,
    (* TYPE *) Azym_ConT, AzDif0_ConT, AzymAV_ConT, MkrLnth_ConT, CountDif,
               Avr_ConT;

  FROM L_results IMPORT
    anRes;

  FROM ScreenCTypes IMPORT
    RodzWykr;

  FROM SYSTEM IMPORT
    ADR;

  FROM L_CommonTypes IMPORT
    NumStrefy, NumPunktu, GetNumStrefy;

  FROM ILS_ZoneMngmnt IMPORT
    L_LstPToBeTraced;

  FROM Random IMPORT
    RandomInt;

  FROM Kalibracja IMPORT
    InputSignal;

  CONST
    locAlignment = 0.0;
    MaxPos       = 12;

  TYPE
    ProcIdxT =
      [0 .. MaxPos];

  VAR
    CollectData   : BOOLEAN;
    displSens     : REAL;
    secWith       : REAL;
    currOffR      : REAL;
    currOffI      : INTEGER;
    currZone      : NumStrefy;
    procTable     : ARRAY [0 .. MaxPos] OF PROC;
    procIdx       : ProcIdxT;
    covSecMin     : INTEGER;
    covSecMax     : INTEGER;
    Az150_150_Con : ARRAY GlownyOdbiornikT OF Azym_ConT;
    Az75_150_Con  : ARRAY GlownyOdbiornikT OF Azym_ConT;
    Az150_90_Con  : ARRAY GlownyOdbiornikT OF Azym_ConT;
    Az75_90_Con   : ARRAY GlownyOdbiornikT OF Azym_ConT;
    Az0_Con       : ARRAY GlownyOdbiornikT OF AzDif0_ConT;
    Dif0_Con      : ARRAY GlownyOdbiornikT OF AzDif0_ConT;
    AzymAV_Con    : ARRAY GlownyOdbiornikT OF AzymAV_ConT;
    oMkrL_Con     : ARRAY GlownyOdbiornikT OF MkrLnth_ConT;
    mMkrL_Con     : ARRAY GlownyOdbiornikT OF MkrLnth_ConT;
    iMkrL_Con     : ARRAY GlownyOdbiornikT OF MkrLnth_ConT;
    DifAv_Con     : ARRAY GlownyOdbiornikT OF Avr_ConT;
    sigNilVal     : signTab;
    newZone       : BOOLEAN;
    myDistTT      : INTEGER;

  PROCEDURE DummyProc;

  BEGIN
  END DummyProc;

  PROCEDURE Dif_CP;
  VAR
    rec : GlownyOdbiornikT;

  BEGIN
    FOR rec := goA TO goB DO
      EvalVal[Dif_OS, rec] := CountDif(RefAlfa, devL[rec], displSens, 0.0);
    END (* for rec *);
  END Dif_CP;

  PROCEDURE SS_CP;

  BEGIN
    EvalVal[SS_OS] := agcL;
  END SS_CP;

  PROCEDURE ModL_CP;
  VAR
    rec : GlownyOdbiornikT;

  BEGIN
    FOR rec := goA TO goB DO
      EvalVal[ModL_OS, rec] := modL[rec];
    END (* for rec *);
  END ModL_CP;

  (*.F- *)
  PROCEDURE DifAv_CP;
  VAR
    rec : GlownyOdbiornikT;

  BEGIN
    FOR rec := goA TO goB DO
      EvalVal[DifAv_OS, rec] := AV_Addsmpl( DifAv_Con[rec],
                                            EvalVal[Dif_OS, rec],
                                            newZone
                                           );
    END (* for rec *);
  END DifAv_CP;
  (*.F+ *)

  PROCEDURE Dew_CP;
  VAR
    rec : GlownyOdbiornikT;

  BEGIN
    FOR rec := goA TO goB DO
      EvalVal[Dew_OS, rec] := devL[rec];
    END (* for rec *);
  END Dew_CP;

  PROCEDURE DewOff_CP;
  VAR
    rec : GlownyOdbiornikT;

  BEGIN
    FOR rec := goA TO goB DO
      IF devL[rec] = SigNilVal
      THEN
        EvalVal[DewOff_OS, rec] := SigNilVal;
      ELSE
        EvalVal[DewOff_OS, rec] := devL[rec] - currOffI;
      END (* if devL *);
    END (* for rec *);
  END DewOff_CP;

  PROCEDURE DifMin_CP;
  VAR
    rec : GlownyOdbiornikT;

  BEGIN
    FOR rec := goA TO goB DO
      GorszeBoMniejsze(EvalVal[DifMin_OS, rec], EvalVal[Dif_OS, rec]);
    END (* for rec *);
  END DifMin_CP;

  PROCEDURE DifMax_CP;
  VAR
    rec : GlownyOdbiornikT;

  BEGIN
    FOR rec := goA TO goB DO
      GorszeBoWieksze(EvalVal[DifMax_OS, rec], EvalVal[Dif_OS, rec]);
    END (* for rec *);
  END DifMax_CP;

  PROCEDURE DifAv0_CP;
  VAR
    rec : GlownyOdbiornikT;
    ang : INTEGER;

  BEGIN (* DifAv0_CP *)
    FOR rec := goA TO goB DO
      ang := SigNilVal;
      AzDif0_Addsmpl(Dif0_Con[rec], RefAlfa, devL[rec], ang);
      GorszeBoBlisze(EvalVal[DifAv0_OS, rec], ang, 0);
    END (* for rec *);
  END DifAv0_CP;

  PROCEDURE DifAZ_CP;
  VAR
    rec : GlownyOdbiornikT;

  BEGIN
    FOR rec := goA TO goB DO
      EvalVal[DifAZ_OS, rec] := CountDelAzym(RefAlfa, devL[rec], currOffR,
                                             locAlignment, secWith);
    END (* for rec *);
  END DifAZ_CP;

  PROCEDURE Az150_150_CP;
  VAR
    rec : GlownyOdbiornikT;
    ang : INTEGER;

  BEGIN
    FOR rec := goA TO goB DO
      ang := SigNilVal;
      Azym_Addsmpl(Az150_150_Con[rec], RefAlfa, devL[rec], ang);
      GorszeBoBlisze(EvalVal[Az150_150_OS, rec], ang, 0);
    END (* for rec *);
  END Az150_150_CP;

  PROCEDURE Az75_150_CP;
  VAR
    rec : GlownyOdbiornikT;
    ang : INTEGER;

  BEGIN
    FOR rec := goA TO goB DO
      ang := SigNilVal;
      Azym_Addsmpl(Az75_150_Con[rec], RefAlfa, devL[rec], ang);
      GorszeBoBlisze(EvalVal[Az75_150_OS, rec], ang, 0);
    END (* for rec *);
  END Az75_150_CP;

  PROCEDURE Az150_90_CP;
  VAR
    rec : GlownyOdbiornikT;
    ang : INTEGER;

  BEGIN
    FOR rec := goA TO goB DO
      ang := SigNilVal;
      Azym_Addsmpl(Az150_90_Con[rec], RefAlfa, devL[rec], ang);
      GorszeBoBlisze(EvalVal[Az150_90_OS, rec], ang, 0);
    END (* for rec *);
  END Az150_90_CP;

  PROCEDURE Az75_90_CP;
  VAR
    rec : GlownyOdbiornikT;
    ang : INTEGER;

  BEGIN
    FOR rec := goA TO goB DO
      ang := SigNilVal;
      Azym_Addsmpl(Az75_90_Con[rec], RefAlfa, devL[rec], ang);
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
      AzDif0_Addsmpl(Az0_Con[rec], RefAlfa, devL[rec], ang);
      GorszeBoBlisze(EvalVal[Az0_OS, rec], ang, 0);
    END (* for rec *);
  END Az0_CP;

  PROCEDURE Ofset_CP;

  BEGIN
    (* procedura intencjonalnie pusta *)
  END Ofset_CP;

  (*.F- *)

  PROCEDURE AzMax_CP;
  VAR
    rec    : GlownyOdbiornikT;
    currAz : INTEGER;

  BEGIN
    FOR rec := goA TO goB DO
      AzymAV_Addsmpl( AzymAV_Con[rec], RefAlfa, devL[rec],
                      EvalVal[AzAv_OS, rec], newZone
                     );
      currAz := CountAzym(RefAlfa, devL[rec], currOffR, locAlignment);
      IF newZone THEN
        EvalVal[AzMax_OS, rec] := SigNilVal;
        EvalVal[AzMin_OS, rec] := SigNilVal;
      END (* if *);
      GorszeBoWieksze(EvalVal[AzMax_OS, rec], currAz );
      GorszeBoMniejsze(EvalVal[AzMin_OS, rec], currAz );
    END (* for rec *);
  END AzMax_CP;

  (*.F+ *)

  PROCEDURE SS150_Min_CP;
  VAR
    rec : GlownyOdbiornikT;

  BEGIN
    FOR rec := goA TO goB DO
      IF (RefAlfa < -covSecMin) AND (RefAlfa > -covSecMax)
      THEN
        GorszeBoMniejsze(EvalVal[SS150_Min_OS, rec], agcL[rec])
      END (* if *);
    END (* for rec *);
  END SS150_Min_CP;

  PROCEDURE SS0_Min_CP;
  VAR
    rec : GlownyOdbiornikT;

  BEGIN
    FOR rec := goA TO goB DO
      IF (RefAlfa > -1000) AND (RefAlfa < 1000)
      THEN
        GorszeBoMniejsze(EvalVal[SS0_Min_OS, rec], agcL[rec])
      END (* if *);
    END (* for rec *);
  END SS0_Min_CP;

  PROCEDURE SS90_Min_CP;
  VAR
    rec : GlownyOdbiornikT;

  BEGIN
    FOR rec := goA TO goB DO
      IF (RefAlfa > covSecMin) AND (RefAlfa < covSecMax)
      THEN
        GorszeBoMniejsze(EvalVal[SS90_Min_OS, rec], agcL[rec])
      END (* if *);
    END (* for rec *);
  END SS90_Min_CP;

  PROCEDURE SS_Mkr_CP;
  VAR
    rec : GlownyOdbiornikT;

  BEGIN
    FOR rec := goA TO goB DO
      EvalVal[SS_Mkr_OS, rec] := agcM[rec];
    END (* for rec *);
  END SS_Mkr_CP;

  (*.F- *)
  PROCEDURE OMkrL_CP;
  VAR
    rec : GlownyOdbiornikT;

  BEGIN
    FOR rec := goA TO goB DO
      GorszeBoWieksze(EvalVal[OMkrL_OS, rec],
                      MkrLnth_AddSmpl(oMkrL_Con[rec], oMkrFlg[rec], RefDis));
    END (* for rec *);
  END OMkrL_CP;

  PROCEDURE MMkrL_CP;
  VAR
    rec : GlownyOdbiornikT;

  BEGIN
    FOR rec := goA TO goB DO
      GorszeBoWieksze(EvalVal[MMkrL_OS, rec],
                      MkrLnth_AddSmpl(mMkrL_Con[rec], mMkrFlg[rec], RefDis));
    END (* for rec *);
  END MMkrL_CP;

  PROCEDURE IMkrL_OS_CP;
  VAR
    rec : GlownyOdbiornikT;

  BEGIN
    FOR rec := goA TO goB DO
      GorszeBoWieksze(EvalVal[IMkrL_OS, rec],
                      MkrLnth_AddSmpl(iMkrL_Con[rec], iMkrFlg[rec], RefDis));
    END (* for rec *);
  END IMkrL_OS_CP;
  (*.F+ *)

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

  PROCEDURE ClearContiners
            (    offset : INTEGER);
  VAR
    rec : GlownyOdbiornikT;
    sigIdx : SigEval;

  BEGIN
    WITH anRes DO
      FOR rec := goA TO goB DO
        FOR sigIdx := MIN(SigEval) TO MAX(SigEval) DO
          EvalVal[sigIdx, rec] := SigNilVal;
        END (* for sigIdx *);
        Azym_Clear(Az150_150_Con[rec], -1500, ustawOsi);
        Azym_Clear(Az75_150_Con[rec], -750, ustawOsi);
        Azym_Clear(Az150_90_Con[rec], 1500, ustawOsi);
        Azym_Clear(Az75_90_Con[rec], 750, ustawOsi);
        Az0_Clear(Az0_Con[rec], displSens);
        Dif0_Clear(Dif0_Con[rec], displSens);
        AzymAV_Clear(AzymAV_Con[rec], offset, ustawOsi);
        MkrLnth_Clear(oMkrL_Con[rec]);
        MkrLnth_Clear(mMkrL_Con[rec]);
        MkrLnth_Clear(iMkrL_Con[rec]);
        AV_Clear(DifAv_Con[rec]);
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
    Zone_CP;
    IF CollectData THEN
      FOR idx := MIN(ProcIdxT) TO INTEGER(procIdx) - 1 DO
        procTable[idx];
      END (* for idx *);
    END;
  END PoprawDane;

  VAR
    Simul_Licz : CARDINAL;

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
            INCL(navOdbFlg, NAVA_flg + ORD(rec));
          ELSE
            ReadValue(devL[rec], LocDev, rec, 10.0);
          END (* if NAV *);
          IF NOT gsFlg[rec]
          THEN
            devG[rec] := NilValI;
            (* <GS INCL(navOdbFlg, GSA_flg + ORD(rec)); GS>*)
          ELSE
            ReadValue(devG[rec], GsDev, rec, 10.0);
          END (* if NAV *);
          ReadValue(modL[rec], LocPrcMod, rec, 10.0);
          ReadValue(agcL[rec], LocAgc, rec, 1.0);
          ReadValue(agcM[rec], MkrAgc, rec, 1.0);
        ELSE
          IF (Simul_Licz MOD 10) > 5  THEN
            navFlg[rec] := FALSE;
            INCL(navOdbFlg, NAVA_flg + ORD(rec));
          ELSE
            navFlg[rec] := TRUE;
          END;
          gsFlg[rec] := TRUE;
          devL[rec] := RandomInt(100);
          devG[rec] := RandomInt(100);
          modL[rec] := RandomInt(30)+800;
          agcL[rec] := RandomInt(1000) + 3000;
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
    (* $R-*)
    INC( Simul_Licz );
    (* $R=*)
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
      Dif_OS :
        RETURN;
      |
      SS_OS :
        RETURN;
      |
      ModL_OS :
        procTable[procIdx] := ModL_CP;
      |
      DifAv_OS :
        procTable[procIdx] := DifAv_CP;
      |
      Dew_OS :
        RETURN;
      |
      DewOff_OS :
        procTable[procIdx] := DewOff_CP;
      |
      DifMin_OS :
        procTable[procIdx] := DifMin_CP;
      |
      DifMax_OS :
        procTable[procIdx] := DifMax_CP;
      |
      DifAv0_OS :
        procTable[procIdx] := DifAv0_CP;
      |
      DifAZ_OS :
        procTable[procIdx] := DifAZ_CP;
      |
      Az150_150_OS :
        procTable[procIdx] := Az150_150_CP;
      |
      Az75_150_OS :
        procTable[procIdx] := Az75_150_CP;
      |
      Az150_90_OS :
        procTable[procIdx] := Az150_90_CP;
      |
      Az75_90_OS :
        procTable[procIdx] := Az75_90_CP;
      |
      Az0_OS :
        procTable[procIdx] := Az0_CP;
      |
      Ofset_OS :
        procTable[procIdx] := Ofset_CP;
      |
      AzAv_OS :
        (* wykonywana w AzMax_CP *);
      |
      AzMax_OS :
        procTable[procIdx] := AzMax_CP;
      |
      AzMin_OS :
        (* wykonywana w AzMax_CP *);
      |
      SS150_Min_OS :
        procTable[procIdx] := SS150_Min_CP;
      |
      SS0_Min_OS :
        procTable[procIdx] := SS0_Min_CP;
      |
      SS90_Min_OS :
        procTable[procIdx] := SS90_Min_CP;
      |
      SS_Mkr_OS :
        procTable[procIdx] := SS_Mkr_CP;
      |
      OMkrL_OS :
        procTable[procIdx] := OMkrL_CP;
      |
      MMkrL_OS :
        procTable[procIdx] := MMkrL_CP;
      |
      IMkrL_OS :
        procTable[procIdx] := IMkrL_OS_CP;
      |
      Zone_OS :
        RETURN;
        procTable[procIdx] := Zone_CP;
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

  BEGIN
    CollectData := FALSE;
  END Zatrzymaj;

  PROCEDURE Wznow;
    (* wznawia zliczanie AV,MP,MM *)

  BEGIN
    CollectData := TRUE;
  END Wznow;

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
      modL[rec] := NilValI;
      agcM[rec] := NilValI;
    END (* for rec *);
    currZone := ns_toA;
    currOffR := real(offset);
    currOffI := offset;
    secWith := FLOAT(szerSektora);
    displSens := 3000.0 / secWith;
    SetPathAngle(0, znakSL);
    WykMainVal := ADR(sigNilVal);
    Wyk1Val := ADR(sigNilVal);
    Wyk2Val := ADR(sigNilVal);
    Wyk3Val := ADR(sigNilVal);
    ClearContiners(currOffI);
    TurnOnLOCSig;
    SetEvalPROC(Oblicz, TRUE);
  END IniData;

  PROCEDURE AktStrefa() : NumStrefy;

  BEGIN
    RETURN currZone
  END AktStrefa;

  PROCEDURE NastStrefa
            (    zne : NumPunktu );

  BEGIN
    IF zne = L_LstPToBeTraced()
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
  currZone := ns_no;
  newZone := FALSE;
  FOR rec := goA TO goB DO
    sigNilVal[rec] := SigNilVal;
  END (* for rec *);
END L_Odb.
