IMPLEMENTATION MODULE NDB_data;

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
  DefineHistorySubView, SetNotification, NDB_HIST_ID, DefineFreqListSubView;
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
FROM DB_Common IMPORT
  SetBlockGPS,BlokGPS, Blok, SetBlock,SetBlock1;
FROM DB_utl IMPORT
  UtnijSpacje, CompareBezSpacji;
IMPORT
  Str, Potw;


TYPE
  PNDBD = POINTER TO NDBD;


VAR
  p : PNDBD;
  Desktop : PGroup;


CONST
  NDB_LIST = "NDBList.ini";


CLASS NDBD( TDialog );
   AktualnyNDB    : ARRAY[0..127] OF CHAR;
   Tytul          : PInputLine;
   Deklinacja     : PRealInputLine;
   GPS            : BlokGPS;
   Czestotliwosc  : PRealInputLine;
   Identyfikator  : PInputLine;
   Szerokosc,
   Dlugosc        : Blok;


   PROCEDURE Init;
   PROCEDURE ResetValue( VAR s : ARRAY OF CHAR );
   PROCEDURE NoweNDB;
   PROCEDURE Zapisz;
   PROCEDURE LoadNDB;
   PROCEDURE Odczytaj;
   PROCEDURE UsunZBazy;
   VIRTUAL PROCEDURE Done;
   VIRTUAL PROCEDURE HandleEvent( VAR E : TEvent );
END NDBD;

PROCEDURE ZmieniloSie( VAR s : ARRAY OF CHAR );
BEGIN
  IF p # NIL THEN
    p^.ResetValue( s );
  END;
END ZmieniloSie;

CLASS IMPLEMENTATION NDBD;

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
    
    BEGIN
    INC( LockCnt );
    DisableCommand( cmNDBdatabase );
    R.Assign( 0, 0, 38, 20 );
    TDialog.Init( R, "Baza danych NDB" );
    Options := Options + ofCentered ;
    DefineHistorySubView( ADR( SELF ), "Zadane ~N~DB", NDB_HIST_ID, Tytul );
