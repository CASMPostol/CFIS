IMPLEMENTATION MODULE ShDlg;

FROM Views IMPORT
  PGroup, EnableCommand, DisableCommand, ofCentered, TViewState, TViewStates;
FROM Dialogs IMPORT
  TDialog;
FROM MsgBox IMPORT
  MessageBox, MsgOption, MsgOptions;
FROM Clusters IMPORT
  NewSItem, PCluster;
FROM HistList IMPORT
  HistoryAdd, HistoryStr, HistoryCount, HistoryDelete;
FROM RadioButtons IMPORT
  PRadioButtons;
FROM CheckBoxes IMPORT
  PCheckBoxes;
FROM ListBoxes IMPORT
  PListBox;
FROM StringCollections IMPORT
  PStringCollection;
FROM InputLines IMPORT
  PInputLine;
FROM Labels IMPORT
  PLabel;
FROM StaticTexts IMPORT
  PStaticText;
FROM RealInputLines IMPORT
  PRealInputLine;
FROM Drivers IMPORT
  TEvent, EventType;
FROM Buttons IMPORT
  PButton, ButtonFlag, ButtonFlags;
FROM ScrollBars IMPORT
  PScrollBar;
FROM Ini IMPORT
  WritePrivateProfileString, GetPrivateProfileString;
FROM stdio IMPORT
  sprintf, sscanf;
FROM Objects IMPORT
  TRect, PString, DisposeStr, NewStr;
FROM ShHist IMPORT
  DefineHistorySubView, HIST_ID, SetNotification;
FROM Str IMPORT
  Length, Copy;
FROM Storage IMPORT
  ALLOCATE, DEALLOCATE;
IMPORT
  Lib, ShExecute;



CONST
  DO_WYKONANIA = "Do. wyk.";
  WYKONANO     = "Zrobione";
  WYKONANO_DME = "Wyk(DME)";

CONST
  cmOrbBladA   = 213;
  cmOrbBladB   = 214;
  cmOrbZasiegA = 215;
  cmOrbZasiegB = 216;
  cmPromBladA  = 217;
  cmPromBladB  = 218;
  cmPromZasiegA= 219;
  cmPromZasiegB= 220;


TYPE
  PStartVOR = POINTER TO StartVOR;

VAR
  VorPtr : PStartVOR;

CLASS StartVOR( TDialog );

  EfektPolaryzacji : RECORD
    A, B : PStaticText;
  END;
  OrbBlad, OrbZasieg, PromBlad, PromZasieg : RECORD
    A, B : PButton;
  END;
  dme : PCheckBoxes;
  NazwaV : PStaticText;
  OdnPomOdl, OdnPomBledu, GlowOdb : PRadioButtons;
  WlkOrbZasieg, WlkOrbBlad : PRealInputLine;
  Lista : RECORD
    A, B : PListBox;
  END;
  Zawartosc : RECORD
    A, B  : PStringCollection;
  END;
  Oblot   : PInputLine;

  PROCEDURE Init;
  VIRTUAL PROCEDURE HandleEvent( VAR e : TEvent );
  PROCEDURE Update( VAR s : ARRAY OF CHAR );
  VIRTUAL PROCEDURE Done;

END StartVOR;


PROCEDURE NotifyVOR( VAR s : ARRAY OF CHAR );
BEGIN
  IF VorPtr # NIL THEN
    VorPtr^.Update( s );
  END;
END NotifyVOR;

