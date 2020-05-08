(*.F- *)
(**********************************************************************
|  Title   : Definicja typow potrzebnych do analizy
|  Author  : M. Postol
|  System  : LOGITECH MODULA-2/86
|  History :
|    19-01-96: M.Postol
|      wprowadzilem wycinanie w analizie ostatnich 360ø
|    01-02-96: M.Postol
|      zmieniono znak dla bledu (dev)
|    16-05-97: M.Postol
|      zmienilem znak bledu namiaru
|    30-05-97: M.Postol
|      wywalilem ABS z SyntResult, dostosowanie do nowej def FlagAnal
|    Rel 3.0. M.Postol
|      Zmiana definicji V_results 
|      Calkowita zmiana O_Analiza
|
|  Copyright (C), CAS LODZ POLAND.
|  TEL: 42' 686 25 47
|  mailto: techsupp@cas.com.pl
|  http: www.cas.com.pl
|
**********************************************************************)
(*.F+ *)

IMPLEMENTATION MODULE V_Count;

  IMPORT
    VORO_avrage;

  FROM DisResUtilities IMPORT
    WrSPlus;

  FROM EventsMng IMPORT
    GetUpdNextEvent, EventKind, SaveDistEvents;

  FROM V_Files IMPORT
    (* TYPE *) SignalsCVDsc,
    (* PROCEDURE *) OpenSignalFiles, StartFileRes, ReadAllSignals, WriteFileRes
                    , CloseSignalFiles, StopFileRes;

  FROM SYSTEM IMPORT
    WORD;

  FROM V_results IMPORT
    (* TYPE *) Parametr, Signals,
    (* VAR *) anRes,
    (* PROCEDURE *) SaveAnRes;

  FROM Files IMPORT
    XRefKind, SigInterpolacja;

  FROM CommonTypes IMPORT
    (* TYPE *) refTab, GlownyOdbiornikT, OdnDlaPomBleduT, OdnDlaPomOdlT,
               SigNilVal, NumStrefy, flgTab,
    (* CONST *) NilValI, NilValC,
    (* PROCEDURE *) Init_flgTab;

  FROM V_CommonTypes IMPORT
    ProceduraT;

  FROM MathLib0 IMPORT
    entier, real;

  FROM V_DisResults IMPORT
    WriteTab;

  FROM VORR_Average IMPORT
    (* TYPE *) Bend_Descriptor, Roughness_Descriptor,
    (* PROCEDURE *) Roughness_ClearContainer, Roughness_AddSample,
                    Bend_ClearContainer, Bend_AddSample;

  FROM SpecConv IMPORT
    SubAngle100, Angle100;

  FROM FlagAnal IMPORT
    FlagErr_Anal;

  FROM WorseBecause IMPORT
    WorseBLess, WorseBGreater;

  FROM MMA_Cout IMPORT
    AvrDscr, MinMaxAvr, Init_AvrDscr;
    
  CONST
    Pomiar  = FALSE;
    PolSam  = 10;
    PolSamR = 10.0;

  TYPE
    myEvent      =
      ( StartPomiaruME,
        StopPomiaruME,
        KoniecDanychME,
        PolVLewoME,
        PolVZeroME,
        PolVPrawoME,
        DaneME,
        NicME );
    bendsArr     =
      ARRAY OdnDlaPomBleduT, GlownyOdbiornikT OF Bend_Descriptor;
    roughnessArr =
      ARRAY OdnDlaPomBleduT, GlownyOdbiornikT OF Roughness_Descriptor;
    AvrArr       =
      ARRAY [ Var .. Agc ], GlownyOdbiornikT OF AvrDscr;
    DevAvrArr    =
      ARRAY OdnDlaPomBleduT, GlownyOdbiornikT OF AvrDscr;
    LastAz       =
      ARRAY [ TEOAxref .. GPSAxref ] OF INTEGER;

  (* Zmienne zadeklarowane globalnie bo problem ze stosem *)
  
  VAR
    dvAVcont      : DevAvrArr;
    signalsAVcont : AvrArr;
    bendsCon      : bendsArr;
    roughnessCon  : roughnessArr;
    
  PROCEDURE Analiza
            (     procedura       : ProceduraT;
                  odnDlaOdl       : OdnDlaPomOdlT;
                  OdnDlaPomBledu  : OdnDlaPomBleduT;
                  GlownyOdbiornik : GlownyOdbiornikT;
                  twoLocations    : BOOLEAN;
              VAR SyntResult      : INTEGER;
              VAR precision       : INTEGER);
  TYPE
    TyppomiaruT =
      ( pNORM,
        pOFF,
        pLEFT,
        pZERO,
        pRIGHT );

  VAR
    SumPol : ARRAY OdnDlaPomBleduT, 
                   GlownyOdbiornikT, 
                   [ pLEFT .. pRIGHT ] OF REAL;
        (* 2 odniesienia 2 kanaly 3 fazy *)
    PolOk  : ARRAY OdnDlaPomBleduT, GlownyOdbiornikT OF BOOLEAN;



  VAR
    line   : CARDINAL;
    lastAz : LastAz;


    PROCEDURE CountDev
              (    signal : INTEGER;
                   ref    : INTEGER ): INTEGER;
    BEGIN
      RETURN SubAngle100( ref, signal );
    END CountDev;

    PROCEDURE SigMaxAvr
              (     signalsCV     : SignalsCVDsc;
                    RefDisCV      : WORD;
                VAR signalsAVcont : AvrArr       );

    VAR
      odb        : GlownyOdbiornikT;
      signalFIdx : Signals;

    BEGIN
      FOR odb := goA TO goB DO
        FOR signalFIdx := Var TO Agc DO
          MinMaxAvr( signalsCV[signalFIdx, odb], RefDisCV, signalsAVcont[
                     signalFIdx, odb] );
        END (* for signalFIdx *);
      END (* for odb *)
    END SigMaxAvr;


    PROCEDURE CountAv
              (    AVcont        : DevAvrArr;
                   signalsAVcont : AvrArr    );

    VAR
      odb        : GlownyOdbiornikT;
      odn        : OdnDlaPomBleduT;
      signalFIdx : Signals;

    BEGIN
      FOR odn := pbTeodolit TO pbGPS DO
        FOR odb := goA TO goB DO
          WITH anRes DO
            WITH AVcont[odn, odb] DO
              IF num > 10
              THEN
                devDet[AV, odn, odb].val := entier( sum / FLOAT( num ) );
                devDet[MM, odn, odb] := min;
                devDet[MP, odn, odb] := max;
              ELSE
                devDet[AV, odn, odb].val := NilValI;
                devDet[MM, odn, odb].val := NilValI;
                devDet[MP, odn, odb].val := NilValI;
              END (* if num *);
            END (* with AVcont *);
            FOR signalFIdx := Var TO Agc DO
              WITH signalsAVcont[signalFIdx, odb] DO
                IF num > 10
                THEN
                  signalGen[AV, signalFIdx, odb].val := entier( sum / FLOAT(
                                                                num ) );
                  signalGen[MM, signalFIdx, odb] := min;
                  signalGen[MP, signalFIdx, odb] := max;
                ELSE
                  signalGen[AV, signalFIdx, odb].val := NilValI;
                  signalGen[MM, signalFIdx, odb].val := NilValI;
                  signalGen[MP, signalFIdx, odb].val := NilValI;
                END (* if num *);
              END (* with signalsAVcont *);
            END (* for signalFIdx *);
          END (* with anRes *);
        END (* for odb *);
      END (* for odn *);
    END CountAv;



    PROCEDURE ClearAvrArr
              ( VAR AVcont  : AvrArr;
                    posNilV : WORD   );

    VAR
      odb  : GlownyOdbiornikT;
      sign : Signals;

    BEGIN
      FOR sign := Var TO Agc DO
        FOR odb := goA TO goB DO
          Init_AvrDscr( AVcont[sign, odb], posNilV );
        END (* for odb *);
      END (* for sign *);
    END ClearAvrArr;

    PROCEDURE ClearDevAvrArr
              ( VAR AVcont  : DevAvrArr;
                    posNilV : WORD      );

    VAR
      odb : GlownyOdbiornikT;
      odn : OdnDlaPomBleduT;

    BEGIN
      FOR odb := goA TO goB DO
        FOR odn := MIN(OdnDlaPomBleduT) TO MAX(OdnDlaPomBleduT) DO
          Init_AvrDscr( AVcont[odn, odb], posNilV );
        END; (* FOR odn *);
      END (* for odb *);
    END ClearDevAvrArr;

    PROCEDURE R_Analiza
              (    twoLocations : BOOLEAN );

    PROCEDURE GetEvent
              (     currSmpl  : CARDINAL;
                VAR evidx     : CARDINAL;
                    position  : WORD;
                    dataLngth : CARDINAL ) : myEvent;

    BEGIN
      IF currSmpl >= dataLngth
      THEN
        RETURN KoniecDanychME;
      END (* if position *);
      CASE GetUpdNextEvent( Pomiar, currSmpl, evidx, position ) OF
        StartPomiaru :
          RETURN StartPomiaruME; |
        StopPomiaru :
          RETURN StopPomiaruME; |
        PolVLewo :
          RETURN PolVLewoME; |
        PolVZero :
          RETURN PolVZeroME; |
        PolVPrawo :
          RETURN PolVPrawoME; |
        BrakZnacznika :
          RETURN DaneME;
      ELSE
        RETURN NicME;
      END (* case GetUpdNextEvent *);
    END GetEvent;



    TYPE
      TyppomiaruSet =
        SET OF TyppomiaruT;

    VAR
      dataLngth        : CARDINAL;
      odb              : GlownyOdbiornikT;
      evidx            : CARDINAL;
      smpIdx           : CARDINAL;
      RefDisCV         : CARDINAL;
      odn              : OdnDlaPomBleduT;
      dv               : INTEGER;
      signalsCV        : SignalsCVDsc;
      refCV            : refTab;
      avrMoving        : INTEGER;
      roughness        : INTEGER;
      state            : TyppomiaruT;
      liczdo10         : CARDINAL;
      lsPrevFlagState  : flgTab;
      flgPrevFlagState : flgTab;
      startRef         : OdnDlaPomBleduT;
      flags            : flgTab;
      newSeg           : BOOLEAN;


      PROCEDURE AssignPolRes
                (    xRef : WORD );

      VAR
        odb     : GlownyOdbiornikT;
        odn     : OdnDlaPomBleduT;
        zeroAV  : INTEGER;
        lowoAV  : INTEGER;
        prawoAV : INTEGER;

      BEGIN
        WITH anRes DO
          FOR odn := pbTeodolit TO pbGPS DO
            FOR odb := goA TO goB DO
              IF PolOk[odn, odb]
              THEN
                lowoAV := entier( SumPol[odn, odb, pLEFT] / PolSamR + 0.5 );
                zeroAV := entier( SumPol[odn, odb, pZERO] / PolSamR + 0.5 );
                prawoAV := entier( SumPol[odn, odb, pRIGHT] / PolSamR + 0.5 );
                WITH devDet[PolLewo, odn, odb] DO
                  val := lowoAV - zeroAV;
                  pos := xRef;
                END (* with devDet *);
                WITH devDet[PolPrawo, odn, odb] DO
                  val := prawoAV - zeroAV;
                  pos := xRef;
                END (* with devDet *);
              END (* if PolOk *);
            END (* for odb *);
          END (* for odn *);
        END (* with anRes *);
      END AssignPolRes;


      PROCEDURE Pol_AddSample
                ( VAR sum : REAL;
                      dv  : INTEGER;
                  VAR ok  : BOOLEAN );

      BEGIN
        IF dv <> SigNilVal
        THEN
          sum := sum + real( dv );
        ELSE
          ok := FALSE;
        END (* if dv *);
      END Pol_AddSample;


      PROCEDURE ClearAllCont
                ( VAR dvAVcont      : DevAvrArr;
                  VAR signalsAVcont : AvrArr;
                  VAR roughnessCon  : roughnessArr;
                  VAR bendsCon      : bendsArr     );

      VAR
        odb : GlownyOdbiornikT;
        odn : OdnDlaPomBleduT;

      BEGIN
        ClearAvrArr( signalsAVcont, NilValI );
        ClearDevAvrArr( dvAVcont, NilValI );
        FOR odn := pbTeodolit TO pbGPS DO
          FOR odb := goA TO goB DO
            Roughness_ClearContainer( roughnessCon[odn, odb] );
            Bend_ClearContainer( bendsCon[odn, odb] );
            PolOk[odn, odb] := TRUE;
            SumPol[odn, odb, pLEFT] := 0.0;
            SumPol[odn, odb, pZERO] := 0.0;
            SumPol[odn, odb, pRIGHT] := 0.0;
          END (* for odb *);
        END (* for odn *);
      END ClearAllCont;

      PROCEDURE CountBends;

      VAR
        average : INTEGER;

      BEGIN
        WITH anRes DO
          FOR odn := pbTeodolit TO pbGPS DO
            FOR odb := goA TO goB DO
              average := devDet[AV, odn, odb].val;
              IF average <> NilValI
              THEN
                WITH devDet[UGMinus, odn, odb] DO
                  IF val <> NilValI
                  THEN
                    val := val - average;
                  END (* if val *);
                END (* with devDet *);
                WITH devDet[UGPlus, odn, odb] DO
                  IF val <> NilValI
                  THEN
                    val := val - average;
                  END (* if val *);
                END (* with devDet *);
              END (* if Dev *);
            END (* for odb *);
          END (* for odn *);
        END (* with anRes *);
      END CountBends;

    BEGIN (* R_Analiza *)
      lsPrevFlagState[goA] := FALSE;
      lsPrevFlagState[goB] := FALSE;
      flgPrevFlagState[goA] := FALSE;
      flgPrevFlagState[goB] := FALSE;
      ClearAllCont( dvAVcont, signalsAVcont, roughnessCon, bendsCon );
      dataLngth := OpenSignalFiles( odnDlaOdl );
      evidx := 0;
      smpIdx := 0;
      ReadAllSignals( signalsCV, refCV, flags, newSeg, RefDisCV );
      StartFileRes( TRUE );
      IF twoLocations
      THEN
        startRef := pbGPS;
      ELSE
        startRef := pbTeodolit;
      END (* if twoLocations *);
      WITH anRes DO
        LOOP
          CASE GetEvent( smpIdx, evidx, RefDisCV, dataLngth ) OF
            StartPomiaruME :
              state := pNORM;; |
            StopPomiaruME :
              FOR odb := goA TO goB DO
                Roughness_ClearContainer( roughnessCon[odn, odb] );
                Bend_ClearContainer( bendsCon[odn, odb] );
              END (* for odb *);
              state := pOFF; |
            PolVLewoME :
              state := pLEFT;
              liczdo10 := 0; |
            PolVZeroME :
              state := pZERO;
              liczdo10 := 0; |
            PolVPrawoME :
              state := pRIGHT;
              liczdo10 := 0; |
            KoniecDanychME :
              EXIT; |
            DaneME :
              IF state = pNORM
              THEN
                SigMaxAvr( signalsCV, RefDisCV, signalsAVcont );
              END (* if state *);
              FOR odb := goA TO goB DO
                FOR odn := startRef TO pbGPS DO
                  IF twoLocations
                  THEN
                    dv := CountDev( signalsCV[Obr, odb], refCV.Spread[odb] );
                  ELSE
                    dv := CountDev( signalsCV[Obr, odb], refCV.Together[odn]);
                  END (* if twoLocations *);
                  CASE state OF
                    pOFF : |
                    pNORM :
                      MinMaxAvr( dv, RefDisCV, dvAVcont[odn, odb] );
                      IF RefDisCV = NilValC
                      THEN
                        Roughness_ClearContainer( roughnessCon[odn, odb] );
                        Bend_ClearContainer( bendsCon[odn, odb] );
                      ELSE
                        IF Bend_AddSample( dv, RefDisCV, avrMoving, bendsCon[
                                           odn, odb] )
                        THEN
                          WorseBGreater( devDet[UGPlus, odn, odb], avrMoving,
                                         RefDisCV );
                          WorseBLess( devDet[UGMinus, odn, odb], avrMoving,
                                      RefDisCV );
                        END (* if Bend_AddSample *);
                        IF Roughness_AddSample( dv, RefDisCV, roughness,
                                                roughnessCon[odn, odb] )
                        THEN
                          WorseBGreater( anRes.devDet[FAL, odn, odb], roughness
                                         , RefDisCV );
                        END (* if Roughness_AddSample *);
                      END (* if RefDisCV *); |
                    pLEFT,
                    pZERO,
                    pRIGHT :
                      Pol_AddSample( SumPol[odn, odb, state], dv, PolOk[odn,
                                     odb] );
                  END (* case state *);
                  WriteFileRes( odn, odb, dv );
                END (* for odn *);
                IF signalsCV[Agc, odb] <> SigNilVal
                THEN
                  FlagErr_Anal( lsPrevFlagState[odb], 
                                signalsCV[Agc, odb] < 5,
                                lowSigTab[odb], 
                                RefDisCV, 
                                ns_no );
                END (* if signalsCV *);
                FlagErr_Anal( flgPrevFlagState[odb], 
                              NOT flags[odb],
                              (* Rel.3.0. signalsCV[Obr, odb] = SigNilVal *) 
                              flagTab[odb], 
                              RefDisCV, 
                              ns_no);
              END (* for odb *);
              IF state IN TyppomiaruSet { pLEFT, pZERO, pRIGHT }
              THEN
                INC( liczdo10 );
                IF liczdo10 > PolSam
                THEN
                  IF state = pRIGHT
                  THEN
                    AssignPolRes( RefDisCV );
                  END (* if state *);
                  state := pOFF;
                END (* if liczdo10 *);
              END (* if state *);
              ReadAllSignals( signalsCV, refCV, flags, newSeg, RefDisCV );
              INC( smpIdx ) |
            NicME :
              ;
          END (* case GetEvent *);
        END (* loop *);
      END (* with anRes *);
      CloseSignalFiles;
      StopFileRes;
      CountAv( dvAVcont, signalsAVcont );
      CountBends;
    END R_Analiza;

    PROCEDURE O_Analiza;

    TYPE
      O_AvrDscArr =
        ARRAY OdnDlaPomBleduT, GlownyOdbiornikT OF VORO_avrage.AVRdescription;
      T_WynikAnalizyNaLuku =
        RECORD
          kompletny : BOOLEAN;
          Dewiacja  : DevAvrArr;
          Sygnaly   : AvrArr;
        END;
      T_WynikAnalizyOrbita = 
        ARRAY VORO_avrage.PartIdx OF T_WynikAnalizyNaLuku;
      TEvent = (TE_Dane, TE_NowySeg, TE_NowyFrag, TE_Koniec);

    VAR
      odb              : GlownyOdbiornikT;
      odn              : OdnDlaPomBleduT;
      (* czytane wartosci sygnalow *)
      signalsCV        : SignalsCVDsc;
      refCV            : refTab;
      flags            : flgTab;
      smpIdx           : CARDINAL;
      dataLngth        : CARDINAL;
      currIndex        : VORO_avrage.PartIdx;
      Kompletny        : BOOLEAN;
      ostEvent         : TEvent;
      
      (* wyniki analizy *) 

      deltaDev         : INTEGER;
        (* wartosc chwilowa bledu dewiacji *)
      BledyNa10        : O_AvrDscArr;
      lsPrevFlagState  : flgTab;
      flgPrevFlagState : flgTab;
      aktStanLuku      : VORO_avrage.OpisStanuLuku;
      analiza          : T_WynikAnalizyOrbita;
      
      PROCEDURE Ini_T_WynikAnalizyOrbita 
                (VAR analiza: T_WynikAnalizyOrbita);
      VAR
        idx : VORO_avrage.PartIdx;
      BEGIN
        FOR idx := MIN(VORO_avrage.PartIdx) TO MAX(VORO_avrage.PartIdx) DO
          WITH analiza[idx]  DO
            kompletny := FALSE;
            ClearDevAvrArr(Dewiacja, SigNilVal);
            ClearAvrArr(Sygnaly, SigNilVal);
          END;
        END;
      END Ini_T_WynikAnalizyOrbita;
    
      PROCEDURE ClearDevOAvr
                ( VAR BledyNa10 : O_AvrDscArr);
      VAR
        odb : GlownyOdbiornikT;
        odn : OdnDlaPomBleduT;

      BEGIN
        FOR odb := goA TO goB DO
          FOR odn := pbTeodolit TO pbGPS DO
            VORO_avrage.ClearContainer( BledyNa10[odn, odb] );
          END;
        END (* for odb *);
      END ClearDevOAvr;

      PROCEDURE ZerujFlagi;
      
      BEGIN
        Init_flgTab( lsPrevFlagState );
        Init_flgTab( flgPrevFlagState );
      END ZerujFlagi;

      PROCEDURE ClearAllCont;

      BEGIN
        ClearDevOAvr( BledyNa10 );
        ClearDevAvrArr( dvAVcont, NilValC );
        ClearAvrArr( signalsAVcont, NilValC );
        VORO_avrage.InicjujOpisStanuLuku(aktStanLuku);
        ZerujFlagi;
      END ClearAllCont;

    PROCEDURE ReadData
            ( VAR signalsAVcont : SignalsCVDsc;
              VAR refCV         : refTab;
              VAR flags         : flgTab;
              VAR currSmpl      : CARDINAL;
                  dataLngth     : CARDINAL;
              VAR kompletny     : BOOLEAN;
                  (* zwracany true jesli koniec segmentu i segment 
                     zakonczony calkowicie *)
              VAR currIndex     : VORO_avrage.PartIdx;
              VAR aktStanLuku   : VORO_avrage.OpisStanuLuku;
              VAR ostEvent      : TEvent);
     VAR 
       dummDistCV : WORD;
       newSeg     : BOOLEAN;
       
     BEGIN (* ReadData *)
       ostEvent := TE_Dane;
       kompletny := FALSE;
       IF currSmpl >= dataLngth
       THEN
         ostEvent := TE_Koniec;
       ELSE
         ReadAllSignals( signalsAVcont, refCV, flags, newSeg, dummDistCV );
         INC(currSmpl);
         IF newSeg  THEN
           VORO_avrage.InicjujOpisStanuLuku(aktStanLuku);
           ostEvent := TE_NowySeg
         END;
         IF VORO_avrage.SegmentZakonczony(refCV.Together[OdnDlaPomBledu], 
                                          aktStanLuku, 
                                          kompletny, 
                                          currIndex) 
         THEN
           ostEvent := TE_NowyFrag
         END; (* IF VORO_avrage.SegmentZakonczony *)
       END; (* IF currSmpl *)
    END ReadData;
    
    PROCEDURE  PodstawWynikNaLuku;
    BEGIN
      IF Kompletny THEN
        WITH analiza[currIndex] DO
          kompletny := TRUE;
          Dewiacja  := dvAVcont;
          Sygnaly   := signalsAVcont;
        END; (* WITH analiza *)
      END (* IF kompletny *);
      ClearDevAvrArr( dvAVcont,   SigNilVal );
      ClearAvrArr( signalsAVcont, SigNilVal );
    END PodstawWynikNaLuku;
                                
    PROCEDURE AnalizujWynikiNaLuku;
    VAR
      aktLuk   : VORO_avrage.PartIdx;
      brakLuku : BOOLEAN;
      
      PROCEDURE AddAvrDscr
                ( VAR Suma     : AvrDscr;
                      Skladnik : AvrDscr);

      BEGIN
        WITH Suma DO
          INC( num,  Skladnik.num);
          sum := sum + Skladnik.sum;
          WorseBLess( min,    Skladnik.min.val, Skladnik.min.pos );
          WorseBGreater( max, Skladnik.max.val, Skladnik.max.pos );
        END (* with Suma *);
      END AddAvrDscr;
    
      PROCEDURE AddAvrArr 
                ( VAR Suma     : AvrArr;
                      Skladnik : AvrArr );
      VAR
        odb        : GlownyOdbiornikT;
        signalFIdx : Signals;
      BEGIN
        FOR odb := goA TO goB DO
          FOR signalFIdx := Var TO Agc DO
            AddAvrDscr(Suma[signalFIdx, odb], Skladnik[signalFIdx, odb]);
          END (* for signalFIdx *);
        END (* for odb *)
      END AddAvrArr;
    
      PROCEDURE AddDevAvrArr
                ( VAR Suma     : DevAvrArr;
                      Skladnik : DevAvrArr );

      VAR
        odb : GlownyOdbiornikT;
        odn : OdnDlaPomBleduT;
  
      BEGIN
        FOR odb := goA TO goB DO
          FOR odn := MIN(OdnDlaPomBleduT) TO MAX(OdnDlaPomBleduT) DO
            AddAvrDscr(Suma[odn, odb],  Skladnik[odn, odb]);
          END; (* FOR odn *);
        END (* for odb *);
      END AddDevAvrArr;

    BEGIN (* AnalizujWynikiNaLuku *)
      ClearDevAvrArr( dvAVcont,   SigNilVal );
      ClearAvrArr( signalsAVcont, SigNilVal );
      brakLuku := FALSE;
      FOR aktLuk := MIN(VORO_avrage.PartIdx) TO MAX(VORO_avrage.PartIdx) DO
        WITH analiza[aktLuk] DO
          IF kompletny THEN
            AddDevAvrArr  ( dvAVcont, Dewiacja);
            AddAvrArr( signalsAVcont, Sygnaly);
          END; (* IF kompletny *)
          FlagErr_Anal(brakLuku, NOT kompletny, anRes.brakPomNaorbicie, 
                       Angle100(aktLuk*10), ns_no);
          FlagErr_Anal(brakLuku, NOT kompletny, anRes.brakPomNaorbicie, 
                       Angle100((aktLuk+1)*10), ns_no);
        END; (* WITH analiza *)
      END; (* FOR aktLuk *)
    END AnalizujWynikiNaLuku;

    BEGIN (* O_Analiza *)
      dataLngth := OpenSignalFiles( odnDlaOdl );
      StartFileRes( TRUE );
      smpIdx := 0;
      ClearAllCont;
      WITH anRes DO
        Ini_T_WynikAnalizyOrbita(analiza);
        LOOP
          ReadData( signalsCV, refCV, flags, smpIdx, dataLngth, 
                    Kompletny, currIndex, aktStanLuku, ostEvent );
          IF ostEvent = TE_Koniec THEN
            EXIT;
          ELSIF ostEvent = TE_NowySeg THEN
            ZerujFlagi;
            ClearDevOAvr( BledyNa10)
          ELSIF ostEvent = TE_NowyFrag THEN
            PodstawWynikNaLuku;
          END; (* IF ostEven *)
          SigMaxAvr( signalsCV, refCV.Together[OdnDlaPomBledu],
                     signalsAVcont );
          FOR odb := goA TO goB DO
            FOR odn := pbTeodolit TO pbGPS DO
              deltaDev := CountDev( signalsCV[Obr, odb], 
                                    refCV.Together[odn] );
              MinMaxAvr( deltaDev, refCV.Together[odn], dvAVcont[odn, odb] );
              VORO_avrage.AVR10_AddSample( deltaDev, 
                                           refCV.Together[odn], 
                                           BledyNa10[odn, odb], 
                                           DevOrbit[odn, odb] );
              WriteFileRes( odn, odb, deltaDev );
            END (* for odn *);
            IF signalsCV[Agc, odb] <> SigNilVal
            THEN
              FlagErr_Anal( lsPrevFlagState[odb], 
                            signalsCV[Agc, odb] < 5,
                            lowSigTab[odb], 
                            refCV.Together[OdnDlaPomBledu],
                            ns_no );
            END (* if signalsCV *);
            FlagErr_Anal( flgPrevFlagState[odb], 
                          NOT flags[odb],
                          (* Rel.3.0. signalsCV[Obr, odb] = SigNilVal *) 
                          flagTab[odb], 
                          refCV.Together[OdnDlaPomBledu], 
                          ns_no);
          END (* for odb *);
        END (* loop *)
      END (* with anRes *);
      CloseSignalFiles;
      StopFileRes;
      WrSPlus( 'Trwa analiza danych na fragmentach orbit', line, 0 );
      AnalizujWynikiNaLuku;
      CountAv( dvAVcont, signalsAVcont );
    END O_Analiza;

    PROCEDURE Interpolacja
              ( VAR lastAz : LastAz );

    VAR
      sig  : XRefKind;
      dumm : WORD;

    BEGIN
      FOR sig := TEOAxref TO DME_Bxref DO
        IF ( sig >= TEOAxref ) AND ( sig <= HIGH( lastAz ) )
        THEN
          SigInterpolacja( sig, Pomiar, lastAz[sig] );
        ELSE
          SigInterpolacja( sig, Pomiar, dumm );
        END (* if *);
      END (* for sig *);
    END Interpolacja;

  BEGIN (* Analiza *)
    WriteTab( 0, line );
    WrSPlus( 'Trwa interpolacja danych pomiarowych', line, 0 );
    Interpolacja( lastAz );
    CASE procedura OF
      pOkragBlad,
      pOkragZakres :
        WrSPlus( 'Trwa analiza danych z okregu', line, 0 );
        O_Analiza( (* anRes.DevOrbit, lastAz*)); 
      |
      pPromienBlad,
      pPromienZakres :
        WrSPlus( 'Trwa analiza danych z promienia', line, 0 );
        R_Analiza( twoLocations );
    END (* case procedura *);
    WrSPlus( 'Zasadnicza analiza danych zakonczona', line, 0 );
    precision := 100;
    SyntResult := anRes.devDet[AV, OdnDlaPomBledu, GlownyOdbiornik].val;
    SaveAnRes( anRes );
    SaveDistEvents( Pomiar );
  END Analiza;

END V_Count.
