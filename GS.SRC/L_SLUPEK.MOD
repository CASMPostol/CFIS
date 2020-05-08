(*.F- *)
(**********************************************************************
|  Title   : Pomocnicze procedury obslugi ekranu dla GS
|  Author  : M.Postol
|  System  : LOGITECH MODULA-2/86
|  History :
|    27-10-96:
|      created
|    21-10-97: M.Postol
|      pZabezpieczenie jest realizowane jak szer sek w profilu A
|
|  Copyright (C), CAS LODZ POLAND.
|  TEL: 42' 862 547, 42' 87 80 44 FAX/TEL: 42' 84 48 40
|
**********************************************************************)
(*.F+ *)

IMPLEMENTATION MODULE L_Slupek;

  IMPORT
    SpecConv;

  FROM G_Odb IMPORT
    mod, TurnOn, SigEval, EvalVal;

  FROM CommonTypes IMPORT
    SlupekNr, GlownyOdbiornikT, SigNilVal, NilValI;

  FROM G_CommonTypes IMPORT
    ProceduraT;

  FROM Slupek IMPORT
    (* TYPE *) Baund;

  FROM SpecConv IMPORT
    (* TYPE *) ToStringProcT, GorszeBoProc,
    (* PROCEDURE *) Int10Str, Int100Str, Int2Str, GorszeBoMniejsze800,
                    GorszeBoDalszeOdZera, GorszeBoMniejsze, Int2StrCntr;

  FROM HiLevGraf IMPORT
    HDIB, LoadDIB, ShowDIB, CloseDIB;

  FROM GrafTypes IMPORT
    GREEN, RED, WHITE, RECT, POINT;

  FROM HiLevGraf IMPORT
    WrStrXY, Wr2StrXY;

  FROM G_results IMPORT
    anRes;

  FROM SYSTEM IMPORT
    BYTE;

  FROM ScreenCTypes IMPORT
    SkalaWpionieOpis, RodzWykr, slSReg_rec;

  FROM Strings IMPORT
    ConstAssign;

  FROM NumberConversion IMPORT
    IntToString;

  FROM G_CommonTypes IMPORT
    znakGora;

  FROM MathLib0 IMPORT
    real;

  CONST
    Move   = 4;
    Xdib   = 0;
    MaxPos = 11;
    Ydib   = 600 - 160;

  TYPE
    WriteProcT  =
      PROCEDURE
        (     ARRAY OF CHAR,
              INTEGER,
              INTEGER,
              BYTE,
              BYTE          );
    PositionDsc =
      RECORD
        Val      :
          SigEval;
        XposA    :
          CARDINAL;
        YposA    :
          CARDINAL;
        XposB    :
          CARDINAL;
        YposB    :
          CARDINAL;
        ToString :
          ToStringProcT;
        Write    :
          WriteProcT;
        Wykr     :
          RodzWykr;
      END;
    PosTableIdx =
      [0 .. MaxPos];
    ReginDsc    =
      RECORD
        regActive :
          BOOLEAN;
        regRec    :
          RECT;
      END;

  VAR
    regionyWyk       : ARRAY RodzWykr OF ReginDsc;
    screeenDIB       : HDIB;  (* dolna czes ekranu *)
    cursorDIB        : HDIB;  (* obrazek pod kursorem *)
    PosTable         : ARRAY [0 .. MaxPos] OF PositionDsc;
    currSkalaWpionie : SkalaWpionieOpis;

  PROCEDURE WrStrXYDummy
            (    s    : ARRAY OF CHAR;
                 x    : INTEGER;
                 y    : INTEGER;
                 fore : BYTE;
                 back : BYTE          );

  BEGIN
  END WrStrXYDummy;

  PROCEDURE GorszeBoDummy
            ( VAR val : INTEGER;
                  cv  : INTEGER );

  BEGIN
  END GorszeBoDummy;

  PROCEDURE ShowScreenDIB
            (     Src        : RECT;
                  Dest       : POINT;
              VAR ScreeenDIB : HDIB  );

  BEGIN
    ScreeenDIB := screeenDIB;
    ShowDIB(screeenDIB, Src, Dest, TRUE);
  END ShowScreenDIB;

  PROCEDURE ShowCursorDIB
            (    Src  : RECT;
                 Dest : POINT );

  BEGIN
    ShowDIB(cursorDIB, Src, Dest, FALSE);
  END ShowCursorDIB;

  PROCEDURE UnverslVal
            (     slupek : SlupekNr;
                  ChNR   : GlownyOdbiornikT;
              VAR s      : ARRAY OF CHAR;
              VAR val    : INTEGER          );

  BEGIN
    CASE slupek OF
      SlLewy :
        val := SigNilVal;
      |
      SlSrodkowy :
        val := mod[ChNR];
      |
      SlPrawy :
        val := SigNilVal;
    END (* case slupek *);
    Int10Str(val, s, 5);
  END UnverslVal;

  PROCEDURE NapiszSygnaly;
  VAR
    str    : ARRAY [0 .. 10] OF CHAR;
    isgIdx : CARDINAL;

  BEGIN
    FOR isgIdx := 0 TO MaxPos DO
      WITH PosTable[isgIdx] DO
        IF Val <> Non_OS
        THEN
          ToString(EvalVal[Val, goA], str, 5);
          Write(str, XposA, YposA, GREEN, WHITE);
          ToString(EvalVal[Val, goB], str, 5);
          Write(str, XposB, YposB, RED, WHITE);
        END (* if val *);
      END (* with PosTable *);
    END (* for isgIdx *);
  END NapiszSygnaly;

  PROCEDURE AssGorszeBoProc
            (    wykr : RodzWykr;
                 proc : GorszeBoProc );

  BEGIN
    CASE wykr OF
      WykMain :
        WykMainProc := proc;
      |
      Wyk1 :
        Wyk1Proc := proc;
      |
      Wyk2 :
        Wyk2Proc := proc;
      |
      Wyk3 :
        Wyk3Proc := proc;
    ELSE
    END (* case wykr *);
  END AssGorszeBoProc;

  PROCEDURE ModL_SWP
            (    wykr : RodzWykr );

  BEGIN
    WITH currSkalaWpionie[wykr] DO
      cecha := 1;
      mantysa := 10.0;
      magni := 10.0;
      convertProc := SpecConv.Int10Str;
      currOffset := 80.0;
      log := FALSE;
    END (* with currSkalaWpionie *);
    AssGorszeBoProc(wykr, GorszeBoMniejsze800);
  END ModL_SWP;

  PROCEDURE DewDif_SWP
            (    wykr : RodzWykr );

  BEGIN
    WITH currSkalaWpionie[wykr] DO
      cecha := 5;
      mantysa := 10.0;
      magni := 10.0;
      convertProc := SpecConv.Int10Str;
      currOffset := real(anRes.offset)/10.0;;
      log := FALSE;
    END (* with currSkalaWpionie *);
    AssGorszeBoProc(wykr, GorszeBoDalszeOdZera);
  END DewDif_SWP;

  PROCEDURE Az_SWP
            (    wykr : RodzWykr );

  BEGIN
    WITH currSkalaWpionie[wykr] DO
      cecha := 2;
      mantysa := 1.0;
      magni := 100.0;
      convertProc := SpecConv.Int100Str;
      WITH anRes DO
        currOffset:=( real(ustawOsi)
                     +real(znakGora)*real(secWith)*real(offset)/1500.0)/100.0;
      END;
      log := FALSE;
    END (* with currSkalaWpionie *);
    AssGorszeBoProc(wykr, GorszeBoDalszeOdZera);
  END Az_SWP;

  PROCEDURE Dew100_SWP
            (    wykr : RodzWykr );

  BEGIN
    WITH currSkalaWpionie[wykr] DO
    (* Dew_OS *)
      cecha := 5;
      mantysa := 100.0;
      magni := 10.0;
      convertProc := SpecConv.Int10Str;
      currOffset := real(anRes.offset)/10.0;
      log := FALSE;
    END (* with currSkalaWpionie *);
    AssGorszeBoProc(wykr, GorszeBoDalszeOdZera);
  END Dew100_SWP;

  PROCEDURE SS_SWP
            (    wykr : RodzWykr );

  BEGIN
    WITH currSkalaWpionie[wykr] DO
      cecha := 5;
      mantysa := 1000.0;
      magni := 1.0;
      convertProc := SpecConv.Int2Str;
      currOffset := 0.0;
      log := TRUE;
    END (* with currSkalaWpionie *);
    AssGorszeBoProc(wykr, GorszeBoMniejsze);
  END SS_SWP;

  PROCEDURE Alt_SWP
            (    wykr : RodzWykr );

  BEGIN
    WITH currSkalaWpionie[wykr] DO
      cecha := 5;
      mantysa := 1000.0;
      magni := 1.0;
      convertProc := SpecConv.Int2Str;
      currOffset := 0.0;
      log := TRUE;
    END (* with currSkalaWpionie *);
    AssGorszeBoProc(wykr, GorszeBoMniejsze);
  END Alt_SWP;

  PROCEDURE D_SWP
            (    wykr : RodzWykr );

  BEGIN
  END D_SWP;

  PROCEDURE InitSlupek;

  TYPE
    SWP_Procedure =
      PROCEDURE
        (     RodzWykr );
  VAR
    idx : CARDINAL;

    PROCEDURE Activate
              (    val      : SigEval;
                   xPosA    : CARDINAL;
                   yPosA    : CARDINAL;
                   xPosB    : CARDINAL;
                   yPosB    : CARDINAL;
                   toString : ToStringProcT;
                   size     : CARDINAL;
                   wykr     : RodzWykr;
                   swp      : SWP_Procedure );

    BEGIN
      WITH PosTable[idx] DO
        Val := val;
        XposA := xPosA + size * Move + Xdib;
        YposA := yPosA + size * Move + Ydib;
        XposB := xPosB + size * Move + Xdib;
        YposB := yPosB + size * Move + Ydib;
        ToString := toString;
        CASE size OF
          0 :
            Write := WrStrXYDummy;
          |
          1 :
            Write := WrStrXY;
          |
          2 :
            Write := Wr2StrXY;
        END (* case size *);
        Wykr := wykr;
        swp(wykr);
      END (* with PosTable *);
      INC(idx);
    END Activate;

    PROCEDURE regionyWykActv
              (    wyk : RodzWykr;
                   xL  : CARDINAL;
                   yT  : CARDINAL;
                   xR  : CARDINAL;
                   yB  : CARDINAL );

    BEGIN
      WITH regionyWyk[wyk] DO
        regActive := TRUE;
        regRec.left := xL + Xdib;
        regRec.top := yT + Ydib;
        regRec.right := xR + Xdib;
        regRec.bottom := yB + Ydib;
      END (* with regionyWyk *);
    END regionyWykActv;

    PROCEDURE regionyWykActvABS
              (    wyk : RodzWykr;
                   r   : RECT     );

    BEGIN
      WITH regionyWyk[wyk] DO
        regActive := TRUE;
        regRec := r;
      END (* with regionyWyk *);
    END regionyWykActvABS;

    PROCEDURE regionyWykInit;
    VAR
      wyk : RodzWykr;

    BEGIN
      FOR wyk := MIN(RodzWykr) TO MAX(RodzWykr) DO
        regionyWyk[wyk].regActive := FALSE;
      END (* for wyk *);
    END regionyWykInit;

    PROCEDURE WykProcInit;

    BEGIN
      AssGorszeBoProc(WykMain, GorszeBoDummy);
      AssGorszeBoProc(Wyk1, GorszeBoDummy);
      AssGorszeBoProc(Wyk2, GorszeBoDummy);
      AssGorszeBoProc(Wyk3, GorszeBoDummy);
    END WykProcInit;

  BEGIN (* InitSlupek *)
    regionyWykInit;
    WykProcInit;
    FOR idx := MIN(PosTableIdx) TO MAX(PosTableIdx) DO
      WITH PosTable[idx] DO
        Val := Non_OS;
      END (* with PosTable *);
    END (* for idx *);
    idx := MIN(PosTableIdx);
    CASE anRes.procedure OF
      pUstawienieOsi_Struktura, pAlarmOsi, pUstawienieOsi_Szer_pA,
      pUstawienieOsi_Waski_pA :
        screeenDIB := LoadDIB("GS1.DIB");
        Activate(Dif_OS, 230, 39, 308, 39, Int10Str, 2, WykMain, DewDif_SWP);
        regionyWykActv(WykMain, 235, 15, 396, 80);
        Activate(Mod_OS, 900, 900, 900, 900, Int10Str, 0, Wyk1, ModL_SWP);
        regionyWykActvABS(Wyk1, slSReg_rec);
        Activate(Dew_OS, 411, 54, 531, 54, Int10Str, 1, Wyk2, DewDif_SWP);
        regionyWykActv(Wyk2, 411, 54, 588, 76);
        Activate(SS_OS, 153, 36, 153, 56, Int2Str, 1, Wyk3, SS_SWP);
        regionyWykActv(Wyk3, 150, 34, 211, 77);
        Activate(DewLoc_OS, 235, 95, 235, 116, Int10Str, 1, WykNone, D_SWP);
        Activate(AzOsiAv_OS, 411, 15, 531, 15, Int100Str, 1, WykNone, D_SWP);
        Activate(AzOsiMin_OS, 411, 116, 531, 116, Int100Str, 1, WykNone, D_SWP)
        ;
        Activate(AzOsiMax_OS, 411, 95, 531, 95, Int100Str, 1, WykNone, D_SWP);
        Activate(Zone_OS, 0, 40, 900, 900, Int2StrCntr, 2, WykNone, D_SWP);
      |
      pSzerSektora_pA, pAlarmSzeroki_pA, pAlarmWaski_pA, pZabezpieczenie :
        screeenDIB := LoadDIB("GS5.DIB");
        Activate(DewOff_OS, 900, 900, 900, 900, Int10Str, 1, WykMain, DewDif_SWP)
        ;
        Activate(Dew_OS, 235, 39, 313, 39, Int10Str, 2, WykNone, D_SWP);
        regionyWykActv(WykMain, 235, 15, 396, 80);
        Activate(DifAZ_OS, 900, 900, 900, 900, Int100Str, 0, Wyk1, Az_SWP);
        regionyWykActv(Wyk1, 408, 87, 588, 136);
        Activate(Mod_OS, 900, 900, 900, 900, Int10Str, 0, Wyk2, ModL_SWP);
        regionyWykActvABS(Wyk2, slSReg_rec);
        Activate(SS_OS, 228, 95, 228, 116, Int2Str, 1, Wyk3, SS_SWP);
        regionyWykActv(Wyk3, 228, 95, 386, 136);
        Activate(AzAv_OS, 408, 33, 528, 33, Int100Str, 1, WykNone, D_SWP);
        Activate(AzMax_OS, 408, 95, 528, 95, Int100Str, 1, WykNone, D_SWP);
        Activate(AzMin_OS, 408, 116, 528, 116, Int100Str, 1, WykNone, D_SWP);
        Activate(Zone_OS, 0, 40, 900, 900, Int2StrCntr, 2, WykNone, D_SWP);
        Activate(Ofset_OS, 3, 100, 900, 900, Int10Str, 2, WykNone, D_SWP);
      |
      pSzer_i_Osi_pB, pAlarmSzer_pB, pAlarmWaski_pB:
        screeenDIB := LoadDIB("GS4.DIB");
        Activate(Dew_OS, 230, 39, 313, 39, Int10Str, 2, WykMain, Dew100_SWP);
        regionyWykActv(WykMain, 235, 15, 396, 80);
        Activate(Mod_OS, 900, 900, 900, 900, Int10Str, 0, Wyk1, ModL_SWP);
        regionyWykActvABS(Wyk1, slSReg_rec);
        Activate(SS_OS, 148, 36, 148, 57, Int2Str, 1, Wyk2, SS_SWP);
        regionyWykActv(Wyk2, 148 - 2, 36 - 2, 208 + 2, 77 + 2);
        Activate(Az75_90_OS, 148, 95, 268, 95, Int100Str, 1, WykNone, D_SWP);
        Activate(Az75_150_OS, 148, 116, 268, 116, Int100Str, 1, WykNone, D_SWP)
        ;
        Activate(DifAv0_OS, 408, 26, 528, 25, Int10Str, 1, WykNone, D_SWP);
        Activate(Az0_OS, 408, 65, 528, 64, Int100Str, 1, WykNone, D_SWP);
        Activate(Alt_OS, 528, 91, 900, 900, Int2Str, 1, WykNone, D_SWP);
        Activate(Elew_OS, 900, 900, 900, 900, Int100Str, 0, Wyk3, Az_SWP);
        regionyWykActv(Wyk3, 410, 64, 589, 85);
      |
      pRownowagaModulacji, pFazowanie, pPokrycieWOsi, pPokrycie8stP,
      pPokrycie8stL :
        screeenDIB := LoadDIB("GS15.DIB");
        IF (pPokrycieWOsi <= anRes.procedure) AND 
           ( pPokrycie8stL >= anRes.procedure)   THEN
          Activate(Dew_OS, 230, 39, 313, 39, Int10Str, 2, WykMain, Dew100_SWP);
        ELSE
          Activate(Dew_OS, 230, 39, 313, 39, Int10Str, 2, WykMain, DewDif_SWP);
        END;
        regionyWykActv(WykMain, 235, 15, 396, 80);
        Activate(Mod_OS, 900, 900, 900, 900, Int10Str, 0, Wyk1, ModL_SWP);
        regionyWykActvABS(Wyk1, slSReg_rec);
        Activate(SS_OS, 148, 36, 148, 57, Int2Str, 1, Wyk2, SS_SWP);
        regionyWykActv(Wyk2, 148, 34, 209, 78);
        Activate(Alt_OS, 528, 91, 900, 900, Int2Str, 1, Wyk3, Alt_SWP);
        regionyWykActv(Wyk3, 499, 89, 590, 112);
      (*
      |
      pZabezpieczenie :
        screeenDIB := LoadDIB("GS16.DIB");
        Activate(Dew_OS, 230, 39, 313, 39, Int10Str, 2, WykNone, D_SWP);
        Activate(DewOff_OS, 900, 900, 900, 900, Int10Str, 1, WykMain, DewDif_SWP);
        regionyWykActv(WykMain, 235, 15, 396, 80);
        Activate(Mod_OS, 900, 900, 900, 900, Int10Str, 0, Wyk1, ModL_SWP);
        regionyWykActvABS(Wyk1, slSReg_rec);
        Activate(SS_OS, 148, 36, 148, 57, Int2Str, 1, Wyk2, SS_SWP);
        regionyWykActv(Wyk2, 148, 34, 209, 78);
        Activate(Alt_OS, 528, 91, 900, 900, Int2Str, 1, Wyk3, Alt_SWP);
        regionyWykActv(Wyk3, 499, 89, 590, 112);
        Activate(Zone_OS, 0, 40, 900, 900, Int2StrCntr, 2, WykNone, D_SWP);
        Activate(Ofset_OS, 3, 100, 900, 900, Int10Str, 2, WykNone, D_SWP);
      *)
    END (* case anRes.procedure *);
    FOR idx := MIN(PosTableIdx) TO MAX(PosTableIdx) DO
      WITH PosTable[idx] DO
        TurnOn(Val, Wykr);
      END (* with PosTable *);
    END (* for idx *);
    cursorDIB := LoadDIB("kursor.dib");
  END InitSlupek;

  PROCEDURE DoneSlupek;

  BEGIN
    CloseDIB(cursorDIB);
    CloseDIB(screeenDIB);
  END DoneSlupek;

  PROCEDURE Init;

  BEGIN
    parSlupkow[SlLewy, Min] := NilValI;
    parSlupkow[SlLewy, Max] := NilValI;
    parSlupkow[SlLewy, minAlarm] := NilValI;
    parSlupkow[SlLewy, maxAlarm] := NilValI;
    parSlupkow[SlSrodkowy, Min] := 720;
    parSlupkow[SlSrodkowy, Max] := 880;
    parSlupkow[SlSrodkowy, minAlarm] := 780;
    parSlupkow[SlSrodkowy, maxAlarm] := 820;
    parSlupkow[SlPrawy, Min] := NilValI;
    parSlupkow[SlPrawy, Max] := NilValI;
    parSlupkow[SlPrawy, minAlarm] := NilValI;
    parSlupkow[SlPrawy, maxAlarm] := NilValI;
  END Init;

  PROCEDURE IniSkale
            ( VAR skalaWpionie : SkalaWpionieOpis );
  VAR
    wyk : RodzWykr;

  BEGIN
    skalaWpionie := currSkalaWpionie;
    FOR wyk := MIN(RodzWykr) TO MAX(RodzWykr) DO
      skalaWpionie[wyk].poziom := 1;
    END (* for wyk *);
  END IniSkale;

  PROCEDURE GetRegionWykG
            ( VAR rec : RECT ) : BOOLEAN;

  BEGIN
    WITH regionyWyk[WykMain] DO
      IF regActive
      THEN
        rec := regRec;
        RETURN TRUE;
      ELSE
        RETURN FALSE;
      END (* if regActive *);
    END (* with regionyWyk *);
  END GetRegionWykG;

  PROCEDURE GetRegionWyk1
            ( VAR rec : RECT ) : BOOLEAN;

  BEGIN
    WITH regionyWyk[Wyk1] DO
      IF regActive
      THEN
        rec := regRec;
        RETURN TRUE;
      ELSE
        RETURN FALSE;
      END (* if regActive *);
    END (* with regionyWyk *);
  END GetRegionWyk1;

  PROCEDURE GetRegionWyk2
            ( VAR rec : RECT ) : BOOLEAN;

  BEGIN
    WITH regionyWyk[Wyk2] DO
      IF regActive
      THEN
        rec := regRec;
        RETURN TRUE;
      ELSE
        RETURN FALSE;
      END (* if regActive *);
    END (* with regionyWyk *);
  END GetRegionWyk2;

  PROCEDURE GetRegionWyk3
            ( VAR rec : RECT ) : BOOLEAN;

  BEGIN
    WITH regionyWyk[Wyk3] DO
      IF regActive
      THEN
        rec := regRec;
        RETURN TRUE;
      ELSE
        RETURN FALSE;
      END (* if regActive *);
    END (* with regionyWyk *);
  END GetRegionWyk3;

BEGIN
  Init;
END L_Slupek.
