(*.F- *)
(**********************************************************************
|  Title   : Przeliczanie wspo. w systemie biegunowym i geograficznym
|  Author  : M.Morawski
|  System  : LOGITECH MODULA-2/86
|  History :
|    14-12-96; M.Postol
|      zmienilem def Odniesienie i Geo2Kat ze wzgledu na VOR'a
|      trasowego
|    02-01-98: M.Postol
|      dostosowale modul do nowej definicji WspGeo
|
|  Copyright (C), CAS LODZ POLAND.
|  TEL: 42' 862 547, 42' 87 80 44 FAX/TEL: 42' 84 48 40
|
**********************************************************************)
(*.F+ *)

IMPLEMENTATION MODULE GeoArithmetic;

  FROM MathLib0 IMPORT
    (* real, *) cos, sqrt, sin;

  FROM Math IMPORT
    ACos, Sqr, M_PI;

  FROM CommonTypes IMPORT
    PolozenieGeo, PolozenieBiegunowe, WspGeo, GlownyOdbiornikT;

  CONST
    DzielnikMin = 10000;

  PROCEDURE DodajPolozenieGeo
            (     a,
                  b : WspGeo;
              VAR c : WspGeo );

  BEGIN
    c.Stopnie := a.Stopnie + b.Stopnie;
    c.Minuty := a.Minuty + b.Minuty;
    c.DziesTys := a.DziesTys + b.DziesTys;
    INC(c.Minuty, c.DziesTys DIV DzielnikMin);
    c.DziesTys := c.DziesTys MOD DzielnikMin;
    INC(c.Stopnie, c.Minuty DIV 60);
    c.Minuty := c.Minuty MOD 60;
  END DodajPolozenieGeo;

  (* PROCEDURE Odwr( VAR a : WspGeo ); BEGIN IF (a.Stopnie = 0) OR (a.Stopnie >
     180) THEN a.Stopnie := 360-a.Stopnie; IF (a.Minuty # 0) OR (a.Setne # 0)
     THEN DEC( a.Stopnie ); a.Minuty := 60-a.Minuty; IF a.Setne # 0 THEN DEC(
     a.Minuty ); a.Setne := 100-a.Setne; END; END; IF a.Stopnie = 360 THEN
     a.Stopnie := 0; END; IF a.Minuty = 60 THEN a.Minuty := 0; END; ELSE
     a.Stopnie := -a.Stopnie; END; END Odwr; *)

  PROCEDURE Odwr
            ( VAR a : WspGeo );

  BEGIN
    WITH a DO
      Stopnie := 360 - Stopnie;
      IF (Minuty # 0) OR (DziesTys # 0)
      THEN
        DEC(Stopnie);
        Minuty := 60 - Minuty;
        IF DziesTys # 0
        THEN
          DEC(Minuty);
          DziesTys := DzielnikMin - DziesTys;
        END (* if DziesTys *);
      END (* if *);
      IF Stopnie = 360
      THEN
        Stopnie := 0;
      END (* if Stopnie *);
      IF Minuty = 60
      THEN
        Minuty := 0;
      END (* if Minuty *);
    END (* with a *);
  END Odwr;

  PROCEDURE OdejmijPolozenieGeo
            (     a,
                  b : WspGeo;
              VAR c : WspGeo );
  VAR
    odwr : BOOLEAN;

  BEGIN
    IF (a.Stopnie < b.Stopnie) OR (a.Stopnie = b.Stopnie) &
       (a.Minuty < b.Minuty) OR (a.Stopnie = b.Stopnie) & (a.Minuty = b.Minuty)
       & (a.DziesTys < b.DziesTys)
    THEN
      c := a;
      a := b;
      b := c;
      odwr := TRUE;
    ELSE
      odwr := FALSE;
    END (* if *);
    (* na pewno a > b *)
    IF a.DziesTys < b.DziesTys
    THEN
      IF a.Minuty # 0
      THEN
        DEC(a.Minuty);
      ELSE
        DEC(a.Stopnie);
        a.Minuty := 59;
      END (* if a.Minuty *);
      INC(a.DziesTys, DzielnikMin);
    END (* if a.DziesTys *);
    IF a.Minuty < b.Minuty
    THEN
      DEC(a.Stopnie);
      INC(a.Minuty, 60);
    END (* if a.Minuty *);
    DEC(a.Stopnie, b.Stopnie);
    DEC(a.Minuty, b.Minuty);
    DEC(a.DziesTys, b.DziesTys);
    IF odwr
    THEN
      Odwr(a);
    END (* if odwr *);
    c := a;
  END OdejmijPolozenieGeo;

  PROCEDURE SredniPolozenieGeo
            (     a,
                  b : WspGeo;
              VAR c : WspGeo );
  VAR
    reszta : CARDINAL;

  BEGIN
    DodajPolozenieGeo(a, b, c);
    reszta := (c.Stopnie MOD 2) * 60;
    c.Stopnie := c.Stopnie DIV 2;
    INC(c.Minuty, reszta);
    reszta := (c.Minuty MOD 2) * DzielnikMin;
    c.Minuty := c.Minuty DIV 2;
    INC(c.DziesTys, reszta);
    c.DziesTys := c.DziesTys DIV 2;
  END SredniPolozenieGeo;

  PROCEDURE Rad
            ( VAR a : WspGeo ) : REAL;
  VAR
    KatWStopniach : REAL;

  BEGIN
    KatWStopniach := FLOAT(ABS(a.Stopnie)) + FLOAT(a.Minuty) / 60.0 + FLOAT(
                     a.DziesTys) / (60.0 * FLOAT(DzielnikMin));
    IF (a.Stopnie < 0)
    THEN
      KatWStopniach := -KatWStopniach
    END (* if *);
    RETURN KatWStopniach * M_PI / 180.0;
  END Rad;

  PROCEDURE Odl2Geo
            (     OdlWMilach    : REAL;
                  DlugoscMinuty : REAL;
              VAR k             : WspGeo );
  VAR
    mf : REAL;
    mi : CARDINAL;

  BEGIN
    mf := OdlWMilach / DlugoscMinuty;   (* calkowita ilosc minut katawych *)
    mi := TRUNC(ABS(mf));
    k.Stopnie := mi DIV 60;
    k.Minuty := mi MOD 60;
    k.DziesTys := TRUNC((ABS(mf) - FLOAT(mi)) * FLOAT(DzielnikMin));
    IF mf < 0.0
    THEN
      Odwr(k);
    END (* if mf *);
  END Odl2Geo;

  PROCEDURE Mile
            (    a : WspGeo ) : REAL;
  VAR
    m    : REAL;
    odwr : BOOLEAN;

  BEGIN
    IF a.Stopnie > 180
    THEN
      Odwr(a);
      odwr := TRUE;
    ELSE
      odwr := FALSE;
    END (* if a.Stopnie *);
    m := FLOAT(ABS(a.Stopnie)) * 60.0 + FLOAT(a.Minuty) + FLOAT(a.DziesTys) /
         FLOAT(DzielnikMin);
    IF a.Stopnie < 0
    THEN
      m := -m;
    END (* if a.Stopnie *);
    IF odwr
    THEN
      RETURN -m;
    ELSE
      RETURN m;
    END (* if odwr *);
  END Mile;

  PROCEDURE Geo2Kat
            (     pg  : PolozenieGeo;
              VAR pk  : PolozenieBiegunowe;
                  rec : GlownyOdbiornikT   );
  VAR
    SredniRownoleznik : WspGeo;  (* dokola ziemia jest plaska *)
    OdlegloscRownol   : REAL;
    OdlegloscPoludn   : REAL;
    tmp               : WspGeo;

  BEGIN
    WITH Odniesienie[rec] DO
      SredniPolozenieGeo(pg.Szerokosc, Szerokosc, SredniRownoleznik);
      OdejmijPolozenieGeo(pg.Dlugosc, Dlugosc, tmp);
      OdlegloscRownol := Mile(tmp);
      OdejmijPolozenieGeo(pg.Szerokosc, Szerokosc, tmp);
    END (* with Odniesienie *);
    OdlegloscPoludn := Mile(tmp);
    (* modyfikacja ze wzgledu na odchylenie od rownika *)
    OdlegloscRownol := OdlegloscRownol * cos(Rad(SredniRownoleznik));
    pk.Odleglosc := sqrt(Sqr(OdlegloscRownol) + Sqr(OdlegloscPoludn));
    (* IF pk.Odleglosc = 0.0 THEN pk.Kat := 0.0; ELSE pk.Kat := ACos(
       ABS(OdlegloscPoludn) / pk.Odleglosc ); END; pk.Kat := pk.Kat*180.0/M_PI;
       IF OdlegloscRownol > 0.0 THEN IF OdlegloscPoludn < 0.0 THEN pk.Kat :=
       180.0 + pk.Kat; ELSE (* nic *) END; ELSE IF OdlegloscPoludn < 0.0 THEN
       pk.Kat := 180.0 - pk.Kat; ELSE pk.Kat := -pk.Kat; END; END; *)
    IF pk.Odleglosc = 0.0
    THEN
      pk.Kat := 0.0;
    ELSE
      pk.Kat := ACos(OdlegloscPoludn / pk.Odleglosc);
    END (* if pk.Odleglosc *);
    pk.Kat := pk.Kat * 180.0 / M_PI;
    IF OdlegloscRownol < 0.0
    THEN
      pk.Kat := 360.0 - pk.Kat;
    END (* if OdlegloscRownol *);
    pk.Kat := pk.Kat + Deklinacja;
  END Geo2Kat;

  (* (* The program uses the following values: Equatorial radius: a = 6378.533
     km +/- 0.437 km; Polar radius: b = 6356.912 km +/- 0.437 km. Distance
     between two points on earth surface (spherical approximatiion). Given the
     latitude and longitude angles of two points P1 and P2 on the earth's
     surface, one can compute a good estimate of the distance between the two
     points by approximating the earth as a perfect sphere. One uses an
     estimate of the earth's mean radius for this purpose. From the values in
     Earth data One has the following estimate for the mean radius of the
     earth: R = (a + b)/2 = 6367.723 km, (1) where: R: Estimate of earth's mean
     radius (km); a: Earth's equatorial radius (6378.533 km); b: Earth's polar
     radius (6356.912 km); To compute the distance between points P1 and P2 one
     evaluates the angle subtended by the sphere's radii to P1 and P2:
     cos(alfa12) = cos(fi_2-fi_1)+cos(fi_1)cos(fi_2)(cos(gama_2-gama_1)-1); (2)
     where alfa12 -> subtended angle (radian ) f1_1 -> latitude of point P1
     (radian ) f1_2 -> latitude of point P2 (radian ) gama_1 -> longitude of
     point P1 (radian ) gama_2 -> longitude of point P2 (radian ) The proof of
     equation (2) is elementary and is left as an exercise to the reader.
     (Hint: Define a spherical coordinate system. Transform to Cartesian
     coordinates. Express the two radial vectors with their Cartesian
     components and extract the subtended angle from their scalar product). The
     distance between P1 and P2 is: d = R*alfa12 (3) Usefulness of the
     spherical approximation. Equation (3) constitutes a good approximation for
     small distances. It will give the right value for the length of the
     meridian: 40009.58 km well within the achievable accuracy of 2.7 km.
     However it underestimates the length of the equator by 68 km. Clearly, one
     needs a correction taking the ellipticity of the earth into account if one
     wants to realize the achievable accuracy. Distance between two points on
     earth surface (Ellipsoid approximation). Given the latitude and longitude
     angles of two points P1 and P2 on the earth's surface, Grinwich uses the
     following equations to compute an improved estimate of the distance
     between the two points. One approximates the earth's shape by an
     ellipsoid. From the values in Earth data one defines the following
     parameter: k^2 = (a^2-b^2)/4b^2; (4) where: a: Earth's equatorial radius
     (6378.533 km); b: Earth's polar radius (6356.912 km); The distance between
     P1 and P2 is given by the improved approximation: d = alfa12 a(1-k^2 p)
     (5) whith p = 1-[sin(2 fi_2)-sin(2 fi_1)]/[2(fi_2-fi_1)] (6) in case fi_2
     ->fi_1 one takes the limit: p -> 1-cos(2 fi_2) (7) d -> distance between
     P1 and P2 along the Earth's surface alfa12 -> subtended angle (radian )
     f1_1 -> latitude of point P1 (radian ) f1_2 -> latitude of point P2
     (radian ) gama_1 -> longitude of point P1 (radian ) gama_2 -> longitude of
     point P2 (radian ) The proof of equation (5) is elementary and is left as
     an exercise to the reader. (Hint: Express the earth's radius as a function
     of the latitude angle. Substitute in equation (3) and integrate from the
     latitude of P1 to the latitude of P2. Expand the integrand of this
     elliptic integral in a Taylor series and discard the terms of degree 3 and
     above). The equation for the subtended angle is given by equation (2) in
     Sphere approximation. Neglecting the error on latitude and longitude, one
     has the following relation to compute the error on the distance: delta d =
     alfa12 delta a with delta a = 0.437km (8) as given in Earth data.
     Usefulness of the ellipsoid approximation. Equation (5) will give the
     right value of the meridian length: 40009.58 km. It also gives the correct
     value of the equator length: 40077.5 km within the achievable accuracy of
     2.7 km. Ultimately, the distance's accuracy will depend on the errors
     associated with the determination of the latitudes and longitudes. In
     practice, you can therefore expect that your error will be greater or
     equal to the figure quoted by the program. *) PROCEDURE Geo2Kat( pg :
     PolozenieGeo; VAR pk : PolozenieBiegunowe ); CONST SredniPromienZiemi =
     6367.723 (* km*) /1.852; (* w milach *) PromienZiemiNaRowniku = 6378.533
     (* km*) /1.852; (* w milach *) PromienZiemiNaBiegunie = 6356.912 (* km*)
     /1.852; (* w milach *) PromienZiemiNaRownikuKw =
     PromienZiemiNaRowniku*PromienZiemiNaRowniku; PromienZiemiNaBiegunieKw =
     PromienZiemiNaBiegunie*PromienZiemiNaBiegunie; VAR Sz, Dl : REAL; BEGIN
     Sz1 := Rad(pg.Szerokosc); Dl1 := Rad(pg.Dlugosc); KatOdSrodka :=
     cos(Sz2-Sz1)+cos(Sz1)*cos(Sz2)*(cos(Dl2-Dl1)-1); pk.Odleglosc :=
     KatOdSrodka * PromienZiemi; IF JesliElipsoida THEN IF ABS( Sz2-Sz1) <
     0.001 THEN p := 1-cos(2*Sz2); ELSE p :=
     1-(sin(2*Sz2)-sin(2*Sz1))/(2*(Sz2-Sz1)); END; pk.Odleglosc := KatOdSrodka
     * PromienZiemiNaRowniku *

     (1-p*(PromienZiemiNaRownikuKw-PromienZiemiNaBiegunieKw)/(4*PromienZiemiNaBiegun
     (* Blad jest rowny -> KatOdSrodka*437[m] *) END; (* *) END Geo2Kat; *)

  PROCEDURE Kat2Geo
            (     pk  : PolozenieBiegunowe;
              VAR pg  : PolozenieGeo;
                  rec : GlownyOdbiornikT   );
  VAR
    OdlegloscRownol   : REAL;
    OdlegloscPoludn   : REAL;
    KatWRadianach     : REAL;
    SredniRownoleznik : WspGeo;  (* dokola ziemia jest plaska *)

  BEGIN
    KatWRadianach := pk.Kat * M_PI / 180.0;
    OdlegloscRownol := pk.Odleglosc * sin(KatWRadianach);
    OdlegloscPoludn := pk.Odleglosc * cos(KatWRadianach);
    Odl2Geo(OdlegloscPoludn, 1.0, pg.Szerokosc);
    WITH Odniesienie[rec] DO
      DodajPolozenieGeo(pg.Szerokosc, Szerokosc, pg.Szerokosc);
      pg.Szerokosc.Stopnie := pg.Szerokosc.Stopnie MOD 360;
      SredniPolozenieGeo(pg.Szerokosc, Szerokosc, SredniRownoleznik);
      Odl2Geo(OdlegloscRownol, cos(Rad(SredniRownoleznik)), pg.Dlugosc);
      DodajPolozenieGeo(pg.Dlugosc, Dlugosc, pg.Dlugosc);
    END (* with Odniesienie *);
    pg.Dlugosc.Stopnie := pg.Dlugosc.Stopnie MOD 360;
  END Kat2Geo;

END GeoArithmetic.
