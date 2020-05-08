(*.F- *)
(**********************************************************************
|  Title   : Procedury drukowania na drukarce 
|  Author  : M.Morawski				
|  System  : LOGITECH MODULA-2/86 
|  History :
|    Rel 3.0. MPostol
|      blad przydrukowaniu mapy bitowej - przy przerwaniu drukowania nie 
|      zakonczony ciag znakow trybu tekstowego
|    WrProc - w przypadku przerwania nie drukowal jednego znaku
|
|  Copyright (C), CAS LODZ POLAND.
|  TEL: 42' 686 25 47
|  mailto: techsupp@cas.com.pl
|  http: www.cas.com.pl
|
**********************************************************************)
(*.F+ *)
(* $ R -*)
(* $ S -*)
(* $ T -*)
(* $ O +*)
IMPLEMENTATION MODULE DrawEpson;

FROM BlockOps IMPORT
  BlockClear;
FROM SYSTEM IMPORT
  ADDRESS, ADR, CODE, SWI, AX, BX, ES, SETREG, GETREG, BYTE;
FROM ASCII IMPORT
  ff, cr, lf, esc, si;
IMPORT
  XMSService, SYSTEM, ASCII, GrafUtil, Timer, Terminal;
FROM RTSMain IMPORT
  Terminate, Status;
(*
FROM Terminal IMPORT
  WriteString, WriteLn;
FROM NumberConversion IMPORT
  NumToString;
*)


CONST
  TrybGraficzny   = 'Z';
  RozdzielczoscPozioma	= 240;
  PozdzielczoscPionowa  = 72;
  PunktowWPoziomie	= RozdzielczoscPozioma*8; (* bo 8 cali *)
  PunktowWPionie	= PozdzielczoscPionowa*19 DIV 2; (* bo 11 cali za duzo *)
  BajtowWWierszu	= (PunktowWPoziomie+7) DIV 8;

  WLK_BUFORA = BajtowWWierszu*8; (* ma byc wielokrotnoscia 8 !!! *)

  IleWierszyNaStronie = WLK_BUFORA DIV BajtowWWierszu;
  PaskowNaStronie	= IleWierszyNaStronie DIV 8;
  WysokoscStrony	= PaskowNaStronie*8; (* bo 8 igiel *)
  IloscStron		= (PunktowWPionie+WysokoscStrony-1) DIV WysokoscStrony;
  WszystkichPaskow	= (PunktowWPionie+7) DIV 8;
  PaskowNaOstatniejStronie	= WszystkichPaskow-PaskowNaStronie*(IloscStron-1);



CONST
	DrukJednokierunkowy = FALSE;

TYPE
	set8 = SET OF [0..7];
VAR
  xh  : XMSService.XMS_Handle;
  Bufor: ARRAY [0..WLK_BUFORA-1] OF BYTE;
	LastPosition : CARDINAL;
	Masks : ARRAY [0..7] OF set8;
  Adr1, Adr2 : RECORD
		CASE CARDINAL OF
		| 0:
			Ofs, Seg : CARDINAL;
		| 1:
			Ptr	: ADDRESS;
		| 2:
			Pix	: POINTER TO set8;
		END
	END;

(*
PROCEDURE WriteAdr( a : ADDRESS );
VAR
  s : ARRAY[0..20] OF CHAR;
BEGIN
  NumToString( a.SEGMENT, 16, s, 4 );
  WriteString( s );
  WriteString( ":" );
  NumToString( a.OFFSET, 16, s, 4 );
  WriteString( s );
  WriteLn;
END WriteAdr;
*)


PROCEDURE UstawTrybTekstowy( Proc : OutProc ) : BOOLEAN;
  BEGIN
    RETURN
           Proc( esc ) & Proc( 'M' ) & (* 12 cpi *)
(*           Proc( si ) & (* 17 cpi *)*)
           Proc( esc ) & Proc( '2'); (* 6 lpi *)
  END UstawTrybTekstowy;

PROCEDURE MaxX():CARDINAL;
BEGIN
  RETURN PunktowWPoziomie;
