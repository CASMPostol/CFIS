IMPLEMENTATION MODULE ILSFlight;

FROM Clusters IMPORT
  NewSItem;
FROM Objects IMPORT
  TRect;
FROM Storage IMPORT
  ALLOCATE, DEALLOCATE;
FROM Views IMPORT
  ofCentered, TViewOption, TViewOptions, SelectMode, PView, TViewState,
  TViewStates, EnableCommand, DisableCommand;
FROM Labels IMPORT
  PLabel;
FROM Geo2Polar IMPORT
  PolozenieGeograficzne, KatGeo, Kat2Geo;
FROM Drivers IMPORT
  EventType, EventTypes, evMessage, kbLeft, kbRight, kbCtrlLeft, kbCtrlRight;
FROM stdio IMPORT
  sprintf;
FROM Lib IMPORT
  Fill, GetTime, Sound, NoSound;
FROM Data IMPORT
  AktualnePol, PolozenieTeodolitu;
FROM FlightCommon IMPORT
  GetPolozenieGs, GetPolozenieKatowe, SetGeos, SetAngle, TheodolitView,
  EnableTimer, EnableCmds, SubTime, Leci, RamkaPolozenia;
FROM LocCommands IMPORT
  doStart, doStop, cmEnableDisableButtons, cmStopFlight, cmStartFlight;
FROM Commands IMPORT
  cmCommandSetChanged;
FROM Str IMPORT
  Copy;
FROM MATHLIB IMPORT
  Tan, M_Pi;
IMPORT
  Data;




