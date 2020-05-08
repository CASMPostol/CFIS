IMPLEMENTATION MODULE Setup;

FROM Lib IMPORT
  Fill;
FROM CheckBoxes IMPORT
  PCheckBoxes;
FROM RadioButtons IMPORT
  PRadioButtons;
FROM Clusters IMPORT
  NewSItem;
FROM Labels IMPORT
  PLabel;
FROM Buttons IMPORT
  PButton, ButtonFlag, ButtonFlags;
FROM InputLines IMPORT
  PInputLine, TInputLine ;
FROM IntInputLines IMPORT
  PIntInputLine, TIntInputLine;
FROM RealInputLines IMPORT
  PRealInputLine, TRealInputLine;
FROM StaticTexts IMPORT
  PStaticText;
FROM Geo2Polar IMPORT
  PolozenieGeograficzne, PolozenieKatowe, Geo2Kat, Kat2Geo,
  PolozenieOdniesienia;
(*
FROM Editors IMPORT
  TEditor;
*)
FROM History IMPORT
  THistoryViewer;
(*
FROM StdDlg IMPORT
  TFileDialog;
*)
FROM Views IMPORT
  PView, TViewStates, TViewState, ofCentered;
FROM Objects IMPORT
  TRect, String;
FROM Storage IMPORT
  ALLOCATE, DEALLOCATE;
FROM stdio IMPORT
  sprintf;
