(*.F- *)
(**********************************************************************
|  Title   : Zone management procedures
|  Author  : M.Postol
|  System  : LOGITECH MODULA-2/86
|  History :
|    06-06-96:created
|    23-02-97: M.Postol
|      w zwiazku ze zmaina sposobu mierzenia odleglosi zmienilem def 
|      ZoneBDisIdx_Init i poczatki stref.
|
|  Copyright (C), CAS LODZ POLAND.
|  TEL: 42' 862 547, 42' 87 80 44 FAX/TEL: 42' 84 48 40
|
**********************************************************************)
(*.F+ *)

IMPLEMENTATION MODULE ILS_ZoneMngmnt;

  FROM CommonTypes IMPORT
    (* CONST *) NilValC, DisNilVal, oMkrFlgPosA, oMkrFlgPosB, mMkrFlgPosA,
                mMkrFlgPosB,
    (* TYPE *) GlownyOdbiornikT, ZoneBoundPt, zoneBIdx_T;

  FROM L_CommonTypes IMPORT
    (* TYPE *) NumStrefy, Boundary_T, category, NumPunktu,
    (* PROCEDURE *) SuccNumPunktu, GetNumStrefy, GetNumStrefyEp;

  FROM L_DataBase IMPORT
    Lotnisko, MkrId_T;

  VAR
    lstPToBeTraced  : ZoneBoundPt;
    lstZone         :  NumStrefy;

  PROCEDURE LookFNKP
            ( VAR NextKnownPoint      : ZoneBoundPt;
                  zoneBDisIdx         : zoneBIdx_T;
                  lastPointToBeTraced : ZoneBoundPt) : BOOLEAN;

  BEGIN
    LOOP
      IF NextKnownPoint < lastPointToBeTraced
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
            ( VAR cCon                 : TraceZoneCont_T;
                  cZoneBIdx            : zoneBIdx_T;
                  cLastPointToBeTraced : ZoneBoundPt      );

  BEGIN
    WITH cCon DO
      zoneBIdx := cZoneBIdx;
      NextKnownPoint := MIN(NumPunktu);
      lastPointToBeTraced := cLastPointToBeTraced;
      IF NOT LookFNKP(NextKnownPoint, zoneBIdx, cLastPointToBeTraced)
      THEN
        NextKnownPoint := np_no;
      END (* if *);
      comleted := FALSE;
    END (* with Con *);
  END TraceZoneCont_Clear;

  PROCEDURE TraceZone
            ( VAR con       : TraceZoneCont_T;
              VAR currZone  : NumStrefy;
                  currPoint : CARDINAL       ) : BOOLEAN;

  BEGIN (* TraceZone *)
    WITH con DO
      IF comleted
      THEN
        RETURN FALSE;
      END (* if comleted *);
      IF NextKnownPoint = np_no THEN
        RETURN TRUE
      END;
      IF currPoint >= zoneBIdx[NextKnownPoint]
      THEN
        IF NextKnownPoint < lastPointToBeTraced
        THEN
          currZone := GetNumStrefy(NextKnownPoint);
        ELSE
          comleted := TRUE;
          RETURN FALSE
        END (* if NextKnownPoint *);
        IF NOT LookFNKP(NextKnownPoint, zoneBIdx, lastPointToBeTraced)
        THEN
          NextKnownPoint := np_no;
        END (* if LookFNKP *);
      END (* if currPoint *);
    END (* with con *);
    RETURN TRUE;
  END TraceZone;

  PROCEDURE ZoneConClear
            ( VAR Con          : ZoneContainer_T;
                  ZoneBDisIdx  : zoneBDisIdx_T;
                  IdentPunktow : IdPunktowArr_T;
                  MkrNrIdent   : zoneBIdx_T  );

  BEGIN
    WITH Con DO
      lookForPoit := MIN(ZoneBoundPt);
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
                   zoneBIdx : zoneBDisIdx_T ) : NumPunktu;
    VAR
      currPoint : NumPunktu;
      state     : ( incZone,
                    checkIfIn );

    BEGIN
      currPoint := MIN(ZoneBoundPt);
      state := checkIfIn;
      LOOP
        CASE state OF
          incZone :
            IF currPoint < lstPToBeTraced
            THEN
              INC(currPoint);
              state := checkIfIn;
            ELSE
              currPoint := np_no;
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
      IF lookForPoit < lstPToBeTraced THEN
        RETURN (lo[SuccNumPunktu(lookForPoit)] + lo[lookForPoit]) DIV 2 >= Dis
      ELSE
        RETURN lo[lookForPoit]  DIV 2 >= Dis 
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
      CASE identPunktow[lookForPoit] OF
        ipGPS :
          CASE CheckDis(Dis, lookForPoit, zoneBDisIdx) OF
            zoneBegin_D :
              pointFound := lookForPoit;
              IF lookForPoit < lstPToBeTraced
              THEN
                INC(lookForPoit);
              ELSE
                completed := TRUE;
              END (* if lookForPoit *);
              RETURN TRUE;
            |
            newZone_D :
              lookForPoit := LookForNextPnt(Dis, zoneBDisIdx);
              IF lookForPoit = np_no
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
              IF lookForPoit < lstPToBeTraced
              THEN
                INC(lookForPoit);
              ELSE
                completed := TRUE;
              END (* if lookForPoit *);
              RETURN TRUE;
            |
            newZone_D :
              lookForPoit := LookForNextPnt(Dis, zoneBDisIdx);
              IF lookForPoit = np_no
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
              IF lookForPoit < lstPToBeTraced
              THEN
                INC(lookForPoit);
              ELSE
                completed := TRUE;
              END (* if lookForPoit *);
              RETURN TRUE;
            |
            newZone_D :
              lookForPoit := LookForNextPnt(Dis, zoneBDisIdx);
              IF lookForPoit = np_no
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
    ZoneBIdx[MIN(NumPunktu)] := 0;
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
    idx : ZoneBoundPt;
  BEGIN
    FOR idx := MIN(ZoneBoundPt) TO MAX(ZoneBoundPt) DO
      array[idx] := ipNoOne;
    END;
  END Fill_IdPunktowArr_T;
  
  PROCEDURE ZoneBDisIdx_Init
            ( VAR ZoneBDisIdx : zoneBDisIdx_T;
              VAR mkrNrIdent  : zoneBIdx_T;
                  rec         : GlownyOdbiornikT;
                  LOCnotGS    : BOOLEAN );
  VAR
    zoneIdx : NumPunktu;
    
  BEGIN (* ZoneBDisIdx_Init *)
    ZoneBDisIdx[np_Start] := NilValC;
    WITH Lotnisko DO
      ZoneBDisIdx[np_A]    := ProgPasa + PolozeniePCh[0];
      ZoneBDisIdx[np_B]    := ProgPasa + PolozeniePCh[1];
      ZoneBDisIdx[np_CorT] := ProgPasa + PolozeniePCh[2];
      IF LOCnotGS  THEN
        ZoneBDisIdx[np_D] := ProgPasa - PolozeniePCh[3];
        ZoneBDisIdx[np_E] := ProgPasa - PolozeniePCh[4];
      ELSE
        ZoneBDisIdx[np_D] := NilValC;
        ZoneBDisIdx[np_E] := NilValC;
      END;
      ZoneBDisIdx[np_no] := NilValC;
      FOR zoneIdx := MIN(NumPunktu) TO MAX(NumPunktu) DO
        mkrNrIdent[zoneIdx] := NilValC;
      END (* for zoneIdx *);
      IF OdlMarkerow[OMkr] <> DisNilVal
      THEN
        CASE rec OF
          goA :
            mkrNrIdent[np_A] := oMkrFlgPosA;
          |
          goB :
            mkrNrIdent[np_A] := oMkrFlgPosB;
        END (* case rec *);
      END (* if OdlMarkerow *);
      IF OdlMarkerow[MMkr] <> DisNilVal
      THEN
        CASE rec OF
          goA :
            mkrNrIdent[np_B] := mMkrFlgPosA;
          |
          goB :
            mkrNrIdent[np_B] := mMkrFlgPosB;
        END (* case rec *);
      END (* if OdlMarkerow *);
    END (* with Lotnisko *);
  END ZoneBDisIdx_Init;
  
  PROCEDURE  L_LstPToBeTraced()  : ZoneBoundPt;
  BEGIN
    RETURN lstPToBeTraced;
  END L_LstPToBeTraced;
  
  PROCEDURE  G_LstPToBeTraced()  : ZoneBoundPt; 
  BEGIN
    RETURN np_CorT;
  END G_LstPToBeTraced;
  
  PROCEDURE L_LstZToBeTraced()  : NumStrefy; 
  (* last zone to be traced for cat *)
  BEGIN
    RETURN lstZone;
  END L_LstZToBeTraced;
  
  PROCEDURE G_LstZToBeTraced()  : NumStrefy; 
  (* last zone to be traced for cat *)
  BEGIN
    RETURN GetNumStrefyEp(np_CorT);
  END G_LstZToBeTraced;
  
  PROCEDURE  SetLastPointToBeTraced
             (   Kategoria : category; 
                 LOCnotGS  : BOOLEAN);
  BEGIN
    IF LOCnotGS AND (Kategoria = 3)  THEN
      lstPToBeTraced := np_E;
    ELSE
      lstPToBeTraced := np_CorT;
    END;
    lstZone := GetNumStrefyEp(lstPToBeTraced);
  END SetLastPointToBeTraced;


BEGIN
  lstPToBeTraced := np_A;
END ILS_ZoneMngmnt.
