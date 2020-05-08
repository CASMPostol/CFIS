(*.F- *)
(**********************************************************************
|  Title   : Polozenie urzadzenia
|  Author  :
|  System  : LOGITECH MODULA-2/86
|  History :
|  Copyright (C), CAS LODZ POLAND.
|  TEL: 42' 86 58 12, 42' 87 80 44 FAX/TEL: 42' 84 48 40
|
**********************************************************************)
(*.F+ *)

IMPLEMENTATION MODULE POLoze;

  FROM TypDanych IMPORT
    MainStates, TypUrzadzenia, PolozenieBiegunWysokosc, ParametryIdentyf,
    ParametryPlikIni, ParametryUrzadzenia;

  FROM GrafTypes IMPORT
    RECT, AssignRect, MoveRect, WHITE, BLUE, MAGENTA, BLACK, LT_RED;

  FROM Buttons IMPORT
    Button, EnableButton;

  FROM Ini IMPORT
    GetPrivateProfileString, WritePrivateProfileString;

  FROM NumberConversion IMPORT
    StringToCard, StringToInt, CardToString;

  FROM GList IMPORT
    HLIST, SetNotificationProc, Sortowana, GetSelection, Skasuj, SetSelection,
    DodajDoListy, Idx2Str, SkasujWszystko, HCONTENT, KillContents, GetContents,
    SetContents;

  FROM Dialog IMPORT
    HDLG, EndDialog, TworzDialog, WstawListe, WstawButton, EnableDlg, Go,
    UsunDialog, Redraw, AltF4, WstawInpLine, GetDialogDIBHandle;

  FROM CommonTypes IMPORT
    TimeAndDate, PolozenieGeo, PolozenieBiegunowe, Str40, Str99, NilValC;

  FROM CommonData IMPORT
    SciezkaOpisuPomiaru, NazwaOblotu, NazwaUrzadz1;

  FROM Strings IMPORT
    Length, Insert, CompareStr, Concat;

  FROM HiLevGraf IMPORT
    WrStrXY, Wr2fStrXY;

  FROM StdIO IMPORT
    sprintf5, sprintf4, sprintf3, sprintf2, sprintf;

  FROM HiLevGraf IMPORT
    WrStr, SetPaletteEntry;

  IMPORT
    ShortCuts, MsgBox, PI_PA, InpLine;

  FROM GrafUtil IMPORT
    Info, InfoBeep;

  FROM Sounds IMPORT
    Sound, NoSound;

  FROM Timer IMPORT
    Wait, TInOneSecond;

  FROM MANAGER IMPORT
    STARTPROCESS;

  FROM RealConversions IMPORT
    StringToReal;

  FROM InpLine IMPORT
    HLINE, GetText, DoNothing;

  FROM SYSTEM IMPORT
    ADDRESS, ADR;

  FROM INIcja IMPORT
    Kat2Geo, KoniecGPS, GPSReceive, Inicjacja;

  TYPE
    str30 =
      ARRAY [ 0 .. 30 ] OF CHAR;

  TYPE
    StanyZnacznik =
      ( Znacznik,
        Koniec );

  TYPE
    State =
      ( LOCMenu,
        GSMenu,
        VORMenu,
        ADFMenu,
        VHFMenu );

  VAR
    GtypURZ         : TypUrzadzenia;
    GmainState      : MainStates;
    GParametryURZ   : ParametryUrzadzenia;
    ListaUrz_Obiekt : HLIST;
    RedrawScr       : BOOLEAN;
    hDlg            : HDLG;
    ParamIdenty     : ParametryIdentyf;
        (* currState :State;*)
    GPSOdleglosc,
    GPSWysokosc,
    GPSKat          : InpLine.HLINE;
    Stan            : StanyZnacznik;

  PROCEDURE Pokaz
            (    s   : ARRAY OF CHAR;
                 Snd : CARDINAL      );

  BEGIN
    InfoBeep( s, 2, Snd );
  END Pokaz;

  PROCEDURE RealKatValid
            (     l         : InpLine.HLINE;
              VAR s         : ARRAY OF CHAR;
                  KillFocus : BOOLEAN       ) : BOOLEAN;

  VAR
    r  : REAL;
    ok : BOOLEAN;
    i  : ARRAY [ 0 .. 99 ] OF CHAR;

  BEGIN
    IF KillFocus
    THEN
      StringToReal( s, r, ok );
      IF NOT ok
      THEN
        i := "Napis nie jest liczba rzeczywist¥";
      ELSIF KillFocus & ( ( r < 0.0 ) OR ( r > 359.0 ) )
      THEN
        i := "Wprowadzona liczba jest zbyt du¾a lub zbyt maˆa";
        ok := FALSE;
      END (* if *);
      IF NOT ok
      THEN
        Pokaz( i, 5000 );
      END (* if *);
      RETURN ok;
    ELSE
      RETURN TRUE;
    END (* if KillFocus *);
  END RealKatValid;

  PROCEDURE RealOdlegValid
            (     l         : InpLine.HLINE;
              VAR s         : ARRAY OF CHAR;
                  KillFocus : BOOLEAN       ) : BOOLEAN;

  VAR
    r  : REAL;
    ok : BOOLEAN;
    i  : ARRAY [ 0 .. 99 ] OF CHAR;

  BEGIN
    IF KillFocus
    THEN
      StringToReal( s, r, ok );
      IF NOT ok
      THEN
        i := "Napis nie jest liczba rzeczywist¥";
      ELSIF KillFocus & ( ( r < 0.0 ) OR ( r > 300.0 ) )
      THEN
        i := "Wprowadzona liczba jest zbyt du¾a lub zbyt maˆa";
        ok := FALSE;
      END (* if *);
      IF NOT ok
      THEN
        Pokaz( i, 5000 );
      END (* if *);
      RETURN ok;
    ELSE
      RETURN TRUE;
    END (* if KillFocus *);
  END RealOdlegValid;

  PROCEDURE RealWysokValid
            (     l         : InpLine.HLINE;
              VAR s         : ARRAY OF CHAR;
                  KillFocus : BOOLEAN       ) : BOOLEAN;

  VAR
    r  : REAL;
    ok : BOOLEAN;
    i  : ARRAY [ 0 .. 99 ] OF CHAR;

  BEGIN
    IF KillFocus
    THEN
      StringToReal( s, r, ok );
      IF NOT ok
      THEN
        i := "Napis nie jest liczba rzeczywist¥";
      ELSIF KillFocus & ( ( r < 0.0 ) OR ( r > 2000.0 ) )
      THEN
        i := "Wprowadzona liczba jest zbyt du¾a lub zbyt maˆa";
        ok := FALSE;
      END (* if *);
      IF NOT ok
      THEN
        Pokaz( i, 5000 );
      END (* if *);
      RETURN ok;
    ELSE
      RETURN TRUE;
    END (* if KillFocus *);
  END RealWysokValid;

  PROCEDURE ZmienUrzadz
            (    idx : INTEGER );

  BEGIN
    IF idx < 0
    THEN
      RETURN;
    END (* if idx *);
    (* wybrany typ urzadzenia *)
    CASE idx OF
      0 :
        GtypURZ := LOC;
      |
      1 :
        GtypURZ := GS;
      |
      2 :
        GtypURZ := VOR;
      |
      3 :
        GtypURZ := ADF;
      |
      4 :
        GtypURZ := VHF;
    END (* case idx *);
    ParametryPlikIni( GtypURZ, ParamIdenty );   (* ustawienie nazw plikow nazw
                                                   sekcji dla urzadzenia *)
    WstawObloty;   (* ustawienie obiektow dla typu urzadzenia *)
  END ZmienUrzadz;

  PROCEDURE ZmienOiekt
            (    idx : INTEGER );

  VAR
    s     : ARRAY [ 0 .. 119 ] OF CHAR;
    bufor : ARRAY [ 0 .. 15 ] OF CHAR;
    nr    : ARRAY [ 0 .. 5 ] OF CHAR;
    R     : RECT;
    okZO  : BOOLEAN;

  BEGIN
    IF idx < 0
    THEN
      RETURN;
    END (* if idx *);
    RedrawScr := FALSE;
    AssignRect( R, 0, 0, 790, 30 );
    Redraw( hDlg, R );
    RedrawScr := FALSE;
    AssignRect( R, 250, 50, 700, 100 );
    Redraw( hDlg, R );

    sprintf( nr, "%d", idx );   (* numer urzadzenia w bazie danych*)
    Concat( ParamIdenty.Urzadz, nr, bufor );   (* polaczenie nazwy urzadzenia i
                                                  jego numeru*)
    GetPrivateProfileString( ParamIdenty.Lista, bufor, "", ParamIdenty.Nazwa,
                             ParamIdenty.NazwaPlikuOpisu );   (* pobranie nazwy
                                                                 wlasnej danego
                                                              urzadzenia*)
    GetPrivateProfileString( ParamIdenty.Nazwa, ParamIdenty.Identyfikator, "",
                             GParametryURZ.Identyfikator,
                             ParamIdenty.NazwaPlikuOpisu );
    GParametryURZ.Nazwa := ParamIdenty.Nazwa;
    Wr2fStrXY( GParametryURZ.Nazwa, 330, 50, WHITE, BLUE );
    Wr2fStrXY( GParametryURZ.Identyfikator, 250, 50, WHITE, BLUE );
    GetPrivateProfileString( ParamIdenty.Nazwa, ParamIdenty.GPSOdleglosc, "0",
                             bufor, ParamIdenty.NazwaPlikuOpisu );
    StringToReal( bufor, GParametryURZ.PolozenieDGPS.Odleglosc, okZO );
    GetPrivateProfileString( ParamIdenty.Nazwa, ParamIdenty.GPSKat, "0", bufor,
                             ParamIdenty.NazwaPlikuOpisu );
    StringToReal( bufor, GParametryURZ.PolozenieDGPS.Kat, okZO );
    GetPrivateProfileString( ParamIdenty.Nazwa, ParamIdenty.GPSWysokosc, "0",
                             bufor, ParamIdenty.NazwaPlikuOpisu );
    StringToReal( bufor, GParametryURZ.PolozenieDGPS.Wysokosc, okZO );
    GetPrivateProfileString( ParamIdenty.Nazwa, ParamIdenty.Deklinacja, "0",
                             bufor, ParamIdenty.NazwaPlikuOpisu );
    StringToReal( bufor, GParametryURZ.Deklinacja, okZO );
    GetPrivateProfileString( ParamIdenty.Nazwa, ParamIdenty.SzerokoscStopnie,
                             "", bufor, ParamIdenty.NazwaPlikuOpisu );
    StringToInt( bufor, GParametryURZ.Polozenie.Szerokosc.Stopnie, okZO );
    GetPrivateProfileString( ParamIdenty.Nazwa, ParamIdenty.SzerokoscMinuty, ""
                             , bufor, ParamIdenty.NazwaPlikuOpisu );
    StringToCard( bufor, GParametryURZ.Polozenie.Szerokosc.Minuty, okZO );
    GetPrivateProfileString( ParamIdenty.Nazwa, ParamIdenty.SzerokoscSetne, "",
                             bufor, ParamIdenty.NazwaPlikuOpisu );
    StringToCard( bufor, GParametryURZ.Polozenie.Szerokosc.DziesTys, okZO );
    GetPrivateProfileString( ParamIdenty.Nazwa, ParamIdenty.DlugoscStopnie, "",
                             bufor, ParamIdenty.NazwaPlikuOpisu );
    StringToInt( bufor, GParametryURZ.Polozenie.Dlugosc.Stopnie, okZO );
    GetPrivateProfileString( ParamIdenty.Nazwa, ParamIdenty.DlugoscMinuty, "",
                             bufor, ParamIdenty.NazwaPlikuOpisu );
    StringToCard( bufor, GParametryURZ.Polozenie.Dlugosc.Minuty, okZO );
    GetPrivateProfileString( ParamIdenty.Nazwa, ParamIdenty.DlugoscSetne, "",
                             bufor, ParamIdenty.NazwaPlikuOpisu );
    StringToCard( bufor, GParametryURZ.Polozenie.Dlugosc.DziesTys, okZO );
    GetPrivateProfileString( ParamIdenty.Nazwa, ParamIdenty.Czestotliwosc, "",
                             bufor, ParamIdenty.NazwaPlikuOpisu );
    StringToCard( bufor, GParametryURZ.Czestotliwosc, okZO );
    (* wypisanie parametrow urzadzenia *)
    sprintf3( s, "Poˆo¾enie = %dø%02d.%04d'E,",
              GParametryURZ.Polozenie.Szerokosc.Stopnie,
              GParametryURZ.Polozenie.Szerokosc.Minuty,
              GParametryURZ.Polozenie.Szerokosc.DziesTys );
    WrStrXY( s, 11, 11, WHITE, WHITE );
    sprintf3( s, " %dø%02d.%04d'N", GParametryURZ.Polozenie.Dlugosc.Stopnie,
              GParametryURZ.Polozenie.Dlugosc.Minuty,
              GParametryURZ.Polozenie.Dlugosc.DziesTys );
    WrStrXY( s, 210, 11, WHITE, WHITE );
    (* sprintf2( s, "ë=%3.1lfø,f=%d", GParametryURZ.Deklinacja,
       GParametryURZ.Czestotliwosc ); WrStrXY( s, 270, 11, WHITE, WHITE );*)
    sprintf3( s, "GPS KAT=%3.2lfø,ODL=%3.2lfm, WYS=%3.2lfm",
              GParametryURZ.PolozenieDGPS.Kat,
              GParametryURZ.PolozenieDGPS.Odleglosc,
              GParametryURZ.PolozenieDGPS.Wysokosc );
    WrStrXY( s, 400, 11, WHITE, WHITE );
    sprintf( s, "%3.2lf", GParametryURZ.PolozenieDGPS.Kat );
    InpLine.SetText( GPSKat, s );
    sprintf( s, "%3.2lf", GParametryURZ.PolozenieDGPS.Odleglosc );
    InpLine.SetText( GPSOdleglosc, s );
    sprintf( s, "%3.2lf", GParametryURZ.PolozenieDGPS.Wysokosc );
    InpLine.SetText( GPSWysokosc, s );
  END ZmienOiekt;

  PROCEDURE WstawObloty();

  VAR
    u,
    sekcja : ARRAY [ 0 .. 99 ] OF CHAR;
    ok     : BOOLEAN;
    ile,
    i      : INTEGER;

  BEGIN
    SkasujWszystko( ListaUrz_Obiekt );
    GetPrivateProfileString( ParamIdenty.Lista, ParamIdenty.Ilosc, "0", u,
                             ParamIdenty.NazwaPlikuOpisu );
    StringToInt( u, ile, ok );
    IF NOT ok
    THEN
      ile := 0;
    END (* if *);
    ok := FALSE;
    FOR i := 0 TO ile - 1 DO
      sprintf( u, "%d", i );
      Concat( ParamIdenty.Urzadz, u, sekcja );
      GetPrivateProfileString( ParamIdenty.Lista, sekcja, "", u,
                               ParamIdenty.NazwaPlikuOpisu );
      DodajDoListy( ListaUrz_Obiekt, u );
    END (* for i *);
  END WstawObloty;

  PROCEDURE InitGS();

  VAR

  BEGIN
    (* EnableDlg( hDlg, FALSE );*)
    STARTPROCESS( InicjujGPS, 1000H, 0 );
  END InitGS;

  PROCEDURE InicjujGPS;

  VAR
    Ask                 : HDLG;
    Rsk                 : RECT;
    nieistot            : BOOLEAN;
    GpolozebGPS         : PolozenieBiegunWysokosc;
    polozenieGPSinicjac : PolozenieGeo;
    s                   : ARRAY [ 0 .. 80 ] OF CHAR;
    przyciskStop        : Button;

  BEGIN
    (* tworzenie ekranu inicjacji *)
    AssignRect( Rsk, 250, 170, 460, 500 );
    Ask := TworzDialog( Rsk, "gps_mo.bmp", TRUE );
    AssignRect( Rsk, 35, 300, 165, 320 );
    (* przycisk konca pracy GP S*)
    WstawButton( Ask, Rsk, "STOP", 0, ShortCuts.kbAltS, OblotStop, przyciskStop
    );
    (* pobranie danych o GPS z okien danych *)
    GpolozebGPS.Kat := RealVal( GPSKat );   (* MP *)
    GpolozebGPS.Odleglosc := RealVal( GPSOdleglosc );   (* MP *)
    GpolozebGPS.Wysokosc := RealVal( GPSWysokosc );
    (* przeliczenie polozenia Katowego GPS i urzadzenia Nawigacyjnego na po
       lozenie geograficzne GPS *)
    Kat2Geo( GpolozebGPS, GParametryURZ.Polozenie, polozenieGPSinicjac );
    sprintf3( s, "Szerokosc %dø%02d.%04d'N",
              polozenieGPSinicjac.Szerokosc.Stopnie,
              polozenieGPSinicjac.Szerokosc.Minuty,
              polozenieGPSinicjac.Szerokosc.DziesTys );
    WrStrXY( s, 270, 280, WHITE, WHITE );
    sprintf3( s, "Dlugosc   %dø%02d.%04d'E", polozenieGPSinicjac.Dlugosc.Stopnie,
              polozenieGPSinicjac.Dlugosc.Minuty,
              polozenieGPSinicjac.Dlugosc.DziesTys );
    WrStrXY( s, 270, 300, WHITE, WHITE );
    
    WrStrXY( 'NOS      = ', 270, 340, WHITE, WHITE );
    WrStrXY( 'ILOSZNAK = ', 270, 360, WHITE, WHITE );
    (*WrStrXY( 'POPDOBRE = ', 270, 380, WHITE, WHITE );
    WrStrXY( 'POPZLE   = ', 270, 400, WHITE, WHITE );*)
  
    (* inicjacja GPS *)
    Inicjacja( polozenieGPSinicjac, GpolozebGPS );
    (* uruchomienie procesu czytania z GPS *)
    STARTPROCESS( ZnacznikP, 0800H, 0 );
    IF Go( Ask )
    THEN
      UsunDialog( Ask );   (* koniec pracy GPS *)
      RETURN
    END (* if Go *);
  END InicjujGPS;

  PROCEDURE ZnacznikP();

  VAR
    waitTime            : CARDINAL;
    pass                : BOOLEAN;
    iloscramekCom2,
    nos                 : REAL;
    currdtaSign         : CARDINAL;
    s                   : str30;
    GPS_dtaSign         : CARDINAL;

  BEGIN
    waitTime := TInOneSecond( ) * 1;
    Stan := Znacznik;
    iloscramekCom2 := 0.0;
    nos := 0.0;
    LOOP
      Wait( waitTime );
      CASE Stan OF
        Znacznik :
          GPSReceive( iloscramekCom2, 
                      nos, currdtaSign );
          IF GPS_dtaSign # currdtaSign
          THEN
            GPS_dtaSign := currdtaSign;
            
            sprintf( s, "%8.0lf", nos );
            WrStrXY( s, 380, 340, WHITE, BLACK );
            sprintf( s, "%8.0lf", iloscramekCom2 );
            WrStrXY( s, 380, 360, WHITE, BLACK );

            IF pass = TRUE
            THEN
              WrStrXY( '\', 270, 260, WHITE, BLACK );
            ELSE
              WrStrXY( '/', 270, 260, WHITE, BLACK );
            END (* if *);
          ELSE
            WrStrXY( '     NOT', 380, 340, WHITE, BLACK );
            WrStrXY( '     NOT', 380, 360, WHITE, BLACK );
          END (* if GPS_DIFFMODE *);
          pass := NOT pass;
        |
        Koniec :
          KoniecGPS( );   (* wylogowanie GPS *)
          EXIT;
      END (* case Stan *);
    END (* loop *);
  END ZnacznikP;

  PROCEDURE GSKoniec();

  VAR

  BEGIN
    GmainState := KoniecMS;
    EndDialog( TRUE );
    RETURN;
  END GSKoniec;

  PROCEDURE OblotStop();

  VAR
    Rekran : RECT;

  BEGIN
    Stan := Koniec;
    EndDialog( TRUE );
  END OblotStop;

  PROCEDURE RealVal
            (    l : InpLine.HLINE ) : REAL;

  VAR
    s  : ARRAY [ 0 .. 99 ] OF CHAR;
    r  : REAL;
    ok : BOOLEAN;

  BEGIN
    InpLine.GetText( l, s );
    StringToReal( s, r, ok );
    (* Assert( ok );*)
    RETURN r;
  END RealVal;

  PROCEDURE InitOblot();

  VAR
    R               : RECT;
    kont,
    firsTime        : BOOLEAN;
    b               : Button;
    s               : ARRAY [ 0 .. 11 ] OF CHAR;
    i,
    k               : CARDINAL;
    ListaUrz_Typ    : HLIST;
    przyciskInicjuj,
    przyciskKoniec  : Button;

  BEGIN
    (* inicjacja zmiennych *)
    firsTime := TRUE;
    RedrawScr := TRUE;
    i := 0;
    k := 0;
    (* tworzenie ekranu *)
    AssignRect( R, 0, 0, 800, 600 );
    hDlg := TworzDialog( R, "gps.dib", FALSE );
    SetPaletteEntry( GetDialogDIBHandle( hDlg ), 2, 127, 127, 255 );
    Wr2fStrXY( ' URZADZENIA ', 70, 100, WHITE, BLUE );
    AssignRect( R, 100, 150, 200, 250 );
    ListaUrz_Typ := WstawListe( hDlg, R, FALSE );   (* lista urzadzen*)
    KillContents( ListaUrz_Typ, FALSE );
    AssignRect( R, 500, 150, 770, 500 );
    Wr2fStrXY( ' LOKALIZACJE ', 500, 100, WHITE, BLUE );
    ListaUrz_Obiekt := WstawListe( hDlg, R, FALSE );
    (* linie wprowadzania danych *)
    WstawInpLine( hDlg, 100, 320, 12, RealKatValid, BLACK, LT_RED, GPSKat );
    WstawInpLine( hDlg, 100, 360, 12, RealOdlegValid, BLACK, LT_RED,
                  GPSOdleglosc );
    WstawInpLine( hDlg, 100, 400, 12, RealWysokValid, BLACK, LT_RED,
                  GPSWysokosc );
    IF firsTime (* lista urzadzen *)
    THEN
      DodajDoListy( ListaUrz_Typ, "LOC" );
      DodajDoListy( ListaUrz_Typ, "GS" );
      DodajDoListy( ListaUrz_Typ, "VOR" );
      DodajDoListy( ListaUrz_Typ, "ADF" );
      DodajDoListy( ListaUrz_Typ, "VHF" );
    END (* if firsTime *);
    firsTime := FALSE;
    (* RedrawScr := FALSE;*)
    SetNotificationProc( ListaUrz_Typ, ZmienUrzadz );   (* ustawienie aktywnego
                                                           typu urzadzenia *)
    SetNotificationProc( ListaUrz_Obiekt, ZmienOiekt );   (* ustawienie
                                                             aktywnego obiekyu
                                                          *)
    (* wprowadzenie przyciskow *)
    AssignRect( R, 50, 526, 150, 570 );
    WstawButton( hDlg, R, "INICJUJ", 0, ShortCuts.kbAltI, InitGS,
                 przyciskInicjuj );
    AssignRect( R, 200, 526, 300, 570 );
    WstawButton( hDlg, R, "KONIEC", 0, ShortCuts.kbAltK, GSKoniec,
                 przyciskKoniec );
    MoveRect( R, 0, 100 );
    WstawButton( hDlg, R, "", -1, ShortCuts.kbEnter, InitGS, b );
    IF NOT kont
    THEN
      i := 0;
      k := 0;
    END (* if *);
    ZmienUrzadz( k );
    SetSelection( ListaUrz_Typ, k );
    ZmienOiekt( i );
    SetSelection( ListaUrz_Obiekt, i );
    RedrawScr := FALSE;
    kont := Go( hDlg );
    (* UsunDialog( hDlg );*)
    RETURN;
  END InitOblot;


  PROCEDURE Polozenie
            ( VAR mainState : MainStates );

  VAR

  BEGIN
    Info( "" );   (* komunikat na ekran *)
    GtypURZ := LOC;   (* inicjacja zmiennej okreslajacej typ urzadzenia *)
    ParametryPlikIni( GtypURZ, ParamIdenty );   (* ustawienie nazw plikow nazw
                                                   sekcji dla urzadzenia *)
    InitOblot;   (* procedura glowna *)
    mainState := GmainState;
  END Polozenie;

END POLoze.
