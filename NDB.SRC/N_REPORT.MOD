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
|    Rel.3.00.MPostol
|     - Program wywalal sie gdy wysokosc < 0 Uzdrowilem przez podstawienie 0
|       w takiej sytuacji
|     - 
|    Rel.3.02. MPOstol
|     - wstawilem wydruk odcinkow bledu 5 i 10deg.
|     - zly format dla polozenia geograficznego w raportach koncowych
|     - do wykresu zasiegu poziomego w raporcie koncowym wstawilem filtr 
|       dla AGC
|   Rel. 3.14. MPostol
|     - przy wypisywaniu sprawdzane jest czy pomiar dla nadajnika byl
|       robiony i jesli nie na wydruku jest to zaznaczane.
|
|  Copyright (C), CAS LODZ POLAND.
|  TEL: 42' 686 25 47
|  mailto: techsupp@cas.com.pl
|  http: www.cas.com.pl
|
**********************************************************************)
(*.F+ *)
IMPLEMENTATION MODULE N_Report;

FROM CommonTypes IMPORT
  Str40, Str99, PolozenieGeo, NadajnikT,
  GlownyOdbiornikT, NilValC, SignalDsc, NilValI, DisNilVal,
  OdnDlaPomBleduT, InitSignalDsc, SigNilVal, RodzajLotu, Reprezentacja;

FROM MathLib0 IMPORT
  ln;
FROM N_DataBase IMPORT
  NadajnikNDB;
FROM PI_ArchDate IMPORT
  okTab, LoadData;
FROM Czas IMPORT
  Date, GetTimeAndDate, TimeAndDate;
FROM N_results IMPORT
  anRes, OdcinekNr, A_TablicaOdci;
FROM FlagAnal IMPORT
  FlagsTable;
FROM FIO IMPORT
  File, Open, Close, CD, Read;
FROM Files IMPORT
  GoHomeDir;
FROM N_Files IMPORT
  Signals;
FROM N_CommonTypes IMPORT
  Procedura, ProceduraT;
FROM StdIO IMPORT
  sprintf, sprintf2;
FROM Strings IMPORT
  Assign, ConstAssign, Length;
FROM SYSTEM IMPORT
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
  SKALA_Y_90, SKALA_X_90, WrFlagsTableWHeading;
IMPORT
  DrawEpson, (* bo kloci sie Close *)
  CommonData, HiLevGraf,
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

  FROM Ini IMPORT
    GetPrivateProfileString;

  FROM FIltr1St IMPORT
    Continer2FiltersT, InitCont2Filters, Filtr2Filters;
  
  FROM WorseBecause IMPORT
    WorseBLess;

  FROM PrintUtl IMPORT
    PiszSignalDsc, StartN, NagTab1, NagTab2nad, NagTab3nad, NagTab4, NagTab8,
    KolStr;

  FROM SpecConv IMPORT
    ToStringProcT, Card500Str, Int100Str, Int2Card, ZaokraglicDo500;
  
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
  DATA_STR    = "%02d.%02d.%02d";

TYPE
  OpisyZasiegow = RECORD
    Wysokosc  : CARDINAL;
    Zasieg    : CARDINAL;
    blad      : FlagsTable;
  END;
  T_TabOpisyZasiegow = ARRAY OdcinekNr OF OpisyZasiegow;
  PomiarNadajnika = 
    RECORD
      KiedyPomiar           : Date;
      RK_a_IleOd            : OdcinekNr;
      Pokrycie              : T_TabOpisyZasiegow;
      RK_SSmin              : SignalDsc;
      SlyszalnoscPrawidlowa : BOOLEAN;
      BylPomiar             : BOOLEAN;
    END;
  T_OpissPomiarow = ARRAY NadajnikT OF PomiarNadajnika;
  RaportKoncowyDesc = RECORD
    NazwaInspekcji           : Str40;
    Lokalizacja              : Str40;
    Polozenie                : PolozenieGeo;
    Czestotliwosc            : REAL;
    Deklinacja               : REAL;
    Odpowiedzialny           : Str40;
    SamolotPomiarowy         : ARRAY[ 0..6 ] OF CHAR;
    GlownyOdbiornik          : GlownyOdbiornikT;
    DataOstatniejKalibracji  : Str40;
    NazwaAparaturyPomiarowej : Str40;
    Pomiary                  : T_OpissPomiarow;
    NDB_Lotniskowe           : BOOLEAN;
    UrzadzenieOK             : BOOLEAN;
  END;
  Buttony = ARRAY NadajnikT OF Button;

