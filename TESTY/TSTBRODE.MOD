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

MODULE TstBrodersen;

  FROM DGHInterface IMPORT
    DtaSignType, WaitForNewData;

  FROM CocpDsp IMPORT
    State, UstawFormat, UstawZmienne;

  FROM Terminal IMPORT
    KeyPressed, Write, WriteLn, Read;

  FROM InOut IMPORT
    WriteInt;

  IMPORT
    RTSMain, DebugPMD;

  VAR
    DataSign : DtaSignType;
    error    : INTEGER;

  CONST
    errorMin  = -595;
    errorMax  = 595;
VAR
  errorStep : INTEGER;
  lastChar  : CHAR;
  
BEGIN (* DGHTest *)
  error := errorMin;
  UstawFormat( VORKat, 100 );
  errorStep := 100;
  REPEAT
    WaitForNewData( DataSign );
    UstawZmienne( ABS( error ), ABS( error ) * 10, error );
    WriteLn;
    WriteInt( error, 8 );
    IF error > errorMax
    THEN
      errorStep := -errorStep;
    ELSIF error < errorMin THEN
      errorStep := -errorStep;
    END (* if error *);
    INC( error, errorStep );
    Read(lastChar)
  UNTIL lastChar="*";
  RTSMain.Terminate( RTSMain.Stopped );
END TstBrodersen.