END MaxX;

PROCEDURE MaxY():CARDINAL;
BEGIN
  RETURN PunktowWPionie;
END MaxY;



VAR
  PrevPage : CARDINAL;

PROCEDURE Map( page : CARDINAL );
VAR
  from, to : XMSService.ExtMemPtr;
BEGIN
  IF PrevPage # page THEN
    IF PrevPage < 0f000h THEN
      from.RealPtr := ADR( Bufor );
      to.ProtectedPtr := VAL( LONGINT, PrevPage )*VAL( LONGINT, WLK_BUFORA );
      XMSService.Copy( 0, from, xh, to, WLK_BUFORA );
    END;
    to.RealPtr := ADR( Bufor );
    from.ProtectedPtr := VAL( LONGINT, page )*VAL( LONGINT, WLK_BUFORA );
    XMSService.Copy( xh, from, 0, to, WLK_BUFORA );
    PrevPage := page;
  END;
END Map;

PROCEDURE Point( x, y : INTEGER; Set : BOOLEAN );
BEGIN
  IF (y >= PunktowWPionie) OR ( x >= PunktowWPoziomie ) OR
     (y < 0 ) OR ( x < 0 )
  THEN
    RETURN;
  END;
  Map( y DIV WysokoscStrony );
  y := y MOD WysokoscStrony;
  Adr1.Ofs := Adr2.Ofs+VAL(CARDINAL,y*BajtowWWierszu + x DIV 8);
  x := x MOD 8;
  IF Set THEN
    Adr1.Pix^ := Adr1.Pix^ + Masks[x];
  ELSE
    Adr1.Pix^ := Adr1.Pix^ * (Masks[x]/set8{0..7});
  END;
END Point;

PROCEDURE IsDrawn( x, y : CARDINAL ) : BOOLEAN ;
BEGIN
  IF (y >= PunktowWPionie) OR ( x >= PunktowWPoziomie ) THEN
    RETURN FALSE;
  END;
  Map( y DIV WysokoscStrony );
  y := y MOD WysokoscStrony;
  Adr1.Ofs := Adr2.Ofs+VAL( CARDINAL, y*BajtowWWierszu + x DIV 8 );
  x := x MOD 8;
  RETURN Adr1.Pix^ * Masks[x] # set8{};
END IsDrawn;

(*
PROCEDURE HorizontalLine( y, x1, x2 : CARDINAL; Style : BITSET );
BEGIN
  IF x1 < x2 THEN
    t := x1;
    x1 := x2;
    x2 := t;
  END;
  IF (y >= PunktowWPionie) OR ( x1 >= PunktowWPoziomie ) THEN
    RETURN;
  END;
  IF x2 >= PunktowWPoziomie THEN
    x2 := PunktowWPoziomie-1;
  END;
  Map( y DIV WysokoscStrony );
  y := y MOD WysokoscStrony;
  Adr.Ofs := y*BajtowWWierszu + x1 DIV 8;
  SETREG( CX, (x1 MOD 8 + LastPosition) MOD 16 );
  SETREG( AX, Style );
  CODE( 0d3h, 0c0h (* rol ax,cl *));
  GETREG( AX, Style );
  x := x MOD 8;
  IF x2 DIV 8 = x1 DIV 8 THEN (* ten sam bajt *)
    Mask := SideMasks[ x ] * (SideMasks[ x2 MOD 8 ]/BITSET{0..15})
    Adr.Pix^ := Adr.Pix^*(Masks/BITSET{0..15});
    Style := Style * Mask;
    Adr.Pix^ := Adr.Pix^
  IF Set THEN
    Adr.Pix^ := Adr.Pix^ + Masks[x];
  ELSE
    Adr.Pix^ := Adr.Pix^ * (Masks[x]/set8{0..7});
  END;


END HorizontalLine;
*)



PROCEDURE Out( Proc : OutProc ) : BOOLEAN;

