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
|    17-05-98: M.Morawski
|      blad przy rysowaniu skal
|    Rel.3.0.MPostol
|     - Program wywalal sie gdy wysokosc < 0 Uzdrowilem przez podstawienie 0
|       w takiej sytuacji
|    Rel.3.02. MPostol
|     - wypisywanie maksymalnego bledu.
|     - zly format dla polozenia geograficznego w raportach koncowych
|    Rel 3.14
|     - Jesli na nadajniku nie bylo pomiaru na wydruku sygnalizowane jest,
|       ze nie bylo pomiaru niezaleznie od ustawienia klawiszy
|     - zlikwidowano niepotrzebny wydruk zasigu pionowego na nadajnika, ktory
|       nie byl mierzony.
 
|
|  Copyright (C), CAS LODZ POLAND.
|  TEL: 42' 686 25 47
|  mailto: techsupp@cas.com.pl
|  http: www.cas.com.pl
|
**********************************************************************)
(*.F+ *)
IMPLEMENTATION MODULE D_Report;

FROM CommonTypes IMPORT
  Str40, Str99, PolozenieGeo, OdnDlaPomOdlT, NadajnikT,
  GlownyOdbiornikT, NilValC, NilValI, SigNilVal, 
  OdnDlaPomBleduT, SignalDsc, InitSignalDsc, RodzajLotu, Reprezentacja;
FROM Czas IMPORT
  TimeAndDate, Date, GetTimeAndDate;
FROM D_results IMPORT
  anRes, Signals, OdcinekNr, A_TablicaOdci, A_OpisOdcinka;
FROM FIO IMPORT
  File, Open, Close, CD, Read;
FROM Files IMPORT
  GoHomeDir;
FROM StdIO IMPORT
  sprintf;
FROM Strings IMPORT
  Assign, Length, ConstAssign;FROM SYSTEM IMPORT
  ADR, BYTE;
FROM MANAGER IMPORT
  Assert;
FROM GrafUtil IMPORT
  InfoBeep;
FROM Rap_Util IMPORT
  GetInteractiveData;
FROM MathLib0 IMPORT
  real, entier, sin, cos;
FROM Print IMPORT
  WrPrn, WrPrnLn, WrLn, PASEK, GWIAZDKI, PrnX, PrnY,
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
FROM Ini IMPORT
  GetPrivateProfileString;

  FROM MMA_Cout  IMPORT
    MMA_SignalDsc;

  FROM WorseBecause IMPORT
    WorseBGreater, WorseBLess;
  
  FROM PrintUtl IMPORT
    (* PROCEDURE *) PiszSignalDsc, 
    (* TYPE *)      KolStrWaska,
    (* CONST *)     NagTab1, NagTab2nad, NagTab3nad, NagTab4, NagTab8, 
                    KolStr, Wr_NagTab10, NagTab9;
  
  FROM SpecConv IMPORT
    Int2Card, Int500Str, ZaokraglicDo500;
  
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
    PWP_LiczbaOdcikow             : CARDINAL;
    PokrycieWPionie               : ARRAY OdcinekNr OF OpisyZasiegow;
    PokrycieWPoziomie             : OpisyZasiegow;
    BledyOdleglosciOrb            : INTEGER;
    SSminDlaPomOrb                : SignalDsc;
    BledyOdleglosciPro            : INTEGER;
    SlyszalnoscPrawidlowa         : BOOLEAN;
    DokladnoscWNormie             : BOOLEAN;
    BylPomiar                     : BOOLEAN;
  END;

  RaportKoncowyDesc = RECORD
    NazwaInspekcji           : Str40;
    Lokalizacja              : Str40;
    Polozenie                : PolozenieGeo;
    Czestotliwosc            : REAL;
    Deklinacja               : REAL;
    Odpowiedzialny           : Str40;
    SamolotPomiarowy         : ARRAY[ 0..6 ] OF CHAR;
    Odniesienie              : OdnDlaPomOdlT;
    GlownyOdbiornik          : GlownyOdbiornikT;
    DataOstatniejKalibracji  : Str40;
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
  line : CARDINAL;
  

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

  PROCEDURE WrPrnFmtLn( At   : INTEGER;
                        Fmt  : ARRAY OF CHAR;
                        Dane : ARRAY OF BYTE ) : BOOLEAN;
  BEGIN
    RETURN WrPrnFmt( At, Fmt, Dane ) & WrLn();
  END WrPrnFmtLn;


  PROCEDURE RaportKoncowy(  );

  PROCEDURE PoczatekWypisywania(  ) : BOOLEAN;
    VAR
      td   : TimeAndDate;
      c    : CHAR;
    BEGIN (* PoczatekWypisywania *)
