(*.F- *)
(**********************************************************************
|  Title   : Test dla kanalu czyteania danych z odbiornika NAV przez ARINC
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
    WaitForNewData, DtaSignType;

  FROM NAVInterface IMPORT
    GetOmnibearing;

  FROM Terminal IMPORT
    KeyPressed, Write, WriteLn, WriteString;

  FROM InOut IMPORT
    WriteInt;

  IMPORT
    RTSMain;

  VAR
    DataSign   : DtaSignType;
    omnibering : INTEGER;

  CONST

BEGIN (* DGHTest *)
  REPEAT
    WaitForNewData( DataSign );
    IF GetOmnibearing( 1, omnibering )
    THEN
      WriteLn;
      WriteInt( omnibering, 8 );
    ELSE
      WriteLn;
      WriteString( "brak danych z ARINC" );
    END (* if GetOmnibearing *);
  UNTIL KeyPressed( );
  RTSMain.Terminate( RTSMain.Stopped );
END TstBrodersen.
