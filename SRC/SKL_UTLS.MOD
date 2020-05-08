(*.F- *)
(**********************************************************************
|  Title   : Procedury realizujace kalibracje
|  Author  : Mariusz Postol
|  System  : LOGITECH MODULA-2/86
|  History :
|   rel 001 31.12.95: new
|   rel 002 01.09.96:M.Postol
|     autokalibracje dodano
|     UWAGI:
|       warunkowac akceptacje autokalibracji od maksymalnego bledu
|   08-05-97: M.Postol
|     poprawilem wykres omniberingu
|     poprawilem napisy dl VOR.BRG i GS.AGC
|   15-06-97: M.Postol
|     poprawilem napis VOR_BRG_Stm
|
|  Copyright (C), CAS LODZ POLAND.
|  TEL: 42' 862 547, 42' 87 80 44 FAX/TEL: 42' 84 48 40
|
**********************************************************************)
(*.F+ *)

IMPLEMENTATION MODULE Skl_utls;

  IMPORT
    DGHInterface, MsgBox;

  FROM SYSTEM IMPORT
    ADDRESS, ADR;

  FROM Timer IMPORT
    Wait, TInOneSecond;

  FROM Hrdw_plt IMPORT
    CommCh, VOR_AGC_pc, VOR_REF_pc, VOR_VAR_pc, VOR_SUBCAR_pc, VOR_OMNIBERI_pc,
    LOC_MOD_pc, LOC_DEV_pc, GS_DEV_pc, GS_MOD_pc, GS_AGC_pc, MKR_AGC_pc,
    ADF_AGC_pc, VHF_AGC_pc, DME_AGC_pc, DME_SQUITTER_pc, DME_RPL_pc;

  FROM Kl_Utils IMPORT
    Input_Proc_cal, Get_Format_Signal;

  FROM Kalibracja IMPORT
    Par, ParTable, OmnibearingProgi, OmnibearingType,
    AGCwartosciProgow, AGCwartosciProgowM, AGCwartosciProgowD,
    LOC_DEVPuntyKal, GS_DEVPuntyKal, TabKalib2P, InputSignal, StruTabKalib2P, LocDev_delay,
    GsDev_delay, LocPrcMod_delay, GsPrcMod_delay, VorRefPrcMod_delay,
    VorVarPrcMod_delay, SubcarPrcMod_delay, Omnibearing_delay, VorAgc_delay,
    GsAgc_delay, MkrAgc_delay, SaveSegmentTables, inputCoeff, AgcInput;

  FROM GrafTypes IMPORT
    RECT, BLUE, LT_BLUE, WHITE, LT_RED, LT_GREEN, BLACK, AssignRect;

  FROM Graphics IMPORT
    MaxHor, MaxVer, _Wr16StrXY;

  FROM MathLib0 IMPORT
    entier, real;

  FROM Wykres IMPORT
    Opis, PokazWykresNS, OpisLog, PokazWykresNSLog;

  FROM GrafUtil IMPORT
    Info;

  FROM StdIO IMPORT
    sprintf;

  FROM Sounds IMPORT
    Sound, NoSound;

  FROM Terminal IMPORT
    Write, Read, KeyPressed;

  FROM ASCII IMPORT
    bel;

  FROM Chronometer IMPORT
    (* TYPE *) Chrono, Duration,
    (* PROCEDURE *) NewChrono, StartChrono, ReadChrono,
                    StopChrono, ResetChrono, DurationToStr;

  FROM NAVGPIB IMPORT
    (* TYPE *) CommandSimple, CommandRealPar,
    (* PROCEDURE *) DoSimpleComm, DoCommandRealPar, VOR_Default, LOC_Default,
                    GS_Default, MKR_Default;

  FROM CommonTypes IMPORT
    znakSL, znakGora;

  FROM Strings  IMPORT 
    Insert;
    
  FROM SpecConv IMPORT
    GorszeBoDalszeR, SubAng360;

  CONST
    Wszystko          = MAX(INTEGER);
    OdPoczatku        = 0;
    zkrsPrzetw        = 10000;
    skokDzialkiPrzetw = 1000;
    kol_ws            = WHITE;
    kol_wn            = LT_RED;
    kol_tla           = LT_BLUE;
    kol_osi           = BLUE;
    Line_thickness    = 16;
    noauto            = FALSE;

  TYPE
    FixedArray  =
      ARRAY [0 .. 80] OF CHAR;  (* zeby ten glupi Logitech dolaczyl 0 na koncu
                                   stringu *)
    ConvertProc =
      PROCEDURE
        (     REAL,
              CommandRealPar ) : BOOLEAN;

