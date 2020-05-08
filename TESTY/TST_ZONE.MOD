MODULE TST_Zone;

  FROM CommonTypes  IMPORT
    NilValC, oMkrFlgPosA, mMkrFlgPosA;
    
  FROM L_CommonTypes IMPORT
    zoneBIdx_T, NumStrefy, Boundary_T, category, NumPunktu, IdPunktowArr_T,
    IdentPunktowT, zoneBDisIdx_T;

  FROM ILS_ZoneMngmnt IMPORT
    ZoneConClear, ZoneContainer_T, ZoneAnalyse, Fill_zoneBIdx, LookForZone, 
    TraceZoneCont_T, TraceZoneCont_Clear, TraceZone, Fill_zoneBDisIdx;
  FROM Strings IMPORT
    ConstAssign;
  
  FROM L_DataBase  IMPORT
    OpisLotniska;
  
  PROCEDURE ZoneBDisIdx_Init( VAR  ZoneBDisIdx  : zoneBDisIdx_T);
  VAR
    idx : NumPunktu;
  BEGIN
    FOR idx := MIN(NumPunktu) TO MAX(NumPunktu) DO
       ZoneBDisIdx[idx] := 10000 - 1000*idx;
    END;
    ZoneBDisIdx[MIN(NumStrefy)] := NilValC;
  END ZoneBDisIdx_Init;
  
  PROCEDURE  IdentPunktow_Init
             (VAR IdentPunktow : IdPunktowArr_T);
  BEGIN
    IdentPunktow[0] := ipMarkery;
    IdentPunktow[1] := ipMarkery;
    IdentPunktow[2] := ipGPS;
    IdentPunktow[3] := ipZnacznikiPilota;
    IdentPunktow[4] := ipZnacznikiPilota;
  END IdentPunktow_Init;
  
  
VAR
  Con              : ZoneContainer_T;
  ZoneBDisIdx      : zoneBDisIdx_T;
  currZoneBDisIdx  : zoneBDisIdx_T;
  PointPosDis      : CARDINAL;
  IdentPunktow     : IdPunktowArr_T;
  Dis              : CARDINAL;
  newZone          : NumStrefy;
  posDif           : CARDINAL;
  flags            : BITSET;
  pilEvent         : BOOLEAN;
  zonePos          : zoneBIdx_T;
  pointIdx         : CARDINAL;
  TraceCon         : TraceZoneCont_T;
  prevZone         : NumStrefy;
  currZone         : NumStrefy;
  NazwaLotniska    : ARRAY[0..15] OF CHAR;
  NazwaPliku       : ARRAY[0..15] OF CHAR;
BEGIN
  ConstAssign("Lublinek", NazwaLotniska);
  ConstAssign("lotnlist.ini", NazwaLotniska);
  OpisLotniska(NazwaLotniska, NazwaPliku, TRUE);
  ZoneBDisIdx_Init( ZoneBDisIdx );
  IdentPunktow_Init(IdentPunktow);
  ZoneConClear(Con, ZoneBDisIdx, IdentPunktow);
  Fill_zoneBIdx(zonePos);
  Fill_zoneBDisIdx(currZoneBDisIdx);
  newZone := MIN(NumStrefy);
  flags := {};
  pilEvent     := FALSE;
  pointIdx := 0;
  FOR Dis := 9999 TO 10 BY -1 DO
    IF (Dis <= 9100) AND (Dis >= 8900)  THEN
      flags := {oMkrFlgPosA};
    ELSIF (Dis <= 8300) AND (Dis >= 8100) THEN
      flags := {mMkrFlgPosA};
    ELSE
      flags := {};
    END;
    pilEvent := (Dis = 6000) OR (Dis = 5000);
    IF  ZoneAnalyse( Con, newZone, posDif, PointPosDis, Dis, flags, pilEvent)
    THEN
      zonePos[newZone] := pointIdx-posDif;
      currZoneBDisIdx[newZone] := PointPosDis;
    END;
    INC(pointIdx);
  END;
  prevZone := 0;
  currZone := 0;
  TraceZoneCont_Clear( TraceCon, zonePos);
  pointIdx := 0;
  WHILE TraceZone(TraceCon, currZone, pointIdx)  DO
    IF currZone <> prevZone THEN
      prevZone := currZone
    END;
  END;
END TST_Zone.
