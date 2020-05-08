(*.F- *)
(**********************************************************************
|  Title   : Wyliczanie namiaru na podstawie sin i cos kata
|  Author  : M.Postol
|  System  : LOGITECH MODULA-2/86
|  History :
|    12-12-96: Created
|
|  Copyright (C), CAS LODZ POLAND.
|  TEL: 42' 862 547, 42' 87 80 44 FAX/TEL: 42' 84 48 40
|
**********************************************************************)
(*.F+ *)
IMPLEMENTATION MODULE ADFAngle;

  FROM MathLib0 IMPORT
    arctan, real;

  FROM SpecConv IMPORT
    entierCheck;

  FROM CommonTypes  IMPORT
    SigNilVal;
    
  CONST
    Pi = 3.14159265358979323846264338327;


  PROCEDURE GetADFAngle
            (    ADFSin,
                 ADFCos : INTEGER ) : INTEGER;

  VAR
    Angle  : REAL;
    AngleI : INTEGER;
    ok     : BOOLEAN;

  BEGIN
    IF (ADFSin = SigNilVal) OR ( ADFCos = SigNilVal) THEN
      RETURN SigNilVal;
    END;
    IF ABS( ADFSin ) < ABS( ADFCos )
    THEN
      Angle := arctan( real( ADFSin ) / real( ADFCos ) );
      IF ADFCos < 0
      THEN
        IF ADFSin >= 0
        THEN
          Angle := Pi + Angle
        ELSE
          Angle := -Pi + Angle;
        END (* if ADFSin *);
      END (* if ADFCos *);
    ELSE
      Angle := Pi / 2.0 + arctan( real( ADFCos ) / real( ADFSin ) );
      IF ( ADFSin < 0 )
      THEN
        Angle := -Pi + Angle;
      END (* if *)
    END (* if ABS *);
    Angle := 180.0 * Angle / Pi;
    ok := entierCheck( Angle * 100.0, AngleI );
    RETURN AngleI;
  END GetADFAngle;

BEGIN
END ADFAngle.
