IMPLEMENTATION MODULE DMEADFFlight;

FROM Clusters IMPORT
  NewSItem;
FROM Objects IMPORT
  TRect;
FROM Storage IMPORT
  ALLOCATE, DEALLOCATE;
FROM Views IMPORT
  ofCentered, TViewOption, TViewOptions, SelectMode, PView, TViewState,
  EnableCommand, DisableCommand;
FROM Labels IMPORT
  PLabel;
FROM Geo2Polar IMPORT
  PolozenieGeograficzne, KatGeo, Kat2Geo;
FROM Data IMPORT
  LatKatowy;
FROM Drivers IMPORT
  EventType, EventTypes, evMessage, kbLeft, kbRight, kbCtrlLeft, kbCtrlRight;
FROM stdio IMPORT
  sprintf;
FROM Lib IMPORT
  Fill, GetTime;
FROM Data IMPORT
  AktualnePol, PolozenieTeodolitu;
FROM LocCommands IMPORT
  doStart, doStop, cmEnableDisableButtons, cmStopFlight, cmStartFlight;
FROM Commands IMPORT
  cmCommandSetChanged;
FROM FlightCommon IMPORT
  GetPolozenieGs, GetPolozenieKatowe, SetGeos, SetAngle, TheodolitView,
  EnableTimer, EnableCmds, SubTime, RamkaPolozenia;
FROM Str IMPORT
  Copy;
IMPORT
  Data, Send;


CLASS IMPLEMENTATION TDMEADFFlight;


  PROCEDURE Init();
  VAR
    R : TRect;
    p : PStaticText;
    Label : PLabel;

  BEGIN
    R.Assign(0, 0, 48, 12 );
    TDialog.Init( R, DialogName()^ );
    Options := Options + ofCentered;
    INCL( EventMask, evTimer );

    R.Assign(2, 4, 18, 6 );
    NEW( CheckBox );
    CheckBox^.Init(R,
                   NewSItem('~G~PS',
                   NewSItem('~T~eodolit',
                   NIL)),
                   ADR( Data.Devices )
                  );
    Insert(CheckBox);
    R.Assign(2, 3, 18, 4);

    NEW( Label );
    Label^.Init( R, 'Urz. pom~i~arowe', CheckBox );
    Insert( Label );

    RamkaPolozenia( ADR(SELF), 1 );
    GetPolozenieGs( ADR(SELF), 3, CurrGeoPos );
    GetPolozenieKatowe( ADR(SELF), 2, CurrAnglePos, FALSE );
    GetPolozenieKatowe( ADR(SELF), 5, TheodolitPos, TRUE );

    R.Assign( 10, 7, 47, 9 );
    NEW( AGC );
    InitAGC( R, FALSE );
    R.Assign( 1, 7, 10, 8 );
    InitLabel( R, FALSE );

    R.Assign( 10, 9, 47, 11 );
    NEW( Wysokosc );
    InitAGC( R, TRUE );
    R.Assign( 1, 9, 10, 10 );
    InitLabel( R, TRUE );

    AktualnePol.Pol2D := LatKatowy.pk;
    AktualnePol.Wysokosc := Data.Height;
    AGC^.Select( );
    SetIniData();
    AddInit;
    AktualizujPolozenie;
    EnableTimer( ADR( SELF ), TRUE );
    EnableCmds( ADR(SELF), FALSE );
    DisableCommand( cmStopFlight );
    EnableCommand( cmStartFlight );
  END Init;

  PROCEDURE SetIniData();
  VAR
    _r : LONGREAL;
  BEGIN
    CheckBox^.SetData(Data.Devices);
(*    Height^.SetData( Data.Var2Ref );*)
  END SetIniData;

  VIRTUAL PROCEDURE HandleEvent( VAR Event : TEvent );
  VAR
    e        : TEvent;
    SkipTime : FlightTime;
  BEGIN
    TDialog.HandleEvent( Event );
    IF evCommand IN Event.What THEN
      CASE Event.Command OF
      | cmEnableDisableButtons:
          EnableDisableButtons();
      | doStart:
          Send.Leci( TRUE );
          LotTrwa := TRUE;
          WITH StartTime DO
            GetTime( h, m, s, _100 );
          END;
          DisableCommand( cmStartFlight );
          EnableCommand( cmStopFlight );
      | doStop:
          Send.Leci( FALSE );
          IF LotTrwa THEN
            WITH SkipTime DO
              GetTime( h, m, s, _100 );
            END;
            SkippedTime := SkippedTime + SubTime( SkipTime, StartTime );
          END;
          LotTrwa := FALSE;
          DisableCommand( cmStopFlight );
          EnableCommand( cmStartFlight );
      ELSE
        RETURN;
      END;
      ClearEvent( Event );
    ELSIF evBroadcast IN Event.What THEN
      IF Event.Command = cmCommandSetChanged THEN
        Fill( ADR( e ), SIZE( e ), 0 );
        e.What := EventTypes{ evCommand };
        e.Command := cmEnableDisableButtons;
        PutEvent( e );
      END;
    END;
  END HandleEvent;


  VIRTUAL PROCEDURE DialogName() : PString;
  (* generic *)
  BEGIN
    RETURN ADR( "Generic Dialog" );
  END DialogName;

  VIRTUAL PROCEDURE Done;
  BEGIN
    EnableTimer( ADR( SELF ), FALSE );
    TDialog.Done;
    EnableCmds( ADR(SELF), TRUE );
  END Done;

  PROCEDURE AktualizujPolozenie;

  VAR
    _r : LONGREAL;
  BEGIN
    SetGeos( CurrGeoPos,    AktualnePol.Pol2D );
    SetAngle( CurrAnglePos, AktualnePol.Pol2D, FALSE );
    SetAngle( TheodolitPos, TheodolitView( AktualnePol.Pol2D ), TRUE );
    WITH Wysokosc^ DO
      _r := Update( Indep^ );
      SetData( _r );
    END;
    WITH AGC^ DO
      _r := Update( Indep^ );
      SetData( _r );
    END;
  END AktualizujPolozenie;

  VIRTUAL PROCEDURE EnableDisableButtons;
  VAR
    p : PView;
  BEGIN
    p := Current;
    SetCurrent( Wysokosc, LeaveSelect );
    SetCurrent( AGC, LeaveSelect );
    Current := NIL;
    SetCurrent( p,   EnterSelect );
  END EnableDisableButtons;

  VIRTUAL PROCEDURE InitLabel( VAR R : TRect; Wys : BOOLEAN );
  END InitLabel;

  VIRTUAL PROCEDURE InitAGC( VAR R : TRect; Wys : BOOLEAN );
  END InitAGC;

  VIRTUAL PROCEDURE AddInit();
  END AddInit;

BEGIN
  Fill( ADR( CurrGeoPos ), SIZE ( CurrGeoPos ), 0 );
  Fill( ADR( CurrAnglePos ), SIZE( CurrAnglePos ), 0 );
  Fill( ADR( TheodolitPos ), SIZE( TheodolitPos ), 0 );
  LotTrwa := FALSE;
  WITH StartTime DO
    GetTime( h, m, s, _100 );
  END;
  SkippedTime := 0;
END TDMEADFFlight;


END DMEADFFlight.
