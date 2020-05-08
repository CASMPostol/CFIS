MODULE Sh;

IMPORT
  Storage, Lib(*, Shell*);
FROM Overlay IMPORT
  str65, UnLoadModule, LoadModule, GetProcAddr;


TYPE
  GoProc = PROCEDURE( ADDRESS );

VAR
  s1, s2 : str65;
  m1, m2 : CARDINAL;
  p : GoProc;

PROCEDURE Execute( Cmd, Param : ARRAY OF CHAR; a : ADDRESS ) : CARDINAL;
VAR
  i : CARDINAL;
BEGIN
  UnLoadModule( s1 );
  i := Lib.Exec( Cmd, Param, a );
  m1 := LoadModule( s1 );
  RETURN i;
END Execute;

BEGIN
  s1 := '.\shelldll.dll';
  m1 := LoadModule( s1 );
  p := GoProc( GetProcAddr( m1, 'Shell$Go' ));
  p( ADR(Execute));
(*  Shell.Go(ADR(Execute));*)
END Sh.
