(*.F- *)
(**********************************************************************
|  Title   : Raport koncowy dla DME
|  Author  : M.Morawski
|  System  : LOGITECH MODULA-2/86
|  History :
|    08-05-97: M.Postol
|      zmiana nazwy modulu
|    06-20-97 07:20pm: MM
|      pokrycie w poziomie rozdzielono: kazdy nadajnik na iinej stronie
|
|  Copyright (C), CAS LODZ POLAND.
|  TEL: 42' 862 547, 42' 87 80 44 FAX/TEL: 42' 84 48 40
|
**********************************************************************)
(*.F+ *)

IMPLEMENTATION MODULE D_Report;

FROM CommonTypes IMPORT
  Date, Str40, Str99, PolozenieGeo, OdnDlaPomOdlT, NadajnikT,
  GlownyOdbiornikT, NilValC, SignalDsc, TimeAndDate, NilValI,
  OdnDlaPomBleduT;
FROM RTSMain IMPORT
  Terminate, Status;
FROM Czas IMPORT
  GetTimeAndDate;
FROM NumberConversion IMPORT
  IntToString;
FROM Marks IMPORT
  AngMarksDsc, AngResetContiner, AngAddSample;
FROM D_results IMPORT
  anRes, Signals, OdcinekNr, A_TablicaOdci;
FROM FlagAnal IMPORT
  FlagsTable;
FROM FIO IMPORT
  File, Open, Close, CD, Read, GetFileStamp, Write, Create;
FROM Files IMPORT
  ExistDIR, GoHomeDir, GetALfaRefFName;
FROM D_Files IMPORT
  GetFileName;
FROM StdIO IMPORT
  sprintf, sprintf2, sprintf3, sprintf4;
FROM D_CommonTypes IMPORT
  ProceduraT;
FROM Strings IMPORT
  Assign, Length, Insert;
FROM PI_ArchDate IMPORT
  okTab, LoadData;
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
  PI_DMEnaglowek,
  HiLevGraf,
  Files,
  FIO,
  D_Files;
FROM ASCII IMPORT
  ff;
FROM Dialog IMPORT
  HDLG, WstawButton;
FROM Buttons IMPORT
  Button, ChangeButtonText;
FROM GrafTypes IMPORT
  RECT, AssignRect, MoveRect, WHITE;
FROM ShortCuts IMPORT
  kbAltY, kbCtrlY, kbAltD, kbCtrlD;
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
  pomiar      = TRUE;
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
    DokladnoscWNormie             : BOOLEAN;
  END;

  RaportKoncowyDesc = RECORD
    NazwaInspekcji           : Str40;
    Lokalizacja              : Str40;
    Polozenie                : PolozenieGeo;
    Czestotliwosc            : REAL;
    Deklinacja               : REAL;
    Odpowiedzialny           : Str40;
    SamolotPomiarowy         : ARRAY[0..6] OF CHAR;
    Odniesienie              : OdnDlaPomOdlT;
    GlownyOdbiornik          : GlownyOdbiornikT;
    DataOstatniejKalibracji  : Date;
    NazwaAparaturyPomiarowej : Str40;
    Pomiary                  : ARRAY NadajnikT OF PomiarNadajnika;
    UrzadzenieOK             : BOOLEAN;
  END;

  Buttony = ARRAY NadajnikT OF Button;



VAR
  StartN : ARRAY NadajnikT OF CARDINAL;
  StartTol : CARDINAL;
  AktualnyPromien : CARDINAL;