(*    DefineFreqListSubView( ADR( SELF ), Czestotliwosc ); *)

    SetBlock1( SELF, "~S~zeroko˜†", Szerokosc, "N",2, 4 );
    SetBlock1( SELF, "Dˆu~g~o˜†", Dlugosc, "E",2, 5 );

    R.Assign( 15, 7, 32, 8 );
    NEW( Czestotliwosc );
    Czestotliwosc^.Init( R, 10, 0.0, 1.0E6 );
    Czestotliwosc^.SetFormat( "%.2lf" );
    Insert( Czestotliwosc );

    R.Assign( 2, 7, 15, 8 );
    NEW( l );
    l^.Init( R, "~C~z©st. [kHz]", Czestotliwosc );
    Insert( l );

    SetNotification( NDB_HIST_ID, ZmieniloSie );

    R.Assign( 15, 8, 32, 9 );
      NEW( Deklinacja );
      Deklinacja^.Init( R, 15, -10.0, +10.0 );
      Deklinacja^.SetFormat( "%.2lf" );
      Insert( Deklinacja );
    R.Assign( 2, 8, 15, 9 );
      NEW( l );
      l^.Init( R, "~D~eklinacja", Deklinacja );
      Insert( l );
    R.Assign( 32, 8, 33, 9 );
      NEW( st );
      st^.Init( R, "ø" );
      Insert( st );

    R.Assign( 15, 10, 21, 11 );
      NEW( Identyfikator );
      Identyfikator^.Init( R, 4 );
      Insert( Identyfikator );
    R.Assign( 2, 10, 15, 11 );
      NEW( l );
      l^.Init( R, "~I~dentyf.", Identyfikator );
      Insert( l );
    
      SetBlockGPS( SELF, GPS , 2, 12);

    R.Assign( 2, 17, 33, 19 );
      NEW( Button );
      Button^.Init( R, "~U~suä z bazy danych", cmUsunZBazy, ButtonFlags{bfNormal} );
      Insert( Button );

    LoadNDB;
    p := ADR( SELF );
    Odczytaj;
  END Init;

  VIRTUAL PROCEDURE HandleEvent( VAR E : TEvent );
  BEGIN
    TDialog.HandleEvent( E );
    IF evCommand IN E.What THEN
      CASE E.Command OF
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
    ps      : PString;
    cnt     : INTEGER;
    i, j, k : INTEGER;
    ok      : BOOLEAN;
  BEGIN
    UtnijSpacje( AktualnyNDB );
    IF AktualnyNDB[0] = 0C THEN
      RETURN;
    END;
    IF NOT Potw.UsunZBazy() THEN
      RETURN;
    END;
    GetPrivateProfileString( "Lista", "Ilosc", "0"+0C, s, NDB_LIST );
    cnt := VAL(INTEGER, StrToInt( s, 10, ok ));
    IF NOT ok THEN
      cnt := 0;
    END;
    i := 0;
    LOOP
      sprintf( s, "NDB%d", i );
      GetPrivateProfileString( "Lista", s, "", s, NDB_LIST );
      IF Compare( s, AktualnyNDB ) = 0 THEN
        EXIT;
      END;
      INC( i );
      IF i > cnt THEN
        RETURN; (* nie ma takiego *)
      END;
    END;
    DeleteSection( AktualnyNDB, NDB_LIST );
    ps := HistoryStr( NDB_HIST_ID, i );
    IF ps # NIL THEN
      HistoryDelete( NDB_HIST_ID, ps^ );
    END;
    k := i;
    WHILE i < cnt DO
      j := i+1;
      sprintf( s, "NDB%d", j );
      GetPrivateProfileString( "Lista", s, "", s1, NDB_LIST );
      sprintf( s, "NDB%d", i );
      WritePrivateProfileString( "Lista", s, s1, NDB_LIST );
      INC( i );
    END;
    j := cnt - 1;
    sprintf( s, "%d", j );
    WritePrivateProfileString( "Lista", "Ilosc", s, NDB_LIST );

    (* a teraz, zeby sie pojawilo cos nowego *)
    IF k = cnt-1 THEN
      DEC( k );
    END;
    sprintf( s, "NDB%d", k );
    GetPrivateProfileString( "Lista", s, "", AktualnyNDB, NDB_LIST );
    Tytul^.SetData( AktualnyNDB );
    Odczytaj;
  END UsunZBazy;

  PROCEDURE NoweNDB;
  VAR
    s : ARRAY[0..99] OF CHAR;
    i, cnt : INTEGER;
    ok : BOOLEAN;
  BEGIN
    IF AktualnyNDB[0] = 0C THEN
      RETURN;
    END;
    GetPrivateProfileString( "Lista", "Ilosc", "0"+0C, s, NDB_LIST );
    cnt := VAL(INTEGER, StrToInt( s, 10, ok ));
    IF NOT ok THEN
      cnt := 0;
    END;
    FOR i := 0 TO cnt-1 DO
      sprintf( s, "NDB%d", i );
      GetPrivateProfileString( "Lista", s, "", s, NDB_LIST );
      IF Compare( s, AktualnyNDB ) = 0 THEN
        RETURN (* to NDB bylo juz w bazie danych *)
      END;
    END;
    sprintf( s, "NDB%d", cnt );
    WritePrivateProfileString( "Lista", s, AktualnyNDB, NDB_LIST );
    INC( cnt );
    sprintf( s, "%d", cnt );
    WritePrivateProfileString( "Lista", "Ilosc", s, NDB_LIST );
  END NoweNDB;

  PROCEDURE LoadNDB;
  VAR
    s : ARRAY[0..99] OF CHAR;
    i, cnt : INTEGER;
    j  : CARDINAL;
    ok : BOOLEAN;
    sp : PString;
  BEGIN
    GetPrivateProfileString( "Lista", "Ilosc", "0"+0C, s, NDB_LIST );
    cnt := VAL(INTEGER, StrToInt( s, 10, ok ));
    IF NOT ok THEN
      cnt := 0;
    END;
    FOR i := 0 TO cnt-1 DO
      sprintf( s, "NDB%d", i );
      GetPrivateProfileString( "Lista", s, "", s, NDB_LIST );
      HistoryAdd( NDB_HIST_ID, s );
    END;
    IF cnt = 0 THEN
      AktualnyNDB := '';
    ELSE
      sp := HistoryStr( NDB_HIST_ID, 0 );
      IF sp # NIL THEN
        Copy( AktualnyNDB, sp^ );
      END;
    END;
    Tytul^.SetData( AktualnyNDB );
  END LoadNDB;

  PROCEDURE Zapisz;
  VAR
    s : ARRAY[0..127] OF CHAR;

    PROCEDURE TextI( il : PIntInputLine; Entry : ARRAY OF CHAR );
    BEGIN
      il^.TInputLine.GetData( s );
      WritePrivateProfileString( AktualnyNDB,
                                 Entry,
                                 s,
                                 NDB_LIST );
     END TextI;

    PROCEDURE TextR( il : PRealInputLine; Entry : ARRAY OF CHAR );
    BEGIN
      il^.TInputLine.GetData( s );
      WritePrivateProfileString( AktualnyNDB,
                                 Entry,
                                 s,
                                 NDB_LIST );
     END TextR;

  VAR
    i, j : CARDINAL;
    fr   : LONGREAL;
    str  : ARRAY[0..20] OF CHAR;
  BEGIN
