IMPLEMENTATION MODULE Warn;

FROM MsgBox IMPORT
  MsgOption, MsgOptions, MessageBox;
FROM Commands IMPORT
  cmYes;


PROCEDURE Proceed():BOOLEAN;
BEGIN
  IF LockCnt = 0 THEN
    RETURN TRUE;
  ELSE
    RETURN MessageBox( 3C+"Pozostaly aktywne okna dialogowe. Ostatnie zmiany zostana odrzucone!. kontynuowa† ?", NIL, MsgOptions{mfWarning, mfYesButton, mfNoButton}) = cmYes;
  END;
END Proceed;

BEGIN
  LockCnt := 0;
END Warn.