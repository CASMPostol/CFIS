(*.F- *)
(**********************************************************************
|  Title   : Evaluation procedures for ILS nad GS
|  Author  : M.Postol
|  System  : LOGITECH MODULA-2/86
|  History :
|    16-10-96: created
|    30-10-96: M.Postol
|      w CountDif0R uwzgledniono znak dewiacji 
|    06-10-96: M.Postol
|      CheckMkrState uproszczono
|    26-01-96: M.Postol
|      zmieniono baze odniesienia dla pomiaru katow na 0 absolutne
|      dotyczy procedury CountAzymR
|    30-01-96: M.Postol
|      CountAzym inne zabezpieczenie
|    05-02-96:
|      AzymAV_Addsmpl - zmiana kolejnosci okreslania poprawnosci sygnalow
|      CountAzym - dodatkowe zabezpieczenie na dev
|      CountDif = dodatkowe zabezpieczenie na displacement
|    23-03-97: M.Postol
|      wywalilem Alig_Continer_T i procedure InSegment do L_CntProcedures
|      poniewaz w gs jest inn i w loc jest inna.
|    Rel 3.10
|      wywala sie przy liczeniu kata. Wprowadzilem entier z
|      zabezpieczeniem.
|    Rel. 3.14: MPostol
|      - W Clearence_ConT dodatkowe pole, by mozna bylo wskazac, ze
|        pomiar byl robiony.
|     - Zmiana sposobu obliczania wyrazistosci.
|
|  Copyright (C), CAS LODZ POLAND.
|  TEL: 42' 862 547, 42' 87 80 44 FAX/TEL: 42' 84 48 40
|
**********************************************************************)
(*.F+ *)

