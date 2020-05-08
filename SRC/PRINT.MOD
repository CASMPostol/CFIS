(*.F- *)
(**********************************************************************
|  Title   : Wykonywanie raportow
|  Author  : M.Morawski
|  System  : LOGITECH MODULA-2/86
|  History :
|    07-07-96: M.Postol
|      bledy przy funkcjach logarytmicznych
|      brak funkcji kompresji danych (gorszebo) nie poprawilem
|    19-07-96:M.Postol
|      bledy w procedurze ZnacznikiOdleglosci, PointB
|      zmiana procedury Opis
|    20-09-96: M.Postol
|      zdefiniowano nowe procedury WrFlagsTable, WrF_TablicaOdci
|    10-04-96 05:10pm: MM
|      zmiany w WrFlagsTable
|    01-19-97 11:03pm: MM
|      zablokowany PrnScreen
|    03-21-97 10:32am: MM
|      Punkt C wypisuje jako C/T
|    23-03-97: M.Postol
|      zmiana napisu w WypiszStrefy
|    Rel 3.0.: MPostol
|      przy wypisywaniu odcinkow wyswietlana jest dodatkowo informacja
|      o ilosci odcinkow pominietych.
|      podzielilem procedure opisujaca odcinki WrFlagsTable
|      i wydzielilem WrFlagsTableWHeading aby opisywac odcinki 
|      nie analizowane na orbicie VOR
|      - EvProc byl blad, bo uzyto INTEGER do przekazania numeru probki i 
|        bylo przekroczenie dla wysokich liczb
|      - Obsluga klawisza Print Screen nie moze wypisywac tekstow i 
|        wchodzic do monitora.
|
|  Copyright (C), CAS LODZ POLAND.
|  TEL: 42' 686 25 47
|  mailto: techsupp@cas.com.pl
|  http: www.cas.com.pl
|
**********************************************************************)
(*.F+ *)

