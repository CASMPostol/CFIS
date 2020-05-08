(*.F- *)
(**********************************************************************
|  Title   : Rysoanie samolotu - mnemomapa
|  Author  : M.Morawski ?
|  System  : LOGITECH MODULA-2/86
|  History :
|    14-09-96: M.Postol
|      schowane zmienne globalne
|    07-05-97: M.Postol
|      UpdateM dostaje kat przesuniety wzgledem 0N i musi byc 
|      skorygowany
|
|  Copyright (C), CAS LODZ POLAND.
|  TEL: 42' 862 547, 42' 87 80 44 FAX/TEL: 42' 84 48 40
|
**********************************************************************)
(*.F+ *)

IMPLEMENTATION MODULE Polozenie [ 0 ];

  IMPORT
    GrafTypes;

  FROM GrafTypes IMPORT
    POINT, RECT, WHITE, BLUE, BLACK, YELLOW, GREY, LT_BLUE, LT_GREEN;

  FROM SYSTEM IMPORT
    BYTE, ADR, SIZE;

  FROM Graphics IMPORT
    SetWindow, GetWindow, GetBank, SetBank, DP;

  FROM MathLib0 IMPORT
    sin, cos, entier, real;

  FROM BlockOps IMPORT
    BlockClear;

  FROM MMMouse IMPORT
    HideConditionally, ShowCursor;

  FROM HiLevGraf IMPORT
    Line;

  FROM Marks IMPORT
    (* TYPE *) AngMarksDsc, DisMarksDsc,
    (* PROCEDURE *) AngResetContiner, DisResetContiner, AngAddSample,
                    DisAddSample;

  FROM SpecConv IMPORT
    AngleDeg, AddAngle100;

  CONST
    MARKERSIZE = 15;  (* nieparzyste *)
    M_PI       = 3.1415926;
    okrag_Col  = GrafTypes.LT_GREEN;
    ZeroL      = VAL(LONGINT, 0);

  VAR
    Srodek        : POINT;
    Promien       : CARDINAL;
    MaxVal        : REAL;
    AktOdleglosc  : REAL;
    AktKat        : REAL;
    Narysowany    : CARDINAL;  (* 0 => nienarysowany *)
    Bufor         : ARRAY [0 .. MARKERSIZE - 1], [0 .. MARKERSIZE - 1] OF BYTE;
    Rect          : RECT;  (* Aktualnie zamazany prostokat *)
    ProcesAktywny : BOOLEAN;
    NCO           : BOOLEAN;
    angContiner   : AngMarksDsc;

  TYPE
    MarkerShape =
      ARRAY [0 .. MARKERSIZE - 1] OF BITSET;

  VAR
    MarkerShapes : ARRAY [0 .. 7] OF MarkerShape;
    Dir          : CARDINAL;
    CzesciOkregu : ARRAY [ 0 .. 35 ] OF CHAR;

  PROCEDURE InitMarkers;

    PROCEDURE FlipY
              (    Src,
                   Dest : CARDINAL );
    VAR
      i : CARDINAL;

    BEGIN
      FOR i := 0 TO MARKERSIZE - 1 DO
        MarkerShapes[Dest][MARKERSIZE - 1 - i] := MarkerShapes[Src][i];
      END (* for i *);
    END FlipY;

    PROCEDURE FlipX
              (    Src,
                   Dest : CARDINAL );
    VAR
      i,
      j : CARDINAL;

    BEGIN
      FOR i := 0 TO MARKERSIZE - 1 DO
        FOR j := 0 TO MARKERSIZE - 1 DO
          IF j IN MarkerShapes[Src][i]
          THEN
            INCL(MarkerShapes[Dest][i], MARKERSIZE - 1 - j);
          END (* if j *);
        END (* for j *);
      END (* for i *);
    END FlipX;

    PROCEDURE Rot90
              (    Src,
                   Dest : CARDINAL );
    VAR
      i,
      j : CARDINAL;

    BEGIN
      FOR i := 0 TO MARKERSIZE - 1 DO
        FOR j := 0 TO MARKERSIZE - 1 DO
          IF j IN MarkerShapes[Src][i]
          THEN
            INCL(MarkerShapes[Dest][MARKERSIZE - 1 - j], i);
          END (* if j *);
        END (* for j *);
      END (* for i *);
    END Rot90;

  BEGIN
    BlockClear(ADR(MarkerShapes), SIZE(MarkerShapes));
    (* na polnoc *)
    MarkerShapes[0][0] := BITSET(00080H);   (* °°°°°°°Û°°°°°°° *)
    MarkerShapes[0][1] := BITSET(00080H);   (* °°°°°°°Û°°°°°°° *)
    MarkerShapes[0][2] := BITSET(001C0H);   (* °°°°°°ÛÛÛ°°°°°° *)
    MarkerShapes[0][3] := BITSET(001C0H);   (* °°°°°°ÛÛÛ°°°°°° *)
    MarkerShapes[0][4] := BITSET(003E0H);   (* °°°°°ÛÛÛÛÛ°°°°° *)
    MarkerShapes[0][5] := BITSET(007F0H);   (* °°°°ÛÛÛÛÛÛÛ°°°° *)
    MarkerShapes[0][6] := BITSET(00FF8H);   (* °°°ÛÛÛÛÛÛÛÛÛ°°° *)
    MarkerShapes[0][7] := BITSET(01FFCH);   (* °°ÛÛÛÛÛÛÛÛÛÛÛ°° *)
    MarkerShapes[0][8] := BITSET(03FFEH);   (* °ÛÛÛÛÛÛÛÛÛÛÛÛÛ° *)
    MarkerShapes[0][9] := BITSET(071C7H);   (* ÛÛÛ°°°ÛÛÛ°°°ÛÛÛ *)
    MarkerShapes[0][10] := BITSET(001C0H);   (* °°°°°°ÛÛÛ°°°°°° *)
    MarkerShapes[0][11] := BITSET(003E0H);   (* °°°°°ÛÛÛÛÛ°°°°° *)
    MarkerShapes[0][12] := BITSET(003E0H);   (* °°°°°ÛÛÛÛÛ°°°°° *)
    MarkerShapes[0][13] := BITSET(00770H);   (* °°°°ÛÛÛ°ÛÛÛ°°°° *)
    MarkerShapes[0][14] := BITSET(00C18H);   (* °°°ÛÛ°°°°°ÛÛ°°° *)
    (* na NE *)
    MarkerShapes[1][0] := BITSET(00001H);   (* °°°°°°°°°°°°°°Û *)
    MarkerShapes[1][1] := BITSET(00006H);   (* °°°°°°°°°°°°ÛÛ° *)
    MarkerShapes[1][2] := BITSET(0000EH);   (* °°°°°°°°°°°ÛÛÛ° *)
    MarkerShapes[1][3] := BITSET(03FFCH);   (* °ÛÛÛÛÛÛÛÛÛÛÛÛ°° *)
    MarkerShapes[1][4] := BITSET(01FF8H);   (* °°ÛÛÛÛÛÛÛÛÛÛ°°° *)
    MarkerShapes[1][5] := BITSET(00FF8H);   (* °°°ÛÛÛÛÛÛÛÛÛ°°° *)
    MarkerShapes[1][6] := BITSET(00FF8H);   (* °°°ÛÛÛÛÛÛÛÛÛ°°° *)
    MarkerShapes[1][7] := BITSET(007F8H);   (* °°°°ÛÛÛÛÛÛÛÛ°°° *)
    MarkerShapes[1][8] := BITSET(003F8H);   (* °°°°°ÛÛÛÛÛÛÛ°°° *)
    MarkerShapes[1][9] := BITSET(007F8H);   (* °°°°ÛÛÛÛÛÛÛÛ°°° *)
    MarkerShapes[1][10] := BITSET(07EF8H);   (* ÛÛÛÛÛÛ°ÛÛÛÛÛ°°° *)
    MarkerShapes[1][11] := BITSET(03C78H);   (* °ÛÛÛÛ°°°ÛÛÛÛ°°° *)
    MarkerShapes[1][12] := BITSET(01C18H);   (* °°ÛÛÛ°°°°°ÛÛ°°° *)
    MarkerShapes[1][13] := BITSET(00C08H);   (* °°°ÛÛ°°°°°°Û°°° *)
    MarkerShapes[1][14] := BITSET(00400H);   (* °°°°Û°°°°°°°°°° *)
    FlipY(0, 4);
    Rot90(0, 2);
    FlipX(2, 6);
    FlipY(1, 3);
    FlipX(1, 7);
    FlipY(7, 5);
  END InitMarkers;

  PROCEDURE DrawMarker
            (    Dir : CARDINAL );
  VAR
    h : BOOLEAN;
    p : CARDINAL;
    i,
    j : INTEGER;

  BEGIN
    Rect.left := Srodek.x + entier(FLOAT(Promien) * (AktOdleglosc / MaxVal) *
                                   cos(-AktKat));
    Rect.top := Srodek.y + entier(FLOAT(Promien) * (AktOdleglosc / MaxVal) *
                                  sin(-AktKat));
    DEC(Rect.left, MARKERSIZE DIV 2);
    DEC(Rect.top, MARKERSIZE DIV 2);
    Rect.right := Rect.left + MARKERSIZE - 1;
    Rect.bottom := Rect.top + MARKERSIZE - 1;
    CASE Narysowany OF
      0 :
        Narysowany := GREY;
      |
      GREY :
        Narysowany := BLACK;
      |
      BLACK :
        Narysowany := GREY;
    END (* case Narysowany *);
    h := HideConditionally(Rect);
    p := GetBank();
    GetWindow(ADR(Bufor), Rect.left, Rect.top, Rect.right, Rect.bottom, 0,
              ZeroL);
    FOR i := 0 TO MARKERSIZE - 1 DO
      FOR j := 0 TO MARKERSIZE - 1 DO
        IF ORD(j) IN MarkerShapes[Dir][i]
        THEN
          DP((Rect.right + Rect.left) DIV 2 + (MARKERSIZE - 1) - j - MARKERSIZE
             DIV 2, (Rect.bottom + Rect.top) DIV 2 + i - MARKERSIZE DIV 2, CHR(
             Narysowany));
        END (* if ORD *);
      END (* for j *);
    END (* for i *);
    SetBank(p);
    IF h
    THEN
      ShowCursor;
    END (* if h *);
  END DrawMarker;

  PROCEDURE EraseMarker;
  VAR
    h : BOOLEAN;
    p : CARDINAL;

  BEGIN
    h := HideConditionally(Rect);
    p := GetBank();
    SetWindow(ADR(Bufor), Rect.left, Rect.top, Rect.right, Rect.bottom, 0,
              ZeroL);
    SetBank(p);
    IF h
    THEN
      ShowCursor;
    END (* if h *);
  END EraseMarker;

  PROCEDURE Start_Polozenie
            (    ASrodek  : POINT; (* polozenie srodka okregu *)
                 APromien : CARDINAL; (* promien okregu *)
                 AMaxVal  : REAL
                    (* Wartosc odpowiadajaca krancom okregu *) );

  BEGIN
    IF NOT ProcesAktywny
    THEN
      Srodek := ASrodek;
      Promien := APromien;
      MaxVal := AMaxVal;
      ProcesAktywny := TRUE;
    END (* if *);
  END Start_Polozenie;

  PROCEDURE DrawNCO;
  VAR
    ix : INTEGER;

    PROCEDURE LL
              (    Prom : CARDINAL );
    VAR
      x1,
      x2,
      y1,
      y2  : INTEGER;
      kat : REAL;

      PROCEDURE XY
                ( VAR x,
                      y : INTEGER );

      BEGIN
        x := entier(FLOAT(Prom) * sin(kat)) + Srodek.x;
        y := Srodek.y - entier(FLOAT(Prom) * cos(kat));
      END XY;

    BEGIN
      kat := real(ix * 10 - 5) * M_PI / 180.0;
      XY(x1, y1);
      kat := FLOAT(ix * 10 + 5) * M_PI / 180.0;
      XY(x2, y2);
      Line(x1, y1, x2, y2, CzesciOkregu[ix]);
    END LL;

  BEGIN
    FOR ix := 0 TO 35 DO
      IF CzesciOkregu[ix] # 0C
      THEN
        LL(Promien);
        LL(Promien - 1);
        LL(Promien + 1);
      END (* if CzesciOkregu *);
    END (* for ix *);
  END DrawNCO;

  PROCEDURE UpdateM
            (    Odleglosc : REAL;
                 Kat       : REAL;
                 Kierunek  : REAL );
    (* Polozenie we wspolrzednych biegunowych *)

  BEGIN
    IF ProcesAktywny
    THEN
      AktKat := 90.0 - ( Kat + real(StalyKat)/100.0 );
      AktKat := AktKat * M_PI / 180.0;
      AktOdleglosc := Odleglosc;
      Kierunek := Kierunek + 382.5;   (* 360+22.5*)
      Dir := TRUNC(Kierunek / 45.0) MOD 8;
      IF Narysowany # 0
      THEN
        EraseMarker();
      END (* if Narysowany *);
      IF NCO
      THEN   (* nowe czesci okregu *)
        NCO := FALSE;
        DrawNCO;
      END (* if NCO *);
      IF AktOdleglosc >= 0.0
      THEN
        DrawMarker(Dir);
      END (* if AktOdleglosc *);
    END (* if ProcesAktywny *);
  END UpdateM;

  PROCEDURE Stop_Polozenie();

  BEGIN
    ProcesAktywny := FALSE;
    IF Narysowany # 0
    THEN
      EraseMarker();
      Narysowany := 0;
    END (* if Narysowany *);
  END Stop_Polozenie;

  PROCEDURE RresetCzesciOkregu();
  VAR
    ix10 : CARDINAL;

  BEGIN
    AngResetContiner(angContiner);
    FOR ix10 := 0 TO 35 DO
      CzesciOkregu[ix10] := 0C;
    END (* for ix10 *);
    NCO := TRUE;
  END RresetCzesciOkregu;

  PROCEDURE NoweCzesciOkregu
            (    alfa : INTEGER );
  VAR
    currIndex : INTEGER;

  BEGIN
    alfa := AddAngle100( alfa, StalyKat );
    IF AngAddSample(alfa, angContiner, currIndex, 10 * 100)
    THEN
      CzesciOkregu[AngleDeg(currIndex) DIV 10] := CHR(okrag_Col);
      NCO := TRUE;
    END (* if AngAddSample *);
  END NoweCzesciOkregu;

  PROCEDURE Promienie
            ( VAR DoZrobienia,
                  Zrobione    : ARRAY OF CARDINAL;
                  Aktualny    : CARDINAL          );

    PROCEDURE Rysuj
              (    Kat   : CARDINAL;
                   kolor : BYTE     );
    VAR
      x,
      y : INTEGER;
      r : REAL;

    BEGIN
      IF Kat < 360
      THEN
        r := FLOAT(Kat);
        r := r * M_PI / 180.0;
        x := entier(FLOAT(Promien) * sin(r));
        y := entier(FLOAT(Promien) * cos(r));
        Line(Srodek.x, Srodek.y, Srodek.x + x, Srodek.y - y, kolor);
      END (* if Kat *);
    END Rysuj;
  VAR
    i   : CARDINAL;
    nar : BOOLEAN;

  BEGIN
    nar := FALSE;
    IF Narysowany # 0
    THEN
      EraseMarker();
      Narysowany := 0;
      nar := TRUE;
    END (* if Narysowany *);
    FOR i := 0 TO HIGH(DoZrobienia) DO
      Rysuj(DoZrobienia[i], LT_BLUE);
    END (* for i *);
    FOR i := 0 TO HIGH(Zrobione) DO
      Rysuj(Zrobione[i], LT_GREEN);
    END (* for i *);
    Rysuj( Aktualny, BLACK );
    IF nar
    THEN
      DrawMarker(Dir);
    END (* if nar *);
  END Promienie;

BEGIN
  StalyKat := 0;
  NCO := TRUE;
  AktOdleglosc := 0.0;
  Dir := 0;
  Narysowany := 0;
  Promien := 1;
  RresetCzesciOkregu();
  ProcesAktywny := FALSE;
  InitMarkers;
END Polozenie.
