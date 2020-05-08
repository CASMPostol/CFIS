IMPLEMENTATION MODULE Data;

FROM stdio IMPORT
  sprintf, sscanf;
FROM Geo2Polar IMPORT
  PolozenieOdniesienia, UstawPolozenieOdniesienia, PolozenieGeograficzne;
FROM Ini IMPORT
  GetPrivateProfileString, WritePrivateProfileString;
FROM App IMPORT
  Desktop;
FROM Winds IMPORT
  WindowFlags, WindowFlags, wfClose;
FROM Views IMPORT
  TViewOption, TViewOptions, ofCentered;
FROM Objects IMPORT
  TRect;
FROM StaticTexts IMPORT
  PStaticText;
FROM Dialogs IMPORT
  PDialog;
FROM Storage IMPORT
  ALLOCATE, DEALLOCATE;
FROM Logo IMPORT
  ShowLogo;
IMPORT
  FIOR, Str;

CONST
  GeoStr = "%d-%d-%d";

(*
TYPE
  RedDeviceType  = [MIN(DeviceType)..sdFile];
  SourceConvType = ARRAY RedDeviceType OF ARRAY[0..4] OF CHAR;

CONST
  SourceConv = SourceConvType( "COM1",
                               "COM2",
                               "COM3",
                               "COM4",
                               "");

PROCEDURE UnderstandSourceRecord( VAR Opt:Source );
VAR
  d : DeviceType;
BEGIN
  FOR d := MIN( RedDeviceType ) TO VAL( RedDeviceType, ORD(MAX( RedDeviceType ))-1) DO (* plik ostatni! *)
    IF Str.Compare( Opt.FileName, SourceConv[d]) = 0 THEN
      Opt.Device := SetOfDeviceType{d};
      RETURN;
    END;
  END;
  Opt.Device := SetOfDeviceType{sdFile};
END UnderstandSourceRecord;

PROCEDURE SetSourceRecord( VAR Opt : Source );
VAR
  d : DeviceType;
BEGIN
  FOR d := MIN( RedDeviceType ) TO MAX( RedDeviceType ) DO
    IF Opt.Device = SetOfDeviceType{d} THEN
      IF d # sdFile THEN
        Str.Copy( Opt.FileName, SourceConv[d] );
      END;
      RETURN;
    END;
  END;
  Opt.Device := SetOfDeviceType{sdCOM1};
  Str.Copy( Opt.FileName, SourceConv[sdCOM1] );
END SetSourceRecord;
*)

PROCEDURE GetMarker( Entry : ARRAY OF CHAR; VAR m : MarkerType );
VAR
  s : ARRAY [0..255] OF CHAR;
BEGIN
  m.Odleglosc := 1.0;
  m.KatWiazki := 4.0; (* stopnie *)
  GetPrivateProfileString( "Markers",
                           Entry,
                           "1,4",
                           s,
                           "Symulator.ini");
  sscanf( s, '%lf,%lf', ADR( m.Odleglosc ), ADR( m.KatWiazki ));
END GetMarker;

PROCEDURE WriteMarker( Entry : ARRAY OF CHAR; VAR m : MarkerType );
VAR
  s : ARRAY [0..255] OF CHAR;
BEGIN
  sprintf( s, '%lf,%lf', m.Odleglosc, m.KatWiazki );
  WritePrivateProfileString( "Markers",
                             Entry,
                             s,
                             "Symulator.ini");
END WriteMarker;


PROCEDURE GetReal( Section, Entry : ARRAY OF CHAR ) : LONGREAL;
VAR
  s : ARRAY [0..255] OF CHAR;
  r : LONGREAL;
BEGIN
  GetPrivateProfileString( Section,
                           Entry,
                           "0.0",
                           s,
                           "Symulator.ini" );
  sscanf( s, "%lf", ADR( r ));
  RETURN r;
END GetReal;

PROCEDURE WriteReal( Section, Entry : ARRAY OF CHAR; r : LONGREAL );
VAR
  s : ARRAY [0..63] OF CHAR;
