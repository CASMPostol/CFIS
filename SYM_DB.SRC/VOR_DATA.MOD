IMPLEMENTATION MODULE VOR_data;

FROM Objects IMPORT
  TRect, DisposeStr, NewStr, PString;
FROM Drivers IMPORT
  TEvent, EventType;
FROM IntInputLines IMPORT
  PIntInputLine;
FROM RealInputLines IMPORT
  PRealInputLine;
FROM InputLines IMPORT
  PInputLine, TInputLine;
FROM StaticTexts IMPORT
  PStaticText;
FROM CheckBoxes IMPORT
  PCheckBoxes;
FROM Clusters IMPORT
  NewSItem;
FROM Dialogs IMPORT
  PDialog, TDialog;
FROM Views IMPORT
  TViewOption, TViewOptions, ofCentered, EnableCommand, DisableCommand;
FROM Labels IMPORT
  PLabel;
FROM Storage IMPORT
  ALLOCATE, DEALLOCATE;
FROM Hist IMPORT
  DefineHistorySubView, SetNotification, VOR_HIST_ID, DefineFreqListSubView;
FROM Str IMPORT
  Copy, StrToInt, Compare, StrToCard, StrToReal, Item, CHARSET;
FROM StringCollections IMPORT
  PStringCollection;
FROM ListBoxes IMPORT
  PListBox;
FROM Buttons IMPORT
  PButton, ButtonFlag, ButtonFlags;
FROM ScrollBars IMPORT
  PScrollBar;
FROM Ini IMPORT
  WritePrivateProfileString, GetPrivateProfileString, DeleteSection;
FROM stdio IMPORT
  sprintf, sscanf;
FROM HistList IMPORT
  HistoryAdd, HistoryStr, HistoryCount, HistoryDelete;
FROM Commands IMPORT
  cmOK, cmCancel;
FROM Warn IMPORT
  LockCnt;
FROM DB_utl IMPORT
  UtnijSpacje, CompareBezSpacji;
IMPORT
  Str, Potw;

FROM DB_Common IMPORT
  SetBlockGPS,Blok, SetBlock1, BlokGPS;


TYPE
  PVORD = POINTER TO VORD;


VAR
  p : PVORD;
  Desktop : PGroup;


CONST
  VOR_LIST = "VorList.ini";


CLASS VORD( TDialog );
   AktualnyVOR : ARRAY[0..127] OF CHAR;
   Szerokosc, Dlugosc : Blok;
   GPS            : BlokGPS;
   Odleglosc      : PRealInputLine;
   Kat            : PIntInputLine;
   OrbPom, OrbZas : PRealInputLine;
   Deklinacja     : PRealInputLine;
   Zawartosc      : PStringCollection;
   Lista          : PListBox;
   Tytul          : PInputLine;
   Czestotliwosc  : PRealInputLine;
   IsDme          : PCheckBoxes;
   Identyfikator  : PInputLine;

   PROCEDURE Init;
   PROCEDURE ResetValue( VAR s : ARRAY OF CHAR );
   PROCEDURE NowyVor;
   PROCEDURE Zapisz;
   PROCEDURE LoadVor;
   PROCEDURE Odczytaj;
   PROCEDURE Dodaj;
   PROCEDURE Usun;
   PROCEDURE UsunZBazy;
   VIRTUAL PROCEDURE Done;
   VIRTUAL PROCEDURE HandleEvent( VAR E : TEvent );
END VORD;

PROCEDURE ZmieniloSie( VAR s : ARRAY OF CHAR );
BEGIN
  IF p # NIL THEN
    p^.ResetValue( s );
  END;
END ZmieniloSie;

