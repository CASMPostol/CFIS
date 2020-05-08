MODULE T;

FROM RealConversions IMPORT
  RealToString;

VAR
  r : REAL;
  str : ARRAY[0..100] OF CHAR;
  ok : BOOLEAN;

BEGIN
  r := -0.01;
  RealToString( r, 1, 1, str, ok );
END T.
