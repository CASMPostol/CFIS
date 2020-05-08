(*.F- *)
(**********************************************************************
|  Title   : Common procedures for file handling
|  Author  : M.Postol
|  System  : LOGITECH MODULA-2/86
|  History :
|    23-10-96: M.Postol
|      filtr cyfrowy po pierwszym wywolaniu podstawia input jako wartosc 
|      poczatkowa
|    12-12-96: M.Postol
|      wstawilem filtr - podtrzymanie wartosci analogowej.
|    Rel. 3.14: MPostol
|      W MemFiltrnie byl zmniejszany licznik przy zlej wartosci.
|
|  Copyright (C), CAS LODZ POLAND.
|  TEL: 42' 862 547, 42' 87 80 44 FAX/TEL: 42' 84 48 40
|
**********************************************************************)
(*.F+ *)

IMPLEMENTATION MODULE FIltr1St;

  FROM MathLib0 IMPORT
    exp;

  FROM SpecConv  IMPORT
    entierCheck;
    
  FROM CommonTypes IMPORT
    SigNilVal;
    
  VAR
    okresImp : REAL;
    
  PROCEDURE UstawOkresImpulsowania
            (     okres: REAL);
  BEGIN
    okresImp := okres;
  END UstawOkresImpulsowania;
  
  PROCEDURE InitCont
            ( VAR con : ContinerT;
                  tau : REAL      );

  CONST
    Wartoscpoczatkowa = 0.0;

  BEGIN
    WITH con DO
      first := TRUE;
      out := Wartoscpoczatkowa;
      IF tau < okresImp / 10.0
      THEN
        Tau := 0.0;
      ELSE
        Tau := 1.0 - exp(-okresImp / tau);
      END (* if tau *);
    END (* with con *);
  END InitCont;

  PROCEDURE Filtr
            ( VAR con   : ContinerT;
                  input : REAL      ) : REAL;

  BEGIN
    WITH con DO
      IF first  THEN
        first := FALSE;
        out := input;
        RETURN out;
      END;
      out := out + Tau * (input - out);
      RETURN out
    END (* with con *);
  END Filtr;
  
  PROCEDURE InitCont2Filters
            ( VAR con      : Continer2FiltersT;
                  tauSmal  : REAL;
                  tauLarge : REAL );

  CONST
    okresImp          = 0.2;
    Wartoscpoczatkowa = 0.0;

  BEGIN
    WITH con DO
      first := TRUE;
      out := Wartoscpoczatkowa;
      IF tauSmal < okresImp / 10.0
      THEN
        TauSmall := 0.0;
      ELSE
        TauSmall := 1.0 - exp(-okresImp / tauSmal);
      END (* if tau *);
      IF tauLarge < okresImp / 10.0
      THEN
        TauLarge := 0.0;
      ELSE
        TauLarge := 1.0 - exp(-okresImp / tauLarge);
      END (* if tau *);
    END (* with con *);
  END InitCont2Filters;

  PROCEDURE Filtr2Filters
            ( VAR con   : Continer2FiltersT;
                  input : REAL      ) : REAL;
  VAR
    delta: REAL;
    
  BEGIN
    WITH con DO
      IF first  THEN
        first := FALSE;
        out := input;
        RETURN out;
      END;
      delta := (input - out);
      IF ABS(delta/out) > 0.2  THEN
        out := out + TauLarge * delta;
      ELSE
        out := out + TauSmall * delta;
      END (* IF *);
      RETURN out
    END (* with con *);
  END Filtr2Filters;
  
  PROCEDURE InitContB
            ( VAR con       : ContinerBT;
                  tau       : CARDINAL;
                  startVal  : BOOLEAN  );
  BEGIN
    WITH con  DO
      maxFCount := tau;
      IF startVal  THEN
        count := maxFCount;
      ELSE
        count := 0;
      END;
    END;
  END InitContB;
  
  PROCEDURE  FiltrB
             (VAR con   : ContinerBT;
                  input : BOOLEAN;
              VAR res   : BOOLEAN);
  BEGIN  (* FiltrB *)
    WITH con DO
      IF input  THEN
        IF  count < maxFCount  THEN
          INC(count);
        ELSE
          res := TRUE;
        END;
      ELSE
        IF count > 0  THEN
          DEC(count);
        ELSE
          res := FALSE;
        END;
      END;
    END;
  END FiltrB;

  PROCEDURE InitContBCoun
            ( VAR con       : BinaryCounterCon;
                  startVal  : BOOLEAN  );
  BEGIN
    WITH con DO
      prevVal := startVal;
      counter := 0;
    END;
  END InitContBCoun;
  
  PROCEDURE BinaryCounter
            (    bit : BOOLEAN;
             VAR cont: BinaryCounterCon): CARDINAL;
  BEGIN
    WITH cont DO
      IF NOT prevVal AND bit
      THEN
        (*$R-*)
        INC(counter);
        (*$R=*)
        prevVal := TRUE;
      ELSIF prevVal AND NOT bit
      THEN
        prevVal := FALSE;
      END (* if *);
      RETURN counter;
    END;
  END BinaryCounter;
   
  PROCEDURE  MemFiltr
             ( VAR con  : MemFContiner;
                   val  : REAL;
                   sign : CARDINAL): INTEGER;
                   
  BEGIN
    WITH con  DO
      IF sign <> dataSign THEN
        IF NOT entierCheck(val, lastVal) THEN
          lastVal := SigNilVal;
        END;
        dataSign := sign;
        counter := maxCount;
        RETURN lastVal;
      ELSIF counter > 0 THEN
        DEC(counter);
        RETURN lastVal;
      ELSE
        RETURN SigNilVal;
      END;
    END;
  END MemFiltr;
  
  PROCEDURE InitMemFiltr
             ( VAR con          : MemFContiner;
                   frstDataSign : CARDINAL;
                   fltrMaxCount : CARDINAL);
  BEGIN
    WITH con  DO
      lastVal  := SigNilVal;
      dataSign := frstDataSign;
      counter  := 0;
      maxCount := fltrMaxCount;
    END;
  END InitMemFiltr;
  
  PROCEDURE  MemFiltrInt
             ( VAR con  : MemFIntContiner;
                   val  : INTEGER        ): INTEGER;
                   
  BEGIN
    WITH con  DO
      IF val <> SigNilVal THEN
        lastVal := val;
        counter := maxCount;
        RETURN val;
      ELSIF counter > 0 THEN
        DEC(counter);
        RETURN lastVal;
      ELSE
        RETURN SigNilVal;
      END;
    END;
  END MemFiltrInt;
  
  PROCEDURE InitMemFIntContiner
             ( VAR con          : MemFIntContiner;
                   fltrMaxCount : CARDINAL);
  BEGIN
    WITH con  DO
      lastVal  := SigNilVal;
      counter  := 0;
      maxCount := fltrMaxCount;
    END;
  END InitMemFIntContiner;

BEGIN
  okresImp := 0.2;
END FIltr1St.