(*
      (* symulacja drukarki *)
      DrukarkaSim := Create( PrnFileName );
      TextModeOutProc := FIOOut;
*)
      PrnX := 0;
      PrnY := 0;
      GetTimeAndDate( td );
      IF NOT WrPrnFmtLn
         ( 0, 
     "RAPORT Z INSPEKCJI DME WYKONANY O DNIA: %02d.%02d.%04d GODZ: %02d:%02d", 
           td ) 
      THEN
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
                    "Poˆo¾enie geograficzne: %dø%02d.%04d'E, %dø%02d.%04d'N",
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
        IF NOT WrPrn( 0, "Data ostatniej kalibracji : " ) OR
           NOT WrPrnLn( 0,  DataOstatniejKalibracji)
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

    PROCEDURE AssignButtString
              (     spelniaNorme : BOOLEAN;
                    bylPomiar    : BOOLEAN;
                VAR str          : ARRAY OF CHAR) ;
    BEGIN
      IF NOT bylPomiar  THEN
        ConstAssign("nie spr.",   str);
        RETURN
      END (* IF *);
      IF spelniaNorme THEN
        ConstAssign("w normie",   str);
      ELSE
        ConstAssign("poza norm¥", str);
      END;
    END AssignButtString;

  PROCEDURE KoniecWypisywania(  ) : BOOLEAN;
    VAR
      n      : NadajnikT;
      kolStr : ARRAY NadajnikT  OF KolStr;
      linia  : CARDINAL;
      
    BEGIN
      IF NOT WrPrnLn( 0, NagTab9 ) THEN
        RETURN FALSE;
      END;
      FOR n := nA TO nB DO
        WITH Dane.Pomiary[n] DO
          AssignButtString(DokladnoscWNormie, BylPomiar, kolStr[n]);
        END;
      END;
      IF NOT Wr_NagTab10("Dokˆadno˜†", kolStr[nA], kolStr[nB]) THEN
        RETURN FALSE;
      END (* if *);
      IF NOT WrPrnLn( 0, NagTab4 ) THEN
        RETURN FALSE;
      END;
      FOR n := nA TO nB DO
        WITH Dane.Pomiary[n] DO
          AssignButtString(SlyszalnoscPrawidlowa, BylPomiar, kolStr[n]);
        END;
      END;
      IF NOT Wr_NagTab10("Sygnaˆ rozpoznawczy", kolStr[nA], kolStr[nB]) THEN
        RETURN FALSE;
      END (* if *);
      IF NOT WrPrnLn( 0, NagTab8 ) THEN
        RETURN FALSE;
      END;
      FOR linia := 0 TO 2 DO
        IF NOT WrLn() THEN
          RETURN FALSE;
        END;
      END (* for *);
      IF Dane.UrzadzenieOK THEN
        IF NOT WrPrnLn( 0, "Urz¥dzenie speˆnia wymagania ICAO" ) THEN
          RETURN FALSE;
        END;
      ELSE
        IF NOT WrPrnLn( 0, "Urz¥dzenie nie speˆnia wymagaä ICAO" ) THEN
          RETURN FALSE;
        END;
      END;
      IF NOT WrLn() OR NOT WrPrnLn(0,"Uwagi") THEN
        RETURN FALSE;
      END;
      FOR linia := 0 TO 10 DO
        IF NOT WrLn() THEN
          RETURN FALSE;
        END;
      END (* for *);
      IF NOT WrPrnLn( 40, Dane.Odpowiedzialny ) THEN
        RETURN FALSE;
      END;
      IF NOT WrPrn( 0, ff ) THEN
        RETURN FALSE;
      END;
      RETURN TRUE;
    END KoniecWypisywania;

    BEGIN (* RaportKoncowy *)
      InitDane;
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
        GetPrivateProfileString( "DataKalibracji", 
                                 "Data", 
                                 "15-09-2000", 
                                 DataOstatniejKalibracji,
                                 CommonData.NazwaPlikuOpisu );
        Odniesienie     := CommonData.OdnDlaPomOdl;
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

 PROCEDURE DaneDlaDME
           (     PromienNieOrbita : BOOLEAN;
                 nadajnik         : NadajnikT;
             VAR Naglowek         : ARRAY OF CHAR;
                 TylkoDruk        : BOOLEAN ) : BOOLEAN;
                 
        (* Procedura zaklada, ze dane sa dobrze ustawione *)

  PROCEDURE WrOdcinek( Nr : CARDINAL; a, b : OpisyZasiegow ): BOOLEAN ;
    CONST
      CONV_STR = "| %d/%x";
    VAR
      wys : Str99;
    BEGIN
      ZaokraglicDo500( a.Wysokosc );
      ZaokraglicDo500( b.Wysokosc );
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

    PROCEDURE UstawPokrycieWPoziomie
              ( nadajnik : NadajnikT );
      VAR
        idx : CARDINAL;
        j   : CARDINAL;
        
      BEGIN (* UstawPokrycieWPoziomie *)
        WITH Dane.Pomiary[nadajnik] DO
          BledyOdleglosciOrb := SigNilVal;
          InitSignalDsc(SSminDlaPomOrb,     SigNilVal);
          WITH anRes DO
            IF a_IleOd = 0 THEN
              RETURN;
            END;
            j := 0;
            line := 534;
            WITH odlBlaSren[ Dane.GlownyOdbiornik ] DO
              BledyOdleglosciOrb     := avr;
              WITH PokrycieWPoziomie DO
                FOR idx := 0 TO anRes.a_IleOd-1 DO
                  (* wyznaczenie wysokosci *)
                  line := 542;
                  WHILE Events[pomiar].events[j].EventID # StartPomiaru DO
                    line := 543;
                    INC( j );
                  END;
                  line := 547;
                  PodstawCardinal( Wysokosc,
                                   Int2Card(
                                          Events[pomiar].events[j].Wysokosc),
                                   TRUE );
                  line := 549;
                  WITH analiza[idx].SSmin[Dane.GlownyOdbiornik]   DO
                    WorseBLess(SSminDlaPomOrb, val, pos);
                  END (* WITH *);
                END (* FOR idx := 0 *);
                line := 556;
                Zasieg := CARDINAL(PromienLubOrbita);
                line := 558;
              END (* WITH PokrycieWPoziomie *);
            END (* WITH *);
          END (* WITH anRes *);
        END (* WITH Dane.Pomiary *);
      END UstawPokrycieWPoziomie;

    PROCEDURE ZasiegiNaOdcinkach
              (     io                 : CARDINAL;
                    odlBlaSren         : MMA_SignalDsc;
                VAR oo                 : A_TablicaOdci;
                VAR oz                 : ARRAY OF OpisyZasiegow;
                VAR lo                 : CARDINAL;
                VAR BledyOdleglosci    : INTEGER);
    VAR
      i, j, k : CARDINAL;
      
    BEGIN (* ZasiegiNaOdcinkach *)
      IF io = 0 THEN
        RETURN;
      END;
      BledyOdleglosci := SigNilVal;
      lo := io;
      BledyOdleglosci := odlBlaSren.avr;
      j := 0;
      FOR i := 0 TO io - 1 DO
        (* wyznaczenie wysokosci *)
        WHILE (Events[pomiar].events[j].EventID # StartPomiaru) DO
          INC( j );
          (*
          IF j > Events[pomiar].EventIDX THEN
            RETURN;
          END;
          *)
        END;
        oz[i].Wysokosc := Int2Card(Events[pomiar].events[j].Wysokosc);
        INC(j);
        ZaokraglicDo500( oz[i].Wysokosc );
        (* zasieg *)
        WITH oo[i].wykluczenia[ Dane.GlownyOdbiornik ] DO
          FOR k := 1 TO w_IleOd DO
            (* wybor najblizszej odleglosci *)
            WITH opis[k] DO
              PodstawCardinal( oz[i].Zasieg, CARDINAL(pocz), FALSE );
              PodstawCardinal( oz[i].Zasieg, CARDINAL(kon),  FALSE );
            END;
          END;
          IF oz[i].Zasieg = NilValC THEN
            (* wybor najwiekszej odleglosci *)
            PodstawCardinal( oz[i].Zasieg, CARDINAL(oo[i].pocz), TRUE );
            PodstawCardinal( oz[i].Zasieg, CARDINAL(oo[i].kon),  TRUE );
          ELSE
          END (* IF oz[i].Zasieg *);
        END (* WITH oo[i].wykluczenia *);
      END;
    END ZasiegiNaOdcinkach;

    PROCEDURE DatyNagl(  ) : BOOLEAN;
    BEGIN
      IF NOT WrPrn  ( StartN[nA], "| Nad. Gˆ¢wny  " ) OR
         NOT WrPrnLn( StartN[nB], "| Nad. Zapasowy" )
      THEN
        RETURN FALSE;
      ELSE
        RETURN WrPrn( 0, "Data wykonania pomiaru:" );
      END;
    END DatyNagl;

    PROCEDURE WrFmtNad
              (    Nad      : NadajnikT;
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

    PROCEDURE DrukujOrbite
              ( VAR Naglowek : ARRAY OF CHAR ) : BOOLEAN;
    VAR
      nidx      : NadajnikT;
      bladOdlA  : KolStrWaska;
      bladOdlB  : KolStrWaska;
  
  PROCEDURE WykresPokryciaWPoziomie
            (     nad      : NadajnikT;
              VAR Naglowek : ARRAY OF CHAR  ) : BOOLEAN;
    CONST
      M_PI        = 3.1415926;
      Zero_dBm    = -90;
      MIN_dBm     = -80;
      MAX_dBm     = -50;
      style       = {0..15};
    VAR
      CenterX,
      CenterY    : INTEGER;
      Aspect     : REAL;
      x, y       : INTEGER;
      PrevX,
      PrevY      : INTEGER;
      i          : CARDINAL;
      AgcFile,
      AngleFile  : File;
      FileName   : Str99;
      agc,
      angle      : INTEGER;
      KatS       : Str40;
      radial     : INTEGER;


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

    BEGIN (* WykresPokryciaWPoziomie *)
      CenterX := DrawEpson.MaxX() DIV 2;
      CenterY := DrawEpson.MaxY() DIV 2;
      Aspect  := ( (FLOAT( DrawEpson.MaxX()) /  8.0 (* cali *))) /
                 ( (FLOAT( DrawEpson.MaxY()) / 12.0 (* cali *)));
      Aspect := 1.253/Aspect;
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

        CommonData.Nadajnik1 := nad;
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
        IF (nad = nA) THEN
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
      RETURN TRUE;
    END WykresPokryciaWPoziomie;
    
    BEGIN (* DrukujOrbite *)
      (* Wyniki pomiarow *)
      IF NOT WrPrnLn( 0, PASEK ) THEN
        RETURN FALSE;
      END;
      IF NOT WrPrnLn( 0, Naglowek ) THEN
        RETURN FALSE;
      END;
      IF NOT DatyNagl() THEN
        RETURN FALSE;
      END;
      FOR nidx := MIN( NadajnikT ) TO MAX( NadajnikT ) DO
        WITH Dane.Pomiary[nidx] DO
          IF NOT WrFmtNad( nidx, KiedyOrbita.y # 0, DATA_STR, KiedyOrbita ) THEN
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
      WITH Dane  DO
        IF NOT WrOdcinek( 1,
                          Pomiary[nA].PokrycieWPoziomie,
                          Pomiary[nB].PokrycieWPoziomie )
        THEN
          RETURN FALSE;
        END;
        IF NOT WrPrnLn( 0, NagTab1 ) THEN
          RETURN FALSE;
        END;
        IF NOT WrPrnLn( 0, NagTab2nad ) THEN
          RETURN FALSE;
        END;
        IF NOT WrPrnLn( 0, NagTab3nad ) THEN
          RETURN FALSE;
        END;
        IF NOT WrPrnLn( 0, NagTab4 ) THEN
          RETURN FALSE;
        END;
        Int500Str(Pomiary[nA].BledyOdleglosciOrb, bladOdlA, 7);
        Int500Str(Pomiary[nB].BledyOdleglosciOrb, bladOdlB, 7);
        IF NOT Wr_NagTab10("Blad odleglosci ˜redni [NM]", bladOdlA, bladOdlB) 
        THEN
          RETURN FALSE;
        END (* IF *);
        IF NOT PiszSignalDsc( "Sila sygnalu min [DBm/ø]",
                              Pomiary[nA].SSminDlaPomOrb,
                              Pomiary[nB].SSminDlaPomOrb,
                              Orbita360,
                              Wart_X1)
        THEN
          RETURN FALSE;
        END;
        IF NOT WrPrnLn( 0, NagTab8 ) THEN
          RETURN FALSE;
        END;
      END (* WITH *);
      IF NOT WrPrn( 0, ff ) THEN (* nowa strona *)
        RETURN FALSE;
      END;
      FOR nidx := MIN( NadajnikT ) TO MAX( NadajnikT ) DO
        IF Dane.Pomiary[nidx].KiedyOrbita.y # 0 THEN
          IF NOT WykresPokryciaWPoziomie(nidx, Naglowek) THEN
            RETURN FALSE;
          END (* IF *);
        END (* IF *);
      END (* FOR *);
      RETURN TRUE;
    END DrukujOrbite;

  PROCEDURE DrukujPromien
            ( VAR Naglowek : ARRAY OF CHAR ) : BOOLEAN;
    VAR
      DP_nidx    : NadajnikT;
      i          : CARDINAL;
      bladOdlA   : KolStrWaska;
      bladOdlB   : KolStrWaska;

  PROCEDURE WykresPokryciaWPionie
            ( VAR Naglowek : ARRAY OF CHAR ) : BOOLEAN;
    CONST
      WYS_LINE    = {0};
      ZAS_LINE    = {0,4,8,12};
      START_LABEL = 40;

    VAR
      TablicaLecianychWysokosci : ARRAY OdcinekNr OF CARDINAL;
      IleRoznychWysokosci       : INTEGER;
      MaxZasieg                 : CARDINAL;
      i, j, w                   : INTEGER;
      px, py, x, y, LastY       : INTEGER;
      WPWP_nidx                 : NadajnikT;
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

    BEGIN (* WykresPokryciaWPionie *)
      IleRoznychWysokosci := 0;
      MaxZasieg := 0;
      FOR i := 0 TO  HIGH(Dane.Pomiary[nA].PokrycieWPionie) DO
        FOR WPWP_nidx := nA TO nB DO
          WITH Dane.Pomiary[WPWP_nidx].PokrycieWPionie[i] DO
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
        END (*  FOR n := nA *);
      END (* FOR i *);
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
      FOR WPWP_nidx := nA TO nB DO
        IF Dane.Pomiary[WPWP_nidx].KiedyPromien.y # 0  THEN
        
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
        DrawEpson.SetDir( DrawEpson.t_90 );
        DrawEpson.Mnoznik( SKALA_X_90, SKALA_Y_90 );
        LastY := START_LABEL;
        FOR i := 0 TO HIGH( Dane.Pomiary[nA].PokrycieWPionie ) DO
          WITH Dane.Pomiary[WPWP_nidx].PokrycieWPionie[i] DO
            IF (Wysokosc # NilValC) THEN
              w := IndexWys( Wysokosc );
              y := PolozenieNaWspolrzednejY(w);
              sprintf( s, "%xNM", Zasieg );
              x := VAL( CARDINAL, VAL( LONGINT, Zasieg ) *
                                  VAL( LONGINT, DrawEpson.MaxX() -1) DIV
                                  VAL( LONGINT, MaxZasieg ));
              DrawEpson.Line( x, 0, x, DrawEpson.MaxY(), ZAS_LINE );
              IF x < INTEGER(DrawEpson.MaxX())-(SKALA_X_90*8+4) THEN
                DrawEpson.DrawText( s, x+1+SKALA_X_90*8, LastY );
              ELSE
                DrawEpson.DrawText( s, x-1-SKALA_X_90*8, LastY );
              END;
              LastY := LastY + (SKALA_Y_90*8*INTEGER(Length(s)+4));
              IF LastY > INTEGER(DrawEpson.MaxY() *3 DIV 4) THEN
                LastY := START_LABEL;
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
        IF WPWP_nidx = nA THEN
          DrawEpson.DrawText( 
            "Wykres pokrycia pionowego dla odb. glownego",   200, 10 );
        ELSE
          DrawEpson.DrawText( 
            "Wykres pokrycia pionowego dla odb. zapasowego", 200, 10 );
        END;
        IF NOT DrawEpson.Out(DrawEpson.WrProc) THEN
          DrawEpson.Close;
          RETURN FALSE;
        END;
        DrawEpson.Close;
        END (* IF *);
      END (* FOR WPWP_nidx *);
      RETURN TRUE;
    END WykresPokryciaWPionie;

    BEGIN (* DrukujPromien *)
      (* Wyniki pomiarow *)
      IF NOT WrPrnLn( 0, PASEK ) THEN
        RETURN FALSE;
      END;
      IF NOT WrPrnLn( 0, Naglowek ) THEN
        RETURN FALSE;
      END;
      IF NOT DatyNagl() THEN
        RETURN FALSE;
      END;
      FOR DP_nidx  := MIN( NadajnikT ) TO MAX( NadajnikT ) DO
        WITH Dane.Pomiary[DP_nidx] DO
          IF NOT WrFmtNad( DP_nidx, KiedyPromien.y # 0, DATA_STR, KiedyPromien ) 
          THEN
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
      FOR i := 0 TO max(Dane.Pomiary[nA].PWP_LiczbaOdcikow,
                        Dane.Pomiary[nB].PWP_LiczbaOdcikow ) -1
      DO
        IF NOT WrOdcinek( i+1,
                          Dane.Pomiary[nA].PokrycieWPionie[i],
                          Dane.Pomiary[nB].PokrycieWPionie[i] )
        THEN
          RETURN FALSE;
        END;
      END;
      (*
      WITH Dane  DO
        IF NOT WrPrnLn( 0, NagTab1 ) THEN
          RETURN FALSE;
        END;
        IF NOT WrPrnLn( 0, NagTab2nad ) THEN
          RETURN FALSE;
        END;
        IF NOT WrPrnLn( 0, NagTab3nad ) THEN
          RETURN FALSE;
        END;
        IF NOT WrPrnLn( 0, NagTab4 ) THEN
          RETURN FALSE;
        END;
        Int500Str(Pomiary[nA].BledyOdleglosciPro, bladOdlA, 7);
        Int500Str(Pomiary[nB].BledyOdleglosciPro, bladOdlB, 7);
        IF NOT Wr_NagTab10("Blad odleglosci ˜redni [NM]", bladOdlA, bladOdlB) 
        THEN
          RETURN FALSE;
        END (* IF *);
        IF NOT WrPrnLn( 0, NagTab8 ) THEN
          RETURN FALSE;
        END;
      END (* WITH *);
      *)
      IF NOT WykresPokryciaWPionie( Naglowek ) THEN
        RETURN FALSE;
      END;
      RETURN TRUE;
    END DrukujPromien;

      BEGIN (* DaneDlaDME *)
        IF NOT TylkoDruk THEN
          WITH Dane.Pomiary[ nadajnik ]  DO
            BylPomiar := TRUE;
            IF PromienNieOrbita THEN
              KiedyPromien := anRes.data.d;
              ZasiegiNaOdcinkach( anRes.a_IleOd,
                                  anRes.odlBlaSren[ Dane.GlownyOdbiornik ],
                                  anRes.analiza,
                                  PokrycieWPionie,
                                  PWP_LiczbaOdcikow,
                                  BledyOdleglosciPro );
            ELSE
              KiedyOrbita := anRes.data.d;
              UstawPokrycieWPoziomie( nadajnik );
            END;
          END (* WITH *);
        END;
        IF (nadajnik = MAX( NadajnikT )) OR TylkoDruk THEN
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

  PROCEDURE InitDane(  );

    VAR
      n : NadajnikT;

  PROCEDURE InitLocalData( VAR p : PomiarNadajnika );
    VAR
      i : CARDINAL;
    BEGIN
      WITH p DO
        KiedyPromien.y    := 0;
        KiedyOrbita.y     := 0;
        PWP_LiczbaOdcikow := 0;
        FOR i := 0 TO HIGH( PokrycieWPionie ) DO
          WITH PokrycieWPionie[i] DO
            Wysokosc := NilValC;
            Zasieg   := NilValC;
          END;
        END;
        PokrycieWPoziomie.Wysokosc := NilValC;
        PokrycieWPoziomie.Zasieg   := NilValC;
        BledyOdleglosciOrb         := SigNilVal;
        BledyOdleglosciPro         := SigNilVal;
        InitSignalDsc(SSminDlaPomOrb, SigNilVal);
        BylPomiar := FALSE;
      END (* WITH *);
    END InitLocalData;

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
END D_Report.