CLASS IMPLEMENTATION VORD;

  PROCEDURE Init;
  VAR
    R : TRect;
    n : PInputLine;
    l : PLabel;
    st : PStaticText;
    Scroll : PScrollBar;
    Button : PButton;


    PROCEDURE SetReal(     LabelText : ARRAY OF CHAR;
                       VAR p         : PRealInputLine;
                           max       : LONGREAL;
                           y         : CARDINAL      );
    BEGIN
      R.Assign( 15, y, 32, y+1 );
      NEW( p );
      p^.Init( R, 15, 0.0, max );
      p^.SetFormat( "%.2lf" );
      Insert( p );

      R.Assign( 2, y, 15, y+1 );
      NEW( l );
      l^.Init( R, LabelText, p );
      Insert( l );

    END SetReal;
    
    PROCEDURE SetReal1(     LabelText : ARRAY OF CHAR;
                       VAR p         : PRealInputLine;
                           max       : LONGREAL;
                           dodatnie  : BOOLEAN;
                           x, y      : CARDINAL      );
    BEGIN
      R.Assign( x+13, y, x+30, y+1 );
      NEW( p );
      IF dodatnie THEN
        p^.Init( R, 15, 0.0, max );
      ELSE
        p^.Init( R, 15, -max, max );
      END;
      p^.SetFormat( "%.2lf" );
      Insert( p );

      R.Assign( x, y, x+13, y+1 );
      NEW( l );
      l^.Init( R, LabelText, p );
      Insert( l );

    END SetReal1;

    PROCEDURE SetInt1(     LabelText : ARRAY OF CHAR;
                       VAR p         : PIntInputLine;
                           x, y      : CARDINAL      );
    BEGIN
      R.Assign( x+13, y, x+30, y+1 );
      NEW( p );
      p^.Init( R, 15, -180, 359 );
      p^.SetFormat( "%03d" );
      Insert( p );

      R.Assign( x, y, x+13, y+1 );
      NEW( l );
      l^.Init( R, LabelText, p );
      Insert( l );

    END SetInt1;


    PROCEDURE SetInt(     LabelText : ARRAY OF CHAR;
                      VAR p         : PIntInputLine;
                          y         : CARDINAL      );
    BEGIN
      R.Assign( 15, y, 32, y+1 );
      NEW( p );
      p^.Init( R, 15, -180, 359 );
      p^.SetFormat( "%03d" );
      Insert( p );

      R.Assign( 2, y, 15, y+1 );
      NEW( l );
      l^.Init( R, LabelText, p );
      Insert( l );

    END SetInt;

  BEGIN
    INC( LockCnt );
    DisableCommand( cmVORdatabase );
    R.Assign( 0, 0, 74, 16 );
    TDialog.Init( R, "Baza danych VOR" );
    Options := Options + ofCentered ;
    DefineHistorySubView( ADR( SELF ), "Zadany ~V~OR", VOR_HIST_ID, Tytul );
    
    SetBlock1(SELF, "~S~zeroko˜†", Szerokosc, "N",2, 4 );
    SetBlock1(SELF, "Dˆu~g~o˜†", Dlugosc, "E",2, 5 );


