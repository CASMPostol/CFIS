(*.F- *)
(**********************************************************************
|  Title   : Program testowania ukladu strojenia
|  Author  : Mariusz Postol
|  System  : LOGITECH MODULA-2/86
|  History :
|
|  Copyright (C), CAS LODZ POLAND.
|  TEL: 42' 86 58 12, 42' 87 80 44 FAX/TEL: 42' 84 48 40
|
**********************************************************************)
(*.F+ *)

MODULE Tst_kalibracji;

  IMPORT
    RTSMain, DebugPMD;

  FROM Kalibracja IMPORT
    Par, Lookup, LookupM, OmnibearingV, AGCwartosciProgow, AGCwartosciProgowM,
    AGCwartosciProgowD, LOC_GS_DEVPuntyKal, InputSignal;

  FROM Strings IMPORT
    ConstAssign, Concat, Length;

  FROM Terminal IMPORT
    Read, KeyPressed;

  FROM Conversions IMPORT
    ConvertCardinal, ConvertInteger;

  FROM Tune IMPORT
    Receiver, TurnOffADF, TurnOffVOR_ILS, TuneADF, TuneILS, TuneDMEforILS,
    ILSfrqIdx, ILSfrqString, MaxNAV_Chann_Num, TuneVOR;

  FROM NAVInterface IMPORT
    GetLocDev, GetGSDev, GetOmnibearing;

  FROM DGHInterface IMPORT
    DtaSignType, GetAnalogVal, TurnOn, TurnOff, WaitForNewData, GetBinaryVal;

  FROM DGHIni IMPORT
    SignalNames;

  FROM AltInterface IMPORT
    ALTConvert;

  FROM Int_DME IMPORT
    DMEConvert;

  FROM GrafTypes IMPORT
    WHITE, BLACK, BLUE, GREEN;

  FROM Graphics IMPORT
    FillRect, MaxHor, MaxVer, Wr16StrXY;

  FROM RealConversions IMPORT
    RealToString;

  FROM MathLib0 IMPORT
    real, entier;

  FROM DGH_utils IMPORT
    TurnOnILSSig, TurnOffILSSig, TurnOnVORSig, TurnOffVORSig, TurnOnDMESig,
    TurnOffDMESig, TurnOffADFSig, TurnOnADFSig;

  FROM CocpDsp IMPORT
    UstawFormat, UstawZmienne;

  IMPORT
    CocpDsp, Hrdw_plt;

  CONST
    Line_thickness = 16;

  TYPE
    Proc_cal            =
      PROCEDURE
        (     REAL,
              CARDINAL ) : REAL;
    ConversionProcedure =
      PROCEDURE
        (     BITSET ) : INTEGER;
    State               =
      ( GlowneMenu,
        ILSMenu,
        VORMenu,
        DMEMenu,
        ADFMenu,
        ALTMenu,
        VHFMenu );

  CONST
    BladStr = '******************************';

  VAR
    adfCurrFrq     : CARDINAL;
    vorCurrFrq     : CARDINAL;
    dmeCurrFrq     : ILSfrqIdx;
    locCurrFrq     : ILSfrqIdx;
    markerLowSense : BOOLEAN;
    lastCh         : CHAR;
    lastStr        : ARRAY [0 .. 20] OF CHAR;
    currState      : State;
    disp_curr_X    : CARDINAL;
    disp_curr_Y    : CARDINAL;

  PROCEDURE cscr;

  BEGIN
    disp_curr_X := 0;
    disp_curr_Y := Line_thickness;
    FillRect(0,
             0,
             MaxHor(),
             MaxVer(),
             WHITE);
  END cscr;

  PROCEDURE GoToTop;

  BEGIN
    disp_curr_X := 0;
    disp_curr_Y := Line_thickness;
  END GoToTop;

  PROCEDURE WriteLn;

  BEGIN
    disp_curr_X := 0;
    INC(disp_curr_Y,
        Line_thickness);
  END WriteLn;

  PROCEDURE WriteString
            (    str : ARRAY OF CHAR );

  BEGIN
    IF ODD(disp_curr_Y DIV Line_thickness)
    THEN
      Wr16StrXY(str,
                disp_curr_X,
                disp_curr_Y,
                WHITE,
                BLUE);
    ELSE
      Wr16StrXY(str,
                disp_curr_X,
                disp_curr_Y,
                BLUE,
                WHITE);
    END (* if ODD *);
    INC(disp_curr_X,
        Length(str) * 8);
  END WriteString;

  PROCEDURE Get_WriteBinary
            (    str   : ARRAY OF CHAR;
                 from1 : SignalNames;
                 from2 : SignalNames   );

    PROCEDURE GetVal
              (     from : SignalNames;
                VAR str  : ARRAY OF CHAR );

    CONST
      BitNumber = 0;
      HIstr     = '  HI';
      LOstr     = '  LO';
      ERstr     = '****';
    VAR
      dtaSign : DtaSignType;
      val     : BITSET;

    BEGIN (* GetVal *)
      IF GetBinaryVal(from,
                      val,
                      dtaSign)
      THEN
        IF BitNumber IN val
        THEN
          ConstAssign(HIstr,
                      str);;
        ELSE
          ConstAssign(LOstr,
                      str);
        END (* if BitNumber *);
      ELSE
        ConstAssign(ERstr,
                    str);
      END (* if GetBinaryVal *);
    END GetVal;

  BEGIN (* Get_WriteBinary *)
    WriteLn;
    WriteString(str);
    GetVal(from1,
           lastStr);
    WriteString(lastStr);
    WriteString(' B= ');
    GetVal(from2,
           lastStr);
    WriteString(lastStr);
  END Get_WriteBinary;

  PROCEDURE Convert_Val
            (     what       : INTEGER;
                  scale      : REAL;
                  unit       : ARRAY OF CHAR;
                  unit_cal   : ARRAY OF CHAR;
                  digits     : CARDINAL;
                  digits_cal : CARDINAL;
                  calib      : Proc_cal;
                  channel    : CARDINAL;
              VAR val        : ARRAY OF CHAR );
  VAR
    lastVal_REAL     : REAL;
    lastVal_Cal_REAL : REAL;
    my_string        : ARRAY [0 .. 15] OF CHAR;
    ok               : BOOLEAN;

  BEGIN (* Convert_Val *)
    lastVal_REAL := real(what);
    lastVal_Cal_REAL := calib(lastVal_REAL,
                              channel);
    RealToString(lastVal_Cal_REAL,
                 digits_cal,
                 10,
                 val,
                 ok);
    Concat(val,
           unit_cal,
           val);
    IF ok
    THEN
      RealToString(lastVal_REAL * scale,
                   digits,
                   10,
                   my_string,
                   ok);
      IF ok
      THEN
        Concat(val,
               '(',
               val);
        Concat(val,
               my_string,
               val);
        Concat(val,
               unit,
               val);
        Concat(val,
               ')',
               val);
      ELSE
        Concat(val,
               '(',
               val);
        Concat(val,
               '####################',
               val);
        Concat(val,
               unit,
               val);
        Concat(val,
               ')',
               val);
      END (* if ok *);
    ELSE
      lastStr := '####################';
    END (* if ok *);
  END Convert_Val;

  PROCEDURE Get_WriteAnalog
            (    str        : ARRAY OF CHAR;
                 from1      : SignalNames;
                 from2      : SignalNames;
                 scale      : REAL;
                 unit       : ARRAY OF CHAR;
                 unit_cal   : ARRAY OF CHAR;
                 digits     : CARDINAL;
                 digits_cal : CARDINAL;
                 calib      : Proc_cal      );
  VAR
    lastStr : ARRAY [0 .. 80] OF CHAR;
    lastVal : INTEGER;
    dtaSign : DtaSignType;

  BEGIN (* Get_WriteAnalog *)
    WriteLn;
    WriteString(str);
    IF GetAnalogVal(from1,
                    lastVal,
                    dtaSign)
    THEN
      Convert_Val(lastVal,
                  scale,
                  unit,
                  unit_cal,
                  digits,
                  digits_cal,
                  calib,
                  0,
                  lastStr);
    ELSE
      lastStr := BladStr;
    END (* if GetAnalogVal *);
    WriteString(lastStr);
    WriteString(' B= ');
    IF GetAnalogVal(from2,
                    lastVal,
                    dtaSign)
    THEN
      Convert_Val(lastVal,
                  scale,
                  unit,
                  unit_cal,
                  digits,
                  digits_cal,
                  calib,
                  1,
                  lastStr);
    ELSE
      lastStr := BladStr;
    END (* if GetAnalogVal *);
    WriteString(lastStr);
  END Get_WriteAnalog;

  PROCEDURE Get_WriteBinAnalog
            (    str     : ARRAY OF CHAR;
                 from1   : SignalNames;
                 from2   : SignalNames;
                 convert : ConversionProcedure );

    PROCEDURE GetVal
              (     from : SignalNames;
                VAR val  : ARRAY OF CHAR );
    VAR
      lastVal    : BITSET;
      lastIntVal : INTEGER;
      dtaSign    : DtaSignType;

    BEGIN
      IF GetBinaryVal(from,
                      lastVal,
                      dtaSign)
      THEN
        lastIntVal := convert(lastVal);
        ConvertInteger(lastIntVal,
                       10,
                       val);
      ELSE
        lastStr := '**********';
      END (* if GetAnalogVal *);
    END GetVal;

  BEGIN (* Get_WriteBinAnalog *)
    WriteLn;
    WriteString(str);
    GetVal(from1,
           lastStr);
    WriteString(lastStr);
    WriteString(' B= ');
    GetVal(from2,
           lastStr);
    WriteString(lastStr);
  END Get_WriteBinAnalog;

  PROCEDURE IncFch
            ( VAR fch : ILSfrqIdx;
                  by  : CARDINAL  );

  BEGIN
    INC(fch,
        by);
    IF fch > MaxNAV_Chann_Num
    THEN
      fch := MaxNAV_Chann_Num;
    END (* if fch *);
  END IncFch;

  PROCEDURE DecFch
            ( VAR fch : ILSfrqIdx;
                  by  : CARDINAL  );

  BEGIN
    IF fch > 0
    THEN
      DEC(fch,
          by);
    END (* if fch *);
  END DecFch;

  PROCEDURE VOR_AGC_pc
            (    r       : REAL;
                 channel : CARDINAL ) : REAL;
  VAR
    ok : BOOLEAN;

  BEGIN
    RETURN LookupM(r,
                   AGCwartosciProgow,
                   Par[0].VorAgc,
                   ok)
  END VOR_AGC_pc;

  PROCEDURE VOR_VAR_pc
            (    r       : REAL;
                 channel : CARDINAL ) : REAL;
  VAR
    ok : BOOLEAN;

  BEGIN
    RETURN Lookup(r,
                   VorVarPrcMod,
                   channel,
                   ok);
  END VOR_VAR_pc;

  PROCEDURE VOR_REF_pc
            (    r       : REAL;
                 channel : CARDINAL ) : REAL;
  VAR
    ok : BOOLEAN;

  BEGIN
    RETURN Lookup(r,
                   VorRefPrcMod, channel,
                   ok);
  END VOR_REF_pc;

  PROCEDURE VOR_SUBCAR_pc
            (    r       : REAL;
                 channel : CARDINAL ) : REAL;
  VAR
    ok : BOOLEAN;

  BEGIN
    RETURN Lookup(r,
                   SubcarPrcMod, channel,
                   ok)
  END VOR_SUBCAR_pc;

  PROCEDURE LOC_DEV_pc
            (    r       : REAL;
                 channel : CARDINAL ) : REAL;
  VAR
    ok : BOOLEAN;

  BEGIN
    RETURN LookupM(r,
                   LOC_GS_DEVPuntyKal,
                   Par[channel].LocDev,
                   ok)
  END LOC_DEV_pc;

  PROCEDURE GS_DEV_pc
            (    r       : REAL;
                 channel : CARDINAL ) : REAL;
  VAR
    ok : BOOLEAN;

  BEGIN
    RETURN LookupM(r,
                   LOC_GS_DEVPuntyKal,
                   Par[channel].GsDev,
                   ok)
  END GS_DEV_pc;

  PROCEDURE VOR_OMNIBERI_pc
            (    r       : REAL;
                 channel : CARDINAL ) : REAL;
  VAR
    ok : BOOLEAN;

  BEGIN
    RETURN real(OmnibearingV(entier(r),
                             0,
                             ok)) / 100.0;
  END VOR_OMNIBERI_pc;

  PROCEDURE LOC_MOD_pc
            (    r       : REAL;
                 channel : CARDINAL ) : REAL;
  VAR
    ok : BOOLEAN;

  BEGIN
    RETURN Lookup(r,
                   LocPrcMod,channel,
                   ok);
  END LOC_MOD_pc;

  PROCEDURE LOC_AGC_pc
            (    r       : REAL;
                 channel : CARDINAL ) : REAL;
  VAR
    ok : BOOLEAN;

  BEGIN
    RETURN LookupM(r,
                   AGCwartosciProgow,
                   Par[0].VorAgc,
                   ok);
  END LOC_AGC_pc;

  PROCEDURE MKR_AGC_pc
            (    r       : REAL;
                 channel : CARDINAL ) : REAL;
  VAR
    ok : BOOLEAN;

  BEGIN
    RETURN LookupM(r,
                   AGCwartosciProgowM,
                   Par[0].MkrAgc,
                   ok)
  END MKR_AGC_pc;

  PROCEDURE GS_MOD_pc
            (    r       : REAL;
                 channel : CARDINAL ) : REAL;
  VAR
    ok : BOOLEAN;

  BEGIN
    RETURN Lookup(r,
                   GsPrcMod, channel,
                   ok);
  END GS_MOD_pc;

  PROCEDURE GS_AGC_pc
            (    r       : REAL;
                 channel : CARDINAL ) : REAL;
  VAR
    ok : BOOLEAN;

  BEGIN
    RETURN LookupM(r,
                   AGCwartosciProgow,
                   Par[0].GsAgc,
                   ok)
  END GS_AGC_pc;

  PROCEDURE DME_AGC_pc
            (    r       : REAL;
                 channel : CARDINAL ) : REAL;
  VAR
    ok : BOOLEAN;

  BEGIN
    RETURN LookupM(r,
                   AGCwartosciProgowD,
                   Par[0].DmeAgc,
                   ok)
  END DME_AGC_pc;

  PROCEDURE DME_SQUITTER_pc
            (    r       : REAL;
                 channel : CARDINAL ) : REAL;
  VAR
    ok : BOOLEAN;

  BEGIN
    RETURN Lookup(r,
                   DmeSquitter,channel, 
                   ok);
  END DME_SQUITTER_pc;

  PROCEDURE DME_RPL_pc
            (    r       : REAL;
                 channel : CARDINAL ) : REAL;
  VAR
    ok : BOOLEAN;

  BEGIN
    RETURN Lookup(r,
                   DmePrcReply,channel,
                   ok);
  END DME_RPL_pc;

  PROCEDURE ADF_AGC_pc
            (    r       : REAL;
                 channel : CARDINAL ) : REAL;
  VAR
    ok : BOOLEAN;

  BEGIN
    RETURN LookupM(r,
                   AGCwartosciProgow,
                   Par[channel].AdfAgc,
                   ok)
  END ADF_AGC_pc;

  PROCEDURE COM_AGC_pc
            (    r       : REAL;
                 channel : CARDINAL ) : REAL;
  VAR
    ok : BOOLEAN;

  BEGIN
    RETURN LookupM(r,
                   AGCwartosciProgow,
                   Par[channel].VhfAgc,
                   ok)
  END COM_AGC_pc;

  PROCEDURE ADF_SIN_pc
            (    r       : REAL;
                 channel : CARDINAL ) : REAL;

  BEGIN
    RETURN r;
  END ADF_SIN_pc;

  PROCEDURE ADF_COS_pc
            (    r       : REAL;
                 channel : CARDINAL ) : REAL;

  BEGIN
    RETURN r;
  END ADF_COS_pc;

  PROCEDURE DoILSMenu;

    PROCEDURE WyswietlStan;
    VAR
      lastStr    : ARRAY [0 .. 40] OF CHAR;
      lastVal    : INTEGER;
      distanceBS : BITSET;
      distance   : INTEGER;
      dtaSign    : DtaSignType;
      dev        : INTEGER;
      val        : REAL;
      val_cal    : REAL;

    BEGIN (* WyswietlStan *)
      IF GetBinaryVal(DMEDistanceA,
                      distanceBS,
                      dtaSign)
      THEN
        distance := DMEConvert(distanceBS);
      ELSE
        distance := MIN(INTEGER);
      END (* if GetAnalogVal *);
      IF Hrdw_plt.LOC_DEV_pc(val,
                             val_cal,
                             dtaSign,
                             0)
      THEN
        dev := entier(val_cal + 0.5);
      ELSE
        dev := MIN(INTEGER);
      END (* if Hrdw_plt.LOC_DEV_pc *);
      UstawZmienne(distance DIV 10,
                   dev,
                   dev);
      WriteString('czestotliwosc = ');
      ILSfrqString(locCurrFrq,
                   lastStr);
      WriteString(lastStr);
      IF markerLowSense
      THEN
        WriteString(' MKR Low Sense');
      ELSE
        WriteString(' MKR High Sense');
      END (* if markerLowSense *);
      WriteLn;
      WriteString(' LOC.DEV A= ');
      IF GetLocDev(1,
                   lastVal)
      THEN
        Convert_Val(lastVal,
                    0.01,
                    '   ',
                    'uA ',
                    2,
                    1,
                    LOC_DEV_pc,
                    0,
                    lastStr);
      ELSE
        lastStr := BladStr;
      END (* if GetAnalogVal *);
      WriteString(lastStr);
      WriteString(' B= ');
      IF GetLocDev(2,
                   lastVal)
      THEN
        Convert_Val(lastVal,
                    0.01,
                    '   ',
                    'uA ',
                    2,
                    1,
                    LOC_DEV_pc,
                    1,
                    lastStr);
      ELSE
        lastStr := BladStr;
      END (* if GetAnalogVal *);
      WriteString(lastStr);
      WriteLn;
      WriteString(' GS.DEV A= ');
      IF GetGSDev(1,
                  lastVal)
      THEN
        Convert_Val(lastVal,
                    0.01,
                    '   ',
                    'uA ',
                    2,
                    1,
                    GS_DEV_pc,
                    0,
                    lastStr);
      ELSE
        lastStr := BladStr;
      END (* if GetAnalogVal *);
      WriteString(lastStr);
      WriteString(' B= ');
      IF GetGSDev(2,
                  lastVal)
      THEN
        Convert_Val(lastVal,
                    0.01,
                    '   ',
                    'uA ',
                    2,
                    1,
                    GS_DEV_pc,
                    0,
                    lastStr);
      ELSE
        lastStr := BladStr;
      END (* if GetAnalogVal *);
      WriteString(lastStr);
      WriteLn;
      Get_WriteAnalog(' LOC.MOD A= ',
                      MODforLOCa,
                      MODforLOCb,
                      0.001,
                      'V   ',
                      '%   ',
                      2,
                      1,
                      LOC_MOD_pc);
      Get_WriteAnalog(' LOC.AGC A= ',
                      AGCforNAVa,
                      AGCforNAVb,
                      0.001,
                      'V   ',
                      'uV  ',
                      2,
                      0,
                      LOC_AGC_pc);
      Get_WriteAnalog(' MKR.AGC A= ',
                      AGCforMKRa,
                      AGCforMKRb,
                      0.001,
                      'V   ',
                      'uV  ',
                      2,
                      0,
                      MKR_AGC_pc);
      Get_WriteAnalog('  GS.MOD A= ',
                      MODforGSa,
                      MODforGSb,
                      0.001,
                      'V   ',
                      '%   ',
                      2,
                      1,
                      GS_MOD_pc);
      Get_WriteAnalog('  GS.AGC A= ',
                      AGCforGSa,
                      AGCforGSb,
                      0.001,
                      'V   ',
                      'uV  ',
                      2,
                      0,
                      GS_AGC_pc);
      WriteLn;
      WriteLn;
      Get_WriteBinAnalog('DME.DISTANCE A= ',
                         DMEDistanceA,
                         DMEDistanceB,
                         DMEConvert);
      WriteLn;
      WriteLn;
      Get_WriteBinary('  LOC.SFLG A= ',
                      SFLGforNAVa,
                      SFLGforNAVb);
      Get_WriteBinary('  GS.SFLG A= ',
                      SFLGforGSa,
                      SFLGforGSb);
      Get_WriteBinary('   MKR.OUT A= ',
                      OutMKRa,
                      OutMKRb);
      Get_WriteBinary('   MKR.MID A= ',
                      MidMKRa,
                      MidMKRb);
      Get_WriteBinary('   MKR.INN A= ',
                      InnMKRa,
                      InnMKRb);
      Get_WriteBinary(' NAV.AUDIO A= ',
                      NAVaAudio,
                      NAVbAudio);
      WriteLn;
    END WyswietlStan;

    PROCEDURE WyswietlMenu;

    BEGIN
      cscr;
      WriteString('       0)  wyjdz do glownego menu  ');
      WriteLn;
      WriteString('       1)  zwieksz czestotliwosc   ');
      WriteLn;
      WriteString('       2)  zmniejsz czestotliwosc  ');
      WriteLn;
      WriteString('       3)  wylacz NAV              ');
      WriteLn;
      WriteString('       4)  wlacz monitorowanie NAV ');
      WriteLn;
      WriteString('       5)  zmien MKR HL/LO SENSE   ');
      WriteLn;
      WriteString('       6)  wlacz odbiornik         ');
      WriteLn;
      WyswietlStan;
    END WyswietlMenu;

    PROCEDURE Monitorowanie;
    VAR
      dtaSign : DtaSignType;

    BEGIN
      cscr;
      REPEAT
        WaitForNewData(dtaSign);
        GoToTop;
        WyswietlStan;
      UNTIL KeyPressed();
    END Monitorowanie;

  BEGIN (* DoILSMenu *)
    UstawFormat(CocpDsp.LOCPrad,
                150 DIV 5);
    TurnOnILSSig;
    TuneILS(AReceiver,
            locCurrFrq,
            markerLowSense);
    TuneILS(BReceiver,
            locCurrFrq,
            markerLowSense);
    TurnOn(DMEDistanceA);
    TurnOn(DMEDistanceB);
    TuneDMEforILS(AReceiver,
                  locCurrFrq);
    TuneDMEforILS(BReceiver,
                  locCurrFrq);
    LOOP
      WyswietlMenu;
      Read(lastCh);
      CASE lastCh OF
        '0' :
        (* TurnOffVOR_ILS( AReceiver ); *)
        (* TurnOffVOR_ILS( BReceiver );*)
          TurnOffILSSig;
          UstawFormat(CocpDsp.Idle,
                      MAX(CARDINAL));
          RETURN;
        |
        '1' :
          IncFch(locCurrFrq,
                 1);
          dmeCurrFrq := locCurrFrq;
          TuneILS(AReceiver,
                  locCurrFrq,
                  markerLowSense);
          TuneILS(BReceiver,
                  locCurrFrq,
                  markerLowSense);
          TuneDMEforILS(AReceiver,
                        locCurrFrq);
          TuneDMEforILS(BReceiver,
                        locCurrFrq);
        |
        '2' :
          DecFch(locCurrFrq,
                 1);
          dmeCurrFrq := locCurrFrq;
          TuneILS(AReceiver,
                  locCurrFrq,
                  markerLowSense);
          TuneILS(BReceiver,
                  locCurrFrq,
                  markerLowSense);
          TuneDMEforILS(AReceiver,
                        locCurrFrq);
          TuneDMEforILS(BReceiver,
                        locCurrFrq);
        |
        '3' :
          TurnOffVOR_ILS(AReceiver);
          TurnOffVOR_ILS(BReceiver);
        |
        '4' :
          Monitorowanie;
        |
        '5' :
          markerLowSense := NOT markerLowSense;
        |
        '6' :
          TuneILS(AReceiver,
                  locCurrFrq,
                  markerLowSense);
          TuneILS(BReceiver,
                  locCurrFrq,
                  markerLowSense);
          TuneDMEforILS(AReceiver,
                        locCurrFrq);
          TuneDMEforILS(BReceiver,
                        locCurrFrq);
      ELSE
      END (* case lastCh *);
    END (* loop *);
  END DoILSMenu;

  PROCEDURE DoVORMenu;

    PROCEDURE WyswietlStan;
    VAR
      lastStr : ARRAY [0 .. 80] OF CHAR;
      lastVal : INTEGER;

    BEGIN (* WyswietlStan *)
      WriteString('czestotliwosc = ');
      ConvertCardinal(vorCurrFrq,
                      10,
                      lastStr);
      Concat(lastStr,
             '0kHz',
             lastStr);
      WriteString(lastStr);
      WriteLn;
      WriteLn;
      WriteString('VOR.OMNIBERI A= ');
      IF GetOmnibearing(1,
                        lastVal)
      THEN
        Convert_Val(lastVal,
                    0.01,
                    'deg ',
                    'deg ',
                    2,
                    2,
                    VOR_OMNIBERI_pc,
                    0,
                    lastStr);
      ELSE
        lastStr := BladStr;
      END (* if GetAnalogVal *);
      WriteString(lastStr);
      WriteString(' B= ');
      IF GetOmnibearing(2,
                        lastVal)
      THEN
        Convert_Val(lastVal,
                    0.01,
                    'deg ',
                    'deg ',
                    2,
                    2,
                    VOR_OMNIBERI_pc,
                    1,
                    lastStr);
      ELSE
        lastStr := BladStr;
      END (* if GetAnalogVal *);
      WriteString(lastStr);
      Get_WriteAnalog('     VOR.AGC A= ',
                      AGCforNAVa,
                      AGCforNAVb,
                      0.001,
                      'V   ',
                      'uV  ',
                      2,
                      0,
                      VOR_AGC_pc);
      Get_WriteAnalog('     VOR.VAR A= ',
                      VARa,
                      VARb,
                      0.001,
                      'V   ',
                      '%   ',
                      2,
                      1,
                      VOR_VAR_pc);
      Get_WriteAnalog('     VOR.REF A= ',
                      REFa,
                      REFb,
                      0.001,
                      'V   ',
                      '%   ',
                      2,
                      1,
                      VOR_REF_pc);
      Get_WriteAnalog('  VOR.SUBCAR A= ',
                      SUBCARa,
                      SUBCARb,
                      0.001,
                      'V   ',
                      '%   ',
                      2,
                      1,
                      VOR_SUBCAR_pc);
      WriteLn;
      WriteLn;
      Get_WriteBinary('    VOR.SFLG A= ',
                      SFLGforNAVa,
                      SFLGforNAVb);
      Get_WriteBinary('   NAV.AUDIO A= ',
                      NAVaAudio,
                      NAVbAudio);
    END WyswietlStan;

    PROCEDURE WyswietlMenu;

    BEGIN
      cscr;
      WriteString('       0)  wyjdz do glownego menu           ');
      WriteLn;
      WriteString('       1)  zwieksz czestotliwosc o 50 kHz   ');
      WriteLn;
      WriteString('       2)  zwieksz czestotliwosc o 500 kHz  ');
      WriteLn;
      WriteString('       3)  zwieksz czestotliwosc o 5 MHz    ');
      WriteLn;
      WriteString('       4)  zmniejsz czestotliwosc o 50 kHz  ');
      WriteLn;
      WriteString('       5)  zmniejsz czestotliwosc o 500 kHz ');
      WriteLn;
      WriteString('       6)  zmniejsz czestotliwosc o 5 MHz   ');
      WriteLn;
      WriteString('       7)  wylacz NAV                       ');
      WriteLn;
      WriteString('       8)  wlacz monitorowanie NAV          ');
      WriteLn;
      WyswietlStan;
    END WyswietlMenu;

    PROCEDURE IncFch
              ( VAR fch : CARDINAL;
                    by  : CARDINAL );

    BEGIN
      INC(fch,
          by);
      IF (fch > 11795) AND (fch < 13300)
      THEN
        fch := 13300;
      ELSIF (fch > 13595)
      THEN
        fch := 13595;
      END (* if fch *);
    END IncFch;

    PROCEDURE DecFch
              ( VAR fch : CARDINAL;
                    by  : CARDINAL );

    BEGIN
      DEC(fch,
          by);
      IF fch < 10800
      THEN
        fch := 10800;
      ELSIF (fch < 13300) AND (fch > 11795)
      THEN
        fch := 11795;
      END (* if fch *);
    END DecFch;

    PROCEDURE Monitorowanie;
    VAR
      dtaSign : DtaSignType;

    BEGIN
      cscr;
      REPEAT
        WaitForNewData(dtaSign);
        GoToTop;
        WyswietlStan;
      UNTIL KeyPressed();
    END Monitorowanie;

  BEGIN (* DoVORMenu *)
    TurnOnVORSig;
    TuneVOR(AReceiver,
            vorCurrFrq);
    TuneVOR(BReceiver,
            vorCurrFrq);
    LOOP
      WyswietlMenu;
      Read(lastCh);
      CASE lastCh OF
        '0' :
          TurnOffVORSig;
          RETURN;
        |
        '1' :
          IncFch(vorCurrFrq,
                 5);
        |
        '2' :
          IncFch(vorCurrFrq,
                 50);
        |
        '3' :
          IncFch(vorCurrFrq,
                 500);
        |
        '4' :
          DecFch(vorCurrFrq,
                 5);
        |
        '5' :
          DecFch(vorCurrFrq,
                 50);
        |
        '6' :
          DecFch(vorCurrFrq,
                 500);
        |
        '7' :
          TurnOffVOR_ILS(AReceiver);
          TurnOffVOR_ILS(BReceiver);
        |
        '8' :
          Monitorowanie;
      ELSE
      END (* case lastCh *);
      TuneVOR(AReceiver,
              vorCurrFrq);
      TuneVOR(BReceiver,
              vorCurrFrq);
    END (* loop *);
  END DoVORMenu;

  PROCEDURE DoDMEMenu;

    PROCEDURE WyswietlStan;
    VAR
      lastStr : ARRAY [0 .. 20] OF CHAR;
      lastVal : INTEGER;

    BEGIN (* WyswietlStan *)
      WriteString('czestotliwosc = ');
      ILSfrqString(dmeCurrFrq,
                   lastStr);
      WriteString(lastStr);
      WriteLn;
      Get_WriteAnalog(' DME.AGC A= ',
                      AGCforDMEa,
                      AGCforDMEb,
                      0.001,
                      'V   ',
                      'dBm ',
                      2,
                      0,
                      DME_AGC_pc);
      Get_WriteAnalog('DME.SQUITTER A= ',
                      SQUITTERforDMEa,
                      SQUITTERforDMEb,
                      0.001,
                      'V   ',
                      '    ',
                      2,
                      0,
                      DME_SQUITTER_pc);
      Get_WriteAnalog(' DME.%REPLAY A= ',
                      REPLYforDMEa,
                      REPLYforDMEb,
                      0.001,
                      'V   ',
                      '%   ',
                      2,
                      1,
                      DME_RPL_pc);
      Get_WriteBinary(' DME.MEM A= ',
                      DME_MEMa,
                      DME_MEMb);
      Get_WriteBinary(' DME.SEARCH A= ',
                      DME_SRCa,
                      DME_SRCb);
      Get_WriteBinary(' DME.AUDIO A= ',
                      DMEaAudio,
                      DMEbAudio);
      Get_WriteBinAnalog('DME.DISTANCE A= ',
                         DMEDistanceA,
                         DMEDistanceB,
                         DMEConvert);
    END WyswietlStan;

    PROCEDURE Monitorowanie;
    VAR
      dtaSign : DtaSignType;

    BEGIN (* Monitorowanie *)
      cscr;
      REPEAT
        WaitForNewData(dtaSign);
        GoToTop;
        WyswietlStan;
      UNTIL KeyPressed();
    END Monitorowanie;

    PROCEDURE WyswietlMenu;

    BEGIN (* WyswietlMenu *)
      cscr;
      WriteString('       0)  wyjdz do glownego menu          ');
      WriteLn;
      WriteString('       1)  zwieksz czestotliwosc           ');
      WriteLn;
      WriteString('       2)  zmniejsz czestotliwosc          ');
      WriteLn;
      WriteString('       3)  wlacz monitorowanie odbiornikow ');
      WriteLn;
      WyswietlStan;
    END WyswietlMenu;

  BEGIN (* DoDMEMenu *)
    TurnOnDMESig;
    TuneDMEforILS(AReceiver,
                  dmeCurrFrq);
    TuneDMEforILS(BReceiver,
                  dmeCurrFrq);
    LOOP
      WyswietlMenu;
      Read(lastCh);
      CASE lastCh OF
        '0' :
          TurnOffDMESig;
          RETURN;
        |
        '1' :
          IncFch(dmeCurrFrq,
                 1);
          locCurrFrq := dmeCurrFrq;
          TuneDMEforILS(AReceiver,
                        dmeCurrFrq);
          TuneDMEforILS(BReceiver,
                        dmeCurrFrq);
        |
        '2' :
          DecFch(dmeCurrFrq,
                 1);
          locCurrFrq := dmeCurrFrq;
          TuneDMEforILS(AReceiver,
                        dmeCurrFrq);
          TuneDMEforILS(BReceiver,
                        dmeCurrFrq);
        |
        '3' :
          Monitorowanie;
      ELSE
      END (* case lastCh *);
    END (* loop *);
  END DoDMEMenu;

  PROCEDURE DoADFMenu;

    PROCEDURE WyswietlStan;
    VAR
      lastStr : ARRAY [0 .. 20] OF CHAR;

    BEGIN
      WriteString('czestotliwosc = ');
      ConvertCardinal(adfCurrFrq,
                      10,
                      lastStr);
      WriteString(lastStr);
      WriteLn;
      Get_WriteAnalog(' AGC A=  ',
                      AGCforADFa,
                      AGCforADFb,
                      0.001,
                      'V   ',
                      'uV  ',
                      2,
                      0,
                      ADF_AGC_pc);
      Get_WriteAnalog(' SIN A= ',
                      SINforADFa,
                      SINforADFb,
                      0.001,
                      'V   ',
                      '    ',
                      2,
                      3,
                      ADF_SIN_pc);
      Get_WriteAnalog(' COS A= ',
                      COSforADFa,
                      COSforADFb,
                      0.001,
                      'V   ',
                      '    ',
                      2,
                      3,
                      ADF_COS_pc);
      Get_WriteBinary(' ADF.AUDIO A= ',
                      ADFaAudio,
                      ADFbAudio);
    END WyswietlStan;

    PROCEDURE WyswietlMenu;

    BEGIN
      cscr;
      WriteString('       0)  wyjdz do glownego menu           ');
      WriteLn;
      WriteString('       1)  zwieksz czestotliwosc o 1 kHz    ');
      WriteLn;
      WriteString('       2)  zwieksz czestotliwosc o 10 kHz   ');
      WriteLn;
      WriteString('       3)  zwieksz czestotliwosc o 100 kHz  ');
      WriteLn;
      WriteString('       4)  zmniejsz czestotliwosc o 1 kHz   ');
      WriteLn;
      WriteString('       5)  zmniejsz czestotliwosc o 10 kHz  ');
      WriteLn;
      WriteString('       6)  zmniejsz czestotliwosc o 100 kHz ');
      WriteLn;
      WriteString('       7)  wylacz ADF                       ');
      WriteLn;
      WriteString('       8)  wlacz monitorowanie ADF          ');
      WriteLn;
      WyswietlStan;
    END WyswietlMenu;

    PROCEDURE IncFch
              ( VAR fch : CARDINAL;
                    by  : CARDINAL );

    BEGIN
      INC(fch,
          by);
      IF fch > 1799
      THEN
        fch := 1799;
      END (* if fch *);
    END IncFch;

    PROCEDURE DecFch
              ( VAR fch : CARDINAL;
                    by  : CARDINAL );

    BEGIN
      DEC(fch,
          by);
      IF fch < 190
      THEN
        fch := 190;
      END (* if fch *);
    END DecFch;

    PROCEDURE Monitorowanie;
    VAR
      dtaSign : DtaSignType;

    BEGIN
      cscr;
      REPEAT
        WaitForNewData(dtaSign);
        GoToTop;
        WyswietlStan;
      UNTIL KeyPressed();
    END Monitorowanie;

  BEGIN
    TurnOnADFSig;
    LOOP
      TuneADF(AReceiver,
              adfCurrFrq,
              FALSE,
              TRUE,
              FALSE);
      TuneADF(BReceiver,
              adfCurrFrq,
              FALSE,
              TRUE,
              FALSE);
      WyswietlMenu;
      Read(lastCh);
      CASE lastCh OF
        '0' :
          TurnOffADF(AReceiver);
          TurnOffADF(BReceiver);
          TurnOffADFSig;
          RETURN;
        |
        '1' :
          IncFch(adfCurrFrq,
                 1);
        |
        '2' :
          IncFch(adfCurrFrq,
                 10);
        |
        '3' :
          IncFch(adfCurrFrq,
                 100);
        |
        '4' :
          DecFch(adfCurrFrq,
                 1);
        |
        '5' :
          DecFch(adfCurrFrq,
                 10);
        |
        '6' :
          DecFch(adfCurrFrq,
                 100);
        |
        '7' :
          TurnOffADF(AReceiver);
          TurnOffADF(BReceiver);
        |
        '8' :
          Monitorowanie;
      ELSE
      END (* case lastCh *);
    END (* loop *);
  END DoADFMenu;

  PROCEDURE DoALTMenu;

    PROCEDURE WyswietlStan;
    VAR
      lastStr : ARRAY [0 .. 20] OF CHAR;
      lastVal : INTEGER;

    BEGIN (* WyswietlStan *)
      Get_WriteBinAnalog('     ALTITUDE = ',
                         Altimeter,
                         Altimeter,
                         ALTConvert);
    END WyswietlStan;

    PROCEDURE Monitorowanie;
    VAR
      dtaSign : DtaSignType;
      pass    : BOOLEAN;

    BEGIN
      cscr;
      pass := TRUE;
      REPEAT
        WaitForNewData(dtaSign);
        GoToTop;
        IF pass = TRUE
        THEN
          WriteString('/');
        ELSE
          WriteString('\');
        END (* if *);
        WyswietlStan;
        pass := NOT pass;
      UNTIL KeyPressed();
    END Monitorowanie;

    PROCEDURE WyswietlMenu;

    BEGIN (* WyswietlMenu *)
      cscr;
      WriteString('       0)  wyjdz do glownego menu          ');
      WriteLn;
      WriteString('       1)  wlacz monitorowanie odbiornikow ');
      WriteLn;
      WyswietlStan;
    END WyswietlMenu;

  BEGIN (* DoDMEMenu *)
    TurnOn(Altimeter);
    LOOP
      WyswietlMenu;
      Read(lastCh);
      CASE lastCh OF
        '0' :
          TurnOff(Altimeter);
          RETURN;
        |
        '1' :
          Monitorowanie;
      ELSE
      END (* case lastCh *);
    END (* loop *);
  END DoALTMenu;

  PROCEDURE DoVHFMenu;

    PROCEDURE WyswietlStan;
    VAR
      lastStr : ARRAY [0 .. 20] OF CHAR;
      lastVal : INTEGER;

    BEGIN (* WyswietlStan *)
      Get_WriteAnalog(' AGC A=  ',
                      AGCforCOMa,
                      AGCforCOMb,
                      0.001,
                      'V   ',
                      'uV  ',
                      2,
                      0,
                      COM_AGC_pc);
    END WyswietlStan;

    PROCEDURE Monitorowanie;
    VAR
      dtaSign : DtaSignType;
      pass    : BOOLEAN;

    BEGIN
      cscr;
      pass := TRUE;
      REPEAT
        WaitForNewData(dtaSign);
        GoToTop;
        IF pass = TRUE
        THEN
          WriteString('/');
        ELSE
          WriteString('\');
        END (* if *);
        WyswietlStan;
        pass := NOT pass;
      UNTIL KeyPressed();
    END Monitorowanie;

    PROCEDURE WyswietlMenu;

    BEGIN (* WyswietlMenu *)
      cscr;
      WriteString('       0)  wyjdz do glownego menu          ');
      WriteLn;
      WriteString('       1)  wlacz monitorowanie odbiornikow ');
      WriteLn;
      WyswietlStan;
    END WyswietlMenu;

  BEGIN (* DoVHFMenu *)
    TurnOn(AGCforCOMa);
    TurnOn(AGCforCOMb);
    LOOP
      WyswietlMenu;
      Read(lastCh);
      CASE lastCh OF
        '0' :
          TurnOff(AGCforCOMa);
          TurnOff(AGCforCOMb);
          RETURN;
        |
        '1' :
          Monitorowanie;
      ELSE
      END (* case lastCh *);
    END (* loop *);
  END DoVHFMenu;

  PROCEDURE WylaczWszystko;

  BEGIN
    TurnOffADF(AReceiver);
    TurnOffADF(BReceiver);
    TurnOffVOR_ILS(AReceiver);
    TurnOffVOR_ILS(BReceiver);
  END WylaczWszystko;

  PROCEDURE WyswietlGlowneMenu;

  BEGIN
    cscr;
    WriteString('       0)  zakoncz program              ');
    WriteLn;
    WriteString('       1)  menu dla ILS                 ');
    WriteLn;
    WriteString('       2)  menu dla VOR                 ');
    WriteLn;
    WriteString('       3)  menu dla DME                 ');
    WriteLn;
    WriteString('       4)  menu dla ADF                 ');
    WriteLn;
    WriteString('       5)  menu dla VHF                 ');
    WriteLn;
    WriteString('       6)  menu dla wysokosciomierza    ');
    WriteLn;
    WriteString('       7)  wylacz wszystkie urzadzenia  ');
    WriteLn;
  END WyswietlGlowneMenu;

BEGIN
  UstawFormat(CocpDsp.Idle,
              MAX(INTEGER));
  markerLowSense := TRUE;
  vorCurrFrq := 10800;
  dmeCurrFrq := 0;
  locCurrFrq := 0;
  adfCurrFrq := 190;
  currState := GlowneMenu;
  LOOP
    CASE currState OF
      GlowneMenu :
        WyswietlGlowneMenu;
        Read(lastCh);
        CASE lastCh OF
          '0' :
            RTSMain.Terminate(RTSMain.Stopped);
          |
          '1' :
            currState := ILSMenu;
          |
          '2' :
            currState := VORMenu;
          |
          '3' :
            currState := DMEMenu;
          |
          '4' :
            currState := ADFMenu;
          |
          '5' :
            currState := VHFMenu;
          |
          '6' :
            currState := ALTMenu;
          |
          '7' :
            WylaczWszystko;
        ELSE
          (* Do nothing *)
        END (* case lastCh *);
      |
      VORMenu :
        DoVORMenu;
        currState := GlowneMenu;
      |
      ILSMenu :
        DoILSMenu;
        currState := GlowneMenu;
      |
      DMEMenu :
        DoDMEMenu;
        currState := GlowneMenu;
      |
      ADFMenu :
        DoADFMenu();
        currState := GlowneMenu;
      |
      ALTMenu :
        DoALTMenu();
        currState := GlowneMenu;
      |
      VHFMenu :
        DoVHFMenu();
        currState := GlowneMenu;
    END (* case currState *);
  END (* loop *);
END Tst_kalibracji.