BEGIN
  sprintf( s, "%lf", r );
  WritePrivateProfileString( Section,
                             Entry,
                             s,
                             "Symulator.ini" );
END WriteReal;

PROCEDURE WaitMessage( Mess : ARRAY OF CHAR ) : PDialog;
VAR
  R  : TRect;
  s  : PStaticText;
  d  : PDialog;
  tmp : CARDINAL;
BEGIN
  R.Assign( 0, 0, 40, 5 );
  NEW( d );
  WITH d^ DO
    Init( R, "Poczekaj chwil‘" );
    Options := Options + ofCentered;
    EXCL( Flags, wfClose );
    R.Assign( 2, 2, 38, 3 );
    NEW( s );
    s^.Init( R, Mess );
    Insert( s );
  END;
  Desktop^.Insert( d );
  RETURN d;
END WaitMessage;





PROCEDURE LoadIni;
VAR
  pg : PolozenieGeograficzne;
  s  : ARRAY [0..80-1] OF CHAR;
  tmp : INTEGER;
  d   : PDialog;
BEGIN
(*
  d := WaitMessage( 3C+"Czytanie wielkožci pocz†tkowych" );
*)
  d := ShowLogo( Desktop, TRUE );

  GetPrivateProfileString( "Symulator",
                           "Latitude",
                           "52-44-12",
                           s,
                           "Symulator.ini");
  IF s[0]=0C THEN
    RETURN;
  END;
  sscanf( s, GeoStr, ADR( pg.Szerokosc.Stopnie ), ADR( pg.Szerokosc.Minuty), ADR( pg.Szerokosc.Setne));
  GetPrivateProfileString( "Symulator",
                           "Longitude",
                           "19-22-22",
                           s,
                           "Symulator.ini" );
  IF s[0]=0C THEN
    RETURN;
  END;
  sscanf( s, GeoStr, ADR( pg.Dlugosc.Stopnie ), ADR( pg.Dlugosc.Minuty), ADR( pg.Dlugosc.Setne));
  UstawPolozenieOdniesienia( pg );
(*
  GetPrivateProfileString( "Symulator",
                           "GPS_Out",
                           "COM1",
                           GPSOpt.FileName,
                           "Symulator.ini");
  GetPrivateProfileString( "Symulator",
                           "ILS_Out",
                           "COM2",
                           ILSOpt.FileName,
                           "Symulator.ini");
  UnderstandSourceRecord( GPSOpt );
  UnderstandSourceRecord( ILSOpt );
*)
  GetPrivateProfileString( "Angle flight",
                           "Distance",
                           "0.0",
                           s,
                           "Symulator.ini");
  sscanf( s, "%lf", ADR(LatKatowy.pk.Odleglosc) );
  GetPrivateProfileString( "Angle flight",
                           "Angle",
                           "0.0",
                           s,
                           "Symulator.ini");
  sscanf( s, "%lf", ADR(LatKatowy.pk.Kat) );
  GetPrivateProfileString( "Angle flight",
                           "Velocity",
                           "300",
                           s,
                          "Symulator.ini");
  sscanf( s, "%lf", ADR(LatKatowy.Predkosc) );
  GetPrivateProfileString( "Theodolit",
                           "Distance",
                           "0.0",
                           s,
                           "Symulator.ini");
  sscanf( s, "%lf", ADR(PolozenieTeodolitu.Odleglosc) );
  GetPrivateProfileString( "Theodolit",
                           "Angle",
                           "0.0",
                           s,
                           "Symulator.ini");
  sscanf( s, "%lf", ADR(PolozenieTeodolitu.Kat) );

  GetPrivateProfileString( "Symulator",
                           "Deklinacja",
                           "0.0",
                           s,
                           "Symulator.ini");
  sscanf( s, "%lf", ADR(Deklinacja) );

  GetPrivateProfileString( "VOR_Flight",
                           "GPS",
                           "1"+0C,
                           s,
                           "Symulator.ini");
  sscanf( s, '%d', ADR( tmp ));
  IF tmp # 0 THEN
    INCL( Devices, GPS_On );
  ELSE
    EXCL( Devices, GPS_On );
  END;
  GetPrivateProfileString( "VOR_Flight",
                           "Theodolit",
                           "1"+0C,
                           s,
                           "Symulator.ini");
  sscanf( s, '%d', ADR( tmp ));
  IF tmp # 0 THEN
    INCL( Devices, Theodolit_On );
  ELSE
    EXCL( Devices, Theodolit_On );
  END;