CLASS IMPLEMENTATION TILSFlight;


  PROCEDURE Init;
  VAR
    R : TRect;
    Label : PLabel;
    ps : PStaticText;
  BEGIN
    R.Assign(0, 0, 65, 16 );
    TDialog.Init( R, DialogName()^ );
    Options := Options + ofCentered;
    INCL( EventMask, evTimer );

    R.Assign(2, 4, 18, 6);
    NEW( CheckBoxDev );
    CheckBoxDev^.Init(R,
                      NewSItem('~G~PS',
                      NewSItem('~T~eodolit',
                      NIL)),
                      ADR( Data.Devices )
                     );
    Insert(CheckBoxDev);
    R.Assign(2, 3, 18, 4);

    NEW( Label );
    Label^.Init( R, 'Urz. pom~i~arowe', CheckBoxDev );
    Insert( Label );

    RamkaPolozenia( ADR(SELF), 1 );
    GetPolozenieGs( ADR( SELF ), 3, CurrGeoPos );
    GetPolozenieKatowe( ADR( SELF ), 2, CurrAnglePos, FALSE );
    GetPolozenieKatowe( ADR( SELF ), 5, TheodolitPos, TRUE );

    AddLocGs;

    R.Assign( 10, 9, 47, 11 );
    NEW( AGC.Mark );
    AGC.Mark^.Init( R,
                    12, 0.0, 10.0,
                    ADR(Data.AGC_Mark_Akt),
                    "",
(*                    ADR( Data.AGC_Mark_Org ),*)
                    ADR( AktualnePol.Pol2D.Odleglosc ));
    Insert( AGC.Mark );
    AGC.Mark^.StringOrReal( Data.AGC_Mark );
    R.Assign( 2, 9, 10, 10 );
    NEW( Label );
    Label^.Init( R, "~M~KR.AGC", AGC.Mark );
    Insert( Label );

    R.Assign( 10, 11, 47, 13 );
    InsertDeviation( R );
    R.Assign( 2, 11, 10, 12 );
    InsertDeviationLabel( R );

    R.Assign( 10, 13, 47, 15 );
    NEW( ProcentMod );
    ProcentMod^.Init( R, 12, 0.0, 10.0,
                      ADR( Data.MOD_LOC_Akt ),
                      "",
                      ADR( AktualnePol.Pol2D.Odleglosc ));
    Insert( ProcentMod );
    ProcentMod^.StringOrReal( Data.MOD_LOC );
    R.Assign( 2, 13, 10, 14 );
    NEW( Label );
    Label^.Init( R, "M~O~D LOC", ProcentMod );
    Insert( Label );


    R.Assign(48, 3, 63, 6);
    NEW( MarkerCheckBox );
    MarkerCheckBox^.Init(R,
                         NewSItem('~W~ewn‘trzny',
                         NewSItem('˜~r~odkowy',
                         NewSItem('~Z~ewn‘trzny',
                         NIL))),
                         ADR( Data.Markers )
                        );
    Insert(MarkerCheckBox);

    R.Assign(48, 2, 63, 3);
    NEW( Label );
    Label^.Init( R, 'Mar~k~ery', MarkerCheckBox );
    Insert( Label );


    R.Assign(48, 7, 63, 12 );
    NEW( ps );
    ps^.Init( R, " ponad"+    CHR(0DH)+
                 "Wewn‘trznym ( )"+CHR(0DH)+
                 "˜rodkowym   ( )"+CHR(0DH)+
                 "Zewn‘trznym ( )"+CHR(0DH)+
                 " markerem" );
    Insert( ps );

    R.Assign( 61, 8, 62, 9 );
    NEW( MarkerZone.Inner );
    MarkerZone.Inner^.Init( R, '-' );
    Insert( MarkerZone.Inner );

    R.Assign( 61, 9, 62, 10 );
    NEW( MarkerZone.Middle );
    MarkerZone.Middle^.Init( R, '-' );
    Insert( MarkerZone.Middle);

    R.Assign( 61, 10, 62, 11 );
    NEW( MarkerZone.Outer );
    MarkerZone.Outer^.Init( R, '-' );
    Insert( MarkerZone.Outer );

    AktualnePol.Pol2D := Data.LatKatowy.pk;
    AktualnePol.Wysokosc := Data.Height;
    AGC.LOC_GS^.Select( );
    SetIniData();
    AktualizujPolozenie;
    EnableTimer( ADR( SELF ), TRUE );
    EnableCmds( ADR(SELF), FALSE );
    DisableCommand( cmStopFlight );
    EnableCommand( cmStartFlight );
  END Init;

  VIRTUAL PROCEDURE InsertDeviation( VAR R : TRect );
  END InsertDeviation;

  VIRTUAL PROCEDURE InsertDeviationLabel( VAR R : TRect );
  END InsertDeviationLabel;

  VIRTUAL PROCEDURE DialogName():PString;
  BEGIN
    RETURN ADR( "Any ILS" );
  END DialogName;

  PROCEDURE EnableDisableButtons;
  VAR
    p : PView;
  BEGIN
    p := Current;
    SetCurrent( AGC.LOC_GS, LeaveSelect );
    SetCurrent( AGC.Mark,  LeaveSelect );
    SetCurrent( Deviation, LeaveSelect );
    SetCurrent( AGC.LOC_GS, LeaveSelect );
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
          Leci( TRUE );
          LotTrwa := TRUE;
          WITH StartTime DO
            GetTime( h, m, s, _100 );
          END;
          DisableCommand( cmStartFlight );
          EnableCommand( cmStopFlight );
      | doStop:
          Leci( FALSE );
          IF LotTrwa THEN
            WITH SkipTime DO
              GetTime( h, m, s, _100 );
            END;
            SkippedTime := SkippedTime + SubTime( SkipTime, StartTime );
          END;
          LotTrwa := FALSE;
          NoSound;
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

  VIRTUAL PROCEDURE LotPoziomy():BOOLEAN;
  BEGIN
    RETURN TRUE;
  END LotPoziomy;


  VIRTUAL PROCEDURE Done;
  BEGIN
    IF AGC.Mark^.FileName # NIL THEN
      Copy( Data.AGC_Mark, AGC.Mark^.FileName^ );
    ELSE
      Data.AGC_Mark := "";
    END;
    NoSound;
    EnableTimer( ADR( SELF ), FALSE );
    TDialog.Done;
    EnableCmds( ADR(SELF), TRUE );
  END Done;

  PROCEDURE SetIniData;
  END SetIniData;

  VIRTUAL PROCEDURE DistOffset():LONGREAL;
  BEGIN
    RETURN 0.0;
  END DistOffset;

  PROCEDURE AktualizujPolozenie;
  VAR
    JakikolwiekMarker : BOOLEAN;
    s                 : ARRAY [0..255] OF CHAR;

    PROCEDURE UpdateAGC( p : PAGC );
    VAR
      _r : LONGREAL;
    BEGIN
      _r := p^.Update( p^.Indep^ );
      p^.SetData( _r );
    END UpdateAGC;

    PROCEDURE UpdateMarker(     p    : PStaticText;
                            VAR m    : Data.MarkerType;
                                Freq : CARDINAL;
                                ms   : Data.MarkerSet );
    VAR
      r : LONGREAL;
    BEGIN
      IF LotPoziomy() THEN
        r := Data.Height;
      ELSE
        r := Data.AktualnePol.Wysokosc;
      END;
      r := r*Tan((m.KatWiazki/2.0)*M_Pi/180.0);
      IF (Data.AktualnePol.Pol2D.Odleglosc+DistOffset() > m.Odleglosc-r ) &
         (Data.AktualnePol.Pol2D.Odleglosc+DistOffset() < m.Odleglosc+r )
      THEN
        JakikolwiekMarker := TRUE;
        IF ms*Data.Markers = Data.MarkerSet{} THEN
          p^.ChangeString( '+' );
        ELSE
          Sound( Freq );
          p^.ChangeString( '*' );
          Data.CurMarkers := ms;
        END;
      ELSE
        IF (ms*Data.Markers # Data.MarkerSet{}) & (p^.Text^[0] = '*') THEN
          NoSound;
          Data.CurMarkers := Data.MarkerSet{};
        END;
        p^.ChangeString( '-' );
      END;
    END UpdateMarker;

    PROCEDURE EnableAGC( agc : PAGC; Enable : BOOLEAN );
    BEGIN
(*
      WITH agc^ DO
        IF (sfDisabled IN State) = Enable THEN
          SetState( TViewStates{sfDisabled}, Enable );
          Inp^.SetState( TViewStates{sfDisabled}, Enable );
        END;
      END;
*)
      IF (sfDisabled IN agc^.State) = Enable THEN
        agc^.SetState( TViewStates{sfDisabled}, Enable );
        agc^.Inp^.SetState( TViewStates{sfDisabled}, Enable );
      END;
    END EnableAGC;

  VAR
    p2d : PolozenieKatowe;
  BEGIN
    SetGeos( CurrGeoPos,    AktualnePol.Pol2D );
    SetAngle( CurrAnglePos, AktualnePol.Pol2D, FALSE );
    p2d := TheodolitView( AktualnePol.Pol2D );
    p2d.Kat := p2d.Kat - Data.KierunekPasa ;
    SetAngle( TheodolitPos, p2d, TRUE );
    UpdateAGC( Deviation );
    UpdateAGC( AGC.LOC_GS );
    JakikolwiekMarker := FALSE;
    UpdateMarker( MarkerZone.Inner,  Data.InnerMarker,  3000, Data.MarkerSet{ Data.mInner } );
    UpdateMarker( MarkerZone.Middle, Data.MiddleMarker, 1000, Data.MarkerSet{ Data.mMiddle } );
    UpdateMarker( MarkerZone.Outer,  Data.OuterMarker,  0400, Data.MarkerSet{ Data.mOuter } );

    IF JakikolwiekMarker OR (AGC.Mark^.FileName # NIL) THEN
      EnableAGC( AGC.Mark, TRUE );
      UpdateAGC( AGC.Mark );
    ELSE
      IF NOT( sfFocused IN AGC.Mark^.State) THEN
        s := '< brak >';
        AGC.Mark^.Inp^.TInputLine.SetData( s );
      END;
      EnableAGC( AGC.Mark, FALSE );
    END;
  END AktualizujPolozenie;

  VIRTUAL PROCEDURE AddLocGs;
  END AddLocGs;

BEGIN
  Fill( ADR( CurrGeoPos ), SIZE ( CurrGeoPos ), 0 );
  Fill( ADR( CurrAnglePos ), SIZE( CurrAnglePos ), 0 );
  Fill( ADR( TheodolitPos ), SIZE( TheodolitPos ), 0 );
  LotTrwa := FALSE;
  WITH StartTime DO
    GetTime( h, m, s, _100 );
  END;
  SkippedTime := 0;
END TILSFlight;


END ILSFlight.