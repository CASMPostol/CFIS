(*.F- *)
(**********************************************************************
|  Title   : Raport koncowy dla NDB
|  Author  : M.Morawski
|  System  : LOGITECH MODULA-2/86
|    06-06-97: M.Postol
|      zmienilem aspekt wykresu kolka
|      blad w WrPrnFmt
|    06-20-97 07:26pm: MM
|      Rozdzielono wykresy pokrycia poziomego dla nadajnikow
|   25-02-98: M.Postol
|     blad przy czytaniu czestotliwosci - czestotliwosc w bazie danych
|     powinna buc w KHz, a nie *100 bo sie nie miesci w CARDINAL
|   17-05-98: M.Morawski
|     blad przy rysowaniu skal
|
|  Copyright (C), CAS LODZ POLAND.
|  TEL: 42' 862 547, 42' 87 80 44 FAX/TEL: 42' 84 48 40
|
**********************************************************************)
(*.F+ *)

IMPLEMENTATION MODULE N_Report;

FROM CommonTypes IMPORT
  Date, Str40, Str99, PolozenieGeo, OdnDlaPomOdlT, NadajnikT,
  GlownyOdbiornikT, NilValC, SignalDsc, TimeAndDate, NilValI,
  OdnDlaPomBleduT;
FROM MathLib0 IMPORT
  ln;
FROM N_DataBase IMPORT
  NadajnikNDB;
FROM PI_ArchDate IMPORT
  okTab, LoadData;
FROM RTSMain IMPORT
  Terminate, Status;
FROM Czas IMPORT
  GetTimeAndDate;
FROM NumberConversion IMPORT
  IntToString;
FROM Marks IMPORT
  AngMarksDsc, AngResetContiner, AngAddSample;
FROM N_results IMPORT
  anRes, OdcinekNr, A_TablicaOdci;
FROM FlagAnal IMPORT
  FlagsTable;
FROM FIO IMPORT
  File, Open, Close, CD, Read, GetFileStamp, Write, Create;
FROM Files IMPORT
  ExistDIR, GoHomeDir, GetALfaRefFName;
FROM N_Files IMPORT
  GetSigFileName, Signals;
FROM N_CommonTypes IMPORT
  Procedura, ProceduraT;
FROM StdIO IMPORT
  sprintf, sprintf2, sprintf3, sprintf4;
FROM Strings IMPORT
  Assign, Length, Insert;
FROM SYSTEM IMPORT
  ADR, SIZE, BYTE, ADDRESS;
FROM MANAGER IMPORT
  Assert;
FROM GrafUtil IMPORT
  InfoBeep;
FROM Rap_Util IMPORT
  GetInteractiveData;
FROM MathLib0 IMPORT
  real, entier, sin, cos;
FROM Print IMPORT
  WrPrn, WrPrnLn, WrLn, TextModeOutProc, PASEK, GWIAZDKI, PrnX, PrnY,
  SKALA_Y_90, SKALA_X_90;
IMPORT
  DrawEpson, (* bo kloci sie Close *)
  CommonData,
  HiLevGraf,
  Files,
  FIO,
  N_Files,
  N_Oblot;
FROM ASCII IMPORT
  ff;
FROM Dialog IMPORT
  HDLG, WstawButton;
FROM Buttons IMPORT
  Button, ChangeButtonText;
FROM GrafTypes IMPORT
  RECT, AssignRect, MoveRect, WHITE;
FROM ShortCuts IMPORT
  kbAltY, kbCtrlY, kbAltD;
FROM EventsMng IMPORT
  Events, EventKind;



(*
VAR
  DrukarkaSim : File; (* zamiast pisania na drukarke *)
CONST
  PrnFileName = "\Drukarka.sim";

  PROCEDURE FIOOut( ch : CHAR ) : BOOLEAN;
    BEGIN
      RETURN Write( DrukarkaSim, ADR( ch ), 1 );
    END FIOOut;
*)

CONST
  pomiar      = FALSE;
  DATA_STR    = "%02d.%02d.%d";

TYPE
  OpisyZasiegow = RECORD
    Wysokosc,
    Zasieg    : CARDINAL;
  END;


  PomiarNadajnika = RECORD
    KiedyOrbita                   : Date;
    KiedyPromien                  : Date;
    PokrycieWPionie               : ARRAY OdcinekNr OF OpisyZasiegow;
    PokrycieWPoziomie             : OpisyZasiegow;

    SlyszalnoscPrawidlowa         : BOOLEAN;
  END;

  RaportKoncowyDesc = RECORD
    NazwaInspekcji           : Str40;
    Lokalizacja              : Str40;
    Polozenie                : PolozenieGeo;
    Czestotliwosc            : REAL;
    Deklinacja               : REAL;
    Odpowiedzialny           : Str40;
    SamolotPomiarowy         : ARRAY[0..6] OF CHAR;
    GlownyOdbiornik          : GlownyOdbiornikT;
    DataOstatniejKalibracji  : Date;
    NazwaAparaturyPomiarowej : Str40;
    Pomiary                  : ARRAY NadajnikT OF PomiarNadajnika;
    NDB_Lotniskowe                : BOOLEAN;
    UrzadzenieOK             : BOOLEAN;
  END;

  FracType = RECORD
    Int  : CARDINAL;
    Frac : CARDINAL;
  END;

  Buttony = ARRAY NadajnikT OF Button;