(*
  PROCEDURE String( s : ARRAY OF CHAR );
  VAR
    i : CARDINAL;
  BEGIN
    WHILE ( i <= HIGH(s)) & ( s[i] # 0C ) DO
      Proc( s[i] );
      INC( i );
    END;
  END String;
*)

VAR
  pix             : set8;
  p,w,x,y,lim     : CARDINAL;
  WydrukPrzerwany : BOOLEAN; 
    (*MP: ustawiany jesli nastepuje przerwanie wydruku *)
  WydrukOK        : BOOLEAN;
  
BEGIN
  WydrukPrzerwany := FALSE;
  p := IloscStron;
  p := PaskowNaOstatniejStronie;
  p := WszystkichPaskow;
  p := PaskowNaStronie;
  IF NOT Proc( esc ) THEN
    RETURN FALSE;
  END;
  IF NOT Proc( '@' )  (* reset *) THEN
    RETURN FALSE;
  END;
  IF NOT Proc( esc ) THEN
    RETURN FALSE;
  END;
  IF NOT Proc( 'A' ) THEN
    RETURN FALSE;
  END;
  IF NOT Proc( CHR( 8 ) )	(* Ustaw wysokosc wysuwu na 8/72 " *) THEN
    RETURN FALSE;
  END;
(*
  Proc( esc );
  Proc( '8' );		(* Wulacznik czujnika konca papieru *)
*)
  IF DrukJednokierunkowy THEN
    IF NOT Proc( esc ) THEN
      RETURN FALSE;
    END;
    IF NOT Proc( 'U' ) THEN
      RETURN FALSE;
    END;
    IF NOT Proc( '1' ) THEN
      RETURN FALSE;
    END;
  END;

  FOR p := 0 TO IloscStron-1 DO
    Map( p );
    IF p = IloscStron-1 THEN
      lim := PaskowNaOstatniejStronie;
    ELSE
      lim := PaskowNaStronie;
    END;
    FOR w := 0 TO lim-1 DO
      IF NOT Proc( esc ) THEN
        RETURN FALSE;
      END;
      IF NOT Proc( TrybGraficzny ) THEN
        RETURN FALSE;
      END;
      IF NOT Proc( CHR( PunktowWPoziomie MOD 100H )) THEN
        RETURN FALSE;
      END;
      IF NOT Proc( CHR( PunktowWPoziomie DIV 100H )) THEN
        RETURN FALSE;
      END;
      FOR x := 0 TO PunktowWPoziomie-1 DO
        pix := set8{};
        FOR y := 0 TO 7 DO
          Adr1.Ofs := Adr2.Ofs+(w*8+y)*BajtowWWierszu+x DIV 8;
          IF Adr1.Pix^*Masks[x MOD 8] # set8{} THEN
            INCL( pix, 7-y );
          END;
        END;
        WydrukOK := NOT Proc( CHAR(pix) );
        WydrukPrzerwany := WydrukPrzerwany OR WydrukOK;
      END;
      IF WydrukPrzerwany THEN
        WydrukPrzerwany := Proc( ff );
        WydrukPrzerwany := UstawTrybTekstowy( Proc );
        RETURN FALSE;
      END;
      IF (p = IloscStron-1) & (w = lim-1) THEN
        IF NOT Proc( ff ) THEN
          RETURN FALSE;
        END;
      ELSE
        IF NOT Proc( cr ) THEN
          RETURN FALSE;
        END;
        IF NOT Proc( lf ) THEN
          RETURN FALSE;
        END;
      END;
    END;
  END;
  RETURN UstawTrybTekstowy( Proc );
END Out;

PROCEDURE Open;
VAR
  i : CARDINAL;
BEGIN
  xh := XMSService.Allocate( VAL(LONGINT, IloscStron ) * VAL( LONGINT, WLK_BUFORA ) );
  Adr1 := Adr2;
  FOR i := 0 TO IloscStron-1 DO
    Map( i );
    BlockClear( Adr1.Ptr, WLK_BUFORA );
  END;
END Open;

PROCEDURE Close;
BEGIN
  XMSService.Deallocate( xh );
END Close;

PROCEDURE Line(X1, Y1, X2, Y2: INTEGER; Style : BITSET );
VAR
    X, Y, XStep, YStep, Direction : INTEGER;
    DeltaX, DeltaY    : CARDINAL;
BEGIN
  X       := X1;
  Y       := Y1;
  XStep   := 1;
  YStep   := 1;
  IF X1 > X2 THEN
    XStep := -1
  END;
  IF Y1 > Y2 THEN
    YStep := -1
  END;
  DeltaX := ABS(INTEGER(X2)-INTEGER(X1));
  DeltaY := ABS(INTEGER(Y2)-INTEGER(Y1));
  IF DeltaX = 0 THEN
    Direction := (-1)
  ELSE
    Direction := 0
  END;
  WHILE  NOT ((X = INTEGER(X2)) AND (Y = INTEGER(Y2))) DO
    Point( X, Y, LastPosition IN Style );
    LastPosition := (LastPosition+1) MOD 16;
    IF Direction < 0 THEN
      INC(Y, YStep);
      INC(Direction, DeltaX);
    ELSE
      INC(X, XStep);
      DEC(Direction, DeltaY);
    END;
  END;
(*  Terminate( Warning );*)
END Line;


TYPE
  FontPtr	= POINTER TO ARRAY[0..15] OF CHAR (* wiekszych znakow nie ma *);
VAR
  CurMode	: mtMode;
  FontAdrN	: FontPtr;
  FontAdrA	: FontPtr;
  FontHeight	: CARDINAL;

PROCEDURE SetTextMode( m : mtMode );
BEGIN
  CurMode := m;
END SetTextMode;

PROCEDURE SetFont( f : tFont );
VAR
  submodeN, submodeA : CHAR;
  a		     : ADDRESS;
BEGIN
  CASE f OF
    ft8x8:
      submodeN   := 3C;
      submodeA   := 4C;
      FontHeight := 8;
  | ft8x14:
      submodeN   := 2C;
      submodeA   := 5C;
      FontHeight := 14;
  | ft8x16:
      submodeN   := 6C;
      submodeA   := 7C;
      FontHeight := 16;
  ELSE
    HALT;
  END;
  SETREG( BX, ORD(submodeN)*256 );
  SETREG( AX, 1130H );
  CODE( 055h (* push bp *));
  SWI( 10H );
  CODE( 089h,0e8h (* mov ax,bp *));
  CODE( 05dh (* pop bp *));
  GETREG( AX, a.OFFSET );
  GETREG( ES, a.SEGMENT );

  FontAdrN := a;

  SETREG( BX, ORD(submodeA)*256 );
  SETREG( AX, 1130H );
  CODE( 055h (* push bp *));
  SWI( 10H );
  CODE( 089h,0e8h (* mov ax,bp *));
  CODE( 05dh (* pop bp *));
  GETREG( AX, a.OFFSET );
  GETREG( ES, a.SEGMENT );

  FontAdrA := a;
END SetFont;

PROCEDURE Conv2PL( VAR a : ADDRESS; VAR c : CHAR );
  BEGIN
    IF c > CHR( 7FH ) THEN
      a := FontAdrN;
      CASE c OF
        '•': c := 'a';
      | 'Ü': c := 'c';
      | '©': c := 'e';
      | 'à': c := 'l';
      | '‰': c := 'n';
      | '¢': c := 'o';
      | 'ò': c := 's';
      | 'æ': c := 'z';
      | '´': c := 'z';
      | '§': c := 'A';
      | 'è': c := 'C';
      | '®': c := 'E';
      | 'ù': c := 'L';
      | '„': c := 'N';
      | '‡': c := 'O';
      | 'ó': c := 'S';
      | 'Ω': c := 'Z';
      | 'ç': c := 'Z';
      ELSE
        a := FontAdrA;
        DEC( c, 80H );
      END;
    ELSE
      a := FontAdrN;
    END;  
  END Conv2PL;
  
PROCEDURE DrawChar0( c : CHAR; x, y : CARDINAL );
VAR
  a : ADDRESS;
  m, nieRob : BOOLEAN;
  f : FontPtr;
  i, j, k, l : CARDINAL;
BEGIN
  Conv2PL( a, c );
  INC( a.OFFSET, ORD(c)*FontHeight );
  f := a;
  FOR i := 0 TO FontHeight-1 DO
    FOR l := 0 TO MnY-1 DO
      FOR j := 0 TO 7 DO
        FOR k := 0 TO MnX-1 DO
          nieRob := FALSE;
          IF ORD(7-j) IN set8( f^[i] ) THEN (* czarny punkt *)
            CASE CurMode OF
              mtSet   : m := TRUE;
            | mtClear : m := FALSE;
            | mtOr    : m := TRUE;
            | mtAnd   : nieRob := TRUE;
            | mtXor   : m := NOT IsDrawn( x+j*MnX+k, y+i*MnY+l );
            END;
          ELSE
            CASE CurMode OF
              mtSet   : m := FALSE;
            | mtClear : m := TRUE;
            | mtOr    : nieRob := TRUE;
            | mtAnd   : m := FALSE;
            | mtXor   : nieRob := TRUE;
            END;
          END;
          IF NOT nieRob THEN
            Point( x+j*MnX+k, y+i*MnY+l, m );
          END;
        END;
      END;
    END;
  END;
END DrawChar0;

PROCEDURE DrawText0( VAR s : ARRAY OF CHAR; x, y : CARDINAL );
VAR
  i : CARDINAL;
BEGIN
  i := 0;
  WHILE ( i <= HIGH( s )) & (s[i] # 0C ) DO
    DrawChar0( s[i], x, y );
    INC( x, 8*MnX );
    INC( i );
  END;
END DrawText0;

PROCEDURE DrawChar90( c : CHAR; x, y : CARDINAL );
VAR
  a : ADDRESS;
  m, nieRob : BOOLEAN;
  f : FontPtr;
  i, j, k, l : CARDINAL;
  x1, y1 : CARDINAL;
BEGIN
  Conv2PL( a, c );
  INC( a.OFFSET, ORD(c)*FontHeight );
  f := a;
  FOR i := 0 TO FontHeight-1 DO
    FOR l := 0 TO MnY-1 DO
      FOR j := 0 TO 7 DO
        FOR k := 0 TO MnX-1 DO
          nieRob := FALSE;
          x1 := x-i*MnX-k;
          y1 := y+j*MnY+l;
          IF ORD(7-j) IN set8( f^[i] ) THEN (* czarny punkt *)
            CASE CurMode OF
              mtSet   : m := TRUE;
            | mtClear : m := FALSE;
            | mtOr    : m := TRUE;
            | mtAnd   : nieRob := TRUE;
            | mtXor   : m := NOT IsDrawn( x1, y1 );
            END;
          ELSE
            CASE CurMode OF
              mtSet   : m := FALSE;
            | mtClear : m := TRUE;
            | mtOr    : nieRob := TRUE;
            | mtAnd   : m := FALSE;
            | mtXor   : nieRob := TRUE;
            END;
          END;
          IF NOT nieRob THEN
            Point( x1, y1, m );
          END;
        END;
      END;
    END;
  END;
END DrawChar90;

PROCEDURE DrawText90( VAR s : ARRAY OF CHAR; x, y : CARDINAL );
VAR
  i : CARDINAL;
BEGIN
  i := 0;
  WHILE ( i <= HIGH( s )) & (s[i] # 0C ) DO
    DrawChar90( s[i], x, y );
    INC( y, 8*MnY );
    INC( i );
  END;
END DrawText90;

PROCEDURE DrawText( s : ARRAY OF CHAR; x, y : CARDINAL );
  BEGIN
    CASE Rotation OF
      t_0:
        DrawText0( s, x, y );
    | t_90:
        DrawText90( s, x, y );
    END;
  END DrawText;

PROCEDURE SetDir( t : tDir );
  BEGIN
    Rotation := t;
  END SetDir;

PROCEDURE Mnoznik( x, y : CARDINAL );
  BEGIN
    MnX := x;
    MnY := y;
  END Mnoznik;

VAR
  Rotation : tDir;
  MnX,
  MnY      : CARDINAL;

VAR
  JuzNarysowane : BOOLEAN;

  PROCEDURE InitPort;
  VAR
    stat : BITSET;
  BEGIN
    SYSTEM.SETREG( SYSTEM.AX, 100H );
    SYSTEM.SETREG( SYSTEM.DX, PrnPort );
    SYSTEM.SWI( 17H );
    SYSTEM.GETREG( SYSTEM.AX, stat );
    stat := stat-{0..7};
    JuzNarysowane := TRUE;
    IF stat = {} THEN
      IF NOT UstawTrybTekstowy( WrProc ) THEN (* condensed mode *)
        RETURN;
      END;
    END;
    JuzNarysowane := FALSE;
  END InitPort;

  PROCEDURE IsAborted(  ) : BOOLEAN;
  VAR
    term : CHAR;
  BEGIN
    IF Terminal.KeyPressed() THEN
      Terminal.Read( term );
      IF term = ASCII.esc THEN
        GrafUtil.InfoBeep( 'Drukowanie zaniechane...', 2, 1 );
        RETURN TRUE;
      END;
    END;
    RETURN FALSE;
  END IsAborted;

  PROCEDURE WrProc( c : CHAR ) : BOOLEAN;
  VAR
    s : BITSET;
  BEGIN
(*    RETURN TRUE;*)
    REPEAT
      IF NOT JuzNarysowane THEN
        Timer.Wait(3*Timer.TInOneSecond());
        SYSTEM.SETREG( SYSTEM.AX, 200H );
        SYSTEM.SETREG( SYSTEM.DX, PrnPort );
        SYSTEM.SWI( 17H );
        SYSTEM.GETREG( SYSTEM.AX, s );
      END;
      SYSTEM.SETREG( SYSTEM.AX, ORD( c ));
      SYSTEM.SETREG( SYSTEM.DX, PrnPort );
      SYSTEM.SWI( 17H );
      SYSTEM.GETREG( SYSTEM.AX, s );
      IF IsAborted() THEN
        RETURN FALSE;
      END;
(*
      IF NOT(14 IN s ) THEN
        GrafUtil.InfoBeep( "Drukarka nie przyà•czona...", 2, 1000 );
        JuzNarysowane := FALSE;
      END;
*)
      IF 13 IN s THEN
        GrafUtil.InfoBeep( 'Brak papieru w drukarce', 2, 1000 );
        JuzNarysowane := FALSE;
      ELSIF 11 IN s THEN
        GrafUtil.InfoBeep( 'Bà•d portu', 2, 1000 );
        JuzNarysowane := FALSE;
      ELSIF NOT(12 IN s) THEN
        GrafUtil.InfoBeep( 'Drukarka nieaktywna', 2, 1000 );
        JuzNarysowane := FALSE;
      ELSIF 8 IN s THEN
        GrafUtil.InfoBeep( 'Przekroczony limit czasu na wysàanie znaku', 2, 1000 );
        JuzNarysowane := FALSE;
      ELSIF NOT JuzNarysowane THEN
        GrafUtil.Info( "Drukowanie raportu. <ESC> konczy wydruk" );
        JuzNarysowane := TRUE;
      END;
    UNTIL JuzNarysowane;
    RETURN TRUE;
  END WrProc;




BEGIN
  PrnPort := 0;
  PrevPage := 0FFF9H; (* invalid *)
  Adr1.Ptr := ADR( Bufor );
  Adr2 := Adr1;
  Masks[0] := set8{7};
  Masks[1] := set8{6};
  Masks[2] := set8{5};
  Masks[3] := set8{4};
  Masks[4] := set8{3};
  Masks[5] := set8{2};
  Masks[6] := set8{1};
  Masks[7] := set8{0};
  LastPosition := 0;

  SetFont( ft8x8 );
  SetTextMode( mtSet );
  Mnoznik(1,1);
  SetDir( t_0 );
  InitPort;
END DrawEpson.
