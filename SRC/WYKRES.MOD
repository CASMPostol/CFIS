(*.F- *)
(**********************************************************************
|  Title   : Wykonywanie wykresow
|  Author  : M.Morawski
|  System  : LOGITECH MODULA-2/86
|  History :
|    Nowa procedura pozwalajaca wykonywac wykresy Log
|    MM: 11-25-96 04:23pm
|            W procedurze liczacej logarytmu dolozylem ABS
|    28-01-97: M.Postol
|      zwiekszylem dokladnosc wyswietlania skali y wykresu
|    05-31-97 02:11pm: MM
|      Dodano pareametr czy w opisie zawijac wartosc kata czy nie
|
|  Copyright (C), CAS LODZ POLAND.
|  TEL: 42' 862 547, 42' 87 80 44 FAX/TEL: 42' 84 48 40
|
**********************************************************************)
(*.F+ *)
IMPLEMENTATION MODULE Wykres;



FROM SYSTEM IMPORT
  BYTE, ADR, WORD;
FROM HiLevGraf IMPORT
  Clip, NoClip, MoveTo, LineTo, Line, FrameRect, FillRect, SetLineStyle,
  Point, WrStrXY;
FROM GrafTypes IMPORT
  RECT;
FROM MMMouse IMPORT
  HideConditionally, ShowCursor;
FROM StdIO IMPORT
  sprintf;
FROM MathLib0 IMPORT
  real, entier, ln;
FROM XMSTable IMPORT
  XmsTable, GetElem;
FROM CommonTypes IMPORT
  SigNilVal, DisNilVal;



PROCEDURE Log10( x : REAL ) : REAL;
BEGIN
  RETURN ln(ABS(x))/2.302585093;
END Log10;

PROCEDURE Draw( VAR y	   : ARRAY OF INTEGER;
		           xFirst,
		           xLast   : INTEGER;
		           Rect	   : RECT;
		           yMax    : REAL;
		           yMin    : REAL;
		           Color   : CARDINAL;
		           Log     : BOOLEAN );


  PROCEDURE SkalY( idx : CARDINAL ) : INTEGER;
  VAR
    r : REAL;
    h : INTEGER;
    c : INTEGER;
  BEGIN
    h := Rect.bottom - Rect.top;
    IF Log  THEN
      r := Log10(real(y[idx])) - Log10(yMin);
      r := FLOAT(h)/( Log10(yMax) - Log10(yMin)) * r;
    ELSE
      r := real(y[idx]) - yMin;
      r := FLOAT(h)/( yMax - yMin) * r;
    END;
    IF r > 1000.0 THEN
      r := 1000.0
    ELSIF r < -1000.0 THEN
      r := -1000.0
    END;
    c := Rect.bottom - entier(r);
    RETURN c;
  END SkalY;

VAR
  idx, ypos : INTEGER;
  nilfound : BOOLEAN;
BEGIN
  IF xFirst < 1 THEN
    xFirst := 1;
  END;
  IF xLast > y[0] THEN
    xLast := y[0];
  END;
  Clip( Rect );
  nilfound := TRUE;
  FOR idx := xFirst TO xLast DO
    IF nilfound THEN
      IF y[idx] # SigNilVal THEN
        ypos := SkalY(idx);
        MoveTo(idx,ypos );
        Point(idx, ypos, CHR(Color));
        nilfound := FALSE;
      END;
    END;
    IF y[idx] # SigNilVal THEN
      LineTo( idx, SkalY(idx), CHR(Color));
    ELSE
      nilfound := TRUE;
    END;
  END;
  NoClip;
END Draw;

PROCEDURE PokazWykres( VAR x       : ARRAY OF INTEGER;
                       VAR y       : ARRAY OF INTEGER;
                           xFirst,
                           xLast   : INTEGER;
                           possMinX,
                           possMaxX: INTEGER;
                           Rect    : RECT;
                           yLimit  : REAL;
                           Color   : CARDINAL );


  PROCEDURE SkalY( idx : CARDINAL ) : INTEGER;
  VAR
    r : REAL;
    h : INTEGER;
    c : INTEGER;
  BEGIN
    r := real(y[idx])+yLimit;
    h := Rect.bottom-Rect.top;
    r := FLOAT(h)/(yLimit+yLimit)*r;
    c := Rect.bottom-entier(r);
    RETURN c;
  END SkalY;

  PROCEDURE SkalX( idx : CARDINAL ) : INTEGER;
  VAR
    r : REAL;
    w : INTEGER;
    c : INTEGER;
  BEGIN
    r := real(x[idx])-FLOAT(possMinX);
    w := Rect.right-Rect.left;
    r := real(w)/real(possMaxX-possMinX)*r;
    c := entier(r)+Rect.left;
    RETURN c;
  END SkalX;

