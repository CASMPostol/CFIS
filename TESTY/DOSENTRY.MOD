(*.F- *)
(**********************************************************************
|  Title   : DOS resource guard
|  Author  : M.Postol
|  System  : LOGITECH MODULA-2/86
|  History :
|    31.12.94: original version
|
|  Copyright (C), CAS LODZ POLAND.
|  TEL: 42' 86 58 12, 42' 87 80 44 FAX/TEL: 42' 84 48 40
|
**********************************************************************)
(*.F+ *)

IMPLEMENTATION MODULE DOSEntry [ 8 ];

  IMPORT RTSMain;
  
  FROM SYSTEM IMPORT
    ADR, ADDRESS;

  FROM MANAGER IMPORT
    Condition, InitC, Notify, WAITC, StartTimeSlicing;

  FROM Sounds IMPORT Sound, NoSound;
  FROM SoftIntHandlingManager IMPORT
    (* CONST *) GeneralDOSfunctions,
    (* TYPE *) Template, Result, TemplatePtr,
    (* PROCEDURE *) InstPrologueHnd, InstEpilogueHnd;

  VAR
    entryTmp    : Template;
    exitTmp     : Template;
    entryTmpPtr : TemplatePtr;
    exitTmpPtr  : TemplatePtr;
    insideFlag  : CARDINAL;
    DOSEmpty    : Condition;
(*    Collision   : CARDINAL; *)

  PROCEDURE onEntryHandler
            (    dummy : ADDRESS );

  BEGIN
    INC( insideFlag );
    Sound(5000);
    IF insideFlag > 1
    THEN
(*      INC(Collision); *)
      WAITC( DOSEmpty );
    ELSE
      insideFlag := insideFlag;
    END (* if insideFlag *);
(*    Sound(10000); *)
  END onEntryHandler;

  PROCEDURE onExitHandler
            (    dummy : ADDRESS );

  BEGIN
(*    NoSound();*)
    DEC( insideFlag );
    IF insideFlag > 0
    THEN
      Notify( DOSEmpty );
    ELSE
      NoSound();
      insideFlag := insideFlag;
    END (* if insideFlag *);
  END onExitHandler;
  
  PROCEDURE TerminalProcedure;
  (* Import this module as first - it must be called before DebugPMD *)
  BEGIN
    StartTimeSlicing(0FFFFH, 0FFFFH);
  END TerminalProcedure;
  
BEGIN
(*  Collision := 0; *)
  insideFlag := 0;
  InitC( DOSEmpty );
  exitTmpPtr := ADR( exitTmp );
  entryTmpPtr := ADR( entryTmp );
  InstEpilogueHnd( GeneralDOSfunctions, exitTmpPtr, onExitHandler, NIL );
  InstPrologueHnd( GeneralDOSfunctions, entryTmpPtr, onEntryHandler, NIL );
  RTSMain.InstallTermProc(TerminalProcedure);
END DOSEntry.
