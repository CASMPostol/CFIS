(*.F- *)
(**********************************************************************
|  Title   : Evaluation procedures for ILS
|  Author  : M.Postol
|  System  : LOGITECH MODULA-2/86
|  History :
|
|  Copyright (C), CAS LODZ POLAND.
|  TEL: 42' 862 547, 42' 87 80 44 FAX/TEL: 42' 84 48 40
|
**********************************************************************)
(*.F+ *)

IMPLEMENTATION MODULE L_EvalProcedures;

  FROM MathLib0 IMPORT
    entier, real;

  FROM CommonTypes IMPORT
    SigNilVal, DisNilVal, NilValC, Dist01NM, OdnDlaPomBleduT, 
    GlownyOdbiornikT;

  FROM L_CommonTypes IMPORT
    NumStrefy, NumPunktu, category;

  FROM ILS_ZoneMngmnt IMPORT
    zoneBIdx_T, FillBound;

  FROM SpecConv IMPORT
    entierCheck;
    
  TYPE
    pos =
      ( OutL,
        OutR,
        Inside );

  PROCEDURE CountAzym0R
            (    Alfa        : INTEGER;
                 dev         : REAL;
                 coefficient : REAL    ) : REAL;

  BEGIN
    RETURN real(Alfa) - dev * coefficient;
  END CountAzym0R;

  PROCEDURE CountAzymR
            (    Alfa : INTEGER;
                 dev  : REAL;
                 devS : REAL;
                 os   : REAL    ) : REAL;

  BEGIN
    RETURN (real(Alfa) * devS - (devS - dev) * os) / dev;
  END CountAzymR;

  PROCEDURE CountDif
            (    Alfa      : INTEGER;
                 dev       : INTEGER;
                 displSens : REAL;
                 pathAng   : REAL    ) : INTEGER;
  VAR
    displace: INTEGER;
  BEGIN
    IF (dev = SigNilVal) OR (Alfa = SigNilVal) OR (ABS(Alfa) > 1500)
    THEN
      RETURN SigNilVal
    ELSIF entierCheck((real(Alfa)-pathAng) * displSens + 0.5, displace)
    THEN
      RETURN +dev - displace;
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
        IF num > 0  THEN
          RETURN entier(sum / FLOAT(num) + 0.5);
        ELSE
          RETURN SigNilVal
        END;
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
        IF num > 0  THEN
          RETURN entier(sum / FLOAT(num) + 0.5);
        ELSE
          RETURN SigNilVal;
        END;
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
            (    Alfa      : INTEGER;
                 dev       : INTEGER;
                 devS      : REAL;
                 os        : REAL;
                 secWith   : REAL    ) : INTEGER;
  VAR
    az : REAL;

  BEGIN
    IF (ABS(dev) < 100) OR (Alfa = SigNilVal) OR (dev = SigNilVal)
    THEN
      RETURN SigNilVal;
    END (* if *);
    az := CountAzymR(Alfa, real(dev), devS, os);
    RETURN entier(az - secWith * 1500.0 / devS / 2.0  )
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
    RETURN -dev + real(Alfa) * coefficient;
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
              (    dev : INTEGER ) : Event_T;

    BEGIN
      IF ABS(dev) < 1500
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
      event := Check(dev);
      CASE State OF
        Outside_CL :
          CASE event OF
            Outside_EV :
            |
            After150_EV :
              IF (h175Mn = SigNilVal) OR (ABS(Alfa) < ABS(h175Mn))
              THEN
                h150Mn := Alfa;
                State := After150_CL;
              END (* if *);
            |
            After175_EV :
              IF (h175Mn = SigNilVal) OR (ABS(Alfa) < ABS(h175Mn))
              THEN
                h175Mn := Alfa;   (* tylko dla orientacji kierunku *)
                State := Inside_CL;
              END (* if *);
          END (* case event *);
        |
        After150_CL :
          CASE event OF
            Outside_EV :
              h150Mn := SigNilVal;
              State := Outside_CL;
            |
            After150_EV :
            |
            After175_EV :
              IF ABS(Alfa) < ABS(h150Mn)
              THEN
                State := InsideToCent_CL;
                h175Mx := Alfa
              ELSIF ABS(Alfa) > ABS(h150Mn)
              THEN
                State := InsideFromCent_CL;
                h175Mn := Alfa;
                h150Mn := SigNilVal;
              ELSE
                State := Inside_CL;
                h175Mn := Alfa;
                h150Mn := SigNilVal;
              END (* if Alfa *);
          END (* case event *);
        |
        InsideFromCent_CL :
          CASE event OF
            Outside_EV :
              h150Mn := Alfa;
              h175Mx := Alfa;
              State := Completed_CL;
            |
            After150_EV :
              State := After150FromCent_EV;
            |
            After175_EV :
              h175Mx := Alfa;
          END (* case event *);
        |
        InsideToCent_CL :
          CASE event OF
            Outside_EV, After150_EV :
              State := Completed_CL;
            |
            After175_EV :
              h175Mn := Alfa;
          END (* case event *);
        |
        Inside_CL :
          CASE event OF
            Outside_EV :
            (* bylo zaklucenie *)
              h150Mn := SigNilVal;
              h175Mx := SigNilVal;
              h175Mn := SigNilVal;
              State := Outside_CL;
            |
            After150_EV :
              IF h175Mx = SigNilVal
              THEN
              (* czysto teoretyczny przypadek *)
                h175Mx := Alfa;
              END (* if h175Mx *);
              IF ABS(h175Mx) < ABS(h175Mn)
              THEN
                h175Mn := h175Mx;
                h175Mx := SigNilVal;
                State := Completed_CL;
              ELSE
                h175Mn := SigNilVal;
                State := After150FromCent_EV;
              END (* if Alfa *);
            |
            After175_EV :
              h175Mx := Alfa;
          END (* case event *);
        |
        After150FromCent_EV :
          CASE event OF
            Outside_EV :
              IF h150Mn = SigNilVal
              THEN
                h150Mn := Alfa;
              END (* if h150Mn *);
              State := Completed_CL;
            |
            After150_EV, After175_EV :
              h150Mn := Alfa;
          END (* case event *);
        |
        Completed_CL :
          CASE event OF
            Outside_EV :
              State := Outside_CL;
            |
            After150_EV :
            |
            After175_EV :
              IF ABS(Alfa) < ABS(h175Mn)
              THEN
                h150Mn := SigNilVal;
                h175Mn := Alfa;
                h175Mx := SigNilVal;
                State := After150_CL
              END (* if Alfa *);
          END (* case event *);
      END (* case State *);
    END (* with cont *);
  END Clearence_Addsmpl;

  PROCEDURE Clearence_Clear
            ( VAR cont : Clearence_ConT;
                  znak : INTEGER        );

  BEGIN
    WITH cont DO
      State := Outside_CL;
      Znak := znak;
      h175Mn := SigNilVal;
      h175Mx := SigNilVal;
      h150Mn := SigNilVal;
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
      IF (ABS(dev) < 100) OR (Alfa = SigNilVal) OR (dev = SigNilVal)
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

  BEGIN
    IF (ABS(dev) < 100) OR (Alfa = SigNilVal) OR (dev = SigNilVal)
    THEN
      RETURN SigNilVal;
    ELSE
      RETURN entier(CountAzymR(Alfa, real(dev), devS, os));
    END (* if *);
  END CountAzym;

  PROCEDURE CountAzymOsi
            (    Alfa       : INTEGER;
                 dev        : INTEGER;
                 displSens  : REAL    ) : INTEGER;

  BEGIN
    IF (ABS(dev) > 1000) OR (Alfa = SigNilVal) OR (dev = SigNilVal)
    THEN
      RETURN SigNilVal;
    ELSE
      RETURN entier(CountAzym0R(Alfa, real(dev), 1.0 / displSens));
    END (* if *);
  END CountAzymOsi;

  PROCEDURE MkrLnth_AddSmpl
            ( VAR cont : MkrLnth_ConT;
                  flg  : BOOLEAN;
                  dis  : CARDINAL     ) : INTEGER;

  BEGIN
    IF (dis = DisNilVal)
    THEN
      RETURN SigNilVal;
    END (* if *);
    WITH cont DO
      CASE state OF
        Ouside_Mkr :
          IF flg
          THEN
            INC(numOfMkrs);
            state := Inside_Mkr;
            beg := dis;
          END (* if flg *);
        |
        Inside_Mkr :
          IF NOT flg
          THEN
            state := Ouside_Mkr;
            IF dis > beg
            THEN
              RETURN dis - beg
            ELSE
              RETURN beg - dis
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
      state := MIN(MkrLnth);
      numOfMkrs := 0;
      beg := DisNilVal;
    END (* with cont *);
  END MkrLnth_Clear;

  PROCEDURE Bend_ClearContainer
            ( VAR Container : Bend_Descriptor;
                  ZoneBIdx  : zoneBIdx_T;
                  Cat       : category;
                  KapaBuff  : KapaBuff_T      );

  BEGIN
    WITH Container DO
      zone := NilValC;
      zoneBIdx := ZoneBIdx;
      FillBound(boundary, Cat);
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
                  currZone  : CARDINAL;
                  ref       : OdnDlaPomBleduT;
                  rec       : GlownyOdbiornikT;
              VAR boundP    : INTEGER;
              VAR boundM    : INTEGER;
              VAR centre    : INTEGER;
              VAR bends     : INTEGER; (* x100 *)
              VAR container : Bend_Descriptor ) : BOOLEAN;

  CONST
    Dist1_17NM = 585;  (* 1.17*500.0 *)
  VAR
    result : BOOLEAN;

    PROCEDURE Count();
    VAR
      endCond : BOOLEAN;

    BEGIN (* Count *)
      WITH container DO
        REPEAT
          WITH buff[begIdx] DO
            IF valInside
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

    PROCEDURE Inside
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
      kf    : REAL;
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
      centre := entier(kf + 0.5);
      boundP := entier(kf + bound + 0.5);
      boundM := entier(kf - bound + 0.5);
      IF (dif > boundP) OR (dif < boundM)
      THEN
        RETURN TRUE;
      END (* if *);
      RETURN FALSE;
    END Inside;

  BEGIN (* Bend_AddSample *)
    result := FALSE;
    IF (currZone = NilValC) OR (dif = SigNilVal)
    THEN
      boundP := SigNilVal;
      boundM := SigNilVal;
      centre := SigNilVal;
      bends := SigNilVal;
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
      WITH buff[endIdx] DO
        valInside := Inside(dif, Idx, zoneBIdx[zone], zoneBIdx[zone + 1],
                            kapaBuff[zone], boundary[zone], boundary[zone + 1],
                            boundP, boundM, centre);
        valueDist := dist;
        IF valInside
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

END L_EvalProcedures.
