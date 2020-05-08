IMPLEMENTATION MODULE CircleVOR;

FROM CircleFlight IMPORT
  PCircleFlight;
FROM FlightCommon IMPORT
  EnableTimer;
FROM Storage IMPORT
  ALLOCATE, DEALLOCATE;

PROCEDURE CircleFlightStart( p : PGroup );
VAR
  cf : PCircleFlight;
BEGIN
  NEW( cf );
  cf^.Init;
  p^.Insert( cf );
  EnableTimer( cf, TRUE );
END CircleFlightStart;

END CircleVOR.