FROM Commands IMPORT
  cmOK, cmCancel;

  PROCEDURE GPS_Opt_Dialog( VAR Data : ARRAY OF BYTE ):PDialog;
  VAR
    Button : PButton;
    RadioButton : PRadioButtons;
    InputLine : PInputLine;
    Label : PLabel;
    Dialog: PDialog;
    R: TRect;
    C: CARDINAL;
  BEGIN
    R.Assign(20, 6, 60, 19);
    NEW( Dialog );
    WITH Dialog^ DO
      Init(R, 'GPS Setup');
      R.Assign(3, 3, 18, 8);

      NEW( RadioButton );
      RadioButton^.Init(R,
                        NewSItem('COM~1~',
                        NewSItem('COM~2~',
                        NewSItem('COM~3~',
                        NewSItem('COM~4~',
                        NewSItem('~F~ile',
                        NIL)))))
                       );
      Insert(RadioButton);

      R.Assign(3, 2, 18, 3);
      NEW( Label );
      Label^.Init(R, 'Output To', RadioButton);
      Insert( Label );

      R.Assign(3, 10, 37, 11);
      NEW( InputLine );
      InputLine^.Init(R, 128);
      Insert(InputLine);

      R.Assign(2, 9, 24, 10);
      NEW( Label );
      Label^.Init(R, 'Output file name', InputLine);
      Insert( Label );

      R.Assign(20, 4, 36, 6);
      NEW( Button );
      Button^.Init(R, '~O~k', cmOK, ButtonFlags{ bfDefault });
      Insert( Button );

      R.Assign(20, 6, 36, 8);
      NEW( Button );
      Button^.Init(R, 'Cancel', cmCancel, ButtonFlags{ bfNormal });
      Insert( Button );

      SetData(Data);
    END;
    RETURN Dialog;
  END GPS_Opt_Dialog;

  PROCEDURE ILS_Opt_Dialog( VAR Data : ARRAY OF BYTE ):PDialog;
  BEGIN
    RETURN NIL;
  END ILS_Opt_Dialog;


  TYPE
    PGeoIntInputLine = POINTER TO GeoIntInputLine;
    PAngleInputLine = POINTER TO AngleRealInputLine;

    GeoInput = RECORD
      Stopnie, Minuty, Setne : PGeoIntInputLine;
    END;
    GeoViews =  RECORD
      Szerokosc, Dlugosc : GeoInput;
    END;
    AngleViews = RECORD
      Odleglosc, Kat : PAngleInputLine;
    END;

  CLASS GeoIntInputLine( TIntInputLine );
    RelStruct : AngleViews;
    OwnStruct : GeoViews;
    PROCEDURE SetConn( VAR g : GeoViews; VAR a : AngleViews );
    VIRTUAL PROCEDURE SetState( AState : TViewStates; Enable : BOOLEAN );
  END GeoIntInputLine;

  CLASS AngleRealInputLine( TRealInputLine );
    RelStruct : GeoViews;
    OwnStruct : AngleViews;
    PROCEDURE SetConn( VAR a : AngleViews; VAR g : GeoViews );
    VIRTUAL PROCEDURE SetState( AState : TViewStates; Enable : BOOLEAN );
  END AngleRealInputLine;

  CLASS IMPLEMENTATION GeoIntInputLine;

    PROCEDURE SetConn( VAR g : GeoViews; VAR a : AngleViews );
    BEGIN
      RelStruct := a;
      OwnStruct := g;
    END SetConn;

    VIRTUAL PROCEDURE SetState( AState : TViewStates; Enable : BOOLEAN );
    VAR
      pg : PolozenieGeograficzne;
      pk : PolozenieKatowe;
    BEGIN
      IF ( sfFocused IN AState ) & NOT Enable & ( sfFocused IN State ) THEN
        TIntInputLine.SetState( AState, Enable );
        IF OwnStruct.Szerokosc.Stopnie # NIL THEN
          OwnStruct.Szerokosc.Stopnie^.GetData( pg.Szerokosc.Stopnie );
          OwnStruct.Szerokosc.Minuty^.GetData( pg.Szerokosc.Minuty );
          OwnStruct.Szerokosc.Setne^.GetData( pg.Szerokosc.Setne );
          OwnStruct.Dlugosc.Stopnie^.GetData( pg.Dlugosc.Stopnie );
          OwnStruct.Dlugosc.Minuty^.GetData( pg.Dlugosc.Minuty );
          OwnStruct.Dlugosc.Setne^.GetData( pg.Dlugosc.Setne );
          Geo2Kat( pg, pk );
          RelStruct.Odleglosc^.SetData( pk.Odleglosc );
          RelStruct.Kat^.SetData( pk.Kat );
        END;
      ELSE
        TIntInputLine.SetState( AState, Enable );
      END;
    END SetState;

  BEGIN
    Fill( ADR( RelStruct ), SIZE( RelStruct ), 0 );
    Fill( ADR( OwnStruct ), SIZE( OwnStruct ), 0 );
  END GeoIntInputLine;

  CLASS IMPLEMENTATION AngleRealInputLine;

    PROCEDURE SetConn( VAR a : AngleViews; VAR g : GeoViews );
    BEGIN
      RelStruct := g;
      OwnStruct := a;
    END SetConn;

    VIRTUAL PROCEDURE SetState( AState : TViewStates; Enable : BOOLEAN );
    VAR
      pg : PolozenieGeograficzne;
      pk : PolozenieKatowe;
    BEGIN
      IF ( sfFocused IN AState ) & NOT Enable & ( sfFocused IN State ) THEN
        TRealInputLine.SetState( AState, Enable );
        IF OwnStruct.Odleglosc # NIL THEN
          OwnStruct.Odleglosc^.GetData( pk.Odleglosc );
          OwnStruct.Kat^.GetData( pk.Kat );
          Kat2Geo( pk, pg );
          RelStruct.Szerokosc.Stopnie^.SetData( pg.Szerokosc.Stopnie );
          RelStruct.Szerokosc.Minuty^.SetData( pg.Szerokosc.Minuty );
          RelStruct.Szerokosc.Setne^.SetData( pg.Szerokosc.Setne );
          RelStruct.Dlugosc.Stopnie^.SetData( pg.Dlugosc.Stopnie );
          RelStruct.Dlugosc.Minuty^.SetData( pg.Dlugosc.Minuty );
          RelStruct.Dlugosc.Setne^.SetData( pg.Dlugosc.Setne );
        END;
      ELSE
        TRealInputLine.SetState( AState, Enable );
      END;
    END SetState;

  BEGIN
    Fill( ADR( RelStruct ), SIZE( RelStruct ), 0 );
    Fill( ADR( OwnStruct ), SIZE( OwnStruct ), 0 );
  END AngleRealInputLine;


  PROCEDURE PolozenieGeo(     Dialog    : PDialog;
                              x, Y      : CARDINAL;
                              Lab       : ARRAY OF CHAR;
                              Side      : ARRAY OF CHAR;
                              Szerokosc : BOOLEAN;
                          VAR g         : GeoInput);
  VAR
    R : TRect;
    Label : PLabel;
    StaticText : PStaticText;
  BEGIN
    WITH Dialog^ DO
      R.Assign(x, Y, x+6, Y+1 );
      NEW( g.Stopnie );
      IF Szerokosc THEN
        g.Stopnie^.Init(R, 4, -90, 90 );
      ELSE
        g.Stopnie^.Init(R, 4, -180, 180 );
      END;
      Insert(g.Stopnie);

      R.Assign(x, Y-1, x+11, Y);
      NEW( Label );
      Label^.Init(R, Lab, g.Stopnie );
      Insert( Label );

      R.Assign(x+6, Y, x+7, Y+1 );
      NEW( StaticText );
      StaticText^.Init(R, '¯'+0C);
      Insert(StaticText);

      R.Assign(x+7, Y, x+12, Y+1 );
      NEW( g.Minuty );
      g.Minuty^.Init(R, 3, 0, 59);
      Insert( g.Minuty );

      R.Assign(x+12, Y, x+13, Y+1 );
      NEW( StaticText );
      StaticText^.Init(R, "'"+0C);
      Insert(StaticText);

      R.Assign(x+13, Y, x+18, Y+1 );
      NEW( g.Setne );
      g.Setne^.Init(R, 3, 0, 99);
      Insert( g.Setne );

      R.Assign(x+18, Y, x+19, Y+1 );
      NEW( StaticText );
      StaticText^.Init(R, Side);
      Insert(StaticText);

    END;
  END PolozenieGeo;

  PROCEDURE InsertOriginPoint( d : PDialog; VAR r : TRect );
  VAR
    s : PStaticText;
    t : String;
    pg : PolozenieGeograficzne;
  BEGIN
    pg := PolozenieOdniesienia();
    sprintf( t,
             3C+"Punkt odniesienia znajduje sië w miejscu o wsp¢írzëdnych %d¯%d'%dN i %d¯%d'%dE",
             pg.Szerokosc.Stopnie,
             pg.Szerokosc.Minuty,
             pg.Szerokosc.Setne,
             pg.Dlugosc.Stopnie,
             pg.Dlugosc.Minuty,
             pg.Dlugosc.Setne );
    NEW( s );
    s^.Init( r, t );
    d^.Insert( s );
  END InsertOriginPoint;


  PROCEDURE VOR_Dialog(VAR Data : ARRAY OF BYTE ):PDialog;
  CONST
    Y = 3;
  VAR
    Angle : AngleViews;
    Geo   : GeoViews;
    Button : PButton;
    StaticText  : PStaticText;
