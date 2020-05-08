(*.F- *)
(**********************************************************************
|  Title   : Analyse supporting procedures
|  Author  : M.Postol
|  System  : LOGITECH MODULA-2/86
|  History :
|      10-06-96: created
|      29-10-96: M.Postol
|        Wprowadzilem zabezpieczenie przy zwracaniu SyntResult 
|        w Close_CntProcedures - nie dieli przez 10 jak jest NIL
|      30-10-96: M.Postol
|        blad w CASE w CntProcedures_Epilog
|      15-12-96: M.Postol
|        zmaiana def'a ScannerI
|      25-01-97: M.Postol
|        zmienilem sposob wyznaczania odcinkoe przekroczen roughErr_PO 
|        w RoughErr_An
|      23-03-97: M.Postol
|        szerokosc sektora byla wyznaczana aktualna stron / total,
|        a jest eta po stronie 90/total
|        przenioslem procedure InSegment z ILS_EvalProcedures do tego modulu
|        dla kategoeii 2 i 3 ustawienie osi jest mierzone w zadanych strefach 
|        wyznacznanych bez wykorzystania odleglosci
|      24-03-97: M.Postol
|        osie w alarmach sektorow na ekranie glownym na klawiszach sa 
|        kat osi w 2 strefie
|      23-04-97: M.Postol
|        alig_ContinerClear: blad odwolanie nie do tej zmiennej.
|      07-05-97: M.Postol
|        analiza flagi zawsze byla robiona wzgledem odleglosci
|      Rel. 3.0, MPostol
|        Uzgodnilem z nowa wersja FlagAnal.
|      Rel. 3.14: MPostol
|        - Wyrazistosc jest podstawiana do wynikow pomiaru, jesli
|          pomiar byl robiony, tzn. przeleciano >35deg
|        - Count_ChiLoc - sprawdza czy katy polsektoroe nie sa za duze
|          co sie moze zdazyc przy zle wprowadzonym polozeniu.
|
|  Copyright (C), CAS LODZ POLAND.
|  TEL: 42' 686 25 47
|  mailto: techsupp@cas.com.pl
|  http: www.cas.com.pl
|
**********************************************************************)
(*.F+ *)

