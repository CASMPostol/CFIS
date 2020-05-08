IMPLEMENTATION MODULE Geo2Polar;

FROM MATHLIB IMPORT
  M_Pi, Cos, Sin, ACos, Sqrt;


VAR
  Odniesienie : PolozenieGeograficzne;


INLINE PROCEDURE Sqr( x : LONGREAL ) : LONGREAL;
BEGIN
  RETURN x*x;
END Sqr;

PROCEDURE UstawPolozenieOdniesienia( pg : PolozenieGeograficzne );
BEGIN
  Odniesienie := pg;
END UstawPolozenieOdniesienia;

PROCEDURE PolozenieOdniesienia() : PolozenieGeograficzne;
BEGIN
  RETURN Odniesienie;
END PolozenieOdniesienia;

PROCEDURE DodajKatGeo( a, b : KatGeo ) : KatGeo;
VAR
  c : KatGeo;
BEGIN
  c.Stopnie := a.Stopnie+b.Stopnie;
  c.Minuty  := a.Minuty+b.Minuty;
  c.Setne := a.Setne+b.Setne;
  INC( c.Minuty, c.Setne DIV 100 );
  c.Setne := c.Setne MOD 100;
  INC( c.Stopnie, c.Minuty DIV 60 );
  c.Minuty := c.Minuty MOD 60;
  RETURN c;
END DodajKatGeo;

