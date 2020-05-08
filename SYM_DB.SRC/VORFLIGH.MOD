IMPLEMENTATION MODULE VORFlights;

FROM AngleFlight IMPORT
  PAngleFlight;
FROM CircleFlight IMPORT
  PCircleFlight;
FROM App IMPORT
  Desktop;
FROM Storage IMPORT
  ALLOCATE, DEALLOCATE;

PROCEDURE AngleFlightStart( );
VAR
  af : PAngleFlight;
BEGIN
  NEW( af );
  af^.Init;
  Desktop^.Insert( af );
END AngleFlightStart;

PROCEDURE CircleFlightStart;
VAR
  cf : PCircleFlight;
BEGIN
  NEW( cf );
  cf^.Init;
  Desktop^.Insert( cf );
END CircleFlightStart;

END VORFlights.
