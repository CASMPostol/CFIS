(*.F- *)
(**********************************************************************
|  Title   : Test dla wyswietlacza Brodersen 
|  Author  : Mariusz Postol
|  System  : LOGITECH MODULA-2/86 
|  History :
|
|  Copyright (C), CAS LODZ POLAND.
|  TEL: 42' 86 58 12, 42' 87 80 44 FAX/TEL: 42' 84 48 40
|
**********************************************************************)
(*.F+ *)

MODULE TstDGHbt;

FROM DGHIni IMPORT 
  SignalNames,signals;

FROM DGHInterface IMPORT 
  DtaSignType, GetCurrDataSign, WaitForNewData, TurnOff, TurnOn, GetAnalogVal,
  GetBinaryVal, SetAnalogVal, SetBinaryVal, Number, SetMessage;

FROM Terminal IMPORT
  Read, KeyPressed, ReadAgain, ReadString, Write, WriteString, WriteLn;

FROM BitWordOps IMPORT
  WordXor;

FROM InOut IMPORT
  WriteCard, WriteInt;

IMPORT RTSMain, DGHInterface, InOut;

FROM Timer IMPORT
  Wait;

VAR
  binaryOut	: CARDINAL;
  DataSign1,
  DataSign2,
  DataSign3,
  DataSign4 	: DtaSignType;
  digi 		: CARDINAL;
  counter	: INTEGER;

  PROCEDURE SendMsg1 (     val     : CARDINAL;
                           msgNum  : CARDINAL;
                       VAR dtaSign : DtaSignType);
  VAR
    compiledVal : Number;
    count : CARDINAL;
    
  BEGIN
    FOR count := 4 TO 1 BY -1 DO
      compiledVal[ count -1 ] := 100H+count*10H+val MOD 10;
      val := val DIV 10;
    END;
    SetMessage( msgNum, compiledVal, dtaSign);
  END SendMsg1;

  PROCEDURE SendMsg2 (     val     : CARDINAL;
                           msgNum  : CARDINAL;
                       VAR dtaSign : DtaSignType);
  VAR
    compiledVal : Number;
    count : CARDINAL;
    
  BEGIN
    FOR count := 7 TO 5 BY -1 DO
      compiledVal[ count - 5 ] := 100H+count*10H+val MOD 10;
      val := val DIV 10;
    END;
    compiledVal[3] := 100H+80H;
    SetMessage( msgNum, compiledVal, dtaSign);
  END SendMsg2;
  
BEGIN (* DGHTest *)
  digi := 0;
  DataSign1 := GetCurrDataSign();
  REPEAT
    WaitForNewData(DataSign1);
    IF NOT ODD(digi) THEN
      SendMsg1(digi*100, digi, DataSign1);
    ELSE
      SendMsg2(digi*10, digi, DataSign1);
    END;    
    WriteLn;
    WriteCard(digi, 3);
    INC(digi);
    IF digi>19 THEN
      digi:=0;
    END;
  UNTIL  KeyPressed();
  RTSMain.Terminate(RTSMain.Stopped);
END DGHbt.