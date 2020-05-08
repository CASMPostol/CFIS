MODULE TGS;

IMPORT
  DebugPMD, MANAGER;
FROM G_Oblot IMPORT
  InitOblot, InitLot;

BEGIN
  IF InitOblot() THEN
  END;
  IF InitLot() THEN
  END;
END TGS.
