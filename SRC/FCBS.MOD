IMPLEMENTATION MODULE FCBS;

  FROM SYSTEM IMPORT
    ADDRESS, WORD, BYTE, SIZE, ADR, SETREG, AX, BX, SWI;
  FROM RTSMain IMPORT
    Terminate, Status;
  FROM SoftIntHandlingManager IMPORT
    BreakChain, Template, KeyboardBreak, InstPrologueHnd;

  PROCEDURE Set( Cnt : CARDINAL );
    BEGIN
      SETREG(BX, Cnt);
      SETREG(AX, 6700H);
      SWI(21H);
    END Set;



  PROCEDURE CtrlBreakProc( a : ADDRESS );
    BEGIN
      Terminate( Warning );
      BreakChain; (* na wszelki wypadek *)
    END CtrlBreakProc;

VAR
  Code : Template;
BEGIN
  Set( 100 );
(*
  InstPrologueHnd( KeyboardBreak,
                   ADR(Code),
                   CtrlBreakProc,
                   NIL );
*)
END FCBS.
