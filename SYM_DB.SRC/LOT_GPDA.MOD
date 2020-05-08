IMPLEMENTATION MODULE LOT_GPda;

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
FROM Warn IMPORT
  LockCnt;
FROM DB_utl IMPORT
  UtnijSpacje, CompareBezSpacji;
IMPORT
  Str, Potw;
FROM DB_Common IMPORT
  BlokGPS,SetBlockGPS,Blok;


FROM Commands IMPORT
  cmOK, cmCancel;

TYPE
  PLOTGSD = POINTER TO LOTGPS;


VAR
  p : PLOTGSD;
  
CONST
  LOT_LIST = "LotnList.ini";

TYPE
  POpt            = POINTER TO LOTGPS;

CLASS LOTGPS( TDialog );
  AktualneLotnisko: ARRAY[0..127] OF CHAR;
   GPSLOC            : BlokGPS;
   GPSGS            : BlokGPS;
   PROCEDURE Init;
   PROCEDURE Zapisz;
   PROCEDURE Odczytaj;
   VIRTUAL PROCEDURE Done;
END LOTGPS;


CLASS IMPLEMENTATION LOTGPS;

  PROCEDURE Init;
  VAR
    R : TRect;
    n : PInputLine;
    l : PLabel;
    st : PStaticText;
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
    DisableCommand( cmLOTGPSdatabase );
    R.Assign( 0, 0, 38, 12 );

    TDialog.Init( R, "Baza danych GPS" );
    Options := Options + ofCentered ;


    R.Assign( 2, 1, 15, 2 );
      NEW( st );
      st^.Init( R, "GPS LOC" );
      Insert( st );
      SetBlockGPS( SELF, GPSLOC , 2, 2);



      R.Assign( 2, 6, 15, 7 );
      NEW( st );
      st^.Init( R, "GPS GS" );
      Insert( st );
      SetBlockGPS( SELF, GPSGS , 2, 7);
    p := ADR( SELF );
     Odczytaj;

  END Init;


  PROCEDURE Zapisz;
  VAR
    s : ARRAY[0..127] OF CHAR;

    PROCEDURE TextI( il : PIntInputLine; Entry : ARRAY OF CHAR );
    BEGIN
      il^.TInputLine.GetData( s );
      WritePrivateProfileString( AktualneLotnisko,
                                 Entry,
                                 s,
                                 LOT_LIST  );
     END TextI;

    PROCEDURE TextR( il : PRealInputLine; Entry : ARRAY OF CHAR );
    BEGIN
      il^.TInputLine.GetData( s );
      WritePrivateProfileString( AktualneLotnisko,
                                 Entry,
                                 s,
                                 LOT_LIST  );
     END TextR;

  VAR
    i, j : CARDINAL;
    fr   : LONGREAL;
    str  : ARRAY[0..20] OF CHAR;
  BEGIN
(*    Copy( AktualneLotnisko, AktLotnisko );    *)
    WHILE AktualneLotnisko[0] = ' ' DO
      Str.Delete( AktualneLotnisko, 0, 1 );
    END;
    IF AktualneLotnisko[0] = 0C THEN
      RETURN;
    END;
    TextR( GPSGS.Odleglosc,     "GPSGS.Odleglosc" );
    TextR( GPSGS.Wysokosc,      "GPSGS.Wysokosc" );
    TextR( GPSGS.Kat,           "GPSGS.Kat" );
    TextR( GPSLOC.Odleglosc,   "GPSLOC.Odleglosc");
    TextR( GPSLOC.Wysokosc,    "GPSLOC.Wysokosc" );
    TextR( GPSLOC.Kat,         "GPSLOC.Kat" );

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
      GetPrivateProfileString( AktualneLotnisko,
                               Entry,
                               "00",
                               s,
                               LOT_LIST  );
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
      GetPrivateProfileString( AktualneLotnisko,
                               Entry,
                               "00",
                               s,
                               LOT_LIST  );
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
    IF AktualneLotnisko[0] = 0C THEN
      RETURN;
    END;
    TextR( GPSGS.Odleglosc,     "GPSGS.Odleglosc" );
    TextR( GPSGS.Wysokosc,      "GPSGS.Wysokosc" );
    TextR( GPSGS.Kat,           "GPSGS.Kat" );
    TextR( GPSLOC.Odleglosc,   "GPSLOC.Odleglosc");
    TextR( GPSLOC.Wysokosc,    "GPSLOC.Wysokosc" );
    TextR( GPSLOC.Kat,         "GPSLOC.Kat" );
  END Odczytaj;


  VIRTUAL PROCEDURE Done;
  VAR
    s : ARRAY[0..1] OF CHAR;
    i : INTEGER;
  BEGIN
    DEC( LockCnt );
    Zapisz;
    EnableCommand( cmLOTGPSdatabase );
    TDialog.Done;
  END Done;

BEGIN
  AktualneLotnisko[0] := 0C;
END LOTGPS;


PROCEDURE GPS_Dialog( AktLotnisko:ARRAY OF CHAR ):PDialog;


VAR
  D : POpt;
BEGIN
  NEW( D );
  WITH D^ DO
    Copy( AktualneLotnisko, AktLotnisko );  
    Init;
  END;

  RETURN D;
END GPS_Dialog;




BEGIN
  p := NIL;
END LOT_GPda.