VAR
  DWN  : Buttony; (* dokladnosc w normie *)
  SR   : Buttony; (* sygnal rozpoznawczy *)
  Dane : RaportKoncowyDesc;



  PROCEDURE DokladnoscWNormie_P(     n : NadajnikT;
                                 VAR b : Buttony   );
    BEGIN
      WITH Dane.Pomiary[n] DO
        DokladnoscWNormie := NOT DokladnoscWNormie;
        IF (DokladnoscWNormie) THEN
          ChangeButtonText( b[n], "DOKADNO— W NORMIE" );
        ELSE
          ChangeButtonText( b[n], "DOKADNO— POZA NORM¤" );
        END;
      END;
    END DokladnoscWNormie_P;

  PROCEDURE DokladnoscWNormie_A(  );
    BEGIN
      DokladnoscWNormie_P( nA, DWN );
    END DokladnoscWNormie_A;

  PROCEDURE DokladnoscWNormie_B(  );
    BEGIN
      DokladnoscWNormie_P( nB, DWN );
    END DokladnoscWNormie_B;

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
      AssignRect( R, 500, 340, 790, 370 );
      WstawButton( h, R, "", 0, kbAltD, DokladnoscWNormie_A, DWN[nA] );
      MoveRect( R, 0, 100 );
      WstawButton( h, R, "", 0, kbCtrlD, DokladnoscWNormie_B, DWN[nB] );
      HiLevGraf.WrStr( "Nadajnik `A'", 500, 280, WHITE, WHITE );
      HiLevGraf.WrStr( "Nadajnik `B'", 500, 380, WHITE, WHITE );
      FOR n := nA TO nB DO
        WITH Dane.Pomiary[n] DO
          SlyszalnoscPrawidlowa := FALSE;
          DokladnoscWNormie := FALSE;
          SygnalRozpoznawczy( n, SR );
          DokladnoscWNormie_P( n, DWN );
        END;
      END;
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

  PROCEDURE WrPrnFmt( At   : INTEGER;
                      Fmt  : ARRAY OF CHAR;
                      Dane : ARRAY OF BYTE ) : BOOLEAN;
    VAR
      str   : ARRAY[0..99] OF CHAR;
    BEGIN
      IF CHAR(Dane[0]) = 0377c THEN
        RETURN WrPrn( At, '| ******' );
      ELSE
        sprintf( str, Fmt, Dane );
        IF NOT WrPrn( At, str ) THEN
          RETURN FALSE;
        ELSE
          RETURN TRUE;
        END;
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
                        Fmt  : ARRAY OF CHAR;
                        Dane : ARRAY OF BYTE ) : BOOLEAN;
  BEGIN
    RETURN WrPrnFmt( At, Fmt, Dane ) & WrLn();
  END WrPrnFmtLn;


  PROCEDURE ZaokraglicDo1000( VAR h : CARDINAL );
    BEGIN
      IF h # NilValC THEN
        h := ((h+500) DIV 1000) * 1000;
      END;
    END ZaokraglicDo1000;

  PROCEDURE WrOdcinek( Nr : CARDINAL; a, b : OpisyZasiegow ) : BOOLEAN;
    CONST
      CONV_STR = "| %d/%x";
    VAR
      v : ARRAY [0..1] OF CARDINAL;
      wys : Str99;
    BEGIN
      ZaokraglicDo1000( a.Wysokosc );
      ZaokraglicDo1000( b.Wysokosc );
      sprintf( wys, "%2d Wysoko˜† [ft]/[NM]", Nr );
      IF NOT WrPrn( 0, wys ) THEN
        RETURN FALSE;
      END;
      IF NOT WrPrnFmt( StartN[nA], CONV_STR, a ) THEN
        RETURN FALSE;
      END;
      IF NOT WrPrnFmt( StartN[nB], CONV_STR, b ) THEN
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
      ZAS_LINE = {0,4,8,12};
    VAR
      TablicaLecianychWysokosci : ARRAY OdcinekNr OF CARDINAL;
      IleRoznychWysokosci : INTEGER;
      MaxZasieg : CARDINAL;
      i, j, w      : INTEGER;
      px, py, x, y : INTEGER;
      n            : NadajnikT;
      s            : Str99;


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
        DrawEpson.DrawText( Naglowek, 
                            DrawEpson.MaxX()-Length( Naglowek)*2*8-10,
                            0 );
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
        FOR i := 0 TO HIGH( Dane.Pomiary[nA].PokrycieWPionie ) DO
          WITH Dane.Pomiary[n].PokrycieWPionie[i] DO
            IF (Wysokosc # NilValC) THEN
              w := IndexWys( Wysokosc );
              y := PolozenieNaWspolrzednejY(w);
              x := VAL( CARDINAL, VAL( LONGINT, Zasieg ) *
                                  VAL( LONGINT, DrawEpson.MaxX() -1) DIV
                                  VAL( LONGINT, MaxZasieg ));
              DrawEpson.Line( x, 0, x, DrawEpson.MaxY(), ZAS_LINE );
              IF (px # NilValI) THEN
                DrawEpson.Line( px, py, x, y, {0..15} );
              END;
              px := x;
              py := y;
            END;
          END;
        END;
        DrawEpson.Mnoznik( 4, 2 );
        IF n = nA THEN
          DrawEpson.DrawText( "Wykres pokrycia pionowego dla odb. glownego", 200, 10 );
        ELSE
          DrawEpson.DrawText( "Wykres pokrycia pionowego dla odb. zapasowego", 
          200, 10 );
        END;
        IF NOT DrawEpson.Out(DrawEpson.WrProc) THEN
          DrawEpson.Close;
          RETURN FALSE;
        END;
        DrawEpson.Close;
      END;

      RETURN TRUE;
    END WykresPokryciaWPionie;

  PROCEDURE WykresPokryciaWPoziomie
            ( VAR Naglowek : ARRAY OF CHAR  ) : BOOLEAN;
    CONST
      M_PI = 3.1415926;
      Zero_dBm= -90;
      MIN_dBm = -80;
      MAX_dBm = -50;
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
      radial    : INTEGER;


        PROCEDURE CoordAt(     agc   : INTEGER;
                               angle : REAL;
                           VAR x, y  : INTEGER );
          VAR
            promien,
            xR,
            yR       : REAL;
          BEGIN
            angle := angle -90.0;
            angle := angle * M_PI/180.0;
            promien := real( agc - Zero_dBm ) / real(MAX_dBm-Zero_dBm) *
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
        FOR radial := MAX_dBm TO Zero_dBm - 5 BY -10 DO
          Circle( radial );
        END;
        DrawEpson.Mnoznik( 2, 1 );
        DrawEpson.DrawText( Naglowek, 0, 0 );
        DrawEpson.Mnoznik( 2, 1 );
        FOR i := 0 TO 359 BY 30 DO
          CoordAt( MAX_dBm, FLOAT(i), x, y );
          DrawEpson.Line(CenterX, CenterY, x, y, {0..15} );
          CoordAt( (2*MAX_dBm+MIN_dBm) DIV 3, FLOAT(i+3), x, y );
          sprintf( KatS, "%dø", i );
          DrawEpson.DrawText( KatS, x, y );
        END;
        FOR radial := MAX_dBm TO Zero_dBm + 5 BY -10 DO
          CoordAt( radial, 90.0, x, y );
          sprintf( KatS, "%ddBmø", radial);
          DrawEpson.DrawText( KatS, x, y+1 );
        END;
      (* Tlo wykresu zostalo narysowane *)

        PrevX := NilValI;
        PrevY := NilValI;

        CommonData.Nadajnik1 := n;
        PI_DMEnaglowek.UstawSciezke;
        Assign( CommonData.SciezkaOpisuPomiaru, FileName );
        FileName[ Length( FileName ) -1 ] := 0C;

        IF CD( FileName ) THEN
          D_Files.GetFileName( AGC, Dane.GlownyOdbiornik, FileName );
          AgcFile := Open(FileName);
          Assert( AgcFile # MAX( CARDINAL ));
          Files.GetALfaRefFName( pbGPS, TRUE, FileName );
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
        IF (n = nA) THEN
          DrawEpson.DrawText( 'Wykres siˆy sygnaˆu dla nadajnika gˆ¢wnego',
                              0, 
                              10 );
        ELSE
          DrawEpson.DrawText( 'Wykres siˆy sygnaˆu dla nadajnika zapasowego',
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
          IF NOT WrFmtNad( n, KiedyPromien.y # 0, DATA_STR, KiedyPromien ) THEN
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
      IF NOT WykresPokryciaWPoziomie(Naglowek) THEN
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
      IF NOT WrPrnFmtLn( 0, "RAPORT Z INSPEKCJI DME WYKONANY O GODZ. %02d:%02d dnia %02d.%02d.%d", td ) THEN
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
                            Polozenie )
        THEN
          RETURN FALSE;
        END;
        IF NOT WrPrnFmtLn( 0, "Deklinacja: %3.1lfø", Deklinacja ) THEN
          RETURN FALSE;
        END;
        IF NOT WrPrnFmtLn( 0, "Cz©stotliwo˜† (stow): %5.2lfMHz", Czestotliwosc ) THEN
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
                            c )
        THEN
          RETURN FALSE;
        END;
        IF NOT WrPrnFmtLn( 0,
                            "Data ostatniej kalibracji: %02d.%02d.%d",
                            DataOstatniejKalibracji )
        THEN
          RETURN FALSE;
        END;
        IF NOT WrPrn( 0, "Nazwa aparatury pomiarowej: " ) OR
            NOT WrPrnLn( 0, NazwaAparaturyPomiarowej )
        THEN
          RETURN FALSE;
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
      IF NOT WrPrn( 0, "Dokˆadno˜†" ) THEN
        RETURN FALSE;
      END;
      FOR n := nA TO nB DO
        WITH Dane.Pomiary[n] DO
          IF DokladnoscWNormie THEN
            IF NOT WrPrn( StartN[n], "| w normie" ) THEN
              RETURN FALSE;
            END;
          ELSE
            IF NOT WrPrn( StartN[n], "| poza norm¥" ) THEN
              RETURN FALSE;
            END;
          END;
        END;
      END;
      IF NOT WrLn() THEN
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
          (*
          IF j > Events[pomiar].EventIDX THEN
            RETURN;
          END;
          *)
        END;
        oz[i].Wysokosc := Events[pomiar].events[j].Wysokosc;
        INC(j);
        ZaokraglicDo1000(oz[i] .Wysokosc );
        (* zasieg *)
        WITH oo[i].wykluczenia[ Dane.GlownyOdbiornik ] DO
          FOR k := 1 TO w_IleOd DO
            (* wybor najblizszej odleglosci *)
            WITH opis[k] DO
              PodstawCardinal( oz[i].Zasieg, CARDINAL(pocz), FALSE );
              PodstawCardinal( oz[i].Zasieg, CARDINAL(kon), FALSE );
            END;
          END;
          IF oz[i].Zasieg = NilValC THEN
            (* wybor najwiekszej odleglosci *)
            PodstawCardinal( oz[i].Zasieg, CARDINAL(oo[i].pocz), TRUE );
            PodstawCardinal( oz[i].Zasieg, CARDINAL(oo[i].kon), TRUE );
          ELSE
          END;
        END;
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
          Zasieg := CARDINAL(anRes.PromienLubOrbita);
        END;
      END UstawPokrycieWPoziomie;

  PROCEDURE RaportKoncowy(  );
    VAR
      void   : CARDINAL;
      f      : File;
      i      : INTEGER;
      n      : NadajnikT;
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
        PI_DMEnaglowek.DaneZBazyDanych( Czestotliwosc, Deklinacja, Polozenie );

        f := Open( "Kalibracja.ini" );
        Assert( f # MAX( CARDINAL ));
        WITH DataOstatniejKalibracji DO
          GetFileStamp( f, d, m, y, void, void, void );
        END;
        Close( f );

        Odniesienie  := CommonData.OdnDlaPomOdl;
        GlownyOdbiornik := CommonData.GlownyOdbiornik;

        IF NOT PoczatekWypisywania() THEN
          RETURN;
        END;

        PI_DMEnaglowek.NastepneDane( DaneDlaDME );

        IF NOT KoniecWypisywania() THEN
          RETURN;
        END;
      END;
    END RaportKoncowy;


    PROCEDURE DaneDlaDME(     PromienNieOrbita : BOOLEAN;
                              n                : NadajnikT;
                          VAR Naglowek         : ARRAY OF CHAR;
                              TylkoDruk        : BOOLEAN
                        ) : BOOLEAN;
      BEGIN
        (* Procedura zaklada, ze dane sa dobrze ustawione *)
        IF NOT TylkoDruk THEN
          IF (PromienNieOrbita) THEN
            Dane.Pomiary[n].KiedyPromien := anRes.data.d;
            ZasiegiNaOdcinkach( anRes.a_IleOd,
                                anRes.analiza,
                                Dane.Pomiary[n].PokrycieWPionie );
          ELSE
            Dane.Pomiary[n].KiedyOrbita := anRes.data.d;
            UstawPokrycieWPoziomie( n );
          END;
        END;
        IF (n = MAX( NadajnikT )) OR TylkoDruk THEN
          IF PromienNieOrbita THEN
            IF NOT DrukujPromien( Naglowek ) THEN
              RETURN FALSE;
            END;
          ELSE
            IF NOT DrukujOrbite( Naglowek ) THEN
              RETURN FALSE;
            END;
          END;
        END;
        RETURN TRUE;
      END DaneDlaDME;

  PROCEDURE InitLocalData( VAR p : PomiarNadajnika );
    VAR
      i : CARDINAL;
    BEGIN
      p.KiedyPromien.y := 0;
      p.KiedyOrbita.y  := 0;
      FOR i := 0 TO HIGH( p.PokrycieWPionie ) DO
        WITH p.PokrycieWPionie[i] DO
          Wysokosc := NilValC;
          Zasieg   := NilValC;
        END;
      END;
      p.PokrycieWPoziomie.Wysokosc := NilValC;
      p.PokrycieWPoziomie.Zasieg := NilValC;
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
        Odniesienie := MIN( OdnDlaPomOdlT );
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
END D_Report.