VAR
  idx : INTEGER;
BEGIN
  IF xFirst < 1 THEN
    xFirst := 1;
  END;
  IF xLast > x[0] THEN
    xLast := x[0];
  END;
  Clip( Rect );
  MoveTo( SkalX(xFirst), SkalY(xFirst));
  FOR idx := xFirst TO xLast DO
    LineTo( SkalX(idx), SkalY(idx), CHR(Color));
  END;
  NoClip;
END PokazWykres;


PROCEDURE PokazWykres1(
 		       VAR y	   : ARRAY OF INTEGER;
		           xFirst,
		           xLast   : INTEGER;
		           Rect	   : RECT;
		           yLimit  : REAL;
		           Color   : CARDINAL );


  PROCEDURE SkalY( idx : CARDINAL ) : INTEGER;
  VAR
    r : REAL;
    h : INTEGER;
    c : INTEGER;
  BEGIN
    r := real(y[idx])+yLimit;
    h := Rect.bottom-Rect.top;
    r := FLOAT(h)/(yLimit+yLimit)*r;
    IF r>1000.0 THEN
      r:=1000.0
    ELSIF r<-1000.0 THEN
      r:=-1000.0
    END;
    c := Rect.bottom-entier(r);
    RETURN c;
  END SkalY;

VAR
  idx, ypos : INTEGER;
  nilfound : BOOLEAN;
BEGIN
  IF xFirst < 1 THEN
    xFirst := 1;
  END;
  IF xLast > y[0] THEN
    xLast := y[0];
  END;
  Clip( Rect );
  nilfound := TRUE;
  FOR idx := xFirst TO xLast DO
    IF nilfound THEN
      IF y[idx] # SigNilVal THEN
        ypos := SkalY(idx);
        MoveTo(idx,ypos );
        Point(idx,ypos,CHR(Color));
        nilfound := FALSE;
      END;
    END;
    IF y[idx] # SigNilVal THEN
      LineTo( idx, SkalY(idx), CHR(Color));
    ELSE
      nilfound := TRUE;
    END;
  END;
  NoClip;
END PokazWykres1;


PROCEDURE Opis(     Rect       : RECT;
                    minX, maxX : REAL;
                    minY, maxY : REAL;
                VAR PosMarkerX : ARRAY OF REAL;
                    NrX        : CARDINAL;
                VAR PosMarkerY : ARRAY OF REAL;
                    NrY        : CARDINAL;
                    DlaKata    : BOOLEAN;
                    BackColor  : CARDINAL;
                    MarkColor  : CARDINAL;
                    Fill       : BOOLEAN );
BEGIN
  OpisLog( Rect,
           minX, maxX, minY, maxY,
           PosMarkerX, NrX,
           PosMarkerY, NrY,
           DlaKata,
           BackColor, MarkColor,
           FALSE, FALSE,
           Fill );
END Opis;


PROCEDURE OpisLog(     Rect       : RECT;
                       minX, maxX : REAL;
                       minY, maxY : REAL;
                   VAR PosMarkerX : ARRAY OF REAL;
                       NrX        : CARDINAL;
                   VAR PosMarkerY : ARRAY OF REAL;
                       NrY        : CARDINAL;
                       DlaKata    : BOOLEAN;
                       BackColor  : CARDINAL;
                       MarkColor  : CARDINAL;
                       LogX, LogY : BOOLEAN;
                       Fill       : BOOLEAN );