CONST
  VHF_AGC_Str = "VHF.AGC[uV] ";
  ADF_AGC_Str = "ADF.AGC[uV]";
  DME_RPL_Str = "DME.RPL (-50dBm, SQR=2700)[%]";
  DME_AGC_Str = "DME.AGC (SQR=2700, RPL=100%)[dBm]";
  DME_SQR_Str = "DME.Squitter (-50dBm, 100%)[ ]";
  VOR_BRG_Sta = "Ustawiam VOR.BRG (100uV, mod normal) na %dø (ESC przerwij)";
  VOR_BRG_Stm = "Ustaw VOR.BRG (100uV, mod normal) na %dø i wci˜nij klawisz SPACJI";
  VOR_AGC_Str = "VOR.AGC (BRG=0, mod normal)[uV]";
  VOR_SUB_Str = "VOR.SUBCAR (100uV, BRG=0)[%]";
  VOR_VAR_Str = "VOR.VAR (100uV, BRG=0)[%]";
  VOR_REF_Str = "VOR.REF (100uV, BRG=0)[ ]";
  GS_AGC_Str  = "GS.AGC (%MOD=80%, DEV=0uA)[uV]";
  GS_MOD_Str  = "GS.MOD (700uV, DEV=0uA)[%]";
  LOC_MOD_Str = "LOC.MOD (100uV, DEV=0)[%]";
  LOC_AGC_Str = "LOC.AGC (%MOD=40%, DEV=0)[uV]";
  GS_DEV_Str  = "GS.DEV (700uV/80% - dla 90Hz)[uA]";
  LOC_DEV_Str = "LOC.DEV (100uV/40% - dla 150Hz)[uA]";

  VAR
    ScreenR     : RECT;
    PopParam    : ParTable;
    PTabKalib2P : StruTabKalib2P;
    chrono      : Chrono;

  PROCEDURE Init;

  BEGIN
    ScreenR.left := 0;
    ScreenR.top := 2 * Line_thickness;
    ScreenR.right := MaxHor();
    ScreenR.bottom := MaxVer() - 17;
  END Init;

  PROCEDURE WaitMultiCh
            (    pktCal   : REAL;
                 toGetVal : Input_Proc_cal;
                 channel  : CommCh;
                 waitTime : Duration;
                 maxError : REAL       ) : CHAR;
  VAR
    c            : CHAR;
    dtaSign      : DGHInterface.DtaSignType;
    stringToDis  : ARRAY [0 .. 80] OF CHAR;
    str          : ARRAY [0 .. 80] OF CHAR;
    autoTiming   : BOOLEAN;
    currDuration : Duration;

    PROCEDURE Pass
              (    currDuration : Duration;
                   waitTime     : Duration ) : BOOLEAN;

    BEGIN
      WITH waitTime DO
        IF (Minute = 0) OR (currDuration.Minute >= Minute)
        THEN
          IF currDuration.Millisec >= Millisec
          THEN
            RETURN TRUE
          END (* if currDuration.Millisec *);
        END (* if *);
      END (* with waitTime *);
      RETURN FALSE
    END Pass;

  BEGIN (* WaitMultiCh *)
    Write(bel);
    ResetChrono(chrono);
    StartChrono(chrono);
    WITH waitTime DO
      autoTiming := (Minute <> 0) OR (Millisec <> 0)
    END (* with waitTime *);
    IF KeyPressed()
    THEN
      Read(c);
    END (* if KeyPressed *);
    LOOP
      Get_Format_Signal(pktCal,
                        " ",
                        " ",
                        2,
                        1,
                        toGetVal,
                        channel,
                        str,
                        dtaSign);
      Insert(" max blad= %6.2lf", str, 0FFFFH);
      sprintf(stringToDis, str, maxError);
      ReadChrono(chrono,
                 currDuration);
      DurationToStr(currDuration,
                    str);
      Insert(str, stringToDis, 0FFFFH);
      Insert('     ', stringToDis, 0FFFFH);
      _Wr16StrXY(stringToDis,
                10,
                Line_thickness DIV 2,
                kol_wn,
                kol_osi);
      IF KeyPressed()
      THEN
        Read(c);
        IF (c = "r") OR (c = "R")
        THEN
          ResetChrono(chrono);
          StartChrono(chrono);
        ELSE
          EXIT;
        END (* if *);
      END (* if KeyPressed *);
      IF autoTiming AND Pass(currDuration,
                             waitTime)
      THEN
        c := " ";
        EXIT;
      END (* if autoTiming *);
    END (* loop *);
    StopChrono(chrono);
    RETURN c;
  END WaitMultiCh;

  PROCEDURE Pokaz
            (    s     : ARRAY OF CHAR;
                 Gwizd : BOOLEAN       );
  VAR
    i : CARDINAL;

  BEGIN
    Info(s);
    IF Gwizd
    THEN
      FOR i := 0 TO 40000 DO
        Sound(100 + i DIV 10);
      END (* for i *);
      FOR i := 40000 TO 0 BY -1 DO
        Sound(100 + i DIV 10);
      END (* for i *);
      NoSound;
    END (* if Gwizd *);
    Wait(5 * TInOneSecond());
    Info("");
  END Pokaz;

  PROCEDURE AssignDuration
            (     auto     : BOOLEAN;
                  waitTime : REAL;
              VAR duration : Duration );

  BEGIN
    WITH duration DO
      IF auto
      THEN
        Minute := TRUNC(waitTime / 60.0);
        Millisec := TRUNC((waitTime - FLOAT(Minute * 60)) * 1000.0);
      ELSE
        Minute := 0;
        Millisec := 0;
      END (* if auto *);
    END (* with duration *);
  END AssignDuration;

  PROCEDURE DoOmnibearing
            ( VAR Par          : OmnibearingType;
                  channel      : CommCh;
                  auto         : BOOLEAN;
                  navCntrlProc : ConvertProc;
                  navComm      : CommandRealPar;
                  autoWaitTime : REAL            ) : BOOLEAN;

  TYPE
    rejestr =
      ARRAY [0 .. 37] OF INTEGER;
  VAR
    dtaSign  : DGHInterface.DtaSignType;
    val_cal  : REAL;
    Xiplus1  : REAL;
    infoLine : ARRAY [0 .. 80] OF CHAR;
    forCount : CARDINAL;
    j        : INTEGER;
    x        : rejestr;
    duration : Duration;
    maxError : REAL;
    
    PROCEDURE PokazWykres
              (    iloscPnkt   : CARDINAL;
                   omnibearing : OmnibearingType;
                   kolor       : CARDINAL        );
    VAR
      xStr : rejestr;
      yStr : rejestr;
      idx  : CARDINAL;
      pos  : CARDINAL;

      PROCEDURE rysuj();

      BEGIN
        IF xStr[0] > 1
        THEN
          PokazWykresNS(xStr,
                        yStr,
                        OdPoczatku,
                        Wszystko,
                        0,
                        360,
                        ScreenR,
                        0.0,
                        360.0,
                        kolor);
        END (* if *);
      END rysuj;

    BEGIN
      IF iloscPnkt < 2
      THEN
        RETURN
      END (* if iloscPnkt *);
      xStr[0] := 0;
      yStr[0] := 0;
      idx := 0;
      pos := 1;
      LOOP
        yStr[pos] := idx * 10;
        xStr[pos] := entier(omnibearing[idx]);
        IF (pos > 1) AND (xStr[pos - 1] > xStr[pos])
        THEN
          rysuj;
          xStr[0] := 0;
          yStr[0] := 0;
          pos := 1;
        ELSE
          INC(xStr[0]);
          INC(yStr[0]);
          INC(pos);
        END (* if *);
        INC(idx);
        IF idx = iloscPnkt
        THEN
          rysuj;
          EXIT;
        END (* if idx *);
      END (* loop *);
    END PokazWykres;

  BEGIN (* DoOmnibearing *)
    maxError := 0.0;
    Info("Omnibearing");
    Opis(ScreenR,
         0.0,
         360.0,
         0.0,
         360.0,
         OmnibearingProgi,
         36,
         OmnibearingProgi,
         36,
         FALSE,
         kol_tla,
         kol_osi,
         TRUE);
    PokazWykres(36,
                Par,
                kol_ws);
    x[0] := 37;
    AssignDuration(auto,
                   autoWaitTime,
                   duration);
    FOR forCount := 0 TO 35 DO
      j := forCount * 10;
      IF auto
      THEN
        IF NOT navCntrlProc(FLOAT(j),
                            navComm)
        THEN
          Info("Nie moge ustawic generatora przez GPIB");
          Wait(3 * TInOneSecond());
          Info("");
          RETURN FALSE;
        END (* if *);
        sprintf(infoLine,
                VOR_BRG_Sta,
                j);
      ELSE
        sprintf(infoLine,
                VOR_BRG_Stm,
                j);
      END (* if auto *);
      Info(infoLine);
      CASE WaitMultiCh(FLOAT(j),
                       VOR_OMNIBERI_pc,
                       channel,
                       duration, maxError) OF
        ' ' :
          IF NOT VOR_OMNIBERI_pc(Xiplus1,
                                 val_cal,
                                 dtaSign,
                                 channel)
          THEN
            Pokaz("Kanaˆ ARINC dla pomiaru namiaru jest uszkodzony!",
                  TRUE);
            RETURN FALSE;
          END (* if *);
        |
        's', 'S' :
          Xiplus1 := Par[forCount];
          val_cal := FLOAT(j);
      ELSE
        Info("Procedura zaniechana");
        Wait(TInOneSecond());
        Info("");
        RETURN FALSE;
      END (* case *);
      GorszeBoDalszeR( maxError, SubAng360(FLOAT(j), val_cal));
      Par[forCount] := Xiplus1;
      PokazWykres(forCount+1,
                  Par,
                  kol_wn);
    END (* for forCount *);
    IF NOT auto AND NOT MsgBox.Info("Procedura zakonczona - zapisac dane?")
    THEN
      Info("Procedura zaniechana");
      Wait(TInOneSecond());
      Info("");
      RETURN FALSE
    END (* if *);
    RETURN TRUE
  END DoOmnibearing;

  PROCEDURE MulSegCal
            ( VAR OldSegments  : ARRAY OF REAL;
                  sn           : Input_Proc_cal;
              VAR PunktyKalibr : ARRAY OF REAL;
                  Nazwa        : FixedArray;
                  Log          : BOOLEAN;
                  channel      : CommCh;
                  auto         : BOOLEAN;
                  navCntrlProc : ConvertProc;
                  navComm      : CommandRealPar;
                  autoWaitTime : REAL;
                  inputCoeff   : REAL     ) : BOOLEAN;

  TYPE
    Rejestr =
      ARRAY [0 .. 100] OF INTEGER;
  VAR
    lidx             : CARDINAL;
    LastVal          : REAL;
    LastValCal       : REAL;
    dtaSign          : DGHInterface.DtaSignType;
    str              : ARRAY [0 .. 99] OF CHAR;
    s_s              : RECORD
                         adr :
                           ADDRESS;
                         int :
                           REAL;
                       END;
    forCount         : INTEGER;
    x                : Rejestr;
    punktyKalibr_INT : Rejestr;
    duration         : Duration;
    maxError         : REAL;
    
    PROCEDURE OpiszOsie;
    VAR
      opisPodzX  : ARRAY [0 .. 20] OF REAL;
      iloscPodzX : CARDINAL;
      count      : INTEGER;
      idx        : CARDINAL;

    BEGIN
      idx := 0;
      iloscPodzX := 0;
      FOR count := -zkrsPrzetw TO zkrsPrzetw BY skokDzialkiPrzetw DO
        opisPodzX[idx] := real(count);
        INC(iloscPodzX);
        INC(idx);
      END (* for count *);
      OpisLog(ScreenR,
              -FLOAT(zkrsPrzetw),
              FLOAT(zkrsPrzetw),
              PunktyKalibr[0],
              PunktyKalibr[HIGH(PunktyKalibr)],
              opisPodzX,
              iloscPodzX,
              PunktyKalibr,
              lidx,
              FALSE,
              kol_tla,
              kol_osi,
              FALSE,
              Log,
              TRUE);
    END OpiszOsie;

    PROCEDURE CountX
              (    Y2,
                   Y1,
                   Y,
                   X2,
                   X1 : REAL ) : REAL;

    BEGIN
      RETURN X1 - (Y1 - Y) / (Y2 - Y1) * (X2 - X1);
    END CountX;

  BEGIN (* MulSegCal *)
    maxError := 0.0;
    lidx := HIGH(PunktyKalibr);
    OpiszOsie;
    s_s.adr := ADR(Nazwa);
    x[0] := lidx + 1;
    punktyKalibr_INT[0] := x[0];
    FOR forCount := 0 TO lidx DO
      punktyKalibr_INT[forCount + 1] := entier(PunktyKalibr[forCount]);
      x[forCount + 1] := entier(OldSegments[forCount]);
      IF x[forCount + 1] > zkrsPrzetw
      THEN
        x[forCount + 1] := zkrsPrzetw
      ELSIF x[forCount + 1] < -zkrsPrzetw
      THEN
        x[forCount + 1] := -zkrsPrzetw
      END (* if *);
    END (* for i *);
    PokazWykresNSLog(x,
                     punktyKalibr_INT,
                     OdPoczatku,
                     Wszystko,
                     -zkrsPrzetw,
                     zkrsPrzetw,
                     ScreenR,
                     PunktyKalibr[0],
                     PunktyKalibr[lidx],
                     kol_ws,
                     FALSE,
                     Log);
    x[0] := 0;
    punktyKalibr_INT[0] := 0;
    AssignDuration(auto,
                   autoWaitTime,
                   duration);
    FOR forCount := 0 TO lidx - 2 DO
      s_s.int := PunktyKalibr[forCount + 1] * inputCoeff;
      IF auto
      THEN
        IF NOT navCntrlProc(s_s.int,
                            navComm)
        THEN
          Info("Nie moge ustawic generatora przez GPIB");
          Wait(3 * TInOneSecond());
          Info("");
          RETURN FALSE;
        END (* if *);
        sprintf(str,
                "Ustawiam %s na %8.1f (ESC przerwij)",
                s_s);
      ELSE
        sprintf(str,
                "Ustaw %s na %8.1f i wci˜nij SPACJE",
                s_s);
      END (* if auto *);
      Info(str);
      CASE WaitMultiCh(PunktyKalibr[forCount + 1],
                       sn,
                       channel,
                       duration, maxError) OF
        ' ' :
          IF NOT sn(LastVal,
                    LastValCal,
                    dtaSign,
                    channel)
          THEN
            Info("Bˆ¥d odczytu kostki DGH");
            Wait(TInOneSecond());
            Info("");
            RETURN FALSE;
          END (* if *);
        |
        's', 'S' :
          LastVal := OldSegments[forCount + 1];
          LastValCal := PunktyKalibr[forCount + 1];
      ELSE
        Info("Procedura zaniechana");
        Wait(TInOneSecond());
        Info("");
        RETURN FALSE;
      END (* case WaitMultiCh *);
      GorszeBoDalszeR( maxError, PunktyKalibr[forCount + 1] - LastValCal);
      OldSegments[forCount + 1] := LastVal;
      punktyKalibr_INT[forCount + 1] := entier(PunktyKalibr[forCount + 1]);
      x[forCount + 1] := entier(LastVal);
      INC(x[0]);
      INC(punktyKalibr_INT[0]);
      PokazWykresNSLog(x,
                       punktyKalibr_INT,
                       OdPoczatku,
                       Wszystko,
                       -zkrsPrzetw,
                       zkrsPrzetw,
                       ScreenR,
                       PunktyKalibr[0],
                       PunktyKalibr[lidx],
                       kol_wn,
                       FALSE,
                       Log);
    END (* for i *);
    OldSegments[0] := CountX(PunktyKalibr[2],
                             PunktyKalibr[1],
                             PunktyKalibr[0],
                             OldSegments[2],
                             OldSegments[1]);
    OldSegments[lidx] := CountX(PunktyKalibr[lidx - 1],
                                PunktyKalibr[lidx - 2],
                                PunktyKalibr[lidx],
                                OldSegments[lidx - 1],
                                OldSegments[lidx - 2]);
    IF NOT auto AND NOT MsgBox.Info("Procedura zakonczona - zapisac dane?")
    THEN
      Info("Procedura zaniechana");
      Wait(TInOneSecond());
      Info("");
      RETURN FALSE
    END (* if *);
    Pokaz("Procedura zakoäczona",
          FALSE);
    RETURN TRUE
  END MulSegCal;

  PROCEDURE Conv_LocGsMod
            (    pk   : REAL;
                 comm : CommandRealPar ) : BOOLEAN;
  BEGIN
    RETURN DoCommandRealPar(Mod90Hz,  pk * 0.5) AND
           DoCommandRealPar(Mod150Hz, pk * 0.5)
  END Conv_LocGsMod;

  PROCEDURE Conv_LocDDM
            (    pk   : REAL;
                 comm : CommandRealPar ) : BOOLEAN;
  VAR
    ok : BOOLEAN;

  BEGIN
    IF NOT DoCommandRealPar(comm,
                            ABS(pk) / 150.0 * 0.155)
    THEN
      RETURN FALSE
    END (* if *);
    IF entier(pk) * znakSL > 0
    THEN
      RETURN DoSimpleComm(LocRefRight); (* w generatorze strony sa odwrotnie *)
    ELSE
      RETURN DoSimpleComm(LocRefLeft);  (* w generatorze strony sa odwrotnie *)
    END (* if entier *);
  END Conv_LocDDM;

  PROCEDURE Conv_GsDDM
            (    pk   : REAL;
                 comm : CommandRealPar ) : BOOLEAN;
  VAR
    ok : BOOLEAN;

  BEGIN
    IF NOT DoCommandRealPar(comm,
                            ABS(pk) /150.0 * 0.175)
    THEN
      RETURN FALSE
    END (* if *);
    IF entier(pk) * znakGora > 0
    THEN
      ok := DoSimpleComm(GSRefUp);
    ELSE
      ok := DoSimpleComm(GSRefDown);
    END (* if entier *);
    RETURN ok;
  END Conv_GsDDM;

  PROCEDURE Conv_Comm
            (    pk   : REAL;
                 comm : CommandRealPar ) : BOOLEAN;

  BEGIN
    RETURN DoCommandRealPar(comm,
                            pk);
  END Conv_Comm;

  PROCEDURE Conv_REF
            (    pk   : REAL;
                 comm : CommandRealPar ) : BOOLEAN;

  BEGIN
    IF pk = 0.0  THEN
      RETURN DoCommandRealPar(comm,
                              pk);
    ELSE
      RETURN DoCommandRealPar(comm,
                              30.0);
    END;
    
  END Conv_REF;

  PROCEDURE KalibracjaLocAGC
            (    ch   : CommCh;
                 auto : BOOLEAN ): BOOLEAN;

  BEGIN
    IF auto AND NOT LOC_Default()
    THEN
      RETURN FALSE
    END (* if *);
    IF MulSegCal(PopParam[ch].VorAgc,
                 VOR_AGC_pc,
                 AGCwartosciProgow,
                 LOC_AGC_Str,
                 TRUE,
                 ch,
                 auto,
                 Conv_Comm,
                 RFLevel,
                 VorAgc_delay,
                 inputCoeff[ch, AGCLocVor])
    THEN
      Par[ch].VorAgc := PopParam[ch].VorAgc;
      SaveSegmentTables;
      RETURN LOC_Default()
    ELSE
      PopParam[ch].VorAgc := Par[ch].VorAgc;
      RETURN FALSE
    END (* if *);
  END KalibracjaLocAGC;
  
  PROCEDURE KalibracjaLocDev
            (    ch   : CommCh;
                 auto : BOOLEAN ) : BOOLEAN;

  BEGIN
    IF auto AND NOT LOC_Default()
    THEN
      RETURN FALSE
    END (* if *);
    IF MulSegCal(PopParam[ORD(ch)].LocDev,
                 LOC_DEV_pc,
                 LOC_DEVPuntyKal,
                 LOC_DEV_Str,
                 FALSE,
                 ch,
                 auto,
                 Conv_LocDDM,
                 DDM,
                 LocDev_delay,
                 1.0)
    THEN
      Par[ORD(ch)].LocDev := PopParam[ORD(ch)].LocDev;
      SaveSegmentTables;
      RETURN TRUE
    ELSE
      PopParam[ch].LocDev := Par[ch].LocDev;
      RETURN LOC_Default()
    END (* if *);
  END KalibracjaLocDev;

  PROCEDURE KalibracjaGsDev
            (    ch   : CommCh;
                 auto : BOOLEAN ) : BOOLEAN;

  BEGIN
    IF auto AND NOT GS_Default()
    THEN
      RETURN FALSE
    END (* if *);
    IF MulSegCal(PopParam[ch].GsDev,
                 GS_DEV_pc,
                 GS_DEVPuntyKal,
                 GS_DEV_Str,
                 FALSE,
                 ch,
                 auto,
                 Conv_GsDDM,
                 DDM,
                 GsDev_delay,
                 1.0)
    THEN
      Par[ch].GsDev := PopParam[ch].GsDev;
      SaveSegmentTables;
      RETURN GS_Default()
    ELSE
      PopParam[ch].GsDev := Par[ch].GsDev;
      RETURN FALSE
    END (* if *);
  END KalibracjaGsDev;

  PROCEDURE KalibracjaLocMod
            (    ch   : CommCh;
                 auto : BOOLEAN ) : BOOLEAN;

  BEGIN
    IF auto AND NOT LOC_Default()
    THEN
      RETURN FALSE
    END (* if *);
    IF MulSegCal(PTabKalib2P[ch,
                 LocPrcMod].punktyPom,
                 LOC_MOD_pc,
                 PTabKalib2P[ch,
                 LocPrcMod].punktyKal,
                 LOC_MOD_Str,
                 FALSE,
                 ch,
                 auto,
                 Conv_LocGsMod,
                 Mod90Hz,
                 LocPrcMod_delay,
                 1.0)
    THEN
      TabKalib2P[ch,
      LocPrcMod].punktyPom := PTabKalib2P[ch,
                              LocPrcMod].punktyPom;
      SaveSegmentTables;
      RETURN LOC_Default()
    ELSE
      PTabKalib2P[ch,
      LocPrcMod].punktyPom := TabKalib2P[ch,
                              LocPrcMod].punktyPom;
      RETURN FALSE
    END (* if MulSegCal *);
  END KalibracjaLocMod;

  PROCEDURE KalibracjaGsMod
            (    ch   : CommCh;
                 auto : BOOLEAN ) : BOOLEAN;

  BEGIN
    IF auto AND NOT GS_Default()
    THEN
      RETURN FALSE
    END (* if *);
    IF MulSegCal(PTabKalib2P[ch,
                 GsPrcMod].punktyPom,
                 GS_MOD_pc,
                 PTabKalib2P[ch,
                 GsPrcMod].punktyKal,
                 GS_MOD_Str,
                 FALSE,
                 ch,
                 auto,
                 Conv_LocGsMod,
                 Mod90Hz,
                 GsPrcMod_delay,
                 1.0)
    THEN
      TabKalib2P[ch,
      GsPrcMod].punktyPom := PTabKalib2P[ch,
                             GsPrcMod].punktyPom;
      SaveSegmentTables;
      RETURN GS_Default() 
    ELSE
      PTabKalib2P[ch,
      GsPrcMod].punktyPom := TabKalib2P[ch,
                             GsPrcMod].punktyPom;
      RETURN FALSE
    END (* if MulSegCal *);
  END KalibracjaGsMod;

  PROCEDURE KalibracjaGsAGC
            (    ch   : CommCh;
                 auto : BOOLEAN ) : BOOLEAN;

  BEGIN
    IF auto AND NOT GS_Default()
    THEN
      RETURN FALSE
    END (* if *);
    IF MulSegCal(PopParam[ch].GsAgc,
                 GS_AGC_pc,
                 AGCwartosciProgow,
                 GS_AGC_Str,
                 TRUE,
                 ch,
                 auto,
                 Conv_Comm,
                 RFLevel,
                 GsAgc_delay,
                 inputCoeff[ch, AGCGs])
    THEN
      Par[ch].GsAgc := PopParam[ch].GsAgc;
      SaveSegmentTables;
      RETURN GS_Default()
    ELSE
      PopParam[ch].GsAgc := Par[ch].GsAgc;
      RETURN FALSE
    END (* if *);
  END KalibracjaGsAGC;

  PROCEDURE KalibracjaMkrAGC
            (    ch   : CommCh;
                 auto : BOOLEAN ) : BOOLEAN;

  BEGIN
    IF auto AND NOT MKR_Default()
    THEN
      RETURN FALSE
    END (* if *);
    IF MulSegCal(PopParam[ch].MkrAgc,
                 MKR_AGC_pc,
                 AGCwartosciProgowM,
                 "MKR.AGC",
                 TRUE,
                 ch,
                 auto,
                 Conv_Comm,
                 RFLevel,
                 MkrAgc_delay,
                 inputCoeff[ch, AGCMkr])
    THEN
      Par[ch].MkrAgc := PopParam[ch].MkrAgc;
      SaveSegmentTables;
      RETURN MKR_Default()
    ELSE
      PopParam[ch].MkrAgc := Par[ch].MkrAgc;
      RETURN FALSE
    END (* if *);
  END KalibracjaMkrAGC;

  PROCEDURE ILSWszystko
            (    ch   : CommCh;
                 auto : BOOLEAN ) : BOOLEAN;

  TYPE
    State =
      ( LocDev,
        LocMod,
        LocAGC,
        GsDev,
        GsMod,
        GsAgc,
        MkrAgc );
  VAR
    currState : State;
    res       : BOOLEAN;

  BEGIN
    currState := LocDev;
    res := FALSE;
    LOOP
      CASE currState OF
        LocDev :
          IF KalibracjaLocDev(ch,
                              auto)
          THEN
            currState := LocMod;
          ELSE
            EXIT;
          END (* if KalibracjaLocDev *);
        |
        LocMod :
          IF KalibracjaLocMod(ch,
                              auto)
          THEN
            currState := LocAGC;
          ELSE
            EXIT;
          END (* if KalibracjaLocMod *);
        |
        LocAGC :
          IF KalibracjaLocAGC(ch,
                              auto)
          THEN
            currState := GsDev;
          ELSE
            EXIT;
          END (* if KalibracjaVorAGC *);
        |
        GsDev :
          IF KalibracjaGsDev(ch,
                             auto)
          THEN
            currState := GsMod;
          ELSE
            EXIT;
          END (* if KalibracjaGsDev *);
        |
        GsMod :
          IF KalibracjaGsMod(ch,
                             auto)
          THEN
            currState := GsAgc;
          ELSE
            EXIT;
          END (* if KalibracjaGsMod *);
        |
        GsAgc :
          IF KalibracjaGsAGC(ch,
                             auto)
          THEN
            currState := MkrAgc;
          ELSE
            EXIT;
          END (* if KalibracjaGsAGC *);
        |
        MkrAgc :
          IF KalibracjaMkrAGC(ch,
                              auto)
          THEN
            res := TRUE;
          ELSE
            EXIT;
          END (* if KalibracjaMkrAGC *);
          EXIT;
      END (* case currState *);
    END (* loop *);
    RETURN res AND LOC_Default();
  END ILSWszystko;

  PROCEDURE KalibracjaVorRef
            (    ch   : CommCh;
                 auto : BOOLEAN ) : BOOLEAN;

  BEGIN
    IF auto AND NOT VOR_Default()
    THEN
      RETURN FALSE
    END (* if *);
    IF MulSegCal(PTabKalib2P[ch,
                 VorRefPrcMod].punktyPom,
                 VOR_REF_pc,
                 PTabKalib2P[ch, VorRefPrcMod].punktyKal,
                 VOR_REF_Str,
                 FALSE,
                 ch,
                 auto,
                 Conv_REF,
                 Mod9960Hz,
                 VorRefPrcMod_delay, 
                 1.0)
    THEN
      TabKalib2P[ch,
      VorRefPrcMod].punktyPom := PTabKalib2P[ch,
                                 VorRefPrcMod].punktyPom;
      SaveSegmentTables;
      RETURN VOR_Default()
    ELSE
      PTabKalib2P[ch,
      VorRefPrcMod].punktyPom := TabKalib2P[ch,
                                 VorRefPrcMod].punktyPom;
      RETURN FALSE;
    END (* if MulSegCal *);
  END KalibracjaVorRef;

  PROCEDURE KalibracjaVorVar
            (    ch   : CommCh;
                 auto : BOOLEAN ) : BOOLEAN;

  BEGIN
    IF auto AND NOT VOR_Default()
    THEN
      RETURN FALSE
    END (* if *);
    IF MulSegCal(PTabKalib2P[ch,
                 VorVarPrcMod].punktyPom,
                 VOR_VAR_pc,
                 PTabKalib2P[ch,
                 VorVarPrcMod].punktyKal,
                 VOR_VAR_Str,
                 FALSE,
                 ch,
                 auto,
                 Conv_Comm,
                 Mod30Hz,
                 VorVarPrcMod_delay,
                 1.0)
    THEN
      TabKalib2P[ch,
      VorVarPrcMod].punktyPom := PTabKalib2P[ch,
                                 VorVarPrcMod].punktyPom;
      SaveSegmentTables;
      RETURN VOR_Default()
    ELSE
      PTabKalib2P[ch,
      VorVarPrcMod].punktyPom := TabKalib2P[ch,
                                 VorVarPrcMod].punktyPom;
      RETURN FALSE
    END (* if MulSegCal *);
  END KalibracjaVorVar;

  PROCEDURE KalibracjaOmnibearing
            (    ch   : CommCh;
                 auto : BOOLEAN ) : BOOLEAN;

  BEGIN
    IF auto AND NOT VOR_Default()
    THEN
      RETURN FALSE
    END (* if *);
    IF DoOmnibearing(PopParam[ch].Omnibearing,
                     ch,
                     auto,
                     Conv_Comm,
                     Bearing,
                     Omnibearing_delay)
    THEN
      Par[ch].Omnibearing := PopParam[ch].Omnibearing;
      SaveSegmentTables;
      RETURN VOR_Default()
    ELSE
      PopParam[ch].Omnibearing := Par[ch].Omnibearing;
      RETURN FALSE
    END (* if DoOmnibearing *);
  END KalibracjaOmnibearing;

  PROCEDURE KalibracjaSubcar
            (    ch   : CommCh;
                 auto : BOOLEAN ) : BOOLEAN;

  BEGIN
    IF auto AND NOT VOR_Default()
    THEN
      RETURN FALSE
    END (* if *);
    IF MulSegCal(PTabKalib2P[ch,
                 SubcarPrcMod].punktyPom,
                 VOR_SUBCAR_pc,
                 PTabKalib2P[ch,
                 SubcarPrcMod].punktyKal,
                 VOR_SUB_Str,
                 FALSE,
                 ch,
                 auto,
                 Conv_Comm,
                 Mod9960Hz,
                 SubcarPrcMod_delay,
                 1.0)
    THEN
      TabKalib2P[ch,
      SubcarPrcMod].punktyPom := PTabKalib2P[ch,
                                 SubcarPrcMod].punktyPom;
      SaveSegmentTables;
      RETURN VOR_Default()
    ELSE
      PTabKalib2P[ch,
      SubcarPrcMod].punktyPom := TabKalib2P[ch,
                                 SubcarPrcMod].punktyPom;
      RETURN FALSE
    END (* if MulSegCal *);
  END KalibracjaSubcar;

  PROCEDURE KalibracjaVorAGC
            (    ch   : CommCh;
                 auto : BOOLEAN ) : BOOLEAN;

  BEGIN
    IF auto AND NOT VOR_Default()
    THEN
      RETURN FALSE
    END (* if *);
    IF MulSegCal(PopParam[ch].VorAgc,
                 VOR_AGC_pc,
                 AGCwartosciProgow,
                 VOR_AGC_Str,
                 TRUE,
                 ch,
                 auto,
                 Conv_Comm,
                 RFLevel,
                 VorAgc_delay,
                 inputCoeff[ch, AGCLocVor])
    THEN
      Par[ch].VorAgc := PopParam[ch].VorAgc;
      SaveSegmentTables;
      RETURN VOR_Default()
    ELSE
      PopParam[ch].VorAgc := Par[ch].VorAgc;
      RETURN FALSE
    END (* if *);
  END KalibracjaVorAGC;

  PROCEDURE VORWszystko
            (    ch   : CommCh;
                 auto : BOOLEAN ) : BOOLEAN;

  TYPE
    State =
      ( VorRef,
        VorVar,
        Omnibearing,
        Subcar,
        VorAGC );
  VAR
    currState : State;
    res       : BOOLEAN;

  BEGIN
    currState := VorRef;
    res := FALSE;
    LOOP
      CASE currState OF
        VorRef :
          IF KalibracjaVorRef(ch,
                              auto)
          THEN
            currState := VorVar;
          ELSE
            EXIT;
          END (* if KalibracjaVorRef *);
        |
        VorVar :
          IF KalibracjaVorVar(ch,
                              auto)
          THEN
            currState := Omnibearing;
          ELSE
            EXIT;
          END (* if KalibracjaVorVar *);
        |
        Omnibearing :
          IF KalibracjaOmnibearing(ch,
                                   auto)
          THEN
            currState := Subcar;
          ELSE
            EXIT;
          END (* if KalibracjaOmnibearing *);
        |
        Subcar :
          IF KalibracjaSubcar(ch,
                              auto)
          THEN
            currState := VorAGC;
          ELSE
            EXIT;
          END (* if KalibracjaSubcar *);
        |
        VorAGC :
          IF KalibracjaVorAGC(ch,
                              auto)
          THEN
            res := TRUE;
          END (* if KalibracjaVorAGC *);
          EXIT;
      END (* case currState *);
    END (* loop *);
    RETURN res AND VOR_Default();
  END VORWszystko;

  PROCEDURE KalibracjaDmeSquitter
            (    ch : CommCh );

  BEGIN
    IF MulSegCal(PTabKalib2P[ch,
                 DmeSquitter].punktyPom,
                 DME_SQUITTER_pc,
                 PTabKalib2P[ch,
                 DmeSquitter].punktyKal,
                 DME_SQR_Str,
                 FALSE,
                 ch,
                 noauto,
                 Conv_Comm,
                 RFLevel,
                 1.0,
                 1.0)
    THEN
      TabKalib2P[ch,
      DmeSquitter].punktyPom := PTabKalib2P[ch,
                                DmeSquitter].punktyPom;
      SaveSegmentTables;
    ELSE
      PTabKalib2P[ch,
      DmeSquitter].punktyPom := TabKalib2P[ch,
                                DmeSquitter].punktyPom;
    END (* if MulSegCal *);
  END KalibracjaDmeSquitter;

  PROCEDURE KalibracjaDmeAGC
            (    ch : CommCh );

  BEGIN
    IF MulSegCal(PopParam[ch].DmeAgc,
                 DME_AGC_pc,
                 AGCwartosciProgowD,
                 DME_AGC_Str,
                 FALSE,
                 ch,
                 noauto,
                 Conv_Comm,
                 RFLevel,
                 1.0,
                 1.0)
    THEN
      Par[ch].DmeAgc := PopParam[ch].DmeAgc;
      SaveSegmentTables;
    ELSE
      PopParam[ch].DmeAgc := Par[ch].DmeAgc;
    END (* if *);
  END KalibracjaDmeAGC;

  PROCEDURE KalibracjaDmeReply
            (    ch : CommCh );

  BEGIN
    IF MulSegCal(PTabKalib2P[ch,
                 DmePrcReply].punktyPom,
                 DME_RPL_pc,
                 PTabKalib2P[ch,
                 DmePrcReply].punktyKal,
                 DME_RPL_Str,
                 FALSE,
                 ch,
                 noauto,
                 Conv_Comm,
                 RFLevel,
                 1.0,
                 1.0)
    THEN
      TabKalib2P[ch,
      DmePrcReply].punktyPom := PTabKalib2P[ch,
                                DmePrcReply].punktyPom;
      SaveSegmentTables;
    ELSE
      PTabKalib2P[ch,
      DmePrcReply].punktyPom := TabKalib2P[ch,
                                DmePrcReply].punktyPom;
    END (* if MulSegCal *);
  END KalibracjaDmeReply;

  PROCEDURE KalibracjaADF
            (    ch : CommCh );

  BEGIN
    IF MulSegCal(PopParam[ch].AdfAgc,
                 ADF_AGC_pc,
                 AGCwartosciProgow,
                 ADF_AGC_Str,
                 TRUE,
                 ch,
                 noauto,
                 Conv_Comm,
                 RFLevel,
                 1.0,
                 1.0)
    THEN
      Par[ch].AdfAgc := PopParam[ch].AdfAgc;
      SaveSegmentTables;
    ELSE
      PopParam[ch].AdfAgc := Par[ch].AdfAgc;
    END (* if *);
  END KalibracjaADF;

  PROCEDURE KalibracjaVHF
            (    ch : CommCh );

  BEGIN
    IF MulSegCal(PopParam[ch].VhfAgc,
                 VHF_AGC_pc,
                 AGCwartosciProgow,
                 VHF_AGC_Str,
                 TRUE,
                 ch,
                 noauto,
                 Conv_Comm,
                 RFLevel,
                 1.0,
                 1.0)
    THEN
      Par[ch].VhfAgc := PopParam[ch].VhfAgc;
      SaveSegmentTables;
    ELSE
      PopParam[ch].VhfAgc := Par[ch].VhfAgc;
    END (* if *);
  END KalibracjaVHF;

BEGIN
  Init;
  NewChrono(chrono);
  PopParam := Par;
  PTabKalib2P := TabKalib2P;
END Skl_utls.