IMPLEMENTATION MODULE L_CntProcedures;

  IMPORT
    L_DataBase;

  FROM L_results IMPORT
    (* TYPE *) An_OpisProfilBT,
    (* VAR *) anRes, lastAzAv_A, lastEta_150_A, lastEta_90_A, lastAzAv_ANr,
              lastEta_150_ANr, lastEta_90_ANr, lastAzAv_AWd, lastEta_150_AWd,
              lastEta_90_AWd;

  FROM L_CommonTypes IMPORT
    (* CONST *) znak90, znak150, znakSL,
    (* TYPE *) ProceduraT, NumStrefy, StronaT, SignalsCVDsc, Signals,
               MkrLengthT, SignalDsc, Boundary_T, 
               DevValueTab, category, NumPunktu;

  FROM MathLib0 IMPORT
    entier, real;

  FROM CommonTypes IMPORT
    (* TYPE *) refTab, GlownyOdbiornikT, OdnDlaPomBleduT, signTabBin, signTab,
               zoneBIdx_T, 
    (* CONST *) SigNilVal, NilValI, DisNilVal, oMkrFlgPosA, oMkrFlgPosB,
                mMkrFlgPosA, mMkrFlgPosB, iMkrFlgPosA, iMkrFlgPosB, NAVA_flg,
                NAVB_flg;

  FROM ILS_ZoneMngmnt IMPORT
    zoneBDisIdx_T, IdPunktowArr_T;

  FROM ILS_EvalProcedures IMPORT
    (* PROCEDURE *) Azym_Addsmpl, Azym_Clear, AzDif0_Addsmpl, Az0_Clear,
                    Dif0_Clear, MkrLnth_AddSmpl, AzymAV_Addsmpl, AzymAV_Clear,
                    CountAzym, AV_Clear, AV_Addsmpl, Az0Av_Addsmpl, Az0Av_Clear
                    , Clearence_Addsmpl, Clearence_Clear, Bend_AddSample,
                    Bend_ClearContainer, CountDif, SetPathAngle,
                    MkrLength_Count, MkrALengthConClear,
    (* TYPE *) Azym_ConT, AzDif0_ConT, AzymAV_ConT, MkrLnth_ConT, Avr_ConT,
               Az0Av_ConT, Clearence_ConT, Bend_Descriptor, KapaBuff_T,
               MkrALengthCon_T;

  FROM SpecConv IMPORT
    GorszeBoMniejsze, GorszeBoWieksze, GorszeBoBlisze, entierCheck, Div, Mul;

  FROM L_Files IMPORT
    resultT,
    (* PROCEDURE *) WriteFileRes, OpenFileRes, CloseFileRes;

  FROM SYSTEM IMPORT
    WORD, ADR;

  FROM MANAGER IMPORT
    Assert;

  FROM FlagAnal IMPORT
    FlagErr_Anal, FlagsTable;

  FROM CommonData  IMPORT
    OdnDlaPomBledu;
  
  CONST
    MaxPos       = 10;
    StrefaPomSek = ns_AB;

  TYPE
    ProcIdxT   =
      [0 .. MaxPos];
    procTableT =
      ARRAY [0 .. MaxPos] OF PROC;
    PolCont_T  =
      RECORD
        sum_Left      :
          REAL;
        polSam_Left   :
          CARDINAL;
        sum_Plain     :
          REAL;
        polSam_Plain  :
          CARDINAL;
        sum_Rihght    :
          REAL;
        polSam_Rihght :
          CARDINAL;
      END;
    ZonesSet = SET OF NumStrefy;
    Alig_Continer_T =
      RECORD
        CASE inZoneNotDist : BOOLEAN OF
          FALSE:
            begDist : CARDINAL;
            endDist : CARDINAL;
          |
          TRUE:
            zones : ZonesSet; 
        END;
      END;

  VAR
    procTable      : procTableT;
    procIdx        : ProcIdxT;
    newZone        : BOOLEAN;
    zoneNr         : NumStrefy;
    inPolar        : BOOLEAN;
    signalsCV      : SignalsCVDsc;
    refCV          : refTab;
    flgs           : BITSET;
    refDisCV       : WORD;
    oMkrFlg        : signTabBin;
    mMkrFlg        : signTabBin;
    iMkrFlg        : signTabBin;
    covSecMin      : INTEGER;
    covSecMax      : INTEGER;
    Az150_150_Con  : ARRAY OdnDlaPomBleduT, GlownyOdbiornikT OF Azym_ConT;
    Az75_150_Con   : ARRAY OdnDlaPomBleduT, GlownyOdbiornikT OF Azym_ConT;
    Az150_90_Con   : ARRAY OdnDlaPomBleduT, GlownyOdbiornikT OF Azym_ConT;
    Az75_90_Con    : ARRAY OdnDlaPomBleduT, GlownyOdbiornikT OF Azym_ConT;
    Az0_Con        : ARRAY OdnDlaPomBleduT, GlownyOdbiornikT OF AzDif0_ConT;
    Clrnc150_Con   : ARRAY OdnDlaPomBleduT, GlownyOdbiornikT OF Clearence_ConT;
    Clrnc90_Con    : ARRAY OdnDlaPomBleduT, GlownyOdbiornikT OF Clearence_ConT;
    Dif0_Con       : ARRAY OdnDlaPomBleduT, GlownyOdbiornikT OF AzDif0_ConT;
    AzymAV_Con     : ARRAY OdnDlaPomBleduT, GlownyOdbiornikT OF AzymAV_ConT;
    DifAv_Con      : ARRAY OdnDlaPomBleduT, GlownyOdbiornikT OF Avr_ConT;
    Az0Av_Con      : ARRAY OdnDlaPomBleduT, GlownyOdbiornikT OF Az0Av_ConT;
    DifAvTotal_Con : ARRAY OdnDlaPomBleduT, GlownyOdbiornikT OF Avr_ConT;
    alig_Con       : ARRAY OdnDlaPomBleduT, GlownyOdbiornikT OF Avr_ConT;
    mkrLengthCon   : ARRAY GlownyOdbiornikT OF MkrALengthCon_T;
    modLocAv_Con   : ARRAY GlownyOdbiornikT OF Avr_ConT;
    dewAv_BD_Cont  : ARRAY GlownyOdbiornikT OF Avr_ConT;
    currNavState   : ARRAY GlownyOdbiornikT OF BOOLEAN;
    PolCont        : ARRAY OdnDlaPomBleduT, GlownyOdbiornikT OF PolCont_T;
    Bend_con       : ARRAY OdnDlaPomBleduT, GlownyOdbiornikT OF Bend_Descriptor
  ;
    bendState      : ARRAY OdnDlaPomBleduT, GlownyOdbiornikT OF BOOLEAN;
    aligSec_Con    : Alig_Continer_T;
    displSens      : REAL;

  PROCEDURE DummyProc;

  BEGIN
  END DummyProc;

   (*.F- *)

  PROCEDURE Common_CP;
  VAR
    rec : GlownyOdbiornikT;

  BEGIN (* Common_CP *)
    WITH anRes DO
      FOR rec := goA TO goB DO
        IF NOT inPolar  THEN
          GorszeBoMniejsze(modLocMin_PO[rec].val, signalsCV[modL_Sg, rec]);
          modLocAv_PO[rec].val :=
            AV_Addsmpl(modLocAv_Con[rec], signalsCV[modL_Sg, rec], FALSE);
        
        END;
        GorszeBoMniejsze(SSMin_PO[rec].val, signalsCV[agcL_Sg, rec]);
      END (* for rec *);
    END (* with anRes.an_OpisOsi *);
  END Common_CP;

  PROCEDURE An_OpisBadDod_CP;
  VAR
    rec : GlownyOdbiornikT;
  BEGIN
    WITH anRes DO
      FlagErr_Anal(currNavState[goA], NAVA_flg IN flgs, flagErr[goA],
                   refDisCV,  zoneNr);
      FlagErr_Anal(currNavState[goB], NAVB_flg IN flgs, flagErr[goB],
                   refDisCV, zoneNr);
      WITH an_OpisBadDod  DO
        FOR rec := goA TO goB DO
          dewAv[rec].val:=
             AV_Addsmpl(dewAv_BD_Cont[rec], signalsCV[devL_Sg, rec], FALSE);
        END;
      END;
    END;
  END An_OpisBadDod_CP;

  PROCEDURE An_OpisOsi_CP;
  VAR
    rec     : GlownyOdbiornikT;
    ref     : OdnDlaPomBleduT;
    currDif : INTEGER;

    PROCEDURE InSegment
              (    currZone      : NumStrefy;
                   refDisCV      : CARDINAL;
                   alig_Continer : Alig_Continer_T ) : BOOLEAN;

    BEGIN
      WITH alig_Continer DO
        IF inZoneNotDist  THEN
          RETURN currZone IN zones
        ELSE
          IF ( refDisCV = DisNilVal) OR (begDist = DisNilVal) OR 
             (endDist = DisNilVal)
          THEN
            RETURN FALSE;
          END (* if refDisCV *);
          RETURN (refDisCV >= endDist) AND (refDisCV <= begDist)
        END;
      END (* with alig_Continer *);
    END InSegment;
  
  BEGIN
    WITH anRes  DO
      FlagErr_Anal(currNavState[goA], NAVA_flg IN flgs, flagErr[goA],
                   refDisCV, zoneNr);
      FlagErr_Anal(currNavState[goB], NAVB_flg IN flgs, flagErr[goB],
                   refDisCV, zoneNr);
    END;
    WITH anRes.an_OpisOsi DO
      FOR rec := goA TO goB DO
        FOR ref := pbTeodolit TO MAX(OdnDlaPomBleduT) DO
          currDif :=
            CountDif( refCV.Together[ref], signalsCV[devL_Sg, rec], displSens, 0.0);
          WriteFileRes(Dif, ref, rec, currDif);
          IF NOT inPolar  THEN
            difAv_PO[zoneNr, ref, rec].val :=
                          AV_Addsmpl( DifAv_Con[ref, rec], currDif, newZone);
            AzAv_PO[zoneNr, ref, rec].val :=
                                       Az0Av_Addsmpl( Az0Av_Con[ref, rec],
                                                      signalsCV[devL_Sg, rec],
                                                      refCV.Together[ref],
                                                      newZone);
            GorszeBoWieksze(difMax_PO[zoneNr, ref, rec].val, currDif);
            GorszeBoMniejsze(difMin_PO[zoneNr, ref, rec].val, currDif);
            difAvTotal_PO[ref, rec].val :=
                       AV_Addsmpl( DifAvTotal_Con[ref, rec], currDif, FALSE);
            IF InSegment(zoneNr, CARDINAL(refDisCV), aligSec_Con)
            THEN
              alig_PO[ref, rec].val := AV_Addsmpl(alig_Con[ref, rec],
                                                  currDif,
                                                  FALSE);
            END (* InSegment *);
          END;
        END (* for ref *);
        MkrLength_Count(oMkrFlg,
                        mMkrFlg,
                        iMkrFlg,
                        rec,
                        CARDINAL(refDisCV),
                        signalsCV[agcM_Sg, rec],
                        mkrLengthCon[rec],
                        mkrLength);
      END (* for rec *);
    END (* with anRes.an_OpisOsi *);
  END An_OpisOsi_CP;

  PROCEDURE ProfBComm_CP;
  VAR
    rec : GlownyOdbiornikT;
    ref : OdnDlaPomBleduT;
    ang : INTEGER;

  BEGIN
    WITH anRes  DO
      FlagErr_Anal(currNavState[goA], NAVA_flg IN flgs, flagErr[goA],
                   refCV.Together[OdnDlaPomBledu], zoneNr);
      FlagErr_Anal(currNavState[goB], NAVB_flg IN flgs, flagErr[goB],
                   refCV.Together[OdnDlaPomBledu], zoneNr);
    END;
    WITH anRes.an_OpisProfilB DO
      FOR rec := goA TO goB DO
        FOR ref := pbTeodolit TO MAX(OdnDlaPomBleduT) DO
          ang := SigNilVal;
          AzDif0_Addsmpl(Dif0_Con[ref, rec], refCV.Together[ref], signalsCV[devL_Sg, rec
                         ], ang);
          GorszeBoBlisze(difAv0_PB[ref, rec].val, ang, 0);
          ang := SigNilVal;
          AzDif0_Addsmpl(Az0_Con[ref, rec], refCV.Together[ref], signalsCV[devL_Sg, rec]
                         , ang);
          GorszeBoBlisze(az0_PB[ref, rec].val, ang, 0);
          ang := SigNilVal;
          Azym_Addsmpl(Az150_150_Con[ref, rec], refCV.Together[ref], signalsCV[devL_Sg,
                       rec], ang);
          GorszeBoBlisze(az150_150_PB[ref, rec].val, ang, 0);
          ang := SigNilVal;
          Azym_Addsmpl(Az75_150_Con[ref, rec], refCV.Together[ref], signalsCV[devL_Sg,
                       rec], ang);
          GorszeBoBlisze(az75_150_PB[ref, rec].val, ang, 0);
          ang := SigNilVal;
          Azym_Addsmpl(Az150_90_Con[ref, rec], refCV.Together[ref], signalsCV[devL_Sg,
                       rec], ang);
          GorszeBoBlisze(az150_90_PB[ref, rec].val, ang, 0);
          ang := SigNilVal;
          Azym_Addsmpl(Az75_90_Con[ref, rec], refCV.Together[ref], signalsCV[devL_Sg,
                       rec], ang);
          GorszeBoBlisze(az75_90_PB[ref, rec].val, ang, 0);
          Clearence_Addsmpl(Clrnc150_Con[ref, rec], refCV.Together[ref], signalsCV[
                            devL_Sg, rec]);
          Clearence_Addsmpl(Clrnc90_Con[ref, rec], refCV.Together[ref], signalsCV[
                            devL_Sg, rec]);
        END (* for ref *);
      END (* for rec *);
    END (* with anRes.an_OpisProfilB *);
  END ProfBComm_CP;

  PROCEDURE An_OpisSektora_CP;
  VAR
    rec    : GlownyOdbiornikT;
    ref    : OdnDlaPomBleduT;
    currAz : INTEGER;

  BEGIN
    WITH anRes  DO
      FlagErr_Anal(currNavState[goA], NAVA_flg IN flgs, flagErr[goA],
                   refDisCV, zoneNr);
      FlagErr_Anal(currNavState[goB], NAVB_flg IN flgs, flagErr[goB],
                   refDisCV, zoneNr);
    END;
    WITH anRes.an_OpisSektora DO
      FOR rec := goA TO goB DO
        FOR ref := pbTeodolit TO MAX(OdnDlaPomBleduT) DO
          AzymAV_Addsmpl( AzymAV_Con[ref, rec],
                          refCV.Together[ref],
                          signalsCV[devL_Sg, rec],
                          AzAv_OS[zoneNr, ref, rec].val,
                          newZone);
          WITH anRes DO
            currAz := CountAzym( refCV.Together[ref], signalsCV[devL_Sg, rec],
                                 real(anRes.offset),
                                 real(anRes.ustawOsi)
                                );
            WriteFileRes(SecWith, ref, rec, currAz);
            GorszeBoWieksze ( AzMax_OSA[zoneNr, ref, rec].val, currAz );
            GorszeBoMniejsze( AzMin_OSA[zoneNr, ref, rec].val, currAz );
          END;
        END (* for ref *);
      END (* for rec *);
    END (* with anRes.an_OpisSektora *);
  END An_OpisSektora_CP;

  (*.F+ *)

  PROCEDURE An_OpisZasieg_do_10_CP;
  VAR
    ref : OdnDlaPomBleduT;
    rec : GlownyOdbiornikT;

  BEGIN
    WITH anRes  DO
      FlagErr_Anal(currNavState[goA], NAVA_flg IN flgs, flagErr[goA],
                   refCV.Together[OdnDlaPomBledu], zoneNr);
      FlagErr_Anal(currNavState[goB], NAVB_flg IN flgs, flagErr[goB],
                   refCV.Together[OdnDlaPomBledu], zoneNr);
    END;
    WITH anRes.an_OpisZasieg_do_10 DO
      FOR rec := goA TO goB DO
        FOR ref := pbTeodolit TO MAX(OdnDlaPomBleduT) DO
          IF (refCV.Together[ref] <> SigNilVal) AND (ABS(refCV.Together[ref]) <= 1000)
          THEN
            GorszeBoMniejsze(sS0_Min_ZW[ref, rec].val, signalsCV[agcL_Sg, rec])
          END (* if *);
        END (* for ref *);
      END (* for rec *);
    END (* with anRes.an_OpisZasieg_do_10 *);
  END An_OpisZasieg_do_10_CP;

  PROCEDURE An_OpisZasiegSzer_CP;
  VAR
    rec : GlownyOdbiornikT;
    ref : OdnDlaPomBleduT;

  BEGIN
    WITH anRes  DO
      FlagErr_Anal(currNavState[goA], NAVA_flg IN flgs, flagErr[goA],
                   refCV.Together[OdnDlaPomBledu], zoneNr);
      FlagErr_Anal(currNavState[goB], NAVB_flg IN flgs, flagErr[goB],
                   refCV.Together[OdnDlaPomBledu], zoneNr);
    END;
    WITH anRes.an_OpisZasiegSzer DO
      FOR rec := goA TO goB DO
        FOR ref := pbTeodolit TO MAX(OdnDlaPomBleduT) DO
          IF refCV.Together[ref] <> SigNilVal
          THEN
            IF (refCV.Together[ref] >= covSecMin) AND (refCV.Together[ref] <= covSecMax)
            THEN
              GorszeBoMniejsze(sS90_Min_ZS[ref, rec].val, signalsCV[agcL_Sg,
                               rec])
            END (* if *);
            IF (refCV.Together[ref] <= -covSecMin) AND (refCV.Together[ref] >= -covSecMax)
            THEN
              GorszeBoMniejsze(sS150_Min_ZS[ref, rec].val, signalsCV[agcL_Sg,
                               rec])
            END (* if *);
          END (* refCV.Together[ref] <> SigNilVal *);
        END (* for rec *);
      END (* for rec *)
    END (* with anRes.an_OpisZasiegSzer *)
  END An_OpisZasiegSzer_CP;

  PROCEDURE MkrL_CP;
  VAR
    rec : GlownyOdbiornikT;
    ref : OdnDlaPomBleduT;

  BEGIN
    WITH anRes  DO
      FlagErr_Anal(currNavState[goA], NAVA_flg IN flgs, flagErr[goA],
                   refDisCV, zoneNr);
      FlagErr_Anal(currNavState[goB], NAVB_flg IN flgs, flagErr[goB],
                   refDisCV, zoneNr);
    END;
    FOR rec := goA TO goB DO
      MkrLength_Count(oMkrFlg, mMkrFlg, iMkrFlg, rec, CARDINAL(refDisCV),
                      signalsCV[agcM_Sg, rec], mkrLengthCon[rec],
                      anRes.an_OpisMarker.mkrLength);
    END (* for rec *);
  END MkrL_CP;

  PROCEDURE CntProcedures_Prolog
            (    ZonesBeg : zoneBDisIdx_T );

    PROCEDURE ClearProcTable
              ( VAR procIdx   : ProcIdxT;
                VAR procTable : procTableT );
    VAR
      idx : ProcIdxT;

    BEGIN
      FOR idx := MIN(ProcIdxT) TO MAX(ProcIdxT) DO
        procTable[idx] := DummyProc;
      END (* for idx *);
      procIdx := MIN(ProcIdxT);
    END ClearProcTable;

    PROCEDURE ClearAllCont
              (    ZonesBeg : zoneBDisIdx_T );
    VAR
      rec : GlownyOdbiornikT;
      ref : OdnDlaPomBleduT;

      PROCEDURE alig_ContinerClear
                ( VAR alig_Continer : Alig_Continer_T;
                      ZonesBeg      : zoneBDisIdx_T   );

      BEGIN
        WITH anRes.an_OpisOsi DO
          WITH alig_Continer DO
            inZoneNotDist := TRUE;
            CASE L_DataBase.Lotnisko.Kategoria OF
              1 :
                inZoneNotDist := FALSE;
                IF ZonesBeg[np_B] <> DisNilVal
                THEN
                  begDist := ZonesBeg[np_B] + 54;   (* 200[m]/1852*500 *)
                  endDist := ZonesBeg[np_B] - 54;
                ELSE
                  begDist := DisNilVal;
                  endDist := DisNilVal;
                END (* if zonesBeg *);
              |
              2 :
                zones := ZonesSet{ ns_BCorT };
              |
              3 :
                zones := ZonesSet{ ns_BCorT, ns_CorTD };
            END (* case L_DataBase.Lotnisko.Kategoria *);
          END (* with alig_Continer *);
        END (* with anRes.an_OpisOsi *);
      END alig_ContinerClear;

    BEGIN
      SetPathAngle(0, znakSL);
      WITH anRes DO
        displSens := 3000.0 / FLOAT(secWith);
        FOR rec := goA TO goB DO
          FOR ref := pbTeodolit TO MAX(OdnDlaPomBleduT) DO
            Azym_Clear(Az150_150_Con[ref, rec], -1500, ustawOsi);
            Azym_Clear(Az75_150_Con[ref, rec], -750, ustawOsi);
            Azym_Clear(Az150_90_Con[ref, rec], 1500, ustawOsi);
            Azym_Clear(Az75_90_Con[ref, rec], 750, ustawOsi);
            Az0_Clear(Az0_Con[ref, rec], displSens);
            Clearence_Clear(Clrnc150_Con[ref, rec], znak150);
            Clearence_Clear(Clrnc90_Con[ref, rec], znak90);
            Dif0_Clear(Dif0_Con[ref, rec], displSens);
            AzymAV_Clear(AzymAV_Con[ref, rec], offset, ustawOsi);
            AV_Clear(DifAv_Con[ref, rec]);
            Az0Av_Clear(Az0Av_Con[ref, rec], displSens);
            AV_Clear(DifAvTotal_Con[ref, rec]);
            AV_Clear(alig_Con[ref, rec]);
          END (* for ref *);
          MkrALengthConClear(mkrLengthCon[rec]);
          AV_Clear(modLocAv_Con[rec]);
          AV_Clear(dewAv_BD_Cont[rec]);
          currNavState[rec] := FALSE;
        END (* for rec *);
      END (* with anRes *);
      alig_ContinerClear(aligSec_Con, ZonesBeg);
    END ClearAllCont;

    PROCEDURE AssignEvalProc
              ( VAR procIdx   : ProcIdxT;
                VAR procTable : procTableT );

      PROCEDURE TurnOn
                (    proc : PROC );

      BEGIN
        procTable[procIdx] := proc;
        INC(procIdx);
      END TurnOn;

    BEGIN (* AssignEvalProc *)
      CASE anRes.procedure OF
        pUstawienieOsi_Struktura, pAlarmOsi, pUstawienieOsi_Szer_pA,
        pUstawienieOsi_Waski_pA :
          TurnOn(An_OpisOsi_CP);
          PolContClear;
        |
        pSzerSektora_pA, pAlarmSzeroki_pA, pAlarmWaski_pA :
          TurnOn(An_OpisSektora_CP);
        |
        pSzer_i_Osi_pB, pAlarmSzer_pB, pAlarmWaski_pB, pWyrazistosc_na_d_katach
        :
          TurnOn(ProfBComm_CP);
        |
        pRownowagaModulacji, pFazowanie :
          TurnOn(An_OpisBadDod_CP);
        |
        pZasieg_do_10 :
          TurnOn(An_OpisZasieg_do_10_CP);
        |
        pZasieg_10_35, pZasieg_ponad_35 :
          TurnOn(An_OpisZasiegSzer_CP);
          IF anRes.procedure = pZasieg_10_35
          THEN
            covSecMax := 3500;
            covSecMin := 1000;
          ELSE
            covSecMax := 9000;
            covSecMin := 3500;
          END (* if anRes.procedure *);
        |
        pMarker :
          TurnOn(MkrL_CP);
      END (* case anRes.procedure *);
    END AssignEvalProc;

  CONST
    Create = TRUE;
  VAR
    resultIdx : resultT;

  BEGIN (* CntProcedures_Prolog *)
    FOR resultIdx := MIN(resultT) TO MAX(resultT) DO
      OpenFileRes(Create, resultIdx);
    END (* for resultIdx *);
    zoneNr := MIN(NumStrefy);
    ClearAllCont(ZonesBeg);
    ClearProcTable(procIdx, procTable);
    AssignEvalProc(procIdx, procTable);
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
                                              pAlarmWaski_pA }
  END InZoneAnalyse;
  (*.F+ *)

  PROCEDURE DoCountProcedures
            (    SignalsCV : SignalsCVDsc;
                 RefCV     : refTab;
                 RefDisCV  : WORD;
                 Flgs      : BITSET;
                 CurrZone  : NumStrefy;
                 polar     : BOOLEAN    );
  VAR
    idx : ProcIdxT;

  BEGIN
    signalsCV := SignalsCV;
    refCV := RefCV;
    refDisCV := RefDisCV;
    flgs := Flgs;
    newZone := CurrZone <> zoneNr;
    zoneNr := CurrZone;
    inPolar := polar;
    oMkrFlg[goA] := oMkrFlgPosA IN flgs;
    oMkrFlg[goB] := oMkrFlgPosB IN flgs;
    mMkrFlg[goA] := mMkrFlgPosA IN flgs;
    mMkrFlg[goB] := mMkrFlgPosB IN flgs;
    iMkrFlg[goA] := iMkrFlgPosA IN flgs;
    iMkrFlg[goB] := iMkrFlgPosB IN flgs;
    Common_CP;
    FOR idx := MIN(ProcIdxT) TO procIdx - 1 DO
      procTable[idx];
    END (* for idx *);
  END DoCountProcedures;

  PROCEDURE KapaFun1
            (    ref : OdnDlaPomBleduT;
                 rec : GlownyOdbiornikT;
                 dif : REAL             ) : INTEGER;

  BEGIN
    WITH anRes.an_OpisOsi DO
      RETURN difAv_PO[ns_toA, ref, rec].val;
    END (* with anRes.an_OpisOsi *);
  END KapaFun1;

  PROCEDURE KapaFun2
            (    ref : OdnDlaPomBleduT;
                 rec : GlownyOdbiornikT;
                 dif : REAL             ) : INTEGER;

  BEGIN
    WITH anRes.an_OpisOsi DO
      RETURN alig_PO[ref, rec].val;
    END (* with anRes.an_OpisOsi *);
  END KapaFun2;

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
      ref : OdnDlaPomBleduT;
    CONST
      maksSektor = 1500;
      
    BEGIN
      FOR rec := goA TO goB DO
        FOR ref := pbTeodolit TO MAX(OdnDlaPomBleduT) DO
          IF (Eta1[ref, rec].val      = SigNilVal  ) OR
             (Eta2[ref, rec].val      = SigNilVal  )
          THEN
            ChiLoc[ref, rec].val := SigNilVal;
          ELSIF (ABS(Eta1[ref, rec].val) > maksSektor ) OR
                (ABS(Eta2[ref, rec].val) > maksSektor )
          THEN
            (* przy zlym ustawieniu polozenia w bazie pojawialy sie bledy *)
            ChiLoc[ref, rec].val := SigNilVal;
          ELSE
            ChiLoc[ref, rec].val := ABS(Eta1[ref, rec].val) + 
                                    ABS(Eta2[ref, rec].val)
          END (* if *);
        END (* for ref *);
      END (* for rec *);
    END Count_ChiLoc;

    PROCEDURE Count_PhiLoc
              ( VAR PhiLoc : DevValueTab;
                    Eta0   : DevValueTab;
                    Eta    : DevValueTab;
                    ChiLoc : DevValueTab );
    VAR
      rec     : GlownyOdbiornikT;
      ref     : OdnDlaPomBleduT;
      Eta0R   : REAL;
      EtaR    : REAL;
      ChiLocR : REAL;

    BEGIN
      FOR rec := goA TO goB DO
        FOR ref := pbTeodolit TO MAX(OdnDlaPomBleduT) DO
          IF (Eta0[ref, rec].val = SigNilVal) OR
             (Eta[ref, rec].val = SigNilVal)
          THEN
            PhiLoc[ref, rec].val := SigNilVal;
          ELSIF ChiLoc[ref, rec].val = SigNilVal THEN
            (* rozbicie warunku ze wzgledu na ograniczenie kompilatora *)
            PhiLoc[ref, rec].val := SigNilVal;
          ELSE
            Eta0R := real(Eta0[ref, rec].val);
            EtaR := real(Eta[ref, rec].val);
            ChiLocR := real(ChiLoc[ref, rec].val);
            IF NOT entierCheck(ABS((EtaR - Eta0R) / ChiLocR * 1000.0) + 0.5,
                               PhiLoc[ref, rec].val)
            THEN
              PhiLoc[ref, rec].val := SigNilVal;
            END (* if *);
          END (* if *);
        END (* for ref *);
      END (* for rec *);
    END Count_PhiLoc;

    PROCEDURE AssignAz
              (     currEta       : DevValueTab;
                VAR lastEta_150_A : DevValueTab;
                VAR lastEta_90_A  : DevValueTab;
                    strona        : StronaT     );

      
      PROCEDURE mulDevValueTab
                (     A   : DevValueTab;
                      B   : INTEGER;
                  VAR res : DevValueTab );
      VAR
        ref : OdnDlaPomBleduT;
        rec : GlownyOdbiornikT;

      BEGIN
        FOR rec := goA TO goB DO
          FOR ref := pbTeodolit TO MAX(OdnDlaPomBleduT) DO
            IF A[ref, rec].val <> NilValI
            THEN
              res[ref, rec].val := A[ref, rec].val * B;
            ELSE
              res[ref, rec].val := NilValI;
            END (* if A *);
          END (* for ref *);
        END (* for rec *);
      END mulDevValueTab;

    BEGIN
      CASE strona OF
        sL150 :
          lastEta_90_A := currEta;
        |
        sL75 :
          mulDevValueTab(currEta, 2, lastEta_90_A);

        |
        sP75 :
          mulDevValueTab(currEta, 2, lastEta_150_A);

        |
        sP150 :
          lastEta_150_A := currEta;
          
      END (* case strona *);
    END AssignAz;

    PROCEDURE AssignClearence
              ( VAR an_OpisProfilB : An_OpisProfilBT );
    VAR
      ref        : OdnDlaPomBleduT;
      rec        : GlownyOdbiornikT;
      bylRobiony : BOOLEAN;
      
    BEGIN (* AssignClearence *)
      WITH an_OpisProfilB DO
        FOR rec := goA TO goB DO
          FOR ref := pbTeodolit TO MAX(OdnDlaPomBleduT) DO
            bylRobiony  := Clrnc90_Con [ref, rec].bylPom  AND 
                           Clrnc150_Con[ref, rec].bylPom;
            IF bylRobiony  THEN
              WITH Clrnc90_Con[ref, rec] DO
                H175Mn[ref, rec].val := h175Mn;
                H175Mx[ref, rec].val := h175Mx;
                H150mn[ref, rec].val := h150Mn;
              END (* with Clrnc90_Con *);
              WITH Clrnc150_Con[ref, rec] DO
                HM175Mn[ref, rec].val := h175Mn;
                HM175Mx[ref, rec].val := h175Mx;
                HM150mn[ref, rec].val := h150Mn;
              END (* with Clrnc150_Con *);
            END (* IF *);
          END (* for ref *);
        END (* for rec *);
      END (* with an_OpisProfilB *);
    END AssignClearence;

    PROCEDURE InitCon;
    VAR
      rec      : GlownyOdbiornikT;
      ref      : OdnDlaPomBleduT;
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
          boundary[np_B] := 50.0;
          boundary[np_CorT] := 50.0;
          boundary[np_D] := 50.0;
          boundary[np_E] := 100.0;
        ELSE
          boundary[np_B] := 150.0;
          boundary[np_CorT] := 150.0;
          boundary[np_D] := 150.0;
          boundary[np_E] := 150.0;
        END (* if cat *);
      END FillBound;

    BEGIN
      KapaBuff[ns_toA] := KapaFun1;
      KapaBuff[ns_AB] := KapaFun2;
      KapaBuff[ns_BCorT] := KapaFun2;
      KapaBuff[ns_CorTD] := KapaFun2;
      KapaBuff[ns_DE] := KapaFun2;
      FillBound(boundary, L_DataBase.Lotnisko.Kategoria);
      FOR rec := goA TO goB DO
        FOR ref := pbTeodolit TO MAX(OdnDlaPomBleduT) DO
          bendState[ref, rec] := FALSE;
          Bend_ClearContainer(Bend_con[ref, rec], ZoneBIdx, boundary, KapaBuff)
          ;
        END (* for ref *)
      END (* for rec *);
    END InitCon;

  BEGIN (* CntProcedures_Epilog *)
    DoStructAn := FALSE;
    WITH anRes DO
      CASE procedure OF
        pUstawienieOsi_Struktura, pAlarmOsi, pUstawienieOsi_Szer_pA,
        pUstawienieOsi_Waski_pA :
          DoStructAn := TRUE;
          InitCon;
          CASE procedure OF
            pUstawienieOsi_Struktura :
              lastAzAv_A[Nadajnik] := an_OpisOsi.AzAv_PO[StrefaPomSek];
            |
            pUstawienieOsi_Szer_pA :
              lastAzAv_AWd[Nadajnik] := an_OpisOsi.AzAv_PO[StrefaPomSek];
            |
            pUstawienieOsi_Waski_pA :
              lastAzAv_ANr[Nadajnik] := an_OpisOsi.AzAv_PO[StrefaPomSek];
          ELSE
          END (* case procedure *);
        |
        pSzerSektora_pA :
          WITH an_OpisSektora DO
            AssignAz(AzAv_OS[StrefaPomSek], lastEta_150_A[Nadajnik],
                     lastEta_90_A[Nadajnik], strona);
            Count_ChiLoc(ChiLoc, lastEta_150_A[Nadajnik], lastEta_90_A[Nadajnik]);
            Count_PhiLoc(PhiLoc, lastAzAv_A[Nadajnik], lastEta_90_A[Nadajnik], ChiLoc);
          END (* with an_OpisSektora *);
        |
        pAlarmSzeroki_pA :
          WITH an_OpisSektora DO
            AssignAz(AzAv_OS[StrefaPomSek], lastEta_150_AWd[Nadajnik],
                     lastEta_90_AWd[Nadajnik], strona);
            Count_ChiLoc(ChiLoc, lastEta_150_AWd[Nadajnik], lastEta_90_AWd[Nadajnik]);
            Count_PhiLoc(PhiLoc, lastAzAv_AWd[Nadajnik], lastEta_90_AWd[Nadajnik], ChiLoc);
          END (* with an_OpisSektora *);
        |
        pAlarmWaski_pA :
          WITH an_OpisSektora DO
            AssignAz(AzAv_OS[StrefaPomSek], lastEta_150_ANr[Nadajnik],
                     lastEta_90_ANr[Nadajnik], strona);
            Count_ChiLoc(ChiLoc, lastEta_150_ANr[Nadajnik], lastEta_90_ANr[Nadajnik]);
            Count_PhiLoc(PhiLoc, lastAzAv_ANr[Nadajnik], lastEta_90_ANr[Nadajnik], ChiLoc);
          END (* with an_OpisSektora *);
        |
        pSzer_i_Osi_pB, pAlarmSzer_pB, pAlarmWaski_pB, pWyrazistosc_na_d_katach
        :
          WITH an_OpisProfilB DO
            Count_ChiLoc(ChiLoc, az150_150_PB, az150_90_PB);
            Count_PhiLoc(PhiLoc, az0_PB, az150_90_PB, ChiLoc);
            AssignClearence(an_OpisProfilB);
          END (* with an_OpisProfilB *);
      ELSE
        ;
      END (* case anRes.procedure *);
    END (* with anRes *);
  END CntProcedures_Epilog;

  PROCEDURE PolContClear;
  VAR
    rec : GlownyOdbiornikT;
    ref : OdnDlaPomBleduT;

  BEGIN
    FOR rec := goA TO goB DO
      FOR ref := pbTeodolit TO MAX(OdnDlaPomBleduT) DO
        WITH PolCont[ref, rec] DO
          sum_Left := 0.0;
          polSam_Left := 0;
          sum_Plain := 0.0;
          polSam_Plain := 0;
          sum_Rihght := 0.0;
          polSam_Rihght := 0;
        END (* with PolCont *);
      END (* for ref *);
    END (* for rec *);
  END PolContClear;

  PROCEDURE Pol_AddSample
            (    SignalsCV : SignalsCVDsc;
                 RefCV     : refTab;
                 PolSector : PolSector_T;
                 count     : BOOLEAN      );
  VAR
    currDifR : REAL;
    currDif  : INTEGER;
    rec      : GlownyOdbiornikT;
    ref      : OdnDlaPomBleduT;

  BEGIN
    FOR rec := goA TO goB DO
      FOR ref := pbTeodolit TO MAX(OdnDlaPomBleduT) DO
        currDif := CountDif(refCV.Together[ref], SignalsCV[devL_Sg, rec], displSens, 0.0
                   );
        IF count
        THEN
          currDifR := real(currDif);
          WITH PolCont[ref, rec] DO
            CASE PolSector OF
              Pol_Left :
                sum_Left := sum_Left + currDifR;
                INC(polSam_Left);
              |
              Pol_Plain :
                sum_Plain := sum_Plain + currDifR;
                INC(polSam_Plain);
              |
              Pol_Right :
                sum_Rihght := sum_Rihght + currDifR;
                INC(polSam_Rihght);
            END (* case PolSector *);
          END (* with PolCont *);
        END (* if count *);
      END (* for ref *);
    END (* for rec *);
  END Pol_AddSample;

  PROCEDURE AssignPolRes
            (    xRef : WORD );
  VAR
    rec     : GlownyOdbiornikT;
    ref     : OdnDlaPomBleduT;
    zeroAV  : INTEGER;
    lowoAV  : INTEGER;
    prawoAV : INTEGER;

  BEGIN
    FOR rec := goA TO goB DO
      FOR ref := pbTeodolit TO MAX(OdnDlaPomBleduT) DO
        WITH PolCont[ref, rec] DO
          lowoAV := entier(sum_Left / FLOAT(polSam_Left) + 0.5);
          zeroAV := entier(sum_Plain / FLOAT(polSam_Plain) + 0.5);
          prawoAV := entier(sum_Rihght / FLOAT(polSam_Rihght) + 0.5);
        END (* with PolCont *);
        WITH anRes.an_OpisOsi DO
          WITH difAvPolL_PO[ref, rec] DO
            val := lowoAV - zeroAV;
            pos := xRef;
          END (* with devDet *);
          WITH difAvPolR_PO[ref, rec] DO
            val := prawoAV - zeroAV;
            pos := xRef;
          END (* with devDet *);
        END (* with anRes *);
      END (* for ref *);
    END (* for rec *);
  END AssignPolRes;

  PROCEDURE DoBendAnalyse
            (    devL_Sg      : signTab;
                 Idx          : CARDINAL;
                 refCV        : refTab;
                 refDisCV     : WORD;
                 currZone     : NumStrefy;
                 zoneExcluded : BOOLEAN   );
  VAR
    currdif    : INTEGER;
    rec        : GlownyOdbiornikT;
    ref        : OdnDlaPomBleduT;
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
      FlagErr_Anal(bendOut, bends > 50, roughErr_PO, dis, CurrZone);
    END RoughErr_An;

  BEGIN (* DoBendAnalyse *)
    WITH anRes.an_OpisOsi DO
      FOR rec := goA TO goB DO
        FOR ref := pbTeodolit TO MAX(OdnDlaPomBleduT) DO
          IF zoneExcluded
          THEN
            currdif := SigNilVal;
          ELSE
            currdif := CountDif(refCV.Together[ref], devL_Sg[rec], displSens, 0.0);
          END (* if zoneExcluded *);
          isRes := Bend_AddSample(currdif, Idx, CARDINAL(refDisCV), currZone,
                                  ref, rec, boundP_res, boundM_res, centre_res,
                                  bends, Bend_con[ref, rec]);
          WriteFileRes(boundP, ref, rec, boundP_res);
          WriteFileRes(boundM, ref, rec, boundM_res);
          WriteFileRes(DifAV, ref, rec, centre_res);
          IF isRes
          THEN
            GorszeBoWieksze(roughness_PO[currZone, ref, rec].val, bends);
            RoughErr_An(bends, roughErr_PO[ref, rec], CARDINAL(refDisCV),
                        bendState[ref, rec], currZone);
          END (* if isRes *);
        END (* for ref *);
      END (* for rec *);
    END (* with anRes.an_OpisOsi *);
  END DoBendAnalyse;

  PROCEDURE Close_CntProcedures
            ( VAR SyntResult      : INTEGER;
              VAR podzielnik      : INTEGER;
                  ZoneBDisIdx : zoneBDisIdx_T );
  VAR
    resultIdx : resultT;

  BEGIN
    FOR resultIdx := MIN(resultT) TO MAX(resultT) DO
      CloseFileRes(resultIdx);
    END (* for resultIdx *);
    WITH anRes DO
      CASE procedure OF
        pUstawienieOsi_Struktura, pAlarmOsi :
          WITH an_OpisOsi DO
            podzielnik := 10;
            IF alig_PO[odnDlaPomBledu, glownyOdbiornik].val <> SigNilVal THEN
              SyntResult := alig_PO[odnDlaPomBledu, glownyOdbiornik].val;
            ELSE
              SyntResult := difAv_PO[ns_BCorT, odnDlaPomBledu, 
                                      glownyOdbiornik].val;
            END;
            zonesBeg := ZoneBDisIdx;
          END (* with an_OpisOsi *);
        |
        pUstawienieOsi_Szer_pA, pUstawienieOsi_Waski_pA :
          WITH an_OpisOsi DO
            podzielnik := 100;
            SyntResult := an_OpisOsi.AzAv_PO[ StrefaPomSek, odnDlaPomBledu, 
                                              glownyOdbiornik ].val;
            zonesBeg := ZoneBDisIdx;
          END (* with an_OpisOsi *);
        |
        pSzerSektora_pA, pAlarmSzeroki_pA, pAlarmWaski_pA :
          WITH an_OpisSektora DO
            podzielnik := 100;
            SyntResult := 
              AzAv_OS[StrefaPomSek, odnDlaPomBledu, glownyOdbiornik].val;
            zonesBeg := ZoneBDisIdx;
          END (* with an_OpisSektora *);
        |
        pSzer_i_Osi_pB, pAlarmSzer_pB, pAlarmWaski_pB, pWyrazistosc_na_d_katach
        :
          podzielnik := 100;
          SyntResult := 
            an_OpisProfilB.ChiLoc[odnDlaPomBledu, glownyOdbiornik].val;
        |
        pRownowagaModulacji, pFazowanie :
          podzielnik := 10;
          SyntResult := an_OpisBadDod.dewAv[glownyOdbiornik].val;
        |
        pZasieg_do_10 :
          podzielnik := 1;
          SyntResult := 
            an_OpisZasieg_do_10.sS0_Min_ZW[odnDlaPomBledu, glownyOdbiornik].val;
        |
        pZasieg_10_35, pZasieg_ponad_35 :
          WITH an_OpisZasiegSzer DO
            podzielnik := 1;
            GorszeBoMniejsze(SyntResult, sS150_Min_ZS[odnDlaPomBledu,
                             glownyOdbiornik].val);
            GorszeBoMniejsze(SyntResult, sS90_Min_ZS[odnDlaPomBledu,
                             glownyOdbiornik].val);
          END (* with an_OpisZasiegSzer *);
        |
        pMarker :
          podzielnik := 500;
          SyntResult := 
            an_OpisMarker.mkrLength.oMkrL_OM[glownyOdbiornik].val;
      ELSE
        ;
      END (* case anRes.procedure *);
    END (* with anRes *);
  END Close_CntProcedures;

END L_CntProcedures.