CONST
  Pat = {0,8};
  Pat0 = {0,1,8,9};


  PROCEDURE AutoFormat( liczba : REAL; VAR str : ARRAY OF CHAR );
    VAR
      dec : INTEGER;
    BEGIN
      str[0] := 0C;
      liczba := ABS( liczba );
      IF liczba = 0.0 THEN
        RETURN;
      END;
      dec := entier(Log10( liczba ));
      IF dec > 0 THEN
        dec := 0;
      ELSE
        dec := -dec+2;
      END;
      sprintf( str, "%%2.%dlf", dec );
    END AutoFormat;

  PROCEDURE LineV( r : REAL );
  VAR
    w : INTEGER;
    c : INTEGER;
    s, fmt : ARRAY[0..63] OF CHAR;
    r1 : REAL;
  BEGIN
    IF (minX=maxX) THEN
      RETURN;
    END;
    AutoFormat( maxX-minX, fmt );
    r1 := r;
    IF (DlaKata) THEN
      WHILE r1 >= 360.0 DO
        r1 := r1 - 360.0;
      END;
      WHILE r1 < 0.0 DO
        r1 := r1 + 360.0;
      END;
    END;
    sprintf( s, fmt, r1 );
    w := Rect.right-Rect.left;
    IF LogX THEN
(*      r := LogPos( r, minX, maxX );*)
      r := Log10(r)-Log10(minX);
      r := real(w)/(Log10(maxX)-Log10(minX))*r;
    ELSE
      r := r-minX;
      r := real(w)/(maxX-minX)*r;
    END;
    c := entier(r)+Rect.left;
    Line( c, Rect.top, c, Rect.bottom, CHR( MarkColor ) );
    INC( c );
    IF (c+8 > Rect.bottom) THEN
      DEC( c, 10 );
    END;
    WrStrXY( s, c, (Rect.top+Rect.bottom) DIV 2 +1,
             CHR( MarkColor ), CHR( BackColor ) );
  END LineV;

  PROCEDURE LineH( r : REAL );
  VAR
    h : INTEGER;
    c : INTEGER;
    s, fmt : ARRAY[0..63] OF CHAR;
  BEGIN
    IF (minY=maxY) THEN
      RETURN;
    END;
    AutoFormat( maxY-minY, fmt );
    sprintf( s, fmt, r );
    h := Rect.bottom-Rect.top;
    IF LogY THEN
(*      r := LogPos( r, minY, maxY );*)
      r := Log10(r)-Log10(minY);
      r := real(h)/(Log10(maxY)-Log10(minY))*r;
    ELSE
      r := r-minY;
      r := real(h)/(maxY-minY)*r;
    END;
    c := Rect.bottom-entier(r);
    Line( Rect.left, c, Rect.right, c, CHR( MarkColor ) );
    INC( c );
    IF (c+16 > Rect.bottom) THEN
      DEC( c, 18 );
    END;
    WrStrXY( s, Rect.left+1, c, CHR( MarkColor ), CHR( BackColor ) );
  END LineH;

VAR
  idx : CARDINAL;
  h   : BOOLEAN;
BEGIN
  Clip( Rect );
  h := HideConditionally( Rect );
  IF Fill THEN
    FillRect( Rect, CHR(BackColor) );
  END;
  SetLineStyle( Pat );
  IF (HIGH( PosMarkerX )+1)<NrX THEN
    NrX:=HIGH( PosMarkerX )+1;
  END;
  FOR idx := 1 TO NrX DO
    LineV( PosMarkerX[idx-1] );
  END;
  IF (HIGH( PosMarkerY )+1)<NrY THEN
    NrY:=HIGH( PosMarkerY )+1;
  END;
  FOR idx := 1 TO NrY DO
    LineH( PosMarkerY[idx-1] );
  END;
  (*
  SetLineStyle( Pat0 );
  IF NOT LogY AND (minY < 0.0) AND (maxY > 0.0) THEN
    LineH( 0.0 );
  END;
  *)
  SetLineStyle( {0..15} );
  DEC( Rect.left );
  DEC( Rect.top );
  INC( Rect.right );
  INC( Rect.bottom );
  FrameRect( Rect, CHR(MarkColor) );
  IF h THEN
    ShowCursor;
  END;
  NoClip;
END OpisLog;

PROCEDURE PokazWykresNS( VAR x       : ARRAY OF INTEGER;
                         VAR y       : ARRAY OF INTEGER;
                             xFirst,
                             xLast   : INTEGER;
                             possMinX,
                             possMaxX: INTEGER;
                             Rect    : RECT;
                             ymin    : REAL;
                             ymax    : REAL;
                             Color   : CARDINAL );
BEGIN
  PokazWykresNSLog( x, y, xFirst, xLast, possMinX, possMaxX, Rect, ymin, ymax, Color, FALSE, FALSE );
END PokazWykresNS;