VAR
  StartTol        : CARDINAL;
  AktualnyPromien : CARDINAL;
  SR              : Buttony;               (* sygnal rozpoznawczy *)
  Rodzaj          : Button;
  Dane            : RaportKoncowyDesc;

  PROCEDURE InitPomiarNadajnika
            ( VAR p    : PomiarNadajnika;
                  proc : RodzajLotu);
      
    PROCEDURE Init_OpisyZasiegow
              ( VAR RK_a_IleOd : OdcinekNr;
                VAR Pokrycie   : T_TabOpisyZasiegow);
    VAR
      idx: OdcinekNr;
    BEGIN
      RK_a_IleOd := 0;
      FOR idx := MIN(OdcinekNr) TO MAX(OdcinekNr) DO
        WITH Pokrycie[idx] DO
          Wysokosc     := NilValC;
          Zasieg       := NilValC;
          blad.w_IleOd := 0;
        END;
      END (* FOR i *);
    END Init_OpisyZasiegow;
  
  BEGIN (* InitPomiarNadajnika *)
    WITH p DO
      KiedyPomiar.y := 0;
      Init_OpisyZasiegow(RK_a_IleOd, Pokrycie);
      CASE proc  OF
        Promien :
          InitSignalDsc(RK_SSmin, DisNilVal);
      | Orbita :
          InitSignalDsc(RK_SSmin, SigNilVal );
      END (* CASE *);
    END (* WITH *);
  END InitPomiarNadajnika;

  PROCEDURE Rodzaj_P( );
  BEGIN
    WITH Dane DO
      NDB_Lotniskowe := NOT NDB_Lotniskowe;
      IF NDB_Lotniskowe THEN
        ChangeButtonText( Rodzaj, "NDB LOTNISKOWE" );
      ELSE
        ChangeButtonText( Rodzaj, "NDB TRASOWE" );
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
                                 sv            : CARDINAL);
    BEGIN
      IF sv = NilValC THEN
        RETURN;
      ELSE
        IF (jg = NilValC) THEN
          jg := sv;
        ELSE
          jg := max( jg, sv );
        END;
      END;
    END PodstawCardinal;

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

  PROCEDURE WrPrnFmt
            (    At   : INTEGER;
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

  PROCEDURE WrPrnFmtLn( At   : INTEGER;
                        Fmt1,
                        Fmt2 : ARRAY OF CHAR;
                        Dane : ARRAY OF BYTE ) : BOOLEAN;
  BEGIN
    RETURN WrPrnFmt( At, Fmt1, Fmt2, Dane ) & WrLn();
  END WrPrnFmtLn;

  PROCEDURE  PiszDaty
             (     Pomiary: T_OpissPomiarow): BOOLEAN;
  VAR
    nidx: NadajnikT;
    
    PROCEDURE Daty(  ): BOOLEAN;
    BEGIN
      IF  NOT WrPrn  ( StartN[nA], "| Nad. gˆ¢wny" )   OR
          NOT WrPrnLn( StartN[nB], "| Nad. zapasowy" )
      THEN
        RETURN FALSE;
      ELSE
        RETURN WrPrn( 0, "Data wykonania pomiaru:" );
      END;
    END Daty;

  BEGIN (* PiszDaty *)
    IF NOT Daty() THEN
      RETURN FALSE;
    END;
    FOR nidx := MIN( NadajnikT ) TO MAX( NadajnikT ) DO
      WITH Pomiary[nidx] DO
        IF NOT WrFmtNad( nidx, KiedyPomiar.y # 0, DATA_STR, KiedyPomiar )
        THEN
          RETURN FALSE;
        END;
      END;
    END (* FOR n *);
    RETURN TRUE
  END PiszDaty;

  PROCEDURE PiszPokrycie
            (     Pomiary        : T_OpissPomiarow;
                  nag            : ARRAY OF CHAR;
                  lot            : RodzajLotu;
                  NDB_Lotniskowe : BOOLEAN ): BOOLEAN;

  PROCEDURE WrOdcinek( Nr   : CARDINAL; 
                       a, b : OpisyZasiegow;
                       lot  : RodzajLotu) : BOOLEAN;

  VAR
    wys       : Str99;
    CONV_STR1 : KolStr;
    CONV_STR3 : KolStr;

  CONST
    CONV_STR2 = "| %d/*****";

  BEGIN
    ZaokraglicDo500( a.Wysokosc );
    ZaokraglicDo500( b.Wysokosc );
    CASE lot  OF
      Promien:
      ConstAssign("| %d/%x", CONV_STR1);
      ConstAssign("%2d Wysoko˜† [ft]/[NM]", CONV_STR3);
    | Orbita360:
      ConstAssign("| %d", CONV_STR1);
      ConstAssign("%2d Wysoko˜† [ft]", CONV_STR3);
    END (* CASE *);
    sprintf( wys, CONV_STR3, Nr );
    IF NOT WrPrn( 0, wys ) THEN
      RETURN FALSE;
    END;
    IF NOT WrPrnFmt( StartN[nA], CONV_STR1, CONV_STR2, a ) THEN
      RETURN FALSE;
    END;
    IF NOT WrPrnFmt( StartN[nB], CONV_STR1, CONV_STR2, b ) THEN
      RETURN FALSE;
    END;
    IF NOT WrLn() THEN
      RETURN FALSE;
    END;
    RETURN TRUE;
  END WrOdcinek;

  VAR
    idx     : OdcinekNr;
    converP : ToStringProcT;
    
  BEGIN (* PiszPokrycie *)
    IF NOT WrLn() THEN
      RETURN FALSE;
    END;
    CASE lot  OF
      Promien:
      converP := ToStringProcT(Card500Str);
    | Orbita360:
      converP := Int100Str;
    END (* CASE *);
    IF NOT WrPrnLn( 0, nag) THEN
      RETURN FALSE;
    END;
    FOR idx := 0 TO max(Pomiary[nA].RK_a_IleOd, Pomiary[nB].RK_a_IleOd) DO
      IF NOT WrOdcinek( idx + 1, 
                        Pomiary[nA].Pokrycie[idx],
                        Pomiary[nB].Pokrycie[idx], 
                        lot )
      THEN
        RETURN FALSE;
      END;
    END;
    IF lot = Promien THEN
      IF NDB_Lotniskowe THEN
        IF NOT WrPrnLn( 0, "Zestawienie odcink¢w na kt¢rych bˆ¥d > 5ø" )
        THEN
          RETURN FALSE;
        END (* IF *);
      ELSE
        IF NOT WrPrnLn( 0, "Zestawienie odcink¢w na kt¢rych bˆ¥d > 10ø" )
        THEN
          RETURN FALSE;
        END (* IF *);
      END;
      FOR idx := 0 TO Pomiary[nA].RK_a_IleOd DO
        IF NOT WrFlagsTableWHeading('NAD G:', Pomiary[nA].Pokrycie[idx].blad, 
                                    converP)
        THEN
          RETURN FALSE;
        END (* IF *);
      END (* FOR idx := 0 *);
      FOR idx := 0 TO Pomiary[nB].RK_a_IleOd DO
        IF NOT WrFlagsTableWHeading('NAD Z:', Pomiary[nB].Pokrycie[idx].blad, 
                                    converP)
        THEN
          RETURN FALSE;
        END (* IF *);
      END;
    END (* IF IF lot = Promien *);
    RETURN TRUE;
  END PiszPokrycie;

  PROCEDURE DrukujPromien
            ( VAR Naglowek : ARRAY OF CHAR ) : BOOLEAN;

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

    BEGIN (* WykresPokryciaWPionie *)
      IleRoznychWysokosci := 0;
      MaxZasieg := 0;
      FOR i := 0 TO Dane.Pomiary[n].RK_a_IleOd DO
        FOR n := nA TO nB DO
          WITH Dane.Pomiary[n].Pokrycie[i] DO
            IF Wysokosc # NilValC THEN
              IF Zasieg > MaxZasieg THEN
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
        IF Dane.Pomiary[n].KiedyPomiar.y # 0  THEN
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
          FOR i := 0 TO Dane.Pomiary[n].RK_a_IleOd DO
            WITH Dane.Pomiary[n].Pokrycie[i] DO
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
        END (* IF *);
      END;
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
      WITH Dane  DO
        IF NOT PiszDaty(Pomiary) THEN
          RETURN FALSE;
        END;
        IF NOT PiszPokrycie( Pomiary, "Pokrycie w pionie", Promien, 
                             NDB_Lotniskowe )
        THEN
          RETURN FALSE;
        END (* IF *);
        IF NOT WrPrnLn( 0, NagTab1 ) THEN
          RETURN FALSE;
        END;
        IF NOT WrPrnLn( 0, NagTab2nad) THEN
          RETURN FALSE;
        END;
        IF NOT WrPrnLn( 0,  NagTab3nad) THEN
          RETURN FALSE;
        END;
        IF NOT WrPrnLn( 0,  NagTab4) THEN
          RETURN FALSE;
        END;
        IF NOT PiszSignalDsc("Siˆa sygnaˆu min [uV/NM]",
                              Pomiary[nA].RK_SSmin,
                              Pomiary[nB].RK_SSmin,
                              Promien,
                              Wart_X1) 
        THEN
          RETURN FALSE;
        END (* IF *);
        IF NOT WrPrnLn( 0,  NagTab8) THEN
          RETURN FALSE;
        END;
      END (* WITH Dane *);
      (*
      IF NOT WykresPokryciaWPionie( Naglowek ) THEN
        RETURN FALSE;
      END;
      *)
      RETURN TRUE;
    END DrukujPromien;

  PROCEDURE DrukujOrbite
            ( VAR Naglowek : ARRAY OF CHAR ) : BOOLEAN;

  PROCEDURE WykresPokryciaWPoziomie( VAR Naglowek : ARRAY OF CHAR ) : BOOLEAN;
    CONST
      M_PI     = 3.1415926;
      Zero_Agc = 1.0;
      MIN_Agc  = 10;
      AV_Agc   = 100;
      MAX_Agc  = 1000;
      style    = {0..15};
      TauSmall = 0.0;
      TauLarge = 3.0;
      
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
      agcR      : REAL;
      agc,
      angle     : INTEGER;
      KatS      : Str40;
      FiltrSS   : Continer2FiltersT;
      
        PROCEDURE Log10( x : REAL ) : REAL;
          BEGIN
            RETURN ln( x ) / 2.302585093;
          END Log10;


        PROCEDURE CoordAt(     agc   : REAL;
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
            promien := (Log10( agc ) - Log10( Zero_Agc )) /
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
            CoordAt( real(rad), 0.0, px, py );
            FOR i := 1 TO 360 DO
              CoordAt( real(rad), FLOAT( i ), x, y );
              DrawEpson.Line( px, py, x, y, {0..15} );
(*              IF i > 320 THEN Terminate( Warning ); END;*)
              px := x;
              py := y;
            END;
          END Circle;

    BEGIN (* WykresPokryciaWPoziomie *)
      IF NOT WrPrn( 0, ff ) THEN (* nowa strona *)
        RETURN FALSE;
      END;
      CenterX := DrawEpson.MaxX() DIV 2;
      CenterY := DrawEpson.MaxY() DIV 2;
      Aspect  := ( (FLOAT( DrawEpson.MaxX()) /  8.0 (* cali *))) /
                 ( (FLOAT( DrawEpson.MaxY()) / 12.0 (* cali *)));
      Aspect := 1.253/Aspect;
      FOR n := nA TO nB DO
        IF Dane.Pomiary[n].KiedyPomiar.y # 0  THEN
          DrawEpson.Open;
          InitCont2Filters(FiltrSS, TauSmall, TauLarge);
          Circle( MAX_Agc );
          Circle( AV_Agc );
          Circle( MIN_Agc );
          DrawEpson.Mnoznik( 2, 1 );
          DrawEpson.DrawText( Naglowek, 0, 0 );
          FOR i := 0 TO 359 BY 30 DO
            CoordAt( real(MAX_Agc), FLOAT(i), x, y );
            DrawEpson.Line(CenterX, CenterY, x, y, {0..15} );
            CoordAt( 50.0, FLOAT(i+3), x, y );
            sprintf( KatS, "%dø", i );
            DrawEpson.DrawText( KatS, x, y );
          END;
          CoordAt( real(MIN_Agc), 90.0, x, y );
          DrawEpson.DrawText( "10", x, y+1 );
          CoordAt( real(MAX_Agc), 90.0, x, y );
          DrawEpson.DrawText( "1000", x, y+1 );
          CoordAt( real(AV_Agc), 90.0, x, y );
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
                  agcR := Filtr2Filters(FiltrSS, real(agc));
                  CoordAt( agcR,
                           real( angle ) / 100.0,
                           x, y );
              ELSE
                InitCont2Filters(FiltrSS, TauSmall, TauLarge);
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
            DrawEpson.DrawText('Wykres pokrycia poziomego dla nadajnika gˆ¢wnego',
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
        END (* Dane.Pomiary[n].KiedyPomiar.y # 0 *);
      END (* FOR n := nA TO nB *);
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
      WITH Dane DO
        IF NOT PiszDaty(Pomiary) THEN
          RETURN FALSE;
        END;
        IF NOT PiszPokrycie(Pomiary, "Pokrycie w poziomie", Orbita360, 
                            NDB_Lotniskowe) 
        THEN
          RETURN FALSE;
        END (* IF *);
        IF NOT WrPrnLn( 0, NagTab1 ) THEN
          RETURN FALSE;
        END;
        IF NOT WrPrnLn( 0, NagTab2nad) THEN
          RETURN FALSE;
        END;
        IF NOT WrPrnLn( 0,  NagTab3nad) THEN
          RETURN FALSE;
        END;
        IF NOT WrPrnLn( 0,  NagTab4) THEN
          RETURN FALSE;
        END;
        IF NOT PiszSignalDsc("Siˆa sygnaˆu min [uV/ø]",
                              Pomiary[nA].RK_SSmin,
                              Pomiary[nB].RK_SSmin,
                              Orbita,
                              Wart_X1) 
        THEN
          RETURN FALSE;
        END (* IF *);
      END (* WITH Dane *);
      IF NOT WrPrnLn( 0,  NagTab8) THEN
        RETURN FALSE;
      END;
      IF NOT WykresPokryciaWPoziomie( Naglowek ) THEN
        RETURN FALSE;
      END;
      RETURN TRUE;
    END DrukujOrbite;

  PROCEDURE RaportKoncowy(  );

    PROCEDURE InitDane(  );

    VAR
      n : NadajnikT;

    BEGIN (* InitDane *)
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
          InitPomiarNadajnika( Pomiary[n], Promien);
          Pomiary[n].BylPomiar := FALSE;
        END;
      END;
    END InitDane;
    
    PROCEDURE PoczatekWypisywania(  ) : BOOLEAN;
    VAR
      td   : TimeAndDate;
      c    : CHAR;
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
       "RAPORT Z INSPEKCJI NDB WYKONANY W DNIU %02d.%02d.%4d O GODZ %02d:%02d",
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
            "Poˆo¾enie geograficzne: %dø%02d.%04d'E, %dø%02d.%04d'N",
                            "  ",
                            Polozenie )
        THEN
          RETURN FALSE;
        END;
        (*
        IF NOT WrPrnFmtLn( 0,
                           "Deklinacja: %3.1lfø",
                           "  ", Deklinacja ) THEN
          RETURN FALSE;
        END;
        
        *)
        IF NOT WrPrnFmtLn( 0, "Cz©stotliwo˜†: %5.2lfkHz",
                              "  ", Czestotliwosc ) THEN
          RETURN FALSE;
        END;
        IF NOT WrPrn( 0, "Samolot pomiarowy: " ) OR
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
        IF NDB_Lotniskowe THEN
          IF NOT WrPrn( 0, 
                     "Urz¥dzenie NDB zostaˆo zadeklarowane jako lotniskowe" )
          THEN
            RETURN FALSE;
          END;
        ELSE
          IF NOT WrPrn( 0, 
                        "Urz¥dzenie NDB zostaˆo zadeklarowane jako trasowe" )
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
          IF NOT BylPomiar THEN 
            IF NOT WrPrn( StartN[n], "| nie spr." ) THEN
              RETURN FALSE;
            END;
          ELSIF SlyszalnoscPrawidlowa THEN
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
      IF NOT WrLn() OR NOT WrPrnLn(0,"Uwagi") OR 
         NOT WrLn() OR NOT WrLn() OR 
         NOT WrLn() OR NOT WrLn() OR 
         NOT WrLn() OR NOT WrLn() OR 
         NOT WrLn() OR NOT WrLn() OR 
         NOT WrLn() OR NOT WrLn() OR 
         NOT WrLn() THEN
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

    PROCEDURE ZasiegiNaOdcinkach
            (     io              : CARDINAL;
              VAR oo              : A_TablicaOdci;
              VAR oz              : ARRAY OF OpisyZasiegow;
              VAR RK_SSmin        : SignalDsc;
                  GOdb            : GlownyOdbiornikT;
                  NDB_Lotniskowe  : BOOLEAN
            );
    VAR
      i, j : CARDINAL;
    BEGIN (* ZasiegiNaOdcinkach *)
      IF io = 0 THEN
        RETURN;
      END;
      j := 0;
      FOR i := 0 TO io-1 DO
        (* wyznaczenie wysokosci *)
        WHILE (Events[pomiar].events[j].EventID # StartPomiaru) DO
          INC( j );
        END;
        oz[i].Wysokosc := Int2Card(Events[pomiar].events[j].Wysokosc);
        INC(j);
        ZaokraglicDo500( oz[i].Wysokosc );
        (* zasieg *)
        WITH oo[i]  DO
          PodstawCardinal( oz[i].Zasieg, CARDINAL(oo[i].pocz) );
          PodstawCardinal( oz[i].Zasieg, CARDINAL(oo[i].kon)  );
          WITH SSmin[GOdb] DO
            WorseBLess(RK_SSmin, val, pos);
          END (* WITH *);
          IF NDB_Lotniskowe  THEN
            oz[i].blad := blad5[ GOdb];
          ELSE
            oz[i].blad := blad10[GOdb];
          END (* IF *);
        END (* WITH *);
      END;
    END ZasiegiNaOdcinkach;

    VAR
      f      : File;
      i      : INTEGER;
      n      : NadajnikT;
      dataOk : okTab;
      Ktorykolwiek_Nadajnik : BOOLEAN;
      Naglowek : Str99;

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
        Czestotliwosc := FLOAT(NadajnikNDB.Czestotliwosc);
        Deklinacja := NadajnikNDB.Deklinacja;
        Polozenie  := NadajnikNDB.Polozenie;
        GetPrivateProfileString( "DataKalibracji", 
                                 "Data", 
                                 "15-09-2000", 
                                 DataOstatniejKalibracji,
                                 CommonData.NazwaPlikuOpisu );
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
          InitPomiarNadajnika(Pomiary[n], Orbita);
          IF dataOk[pomiar] THEN
            Ktorykolwiek_Nadajnik := TRUE;
            WITH Pomiary[n]  DO
              BylPomiar := TRUE;
              KiedyPomiar := anRes.data.d;
              ZasiegiNaOdcinkach( anRes.a_IleOd,
                                  anRes.analiza,
                                  Pokrycie,
                                  RK_SSmin,
                                  GlownyOdbiornik,
                                  NDB_Lotniskowe
                                );
            END (* WITH Pomiary[n] *);
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
            CommonData.Promien   := i;
            N_Oblot.SciezkaDoKataloguOpisu();
            LoadData( dataOk );
            GoHomeDir;
            InitPomiarNadajnika(Pomiary[n], Promien);
            IF dataOk[pomiar] THEN
              Ktorykolwiek_Nadajnik := TRUE;
              WITH Dane.Pomiary[n] DO
                BylPomiar := TRUE;
                KiedyPomiar := anRes.data.d;
                ZasiegiNaOdcinkach( anRes.a_IleOd,
                                    anRes.analiza,
                                    Pokrycie,
                                    RK_SSmin,
                                    GlownyOdbiornik,
                                    NDB_Lotniskowe
                                  );
              END (* WITH *);
            END (* IF dataOk[pomiar] *);
          END (* FOR i := 0 *);
          IF Ktorykolwiek_Nadajnik THEN
            sprintf( Naglowek, "Raport z inspekcji NDB na promieniu %dø", i );
            IF NOT DrukujPromien( Naglowek ) THEN
              RETURN;
            END;
          END;
        END;
        IF NOT KoniecWypisywania() THEN
          RETURN;
        END;
      END (* Dane *);
    END RaportKoncowy;

BEGIN
  AktualnyPromien := 0;
  StartTol        := 64;
END N_Report.
