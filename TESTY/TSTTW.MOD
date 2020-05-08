MODULE TW;


FROM MathLib0 IMPORT
  sin, entier;
FROM Graphics IMPORT
  MaxVer, MaxHor;
FROM HiLevGraf IMPORT
  MoveTo, LineTo, FrameRect;
FROM GrafTypes IMPORT
  RECT, RED, YELLOW, WHITE, LT_RED, BLUE, LT_BLUE, LT_GREEN;
FROM Wykres IMPORT
  PokazWykres, Opis;
FROM Filtr IMPORT
  MaxErr;
FROM Random IMPORT
  Randomize, RandomInt;
FROM RTSMain IMPORT
  Terminate, Status;
FROM Terminal IMPORT
  Read, KeyPressed;
FROM SYSTEM IMPORT SIZE;


CONST
  scY = 1000.0;
  PI_2= 6.283185307;
VAR
  x, y1, y2 : ARRAY[0..1024] OF INTEGER;
  xf, yf    : ARRAY[0..79] OF INTEGER;
  r, rh: RECT;
  char : CHAR;
  mn   : CARDINAL;
  
  
  PROCEDURE sqr(x: REAL) : REAL;
  BEGIN
    RETURN x*x;
  END sqr;
  
  PROCEDURE PrzygotujDane;
  VAR
    i : INTEGER;
  BEGIN
    Randomize;
    x[0] := HIGH(x);
    y1[0] := x[0];
    y2[0] := x[0];
    FOR i := 1 TO HIGH(x) DO
      x[i] := HIGH(x)+1-i;
(*      x[i] := i;*)
      y1[i] := entier( scY*sqr( sin( FLOAT(i)*PI_2/FLOAT(HIGH(x)))));
      y2[i] := entier( scY*sin( FLOAT(i)*PI_2/FLOAT(HIGH(x))));
      
      INC( y1[i], + RandomInt( 600 ) - 300 );
      INC( y2[i], + RandomInt( 600 ) - 300 );
    END;
  END PrzygotujDane;
(*
  PROCEDURE Read( VAR ch : CHAR );
  VAR
    r : Registers;
  BEGIN
    r.AX := 0;
    Intr( 16H, r );
    ch := r.AL;
  END Read;
*)
  PROCEDURE Ramka;
  BEGIN
    MoveTo( r.left, r.top );
    LineTo( r.right, r.top, WHITE );
    LineTo( r.right, r.bottom, WHITE );
    LineTo( r.left, r.bottom, WHITE );
    LineTo( r.left, r.top, WHITE );
  END Ramka;

VAR
  MY : ARRAY[0..2] OF REAL;
  MX : ARRAY[0..9] OF REAL;
  
  PROCEDURE PrzygotujOpis;
  VAR
   i : CARDINAL;
  BEGIN
    MY[0] := 100.0;
    MY[1] := 200.0;
    MY[2] := 500.0;
    FOR i := 0 TO 9 DO
      MX[i] := FLOAT(i)*100.0;
    END;
  END PrzygotujOpis;
  
  
BEGIN
  PrzygotujDane;
  r.left := 1;
  r.top := 1;
  r.right := MaxHor()-2;
  r.bottom := MaxVer()-2;
(*
  REPEAT
    Ramka;
    PokazWykres(  x, y1,
		  0, 07FFFH,
		  0, HIGH(x),
		  r ,
		  scY,
		  YELLOW );
    PokazWykres(  x, y2,
		  0, 07FFFH,
		  0, HIGH(x),
		  r,
		  scY,
		  RED );
    Read(char);
    INC( r.top, 31 );
    INC( r.left, 47 );
    DEC( r.bottom, 23 );
    DEC( r.right, 48 );
  UNTIL (char = 33c) OR (r.left >= r.right) OR (r.top >= r.bottom);
  r.left := 0;
  r.top := 0;
  r.right := MaxHor()-1;
  r.bottom := MaxVer()-1;
  mn := 0;
  REPEAT
    Ramka;
    PokazWykres(  x, y1,
		  0, 07FFFH,
		  mn, HIGH(x)-mn,
		  r ,
		  scY/2.0,
		  YELLOW );
    PokazWykres(  x, y2,
		  0, 07FFFH,
		  mn, HIGH(x)-mn,
		  r,
		  scY/2.0,
		  RED );
    Read(char);
    INC( mn, 57 );
  UNTIL (char = 33c) OR (mn >= HIGH(x) DIV 2);
*)
  PrzygotujOpis;
  Opis( r, 0.0, FLOAT(HIGH(x)), 0.0, scY, MX, SIZE(MX) DIV 2,
                                          MY, SIZE(MY) DIV 2,
                                          BLUE, LT_BLUE );
  PokazWykres(  x, y1,
		0, 200,
		0, HIGH(x),
		r ,
		scY+300.0,
		YELLOW );
  PokazWykres(  x, y1,
		200, 07FFFH,
		0, HIGH(x),
		r ,
		scY+300.0,
		LT_RED );
  xf[0] := 0;
  yf[0] := 0;
  MaxErr( 500, 0, HIGH( x ), x, y1, xf, yf );
  PokazWykres(  xf, yf,
		0, 7FFFH,
		0, HIGH(xf),
		r ,
		scY+300.0,
		LT_GREEN );
  Read(char);
(*
  mn := 0;
  rh := r;
  REPEAT
    FrameRect( r, CHR( 255-15(*+mn*) ));
    mn := (mn+1) MOD 16;
    INC( r.top );
    INC( r.left );
    DEC( r.right );
    DEC( r.bottom );
    IF (r.top >= r.bottom) OR (r.left >= r.right) THEN
      r := rh;
    END;
  UNTIL KeyPressed();
*)
  Terminate( Stopped );
END TW.