(*    DefineFreqListSubView( ADR( SELF ), Czestotliwosc ); *)

    R.Assign( 16, 3, 30, 4 );
    NEW( Czestotliwosc );
    Czestotliwosc^.Init( R, 10, 0.0, 1.0E6 );
    Czestotliwosc^.SetFormat( "%.2lf" );
    Insert( Czestotliwosc );

    R.Assign( 2, 3, 15, 4 );
    NEW( l );
    l^.Init( R, "~C~z©st. [MHz]", Czestotliwosc );
    Insert( l );

    SetNotification( VOR_HIST_ID, ZmieniloSie );
    
    R.Assign( 15, 6, 24, 7 );
    NEW( Deklinacja );
    Deklinacja^.Init( R, 15, -10.0, +10.0 );
    Deklinacja^.SetFormat( "%.2lf" );
    Insert( Deklinacja );
    R.Assign( 2, 6, 15, 7 );
    NEW( l );
    l^.Init( R, "~D~eklinacja", Deklinacja );
    Insert( l );
    
    R.Assign( 24, 6, 25, 7 );
    NEW( st );
    st^.Init( R, "ø" );
    Insert( st );

    SetBlockGPS( SELF, GPS , 38, 2);

    R.Assign( 38, 6, 72, 9 );
    NEW( st );
    st^.Init( R, "Õ                               Í¸"+15C+12C+
                 "³                                ³"+15C+12C+
                 "À¯Teodolit®ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ" );
    Insert( st );

    SetReal1( "~Odlegˆo˜†", Odleglosc, 10.0,TRUE,39, 6 );
    R.Assign( 69, 6, 70, 7 );
      NEW( st );
      st^.Init( R, "m" );
      Insert( st );

    SetInt1( "~K~¥t", Kat, 39,7 );
    R.Assign( 69, 7, 70, 8);
      NEW( st );
      st^.Init( R, "ø" );
      Insert( st );

    SetReal( "Orb. ~p~omiar", OrbPom, 40.0, 7 );
      R.Assign( 32, 7, 34, 8 );
      NEW( st );
      st^.Init( R, "NM" );
      Insert( st );
    SetReal( "Orb. ~z~asi©g", OrbZas, 40.0, 8 );
      R.Assign( 32, 8, 34, 9 );
      NEW( st );
      st^.Init( R, "NM" );
      Insert( st );

    R.Assign( 15, 9, 21, 10 );
      NEW( Identyfikator );
      Identyfikator^.Init( R, 4 );
      Insert( Identyfikator );
    R.Assign( 2, 9, 15, 10 );
      NEW( l );
      l^.Init( R, "~I~dentyf.", Identyfikator );
      Insert( l );
    R.Assign( 21, 9, 32, 10 );
      NEW( IsDme );
      IsDme^.Init( R, NewSItem( "DME", NIL ));
      Insert( IsDme );

    R.Assign( 32, 10, 33, 15 );
      NEW( Scroll );
      Scroll^.Init( R );

    R.Assign( 2, 10, 32, 15 );
      NEW( Lista );
      Lista^.Init( R, 3, Scroll );
      Lista^.NewList( Zawartosc );
      Insert( Lista );

    R.Assign( 39, 10, 54, 12 );
      NEW( Button );
      Button^.Init( R, "~U~suä", cmUsun, ButtonFlags{bfNormal} );
      Insert( Button );

    R.Assign( 56, 10, 69, 12 );
      NEW( Button );
      Button^.Init( R, "~D~odaj", cmDodaj, ButtonFlags{bfNormal} );
      Insert( Button );

    R.Assign( 39, 12, 67, 14 );
      NEW( Button );
      Button^.Init( R, "~U~suä z bazy danych", cmUsunZBazy, ButtonFlags{bfNormal} );
      Insert( Button );

    LoadVor;
    p := ADR( SELF );
    Odczytaj;
  END Init;

  PROCEDURE Dodaj;
  VAR
    Wybrany : CARDINAL;
    Co      : CARDINAL;
    R       : TRect;
    Dlg     : PDialog;
    i       : PIntInputLine;
    b       : PButton;
    s       : ARRAY[0..99] OF CHAR;
    sp      : PString;
  BEGIN
    Wybrany := Lista^.Focused;
    Co := 0;
    R.Assign( 40, 12, 60, 19 );
    NEW( Dlg );
    WITH Dlg^ DO
      Init( R, "Kierunek?" );
      Options := Options + ofCentered;
      R.Assign( 2, 4, 8, 6 );
      NEW( b );
      b^.Init( R, "~O~k", cmOK, ButtonFlags{ bfDefault } );
      Insert( b );
      R.Assign( 8, 4, 18, 6 );
      NEW( b );
      b^.Init( R, "~C~ancel", cmCancel, ButtonFlags{ bfNormal } );
      Insert( b );
      R.Assign( 2, 2, 18, 3 );
      NEW( i );
      i^.Init( R, 12, 0, 359 );
      Insert( i );
      SetData( Co );
    END;
    IF Desktop^.ExecView( Dlg ) # cmCancel THEN
      Dlg^.GetData( Co );
      sprintf( s, "%03d", Co );
      sp := NewStr( s );
      Zawartosc^.Insert( sp );
      Lista^.SetRange( Zawartosc^.Count );
      Lista^.DrawView;
