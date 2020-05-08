IMPLEMENTATION MODULE ILSGS1;

FROM Drivers IMPORT
  EventType, EventTypes;
FROM Objects IMPORT
  TRect;
FROM Storage IMPORT
  ALLOCATE, DEALLOCATE;
FROM Views IMPORT
  ofCentered, TViewState;
FROM Geo2Polar IMPORT
  PolozenieGeograficzne, KatGeo, Kat2Geo, PolozenieKatowe;
FROM Data IMPORT
  LatKatowy, AktualnePol, DoVoraLubRosnaceKaty;
FROM Drivers IMPORT
  EventType, EventTypes, evMessage, kbLeft, kbRight, kbCtrlLeft, kbCtrlRight;
FROM Lib IMPORT
  Fill, GetTime;
FROM Labels IMPORT
  PLabel;
FROM FlightCommon IMPORT
  FlightTime, SubTime, GetGS, Angle360, TheodolitView;
FROM MATHLIB IMPORT
  Tan, M_Pi, ATan2;
FROM FC IMPORT
  Copy, BadTeodolitSetup;
IMPORT
  Data;

VAR
  DefVal : LONGREAL;
  AngVelocity : LONGREAL;

CLASS IMPLEMENTATION TGSacrossFlight;


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

  VIRTUAL PROCEDURE HandleEvent( VAR Event : TEvent );
  VAR
    t : FlightTime;
    s : LONGCARD; (* w setnych sekundy *)
    d : LONGREAL;
    pk : PolozenieKatowe;
  BEGIN
    TILSFlight.HandleEvent( Event );
    IF LotTrwa & ( evTimer IN Event.What ) THEN
      WITH t DO
        GetTime( h, m, s, _100 );
      END;
      s := SubTime( t, StartTime )+SkippedTime;
      d := LONGREAL( s )*AngVelocity/360000.0;
      AktualnePol.Pol2D.Kat := LatKatowy.pk.Kat+d;
      AktualnePol.Pol2D.Kat := Angle360( AktualnePol.Pol2D.Kat );
      AktualnePol.Wysokosc := Data.Height;
      pk := TheodolitView( AktualnePol.Pol2D );
      DefVal := Data.KierunekPasa-pk.Kat;
      WHILE DefVal <= -180.0 DO
        DefVal := DefVal + 360.0;
      END;
      WHILE DefVal > 180.0 DO
        DefVal := DefVal - 360.0;
      END;
      DoVoraLubRosnaceKaty := d >= 0.0;
      AktualizujPolozenie;
    END;
  END HandleEvent;

  VIRTUAL PROCEDURE DialogName() : PString;
  BEGIN
    RETURN ADR("Kierunek - profil B");
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
(*                     ADR(Data.DevGSV),*)
                     ADR( DefVal ) );
    Insert( Deviation );
    Deviation^.StringOrReal( Data.DEV_LOC )
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
  AngVelocity := LatKatowy.Predkosc/LatKatowy.pk.Odleglosc*M_Pi/180.0*3600.0; (* w stopniach na sekunde *)
END TGSacrossFlight;

CLASS IMPLEMENTATION TGSalongFlight;


  VIRTUAL PROCEDURE HandleEvent( VAR Event : TEvent );
  VAR
    t : FlightTime;
    s : LONGCARD; (* w setnych sekundy *)
    d, q : LONGREAL;
  VAR
    a : LONGREAL;
  VAR
    pk : PolozenieKatowe;
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
      pk := TheodolitView( AktualnePol.Pol2D );
      a := ATan2( AktualnePol.Wysokosc, pk.Odleglosc );
      a := a*360.0/M_Pi;
      DefVal := a-GetGS( pk.Odleglosc );
      WHILE DefVal <= -180.0 DO
        DefVal := DefVal + 360.0;
      END;
      WHILE DefVal > 180.0 DO
        DefVal := DefVal - 360.0;
      END;
      AktualnePol.Wysokosc := Data.Height;
      DoVoraLubRosnaceKaty := AktualnePol.Pol2D.Odleglosc < q;
      AktualizujPolozenie;
    END;
  END HandleEvent;

  VIRTUAL PROCEDURE DistOffset():LONGREAL;
  BEGIN
    RETURN Data.PoczatekPasa;
  END DistOffset;

  VIRTUAL PROCEDURE DialogName() : PString;
  BEGIN
    RETURN ADR("˜cie§ka - profil B");
  END DialogName;

  VIRTUAL PROCEDURE InsertDeviation( VAR R : TRect );
  BEGIN
    NEW( Deviation );
    Deviation^.Init( R,
                     12,
                     -400.0,
                     +400.0,
                     ADR(Data.DevGS_Akt ),
                     "",
(*                     ADR(Data.DevGSV),*)
                     ADR( Data.WidokZTeodolitu.Elewacja )  );
    Insert( Deviation );
    Deviation^.StringOrReal( Data.DEV_GS )
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
    TILSFlight.Done;
  END Done;

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

BEGIN
END TGSalongFlight;



END ILSGS1.
