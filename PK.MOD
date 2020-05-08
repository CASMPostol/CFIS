(*.F- *)
(**********************************************************************
|  Title   : Program testowania ukladu strojenia
|  Author  : Mariusz Postol
|  System  : LOGITECH MODULA-2/86
|  History :
|  Rel. 001 01.01.1996: new
|    05-02-97: M.Postol
|      zablokowalem PrintScr
|    21-02-97: M.Postpl
|      ujednolicono nazewnictwo kanalow.
|    23-05-97: M.Postol
|      blad edycyjny w proc. ADF
|    25-02-98: M.Postol
|      blad w procedurze ADFDecFchby1 - brak strojenia
|
|  Copyright (C), CAS LODZ POLAND.
|  TEL: 42' 86 58 12, 42' 87 80 44 FAX/TEL: 42' 84 48 40
|
**********************************************************************)
(*.F+ *)

MODULE PK;

  IMPORT
    DebugPMD, DOSEntry, RTSMain, ErrorMess, MsgBox, GrafUtil;

  (* IMPORT GPSRead, TheodolitRead; *)

  FROM SYSTEM IMPORT
    ADDRESS, ADR;
    
  FROM Skl_utls IMPORT
    KalibracjaVorRef, KalibracjaVorVar, KalibracjaOmnibearing, KalibracjaSubcar
    , KalibracjaLocDev, KalibracjaLocMod, KalibracjaVorAGC, KalibracjaGsDev,
    KalibracjaGsMod, KalibracjaMkrAGC, KalibracjaGsAGC, KalibracjaDmeSquitter,
    KalibracjaDmeReply, KalibracjaDmeAGC, KalibracjaADF, KalibracjaVHF, 
    ILSWszystko, VORWszystko, KalibracjaLocAGC;

  FROM Dialog IMPORT
    HDLG, TworzDialog, UsunDialog, WstawListe, Go, WstawButton, EndDialog, 
    AltF4;

  FROM GList IMPORT
    HLIST, DodajDoListy, GetSelection, SetSelection, SetContents, GetContents,
    HCONTENT, KillContents;

  FROM Buttons IMPORT
    Button;

  FROM ShortCuts IMPORT
    kbAltA, kbAltM, kbAltK, kbEnter, kbF1, kbF2, kbF3, kbF4, kbF5, kbF6, 
    kbAltW, kbAltO, kbAltF4;

  FROM Graphics IMPORT
    MaxHor, MaxVer, _Wr16StrXY;

  FROM HiLevGraf IMPORT
    FillRect;

  FROM Strings IMPORT
    ConstAssign, Concat, Length, Insert;

  FROM Terminal IMPORT
    Read, KeyPressed;

  FROM Conversions IMPORT
    ConvertCardinal, ConvertInteger;

  FROM Tune IMPORT
    Receiver, TurnOffADF, TurnOffVOR_ILS, TuneADF, TuneILS, TuneDMEforVOR,
    TuneDMEforILS, ILSfrqIdx, ILSfrqString, TuneVOR, DecADFFch, IncADFFch,
    VORDecFch, VORIncFch, ILSDecFch, ILSIncFch, SetCPFlags;

  FROM DGHInterface IMPORT
    DtaSignType, TurnOn, TurnOff, WaitForNewData, GetBinaryVal;

  FROM DGHIni IMPORT
    SignalNames;

  FROM AltInterface IMPORT
    ALTConvert;

  FROM Int_DME IMPORT
    DMEConvert;

  FROM GrafTypes IMPORT
    WHITE, BLACK, BLUE, GREEN, RECT, AssignRect, MoveRect;

  FROM RealConversions IMPORT
    RealToString;

  FROM MathLib0 IMPORT
    entier;

  FROM DGH_utils IMPORT
    TurnOnLOCSig, TurnOnGSSig, TurnOffILSSig, TurnOnVORSig, TurnOffVORSig, 
    TurnOnDMESig, TurnOffDMESig, TurnOffADFSig, TurnOnADFSig;

  FROM CocpDsp IMPORT
    UstawFormat, UstawZmienne, State;

  FROM GrafUtil IMPORT
    Info;

  FROM Hrdw_plt IMPORT
    CommCh, LOC_DEV_pc, VOR_AGC_pc, VOR_VAR_pc, VOR_REF_pc, VOR_SUBCAR_pc,
    VOR_OMNIBERI_pc, GS_DEV_pc, LOC_MOD_pc, LOC_AGC_pc, MKR_AGC_pc, GS_MOD_pc,
    GS_AGC_pc, DME_AGC_pc, DME_Distance_pc, DME_SQUITTER_pc, DME_RPL_pc,
    ADF_AGC_pc, ADF_SIN_pc, ADF_COS_pc, VHF_AGC_pc;
  
  FROM NAVGPIB  IMPORT
    DoSimpleComm, CommandSimple;
    
  FROM SoftIntHandlingManager IMPORT
    InstPrologueHnd, Template, PrintScreen, BreakChain;

  CONST
    Line_thickness = 16;

  TYPE
    ConversionProcedure =
      PROCEDURE
        (     BITSET ) : INTEGER;
    Input_Proc_cal      =
      PROCEDURE
        ( VAR REAL,
          VAR REAL,
          VAR DtaSignType,
              CommCh      ) : BOOLEAN;

  CONST
    scrBackground = WHITE;
    BladStr       = '******************************';
  TYPE
    Operacja = (Kalibracja, KalibracjaAuto, Monitorowanie, Wyjscie);
  VAR
    nastOperacja : Operacja;
    ScreenR        : RECT;
    adfCurrFrq     : CARDINAL;
    vorCurrFrq     : CARDINAL;
    locCurrFrq     : ILSfrqIdx;
    markerLowSense : BOOLEAN;
    lastStr        : ARRAY [0 .. 20] OF CHAR;
    disp_curr_X    : CARDINAL;
    disp_curr_Y    : CARDINAL;

  PROCEDURE DoKalibr;

  BEGIN
    nastOperacja := Kalibracja;
    EndDialog(TRUE);
  END DoKalibr;

  PROCEDURE DoAutoKalibr;

  BEGIN
    nastOperacja := KalibracjaAuto;
    EndDialog(TRUE);
  END DoAutoKalibr;

  PROCEDURE DoMonitorowanie;

  BEGIN
    nastOperacja := Monitorowanie;
    EndDialog(TRUE);
  END DoMonitorowanie;

  PROCEDURE DoWyjscie;

  BEGIN
    nastOperacja := Wyjscie;
    EndDialog(TRUE);
  END DoWyjscie;

  PROCEDURE InitScreen
            ( VAR hDlg     : HDLG;
              VAR listaUrz : HLIST;
              VAR listaKan : HLIST;
                  jestAuto : BOOLEAN );
  VAR
    Rectangle : RECT;
    but       : Button;
    moveDis   : CARDINAL;
  BEGIN
    cscr;
    hDlg := TworzDialog(ScreenR, "ss.bmp", FALSE);
    AssignRect(Rectangle, 50, 250, 200, 500);
    listaUrz := WstawListe(hDlg, Rectangle, FALSE);
    KillContents(listaUrz, FALSE);
    MoveRect(Rectangle, 200, 0);
    listaKan := WstawListe(hDlg, Rectangle, FALSE);
    KillContents(listaKan, FALSE);
    IF NOT jestAuto THEN
      AssignRect(Rectangle, 50, 120, 350, 180);
      moveDis := 400;
    ELSE
      AssignRect(Rectangle, 50, 120, 250, 180);
      moveDis := 250;
    END;
    WstawButton(hDlg, Rectangle, "KALIBRUJ", 0, kbAltK, DoKalibr, but);
    IF jestAuto THEN
      MoveRect(Rectangle, moveDis, 0);
      WstawButton(hDlg, Rectangle, "KALIBRUJ AUTO", 9, kbAltA, DoAutoKalibr, 
                  but);
    END;
    MoveRect(Rectangle, moveDis, 0);
    WstawButton(hDlg, Rectangle, "MONITORUJ", 0, kbAltM, DoMonitorowanie, but);
    MoveRect(Rectangle, 0, 300);
    WstawButton(hDlg, Rectangle, "WYJSCIE", 0, kbAltW, DoWyjscie, but);
  END InitScreen;

  PROCEDURE cscr;

  BEGIN
    disp_curr_X := 0;
    disp_curr_Y := Line_thickness;
    FillRect(ScreenR, scrBackground);
  END cscr;

  PROCEDURE GoToTop;

  BEGIN
    disp_curr_X := 0;
    disp_curr_Y := Line_thickness;
  END GoToTop;

  PROCEDURE WriteLn;

  BEGIN
    disp_curr_X := 0;
    INC(disp_curr_Y, Line_thickness);
  END WriteLn;

  PROCEDURE WriteString
            (    str : ARRAY OF CHAR );

  BEGIN
    IF ODD(disp_curr_Y DIV Line_thickness)
    THEN
      _Wr16StrXY(str, disp_curr_X, disp_curr_Y, WHITE, BLUE);
    ELSE
      _Wr16StrXY(str, disp_curr_X, disp_curr_Y, BLUE, WHITE);
    END (* if ODD *);
    INC(disp_curr_X, Length(str) * 8);
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
      IF GetBinaryVal(from, val, dtaSign)
      THEN
        IF BitNumber IN val
        THEN
          ConstAssign(HIstr, str);;
        ELSE
          ConstAssign(LOstr, str);
        END (* if BitNumber *);
      ELSE
        ConstAssign(ERstr, str);
      END (* if GetBinaryVal *);
    END GetVal;

  BEGIN (* Get_WriteBinary *)
    WriteLn;
    WriteString(str);
    GetVal(from1, lastStr);
    WriteString(lastStr);
    WriteString(' B= ');
    GetVal(from2, lastStr);
    WriteString(lastStr);
  END Get_WriteBinary;

  PROCEDURE Get_WriteAnalog
            (    str        : ARRAY OF CHAR;
                 scale      : REAL;
                 unit       : ARRAY OF CHAR;
                 unit_cal   : ARRAY OF CHAR;
                 digits     : CARDINAL;
                 digits_cal : CARDINAL;
                 calib      : Input_Proc_cal );

    PROCEDURE Convert_Val
              (     what       : REAL;
                    whatCal    : REAL;
                    scale      : REAL;
                    unit       : ARRAY OF CHAR;
                    unit_cal   : ARRAY OF CHAR;
                    digits     : CARDINAL;
                    digits_cal : CARDINAL;
                VAR val        : ARRAY OF CHAR );

    CONST
      errStr = '####################';
    VAR
      my_string : ARRAY [0 .. 15] OF CHAR;
      ok        : BOOLEAN;

    BEGIN (* Convert_Val *)
      RealToString(whatCal, digits_cal, 10, val, ok);
      IF NOT ok
      THEN
        ConstAssign(errStr, val);
      END (* if ok *);
      Concat(val, unit_cal, val);
      RealToString(what * scale, digits, 10, my_string, ok);
      IF ok
      THEN
        Concat(val, '(', val);
        Concat(val, my_string, val);
        Concat(val, unit, val);
        Concat(val, ')', val);
      ELSE
        Concat(val, '(', val);
        Concat(val, errStr, val);
        Concat(val, unit, val);
        Concat(val, ')', val);
      END (* if ok *);
    END Convert_Val;
  VAR
    lastStr    : ARRAY [0 .. 80] OF CHAR;
    lastVal    : REAL;
    lastValCal : REAL;
    dtaSign    : DtaSignType;

  BEGIN (* Get_WriteAnalog *)
    WriteLn;
    WriteString(str);
    IF calib(lastVal, lastValCal, dtaSign, 0)
    THEN
      Convert_Val(lastVal, lastValCal, scale, unit, unit_cal, digits,
                  digits_cal, lastStr);
    ELSE
      lastStr := BladStr;
    END (* if GetAnalogVal *);
    WriteString(lastStr);
    WriteString(' B= ');
    IF calib(lastVal, lastValCal, dtaSign, 1)
    THEN
      Convert_Val(lastVal, lastValCal, scale, unit, unit_cal, digits,
                  digits_cal, lastStr);
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
      IF GetBinaryVal(from, lastVal, dtaSign)
      THEN
        lastIntVal := convert(lastVal);
        ConvertInteger(lastIntVal, 10, val);
      ELSE
        lastStr := '**********';
      END (* if GetAnalogVal *);
    END GetVal;

  BEGIN (* Get_WriteBinAnalog *)
    WriteLn;
    WriteString(str);
    GetVal(from1, lastStr);
    WriteString(lastStr);
    WriteString(' B= ');
    GetVal(from2, lastStr);
    WriteString(lastStr);
  END Get_WriteBinAnalog;

  PROCEDURE WriteILSFrq;
  VAR
    lastStr : ARRAY [0 .. 80] OF CHAR;

  BEGIN (* WriteILSFrq *)
    ILSfrqString(locCurrFrq, lastStr);
    Insert('czestotliwosc ILS = ', lastStr, 0);
    _Wr16StrXY(lastStr, 450, 490, WHITE, BLUE);
  END WriteILSFrq;

  PROCEDURE TuneILSandDME;

  BEGIN
    TuneILS(AReceiver, locCurrFrq, markerLowSense);
    TuneILS(BReceiver, locCurrFrq, markerLowSense);
    TuneDMEforILS(AReceiver, locCurrFrq);
    TuneDMEforILS(BReceiver, locCurrFrq);
    WriteILSFrq;
  END TuneILSandDME;

  PROCEDURE ILSIncF;

  BEGIN
    ILSIncFch(locCurrFrq, 1);
    TuneILSandDME;
  END ILSIncF;

  PROCEDURE ILSDecF;

  BEGIN
    ILSDecFch(locCurrFrq, 1);
    TuneILSandDME;
  END ILSDecF;

  PROCEDURE WriteVORFrq;
  VAR
    lastStr : ARRAY [0 .. 80] OF CHAR;
    ok      : BOOLEAN;

  BEGIN (* WriteVORFrq *)
    RealToString(FLOAT(vorCurrFrq) / 100.0, 2, 10, lastStr, ok);
    Insert('czestotliwosc VOR = ', lastStr, 0);
    Insert(' MHz ', lastStr, 9999);
    _Wr16StrXY(lastStr, 450, 490, WHITE, BLUE);
  END WriteVORFrq;

  PROCEDURE TuneVORandDME;

  BEGIN
    WriteVORFrq;
    TuneVOR(AReceiver, vorCurrFrq);
    TuneVOR(BReceiver, vorCurrFrq);
    TuneDMEforVOR(AReceiver, vorCurrFrq);
    TuneDMEforVOR(BReceiver, vorCurrFrq);
  END TuneVORandDME;

  PROCEDURE VORIncFchby100;

  BEGIN
    VORIncFch(vorCurrFrq, 100);
    TuneVORandDME;
  END VORIncFchby100;

  PROCEDURE VORIncFchby10;

  BEGIN
    VORIncFch(vorCurrFrq, 10);
    TuneVORandDME;
  END VORIncFchby10;

  PROCEDURE VORIncFchby1;

  BEGIN
    VORIncFch(vorCurrFrq, 1);
    TuneVORandDME;
  END VORIncFchby1;

  PROCEDURE VORDecFchby100;

  BEGIN
    VORDecFch(vorCurrFrq, 100);
    TuneVORandDME;
  END VORDecFchby100;

  PROCEDURE VORDecFchby10;

  BEGIN
    VORDecFch(vorCurrFrq, 10);
    TuneVORandDME;
  END VORDecFchby10;

  PROCEDURE VORDecFchby1;

  BEGIN
    VORDecFch(vorCurrFrq, 1);
    TuneVORandDME;
  END VORDecFchby1;

  PROCEDURE WriteADFFrq;
  VAR
    lastStr : ARRAY [0 .. 80] OF CHAR;
    ok      : BOOLEAN;

  BEGIN
    RealToString(FLOAT(adfCurrFrq), 2, 10, lastStr, ok);
    Insert('czestotliwosc ADF = ', lastStr, 0);
    Insert(' kHz ', lastStr, 9999);
    _Wr16StrXY(lastStr, 450, 490, WHITE, BLUE);
  END WriteADFFrq;

  PROCEDURE TuneADFrec;

  BEGIN
    TuneADF(AReceiver, adfCurrFrq, FALSE, TRUE, FALSE);
    TuneADF(BReceiver, adfCurrFrq, FALSE, TRUE, FALSE);
    WriteADFFrq;
  END TuneADFrec;

  PROCEDURE ADFIncFchby100;

  BEGIN
    IncADFFch(adfCurrFrq, 100);
    TuneADFrec;
  END ADFIncFchby100;

  PROCEDURE ADFIncFchby10;

  BEGIN
    IncADFFch(adfCurrFrq, 10);
    TuneADFrec;
  END ADFIncFchby10;

  PROCEDURE ADFIncFchby1;

  BEGIN
    IncADFFch(adfCurrFrq, 1);
    TuneADFrec;
  END ADFIncFchby1;

  PROCEDURE ADFDecFchby100;

  BEGIN
    DecADFFch(adfCurrFrq, 100);
    TuneADFrec;
  END ADFDecFchby100;

  PROCEDURE ADFDecFchby10;

  BEGIN
    DecADFFch(adfCurrFrq, 10);
    TuneADFrec;
  END ADFDecFchby10;

  PROCEDURE ADFDecFchby1;

  BEGIN
    DecADFFch(adfCurrFrq, 1);
    TuneADFrec;
  END ADFDecFchby1;

  PROCEDURE DoILSMenu;
  VAR
    firstTime   : BOOLEAN;
    hDlg        : HDLG;
    memlistaUrz : HCONTENT;
    memlistaKan : HCONTENT;
    listaUrz    : HLIST;
    listaKan    : HLIST;
    but         : Button;
    position    : CARDINAL;
    kanal       : CARDINAL;
    auto        : BOOLEAN;
    ok          : BOOLEAN;
    
    PROCEDURE Monitorowanie;
    CONST
      BitNumber = 0;
    VAR
      dtaSign : DtaSignType;
      lastCh  : CHAR;
      val     : BITSET;
      LocFlag : BOOLEAN;
      GSFlag  : BOOLEAN;
      pass    : BOOLEAN;

    PROCEDURE WyswietlStan( VAR dtaSign    : DtaSignType);
    VAR
      lastStr    : ARRAY [0 .. 40] OF CHAR;
      distanceBS : BITSET;
      distance   : INTEGER;
      dev        : INTEGER;
      devGS      : INTEGER;
      val        : REAL;
      val_cal    : REAL;

    BEGIN (* WyswietlStan *)
        IF pass = TRUE
        THEN
          WriteString('/');
        ELSE
          WriteString('\');
        END (* if *);
        pass := NOT pass;
      IF GetBinaryVal(DMEDistanceA, distanceBS, dtaSign)
      THEN
        distance := DMEConvert(distanceBS);
      ELSE
        distance := MIN(INTEGER);
      END (* if GetAnalogVal *);
      IF LOC_DEV_pc(val, val_cal, dtaSign, 0)
      THEN
        dev := entier(val_cal + 0.5);
      ELSE
        dev := MIN(INTEGER);
      END (* if LOC_DEV_pc *);
      IF GS_DEV_pc(val, val_cal, dtaSign, 0)
      THEN
        devGS := entier(val_cal + 0.5);
      ELSE
        devGS := MIN(INTEGER);
      END (* if LOC_DEV_pc *);
      UstawZmienne(distance DIV 10, dev, dev, devGS);
      WriteLn;
      WriteString('czestotliwosc = ');
      ILSfrqString(locCurrFrq, lastStr);
      WriteString(lastStr);
      IF markerLowSense
      THEN
        WriteString(' MKR Low Sense');
      ELSE
        WriteString(' MKR High Sense');
      END (* if markerLowSense *);
      WriteLn;
      Get_WriteAnalog('     LOC.DEV A= ', 1.0, '   ', 'uA ', 2, 1, LOC_DEV_pc);
      Get_WriteAnalog('     LOC.MOD A= ', 0.001, 'V   ', '%   ', 2, 1,
                      LOC_MOD_pc);
      Get_WriteAnalog('     LOC.AGC A= ', 0.001, 'V   ', 'uV  ', 2, 0,
                      LOC_AGC_pc);
      WriteLn;
      WriteLn;
      Get_WriteAnalog('      GS.DEV A= ', 1.0, '   ', 'uA ', 2, 1, GS_DEV_pc);
      Get_WriteAnalog('      GS.MOD A= ', 0.001, 'V   ', '%   ', 2, 1,
                      GS_MOD_pc);
      Get_WriteAnalog('      GS.AGC A= ', 0.001, 'V   ', 'uV  ', 2, 0,
                      GS_AGC_pc);
      WriteLn;
      WriteLn;
      Get_WriteAnalog('     MKR.AGC A= ', 0.001, 'V   ', 'uV  ', 2, 0,
                      MKR_AGC_pc);
      WriteLn;
      WriteLn;
      Get_WriteAnalog('DME.DISTANCE A= ', 1.0, 'NM  ', 'NM  ', 2, 2,
                      DME_Distance_pc);
      WriteLn;
      WriteLn;
      Get_WriteBinary('  LOC.SFLG A= ', SFLGforNAVa, SFLGforNAVb);
      Get_WriteBinary('   GS.SFLG A= ', SFLGforGSa, SFLGforGSb);
      Get_WriteBinary('   MKR.OUT A= ', OutMKRa, OutMKRb);
      Get_WriteBinary('   MKR.MID A= ', MidMKRa, MidMKRb);
      Get_WriteBinary('   MKR.INN A= ', InnMKRa, InnMKRb);
      Get_WriteBinary(' NAV.AUDIO A= ', NAVaAudio, NAVbAudio);
      WriteLn;
    END WyswietlStan;
    

    BEGIN
      cscr;
      pass := FALSE;
      UstawFormat(LOCPradOffset, 150, 150);
      REPEAT
        WaitForNewData(dtaSign);
        IF GetBinaryVal(SFLGforNAVa, val, dtaSign)
        THEN
          LocFlag := BitNumber IN val;
        END;
        IF GetBinaryVal(SFLGforGSa, val, dtaSign) THEN
          GSFlag := BitNumber IN val;
        END;
        SetCPFlags(LocFlag, GSFlag, FALSE, FALSE, TRUE);
        GoToTop;
        WyswietlStan( dtaSign );
      UNTIL KeyPressed();
      UstawZmienne(0, 0, 0, 0);
      UstawFormat(Idle, MAX(INTEGER), MAX(INTEGER));
      SetCPFlags(FALSE, FALSE, FALSE, FALSE, TRUE);
      WHILE KeyPressed() DO
        Read(lastCh);
      END;
    END Monitorowanie;

    PROCEDURE WstawButony;

    CONST
      movement = 170;
    VAR
      Rectangle : RECT;
      auto      : BOOLEAN;
      
    BEGIN (* WstawButony *)
      AssignRect(Rectangle, 450, 520, 600, 550);
      WstawButton(hDlg, Rectangle, "Prv. ch.(F1)", 9, kbF1, ILSDecF, but);
      MoveRect(Rectangle, movement, 0);
      WstawButton(hDlg, Rectangle, "Next ch.(F2)", 9, kbF2, ILSIncF, but);
    END WstawButony;

  BEGIN (* DoILSMenu *)
    firstTime := TRUE;
    position := 0;
    kanal := 0;
    TurnOnLOCSig;
    TurnOnGSSig;
    TurnOn(DMEDistanceA);
    TurnOn(DMEDistanceB);
    TuneILSandDME;
    LOOP
      InitScreen(hDlg, listaUrz, listaKan, TRUE);
      WstawButony;
      WriteILSFrq;
      IF firstTime
      THEN
        DodajDoListy(listaKan, "Kanal A");
        DodajDoListy(listaKan, "Kanal B");
        DodajDoListy(listaUrz, "LOC.DEV");
        DodajDoListy(listaUrz, "LOC.%MOD");
        DodajDoListy(listaUrz, "LOC.AGC");
        DodajDoListy(listaUrz, "GS.DEV");
        DodajDoListy(listaUrz, "GS.%MOD");
        DodajDoListy(listaUrz, "GS.AGC");
        DodajDoListy(listaUrz, "MKR.AGC");
        DodajDoListy(listaUrz, "Wszystko");
        memlistaUrz := GetContents(listaUrz);
        memlistaKan := GetContents(listaKan);
      ELSE
        SetContents(listaUrz, memlistaUrz);
        SetContents(listaKan, memlistaKan);
      END (* if firstTime *);
      firstTime := FALSE;
      SetSelection(listaUrz, position);
      SetSelection(listaKan, kanal);
      IF Go(hDlg)
      THEN
        position := GetSelection(listaUrz);
        kanal := GetSelection(listaKan);
        UsunDialog(hDlg);
        auto := nastOperacja = KalibracjaAuto;
        IF (nastOperacja = Kalibracja) OR auto
        THEN
          CASE position OF
            0 :
              ok := KalibracjaLocDev(kanal, auto);
            |
            1 :
              ok := KalibracjaLocMod(kanal, auto);
            |
            2 :
              ok := KalibracjaLocAGC(kanal, auto);
            |
            3 :
              ok := KalibracjaGsDev(kanal, auto);
            |
            4 :
              ok := KalibracjaGsMod(kanal, auto);
            |
            5 :
              ok := KalibracjaGsAGC(kanal, auto);
            |
            6 :
              ok := KalibracjaMkrAGC(kanal, auto);
            |
            7 :
              ok := ILSWszystko(kanal, auto);
          END (* case lastCh *);
          IF auto AND NOT ok THEN
            ok :=  DoSimpleComm(Local);
            ok := MsgBox.Info("Czy wiesz, ze procedure przerwano");
          END;
          IF auto  THEN
            TuneILSandDME
          END;
        ELSIF nastOperacja = Wyjscie THEN
          EXIT
        ELSE
          Monitorowanie;
        END (* if nastOperacja *);
      ELSE
        UsunDialog(hDlg);
        EXIT
      END (* if ok *);
    END (* loop *);
    TurnOffILSSig;
    TurnOff(DMEDistanceA);
    TurnOff(DMEDistanceB);
  END DoILSMenu;

  PROCEDURE WstawButonyVOR
            ( VAR hDlg : HDLG );

  CONST
    movement = 60;
  VAR
    Rectangle : RECT;
    but       : Button;

  BEGIN
    AssignRect(Rectangle, 450, 520, 500, 550);
    WstawButton(hDlg, Rectangle, "-1", 0, kbF1, VORDecFchby100, but);
    MoveRect(Rectangle, movement, 0);
    WstawButton(hDlg, Rectangle, "-0.1", 0, kbF2, VORDecFchby10, but);
    MoveRect(Rectangle, movement, 0);
    WstawButton(hDlg, Rectangle, "-0.01", 0, kbF3, VORDecFchby1, but);
    MoveRect(Rectangle, movement, 0);
    WstawButton(hDlg, Rectangle, "+0.01", 0, kbF4, VORIncFchby1, but);
    MoveRect(Rectangle, movement, 0);
    WstawButton(hDlg, Rectangle, "+0.1", 0, kbF5, VORIncFchby10, but);
    MoveRect(Rectangle, movement, 0);
    WstawButton(hDlg, Rectangle, "+1", 0, kbF6, VORIncFchby100, but);
  END WstawButonyVOR;

  PROCEDURE DoVORMenu;
  VAR
    firstTime   : BOOLEAN;
    hDlg        : HDLG;
    memlistaUrz : HCONTENT;
    memlistaKan : HCONTENT;
    listaUrz    : HLIST;
    listaKan    : HLIST;
    position    : CARDINAL;
    kanal       : CARDINAL;
    auto        : BOOLEAN;
    ok          : BOOLEAN;
    
    PROCEDURE WyswietlStan;
    VAR
      lastStr : ARRAY [0 .. 80] OF CHAR;

    BEGIN (* WyswietlStan *)
      WriteString('czestotliwosc VOR = ');
      ConvertCardinal(vorCurrFrq, 10, lastStr);
      Concat(lastStr, '0kHz', lastStr);
      WriteString(lastStr);
      WriteLn;
      WriteLn;
      Get_WriteAnalog(' VOR.OMNIBERI A= ', 1.0, 'deg ', 'deg ', 2, 2,
                      VOR_OMNIBERI_pc);
      WriteLn;
      Get_WriteAnalog('      VOR.AGC A= ', 0.001, 'V   ', 'uV ', 2, 0,
                      VOR_AGC_pc);
      Get_WriteAnalog('      VOR.VAR A= ', 0.001, 'V   ', '%   ', 2, 1,
                      VOR_VAR_pc);
      Get_WriteAnalog('      VOR.REF A= ', 0.001, 'V   ', '%   ', 2, 1,
                      VOR_REF_pc);
      Get_WriteAnalog('   VOR.SUBCAR A= ', 0.001, 'V   ', '%   ', 2, 1,
                      VOR_SUBCAR_pc);
      WriteLn;
      WriteLn;
      Get_WriteBinary('     VOR.SFLG A= ', SFLGforNAVa, SFLGforNAVb);
      Get_WriteBinary('    NAV.AUDIO A= ', NAVaAudio, NAVbAudio);
    END WyswietlStan;

    PROCEDURE Monitorowanie;
    VAR
      dtaSign : DtaSignType;
      lastCh  : CHAR;

    BEGIN (* Monitorowanie *)
      cscr;
      REPEAT
        WaitForNewData(dtaSign);
        GoToTop;
        WyswietlStan;
      UNTIL KeyPressed();
      Read(lastCh);
    END Monitorowanie;

  BEGIN (* DoVORMenu *)
    firstTime := TRUE;
    position := 0;
    kanal := 0;
    TurnOnVORSig;
    TuneVORandDME;
    LOOP
      InitScreen(hDlg, listaUrz, listaKan, TRUE);
      WstawButonyVOR(hDlg);
      WriteVORFrq;
      IF firstTime
      THEN
        DodajDoListy(listaKan, "Kanal A");
        DodajDoListy(listaKan, "Kanal B");
        DodajDoListy(listaUrz, "Omnibearing");
        DodajDoListy(listaUrz, "REF");
        DodajDoListy(listaUrz, "VAR");
        DodajDoListy(listaUrz, "Subcar");
        DodajDoListy(listaUrz, "AGC");
        DodajDoListy(listaUrz, "Wszystko");
        memlistaUrz := GetContents(listaUrz);
        memlistaKan := GetContents(listaKan);
      ELSE
        SetContents(listaUrz, memlistaUrz);
        SetContents(listaKan, memlistaKan);
      END (* if firstTime *);
      firstTime := FALSE;
      SetSelection(listaUrz, position);
      SetSelection(listaKan, kanal);
      IF Go(hDlg)
      THEN
        position := GetSelection(listaUrz);
        kanal := GetSelection(listaKan);
        UsunDialog(hDlg);
        auto := nastOperacja = KalibracjaAuto;
        IF (nastOperacja = Kalibracja) OR auto 
        THEN
          CASE position OF
            0 :
              ok := KalibracjaOmnibearing(kanal, auto);
            |
            1 :
              ok := KalibracjaVorRef(kanal, auto);
            |
            2 :
              ok := KalibracjaVorVar(kanal, auto);
            |
            3 :
              ok := KalibracjaSubcar(kanal, auto);
            |
            4 :
              ok := KalibracjaVorAGC(kanal, auto);
            |
            5 :
              ok := VORWszystko(kanal, auto);
          END (* case lastCh *);
          IF auto AND NOT ok THEN
            ok :=  DoSimpleComm(Local);
            ok := MsgBox.Info("Czy wiesz, ze procedure przerwano");
          END;
          IF auto THEN
            TuneVORandDME;
          END;
        ELSIF nastOperacja = Wyjscie THEN
          EXIT
        ELSE
          Monitorowanie;
        END (* if nastOperacja *);
      ELSE
        UsunDialog(hDlg);
        EXIT
      END (* if ok *);
    END (* loop *);
    TurnOffVORSig;
  END DoVORMenu;

  PROCEDURE DoDMEMenu;
  VAR
    firstTime   : BOOLEAN;
    hDlg        : HDLG;
    memlistaUrz : HCONTENT;
    memlistaKan : HCONTENT;
    listaUrz    : HLIST;
    listaKan    : HLIST;
    position    : CARDINAL;
    kanal       : CARDINAL;

    PROCEDURE WyswietlStan;
    VAR
      lastStr : ARRAY [0 .. 20] OF CHAR;

    BEGIN (* WyswietlStan *)
      WriteString('czestotliwosc = ');
      ConvertCardinal(vorCurrFrq, 10, lastStr);
      Concat(lastStr, '0kHz', lastStr);
      WriteString(lastStr);
      WriteLn;
      WriteLn;
      Get_WriteAnalog('DME.DISTANCE A= ', 1.0, 'NM  ', 'NM  ', 2, 2,
                      DME_Distance_pc);
      WriteLn;
      WriteLn;
      Get_WriteAnalog('        DME.AGC A= ', 0.001, 'V   ', 'dBm ', 2, 0,
                      DME_AGC_pc);
      Get_WriteAnalog('   DME.SQUITTER A= ', 0.001, 'V   ', '    ', 2, 0,
                      DME_SQUITTER_pc);
      Get_WriteAnalog('    DME.%REPLAY A= ', 0.001, 'V   ', '%   ', 2, 1,
                      DME_RPL_pc);
      WriteLn;
      WriteLn;
      Get_WriteBinary('        DME.MEM A= ', DME_MEMa, DME_MEMb);
      Get_WriteBinary('      DME.TRACE A= ', DME_SRCa, DME_SRCb);
      Get_WriteBinary('      DME.AUDIO A= ', DMEaAudio, DMEbAudio);
    END WyswietlStan;

    PROCEDURE Monitorowanie;
    VAR
      dtaSign : DtaSignType;
      lastCh  : CHAR;

    BEGIN (* Monitorowanie *)
      cscr;
      REPEAT
        WaitForNewData(dtaSign);
        GoToTop;
        WyswietlStan;
      UNTIL KeyPressed();
      Read(lastCh);
    END Monitorowanie;

  BEGIN (* DoDMEMenu *)
    firstTime := TRUE;
    position := 0;
    kanal := 0;
    TurnOnDMESig;
    TuneDMEforVOR(AReceiver, vorCurrFrq);
    TuneDMEforVOR(BReceiver, vorCurrFrq);
    LOOP
      InitScreen(hDlg, listaUrz, listaKan, FALSE);
      WstawButonyVOR(hDlg);
      WriteVORFrq;
      IF firstTime
      THEN
        DodajDoListy(listaKan, "Kanal A");
        DodajDoListy(listaKan, "Kanal B");
        DodajDoListy(listaUrz, "Squiter");
        DodajDoListy(listaUrz, "DME.%RPL");
        DodajDoListy(listaUrz, "DME.AGC");
        memlistaUrz := GetContents(listaUrz);
        memlistaKan := GetContents(listaKan);
      ELSE
        SetContents(listaUrz, memlistaUrz);
        SetContents(listaKan, memlistaKan);
      END (* if firstTime *);
      firstTime := FALSE;
      SetSelection(listaUrz, position);
      SetSelection(listaKan, kanal);
      IF Go(hDlg)
      THEN
        position := GetSelection(listaUrz);
        kanal := GetSelection(listaKan);
        UsunDialog(hDlg);
        IF nastOperacja = Kalibracja
        THEN
          CASE position OF
            0 :
              KalibracjaDmeSquitter(kanal);
            |
            1 :
              KalibracjaDmeReply(kanal);
            |
            2 :
              KalibracjaDmeAGC(kanal);
          END (* case lastCh *);
        ELSIF nastOperacja = Wyjscie THEN
          EXIT
        ELSE
          Monitorowanie;
        END (* if nastOperacja *);
      ELSE
        UsunDialog(hDlg);
        EXIT
      END (* if ok *);
    END (* loop *);
    TurnOffDMESig;
  END DoDMEMenu;

  PROCEDURE DoADFMenu;
  VAR
    firstTime   : BOOLEAN;
    hDlg        : HDLG;
    memlistaUrz : HCONTENT;
    memlistaKan : HCONTENT;
    listaUrz    : HLIST;
    listaKan    : HLIST;
    but         : Button;
    position    : CARDINAL;
    kanal       : CARDINAL;

    PROCEDURE WyswietlStan;
    VAR
      lastStr : ARRAY [0 .. 20] OF CHAR;

    BEGIN (* WyswietlStan *)
      WriteString('czestotliwosc = ');
      ConvertCardinal(adfCurrFrq, 10, lastStr);
      WriteString(lastStr);
      WriteLn;
      Get_WriteAnalog(' AGC A=  ', 0.001, 'V   ', 'uV  ', 2, 0, ADF_AGC_pc);
      Get_WriteAnalog(' SIN A= ', 0.001, 'V   ', '    ', 2, 3, ADF_SIN_pc);
      Get_WriteAnalog(' COS A= ', 0.001, 'V   ', '    ', 2, 3, ADF_COS_pc);
      Get_WriteBinary(' ADF.AUDIO A= ', ADFaAudio, ADFbAudio);
    END WyswietlStan;

    PROCEDURE Monitorowanie;
    VAR
      dtaSign : DtaSignType;
      lastCh  : CHAR;

    BEGIN
      cscr;
      REPEAT
        WaitForNewData(dtaSign);
        GoToTop;
        WyswietlStan;
      UNTIL KeyPressed();
      Read(lastCh);
    END Monitorowanie;

    PROCEDURE WstawButony;

    CONST
      movement = 60;
    VAR
      Rectangle : RECT;

    BEGIN
      AssignRect(Rectangle, 450, 520, 500, 550);
      WstawButton(hDlg, Rectangle, "-100", 0, kbF5, ADFDecFchby100, but);
      MoveRect(Rectangle, movement, 0);
      WstawButton(hDlg, Rectangle, "-10", 0, kbF4, ADFDecFchby10, but);
      MoveRect(Rectangle, movement, 0);
      WstawButton(hDlg, Rectangle, "-1", 0, kbF3, ADFDecFchby1, but);
      MoveRect(Rectangle, movement, 0);
      WstawButton(hDlg, Rectangle, "+1", 0, kbF2, ADFIncFchby1, but);
      MoveRect(Rectangle, movement, 0);
      WstawButton(hDlg, Rectangle, "+10", 0, kbF2, ADFIncFchby10, but);
      MoveRect(Rectangle, movement, 0);
      WstawButton(hDlg, Rectangle, "+100", 0, kbF1, ADFIncFchby100, but);
    END WstawButony;

  BEGIN (* DoADFMenu *)
    firstTime := TRUE;
    position := 0;
    kanal := 0;
    TurnOnADFSig;
    TuneADF(AReceiver, adfCurrFrq, FALSE, TRUE, FALSE);
    TuneADF(BReceiver, adfCurrFrq, FALSE, TRUE, FALSE);
    LOOP
      InitScreen(hDlg, listaUrz, listaKan, FALSE);
      WstawButony;
      WriteADFFrq;
      IF firstTime
      THEN
        DodajDoListy(listaKan, "Kanal A");
        DodajDoListy(listaKan, "Kanal B");
        DodajDoListy(listaUrz, "ADF.AGC");
        memlistaUrz := GetContents(listaUrz);
        memlistaKan := GetContents(listaKan);
      ELSE
        SetContents(listaUrz, memlistaUrz);
        SetContents(listaKan, memlistaKan);
      END (* if firstTime *);
      firstTime := FALSE;
      SetSelection(listaUrz, position);
      SetSelection(listaKan, kanal);
      IF Go(hDlg)
      THEN
        position := GetSelection(listaUrz);
        kanal := GetSelection(listaKan);
        UsunDialog(hDlg);
        IF nastOperacja  = Kalibracja
        THEN
          KalibracjaADF(kanal);
        ELSIF nastOperacja = Wyjscie THEN
          EXIT
        ELSE
          Monitorowanie;
        END (* if nastOperacja *);
      ELSE
        UsunDialog(hDlg);
        EXIT
      END (* if ok *);
    END (* loop *);
    TurnOffADFSig;
  END DoADFMenu;

  PROCEDURE DoALTMenu;

    PROCEDURE WyswietlStan;

    BEGIN (* WyswietlStan *)
      Get_WriteBinAnalog('     ALTITUDE = ', Altimeter, Altimeter, ALTConvert);
    END WyswietlStan;

    PROCEDURE Monitorowanie;
    VAR
      dtaSign : DtaSignType;
      pass    : BOOLEAN;
      lastCh  : CHAR;

    BEGIN (* Monitorowanie *)
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
      Read(lastCh);
    END Monitorowanie;

  BEGIN (* DoALTMenu *)
    TurnOn(Altimeter);
    Monitorowanie;
    TurnOff(Altimeter);
  END DoALTMenu;

  PROCEDURE DoVHFMenu;
  VAR
    hDlg      : HDLG;
    but       : Button;
    Rectangle : RECT;

    PROCEDURE WyswietlStan;

    BEGIN (* WyswietlStan *)
      Get_WriteAnalog(' AGC A=  ', 0.001, 'V   ', 'uV  ', 2, 0, VHF_AGC_pc);
    END WyswietlStan;

    PROCEDURE Monitorowanie;
    VAR
      dtaSign : DtaSignType;
      pass    : BOOLEAN;
      lastCh  : CHAR;

    BEGIN (* Monitorowanie *)
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
      Read(lastCh);
    END Monitorowanie;

  BEGIN (* DoVHFMenu *)
    TurnOn(AGCforCOMa);
    LOOP
      cscr;
      hDlg := TworzDialog(ScreenR, "ss.dib", FALSE);
      AssignRect(Rectangle, 50, 120, 350, 180);
      WstawButton(hDlg, Rectangle, "KALIBRUJ", 0, kbAltK, DoKalibr, but);
      MoveRect(Rectangle, 400, 0);
      WstawButton(hDlg, Rectangle, "MONITORUJ", 0, kbAltM, DoMonitorowanie, 
                  but);
      MoveRect(Rectangle, 0, 300);
      WstawButton(hDlg, Rectangle, "WYJSCIE", 0, kbAltW, DoWyjscie, but);
      IF Go(hDlg)
      THEN
        UsunDialog(hDlg);
        IF nastOperacja = Kalibracja 
        THEN
          KalibracjaVHF(0);
        ELSIF nastOperacja = Wyjscie THEN
          EXIT
        ELSE
          Monitorowanie;
        END (* if nastOperacja *);
      ELSE
        UsunDialog(hDlg);
        EXIT;
      END (* if ok *);
    END (* loop *);
    TurnOff(AGCforCOMa);
  END DoVHFMenu;

  PROCEDURE WylaczWszystko;

  BEGIN
    TurnOffADF(AReceiver);
    TurnOffADF(BReceiver);
    TurnOffVOR_ILS(AReceiver);
    TurnOffVOR_ILS(BReceiver);
  END WylaczWszystko;

  PROCEDURE Init;

  BEGIN
    TuneADF(AReceiver, adfCurrFrq, FALSE, TRUE, FALSE);
    TuneADF(BReceiver, adfCurrFrq, FALSE, TRUE, FALSE);
    TuneILS(AReceiver, locCurrFrq, markerLowSense);
    TuneILS(BReceiver, locCurrFrq, markerLowSense);
    ScreenR.left := 0;
    ScreenR.top := 0;
    ScreenR.right := MaxHor();
    ScreenR.bottom := MaxVer();
  END Init;

  PROCEDURE OkP;

  BEGIN
    EndDialog(TRUE);
  END OkP;

  PROCEDURE GlowneMenu;

  TYPE
    State =
      ( ILSMenu,
        VORMenu,
        DMEMenu,
        ADFMenu,
        VHFMenu,
        ALTMenu,
        WylaczOdbi );
  VAR
    hDlg      : HDLG;
    currState : State;
    c1        : HCONTENT;
    but       : Button;
    firsTime  : BOOLEAN;
    R         : RECT;
    l1        : HLIST;

  BEGIN (* GlowneMenu *)
    currState := ILSMenu;
    firsTime := TRUE;
    LOOP
      FillRect(ScreenR, BLACK);
      AssignRect(R, 0, 0, 800, 600);
      hDlg := TworzDialog(R, "pk.bmp", FALSE);
      AssignRect(R, 50, 150, 400, 400);
      l1 := WstawListe(hDlg, R, FALSE);
      KillContents(l1, FALSE);
      AssignRect(R, 50, 420, 400, 470);
      WstawButton(hDlg, R, "WYJSCIE", 0, kbAltW, AltF4, but);
      MoveRect(R, 0, 70);
      WstawButton(hDlg, R, "OK", 0, kbAltO, OkP, but);
      Info("Wybierz urz¥dzenie do kalibracji/monitorowania");
      IF firsTime
      THEN
        DodajDoListy(l1, "ILS");
        DodajDoListy(l1, "VOR");
        DodajDoListy(l1, "DME");
        DodajDoListy(l1, "ADF");
        DodajDoListy(l1, "VHF");
        DodajDoListy(l1, "Wysokosciomierz");
        DodajDoListy(l1, "Wylacz odbiorniki NAv i ADF");
        c1 := GetContents(l1);
      ELSE
        SetContents(l1, c1);
      END (* if firsTime *);
      firsTime := FALSE;
      SetSelection(l1, ORD(currState));
      IF Go(hDlg)
      THEN
        currState := VAL(State, GetSelection(l1));
      ELSE
        UsunDialog(hDlg);
        EXIT;
      END (* if ok *);
      UsunDialog(hDlg);
      CASE currState OF
        VORMenu :
          DoVORMenu;
        |
        ILSMenu :
          DoILSMenu;
        |
        DMEMenu :
          DoDMEMenu;
        |
        ADFMenu :
          DoADFMenu();
        |
        ALTMenu :
          DoALTMenu();
        |
        VHFMenu :
          DoVHFMenu();
        |
        WylaczOdbi :
          WylaczWszystko;
      END (* case currState *);
    END (* loop *);
  END GlowneMenu;

  PROCEDURE PrintScreenProc( a : ADDRESS );
    BEGIN
      GrafUtil.Info( 'Nie tˆucz w klawisze bez sensu!!!');
      BreakChain;
    END PrintScreenProc;

VAR
  Tmpl : Template;

BEGIN
  UstawFormat(Idle, MAX(INTEGER), MAX(INTEGER));
  markerLowSense := TRUE;
  vorCurrFrq := 11490;
  locCurrFrq := 20;
  adfCurrFrq := 190;
  InstPrologueHnd( PrintScreen, ADR(Tmpl), PrintScreenProc, NIL );
  Init;
  GlowneMenu;
  RTSMain.Terminate(RTSMain.Normal);
END PK.