(*
  GetPrivateProfileString( "VOR_Flight",
                           "AGC",
                           "3.0",
                           s,
                           "Symulator.ini");
  sscanf( s, '%lf', ADR( AGC_VOR_Org ));
*)
  sprintf( s, '%lf', LatKatowy.pk.Kat );
  GetPrivateProfileString( "VOR_Flight",
                           "Omnibearing",
                           s,
                           s,
                           "Symulator.ini");
  sscanf( s, '%lf', ADR( Omnibearing ));
  GetPrivateProfileString( "VOR_Flight",
                           "Var",
                           "1.0",
                           s,
                           "Symulator.ini");
  sscanf( s, '%lf', ADR( Var ));
  GetPrivateProfileString( "VOR_Flight",
                           "Height",
                           "1.0",
                           s,
                           "Symulator.ini");
  sscanf( s, '%lf', ADR( Height ));
  GetPrivateProfileString( "VOR_Flight",
                           "Ref",
                           "1.0",
                           s,
                           "Symulator.ini");
  sscanf( s, '%lf', ADR( Ref ));

  GetPrivateProfileString( "VOR_Flight",
                           "Subcar",
                           "1.0",
                           s,
                           "Symulator.ini");
  sscanf( s, '%lf', ADR( Subcar ));

  GetPrivateProfileString( "Files",
                           "AGC.VOR",
                           "",
                           AGC_VOR,
                           "Symulator.ini");
  GetPrivateProfileString( "Files",
                           "AGC.LOC",
                           "",
                           AGC_LOC,
                           "Symulator.ini");
  GetPrivateProfileString( "Files",
                           "AGC.GS",
                           "",
                           AGC_GS,
                           "Symulator.ini");
  GetPrivateProfileString( "Files",
                           "AGC.Marker",
                           "",
                           AGC_Mark,
                           "Symulator.ini");
  GetPrivateProfileString( "Files",
                           "AGC.DME",
                           "",
                           AGC_DME,
                           "Symulator.ini");
  GetPrivateProfileString( "Files",
                           "AGC.ADF",
                           "",
                           AGC_ADF,
                           "Symulator.ini");
  GetPrivateProfileString( "Files",
                           "DEV.ADF",
                           "",
                           DEV_ADF,
                           "Symulator.ini");
  GetPrivateProfileString( "Files",
                           "VOR.Omnibearing",
                           "",
                           VOR_Omnibearing,
                           "Symulator.ini");
  GetPrivateProfileString( "Files",
                           "LOC.Deviation",
                           "",
                           DEV_LOC,
                           "Symulator.ini");
  GetPrivateProfileString( "Files",
                           "GS.Deviation",
                           "",
                           DEV_GS,
                           "Symulator.ini");
  GetPrivateProfileString( "Files",
                           "AGC.COMM",
                           "",
                           AGC_COMM,
                           "Symulator.ini");
  GetPrivateProfileString( "Files",
                           "MOD.LOC",
                           "",
                           MOD_LOC,
                           "Symulator.ini");
