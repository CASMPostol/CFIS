(*.F- *)
(**********************************************************************
|  Title   : Procedury uzytkowe dla programu kalibracji
|  Author  : Mariusz Postol
|  System  : LOGITECH MODULA-2/86
|  History :
|
|  Copyright (C), CAS LODZ POLAND.
|  TEL: 42' 86 58 12, 42' 87 80 44 FAX/TEL: 42' 84 48 40
|
**********************************************************************)
(*.F+ *)

IMPLEMENTATION MODULE Kl_Utils;

  FROM RealConversions IMPORT
    RealToString;

  FROM Strings IMPORT
    ConstAssign, Concat, Length;

  FROM DGHInterface IMPORT
    DtaSignType;

  FROM Hrdw_plt IMPORT
    CommCh;

  CONST
    BladStr = '******************************';

  PROCEDURE Get_Format_Signal
            (     pktCal   : REAL;
                  unit       : ARRAY OF CHAR;
                  unit_cal   : ARRAY OF CHAR;
                  digits     : CARDINAL;
                  digits_cal : CARDINAL;
                  calib      : Input_Proc_cal;
                  channel    : CommCh;
              VAR result     : ARRAY OF CHAR;
              VAR dtaSign    : DtaSignType    );
  VAR
    lastVal     : REAL;
    lastVal_Cal : REAL;
    my_string   : ARRAY [0 .. 15] OF CHAR;
    ok          : BOOLEAN;

  BEGIN (* Get_Format_Signal *)
    ConstAssign("",
                result);
    IF calib(lastVal,
             lastVal_Cal,
             dtaSign,
             channel)
    THEN
      RealToString(lastVal_Cal,
                   digits,
                   10,
                   my_string,
                   ok);
      IF NOT ok
      THEN
        ConstAssign('##########',
                    my_string);
      END (* if ok *);
      Concat(result,
             my_string,
             result);
      Concat(result,
             "    delta= ",
             result);
      RealToString(lastVal_Cal-pktCal,
                   digits,
                   6,
                   my_string,
                   ok);
      IF NOT ok
      THEN
        ConstAssign('##########',
                    my_string);
      END (* if ok *);
      Concat(result,
             my_string,
             result);
      RealToString(lastVal,
                   digits,
                   10,
                   my_string,
                   ok);
      IF NOT ok
      THEN
        ConstAssign('##########',
                    my_string);
      END (* if ok *);
      Concat(result,
             '(',
             result);
      Concat(result,
             my_string,
             result);
      Concat(result,
             unit,
             result);
      Concat(result,
             ')',
             result);
    ELSE
      ConstAssign(BladStr,
                  result);
    END (* if calib *);
  END Get_Format_Signal;

END Kl_Utils.
