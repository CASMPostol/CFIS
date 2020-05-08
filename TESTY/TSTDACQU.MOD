MODULE  Tstdacqu;

IMPORT DebugPMD, RTSMain;

FROM SpecConv  IMPORT Angle100;

FROM DataAcquisition IMPORT 
  UpdateAlfaMarks, UpdateDistMarks, Start;

VAR
  redrawM : BOOLEAN;
  idx     : CARDINAL;
  sample  : CARDINAL;
  
  PROCEDURE  testAlfa;
  VAR
    redrawM : BOOLEAN;
    idx     : INTEGER;
    sample  : CARDINAL;
  BEGIN
    sample := 0;
    FOR idx := -3365 TO 17999 BY -3336+3365 DO
      UpdateAlfaMarks(FALSE, idx, sample, 10, redrawM);
      INC(sample, 1);
      IF redrawM  THEN
        redrawM := redrawM;
      END;
    END;
  END testAlfa;
  
BEGIN
  Start(FALSE);
  sample := 0;
  testAlfa;
  (*
  FOR idx := 100*500 TO 0  BY -7 DO
    UpdateDistMarks(FALSE, idx, sample, 10, redrawM);
    INC(sample, 8);
    IF redrawM  THEN
      redrawM := redrawM;
    END;
  END;
  *)
  RTSMain.Terminate(RTSMain.Stopped);
END Tstdacqu.
