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
    
  PROCEDURE InitCont
            ( VAR con : ContinerT;
                  tau : REAL      );

  CONST
    okresImp          = 0.2;
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
  
END FIltr1St.
