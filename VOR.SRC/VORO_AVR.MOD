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
|    Rel 3.0. M.Postol
|       Zmienilem procedure AddSample na AVR10_AddSample, ktora od razu 
|       podstawia wyniki do srednich na 10 stopniach.
|       Przenioslem tu OrbitDsc zdefiniowale procedure inicjacji
|
|  Copyright (C), CAS LODZ POLAND.
|  TEL: 42' 686 25 47
|  mailto: techsupp@cas.com.pl
|  http: www.cas.com.pl
|
**********************************************************************)
(*.F+ *)
IMPLEMENTATION MODULE VORO_avrage;

  FROM MathLib0 IMPORT
    real, entier;

  FROM CommonTypes  IMPORT
    SigNilVal, NilValC;

  FROM SpecConv IMPORT
    SubAng360, SubAngle100;
    
  TYPE
    where =
      ( left, right, inside, away);

  CONST
    Width      = 2.0; (* specyfikacja 4.5.3.4.3 *)
    minSamples = 7;   (* minimalna liczba probek potrzebna do akceptacji 
                         wyniku *)
    
  PROCEDURE OrbitDscClear( VAR DevOrbit: OrbitDsc);
  VAR
    decIdx : PartIdx;
  BEGIN
    FOR decIdx := 0 TO 35 DO
      DevOrbit[decIdx] := SigNilVal;
    END (* for decIdx *);
  END OrbitDscClear;

  PROCEDURE ResetContiner
            ( VAR continer : AVRdescription );

  BEGIN
    WITH continer DO
      errDevSun := 0.0;
      samples   := 0;
    END (* with continer *);
  END ResetContiner;

  PROCEDURE ClearContainer
            ( VAR continer : AVRdescription );

  BEGIN
    continer.state := Empty;
    ResetContiner(continer);
  END ClearContainer;
  

  PROCEDURE InicjujOpisStanuLuku
            ( VAR continer  : OpisStanuLuku);
  BEGIN
    WITH continer DO
      index      := NilValC;
      KatPocz    := SigNilVal;
      KatKon     := SigNilVal;
    END;
  END InicjujOpisStanuLuku;
  
  PROCEDURE SegmentZakonczony
            (     reference    : INTEGER;
              VAR continer     : OpisStanuLuku;
              VAR kompletny    : BOOLEAN;
              VAR indexZakLuku : PartIdx ) : BOOLEAN;
  VAR
    normRfc   : REAL;
    pierwszy  : BOOLEAN;
    luk       : INTEGER;
    currIndex : CARDINAL;
    
    PROCEDURE findidx
              (     ref     : INTEGER;
                VAR normRfc : REAL    ) : CARDINAL;
    VAR
      idx : INTEGER;

    BEGIN (* findidx *)
      IF ref = SigNilVal THEN
        RETURN NilValC;
      END;
      normRfc := real(ref) / 100.0;
      IF normRfc < 0.0
      THEN
        normRfc := normRfc + 360.0;
      END (* if normRfc *);
      idx := entier((normRfc + 5.0) / 10.0) MOD 36;
      normRfc := SubAng360(normRfc, real(idx) * 10.0);
      RETURN idx;
    END findidx;

  BEGIN (* SegmentZakonczony *)
    currIndex := findidx(reference, normRfc);
    WITH continer DO
      IF index = currIndex  THEN
        KatKon := reference;
        RETURN FALSE;
      ELSE
        luk := SubAngle100(KatKon, KatPocz);
        kompletny := (luk<>SigNilVal) AND (ABS(luk) >= 970);
        IF kompletny  THEN
          indexZakLuku := index;
        END; (* IF kompletny *)
        pierwszy  := index = NilValC;
        KatPocz   := reference;
        KatKon    := SigNilVal;
        index     := currIndex;
        RETURN NOT pierwszy;
      END; (* IF index *)
    END; (* WITH continer *)
  END SegmentZakonczony;

  
  PROCEDURE AVR10_AddSample
            (     dev       : INTEGER;
                  (* akytualna dewiacja namiaru *)
                  rfc       : INTEGER;
                  (* wartosc odniesienia kata *)
              VAR container : AVRdescription;
                  (* opis aktualnego odcinka *)
              VAR devOrbit  : OrbitDsc);

  PROCEDURE AddSample
            (     dev       : INTEGER;
                  reference : INTEGER;
              VAR continer  : AVRdescription ) : BOOLEAN;
  VAR
    normRfc   : REAL;
    currIndex : PartIdx;

    PROCEDURE findidx
              (     ref     : INTEGER;
                VAR normRfc : REAL    ) : INTEGER;
    VAR
      idx : INTEGER;

    BEGIN (* findidx *)
      normRfc := real(ref) / 100.0;
      IF normRfc < 0.0
      THEN
        normRfc := normRfc + 360.0;
      END (* if normRfc *);
      idx := entier((normRfc + 5.0) / 10.0) MOD 36;
      normRfc := SubAng360(normRfc, real(idx) * 10.0);
      RETURN idx;
    END findidx;

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
    IF (dev = SigNilVal) OR (reference = SigNilVal)
    THEN
      RETURN FALSE;
    END;
    currIndex := findidx(reference, normRfc);
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
                errDevSun := errDevSun + real(dev);
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
                errDevSun := errDevSun + real(dev);
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

   PROCEDURE O_AvrCountErr
             ( VAR err  : OrbitDsc;
                   CONT : AVRdescription );
    BEGIN
      WITH CONT DO
        err[index] := entier( errDevSun / real( samples ) );
      END (* with CONT *);
    END O_AvrCountErr;

  BEGIN
    IF AddSample(dev, rfc, container)
    THEN
      O_AvrCountErr( devOrbit, container )
    END (* if VORO_avrage.AddSample *);
  END AVR10_AddSample;
    
END VORO_avrage.
