MODULE TW;

IMPORT
  MANAGER, Timer, Wykres, GrafTypes, MathLib0;


VAR
  x, y : ARRAY[0..360] OF INTEGER;

  PROCEDURE Init(  );
    VAR
      i : INTEGER;
    BEGIN
      x[0] := HIGH(x);
      y[0] := HIGH(y);
      FOR i := 1 TO HIGH(x) DO
        x[i] := (i-1);
        y[i] := MathLib0.entier( MathLib0.sin( MathLib0.real( x[i] ) * 2.0 * 3.1415926/ 360.0 ) * 100.0 );
      END;
    END Init;


VAR
  R : GrafTypes.RECT;
BEGIN
  Init;
  GrafTypes.AssignRect( R, 100, 100, 700, 500 );
  Wykres.PokazWykresNS( x, y, 1, 10000, 0, 360, R, -200.0, +150.0, GrafTypes.LT_RED );
END TW.
