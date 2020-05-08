(*.F- *)
(**********************************************************************
|  Title   : Sterowanie wskaznikami nawigacyjnymi dla LOC
|  Author  : M.Postol
|  System  : LOGITECH MODULA-2/86
|  History :
|    10-10-96: M.Postol
|      Zaokraglilem odleglosc na wyswietlaczu pilota na orbicie i 
|      promieniu
|    27-10-96: M.Postol
|      wywalilem niepotrzebne importy i zmienne
|
|  Copyright (C), CAS LODZ POLAND.
|  TEL: 42' 862 547, 42' 87 80 44 FAX/TEL: 42' 84 48 40
|
**********************************************************************)
(*.F+ *)

IMPLEMENTATION MODULE L_CP_ControlProc;

  FROM MathLib0 IMPORT
    entier;

  FROM MANAGER IMPORT
    Assert;

  FROM SYSTEM IMPORT
    WORD;

  FROM ScannerI IMPORT
    SetEvalPROC, RefDis, RefAlfa, pilErr;

  FROM CommonTypes IMPORT
    NilValC, NilValI, GlownyOdbiornikT;

  FROM CocpDsp IMPORT
    (* TYPE *) State,
    (* PROCEDURE *) UstawFormat, UstawZmienne, SetIdleMsg;

  FROM SpecConv IMPORT
    SubAngle100;

  FROM L_DataBase IMPORT
    LOC_O_czuloscWP, LOC_O_czuloscCP, LOC_R_czuloscWP, LOC_R_czuloscCP;

  FROM L_Odb IMPORT
    devL, devG, RefDisTT;

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

  VAR
    angCont   : AngVelContiner;
    myRadial  : INTEGER;
    aktOrbita : CARDINAL;
    radial    : BOOLEAN;
    Running   : BOOLEAN;
    currRec   : GlownyOdbiornikT;
    
  PROCEDURE Radial;
  VAR
    pilErrDis   : INTEGER;

  BEGIN (* Radial *)
    IF devL[currRec] <> NilValI  THEN
      pilErr := devL[currRec] - myRadial;
      IF pilErr > 0  THEN
        pilErrDis := (pilErr+5) DIV 10;
      ELSE
        pilErrDis := (pilErr-5) DIV 10;
      END;
    ELSE
      pilErr := NilValI;
      pilErrDis := NilValI;
    END;
    UstawZmienne(ABS(RefDisTT), pilErrDis, pilErr, devG[currRec]);
  END Radial;

  PROCEDURE ClearAngVelContiner
            ( VAR val : AngVelContiner;
                  ang : INTEGER        );
  VAR
    froIdx : CARDINAL;

  BEGIN
    WITH val DO
      idx := 0;
      watchDog := 0;
      prevDirection := angAsPrevious;
      FOR froIdx := 0 TO AngVelMaxIdx - 1 DO
        data[froIdx] := ang;
      END (* for froIdx *);
    END (* with val *);
  END ClearAngVelContiner;

  PROCEDURE Orbit;
  VAR
    dis      : INTEGER;
    currDir  : AngDirection;
    perrR    : REAL;
    dirKnown : BOOLEAN;

    PROCEDURE OrbitDirection
              (     ang      : INTEGER;
                VAR val      : AngVelContiner;
                VAR dirKnown : BOOLEAN        ) : AngDirection;

      PROCEDURE succ
                ( VAR idx : CARDINAL );

      BEGIN
        idx := (idx + 1) MOD AngVelMaxIdx;
      END succ;

      PROCEDURE checkDir
                (    far  : INTEGER;
                     near : INTEGER ) : AngDirection;
      VAR
        ang : INTEGER;

      BEGIN (* checkDir *)
        IF (far = NilValI) OR (near = NilValI)
        THEN
          RETURN angDirUnknown;
        END (* if *);
        ang := SubAngle100(near, far);
        IF ang > AngVelMinVAl
        THEN
          RETURN CWdir;
        ELSIF ang < -AngVelMinVAl
        THEN
          RETURN CCWdir;
        ELSE
          RETURN angDirUnknown;
        END (* if dist *);
      END checkDir;

    BEGIN (* OrbitDirection *)
      WITH val DO
        IF ang <> NilValI
        THEN
          succ(idx);
          data[idx] := ang;
          IF watchDog = 0
          THEN
            ClearAngVelContiner(angCont, ang);
            watchDog := 20;
          END (* if watchDog *);
        ELSIF watchDog = 0
        THEN
          succ(idx);
          data[idx] := NilValI
        ELSE
          DEC(watchDog);
          data[(idx + 1) MOD AngVelMaxIdx] := data[idx];
          succ(idx);
        END (* if *);
        currDir := checkDir(data[(idx + 1) MOD AngVelMaxIdx], data[idx]);
        dirKnown := currDir <> angDirUnknown;
        IF currDir = angAsPrevious
        THEN
          RETURN angAsPrevious;
        ELSE
          prevDirection := currDir;
          RETURN currDir;
        END (* if currDir *);
      END (* with val *);
    END OrbitDirection;

  BEGIN (* Orbit *)
    CASE OrbitDirection(RefAlfa, angCont, dirKnown) OF
      CWdir :
        UstawFormat(LOCOdlegloscRgh, LOC_O_czuloscWP, LOC_O_czuloscCP);
      |
      CCWdir :
        UstawFormat(LOCOdlegloscLft, LOC_O_czuloscWP, LOC_O_czuloscCP);
      |
      angDirUnknown :
        UstawZmienne(dis, ( ABS(RefAlfa) + 5) DIV 10, NilValI, NilValI);
      |
      angAsPrevious :
      (* do nothing *)
        ;
    END (* case RadialDirection *);
    IF RefDis = NilValC
    THEN
      pilErr := NilValI;
      dis := NilValI;
    ELSE
      dis := ( RefDis + 25 ) DIV 50;
      perrR := FLOAT(RefDis) - FLOAT(aktOrbita);
      IF NOT dirKnown OR (ABS(perrR) > FLOAT(MAX(INTEGER) - 2))
      THEN
        pilErr := NilValI;
      ELSE
        pilErr := entier(perrR);
      END (* if perrR *);
    END (* if RefDis *);
    UstawZmienne(dis, (ABS(RefAlfa)+5) DIV 10, pilErr, NilValI);
  END Orbit;

  PROCEDURE StartCPLoop
            (    proc  : Trajektoria;
                 param : WORD;
                 rec   : GlownyOdbiornikT );

  BEGIN
    Assert(NOT Running);
    currRec := rec;
    IF proc = Kolko
    THEN
      radial := FALSE;
      aktOrbita := CARDINAL(param);
      ClearAngVelContiner(angCont, NilValI);
      UstawFormat(LOCOdlegloscRgh, LOC_O_czuloscWP, LOC_O_czuloscCP);
      SetIdleMsg(197);
      SetEvalPROC(Orbit, TRUE);
    ELSE
      radial := TRUE;
      myRadial := INTEGER(param);
      IF myRadial = 0
      THEN
        UstawFormat(LOCPrad, LOC_R_czuloscWP, LOC_R_czuloscCP);
      ELSE
        UstawFormat(LOCPradOffset, LOC_R_czuloscWP, LOC_R_czuloscCP);
      END (* if myRadial *);
      SetIdleMsg(197);
      SetEvalPROC(Radial, TRUE);
    END (* if proc *);
    Running := TRUE;
  END StartCPLoop;

  PROCEDURE StopCPLoop;

  BEGIN
    pilErr := NilValI;
    Assert(Running);
    IF radial
    THEN
      SetEvalPROC(Radial, FALSE);
    ELSE
      SetEvalPROC(Orbit, FALSE);
    END (* if radial *);
    UstawFormat(Idle, NilValC, NilValC);
    Running := FALSE;
  END StopCPLoop;

BEGIN
  pilErr := NilValI;
  aktOrbita := 0;
  Running := FALSE;
  myRadial := 0;
  radial := FALSE;
END L_CP_ControlProc.
