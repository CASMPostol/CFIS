IMPLEMENTATION MODULE AngleVOR;

FROM AngleFlight IMPORT
  PAngleFlight;
FROM FlightCommon IMPORT
  EnableTimer;
FROM Storage IMPORT
  ALLOCATE, DEALLOCATE;

PROCEDURE AngleFlightStart( p : PGroup );
VAR
  af : PAngleFlight;
BEGIN
  NEW( af );
  af^.Init;
  p^.Insert( af );
  EnableTimer( af, TRUE );
END AngleFlightStart;

END AngleVOR.
