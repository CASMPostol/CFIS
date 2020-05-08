MODULE ST;


FROM MathLib0 IMPORT
  sin, entier;
FROM Graphics IMPORT
  MaxVer, MaxHor;
FROM GrafTypes IMPORT
  RECT, RED, YELLOW, WHITE, GREY, POINT;
FROM HiLevGraf IMPORT
  MoveTo, LineTo, HDIB, LoadDIB, CloseDIB, DIBWidth, DIBHeight;
FROM Slupek IMPORT
  Update, Nothing, Dispose, WykresSlupkowy, WHandle;
FROM Timer IMPORT
  Wait, TInOneSecond;
FROM RTSMain IMPORT
  Terminate, Status;
FROM Terminal IMPORT
  Read, KeyPressed;
IMPORT
  Czas;
(*
IMPORT
  DebugPMD;
*)

CONST
  scY = 1000.0;
  PI_2= 6.283185307;
VAR
  x, y1, y2 : ARRAY[0..1024] OF INTEGER;
  r    : RECT;
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
    x[0] := HIGH(x);
    y1[0] := x[0];
    y2[0] := x[0];
    FOR i := 1 TO HIGH(x) DO
      x[i] := i;
      y1[i] := entier( scY*sqr( sin( FLOAT(i)*PI_2/FLOAT(HIGH(x)))));
      y2[i] := entier( scY*sin( FLOAT(i)*PI_2/FLOAT(HIGH(x))));
    END;
  END PrzygotujDane;

VAR
  pf, df : INTEGER;
  PROCEDURE PierwszaFunkcja(): INTEGER;
  BEGIN
    pf := pf MOD HIGH( y1 ) +1;
    RETURN y1[pf];
  END PierwszaFunkcja;

  PROCEDURE DrugaFunkcja(): INTEGER;
  BEGIN
    df := df MOD HIGH( y2 ) +1;
    RETURN (y2[pf]+1000) DIV 2;
  END DrugaFunkcja;

  PROCEDURE Ramka( VAR r : RECT; Color : CHAR );
  BEGIN
    MoveTo( r.left-1, r.top-1 );
    LineTo( r.right+1, r.top-1, Color );
    LineTo( r.right+1, r.bottom+1, Color );
    LineTo( r.left-1, r.bottom+1, Color );
    LineTo( r.left-1, r.top-1, Color );
  END Ramka;

VAR
  dib : HDIB;
  w1, w2   : WHandle;
  p : POINT;
  rdib : RECT;
BEGIN
  pf := 0;
  df := 0;
  PrzygotujDane;
  dib := LoadDIB( "Tlo2.dib" );
  WITH rdib DO
    left := 0;
    top := 0;
    right := DIBWidth(dib)-1;
    bottom := DIBHeight(dib)-1;
  END;
  r.left := MaxHor() DIV 3;
  r.top := MaxVer() DIV 3;
  r.right := r.left+DIBWidth(dib);
  r.bottom := r.top+DIBHeight(dib);
  p.x := r.left;
  p.y := r.top;
  (*
  REPEAT
    Ramka( r, CHR(WHITE) );
    INC(r.left);
  UNTIL r.left+88>=r.right;
  *)
  w1 := WykresSlupkowy( PierwszaFunkcja,
  		       DrugaFunkcja,
  		       0,
  		       1000,
  		       250,
  		       750,
  		       dib,
  		       rdib,
  		       p );
  REPEAT
    Ramka( r, CHR(WHITE) );
    INC(r.left);
  UNTIL r.left+88>=r.right;
  r.left := MaxHor() DIV 3+300;
  r.top := MaxVer() DIV 3;
  r.right := r.left+DIBWidth(dib);
  r.bottom := r.top+DIBHeight(dib);
  p.x := r.left;
  p.y := r.top;
  w2 := WykresSlupkowy( PierwszaFunkcja,
  		       Nothing,
  		       0,
  		       1000,
  		       250,
  		       750,
  		       dib,
  		       rdib,
  		       p );
  REPEAT
    Ramka( r, CHR(WHITE) );
    INC(r.left);
  UNTIL r.left+90>=r.right;
  REPEAT
(*    Wait( TInOneSecond() DIV 5);*)
    Wait(1);
    Update( w1 );
    Update( w2 );
    IF KeyPressed() THEN
      Read(char);
    END;
  UNTIL char = 33C;;
  Dispose( w1 );
  Dispose( w2 );
  CloseDIB( dib );
  Terminate( Stopped );
END ST.
