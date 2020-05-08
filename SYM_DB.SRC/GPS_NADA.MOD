IMPLEMENTATION MODULE GPS_Nadawanie;

FROM SYSTEM IMPORT
  Registers;
FROM stdio IMPORT
  sprintf;
FROM Lib IMPORT
  Dos, Terminate, Fill, RANDOM, RAND, RANDOMIZE;
IMPORT
  rs;

CONST
  Trimble = TRUE;

(*%T Trimble *)

CONST
  STX = 2C;
  ETX = 3C;
  EOL = 15C+12C;


CONST
(*  MagneticTrack   = "C137"    +EOL;*)
  GroundSpeed     = "D128"    +EOL;
  DistToDest      = "E071227" +EOL;
  TimeToWaypoint  = "F0534"   +EOL;
  CrossTrackErr   = "GR0018"  +EOL;
  TrackAngleErr   = "HR0003"  +EOL;
  DesiredTrack    = "I1384"   +EOL;
  ActiveLegNr     = "J11"     +EOL;
  DestWaypoint    = "KGUC"    +EOL;
  BearingToDest   = "L1384"   +EOL;
  ParallelOffset  = "M-0000"  +EOL;
(*  EstimatedPosErr = "P001"    +EOL;*)
  MagneticVar     = "QE158"   +EOL;
  TimeSinceSol    = "c001"    +EOL;
  Unknown1        = "O---"    +EOL;
  Unknown2        = "S----"   +EOL;
  MinSafeAltitude = "d057"    +EOL;
  MinEnrouteAlt   = "e157"    +EOL;
  Unknown3        = "s8312"   +EOL;



VAR
  MagneticTrack,
  EstimatedPosErr,
  GPSMode : ARRAY[0..19] OF CHAR;

VAR
  Date,
  Time,
  Warning,
  Longitude,
  Latitude : ARRAY [0..12] OF CHAR;

PROCEDURE SetHSpeed( r : LONGREAL );
END SetHSpeed;

PROCEDURE SetVSpeed( r : LONGREAL );
END SetVSpeed;

PROCEDURE SetDir( r : LONGREAL );
BEGIN
  WHILE r < 0.0 DO
    r := r + 360.0;
  END;
  sprintf( MagneticTrack, "C%03.0lf"+EOL, r);
END SetDir;

PROCEDURE SetDate();
VAR
  r : Registers;
BEGIN
  r.AH := 02AH;
  Dos( r );
  sprintf( Date, "i%02d/%02d/%02d"+EOL, ORD(r.DH), ORD(r.DL), r.CX MOD 100 );
END SetDate;

PROCEDURE SetTime();
VAR
  r : Registers;
BEGIN
  r.AH := 02CH;
  Dos( r );
  sprintf( Time, "j%02d:%02d:%02d"+EOL, ORD(r.CH), ORD(r.CL), ORD(r.DH) );
END SetTime;

PROCEDURE SetLatitude( kg : KatGeo );
VAR
  Polkula : ARRAY [0..1] OF CHAR;
BEGIN
  IF kg.Stopnie > 0 THEN
    Polkula[0] := 'N';
  ELSE
    Polkula[0] := 'S';
  END;
  Polkula[1] := 0C;
  sprintf( Latitude, "A%s%02d %02d%02d"+EOL, Polkula, kg.Stopnie, kg.Minuty, kg.Setne );
END SetLatitude;

PROCEDURE SetLongitude( kg : KatGeo );
VAR
  Polkula : ARRAY [0..1] OF CHAR;
BEGIN
  IF kg.Stopnie > 0 THEN
    Polkula[0] := 'E';
  ELSE
    Polkula[0] := 'W';
  END;
  Polkula[1] := 0C;
  sprintf( Longitude, "B%s%03d %02d%02d"+EOL, Polkula, kg.Stopnie, kg.Minuty, kg.Setne );
END SetLongitude;


PROCEDURE SetError( On : BOOLEAN );
BEGIN
  IF On THEN
    sprintf( Warning, "T---A---"+EOL );
  ELSE
    sprintf( Warning, "T-------"+EOL );
  END;
END SetError;


(*%T Debug*)
VAR
  F : FIO.File;

PROCEDURE WrChar( ch : CHAR );
BEGIN
  FIO.WrChar( F, ch );
END WrChar;
(*%E*)

VAR
  Retry : CARDINAL;

