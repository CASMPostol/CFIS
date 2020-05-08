IMPLEMENTATION MODULE Glos;

FROM Dialogs IMPORT
  TDialog;
FROM StaticTexts IMPORT
  PStaticText;
FROM RealInputLines IMPORT
  PSpeedBoxReal, TSpeedBoxReal, PReal;
FROM Drivers IMPORT
  TEvent, EventType, EventTypes;
FROM Objects IMPORT
  PString, TRect;
FROM Geo2Polar IMPORT
  PolozenieKatowe;
FROM FileLines IMPORT
  TFileLine, PFileLine;
FROM FlightUtil IMPORT
  GeoPtrs, AnglePtr, PChkBox, PAGC, FlightTime;
FROM Labels IMPORT
  PLabel;
FROM Views IMPORT
  ofCentered, SelectMode, DisableCommand, EnableCommand;
FROM Storage IMPORT
  ALLOCATE;
FROM Clusters IMPORT
  NewSItem;
FROM FlightCommon IMPORT
  GetPolozenieGs, GetPolozenieKatowe, SetGeos, SetAngle, TheodolitView,
  EnableTimer, EnableCmds, SubTime, RamkaPolozenia, Angle360;
FROM LocCommands IMPORT
  doStart, doStop, cmStopFlight, cmStartFlight;
FROM Lib IMPORT
  GetTime, Fill;
FROM Commands IMPORT
  cmCommandSetChanged;
FROM Str IMPORT
  Copy;
IMPORT
  Data, Send;



CLASS TGlosDlg( TDialog );

  Agc           : PAGC;
  CurrGeoPos    : GeoPtrs;
  CurrAnglePos  : AnglePtr;
  TheodolitPos  : AnglePtr;
  CheckBox      : PChkBox;
  LotTrwa       : BOOLEAN;

  StartTime     : FlightTime;
  SkippedTime   : LONGCARD;

  PROCEDURE Init;
  VIRTUAL PROCEDURE HandleEvent( VAR Event : TEvent );
  PROCEDURE AktualizujPolozenie;
  VIRTUAL PROCEDURE Done;

END TGlosDlg;

CLASS IMPLEMENTATION TGlosDlg;

  PROCEDURE Init();
  VAR
    R : TRect;
    p : PStaticText;
    Label : PLabel;

  BEGIN
    R.Assign(0, 0, 48, 10 );
    TDialog.Init( R, "Testowanie odbiornika akustycznego" );
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
    NEW( Agc );
    Agc^.Init( R, 12, 0.0, 10.0,
               ADR(Data.AGC_Comm_Akt),
               "",
               ADR( Data.AktualnePol.Pol2D.Odleglosc ));
    Insert( Agc );
    Agc^.StringOrReal( Data.AGC_COMM );
    R.Assign( 1, 7, 10, 8 );
    NEW( Label );
    Label^.Init( R, "COMM.~A~GC", Agc );
    Insert( Label );

    Data.AktualnePol.Pol2D := Data.LatKatowy.pk;
    Data.AktualnePol.Wysokosc := Data.Height;
(*    EnableDisableButtons;*)
    Agc^.Select( );
    CheckBox^.SetData(Data.Devices);
    AktualizujPolozenie;
    EnableTimer( ADR( SELF ), TRUE );
    EnableCmds( ADR( SELF), FALSE );
    SetCurrent( CheckBox, EnterSelect );
    DisableCommand( cmStopFlight );
    EnableCommand( cmStartFlight );
  END Init;

  VIRTUAL PROCEDURE HandleEvent( VAR Event : TEvent );
  VAR
    e        : TEvent;
    SkipTime : FlightTime;
  VAR
    t : FlightTime;
    s : LONGCARD; (* w setnych sekundy *)
    d, q : LONGREAL;
  BEGIN
    TDialog.HandleEvent( Event );
    IF evCommand IN Event.What THEN
      CASE Event.Command OF
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
(*
    ELSIF evBroadcast IN Event.What THEN
      IF Event.Command = cmCommandSetChanged THEN
        Fill( ADR( e ), SIZE( e ), 0 );
        e.What := EventTypes{ evCommand };
        e.Command := cmEnableDisableButtons;
        PutEvent( e );
      END;
*)
    ELSIF LotTrwa & (evTimer IN Event.What) THEN
      WITH t DO
        GetTime( h, m, s, _100 );
      END;
      s := SubTime( t, StartTime )+SkippedTime;
      d := LONGREAL( s )*Data.LatKatowy.Predkosc/360000.0;
      q := Data.AktualnePol.Pol2D.Odleglosc;
      Data.AktualnePol.Pol2D.Odleglosc := Data.LatKatowy.pk.Odleglosc-d;
      IF Data.AktualnePol.Pol2D.Odleglosc < 0.0 THEN
        Data.AktualnePol.Pol2D.Odleglosc := -Data.AktualnePol.Pol2D.Odleglosc;
        Data.AktualnePol.Pol2D.Kat := Angle360( Data.LatKatowy.pk.Kat-180.0 );
      END;
      Data.DoVoraLubRosnaceKaty := Data.AktualnePol.Pol2D.Odleglosc < q;
      AktualizujPolozenie;
    END;
  END HandleEvent;

  VIRTUAL PROCEDURE Done;
  BEGIN
    IF Agc^.FileName # NIL THEN
      Copy( Data.AGC_COMM, Agc^.FileName^ );
    ELSE
      Data.AGC_COMM := "";
    END;
    EnableTimer( ADR( SELF ), FALSE );
    EnableCmds( ADR( SELF), TRUE );
    TDialog.Done;
  END Done;

  PROCEDURE AktualizujPolozenie;

  VAR
    _r : LONGREAL;
  BEGIN
    SetGeos( CurrGeoPos,    Data.AktualnePol.Pol2D );
    SetAngle( CurrAnglePos, Data.AktualnePol.Pol2D, FALSE );
    SetAngle( TheodolitPos, TheodolitView( Data.AktualnePol.Pol2D ), TRUE );
    WITH Agc^ DO
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
END TGlosDlg;

TYPE
  PGlosDlg = POINTER TO TGlosDlg;


PROCEDURE GlosDlg( Desktop : PGroup );
VAR
  d : PGlosDlg;
  i : INTEGER;
BEGIN
  NEW(d);
  d^.Init;
  Desktop^.Insert(d);
  EnableTimer( d, TRUE );
END GlosDlg;

END Glos.
