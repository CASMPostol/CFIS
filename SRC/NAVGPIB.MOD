(*.F- *)
(**********************************************************************
|  Title   : Access to NAV generator by BPIB Interface
|  Author  : M.Postol
|  System  : LOGITECH MODULA-2/86
|  History :
|    01-09-96: created
|    11-09-96: M.Postol
|      switch control was added
|    23-03-97: M.Postol
|      w MKR_Default nie przelaczal przelacznikow, gdy nie bylo generatora 
|      przez GPIB
|    Rel 3.0. MPostol
|      Dla ustawien domyslnych LOCVOR, GS, MKR nie byly uwzglednione 
|      wspolczynniki tlumienia przelacznikow w.cz.
|
|
|  Copyright (C), CAS LODZ POLAND.
|  TEL: 42' 686 25 47
|  mailto: techsupp@cas.com.pl
|  http: www.cas.com.pl
|
**********************************************************************)
(*.F+ *)
IMPLEMENTATION MODULE NAVGPIB;

  FROM StdIO IMPORT
    sprintf;

  FROM M_PGPIB IMPORT
    ieabort, iestatus, ieinit, ieoutput, ieenter, IOCheck, 
    GPIBPresent, lstring, ietimout;

  FROM Strings IMPORT
    Length, Delete;

  FROM Tune IMPORT
    TuneVOR, Receiver, TuneILS;
  
  FROM SwitchCntrl IMPORT
    SwState, SwitchTo;

  FROM Kalibracja  IMPORT
    AgcInput, inputCoeff;
    
  FROM Timer IMPORT
    Wait, TInOneSecond;
    
  CONST
    DMA_SB              = 15;
    DMATransfer_SB      = 14;
    SystemController_SB = 9;
    IRQ2_SB             = 4;
    IRQ1_SB             = 3;
    IRQ0_SB             = 2;
    DMA1_SB             = 1;
    DMA0_SB             = 0;
    setting             = 0H;
    SW1Setting          = 02B0H;
    IOAddress           = SW1Setting + 8;
    GPIBAddr            = 21;
    NAVGPIBAddr         = 20;
    MarkerLowSense      = TRUE;
    
  VAR
    simpleComm       : ARRAY CommandSimple OF lstring;
    realComm         : ARRAY CommandRealPar OF lstring;
    lastGPIBCommand  : lstring;
    lastGPIBResponse : lstring;
    status           : INTEGER;
    FirstLocal       : BOOLEAN;
    CommCount        : CARDINAL;
    
  PROCEDURE  ConvertTMStr(VAR str: ARRAY OF CHAR);
  BEGIN
    IF str[0] <> 0C  THEN
      str[ORD(str[0])+1] := 0C;
      Delete(str, 0, 1);
    END;
  END ConvertTMStr;
  
  PROCEDURE GetResponse() : BOOLEAN;
  
  BEGIN
    IF NOT IOCheck()
    THEN
      lastGPIBError := GPIB_InterfaceError;
      RETURN FALSE;
    END (* if *);
    lastGPIBResponse := "XXXXXXXXXXXXXXXXXXXXX";
    lastGPIBResponse[0] := CHAR(HIGH(lastGPIBResponse)-1);
    ieenter(NAVGPIBAddr, lastGPIBResponse);
    ConvertTMStr(lastGPIBResponse);
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
  
  VAR
    loopCount    : CARDINAL;
    loopCountmax : CARDINAL;
    Line         : CARDINAL;
    
  PROCEDURE DoSimpleComm
            (    comm : CommandSimple ) : BOOLEAN;

  VAR
    tpComm: lstring;
  BEGIN
    INC(CommCount);
    lastGPIBCommand := simpleComm[comm];
    tpComm := lastGPIBCommand;
    tpComm[0] := CHR(Length(lastGPIBCommand));
    ieoutput(NAVGPIBAddr, tpComm);
    loopCount := 0;
    WHILE NOT GetResponse() DO
      Line := 141;
      IF loopCount < 2  THEN
        INC(loopCount);
        IF loopCountmax < loopCount THEN
          loopCountmax := loopCount;
        END;
      ELSE   
        Line := 147;
        RETURN FALSE;
      END;
      Wait( TInOneSecond() );
    END;
    RETURN TRUE;
  END DoSimpleComm;

  PROCEDURE DoCommandRealPar
            (    comm : CommandRealPar;
                 par  : REAL           ) : BOOLEAN;
  VAR
    tpComm: lstring;
  BEGIN
    sprintf(lastGPIBCommand, realComm[comm], par);
    tpComm := lastGPIBCommand;
    tpComm[0] := CHR(Length(lastGPIBCommand));
    ieoutput(NAVGPIBAddr, tpComm);
    RETURN GetResponse();
  END DoCommandRealPar;

  PROCEDURE VOR_Default() : BOOLEAN;

  VAR
    ok         : BOOLEAN;
    vorCurrFrq : CARDINAL;
  BEGIN
    IF NOT GPIBPresent()
    THEN
      lastGPIBError := GPIB_NOTPresent;
      RETURN FALSE;
    END (* if *);
    ok := DoSimpleComm(MdeVOR);
    ok := ok AND DoSimpleComm(Default);
    ok := ok AND DoSimpleComm(VorRefFrom);
    ok := ok AND DoSimpleComm(IdentOff);
    ok := ok AND DoCommandRealPar(Bearing, 0.0);
    ok := ok AND DoCommandRealPar(RFLevel, 100.0 * inputCoeff[0, AGCLocVor] );
    ok := ok AND DoCommandRealPar(Bearing, 0.0);
    ok := ok AND DoCommandRealPar(RFFreq, 114.90);
    ok := ok AND DoSimpleComm(Local);
    vorCurrFrq := 11490;
    TuneVOR(AReceiver, vorCurrFrq);
    TuneVOR(BReceiver, vorCurrFrq);
    SwitchTo(VORa);
    SwitchTo(VORb);
    iestatus(8, status);
    RETURN ok;
  END VOR_Default;

  PROCEDURE LOC_Default() : BOOLEAN;

  VAR
    ok : BOOLEAN;

  BEGIN
    IF NOT GPIBPresent()
    THEN
      lastGPIBError := GPIB_NOTPresent;
      RETURN FALSE;
    END (* if *);
    ok := DoSimpleComm(MdeLOC);
    ok := ok AND DoSimpleComm(Default);
    ok := ok AND DoSimpleComm(IdentOff);
    ok := ok AND DoCommandRealPar(DDM, 0.0);
    ok := ok AND DoCommandRealPar(RFLevel, 100.0 * inputCoeff[0, AGCLocVor] );
    ok := ok AND DoCommandRealPar(RFFreq, 110.10);
    ok := ok AND DoSimpleComm(Local);
    TuneILS(AReceiver, 20, MarkerLowSense);
    TuneILS(BReceiver, 20, MarkerLowSense);
    SwitchTo(VORa);
    SwitchTo(VORb);
    iestatus(8, status);
    RETURN ok;
  END LOC_Default;

  PROCEDURE GS_Default() : BOOLEAN;

  VAR
    ok : BOOLEAN;

  BEGIN
    IF NOT GPIBPresent()
    THEN
      lastGPIBError := GPIB_NOTPresent;
      RETURN FALSE;
    END (* if *);
    ok := DoSimpleComm(MdeGS);
    ok := ok AND DoSimpleComm(Default);
    ok := ok AND DoCommandRealPar(DDM, 0.0);
    ok := ok AND DoCommandRealPar(RFLevel, 700.0 * inputCoeff[0, AGCGs] );
    ok := ok AND DoCommandRealPar(RFFreq, 334.40);
    ok := ok AND DoSimpleComm(Local);
    TuneILS(AReceiver, 20, MarkerLowSense);
    TuneILS(BReceiver, 20, MarkerLowSense);
    SwitchTo(GSa);
    SwitchTo(GSb);
    iestatus(8, status);
    RETURN ok;
  END GS_Default;

  PROCEDURE MKR_Default() : BOOLEAN;

  VAR
    ok : BOOLEAN;

  BEGIN
    IF NOT GPIBPresent()
    THEN
      lastGPIBError := GPIB_NOTPresent;
      RETURN FALSE;
    END (* if *);
    ok := DoSimpleComm(MdeMkr);
    ok := ok AND DoSimpleComm(Default);
    ok := ok AND DoSimpleComm(IdentOff);
    ok := ok AND DoSimpleComm(MkrOut);
    ok := ok AND DoCommandRealPar(RFLevel, 1000.0 * inputCoeff[0, AGCMkr]);
    ok := ok AND DoSimpleComm(Local);
    SwitchTo(MKRa);
    SwitchTo(MKRb);
    iestatus(8, status);
    RETURN ok;
  END MKR_Default;
  
