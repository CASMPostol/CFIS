(*.F- *)
(**********************************************************************
|  Title   : DGH utilities
|  Author  : M.Postol
|  System  : LOGITECH MODULA-2/86
|  History :
|    Rel 3.16: MPostol
|      Aby zaoszczedzic pamiec zostala zdefiniowana iml pusta dla arch
|
|  Copyright (C), CAS LODZ POLAND.
|  TEL: 42' 686 25 47
|  mailto: techsupp@cas.com.pl
|  http: www.cas.com.pl
|
**********************************************************************)
(*.F+ *)
IMPLEMENTATION MODULE DGH_utils;

  FROM CommonTypes IMPORT
    GlownyOdbiornikT;

  FROM Kalibracja IMPORT
    InputSignal;

  FROM MANAGER IMPORT
    Assert;

  FROM  PA_PA IMPORT
    PomiarANieArchiwum;

  PROCEDURE TurnOffILSSig;

  BEGIN
  END TurnOffILSSig;

  PROCEDURE TurnOnLOCSig;

  BEGIN
  END TurnOnLOCSig;

  PROCEDURE TurnOnGSSig;

  BEGIN
  END TurnOnGSSig;

  PROCEDURE TurnOnVORSig;

  BEGIN
  END TurnOnVORSig;

  PROCEDURE TurnOffVORSig;

  BEGIN
  END TurnOffVORSig;

  PROCEDURE TurnOnDMESig;

  BEGIN
  END TurnOnDMESig;

  PROCEDURE TurnOffDMESig;

  BEGIN
  END TurnOffDMESig;

  PROCEDURE TurnOnADFSig;

  BEGIN
  END TurnOnADFSig;

  PROCEDURE TurnOffADFSig;

  BEGIN
  END TurnOffADFSig;

  PROCEDURE ReadValue
            ( VAR zm   : INTEGER;
                  S    : InputSignal;
                  CHN  : GlownyOdbiornikT;
                  prec : REAL             );

  BEGIN
  END ReadValue;

  PROCEDURE ReadOmniber
            ( VAR zm  : INTEGER;
                  rec : GlownyOdbiornikT );
  BEGIN
  END ReadOmniber;

  PROCEDURE BinaryValSet
            (    sn  : BinInputSignal;
                 CHN : GlownyOdbiornikT ) : BOOLEAN;
  BEGIN
    RETURN FALSE;
  END BinaryValSet;

BEGIN
  Assert( NOT PomiarANieArchiwum );
END DGH_utils.