(*
  GetPrivateProfileString( "Files",
                           "Vertical.IMG",
                           "",
                           Vert,
                           "Symulator.ini");
  GetPrivateProfileString( "Files",
                           "Horizontal.IMG",
                           "",
                           Horiz,
                           "Symulator.ini");
*)
  GetPrivateProfileString( "Files",
                           "Height",
                           "",
                           FWysokosc,
                           "Symulator.ini");
  GetMarker( "Inner.where", InnerMarker );
  GetMarker( "Middle.where", MiddleMarker );
  GetMarker( "Outer.where", OuterMarker );
  GetPrivateProfileString( "Markers",
                           "Inner.On",
                           "1"+0C,
                           s,
                           "Symulator.ini" );
  sscanf( s, '%d', ADR( tmp ));
  IF tmp # 0 THEN
    INCL( Markers, mInner );
  ELSE
    EXCL( Markers, mInner );
  END;
  GetPrivateProfileString( "Markers",
                           "Middle.On",
                           "1"+0C,
                           s,
                           "Symulator.ini" );
  sscanf( s, '%d', ADR( tmp ));
  IF tmp # 0 THEN
    INCL( Markers, mMiddle );
  ELSE
    EXCL( Markers, mMiddle );
  END;
  GetPrivateProfileString( "Markers",
                           "Outer.On",
                           "1"+0C,
                           s,
                           "Symulator.ini" );
  sscanf( s, '%d', ADR( tmp ));
  IF tmp # 0 THEN
    INCL( Markers, mOuter );
  ELSE
    EXCL( Markers, mOuter );
  END;

  GetPrivateProfileString( "ILS_Flight",
                           "Gliding.Slope.Inner",
                           "1.0",
                           s,
                           "Symulator.ini");
  sscanf( s, '%lf', ADR( GlidingSlope1 ));
  GetPrivateProfileString( "ILS_Flight",
                           "Gliding.Slope.Middle",
                           "1.0",
                           s,
                           "Symulator.ini");
  sscanf( s, '%lf', ADR( GlidingSlope2 ));
  GetPrivateProfileString( "ILS_Flight",
                           "Gliding.Slope.Outer",
                           "1.0",
                           s,
                           "Symulator.ini");
  sscanf( s, '%lf', ADR( GlidingSlope3 ));
  GetPrivateProfileString( "ILS_Flight",
                           "Landing.Dir",
                           "0.0",
                           s,
                           "Symulator.ini");
  sscanf( s, '%lf', ADR( KierunekPasa ));
  GetPrivateProfileString( "ILS_Flight",
                           "Threshold.Dist",
                           "0.0",
                           s,
                           "Symulator.ini");
  sscanf( s, '%lf', ADR(PoczatekPasa) );
  AGC_VOR_LOC_Akt := GetReal( "AGCs", "LOC" );
  AGC_GS_Akt := GetReal( "AGCs", "GS" );
  AGC_DME_Akt := GetReal( "AGCs", "DME" );
  AGC_ADF_Akt := GetReal( "AGCs", "ADF" );
  AGC_Mark_Akt := GetReal( "AGCs", "Marker" );
  AGC_Comm_Akt := GetReal( "AGCs", "COMM" );
  DevGS_Akt := GetReal( "Deviations", "GS" );
  DevLOC_Akt := GetReal( "Deviations", "LOC" );
  DevADF_Akt := GetReal( "Deviations", "ADF" );
  Replay_Akt := GetReal( "DME", "Replay" );
  Squitter_Akt := GetReal( "DME", "Squitter" );
  MOD_LOC_Akt := GetReal( "ILS_Flight", "MOD.LOC" );
  Desktop^.Delete( d );
END LoadIni;


PROCEDURE SaveIni( );
VAR
  pg : PolozenieGeograficzne;
  s  : ARRAY [0..80-1] OF CHAR;
  d  : PDialog;
BEGIN
(*
  d := WaitMessage( 3C+"Zapisywanie wartožci pocz†tkowych" );
*)
  d := ShowLogo( Desktop, FALSE );

  pg := PolozenieOdniesienia( );
  sprintf( s, GeoStr, pg.Szerokosc.Stopnie, pg.Szerokosc.Minuty, pg.Szerokosc.Setne );
  WritePrivateProfileString( "Symulator",
                             "Latitude",
                             s,
                             "Symulator.ini");
  sprintf( s, GeoStr, pg.Dlugosc.Stopnie, pg.Dlugosc.Minuty, pg.Dlugosc.Setne );
  WritePrivateProfileString( "Symulator",
                             "Longitude",
                             s,
                             "Symulator.ini");
