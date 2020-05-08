IMPLEMENTATION MODULE ILSS1;

FROM ILSGS1 IMPORT
  PGSacrossFlight, PGSalongFlight;
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

PROCEDURE AcrossGS( p : PGroup );
VAR
  af : PGSacrossFlight;
BEGIN
  NEW( af );
  af^.Init;
  p^.Insert(af);
  EnableTimer( af, TRUE );
END AcrossGS;

PROCEDURE AlongGS( p : PGroup );
VAR
  af : PGSalongFlight;
BEGIN
  NEW( af );
  af^.Init;
  p^.Insert(af);
  EnableTimer( af, TRUE );
END AlongGS;


END ILSS1.
