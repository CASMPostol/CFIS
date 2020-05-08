IMPLEMENTATION MODULE ShExecute;

IMPORT
  Lib;
FROM App IMPORT
  Application;
FROM Drivers IMPORT
  smCO80, DoneEvents, InitEvents;
FROM Overlay IMPORT
  UnLoadModule, LoadModule, str65;
FROM Storage IMPORT
  HeapTotalAvail, MainHeap;

TYPE
  ExecProc = PROCEDURE ( ARRAY OF CHAR, ARRAY OF CHAR, ADDRESS ) : CARDINAL;

VAR
  e : ExecProc;

PROCEDURE Exec( Cmd, Prm : ARRAY OF CHAR; a : ADDRESS ) : CARDINAL;
VAR
  r : CARDINAL;
BEGIN
(*%F __DLL__*)
  r := Lib.Exec( Cmd, Prm, a );
(*%E*)
(*%T __DLL__*)
  r := e( 'command.com', Prm, a );
(*%E*)
  Application^.SetScreenMode( smCO80 );
  RETURN r;
END Exec;

(*%T __DLL__*)
PROCEDURE SetRun( a : ADDRESS );
BEGIN
  e := ExecProc( a );
END SetRun;

(*%E*)
END ShExecute.