(*
  SetSourceRecord( GPSOpt );
  WritePrivateProfileString( "Symulator",
                             "GPS_Out",
                             GPSOpt.FileName,
                             "Symulator.ini");
  SetSourceRecord( ILSOpt );
  WritePrivateProfileString( "Symulator",
                             "ILS_Out",
                             ILSOpt.FileName,
                             "Symulator.ini");
*)
  sprintf( s, "%lf", LatKatowy.pk.Odleglosc );
  WritePrivateProfileString( "Angle flight",
                             "Distance",
                             s,
                             "Symulator.ini");
  sprintf( s, "%lf", LatKatowy.pk.Kat );
  WritePrivateProfileString( "Angle flight",
                             "Angle",
                             s,
                             "Symulator.ini");
  sprintf( s, "%lf", Deklinacja );
  WritePrivateProfileString( "Symulator",
                             "Deklinacja",
                             s,
                             "Symulator.ini");
  sprintf( s, "%lf", LatKatowy.Predkosc );
  WritePrivateProfileString( "Angle flight",
                             "Velocity",
                             s,
                             "Symulator.ini");
  sprintf( s, "%lf", PolozenieTeodolitu.Odleglosc );
  WritePrivateProfileString( "Theodolit",
                             "Distance",
                             s,
                             "Symulator.ini");
  sprintf( s, "%lf", PolozenieTeodolitu.Kat );
  WritePrivateProfileString( "Theodolit",
                             "Angle",
                             s,
                             "Symulator.ini");
  sprintf( s, '%d', ORD( GPS_On IN Devices ));
  WritePrivateProfileString( "VOR_Flight",
                             "GPS",
                             s,
                             "Symulator.ini");
  sprintf( s, '%d', ORD( Theodolit_On IN Devices ));
  WritePrivateProfileString( "VOR_Flight",
                             "Theodolit",
                             s,
                             "Symulator.ini");
(*
  sprintf( s, '%lf', AGC_VOR_Org );
  WritePrivateProfileString( "VOR_Flight",
                             "AGC",
                             s,
                             "Symulator.ini");
*)
  sprintf( s, '%lf', Omnibearing);
  WritePrivateProfileString( "VOR_Flight",
                             "Omnibearing",
                             s,
                             "Symulator.ini");
  sprintf( s, '%lf', Var);
  WritePrivateProfileString( "VOR_Flight",
                             "Var",
                             s,
                             "Symulator.ini");
  sprintf( s, '%lf', Height);
  WritePrivateProfileString( "VOR_Flight",
                             "Height",
                             s,
                             "Symulator.ini");
  sprintf( s, '%lf', Ref);
  WritePrivateProfileString( "VOR_Flight",
                             "Ref",
                             s,
                             "Symulator.ini");
  sprintf( s, '%lf', Subcar);
  WritePrivateProfileString( "VOR_Flight",
                             "Subcar",
                             s,
                             "Symulator.ini");

  WritePrivateProfileString( "Files",
                             "AGC.VOR",
                             AGC_VOR,
                             "Symulator.ini");
  WritePrivateProfileString( "Files",
                             "AGC.LOC",
                             AGC_LOC,
                             "Symulator.ini");
  WritePrivateProfileString( "Files",
                             "AGC.GS",
                             AGC_GS,
                             "Symulator.ini");
  WritePrivateProfileString( "Files",
                             "AGC.COMM",
                             AGC_COMM,
                             "Symulator.ini" );
  WritePrivateProfileString( "Files",
                             "MOD.LOC",
                             MOD_LOC,
                             "Symulator.ini" );
  WritePrivateProfileString( "Files",
                             "AGC.Marker",
                             AGC_Mark,
                             "Symulator.ini");
  WritePrivateProfileString( "Files",
                             "AGC.DME",
                             AGC_DME,
                             "Symulator.ini");
  WritePrivateProfileString( "Files",
                             "AGC.DME",
                             AGC_DME,
                             "Symulator.ini");
  WritePrivateProfileString( "Files",
                             "AGC.ADF",
                             AGC_ADF,
                             "Symulator.ini");
  WritePrivateProfileString( "Files",
                             "DEV.ADF",
                             DEV_ADF,
                             "Symulator.ini");
  WritePrivateProfileString( "Files",
                             "VOR.Omnibearing",
                             VOR_Omnibearing,
                             "Symulator.ini");
  WritePrivateProfileString( "Files",
                             "LOC.Deviation",
                             DEV_LOC,
                             "Symulator.ini");
  WritePrivateProfileString( "Files",
                             "GS.Deviation",
                             DEV_GS,
                             "Symulator.ini");
