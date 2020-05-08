(*.F- *)
(**********************************************************************
|  Title   : Wykresy slupkowe
|  Author  : M.Morawski
|  System  : LOGITECH MODULA-2/86
|  History :
|    16-09-96: M.Postol
|      slupek nie zmienia palety
|
|  Copyright (C), CAS LODZ POLAND.
|  TEL: 42' 862 547, 42' 87 80 44 FAX/TEL: 42' 84 48 40
|
**********************************************************************)
(*.F+ *)
IMPLEMENTATION MODULE Slupek;

FROM GrafTypes IMPORT
  RED, GREEN, RECT, POINT, Intersection;
FROM HiLevGraf IMPORT
  ShowDIB, HDIB, FillRect, Clip, NoClip, DIBHeight, DIBWidth;
FROM Storage IMPORT
  ALLOCATE, DEALLOCATE;
FROM MathLib0 IMPORT
  real, entier;

TYPE
   WHandle = POINTER TO WDesc;
   WDesc = RECORD
     A, B   : PInt;
     pA, pB : INTEGER; (* poprzednie wartosci zmiennej *)
     dib    : HDIB;
     place  : RECT;
     redrawRECT : RECT;
     min    : INTEGER;
     max    : INTEGER;
     Alarm  : RECORD
       min, max : INTEGER;
     END;
     oba    : BOOLEAN;
     Poczatki : ARRAY[0..3] OF INTEGER;
   END;



PROCEDURE WykresSlupkowy(
		ZmiennaA	: PInt;
		ZmiennaB	: PInt;
		Min, Max	: INTEGER;
		minAlarm,
		maxAlarm	: INTEGER;
		Tlo		: HDIB;
		DibRECT         : RECT;
		ULCorner	: POINT ) : WHandle;
VAR
  h  : WHandle;
  sz : INTEGER;
BEGIN
  NEW( h );
  WITH h^ DO
    A := ZmiennaA;
    B := ZmiennaB;
    pA := Min;
    pB := Min;
    place.left  := ULCorner.x;
    place.top   := ULCorner.y;
    place.right := place.left+DibRECT.right-DibRECT.left;
    place.bottom:= place.top +DibRECT.bottom-DibRECT.top;
    redrawRECT  := DibRECT;
    dib := Tlo;
    max := Max;
    min := Min;
    Alarm.min := minAlarm;
    Alarm.max := maxAlarm;
    ShowDIB( Tlo, DibRECT, ULCorner, FALSE);
    oba := B # Nothing;
    sz := (place.right-place.left+1) DIV 7;
    IF oba THEN
      Poczatki[0] := place.left + sz;
      Poczatki[1] := place.left + 3*sz;
      Poczatki[2] := place.left + 4*sz;
      Poczatki[3] := place.left + 6*sz;
    ELSE
      Poczatki[0] := place.left + 2*sz;
      Poczatki[1] := place.left + 5*sz;
    END;
  END;
  Update( h );
  RETURN h;
END WykresSlupkowy;


PROCEDURE Update( w : WHandle );

  PROCEDURE Skala( x, min, max, height : INTEGER ) : INTEGER;
  BEGIN
    RETURN entier( real( x-min ) * real( height ) / real( max-min ));
(*
    RETURN VAL( INTEGER,
	   VAL( LONGINT, x - min ) * VAL( LONGINT, height ) DIV
    			   			VAL( LONGINT, max - min ));
*)
  END Skala;

  PROCEDURE Kolor( x, min, max : INTEGER ) : CHAR;
  BEGIN
    IF (x < min) OR (x > max) THEN
      RETURN CHR(RED);
    ELSE
      RETURN CHR(GREEN);
    END;
  END Kolor;

  PROCEDURE Odswiez( nowa,
                     stara  : INTEGER;
                     idx    : CARDINAL );

    PROCEDURE FillR( R : RECT; color : CHAR );
    BEGIN
      IF Intersection( R, w^.place, R )  THEN
        FillRect( R, color );
      END;
    END FillR;

  VAR
    h       : INTEGER;
    screenR,
    dibR    : RECT;
    sk, nk  : CHAR;
    Redraw  : BOOLEAN;
    pt      : POINT;
  BEGIN
    WITH w^ DO
      sk := Kolor( stara, Alarm.min, Alarm.max );
      nk := Kolor( nowa, Alarm.min, Alarm.max );
      Redraw := sk # nk;
      h := place.bottom-place.top;
      nowa := Skala( nowa, min, max, h );
      stara := Skala( stara, min, max, h );

      screenR.left  := Poczatki[idx];
      screenR.right := Poczatki[idx+1];
      screenR.top   := place.bottom - nowa;
      screenR.bottom:= place.bottom - stara;

      IF nowa = stara THEN (* ze wzgledu na dokladnosc *)
        IF Redraw THEN
          screenR.bottom := place.bottom;
          FillR( screenR, nk );
        END;
      ELSIF nowa > stara THEN
        IF Redraw THEN
          screenR.bottom := place.bottom;
        END;
        FillR( screenR, nk );
      ELSE (* stary > nowy *)
        pt.x := screenR.left;
        pt.y := screenR.bottom;
        dibR := redrawRECT;
        dibR.left  := redrawRECT.left +  screenR.left - place.left ;
        dibR.right := redrawRECT.left +  screenR.right - place.left;
        dibR.bottom := redrawRECT.top+h-nowa ;
        dibR.top    := redrawRECT.top+h-stara;
        IF Redraw THEN
          screenR.bottom := place.bottom;
          FillR( screenR, nk );
        END;
        ShowDIB( dib, dibR, pt, FALSE );
      END;
    END;
  END Odswiez;

VAR
  val   : INTEGER;
BEGIN
  WITH w^ DO
    Clip( place );
    val := A(w);
    IF val>max THEN
      val:=max;
    ELSIF val<min THEN
      val := min;
    END;
    Odswiez( val, pA, 0 );
    pA := val;
    IF oba THEN
      val := B(w);
      IF val>max THEN
        val:=max;
      ELSIF val<min THEN
        val := min;
      END;
      Odswiez( val, pB, 2 );
      pB := val;
    END;
    NoClip;
  END;
END Update;

PROCEDURE Dispose( w : WHandle );
BEGIN
  DISPOSE( w );
END Dispose;

PROCEDURE Nothing(w : WHandle): INTEGER;
  (* nie powinna byc nigdy wywolywana *)
END Nothing;

PROCEDURE GetSlupRect( w : WHandle; VAR r : RECT );
BEGIN
  IF w # NIL THEN
    r := w^.place;
  END;
END GetSlupRect;

PROCEDURE Nil() : WHandle;
BEGIN
  RETURN NIL;
END Nil;

END Slupek.
