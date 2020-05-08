MODULE TestDE;

IMPORT
  DOSEntry, DebugPMD;
VAR
  Counter: CARDINAL;

BEGIN
  Counter := 0FFFFH;
  LOOP 
    DEC(Counter);
  END (* loop *);
END TestDE.