(*
  WritePrivateProfileString( "Files",
                             "Vertical.IMG",
                             Vert,
                             "Symulator.ini");
  WritePrivateProfileString( "Files",
                             "Horizontal.IMG",
                             Horiz,
                             "Symulator.ini");
*)
  WritePrivateProfileString( "Files",
                             "Height",
                             FWysokosc,
                             "Symulator.ini");
  WriteMarker( "Inner.where", InnerMarker );
  WriteMarker( "Middle.where", MiddleMarker );
  WriteMarker( "Outer.where", OuterMarker );
  sprintf( s, '%d', ORD( mInner IN Markers ));
  WritePrivateProfileString( "Markers",
                             "Inner.On",
                             s,
                             "Symulator.ini");
  sprintf( s, '%d', ORD( mMiddle IN Markers ));
  WritePrivateProfileString( "Markers",
                             "Middle.On",
                             s,
                             "Symulator.ini");
  sprintf( s, '%d', ORD( mOuter IN Markers ));
  WritePrivateProfileString( "Markers",
                             "Outer.On",
                             s,
                             "Symulator.ini");
  sprintf( s, '%lf', GlidingSlope1 );
  WritePrivateProfileString( "ILS_Flight",
                             "Gliding.Slope.Inner",
                             s,
                             "Symulator.ini");
  sprintf( s, '%lf', GlidingSlope2 );
  WritePrivateProfileString( "ILS_Flight",
                             "Gliding.Slope.Middle",
                             s,
                             "Symulator.ini");
  sprintf( s, '%lf', GlidingSlope3 );
  WritePrivateProfileString( "ILS_Flight",
                             "Gliding.Slope.Outer",
                             s,
                             "Symulator.ini");
  sprintf( s, '%lf', KierunekPasa );
  WritePrivateProfileString( "ILS_Flight",
                             "Landing.Dir",
                             s,
                             "Symulator.ini");
  sprintf( s, '%lf', PoczatekPasa );
  WritePrivateProfileString( "ILS_Flight",
                             "Threshold.Dist",
                             s,
                             "Symulator.ini");
  WriteReal( "AGCs", "LOC", AGC_VOR_LOC_Akt );
  WriteReal( "AGCs", "GS", AGC_GS_Akt );
  WriteReal( "AGCs", "DME", AGC_DME_Akt );
  WriteReal( "AGCs", "ADF", AGC_ADF_Akt );
  WriteReal( "AGCs", "Marker", AGC_Mark_Akt );
  WriteReal( "AGCs", "COMM", AGC_Comm_Akt );
  WriteReal( "Deviations", "ADF", DevADF_Akt );
  WriteReal( "Deviations", "GS", DevGS_Akt );
  WriteReal( "Deviations", "LOC", DevLOC_Akt );
  WriteReal( "DME", "Replay", Replay_Akt );
  WriteReal( "DME", "Squitter", Squitter_Akt );
  WriteReal( "ILS_Flight", "MOD.LOC", MOD_LOC_Akt );
  Desktop^.Delete( d );
END SaveIni;




BEGIN
  FIOR.ReadRedirectionFile( "symulator.red" );
(*
  GPSOpt.Device := SetOfDeviceType{sdFile};
  GPSOpt.FileName := "GPS.log";
  ILSOpt.Device := SetOfDeviceType{sdFile};
  ILSOpt.FileName := "ILS.log";
*)
(*  LoadIni;*)
  TeoEvent := FALSE;
END Data.