IMPLEMENTATION MODULE Print;

  FROM Marks IMPORT
    (* TYPE *) AngMarksDsc, DisMarksDsc,
    (* PROCEDURE *) AngResetContiner, DisResetContiner, AngAddSample,
                    DisAddSample;

  FROM SYSTEM IMPORT
    TSIZE, WORD, ADDRESS, ADR;

  FROM SpecConv IMPORT
    Ang100Str36Calk, Int100StrCalk, Card500Str, ToStringProcT, SubDis;

  FROM FlagAnal IMPORT
    GetNextFrac, FlagsTable, OdcinekIdx, F_TablicaOdci;

  FROM CommonTypes IMPORT
    GlownyOdbiornikT, GetRecName, Str99, NumPunktu, zoneBDisIdx_T;

  IMPORT
    GrafTypes, GrafUtil, DrawEpson, FIO, NumberConversion,
    Strings, SYSTEM, MathLib0, BlockOps, StdIO, ASCII,
    CommonTypes, Files, MANAGER;

  FROM Strings IMPORT
    Concat, Length;

  FROM SoftIntHandlingManager IMPORT
    InstPrologueHnd, Template, PrintScreen, BreakChain;

  CONST
    ScreenMaxLen = 84;
  
  VAR
    PrevIdx  : INTEGER;
    Flagi    : FIO.File;
    flgEOF   : BOOLEAN;
    scaleDiv : CARDINAL;
    CoKtoraProbka: CARDINAL;

  PROCEDURE GorszeBoMniejsze
            ( VAR val : INTEGER;
                  cv  : INTEGER );

  BEGIN
    IF (val = CommonTypes.NilValI) OR ((cv # CommonTypes.NilValI) AND
       (val > cv))
    THEN
      val := cv;
    END (* if *);
  END GorszeBoMniejsze;

  PROCEDURE DalszeOdZera
            ( VAR val : INTEGER;
                  cv  : INTEGER );

  BEGIN
    IF (val = CommonTypes.NilValI) OR ((cv # CommonTypes.NilValI) AND (ABS(val)
       < ABS(cv)))
    THEN
      val := cv;
    END (* if *);
  END DalszeOdZera;

  PROCEDURE MaxY() : CARDINAL;

  BEGIN
    RETURN DrawEpson.MaxY() - 10;
  END MaxY;

  PROCEDURE log
            (    x : REAL ) : REAL;

  CONST
    LN_10 = 2.302585093;

  BEGIN
    RETURN MathLib0.ln(x) / LN_10;
  END log;

  PROCEDURE Wr
            (    ch : CHAR ) : BOOLEAN;

  BEGIN
    IF NOT TextModeOutProc(ch)
    THEN
      RETURN FALSE;
    END (* if *);
    IF ch >= ' '
    THEN
      INC(PrnX);
    END (* if ch *);
    IF ch = ASCII.cr
    THEN
      PrnX := 0;
    ELSIF ch = ASCII.lf
    THEN
      INC(PrnY);
    END (* if ch *);
    RETURN TRUE;
  END Wr;

  PROCEDURE WrPrn
            (    At  : CARDINAL;
                 str : ARRAY OF CHAR ) : BOOLEAN;
  VAR
    i : CARDINAL;
    j : CARDINAL;

  BEGIN (* WrPrn *)
    IF At >= PrnX
    THEN
      j := At - PrnX;
      FOR i := 1 TO j DO
        IF NOT Wr(' ')
        THEN
          RETURN FALSE;
        END (* if *);
      END (* for i *)
    END (* if At *);
    i := 0;
    WHILE (i <= HIGH(str)) & (str[i] # 0C) DO
      IF NOT Wr(str[i])
      THEN
        RETURN FALSE;
      END (* if *);
      INC(i);
    END (* while *);
    RETURN TRUE;
  END WrPrn;

  PROCEDURE WrLn() : BOOLEAN;

  BEGIN
    RETURN Wr(ASCII.cr) & Wr(ASCII.lf);
  END WrLn;

  PROCEDURE WrPrnLn
            (    At  : CARDINAL;
                 str : ARRAY OF CHAR ) : BOOLEAN;

  BEGIN
    RETURN WrPrn(At, str) & WrLn();
  END WrPrnLn;

  PROCEDURE InitA
            ( VAR d      : Desc;
                  FN     : ARRAY OF CHAR;
                  opis   : ARRAY OF CHAR;
                  Offset : INTEGER;
                  zakres : INTEGER;
                  od,
                  do     : INTEGER;
                  lg     : BOOLEAN      );
  VAR
    a  : SYSTEM.ADDRESS;
    t1,
    t2 : ARRAY [0 .. 31] OF CHAR;

  BEGIN
    WITH d DO
      File := FIO.Open(FN);
      IF File = MAX(CARDINAL)
      THEN
        Strings.Assign(FN, t1);
        a := SYSTEM.ADR(t1);
        StdIO.sprintf(t2, 'Nie mo¾na otworzy† pliku "%s"', a);
        GrafUtil.InfoBeep(t2, 3, 400);
      END (* if File *);
      Strings.Assign(opis, Opis);
      SklStala := Offset;
      Zakres := zakres;
      st := CommonTypes.NilValI;
      Binarne := FALSE;
      Logarytm := lg;
      IF lg
      THEN
        Przes := (log(MathLib0.real(do)) - log(MathLib0.real(od))) / 2.0 + log(
                 MathLib0.real(od));
        Mnoznik := MathLib0.real(zakres) / (log(MathLib0.real(do)) - log(
                   MathLib0.real(od)));
      ELSE
        Przes := (MathLib0.real(do) - MathLib0.real(od)) / 2.0 + MathLib0.real(
                 od);
        Mnoznik := MathLib0.real(zakres) / (MathLib0.real(do) - (MathLib0.real(
                   od)));
      END (* if lg *);
      Uzywane := TRUE;
    END (* with d *);
  END InitA;

  PROCEDURE InitB
            ( VAR d      : Desc;
                  opis   : ARRAY OF CHAR;
                  Neg    : BOOLEAN;
                  Offset : INTEGER;
                  zakres : INTEGER;
                  Pole   : CARDINAL      );

  BEGIN
    WITH d DO
      Strings.Assign(opis, Opis);
      SklStala := Offset;
      Zakres := zakres;
      Bit := Pole;
      st := CommonTypes.NilValI;
      Binarne := TRUE;
      Uzywane := TRUE;
      Negacja := Neg;
    END (* with d *);
  END InitB;

  PROCEDURE PointA
            ( VAR rec     : Desc;
                  cur_idx : INTEGER );
  VAR
    ZestawProbekDoWyboru : ARRAY [0 .. 99] OF INTEGER;
    i,
    x                    : INTEGER;
    Nil                  : INTEGER;
    r                    : REAL;

  BEGIN
    Nil := CommonTypes.NilValI;
    BlockOps.BlockSet(SYSTEM.ADR(ZestawProbekDoWyboru), SYSTEM.SIZE(
                      ZestawProbekDoWyboru), SYSTEM.ADR(Nil), SYSTEM.SIZE(Nil))
    ;
    WITH rec DO
(*RTSMain.Terminate( RTSMain.Warning );*)
      IF NOT FIO.Read(File,
                      SYSTEM.ADR(ZestawProbekDoWyboru),
                      CoKtoraProbka * SYSTEM.SIZE(INTEGER))
      THEN
        RETURN
      END (* if *);
      x := ZestawProbekDoWyboru[0];
      FOR i := 1 TO CoKtoraProbka - 1 DO
        IF Przes = 0.0
        THEN
        (* VORRdacq.*)
          DalszeOdZera(x, ZestawProbekDoWyboru[i]);
        ELSE
        (* VORRdacq.*)
          GorszeBoMniejsze(x, ZestawProbekDoWyboru[i]);
        END (* if Przes *);
      END (* for i *);
      IF (x # CommonTypes.NilValI) AND (NOT Logarytm OR (Logarytm AND (x > 0)))
      THEN
        IF Logarytm
        THEN
          r := log(MathLib0.real(ABS(x)));
        ELSE
          r := MathLib0.real(x);
        END (* if Logarytm *);
        x := MathLib0.entier((r - Przes) * Mnoznik) + SklStala;
        IF (st = CommonTypes.NilValI) OR (cur_idx = 0)
        THEN
          DrawEpson.Point(x, cur_idx, TRUE);
        ELSE
          DrawEpson.Line(st, cur_idx - 1, x, cur_idx, {0..15});
        END (* if *);
      END (* if *);
      st := x;
    END (* with rec *);
  END PointA;


VAR
    ZestawProbekBinDoWyboru : ARRAY [0 .. 96] OF BITSET;

  PROCEDURE PointB
            ( VAR rec     : Desc;
                  cur_idx : INTEGER );
  VAR
    i,
    x                       : INTEGER;
    Nil                     : INTEGER;
    x1                      : BOOLEAN;

  BEGIN
    Nil := 0;
    WITH rec DO
      IF flgEOF
      THEN
        RETURN;
      ELSIF cur_idx # PrevIdx
      THEN
        BlockOps.BlockSet(SYSTEM.ADR(ZestawProbekBinDoWyboru), SYSTEM.SIZE(
                          ZestawProbekBinDoWyboru), SYSTEM.ADR(Nil),
                          SYSTEM.SIZE(Nil));
        PrevIdx := cur_idx;
        IF NOT FIO.Read(Flagi, SYSTEM.ADR(ZestawProbekBinDoWyboru),
                        CoKtoraProbka * SYSTEM.SIZE(BITSET))
        THEN
          flgEOF := TRUE;
          RETURN
        END (* if *);
      END (* if cur_idx *);
      x1 := FALSE;
      FOR i := 0 TO CoKtoraProbka - 1 DO
        IF Negacja
        THEN
          x1 := x1 OR NOT (Bit IN ZestawProbekBinDoWyboru[i]);
        ELSE
          x1 := x1 OR (Bit IN ZestawProbekBinDoWyboru[i]);
        END (* if Negacja *);
      END (* for i *);
      x := Zakres * 3 * INTEGER(ORD(x1)) DIV 4;
      DrawEpson.Line(SklStala - x DIV 2, cur_idx, SklStala + x DIV 2, cur_idx,
                     {0..15});
    END (* with rec *);
  END PointB;

  PROCEDURE Point
            ( VAR rec     : Desc;
                  cur_idx : INTEGER );

  BEGIN
    IF rec.Uzywane
    THEN
      IF rec.Binarne
      THEN
        PointB(rec, cur_idx);
      ELSE
        PointA(rec, cur_idx);
      END (* if d.Binarne *);
    END (* if d.Uzywane *);
  END Point;

  PROCEDURE Opis
            ( VAR rec   : Desc;
                  Nizej : BOOLEAN );
  VAR
    l : INTEGER;

  BEGIN
    WITH rec DO
      IF NOT Uzywane THEN
        RETURN;
      END;
      l := (Strings.Length(Opis) DIV 2) * 8 * SKALA_X;
      IF l > SklStala
      THEN
        l := SklStala;
      END (* if l *);
      DrawEpson.DrawText(Opis, SklStala - l, ORD(Nizej) * 8);
      DrawEpson.Line(SklStala + Zakres DIV 2, 0, SklStala + Zakres DIV 2, MaxY(
                     ) - 1, StyleSep);
      DrawEpson.Line(SklStala, 0, SklStala, MaxY() - 1, Style0);
    END (* with rec *);
  END Opis;

  PROCEDURE CloseAll
            ( VAR d : ARRAY OF Desc );
  VAR
    j : INTEGER;

  BEGIN
    FOR j := 0 TO HIGH(d) DO
      IF NOT d[j].Binarne
      THEN
        FIO.Close(d[j].File);
      END (* if *);
    END (* for j *);
    FIO.Close(Flagi);
  END CloseAll;

  PROCEDURE InitAll
            ( VAR d            : ARRAY OF Desc;
                  currScaleDiv : CARDINAL;
                  Zestaw       : BOOLEAN;
                  aktCoKtoraProbka: CARDINAL  );
  VAR
    j       : INTEGER;
    flgName : ARRAY [0 .. 80] OF CHAR;
    napis   : ARRAY [0 .. 80] OF CHAR;
    a       : SYSTEM.ADDRESS;

  BEGIN
    CoKtoraProbka := aktCoKtoraProbka;
    Files.GetCommSigFName(Files.CS_Flags, Zestaw, flgName);
    Flagi := FIO.Open(flgName);
    IF Flagi = MAX(CARDINAL)
    THEN
      flgEOF := TRUE;
      a := SYSTEM.ADR(flgName);
      StdIO.sprintf(napis, "Nie mo¾na otworzy† pliku `%s'", a);
      GrafUtil.InfoBeep(napis, 3, 400);
    ELSE
      flgEOF := FALSE;
    END (* if Flagi *);
    FOR j := 0 TO HIGH(d) DO
      d[j].Binarne := TRUE;
      d[j].Uzywane := FALSE;
    END (* for j *);
    PrevIdx := -1;   (* na pewno zle *)
    scaleDiv := currScaleDiv;
  END InitAll;

  PROCEDURE EvProc
            (     NumerP          : CARDINAL;
                  NumerPorzadkowy : CARDINAL;
              VAR opis            : ARRAY OF CHAR;
                  Strona          : CARDINAL       );

  CONST
    WLK_STRZALKI = 4;
    MIN_Y        = 30;
  VAR
    idx_y : CARDINAL;
    j     : INTEGER;
    p     : INTEGER;
    R     : GrafTypes.RECT;
    np    : ARRAY [0 .. 7] OF CHAR;

  BEGIN
    p := 0;
    idx_y := (NumerP - Strona * MaxY() * CoKtoraProbka) DIV CoKtoraProbka;
    DrawEpson.Line(0, idx_y, DrawEpson.MaxX(), idx_y, {0, 1, 8, 9});
    (* j := Strings.Length( opis );*)
    StdIO.sprintf(np, "%d", NumerPorzadkowy);
    j := Strings.Length(np);
    (* ramka *)
    R.top := idx_y;
    R.bottom := R.top + 2 + 2 + j * SKALA_Y_90 * 8;
    R.right := PolozenieNapisu;
    R.left := R.right - (2 + 2 + 8 * SKALA_X_90);
    GrafTypes.MoveRect(R, 0, WLK_STRZALKI);
    IF R.bottom >= VAL(INTEGER, MaxY())
    THEN
      GrafTypes.MoveRect(R, 0, -R.bottom + VAL(INTEGER, MaxY()) - 1);
    END (* if R.bottom *);
    IF R.top < MIN_Y
    THEN
      p := MIN_Y - R.top;
      GrafTypes.MoveRect(R, 0, p);
    END (* if R.top *);
    DrawEpson.Line(R.left, R.top, R.left, R.bottom, {0..15});
    DrawEpson.Line(R.left, R.top, R.right, R.top, {0..15});
    DrawEpson.Line(R.right, R.bottom, R.right, R.top, {0..15});
    DrawEpson.Line(R.right, R.bottom, R.left, R.bottom, {0..15});
    (* strzalka *)
    DrawEpson.Line( R.left - WLK_STRZALKI - p, 
                    idx_y, R.left, 
                     VAL(INTEGER, idx_y) + WLK_STRZALKI + p,
                    {0..15});
    DEC(PolozenieNapisu, 2 * 8 * SKALA_X_90);
    IF PolozenieNapisu <= DrawEpson.MaxX() DIV 10
    THEN
      PolozenieNapisu := DrawEpson.MaxX() * 9 DIV 10;
    END (* if PolozenieNapisu *);
    (* napis *)
    DrawEpson.DrawText(np, R.right - 2, R.top + 2);
  END EvProc;

  PROCEDURE ZnacznikiOdleglosci
            (    DisRef            : CommonTypes.OdnDlaPomOdlT;
                 AlfaRef           : CommonTypes.OdnDlaPomBleduT;
                 pomiar            : BOOLEAN;
                 strona            : CARDINAL;
                 PromienANieOrbita : BOOLEAN;
                 Format360         : BOOLEAN;
                 DisOffset         : CARDINAL );
  VAR
    OdleglosciNaStronie : CARDINAL;
    DistFile            : FIO.File;
    str                 : ARRAY [0 .. 63] OF CHAR;
    Odl                 : SYSTEM.WORD;
    i                   : CARDINAL;
    PolZnacznika        : CARDINAL;
    disContiner         : DisMarksDsc;
    angContiner         : AngMarksDsc;
    disCurrIndex        : CARDINAL;
    angCurrIndex        : INTEGER;

  BEGIN (* ZnacznikiOdleglosci *)
    IF PromienANieOrbita
    THEN
      DisResetContiner(disContiner);
      Files.GetDisRefFName(DisRef, pomiar, str);
    ELSE
      AngResetContiner(angContiner);
      Files.GetALfaRefFName(AlfaRef, pomiar, str);
    END (* if PromienANieOrbita *);
    DistFile := FIO.Open(str);
    MANAGER.Assert(DistFile <> MAX(CARDINAL));
    IF DistFile = MAX(CARDINAL)
    THEN
      GrafUtil.InfoBeep("Nie mozna otworzyc pliku ze znacznikami odleglosci", 3
                        , 500);
      RETURN;
    END (* if DistFile *);
    OdleglosciNaStronie := MaxY() * CoKtoraProbka;
    IF FIO.Seek(DistFile, VAL(LONGINT, strona) * VAL(LONGINT,
                                                     OdleglosciNaStronie) * VAL
                (LONGINT, TSIZE(WORD)), FIO.sBegin) = VAL(LONGINT, 0)
    THEN
    (* nic *)
    END (* if FIO.Seek *);
    i := 0;
    WHILE (i < OdleglosciNaStronie) DO
      IF NOT FIO.Read(DistFile, SYSTEM.ADR(Odl), SYSTEM.SIZE(Odl))
      THEN
      (* Dane sie wyczerpaly *)
        FIO.Close(DistFile);
        RETURN;
      END (* if *);
      str[0] := 0C;   (* sluzy tez do oznaczania czy olac dana probke *)
      IF PromienANieOrbita
      THEN
        Odl := SYSTEM.WORD(SubDis(CARDINAL(Odl), DisOffset));
        IF DisAddSample(CARDINAL(Odl), disContiner, disCurrIndex, scaleDiv)
        THEN   (* granica pelnej mili *)
          NumberConversion.CardToString(disCurrIndex DIV 500, str, 3);
        END (* if CARDINAL *);
      ELSE
        IF AngAddSample(INTEGER(Odl), angContiner, angCurrIndex, scaleDiv)
        THEN   (* granica pelnego stopnia *)
          IF Format360
          THEN
            Ang100Str36Calk(angCurrIndex, str, 4);
          ELSE
            Int100StrCalk(angCurrIndex, str, 4);
          END (* if Format360 *);
        END (* if INTEGER *);
      END (* if *);
      IF str[0] # 0C
      THEN   (* do narysowania *)
        PolZnacznika := i DIV CoKtoraProbka;
        DrawEpson.Line(0, PolZnacznika, DrawEpson.MaxX(), PolZnacznika,
                       StyleOdl);
        IF (PolZnacznika >= 9)
        THEN
          DrawEpson.DrawText(str, 0, PolZnacznika - 9);
          DrawEpson.DrawText(str, DrawEpson.MaxX() - 5 * 8 * SKALA_X,
                             PolZnacznika - 9);
        ELSE
          DrawEpson.DrawText(str, 0, PolZnacznika + 1);
          DrawEpson.DrawText(str, DrawEpson.MaxX() - 5 * 8 * SKALA_X,
                             PolZnacznika + 1);
        END (* if *);
      END (* if str *);
      INC(i);
    END (* while *);
    FIO.Close(DistFile);
  END ZnacznikiOdleglosci;

  PROCEDURE WrFlagsTableWHeading
            (     heading : ARRAY OF CHAR;
                  tab     : FlagsTable;
                  converP : ToStringProcT
             ) : BOOLEAN;
  VAR
    fracNum : OdcinekIdx;
    lineStr : ARRAY [0 .. ScreenMaxLen] OF CHAR;
    str     : ARRAY [0 .. 45] OF CHAR;
  
  BEGIN
    fracNum := MIN(OdcinekIdx);
    Strings.Assign(heading, lineStr);
    LOOP
      IF NOT GetNextFrac(converP, tab, str, fracNum)
      THEN
        IF NOT WrPrnLn(0, lineStr)  THEN
          RETURN FALSE;
        END;
        RETURN TRUE;
      END (* if *);
      IF Length(lineStr) + Length(str) < ScreenMaxLen
      THEN
        Concat(lineStr, str, lineStr);
      ELSE
        IF NOT WrPrnLn(0, lineStr)  THEN
          RETURN FALSE;
        END;
        Concat(heading, str, lineStr);
      END (* if Length *);
    END (* loop *);
  END WrFlagsTableWHeading;

  PROCEDURE WrFlagsTable
            (     tab     : FlagsTable;
                  converP : ToStringProcT;
                  rec     : GlownyOdbiornikT ): BOOLEAN;
  VAR
    lineStr        : ARRAY [0 .. ScreenMaxLen] OF CHAR;
    str            : ARRAY [0 .. 45] OF CHAR;
    nazwaOdb       : ARRAY [0 .. 15] OF CHAR;
    addr_nazwaOdb  : ADDRESS;
    strAdr         : ADDRESS;
    

  BEGIN (* WrFlagsTable *)
    strAdr := ADR(str);
    addr_nazwaOdb := ADR(nazwaOdb);
    GetRecName(nazwaOdb, rec);
    WITH tab DO
      IF W_IleRazem > 0  THEN
        converP(w_KatRazem, str, 5);
        StdIO.sprintf3(lineStr, 
             'Odb %s: W analizie pomini©to %1d odcink¢w o dˆugo˜ci: %s)', 
             addr_nazwaOdb,
             W_IleRazem,
             strAdr );
        IF NOT WrPrnLn(0, lineStr)  THEN
          RETURN FALSE;
        END;
      END; (* IF W_IleRazem *)
    END; (* WITH tab *)
    StdIO.sprintf(lineStr, 'Odb %s:', addr_nazwaOdb);
    RETURN WrFlagsTableWHeading( lineStr, tab, converP);
  END WrFlagsTable;

  PROCEDURE WrF_TablicaOdci
            (     heading : ARRAY OF CHAR;
                  tab     : F_TablicaOdci;
                  converP : ToStringProcT ): BOOLEAN;
  VAR
    rec : GlownyOdbiornikT;

  BEGIN
    IF NOT WrPrnLn(0, heading) THEN
      RETURN FALSE;
    END;
    FOR rec := MIN(GlownyOdbiornikT) TO MAX(GlownyOdbiornikT) DO
      IF NOT WrFlagsTable(tab[rec], converP, rec) THEN
        RETURN FALSE;
      END;
    END (* for rec *);
    RETURN TRUE;
  END WrF_TablicaOdci;

  PROCEDURE WypiszStrefy( strf      : zoneBDisIdx_T ;
                          locANieGs : BOOLEAN ) : BOOLEAN;
    VAR
      sec     : CHAR;
      nap     : Str99;
      i       : NumPunktu;
      a       : ADDRESS;
      s       : Str99;
      lastStr : NumPunktu;
    BEGIN
      a := ADR( s );
      IF NOT WrPrnLn(0,PASEK) THEN
        RETURN FALSE;
      END(*if*);
      IF NOT WrPrnLn(0, "Pocz¥tki stref") THEN
        RETURN FALSE;
      END;
      IF locANieGs THEN
        lastStr := np_E;
      ELSE
        lastStr := np_CorT;
      END;
      FOR i := np_A TO lastStr DO
        sec := CHR(ORD('A') + ORD(i) - 1 );
        Card500Str( strf[i], s, 6 );
        IF i = np_CorT THEN
          StdIO.sprintf( nap, "Punkt C(TH) w miejscu %sNM", a );
        ELSE
          StdIO.sprintf2(nap, "Punkt %c w miejscu %sNM", sec, a );
        END;
        IF NOT WrPrnLn( 4, nap ) THEN
          RETURN FALSE;
        END;
      END;(*if*);
      RETURN TRUE;
    END WypiszStrefy;



  PROCEDURE PrintScreenProc( a : ADDRESS );
    BEGIN
      (* GrafUtil.Info( 'Klawisz nieaktywny !!!'); *)
      BreakChain;
    END PrintScreenProc;

VAR
  Tmpl : Template;
BEGIN
  flgEOF := TRUE;
  Flagi := MAX(CARDINAL);
  scaleDiv := 500;
  InstPrologueHnd( PrintScreen, ADR(Tmpl), PrintScreenProc, NIL );
  TextModeOutProc := DrawEpson.WrProc;
END Print.
