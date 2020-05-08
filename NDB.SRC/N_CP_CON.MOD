(*.F- *)
(**********************************************************************
|  Title   : Sterowanie wskaznikami nawigacyjnymi
|  Author  : M.Postol na podstawie V_CP_ControlProc
|  System  : LOGITECH MODULA-2/86
|  History :
|    11-12-96: created
|
|  Copyright (C), CAS LODZ POLAND.
|  TEL: 42' 862 547, 42' 87 80 44 FAX/TEL: 42' 84 48 40
|
**********************************************************************)
(*.F+ *)

IMPLEMENTATION MODULE N_CP_ControlProc;

  FROM MathLib0 IMPORT
    entier;

  FROM MANAGER IMPORT
    Assert;

  FROM SYSTEM IMPORT
    WORD;

  FROM ScannerI IMPORT
    SetEvalPROC, RefDis, RefAlfa, pilErr;

  FROM CommonTypes IMPORT
    NilValC, NilValI;

  FROM N_CommonTypes IMPORT
    ProceduraT;

  FROM CocpDsp IMPORT
    (* TYPE *) State,
    (* PROCEDURE *) UstawFormat, UstawZmienne, SetIdleMsg;

  FROM SpecConv IMPORT
    SubAngle100;

  FROM N_DataBase IMPORT
    NDB_O_czuloscWP, NDB_O_czuloscCP, NDB_R_czuloscWP, NDB_R_czuloscCP;

  CONST
    LinVelMaxIdx   = 100;
    LinVelMinVAl   = 100.0;
    AngVelMaxIdx   = 95;
    AngVelMinVAl   = 27;

  TYPE
    AngDirection   =
      ( CWdir,
        CCWdir,
        angDirUnknown,
        angAsPrevious );
    Direction      =
      ( dirTO,
        dirFROM,
        dirUnknown,
        asPrevious );
    LinVelContiner =
      RECORD
        data          :
          ARRAY [0 .. LinVelMaxIdx - 1] OF CARDINAL;
        idx           :
          CARDINAL;
        watchDog      :
          CARDINAL;
        prevDirection :
          Direction;
      END;
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
    disCont   : LinVelContiner;
    angCont   : AngVelContiner;
    myRadial  : INTEGER;
    aktOrbita : CARDINAL;
    radial    : BOOLEAN;
    Running   : BOOLEAN;

  PROCEDURE ClearLinVelContiner
            ( VAR val  : LinVelContiner;
                  dist : CARDINAL       );
  VAR
    froIdx : CARDINAL;

  BEGIN
    WITH val DO
      idx := 0;
      watchDog := 0;
      prevDirection := asPrevious;
      FOR froIdx := 0 TO LinVelMaxIdx - 1 DO
        data[froIdx] := dist;
      END (* for froIdx *);
    END (* with val *);
  END ClearLinVelContiner;

  PROCEDURE Radial;
  VAR
    alfa    : INTEGER;
    currDir : Direction;
    dist    : INTEGER;
    dirKnown  : BOOLEAN;

    PROCEDURE RadialDirection
              (     dist     : CARDINAL;
                VAR val      : LinVelContiner;
                VAR dirKnown : BOOLEAN ) : Direction;

      PROCEDURE succ
                ( VAR idx : CARDINAL );

      BEGIN
        idx := (idx + 1) MOD LinVelMaxIdx;
      END succ;

      PROCEDURE checkDir
                (    far  : CARDINAL;
                     near : CARDINAL ) : Direction;
      VAR
        dist : REAL;

      BEGIN (* checkDir *)
        IF (far = NilValC) OR (near = NilValC)
        THEN
          RETURN dirUnknown;
        END (* if *);
        dist := FLOAT(far) - FLOAT(near);
        IF dist > LinVelMinVAl
        THEN
          RETURN dirTO;
        ELSIF dist < -LinVelMinVAl
        THEN
          RETURN dirFROM;
        ELSE
          RETURN dirUnknown;
        END (* if dist *);
      END checkDir;

    BEGIN (* RadialDirection *)
      WITH val DO
        IF dist <> NilValC
        THEN
          succ(idx);
          data[idx] := dist;
          IF watchDog = 0
          THEN
            ClearLinVelContiner(disCont, dist);
            watchDog := 20;
          END (* if watchDog *);
        ELSIF watchDog = 0
        THEN
          succ(idx);
          data[idx] := NilValC
        ELSE
          DEC(watchDog);
          data[(idx + 1) MOD LinVelMaxIdx] := data[idx];
          succ(idx);
        END (* if *);
        currDir := checkDir(data[(idx + 1) MOD LinVelMaxIdx], data[idx]);
        dirKnown := currDir <> dirUnknown;
        IF currDir = prevDirection
        THEN
          RETURN asPrevious;
        ELSE
          prevDirection := currDir;
          RETURN currDir;
        END (* if currDir *);
      END (* with val *);
    END RadialDirection;

  BEGIN (* Radial *)
    CASE RadialDirection(RefDis, disCont, dirKnown) OF
      dirTO :
        UstawFormat(VORKatTO, NDB_R_czuloscWP, NDB_R_czuloscCP);
      |
      dirFROM :
        UstawFormat(VORKatFROM, NDB_R_czuloscWP, NDB_R_czuloscCP);
      |
      dirUnknown :
        UstawZmienne(dist, alfa, NilValI, NilValI)
      |
      asPrevious :
      (* do nothing *)
        ;
    END (* case RadialDirection *);
    IF RefAlfa = NilValI
    THEN
      pilErr := NilValI;
      alfa := NilValI;
    ELSE
      IF RefAlfa > 0  THEN
        alfa := (RefAlfa + 5) DIV 10;
      ELSE
        alfa := (RefAlfa - 5) DIV 10 + 3600
      END;
      IF dirKnown THEN
        pilErr := SubAngle100(RefAlfa, myRadial);
        IF pilErr < -9000
        THEN
          pilErr := pilErr + 18000;
        ELSIF pilErr > 9000
        THEN
          pilErr := pilErr - 18000;
        END (* if perr *);
      ELSE
        pilErr := NilValI;
      END;
    END (* if RefAlfa *);
    IF RefDis = NilValC
    THEN
      dist := NilValI;
    ELSE
      dist := RefDis DIV 50;
    END (* if RefDis *);
    UstawZmienne(dist, alfa, pilErr, NilValI)
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
    alfa     : INTEGER;
    dis      : INTEGER;
    currDir  : AngDirection;
    perrR    : REAL;
    dirKnown : BOOLEAN;

    PROCEDURE OrbitDirection
              (     ang      : INTEGER;
                VAR val      : AngVelContiner;
                VAR dirKnown : BOOLEAN) : AngDirection;

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
        UstawFormat(VOROdlegloscRgh, NDB_O_czuloscWP, NDB_O_czuloscCP);
      |
      CCWdir :
        UstawFormat(VOROdlegloscLft, NDB_O_czuloscWP, NDB_O_czuloscCP);
      |
      angDirUnknown :
        UstawZmienne(dis, alfa, NilValI, NilValI);
      |
      angAsPrevious :
      (* do nothing *)
        ;
    END (* case RadialDirection *);
    IF RefAlfa = NilValI
    THEN
      alfa := NilValI;
    ELSE
      IF RefAlfa > 0  THEN
        alfa := (RefAlfa + 5) DIV 10;
      ELSE
        alfa := (RefAlfa - 5) DIV 10 + 3600
      END;
    END (* if RefAlfa *);
    IF RefDis = NilValC
    THEN
      pilErr := NilValI;
      dis := NilValI;
    ELSE
      dis := RefDis DIV 50;
      perrR := FLOAT(RefDis) - FLOAT(aktOrbita);
      IF NOT dirKnown OR
         ( ABS(perrR) > FLOAT(MAX(INTEGER) - 2) )
      THEN
        pilErr := NilValI;
      ELSE
        pilErr := entier( perrR );
      END (* if perrR *);
    END (* if RefDis *);
    UstawZmienne(dis, alfa, pilErr, NilValI);
  END Orbit;

  PROCEDURE StartCPLoop
            (    proc  : ProceduraT;
                 param : WORD       );

  BEGIN
    Assert(NOT Running);
    IF proc = pOrbita THEN
      radial := FALSE;
      aktOrbita := CARDINAL(param);
      ClearAngVelContiner(angCont, NilValI);
      UstawFormat(VOROdlegloscRgh, NDB_O_czuloscWP, NDB_O_czuloscCP);
      SetIdleMsg(197);
      SetEvalPROC(Orbit, TRUE);
    ELSE
      radial := TRUE;
      myRadial := INTEGER(param);
      ClearLinVelContiner(disCont, NilValC);
      UstawFormat(VORKatFROM, NDB_R_czuloscWP, NDB_R_czuloscCP);
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
      SetEvalPROC( Radial, FALSE );
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
  ClearLinVelContiner(disCont, NilValC);
  ClearAngVelContiner(angCont, NilValI);
  myRadial := 0;
  radial := FALSE;
END N_CP_ControlProc.
