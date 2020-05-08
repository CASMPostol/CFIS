(*.F- *)
(**********************************************************************
|  Title   : Distance and angle marks management
|  Author  : M.Postol
|  System  : LOGITECH MODULA-2/86
|  History :
|
|  Copyright (C), CAS LODZ POLAND.
|  TEL: 42' 862 547, 42' 87 80 44 FAX/TEL: 42' 84 48 40
|
**********************************************************************)
(*.F+ *)

IMPLEMENTATION MODULE Marks;

  FROM CommonTypes IMPORT
    SigNilVal, DisNilVal, NilValC;

  FROM SpecConv IMPORT
    SubAng360, SubAngle100;

  FROM MathLib0 IMPORT
    real, entier;

  TYPE
    where =
      ( left,
        right,
        away );

  PROCEDURE AngResetContiner
            ( VAR continer : AngMarksDsc );

  BEGIN
    continer.state := Empty;
  END AngResetContiner;

  PROCEDURE DisResetContiner
            ( VAR continer : DisMarksDsc );

  BEGIN
    continer.state := Empty;
  END DisResetContiner;

  PROCEDURE AngAddSample
            (     reference : INTEGER;
              VAR continer  : AngMarksDsc;
              VAR currIndex : INTEGER;
                  Width     : CARDINAL     ) : BOOLEAN;
  VAR
    normRfc : INTEGER;

    PROCEDURE findidx
              (     ref       : INTEGER;
                VAR normRfc   : INTEGER;
                    ImportDif : INTEGER ) : INTEGER;
    VAR
      idx : INTEGER;

    BEGIN (* findidx *)
      IF ref >= 0
      THEN
        idx := (ref + ImportDif DIV 2) DIV ImportDif * ImportDif;
        IF idx = 18000  THEN
         idx := - idx;
        END;
      ELSE
        idx := (ref - ImportDif DIV 2) DIV ImportDif * ImportDif;
      END (* if ref *);
      normRfc := SubAngle100(ref, idx);
      RETURN idx;
    END findidx;

    PROCEDURE Side
              (    normVal   : INTEGER;
                   curIdx    : INTEGER;
                   index     : INTEGER;
                   importDif : INTEGER ) : where;

    BEGIN
      IF (curIdx <> index) OR ( ABS(normVal) > importDif DIV 4 )
      THEN
        RETURN away
      ELSIF normVal < 0
      THEN
        RETURN left
      ELSE
        RETURN right
      END (* if ABS *);
    END Side;

  BEGIN
    IF (Width = DisNilVal) OR (reference = SigNilVal)
    THEN
      RETURN FALSE;
    END (* if reference *);
    currIndex := findidx(reference, normRfc, Width);
    WITH continer DO
      CASE state OF
        Empty :
          index := currIndex;
          CASE Side(normRfc, currIndex, index, Width) OF
            left :
              state := insideCW;
            |
            right :
              state := insideCCW;
          ELSE
          END (* case Side *);
          RETURN FALSE;
        |
        insideCW :
          CASE Side(normRfc, currIndex, index, Width) OF
            right :
              state := WaitFAway;
              RETURN TRUE;
            |
            left :
              RETURN FALSE;
            |
            away :
              state := Empty;
              RETURN FALSE;
          END (* case Side *);
        |
        insideCCW :
          CASE Side(normRfc, currIndex, index, Width) OF
            left :
              state := WaitFAway;
              RETURN TRUE;
            |
            right :
              RETURN FALSE;
            |
            away :
              state := Empty;
              RETURN FALSE;
          END (* case Side *);
        |
        WaitFAway :
          CASE Side(normRfc, currIndex, index, Width) OF
            left, right :
              RETURN FALSE;
            |
            away :
              state := Empty;
              RETURN FALSE;
          END (* case Side *);
      END (* case state *);
    END (* with continer *);
  END AngAddSample;

  PROCEDURE DisAddSample
            (     reference : CARDINAL;
              VAR continer  : DisMarksDsc;
              VAR currIndex : CARDINAL;
                  Width     : CARDINAL     ) : BOOLEAN;
  VAR
    normRfc : INTEGER;

    PROCEDURE findidx
              (     ref       : CARDINAL;
                VAR normRfc   : INTEGER;
                    ImportDif : CARDINAL ) : CARDINAL;
    VAR
      idx : CARDINAL;

    BEGIN (* findidx *)
      IF MAX(CARDINAL) - ImportDif DIV 2 > ref THEN
        idx := (ref + ImportDif DIV 2) DIV ImportDif * ImportDif;
      ELSE
        RETURN DisNilVal;
      END;
      IF ref >= idx
      THEN
        normRfc := ref - idx;
      ELSE
        normRfc := -INTEGER(idx - ref);
      END (* if ref *);
      RETURN idx;
    END findidx;

    PROCEDURE Side
              (    normVal : INTEGER;
                   curIdx  : CARDINAL;
                   index   : CARDINAL ) : where;

    BEGIN
      IF curIdx <> index
      THEN
        RETURN away
      ELSIF normVal < 0
      THEN
        RETURN left
      ELSE
        RETURN right
      END (* if ABS *);
    END Side;

  BEGIN
    IF (Width = DisNilVal) OR (reference = DisNilVal)
    THEN
      RETURN FALSE;
    END (* if reference *);
    currIndex := findidx(reference, normRfc, Width);
    IF currIndex = DisNilVal  THEN
      RETURN FALSE;
    END;
    WITH continer DO
      CASE state OF
        Empty :
          index := currIndex;
          CASE Side(normRfc, currIndex, index) OF
            left :
              state := insideCW;
            |
            right :
              state := insideCCW;
          ELSE
          END (* case Side *);
          RETURN FALSE;
        |
        insideCW :
          CASE Side(normRfc, currIndex, index) OF
            right :
              state := WaitFAway;
              RETURN TRUE;
            |
            left :
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
              state := WaitFAway;
              RETURN TRUE;
            |
            right :
              RETURN FALSE;
            |
            away :
              state := Empty;
              RETURN FALSE;
          END (* case Side *);
        |
        WaitFAway :
          CASE Side(normRfc, currIndex, index) OF
            left, right :
              RETURN FALSE;
            |
            away :
              state := Empty;
              RETURN FALSE;
          END (* case Side *);
      END (* case state *);
    END (* with continer *);
  END DisAddSample;

  PROCEDURE InicjujOpisStanuLuku
            ( VAR continer    : OpisStanuLuku;
                  dlugoscLuku : REAL);
  BEGIN
    WITH continer DO
      index       := NilValC;
      KatPocz     := SigNilVal;
      KatKon      := SigNilVal;
      DlugoscLuku := dlugoscLuku;
    END;
  END InicjujOpisStanuLuku;
  
  PROCEDURE SegZakonczony
            (     reference    : INTEGER;
              VAR continer     : OpisStanuLuku;
              VAR kompletny    : BOOLEAN;
              VAR indexZakLuku : CARDINAL ) : BOOLEAN;
  VAR
    normRfc   : REAL;
    pierwszy  : BOOLEAN;
    luk       : INTEGER;
    currIndex : CARDINAL;
    
    PROCEDURE findidx
              (     ref         : INTEGER;
                VAR normRfc     : REAL;
                    DlugoscLuku : REAL    ) : CARDINAL;
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
      idx := entier((normRfc + DlugoscLuku/2.0) / DlugoscLuku) MOD 
             entier(360.0 / DlugoscLuku);
      normRfc := SubAng360(normRfc, real(idx) * DlugoscLuku);
      RETURN idx;
    END findidx;

  BEGIN (* SegZakonczony *)
    WITH continer DO
      currIndex := findidx(reference, normRfc, DlugoscLuku);
      IF index = currIndex  THEN
        KatKon := reference;
        RETURN FALSE;
      ELSE
        luk := SubAngle100(KatKon, KatPocz);
        kompletny := ( luk<>SigNilVal ) AND 
                     ( real(ABS(luk)) >= 0.7 * DlugoscLuku );
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
  END SegZakonczony;

END Marks.