(*    Tytul^.GetData( AktualnyNDB );*)
    WHILE AktualnyNDB[0] = ' ' DO
      Str.Delete( AktualnyNDB, 0, 1 );
    END;
    IF AktualnyNDB[0] = 0C THEN
      RETURN;
    END;
    TextI( Szerokosc.Stopnie, "Szerokosc.Stopnie" );
    TextI( Szerokosc.Minuty,  "Szerokosc.Minuty" );
    TextI( Szerokosc.Setne,   "Szerokosc.DTysieczne" );
    TextI( Dlugosc.Stopnie,   "Dlugosc.Stopnie" );
    TextI( Dlugosc.Minuty,    "Dlugosc.Minuty" );
    TextI( Dlugosc.Setne,     "Dlugosc.DTysieczne" );
    TextR( GPS.Odleglosc,     "GPS.Odleglosc" );
    TextR( GPS.Wysokosc,      "GPS.Wysokosc" );
    TextR( GPS.Kat,           "GPS.Kat" );
    TextR( Deklinacja,        "Deklinacja" );
    Identyfikator^.GetData( str );
    WritePrivateProfileString( AktualnyNDB,
                               "Identyfikator",
                               str,
                               NDB_LIST );
    Czestotliwosc^.GetData( fr );
    sprintf(s, "%ld", LONGINT(fr * 100.0) );
    WritePrivateProfileString( AktualnyNDB, "Czestotliwosc", s, NDB_LIST );
    NoweNDB;
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
      GetPrivateProfileString( AktualnyNDB,
                               Entry,
                               "00",
                               s,
                               NDB_LIST );
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
      GetPrivateProfileString( AktualnyNDB,
                               Entry,
                               "00",
                               s,
                               NDB_LIST );
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
(*    Tytul^.GetData( AktualnyNDB );*)
    IF AktualnyNDB[0] = 0C THEN
      RETURN;
    END;
    TextI( Szerokosc.Stopnie, "Szerokosc.Stopnie" );
    TextI( Szerokosc.Minuty,  "Szerokosc.Minuty" );
    TextI( Szerokosc.Setne,   "Szerokosc.DTysieczne" );
    TextI( Dlugosc.Stopnie,   "Dlugosc.Stopnie" );
    TextI( Dlugosc.Minuty,    "Dlugosc.Minuty" );
    TextI( Dlugosc.Setne,     "Dlugosc.DTysieczne" );
    TextR( GPS.Odleglosc,         "GPS.Odleglosc" );
    TextR( GPS.Wysokosc,         "GPS.Wysokosc" );
    TextR( GPS.Kat,               "GPS.Kat" );
    TextR( Deklinacja,        "Deklinacja" );
    GetPrivateProfileString( AktualnyNDB,
                             "Identyfikator",
                             "***",
                             str,
                             NDB_LIST );
    Identyfikator^.SetData( str );
    (* czestotliwosc *)
    GetPrivateProfileString( AktualnyNDB, "Czestotliwosc", "0", s, NDB_LIST );
    sscanf( s, "%lf", ADR( fr ));
    fr := fr / 100.0;
    Czestotliwosc^.SetData( fr );
  END Odczytaj;

  PROCEDURE ResetValue( VAR s : ARRAY OF CHAR );
  BEGIN
    Zapisz;
    Copy( AktualnyNDB, s );
    Odczytaj;
  END ResetValue;

  VIRTUAL PROCEDURE Done;
  VAR
    s : ARRAY[0..1] OF CHAR;
    i : INTEGER;
  BEGIN
    DEC( LockCnt );
    s[0] := 0C;
    Tytul^.GetData( AktualnyNDB );
    ResetValue( s );
    EnableCommand( cmNDBdatabase );
    FOR i := 0 TO VAL( INTEGER, HistoryCount( NDB_HIST_ID ))-1 DO
      HistoryDelete( NDB_HIST_ID, HistoryStr( NDB_HIST_ID, 0 )^ );
    END;
    TDialog.Done;
  END Done;

BEGIN
  AktualnyNDB[0] := 0C;
END NDBD;







 


PROCEDURE NDBdata( g : PGroup );
VAR
  d : PNDBD;
BEGIN
  NEW( d );
  Desktop := g;
  WITH d^ DO
    Init;
    g^.Insert( d );
  END;
END NDBdata;

BEGIN
  p := NIL;
END NDB_data.
