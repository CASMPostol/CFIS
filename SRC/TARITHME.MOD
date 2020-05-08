IMPLEMENTATION MODULE TArithmetic;

FROM MathLib0 IMPORT
  real, cos, sqrt, sin, arctan;
FROM Math IMPORT
  ACos, Sqr, M_PI;
FROM CommonTypes IMPORT
   PolozenieBiegunowe;

  PROCEDURE Kierunek(od,do : PolozenieBiegunowe ) : REAL;
  VAR
      deltaKat, deltaa,deltab, res : REAL;
  BEGIN
    deltaKat:=(do.Kat-od.Kat)*M_PI/180.0;
    deltaa := do.Odleglosc*cos(deltaKat) - od.Odleglosc;
    deltab := do.Odleglosc*sin(deltaKat);
    IF ABS(deltaa) < 0.003 THEN
      res := 90.0;
    ELSE
      res := arctan(deltab/deltaa) * 180.0 /M_PI;
    END;
    IF deltaa<0.0 THEN
      res := res+180.0;
    END;  
    res := res + od.Kat;
    WHILE res>=360.0 DO
      res := res - 360.0
    END;
    WHILE res<=-360.0 DO
      res := res + 360.0
    END;
    RETURN res
  END Kierunek;

END TArithmetic.
