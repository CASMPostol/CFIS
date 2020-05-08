MODULE GPS;

FROM Geo2Polar IMPORT
  PolozenieGeograficzne, PolozenieKatowe, PolozenieOdniesienia, KatGeo,
  Geo2Kat, Kat2Geo;
FROM  GPS_Nadawanie IMPORT
  Send, SetLatitude, SetLongitude;
IMPORT
  FIO;
FROM stdio IMPORT
  sprintf;


PROCEDURE TestLog( F   : FIO.File;
                   pg1 : PolozenieGeograficzne;
                   pg2 : PolozenieGeograficzne;
                   pk  : PolozenieKatowe );
VAR
  tbl : ARRAY [0..256] OF CHAR;
BEGIN
  sprintf( tbl, "%02dø%02d.%02dN %03dø%02d.%02dE,  %02dø%02d.%02dN %03dø%02d.%02dE, (%7.3lf,%7.3lf)"+15C+12C,
           pg1.Szerokosc.Stopnie,
           pg1.Szerokosc.Minuty,
           pg1.Szerokosc.Setne,
           pg1.Dlugosc.Stopnie,
           pg1.Dlugosc.Minuty,
           pg1.Dlugosc.Setne,
           pg2.Szerokosc.Stopnie,
           pg2.Szerokosc.Minuty,
           pg2.Szerokosc.Setne,
           pg2.Dlugosc.Stopnie,
           pg2.Dlugosc.Minuty,
           pg2.Dlugosc.Setne,
           pk.Odleglosc,
           pk.Kat );
  FIO.WrStr( F, tbl );
END TestLog;

PROCEDURE Test1;
VAR
  pg, pg1, pg2 : PolozenieGeograficzne;
  pk : PolozenieKatowe;
  F : FIO.File;
  i, j : INTEGER;
BEGIN
  pg := PolozenieGeograficzne(
               KatGeo( 53, 53, 53 ),
               KatGeo( 20, 20, 20 ));
  PolozenieOdniesienia( pg );
  F := FIO.Create( "TST.LOG" );
  FOR i := -1 TO 1 DO
    FOR j := -1 TO 1 DO
      pg1 := pg;
      INC( pg1.Szerokosc.Stopnie, i );
      INC( pg1.Dlugosc.Stopnie, j );
      Geo2Kat( pg1, pk );
      Kat2Geo( pk, pg2 );

      TestLog( F, pg1, pg2, pk );
    END;
  END;
  FIO.Close( F );
END Test1;


PROCEDURE Test2;
VAR
  i : CARDINAL;
  pg : PolozenieGeograficzne;
  pk : PolozenieKatowe;
BEGIN
  pg := PolozenieGeograficzne(
               KatGeo( 52, 49, 11 ),
               KatGeo( 19, 0, 77 ));
  PolozenieOdniesienia( pg );
  pk.Kat := 77.0;
  FOR i := 10 TO 0 BY -1 DO
    pk.Odleglosc := 4.0*LONGREAL(i);
    Kat2Geo( pk, pg );
    SetLatitude( pg.Szerokosc );
    SetLongitude( pg.Dlugosc );
    Send;
  END;
END Test2;


BEGIN
  Test1;
  Test2;
END GPS.