BEGIN
  loopCountmax :=0;
  CommCount := 0;
  simpleComm[MdeVOR ] := ' MODE= VOR';
  simpleComm[MdeLOC ] := ' MODE= LOC';
  simpleComm[MdeGS  ] := ' MODE= G/S';
  simpleComm[MdeMkr ] := ' MODE= MKR';
  simpleComm[Local] := ' LOCAL';
  simpleComm[Default] := ' DEFAULT';
  simpleComm[MkrOut] := ' MKR MODE= OUTER';
  simpleComm[MkrMid] := ' MKR MODE= MIDDLE';
  simpleComm[MkrInn] := ' MKR MODE= INNER';
  simpleComm[VorRefFrom] := ' VOR REF= FROM';
  simpleComm[VorRefTo] := ' VOR REF= TO';
  simpleComm[LocRefRight] := ' LOC REF= RIGHT';
  simpleComm[LocRefLeft] := ' LOC REF= LEFT';
  simpleComm[GSRefUp] := ' G/S REF= UP';
  simpleComm[GSRefDown] := ' G/S REF= DOWN';
  simpleComm[IdentOff] := ' IDENT MODE= OFF';
  realComm[RFLevel] := ' RF LEVEL= %9.5lf uV';
  realComm[Bearing] := ' BEARING= %6.2lf';
  realComm[DDM] := ' DDM=  %4.3lf';
  realComm[RFFreq] := ' RF FREQ= %9.5lf';
  realComm[Mod30Hz] :=   ' 30HZ %%MOD= %6.2lf';
  realComm[Mod90Hz] :=   ' 90HZ %%MOD= %5.1lf';
  realComm[Mod150Hz] :=  ' 150HZ %%MOD= %5.1lf';
  realComm[Mod9960Hz] := ' 9960HZ %%MOD= %6.2lf';
  realComm[ModTotal] :=  ' TOTAL %%MOD= %6.2lf';
  IF NOT GPIBPresent()
  THEN
     lastGPIBError := GPIB_NOTPresent;
  ELSE
    lastGPIBError := GPIB_Ok;
    ieinit(IOAddress, GPIBAddr, setting);
    ieabort;
    ietimout(1000 (* MAX(INTEGER) *)  );
    iestatus(8, status);
    (* FirstLocal := DoSimpleComm(Local); *)
  END (* if *);
END NAVGPIB.
