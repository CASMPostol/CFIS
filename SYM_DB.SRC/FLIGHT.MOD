IMPLEMENTATION MODULE Flight;

FROM Clusters IMPORT
  NewSItem;
FROM Objects IMPORT
  TRect;
FROM Storage IMPORT
  ALLOCATE, DEALLOCATE;
FROM Views IMPORT
  ofCentered, TViewOption, TViewOptions, SelectMode, PView, TViewState,
  DisableCommand, EnableCommand;
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



INLINE PROCEDURE Sqr( x : LONGREAL ) : LONGREAL;
BEGIN
  RETURN x*x;
END Sqr;

CLASS IMPLEMENTATION TFlight;


  PROCEDURE Init();
  VAR
    R : TRect;
    p : PStaticText;
    Label : PLabel;

  BEGIN
    R.Assign(0, 0, 48, 18 );
    TDialog.Init( R, DialogName()^ );
    Options := Options + ofCentered;
    INCL( EventMask, evTimer );

    R.Assign(2, 4, 18, 6);
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
    AGC^.Init( R, 12, 0.0, 10.0,
               ADR(Data.AGC_VOR_LOC_Akt),
               "",
               ADR( AktualnePol.Pol2D.Odleglosc ));
    Insert( AGC );
    AGC^.StringOrReal( Data.AGC_VOR );
    R.Assign( 2, 7, 10, 8 );
    NEW( Label );
    Label^.Init( R, "VOR.~A~GC", AGC );
    Insert( Label );

    R.Assign( 10, 9, 47, 11 );
    NEW( VOR );
    VOR^.Init( R, 12, -180.0, 180.0, ADR( Data.Omnibearing ), "", GetDependencyPtr() );
    Insert( VOR );
    VOR^.StringOrReal( Data.VOR_Omnibearing );
    R.Assign( 2, 9, 10, 10 );
    NEW( Label );
    Label^.Init( R, "+Na~m~iar", VOR );
    Insert( Label );

    R.Assign( 10, 11, 47, 13 );
    NEW( Var );
    Var^.Init( R, 12, 0.0, 10.0, ADR( Data.Var ) );
    Insert( Var );
    R.Assign( 2, 11, 10, 12 );
    NEW( Label );
    Label^.Init( R, "   ~V~ar", Var );
    Insert( Label );

    R.Assign( 10, 13, 47, 15 );
    NEW( Ref );
    Ref^.Init( R, 12, 0.0, 10.0, ADR( Data.Ref ) );
    Insert( Ref );
    R.Assign( 2, 13, 10, 14 );
    NEW( Label );
    Label^.Init( R, "   ~R~ef", Ref );
    Insert( Label );

    R.Assign( 10, 15, 47, 17 );
    NEW( Subcar );
    Subcar^.Init( R, 12, 0.0, 10.0, ADR( Data.Subcar ) );
    Insert( Subcar );
    R.Assign( 2, 15, 10, 16 );
    NEW( Label );
    Label^.Init( R, "~S~ubcar", Subcar );
    Insert( Label );

    AktualnePol.Pol2D := LatKatowy.pk;
    AktualnePol.Wysokosc := Data.Height;
(*    EnableDisableButtons;*)
    AGC^.Select( );
    SetIniData();
    AktualizujPolozenie;
    EnableTimer( ADR( SELF ), TRUE );
    EnableCmds( ADR( SELF), FALSE );
    DisableCommand( cmStopFlight );
    EnableCommand( cmStartFlight );
  END Init;

  VIRTUAL PROCEDURE GetDependencyPtr():PReal;
  BEGIN
    RETURN NIL;
  END GetDependencyPtr;

  PROCEDURE SetIniData();
  VAR
    _r : LONGREAL;
  BEGIN
    CheckBox^.SetData(Data.Devices);
(*
    Data.AGC_Akt := Data.AGC*AktualnePol.Odleglosc/100.0;
    AGC^.SetData( Data.AGC_Akt );
*)
    VOR^.SetData( Data.Omnibearing );

  END SetIniData;

  PROCEDURE EnableDisableButtons;
  VAR
    p : PView;
  BEGIN
    p := Current;
    SetCurrent( Var, LeaveSelect );
    SetCurrent( Ref, LeaveSelect );
    SetCurrent( Subcar, LeaveSelect );
    SetCurrent( VOR, LeaveSelect );
    SetCurrent( AGC, LeaveSelect );
    Current := NIL;
    SetCurrent( p,   EnterSelect );
  END EnableDisableButtons;

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
    IF AGC^.FileName # NIL THEN
      Copy( Data.AGC_VOR, AGC^.FileName^ );
    ELSE
      Data.AGC_VOR := "";
    END;
    IF VOR^.FileName # NIL THEN
      Copy( Data.VOR_Omnibearing, VOR^.FileName^ );
    ELSE
      Data.VOR_Omnibearing := "";
    END;
    EnableTimer( ADR( SELF ), FALSE );
    TDialog.Done;
    EnableCmds( ADR( SELF), TRUE );
  END Done;

  PROCEDURE AktualizujPolozenie;

  VAR
    _r : LONGREAL;
  BEGIN
    SetGeos( CurrGeoPos,    AktualnePol.Pol2D );
    SetAngle( CurrAnglePos, AktualnePol.Pol2D, FALSE );
    SetAngle( TheodolitPos, TheodolitView( AktualnePol.Pol2D ), TRUE );
(*
    AGC^.Update;
    Data.AGC_Akt := Data.AGC-Data.AGC*AktualnePol.Odleglosc/100.0;
*)
    WITH AGC^ DO
      _r := Update( Indep^ );
      SetData( _r );
    END;
    WITH VOR^ DO
      _r := Update( Indep^ );
      SetData( _r );
    END;
  END AktualizujPolozenie;


BEGIN
  Fill( ADR( CurrGeoPos ), SIZE ( CurrGeoPos ), 0 );
  Fill( ADR( CurrAnglePos ), SIZE( CurrAnglePos ), 0 );
  Fill( ADR( TheodolitPos ), SIZE( TheodolitPos ), 0 );
  LotTrwa := FALSE;
  WITH StartTime DO
    GetTime( h, m, s, _100 );
  END;
  SkippedTime := 0;
END TFlight;

END Flight.
