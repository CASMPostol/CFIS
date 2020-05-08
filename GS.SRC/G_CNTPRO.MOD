(*.F- *)
(**********************************************************************
|  Title   : Analyse supporting procedures
|  Author  : M.Postol
|  System  : LOGITECH MODULA-2/86
|  History :
|      10-06-96: created
|      29-01-97: M.Postol
|        zmienilem sposob wyznaczania odcinkoe przekroczen roughErr_PO
|        w RoughErr_An
|        dla pokrycia zwracana jest minimalna odleglosc jako rezultat
|      05pg-02-96: M.Postol
|        blad w Count_PhiLoc
|        dla pokrycia przeszukuje odcinki by wyznaczyc minimalna odleglosc 
|        zle zwraca wartosc rezultatu dla pokrycia 
|      23-03-97: M.Postol
|        wywalilem niepotrzebna zmienna lastAz z CntProcedures_Epilog
|        wywalilem odcinki 150 i 180 dla zabezpieczen
|      25-03-97: M.Postol
|        ustawienie sciezki alig_PO jest liczone zawsze w 3 strefie,
|        a nie jak LOC
|
|  Copyright (C), CAS LODZ POLAND.
|  TEL: 42' 862 547, 42' 87 80 44 FAX/TEL: 42' 84 48 40
|
**********************************************************************)
(*.F+ *)

