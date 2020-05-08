(*.F- *)
(**********************************************************************
|  Title   : Switch control module
|  Author  : Mariusz Postol
|  System  : LOGITECH MODULA-2/86
|  History :
|
|  Copyright (C), CAS LODZ POLAND.
|  TEL: 42' 862 547, 42' 87 80 44 FAX/TEL: 42' 84 48 40
|
**********************************************************************)
(*.F+ *)

IMPLEMENTATION MODULE SwitchCntrl;

  FROM DGHInterface IMPORT
    SetBinaryVal, GetCurrDataSign, WaitForNewData, DtaSignType;

  FROM DGHIni IMPORT
    SwitchCntrl;

  TYPE
    SwCntrlWrd =
      ARRAY SwState OF BITSET;

  CONST
    TwoBytes = TRUE;

  VAR
    ControlWords : SwCntrlWrd;


  PROCEDURE SwitchTo
            (    config : SwState );

  VAR
    bit       : [ 0 .. 15 ];
    currWord  : BITSET;
    waitCount : CARDINAL;
    dtaSign   : DtaSignType;

  BEGIN
    dtaSign := GetCurrDataSign( );
    currWord := { };
    FOR bit := 0 TO 15 DO
      IF bit IN ControlWords[config]
      THEN
        INCL( currWord, bit );
        SetBinaryVal( SwitchCntrl, currWord, TwoBytes );
        FOR waitCount := 0 TO 2 DO
          WaitForNewData( dtaSign );
        END (* for waitCount *);
        currWord := { };
        SetBinaryVal( SwitchCntrl, currWord, TwoBytes );
      END (* if bit *);
    END (* for bit *);
  END SwitchTo;

BEGIN
  ControlWords[Antena] := {4, 6, 8, 11, 13 };
  ControlWords[MKRa] := {1, 5, 12};
  ControlWords[MKRb] := {1, 5, 12};
  ControlWords[VORa] := {0, 3, 7, 10};
  ControlWords[VORb] := {0, 3, 7, 10};
  ControlWords[GSa]  := {0, 2, 9 };
  ControlWords[GSb]  := {0, 2, 9 };
END SwitchCntrl.
