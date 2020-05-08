MODULE TLP;

IMPORT
  DebugPMD, MANAGER, DOSEntry, L_Print, RTSMain, ErrorMess, SYSTEM, Czas,
  CommonTypes, L_CommonTypes, L_results;

  PROCEDURE FCBS(  );
  BEGIN
    SYSTEM.SETREG( SYSTEM.AX, 6700H );
    SYSTEM.SETREG( SYSTEM.BX, 100 );
    SYSTEM.SWI( 21H );
  END FCBS;


VAR
  Tm : CommonTypes.TimeAndDate;
  dummy : CARDINAL;
  p : L_CommonTypes.ProceduraT;
BEGIN
  FCBS;
  Czas.Godzina( Tm.t.h, Tm.t.m, dummy );
  Czas.Data( Tm.d.y, Tm.d.m, Tm.d.d );
  FOR p := MIN( L_CommonTypes.ProceduraT ) TO MAX( L_CommonTypes.ProceduraT ) DO
    L_results.anRes.procedure:=p;
(*    L_Print.Print( Tm );*)
    L_Print.OpisPomiaru( Tm );

  END;
  RTSMain.Terminate( RTSMain.Stopped );
END TLP.

