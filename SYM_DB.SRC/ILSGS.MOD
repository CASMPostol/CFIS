IMPLEMENTATION MODULE ILSGS;

FROM Drivers IMPORT
  EventType, EventTypes;
FROM Objects IMPORT
  TRect;
FROM Storage IMPORT
  ALLOCATE, DEALLOCATE;
FROM Views IMPORT
  ofCentered, TViewState;
FROM Geo2Polar IMPORT
  PolozenieGeograficzne, KatGeo, Kat2Geo;
FROM Data IMPORT
  LatKatowy, AktualnePol, DoVoraLubRosnaceKaty;
FROM Drivers IMPORT
  EventType, EventTypes, evMessage, kbLeft, kbRight, kbCtrlLeft, kbCtrlRight;
FROM Lib IMPORT
  Fill, GetTime;
FROM Labels IMPORT
  PLabel;
FROM FlightCommon IMPORT
  FlightTime, SubTime, GetGS, OnTheGround, Angle360;
FROM MATHLIB IMPORT
  Tan, M_Pi;
FROM FC IMPORT
  Copy, BadTeodolitSetup;
IMPORT
  Data;

CLASS IMPLEMENTATION TGSVFlight;


  VIRTUAL PROCEDURE HandleEvent( VAR Event : TEvent );
  VAR
    t : FlightTime;
    s : LONGCARD; (* w setnych sekundy *)
    d, q : LONGREAL;
  BEGIN
    TILSFlight.HandleEvent( Event );
    IF LotTrwa & ( evTimer IN Event.What ) THEN
      WITH t DO
        GetTime( h, m, s, _100 );
      END;
      s := SubTime( t, StartTime )+SkippedTime;
      d := LONGREAL( s )*LatKatowy.Predkosc/360000.0;
      q := AktualnePol.Pol2D.Odleglosc;
      AktualnePol.Pol2D.Odleglosc := LatKatowy.pk.Odleglosc-d;
      AktualnePol.Wysokosc := AktualnePol.Pol2D.Odleglosc*
                              Tan( GetGS(AktualnePol.Pol2D.Odleglosc)*M_Pi/180.0 );
      IF AktualnePol.Wysokosc <= 0.0 THEN
        AktualnePol.Wysokosc := 0.0;
        IF ABS(AktualnePol.Pol2D.Odleglosc) > Data.PoczatekPasa THEN
          LotTrwa := FALSE;
          OnTheGround;
        END;
      END;
      DoVoraLubRosnaceKaty := AktualnePol.Pol2D.Odleglosc < q;
      AktualizujPolozenie;
    END;
  END HandleEvent;

  VIRTUAL PROCEDURE AddLocGs();
  VAR
    R : TRect;
    Label : PLabel;
  BEGIN
    R.Assign( 10, 7, 47, 9 );
    NEW( AGC.LOC_GS );
    AGC.LOC_GS^.Init( R,
                      12,
                      0.0,
                      10.0,
                      ADR(Data.AGC_GS_Akt),
                      "",
                      ADR( AktualnePol.Pol2D.Odleglosc ));
    Insert( AGC.LOC_GS );
    AGC.LOC_GS^.StringOrReal( Data.AGC_GS );
    R.Assign( 2, 7, 10, 8 );
    NEW( Label );
    Label^.Init( R, " GS.~A~GC", AGC.LOC_GS );
    Insert( Label );
  END AddLocGs;

  VIRTUAL PROCEDURE DialogName() : PString;
  BEGIN
    RETURN ADR("˜cie§ka - Profil A");
  END DialogName;

  VIRTUAL PROCEDURE InsertDeviation( VAR R : TRect );
  BEGIN
    NEW( Deviation );
    Deviation^.Init( R,
                     12,
                     -400.0,
                     +400.0,
                     ADR( Data.DevGS_Akt ),
                     "",
(*                     ADR(Data.DevGSPathV),*)
                     ADR( AktualnePol.Pol2D.Odleglosc) );
    Insert( Deviation );
    Deviation^.StringOrReal( Data.DEV_GS );
  END InsertDeviation;

  VIRTUAL PROCEDURE InsertDeviationLabel( VAR R : TRect );
  VAR
    Label : PLabel;
  BEGIN
    NEW( Label );
    Label^.Init( R, " GS.~D~EV", Deviation );
    Insert( Label );
  END InsertDeviationLabel;

  VIRTUAL PROCEDURE Done;
  BEGIN
    IF AGC.LOC_GS^.FileName # NIL THEN
      Copy( Data.AGC_GS, AGC.LOC_GS^.FileName^ );
    ELSE
      Data.AGC_GS := "";
    END;
    IF Deviation^.FileName # NIL THEN
      Copy( Data.DEV_GS, Deviation^.FileName^ );
    ELSE
      Data.DEV_GS := "";
    END;
    TILSFlight.Done;
  END Done;

  VIRTUAL PROCEDURE DistOffset():LONGREAL;
  BEGIN
    RETURN Data.PoczatekPasa;
  END DistOffset;

