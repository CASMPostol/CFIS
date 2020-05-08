MODULE TestEpson;

FROM DrawEpson IMPORT
  MaxX, MaxY, Line, Open, Close, Out, DrawText, SetTextMode, mtMode,
  InitPort, WrProc;
FROM Terminal IMPORT
  WriteString, Write, WriteLn;
FROM Timer IMPORT
  Wait, TInOneSecond;
FROM MANAGER IMPORT
  Release;
FROM RTSMain IMPORT
  Terminate, Status;

CONST
	PrnPort = 0; (* LPT1 *)



PROCEDURE FatalError( s : ARRAY OF CHAR );
BEGIN
  WriteString( s );
  Terminate( Stopped );
END FatalError;

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
  mtm       : mtMode;
BEGIN
  InitPort;
  Open;

  kx := MaxX() DIV 20;
  ky := MaxY() DIV 20;
  FOR i := 0 TO 20 DO
    Line( i*kx, 0, 0, (20-i)*ky, Pat(i));
    Write('.');
  END;
  WriteLn;
  FOR i := 0 TO 20 DO
    Line( i*kx, 0, MaxX(), i*ky, Pat(i));
    Write('*');
  END;
  WriteLn;
  ky := MaxY() DIV 50;
  FOR i := 0 TO 50 DO
    Line( 0, MaxY()-i*ky, MaxX(), MaxY()-(50-i)*ky, {0..15} );
    Write('#');
  END;
  WriteLn;

  FOR i := 0 TO 20 DO
    SetTextMode( VAL( mtMode, i MOD (ORD(MAX(mtMode))+1)));
    DrawText( 'Ala ma kota', MaxX() DIV 2, MaxY() DIV 2 - 80+i*8 );
    Write('T');
  END;
  WriteLn;
  IF Out( WrProc ) THEN
  END;
  Close;
  FatalError( "Terminated normaly" );
END TestEpson.

