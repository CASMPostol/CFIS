(*.F- *)
(**********************************************************************
|  Title   : Zone management procedures
|  Author  : M.Postol
|  System  : LOGITECH MODULA-2/86
|  History :
|    06-06-96:created
|
|  Copyright (C), CAS LODZ POLAND.
|  TEL: 42' 862 547, 42' 87 80 44 FAX/TEL: 42' 84 48 40
|
**********************************************************************)
(*.F+ *)

IMPLEMENTATION MODULE L_ZoneMngmnt;

  FROM CommonTypes IMPORT
    (* CONST *) NilValC, DisNilVal, oMkrFlgPosA, oMkrFlgPosB, mMkrFlgPosA,
                mMkrFlgPosB,
    (* TYPE *) GlownyOdbiornikT;

  FROM L_CommonTypes IMPORT
    NumStrefy, Boundary_T, category, NumPunktu;

  FROM L_DataBase IMPORT
    Lotnisko;

  PROCEDURE LookFNKP
            ( VAR NextKnownPoint : NumPunktu;
                  zoneBDisIdx    : zoneBIdx_T ) : BOOLEAN;

  BEGIN
    LOOP
      IF NextKnownPoint < MAX(NumPunktu)
      THEN
        INC(NextKnownPoint);
      ELSE
        RETURN FALSE;
      END (* if NextKnownPoint *);
      IF zoneBDisIdx[NextKnownPoint] <> NilValC
      THEN
        RETURN TRUE;
      END (* if zoneBDisIdx *);
    END (* loop *);
  END LookFNKP;

  PROCEDURE TraceZoneCont_Clear
            ( VAR Con         : TraceZoneCont_T;
                  ZoneBIdx    : zoneBIdx_T      );

  BEGIN
    WITH Con DO
      zoneBIdx := ZoneBIdx;
      NextKnownPoint := MIN(NumPunktu);
      IF NOT LookFNKP(NextKnownPoint, zoneBIdx)
      THEN
        NextKnownPoint := NilValC;
      END (* if *);
      comleted := FALSE;
    END (* with Con *);
  END TraceZoneCont_Clear;

  PROCEDURE TraceZone
            ( VAR con       : TraceZoneCont_T;
              VAR currZone  : NumStrefy;
                  currPoint : CARDINAL        ) : BOOLEAN;

  BEGIN (* TraceZone *)
    WITH con DO
      IF comleted
      THEN
        RETURN FALSE;
      END (* if comleted *);
      IF NextKnownPoint = NilValC THEN
        RETURN TRUE
      END;
      IF currPoint >= zoneBIdx[NextKnownPoint]
      THEN
        IF NextKnownPoint <= MAX(NumStrefy)
        THEN
          currZone := NextKnownPoint;
        ELSE
          comleted := TRUE;
          RETURN FALSE
        END (* if NextKnownPoint *);
        IF NOT LookFNKP(NextKnownPoint, zoneBIdx)
        THEN
          NextKnownPoint := NilValC;
        END (* if LookFNKP *);
      END (* if currPoint *);
    END (* with con *);
    RETURN TRUE;
  END TraceZone;

  PROCEDURE LookForZone
            (    Idx      : CARDINAL;
                 zoneBIdx : zoneBIdx_T ) : CARDINAL;
  VAR
    zone  : CARDINAL;
    state : ( checkBaund,
              incZone,
              checkIfIn );

  BEGIN
    zone := 0;
    state := checkBaund;
    LOOP
      CASE state OF
        checkBaund :
          IF (zoneBIdx[zone + 1] = NilValC) OR (zoneBIdx[zone] = NilValC)
          THEN
            state := incZone;
          ELSE
            state := checkIfIn;
          END (* if *);
        |
        incZone :
          IF zone < MAX(NumStrefy)
          THEN
            INC(zone);
            state := checkBaund;
          ELSE
            zone := NilValC;
            EXIT
          END (* if zone *);
        |
        checkIfIn :
          IF (Idx < zoneBIdx[zone + 1]) AND (Idx <= zoneBIdx[zone])
          THEN
            EXIT;
          ELSE
            state := incZone;
          END (* if *);
      END (* case state *);
    END (* loop *);
    RETURN zone;
  END LookForZone;

  PROCEDURE InZone
            (    Idx      : CARDINAL;
                 zoneBIdx : zoneBIdx_T;
                 zone     : CARDINAL   ) : BOOLEAN;

  BEGIN
    IF (zone <> NilValC) OR (zoneBIdx[zone + 1] = NilValC) OR
       (zoneBIdx[zone] = NilValC)
    THEN
      RETURN FALSE
    END (* if *);
    IF (Idx < zoneBIdx[zone + 1]) AND (Idx <= zoneBIdx[zone])
    THEN
      RETURN TRUE;
    ELSE
      RETURN FALSE
    END (* if *);
  END InZone;

  PROCEDURE ZoneConClear
            ( VAR Con          : ZoneContainer_T;
                  ZoneBDisIdx  : zoneBDisIdx_T;
                  IdentPunktow : IdPunktowArr_T;
                  MkrNrIdent   : zoneBIdx_T  );

  BEGIN
    WITH Con DO
      lookForPoit := 1;
      zoneBDisIdx := ZoneBDisIdx;
      identPunktow := IdentPunktow;
      mkrNrIdent := MkrNrIdent;
      completed := FALSE;
      markerSum := 0;
      markerBegDis := DisNilVal;
    END (* with Con *);
  END ZoneConClear;

  PROCEDURE ZoneAnalyse
            ( VAR con         : ZoneContainer_T;
              VAR pointFound  : NumPunktu;
              VAR posDif      : CARDINAL;
              VAR PointPosDis : CARDINAL;
                  Dis         : CARDINAL;
                  flags       : BITSET;
                  pilEvent    : BOOLEAN         ) : BOOLEAN;

  TYPE
    CheckDis_Res_T =
      ( zoneBegin_D,
        newZone_D,
        nothing_D );

    PROCEDURE LookForNextPnt
              (    Idx      : CARDINAL;
                   zoneBIdx : zoneBDisIdx_T ) : CARDINAL;
    VAR
      currPoint : CARDINAL;
      state     : ( incZone,
                    checkIfIn );

    BEGIN
      currPoint := 1;
      state := checkIfIn;
      LOOP
        CASE state OF
          incZone :
            IF currPoint < MAX(NumPunktu) - 1
            THEN
              INC(currPoint);
              state := checkIfIn;
            ELSE
              currPoint := NilValC;
              EXIT
            END (* if currPoint *);
          |
          checkIfIn :
            IF Idx > zoneBIdx[currPoint]
            THEN
              EXIT;
            ELSE
              state := incZone;
            END (* if *);
        END (* case state *);
      END (* loop *);
      RETURN currPoint;
    END LookForNextPnt;

    PROCEDURE CheckIfLost
              (     lookForPoit : NumPunktu;
                VAR lo          : zoneBDisIdx_T ) : BOOLEAN;

      (* !! ta procedura nie ma sensu dla pomiaru wzgledem predkosci - 
         zapewnic w L_oblot, przy predkosci nie ma identyfikacji po 
         odleglosci *)
    BEGIN
      IF lookForPoit < MAX(NumPunktu)
      THEN
        RETURN (lo[lookForPoit + 1] + lo[lookForPoit]) DIV 2 >= Dis
      ELSE
        RETURN lo[lookForPoit] DIV 2 >= Dis 
      END (* if lookForPoit *);
    END CheckIfLost;

    PROCEDURE CheckDis
              (    Dis         : CARDINAL;
                   lookForPoit : NumPunktu;
                   zoneBDisIdx : zoneBDisIdx_T ) : CheckDis_Res_T;

    BEGIN (* CheckDis *)
      IF Dis = DisNilVal
      THEN
        RETURN nothing_D
      END (* if Dis *);
      IF CheckIfLost(lookForPoit, zoneBDisIdx)
      THEN
        RETURN newZone_D;
      ELSIF zoneBDisIdx[lookForPoit] >= Dis
      THEN
        RETURN zoneBegin_D;
      END (* if *);
      RETURN nothing_D;
    END CheckDis;

    PROCEDURE CheckPEv
              (    pilEvent    : BOOLEAN;
                   Dis         : CARDINAL;
                   lookForPoit : NumPunktu;
                   zoneBDisIdx : zoneBDisIdx_T ) : CheckDis_Res_T;

    BEGIN
      IF pilEvent
      THEN
        RETURN zoneBegin_D;
      END (* if pilEvent *);
      IF Dis = DisNilVal
      THEN
        RETURN nothing_D
      END (* if Dis *);
      IF CheckIfLost(lookForPoit, zoneBDisIdx)
      THEN
        RETURN newZone_D;
      END (* if *);
      RETURN nothing_D;
    END CheckPEv;

    PROCEDURE CheckMkr
              (     mkrNrIdent   : CARDINAL;
                    flags        : BITSET;
                    pilEvent     : BOOLEAN;
                    Dis          : CARDINAL;
                    lookForPoit  : NumPunktu;
                    zoneBDisIdx  : zoneBDisIdx_T;
                VAR markerSum    : CARDINAL;
                VAR markerBegDis : CARDINAL;
                VAR posDif       : CARDINAL;
                VAR PointPosDis  : CARDINAL      ) : CheckDis_Res_T;

      PROCEDURE CalculateDist
                (    markerBegDis : CARDINAL;
                     Dis          : CARDINAL ) : CARDINAL;

      BEGIN
        IF (markerBegDis = DisNilVal) OR (Dis = DisNilVal) OR
           (markerBegDis < Dis)
        THEN
          RETURN DisNilVal;
        END (* if *);
        RETURN markerBegDis - (markerBegDis - Dis) DIV 2;
      END CalculateDist;

    BEGIN
      IF mkrNrIdent <> NilValC
      THEN
        IF mkrNrIdent IN flags
        THEN
          IF markerBegDis = DisNilVal
          THEN
            markerBegDis := Dis;
          END (* if markerBegDis *);
          INC(markerSum);
          RETURN nothing_D;
        ELSIF markerSum <> 0
        THEN
          PointPosDis := CalculateDist(markerBegDis, Dis);
          posDif := markerSum DIV 2;
          markerBegDis := DisNilVal;
          markerSum := 0;
          RETURN zoneBegin_D
        END (* if mkrNrIdent *);
      ELSE
        IF pilEvent
        THEN
          RETURN zoneBegin_D;
        END (* if pilEvent *);
      END (* if mkrNrIdent *);
      IF Dis = DisNilVal
      THEN
        RETURN nothing_D
      END (* if Dis *);
      IF CheckIfLost(lookForPoit, zoneBDisIdx)
      THEN
        RETURN newZone_D;
      END (* if *);
      RETURN nothing_D;
    END CheckMkr;

  BEGIN (* ZoneAnalyse *)
    posDif := 0;
    PointPosDis := Dis;
    WITH con DO
      IF completed
      THEN
        RETURN FALSE
      END (* if completed *);
      CASE identPunktow[lookForPoit - 1] OF
        ipGPS :
          CASE CheckDis(Dis, lookForPoit, zoneBDisIdx) OF
            zoneBegin_D :
              pointFound := lookForPoit;
              IF lookForPoit < MAX(NumPunktu)
              THEN
                INC(lookForPoit);
              ELSE
                completed := TRUE;
              END (* if lookForPoit *);
              RETURN TRUE;
            |
            newZone_D :
              lookForPoit := LookForNextPnt(Dis, zoneBDisIdx);
              IF lookForPoit = NilValC
              THEN
                completed := TRUE;
              END (* if lookForPoit *);
              RETURN FALSE;
            |
            nothing_D :
              RETURN FALSE;
          END (* case CheckDis *);
        |
        ipZnacznikiPilota :
          CASE CheckPEv(pilEvent, Dis, lookForPoit, zoneBDisIdx) OF
            zoneBegin_D :
              pointFound := lookForPoit;
              IF lookForPoit < MAX(NumPunktu)
              THEN
                INC(lookForPoit);
              ELSE
                completed := TRUE;
              END (* if lookForPoit *);
              RETURN TRUE;
            |
            newZone_D :
              lookForPoit := LookForNextPnt(Dis, zoneBDisIdx);
              IF lookForPoit = NilValC
              THEN
                completed := TRUE;
              END (* if lookForPoit *);
              RETURN FALSE;
            |
            nothing_D :
              RETURN FALSE;
          END (* case CheckPEv *);
        |
        ipMarkery :
          CASE CheckMkr(mkrNrIdent[lookForPoit], flags, pilEvent, Dis,
                        lookForPoit, zoneBDisIdx, markerSum, markerBegDis,
                        posDif, PointPosDis) OF
            zoneBegin_D :
              pointFound := lookForPoit;
              IF lookForPoit < MAX(NumPunktu)
              THEN
                INC(lookForPoit);
              ELSE
                completed := TRUE;
              END (* if lookForPoit *);
              RETURN TRUE;
            |
            newZone_D :
              lookForPoit := LookForNextPnt(Dis, zoneBDisIdx);
              IF lookForPoit = NilValC
              THEN
                completed := TRUE;
              END (* if lookForPoit *);
            |
            nothing_D :
          END (* case CheckPEv *);
        |
        ipNoOne :
           completed := TRUE;
      END (* case identPunktow *);
    END (* with con *);
    RETURN FALSE;
  END ZoneAnalyse;

  PROCEDURE Fill_zoneBIdx
            ( VAR ZoneBIdx : zoneBIdx_T );
  VAR
    idx : NumPunktu;

  BEGIN
    FOR idx := MIN(NumPunktu) TO MAX(NumPunktu) DO
      ZoneBIdx[idx] := NilValC;
    END (* for idx *);
    ZoneBIdx[MIN(NumStrefy)] := 0;
  END Fill_zoneBIdx;

  PROCEDURE Fill_zoneBDisIdx
            ( VAR ZoneBIdx : zoneBDisIdx_T );
  VAR
    idx : NumPunktu;

  BEGIN
    FOR idx := MIN(NumPunktu) TO MAX(NumPunktu) DO
      ZoneBIdx[idx] := DisNilVal;
    END (* for idx *);
  END Fill_zoneBDisIdx;

  PROCEDURE Fill_IdPunktowArr_T
            ( VAR array : IdPunktowArr_T );
  VAR
    idx : NumStrefy;
  BEGIN
    FOR idx := MIN(NumStrefy) TO MAX(NumStrefy) DO
      array[idx] := ipNoOne;
    END;
  END Fill_IdPunktowArr_T;
  
  PROCEDURE ZoneBDisIdx_Init
            ( VAR ZoneBDisIdx : zoneBDisIdx_T;
              VAR mkrNrIdent  : zoneBIdx_T;
                  rec         : GlownyOdbiornikT );
  VAR
    zoneIdx : NumPunktu;

  BEGIN
    ZoneBDisIdx[0] := NilValC;
    WITH Lotnisko DO
      ZoneBDisIdx[1] := ProgPasa + PolozeniePCh[0];
      ZoneBDisIdx[2] := ProgPasa + PolozeniePCh[1];
      ZoneBDisIdx[3] := ProgPasa + PolozeniePCh[2];
      ZoneBDisIdx[4] := ProgPasa - PolozeniePCh[3];
      ZoneBDisIdx[5] := ProgPasa - PolozeniePCh[4];
      FOR zoneIdx := MIN(NumPunktu) TO MAX(NumPunktu) DO
        mkrNrIdent[zoneIdx] := NilValC;
      END (* for zoneIdx *);
      IF OdlMarkerow[0] <> DisNilVal
      THEN
        CASE rec OF
          goA :
            mkrNrIdent[1] := oMkrFlgPosA;
          |
          goB :
            mkrNrIdent[1] := oMkrFlgPosB;
        END (* case rec *);
      END (* if OdlMarkerow *);
      IF OdlMarkerow[1] <> DisNilVal
      THEN
        CASE rec OF
          goA :
            mkrNrIdent[2] := mMkrFlgPosA;
          |
          goB :
            mkrNrIdent[2] := mMkrFlgPosB;
        END (* case rec *);
      END (* if OdlMarkerow *);
    END (* with Lotnisko *);
  END ZoneBDisIdx_Init;

  PROCEDURE FillBound
            ( VAR boundary : Boundary_T;
                  cat      : category   );

  BEGIN
    boundary[0] := 300.0;
    boundary[1] := 300.0;
    IF cat = 3
    THEN
      boundary[2] := 50.0;
      boundary[3] := 50.0;
      boundary[4] := 50.0;
      boundary[5] := 100.0;
    ELSE
      boundary[2] := 150.0;
      boundary[3] := 150.0;
      boundary[4] := 1000.0;
      boundary[5] := 1000.0;
    END (* if cat *);
  END FillBound;

END L_ZoneMngmnt.
