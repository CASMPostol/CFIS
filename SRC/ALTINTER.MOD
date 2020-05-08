(*.F- *)
(**********************************************************************
|  Title   : Altimeter interface
|  Author  : Mariusz Postol
|  System  : LOGITECH MODULA-2/86
|  History :
|     22-05-97: M.Postol
|       blad w konwersji kodu z wysokosciomierza
|
|  Copyright (C), CAS LODZ POLAND.
|  TEL: 42' 86 58 12, 42' 87 80 44 FAX/TEL: 42' 84 48 40
|
**********************************************************************)
(*.F+ *)

IMPLEMENTATION MODULE AltInterface;

  FROM CommonTypes  IMPORT
     NilValI;

  FROM MathLib0  IMPORT
    entier;
    
  FROM MANAGER IMPORT
    Assert;
    
  TYPE
    Digit =
      [ 0 .. 7 ];
  CONST
    press0Off  = 1013.25;
    pressConst = 996.0 / (1050.0-press0Off);
    
  VAR
    ALT_Conver_Tab  : ARRAY BOOLEAN, Digit OF Digit;
    ALT_Conver_TabC : ARRAY BOOLEAN, Digit OF Digit;
    refPress        : REAL;

  PROCEDURE SetPressure
            (    press : REAL);
  BEGIN
    refPress := press;
  END SetPressure;
  
  PROCEDURE ALTConvert
            (    alt : BITSET ) : INTEGER;

  VAR
    ALT      : CARDINAL;
    current  : BOOLEAN;
    currDig  : INTEGER;
    forCount : CARDINAL;
    pos      : CARDINAL;
    resunt   : INTEGER;
    
  BEGIN (* ALTConvert *)
    ALT := INTEGER( ( alt/{0..15} ) * {0..9} );
    IF ALT = 0  THEN
      RETURN NilValI;
    END;
    pos := 200H;
    resunt := 0;
    current  := FALSE;
    FOR forCount := 0 TO 2 DO
      resunt := resunt * 8;
      currDig := ALT_Conver_Tab[ current, ALT DIV pos];
      resunt := resunt + currDig;
      ALT := ALT MOD pos;
      pos := pos DIV 8;
      current := ODD(currDig);
    END (* for forCount *);
    resunt := resunt * 5 + INTEGER(ALT_Conver_TabC[current, ALT]) - 12;
    IF  (resunt > 300) OR ( resunt < -300) THEN
      (* Assert(FALSE); *)
      RETURN NilValI;
    END;
    resunt := 100*resunt+entier( (refPress-press0Off)*pressConst );
    RETURN resunt
  END ALTConvert;
BEGIN
  SetPressure(press0Off);
  ALT_Conver_Tab[FALSE, 0] := 0;
  ALT_Conver_Tab[FALSE, 1] := 1;
  ALT_Conver_Tab[FALSE, 3] := 2;
  ALT_Conver_Tab[FALSE, 2] := 3;
  ALT_Conver_Tab[FALSE, 6] := 4;
  ALT_Conver_Tab[FALSE, 7] := 5;
  ALT_Conver_Tab[FALSE, 5] := 6;
  ALT_Conver_Tab[FALSE, 4] := 7;
  ALT_Conver_Tab[TRUE, 4] := 0;
  ALT_Conver_Tab[TRUE, 5] := 1;
  ALT_Conver_Tab[TRUE, 7] := 2;
  ALT_Conver_Tab[TRUE, 6] := 3;
  ALT_Conver_Tab[TRUE, 2] := 4;
  ALT_Conver_Tab[TRUE, 3] := 5;
  ALT_Conver_Tab[TRUE, 1] := 6;
  ALT_Conver_Tab[TRUE, 0] := 7;
  ALT_Conver_TabC[FALSE, 1] := 0;
  ALT_Conver_TabC[FALSE, 3] := 1;
  ALT_Conver_TabC[FALSE, 2] := 2;
  ALT_Conver_TabC[FALSE, 6] := 3;
  ALT_Conver_TabC[FALSE, 4] := 4;
  ALT_Conver_TabC[TRUE, 4] := 0;
  ALT_Conver_TabC[TRUE, 6] := 1;
  ALT_Conver_TabC[TRUE, 2] := 2;
  ALT_Conver_TabC[TRUE, 3] := 3;
  ALT_Conver_TabC[TRUE, 1] := 4;
END AltInterface.