PROCEDURE PokazWykresNSLog( VAR x       : ARRAY OF INTEGER;
                            VAR y       : ARRAY OF INTEGER;
                                xFirst,
                                xLast   : INTEGER;
                                possMinX,
                                possMaxX: INTEGER;
                                Rect    : RECT;
                                ymin    : REAL;
                                ymax    : REAL;
                                Color   : CARDINAL;
                                LogX,
                                LogY    : BOOLEAN );

  PROCEDURE SkalY( idx : CARDINAL ) : INTEGER;
  VAR
    r : REAL;
    h : INTEGER;
    c : INTEGER;
  BEGIN
    h := Rect.bottom-Rect.top;
    IF LogY THEN
(*      r := LogPos( real(y[idx]), ymin, ymax );*)
      r := Log10( real(y[idx]))-Log10(ymin);
      r := real(h)/(Log10(ymax)-Log10(ymin))*r;
    ELSE
      r := real(y[idx])-ymin;
      r := real(h)/(ymax-ymin)*r;
    END;
    c := Rect.bottom-entier(r);
    RETURN c;
  END SkalY;

  PROCEDURE SkalX( idx : CARDINAL ) : INTEGER;
  VAR
    r : REAL;
    w : INTEGER;
    c : INTEGER;
  BEGIN
    w := Rect.right-Rect.left;
    IF LogX THEN
(*      r := LogPos( real(y[idx]), real(possMinX), real(possMaxX) );*)
      r := Log10( real(x[idx]))-Log10(real(possMinX));
      r := real(w)/(Log10(real(possMaxX))-Log10(real(possMinX)))*r;
    ELSE
      r := real(x[idx])-real(possMinX);
      r := real(w)/(real(possMaxX)-real(possMinX))*r;
    END;
    c := entier(r)+Rect.left;
    RETURN c;
  END SkalX;

VAR
  idx : INTEGER;
  PoprzednieNarysowane : BOOLEAN;
  Przeskok : BOOLEAN; (* specjalnie dla przejscia -180..+180 *)

BEGIN
  IF xFirst < 1 THEN
    xFirst := 1;
  END;
  IF xLast > x[0] THEN
    xLast := x[0];
  END;
  Clip( Rect );
  PoprzednieNarysowane := FALSE;
  FOR idx := xFirst TO xLast DO
    IF idx = xFirst THEN
      Przeskok := FALSE;
    ELSE
      IF x[idx] > x[idx-1] THEN
        Przeskok := (x[idx-1] < -10000) & (x[idx] > 10000);
      ELSIF x[idx] < x[idx-1] THEN
        Przeskok := (x[idx] < -10000) & (x[idx-1] > 10000);
      ELSE
        Przeskok := FALSE;
      END;
    END;
    IF (y[idx] = MIN(INTEGER)) OR
       (x[idx] = MIN(INTEGER)) OR
       ( idx > y[0] )          OR
       Przeskok
    THEN
      PoprzednieNarysowane := FALSE;
    ELSE
      IF PoprzednieNarysowane THEN
        LineTo( SkalX(idx), SkalY(idx), CHR(Color));
      ELSE
        MoveTo( SkalX(idx), SkalY(idx));
      END;
      PoprzednieNarysowane := TRUE;
    END;
  END;
  NoClip;
END PokazWykresNSLog;


PROCEDURE LogPos( x : REAL; Start, End : REAL ) : REAL;
BEGIN
  Start := Log10( Start );
  End   := Log10( End );
  RETURN End*(Log10(x)-Start)/(End-Start);
END LogPos;

PROCEDURE LessInt( a, b : WORD ) : BOOLEAN;
  BEGIN
    RETURN INTEGER(a) < INTEGER(b);
  END LessInt;

PROCEDURE LessCard( a, b : WORD ) : BOOLEAN;
  BEGIN
    RETURN CARDINAL(a) < CARDINAL(b);
  END LessCard;

PROCEDURE Card2Real( a : WORD ) : REAL;
  BEGIN
    RETURN real(CARDINAL(a));
  END Card2Real;

PROCEDURE Int2Real( a : WORD ) : REAL;
  BEGIN
    RETURN real(INTEGER(a));
  END Int2Real;

TYPE
  Word2RealProc = PROCEDURE(WORD):REAL;
  LessWordProc  = PROCEDURE(WORD,WORD):BOOLEAN;

