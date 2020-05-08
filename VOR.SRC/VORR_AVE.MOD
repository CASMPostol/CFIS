(*.F- *)
(**********************************************************************
|  Title   :  Liczenie srednich dla promieni
|  Author  : Mariusz Postol
|  System  : LOGITECH MODULA-2/86
|  History :
|    15-12-96: M.Postol
|      w Roughness_AddSample i Bend_AddSamplewprowadzilem zabezpieczenie 
|      przed przekroczeniem.
|
|  Copyright (C), CAS LODZ POLAND.
|  TEL: 42' 862 547, 42' 87 80 44 FAX/TEL: 42' 84 48 40
|
**********************************************************************)
(*.F+ *)

IMPLEMENTATION MODULE VORR_Average;

  FROM CommonTypes IMPORT
    Dist01NM, Dist02NM, Dist2NM, NilValC, SigNilVal;

  FROM MathLib0 IMPORT
    real, sqrt;

  FROM SpecConv IMPORT
    entierCheck;
    
  PROCEDURE Bend_ClearContainer
            ( VAR container : Bend_Descriptor );

  BEGIN
    WITH container DO
      state := Empty;
      begIdx := 0;
      begDist := NilValC;
      devSum := 0.0;
      num := 0;
      endIdx := 0;
    END (* with container *);
  END Bend_ClearContainer;

  PROCEDURE Bend_AddSample
            (     dev       : INTEGER;
                  dist      : CARDINAL;
              VAR avr       : INTEGER;
              VAR container : Bend_Descriptor ) : BOOLEAN;

    PROCEDURE Count() : REAL;
    VAR
      warSrednia : REAL;
      endCond    : BOOLEAN;

    BEGIN
      WITH container DO
        warSrednia := devSum / FLOAT(num);
        REPEAT
          WITH buff[begIdx] DO
            devSum := devSum - real(value);
            DEC(num);
          END (* with buff *);
          begIdx := (begIdx + 1) MOD Bend_MaxNumOfPoints;
          WITH buff[begIdx] DO
            endCond := (begDist > valueDist) AND 
                       ((begDist - valueDist) >= Dist01NM) OR 
                       (begDist < valueDist) AND 
                       ((valueDist - begDist) >= Dist01NM)
          END (* with buff *);
        UNTIL endCond;
        begDist := buff[begIdx].valueDist;
      END (* with container *);
      RETURN warSrednia;
    END Count;
  VAR
    result : BOOLEAN;

  BEGIN (* Bend_AddSample *)
    IF dev = SigNilVal THEN
      RETURN FALSE;
    END;
    result := FALSE;
    WITH container DO
      WITH buff[endIdx] DO
        value := dev;
        valueDist := dist;
      END (* with buff *);
      CASE state OF
        Empty :
          num := 1;
          begDist := dist;
          devSum := real(dev);
          state := FirstSec;
        |
        FirstSec :
          IF (begDist > dist) AND ((begDist - dist) >= Dist2NM) OR
             (begDist < dist) AND ((dist - begDist) >= Dist2NM)
          THEN
            IF entierCheck( Count(), avr) THEN
              result := TRUE;
            ELSE
              result := FALSE;
            END;
          END (* if ABS *);
          devSum := devSum + real(dev);
          INC(num);
      END (* case state *);
      endIdx := (endIdx + 1) MOD Bend_MaxNumOfPoints;
    END (* with container *);
    RETURN result;
  END Bend_AddSample;

  PROCEDURE Roughness_ClearContainer
            ( VAR container : Roughness_Descriptor );

  BEGIN
    WITH container DO
      state := Empty;
      begIdx := 0;
      begDist := NilValC;
      devSum := 0.0;
      num := 0;
      next01Idx := 0;
      next01Dist := NilValC;
      devSum01 := 0.0;
      num01 := 0;
      endIdx := 0;
    END (* with container *);
  END Roughness_ClearContainer;

  PROCEDURE Roughness_AddSample
            (     dev       : INTEGER;
                  dist      : CARDINAL;
              VAR Roughness       : INTEGER;
              VAR container : Roughness_Descriptor ) : BOOLEAN;

    PROCEDURE Count
              ( VAR Roughness : INTEGER );
    VAR
      forIdx     : CARDINAL;
      warSrednia : REAL;
      RoughnessR : REAL;
      
      PROCEDURE sqr
                (    r : REAL ) : REAL;

      BEGIN
        RETURN r * r;
      END sqr;

    BEGIN
      WITH container DO
        IF num < 5
        THEN
          Roughness := 0;
          RETURN
        END (* if num *);
        warSrednia := devSum / FLOAT(num);
        forIdx := begIdx;
        RoughnessR := 0.0;
        REPEAT
          RoughnessR := RoughnessR + sqr(real(buff[forIdx]) - warSrednia);
          forIdx := (forIdx + 1) MOD Roughness_MaxNumOfPoints;
        UNTIL forIdx = endIdx;
        IF NOT entierCheck(2.0 * sqrt(RoughnessR / FLOAT(num)), Roughness)  
        THEN
          Roughness := SigNilVal;
        END;
      END (* with container *);
    END Count;
  VAR
    result : BOOLEAN;

  BEGIN (* Roughness_AddSample *)
    IF dev = SigNilVal THEN
      RETURN FALSE;
    END;
    result := FALSE;
    WITH container DO
      buff[endIdx] := dev;
      LOOP
        CASE state OF
          Empty :
            num := 1;
            begDist := dist;
            devSum := real(dev);
            state := FirstSec;
            EXIT
          |
          FirstSec :
            IF (begDist > dist) AND ((begDist - dist) >= Dist01NM) OR
               (begDist < dist) AND ((dist - begDist) >= Dist01NM)
            THEN
              next01Idx := endIdx;
              next01Dist := dist;
              state := SecondSec;
            ELSE
              devSum := devSum + real(dev);
              INC(num);
              EXIT;
            END (* if ABS *);
          |
          SecondSec :
            IF (begDist > dist) AND ((begDist - dist) >= Dist02NM) OR
               (begDist < dist) AND ((dist - begDist) >= Dist02NM)
            THEN
              Count(Roughness);
              begIdx := next01Idx;
              next01Idx := endIdx;
              begDist := next01Dist;
              next01Dist := dist;
              devSum := devSum01 + real(dev);
              devSum01 := real(dev);
              num := num01 + 1;
              num01 := 1;
              result := TRUE;
            ELSE
              devSum := devSum + real(dev);
              INC(num);
              devSum01 := devSum01 + real(dev);
              INC(num01);
            END (* if ABS *);
            EXIT;
        END (* case state *);
      END (* loop *);
      endIdx := (endIdx + 1) MOD Roughness_MaxNumOfPoints;
    END (* with container *);
    RETURN result;
  END Roughness_AddSample;

END VORR_Average.