IMPLEMENTATION MODULE ILS_EvalProcedures;

  FROM SYSTEM IMPORT
    ADR;

  FROM MathLib0 IMPORT
    real;

  FROM CommonTypes IMPORT
    SigNilVal, DisNilVal, NilValC, Dist01NM, OdnDlaPomBleduT, GlownyOdbiornikT,
    signTabBin, ZoneBoundPt, zoneBIdx_T;

  FROM L_CommonTypes IMPORT
    NumStrefy, Boundary_T, GetZoneBoundPt, MkrLengthT, Clear150;

  FROM SpecConv IMPORT
    GorszeBoWieksze, entierCheck, entier;

  TYPE
    pos =
      ( OutL,
        OutR,
        Inside );

  VAR
    pathAng : INTEGER;
    znakKata: INTEGER; 
    
  PROCEDURE CountAzym0R
            (    Alfa        : INTEGER;
                 dev         : REAL;
                 coefficient : REAL    ) : REAL;

  BEGIN
    RETURN real(Alfa) - real(znakKata) * dev * coefficient;
  END CountAzym0R;

  PROCEDURE CountAzymR
            (    Alfa : INTEGER;
                 dev  : REAL;
                 devS : REAL;
                 os   : REAL    ) : REAL;

  BEGIN
    RETURN (real(Alfa-pathAng)*devS-(devS-dev)*os)/dev+FLOAT(pathAng);
  END CountAzymR;

  PROCEDURE CountDif
            (    Alfa      : INTEGER;
                 dev       : INTEGER;
                 displSens : REAL;
                 pathAng   : REAL    ) : INTEGER;
  VAR
    displace : INTEGER;

  BEGIN
    IF (dev = SigNilVal) OR (Alfa = SigNilVal) OR (ABS(Alfa) > 1500)
    THEN
      RETURN SigNilVal
    ELSIF entierCheck((real(Alfa) - pathAng) * displSens + 0.5, displace)
    THEN
      IF ABS(displace) < 1000 THEN
        RETURN +dev - znakKata * displace;
      ELSE
        RETURN SigNilVal
      END;
    ELSE
      RETURN SigNilVal
    END (* if *);
  END CountDif;

  PROCEDURE AV_Addsmpl
            ( VAR cont  : Avr_ConT;
                  val   : INTEGER;
                  clear : BOOLEAN  ) : INTEGER;

  BEGIN
    WITH cont DO
      IF clear
      THEN
        sum := 0.0;
        num := 0;
      END (* if clear *);
      IF val = SigNilVal
      THEN
        IF num > 0
        THEN
          RETURN entier(sum / FLOAT(num) + 0.5);
        ELSE
          RETURN SigNilVal
        END (* if num *);
      END (* if val *);
      INC(num);
      sum := sum + real(val);
      RETURN entier(sum / FLOAT(num) + 0.5)
    END (* with cont *);
  END AV_Addsmpl;

  PROCEDURE AV_Clear
            ( VAR cont : Avr_ConT );

  BEGIN
    WITH cont DO
      sum := 0.0;
      num := 0;
    END (* with cont *);
  END AV_Clear;

  PROCEDURE Az0Av_Addsmpl
            ( VAR cont  : Az0Av_ConT;
                  Dev   : INTEGER;
                  Alfa  : INTEGER;
                  clear : BOOLEAN    ) : INTEGER;

  BEGIN
    WITH cont DO
      IF clear
      THEN
        sum := 0.0;
        num := 0;
      END (* if clear *);
      IF (Dev = SigNilVal) OR (Alfa = SigNilVal)
      THEN
        IF num > 0
        THEN
          RETURN entier(sum / FLOAT(num) + 0.5);
        ELSE
          RETURN SigNilVal;
        END (* if num *);
      END (* if *);
      INC(num);
      sum := sum + CountAzym0R(Alfa, real(Dev), coefficient);
      RETURN entier(sum / FLOAT(num) + 0.5)
    END (* with cont *);
  END Az0Av_Addsmpl;

  PROCEDURE Az0Av_Clear
            ( VAR cont      : Az0Av_ConT;
                  displSens : REAL       );

  BEGIN
    WITH cont DO
      sum := 0.0;
      num := 0;
      coefficient := 1.0 / displSens;
    END (* with cont *);
  END Az0Av_Clear;

  PROCEDURE CountDelAzym
            (    Alfa    : INTEGER;
                 dev     : INTEGER;
                 devS    : REAL;
                 os      : REAL;
                 secWith : REAL    ) : INTEGER;
  VAR
    az : REAL;

  BEGIN
    IF (dev = SigNilVal) OR (ABS(dev) < 100) OR (Alfa = SigNilVal)
    THEN
      RETURN SigNilVal;
    END (* if *);
    az := CountAzymR(Alfa, real(dev), devS, os);
    RETURN entier(az-FLOAT(pathAng)-real(znakKata) * secWith * devS / 3000.0)
  END CountDelAzym;

  PROCEDURE Check
            (    dev     : REAL;
                 devSmin : REAL;
                 devSmax : REAL ) : pos;

  BEGIN
    IF dev < devSmin
    THEN
      RETURN OutL;
    ELSIF dev > devSmax
    THEN
      RETURN OutR;
    ELSE
      RETURN Inside;
    END (* if dev *);
  END Check;

  PROCEDURE Azym_Addsmpl
            ( VAR cont : Azym_ConT;
                  Alfa : INTEGER;
                  dev  : INTEGER;
              VAR ang  : INTEGER   );
  VAR
    devR    : REAL;
    currPos : pos;

  BEGIN
    IF (ABS(dev) < 100) OR (Alfa = SigNilVal) OR (dev = SigNilVal)
    THEN
      RETURN
    END (* if *);
    devR := real(dev);
    WITH cont DO
      currPos := Check(devR, devSmin, devSmax);
      CASE state OF
        OusideL_AZ :
          IF currPos = Inside
          THEN
            state := InsideFromL_AZ;
            sum := sum + CountAzymR(Alfa, devR, offset, os);
            INC(num);
          ELSIF currPos = OutR
          THEN
            state := OusideR_AZ
          END (* if currPos *);
        |
        OusideR_AZ :
          IF currPos = Inside
          THEN
            state := InsideFromR_AZ;
            sum := sum + CountAzymR(Alfa, devR, offset, os);
            INC(num);
          ELSIF currPos = OutL
          THEN
            state := OusideL_AZ
          END (* if currPos *);
        |
        InsideFromL_AZ :
          IF currPos = Inside
          THEN
            sum := sum + CountAzymR(Alfa, devR, offset, os);
            INC(num);
          ELSIF currPos = OutR
          THEN
            ang := entier(sum / FLOAT(num) + 0.5);
            sum := 0.0;
            num := 0;
            state := OusideR_AZ;
          ELSIF currPos = OutL
          THEN
            sum := 0.0;
            num := 0;
            state := OusideL_AZ;
          END (* if currPos *);
        |
        InsideFromR_AZ :
          IF currPos = Inside
          THEN
            sum := sum + CountAzymR(Alfa, devR, offset, os);
            INC(num);
          ELSIF currPos = OutL
          THEN
            ang := entier(sum / FLOAT(num) + 0.5);
            sum := 0.0;
            num := 0;
            state := OusideL_AZ;
          ELSIF currPos = OutR
          THEN
            sum := 0.0;
            num := 0;
            state := OusideR_AZ;
          END (* if currPos *);
      END (* case state *);
    END (* with cont *);
  END Azym_Addsmpl;

  PROCEDURE Azym_Clear
            ( VAR cont     : Azym_ConT;
                  devS     : INTEGER;
                  ustawOsi : INTEGER   );

  BEGIN
    WITH cont DO
      sum := 0.0;
      num := 0;
      devSmin := real(devS) - 150.0;
      devSmax := real(devS) + 150.0;
      offset := real(devS);
      os := real(ustawOsi);
      state := MIN(Azym_StateT);
    END (* with cont *);
  END Azym_Clear;

  PROCEDURE CountDif0R
            (    Alfa        : INTEGER;
                 dev         : REAL;
                 coefficient : REAL    ) : REAL;

  BEGIN
    RETURN -dev * real(znakKata) + real(Alfa-pathAng) * coefficient;
  END CountDif0R;

  PROCEDURE AzDif0_Addsmpl
            ( VAR cont : AzDif0_ConT;
                  Alfa : INTEGER;
                  dev  : INTEGER;
              VAR ang  : INTEGER     );

  CONST
    devSmin = -150.0;
    devSmax = 150.0;
  VAR
    devR    : REAL;
    currPos : pos;

  BEGIN
    IF (ABS(dev) > 500) OR (Alfa = SigNilVal) OR (dev = SigNilVal)
    THEN
      RETURN
    END (* if *);
    devR := real(dev);
    WITH cont DO
      currPos := Check(devR, devSmin, devSmax);
      CASE state OF
        OusideL_AZ :
          IF currPos = Inside
          THEN
            state := InsideFromL_AZ;
            sum := sum + count(Alfa, devR, coefficient);
            INC(num);
          ELSIF currPos = OutR
          THEN
            state := OusideR_AZ
          END (* if currPos *);
        |
        OusideR_AZ :
          IF currPos = Inside
          THEN
            state := InsideFromR_AZ;
            sum := sum + count(Alfa, devR, coefficient);
            INC(num);
          ELSIF currPos = OutL
          THEN
            state := OusideL_AZ
          END (* if currPos *);
        |
        InsideFromL_AZ :
          IF currPos = Inside
          THEN
            sum := sum + count(Alfa, devR, coefficient);
            INC(num);
          ELSIF currPos = OutR
          THEN
            ang := entier(sum / FLOAT(num) + 0.5);
            sum := 0.0;
            num := 0;
            state := OusideR_AZ;
          ELSIF currPos = OutL
          THEN
            sum := 0.0;
            num := 0;
            state := OusideL_AZ;
          END (* if currPos *);
        |
        InsideFromR_AZ :
          IF currPos = Inside
          THEN
            sum := sum + count(Alfa, devR, coefficient);
            INC(num);
          ELSIF currPos = OutL
          THEN
            ang := entier(sum / FLOAT(num) + 0.5);
            sum := 0.0;
            num := 0;
            state := OusideL_AZ;
          ELSIF currPos = OutR
          THEN
            sum := 0.0;
            num := 0;
            state := OusideR_AZ;
          END (* if currPos *);
      END (* case state *);
    END (* with cont *);
  END AzDif0_Addsmpl;

  PROCEDURE Dif0_Clear
            ( VAR cont      : AzDif0_ConT;
                  displSens : REAL        );

  BEGIN
    WITH cont DO
      sum := 0.0;
      num := 0;
      coefficient := displSens;
      state := MIN(Azym_StateT);
      count := CountDif0R;
    END (* with cont *);
  END Dif0_Clear;

  PROCEDURE Az0_Clear
            ( VAR cont      : AzDif0_ConT;
                  displSens : REAL        );

  BEGIN
    WITH cont DO
      sum := 0.0;
      num := 0;
      coefficient := 1.0 / displSens;
      state := MIN(Azym_StateT);
      count := CountAzym0R;
    END (* with cont *);
  END Az0_Clear;

  PROCEDURE Clearence_Addsmpl
            ( VAR cont : Clearence_ConT;
                  Alfa : INTEGER;
                  dev  : INTEGER        );

  TYPE
    Event_T =
      ( Outside_EV,
        After150_EV,
        After175_EV );

    PROCEDURE Check
              (    dev  : INTEGER;
                   Znak :  INTEGER ) : Event_T;

    BEGIN
      IF (Znak * dev < 0) OR (ABS(dev) < 1500)
      THEN
        RETURN Outside_EV;
      ELSIF ABS(dev) < 1750
      THEN
        RETURN After150_EV;
      ELSE
        RETURN After175_EV;
      END (* if dev *);
    END Check;
  VAR
    event : Event_T;

  BEGIN (* Clearence_Addsmpl *)
    WITH cont DO
      IF (Alfa = SigNilVal) OR (dev = SigNilVal) OR (Znak * Alfa < 0)
      THEN
        RETURN
      END (* if *);
      bylPom := bylPom OR ( ABS(Alfa) >= Clear150 );
      event := Check(dev, Znak);
      CASE State OF
        Outside_CL :
          CASE event OF
            Outside_EV :
            |
            After175_EV, After150_EV :
              IF (h175Mn = SigNilVal) OR (ABS(Alfa) < ABS(h175Mn))
              THEN
                h150Mn := Alfa;
                h175Mx := SigNilVal;
                h175Mn := SigNilVal;
                State  := After150_CL;
              END (* if *);
          END (* case event *);
        |
        After150_CL :
          CASE event OF
            Outside_EV :
              State  := Outside_CL;
            |
            After150_EV :
              IF ABS(Alfa) > ABS(h150Mn)
              THEN
                h150Mn := Alfa;
              END;
            |
            After175_EV :
              IF ABS(Alfa) > ABS(h150Mn)
              THEN
                h150Mn := Alfa;
              END;
              IF (h175Mn = SigNilVal) OR (ABS(Alfa) < ABS(h175Mn))
              THEN
                h175Mx := Alfa;
                h175Mn := Alfa;
                State  := Inside_CL;
              END;
          END (* case event *);
        |
        Inside_CL :
          CASE event OF
            Outside_EV :
              State := Outside_CL;
            |
            After150_EV :
              IF ABS(Alfa) > ABS(h150Mn)
              THEN
                h150Mn := Alfa;
              END;
              State := After150_CL;
            | 
            After175_EV :
              IF ABS(Alfa) > ABS(h150Mn)
              THEN
                h150Mn := Alfa;
              END;
              IF    ABS(Alfa) > ABS(h175Mx) THEN
                h175Mx := Alfa;
              ELSIF ABS(Alfa) < ABS(h175Mn) THEN
                h175Mn := Alfa;
              END (* IF *);
          END (* case event *);
      END (* case State *);
    END (* with cont *);
  END Clearence_Addsmpl;

  PROCEDURE Clearence_Clear
            ( VAR cont : Clearence_ConT;
                  znak : INTEGER        );

  BEGIN
    WITH cont DO
      State  := Outside_CL;
      Znak   := znak;
      h175Mn := SigNilVal;
      h175Mx := SigNilVal;
      h150Mn := SigNilVal;
      bylPom := FALSE;
    END (* with cont *);
  END Clearence_Clear;

  PROCEDURE AzymAV_Addsmpl
            ( VAR cont  : AzymAV_ConT;
                  Alfa  : INTEGER;
                  dev   : INTEGER;
              VAR ang   : INTEGER;
                  clear : BOOLEAN     );

  BEGIN
    WITH cont DO
      IF clear
      THEN
        sum := 0.0;
        num := 0;
      END (* if clear *);
      IF (dev = SigNilVal) OR (ABS(dev) < 100) OR (Alfa = SigNilVal)
      THEN
        RETURN
      END (* if *);
      sum := sum + CountAzymR(Alfa, real(dev), offset, os);
      INC(num);
      ang := entier(sum / FLOAT(num) + 0.5);
    END (* with cont *);
  END AzymAV_Addsmpl;

  PROCEDURE AzymAV_Clear
            ( VAR cont     : AzymAV_ConT;
                  devS     : INTEGER;
                  ustawOsi : INTEGER     );

  BEGIN
    WITH cont DO
      sum := 0.0;
      num := 0;
      offset := real(devS);
      os := real(ustawOsi);
    END (* with cont *);
  END AzymAV_Clear;

  PROCEDURE CountAzym
            (    Alfa : INTEGER;
                 dev  : INTEGER;
                 devS : REAL;
                 os   : REAL    ) : INTEGER;
  VAR
    ret : INTEGER;
  BEGIN
    IF (dev = SigNilVal) OR (Alfa = SigNilVal) OR (ABS(dev) < 100)
    THEN
      RETURN SigNilVal;
    ELSIF entierCheck(CountAzymR(Alfa, real(dev), devS, os) + 0.5, ret)  THEN
      RETURN ret
    ELSE
      RETURN SigNilVal
    END (* if *);
  END CountAzym;

  PROCEDURE CountAzymOsi
            (    Alfa      : INTEGER;
                 dev       : INTEGER;
                 displSens : REAL    ) : INTEGER;

  VAR
    ret : INTEGER;
  BEGIN
    IF (Alfa = SigNilVal) OR (dev = SigNilVal)
    THEN
      RETURN SigNilVal;
    ELSIF entierCheck(CountAzym0R(Alfa, real(dev), 1.0 / displSens), ret) THEN
       RETURN ret;
    ELSE
      RETURN SigNilVal;
    END (* if *);
  END CountAzymOsi;

  PROCEDURE MkrLnth_AddSmpl
            ( VAR cont : MkrLnth_ConT;
                  flg  : BOOLEAN;
                  dis  : CARDINAL     ) : INTEGER;

  BEGIN
    IF dis = DisNilVal
    THEN
      RETURN SigNilVal;
    END (* if *);
    WITH cont DO
      CASE state OF
        Ouside_Mkr :
          IF flg
          THEN
            numOfMkrs := 5;
            state := Inside_Mkr;
            beg := dis;
          END (* if flg *);
        |
        Inside_Mkr :
          IF flg
          THEN
            numOfMkrs := 5;
            end := dis;
          ELSIF numOfMkrs <> 0
          THEN
            DEC(numOfMkrs);
          ELSE
            state := Ouside_Mkr;
            IF (end = DisNilVal) OR (beg = DisNilVal) THEN
              RETURN SigNilVal 
            ELSIF end > beg
            THEN
              RETURN end - beg
            ELSE
              RETURN beg - end
            END (* if dis *);
          END (* if *);
      END (* case state *);
    END (* with cont *);
    RETURN SigNilVal;
  END MkrLnth_AddSmpl;

  PROCEDURE MkrLnth_Clear
            ( VAR cont : MkrLnth_ConT );

  BEGIN
    WITH cont DO
      state := Ouside_Mkr;
      numOfMkrs := 0;
      beg := DisNilVal;
      end := DisNilVal;
    END (* with cont *);
  END MkrLnth_Clear;

  PROCEDURE MkrALengthConClear
            ( VAR con : MkrALengthCon_T );
  VAR
    mkr : MkrId_T;

  BEGIN
    WITH con DO
      FOR mkr := MIN(MkrId_T) TO MAX(MkrId_T) DO
        MkrLnth_Clear(mkrL_Con[mkr]);
      END (* for mkr *);
      lastKnown_Mkr := NoOnePrsnt_Mkr;
      localMkrA_OM.val := SigNilVal;
      multpx := ADR(localMkrA_OM);
      MkrLnth_Clear(mkrA_Con);
    END (* with con *);
  END MkrALengthConClear;

  PROCEDURE MkrLength_Count
            (     oMkrFlg      : signTabBin;
                  mMkrFlg      : signTabBin;
                  iMkrFlg      : signTabBin;
                  rec          : GlownyOdbiornikT;
                  refDisCV     : CARDINAL;
                  agcMCV       : INTEGER;
              VAR mkrLengthCon : MkrALengthCon_T;
              VAR MkrDsc       : MkrLengthT       );

  VAR
    curr_Mkr : CheckMkrFlgs_T;
    
    PROCEDURE CheckMkrState
              (    val : INTEGER ) : BOOLEAN;

    BEGIN
      IF val = SigNilVal
      THEN
        RETURN FALSE;
      ELSIF val >= 1700
      THEN
        RETURN TRUE;
      ELSE
        RETURN FALSE;
      END (* if val *);
    END CheckMkrState;

    PROCEDURE CheckMkrFlgs
              (    rec : GlownyOdbiornikT ) : CheckMkrFlgs_T;

    BEGIN
      IF oMkrFlg[rec]
      THEN
        RETURN OMkrPrsnt_Mkr;
      ELSIF mMkrFlg[rec]
      THEN
        RETURN MMkrPrsnt_Mkr;
      ELSIF iMkrFlg[rec]
      THEN
        RETURN IMkrPrsnt_Mkr;
      END (* if oMkrFlg *);
      RETURN NoOnePrsnt_Mkr;
    END CheckMkrFlgs;

  BEGIN (* MkrLength_Count *)
    (*.F- *)
    WITH MkrDsc  DO
      WITH mkrLengthCon DO
        GorszeBoWieksze( oMkrL_OM[rec].val,
                         MkrLnth_AddSmpl( mkrL_Con[OMkr],
                                          oMkrFlg[rec],
                                          refDisCV
                                         )
                        );
        GorszeBoWieksze( mMkrL_OM[rec].val,
                         MkrLnth_AddSmpl( mkrL_Con[MMkr],
                                          mMkrFlg[rec],
                                          refDisCV
                                         )
                        );
        GorszeBoWieksze( iMkrL_OM[rec].val,
                         MkrLnth_AddSmpl( mkrL_Con[IMkr],
                                          iMkrFlg[rec],
                                          refDisCV
                                         )
                        );
        GorszeBoWieksze( multpx^.val,
                         MkrLnth_AddSmpl( mkrA_Con,
                                          CheckMkrState(agcMCV),
                                          refDisCV
                                         )
                        );
        curr_Mkr := CheckMkrFlgs(rec);
        IF curr_Mkr <> lastKnown_Mkr THEN
          lastKnown_Mkr := curr_Mkr;
          CASE  curr_Mkr OF
            OMkrPrsnt_Mkr:
              multpx := ADR(oMkrA_OM[rec]);
            |
            MMkrPrsnt_Mkr:
              multpx := ADR(mMkrA_OM[rec]);
            |
            IMkrPrsnt_Mkr:
              multpx := ADR(iMkrA_OM[rec]);
            |
            NoOnePrsnt_Mkr:
            ;
          END;
        END;
      END;
    END;
    (*.F+ *)
  END MkrLength_Count;

  PROCEDURE Bend_ClearContainer
            ( VAR Container : Bend_Descriptor;
                  ZoneBIdx  : zoneBIdx_T;
                  Boundary  : Boundary_T;
                  KapaBuff  : KapaBuff_T      );

  BEGIN
    WITH Container DO
      zone := ns_no;
      zoneBIdx := ZoneBIdx;
      boundary := Boundary;
      kapaBuff := KapaBuff;
      begIdx := 0;
      begDist := DisNilVal;
      num := 0;
      errorSum := 0;
      endIdx := 0;
    END (* with container *);
  END Bend_ClearContainer;

  PROCEDURE Bend_AddSample
            (     dif       : INTEGER;
                  Idx       : CARDINAL;
                  dist      : CARDINAL;
                  currZone  : NumStrefy;
                  ref       : OdnDlaPomBleduT;
                  rec       : GlownyOdbiornikT;
              VAR boundP    : INTEGER;
              VAR boundM    : INTEGER;
              VAR centre    : INTEGER;
              VAR bends     : INTEGER; (* x100 *)
              VAR container : Bend_Descriptor  ) : BOOLEAN;

  CONST
    Dist1_17NM = 585;  (* 1.17*500.0 *)
  VAR
    result : BOOLEAN;
    begPT  : ZoneBoundPt;
    endPt  : ZoneBoundPt;

    PROCEDURE Count();
    VAR
      endCond : BOOLEAN;

    BEGIN (* Count *)
      WITH container DO
        REPEAT
          WITH buff[begIdx] DO
            IF NOT valInside
            THEN
              DEC(errorSum);;
            END (* if valInside *);
            DEC(num);
          END (* with buff *);
          begIdx := (begIdx + 1) MOD Bend_MaxNumOfPoints;
          WITH buff[begIdx] DO
            endCond := (begDist > valueDist) AND ((begDist - valueDist) >=
                       Dist01NM) OR (begDist < valueDist) AND (
                       (valueDist - begDist) >= Dist01NM)
          END (* with buff *);
        UNTIL endCond;
        begDist := buff[begIdx].valueDist;
      END (* with container *);
    END Count;

    PROCEDURE OutSide
              (     dif          : INTEGER;
                    Idx          : CARDINAL;
                    Kz           : CARDINAL;
                    Mz           : CARDINAL;
                    kapaFunction : kapaFunction_T;
                    Cz           : REAL;
                    Cz_1         : REAL;
                VAR boundP       : INTEGER;
                VAR boundM       : INTEGER;
                VAR centre       : INTEGER        ) : BOOLEAN;
    VAR
      mzMkz : REAL;
      jMkz  : REAL;
      bound : REAL;
      kf    : INTEGER;
      difR  : REAL;

    BEGIN
      IF (Kz = NilValC) OR (Mz = NilValC)
      THEN
        boundP := SigNilVal;
        boundM := SigNilVal;
        centre := SigNilVal;
        RETURN FALSE
      END (* if *);
      DEC(Mz);
      mzMkz := FLOAT(Mz - Kz);
      jMkz := FLOAT(Idx - Kz);
      bound := ((Cz_1 - Cz) * jMkz + Cz * mzMkz) / mzMkz;
      difR := real(dif);
      kf := kapaFunction(ref, rec, difR);
      IF kf <> SigNilVal
      THEN
        centre := kf;
        boundP := kf + entier(bound + 0.5);
        boundM := kf - entier(bound + 0.5);
        IF (dif > boundP) OR (dif < boundM)
        THEN
          RETURN TRUE;
        END (* if *);
        RETURN FALSE;
      ELSE
        centre := SigNilVal;
        boundP := SigNilVal;
        boundM := SigNilVal;
        RETURN TRUE;
      END (* if kf *);
    END OutSide;

  BEGIN (* Bend_AddSample *)
    result := FALSE;
    bends := SigNilVal;
    IF (currZone = ns_no) OR (dif = SigNilVal)
    THEN
      boundP := SigNilVal;
      boundM := SigNilVal;
      centre := SigNilVal;
      RETURN FALSE
    END (* if *);
    WITH container DO
      IF currZone <> zone
      THEN
        zone := currZone;
        begIdx := 0;
        begDist := dist;
        errorSum := 0;
        num := 0;
        endIdx := 0;
      END (* if currZone *);
      GetZoneBoundPt(begPT, endPt, zone);
      WITH buff[endIdx] DO
        valInside := NOT OutSide(dif, Idx, zoneBIdx[begPT], zoneBIdx[endPt],
                                 kapaBuff[zone], boundary[begPT], boundary[
                                 endPt], boundP, boundM, centre);
        valueDist := dist;
        IF NOT valInside
        THEN
          INC(errorSum);
        END (* if valInside *);
        INC(num);
      END (* with buff *);
      IF (begDist > dist) AND ((begDist - dist) >= Dist1_17NM) OR
         (begDist < dist) AND ((dist - begDist) >= Dist1_17NM)
      THEN
        bends := entier(FLOAT(errorSum) / FLOAT(num) * 1000.0 + 0.5);
        (* *100 - bo w procentach i *10 bo taka reprezentacja % *)
        Count();
        result := TRUE;
      END (* if ABS *);
      endIdx := (endIdx + 1) MOD Bend_MaxNumOfPoints;
    END (* with container *);
    RETURN result;
  END Bend_AddSample;

  PROCEDURE SetPathAngle
            (    currPathAng  : INTEGER;
                 currZnakKata : INTEGER );

  BEGIN
    pathAng := currPathAng;
    znakKata := currZnakKata;
  END SetPathAngle;


BEGIN
  pathAng := 0;
END ILS_EvalProcedures.