PROCEDURE PokazWykresZXms( x, y    : XmsTable;
                           OdlegloscANieKat : BOOLEAN;
                           xFirst,
                           xLast   : CARDINAL;
                           possMinX,
                           possMaxX: INTEGER;
                           Rect    : RECT;
                           ymin    : REAL;
                           ymax    : REAL;
                           Color   : CARDINAL;
                           LogX,
                           LogY    : BOOLEAN );


  VAR
    Word2Real  : Word2RealProc;
    LessWord   : LessWordProc;

  PROCEDURE GetX(idx:CARDINAL):WORD;
  BEGIN
    RETURN GetElem( x, idx );
  END GetX;

  PROCEDURE GetY(idx:CARDINAL):INTEGER;
  BEGIN
    RETURN INTEGER( GetElem( y, idx ));
  END GetY;

  PROCEDURE SkalY( idx : CARDINAL ) : INTEGER;
  VAR
    r : REAL;
    h : INTEGER;
    c : INTEGER;
  BEGIN
    h := Rect.bottom-Rect.top;
    IF LogY THEN
(*      r := LogPos( real(y[idx]), ymin, ymax );*)
      r := Log10( real(GetY(idx)))-Log10(ymin);
      r := real(h)/(Log10(ymax)-Log10(ymin))*r;
    ELSE
      r := real(GetY(idx))-ymin;
      r := real(h)/(ymax-ymin)*r;
    END;
    c := Rect.bottom-entier(r);
    RETURN c;
  END SkalY;

  PROCEDURE SkalX( idx : CARDINAL ) : INTEGER;
  VAR
    r : REAL;
    w : INTEGER;
    c : INTEGER;
  BEGIN
    w := Rect.right-Rect.left;
    IF LogX THEN
(*      r := LogPos( real(y[idx]), real(possMinX), real(possMaxX) );*)
      r := Log10( Word2Real(GetX(idx)))-Log10(real(possMinX));
      r := real(w)/(Log10(real(possMaxX))-Log10(real(possMinX)))*r;
    ELSE
      r := Word2Real(GetX(idx))-real(possMinX);
      r := real(w)/(real(possMaxX)-real(possMinX))*r;
    END;
    c := entier(r)+Rect.left;
    RETURN c;
  END SkalX;

VAR
  idx : CARDINAL;
  PoprzednieNarysowane : BOOLEAN;
  Przeskok : BOOLEAN; (* specjalnie dla przejscia -180..+180 *)


VAR
  y_idx_0 : CARDINAL;
  x_idx_1 : WORD;
  x_idx   : WORD;
  term : WORD;
BEGIN
  IF (OdlegloscANieKat) THEN
    LessWord := LessCard;
    Word2Real := Card2Real;
    term      := WORD(SigNilVal);
  ELSE
    LessWord := LessInt;
    Word2Real := Int2Real;
    term      := WORD(DisNilVal);
  END;
  y_idx_0 := CARDINAL(GetY(0));
  IF xFirst < 1 THEN
    xFirst := 1;
  END;
  IF xLast > CARDINAL(GetX(0)) THEN
    xLast := CARDINAL(GetX(0));
  END;
  Clip( Rect );
  PoprzednieNarysowane := FALSE;
  FOR idx := xFirst TO xLast DO
    x_idx_1 := GetX(idx-1);
    x_idx := GetX(idx);
    IF idx = xFirst THEN
      Przeskok := FALSE;
    ELSE
      IF x_idx > x_idx_1 THEN
        Przeskok := LessWord(x_idx_1,-10000) & LessWord(10000, x_idx_1);
      ELSIF x_idx < x_idx_1 THEN
        Przeskok := LessWord(x_idx, -10000) & LessWord( 10000,x_idx_1 );
      ELSE
        Przeskok := FALSE;
      END;
    END;
    IF (GetY(idx) = SigNilVal)    OR
       (x_idx     = term)         OR
       ( idx > y_idx_0 )          OR
       Przeskok
    THEN
      PoprzednieNarysowane := FALSE;
    ELSE
      IF PoprzednieNarysowane THEN
        LineTo( SkalX(idx), SkalY(idx), CHR(Color));
      ELSE
        MoveTo( SkalX(idx), SkalY(idx));
      END;
      PoprzednieNarysowane := TRUE;
    END;
  END;
  NoClip;
END PokazWykresZXms;


END Wykres.
