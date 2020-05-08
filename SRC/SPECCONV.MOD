(*.F- *)
(**********************************************************************
|  Title   : Roznorodne procedury konwersji
|  Author  : D.Arendt/M.Postol
|  System  : LOGITECH MODULA-2/86
|  History :
|    25-02-97: M.Postol
|      Dodalem RAngle100, SubDis
|
|  Copyright (C), CAS LODZ POLAND.
|  TEL: 42' 862 547, 42' 87 80 44 FAX/TEL: 42' 84 48 40
|
**********************************************************************)
(*.F+ *)

IMPLEMENTATION MODULE SpecConv;

  FROM CommonTypes IMPORT
    PolozenieGeo, NilValI, NilValC, SigNilVal, NumStrefy, DisNilVal;

  FROM NumberConversion IMPORT
    IntToString, CardToString;

  FROM StdIO IMPORT
    sprintf5, sprintf4, sprintf3, sprintf2, sprintf;


  FROM Strings IMPORT
    Insert, ConstAssign;

  FROM MathLib0 IMPORT
    entier, real;

  PROCEDURE CheckINil
            (     nr  : INTEGER;
              VAR str : ARRAY OF CHAR;
                  len : CARDINAL      ) : BOOLEAN;

  BEGIN
    IF (nr = NilValI) OR (nr = MIN(INTEGER))
    THEN
      ConstAssign("*****", str);
      str[len] := 0C;
      RETURN TRUE
    END (* if *);
    IF nr < 0
    THEN
      str[0] := '-'
    ELSE
      str[0] := ' '
    END (* if nr *);
    str[1] := '.';
    RETURN FALSE
  END CheckINil;

  PROCEDURE CheckCNil
            (     nr  : CARDINAL;
              VAR str : ARRAY OF CHAR;
                  len : CARDINAL      ) : BOOLEAN;

  BEGIN
    IF nr = NilValC
    THEN
      ConstAssign("*****", str);
      str[len] := 0C;
      RETURN TRUE
    END (* if nr *);
    str[0] := '.';
    RETURN FALSE
  END CheckCNil;

  PROCEDURE Int2Str
            (     nr  : INTEGER;
              VAR str : ARRAY OF CHAR;
                  len : CARDINAL      );

  BEGIN
    IF NOT CheckINil(nr, str, len)
    THEN
      IntToString(nr, str, len);
    END (* if *);
  END Int2Str;

  PROCEDURE Card2Str
            (     nr  : CARDINAL;
              VAR str : ARRAY OF CHAR;
                  len : CARDINAL      );

  BEGIN
    IF NOT CheckCNil(nr, str, len)
    THEN
      CardToString(nr, str, len);
    END (* if *);
  END Card2Str;

  PROCEDURE Int10Str
            (     nr  : INTEGER;
              VAR str : ARRAY OF CHAR;
                  len : CARDINAL      );
  VAR
    aux : ARRAY [0 .. 3] OF CHAR;

  BEGIN
    IF CheckINil(nr, str, len)
    THEN
      RETURN;
    END (* if CheckINil *);
    nr := ABS(nr);
    str[2] := CHR(nr MOD 10 + 30H);
    str[3] := 0C;
    IntToString(nr DIV 10, aux, len - 3);
    Insert(aux, str, 1);
    str[len] := 0C;
  END Int10Str;

  PROCEDURE Card10Str
            (     nr  : CARDINAL;
              VAR str : ARRAY OF CHAR;
                  len : CARDINAL      );
  VAR
    aux : ARRAY [0 .. 3] OF CHAR;

  BEGIN
    IF CheckCNil(nr, str, len)
    THEN
      RETURN;
    END (* if CheckCNil *);
    str[1] := CHR(nr MOD 10 + 30H);
    str[2] := 0C;
    CardToString(nr DIV 10, aux, len - 2);
    Insert(aux, str, 0);
    str[len] := 0C;
  END Card10Str;

  PROCEDURE Int100Str
            (     nr  : INTEGER;
              VAR str : ARRAY OF CHAR;
                  len : CARDINAL      );
  VAR
    aux : ARRAY [0 .. 3] OF CHAR;

  BEGIN
    IF CheckINil(nr, str, len)
    THEN
      RETURN;
    END (* if CheckINil *);
    nr := ABS(nr);
    str[2] := CHR(nr DIV 10 MOD 10 + 30H);
    str[3] := CHR(nr MOD 10 + 30H);
    str[4] := 0C;
    IntToString(nr DIV 100, aux, len - 4);
    Insert(aux, str, 1);
    str[len] := 0C;
  END Int100Str;

  PROCEDURE Int100StrCalk
            (     nr  : INTEGER;
              VAR str : ARRAY OF CHAR;
                  len : CARDINAL      );

  BEGIN
    IF CheckINil(nr, str, len)
    THEN
      RETURN;
    END (* if CheckINil *);
    IntToString(nr DIV 100, str, len);
  END Int100StrCalk;

  PROCEDURE Card100Str
            (     nr  : CARDINAL;
              VAR str : ARRAY OF CHAR;
                  len : CARDINAL      );
  VAR
    aux : ARRAY [0 .. 3] OF CHAR;

  BEGIN
    IF CheckCNil(nr, str, len)
    THEN
      RETURN;
    END (* if CheckCNil *);
    nr := ABS(nr);
    str[1] := CHR(nr DIV 10 MOD 10 + 30H);
    str[2] := CHR(nr MOD 10 + 30H);
    str[3] := 0C;
    CardToString(nr DIV 100, aux, len - 3);
    Insert(aux, str, 0);
    str[len] := 0C;
  END Card100Str;

  PROCEDURE Ang100Str36
            (     nr  : INTEGER;
              VAR str : ARRAY OF CHAR;
                  len : CARDINAL      );
  VAR
    myAng : CARDINAL;

  BEGIN
    IF CheckINil(nr, str, len)
    THEN
      RETURN;
    END (* if CheckINil *);
    IF nr < 0
    THEN
      myAng := 36000 - CARDINAL(ABS(nr));
    ELSE
      myAng := nr;
    END (* if nr *);
    Card100Str(myAng, str, len);
  END Ang100Str36;

  PROCEDURE Ang100Str36Calk
            (     nr  : INTEGER;
              VAR str : ARRAY OF CHAR;
                  len : CARDINAL      );
  VAR
    myAng : CARDINAL;

  BEGIN
    IF CheckINil(nr, str, len)
    THEN
      RETURN;
    END (* if CheckINil *);
    IF nr < 0
    THEN
      myAng := 36000 - CARDINAL(ABS(nr));
    ELSE
      myAng := nr;
    END (* if nr *);
    CardToString(myAng DIV 100, str, len);
  END Ang100Str36Calk;

  PROCEDURE Int500Str
            (     nr  : INTEGER;
              VAR str : ARRAY OF CHAR;
                  len : CARDINAL      );
  VAR
    aux : ARRAY [0 .. 3] OF CHAR;

  BEGIN
    IF CheckINil(nr, str, len)
    THEN
      RETURN;
    END (* if CheckINil *);
    nr := ABS(nr) DIV 5;
    str[2] := CHR(nr DIV 10 MOD 10 + 30H);
    str[3] := CHR(nr MOD 10 + 30H);
    str[4] := 0C;
    IntToString(nr DIV 100, aux, len - 4);
    Insert(aux, str, 1);
    str[len] := 0C;
  END Int500Str;

  PROCEDURE Feed500Str
            (     nr  : INTEGER;
              VAR str : ARRAY OF CHAR;
                  len : CARDINAL      );
  VAR
    feets : INTEGER;

  BEGIN
    IF (nr # SigNilVal) AND (nr < 2633)
    THEN
      feets := entier(real(nr) * 6076.1 / 500.0 + 0.5);
    ELSE
      feets := SigNilVal;
    END (* if nr *);
    Int2Str(feets, str, len);
  END Feed500Str;

  PROCEDURE Card500Str
            (     nr  : CARDINAL;
              VAR str : ARRAY OF CHAR;
                  len : CARDINAL      );
  VAR
    aux : ARRAY [0 .. 3] OF CHAR;

  BEGIN
    IF CheckCNil(nr, str, len)
    THEN
      RETURN;
    END (* if CheckCNil *);
    nr := ABS(nr) DIV 5;
    str[1] := CHR(nr DIV 10 MOD 10 + 30H);
    str[2] := CHR(nr MOD 10 + 30H);
    str[3] := 0C;
    CardToString(nr DIV 100, aux, len - 3);
    Insert(aux, str, 0);
    str[len] := 0C;
  END Card500Str;

  PROCEDURE Int1000Str
            (     nr  : INTEGER;
              VAR str : ARRAY OF CHAR;
                  len : CARDINAL      );
  VAR
    aux : ARRAY [0 .. 3] OF CHAR;

  BEGIN
    IF CheckINil(nr, str, len)
    THEN
      RETURN;
    END (* if CheckINil *);
    nr := ABS(nr);
    str[2] := CHR(nr DIV 100 MOD 10 + 30H);
    str[3] := CHR(nr DIV 10 MOD 10 + 30H);
    str[4] := CHR(nr MOD 10 + 30H);
    str[5] := 0C;
    IntToString(nr DIV 100, aux, len - 5);
    Insert(aux, str, 1);
    str[len] := 0C;
  END Int1000Str;

  PROCEDURE Angle100
            (    a360 : INTEGER ) : INTEGER;

  BEGIN
    a360 := a360 MOD 360;
    IF ABS(a360) <= 180
    THEN
    (* ok *)
    ELSIF a360 > 0
    THEN
      DEC(a360, 360);
    ELSE
      INC(a360, 360);
    END (* if ABS *);
    RETURN a360 * 100;
  END Angle100;

  PROCEDURE RAngle100
            (    a360 : REAL ) : INTEGER;

  BEGIN
    WHILE ABS(a360) > 180.0 DO
      IF a360 > 0.0 
      THEN
        a360 := a360 - 360.0;
      ELSE
        a360 := a360 + 360.0;
      END (* if ABS *);
    END;
    RETURN entier(a360 * 100.0 + 0.5);
  END RAngle100;
  
  PROCEDURE AngleDeg
            (    a100 : INTEGER ) : INTEGER;

  BEGIN
    IF a100 = MIN(INTEGER)
    THEN
      RETURN a100;
    ELSIF a100 >= 0
    THEN
      INC(a100, 50);
      a100 := a100 DIV 100;
    ELSE
      DEC(a100, 50);
      a100 := a100 DIV 100 + 360;
    END (* if a100 *);
    RETURN a100;
  END AngleDeg;

  PROCEDURE SubAngle100
            (    a,
                 b : INTEGER ) : INTEGER;
  VAR
    tmp : LONGINT;

  BEGIN
    IF (a = NilValI) OR (b = NilValI)
    THEN
      RETURN NilValI
    END (* if *);
    tmp := VAL(LONGINT, a) - VAL(LONGINT, b);
    tmp := tmp MOD VAL(LONGINT, 36000);
    IF tmp >= VAL(LONGINT, 18000)
    THEN
      DEC(tmp, 36000);
    ELSIF tmp < VAL(LONGINT, -18000)
    THEN
      INC(tmp, 36000);
    END (* if ABS *);
    RETURN VAL(INTEGER, tmp);
  END SubAngle100;

  PROCEDURE AddAngle100
            (    a,
                 b : INTEGER ) : INTEGER;
  VAR
    tmp : LONGINT;

  BEGIN
    IF (a = MIN(INTEGER)) OR (b = MIN(INTEGER))
    THEN
      RETURN MIN(INTEGER)
    END (* if *);
    tmp := VAL(LONGINT, a) + VAL(LONGINT, b);
    tmp := tmp MOD VAL(LONGINT, 36000);
    IF tmp >= VAL(LONGINT, 18000)
    THEN
      DEC(tmp, 36000);
    ELSIF tmp < VAL(LONGINT, -18000)
    THEN
      INC(tmp, 36000);
    END (* if ABS *);
    RETURN VAL(INTEGER, tmp);
  END AddAngle100;

  PROCEDURE SubAng360
            (    a,
                 minusB : REAL ) : REAL;
  VAR
    res : REAL;

  BEGIN
    res := a - minusB;
    IF res <= -180.0
    THEN
      res := res + 360.0;
    ELSIF res > 180.0
    THEN
      res := res - 360.0;
    END (* if alfa *);
    RETURN res;
  END SubAng360;

  PROCEDURE AfterAngle100
            (    a,
                 awaited : INTEGER;
                 dirplus : BOOLEAN ) : BOOLEAN;
  VAR
    d : LONGINT;

  BEGIN
    d := VAL(LONGINT, a) - VAL(LONGINT, awaited);
    IF dirplus
    THEN
      RETURN (d >= VAL(LONGINT, 0)) OR (d < -VAL(LONGINT, 18000));
    ELSE
      RETURN (d <= VAL(LONGINT, 0)) OR (d > VAL(LONGINT, 18000));
    END (* if dirplus *);
  END AfterAngle100;

  PROCEDURE SubNormal
            (    a,
                 minusb : INTEGER ) : INTEGER;

  BEGIN
    RETURN a - minusb;
  END SubNormal;

  PROCEDURE AddNormal
            (    a,
                 plusb : INTEGER ) : INTEGER;

  BEGIN
    RETURN a + plusb;
  END AddNormal;

  PROCEDURE  GorszeBoDalszeR
             (VAR max  : REAL;
                  cv   : REAL);
  BEGIN
    IF ABS( max ) < ABS (cv) THEN
      max := cv;
    END;
  END GorszeBoDalszeR;

  PROCEDURE GorszeBoDalsze
            ( VAR val : INTEGER;
                  cv,
                  opt : INTEGER );

  BEGIN
    IF (cv # NilValI) AND ((val = NilValI) OR (ABS(val - opt) < ABS(cv - opt)))
    THEN
      val := cv;
    END (* if *);
  END GorszeBoDalsze;

  PROCEDURE GorszeBoBlisze
            ( VAR val : INTEGER;
                  cv,
                  opt : INTEGER );

  BEGIN
    IF (cv # NilValI) AND ((val = NilValI) OR (ABS(val - opt) > ABS(cv - opt)))
    THEN
      val := cv;
    END (* if *);
  END GorszeBoBlisze;

  PROCEDURE GorszeBoMniejszePol
            ( VAR val  : INTEGER;
                  cv,
                  bias : INTEGER );

  BEGIN
    IF (cv # NilValI) AND ((val = NilValI) OR (val + bias > cv))
    THEN
      val := cv - bias;
    END (* if *);
  END GorszeBoMniejszePol;

  PROCEDURE GorszeBoMniejsze
            ( VAR val : INTEGER;
                  cv  : INTEGER );

  BEGIN
    IF (cv # NilValI) AND ((val = NilValI) OR (val > cv))
    THEN
      val := cv;
    END (* if *);
  END GorszeBoMniejsze;

  PROCEDURE GorszeBoWieksze
            ( VAR val : INTEGER;
                  cv  : INTEGER );

  BEGIN
    IF (cv # NilValI) AND ((val = NilValI) OR (val < cv))
    THEN
      val := cv;
    END (* if *);
  END GorszeBoWieksze;

  PROCEDURE GorszeBoMniejszeM60
            ( VAR val : INTEGER;
                  cv  : INTEGER );

  BEGIN
    IF (cv # NilValI) AND ((val = NilValI) OR (val - 60 > cv))
    THEN
      val := cv + 60;
    END (* if *);
  END GorszeBoMniejszeM60;

  PROCEDURE GorszeBoMniejsze400
            ( VAR val : INTEGER;
                  cv  : INTEGER );

  BEGIN
    IF (cv # NilValI) AND ((val = NilValI) OR (val + 400 > cv))
    THEN
      val := cv - 400;
    END (* if *);
  END GorszeBoMniejsze400;

  PROCEDURE GorszeBoMniejsze800
            ( VAR val : INTEGER;
                  cv  : INTEGER );

  BEGIN
    IF (cv # NilValI) AND ((val = NilValI) OR (val + 800 > cv))
    THEN
      val := cv - 800;
    END (* if *);
  END GorszeBoMniejsze800;

  PROCEDURE GorszeBoMniejsze300
            ( VAR val : INTEGER;
                  cv  : INTEGER );

  BEGIN
    IF (cv # NilValI) AND ((val = NilValI) OR (val + 300 > cv))
    THEN
      val := cv - 300;
    END (* if *);
  END GorszeBoMniejsze300;

  PROCEDURE GorszeBoMniejsze160
            ( VAR val : INTEGER;
                  cv  : INTEGER );

  BEGIN
    IF (cv # NilValI) AND ((val = NilValI) OR (val + 160 > cv))
    THEN
      val := cv - 160;
    END (* if *);
  END GorszeBoMniejsze160;

  PROCEDURE GorszeBoMniejsze5000
            ( VAR val : INTEGER;
                  cv  : INTEGER );

  BEGIN
    IF (cv # NilValI) AND ((val = NilValI) OR (val + 5000 > cv))
    THEN
      val := cv - 5000;
    END (* if *);
  END GorszeBoMniejsze5000;

  PROCEDURE GorszeBoMniejsze500
            ( VAR val : INTEGER;
                  cv  : INTEGER );

  BEGIN
    IF (cv # NilValI) AND ((val = NilValI) OR (val + 500 > cv))
    THEN
      val := cv - 500;
    END (* if *);
  END GorszeBoMniejsze500;

  PROCEDURE GorszeBoMniejsze1500
            ( VAR val : INTEGER;
                  cv  : INTEGER );

  BEGIN
    IF (cv # NilValI) AND ((val = NilValI) OR (val + 1500 > cv))
    THEN
      val := cv - 1500;
    END (* if *);
  END GorszeBoMniejsze1500;

  PROCEDURE GorszeBoMniejsze2000
            ( VAR val : INTEGER;
                  cv  : INTEGER );

  BEGIN
    IF (cv # NilValI) AND ((val = NilValI) OR (val + 2000 > cv))
    THEN
      val := cv - 2000;
    END (* if *);
  END GorszeBoMniejsze2000;

  PROCEDURE GorszeBoDalszeOdZera
            ( VAR val : INTEGER;
                  cv  : INTEGER );

  BEGIN
    IF (val = NilValI) OR ((cv # NilValI) AND (ABS(val) < ABS(cv)))
    THEN
      val := cv;
    END (* if *);
  END GorszeBoDalszeOdZera;

  PROCEDURE  entierCheck( in: REAL; VAR out: INTEGER): BOOLEAN;
  BEGIN
    IF (in < real(MAX(INTEGER))) AND (in > real(MIN(INTEGER)) )  THEN
      out := entier(in);
      RETURN TRUE
    ELSE
      RETURN FALSE;
    END;
  END entierCheck;

  PROCEDURE Int2StrCntr
            (     nr  : INTEGER;
              VAR str : ARRAY OF CHAR;
                  len : CARDINAL      );

  BEGIN
    IF nr = SigNilVal
    THEN
      ConstAssign("     ", str);
    ELSE
      CASE VAL(NumStrefy, nr) OF
        ns_toA :
          ConstAssign("  ¯ A", str);
        |
        ns_AB :
          ConstAssign("A ¯ B", str);
        |
        ns_BCorT :
          ConstAssign("B¯C/T", str);
        |
        ns_CorTD :
          ConstAssign("C/T¯D", str);
        |
        ns_DE :
          ConstAssign("D ¯ E", str);
        |
        ns_no :
          ConstAssign("   ", str);
      END (* case VAL *);
    END (* if *);
  END Int2StrCntr;

  PROCEDURE Div (A, byB: INTEGER): INTEGER;
  BEGIN
    IF A = SigNilVal THEN
      RETURN SigNilVal;
    ELSE
      RETURN A DIV byB;
    END;
  END Div;

  PROCEDURE Mul(A, byB: INTEGER): INTEGER;
  BEGIN
    IF A = SigNilVal THEN
      RETURN SigNilVal;
    ELSE
      RETURN A * byB;
    END;
  END Mul;

  PROCEDURE Add(A, byB: INTEGER): INTEGER;
  BEGIN
    IF A = SigNilVal THEN
      RETURN SigNilVal;
    ELSE
      RETURN A + byB;
    END;
  END Add;

  PROCEDURE Sub(A, byB: INTEGER): INTEGER;
  BEGIN
    IF (A = SigNilVal) OR (byB = SigNilVal) THEN
      RETURN SigNilVal;
    ELSE
      RETURN A - byB;
    END;
  END Sub;

 PROCEDURE KonwertPolozGeoNaCiagZnak (
                                     polozGeo :PolozenieGeo;
                                     N_S_E_W :BOOLEAN;
                                     VAR poloStr :ARRAY OF CHAR);
 (*N_S_E_W = TRUE szerokosc *)
 BEGIN
 IF N_S_E_W THEN
    sprintf3( poloStr, "%dø%02d.%04d'E",polozGeo.Szerokosc.Stopnie,
              polozGeo.Szerokosc.Minuty,
              polozGeo.Szerokosc.DziesTys );
    RETURN
 ELSE
   sprintf3( poloStr, "%dø%02d.%04d'E", polozGeo.Dlugosc.Stopnie,
              polozGeo.Dlugosc.Minuty,
              polozGeo.Dlugosc.DziesTys );
     RETURN
 END;
 END KonwertPolozGeoNaCiagZnak;


  PROCEDURE SubDis(A, byB: CARDINAL): CARDINAL;
  BEGIN
    IF (A = DisNilVal) OR (byB = DisNilVal) THEN
      RETURN DisNilVal;
    ELSE
      IF A > byB  THEN
        RETURN A - byB;
      ELSE
        RETURN byB - A;
      END;
    END;
  END SubDis;

END SpecConv.
