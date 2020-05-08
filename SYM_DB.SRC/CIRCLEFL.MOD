IMPLEMENTATION MODULE CircleFlight;

FROM Drivers IMPORT
  EventType, EventTypes;
FROM Objects IMPORT
  TRect;
FROM Storage IMPORT
  ALLOCATE, DEALLOCATE;
FROM Views IMPORT
  ofCentered;
FROM Geo2Polar IMPORT
  PolozenieGeograficzne, KatGeo, Kat2Geo;
FROM Data IMPORT
  LatKatowy, AktualnePol, DoVoraLubRosnaceKaty;
FROM Drivers IMPORT
  EventType, EventTypes, evMessage, kbLeft, kbRight, kbCtrlLeft, kbCtrlRight;
FROM stdio IMPORT
  sprintf;
FROM Flight IMPORT
  FlightTime;
FROM Lib IMPORT
  Fill, GetTime;
FROM MATHLIB IMPORT
  M_Pi;
FROM FlightCommon IMPORT
  SubTime;


CLASS IMPLEMENTATION TCircleFlight;

  VIRTUAL PROCEDURE GetDependencyPtr():PReal;
  BEGIN
    RETURN ADR( AktualnePol.Pol2D.Kat );
  END GetDependencyPtr;


  VIRTUAL PROCEDURE HandleEvent( VAR Event : TEvent );
  VAR
    t : FlightTime;
    s : LONGCARD; (* w setnych sekundy *)
    d : LONGREAL;
  BEGIN
    TFlight.HandleEvent( Event );
    IF LotTrwa & ( evTimer IN Event.What ) THEN
      WITH t DO
        GetTime( h, m, s, _100 );
      END;
      s := SubTime( t, StartTime )+SkippedTime;
      d := LONGREAL( s )*AngVelocity/360000.0;
      AktualnePol.Pol2D.Kat := LatKatowy.pk.Kat+d;
      IF AktualnePol.Pol2D.Kat < 0.0 THEN
        AktualnePol.Pol2D.Kat := AktualnePol.Pol2D.Kat+360.0;
      ELSIF AktualnePol.Pol2D.Kat >= 360.0 THEN
        AktualnePol.Pol2D.Kat := AktualnePol.Pol2D.Kat-360.0;
      END;
      AktualizujPolozenie;
      DoVoraLubRosnaceKaty := d > 0.0
    END;
  END HandleEvent;

  VIRTUAL PROCEDURE DialogName() : PString;
  BEGIN
    RETURN ADR("VOR - okr†g");
  END DialogName;

  PROCEDURE UpdateVal;
  END UpdateVal;

BEGIN
  AngVelocity := LatKatowy.Predkosc/LatKatowy.pk.Odleglosc*M_Pi/180.0*3600.0; (* w stopniach na sekunde *)
END TCircleFlight;


END CircleFlight.
