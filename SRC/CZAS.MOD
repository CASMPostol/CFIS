IMPLEMENTATION MODULE Czas;

IMPORT
  Graphics;
FROM Graphics IMPORT
  MaxHor;
FROM Timer IMPORT
  Wait, TInOneSecond;
FROM GrafTypes IMPORT
  BLACK, LT_GREEN, RECT;
FROM MANAGER IMPORT
  STARTPROCESS;
FROM StdIO IMPORT
  sprintf;
FROM MMMouse IMPORT
  HideConditionally, ShowCursor;
FROM SYSTEM IMPORT
  OUTBYTE, INBYTE, SETREG, GETREG, AX, CX, DX, SWI, DISABLE, ENABLE;
FROM RTSMain IMPORT
  InstallTermProc;
IMPORT
  SYSTEM, CommonTypes;

  PROCEDURE BCD( VAR a : CARDINAL );
  BEGIN
    a := a MOD 16 + (a DIV 16)*10;
  END BCD;


MODULE BezPrzerwan[0];
FROM SYSTEM IMPORT
  OUTBYTE, INBYTE, SETREG, GETREG, AX, CX, DX, SWI, DISABLE, ENABLE;
IMPORT
  Graphics, LT_GREEN, HideConditionally, ShowCursor, RECT, BLACK, BCD ;
FROM Graphics IMPORT
  GetBank, SetBank, _WrStrXY, MaxHor;
EXPORT
  Write, StringRect;


VAR
  StringRect : RECT;

PROCEDURE Write( VAR s : ARRAY OF CHAR );
VAR
  p : CARDINAL;
  h : BOOLEAN;
BEGIN
  h := HideConditionally( StringRect );
  p := GetBank();
  _WrStrXY( s, StringRect.left, StringRect.top, LT_GREEN, 0 );
  SetBank(p);
  IF h THEN
    ShowCursor;
  END;
END Write;


END BezPrzerwan;

PROCEDURE WriteTime;
VAR
  s : ARRAY[0..12] OF CHAR;
  t : RECORD
       h, m, s : CARDINAL;
  END;


BEGIN
  StringRect.left := MaxHor()-64;
  StringRect.right := MaxHor();
  StringRect.top := 0;
  StringRect.bottom := 16;
  LOOP
    Godzina( t.h, t.m, t.s );
    sprintf( s, "%2d:%02d:%02d", t );
    Write( s );
    Wait( TInOneSecond() );
  END;
END WriteTime;


PROCEDURE Godzina( VAR h, m, s : CARDINAL );
  BEGIN
    DISABLE;
    OUTBYTE( 70h, 0 );
    INBYTE( 71h, s );
    OUTBYTE( 70h, 2 );
    INBYTE( 71h, m );
    OUTBYTE( 70h, 4 );
    INBYTE( 71h, h );
    BCD( h );
    BCD( m );
    BCD( s );
    ENABLE;
  END Godzina;

PROCEDURE Data( VAR Y, M, D : CARDINAL );
  BEGIN
    DISABLE;
    OUTBYTE( 70h, 7 );
    INBYTE( 71h, D );
    OUTBYTE( 70h, 8 );
    INBYTE( 71h, M );
    OUTBYTE( 70h, 9 );
    INBYTE( 71h, Y );
    BCD( Y );
    BCD( M );
    BCD( D );
    IF Y < 95 THEN
      INC( Y, 2000 );
    ELSE
      INC( Y, 1900 );
    END;
    ENABLE;
  END Data;

PROCEDURE SetTime( h,m,s : CARDINAL );
  BEGIN
    SETREG( DX, s*100H );
    SETREG( CX, h*100H+m);
    SETREG( AX, 2d00h );
    SWI( 21h );
  END SetTime;

PROCEDURE SetDate( Y,M,D : CARDINAL );
  BEGIN
    SETREG( DX, M*100H+D );
    SETREG( CX, Y );
    SETREG( AX, 02b00h );
    SWI( 21h );
  END SetDate;

PROCEDURE Terminator; (* bo czas systemowy jest tymczasem nieaktualizowany *)
VAR
  s, m, h, y,M,d : CARDINAL;
BEGIN
  Godzina( h,m,s);
  SetTime( h,m,s);
  Data( y,M,d);
  SetDate( y,M,d);
END Terminator;

PROCEDURE GetTimeAndDate( VAR Tm : CommonTypes.TimeAndDate );
  VAR
    dummy : CARDINAL;
  BEGIN
    Godzina( Tm.t.h, Tm.t.m, dummy );
    Data( Tm.d.y, Tm.d.m, Tm.d.d );
  END GetTimeAndDate;


BEGIN
  InstallTermProc( Terminator );
  STARTPROCESS( WriteTime, 700H, 0 );
END Czas.
