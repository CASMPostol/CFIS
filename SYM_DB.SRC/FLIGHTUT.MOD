IMPLEMENTATION MODULE FlightUtil;

IMPORT
  Lib;

CLASS IMPLEMENTATION TChkBox;

  PROCEDURE Init( VAR ABounds  : TRect;
                      AStrings : PSItem;
                      va       : ADDRESS );
  BEGIN
    TCheckBoxes.Init( ABounds, AStrings );
    VariableAffected := va;
    SetData( va^ );
  END Init;

  VIRTUAL PROCEDURE Press( Item : INTEGER );
  BEGIN
    IF Value - BITSET( Item ) # BITSET{} THEN (* Zostalo odcheckowane *)
      Lib.NoSound;
    END;
    TCheckBoxes.Press( Item );
    GetData( VariableAffected^ );
  END Press;

BEGIN
END TChkBox;

CLASS IMPLEMENTATION TVReal;

  VIRTUAL PROCEDURE Validate( VAR v : LONGREAL );
  BEGIN
    TSpeedBoxReal.Validate( v );
    WHILE v <= -180.0 DO
      v := v+360.0;
    END;
    WHILE v > 180.0 DO
      v := v-360.0;
    END;
  END Validate;

BEGIN
END TVReal;

CLASS IMPLEMENTATION TAGC;

  PROCEDURE Init( VAR Bounds  : TRect;
                      StrSize : CARDINAL; (* < StringSize *)
                      AMin,
                      AMax    : LONGREAL;
                      ADef    : PReal;
                      AFileName : ARRAY OF CHAR;
(*                      AOrg    : PReal;*)
                      AIndep  : PReal );
  BEGIN
    TFileLine.Init( Bounds, StrSize, AMin, AMax, ADef, AFileName );
(*    Org := AOrg;*)
    Indep := AIndep;
  END Init;

(*
  VIRTUAL PROCEDURE Validate( VAR v : LONGREAL );
  BEGIN
    IF FileName = NIL THEN
      Org^ := Loc2Glob( v );
      IF Org^ > Inp^.Max THEN
        Org^ := Inp^.Max;
      ELSIF Org^ < Inp^.Min THEN
        Org^ := Inp^.Min;
      END;
      v := Glob2Loc( Org^ );
    END;
  END Validate;

  PROCEDURE Loc2Glob( r : LONGREAL ) : LONGREAL;
  BEGIN
    RETURN r/(1.0-Indep^/100.0);
  END Loc2Glob;

  PROCEDURE Glob2Loc( r : LONGREAL ) : LONGREAL;
  BEGIN
    RETURN  r*(1.0-Indep^/100.0);
  END Glob2Loc;
*)

BEGIN
END TAGC;

END FlightUtil.
