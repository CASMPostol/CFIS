IMPLEMENTATION MODULE DMEADF;

FROM Storage IMPORT
  ALLOCATE;
FROM DMEFlight IMPORT
  PDMEFlight;
FROM ADFFlight IMPORT
  PADFFlight;
FROM FlightCommon IMPORT
  EnableTimer;
FROM DMEADFFlight IMPORT
  PDMEADFFlight;

PROCEDURE DmeAdf( f : PDMEADFFlight; p : PGroup );
BEGIN
  f^.Init;
  p^.Insert( f );
  EnableTimer( f, TRUE );
END DmeAdf;

PROCEDURE DME( p : PGroup );
VAR
  f : PDMEFlight;
BEGIN
  NEW( f );
  DmeAdf( f, p );
END DME;

PROCEDURE ADF( p : PGroup );
VAR
  f : PADFFlight;
BEGIN
  NEW( f );
  DmeAdf( f, p );
END ADF;

END DMEADF.