(*      Lista^.NewList( Zawartosc );*)
    END;
    Dlg^.Done;
    DISPOSE( Dlg );
  END Dodaj;


  PROCEDURE Usun;
  VAR
    Wybrany : CARDINAL;
  BEGIN
    IF Zawartosc^.Count > 0 THEN
      Wybrany := Lista^.Focused;
      Zawartosc^.AtDelete( Wybrany );
    END;
    Lista^.SetRange( Zawartosc^.Count );
    Lista^.DrawView;
  END Usun;

  VIRTUAL PROCEDURE HandleEvent( VAR E : TEvent );
  BEGIN
    TDialog.HandleEvent( E );
    IF evCommand IN E.What THEN
      CASE E.Command OF
      | cmDodaj:
          Dodaj;
      | cmUsun:
          Usun;
      | cmUsunZBazy:
          UsunZBazy;
      ELSE
        RETURN;
      END;
    END;
  END HandleEvent;

  PROCEDURE UsunZBazy;
  VAR
    s, s1   : ARRAY[0..49] OF CHAR;
    sp      : PString;
    cnt     : INTEGER;
    i, j, k : INTEGER;
    ok      : BOOLEAN;
  BEGIN
    UtnijSpacje( AktualnyVOR );
    IF AktualnyVOR[0] = 0C THEN
      RETURN;
    END;
    IF NOT Potw.UsunZBazy() THEN
      RETURN;
    END;
    GetPrivateProfileString( "Lista", "Ilosc", "0"+0C, s, VOR_LIST );
    cnt := VAL(INTEGER, StrToInt( s, 10, ok ));
    IF NOT ok THEN
      cnt := 0;
    END;
    i := 0;
    LOOP
      sprintf( s, "VOR%d", i );
      GetPrivateProfileString( "Lista", s, "", s, VOR_LIST );
      IF CompareBezSpacji( s, AktualnyVOR ) = 0 THEN
        EXIT;
      END;
      INC( i );
      IF i > cnt THEN
        RETURN; (* nie ma takiego *)
      END;
    END;
    DeleteSection( AktualnyVOR, VOR_LIST );
    sp := HistoryStr( VOR_HIST_ID, i );
    IF sp # NIL THEN
      HistoryDelete( VOR_HIST_ID, sp^ );
    END;
    k := i;
    WHILE i < cnt DO
      j := i+1;
      sprintf( s, "VOR%d", j );
      GetPrivateProfileString( "Lista", s, "", s1, VOR_LIST );
      sprintf( s, "VOR%d", i );
      WritePrivateProfileString( "Lista", s, s1, VOR_LIST );
      INC( i );
    END;
    j := cnt - 1;
    sprintf( s, "%d", j );
    WritePrivateProfileString( "Lista", "Ilosc", s, VOR_LIST );

    (* a teraz, zeby sie pojawilo cos nowego *)
    IF k = cnt-1 THEN
      DEC( k );
    END;
    sprintf( s, "VOR%d", k );
    GetPrivateProfileString( "Lista", s, "", AktualnyVOR, VOR_LIST );
    Tytul^.SetData( AktualnyVOR );
    Odczytaj;
  END UsunZBazy;

  PROCEDURE NowyVor;
  VAR
    s : ARRAY[0..99] OF CHAR;
    i, cnt : INTEGER;
    ok : BOOLEAN;
  BEGIN
    UtnijSpacje( AktualnyVOR );
    IF AktualnyVOR[0] = 0C THEN
      RETURN;
    END;
    GetPrivateProfileString( "Lista", "Ilosc", "0"+0C, s, VOR_LIST );
    cnt := VAL(INTEGER, StrToInt( s, 10, ok ));
    IF NOT ok THEN
      cnt := 0;
    END;
    FOR i := 0 TO cnt-1 DO
      sprintf( s, "VOR%d", i );
      GetPrivateProfileString( "Lista", s, "", s, VOR_LIST );
      IF Compare( s, AktualnyVOR ) = 0 THEN
        RETURN (* ten vor byl juz w bazie danych *)
      END;
    END;
    sprintf( s, "VOR%d", cnt );
    WritePrivateProfileString( "Lista", s, AktualnyVOR, VOR_LIST );
    INC( cnt );
    sprintf( s, "%d", cnt );
    WritePrivateProfileString( "Lista", "Ilosc", s, VOR_LIST );
  END NowyVor;

  PROCEDURE LoadVor;
  VAR
    s : ARRAY[0..99] OF CHAR;
    sp : PString;
    i, cnt : INTEGER;
    j  : CARDINAL;
    ok : BOOLEAN;
  BEGIN
    GetPrivateProfileString( "Lista", "Ilosc", "0"+0C, s, VOR_LIST );
    cnt := VAL(INTEGER, StrToInt( s, 10, ok ));
    IF NOT ok THEN
      cnt := 0;
    END;
    FOR i := 0 TO cnt-1 DO
      sprintf( s, "VOR%d", i );
      GetPrivateProfileString( "Lista", s, "", s, VOR_LIST );
      HistoryAdd( VOR_HIST_ID, s );
    END;
    IF cnt = 0 THEN
      AktualnyVOR := '';
    ELSE
      sp := HistoryStr( VOR_HIST_ID, 0 );
      IF sp # NIL THEN
        Copy( AktualnyVOR, sp^ );
      END;
    END;
    Tytul^.SetData( AktualnyVOR );
  END LoadVor;

  PROCEDURE Zapisz;
  VAR
    s : ARRAY[0..127] OF CHAR;

    PROCEDURE TextI( il : PIntInputLine; Entry : ARRAY OF CHAR );
    BEGIN
      il^.TInputLine.GetData( s );
      WritePrivateProfileString( AktualnyVOR,
                                 Entry,
                                 s,
                                 VOR_LIST );
     END TextI;

    PROCEDURE TextR( il : PRealInputLine; Entry : ARRAY OF CHAR );
    BEGIN
      il^.TInputLine.GetData( s );
      WritePrivateProfileString( AktualnyVOR,
                                 Entry,
                                 s,
                                 VOR_LIST );
     END TextR;

  VAR
    i, j : CARDINAL;
    fr   : LONGREAL;
    str  : ARRAY[0..20] OF CHAR;
  BEGIN
