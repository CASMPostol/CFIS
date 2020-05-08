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

IMPLEMENTATION MODULE G_EvalProcedures;

  FROM MathLib0 IMPORT
    entier, real;

  FROM CommonTypes IMPORT
    SigNilVal, DisNilVal;

  TYPE
    pos =
      ( OutL,
        OutR,
        Inside );

  PROCEDURE CountDif
            (    Alfa       : INTEGER;
                 dev        : INTEGER;
                 displSens  : REAL    ) : INTEGER;

  BEGIN
    IF (dev <> SigNilVal) AND (Alfa <> SigNilVal) AND (ABS(Alfa) < 1000)
    THEN
      RETURN -dev + entier(real(Alfa) * displSens + 0.5);
    ELSE
      RETURN SigNilVal
    END (* if *);
  END CountDif;

  PROCEDURE AV_Addsmpl
            ( VAR cont : Avr_ConT;
                  val  : INTEGER  ) : INTEGER;

  BEGIN
    IF val <> SigNilVal
    THEN
      WITH cont DO
        INC(num);
        sum := sum + real(val);
        RETURN entier(sum / FLOAT(num) + 0.5)
      END (* with cont *);
    END (* if val *);
    RETURN SigNilVal;
  END AV_Addsmpl;

  PROCEDURE AV_Clear
            ( VAR cont : Avr_ConT );

  BEGIN
    WITH cont DO
      sum := 0.0;
      num := 0;
    END (* with cont *);
  END AV_Clear;

  PROCEDURE CountAzymR
            (    Alfa : INTEGER;
                 dev  : REAL;
                 devS : REAL;
                 os   : REAL    ) : REAL;

  BEGIN
    RETURN (real(Alfa) * devS - (devS - dev) * os) / dev;
  END CountAzymR;

  PROCEDURE  CountDelAzym
            (    Alfa      : INTEGER;
                 dev       : INTEGER;
                 devS      : REAL;
                 os        : REAL;
                 displSens : REAL) : INTEGER;
  
  VAR
    az: REAL;
    
   BEGIN
    IF (ABS(dev) < 100) OR (Alfa = SigNilVal) OR (dev = SigNilVal)
    THEN
      RETURN SigNilVal;
    END (* if *);
    az := CountAzymR(Alfa, real(dev), devS, os);
    RETURN entier(az - devS/displSens)
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

  PROCEDURE CountAzym0R
            (    Alfa        : INTEGER;
                 dev         : REAL;
                 coefficient : REAL    ) : REAL;

  BEGIN
    RETURN real(Alfa) - dev * coefficient;
  END CountAzym0R;

  PROCEDURE AzDif0_Addsmpl
            ( VAR cont : AzDif0_ConT;
                  Alfa : INTEGER;
                  dev  : INTEGER;
              VAR ang  : INTEGER    );

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
                  displSens : REAL    );

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
                  displSens : REAL    );

  BEGIN
    WITH cont DO
      sum := 0.0;
      num := 0;
      coefficient := 1.0 / displSens;
      state := MIN(Azym_StateT);
      count := CountAzym0R;
    END (* with cont *);
  END Az0_Clear;

  PROCEDURE AzymAV_Addsmpl
            ( VAR cont : AzymAV_ConT;
                  Alfa : INTEGER;
                  dev  : INTEGER;
              VAR ang  : INTEGER     );

  BEGIN
    IF (ABS(dev) < 100) OR (Alfa = SigNilVal) OR (dev = SigNilVal)
    THEN
      RETURN
    END (* if *);
    WITH cont DO
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
                 os   : REAL) : INTEGER;

  BEGIN
    IF (ABS(dev) < 100) OR (Alfa = SigNilVal) OR (dev = SigNilVal)
    THEN
      RETURN SigNilVal;
    ELSE
      RETURN entier(CountAzymR(Alfa, real(dev), devS, os));
    END (* if *);
  END CountAzym;

  PROCEDURE MkrLnth_AddSmpl
            ( VAR cont : MkrLnth_ConT;
                  flg  : BOOLEAN;
                  dis  : CARDINAL     ) : CARDINAL;

  BEGIN
    IF (dis = DisNilVal)
    THEN
      RETURN DisNilVal;
    END (* if *);
    WITH cont DO
      CASE state OF
        Ouside_Mkr :
          IF flg
          THEN
            INC(numOfMkrs);
            state := Inside_Mkr;
            beg := dis;
            RETURN DisNilVal;
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

END G_EvalProcedures.