CLASS IMPLEMENTATION StartVOR;

  PROCEDURE Init;
  CONST
    GXL = 1;
    GXR = 14;
    ZXL = GXR+2;
    ZXR = ZXL+14;
  VAR
    R : TRect;
    p : PStaticText;
    lab : PLabel;
    Scroll : PScrollBar;
    s    : ARRAY[0..63] OF CHAR;
    i, Ile : INTEGER;
  BEGIN
    DisableCommand( cmStartVOR );
    R.Assign( 0, 0, 62, 19 );
    TDialog.Init( R, "Uruchamianie procedury testowania VOR'a" );
    Options := Options + ofCentered;

    R.Assign( GXL+1, 1, GXR, 2 );
    NEW( p );
    p^.Init( R, "Gí¢wny" );
    Insert( p );

    R.Assign( ZXL+1, 1, ZXR, 2 );
    NEW( p );
    p^.Init( R, "Zapasowy" );
    Insert( p );

    R.Assign( GXL+1, 2, GXR, 3 );
    NEW( EfektPolaryzacji.A );
    EfektPolaryzacji.A^.Init( R, DO_WYKONANIA );
    Insert( EfektPolaryzacji.A );

    R.Assign( ZXL+1, 2, ZXR, 3 );
    NEW( EfektPolaryzacji.B );
    EfektPolaryzacji.B^.Init( R, DO_WYKONANIA );
    Insert( EfektPolaryzacji.B );

       R.Assign( ZXR+1, 2, ZXR+9, 3 );
       NEW( p );
       p^.Init( R, "Ef.pol." );
       Insert( p );

    R.Assign( GXL, 3, GXR, 5 );
    NEW( OrbBlad.A );
    OrbBlad.A^.Init( R, DO_WYKONANIA, cmOrbBladA, ButtonFlags{bfNormal} );
    Insert( OrbBlad.A );

    R.Assign( ZXL, 3, ZXR, 5 );
    NEW( OrbBlad.B );
    OrbBlad.B^.Init( R, DO_WYKONANIA, cmOrbBladB, ButtonFlags{bfNormal} );
    Insert( OrbBlad.B );

       R.Assign( ZXR+1, 3, ZXR+9, 5 );
       NEW( p );
       p^.Init( R, "Orbita- bíÜd" );
       Insert( p );

    R.Assign( GXL, 5, GXR, 7 );
    NEW( OrbZasieg.A );
    OrbZasieg.A^.Init( R, DO_WYKONANIA, cmOrbZasiegA, ButtonFlags{bfNormal} );
    Insert( OrbZasieg.A );

    R.Assign( ZXL, 5, ZXR, 7 );
    NEW( OrbZasieg.B );
    OrbZasieg.B^.Init( R, DO_WYKONANIA, cmOrbZasiegB, ButtonFlags{bfNormal} );
    Insert( OrbZasieg.B );

       R.Assign( ZXR+1, 5, ZXR+9, 7 );
       NEW( p );
       p^.Init( R, "Orbita- zasiëg" );
       Insert( p );

    R.Assign( GXL, 7, GXR, 9 );
    NEW( PromBlad.A );
    PromBlad.A^.Init( R, DO_WYKONANIA, cmPromBladA, ButtonFlags{bfNormal} );
    Insert( PromBlad.A );

    R.Assign( ZXL, 7, ZXR, 9 );
    NEW( PromBlad.B );
    PromBlad.B^.Init( R, DO_WYKONANIA, cmPromBladB, ButtonFlags{bfNormal} );
    Insert( PromBlad.B );

       R.Assign( ZXR+1, 7, ZXR+9, 9 );
       NEW( p );
       p^.Init( R, "Promie§-bíÜd" );
       Insert( p );

    R.Assign( GXL, 9, GXR, 11 );
    NEW( PromZasieg.A );
    PromZasieg.A^.Init( R, DO_WYKONANIA, cmPromZasiegA, ButtonFlags{bfNormal} );
    Insert( PromZasieg.A );

    R.Assign( ZXL, 9, ZXR, 11 );
    NEW( PromZasieg.B );
    PromZasieg.B^.Init( R, DO_WYKONANIA, cmPromZasiegB, ButtonFlags{bfNormal} );
    Insert( PromZasieg.B );

       R.Assign( ZXR+1, 9, ZXR+9, 11 );
       NEW( p );
       p^.Init( R, "Promie§-zasiëg" );
       Insert( p );

    R.Assign( GXL, 11, GXR, 12 );
    NEW( dme );
    dme^.Init( R, NewSItem( "Test DME", NIL ));
    Insert( dme );

    R.Assign( ZXL, 11, ZXL+7, 12 );
    NEW( p );
    p^.Init( R, "Nazwa=>" );
    Insert( p );
    R.Assign( ZXL+7, 11, 59, 12 );
    NEW( NazwaV );
    NazwaV^.Init( R, "");
    Insert( NazwaV );

    R.Assign( GXL, 13, GXR, 15 );
    NEW( GlowOdb );
    GlowOdb^.Init( R, NewSItem( "Odb. `A'", NewSItem( "Odb. `B'", NIL)));
    Insert( GlowOdb );
    R.Assign( GXL, 12, GXR, 13 );
    NEW( lab );
    lab^.Init( R, "Gí.odbiornik", GlowOdb );
    Insert( lab );

    R.Assign( GXL, 16, GXR, 18 );
    NEW( OdnPomBledu );
    OdnPomBledu^.Init( R, NewSItem( "GPS", NewSItem( "Teodolit", NIL )));
    Insert( OdnPomBledu );
    R.Assign( GXL, 15, GXR, 16 );
    NEW( lab );
    lab^.Init( R, "Odn.pom.bíëdu", OdnPomBledu );
    Insert( lab );

    R.Assign( ZXL, 15, ZXR, 18 );
    NEW( OdnPomOdl );
    OdnPomOdl^.Init( R, NewSItem( "GPS", NewSItem( "Teodolit", NewSItem( "Prëdkoûç", NIL ))));
    Insert( OdnPomOdl );
    R.Assign( ZXL, 14, ZXR, 15 );
    NEW( lab );
    lab^.Init( R, "Odn.pom.odl.", OdnPomOdl );
    Insert( lab );

    R.Assign( 40, 2, 60, 3 );
    NEW( WlkOrbBlad );
    WlkOrbBlad^.Init( R, 10, 2.0, 60.0 );
    Insert( WlkOrbBlad );
    R.Assign( 40, 1, 60, 2 );
    NEW( lab );
    lab^.Init( R, "Promie§ orb. bíëdu", WlkOrbBlad );
    Insert( lab );

    R.Assign( 40, 4, 60, 5 );
    NEW( WlkOrbZasieg );
    WlkOrbZasieg^.Init( R, 10, 2.0, 60.0 );
    Insert( WlkOrbZasieg );
    R.Assign( 40, 3, 60, 4 );
    NEW( lab );
    lab^.Init( R, "Promie§ orb.zasiëgu", WlkOrbZasieg );
    Insert( lab );

    R.Assign( 59, 6, 60, 11 );
    NEW( Scroll );
    Scroll^.Init( R );
    Insert( Scroll );
    R.Assign( 40, 6, 59, 11 );
    NEW( Lista.A );
    Lista.A^.Init( R, 1, Scroll );
    Lista.A^.NewList( Zawartosc.A );
    Insert( Lista.A );
    R.Assign( 40, 5, 60, 6 );
    NEW( lab );
    lab^.Init( R, "Pom. na gí¢wnym VOR", Lista.A );
    Insert( lab );

    R.Assign( 59, 12, 60, 18 );
    NEW( Scroll );
    Scroll^.Init( R );
    Insert( Scroll );
    R.Assign( 40, 12, 59, 18 );
    NEW( Lista.B );
    Lista.B^.Init( R, 1, Scroll );
    Lista.B^.NewList( Zawartosc.B );
    Insert( Lista.B );
    R.Assign( 40, 11, 60, 12 );
    NEW( lab );
    lab^.Init( R, "Pom. na zapas VOR", Lista.B );
    Insert( lab );

    R.Assign( ZXL, 13, ZXR+5, 14 );
    DefineHistorySubView( R, "Lista oblot¢w", ADR( SELF ), Oblot );

    GetPrivateProfileString( "Lista oblotow VOR", "Ile", "00", s, "obloty.ini" );
    VorPtr := ADR( SELF );
    Ile := 0;
    sscanf( s, "%d", ADR( Ile ));
    FOR i := 0 TO Ile -1 DO
      sprintf( s, "Oblot%d", i );
      GetPrivateProfileString( "Lista oblotow VOR", s, "", s, "obloty.ini" );
      HistoryAdd( HIST_ID, s );
      IF i = 0 THEN
        Oblot^.SetData( s );
        Update( s );
      END;
    END;
    Oblot^.SetState( TViewStates{sfDisabled}, TRUE );

    SetNotification( NotifyVOR );

  END Init;

  VIRTUAL PROCEDURE Done;
  VAR
    i : INTEGER;
    s : ARRAY[0..63] OF CHAR;
  BEGIN
    dme^.GetData( i );
    sprintf( s, "%d", i );
    WritePrivateProfileString( "VOR", "DME", s, "shell.ini" );

    OdnPomBledu^.GetData( i );
    sprintf( s, "%d", i );
    WritePrivateProfileString( "VOR", "OdniesienieDlaBledu", s, "shell.ini" );

    OdnPomOdl^.GetData( i );
    sprintf( s, "%d", i );
    WritePrivateProfileString( "VOR", "OdniesienieDlaOdleglosci", s, "shell.ini" );

    GlowOdb^.GetData( i );
    sprintf( s, "%d", i );
    WritePrivateProfileString( "VOR", "GlownyOdbiornik", s, "shell.ini" );

    FOR i := 0 TO VAL( INTEGER, HistoryCount( HIST_ID ))-1 DO
      HistoryDelete( HIST_ID, HistoryStr( HIST_ID, 0 )^ );
    END;
    EnableCommand( cmStartVOR );
    TDialog.Done;
  END Done;

  PROCEDURE Update( VAR NazwaOblotu : ARRAY OF CHAR );
  VAR
    FileName, s : ARRAY[0..128] OF CHAR;
    s1 : ARRAY [0..1] OF CHAR;
    r : LONGREAL;
    b : BITSET;

    PROCEDURE New( VAR p : PString; s : ARRAY OF CHAR );
    BEGIN
      DisposeStr( p );
      p := NewStr( s );
    END New;


    PROCEDURE NowaLista( VAR Zawartosc : PStringCollection;
                             Sel       : CHAR) : BOOLEAN;
    VAR
      i, j, k, Ile, IleObl : INTEGER;
      Tabl : ARRAY[0..30] OF INTEGER;
      Wszystkie : BOOLEAN;
    BEGIN
      Lib.Fill( ADR( Tabl ), SIZE( Tabl ), 0FFFFH );
      Ile := 0;
      GetPrivateProfileString( NazwaV^.Text^, "IloscKierunkow", "0", s, "vorlist.ini" );
      sscanf( s, "%d", ADR( Ile ));
      FOR i := 0 TO Ile-1 DO
        sprintf( s, "Kierunek%d", i );
        GetPrivateProfileString( NazwaV^.Text^, s, "", s, "vorlist.ini" );
        sscanf( s, "%d", ADR( Tabl[i] ));
      END;

      (* dopisac zdefiniowane *)

      NEW( Zawartosc );
      Zawartosc^.Init( 30, 1 );
      sprintf( s, "IloscLotow.%c", Sel );
      GetPrivateProfileString( NazwaOblotu, s, "0", s, FileName );
      sscanf( s, "%d", ADR( IleObl ));
      FOR j := 0 TO IleObl-1 DO
        sprintf( s, "Lot.%c.%d", Sel, j );
        GetPrivateProfileString( NazwaOblotu, s, "", s, FileName );
        sscanf( s, "%d", ADR( k ));
        FOR i := 0 TO Ile-1 DO
          IF Tabl[i] = k THEN
            Tabl[i] := -1;
          END;
        END;
        s[14] := 0C;
        Zawartosc^.Insert( NewStr( s ));
      END;
      Wszystkie := TRUE;
      FOR i := 0 TO Ile -1 DO
        IF Tabl[i] # 0FFFFH THEN
          sprintf( s, "%03d", Tabl[i] );
          Zawartosc^.Insert( NewStr( s ));
          Wszystkie := FALSE;
        END;
      END;
      RETURN Wszystkie;
    END NowaLista;



  BEGIN
    GetPrivateProfileString( NazwaOblotu, "Kartoteka", ".\", s, "obloty.ini" );
    IF s[Length(s)-1] = '\' THEN
      s1 := "";
    ELSE
      s1 := "\"
    END;
    sprintf( FileName, "%s%s%s", s, s1, "obloty.ini" );

    GetPrivateProfileString( NazwaOblotu, "Nazwa", "", s, FileName );
    NazwaV^.ChangeString( s );

    GetPrivateProfileString( NazwaOblotu, "EfektPolaryzacji.A", "", s, FileName );
    IF s[0] = '1' THEN
      EfektPolaryzacji.A^.ChangeString( WYKONANO );
    ELSE
      EfektPolaryzacji.A^.ChangeString( DO_WYKONANIA );
    END;

    GetPrivateProfileString( NazwaOblotu, "EfektPolaryzacji.B", "", s, FileName );
    IF s[0] = '1' THEN
      EfektPolaryzacji.B^.ChangeString( WYKONANO );
    ELSE
      EfektPolaryzacji.B^.ChangeString( DO_WYKONANIA );
    END;

    GetPrivateProfileString( NazwaOblotu, "OrbitaRozkladBledu.A", "@@", s, FileName );
    IF s[0] = "@" THEN
      New( OrbBlad.A^.Title, DO_WYKONANIA );
      GetPrivateProfileString( NazwaV^.Text^, "Orbita.Pomiarowa", "0", s, "vorlist.ini" );
    ELSE
      New( OrbBlad.A^.Title, WYKONANO );
    END;
    OrbBlad.A^.DrawView;
    sscanf( s, "%lf", ADR( r ));
    WlkOrbBlad^.SetData( r );

    GetPrivateProfileString( NazwaOblotu, "OrbitaRozkladBledu.B", "@@", s, FileName );
    IF s[0] = "@" THEN
      New( OrbBlad.B^.Title, DO_WYKONANIA );
    ELSE
      New( OrbBlad.B^.Title, WYKONANO );
    END;
    OrbBlad.B^.DrawView;

    GetPrivateProfileString( NazwaOblotu, "Orbita.Zasieg.A", "@@", s, FileName );
    IF s[0] = "@" THEN
      New( OrbZasieg.A^.Title, DO_WYKONANIA );
      GetPrivateProfileString( NazwaV^.Text^, "Orbita.Zasiegowa", "0", s, "vorlist.ini" );
    ELSE
      GetPrivateProfileString( NazwaOblotu, "Orbita.DME.A", "0", s, FileName );
      IF s[0] = '1' THEN
        New( OrbZasieg.A^.Title, WYKONANO_DME );
      ELSE
        New( OrbZasieg.A^.Title, WYKONANO );
      END;
    END;
    OrbZasieg.A^.DrawView;
    sscanf( s, "%lf", ADR( r ));
    WlkOrbZasieg^.SetData( r );

    GetPrivateProfileString( NazwaOblotu, "Orbita.Zasieg.B", "@@", s, FileName );
    IF s[0] = "@" THEN
      New( OrbZasieg.B^.Title, DO_WYKONANIA );
    ELSE
      GetPrivateProfileString( NazwaOblotu, "Orbita.DME.B", "0", s, FileName );
      IF s[0] = '1' THEN
        New( OrbZasieg.B^.Title, WYKONANO_DME );
      ELSE
        New( OrbZasieg.B^.Title, WYKONANO );
      END;
    END;
    OrbZasieg.B^.DrawView;

    IF NOT NowaLista( Zawartosc.A, "A" ) THEN
      New( PromBlad.A^.Title, DO_WYKONANIA );
    ELSE
      New( PromBlad.A^.Title, WYKONANO );
    END;
    Lista.A^.NewList( Zawartosc.A );

    IF NOT NowaLista( Zawartosc.B, "B" ) THEN
      New( PromBlad.B^.Title, DO_WYKONANIA );
    ELSE
      New( PromBlad.B^.Title, WYKONANO );
    END;
    Lista.B^.NewList( Zawartosc.B );

    GetPrivateProfileString( NazwaOblotu, "Promien.Zasieg.A", "@@", s, FileName );
    IF s[0] = "@" THEN
      New( PromZasieg.A^.Title, DO_WYKONANIA );
    ELSE
      GetPrivateProfileString( NazwaOblotu, "Promien.DME.A", "0", s, FileName );
      IF s[0] = '1' THEN
        New( PromZasieg.A^.Title, WYKONANO_DME );
      ELSE
        New( PromZasieg.A^.Title, WYKONANO );
      END;
    END;
    PromZasieg.A^.DrawView;

    GetPrivateProfileString( NazwaOblotu, "Promien.Zasieg.B", "@@", s, FileName );
    IF s[0] = "@" THEN
      New( PromZasieg.B^.Title, DO_WYKONANIA );
    ELSE
      GetPrivateProfileString( NazwaOblotu, "Promien.DME.B", "0", s, FileName );
      IF s[0] = '1' THEN
        New( PromZasieg.B^.Title, WYKONANO_DME );
      ELSE
        New( PromZasieg.B^.Title, WYKONANO );
      END;
    END;
    PromZasieg.B^.DrawView;

    GetPrivateProfileString( "VOR", "DME", "0", s, "shell.ini" );
    sscanf( s, "%d", ADR( b ));
    dme^.SetData( b );

    GetPrivateProfileString( "VOR", "OdniesienieDlaBledu", "1", s, "shell.ini" );
    sscanf( s, "%d", ADR( b ));
    OdnPomBledu^.SetData( b );

    GetPrivateProfileString( "VOR", "OdniesienieDlaOdleglosci", "1", s, "shell.ini" );
    sscanf( s, "%d", ADR( b ));
    OdnPomOdl^.SetData( b );

    GetPrivateProfileString( "VOR", "GlownyOdbiornik", "1", s, "shell.ini" );
    sscanf( s, "%d", ADR( b ));
    GlowOdb^.SetData( b );

  END Update;

  VIRTUAL PROCEDURE HandleEvent( VAR e : TEvent );
  VAR
    Prm : ARRAY [0..99] OF CHAR;
    (* znaczenie parametrow:
       1 : Nazwa oblotu
       2 : rodzaj operacji: Orb blad, Orb zasieg, Prom blad, prom zasieg,
       3 : nadajnik: 0 glowny 1 zapasowy
       4 : promien lub kierunek
       5 : (1) badanie DME
       6 : Gl odbiornik
       7 : Odn pom bledu
       8 : odn pom odleglosci
     *)

    PROCEDURE int ( p : PCluster ) : INTEGER;
    VAR
      i : INTEGER;
    BEGIN
      p^.GetData( i );
      RETURN i;
    END int;

    PROCEDURE flt( p : PRealInputLine ) : LONGREAL;
    VAR
      r : LONGREAL;
    BEGIN
      p^.GetData( r );
      RETURN r;
    END flt;

    PROCEDURE lwlk( p : PListBox ) : INTEGER;
    VAR
      i : INTEGER;
      s : ARRAY[0..19] OF CHAR;
    BEGIN
      Copy( s, PString( p^.List^.At( p^.Focused ))^ );
      sscanf( s, "%d", ADR( i ));
      RETURN i;
    END lwlk;


    PROCEDURE ExecuteExtCmd;
    VAR
      Parameter, ob : ARRAY[0..99] OF CHAR;
    BEGIN
      Oblot^.GetData( ob );
      sprintf( Parameter,
               "`%s' %s %d %d %d %d",
               ob,
               Prm,
               int( dme ),
               int( GlowOdb ),
               int( OdnPomBledu ),
               int( OdnPomOdl ));
      IF ShExecute.Exec( 'vor', Parameter, NIL ) = 0FFFFH THEN
        sprintf( Prm, "Nie moßna uruchomiç programu `VOR' z parametrami `%s'", Parameter );
        MessageBox( Prm, NIL, MsgOptions{ mfError, mfOKButton } );
      END;
    END ExecuteExtCmd;

  BEGIN
    TDialog.HandleEvent( e );
    IF evCommand IN e.What THEN
      CASE e.Command OF
      | cmOrbBladA:
          sprintf( Prm, "0 0 %lf", flt( WlkOrbBlad ) );
          ExecuteExtCmd( );
      | cmOrbBladB:
          sprintf( Prm, "0 1 %lf", flt( WlkOrbBlad ) );
          ExecuteExtCmd( );
      | cmOrbZasiegA:
          sprintf( Prm, "1 0 %lf", flt( WlkOrbBlad ) );
          ExecuteExtCmd( );
      | cmOrbZasiegB:
          sprintf( Prm, "1 1 %lf", flt( WlkOrbBlad ) );
          ExecuteExtCmd( );
      | cmPromBladA:
          sprintf( Prm, "2 0 %d", lwlk( Lista.A ) );
          ExecuteExtCmd( );
      | cmPromBladB:
          sprintf( Prm, "2 1 %d", lwlk( Lista.B ) );
          ExecuteExtCmd( );
      | cmPromZasiegA:
          sprintf( Prm, "3 0 %d", lwlk( Lista.A ) );
          ExecuteExtCmd( );
      | cmPromZasiegB:
          sprintf( Prm, "3 1 %d", lwlk( Lista.B ) );
          ExecuteExtCmd( );
      ELSE
        RETURN;
      END;
    ELSE
      RETURN;
    END;
  END HandleEvent;

BEGIN
  Zawartosc.A := NIL;
  Zawartosc.B := NIL;
END StartVOR;

PROCEDURE VOR( p : PGroup );
VAR
  d : PStartVOR;
BEGIN
  NEW( d );
  d^.Init;
  p^.Insert( d );
END VOR;

END ShDlg.
