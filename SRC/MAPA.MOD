(*.F- *)
(**********************************************************************
|  Title   : Sterowanie mapka sytuacyjna
|  Author  : D.Arendt, M.Postol
|  System  : LOGITECH MODULA-2/86
|  History :
|    12-12-96: M.Postol
|      uwzglednilem zmainy w def GPSRead
|    12-05-97: M.Postol
|      dane z GPS sa czytane ze zmiennych filtrowanych, i nie ma analizy 
|      flag GPS
|
|  Copyright (C), CAS LODZ POLAND.
|  TEL: 42' 862 547, 42' 87 80 44 FAX/TEL: 42' 84 48 40
|
**********************************************************************)
(*.F+ *)

IMPLEMENTATION MODULE Mapa;

  IMPORT
    GPSRead, ScannerI, NumberConversion, MANAGER, Polozenie;

  FROM Polozenie IMPORT
    Start_Polozenie, Stop_Polozenie, UpdateM;

  FROM HiLevGraf IMPORT
    FillRect, Circle, WrStrXY;

  FROM GrafTypes IMPORT
    POINT, RECT, BLACK, WHITE, BLUE, YELLOW, BROWN;

  FROM Timer IMPORT
    Wait, TInOneSecond;

  FROM MathLib0 IMPORT
    entier, real;

  FROM CommonTypes  IMPORT
    NilValC, DisNilVal, SigNilVal, OdnDlaPomOdlT, OdnDlaPomBleduT, 
    GlownyOdbiornikT;

  FROM ScannerI IMPORT
    DeltaF, AlfaF, LocationsTogether;
    
  TYPE
    situation =
      ( normal,
        changes,
        nodata );

  CONST
    Radius      = 70;  (* promien kola *)
    margTB        = 11;
    margLR        = 20;
    DistBackCol = YELLOW;
    MaxLiczProm = 15;

  VAR
    doZrobienia        : ARRAY [0..MaxLiczProm] OF CARDINAL;
    zrobione           : ARRAY [0..MaxLiczProm] OF CARDINAL;
    aktualny           : CARDINAL;
    mapRct             : RECT;
    distRect           : RECT;
    PokazywacPolozenie : BOOLEAN;
    RysSytMaxDis       : REAL;
    myPoint            : POINT;
    redraw             : BOOLEAN;

  PROCEDURE RedefineMaxDist
            (    center       : POINT;
                 Radius       : CARDINAL;
                 RysSytMaxDis : REAL     );
  VAR
    str : ARRAY [0 .. 2] OF CHAR;

  BEGIN
    IF RysSytMaxDis > 0.0
    THEN
      Stop_Polozenie;
      Start_Polozenie(center, Radius, RysSytMaxDis);
      NumberConversion.CardToString(entier(RysSytMaxDis+0.5), str, 3);
      WrStrXY(str, 799-margLR-10, 599-margLR, BLACK, DistBackCol);
    ELSE
      FillRect(distRect, CHR(DistBackCol));
    END (* if RysSytMaxDis *);
  END RedefineMaxDist;

  PROCEDURE resolveSituation
            ( VAR RysSytMaxDis : REAL;
              VAR GPS_A        : REAL;
              VAR GPS_R        : REAL ) : situation;
  VAR
    Zmiany : BOOLEAN;

    PROCEDURE GetGPS
              ( VAR GPS_A  : REAL;
                VAR GPS_R  : REAL ) : BOOLEAN;
    BEGIN
      IF LocationsTogether() AND (AlfaF.Together[ pbGPS ] <> SigNilVal)  
      THEN
        GPS_A := real( AlfaF.Together[pbGPS] ) / 100.0;
      ELSIF NOT LocationsTogether() AND (AlfaF.Spread[goA] <> SigNilVal)
      THEN
        GPS_A := real( AlfaF.Spread[goA] ) / 100.0;
      ELSE
        RETURN FALSE
      END;
      IF DeltaF[ poGPS ] <> DisNilVal THEN
        GPS_R := FLOAT( DeltaF[ poGPS ] ) / 500.0;
      ELSE
        RETURN FALSE;
      END;
      RETURN TRUE;
    END GetGPS;

    PROCEDURE CountMaxDist
              (     prevMaxDistance : REAL;
                    currDist        : REAL;
                VAR Zmiany          : BOOLEAN ) : REAL;

    BEGIN
      IF (currDist >= prevMaxDistance * 1.1) OR
         (currDist < prevMaxDistance * 0.4)
      THEN
        WHILE currDist >= prevMaxDistance DO
          prevMaxDistance := prevMaxDistance + 10.0;
        END (* while *);
        WHILE prevMaxDistance > currDist + 11.0 DO
          prevMaxDistance := prevMaxDistance - 10.0;
        END (* while prevMaxDistance *);
        Zmiany := TRUE;
      ELSE
        Zmiany := FALSE;
      END (* if *);
      RETURN prevMaxDistance;
    END CountMaxDist;

  BEGIN (* resolveSituation *)
    IF GetGPS(GPS_A, GPS_R)
    THEN
      RysSytMaxDis := CountMaxDist(RysSytMaxDis, GPS_R, Zmiany);
      IF Zmiany
      THEN
        RETURN changes
      ELSE
        RETURN normal
      END (* if Zmiany *);
    ELSE
      RysSytMaxDis := -10.0;
      RETURN nodata;
    END (* if GPS_OK *);
  END resolveSituation;

  PROCEDURE MakeMAP
            (    color : CARDINAL );
  VAR
    rect     : RECT;
    GPS_A    : REAL;
    GPS_R    : REAL;
    GPS_OK   : BITSET;
    dtaSign  : GPSRead.DtaSignType;
  BEGIN (* MakeMAP *)
    Stop_Polozenie;
    FillRect(mapRct, CHR(color));
    FillRect(distRect, CHR(DistBackCol));
    Circle(myPoint.x, myPoint.y, Radius, BLACK);
    Polozenie.Promienie(doZrobienia, zrobione, aktualny);
    CASE resolveSituation(RysSytMaxDis, GPS_A, GPS_R) OF
      normal, changes :
        RedefineMaxDist(myPoint, Radius, RysSytMaxDis);
        UpdateM(GPS_R, GPS_A, GPSRead.GetDirection(dtaSign));
      |
      nodata :
      ;
    END (* case resolveSituation *);
  END MakeMAP;

  PROCEDURE PokazKatyLotu
            (    regen   : BOOLEAN );
  VAR
    Nilarr   : ARRAY [0 .. 0] OF CARDINAL;
    GPS_A    : REAL;
    GPS_R    : REAL;
    GPS_OK   : BITSET;
    dtaSign  : GPSRead.DtaSignType;

  BEGIN
    IF NOT regen
    THEN
      CASE resolveSituation(RysSytMaxDis, GPS_A, GPS_R) OF
        normal :
          UpdateM(GPS_R, GPS_A, GPSRead.GetDirection(dtaSign));
        |
        changes :
          RedefineMaxDist(myPoint, Radius, RysSytMaxDis);;
          UpdateM(GPS_R, GPS_A, GPSRead.GetDirection(dtaSign));
        |
        nodata :
          FillRect(distRect, CHR(DistBackCol));
          Stop_Polozenie;
          GPS_R := -1.0;
      END (* case resolveSituation *);
    ELSE
      MakeMAP(WHITE);
    END (* if relDis *);
  END PokazKatyLotu;

  PROCEDURE Promienie
            (  DoZrobienia : ARRAY OF CARDINAL;
               Zrobione    : ARRAY OF CARDINAL;
               Aktualny    : CARDINAL          );
  VAR
    idx: CARDINAL;

  PROCEDURE  Min(a, b: CARDINAL): CARDINAL;
  BEGIN
    IF a <= b  THEN
      RETURN a;
    ELSE
      RETURN b;
    END;
  END Min;
  
  BEGIN
    redraw := TRUE;
    FOR idx := 0 TO Min(HIGH(DoZrobienia), MaxLiczProm) DO
      zrobione[idx] := Zrobione[idx];
    END (* for i *);
    FOR idx := 0 TO Min(HIGH(DoZrobienia), MaxLiczProm) DO
      doZrobienia[idx] := DoZrobienia[idx];
    END (* for i *);
    aktualny := Aktualny;
  END Promienie;
  
  PROCEDURE GdzieJest;
  VAR
    GPS_A    : REAL;
    GPS_R    : REAL;
    GPS_OK   : BITSET;
    dtaSign  : GPSRead.DtaSignType;

  BEGIN (* GdzieJest *)
    WHILE PokazywacPolozenie DO
      IF redraw THEN
        redraw := FALSE;
        MakeMAP(BROWN);
      END;
      CASE resolveSituation(RysSytMaxDis, GPS_A, GPS_R) OF
        normal :
          UpdateM(GPS_R, GPS_A, GPSRead.GetDirection(dtaSign));
        |
        changes :
          RedefineMaxDist(myPoint, Radius, RysSytMaxDis);
          UpdateM(GPS_R, GPS_A, GPSRead.GetDirection(dtaSign));
        |
        nodata :
          FillRect(distRect, CHR(DistBackCol));
          Stop_Polozenie;
          GPS_R := -1.0;
      END (* case resolveSituation *);
      Wait(TInOneSecond());
    END (* while PokazywacPolozenie *);
    Stop;
  END GdzieJest;

  MODULE monitor [ 0 ];

    FROM MANAGER IMPORT
      STARTPROCESS, Condition, WAITC, InitC, Notify;

    IMPORT
      MakeMAP, BLUE, BROWN, PokazywacPolozenie, GdzieJest, Stop_Polozenie, 
      redraw;

    EXPORT
      Stop, StartProcess, CancelProcess;

    VAR
      noActive : Condition;

    PROCEDURE Stop;

    BEGIN
      Stop_Polozenie;
      Notify(noActive);
    END Stop;

    PROCEDURE StartProcess;

    BEGIN
      redraw := TRUE;
      PokazywacPolozenie := TRUE;
      STARTPROCESS(GdzieJest, 600H, 0);
    END StartProcess;

    PROCEDURE CancelProcess;

    BEGIN
      PokazywacPolozenie := FALSE;
      WAITC(noActive);
    END CancelProcess;

  BEGIN
    InitC(noActive);
  END monitor;
  
  PROCEDURE  FillPromieie;
  VAR
    idx : CARDINAL;
  BEGIN
    FOR idx := 0 TO MaxLiczProm DO
      zrobione[idx] := NilValC;
      doZrobienia[idx] := NilValC;
    END (* for i *);
    aktualny := NilValC;
  END FillPromieie;
  
BEGIN
  redraw := FALSE;
  FillPromieie;
  WITH mapRct DO
    left := 799 - 2 * Radius - 2 * margLR;
    top := 599 - 2 * Radius - 2 * margTB;
    right := 799;
    bottom := 599;
  END;
  distRect := mapRct;
  WITH distRect DO
    left := 799 -  3*margLR DIV 2;
    top  :=  599 -  3*margLR DIV 2;
  END;
  myPoint.x := 799 - Radius - margLR;   (* srodek kola *)
  myPoint.y := 599 - Radius - margTB;
  PokazywacPolozenie := FALSE;
  RysSytMaxDis := 40.0;
  Start_Polozenie(myPoint, Radius, RysSytMaxDis);
  Stop_Polozenie;
END Mapa.
