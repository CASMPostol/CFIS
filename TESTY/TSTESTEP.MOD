MODULE TSTestEpson;

FROM TSDrawEpson IMPORT
  MaxX, MaxY, Line, Open, Close, Out, DrawText;
FROM Lib IMPORT
  Intr, Delay, FatalError;
FROM SYSTEM IMPORT
  Registers;

CONST
	PrnPort = 0; (* LPT1 *)


PROCEDURE InitPort;
VAR
  r : Registers;
BEGIN
  r.AX := 100H;
  r.DX := PrnPort;
  Intr( r, 17H );
END InitPort;

PROCEDURE CheckPort():BOOLEAN;
VAR
  s : BITSET;
  r : Registers;
BEGIN
  r.AX := 200H;
  r.DX := PrnPort ;
  Intr( r, 17H );
  s := BITSET( r.AX );
  IF NOT( 14 IN s ) THEN
    FatalError( "Printer not attached" );
  END;
  IF 8 IN s THEN
    FatalError( 'Time out' );
  END;
  IF 11 IN s THEN
    FatalError( 'IO error' );
  END;
  IF NOT(12 IN s) THEN
    FatalError( 'Printer off line' );
  END;
  IF 13 IN s THEN
    FatalError( 'Out of paper' );
  END;
  RETURN 15 IN s; (* not busy *)
END CheckPort;

PROCEDURE WritePrn( c : CHAR );
VAR
  r : Registers;
BEGIN
  WHILE NOT CheckPort() DO
    Delay( 1000 );
  END;
  r.AX := ORD( c );
  r.DX := PrnPort ;
  Intr( r, 17H );
END WritePrn;

(*
PROCEDURE Write( c : CHAR );
BEGIN
  SETREG( DX, c );
  SETREG( AX, 500H );
(*  CODE( 060H (* pusha *));*)
  SWI( 21H );
(*  CODE( 061H (* popa *));*)
END Write;
*)

PROCEDURE Pat( i : CARDINAL ) : BITSET;
BEGIN
  CASE i MOD 5 OF
    0 : RETURN {0..3, 8..11};
  | 1 : RETURN {0,1, 4,5, 8,9, 12,13};
  | 2 : RETURN {0..7, 11, 12 };
  | 3 : RETURN {0..15};
  | 4 : RETURN {0, 2, 4, 6, 8, 10, 12, 14};
  END;
END Pat;

VAR
  i, kx, ky : CARDINAL;
BEGIN
  InitPort;
  Open;
  kx := MaxX() DIV 20;
  ky := MaxY() DIV 20;
(*
  FOR i := 0 TO 20 DO
    Line( 0, 0, kx*i, MaxY(), {0..15} );
  END;
  FOR i := 0 TO 20 DO
    Line( MaxX(), 0, 0, ky*i, {0..15} );
  END;
*)
  FOR i := 0 TO 20 DO
    Line( i*kx, 0, 0, (20-i)*ky, Pat(i));
  END;
  FOR i := 0 TO 20 DO
    Line( i*kx, 0, MaxX(), i*ky, Pat(i));
  END;
  ky := MaxY() DIV 50;
  FOR i := 0 TO 50 DO
    Line( 0, MaxY()-i*ky, MaxX(), MaxY()-(50-i)*ky, {0..15} );
  END;
  DrawText( 'Ala ma kota', MaxX() DIV 2, MaxY() DIV 2 );
  Out( WritePrn );
  Close;
  FatalError( "Terminated normaly" );
END TSTestEpson.
