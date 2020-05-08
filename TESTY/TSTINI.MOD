MODULE TstIni;

IMPORT
   DebugPMD, DOSEntry, RTSMain;
  
FROM MANAGER  IMPORT
  STARTPROCESS;

FROM Ini IMPORT 
  WritePrivateProfileString;

FROM SpecConv  IMPORT
  Card100Str;
  
FROM Timer  IMPORT Wait;

FROM Sounds IMPORT Sound, NoSound;

MODULE terminalMonitor [0];

FROM RTSMain IMPORT Terminate, Status;

IMPORT 
  Wait, STARTPROCESS;

EXPORT Register, Unregister; 


VAR
  readerNum  : CARDINAL;
  
  PROCEDURE Register(): CARDINAL ;
  BEGIN
    INC(readerNum);
    RETURN readerNum;
  END Register;
  
  PROCEDURE Unregister ;
  BEGIN
    DEC(readerNum);
    IF readerNum = 0  THEN
      Terminate( Stopped );;
    END;
  END Unregister;

BEGIN
  readerNum := 0;
END terminalMonitor;

  PROCEDURE Proces1;
  VAR
    plik       : ARRAY[0..15] OF CHAR;
    section    : CARDINAL;
    entry      : CARDINAL;
    sectionStr : ARRAY[0..15] OF CHAR;
    entryStr   : ARRAY[0..15] OF CHAR;
    id         : CARDINAL;
  BEGIN
    plik := 'tstini1.dat';
    id := Register();
    FOR entry := 1 TO 10 DO
      FOR  section := 0 TO 10 DO
        Card100Str(section, sectionStr, 5);
        Card100Str(entry, entryStr, 5);
        WritePrivateProfileString(sectionStr, entryStr, entryStr, plik);
      END;
    END;
    Unregister;
  END Proces1;
  
  PROCEDURE Proces2;
  VAR
    plik       : ARRAY[0..15] OF CHAR;
    section    : CARDINAL;
    entry      : CARDINAL;
    sectionStr : ARRAY[0..15] OF CHAR;
    entryStr   : ARRAY[0..15] OF CHAR;
    id         : CARDINAL;
    
  BEGIN
    plik := 'tstini2.dat';
    id := Register();
    FOR entry := 1 TO 10 DO
      FOR  section := 0 TO 10 DO
        Card100Str(section, sectionStr, 5);
        Card100Str(entry, entryStr, 5);
        WritePrivateProfileString(sectionStr, entryStr, entryStr, plik);
      END;
    END;
    Unregister;
  END Proces2;
  
BEGIN
  STARTPROCESS(Proces1, 1000, 0);
  STARTPROCESS(Proces2, 1000, 0);
END TstIni.
