MODULE Inspekcja;

IMPORT
  DebugPMD, MANAGER;
FROM L_Oblot IMPORT
  InitOblot, InitLot;

BEGIN
  IF InitOblot() THEN
  END;
  IF InitLot() THEN
  END;
END Inspekcja.
