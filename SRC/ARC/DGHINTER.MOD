(*.F- *)
(**********************************************************************
|  Title   : Iterface to DGH modules connected through Digibord card.
|  Author  : M.Postol
|  System  : LOGITECH MODULA-2/86
|  History :
|    Rel 3.16: MPostol
|      Aby zaoszczedzic pamiec zostala zdefiniowana imp pusta dla arch
|  
|  Copyright (C), CAS LODZ POLAND.
|  TEL: 42' 686 25 47
|  mailto: techsupp@cas.com.pl
|  http: www.cas.com.pl
|
**********************************************************************)

IMPLEMENTATION MODULE DGHInterface;

  FROM DGHIni IMPORT
    SignalNames;

  FROM PA_PA IMPORT
    PomiarANieArchiwum;

  FROM MANAGER IMPORT
    Assert;

  PROCEDURE GetCurrDataSign() : DtaSignType;

  BEGIN
    RETURN 0;
  END GetCurrDataSign;

  PROCEDURE WaitForNewData
            ( VAR dtaSign : DtaSignType );

  BEGIN
  END WaitForNewData;

  PROCEDURE TurnOff( what: SignalNames);
  BEGIN
  END TurnOff;
  
  PROCEDURE TurnOn( what: SignalNames);
  BEGIN
  END TurnOn;
  
  PROCEDURE GetAnalogVal
            (     from    : SignalNames;
              VAR val     : INTEGER;
              VAR dtaSign : DtaSignType) : BOOLEAN;
  BEGIN
    RETURN FALSE;
  END GetAnalogVal;

  PROCEDURE GetBinaryVal
            (     from    : SignalNames;
              VAR val     : BITSET;
              VAR dtaSign : DtaSignType) : BOOLEAN;
  BEGIN
    RETURN FALSE;
  END GetBinaryVal;

  PROCEDURE SetAnalogVal
            (     from    : SignalNames;
                  val     : INTEGER;
              VAR dtaSign : DtaSignType);
  BEGIN
  END SetAnalogVal;

  PROCEDURE SetBinaryVal
            (     from     : SignalNames;
                  val      : BITSET;
                  twoBytes : BOOLEAN);
  BEGIN
  END SetBinaryVal;

  PROCEDURE  SetMessage
             (    num     : CARDINAL;
                  digits  : Number;
              VAR dtaSign : DtaSignType);
  BEGIN
  END SetMessage;

BEGIN
  Assert( NOT PomiarANieArchiwum );
END DGHInterface.
