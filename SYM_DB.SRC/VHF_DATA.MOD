IMPLEMENTATION MODULE VHF_data;

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
  DefineHistorySubView, SetNotification, VHF_HIST_ID, DefineFreqListSubView;
FROM Str IMPORT
  Copy, StrToInt, Compare, StrToCard, StrToReal, Item, CHARSET, Delete;
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
  BlokGPS,SetBlockGPS,Blok, SetBlock,SetBlock1;
FROM DB_utl IMPORT
  UtnijSpacje, CompareBezSpacji;
IMPORT
  Str, Potw;


TYPE
  PVHFD = POINTER TO VHFD;


VAR
  p : PVHFD;
  Desktop : PGroup;


CONST
  VHF_LIST = "VHFList.ini";


CLASS VHFD( TDialog );
   AktualnyVHF    : ARRAY[0..127] OF CHAR;
   Tytul          : PInputLine;
   Deklinacja     : PRealInputLine;
   Szerokosc,
   Dlugosc        : Blok;
   GPS            : BlokGPS;
   PROCEDURE Init;
   PROCEDURE ResetValue( VAR s : ARRAY OF CHAR );
   PROCEDURE NoweVHF;
   PROCEDURE Zapisz;
   PROCEDURE LoadVHF;
   PROCEDURE Odczytaj;
   PROCEDURE UsunZBazy;
   VIRTUAL PROCEDURE Done;
   VIRTUAL PROCEDURE HandleEvent( VAR E : TEvent );
END VHFD;

PROCEDURE ZmieniloSie( VAR s : ARRAY OF CHAR );
BEGIN
  IF p # NIL THEN
    p^.ResetValue( s );
  END;
END ZmieniloSie;

CLASS IMPLEMENTATION VHFD;

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

  BEGIN
    INC( LockCnt );
    DisableCommand( cmVHFdatabase );
    R.Assign( 0, 0, 38, 18 );
    TDialog.Init( R, "Baza danych VHF" );
    Options := Options + ofCentered ;
    DefineHistorySubView( ADR( SELF ), "Zadany V~H~F", VHF_HIST_ID, Tytul );

    SetNotification( VHF_HIST_ID, ZmieniloSie );

    SetBlock1( SELF, "~S~zeroko��", Szerokosc, "N",2, 4 );
    SetBlock1( SELF, "D�u~g~o��", Dlugosc, "E",2, 5 );

    R.Assign( 15, 7, 32, 8 );
      NEW( Deklinacja );
      Deklinacja^.Init( R, 15, -10.0, +10.0 );
      Deklinacja^.SetFormat( "%.2lf" );
      Insert( Deklinacja );
    R.Assign( 2, 7, 15, 8 );
      NEW( l );
      l^.Init( R, "~D~eklinacja", Deklinacja );
      Insert( l );
    R.Assign( 32, 7, 33, 8 );
      NEW( st );
      st^.Init( R, "�" );
      Insert( st );

      SetBlockGPS( SELF, GPS , 2, 9);


    R.Assign( 2, 15, 33, 17 );
      NEW( Button );
      Button^.Init( R, "~U~su� z bazy danych", cmUsunZBazy, ButtonFlags{bfNormal} );
      Insert( Button );

    LoadVHF;
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
    sp      : PString;
    cnt     : INTEGER;
    i, j, k : INTEGER;
    ok      : BOOLEAN;
  BEGIN
    UtnijSpacje( AktualnyVHF );
    IF AktualnyVHF[0] = 0C THEN
      RETURN;
    END;
    IF NOT Potw.UsunZBazy() THEN
      RETURN;
    END;
    GetPrivateProfileString( "Lista", "Ilosc", "0"+0C, s, VHF_LIST );
    cnt := VAL(INTEGER, StrToInt( s, 10, ok ));
    IF NOT ok THEN
      cnt := 0;
    END;
    i := 0;
    LOOP
      sprintf( s, "VHF%d", i );
      GetPrivateProfileString( "Lista", s, "", s, VHF_LIST );
      IF Compare( s, AktualnyVHF ) = 0 THEN
        EXIT;
      END;
      INC( i );
      IF i > cnt THEN
        RETURN; (* nie ma takiego *)
      END;
    END;
    DeleteSection( AktualnyVHF, VHF_LIST );
    sp := HistoryStr( VHF_HIST_ID, i );
    IF sp # NIL THEN
      HistoryDelete( VHF_HIST_ID, sp^ );
    END;
    k := i;
    WHILE i < cnt DO
      j := i+1;
      sprintf( s, "VHF%d", j );
      GetPrivateProfileString( "Lista", s, "", s1, VHF_LIST );
      sprintf( s, "VHF%d", i );
      WritePrivateProfileString( "Lista", s, s1, VHF_LIST );
      INC( i );
    END;
    j := cnt - 1;
    sprintf( s, "%d", j );
    WritePrivateProfileString( "Lista", "Ilosc", s, VHF_LIST );

    (* a teraz, zeby sie pojawilo cos nowego *)
    IF k = cnt-1 THEN
      DEC( k );
    END;
    sprintf( s, "VHF%d", k );
    GetPrivateProfileString( "Lista", s, "", AktualnyVHF, VHF_LIST );
    Tytul^.SetData( AktualnyVHF );
    Odczytaj;
  END UsunZBazy;

  PROCEDURE NoweVHF;
  VAR
    s : ARRAY[0..99] OF CHAR;
    i, cnt : INTEGER;
    ok : BOOLEAN;
  BEGIN
    IF AktualnyVHF[0] = 0C THEN
      RETURN;
    END;
    GetPrivateProfileString( "Lista", "Ilosc", "0"+0C, s, VHF_LIST );
    cnt := VAL(INTEGER, StrToInt( s, 10, ok ));
    IF NOT ok THEN
      cnt := 0;
    END;
    FOR i := 0 TO cnt-1 DO
      sprintf( s, "VHF%d", i );
      GetPrivateProfileString( "Lista", s, "", s, VHF_LIST );
      IF Compare( s, AktualnyVHF ) = 0 THEN
        RETURN (* to VHF bylo juz w bazie danych *)
      END;
    END;
    sprintf( s, "VHF%d", cnt );
    WritePrivateProfileString( "Lista", s, AktualnyVHF, VHF_LIST );
    INC( cnt );
    sprintf( s, "%d", cnt );
    WritePrivateProfileString( "Lista", "Ilosc", s, VHF_LIST );
  END NoweVHF;

  PROCEDURE LoadVHF;
  VAR
    s : ARRAY[0..99] OF CHAR;
    i, cnt : INTEGER;
    j  : CARDINAL;
    ok : BOOLEAN;
    sp : PString;
  BEGIN
    GetPrivateProfileString( "Lista", "Ilosc", "0"+0C, s, VHF_LIST );
    cnt := VAL(INTEGER, StrToInt( s, 10, ok ));
    IF NOT ok THEN
      cnt := 0;
    END;
    FOR i := 0 TO cnt-1 DO
      sprintf( s, "VHF%d", i );
      GetPrivateProfileString( "Lista", s, "", s, VHF_LIST );
      HistoryAdd( VHF_HIST_ID, s );
    END;
    IF cnt = 0 THEN
      AktualnyVHF := '';
    ELSE
      sp := HistoryStr( VHF_HIST_ID, 0 );
      IF sp # NIL THEN
        Copy( AktualnyVHF, sp^ );
      END;
    END;
    Tytul^.SetData( AktualnyVHF );
  END LoadVHF;

  PROCEDURE Zapisz;
  VAR
    s : ARRAY[0..127] OF CHAR;

    PROCEDURE TextI( il : PIntInputLine; Entry : ARRAY OF CHAR );
    BEGIN
      il^.TInputLine.GetData( s );
      WritePrivateProfileString( AktualnyVHF,
                                 Entry,
                                 s,
                                 VHF_LIST );
     END TextI;

    PROCEDURE TextR( il : PRealInputLine; Entry : ARRAY OF CHAR );
    BEGIN
      il^.TInputLine.GetData( s );
      WritePrivateProfileString( AktualnyVHF,
                                 Entry,
                                 s,
                                 VHF_LIST );
     END TextR;

  VAR
    i, j : CARDINAL;
    fr   : LONGREAL;
    str  : ARRAY[0..20] OF CHAR;
  BEGIN
