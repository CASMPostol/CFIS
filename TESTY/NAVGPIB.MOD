(*.F- *)
(**********************************************************************
|  Title   : Access to NAV generator by BPIB Interface
|  Author  : M.Postol
|  System  : LOGITECH MODULA-2/86
|  History :
|
|  Copyright (C), CAS LODZ POLAND.
|  TEL: 42' 862 547, 42' 87 80 44 FAX/TEL: 42' 84 48 40
|
**********************************************************************)
(*.F+ *)

MODULE NAVGPIB;

  FROM StdIO IMPORT
    sprintf;

  FROM M_PGPIB IMPORT
    ieinit, ieoutput, ieenter, IOCheck, GPIBPresent, iestatus;

  FROM Strings IMPORT
    Length;

  FROM MANAGER IMPORT
    Assert;

  CONST
    DMA_SB              = 15;
    DMATransfer_SB      = 14;
    SystemController_SB = 9;
    IRQ2_SB             = 4;
    IRQ1_SB             = 3;
    IRQ0_SB             = 2;
    DMA1_SB             = 1;
    DMA0_SB             = 0;
    setting             = 0;
    SW1Setting          = 02B0H;
    IOAddress           = SW1Setting + 8;
    GPIBAddr            = 21;
    NAVGPIBAddr         = 26;  (* ustalic to *)

  TYPE
    CommandSimple  =
      ( Local,
        Default,
        MkrOut,
        MkrMid,
        MkrInn,
        VorRefFrom,
        VorRefTo,
        LocRefRight,
        LocRefLeft,
        GSRefUp,
        GSRefDown,
        IdentOff );
    CommandRealPar =
      ( RFLevel,
        Bearing,
        DDM,
        RFFreq );
    String80       =
      ARRAY [0 .. 79] OF CHAR;
    String32       =
      ARRAY [0 .. 31] OF CHAR;
    GPIB_Result    =
      ( GPIB_Ok,
        GPIB_InterfaceError,
        GPIB_LackOfResponse,
        GPIB_Urecognizable,
        GPIB_InvalidPar,
        GPIB_InvalidCommand,
        GPIB_NavError,
        GPIB_BadNavResponse,
        GPIB_NOTPresent );

  VAR
    simpleComm       : ARRAY CommandSimple OF String32;
    realComm         : ARRAY CommandRealPar OF String32;
    lastGPIBError    : GPIB_Result;
    lastGPIBCommand  : String80;
    lastGPIBResponse : String32;

  PROCEDURE GetResponse() : BOOLEAN;

  BEGIN
    IF NOT IOCheck()
    THEN
      lastGPIBError := GPIB_InterfaceError;
      RETURN FALSE;
    END (* if *);
    ieenter(NAVGPIBAddr, lastGPIBResponse);
    IF Length(lastGPIBResponse) = 0
    THEN
      lastGPIBError := GPIB_LackOfResponse;
      RETURN FALSE;
    ELSIF lastGPIBResponse[0] = '*'
    THEN
      lastGPIBError := GPIB_Ok;
      RETURN TRUE;
    ELSIF lastGPIBResponse[0] = '?'
    THEN
      lastGPIBError := GPIB_Urecognizable;
      RETURN FALSE;
    ELSIF lastGPIBResponse[0] = '#'
    THEN
      lastGPIBError := GPIB_InvalidPar;
      RETURN FALSE;
    ELSIF lastGPIBResponse[0] = '!'
    THEN
      lastGPIBError := GPIB_InvalidCommand;
      RETURN FALSE;
    ELSIF lastGPIBResponse[0] = '%'
    THEN
      lastGPIBError := GPIB_NavError;
      RETURN FALSE;
    ELSE
      lastGPIBError := GPIB_BadNavResponse;
      RETURN FALSE;
    END (* if Length *);
  END GetResponse;

  PROCEDURE DoSimpleComm
            (    comm : CommandSimple ) : BOOLEAN;

  BEGIN
    ieoutput(NAVGPIBAddr, simpleComm[comm]);
    RETURN GetResponse();
  END DoSimpleComm;

  PROCEDURE DoCommandRealPar
            (    comm : CommandRealPar;
                 par  : REAL           ) : BOOLEAN;

  BEGIN
    sprintf(lastGPIBCommand, realComm[comm], par);
    ieoutput(NAVGPIBAddr, lastGPIBCommand);
    RETURN GetResponse();
  END DoCommandRealPar;

  PROCEDURE VOR_Default() : BOOLEAN;
  VAR
    ok : BOOLEAN;

  BEGIN
    IF NOT GPIBPresent()
    THEN
      lastGPIBError := GPIB_NOTPresent;
      RETURN FALSE;
    END (* if *);
    ok := DoSimpleComm(Default) AND DoSimpleComm(VorRefFrom) AND DoSimpleComm(
          IdentOff);
    IF NOT ok
    THEN
      RETURN FALSE
    END (* if *);
    ok := DoCommandRealPar(Bearing, 0.0) AND DoCommandRealPar(RFLevel, 0.1) AND
          DoCommandRealPar(Bearing, 0.0) AND DoCommandRealPar(Bearing, 114.90);
    RETURN ok;
  END VOR_Default;
VAR
  status: INTEGER;
BEGIN
  simpleComm[Local] := 'LOCAL';
  simpleComm[Default] := 'DEFAULT';
  simpleComm[MkrOut] := 'MKR MODE= OUTER';
  simpleComm[MkrMid] := 'MKR MODE= MIDDLE';
  simpleComm[MkrInn] := 'MKR MODE= INNER';
  simpleComm[VorRefFrom] := 'VOR REF= FROM';
  simpleComm[VorRefTo] := 'VOR REF= TO';
  simpleComm[LocRefRight] := 'LOC REF= RIGHT';
  simpleComm[LocRefLeft] := 'LOC REF= LEFT';
  simpleComm[GSRefUp] := 'G/S REF= UP';
  simpleComm[GSRefDown] := 'G/S REF= DOWN';
  simpleComm[IdentOff] := 'IDENT MODE= OFF';
  realComm[RFLevel] := 'RF LEVEL= %9.5lf mV';
  realComm[Bearing] := 'BEARING= %6.2lf';
  realComm[DDM] := 'DDM=  %4.3lf';
  realComm[RFFreq] := 'RF FREQ= %9.5lf';
  IF NOT GPIBPresent()
  THEN
     lastGPIBError := GPIB_NOTPresent;
  ELSE
    lastGPIBError := GPIB_Ok;
    ieinit(IOAddress, GPIBAddr, setting);
    iestatus(11, status);
  END (* if *);
END NAVGPIB.