(*    Tytul^.GetData( AktualnyVOR );*)
    WHILE AktualnyVOR[0] = ' ' DO
      Str.Delete( AktualnyVOR, 0, 1 );
    END;
    IF AktualnyVOR[0] = 0C THEN
      RETURN;
    END;
    TextI( Szerokosc.Stopnie, "Szerokosc.Stopnie" );
    TextI( Szerokosc.Minuty,  "Szerokosc.Minuty" );
    TextI( Szerokosc.Setne,   "Szerokosc.Setne" );
    TextI( Dlugosc.Stopnie,   "Dlugosc.Stopnie" );
    TextI( Dlugosc.Minuty,    "Dlugosc.Minuty" );
    TextI( Dlugosc.Setne,     "Dlugosc.Setne" );
    TextR( Odleglosc,         "Teodolit.Odleglosc" );
    TextR( GPS.Kat,           "GPS.Kat" );
    TextR( GPS.Odleglosc,     "GPS.Odleglosc" );
    TextR( GPS.Wysokosc,      "GPS.Wysokosc" );
    TextR( Deklinacja,        "Deklinacja" );
    TextI( Kat,               "Teodolit.Kat" );
    TextR( OrbPom,            "Orbita.Pomiarowa" );
    TextR( OrbZas,            "Orbita.Zasiegowa" );
    Identyfikator^.GetData( str );
    WritePrivateProfileString( AktualnyVOR,
                               "Identyfikator",
                               str,
                               VOR_LIST );
    IsDme^.GetData( i );
    sprintf( str, "%d", i );
    WritePrivateProfileString( AktualnyVOR,
                               "Dme",
                               str,
                               VOR_LIST );

    sprintf( s, "%d", Zawartosc^.Count );
    WritePrivateProfileString( AktualnyVOR, "IloscKierunkow", s, VOR_LIST );
    IF Zawartosc^.Count > 0 THEN
      FOR i := 0 TO Zawartosc^.Count-1 DO
        sprintf( s, "Kierunek%d", i );
        WritePrivateProfileString( AktualnyVOR,
                                   s,
                                   PString(Zawartosc^.At( i ))^,
                                   VOR_LIST );
      END;
    END;
    Lista^.NewList( NIL );
    (* czestotliwosc *)
    Czestotliwosc^.GetData( fr );
    sprintf(s, "%5.0lf", fr * 100.0 );
    WritePrivateProfileString( AktualnyVOR, "Czestotliwosc", s, VOR_LIST );
    NowyVor;
  END Zapisz;

  PROCEDURE Odczytaj;
  VAR
    s : ARRAY[0..127] OF CHAR;
    CalkowitaIlosc, i, j : INTEGER;
    ok : BOOLEAN;
    sp : PString;

    PROCEDURE TextI( il : PIntInputLine; Entry : ARRAY OF CHAR );
    VAR
      i : INTEGER;
    BEGIN
      GetPrivateProfileString( AktualnyVOR,
                               Entry,
                               "00",
                               s,
                               VOR_LIST );
      Item( s, s, CHARSET{' '}, 0 );
      i := VAL( INTEGER, StrToInt( s, 10, ok ));
      IF NOT ok THEN
        i := 0;
      END;
      il^.SetData( i );
    END TextI;

    PROCEDURE TextR( il : PRealInputLine; Entry : ARRAY OF CHAR );
    VAR
      r : LONGREAL;
    BEGIN
      GetPrivateProfileString( AktualnyVOR,
                               Entry,
                               "00",
                               s,
                               VOR_LIST );
      Item( s, s, CHARSET{' '}, 0 );
      r := StrToReal( s, ok );
      IF NOT ok THEN
        r := 0.0;
      END;
      il^.SetData( r );
    END TextR;

  VAR
    fr : LONGREAL;
    str  : ARRAY[0..20] OF CHAR;
  BEGIN