BEGIN
  AktualnePol.Wysokosc := AktualnePol.Pol2D.Odleglosc*
                          Tan( GetGS(AktualnePol.Pol2D.Odleglosc)*M_Pi/180.0 );
END TGSVFlight;

CLASS IMPLEMENTATION TGSHFlight;


  PROCEDURE Init();
  VAR
    k : LONGREAL;
  BEGIN
    TILSFlight.Init;
    k := Angle360( Data.KierunekPasa - Data.PolozenieTeodolitu.Kat );
    IF (k # 180.0) & ( Data.PolozenieTeodolitu.Odleglosc # 0.0 ) THEN
      BadTeodolitSetup;
    END;
  END Init;

  VIRTUAL PROCEDURE LotPoziomy():BOOLEAN;
  BEGIN
    RETURN TRUE;
  END LotPoziomy;

  VIRTUAL PROCEDURE HandleEvent( VAR Event : TEvent );
  VAR
    t : FlightTime;
    s : LONGCARD; (* w setnych sekundy *)
    d, q : LONGREAL;
  BEGIN
    TILSFlight.HandleEvent( Event );
    IF LotTrwa & ( evTimer IN Event.What ) THEN
      WITH t DO
        GetTime( h, m, s, _100 );
      END;
      s := SubTime( t, StartTime )+SkippedTime;
      d := LONGREAL( s )*LatKatowy.Predkosc/360000.0;
      q := AktualnePol.Pol2D.Odleglosc;
      AktualnePol.Pol2D.Odleglosc := LatKatowy.pk.Odleglosc-d;
      AktualnePol.Wysokosc := AktualnePol.Pol2D.Odleglosc*
                              Tan( GetGS(AktualnePol.Pol2D.Odleglosc)*M_Pi/180.0 );
      IF AktualnePol.Wysokosc <= 0.0 THEN
        LotTrwa := FALSE;
        OnTheGround;
      END;
      DoVoraLubRosnaceKaty := AktualnePol.Pol2D.Odleglosc < q;
      AktualizujPolozenie;
    END;
  END HandleEvent;

  VIRTUAL PROCEDURE DialogName() : PString;
  BEGIN
    RETURN ADR("Kierunek - profil A");
  END DialogName;

  VIRTUAL PROCEDURE InsertDeviation( VAR R : TRect );
  BEGIN
    NEW( Deviation );
    Deviation^.Init( R,
                     12,
                     -400.0,
                     +400.0,
                     ADR(Data.DevLOC_Akt ),
                     "",
(*                     ADR(Data.DevGSPathH),*)
                     ADR( AktualnePol.Pol2D.Odleglosc) );
    Insert( Deviation );
    Deviation^.StringOrReal( Data.DEV_LOC );
  END InsertDeviation;

  VIRTUAL PROCEDURE InsertDeviationLabel( VAR R : TRect );
  VAR
    Label : PLabel;
  BEGIN
    NEW( Label );
    Label^.Init( R, "LOC.~D~EV", Deviation );
    Insert( Label );
  END InsertDeviationLabel;

  VIRTUAL PROCEDURE AddLocGs();
  VAR
    R : TRect;
    Label : PLabel;
  BEGIN
    R.Assign( 10, 7, 47, 9 );
    NEW( AGC.LOC_GS );
    AGC.LOC_GS^.Init( R,
                      12,
                      0.0,
                      10.0,
                      ADR(Data.AGC_VOR_LOC_Akt),
                      "",
                      ADR( AktualnePol.Pol2D.Odleglosc ));
    Insert( AGC.LOC_GS );
    AGC.LOC_GS^.StringOrReal( Data.AGC_LOC );
    R.Assign( 2, 7, 10, 8 );
    NEW( Label );
    Label^.Init( R, "~L~OC.AGC", AGC.LOC_GS );
    Insert( Label );
  END AddLocGs;

  VIRTUAL PROCEDURE Done;
  BEGIN
    IF AGC.LOC_GS^.FileName # NIL THEN
      Copy( Data.AGC_LOC, AGC.LOC_GS^.FileName^ );
    ELSE
      Data.AGC_LOC := "";
    END;
    IF Deviation^.FileName # NIL THEN
      Copy( Data.DEV_LOC, Deviation^.FileName^ );
    ELSE
      Data.DEV_LOC := "";
    END;
    TILSFlight.Done;
  END Done;

BEGIN
END TGSHFlight;



END ILSGS.
