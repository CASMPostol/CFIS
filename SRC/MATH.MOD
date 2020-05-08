IMPLEMENTATION MODULE Math;

FROM MathLib0 IMPORT
  sqrt, arctan;

PROCEDURE ACos( x : REAL ) : REAL;
VAR
  tg, k : REAL;
BEGIN
  IF x = 0.0 THEN
    RETURN M_PI_2;
  END;
  tg := sqrt( 1.0 - Sqr( x ))/ABS(x);
  k := arctan( tg );
  IF x > 0.0 THEN
    RETURN k;
  ELSE
    RETURN M_PI-k;
  END;
END ACos;

PROCEDURE Sqr( x : REAL ) : REAL;
BEGIN
  RETURN x*x;
END Sqr;

END Math.
