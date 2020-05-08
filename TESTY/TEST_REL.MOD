MODULE Test_Release [0];
FROM MANAGER IMPORT STARTPROCESS, Release;

PROCEDURE Proces1;
VAR
  Ch: CHAR;

BEGIN
  LOOP
    IF Ch=Ch THEN
      Ch := Ch;
    END (* if *);
    Release;
  END
END Proces1;

PROCEDURE Proces2;
VAR
  Ch: CHAR;

BEGIN
  LOOP
    IF Ch=Ch THEN
      Ch := Ch;
    END (* if *);
    Release;
  END
END Proces2;

BEGIN
  STARTPROCESS( Proces1, 800H, 0);
  STARTPROCESS( Proces2, 800H, 0);
END Test_Release.  
