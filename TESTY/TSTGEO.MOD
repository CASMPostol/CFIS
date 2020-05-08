MODULE TstGeo;

IMPORT
  DebugPMD;
FROM GeoArithmetic IMPORT
  Odniesienie, Deklinacja, Geo2Kat, Kat2Geo;
FROM CommonTypes IMPORT
  PolozenieGeo, PolozenieBiegunowe;
FROM StdIO IMPORT
  sprintf3, sprintf2;
FROM Terminal IMPORT
  WriteString, WriteLn;



CONST
  I_D = 2;

VAR
  pg : PolozenieGeo;
  pk : PolozenieBiegunowe;
  i : CARDINAL;
  s : ARRAY[0..100] OF CHAR;
BEGIN
  Odniesienie.Dlugosc.Stopnie := 19;
  Odniesienie.Dlugosc.Minuty := 38;
  Odniesienie.Dlugosc.Setne := 29;
  Odniesienie.Szerokosc.Stopnie := 51;
  Odniesienie.Szerokosc.Minuty := 48;
  Odniesienie.Szerokosc.Setne := 2;
  Deklinacja := 0.0;
  pg := Odniesienie;
  FOR i := 0 TO 80 DO
    pk.Odleglosc := FLOAT(i);
    pk.Kat := 278.0;
    Kat2Geo( pk, pg );
(*
    INC( pg.Dlugosc.Minuty );
    IF (pg.Dlugosc.Minuty >= 60) THEN
      pg.Dlugosc.Minuty := 0;
      INC( pg.Dlugosc.Stopnie );
    END;
    INC( pg.Szerokosc.Minuty, 5 );
    IF (pg.Szerokosc.Minuty >= 60) THEN
      pg.Szerokosc.Minuty := pg.Szerokosc.Minuty MOD 60;
      INC( pg.Szerokosc.Stopnie );
    END;
*)
(*
    IF pg.Dlugosc.Minuty >= I_D THEN
      DEC( pg.Dlugosc.Minuty, I_D );
    ELSE
      pg.Dlugosc.Minuty := 59 - (I_D-pg.Dlugosc.Minuty);
      DEC( pg.Dlugosc.Stopnie );
    END;
    INC( pg.Szerokosc.Minuty, 1 );
    IF (pg.Szerokosc.Minuty >= 60) THEN
      pg.Szerokosc.Minuty := pg.Szerokosc.Minuty MOD 60;
      INC( pg.Szerokosc.Stopnie );
    END;
*)
    Geo2Kat( pg, pk );
    sprintf2( s,
             "Odleglosc do %dø%02d'%02dE,%dø%02d'%02dN wynosi %lfø i %lf NM",
             pg,
             pk );
    WriteString( s );
    WriteLn;
  END;
END TstGeo.
