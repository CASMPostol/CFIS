IMPLEMENTATION MODULE AngleFlight;

FROM Drivers IMPORT
  EventType, EventTypes;
FROM Objects IMPORT
  TRect;
FROM Storage IMPORT
  ALLOCATE, DEALLOCATE;
FROM Views IMPORT
  ofCentered, Message;
FROM Geo2Polar IMPORT
  PolozenieGeograficzne, KatGeo, Kat2Geo;
FROM Data IMPORT
  LatKatowy, AktualnePol, DoVoraLubRosnaceKaty;
FROM Drivers IMPORT
  EventType, EventTypes, evMessage, kbLeft, kbRight, kbCtrlLeft, kbCtrlRight;
FROM stdio IMPORT
  sprintf;
FROM Lib IMPORT
  Fill, GetTime;
FROM Flight IMPORT
  FlightTime;
FROM FlightCommon IMPORT
  SubTime;
IMPORT
  Msgs;
FROM LocCommands IMPORT
  doStart, doStop, cmEnableDisableButtons;


CLASS IMPLEMENTATION TAngleFlight;


  VIRTUAL PROCEDURE GetDependencyPtr():PReal;
  BEGIN
    RETURN ADR( AktualnePol.Pol2D.Odleglosc );
  END GetDependencyPtr;


  VIRTUAL PROCEDURE HandleEvent( VAR Event : TEvent );
  VAR
    t : FlightTime;
    s : LONGCARD; (* w setnych sekundy *)
    d, q : LONGREAL;
  BEGIN
    TFlight.HandleEvent( Event );
    IF LotTrwa & ( evTimer IN Event.What ) THEN
      WITH t DO
        GetTime( h, m, s, _100 );
      END;
      s := SubTime( t, StartTime )+SkippedTime;
      d := LONGREAL( s )*LatKatowy.Predkosc/360000.0;
      q := AktualnePol.Pol2D.Odleglosc;
      AktualnePol.Pol2D.Odleglosc := LatKatowy.pk.Odleglosc-d;
      IF AktualnePol.Pol2D.Odleglosc < 0.0 THEN
        AktualnePol.Pol2D.Odleglosc := -AktualnePol.Pol2D.Odleglosc;
        AktualnePol.Pol2D.Kat := LatKatowy.pk.Kat-180.0;
        IF AktualnePol.Pol2D.Kat < 0.0 THEN
          AktualnePol.Pol2D.Kat := AktualnePol.Pol2D.Kat+360.0;
        END;
      END;
      DoVoraLubRosnaceKaty := AktualnePol.Pol2D.Odleglosc < q;
      AktualizujPolozenie;
      IF AktualnePol.Pol2D.Odleglosc > 100.0 THEN
        Msgs.Poza_100NM;
        Message( ADR( SELF ), EventTypes{evCommand}, doStop, NIL );
      END;
    END;
  END HandleEvent;

  VIRTUAL PROCEDURE DialogName() : PString;
  BEGIN
    RETURN ADR("VOR - promie¤");
  END DialogName;

  PROCEDURE UpdateVal;
  END UpdateVal;

BEGIN
END TAngleFlight;


END AngleFlight.
