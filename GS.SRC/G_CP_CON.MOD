(*.F- *)
(**********************************************************************
|  Title   : Sterowanie wskaznikami nawigacyjnymi dla GS
|  Author  : M.Postol
|  System  : LOGITECH MODULA-2/86
|  History :
|    27-10-96: M.Postol
|      created
|    29-01-97: M.Postol
|      zmiana sterowaniem pilota w wybranej procedurze
|    25-02-97: M.Postol
|      usunolem niepotrzebny import
|      na zasiegach +/-8ø sterowanie jest wzgledem GPS'a
|    13-03-97: M.Postol
|      na zasiegach +/-8ø sterowanie znowu jest wzgledem TEO
|    26-03-97: M.Postol
|      zlikwidowalem w zasiegach odwolanie do RefAlfa, ktore w tych 
|      procedurach bylo azymutem.
|
|  Copyright (C), CAS LODZ POLAND.
|  TEL: 42' 862 547, 42' 87 80 44 FAX/TEL: 42' 84 48 40
|
**********************************************************************)
(*.F+ *)

IMPLEMENTATION MODULE G_CP_ControlProc;

  FROM MathLib0 IMPORT
    entier;

  FROM MANAGER IMPORT
    Assert;

  FROM SYSTEM IMPORT
    WORD;

  FROM ScannerI IMPORT
    SetEvalPROC, RefAlfa, pilErr, TeoAlfaF;

  FROM CommonTypes IMPORT
    NilValC, SigNilVal, GlownyOdbiornikT, OdnDlaPomBleduT;

  FROM CocpDsp IMPORT
    (* TYPE *) State,
    (* PROCEDURE *) UstawFormat, UstawZmienne, SetIdleMsg;

  FROM SpecConv IMPORT
    SubAngle100;

  FROM L_DataBase IMPORT
    LOC_O_czuloscWP, LOC_O_czuloscCP, LOC_R_czuloscWP, LOC_R_czuloscCP, 
    LOC_Az_czuloscWP, GS_El_czuloscCP, LOC_Az_czuloscCP;

  FROM G_Odb IMPORT
    devL, devG, RefDisTT;

  FROM G_CommonTypes IMPORT
    ProceduraT;

  CONST
    AngVelMaxIdx = 95;
    AngVelMinVAl = 27;

  TYPE
    AngDirection   =
      ( CWdir,
        CCWdir,
        angDirUnknown,
        angAsPrevious );
    AngVelContiner =
      RECORD
        data          :
          ARRAY [0 .. AngVelMaxIdx - 1] OF INTEGER;
        idx           :
          CARDINAL;
        watchDog      :
          CARDINAL;
        prevDirection :
          AngDirection;
      END;
    PilErr_Fun = PROCEDURE(): INTEGER;
  VAR
    myOffset  : INTEGER;
    Running   : BOOLEAN;
    currRec   : GlownyOdbiornikT;
    currProc  : PROC;
    GSPilErr  : PilErr_Fun;
    LOCPilErr : PilErr_Fun;
    PilErrDis : PilErr_Fun;
    
  PROCEDURE Radial;
  BEGIN (* Radial *)
    pilErr := GSPilErr();
    UstawZmienne(ABS(RefDisTT), PilErrDis(), LOCPilErr(), pilErr);
  END Radial;

  PROCEDURE LOCDevErr(): INTEGER;
  BEGIN
    RETURN devL[currRec];
  END LOCDevErr;
  
  PROCEDURE LOCAzErr(): INTEGER;
  VAR
    pilErr : INTEGER;
  BEGIN
    pilErr := SubAngle100(TeoAlfaF, myOffset);
    IF pilErr = SigNilVal THEN
      RETURN SigNilVal
    ELSIF pilErr < -9000
    THEN
      RETURN pilErr + 18000;
    ELSIF pilErr > 9000
    THEN
      RETURN pilErr - 18000;
    ELSE
      RETURN pilErr
    END (* if perr *);
  END LOCAzErr;
  
  PROCEDURE GSDevErr(): INTEGER;
  BEGIN
    IF devG[currRec] = SigNilVal THEN
      RETURN SigNilVal;
    ELSE
      RETURN devG[currRec] - myOffset;
    END;
  END GSDevErr;
  
  PROCEDURE GSDevErrDis(): INTEGER;
  VAR
    pilErr : INTEGER;
    
  BEGIN
    IF devG[currRec] = SigNilVal  THEN
      RETURN SigNilVal;
    ELSE
      pilErr := devG[currRec] - myOffset;
      IF pilErr > 0  THEN
        RETURN (pilErr+5) DIV 10;
      ELSE
        RETURN (pilErr-5) DIV 10;
      END;
    END;
  END GSDevErrDis;
  
  PROCEDURE ElDis(): INTEGER;
  VAR
    pilErr : INTEGER;
    
  BEGIN
    IF RefAlfa = SigNilVal THEN
      RETURN SigNilVal;
    ELSIF RefAlfa < 999 THEN
      RETURN ( ABS(RefAlfa) + 5 ) DIV 10;
    ELSE
      RETURN SigNilVal;
    END;
  END ElDis;
  
  PROCEDURE AzDis(): INTEGER;
  VAR
    pilErr : INTEGER;
    
  BEGIN
    IF TeoAlfaF = SigNilVal THEN
      RETURN SigNilVal;
    ELSIF TeoAlfaF < 999 THEN
      RETURN ( ABS(TeoAlfaF) + 5 ) DIV 10;
    ELSE
      RETURN SigNilVal;
    END;
  END AzDis;
  
  PROCEDURE GsElErr(): INTEGER;
  VAR
    pilErr : INTEGER;
    
  BEGIN
    IF RefAlfa = SigNilVal THEN
      RETURN SigNilVal;
    ELSE
      pilErr := SubAngle100(RefAlfa, myOffset);
      IF pilErr < 999
      THEN
        RETURN pilErr;
      ELSE
        RETURN SigNilVal;
      END (* if pilErr *);
    END;
  END GsElErr;
  
  PROCEDURE GSDevDumm(): INTEGER;
  BEGIN
    RETURN SigNilVal;
  END GSDevDumm;
  
  PROCEDURE StartCPLoop
            (    proc  : ProceduraT;
                 param : INTEGER;
                 rec   : GlownyOdbiornikT );

  BEGIN
    Assert(NOT Running);
    currRec := rec;
    myOffset := param;
    CASE proc  OF
      pAlarmOsi, pSzerSektora_pA, pAlarmSzeroki_pA, pAlarmWaski_pA,
      pUstawienieOsi_Struktura, pUstawienieOsi_Szer_pA, 
      pUstawienieOsi_Waski_pA, pZabezpieczenie:
        GSPilErr  := GSDevErr;
        LOCPilErr := LOCDevErr;
        PilErrDis := GSDevErrDis;
        IF myOffset = 0
        THEN
          UstawFormat(LOCPrad, LOC_R_czuloscWP, LOC_R_czuloscCP);
        ELSE
          UstawFormat(LOCPradOffset, LOC_R_czuloscWP, LOC_R_czuloscCP);
        END;  
      |
      pPokrycieWOsi, pSzer_i_Osi_pB, pAlarmSzer_pB, pAlarmWaski_pB :
        GSPilErr  := GSDevDumm;
        LOCPilErr := LOCDevErr;
        PilErrDis := GSDevErrDis;
        UstawFormat(LOCPrad, LOC_R_czuloscWP, LOC_R_czuloscCP);
       |
      pRownowagaModulacji, pFazowanie :
        GSPilErr  := GSDevDumm; (* ?? ElDis *)
        LOCPilErr := LOCDevErr;
        PilErrDis := ElDis;
        UstawFormat(GSElew, MAX(CARDINAL), LOC_R_czuloscCP
                    (* !!!! GS_El_czuloscCP tu GS pokazuje kat a LOC prad 
                       i czulosc musi byc rozna*) 
                    );
      (*
      |
      pPokrycieWOsi:
        GSPilErr  := GSDevDumm;
        LOCPilErr := LOCDevErr;
        PilErrDis := ElDis;
        UstawFormat(LOCOdlegloscRgh, LOC_R_czuloscWP, LOC_R_czuloscCP);
      *)
      |
      pPokrycie8stP, pPokrycie8stL :
        GSPilErr  := GSDevDumm;
        LOCPilErr := LOCAzErr;
        PilErrDis := AzDis;
        UstawFormat(LOCOdlegloscRgh,  LOC_Az_czuloscWP, LOC_Az_czuloscCP);
    END;
    SetIdleMsg(197);
    currProc := Radial;
    SetEvalPROC(Radial, TRUE);
    Running := TRUE;
  END StartCPLoop;

  PROCEDURE StopCPLoop;

  BEGIN
    pilErr := SigNilVal;
    Assert(Running);
    SetEvalPROC(currProc, FALSE);
    UstawFormat(Idle, NilValC, NilValC);
    Running := FALSE;
  END StopCPLoop;

BEGIN
  currProc := PROC(NIL);
  pilErr := SigNilVal;
  Running := FALSE;
  myOffset := 0;
  GSPilErr := GSDevDumm;
  LOCPilErr := GSDevDumm;
  PilErrDis := GSDevDumm;
END G_CP_ControlProc.