(*    Tytul^.GetData( AktualnyVHF );*)
    WHILE AktualnyVHF[0] = ' ' DO
      Str.Delete( AktualnyVHF, 0, 1 );
    END;
    IF AktualnyVHF[0] = 0C THEN
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
    NoweVHF;
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
      GetPrivateProfileString( AktualnyVHF,
                               Entry,
                               "00",
                               s,
                               VHF_LIST );
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
      GetPrivateProfileString( AktualnyVHF,
                               Entry,
                               "00",
                               s,
                               VHF_LIST );
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
(*    Tytul^.GetData( AktualnyVHF );*)
    IF AktualnyVHF[0] = 0C THEN
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
    GetPrivateProfileString( AktualnyVHF,
                             "Identyfikator",
                             "***",
                             str,
                             VHF_LIST );
  END Odczytaj;

  PROCEDURE ResetValue( VAR s : ARRAY OF CHAR );
  BEGIN
    Zapisz;
    Copy( AktualnyVHF, s );
    Odczytaj;
  END ResetValue;

  VIRTUAL PROCEDURE Done;
  VAR
    s : ARRAY[0..1] OF CHAR;
    i : INTEGER;
  BEGIN
    DEC( LockCnt );
    s[0] := 0C;
    Tytul^.GetData( AktualnyVHF );
    ResetValue( s );
    EnableCommand( cmVHFdatabase );
    FOR i := 0 TO VAL( INTEGER, HistoryCount( VHF_HIST_ID ))-1 DO
      HistoryDelete( VHF_HIST_ID, HistoryStr( VHF_HIST_ID, 0 )^ );
    END;
    TDialog.Done;
  END Done;

BEGIN
  AktualnyVHF[0] := 0C;
END VHFD;







 


PROCEDURE VHFdata( g : PGroup );
VAR
  d : PVHFD;
BEGIN
  NEW( d );
  Desktop := g;
  WITH d^ DO
    Init;
    g^.Insert( d );
  END;
END VHFdata;

BEGIN
  p := NIL;
END VHF_data.
