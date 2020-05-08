MODULE TstFIO;


IMPORT
  FIO, Terminal, StdIO, SYSTEM;

CONST
  N = 50;
VAR
  Tab : ARRAY[0..N-1] OF FIO.File;
  i : INTEGER;
  s : ARRAY[0..100] OF CHAR;

PROCEDURE FCBS(  );
  BEGIN
    SYSTEM.SETREG( SYSTEM.AX, 6700H );
    SYSTEM.SETREG( SYSTEM.BX, N+6 );
    SYSTEM.SWI( 21H );
  END FCBS;

BEGIN
  FCBS;
  FOR i := 0 TO N-1 DO
    StdIO.sprintf( s, "%05d", i );
    Tab[i] := FIO.Create( s );
    IF Tab[i] = 0FFFFH THEN
      StdIO.sprintf( s, "Nie udalo sie otworzyc pliku numer %d", i );
      Terminal.WriteString( s );
      RETURN;
    END;
  END;
END TstFIO.
