MODULE TVP;

IMPORT
  DebugPMD, MANAGER, DOSEntry, VORPrint, RTSMain, ErrorMess, SYSTEM, Czas,
  CommonTypes;

  PROCEDURE FCBS(  );
  BEGIN
    SYSTEM.SETREG( SYSTEM.AX, 6700H );
    SYSTEM.SETREG( SYSTEM.BX, 100 );
    SYSTEM.SWI( 21H );
  END FCBS;


VAR
  Tm : CommonTypes.TimeAndDate;
  dummy : CARDINAL;
BEGIN
  FCBS;
  Czas.Godzina( Tm.t.h, Tm.t.m, dummy );
  Czas.Data( Tm.d.y, Tm.d.m, Tm.d.d );
  VORPrint.Print( FALSE, TRUE, 123, Tm );
  VORPrint.OpisPomiaru( FALSE, TRUE, 123, Tm );
  RTSMain.Terminate( RTSMain.Stopped );
END TVP.
