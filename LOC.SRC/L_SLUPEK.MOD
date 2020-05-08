(*.F- *)
(**********************************************************************
|  Title   : Pomocnicze procedury obslugi ekranu dla GS
|  Author  : M.Postol
|  System  : LOGITECH MODULA-2/86
|  History :
|    27-10-96:
|      created 
|      Az_SWP uzywam Int10 zamiast Int100
|    26-01-97: M.Postol
|      zmieniono sposob wyswietlania przy ofsetach 
|    17-02-97: M.Postol
|      Az_SWP - zmiana znaku ofsetu
|  Copyright (C), CAS LODZ POLAND.
|  TEL: 42' 862 547, 42' 87 80 44 FAX/TEL: 42' 84 48 40
|
**********************************************************************)
(*.F+ *)

IMPLEMENTATION MODULE L_Slupek;

  IMPORT
    SpecConv;

  FROM L_Odb IMPORT
    modL, TurnOn, SigEval, EvalVal;

  FROM CommonTypes IMPORT
    SlupekNr, GlownyOdbiornikT, SigNilVal, NilValI, znakSL;

  FROM L_CommonTypes IMPORT
    ProceduraT, NumStrefy;

  FROM Slupek IMPORT
    (* TYPE *) Baund;

  FROM SpecConv IMPORT
    (* TYPE *) ToStringProcT, GorszeBoProc,
    (* PROCEDURE *) Int10Str, Int100Str, Int2Str, GorszeBoMniejsze400,
                    GorszeBoDalszeOdZera, GorszeBoMniejsze, Feed500Str,
                    Int2StrCntr;

  FROM HiLevGraf IMPORT
    HDIB, LoadDIB, ShowDIB, CloseDIB;

  FROM GrafTypes IMPORT
    GREEN, RED, WHITE, RECT, POINT;

  FROM HiLevGraf IMPORT
    WrStrXY, Wr2StrXY;

  FROM L_results IMPORT
    anRes;

  FROM SYSTEM IMPORT
    BYTE;

  FROM ScreenCTypes IMPORT
    SkalaWpionieOpis, RodzWykr, slSReg_rec;

  FROM Strings IMPORT
    ConstAssign;

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
        val := modL[ChNR];
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
      currOffset := 40.0;
      log := FALSE;
    END (* with currSkalaWpionie *);
    AssGorszeBoProc(wykr, GorszeBoMniejsze400);
  END ModL_SWP;

  PROCEDURE DewDif_SWP
            (    wykr : RodzWykr );

  BEGIN
    WITH currSkalaWpionie[wykr] DO
      cecha := 5;
      mantysa := 10.0;
      magni := 10.0;
      convertProc := SpecConv.Int10Str;
      currOffset := real(anRes.offset)/10.0;
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
      WITH anRes  DO
        currOffset :=+real(znakSL)*real(secWith)*real(offset)/300000.0;
      END;
      log := FALSE;
    END (* with currSkalaWpionie *);
    AssGorszeBoProc(wykr, GorszeBoDalszeOdZera);
  END Az_SWP;

  PROCEDURE Dew10_SWP
            (    wykr : RodzWykr );

  BEGIN
    WITH currSkalaWpionie[wykr] DO
    (* Dew_OS *)
      cecha := 5;
      mantysa := 10.0;
      magni := 10.0;
      convertProc := SpecConv.Int10Str;
      currOffset := 0.0;
      log := FALSE;
    END (* with currSkalaWpionie *);
    AssGorszeBoProc(wykr, GorszeBoDalszeOdZera);
  END Dew10_SWP;

  PROCEDURE Dew100_SWP
            (    wykr : RodzWykr );

  BEGIN
    WITH currSkalaWpionie[wykr] DO
    (* Dew_OS *)
      cecha := 5;
      mantysa := 100.0;
      magni := 10.0;
      convertProc := SpecConv.Int10Str;
      currOffset := 0.0;
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
        screeenDIB := LoadDIB("ILS1.DIB");
        Activate(Dif_OS, 230, 39, 308, 39, Int10Str, 2, WykMain, DewDif_SWP);
        regionyWykActv(WykMain, 235, 15, 396, 80);
        Activate(ModL_OS, 900, 900, 900, 900, Int10Str, 0, Wyk1, ModL_SWP);
        regionyWykActvABS(Wyk1, slSReg_rec);
        Activate(Dew_OS, 411, 54, 531, 54, Int10Str, 1, Wyk2, DewDif_SWP);
        regionyWykActv(Wyk2, 411, 54, 588, 76);
        Activate(SS_OS, 228, 95, 228, 116, Int2Str, 1, Wyk3, SS_SWP);
        regionyWykActv(Wyk3, 228, 95, 386, 136);
        Activate(DifAv_OS, 411, 15, 531, 15, Int10Str, 1, WykNone, D_SWP);
        Activate(DifMin_OS, 411, 116, 531, 116, Int10Str, 1, WykNone, D_SWP);
        Activate(DifMax_OS, 411, 95, 531, 95, Int10Str, 1, WykNone, D_SWP);
        Activate(Zone_OS, 0, 40, 900, 900, Int2StrCntr, 2, WykNone, D_SWP);
      |
      pSzerSektora_pA, pAlarmSzeroki_pA, pAlarmWaski_pA :
        screeenDIB := LoadDIB("ILS5.DIB");
        Activate(Dew_OS, 235, 39, 313, 39, Int10Str, 2, WykNone, D_SWP);
        Activate(DewOff_OS, 900, 900, 900, 900, Int10Str, 1, WykMain, 
                 DewDif_SWP);
        regionyWykActv(WykMain, 235, 15, 396, 80);
        Activate(DifAZ_OS, 900, 900, 900, 900, Int100Str, 0, Wyk1, Az_SWP);
        regionyWykActv(Wyk1, 408, 87, 588, 136);
        Activate(ModL_OS, 900, 900, 900, 900, Int10Str, 0, Wyk2, ModL_SWP);
        regionyWykActvABS(Wyk2, slSReg_rec);
        Activate(SS_OS, 228, 95, 228, 116, Int2Str, 1, Wyk3, SS_SWP);
        regionyWykActv(Wyk3, 228, 95, 386, 136);
        Activate(AzAv_OS, 408, 33, 528, 33, Int100Str, 1, WykNone, D_SWP);
        Activate(AzMax_OS, 408, 95, 528, 95, Int100Str, 1, WykNone, D_SWP);
        Activate(AzMin_OS, 408, 116, 528, 116, Int100Str, 1, WykNone, D_SWP);
        Activate(Zone_OS, 0, 40, 900, 900, Int2StrCntr, 2, WykNone, D_SWP);
        Activate(Ofset_OS, 3, 100, 900, 900, Int10Str, 2, WykNone, D_SWP);
      |
      pSzer_i_Osi_pB, pAlarmSzer_pB, pAlarmWaski_pB, pWyrazistosc_na_d_katach :
        screeenDIB := LoadDIB("ILS4.DIB");
        Activate(Dew_OS, 230, 39, 313, 39, Int10Str, 2, WykMain, Dew100_SWP);
        regionyWykActv(WykMain, 235, 15, 396, 80);
        Activate(ModL_OS, 900, 900, 900, 900, Int10Str, 0, Wyk1, ModL_SWP);
        regionyWykActvABS(Wyk1, slSReg_rec);
        Activate(SS_OS, 148, 36, 148, 57, Int2Str, 1, Wyk2, SS_SWP);
        regionyWykActv(Wyk2, 148 - 2, 36 - 2, 208 + 2, 77 + 2);
        Activate(Az150_150_OS, 148, 95, 268, 95, Int100Str, 1, WykNone, D_SWP);
        Activate(Az75_150_OS, 148, 116, 268, 116, Int100Str, 1, WykNone, D_SWP)
        ;
        Activate(Az150_90_OS, 331, 95, 451, 95, Int100Str, 1, WykNone, D_SWP);
        Activate(Az75_90_OS, 331, 116, 451, 116, Int100Str, 1, WykNone, D_SWP);
        Activate(DifAv0_OS, 408, 25, 528, 25, Int10Str, 1, WykNone, D_SWP);
        Activate(Az0_OS, 408, 64, 528, 64, Int100Str, 1, WykNone, D_SWP);
      |
      pRownowagaModulacji, pFazowanie :
        screeenDIB := LoadDIB("ILS15.DIB");
        Activate(Dew_OS, 230, 39, 313, 39, Int10Str, 2, WykMain, Dew10_SWP);
        regionyWykActv(WykMain, 235, 15, 396, 80);
        Activate(ModL_OS, 900, 900, 900, 900, Int10Str, 0, Wyk1, ModL_SWP);
        regionyWykActvABS(Wyk1, slSReg_rec);
        Activate(SS_OS, 228, 95, 228, 116, Int2Str, 1, Wyk2, SS_SWP);
        regionyWykActv(Wyk2, 228, 95, 386, 136);
      |
      pZasieg_do_10, pZasieg_10_35, pZasieg_ponad_35 :
        screeenDIB := LoadDIB("ILS18.DIB");
        Activate(SS_OS, 228, 95, 228, 116, Int2Str, 1, WykMain, SS_SWP);
        regionyWykActv(WykMain, 228, 95, 386, 136);
        Activate(ModL_OS, 900, 900, 900, 900, Int10Str, 0, Wyk1, ModL_SWP);
        regionyWykActvABS(Wyk1, slSReg_rec);
        Activate(Dew_OS, 230, 39, 313, 39, Int10Str, 2, Wyk2, Dew100_SWP);
        regionyWykActv(Wyk2, 235, 15, 396, 80);
        Activate(SS150_Min_OS, 417, 40, 500, 40, Int2Str, 2, WykNone, D_SWP);
        Activate(SS90_Min_OS, 417, 82, 500, 82, Int2Str, 2, WykNone, D_SWP);
      |
      pMarker :
        screeenDIB := LoadDIB("ILS21.DIB");
        Activate(SS_Mkr_OS, 65, 39, 147, 39, Int2Str, 2, WykMain, SS_SWP);
        regionyWykActv(WykMain, 70, 15, 230, 80);
        Activate(OMkrL_OS, 408, 33, 527, 33, Feed500Str, 1, WykNone, D_SWP);
        Activate(MMkrL_OS, 408, 78, 527, 78, Feed500Str, 1, WykNone, D_SWP);
        Activate(IMkrL_OS, 408, 123, 527, 123, Feed500Str, 1, WykNone, D_SWP);
        Activate(DewOff_OS, 900, 900, 900, 900, Int10Str, 1, Wyk1, DewDif_SWP);
        Activate(Dew_OS, 230, 39, 313, 39, Int10Str, 2, WykNone, D_SWP);
        regionyWykActv(Wyk1, 234, 15, 396, 80);
        Activate(Ofset_OS, 3, 100, 900, 900, Int10Str, 2, WykNone, D_SWP);
        Activate(SS_OS, 228, 95, 228, 116, Int2Str, 1, Wyk2, SS_SWP);
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
    parSlupkow[SlSrodkowy, Min] := 320;
    parSlupkow[SlSrodkowy, Max] := 480;
    parSlupkow[SlSrodkowy, minAlarm] := 360;
    parSlupkow[SlSrodkowy, maxAlarm] := 440;
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
