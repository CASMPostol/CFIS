IMPLEMENTATION MODULE ODP_data;

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
  Str;


TYPE
  POORD = POINTER TO OORD;


CONST
  SEKCJA = "Lista odpowiedzialnych";
  ODP_INI = 'odp.ini';
VAR
  p : POORD;
  Desktop : PGroup;

TYPE
  Blok = RECORD
    Stopnie, Minuty, Setne : PIntInputLine;
  END;

CONST
  VOR_LIST = "Odp.ini";


CLASS OORD( TDialog );
   Zawartosc      : PStringCollection;
   Lista          : PListBox;

   PROCEDURE Init;
   PROCEDURE Zapisz;
   PROCEDURE Odczytaj;
   PROCEDURE Dodaj;
   PROCEDURE Usun;
   VIRTUAL PROCEDURE Done;
   VIRTUAL PROCEDURE HandleEvent( VAR E : TEvent );
END OORD;

CLASS IMPLEMENTATION OORD;

  PROCEDURE Init;
  VAR
    R : TRect;
    st : PStaticText;
    Scroll : PScrollBar;
    Button : PButton;

  BEGIN
    INC( LockCnt );
    DisableCommand( cmODPdatabase );
    R.Assign( 0, 0, 36, 21 );
    TDialog.Init( R, "Odpowiedzialni za pomiar" );
    Options := Options + ofCentered ;

    R.Assign( 32, 12, 33, 17 );
      NEW( Scroll );
      Scroll^.Init( R );

    R.Assign( 2, 2, 32, 17 );
      NEW( Lista );
      Lista^.Init( R, 1, Scroll );
      Lista^.NewList( Zawartosc );
      Insert( Lista );

    R.Assign( 17, 18, 33, 20 );
      NEW( Button );
      Button^.Init( R, "~U~su�", cmUsun, ButtonFlags{bfNormal} );
      Insert( Button );

    R.Assign( 2, 18, 16, 20 );
      NEW( Button );
      Button^.Init( R, "~D~odaj", cmDodaj, ButtonFlags{bfNormal} );
      Insert( Button );

    Odczytaj;
  END Init;

  PROCEDURE Dodaj;
  VAR
    Kto     : ARRAY[0..99] OF CHAR;
    R       : TRect;
    Dlg     : PDialog;
    i       : PInputLine;
    b       : PButton;
    sp      : PString;
  BEGIN
    R.Assign( 30, 12, 70, 19 );
    NEW( Dlg );
    WITH Dlg^ DO
      Init( R, "Nazwisko pracownika" );
      Options := Options + ofCentered;
      R.Assign( 2, 4, 8, 6 );
      NEW( b );
      b^.Init( R, "~O~k", cmOK, ButtonFlags{ bfDefault } );
      Insert( b );
      R.Assign( 8, 4, 18, 6 );
      NEW( b );
      b^.Init( R, "~C~ancel", cmCancel, ButtonFlags{ bfNormal } );
      Insert( b );
      R.Assign( 2, 2, 28, 3 );
      NEW( i );
      i^.Init( R, 30 );
      Insert( i );
    END;
    IF Desktop^.ExecView( Dlg ) # cmCancel THEN
      i^.GetData( Kto );
      sp := NewStr( Kto );
      Zawartosc^.Insert( sp );
      Lista^.SetRange( Zawartosc^.Count );
      Lista^.DrawView;
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
      ELSE
        RETURN;
      END;
    END;
  END HandleEvent;

  PROCEDURE Zapisz;
  VAR
    s : ARRAY[0..127] OF CHAR;


  VAR
    i    : CARDINAL;
    str  : ARRAY[0..99] OF CHAR;
  BEGIN
    sprintf( s, "%d", Zawartosc^.Count );
    WritePrivateProfileString( SEKCJA, "Ilosc", s, ODP_INI );
    IF Zawartosc^.Count > 0 THEN
      FOR i := 0 TO Zawartosc^.Count-1 DO
        sprintf( s, "Odpowiedzialny_%d", i );
        WritePrivateProfileString( SEKCJA,
                                   s,
                                   PString(Zawartosc^.At( i ))^,
                                   VOR_LIST );
      END;
    END;
    Lista^.NewList( NIL );
  END Zapisz;

  PROCEDURE Odczytaj;
  VAR
    s : ARRAY[0..127] OF CHAR;
    CalkowitaIlosc, i : INTEGER;
    ok : BOOLEAN;
    sp : PString;
  BEGIN
    GetPrivateProfileString( SEKCJA, "Ilosc", "00", s, ODP_INI );
    CalkowitaIlosc := VAL( INTEGER, StrToCard( s, 10, ok ));
    NEW( Zawartosc );
    Zawartosc^.Init( 36, 2 );
    IF NOT ok THEN
      CalkowitaIlosc := 0;
    END;
    FOR i := 0 TO CalkowitaIlosc-1 DO
      sprintf( s, "Odpowiedzialny_%d", i );
      GetPrivateProfileString( SEKCJA,
                               s,
                               "",
                               s,
                               ODP_INI );
      sp := NewStr( s );
      Zawartosc^.Insert( sp );
    END;
    Lista^.NewList( Zawartosc );
  END Odczytaj;

  VIRTUAL PROCEDURE Done;
  BEGIN
    DEC( LockCnt );
    Zapisz;
    EnableCommand( cmODPdatabase );
    TDialog.Done;
  END Done;

BEGIN
  NEW( Zawartosc );
  Zawartosc^.Init( 50, 10 );
END OORD;







 


PROCEDURE ODPdata( g : PGroup );
VAR
  d : POORD;
BEGIN
  NEW( d );
  Desktop := g;
  WITH d^ DO
    Init;
    g^.Insert( d );
  END;
END ODPdata;

BEGIN
  p := NIL;
END ODP_data.
