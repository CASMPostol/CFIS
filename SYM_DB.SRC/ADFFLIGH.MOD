IMPLEMENTATION MODULE ADFFlight;


FROM Drivers IMPORT
  EventType, EventTypes;
FROM Objects IMPORT
  TRect;
FROM Storage IMPORT
  ALLOCATE, DEALLOCATE;
FROM Views IMPORT
  ofCentered;
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
IMPORT
  Data;


VAR
  AngVelocity : LONGREAL;

CLASS IMPLEMENTATION TADFFlight;


  VIRTUAL PROCEDURE HandleEvent( VAR Event : TEvent );
  VAR
    t : FlightTime;
    s : LONGCARD; (* w setnych sekundy *)
    d : LONGREAL;
  BEGIN
    TDMEADFFlight.HandleEvent( Event );
    IF LotTrwa & ( evTimer IN Event.What ) THEN
      WITH t DO
        GetTime( h, m, s, _100 );
      END;
      s := SubTime( t, StartTime )+SkippedTime;
      d := LONGREAL( s )*AngVelocity/360000.0;
      AktualnePol.Pol2D.Kat := LatKatowy.pk.Kat+d;
      IF AktualnePol.Pol2D.Kat < 0.0 THEN
        AktualnePol.Pol2D.Kat := AktualnePol.Pol2D.Kat+360.0;
      END;
      Data.DoVoraLubRosnaceKaty := d >= 0.0;
      AktualizujPolozenie;
    END;
  END HandleEvent;

  VIRTUAL PROCEDURE DialogName() : PString;
  BEGIN
    RETURN ADR("ADF");
  END DialogName;

  VIRTUAL PROCEDURE Done;
  BEGIN
    IF AGC^.FileName # NIL THEN
      Copy( Data.AGC_ADF, AGC^.FileName^ );
    ELSE
      Data.AGC_DME := "";
    END;
    IF Wysokosc^.FileName # NIL THEN
      Copy( Data.DEV_ADF, Wysokosc^.FileName^ );
    ELSE
      Data.DEV_ADF := "";
    END;
    TDMEADFFlight.Done;
  END Done;

  VIRTUAL PROCEDURE InitAGC( VAR R : TRect; Wys : BOOLEAN );
  BEGIN
    IF Wys THEN
      Wysokosc^.Init( R, 12, 0.0, 400.0,
                      ADR( Data.DevADF_Akt ),
                      "",
                      ADR( Data.WidokZTeodolitu.Azymut ));
      Wysokosc^.StringOrReal( Data.DEV_ADF );
      Insert( Wysokosc );
    ELSE
      AGC^.Init( R, 12, 0.0, 10.0,
                 ADR(Data.AGC_ADF_Akt),
                 "",
                 ADR( AktualnePol.Pol2D.Kat ));
      Insert( AGC );
      AGC^.StringOrReal( Data.AGC_ADF );
    END;
  END InitAGC;

  VIRTUAL PROCEDURE InitLabel( VAR R : TRect; Wys : BOOLEAN );
  VAR
    l : PLabel;
  BEGIN
    NEW( l );
    IF Wys THEN
      l^.Init( R, "    De~v~", Wysokosc );
    ELSE
      l^.Init( R, "A~D~F.AGC", AGC );
    END;
    Insert( l );
  END InitLabel;

BEGIN
  AngVelocity := LatKatowy.Predkosc/LatKatowy.pk.Odleglosc*M_Pi/180.0*3600.0; (* w stopniach na sekunde *)
END TADFFlight;


END ADFFlight.
