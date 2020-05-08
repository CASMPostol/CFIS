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

MODULE TestFile;

FROM SYSTEM  IMPORT ADR, ADDRESS;

FROM EMS  IMPORT GetFrameSegment, AllocatePages, Map, Close, ems;

FROM Graphics IMPORT FillRect;

FROM HiLevGraf IMPORT
  LoadDIB, CloseDIB, ShowDIB, DIBWidth, DIBHeight, HDIB, Point,
  Line;


IMPORT FIO, RTSMain, Terminal;

FROM FIO IMPORT File;

FROM MANAGER IMPORT ErrorHandler, WAITC, Assert, STARTPROCESS, Release;

FROM Timer  IMPORT Wait;

FROM Sounds IMPORT Sound, NoSound;
 
IMPORT DOSEntry;

CONST
  BuffSize   = 1000;
  windowSize = 4000H;
  SubPage    = 1;
VAR
  largBuff   : ARRAY [0..BuffSize-1] OF CHAR;
  
MODULE terminalMonitor [0];

FROM RTSMain IMPORT Terminate, Status;

FROM Terminal IMPORT KeyPressed;

IMPORT 
  Wait, STARTPROCESS;

EXPORT Register, Unregister, keyPressed;


VAR
  readerNum  : CARDINAL;
  keyPressed : BOOLEAN;
  
  PROCEDURE   KeyPressedPrc;
  BEGIN
    LOOP 
      Wait(100);
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
   IF count = 0FFFFH  THEN
     Sound(100);
     count :=0;
   ELSIF count = 8000H THEN
     Sound(200);
   END;
  END (* loop *);
END ErrHandler;

PROCEDURE Reader;
VAR 
  f          : File;
  fileName   : ARRAY[0..15] OF CHAR;
  numOfBytes : CARDINAL;
  dummy      : BOOLEAN;
  myId       : CARDINAL;
BEGIN
  myId := Register();
  fileName := 'z.dib';
  numOfBytes := BuffSize;
  REPEAT 
    f := FIO.Open(fileName);
    REPEAT
       dummy := FIO.Read(f, ADR(largBuff), numOfBytes);
    UNTIL NOT dummy;
    FIO.Close(f);
    Sound(myId*1000);
  UNTIL keyPressed;
  Unregister;
END Reader;

PROCEDURE AssignAdr(VAR A: ADDRESS; segment: CARDINAL; offset: CARDINAL);
BEGIN
  A.SEGMENT:= segment;
  A.OFFSET := offset;
END AssignAdr;

PROCEDURE EMSTest;

VAR
  EMSPointer : POINTER TO ARRAY[ 0..windowSize-1 ] OF CHAR;
  numOfPages : CARDINAL;
  segment    : CARDINAL;
  handle     : ems;
  PageNum    : CARDINAL;
  counter    : CARDINAL;
  
BEGIN
  counter := Register();
  numOfPages := 40;
  LOOP 
    Sound(5000);
    segment := GetFrameSegment();
    AssignAdr(EMSPointer, segment+SubPage*windowSize DIV 10H, 0);
    handle := AllocatePages(numOfPages);
    FOR PageNum := 0 TO numOfPages - 1 DO
      Map(handle, PageNum, SubPage);
      FOR counter := 0 TO windowSize-1 DO
        EMSPointer^[counter] := CHR(counter MOD 100H);
      END;
    END;
    Close(handle);
    IF keyPressed THEN
      EXIT;
    END;
  END (* loop *); 
  Unregister;
END EMSTest;

VAR
  z           : CARDINAL;
  loopCounter : CARDINAL;
  prevMarker  : CARDINAL;
  counter     : CARDINAL;
  
BEGIN
  STARTPROCESS(ErrHandler, 1000H, 0);
  STARTPROCESS(Reader, 1000H, 0);
  Wait(2000);
  STARTPROCESS(Reader, 1000H, 0);
  STARTPROCESS(EMSTest, 1000H, 0);
  z := 0;
  LOOP 
    FOR z := 0 TO 799 BY 2 DO
      Line( z, 0, 800-z, 599, CHR(z MOD 100H) );
    END;
    Wait(10);
    INC(loopCounter);
    FillRect(0, 0, 800, 599, 10);
    Wait(10);
  END (* loop *);
END TestFile.
