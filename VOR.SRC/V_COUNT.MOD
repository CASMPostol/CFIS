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
|
|  Copyright (C), CAS LODZ POLAND.
|  TEL: 42' 862 547, 42' 87 80 44 FAX/TEL: 42' 84 48 40
|
**********************************************************************)
(*.F+ *)

IMPLEMENTATION MODULE V_Count;

  IMPORT
    BlockOps, VORO_avrage;

  FROM DisResUtilities IMPORT
    WrSPlus;

  FROM EventsMng IMPORT
    GetUpdNextEvent, EventKind, SaveDistEvents;

  FROM V_Files IMPORT
    (* TYPE *) SignalsCVDsc,
    (* PROCEDURE *) OpenSignalFiles, StartFileRes, ReadAllSignals, WriteFileRes
                    , CloseSignalFiles, StopFileRes;

  FROM SYSTEM IMPORT
    ADR, SIZE, WORD;

  FROM V_results IMPORT
    (* TYPE *) AvrOrbitDsc, OrbitDsc, Parametr, Signals,
    (* VAR *) anRes,
    (* PROCEDURE *) Init, SaveAnRes, ClearAnRes;

  FROM Files IMPORT
    XRefKind, SigInterpolacja;

  FROM CommonTypes IMPORT
    (* TYPE *) refTab, GlownyOdbiornikT, OdnDlaPomBleduT, OdnDlaPomOdlT,
               SignalDsc, SigNilVal, NumStrefy, DisNilVal,
    (* CONST *) NilValI, NilValC;

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
    SubAngle100;

  FROM FlagAnal IMPORT
    FlagErr_Anal;

  FROM WorseBecause IMPORT
    WorseBLess, WorseBGreater;

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
    AvrDscr      =
      RECORD
        sum : REAL;
        num : CARDINAL;
        min : SignalDsc;
        max : SignalDsc;
      END;
    AvrArr       =
      ARRAY [ Var .. Agc ], GlownyOdbiornikT OF AvrDscr;
    DevAvrArr    =
      ARRAY OdnDlaPomBleduT, GlownyOdbiornikT OF AvrDscr;
    LastAz       =
      ARRAY [ TEOAxref .. GPSAxref ] OF INTEGER;

  VAR
    dvAVcont      : DevAvrArr;
    signalsAVcont : AvrArr;
    bendsCon      : bendsArr;
    roughnessCon  : roughnessArr;

  TYPE
    TyppomiaruT =
      ( pNORM,
        pOFF,
        pLEFT,
        pZERO,
        pRIGHT );

  VAR
    SumPol : ARRAY OdnDlaPomBleduT, GlownyOdbiornikT, [ pLEFT .. pRIGHT ] OF
  REAL;
        (* 2 odniesienia 2 kanaly 3 fazy *)
    PolOk  : ARRAY OdnDlaPomBleduT, GlownyOdbiornikT OF BOOLEAN;


  PROCEDURE Analiza
            (     procedura       : ProceduraT;
                  odnDlaOdl       : OdnDlaPomOdlT;
                  OdnDlaPomBledu  : OdnDlaPomBleduT;
                  GlownyOdbiornik : GlownyOdbiornikT;
                  twoLocations    : BOOLEAN;
              VAR SyntResult      : INTEGER;
              VAR precision       : INTEGER);

  VAR
    line   : CARDINAL;
    lastAz : LastAz;


    PROCEDURE CountDev
              (    signal : INTEGER;
                   ref    : INTEGER ): INTEGER;
    BEGIN
      RETURN SubAngle100( ref, signal );
    END CountDev;


    PROCEDURE MinMaxAvr
              (     dv       : INTEGER;
                    pos      : WORD;
                VAR dvAVcont : AvrDscr );

    BEGIN
      IF dv <> NilValI
      THEN
        WITH dvAVcont DO
          INC( num );
          sum := sum + real( dv );
          WorseBLess( min, dv, pos );
          WorseBGreater( max, dv, pos );
        END (* with dvAVcont *);
      END (* if dv *);
    END MinMaxAvr;


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


    PROCEDURE ClearAVcont
              ( VAR AVcont  : AvrDscr;
                    posNilV : WORD    );

    BEGIN
      WITH AVcont DO
        num := 0;
        sum := 0.0;
        WITH min DO
          val := NilValI;
          pos := posNilV;
        END (* with min *);
        WITH max DO
          val := NilValI;
          pos := posNilV;
        END (* with min *);
      END (* with AVcont *);
    END ClearAVcont;


    PROCEDURE ClearAvrArr
              ( VAR AVcont  : AvrArr;
                    posNilV : WORD   );

    VAR
      odb  : GlownyOdbiornikT;
      sign : Signals;

    BEGIN
      FOR sign := Var TO Agc DO
        FOR odb := goA TO goB DO
          ClearAVcont( AVcont[sign, odb], posNilV );
        END (* for odb *);
      END (* for sign *);
    END ClearAvrArr;


    PROCEDURE ClearDevAvrArr
              ( VAR AVcont  : DevAvrArr;
                    odn     : OdnDlaPomBleduT;
                    posNilV : WORD      );

    VAR
      odb : GlownyOdbiornikT;

    BEGIN
      FOR odb := goA TO goB DO
        ClearAVcont( AVcont[odn, odb], posNilV );
      END (* for odb *);
    END ClearDevAvrArr;


    PROCEDURE GetEvent
              (     currSmpl  : CARDINAL;
                VAR evidx     : CARDINAL;
                    position  : WORD;
                    dataLngth : CARDINAL ) : myEvent;

    BEGIN
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
          IF currSmpl + 1 > dataLngth
          THEN
            RETURN KoniecDanychME;
          END (* if position *);
          RETURN DaneME;
      ELSE
        RETURN NicME;
      END (* case GetUpdNextEvent *);
    END GetEvent;


    PROCEDURE R_Analiza
              (    twoLocations : BOOLEAN );

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
      lsPrevFlagState  : ARRAY GlownyOdbiornikT OF BOOLEAN;
      flgPrevFlagState : ARRAY GlownyOdbiornikT OF BOOLEAN;
      startRef         : OdnDlaPomBleduT;


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
        FOR odn := pbTeodolit TO pbGPS DO
          ClearDevAvrArr( dvAVcont, odn, NilValI );
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
      ReadAllSignals( signalsCV, refCV, RefDisCV );
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
                  FlagErr_Anal( lsPrevFlagState[odb], signalsCV[Agc, odb] < 5,
                                lowSigTab[odb], RefDisCV, DisNilVal, ns_no );
                END (* if signalsCV *);
                FlagErr_Anal( flgPrevFlagState[odb], signalsCV[Obr, odb] =
                              SigNilVal, flagTab[odb], RefDisCV, DisNilVal,
                              ns_no );
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
              ReadAllSignals( signalsCV, refCV, RefDisCV );
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


    PROCEDURE O_Analiza
              ( VAR avTable : AvrOrbitDsc; 
                    lastAz  : LastAz );

    TYPE
      O_AvrDscArr =
        ARRAY OdnDlaPomBleduT, GlownyOdbiornikT OF VORO_avrage.AVRdescription;

    VAR
      dataLngth        : CARDINAL;
      odb              : GlownyOdbiornikT;
      evidx            : CARDINAL;
      smpIdx           : CARDINAL;
      dummDistCV       : CARDINAL;
      odn              : OdnDlaPomBleduT;
      dv               : INTEGER;
      signalsCV        : SignalsCVDsc;
      refCV            : refTab;
      dvAVcont         : DevAvrArr;
      signalsAVcont    : AvrArr;
      CONT             : O_AvrDscArr;
      radialIdx        : VORO_avrage.PartIdx;
      lsPrevFlagState  : ARRAY GlownyOdbiornikT OF BOOLEAN;
      flgPrevFlagState : ARRAY GlownyOdbiornikT OF BOOLEAN;


      PROCEDURE ClearDevOAvr
                ( VAR CONT : O_AvrDscArr;
                      odn  : OdnDlaPomBleduT );

      BEGIN
        FOR odb := goA TO goB DO
          VORO_avrage.ClearContainer( CONT[odn, odb] );
        END (* for odb *);
      END ClearDevOAvr;


      PROCEDURE ClearAllCont
                ( odn : OdnDlaPomBleduT );

      VAR
        odb : GlownyOdbiornikT;

      BEGIN
        ClearDevAvrArr( dvAVcont, odn, NilValC );
        ClearDevOAvr( CONT, odn );
        IF anRes.odnDlaPomBledu = odn THEN
          ClearAnRes;
          ClearAvrArr( signalsAVcont, NilValC );
          FOR odb := goA TO goB DO
            lsPrevFlagState[odb] := FALSE;
            flgPrevFlagState[odb] := FALSE;
            FOR radialIdx := 1 TO 35 DO
              avTable[odn, odb, radialIdx] := NilValI;
            END (* for radialIdx *);
          END (* for odb *);
        END;
      END ClearAllCont;


      PROCEDURE O_AvrCountErr
                ( VAR err  : OrbitDsc;
                      CONT : VORO_avrage.AVRdescription );

      BEGIN
        WITH CONT DO
          err[index] := entier( errDevSun / FLOAT( samples ) * 100.0 );
        END (* with CONT *);
      END O_AvrCountErr;

    TYPE
      RefState =
        ( Empty,
          OnLeft,
          OnRight );

    VAR
      refCont: ARRAY [ TEOAxref .. GPSAxref ] OF RefState;


      PROCEDURE BeginOfOrbit
                (     reference : INTEGER;
                      idx       : INTEGER;
                  VAR continer  : RefState ) : BOOLEAN;
      TYPE
        Where    =
          ( left,
            right,
            far );

      VAR
        normRfc : INTEGER;


        PROCEDURE Side
                  (    normVal  : INTEGER;
                       prevSide : Where   ) : Where;

        BEGIN
          IF ABS(normVal) > 100 THEN
            RETURN far
          ELSIF normVal < 0
          THEN
            RETURN left
          ELSIF normVal > 0
          THEN
            RETURN right
          ELSE
            RETURN prevSide
          END (* if ABS *);
        END Side;

      BEGIN
        IF reference = SigNilVal
        THEN
          RETURN FALSE;
        END (* if reference *);
        normRfc := SubAngle100( reference, idx );
        CASE continer OF
          Empty :
            CASE Side( normRfc, left ) OF
              left :
                continer := OnLeft; |
              right :
                continer := OnRight;
            ELSE
              ;
            END (* case Side *) |
          OnLeft :
            CASE Side( normRfc, left ) OF
              right :
                continer := OnRight;
                RETURN TRUE; |
              left :
                ;|
              far :
                continer := Empty;
            END (* case Side *); |
          OnRight :
            CASE Side( normRfc, right ) OF
              left :
                continer := OnLeft;
                RETURN TRUE; |
              right :
                ;|
              far :
                continer := Empty;
            END (* case Side *);
        END (* case state *);
        RETURN FALSE;
      END BeginOfOrbit;

    BEGIN (* O_Analiza *)
      refCont[TEOAxref] := Empty;
      refCont[GPSAxref] := Empty;
      ClearAllCont( pbTeodolit );
      ClearAllCont( pbGPS );
      dataLngth := OpenSignalFiles( odnDlaOdl );
      evidx := 0;
      smpIdx := 0;
      ReadAllSignals( signalsCV, refCV, dummDistCV );
      StartFileRes( TRUE );
      WITH anRes DO
        LOOP
          CASE GetEvent( smpIdx, evidx, refCV.Together[OdnDlaPomBledu],
                         dataLngth ) OF
            StartPomiaruME :
              ; |
            StopPomiaruME :
              ClearDevOAvr( CONT,  pbTeodolit); 
              ClearDevOAvr( CONT,  pbGPS); |
            KoniecDanychME :
              EXIT; |
            DaneME :
              SigMaxAvr( signalsCV, refCV.Together[pbGPS], signalsAVcont );
              FOR odb := goA TO goB DO
                FOR odn := pbTeodolit TO pbGPS DO
                  dv := CountDev( signalsCV[Obr, odb], refCV.Together[odn] );
                  MinMaxAvr( dv, refCV.Together[odn], dvAVcont[odn, odb] );
                  IF VORO_avrage.AddSample( signalsCV[Obr, odb], refCV.Together
                                            [odn], CONT[odn, odb] )
                  THEN
                    O_AvrCountErr( avTable[odn, odb], CONT[odn, odb] )
                  END (* if VORO_avrage.AddSample *);
                  WriteFileRes( odn, odb, dv );
                END (* for odn *);
                IF signalsCV[Agc, odb] <> SigNilVal
                THEN
                  FlagErr_Anal( lsPrevFlagState[odb], signalsCV[Agc, odb] < 5,
                                lowSigTab[odb], refCV.Together[OdnDlaPomBledu],
                                SigNilVal, ns_no );
                END (* if signalsCV *);
                FlagErr_Anal( flgPrevFlagState[odb], signalsCV[Obr, odb] =
                              SigNilVal, flagTab[odb], refCV.Together[
                              OdnDlaPomBledu], SigNilVal, ns_no );
              END (* for odb *);
              ReadAllSignals( signalsCV, refCV, dummDistCV );
              INC( smpIdx );
              IF BeginOfOrbit(refCV.Together[pbTeodolit], lastAz[ TEOAxref ], 
                              refCont[TEOAxref] )
              THEN
                ClearAllCont(pbTeodolit);
              END;
              IF BeginOfOrbit(refCV.Together[pbGPS], lastAz[ GPSAxref ], 
                              refCont[ GPSAxref ] )
              THEN
                ClearAllCont(pbGPS);
              END; |
            NicME :
              ;
          END (* case GetEvent *)
        END (* loop *)
      END (* with anRes *);
      CloseSignalFiles;
      StopFileRes;
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
        O_Analiza( anRes.DevOrbit, lastAz); |
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
