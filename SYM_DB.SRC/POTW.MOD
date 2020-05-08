IMPLEMENTATION MODULE Potw;

FROM MsgBox IMPORT
  MessageBox, MsgOption, MsgOptions;
FROM Commands IMPORT
  cmOK, cmCancel, cmYes, cmNo;


PROCEDURE UsunZBazy():BOOLEAN;
VAR
  ret : CARDINAL;
BEGIN
  ret := MessageBox( 3C+"Jestes pewien, ze chcesz usunac ten opis z bazy danych?",
                     NIL,
                     MsgOptions{ mfWarning, mfYesButton, mfNoButton }
                   );
  RETURN ret = cmYes;
END UsunZBazy;



END Potw.