VAR
  StartN : ARRAY NadajnikT OF CARDINAL;
  StartTol : CARDINAL;
  AktualnyPromien : CARDINAL;
VAR
  SR   : Buttony;               (* sygnal rozpoznawczy *)
  Rodzaj : Button;
  Dane : RaportKoncowyDesc;



  PROCEDURE Rodzaj_P( );
    BEGIN
      WITH Dane DO
        NDB_Lotniskowe := NOT NDB_Lotniskowe;
        IF NDB_Lotniskowe THEN
          ChangeButtonText( Rodzaj, "NDB LOTNISKOWE" );
        ELSE
          ChangeButtonText( Rodzaj, "NDB WOLNO STOJ¤CE" );
        END;
      END;
    END Rodzaj_P;

  PROCEDURE SygnalRozpoznawczy(     n : NadajnikT;
                                VAR b : Buttony   );
    BEGIN
      WITH Dane.Pomiary[n] DO
        SlyszalnoscPrawidlowa := NOT SlyszalnoscPrawidlowa;
        IF (SlyszalnoscPrawidlowa) THEN
          ChangeButtonText( b[n], "SYSZALNO— PRAWIDOWA" );
        ELSE
          ChangeButtonText( b[n], "SYSZALNO— NIEPRAWIDOWA" );
        END;
      END;
    END SygnalRozpoznawczy;

  PROCEDURE SygnalRozpoznawczy_A(  );
    BEGIN
      SygnalRozpoznawczy( nA, SR );
    END SygnalRozpoznawczy_A;

  PROCEDURE SygnalRozpoznawczy_B(  );
    BEGIN
      SygnalRozpoznawczy( nB, SR );
    END SygnalRozpoznawczy_B;

  PROCEDURE DodatkoweButtony( h : HDLG );
    VAR
      n : NadajnikT;
      R : RECT;
    BEGIN
      AssignRect( R, 500, 300, 790, 330 );
      WstawButton( h, R, "", 2, kbAltY, SygnalRozpoznawczy_A, SR[nA] );
      MoveRect( R, 0, 100 );
      WstawButton( h, R, "", 2, kbCtrlY, SygnalRozpoznawczy_B, SR[nB] );
      AssignRect( R, 500, 540, 790, 570 );
      WstawButton( h, R, "", 1, kbAltD, Rodzaj_P, Rodzaj );
      HiLevGraf.WrStr( "Nadajnik `A'", 500, 280, WHITE, WHITE );
      HiLevGraf.WrStr( "Nadajnik `B'", 500, 380, WHITE, WHITE );
      FOR n := nA TO nB DO
        WITH Dane.Pomiary[n] DO
          SlyszalnoscPrawidlowa := FALSE;
          SygnalRozpoznawczy( n, SR );
        END;
      END;
      Dane.NDB_Lotniskowe := TRUE;
      Rodzaj_P;
    END DodatkoweButtony;


  PROCEDURE min( a, b : CARDINAL ) : CARDINAL;
    BEGIN
      IF a > b THEN
        RETURN b;
      ELSE
        RETURN a;
      END;
    END min;

  PROCEDURE max( a, b : CARDINAL ) : CARDINAL;
    BEGIN
      IF a > b THEN
        RETURN a;
      ELSE
        RETURN b;
      END;
    END max;

  PROCEDURE PodstawCardinal( VAR jg            : CARDINAL;
                                 sv            : CARDINAL;
                                 DoGory        : BOOLEAN );
    BEGIN
      IF sv = NilValC THEN
        RETURN;
      ELSE
        IF (jg = NilValC) THEN
          jg := sv;
        ELSE
          IF DoGory THEN
            jg := max( jg, sv );
          ELSE
            jg := min( jg, sv );
          END;
        END;
      END;
    END PodstawCardinal;

  PROCEDURE Card2Frac( c : CARDINAL; VAR f : FracType );
    BEGIN
      IF c # NilValC THEN
        f.Int := c DIV 500;
        f.Frac := c MOD 500 DIV 5;
      END;
    END Card2Frac;

  PROCEDURE WrPrnFmt( At   : INTEGER;
                      Fmt1,
                      Fmt2 : ARRAY OF CHAR;
                      Dane : ARRAY OF BYTE ) : BOOLEAN;
    VAR
      str   : ARRAY[0..99] OF CHAR;
    BEGIN
      IF CHAR(Dane[0]) = 0377c THEN
        RETURN WrPrn( At, '| ******' );
      ELSIF (HIGH(Dane) > 0) AND (CHAR( Dane[1] ) = 0377C) THEN
        sprintf( str, Fmt2, Dane );
      ELSE
        sprintf( str, Fmt1, Dane );
      END;
      IF NOT WrPrn( At, str ) THEN
        RETURN FALSE;
      ELSE
        RETURN TRUE;
      END;
    END WrPrnFmt;

  PROCEDURE WrFmtNad( Nad      : NadajnikT;
                      Valid    : BOOLEAN;
                      Fmt      : ARRAY OF CHAR;
                      Dane     : ARRAY OF BYTE ) : BOOLEAN;
    VAR
      str   : ARRAY[0..99] OF CHAR;
    BEGIN
      IF Valid THEN
        sprintf( str, Fmt, Dane );
      ELSE
        str := GWIAZDKI;
      END;
      IF NOT WrPrn( StartN[Nad], '| ' ) OR NOT WrPrn( StartN[Nad], str ) THEN
        RETURN FALSE;
      ELSE
        RETURN TRUE;
      END;
    END WrFmtNad;


  PROCEDURE WrPrnFmtLn( At   : INTEGER;
                        Fmt1,
                        Fmt2 : ARRAY OF CHAR;
                        Dane : ARRAY OF BYTE ) : BOOLEAN;
  BEGIN
    RETURN WrPrnFmt( At, Fmt1, Fmt2, Dane ) & WrLn();
  END WrPrnFmtLn;


  PROCEDURE ZaokraglicDo1000( VAR h : CARDINAL );
    BEGIN
      IF h # NilValC THEN
        h := ((h+500) DIV 1000) * 1000;
      END;
    END ZaokraglicDo1000;

  PROCEDURE WrOdcinek( Nr : CARDINAL; a, b : OpisyZasiegow ) : BOOLEAN;

    PROCEDURE Conv( VAR o : OpisyZasiegow );
      VAR
        f : FracType;
      BEGIN
        v[0] := o.Wysokosc;
        IF o.Zasieg = NilValC THEN
          v[1] := NilValC;
          v[2] := v[1];
        ELSE
          Card2Frac( o.Zasieg, f );
          v[1] := f.Int;
          v[2] := f.Frac;
        END;
      END Conv;

    CONST
      CONV_STR1 = "| %d/%d.%02d";
      CONV_STR2 = "| %d/*****";
    VAR
      v : ARRAY [0..2] OF CARDINAL;
      wys : Str99;
    BEGIN
      ZaokraglicDo1000( a.Wysokosc );
      ZaokraglicDo1000( b.Wysokosc );
      sprintf( wys, "%2d Wysoko˜† [ft]/[NM]", Nr );
      IF NOT WrPrn( 0, wys ) THEN
        RETURN FALSE;
      END;
      Conv( a );
      IF NOT WrPrnFmt( StartN[nA], CONV_STR1, CONV_STR2, v ) THEN
        RETURN FALSE;
      END;
      Conv( b );
      IF NOT WrPrnFmt( StartN[nB], CONV_STR1, CONV_STR2, v ) THEN
        RETURN FALSE;
      END;
      IF NOT WrLn() THEN
        RETURN FALSE;
      END;
      RETURN TRUE;
    END WrOdcinek;

  PROCEDURE Daty(  ) : BOOLEAN;
    BEGIN
      IF  NOT WrPrn( StartN[nA], "| Nad. Gˆ¢wny" )   OR
          NOT WrPrnLn( StartN[nB], "| Nad. zapasowy" )
      THEN
        RETURN FALSE;
      ELSE
        RETURN WrPrn( 0, "Data wykonania pomiaru:" );
      END;
    END Daty;

  PROCEDURE WykresPokryciaWPionie( VAR Naglowek : ARRAY OF CHAR ) : BOOLEAN;
    CONST
      WYS_LINE = {0};
      INIT_LAST_Y = 40;
    VAR
      TablicaLecianychWysokosci : ARRAY OdcinekNr OF CARDINAL;
      IleRoznychWysokosci       : INTEGER;
      MaxZasieg                 : CARDINAL;
      i, j, w                   : INTEGER;
      px, py, x, y, LastY       : INTEGER;
      n                         : NadajnikT;
      s                         : Str99;


      PROCEDURE IndexWys( Wys : CARDINAL ) : CARDINAL;
        VAR
          k : INTEGER;
        BEGIN
          FOR k := 0 TO IleRoznychWysokosci-1 DO
            IF (TablicaLecianychWysokosci[k] = Wys) THEN
              RETURN k;
            END;
          END;
        END IndexWys;

        PROCEDURE PolozenieNaWspolrzednejY( w : CARDINAL ) : CARDINAL;
          VAR
            a : REAL;
          BEGIN
            a := ( FLOAT( TablicaLecianychWysokosci[w] -
                          TablicaLecianychWysokosci[0]
                        ) *
                   FLOAT( DrawEpson.MaxY() -2 ) /
                   FLOAT(
                        TablicaLecianychWysokosci[IleRoznychWysokosci-1] -
                        TablicaLecianychWysokosci[0]
                      )
                 );
             RETURN TRUNC( a+0.5 );
          END PolozenieNaWspolrzednejY;

    BEGIN
      IleRoznychWysokosci := 0;
      MaxZasieg := 0;
      FOR i := 0 TO HIGH( Dane.Pomiary[nA].PokrycieWPionie ) DO
        FOR n := nA TO nB DO
          WITH Dane.Pomiary[n].PokrycieWPionie[i] DO
            IF Wysokosc # NilValC THEN
              IF (Zasieg > MaxZasieg) THEN
                MaxZasieg := Zasieg;
              END;
              j := 0;
              WHILE (j < IleRoznychWysokosci) &
                    (TablicaLecianychWysokosci[j] # Wysokosc )
              DO
                INC( j );
              END;
              (* tu albo skonczyla sie tablica albo zostala znaleziona wysokosc *)
              IF TablicaLecianychWysokosci[j] # Wysokosc THEN
                TablicaLecianychWysokosci[IleRoznychWysokosci] := Wysokosc;
                INC(IleRoznychWysokosci);
              END;
            END;
          END;
        END;
      END;
      IF (IleRoznychWysokosci < 2) THEN
        IF NOT WrPrnLn( 0, "Lot byˆ wykonany na mniej ni¾ 2 wysoko˜ciach," ) THEN
          RETURN FALSE;
        END;
        IF NOT WrPrnLn( 0, "st¥d nie b©dzie mo¾na narysowa† wykresu" ) THEN
          RETURN FALSE;
        END;
        RETURN TRUE;
      END;
      IF NOT WrPrn( 0, ff ) THEN (* nowa strona *)
        RETURN FALSE;
      END;

      (* teraz trzeba posortowac wysokosci *)
      FOR i := IleRoznychWysokosci-1 TO 0 BY -1 DO
        w := 0;
        FOR j := 1 TO i DO
          IF (TablicaLecianychWysokosci[w] < TablicaLecianychWysokosci[j]) THEN
            w := j;
          END;
          x := TablicaLecianychWysokosci[w];
          TablicaLecianychWysokosci[w] := TablicaLecianychWysokosci[i];
          TablicaLecianychWysokosci[i] := x;
        END;
      END;

      FOR n := nA TO nB DO
        DrawEpson.Open;

        DrawEpson.Mnoznik( 2, 1 );
        DrawEpson.DrawText( Naglowek, 100, 0 );
        DrawEpson.Line( 0, 0, DrawEpson.MaxX(), 0, WYS_LINE );
        FOR i := 0 TO IleRoznychWysokosci-1 DO
          w := PolozenieNaWspolrzednejY(i);
          DrawEpson.Line( 0, w, DrawEpson.MaxX(), w, WYS_LINE );
          sprintf( s, "%dft", TablicaLecianychWysokosci[i] );
          IF ORD(w) > DrawEpson.MaxY()-10 THEN
            DEC( w, 10 );
          END;
          DrawEpson.DrawText( s, 0, w+1 );
        END;

        px := NilValI;
        py := NilValI;
        LastY := INIT_LAST_Y;
        DrawEpson.SetDir( DrawEpson.t_90 );
        DrawEpson.Mnoznik( SKALA_X_90, SKALA_Y_90 );
        FOR i := 0 TO HIGH( Dane.Pomiary[nA].PokrycieWPionie ) DO
          WITH Dane.Pomiary[n].PokrycieWPionie[i] DO
            IF (Wysokosc # NilValC) THEN
              w := IndexWys( Wysokosc );
              y := PolozenieNaWspolrzednejY(w);
              sprintf( s, "%xNM", Zasieg );
              x := VAL( CARDINAL, VAL( LONGINT, Zasieg ) *
                                  VAL( LONGINT, DrawEpson.MaxX() -1) DIV
                                  VAL( LONGINT, MaxZasieg ));
              DrawEpson.Line( x, 0, x, DrawEpson.MaxY(), WYS_LINE );
              IF x < INTEGER(DrawEpson.MaxX())-(SKALA_X_90*8+4) THEN
                DrawEpson.DrawText( s, x+1+SKALA_X_90*8, LastY );
              ELSE
                DrawEpson.DrawText( s, x-1-SKALA_X_90*8, LastY );
              END;
              LastY := LastY + (SKALA_Y_90*8*INTEGER(Length(s)+4));
              IF LastY > INTEGER( DrawEpson.MaxY() *3 DIV 4) THEN
                LastY := INIT_LAST_Y;
              END;
              IF (px # NilValI) THEN
                DrawEpson.Line( px, py, x, y, {0..15} );
              END;
              px := x;
              py := y;
            END;
          END;
        END;
        DrawEpson.SetDir( DrawEpson.t_0 );
        DrawEpson.Mnoznik( 4, 2 );
        IF n = nA THEN
          DrawEpson.DrawText( "Wykres pokrycia pionowego dla odb. glownego", 100, 10 );
        ELSE
          DrawEpson.DrawText( "Wykres pokrycia pionowego dla odb. zapasowego", 100, 10 );
        END;
        IF NOT DrawEpson.Out(DrawEpson.WrProc) THEN
          DrawEpson.Close;
          RETURN FALSE;
        END;
        DrawEpson.Close;
      END;
      RETURN TRUE;
    END WykresPokryciaWPionie;

  PROCEDURE WykresPokryciaWPoziomie( VAR Naglowek : ARRAY OF CHAR ) : BOOLEAN;
    CONST
      M_PI = 3.1415926;
      Zero_Agc= 1.0;
      MIN_Agc = 10;
      AV_Agc  = 100;
      MAX_Agc = 1000;
      style   = {0..15};
    VAR
      CenterX,
      CenterY : INTEGER;
      Aspect  : REAL;
      x, y    : INTEGER;
      PrevX,
      PrevY   : INTEGER;
      i       : CARDINAL;
      n       : NadajnikT;
      AgcFile,
      AngleFile : File;
      FileName  : Str99;
      dataOk    : okTab;
      agc,
      angle     : INTEGER;
      KatS      : Str40;

        PROCEDURE Log10( x : REAL ) : REAL;
          BEGIN
            RETURN ln( x ) / 2.302585093;
          END Log10;


        PROCEDURE CoordAt(     agc   : INTEGER;
                               angle : REAL;
                           VAR x, y  : INTEGER );
          VAR
            promien,
            xR,
            yR       : REAL;
          BEGIN
            angle := angle - 90.0;
            angle := angle * M_PI/180.0;
(*
            angle := -angle;    (* bo geograficzny uklad wspolrzednych jest prawoskretny *)
*)
            promien := (Log10(real( agc )) - Log10( Zero_Agc )) /
                       (Log10(real(MAX_Agc))- Log10( Zero_Agc)) *
                         (real(DrawEpson.MaxX()-1)/2.0);
            IF promien < 0.0 THEN
              promien := 0.0;
            END;
            xR := cos( angle ) * promien;
            yR := sin( angle ) * promien * Aspect;
            x := entier( xR+0.5 ) + CenterX;
            y := entier( yR+0.5 ) + CenterY;
            IF (x < 0) THEN
              x := 0;
            END;
            IF (y < 0) THEN
              y := 0;
            END;
          END CoordAt;

        PROCEDURE Circle( rad : INTEGER );
          VAR
            i : CARDINAL;
            px, py, x, y : INTEGER;
          BEGIN
            CoordAt( rad, 0.0, px, py );
            FOR i := 1 TO 360 DO
              CoordAt( rad, FLOAT( i ), x, y );
              DrawEpson.Line( px, py, x, y, {0..15} );

(*              IF i > 320 THEN Terminate( Warning ); END;*)

              px := x;
              py := y;
            END;
          END Circle;

    BEGIN
      IF NOT WrPrn( 0, ff ) THEN (* nowa strona *)
        RETURN FALSE;
      END;
      CenterX := DrawEpson.MaxX() DIV 2;
      CenterY := DrawEpson.MaxY() DIV 2;
      Aspect  := ( (FLOAT( DrawEpson.MaxX()) /  8.0 (* cali *))) /
                 ( (FLOAT( DrawEpson.MaxY()) / 12.0 (* cali *)));
      Aspect := 1.253/Aspect;

      FOR n := nA TO nB DO
        DrawEpson.Open;

        Circle( MAX_Agc );
        Circle( AV_Agc );
        Circle( MIN_Agc );

        DrawEpson.Mnoznik( 2, 1 );
        DrawEpson.DrawText( Naglowek, 0, 0 );
        FOR i := 0 TO 359 BY 30 DO
          CoordAt( MAX_Agc, FLOAT(i), x, y );
          DrawEpson.Line(CenterX, CenterY, x, y, {0..15} );
          CoordAt( 50, FLOAT(i+3), x, y );
          sprintf( KatS, "%dø", i );
          DrawEpson.DrawText( KatS, x, y );
        END;
        CoordAt( MIN_Agc, 90.0, x, y );
        DrawEpson.DrawText( "10", x, y+1 );
        CoordAt( MAX_Agc, 90.0, x, y );
        DrawEpson.DrawText( "1000", x, y+1 );
        CoordAt( AV_Agc, 90.0, x, y );
        DrawEpson.DrawText( "100", x, y+1 );
        (* Tlo wykresu zostalo narysowane *)

        Procedura := pOrbita;
        PrevX := NilValI;
        PrevY := NilValI;

        CommonData.Nadajnik1 := n;
        N_Oblot.SciezkaDoKataloguOpisu;
        Assign( CommonData.SciezkaOpisuPomiaru, FileName );
        FileName[ Length( FileName ) -1 ] := 0C;

        IF CD( FileName ) THEN
          N_Files.GetSigFileName( agc_Sg, Dane.GlownyOdbiornik, FileName );
          AgcFile := Open(FileName);
          Assert( AgcFile # MAX( CARDINAL ));
          Files.GetALfaRefFName( pbGPS, pomiar, FileName );
          AngleFile := Open(FileName);
          GoHomeDir;
          Assert( AngleFile # MAX( CARDINAL ));
          FOR i := 0 TO VAL(CARDINAL, FIO.Length( AgcFile )) DIV 2 -1 DO
            IF NOT Read( AgcFile, ADR( agc ), 2 ) THEN
              Close( AgcFile );
              Close( AngleFile );
              DrawEpson.Close;
              InfoBeep( 'Nie mo¾na czyta† z pliku!!!!!!', 3, 555 );
              RETURN FALSE;
            END;
            IF NOT Read( AngleFile, ADR( angle ), 2 ) THEN
              Close( AgcFile );
              Close( AngleFile );
              DrawEpson.Close;
              InfoBeep( 'Nie mo¾na czyta† z pliku!!!!!!', 3, 555 );
              RETURN FALSE;
            END;
            IF (agc # NilValI) & (angle # NilValI) THEN
                CoordAt( agc,
                         real( angle ) / 100.0,
                         x, y );
            ELSE
              x := NilValI;
              y := NilValI;
            END;
            IF ( x # NilValI ) & ( y # NilValI ) THEN
              IF (PrevX # NilValI) THEN
                DrawEpson.Line( PrevX, PrevY, x, y, style );
              ELSE
                DrawEpson.Point( x, y, TRUE );
              END;
            END;
            PrevX := x;
            PrevY := y;
          END;
          Close( AgcFile );
          Close( AngleFile );
        ELSE
          GoHomeDir;
        END;

        DrawEpson.Mnoznik( 4, 2 );
        IF n = nA THEN
          DrawEpson.DrawText( 'Wykres pokrycia poziomego dla nadajnika gˆ¢wnego',
                              0,
                              10 );
        ELSE
          DrawEpson.DrawText( 'Wykres pokrycia poziomego dla nadajnika zapasowego',
                              0,
                              10 );
        END;
        IF NOT DrawEpson.Out(DrawEpson.WrProc) THEN
          DrawEpson.Close;
          RETURN FALSE;
        END;
        DrawEpson.Close;
      END;
      RETURN TRUE;
    END WykresPokryciaWPoziomie;

  PROCEDURE DrukujPromien( VAR Naglowek : ARRAY OF CHAR ) : BOOLEAN;
    VAR
      n    : NadajnikT;
      i    : CARDINAL;
    BEGIN
      (* Wyniki pomiarow *)
      IF NOT WrPrnLn( 0, PASEK ) THEN
        RETURN FALSE;
      END;

      IF NOT WrPrnLn( 0, Naglowek ) THEN
        RETURN FALSE;
      END;

      IF NOT Daty() THEN
        RETURN FALSE;
      END;
      FOR n := MIN( NadajnikT ) TO MAX( NadajnikT ) DO
        WITH Dane.Pomiary[n] DO
          IF NOT WrFmtNad( n, KiedyPromien.y # 0, DATA_STR, KiedyPromien ) THEN
            RETURN FALSE;
          END;
        END;
      END;
      IF NOT WrLn() THEN
        RETURN FALSE;
      END;
      IF NOT WrPrnLn( 0, "Pokrycie w pionie" ) THEN
        RETURN FALSE;
      END;
      FOR i := 0 TO HIGH( Dane.Pomiary[nA].PokrycieWPionie ) DO
        IF NOT WrOdcinek( i+1,
                          Dane.Pomiary[nA].PokrycieWPionie[i],
                          Dane.Pomiary[nB].PokrycieWPionie[i] )
        THEN
          RETURN FALSE;
        END;
      END;
      IF NOT WykresPokryciaWPionie( Naglowek ) THEN
        RETURN FALSE;
      END;
      RETURN TRUE;
    END DrukujPromien;

    PROCEDURE DrukujOrbite( VAR Naglowek : ARRAY OF CHAR ) : BOOLEAN;
    VAR
      n    : NadajnikT;
    BEGIN
      (* Wyniki pomiarow *)
      IF NOT WrPrnLn( 0, PASEK ) THEN
        RETURN FALSE;
      END;

      IF NOT WrPrnLn( 0, Naglowek ) THEN
        RETURN FALSE;
      END;
      IF NOT Daty() THEN
        RETURN FALSE;
      END;
      FOR n := MIN( NadajnikT ) TO MAX( NadajnikT ) DO
        WITH Dane.Pomiary[n] DO
          IF NOT WrFmtNad( n, KiedyOrbita.y # 0, DATA_STR, KiedyOrbita ) THEN
            RETURN FALSE;
          END;
        END;
      END;
      IF NOT WrLn() THEN
        RETURN FALSE;
      END;
      IF NOT WrPrnLn( 0, "Pokrycie w poziomie" ) THEN
        RETURN FALSE;
      END;
      IF NOT WrOdcinek( 1,
                        Dane.Pomiary[nA].PokrycieWPoziomie,
                        Dane.Pomiary[nB].PokrycieWPoziomie )
      THEN
        RETURN FALSE;
      END;
      IF NOT WykresPokryciaWPoziomie( Naglowek ) THEN
        RETURN FALSE;
      END;
      RETURN TRUE;
    END DrukujOrbite;

  PROCEDURE PoczatekWypisywania(  ) : BOOLEAN;
    VAR
      td   : TimeAndDate;
      c    : CHAR;
      n    : NadajnikT;
    BEGIN
(*
      (* symulacja drukarki *)
      DrukarkaSim := Create( PrnFileName );
      TextModeOutProc := FIOOut;
*)
      PrnX := 0;
      PrnY := 0;
      GetTimeAndDate( td );
      IF NOT WrPrnFmtLn( 0,
        "RAPORT Z INSPEKCJI NDB WYKONANY O GODZ. %02d:%02d dnia %02d.%02d.%d",
        "  ", td ) THEN
        RETURN FALSE;
      END;
      WITH Dane DO
        IF NOT WrPrn( 0, "Nazwa Inspekcji: " ) OR
            NOT WrPrnLn( 0, NazwaInspekcji )
        THEN
          RETURN FALSE;
        END;
        IF NOT WrPrn( 0, "Lokalizacja: " ) OR
            NOT WrPrnLn( 0, Lokalizacja )
        THEN
          RETURN FALSE;
        END;
        IF NOT WrPrnFmtLn( 0,
                            "Poˆo¾enie geograficzne: %dø%02d'%02dE, %dø%02d'%02dN",
                            "  ",
                            Polozenie )
        THEN
          RETURN FALSE;
        END;
        IF NOT WrPrnFmtLn( 0,
                           "Deklinacja: %3.1lfø",
                           "  ", Deklinacja ) THEN
          RETURN FALSE;
        END;
        IF NOT WrPrnFmtLn( 0, "Cz©stotliwo˜†: %5.2lfkHz",
                              "  ", Czestotliwosc ) THEN
          RETURN FALSE;
        END;
        IF NOT WrPrn( 0, "SamolotPomiarowy: " ) OR
            NOT WrPrnLn( 0, SamolotPomiarowy )
        THEN
          RETURN FALSE;
        END;
        IF NOT WrPrn( 0, "Odpowiedzialny za wykonanie pomiaru: " ) THEN
          RETURN FALSE;
        END;
        IF Odpowiedzialny[0] = 0C THEN
          IF NOT WrPrnLn( 0, '** Niezdefiniowany **' ) THEN
            RETURN FALSE;
          END;
        ELSE
          IF NOT WrPrnLn( 0, Odpowiedzialny ) THEN
            RETURN FALSE;
          END;
        END;
        c := CHR( ORD( GlownyOdbiornik ) + ORD('A' ));
        IF NOT WrPrnFmtLn( 0,
                            "Wyniki dotycz¥ toru pomiarowego odbiornika ->%c<-",
                            "  ",
                            c )
        THEN
          RETURN FALSE;
        END;
        IF NOT WrPrnFmtLn( 0,
                            "Data ostatniej kalibracji: %02d.%02d.%d",
                            "  ",
                            DataOstatniejKalibracji )
        THEN
          RETURN FALSE;
        END;
        IF NOT WrPrn( 0, "Nazwa aparatury pomiarowej: " ) OR
            NOT WrPrnLn( 0, NazwaAparaturyPomiarowej )
        THEN
          RETURN FALSE;
        END;
        IF NDB_Lotniskowe THEN
          IF NOT WrPrn( 0, "Urz¥dzenie NDB zostaˆo zadeklarowane jako lotniskowe" )
          THEN
            RETURN FALSE;
          END;
        ELSE
          IF NOT WrPrn( 0, "Urz¥dzenie NDB zostaˆo zadeklarowane jako wolno stoj¥ce" )
          THEN
            RETURN FALSE;
          END;
        END;
      END;
      IF NOT WrLn() THEN
        RETURN FALSE;
      END;
      RETURN TRUE;
    END PoczatekWypisywania;

  PROCEDURE KoniecWypisywania(  ) : BOOLEAN;
    VAR
      n    : NadajnikT;
    BEGIN
      IF NOT WrLn() OR NOT WrPrnLn( 0, PASEK ) THEN
        RETURN FALSE;
      END;
      IF NOT WrPrn( 0, "Sygnaˆ rozpoznawczy" ) THEN
        RETURN FALSE;
      END;
      FOR n := nA TO nB DO
        WITH Dane.Pomiary[n] DO
          IF SlyszalnoscPrawidlowa THEN
            IF NOT WrPrn( StartN[n], "| prawidˆowy" ) THEN
              RETURN FALSE;
            END;
          ELSE
            IF NOT WrPrn( StartN[n], "| nieprawidˆowy" ) THEN
              RETURN FALSE;
            END;
          END;
        END;
      END;
      IF NOT WrLn() OR NOT WrLn() OR NOT WrLn() THEN
        RETURN FALSE;
      END;

      IF Dane.UrzadzenieOK THEN
        IF NOT WrPrnLn( 0, "Urz¥dzenie speˆnia wymagania ICAO" ) THEN
          RETURN FALSE;
        END;
      ELSE
        IF NOT WrPrnLn( 0, "Urz¥dzenie nie speˆnia wymagaä ICAO" ) THEN
          RETURN FALSE;
        END;
      END;
      IF NOT WrLn() OR NOT WrPrnLn(0,"Uwagi") OR NOT WrLn() OR NOT WrLn() OR NOT WrLn() THEN
        RETURN FALSE;
      END;
      IF NOT WrPrnLn( 40, Dane.Odpowiedzialny ) THEN
        RETURN FALSE;
      END;
      IF NOT WrPrn( 0, ff ) THEN
        RETURN FALSE;
      END;
      RETURN TRUE;
    END KoniecWypisywania;

  PROCEDURE ZasiegiNaOdcinkach(     io : CARDINAL;
                                VAR oo : A_TablicaOdci;
                                VAR oz : ARRAY OF OpisyZasiegow );
    VAR
      i, j, k : CARDINAL;
    BEGIN
      IF io = 0 THEN
        RETURN;
      END;
      j := 0;
      FOR i := 0 TO io-1 DO
        (* wyznaczenie wysokosci *)
        WHILE (Events[pomiar].events[j].EventID # StartPomiaru) DO
          INC( j );
        END;
        oz[i].Wysokosc := Events[pomiar].events[j].Wysokosc;
        INC(j);
        ZaokraglicDo1000( oz[i].Wysokosc );
        (* zasieg *)
        PodstawCardinal( oz[i].Zasieg, CARDINAL(oo[i].pocz), FALSE );
        PodstawCardinal( oz[i].Zasieg, CARDINAL(oo[i].kon), FALSE );
      END;
    END ZasiegiNaOdcinkach;

    PROCEDURE UstawPokrycieWPoziomie( n : NadajnikT );
      VAR
        i, j : CARDINAL;
      BEGIN
        WITH Dane.Pomiary[n].PokrycieWPoziomie DO
          IF anRes.a_IleOd = 0 THEN
            RETURN;
          END;
          j := 0;
          FOR i := 0 TO anRes.a_IleOd-1 DO
            (* wyznaczenie wysokosci *)
            WHILE (Events[pomiar].events[j].EventID # StartPomiaru) DO
              INC( j );
            END;
            PodstawCardinal( Wysokosc,
                             Events[pomiar].events[j].Wysokosc,
                             TRUE );
          END;
          Zasieg := CARDINAL(anRes.promienLubOrbita);
        END;
      END UstawPokrycieWPoziomie;

  PROCEDURE RaportKoncowy(  );
    VAR
      void   : CARDINAL;
      f      : File;
      i      : INTEGER;
      n      : NadajnikT;
      dataOk : okTab;
      Ktorykolwiek_Nadajnik : BOOLEAN;
      Naglowek : Str99;
    BEGIN
      Dane.NazwaInspekcji := CommonData.NazwaOblotu;
      WITH Dane DO
        IF NOT GetInteractiveData( UrzadzenieOK,
                                   Odpowiedzialny,
                                   SamolotPomiarowy,
                                   DodatkoweButtony ) THEN
          RETURN;
        END;

        Lokalizacja := CommonData.NazwaUrzadz1;
        Czestotliwosc := FLOAT(NadajnikNDB.Czestotliwosc);
        Deklinacja := NadajnikNDB.Deklinacja;
        Polozenie  := NadajnikNDB.Polozenie;

        f := Open( "Kalibracja.ini" );
        Assert( f # MAX( CARDINAL ));
        WITH DataOstatniejKalibracji DO
          GetFileStamp( f, d, m, y, void, void, void );
        END;
        Close( f );

        GlownyOdbiornik := CommonData.GlownyOdbiornik;

        IF NOT PoczatekWypisywania() THEN
          RETURN;
        END;

        Procedura := pOrbita;
        Ktorykolwiek_Nadajnik := FALSE;
        FOR n := nA TO nB DO
          CommonData.Nadajnik1 := n;
          N_Oblot.SciezkaDoKataloguOpisu();
          LoadData( dataOk );
          GoHomeDir;
          InitOrbita(Dane.Pomiary[n]);
          IF dataOk[pomiar] THEN
            Ktorykolwiek_Nadajnik := TRUE;
            Dane.Pomiary[n].KiedyOrbita := anRes.data.d;
            UstawPokrycieWPoziomie( n );
          END;
        END;
        IF Ktorykolwiek_Nadajnik THEN
          i := CARDINAL( anRes.promienLubOrbita ) DIV 500;
          f := CARDINAL( anRes.promienLubOrbita ) MOD 500 DIV 5;
          sprintf2( Naglowek, "Raport z lotu NDB na orbicie %d.%02dNM", i, f );
          IF NOT DrukujOrbite( Naglowek ) THEN
            RETURN;
          END;
        ELSE
          IF NOT WrPrnLn( 0, "Nie przeprowadzono lotu po orbicie !!!" ) THEN
            RETURN;
          END;
        END;
        Procedura := pPromien;
        FOR i := 0 TO 359 DO (* na chama przegladac wszystkie bo to chyba szybciej *)
          Ktorykolwiek_Nadajnik := FALSE;
          FOR n := nA TO nB DO
            CommonData.Nadajnik1 := n;
            CommonData.Promien := i;
            N_Oblot.SciezkaDoKataloguOpisu();
            LoadData( dataOk );
            GoHomeDir;
            InitPromien(Dane.Pomiary[n]);
            IF dataOk[pomiar] THEN
              Ktorykolwiek_Nadajnik := TRUE;
              Dane.Pomiary[n].KiedyPromien := anRes.data.d;
              ZasiegiNaOdcinkach( anRes.a_IleOd,
                                  anRes.analiza,
                                  Dane.Pomiary[n].PokrycieWPionie );
            END;
          END;
          IF Ktorykolwiek_Nadajnik THEN
            sprintf( Naglowek, "Raport z lotu NDB na promieniu %dø", i );
            IF NOT DrukujPromien( Naglowek ) THEN
              RETURN;
            END;
          END;
        END;

        IF NOT KoniecWypisywania() THEN
          RETURN;
        END;
      END;
    END RaportKoncowy;

  PROCEDURE InitPromien( VAR p : PomiarNadajnika );
    VAR
      i : CARDINAL;
    BEGIN
      p.KiedyPromien.y := 0;
      FOR i := 0 TO HIGH( p.PokrycieWPionie ) DO
        WITH p.PokrycieWPionie[i] DO
          Wysokosc := NilValC;
          Zasieg   := NilValC;
        END;
      END;
    END InitPromien;

  PROCEDURE InitOrbita( VAR p : PomiarNadajnika );
    BEGIN
      p.KiedyOrbita.y  := 0;
      p.PokrycieWPoziomie.Wysokosc := NilValC;
      p.PokrycieWPoziomie.Zasieg := NilValC;
    END InitOrbita;

  PROCEDURE InitLocalData( VAR p : PomiarNadajnika );
    BEGIN
      InitPromien( p );
      InitOrbita( p );
    END InitLocalData;

  PROCEDURE InitDane(  );

    VAR
      n : NadajnikT;
      i : INTEGER;
    BEGIN
      WITH Dane DO
        NazwaInspekcji[0] := 0C;
        Lokalizacja[0] := 0C;
        (*Polozenie :=            Cokolwiek *)
        Czestotliwosc := 0.0;
        Odpowiedzialny[0] := 0C;
        Deklinacja := 0.0;
        GlownyOdbiornik := MIN( GlownyOdbiornikT );
        (* DataOstatniejKalibracji nieinicjowane *);
        NazwaAparaturyPomiarowej := 'CFIS-1';
        SamolotPomiarowy := 'SP-TPA';
        FOR n := MIN( NadajnikT ) TO MAX( NadajnikT ) DO
          InitLocalData( Pomiary[n] );
        END;
      END;
    END InitDane;

BEGIN
  AktualnyPromien := 0;
  StartN[nA] := 32;
  StartN[nB] := 48;
  StartTol   := 64;
  InitDane;
END N_Report.