(*    InputLine : PIntInputLine;*)
    Label : PLabel;
    Dialog: PDialog;
    R: TRect;
    C: CARDINAL;



  VAR
    RealInpLine : PRealInputLine;
  BEGIN
    R.Assign( 10, 3, 54, 20);
    NEW( Dialog );
    WITH Dialog^ DO
      Options := Options + ofCentered;
      Init(R, 'VOR - parametry poczÜtkowe');
      PolozenieGeo( Dialog, 2, Y, "~S~zerokoûç", "N"+0C, TRUE, Geo.Szerokosc );
      PolozenieGeo( Dialog, 22, Y, "~D~íugoûç", "E"+0C, FALSE, Geo.Dlugosc );

      R.Assign( 2, Y+3, 20, Y+4 );
      NEW( Angle.Odleglosc );
      Angle.Odleglosc^.Init( R, 13, 0.0, 60.0 );
      Insert( Angle.Odleglosc );
      R.Assign( 2, Y+2, 20, Y+3);
      NEW( Label );
      Label^.Init(R, "Od~l~egíoûç [Mm]", Angle.Odleglosc );
      Insert( Label );

      R.Assign( 22, Y+3, 40, Y+4 );
      NEW( Angle.Kat );
      Angle.Kat^.Init( R, 13, 0.0, 359.999999999999999999999999 );
      Insert( Angle.Kat );
      R.Assign( 22, Y+2, 40, Y+3);
      NEW( Label );
      Label^.Init(R, "~K~Üt [¯]", Angle.Kat );
      Insert( Label );

      R.Assign( 22, Y+5, 40, Y+6 );
      NEW( RealInpLine );
      RealInpLine^.Init( R, 13, -1000.0, 1000.0 );
      Insert( RealInpLine );
      R.Assign( 5, Y+5, 21, Y+6);
      NEW( Label );
      Label^.Init(R, "~P~rëdkoûç [Mm/h]", RealInpLine);
      Insert( Label );

      R.Assign( 22, Y+6, 40, Y+7 );
      NEW( RealInpLine );
      RealInpLine^.Init( R, 13, 0.0, 10000.0 );
      Insert( RealInpLine );
      R.Assign( 6, Y+6, 21, Y+7);
      NEW( Label );
      Label^.Init(R, "W~y~sokoûç [m]", RealInpLine);
      Insert( Label );

      R.Assign(1, Y+8, 21, Y+10);
      NEW( Button );
      Button^.Init(R, '~O~k', cmOK, ButtonFlags{ bfDefault });
      Insert( Button );

      R.Assign(21, Y+8, 41, Y+10);
      NEW( Button );
      Button^.Init(R, 'WYJóCIE', cmCancel, ButtonFlags{ bfNormal });
      Insert( Button );

      R.Assign( 2, Y+10, 42, Y+12 );
      InsertOriginPoint( Dialog, R );

      SetData(Data);

      Geo.Szerokosc.Stopnie^.SetConn( Geo, Angle );
      Geo.Szerokosc.Minuty^.SetConn( Geo, Angle );
      Geo.Szerokosc.Setne^.SetConn( Geo, Angle );
      Geo.Dlugosc.Stopnie^.SetConn( Geo, Angle );
      Geo.Dlugosc.Minuty^.SetConn( Geo, Angle );
      Geo.Dlugosc.Setne^.SetConn( Geo, Angle );
      Angle.Odleglosc^.SetConn( Angle, Geo );
      Angle.Kat^.SetConn( Angle, Geo );
    END;
    RETURN Dialog;
  END VOR_Dialog;

  PROCEDURE ILS_Dialog  (VAR Data : ARRAY OF BYTE ):PDialog;
  CONST
    Y = 2;
  VAR
    Angle : AngleViews;
    Geo   : GeoViews;
    Button : PButton;
    StaticText  : PStaticText;
    Label : PLabel;
    Dialog: PDialog;
    R: TRect;
    C: CARDINAL;
    RealInpLine : PRealInputLine;




    PROCEDURE Marker( y : CARDINAL; IdStr : ARRAY OF CHAR );
    BEGIN
      R.Assign( 22, y, 35, y+1 );
      NEW( RealInpLine );
      RealInpLine^.Init( R, 13, 0.0, 100.0);
      Dialog^.Insert( RealInpLine );
      R.Assign( 2, y, 20, y+1);
      NEW( Label );
      Label^.Init(R, IdStr, RealInpLine );
      Dialog^.Insert( Label );

      R.Assign( 35, y, 37, y+1);
      NEW( StaticText );
      StaticText^.Init(R, "Mm" );
      Dialog^.Insert( StaticText );

      R.Assign( 37, y, 50, y+1 );
      NEW( RealInpLine );
      RealInpLine^.Init( R, 13, 0.0, 179.999999999999999999999);
      Dialog^.Insert( RealInpLine );
      R.Assign( 50, y, 51, y+1);
      NEW( StaticText );
      StaticText^.Init(R, "¯" );
      Dialog^.Insert( StaticText );

    END Marker;

  BEGIN
    R.Assign( 0, 0, 54, 21);
    NEW( Dialog );
    WITH Dialog^ DO
      Options := Options + ofCentered;
      Init(R, 'ILS - parametry poczÜtkowe');
      PolozenieGeo( Dialog, 2, Y, "~S~zerokoûç", "N"+0C, TRUE, Geo.Szerokosc );
      PolozenieGeo( Dialog, 22, Y, "~D~íugoûç", "E"+0C, FALSE, Geo.Dlugosc );

      R.Assign( 2, Y+2, 20, Y+3 );
      NEW( Angle.Odleglosc );
      Angle.Odleglosc^.Init( R, 13, 0.0, 90.0 );
      Insert( Angle.Odleglosc );
      R.Assign( 2, Y+1, 20, Y+2);
      NEW( Label );
      Label^.Init(R, "Od~l~egíoûç [Mm]", Angle.Odleglosc );
      Insert( Label );

      R.Assign( 22, Y+2, 40, Y+3 );
      NEW( Angle.Kat );
      Angle.Kat^.Init( R, 13, 0.0, 359.999999999999999999999999 );
      Insert( Angle.Kat );
      R.Assign( 22, Y+1, 40, Y+2);
      NEW( Label );
      Label^.Init(R, "~K~Üt [¯]", Angle.Kat );
      Insert( Label );

      R.Assign( 22, Y+4, 40, Y+5 );
      NEW( RealInpLine );
      RealInpLine^.Init( R, 13, -1000.0, 1000.0 );
      Insert( RealInpLine );
      R.Assign( 5, Y+4, 21, Y+5);
      NEW( Label );
      Label^.Init(R, "~P~rëdkoûç [Mm/h]", RealInpLine);
      Insert( Label );

      R.Assign( 22, Y+5, 40, Y+6 );
      NEW( RealInpLine );
      RealInpLine^.Init( R, 13, 0.0, 10000.0 );
      Insert( RealInpLine );
      R.Assign( 8, Y+5, 21, Y+6);
      NEW( Label );
      Label^.Init(R, "W~y~sokoûç [m]", RealInpLine);
      Insert( Label );

      Marker( Y+7, "~W~ewnëtrzny Marker" );
      Marker( Y+8, "  ò~r~odkowy Marker" );
      Marker( Y+9, "~Z~ewnëtrzny Marker" );

      R.Assign( 22, Y+11, 40, Y+12 );
      NEW( RealInpLine );
      RealInpLine^.Init( R, 13, 0.0, 90.0 );
      Insert( RealInpLine );
      R.Assign( 7, Y+11, 21, Y+12);
      NEW( Label );
      Label^.Init(R, "Strefa ~3~ [¯]", RealInpLine);
      Insert( Label );

      R.Assign( 22, Y+12, 40, Y+13 );
      NEW( RealInpLine );
      RealInpLine^.Init( R, 13, 0.0, 90.0 );
      Insert( RealInpLine );
      R.Assign( 7, Y+12, 21, Y+13);
      NEW( Label );
      Label^.Init(R, "Strefa ~2~ [¯]", RealInpLine);
      Insert( Label );

      R.Assign( 22, Y+13, 40, Y+14 );
      NEW( RealInpLine );
      RealInpLine^.Init( R, 13, 0.0, 90.0 );
      Insert( RealInpLine );
      R.Assign( 7, Y+13, 21, Y+14);
      NEW( Label );
      Label^.Init(R, "Strefa ~1~ [¯]", RealInpLine);
      Insert( Label );

      R.Assign( 22, Y+14, 40, Y+15 );
      NEW( RealInpLine );
      RealInpLine^.Init( R, 13, 0.0, 359.99999999999999999999999999 );
      Insert( RealInpLine );
      R.Assign( 2, Y+14, 21, Y+15);
      NEW( Label );
      Label^.Init(R, "Kierunek p~a~sa [¯]", RealInpLine);
      Insert( Label );

      R.Assign( 41, Y, 51, Y+6);
      NEW( Button );
      Button^.Init(R, '~O~k', cmOK, ButtonFlags{ bfDefault });
      Insert( Button );

      R.Assign( 41, Y+11, 51, Y+16);
      NEW( Button );
      Button^.Init(R, 'WYJóCIE', cmCancel, ButtonFlags{ bfNormal });
      Insert( Button );

      R.Assign( 2, Y+16, 52, Y+18 );
      InsertOriginPoint( Dialog, R );

      SetData(Data);

      Geo.Szerokosc.Stopnie^.SetConn( Geo, Angle );
      Geo.Szerokosc.Minuty^.SetConn( Geo, Angle );
      Geo.Szerokosc.Setne^.SetConn( Geo, Angle );
      Geo.Dlugosc.Stopnie^.SetConn( Geo, Angle );
      Geo.Dlugosc.Minuty^.SetConn( Geo, Angle );
      Geo.Dlugosc.Setne^.SetConn( Geo, Angle );
      Angle.Odleglosc^.SetConn( Angle, Geo );
      Angle.Kat^.SetConn( Angle, Geo );
    END;
    RETURN Dialog;
  END ILS_Dialog;


END Setup.
