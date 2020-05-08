(*.F- *)
(**********************************************************************
|  Title   : Testowanie systemu plikow 
|  Author  : Mariusz Postol
|  System  : LOGITECH MODULA-2/86 
|  History :
|
|  Copyright (C), CAS LODZ POLAND.
|  TEL: 42' 86 58 12, 42' 87 80 44 FAX/TEL: 42' 84 48 40
|
**********************************************************************)
(*.F+ *)

MODULE TstFile;

IMPORT
  DebugPMD, FCBS;

FROM SYSTEM  IMPORT ADR, ADDRESS, TSIZE;

FROM Graphics IMPORT FillRect;


FROM HiLevGraf IMPORT
  LoadDIB, CloseDIB, ShowDIB, DIBWidth, DIBHeight, HDIB, Point,
  Line;


IMPORT FIO, RTSMain, Terminal;

FROM FIO IMPORT File;

FROM MANAGER IMPORT ErrorHandler, WAITC, Assert, STARTPROCESS, Release;

FROM Timer  IMPORT Wait, TInOneSecond;

FROM Sounds IMPORT Sound, NoSound;
 FROM Storage IMPORT ALLOCATE, DEALLOCATE;
 
FROM Semafory  IMPORT
 Semafor, Init, Set, Free;
 
 FROM BlockOps  IMPORT
   BlockSet;
   
IMPORT DOSEntry;
CONST
  BuffSize   = 1000;
  windowSize = 4000H;
  SubPage    = 1;
VAR
  largBuff   : ARRAY [0..BuffSize-1] OF CHAR;
  StorageSem : Semafor;
  
MODULE terminalMonitor [0];

FROM RTSMain IMPORT Terminate, Status;

FROM Terminal IMPORT KeyPressed;

IMPORT 
  Wait, STARTPROCESS, TInOneSecond;

EXPORT Register, Unregister, keyPressed;


VAR
  readerNum  : CARDINAL;
  keyPressed : BOOLEAN;
  
  PROCEDURE   KeyPressedPrc;
  BEGIN
    LOOP 
      Wait(TInOneSecond());
      keyPressed := KeyPressed();
    END (* loop *);
  END KeyPressedPrc;
  
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
  keyPressed := FALSE;
  readerNum := 0;
  STARTPROCESS(KeyPressedPrc, 1000H, 0);
END terminalMonitor;

PROCEDURE ErrHandler;
VAR
  count: CARDINAL;
BEGIN
  count := 0;
  WAITC(ErrorHandler);
  Sound(200);
  LOOP 
   INC(count);
   IF count > 8000H  THEN
     Sound(100);
     count :=0;
   ELSE
     Sound(200);
   END;
  END (* loop *);
END ErrHandler;

PROCEDURE Reader;
VAR 
  countOK      : CARDINAL;
  countFA      : CARDINAL;
  f          : File;
  fileName   : ARRAY[0..15] OF CHAR;
  numOfBytes : CARDINAL;
  dummy      : BOOLEAN;
  myId       : CARDINAL;
  adr        : ADDRESS;
  pattern    : ADDRESS;
  blockSize  : CARDINAL;
BEGIN
  pattern := ADR(countOK);
  countOK := 0;
  countFA := 0;
  myId := Register();
  fileName := 'tstfile.mod';
  numOfBytes := BuffSize;
  REPEAT 
    f := FIO.Open(fileName);
    IF f = 0FFFFH  THEN
      INC(countFA);
      FillRect( 300+myId*20, 
                myId*20, 
                300+(myId+1)*20, 
                (myId+1)*20, 
                CHR(253 ));
      Assert(FALSE);
      Wait(5 * TInOneSecond());
      f:= f;
    ELSE
      countOK := (countOK+1) MOD 256;
      blockSize := countOK*10+countOK;
      Set(StorageSem);
      ALLOCATE(adr, blockSize);
      Free(StorageSem);
      BlockSet(adr, blockSize, pattern, TSIZE(CARDINAL) );
      FillRect( myId*20, myId*20, (myId+1)*20, (myId+1)*20, CHR(countOK));
      REPEAT
         dummy := FIO.Read(f, ADR(largBuff), numOfBytes);
      UNTIL NOT dummy;
      FIO.Close(f);
      Set(StorageSem);
      DEALLOCATE(adr, blockSize);
      Free(StorageSem);
    END;
    Sound(myId*200);
  UNTIL (countOK = 200) OR keyPressed;
      FillRect( 400+myId*20, 
                myId*20, 
                400+(myId+1)*20, 
                (myId+1)*20, 
                CHR(251));
  Unregister;
END Reader;

PROCEDURE AssignAdr(VAR A: ADDRESS; segment: CARDINAL; offset: CARDINAL);
BEGIN
  A.SEGMENT:= segment;
  A.OFFSET := offset;
END AssignAdr;

VAR
  z           : CARDINAL;
  loopCounter : CARDINAL;
  prevMarker  : CARDINAL;
  counter     : CARDINAL;
  
BEGIN
  Init(StorageSem);
  Set(StorageSem);
  STARTPROCESS(ErrHandler, 1000H, 0);
  STARTPROCESS(Reader, 1000H, 1);
  STARTPROCESS(Reader, 1000H, 2);
  STARTPROCESS(Reader, 1000H, 3);
  STARTPROCESS(Reader, 1000H, 4);
  STARTPROCESS(Reader, 1000H, 5);
  STARTPROCESS(Reader, 1000H, 6);
  STARTPROCESS(Reader, 1000H, 7);
  STARTPROCESS(Reader, 1000H, 8);
  STARTPROCESS(Reader, 1000H, 9);
  STARTPROCESS(Reader, 1000H, 10);
  STARTPROCESS(Reader, 1000H, 11);
  STARTPROCESS(Reader, 1000H, 12);
  STARTPROCESS(Reader, 1000H, 13);
  STARTPROCESS(Reader, 1000H, 14);
  STARTPROCESS(Reader, 1000H, 15);
  STARTPROCESS(Reader, 1000H, 16);
  Free(StorageSem);
  z := 0;
  LOOP 
    FOR z := 0 TO 799 BY 2 DO
      Line( z, 400, 800-z, 599, CHR(z MOD 100H) );
    END;
    Wait(TInOneSecond() DIV 2);
    INC(loopCounter);
    FillRect(0, 400, 800, 599, 10);
    Wait(10);
  END (* loop *);
END TstFile.
