MODULE TestSIH;

FROM SoftIntHandlingManager  IMPORT UserTimerTick, 
                             ReservedForUserProgramsAt60, 
                             InstEpilogueHnd, 
     Template, TemplatePtr;

FROM Sounds IMPORT Sound, NoSound;

  FROM SYSTEM IMPORT
    ADR, ADDRESS;

FROM RTSMain IMPORT Terminate, Status;
(* FROM Terminal IMPORT KeyPressed; *)


  VAR
    Counter: CARDINAL;

  PROCEDURE onExitHandler
            (    dummy : ADDRESS );
  BEGIN
    IF Counter = 20
    THEN
      Sound(500);
    END (* if insideFlag *);
    IF Counter > 40
    THEN
      NoSound;
      Counter := 0;
    END (* if insideFlag *);
    INC( Counter );
  END onExitHandler;
  
  VAR
    Counter1: CARDINAL;

  PROCEDURE onExitHandler1
            (    dummy : ADDRESS );
  BEGIN
    IF Counter1 = 30
    THEN
      Sound(1000);
    END (* if insideFlag *);
    IF Counter1 > 50
    THEN
      NoSound;
      Counter1 := 0;
    END (* if insideFlag *);
    INC( Counter1 );
  END onExitHandler1;
  
  VAR
    exitTmp     : Template;
    exitTmp1    : Template;

BEGIN
  InstEpilogueHnd( UserTimerTick (* ReservedForUserProgramsAt60 *), 
                   ADR(exitTmp), 
                   onExitHandler, 
                   NIL );
  InstEpilogueHnd( UserTimerTick (* ReservedForUserProgramsAt60 *), 
                   ADR(exitTmp1), 
                   onExitHandler1, 
                   NIL );
  LOOP 
    Counter := Counter;
    (*
    IF KeyPressed()  THEN
      Terminate( Stopped );;
    END;
    *)
  END (* loop *);
END TestSIH.
