IMPLEMENTATION MODULE Wroc;

FROM Strings IMPORT
  Assign;
FROM Komunikacja IMPORT
  InsertInKBD;
FROM RTSMain IMPORT
  InstallTermProc;
FROM GrafUtil IMPORT
  InfoBeep;


VAR
  cmd : ARRAY[0..10] OF CHAR;

PROCEDURE GdzieWrocic( a : ARRAY OF CHAR );
BEGIN
  Assign( a, cmd );
END GdzieWrocic;

PROCEDURE WstawDoBufora(  );
BEGIN
  IF cmd[0] # 0C THEN
    IF NOT InsertInKBD( cmd ) THEN
      InfoBeep( "Problem z wywolaniem programu wykonawczego!!!", 5, 200 );
    END;
  END;
END WstawDoBufora;

BEGIN
  cmd := "";
  InstallTermProc( WstawDoBufora );
END Wroc.

