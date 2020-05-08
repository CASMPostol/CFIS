IMPLEMENTATION MODULE DMEFlight;

FROM Drivers IMPORT
  EventType, EventTypes;
FROM Objects IMPORT
  TRect;
FROM Storage IMPORT
  ALLOCATE, DEALLOCATE;
FROM Views IMPORT
  ofCentered, PView, SelectMode;
FROM Labels IMPORT
  PLabel;
FROM Str IMPORT
  Copy;
FROM Geo2Polar IMPORT
  PolozenieGeograficzne, KatGeo, Kat2Geo;
FROM Data IMPORT
  LatKatowy, AktualnePol;
FROM Flight IMPORT
  FlightTime;
FROM Lib IMPORT
  Fill, GetTime;
FROM MATHLIB IMPORT
  M_Pi;
FROM FlightCommon IMPORT
  SubTime;
FROM RealInputLines IMPORT
  PSpeedBoxReal;
IMPORT
  Data;



CLASS IMPLEMENTATION TDMEFlight;


  VIRTUAL PROCEDURE HandleEvent( VAR Event : TEvent );
  VAR
    t : FlightTime;
    s : LONGCARD; (* w setnych sekundy *)
    d, q : LONGREAL;
  BEGIN
    TDMEADFFlight.HandleEvent( Event );
    IF LotTrwa & ( evTimer IN Event.What ) THEN
      WITH t DO
        GetTime( h, m, s, _100 );
      END;
      s := SubTime( t, StartTime )+SkippedTime;
      d := LONGREAL( s )*LatKatowy.Predkosc/360000.0;
      q := AktualnePol.Pol2D.Odleglosc;
      AktualnePol.Pol2D.Odleglosc := LatKatowy.pk.Odleglosc+d; (* od nadajnika *)
      IF AktualnePol.Pol2D.Odleglosc < 0.0 THEN  (* na wszelki wypadek *)
        AktualnePol.Pol2D.Odleglosc := -AktualnePol.Pol2D.Odleglosc;
        AktualnePol.Pol2D.Kat := LatKatowy.pk.Kat-180.0;
        IF AktualnePol.Pol2D.Kat < 0.0 THEN
          AktualnePol.Pol2D.Kat := AktualnePol.Pol2D.Kat+360.0;
        END;
      END;
      AktualizujPolozenie;
      Data.DoVoraLubRosnaceKaty := AktualnePol.Pol2D.Odleglosc < q;
      AktualnePol.Wysokosc := Data.WysokoscWMetrach / 1852.0;
    END;
  END HandleEvent;

  VIRTUAL PROCEDURE DialogName() : PString;
  BEGIN
    RETURN ADR("DME");
  END DialogName;

  VIRTUAL PROCEDURE Done;
  BEGIN
    IF AGC^.FileName # NIL THEN
      Copy( Data.AGC_DME, AGC^.FileName^ );
    ELSE
      Data.AGC_DME := "";
    END;
    IF Wysokosc^.FileName # NIL THEN
      Copy( Data.FWysokosc, Wysokosc^.FileName^ );
    ELSE
      Data.FWysokosc := "";
    END;
    TDMEADFFlight.Done;
  END Done;

  VIRTUAL PROCEDURE InitAGC( VAR R : TRect; Wys : BOOLEAN );
  BEGIN
    IF Wys THEN
      AktualnePol.Wysokosc := Data.Height;
      Data.WysokoscWMetrach := AktualnePol.Wysokosc * 1852.0;
      Wysokosc^.Init( R, 12, 0.0, 5000.0,
                      ADR( Data.WysokoscWMetrach ),
                      "",
                      ADR( AktualnePol.Pol2D.Odleglosc ));
      Insert( Wysokosc );
      Wysokosc^.StringOrReal( Data.FWysokosc );
    ELSE
      AGC^.Init( R, 12, 0.0, 10.0,
                 ADR(Data.AGC_DME_Akt),
                 "",
                 ADR( AktualnePol.Pol2D.Odleglosc ));
      Insert( AGC );
      AGC^.StringOrReal( Data.AGC_DME );
    END;
  END InitAGC;

  VIRTUAL PROCEDURE InitLabel( VAR R : TRect; Wys : BOOLEAN );
  VAR
    l : PLabel;
  BEGIN
    NEW( l );
    IF Wys THEN
      l^.Init( R, "~W~ysokož", Wysokosc );
    ELSE
      l^.Init( R, "D~M~E.AGC", AGC );
    END;
    Insert( l );
  END InitLabel;

  VIRTUAL PROCEDURE EnableDisableButtons;
  VAR
    p : PView;
  BEGIN
    p := Current;
    SetCurrent( Wysokosc, LeaveSelect );
    SetCurrent( AGC, LeaveSelect );
    SetCurrent( Squitter, LeaveSelect );
    SetCurrent( Replay, LeaveSelect );
    Current := NIL;
    SetCurrent( p,   EnterSelect );
  END EnableDisableButtons;

  VIRTUAL PROCEDURE AddInit();
  VAR
    R : TRect;
    l  : PLabel;
  BEGIN
    R.Assign(0, 0, 48, 16 );
    ChangeBounds( R );

    R.Assign( 10, 11, 47, 13 );
    NEW( Squitter );
    Squitter^.Init( R, 12, 0.0, 10.0, ADR( Data.Squitter_Akt ));
    Insert( Squitter );
    R.Assign( 1, 11, 10, 12 );
    NEW( l );
    l^.Init( R, "~S~quitter", Squitter );
    Insert( l );

    R.Assign( 10, 13, 47, 15 );
    NEW( Replay );
    Replay^.Init( R, 12, 0.0, 10.0, ADR( Data.Replay_Akt ));
    Insert( Replay );
    R.Assign( 1, 13, 10, 14 );
    NEW( l );
    l^.Init( R, "% ~R~eply", Replay );
    Insert( l );

  END AddInit;

BEGIN
END TDMEFlight;


END DMEFlight.
