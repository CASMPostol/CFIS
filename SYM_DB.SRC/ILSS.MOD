IMPLEMENTATION MODULE ILSS;

FROM ILSGS IMPORT
  PGSVFlight, PGSHFlight;
FROM ILSFlight IMPORT
  PILSFlight;
FROM FlightCommon IMPORT
  EnableTimer;
FROM Storage IMPORT
  ALLOCATE, DEALLOCATE;


PROCEDURE GS( f : PILSFlight; p : PGroup );
BEGIN
  f^.Init;
  p^.Insert( f );
  EnableTimer( f, TRUE );
END GS;

PROCEDURE GlidingSlopeNach( p : PGroup );
VAR
  af : PGSVFlight;
BEGIN
  NEW( af );
  af^.Init;
  p^.Insert( af );
  EnableTimer( af, TRUE );
END GlidingSlopeNach;

PROCEDURE GlidingSlopeZbocz( p : PGroup );
VAR
  af : PGSHFlight;
BEGIN
  NEW( af );
  af^.Init;
  p^.Insert( af );
  EnableTimer( af, TRUE );
END GlidingSlopeZbocz;

END ILSS.