IMPLEMENTATION MODULE G_CntProcedures;

  FROM MathLib0 IMPORT
    real, entier;

  FROM G_CommonTypes IMPORT
    ProceduraT, StronaT, znakGora;

  FROM G_results IMPORT
    (* VAR *) anRes, lastAzAv_A, DevValueTab, lastAzAv_ANr, lastAzAv_AWd,
              lastEta_G_A, lastEta_G_AWd, lastEta_G_ANr, lastEta_D_A,
              lastEta_D_AWd, lastEta_D_ANr;

  FROM L_CommonTypes IMPORT
    (* TYPE *) NumStrefy, Boundary_T, category, NumPunktu;

  FROM ILS_ZoneMngmnt IMPORT
    zoneBDisIdx_T, IdPunktowArr_T;

  FROM CommonTypes IMPORT
    (* TYPE *) zoneBIdx_T, GlownyOdbiornikT, signTabBin, OdnDlaPomBleduT,
               signTab,
    (* CONST *) SigNilVal, DisNilVal, oMkrFlgPosA, oMkrFlgPosB, mMkrFlgPosA,
                mMkrFlgPosB, iMkrFlgPosA, iMkrFlgPosB, NAVA_flg, NAVB_flg;

  FROM ILS_EvalProcedures IMPORT
    (* PROCEDURE *) Azym_Addsmpl, Azym_Clear, AzDif0_Addsmpl, Az0_Clear,
                    Dif0_Clear, MkrLnth_Clear, AzymAV_Addsmpl, AzymAV_Clear,
                    CountAzym, AV_Clear, AV_Addsmpl, Bend_AddSample,
                    Bend_ClearContainer, CountAzymOsi, CountDif, SetPathAngle,
                    MkrLength_Count, MkrALengthConClear, 
    (* TYPE *) Azym_ConT, AzDif0_ConT, AzymAV_ConT, MkrLnth_ConT, Avr_ConT,
               Bend_Descriptor, KapaBuff_T, MkrALengthCon_T, Alig_Continer_T;

  FROM SpecConv IMPORT
    GorszeBoMniejsze, GorszeBoWieksze, GorszeBoBlisze, entierCheck, Div, Mul,
    Add;

  FROM G_Files IMPORT
    (* TYPE *) resultT, Signals, SignalsCVDsc,
    (* PROCEDURE *) WriteFileRes, OpenFileRes, CloseFileRes;

  FROM SYSTEM IMPORT
    WORD;

  FROM MANAGER IMPORT
    Assert;

  FROM FlagAnal IMPORT
    FlagErr_Anal, FlagsTable, MinPoczKonDis;

  FROM FIltr1St IMPORT
    ContinerT, InitCont, Filtr;

  FROM L_DataBase IMPORT
    Lotnisko;

  CONST
    MaxPos       = 10;
    StrefaPomSek = ns_AB;

  TYPE
    ProcIdxT   =
      [ 0 .. MaxPos ];
    procTableT =
      ARRAY [ 0 .. MaxPos ] OF PROC;

  VAR
    procTable         : procTableT;
    procIdx           : ProcIdxT;
    newZone           : BOOLEAN;
    zoneNr            : NumStrefy;
    signalsCV         : SignalsCVDsc;
    wysokoscCV        : INTEGER;
    refEl             : INTEGER;
    flgs              : BITSET;
    refDisCV          : WORD;
    oMkrFlg           : signTabBin;
    mMkrFlg           : signTabBin;
    iMkrFlg           : signTabBin;
    Az75_G_PB_Con     : ARRAY GlownyOdbiornikT OF Azym_ConT;
    Az75_D_PB_Con     : ARRAY GlownyOdbiornikT OF Azym_ConT;
    Az150_G_PB_Con    : ARRAY GlownyOdbiornikT OF Azym_ConT;
    Az190_D_PB_Con    : ARRAY GlownyOdbiornikT OF Azym_ConT;
    Az0_PB_Con        : ARRAY GlownyOdbiornikT OF AzDif0_ConT;
    Dif0_Con          : ARRAY GlownyOdbiornikT OF AzDif0_ConT;
    AzymAV_Con        : ARRAY GlownyOdbiornikT OF AzymAV_ConT;
    azAv_PO_Con       : ARRAY GlownyOdbiornikT OF Avr_ConT;
    difAv_PO_Con      : ARRAY GlownyOdbiornikT OF Avr_ConT;
    DifAvTotal_Con    : ARRAY GlownyOdbiornikT OF Avr_ConT;
    alig_Con          : ARRAY GlownyOdbiornikT OF Avr_ConT;
    odcinki150_PS     : ARRAY GlownyOdbiornikT OF BOOLEAN;
    odcinki180_PS     : ARRAY GlownyOdbiornikT OF BOOLEAN;
    oMkrL_Con         : ARRAY GlownyOdbiornikT OF MkrLnth_ConT;
    mMkrL_Con         : ARRAY GlownyOdbiornikT OF MkrLnth_ConT;
    iMkrL_Con         : ARRAY GlownyOdbiornikT OF MkrLnth_ConT;
    mkrLengthCon      : ARRAY GlownyOdbiornikT OF MkrALengthCon_T;
    modAv_Con         : ARRAY GlownyOdbiornikT OF Avr_ConT;
    dewAv_BD_Cont     : ARRAY GlownyOdbiornikT OF Avr_ConT;
    currNavState      : ARRAY GlownyOdbiornikT OF BOOLEAN;
    flag_20uV_OP_Con  : ARRAY GlownyOdbiornikT OF BOOLEAN;
    WysokoscAv_PB_Con : Avr_ConT;
    KapaFun1_Con      : ARRAY GlownyOdbiornikT OF ContinerT;
    KapaFun3_Con      : ARRAY GlownyOdbiornikT OF ContinerT;
    Bend_con          : ARRAY GlownyOdbiornikT OF Bend_Descriptor;
    bendState         : ARRAY GlownyOdbiornikT OF BOOLEAN;
    aligSec_Con       : Alig_Continer_T;
    displSens         : REAL;
    pathAng           : REAL;


  PROCEDURE DummyProc;

  BEGIN
  END DummyProc;


  PROCEDURE Common_CP;

  VAR
    rec : GlownyOdbiornikT;

  BEGIN (* Common_CP *)
    WITH anRes DO
      FlagErr_Anal( currNavState[goA], NAVA_flg IN flgs, flagErr[goA], 
                    refDisCV, DisNilVal, zoneNr );
      FlagErr_Anal( currNavState[goB], NAVB_flg IN flgs, flagErr[goB], 
                    refDisCV, DisNilVal, zoneNr );
      FOR rec := goA TO goB DO
        GorszeBoMniejsze( modMin_PO[rec].val, signalsCV[modG_Sg, rec] );
        modAv_PO[rec].val := AV_Addsmpl( modAv_Con[rec], signalsCV[modG_Sg, rec
                                         ], FALSE );
        GorszeBoMniejsze( SSMin_PO[rec].val, signalsCV[agcG_Sg, rec] );
      END (* for rec *);
    END (* with anRes *);
  END Common_CP;


  PROCEDURE DewMniejsz
            (    dev  : INTEGER;
                 gran : INTEGER;
                 znak : INTEGER ) : BOOLEAN;

  BEGIN
    dev := Mul( dev, znak );
    RETURN (dev <> SigNilVal) AND ( dev > 0 ) AND ( dev <= gran )
  END DewMniejsz;


  PROCEDURE ProfBComm_CP;

  VAR
    rec : GlownyOdbiornikT;
    ang : INTEGER;

  BEGIN
    WITH anRes.an_OpisProfilB DO
      FOR rec := goA TO goB DO
        ang := SigNilVal;
        IF refEl <> SigNilVal
        THEN
          AzDif0_Addsmpl( Az0_PB_Con[rec], refEl, signalsCV[devG_Sg, rec], ang
          );
        END (* if refEl *);
        GorszeBoBlisze( az0_PB[rec].val, ang, anRes.ustawOsi );
        ang := SigNilVal;
        Azym_Addsmpl( Az75_G_PB_Con[rec], refEl, signalsCV[devG_Sg, rec], ang )
        ;
        GorszeBoBlisze( az75_G_PB[rec].val, ang, 0 );
        ang := SigNilVal;
        Azym_Addsmpl( Az75_D_PB_Con[rec], refEl, signalsCV[devG_Sg, rec], ang )
        ;
        GorszeBoBlisze( az75_D_PB[rec].val, ang, 0 );
        ang := SigNilVal;
        Azym_Addsmpl( Az150_G_PB_Con[rec], refEl, signalsCV[devG_Sg, rec], ang
        );
        GorszeBoBlisze( az150_G_PB[rec].val, ang, 0 );
        ang := SigNilVal;
        Azym_Addsmpl( Az190_D_PB_Con[rec], refEl, signalsCV[devG_Sg, rec], ang
        );
        GorszeBoBlisze( az190_D_PB[rec].val, ang, 0 );
      END (* for rec *);
      WysokoscAv_PB := AV_Addsmpl( WysokoscAv_PB_Con, wysokoscCV, FALSE );
    END (* with anRes.an_OpisProfilB *);
  END ProfBComm_CP;

  (*.F+ *)


  PROCEDURE An_OpisOsi_CP;

  VAR
    rec     : GlownyOdbiornikT;
    currVal : INTEGER;

  BEGIN
    WITH anRes.an_OpisOsi DO
      FOR rec := goA TO goB DO
        currVal := CountDif( refEl, signalsCV[devG_Sg, rec], displSens, pathAng
                   );
        difAv_PO[zoneNr, rec].val := AV_Addsmpl( difAv_PO_Con[rec], currVal,
                                                 newZone );
        IF zoneNr = StrefaPomSek
        THEN
          alig_PO[rec].val := AV_Addsmpl( alig_Con[rec], currVal, FALSE );
        END (* if *);
        WriteFileRes( Dif, rec, currVal );
        currVal := CountAzymOsi( refEl, signalsCV[devG_Sg, rec], displSens );
        azAv_PO[zoneNr, rec].val := AV_Addsmpl( azAv_PO_Con[rec], currVal,
                                                newZone );
        GorszeBoWieksze( azMax_PO[zoneNr, rec].val, currVal );
        GorszeBoMniejsze( azMin_PO[zoneNr, rec].val, currVal );
        MkrLength_Count( oMkrFlg, mMkrFlg, iMkrFlg, rec, CARDINAL( refDisCV ),
                         signalsCV[agcM_Sg, rec], mkrLengthCon[rec], mkrLength
        );
      END (* for rec *);
    END (* with anRes.an_OpisOsi *);
  END An_OpisOsi_CP;


  PROCEDURE An_OpisSektora_CP;

  VAR
    rec    : GlownyOdbiornikT;
    currAz : INTEGER;

  BEGIN
    WITH anRes.an_OpisSektora DO
      FOR rec := goA TO goB DO
        AzymAV_Addsmpl( AzymAV_Con[rec], refEl, signalsCV[devG_Sg, rec],
                        AzAv_OS[zoneNr, rec].val, newZone );
        WITH anRes DO
          currAz := CountAzym( refEl, signalsCV[devG_Sg, rec], real(
                               anRes.offset ), 0.0 );
          WriteFileRes( SecWith, rec, currAz );
          GorszeBoWieksze( AzMax_OS[zoneNr, rec].val, currAz );
          GorszeBoMniejsze( AzMin_OS[zoneNr, rec].val, currAz );
        END (* with anRes *);
      END (* for rec *);
    END (* with anRes.an_OpisSektora *);
  END An_OpisSektora_CP;


  PROCEDURE An_OpisBadDod_CP;

  VAR
    rec : GlownyOdbiornikT;

  BEGIN
    WITH anRes.an_OpisBadDod DO
      FOR rec := goA TO goB DO
        dewAv[rec].val := AV_Addsmpl( dewAv_BD_Cont[rec], signalsCV[devG_Sg,
                                      rec], FALSE );
      END (* for rec *);
    END (* with anRes.an_OpisBadDod *);
  END An_OpisBadDod_CP;

  (*.F+ *)


  PROCEDURE An_OpisZasiegSzer_CP;

  VAR
    rec : GlownyOdbiornikT;

  BEGIN
    WITH anRes.an_OpisPokrycia DO
      FOR rec := goA TO goB DO
        FlagErr_Anal( flag_20uV_OP_Con[rec], signalsCV[agcG_Sg, rec] <= 20,
                      odcinki_20uV[rec], refDisCV, DisNilVal, zoneNr );
      END;   (* for rec *)
      IF CARDINAL( refDisCV ) <> DisNilVal THEN
        GorszeBoWieksze( run_Start_OP, CARDINAL( refDisCV ) DIV 5 );
      END;
    END (* with anRes.an_OpisZasiegSzer *)
  END An_OpisZasiegSzer_CP;


  PROCEDURE  An_OpisZabezpieczenie_CP;
  VAR
    rec : GlownyOdbiornikT;

  BEGIN
    WITH anRes.an_OpisZabezpieczenie  DO
      FOR rec := goA TO goB DO
        AzymAV_Addsmpl( AzymAV_Con[rec], refEl, signalsCV[devG_Sg, rec],
                      az180Av[zoneNr, rec].val, newZone );
        (*
        FlagErr_Anal( odcinki180_PS[rec], 
                      DewMniejsz( signalsCV[devG_Sg, rec], 1800, -znakGora),
                      odcinki180_OZ[rec], CARDINAL( refDisCV ), zoneNr );
        FlagErr_Anal( odcinki150_PS[rec], 
                      DewMniejsz( signalsCV[devG_Sg, rec], 1500, -znakGora),
                      odcinki150_OZ[rec], CARDINAL( refDisCV ), zoneNr );
        *)
      END;   (* for rec *)
    END;
  END An_OpisZabezpieczenie_CP;
  
  PROCEDURE CntProcedures_Prolog;


    PROCEDURE ClearProcTable
              ( VAR procIdx   : ProcIdxT;
                VAR procTable : procTableT );

    VAR
      idx : ProcIdxT;

    BEGIN
      FOR idx := MIN( ProcIdxT ) TO MAX( ProcIdxT ) DO
        procTable[idx] := DummyProc;
      END (* for idx *);
      procIdx := MIN( ProcIdxT );
    END ClearProcTable;


    PROCEDURE ClearAllCont;

    VAR
      rec : GlownyOdbiornikT;

    BEGIN
      WITH anRes DO
        SetPathAngle( ustawOsi, znakGora );
        displSens := 1500.0 / FLOAT( secWith );
        pathAng := FLOAT( ustawOsi );
        FOR rec := goA TO goB DO
          Azym_Clear( Az75_G_PB_Con[rec], znakGora * 750, 0 );
          Azym_Clear( Az75_D_PB_Con[rec], -znakGora * 750, 0 );
          Azym_Clear( Az150_G_PB_Con[rec], znakGora * 1500, 0 );
          Azym_Clear( Az190_D_PB_Con[rec], -znakGora * 1900, 0 );
          Az0_Clear( Az0_PB_Con[rec], displSens );
          Dif0_Clear( Dif0_Con[rec], displSens );
          AzymAV_Clear( AzymAV_Con[rec], offset, 0 );
          AV_Clear( azAv_PO_Con[rec] );
          AV_Clear( difAv_PO_Con[rec] );
          AV_Clear( DifAvTotal_Con[rec] );
          AV_Clear( alig_Con[rec] );
          odcinki150_PS[rec] := FALSE;
          odcinki180_PS[rec] := FALSE;
          MkrLnth_Clear( oMkrL_Con[rec] );
          MkrLnth_Clear( mMkrL_Con[rec] );
          MkrLnth_Clear( iMkrL_Con[rec] );
          MkrALengthConClear( mkrLengthCon[rec] );
          AV_Clear( modAv_Con[rec] );
          AV_Clear( dewAv_BD_Cont[rec] );
          currNavState[rec] := FALSE;
          flag_20uV_OP_Con[rec] := FALSE;
        END (* for rec *);
        AV_Clear( WysokoscAv_PB_Con );
      END (* with anRes *);
    END ClearAllCont;


    PROCEDURE AssignEvalProc
              ( VAR procIdx   : ProcIdxT;
                VAR procTable : procTableT );


      PROCEDURE TurnOn
                (    proc : PROC );

      BEGIN
        procTable[procIdx] := proc;
        INC( procIdx );
      END TurnOn;

    BEGIN (* AssignEvalProc *)
      CASE anRes.procedure OF
        pUstawienieOsi_Struktura,
        pAlarmOsi,
        pUstawienieOsi_Szer_pA,
        pUstawienieOsi_Waski_pA :
          TurnOn( An_OpisOsi_CP ); |
        pSzerSektora_pA,
        pAlarmSzeroki_pA,
        pAlarmWaski_pA :
          TurnOn( An_OpisSektora_CP ); |
        pSzer_i_Osi_pB,
        pAlarmSzer_pB,
        pAlarmWaski_pB :
          TurnOn( ProfBComm_CP ); |
        pRownowagaModulacji,
        pFazowanie :
          TurnOn( An_OpisBadDod_CP ); |
        pZabezpieczenie :
          TurnOn( An_OpisZabezpieczenie_CP ); |
        pPokrycieWOsi,
        pPokrycie8stP,
        pPokrycie8stL :
          TurnOn( An_OpisZasiegSzer_CP );
      END (* case anRes.procedure *);
    END AssignEvalProc;

  CONST
    Create = TRUE;

  VAR
    resultIdx : resultT;

  BEGIN (* CntProcedures_Prolog *)
    FOR resultIdx := MIN( resultT ) TO MAX( resultT ) DO
      OpenFileRes( Create, resultIdx );
    END (* for resultIdx *);
    zoneNr := MIN( NumStrefy );
    ClearAllCont;
    ClearProcTable( procIdx, procTable );
    AssignEvalProc( procIdx, procTable );
  END CntProcedures_Prolog;

  (*.F- *)
  PROCEDURE  InZoneAnalyse
             (VAR IdentPunktow : IdPunktowArr_T): BOOLEAN;

  TYPE
    ProceduraTSet =
      SET OF ProceduraT;

  BEGIN
    IdentPunktow := anRes.identPunktow;
    RETURN anRes.procedure IN ProceduraTSet { pUstawienieOsi_Struktura,
                                              pAlarmOsi,
                                              pUstawienieOsi_Szer_pA,
                                              pUstawienieOsi_Waski_pA,
                                              pSzerSektora_pA,
                                              pAlarmSzeroki_pA,
                                              pAlarmWaski_pA,
                                              pZabezpieczenie}
  END InZoneAnalyse;
  (*.F+ *)


  PROCEDURE DoCountProcedures
            (    SignalsCV  : SignalsCVDsc;
                 RefEl      : INTEGER;
                 RefDisCV   : WORD;
                 Flgs       : BITSET;
                 WysokoscCV : INTEGER;
                 CurrZone   : NumStrefy    );

  VAR
    idx : ProcIdxT;

  BEGIN
    signalsCV := SignalsCV;
    refEl := RefEl;
    refDisCV := RefDisCV;
    flgs := Flgs;
    wysokoscCV := WysokoscCV;
    newZone := CurrZone <> zoneNr;
    zoneNr := CurrZone;
    oMkrFlg[goA] := oMkrFlgPosA IN flgs;
    oMkrFlg[goB] := oMkrFlgPosB IN flgs;
    mMkrFlg[goA] := mMkrFlgPosA IN flgs;
    mMkrFlg[goB] := mMkrFlgPosB IN flgs;
    iMkrFlg[goA] := iMkrFlgPosA IN flgs;
    iMkrFlg[goB] := iMkrFlgPosB IN flgs;
    Common_CP;
    FOR idx := MIN( ProcIdxT ) TO procIdx - 1 DO
      procTable[idx];
    END (* for idx *);
  END DoCountProcedures;


  PROCEDURE KapaFun1
            (    ref : OdnDlaPomBleduT;
                 rec : GlownyOdbiornikT;
                 dif : REAL             ) : INTEGER;

  BEGIN
    WITH anRes.an_OpisOsi DO
      RETURN entier( Filtr( KapaFun1_Con[rec], dif ) );
    END (* with anRes.an_OpisOsi *);
  END KapaFun1;


  PROCEDURE KapaFun2
            (    ref : OdnDlaPomBleduT;
                 rec : GlownyOdbiornikT;
                 dif : REAL             ) : INTEGER;

  BEGIN
    WITH anRes.an_OpisOsi DO
      RETURN entier( real( difAv_PO[ns_AB, rec].val ) );
    END (* with anRes.an_OpisOsi *);
  END KapaFun2;


  PROCEDURE KapaFun3
            (    ref : OdnDlaPomBleduT;
                 rec : GlownyOdbiornikT;
                 dif : REAL             ) : INTEGER;

  BEGIN
    WITH anRes.an_OpisOsi DO
      RETURN entier( Filtr( KapaFun3_Con[rec], dif ) );
    END (* with anRes.an_OpisOsi *);
  END KapaFun3;


  PROCEDURE KapaFunDumm
            (    ref : OdnDlaPomBleduT;
                 rec : GlownyOdbiornikT;
                 dif : REAL             ) : INTEGER;

  BEGIN
    RETURN SigNilVal;
  END KapaFunDumm;


  PROCEDURE CntProcedures_Epilog
            (     ZoneBIdx    : zoneBIdx_T;
                  ZoneBDisIdx : zoneBDisIdx_T;
              VAR DoStructAn  : BOOLEAN       );


    PROCEDURE Count_ChiLoc
              ( VAR ChiLoc : DevValueTab;
                    Eta1   : DevValueTab;
                    Eta2   : DevValueTab );

    VAR
      rec : GlownyOdbiornikT;

    BEGIN
      FOR rec := goA TO goB DO
        IF ( Eta1[rec].val = SigNilVal ) OR ( Eta2[rec].val = SigNilVal )
        THEN
          ChiLoc[rec].val := SigNilVal;
        ELSE
          ChiLoc[rec].val := ABS( Eta1[rec].val - Eta2[rec].val );
        END (* if *);
      END (* for rec *);
    END Count_ChiLoc;


    PROCEDURE Count_PhiLoc
              ( VAR PhiLoc : DevValueTab;
                    Eta0   : DevValueTab;
                    Eta    : DevValueTab;
                    ChiLoc : DevValueTab );

    VAR
      rec     : GlownyOdbiornikT;
      Eta0R   : REAL;
      EtaR    : REAL;
      ChiLocR : REAL;

    BEGIN
      FOR rec := goA TO goB DO
        IF ( Eta0[rec].val = SigNilVal ) OR ( Eta[rec].val = SigNilVal ) OR
           ( ChiLoc[rec].val = SigNilVal )
        THEN
          PhiLoc[rec].val := SigNilVal;
        ELSE
          Eta0R := real( Eta0[rec].val );
          EtaR := real( Eta[rec].val );
          ChiLocR := real( ChiLoc[rec].val );
          IF NOT entierCheck( ABS( ( EtaR - Eta0R ) / ChiLocR * 1000.0 ) + 0.5,
                              PhiLoc[rec].val )
          THEN
            PhiLoc[rec].val := SigNilVal;
          END (* if *);
        END (* if *);
      END (* for rec *);
    END Count_PhiLoc;


    PROCEDURE AssignAz
              (     currEta     : DevValueTab;
                VAR lastEta_G_A : DevValueTab;
                VAR lastEta_D_A : DevValueTab;
                    strona      : StronaT     );

    BEGIN
      CASE strona OF
        Gora :
          lastEta_G_A := currEta; |
        Dol :
          lastEta_D_A := currEta;
      END (* case strona *);
    END AssignAz;


    PROCEDURE alig_ContinerClear
              ( VAR alig_Continer : Alig_Continer_T;
                    ZonesBeg      : zoneBDisIdx_T   );

    VAR

    BEGIN
      WITH anRes.an_OpisOsi DO
        WITH alig_Continer DO
          zonesBeg := ZonesBeg;
          begDist := zonesBeg[np_A];
          endDist := zonesBeg[np_B];
        END (* with alig_Continer *);
      END (* with anRes.an_OpisOsi *);
    END alig_ContinerClear;


    PROCEDURE InitCon;

    VAR
      rec      : GlownyOdbiornikT;
      KapaBuff : KapaBuff_T;
      boundary : Boundary_T;


      PROCEDURE FillBound
                ( VAR boundary : Boundary_T;
                      cat      : category   );

      BEGIN
        boundary[np_Start] := 300.0;
        boundary[np_A] := 300.0;
        IF cat = 3
        THEN
          boundary[np_B] := 200.0;
          boundary[np_CorT] := 200.0;
          boundary[np_D] := 200.0;
          boundary[np_E] := 200.0;
        ELSE
          boundary[np_B] := 300.0;
          boundary[np_CorT] := 300.0;
          boundary[np_D] := 300.0;
          boundary[np_E] := 300.0;
        END (* if cat *);
      END FillBound;

    BEGIN
      KapaBuff[ns_toA] := KapaFun1;
      KapaBuff[ns_AB] := KapaFun2;
      KapaBuff[ns_BCorT] := KapaFun3;
      KapaBuff[ns_CorTD] := KapaFunDumm;
      KapaBuff[ns_DE] := KapaFunDumm;
      KapaBuff[ns_no] := KapaFunDumm;
      FillBound( boundary, Lotnisko.Kategoria );
      FOR rec := goA TO goB DO
        bendState[rec] := FALSE;
        Bend_ClearContainer( Bend_con[rec], ZoneBIdx, boundary, KapaBuff );
        InitCont( KapaFun1_Con[rec], 5.0 );
        InitCont( KapaFun3_Con[rec], 5.0 );
      END (* for rec *);
    END InitCon;

  BEGIN (* CntProcedures_Epilog *)
    DoStructAn := FALSE;
    WITH anRes DO
      CASE procedure OF
        pUstawienieOsi_Struktura,
        pAlarmOsi,
        pUstawienieOsi_Szer_pA,
        pUstawienieOsi_Waski_pA :
          alig_ContinerClear( aligSec_Con, ZoneBDisIdx );
          DoStructAn := TRUE;
          InitCon;
          CASE procedure OF
            pUstawienieOsi_Struktura :
              lastAzAv_A[nadajnik] := an_OpisOsi.azAv_PO[ StrefaPomSek]; |
            pUstawienieOsi_Szer_pA :
              lastAzAv_AWd[nadajnik] := an_OpisOsi.azAv_PO[ StrefaPomSek]; |
            pUstawienieOsi_Waski_pA :
              lastAzAv_ANr[nadajnik] := an_OpisOsi.azAv_PO[ StrefaPomSek];
          ELSE
          END (* case procedure *); |
        pSzerSektora_pA :
          WITH an_OpisSektora DO
            AssignAz( AzAv_OS[StrefaPomSek], lastEta_G_A[nadajnik], 
                      lastEta_D_A[nadajnik], strona );
            Count_ChiLoc( Chi_OS, lastEta_D_A[nadajnik], lastEta_G_A[nadajnik] );
            Count_PhiLoc( Phi_OS, lastAzAv_A[nadajnik], lastEta_G_A[nadajnik], Chi_OS );
          END (* with an_OpisSektora *); |
        pAlarmSzeroki_pA :
          WITH an_OpisSektora DO
            AssignAz( AzAv_OS[StrefaPomSek], lastEta_G_AWd[nadajnik],
                      lastEta_D_AWd[nadajnik], strona );
            Count_ChiLoc( Chi_OS, lastEta_D_AWd[nadajnik], lastEta_G_AWd[nadajnik] );
            Count_PhiLoc( Phi_OS, lastAzAv_AWd[nadajnik], lastEta_G_AWd[nadajnik], Chi_OS );
          END (* with an_OpisSektora *); |
        pAlarmWaski_pA :
          WITH an_OpisSektora DO
            AssignAz( AzAv_OS[StrefaPomSek], lastEta_G_ANr[nadajnik],
                      lastEta_D_ANr[nadajnik], strona );
            Count_ChiLoc( Chi_OS, lastEta_D_ANr[nadajnik], lastEta_G_ANr[nadajnik] );
            Count_PhiLoc( Phi_OS, lastAzAv_ANr[nadajnik], lastEta_D_ANr[nadajnik], Chi_OS );
          END (* with an_OpisSektora *); |
        pSzer_i_Osi_pB,
        pAlarmSzer_pB,
        pAlarmWaski_pB :
          WITH an_OpisProfilB DO
            Count_ChiLoc( Chi_PB, az75_G_PB, az75_D_PB );
            Count_PhiLoc( Phi_PB, az0_PB, az75_G_PB, Chi_PB );
          END (* with an_OpisProfilB *);
      ELSE
        ;
      END (* case anRes.procedure *);
    END (* with anRes *);
  END CntProcedures_Epilog;


  PROCEDURE DoBendAnalyse
            (    devG_Sg      : signTab;
                 Idx          : CARDINAL;
                 refEl        : INTEGER;
                 refDisCV     : WORD;
                 currZone     : NumStrefy;
                 zoneExcluded : BOOLEAN   );

  VAR
    currdif    : INTEGER;
    rec        : GlownyOdbiornikT;
    boundP_res : INTEGER;
    boundM_res : INTEGER;
    centre_res : INTEGER;
    bends      : INTEGER;  (* x100 *)
    isRes      : BOOLEAN;


    PROCEDURE RoughErr_An
              (     bends       : INTEGER;
                VAR roughErr_PO : FlagsTable;
                    dis         : CARDINAL;
                VAR bendOut     : BOOLEAN;
                    CurrZone    : NumStrefy  );

    VAR
      currbendOut : BOOLEAN;

    BEGIN
      IF bends = SigNilVal
      THEN
        RETURN
      END (* if bends *);
      FlagErr_Anal( bendOut, bends > 50, roughErr_PO, dis, DisNilVal, 
                    CurrZone );
    END RoughErr_An;

  BEGIN (* DoBendAnalyse *)
    WITH anRes.an_OpisOsi DO
      FOR rec := goA TO goB DO
        IF zoneExcluded
        THEN
          currdif := SigNilVal;
        ELSE
          currdif := CountDif( refEl, devG_Sg[rec], displSens, pathAng );
        END (* if zoneExcluded *);
        isRes := Bend_AddSample( currdif, Idx, CARDINAL( refDisCV ), currZone,
                                 pbTeodolit, rec, boundP_res, boundM_res,
                                 centre_res, bends, Bend_con[rec] );
        WriteFileRes( boundP, rec, boundP_res );
        WriteFileRes( boundM, rec, boundM_res );
        WriteFileRes( DifAV, rec, centre_res );
        IF isRes
        THEN
          GorszeBoWieksze( roughness_PO[currZone, rec].val, bends );
          RoughErr_An( bends, roughErr_PO[rec], CARDINAL( refDisCV ), bendState
                       [rec], currZone );
        END (* if isRes *);
      END (* for rec *);
    END (* with anRes.an_OpisOsi *);
  END DoBendAnalyse;


  PROCEDURE Close_CntProcedures
            ( VAR SyntResult  : INTEGER;
              VAR podzielnik  : INTEGER;
                  ZoneBDisIdx : zoneBDisIdx_T );

  VAR
    resultIdx : resultT;
    disRes    : CARDINAL;
    
  BEGIN
    FOR resultIdx := MIN( resultT ) TO MAX( resultT ) DO
      CloseFileRes( resultIdx );
    END (* for resultIdx *);
    WITH anRes DO
      CASE procedure OF
        pUstawienieOsi_Struktura,
        pAlarmOsi,
        pUstawienieOsi_Szer_pA,
        pUstawienieOsi_Waski_pA :
          WITH an_OpisOsi DO
            podzielnik := 100;
            SyntResult := azAv_PO[StrefaPomSek, glownyOdbiornik].val;
            zonesBeg := ZoneBDisIdx;
          END (* with an_OpisOsi *); |
        pSzerSektora_pA,
        pAlarmSzeroki_pA,
        pAlarmWaski_pA :
          podzielnik := 100;
          SyntResult := an_OpisSektora.AzAv_OS[StrefaPomSek, glownyOdbiornik].
                        val;
          an_OpisSektora.zonesBeg_OS := ZoneBDisIdx; |
        pSzer_i_Osi_pB,
        pAlarmSzer_pB,
        pAlarmWaski_pB :
          podzielnik := 100;
          SyntResult := an_OpisProfilB.Chi_PB[glownyOdbiornik].val; |
        pRownowagaModulacji,
        pFazowanie :
          podzielnik := 10;
          SyntResult := an_OpisBadDod.dewAv[glownyOdbiornik].val; |
        pZabezpieczenie :
          WITH an_OpisZabezpieczenie DO
            podzielnik := 100;
            SyntResult := az180Av[StrefaPomSek, glownyOdbiornik].val;
            zonesBeg_OZ := ZoneBDisIdx;
          END (* with an_OpisZabezpieczenie *); |
        pPokrycieWOsi,
        pPokrycie8stP,
        pPokrycie8stL :
          WITH an_OpisPokrycia DO
            disRes := MinPoczKonDis( odcinki_20uV[glownyOdbiornik] );
            IF disRes = DisNilVal
            THEN
              podzielnik := 100;
              SyntResult := run_Start_OP;
            ELSE
              podzielnik := 500;
              SyntResult := disRes;
            END (* if w_IleOd *);
          END (* with an_OpisPokrycia *);
      ELSE
      END (* case anRes.procedure *);
    END (* with anRes *);
  END Close_CntProcedures;


END G_CntProcedures.
