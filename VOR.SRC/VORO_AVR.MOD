(*.F- *)
(**********************************************************************
|  Title   : Liczenie srednich dla orbity
|  Author  : M.Postol
|  System  : LOGITECH MODULA-2/86
|  History :
|    15-12-96: M.Postol
|      AddSample returns if there is at least one SigNilVal
|    03-06-97: M.Postol
|      Zmienilem znak bledu
|
|  Copyright (C), CAS LODZ POLAND.
|  TEL: 42' 862 547, 42' 87 80 44 FAX/TEL: 42' 84 48 40
|
**********************************************************************)
(*.F+ *)

IMPLEMENTATION MODULE VORO_avrage;

  FROM MathLib0 IMPORT
    real, entier;

  FROM MANAGER IMPORT
    Assert;

  FROM CommonTypes  IMPORT
    SigNilVal;

  TYPE
    where =
      ( left,
        right,
        inside,
        away );

  CONST
    Width      = 2.0; (* specyfikacja 4.5.3.4.3 *)
    minSamples = 7;   (* minimalna liczba probek potrzebna do akceptacji 
                         wyniku *)
    
  PROCEDURE ResetContiner
            ( VAR continer : AVRdescription );

  BEGIN
    WITH continer DO
      errDevSun := 0.0;
      samples := 0;
    END (* with continer *);
  END ResetContiner;

  PROCEDURE ClearContainer
            ( VAR continer : AVRdescription );

  BEGIN
    continer.state := Empty;
    ResetContiner(continer);
  END ClearContainer;

  PROCEDURE AddSample
            (     src,
                  reference : INTEGER;
              VAR continer  : AVRdescription ) : BOOLEAN;
  VAR
    normRfc   : REAL;
    normSrc   : REAL;
    currIndex : PartIdx;

    PROCEDURE findidx
              (     ref     : INTEGER;
                    src     : INTEGER;
                VAR normRfc : REAL;
                VAR normSrc : REAL    ) : INTEGER;
    VAR
      idx : INTEGER;

    BEGIN (* findidx *)
      normRfc := real(ref) / 100.0;
      normSrc := real(src) / 100.0;
      IF normRfc < 0.0
      THEN
        normRfc := normRfc + 360.0;
      END (* if normRfc *);
      IF normSrc < 0.0
      THEN
        normSrc := normSrc + 360.0;
      END (* if normSrc *);
      idx := entier((normRfc + 5.0) / 10.0) MOD 36;
      normSrc := normSrc - FLOAT(idx) * 10.0;
      IF normSrc > 180.0
      THEN
        normSrc := normSrc - 360.0;
      END (* if normSrc *);
      normRfc := normRfc - FLOAT(idx) * 10.0;
      IF normRfc > 180.0
      THEN
        normRfc := normRfc - 360.0;
      END (* if normRfc *);
      RETURN idx;
    END findidx;

    PROCEDURE SubAng(A, minusB: REAL): REAL;
    VAR
      res: REAL;
    BEGIN
      res := A - minusB;
      IF res > 180.0 THEN
        res := res - 360.0
      ELSIF res < -180.0 THEN
        res := res + 360.0
      END;
      RETURN res;
    END SubAng;
    
    PROCEDURE Side
              (    normAangle : REAL;
                   curIdx     : PartIdx;
                   index      : PartIdx ) : where;

    BEGIN
      IF curIdx <> index  THEN
        RETURN away
      ELSIF ABS(normAangle) < Width
      THEN
        RETURN inside
      ELSIF ABS(normAangle) > 4.9
      THEN
        RETURN away
      ELSIF normAangle < 0.0
      THEN
        RETURN left
      ELSE
        RETURN right
      END (* if ABS *);
    END Side;

  BEGIN
    IF (src = SigNilVal) OR (reference = SigNilVal)
    THEN
      RETURN FALSE;
    END;
    currIndex := findidx(reference, src, normRfc, normSrc);
    WITH continer DO
      LOOP
        CASE state OF
          Empty :
            index := currIndex;
            CASE Side(normRfc, currIndex, index) OF
              left :
                state := MinFound;
              |
              right :
                state := MaxFound;
            ELSE
            END (* case Side *);
            RETURN FALSE;
          |
          MinFound :
            CASE Side(normRfc, currIndex, index) OF
              left :
                RETURN FALSE;
              |
              right :
                state := MaxFound;   (* dane musz byc bardzo zle ale nic *)
                RETURN FALSE;
              |
              inside :
                ResetContiner(continer);
                state := insideCCW;
              |
              away :
                state := Empty;
            END (* case Side *);
          |
          MaxFound :
            CASE Side(normRfc, currIndex, index) OF
              left :
                state := MinFound;   (* dane musz byc bardzo zle ale nic *)
                RETURN FALSE;
              |
              right :
                RETURN FALSE;
              |
              inside :
                ResetContiner(continer);
                state := insideCW;
              |
              away :
                state := Empty;
                RETURN FALSE;
            END (* case Side *);
          |
          insideCW :
            CASE Side(normRfc, currIndex, index) OF
              left :
                state := Empty;
                RETURN minSamples <= samples;
              |
              right :
                state := MaxFound;
                RETURN FALSE;
              |
              inside :
                errDevSun := errDevSun + SubAng(normRfc, normSrc);
                INC(samples);
                RETURN FALSE;
              |
              away :
                state := Empty;
                RETURN FALSE;
            END (* case Side *);
          |
          insideCCW :
            CASE Side(normRfc, currIndex, index) OF
              left :
                state := MinFound;
                RETURN FALSE;
              |
              right :
                state := Empty;
                RETURN minSamples <= samples;
              |
              inside :
                errDevSun := errDevSun + SubAng(normRfc, normSrc);
                INC(samples);
                RETURN FALSE;
              |
              away :
                state := Empty;
                RETURN FALSE;
            END (* case Side *);
        END (* case state *);
      END (* loop *);
    END (* with continer *);
  END AddSample;

END VORO_avrage.