PROCEDURE Odwr( a : KatGeo ) : KatGeo;
BEGIN
  IF TRUE OR       (a.Stopnie = 0) OR (a.Stopnie > 180) THEN
    a.Stopnie := 360-a.Stopnie;
    IF (a.Minuty # 0) OR (a.Setne # 0) THEN
      DEC( a.Stopnie );
      a.Minuty  := 60-a.Minuty;
      IF a.Setne # 0 THEN
        DEC( a.Minuty );
        a.Setne   := 100-a.Setne;
      END;
    END;
    IF a.Stopnie = 360 THEN
      a.Stopnie := 0;
    END;
    IF a.Minuty = 60 THEN
      a.Minuty := 0;
    END;
  ELSE
    a.Stopnie := -a.Stopnie;
  END;
  RETURN a;
END Odwr;

PROCEDURE OdejmijKatGeo( a, b : KatGeo ) : KatGeo;
VAR
  c    : KatGeo;
  odwr : BOOLEAN;
BEGIN
  IF ( a.Stopnie < b.Stopnie ) OR
     ( a.Stopnie = b.Stopnie ) & ( a.Minuty < b.Minuty ) OR
     ( a.Stopnie = b.Stopnie ) & ( a.Minuty = b.Minuty ) & ( a.Setne < b.Setne )
  THEN
    c := a;
    a := b;
    b := c;
    odwr := TRUE;
  ELSE
    odwr := FALSE;
  END;
  (* na pewno a > b *)
  IF a.Setne < b.Setne THEN
    IF a.Minuty # 0 THEN
      DEC( a.Minuty );
    ELSE
      DEC( a.Stopnie );
      a.Minuty := 59;
    END;
    INC( a.Setne, 100 );
  END;
  IF a.Minuty < b.Minuty THEN
    DEC( a.Stopnie );
    INC( a.Minuty, 60 );
  END;
  DEC( a.Stopnie, b.Stopnie );
  DEC( a.Minuty, b.Minuty );
  DEC( a.Setne, b.Setne );
  IF odwr THEN
    RETURN Odwr(a);
  ELSE
    RETURN a;
  END;
END OdejmijKatGeo;


PROCEDURE SredniKatGeo( a, b : KatGeo ) : KatGeo;
VAR
  c : KatGeo;
  reszta : CARDINAL;
BEGIN
  c := DodajKatGeo( a, b );
  reszta := ORD( ODD( c.Stopnie )) * 60;
  c.Stopnie := c.Stopnie DIV 2;
  INC( c.Minuty, reszta );
  reszta := ORD(ODD( c.Minuty )) * 100;
  c.Minuty := c.Minuty DIV 2;
  INC( c.Setne, reszta );
  c.Setne := c.Setne DIV 2;
  RETURN c;
END SredniKatGeo;

PROCEDURE Rad( VAR a : KatGeo ) : LONGREAL;
VAR
  KatWStopniach : LONGREAL;
BEGIN
  KatWStopniach := LONGREAL( ABS(a.Stopnie) )+
                   LONGREAL( a.Minuty ) / 60.0+
                   LONGREAL( a.Setne )  / 6000.0;
  IF a.Stopnie < 0 THEN
    KatWStopniach := -KatWStopniach;
  END;
  RETURN KatWStopniach*M_Pi/180.0;
END Rad;

PROCEDURE Odl2Geo( OdlWMilach : LONGREAL; DlugoscMinuty : LONGREAL ) : KatGeo;
VAR
  mf : LONGREAL;
  mi : CARDINAL;
  k : KatGeo;
BEGIN
  mf := OdlWMilach / DlugoscMinuty; (* calkowita ilosc minut katawych *)
  mi := TRUNC( ABS(mf) );
  k.Stopnie := mi DIV 60;
  k.Minuty  := mi MOD 60;
  k.Setne   := TRUNC((ABS(mf)-LONGREAL(mi))*100.0);
  IF mf < 0.0 THEN
    RETURN Odwr( k );
  ELSE
    RETURN k;
  END;
END Odl2Geo;

PROCEDURE Mile( a : KatGeo ) : LONGREAL;
VAR
  m : LONGREAL;
  odwr : BOOLEAN;
BEGIN
  IF a.Stopnie > 180 THEN
    a := Odwr( a );
    odwr := TRUE;
  ELSE
    odwr := FALSE;
  END;
  m := LONGREAL( ABS(a.Stopnie) ) * 60.0+
       LONGREAL( a.Minuty  )+
       LONGREAL( a.Setne   ) / 100.0;
  IF a.Stopnie < 0 THEN
    m := -m;
  END;
  IF odwr THEN
    RETURN -m;
  ELSE
    RETURN m;
  END;
END Mile;



PROCEDURE Geo2Kat(     pg : PolozenieGeograficzne;
                   VAR pk : PolozenieKatowe );
VAR
  SredniRownoleznik : KatGeo; (* dokola ziemia jest plaska *)
  OdlegloscRownol   : LONGREAL;
  OdlegloscPoludn   : LONGREAL;
BEGIN
  SredniRownoleznik := SredniKatGeo( pg.Szerokosc, Odniesienie.Szerokosc );
  OdlegloscRownol := Mile(OdejmijKatGeo( pg.Dlugosc, Odniesienie.Dlugosc ));
  OdlegloscPoludn := Mile(OdejmijKatGeo( pg.Szerokosc, Odniesienie.Szerokosc ));

  (* modyfikacja ze wzgledu na odchylenie od rownika *)
  OdlegloscRownol := OdlegloscRownol*Cos( Rad( SredniRownoleznik ));
  pk.Odleglosc := Sqrt( Sqr( OdlegloscRownol ) + Sqr( OdlegloscPoludn ));
  IF pk.Odleglosc = 0.0 THEN
    pk.Kat := 0.0;
  ELSE
    pk.Kat := ACos( OdlegloscPoludn / pk.Odleglosc );
  END;
  pk.Kat := pk.Kat*180.0/M_Pi;
  IF OdlegloscRownol < 0.0 THEN
    pk.Kat := 360.0 - pk.Kat;
  END;
END Geo2Kat;

PROCEDURE Kat2Geo(     pk : PolozenieKatowe;
                   VAR pg : PolozenieGeograficzne );
VAR
  OdlegloscRownol   : LONGREAL;
  OdlegloscPoludn   : LONGREAL;
  KatWRadianach     : LONGREAL;
  SredniRownoleznik : KatGeo; (* dokola ziemia jest plaska *)
BEGIN
  KatWRadianach := pk.Kat*M_Pi/180.0;
  OdlegloscRownol := pk.Odleglosc * Sin( KatWRadianach );
  OdlegloscPoludn := pk.Odleglosc * Cos( KatWRadianach );
  pg.Szerokosc := Odl2Geo( OdlegloscPoludn, 1.0 );
  pg.Szerokosc := DodajKatGeo( pg.Szerokosc, Odniesienie.Szerokosc );
  pg.Szerokosc.Stopnie := pg.Szerokosc.Stopnie MOD 360;
  SredniRownoleznik := SredniKatGeo( pg.Szerokosc, Odniesienie.Szerokosc );
  pg.Dlugosc := Odl2Geo( OdlegloscRownol, Cos( Rad( SredniRownoleznik )) );
  pg.Dlugosc := DodajKatGeo( pg.Dlugosc, Odniesienie.Dlugosc );
  pg.Dlugosc.Stopnie := pg.Dlugosc.Stopnie MOD 360;
END Kat2Geo;

END Geo2Polar.