(*    Tytul^.GetData( AktualnyVOR );*)
    IF AktualnyVOR[0] = 0C THEN
      RETURN;
    END;
    TextI( Szerokosc.Stopnie, "Szerokosc.Stopnie" );
    TextI( Szerokosc.Minuty,  "Szerokosc.Minuty" );
    TextI( Szerokosc.Setne,   "Szerokosc.Setne" );
    TextI( Dlugosc.Stopnie,   "Dlugosc.Stopnie" );
    TextI( Dlugosc.Minuty,    "Dlugosc.Minuty" );
    TextI( Dlugosc.Setne,     "Dlugosc.Setne" );
    TextR( Deklinacja,        "Deklinacja" );
    TextR( Odleglosc,         "Teodolit.Odleglosc" );
    TextR( GPS.Kat,               "GPS.Kat" );
    TextR( GPS.Odleglosc,         "GPS.Odleglosc" );
    TextR( GPS.Wysokosc,         "GPS.Wysokosc" );    
    TextI( Kat,               "Teodolit.Kat" );
    TextR( OrbPom,            "Orbita.Pomiarowa" );
    TextR( OrbZas,            "Orbita.Zasiegowa" );

    GetPrivateProfileString( AktualnyVOR,
                             "Identyfikator",
                             "***",
                             str,
                             VOR_LIST );
    Identyfikator^.SetData( str );
    GetPrivateProfileString( AktualnyVOR,
                             "Dme",
                             "00",
                             str,
                             VOR_LIST );
    sscanf( str, "%d", ADR(i) );
    IsDme^.SetData( i );

    GetPrivateProfileString( AktualnyVOR, "IloscKierunkow", "00", s, VOR_LIST );
    CalkowitaIlosc := VAL( INTEGER, StrToCard( s, 10, ok ));
    NEW( Zawartosc );
    Zawartosc^.Init( 36, 2 );
    IF NOT ok THEN
      CalkowitaIlosc := 0;
    END;
    IF CalkowitaIlosc > 0 THEN
      FOR i := 0 TO CalkowitaIlosc-1 DO
        sprintf( s, "Kierunek%d", i );
        GetPrivateProfileString( AktualnyVOR,
                                 s,
                                 "",
                                 s,
                                 VOR_LIST );
        j := VAL( INTEGER, StrToInt( s, 10, ok ));
        IF NOT ok THEN
          j := 0;
        END;
        sprintf( s, "%03d", j );
        sp := NewStr( s );
        Zawartosc^.Insert( sp );
      END;
    END;
    Lista^.NewList( Zawartosc );
    (* czestotliwosc *)
    GetPrivateProfileString( AktualnyVOR, "Czestotliwosc", "0", s, VOR_LIST );
    sscanf( s, "%lf", ADR( fr ));
    fr := fr / 100.0;
    Czestotliwosc^.SetData( fr );
  END Odczytaj;

  PROCEDURE ResetValue( VAR s : ARRAY OF CHAR );
  BEGIN
    Zapisz;
    Copy( AktualnyVOR, s );
    Odczytaj;
  END ResetValue;

  VIRTUAL PROCEDURE Done;
  VAR
    s : ARRAY[0..1] OF CHAR;
    i : INTEGER;
  BEGIN
    DEC( LockCnt );
    s[0] := 0C;
    Tytul^.GetData( AktualnyVOR );
    ResetValue( s );
    EnableCommand( cmVORdatabase );
    FOR i := 0 TO VAL( INTEGER, HistoryCount( VOR_HIST_ID ))-1 DO
      HistoryDelete( VOR_HIST_ID, HistoryStr( VOR_HIST_ID, 0 )^ );
    END;
    TDialog.Done;
  END Done;

BEGIN
  AktualnyVOR[0] := 0C;
  NEW( Zawartosc );
  Zawartosc^.Init( 36, 2 );
END VORD;







 


PROCEDURE VORdata( g : PGroup );
VAR
  d : PVORD;
BEGIN
  NEW( d );
  Desktop := g;
  WITH d^ DO
    Init;
    g^.Insert( d );
  END;
END VORdata;

BEGIN
  p := NIL;
END VOR_data.