PROCEDURE WrChar( ch : CHAR );
BEGIN
  rs.Send( ch, 1 );
END WrChar;


PROCEDURE WrStr( u : ARRAY OF CHAR );
VAR
  i : CARDINAL;
BEGIN
  i := 0;
  WHILE ( i <= HIGH( u )) & ( u[i] # 0C ) DO
    WrChar( u[i] );
    INC( i );
  END;
END WrStr;

PROCEDURE ReportError;
END ReportError;

PROCEDURE SetEPE;
VAR
  i : CARDINAL;
BEGIN
  i := RANDOM( 1000 );
  sprintf( EstimatedPosErr, "P%03d"+EOL, i );
END SetEPE;

PROCEDURE SetNrOfSat;
VAR
  i : CARDINAL;
BEGIN
  i := RANDOM( 3 ) + 3;
  sprintf( GPSMode, "zG GPS-3D:%d LOR:5"+EOL, i );
END SetNrOfSat;

PROCEDURE Send;
BEGIN
  IF rs.TxCount() # 0 THEN
    INC( Retry );
    IF Retry = 50 THEN
      ReportError;
    END;
    RETURN;
  END;
  Retry := 0;

  SetEPE;
  SetNrOfSat;

  SetDate;
  SetTime;
  WrStr( STX );
  WrStr( Latitude        );
  WrStr( Longitude       );
  WrStr( MagneticTrack   );
  WrStr( GroundSpeed     );
  WrStr( DistToDest      );
  WrStr( TimeToWaypoint  );
  WrStr( CrossTrackErr   );
  WrStr( TrackAngleErr   );
  WrStr( DesiredTrack    );
  WrStr( ActiveLegNr     );
  WrStr( DestWaypoint    );
  WrStr( BearingToDest   );
  WrStr( ParallelOffset  );
  WrStr( EstimatedPosErr );
  WrStr( MagneticVar     );
  WrStr( TimeSinceSol    );
  WrStr( Unknown1        );
  WrStr( Unknown2        );
  WrStr( Warning         );
  WrStr( MinSafeAltitude );
  WrStr( MinEnrouteAlt   );
  WrStr( Date            );
  WrStr( Time            );
  WrStr( Unknown3        );
  WrStr( GPSMode         );
  WrStr( ETX );
END Send;

BEGIN

  rs.Install( 2 );
  rs.Init( 9600, 8, rs.None, TRUE, FALSE );
  Retry := 0;

  SetDate;
  SetTime;
  SetLatitude( KatGeo( 51, 45, 54 ) );
  SetLongitude( KatGeo( 19, 20, 30 ) );
  SetError( FALSE );
  SetDir( 0.0 );
  RANDOMIZE;

(*%E*)
(*%F Trimble *)

VAR
  Time      : LONGREAL;
  gdop      : LONGREAL;
  WeekNr    : LONGCARD;
  Latitude,
  Longitude : LONGREAL;
  Error     : LONGCARD;
  Retry     : CARDINAL;
  TOG,
  HSpeed,
  VSpeed    : LONGREAL;


CONST
  ID       = 4;
  Len      = 8;
  POSB     = LONGCARD(1);
  DOPB     = LONGCARD(7);
  SPHB     = LONGCARD(6);



PROCEDURE SetDate;
BEGIN
  WeekNr := 0;
END SetDate;

PROCEDURE SetTime();
VAR
  r : Registers;
BEGIN
  r.AH := 02CH;
  Dos( r );
  (* czas od poczatku tygodnia, ale olewa dzien i traktuje, ze zawsze jest poniedzialek *)
  Time := LONGREAL( r.CH ) * 3600.0 +
          LONGREAL( r.CL ) * 60.0 +
          LONGREAL( r.DH );
END SetTime;

PROCEDURE SetLatitude( kg : KatGeo );
BEGIN
  Latitude := LONGREAL( kg.Stopnie ) +
              LONGREAL( kg.Minuty ) / 60.0 +
              LONGREAL( kg.Setne ) / 6000.00+(1.0/12000.0);
END SetLatitude;

PROCEDURE SetLongitude( kg : KatGeo );
BEGIN
  Longitude := LONGREAL( kg.Stopnie ) +
               LONGREAL( kg.Minuty ) / 60.0 +
               LONGREAL( kg.Setne ) / 6000.00+(1.0/12000.0);
END SetLongitude;


PROCEDURE SetError( On : BOOLEAN );
BEGIN
  Error := VAL( LONGINT, NOT On );
END SetError;

PROCEDURE SetHSpeed( r : LONGREAL );
BEGIN
  HSpeed := r*(3600.0/1852.0);
END SetHSpeed;

PROCEDURE SetVSpeed( r : LONGREAL );
BEGIN
  VSpeed := r;
END SetVSpeed;

PROCEDURE SetDir( r : LONGREAL );
BEGIN
  TOG := r;
END SetDir;

PROCEDURE ReportError;
END ReportError;

PROCEDURE Send;
VAR
  Pakiet : ARRAY[0..199] OF CHAR;
  CosOdebral : BOOLEAN;
  NrOfSat    : LONGCARD;

  PROCEDURE JakJestToOdbierz;
  BEGIN
    CosOdebral := FALSE;
    IF rs.RxCount() = 0 THEN
      RETURN;
    END;
    CosOdebral := TRUE;
    WHILE rs.RxCount() # 0 DO
      rs.Receive( Pakiet[0], 1 );
    END;
  END JakJestToOdbierz;

  PROCEDURE Naglowek;
  BEGIN
    Pakiet := CHR( 0AAH ) + CHR( 44H ) + CHR( 11H );
  END Naglowek;

  PROCEDURE SetVal( Offset : CARDINAL; Val : ARRAY OF BYTE );
  VAR
    i : CARDINAL;
  BEGIN
    FOR i := 0 TO HIGH( Val ) DO
      Pakiet[ Offset+i ] := Val[i];
    END;
  END SetVal;

  PROCEDURE Checksum( Ile : CARDINAL );
  TYPE
    Set = SET OF [0..7];
  VAR
    chk : Set;
    i : CARDINAL;
  BEGIN
    chk := Set{};
    FOR i := 0 TO Ile-1 DO
      chk := chk/Set(Pakiet[i]);
    END;
    Pakiet[3] := CHAR( chk );
  END Checksum;

  PROCEDURE WyslijPakiet(Dlugosc : CARDINAL);
  BEGIN
    rs.Send( Pakiet, Dlugosc );
  END WyslijPakiet;

BEGIN
  JakJestToOdbierz;
  IF rs.TxCount() # 0 THEN
    INC( Retry );
    IF Retry = 50 THEN
      ReportError;
    END;
    RETURN;
  END;
  Fill( ADR( Pakiet ), SIZE( Pakiet ), 0 );
  Retry := 0;
  SetDate;
  SetTime;

  Naglowek;
  SetVal( ID, POSB );
  SetVal( Len, LONGCARD(88) );
  SetVal( 12, WeekNr );
  SetVal( 16, Time );
  SetVal( 24, Latitude );
  SetVal( 32, Longitude );
  SetVal( 84, Error );
  Checksum(88);
  WyslijPakiet(88);

  Naglowek;
  SetVal( ID, SPHB );
  SetVal( Len, LONGCARD(52) );
  SetVal( 12, WeekNr );
  SetVal( 16, Time );
  SetVal( 24, HSpeed );
  SetVal( 32, TOG );
  SetVal( 40, VSpeed );
  SetVal( 48, Error );
  Checksum(52);
  WyslijPakiet(52);

  IF CosOdebral OR (RANDOM(20) = 0) THEN
    Fill( ADR( Pakiet ), SIZE( Pakiet ), 0 );
    Naglowek;
    SetVal( ID, DOPB );
    SetVal( 12, WeekNr );
    SetVal( 16, Time );
    gdop := LONGREAL(RAND()) * 10.0;
    SetVal( 24, gdop );
    NrOfSat := LONGCARD( RANDOM( 3 ) + 3 );
    SetVal( 64, NrOfSat );
    SetVal( Len, 68+NrOfSat*4 );
    Checksum(ORD(68+NrOfSat*4));
    WyslijPakiet(ORD(68+NrOfSat*4));
  END;
END Send;

BEGIN
  VSpeed := 0.0;
  RANDOMIZE;

  rs.Install( 2 );
  rs.Init( 38400, 8, rs.None, TRUE, FALSE );

  Retry := 0;
  SetDate;
  SetTime;
  SetLatitude( KatGeo( 51, 45, 54 ) );
  SetLongitude( KatGeo( 19, 20, 30 ) );
  SetError( FALSE );
(*%E*)
END GPS_Nadawanie.
