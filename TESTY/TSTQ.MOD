MODULE tstq;

IMPORT DebugPMD, MANAGER, ErrorMess, RTSMain;

  FROM QCheck IMPORT
    Sprawdz;


BEGIN
  Sprawdz;
  RTSMain.Terminate( RTSMain.Warning );
END tstq.
