MODULE TSEM;

FROM MANAGER IMPORT
  STARTPROCESS;
FROM Timer  IMPORT
  Wait;
FROM Semafory IMPORT
  Semafor, Init, Free, Set;  
PROCEDURE A;
BEGIN
  Set( Sem );
  INC( Zm );
  Wait( 10 );
  DEC( Zm );
  IF Zm # 0 THEN
    HALT;
  END;
  Free( Sem );
END A;

VAR
  Zm, i : CARDINAL;
  Sem : Semafor;
BEGIN
  Zm := 0;
  Init( Sem );
  FOR i := 0 TO 10 DO 
    STARTPROCESS( A, 1000H, 0 );
  END;
END TSEM.
