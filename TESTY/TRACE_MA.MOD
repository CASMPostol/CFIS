(*.F- *)
(**********************************************************************
|  Title   : Sterowanie mapka sytuacyjna
|  Author  : D.Arendt, M.Postol
|  System  : LOGITECH MODULA-2/86
|  History :
|    12-12-96: M.Postol
|      uwzglednilem zmainy w def GPSRead
|
|  Copyright (C), CAS LODZ POLAND.
|  TEL: 42' 862 547, 42' 87 80 44 FAX/TEL: 42' 84 48 40
|
**********************************************************************)
(*.F+ *)

MODULE Trace_Map;

  IMPORT
    DebugPMD, GPSRead, ScannerI, NumberConversion, MANAGER, Polozenie;

  FROM Polozenie IMPORT
    Start_Polozenie, Stop_Polozenie, UpdateM;

  FROM HiLevGraf IMPORT
    FillRect, Circle, WrStrXY, HDIB, LoadDIB, ShowDIB;

  FROM GrafTypes IMPORT
    POINT, RECT, BLACK, WHITE, BLUE, YELLOW, BROWN;

  FROM Timer IMPORT
    Wait, TInOneSecond;

  FROM MathLib0 IMPORT
    entier;

  FROM CommonTypes  IMPORT
    NilValC;

  FROM Graphics IMPORT
    MaxHor, MaxVer, _Wr16StrXY;

  FROM CommonTypes IMPORT
    (* TYPE *) glownyEvent, SigNilVal, OdnDlaPomBleduT, OdnDlaPomOdlT;

  FROM G_Inspekcja  IMPORT
    InspekcjaEP, InspekcjaEvent;
    
  TYPE
    situation =
      ( normal,
        changes,
        nodata );

  CONST
    Radius            = 70;  (* promien kola *)
    DistBackCol       = YELLOW;
    MaxLiczProm       = 15;
    AzymANieElew      = TRUE;
    LocationsTogether = TRUE;

  VAR
    RysSytMaxDis       : REAL;
    myPoint            : POINT;
    redraw             : BOOLEAN;
    ScreenR            : RECT;

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
      (* NumberConversion.CardToString(entier(RysSytMaxDis+0.5), str, 3);
      WrStrXY(str, 799-margLR-10, 599-margLR, BLACK, DistBackCol);
      *)
    ELSE
      (* FillRect(distRect, CHR(DistBackCol)); *)
    END (* if RysSytMaxDis *);
  END RedefineMaxDist;

  PROCEDURE resolveSituation
            ( VAR RysSytMaxDis : REAL;
              VAR GPS_A        : REAL;
              VAR GPS_R        : REAL;
              VAR GPS_OK       : BITSET ) : situation;
  VAR
    Zmiany : BOOLEAN;

    PROCEDURE GetGPS
              ( VAR GPS_A  : REAL;
                VAR GPS_R  : REAL;
                VAR GPS_OK : BITSET ) : BOOLEAN;

    BEGIN
      GPS_A := ScannerI.GPS_A;
      GPS_R := ScannerI.GPS_R;
      GPS_OK := ScannerI.GPS_OK;
      RETURN GPS_OK - BITSET {ScannerI.NewData} = {};
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
    IF GetGPS(GPS_A, GPS_R, GPS_OK)
    THEN
      (* RysSytMaxDis := CountMaxDist(RysSytMaxDis, GPS_R, Zmiany); *)
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

  PROCEDURE MakeMAP;
  VAR
    rect     : RECT;
    GPS_A    : REAL;
    GPS_R    : REAL;
    GPS_OK   : BITSET;
    dtaSign  : GPSRead.DtaSignType;
    dib      : HDIB;
    pnt      : POINT;
    
  BEGIN (* MakeMAP *)
    pnt.x := 0;
    pnt.y := 0;
    Stop_Polozenie;
    FillRect(ScreenR, WHITE);
    dib := LoadDIB("insp.dib");
    ShowDIB(dib, ScreenR, pnt, TRUE);
    (*
    FillRect(distRect, CHR(DistBackCol));
    Circle(myPoint.x, myPoint.y, Radius, BLACK);
    Polozenie.Promienie(doZrobienia, zrobione, aktualny);
    *)
    CASE resolveSituation(RysSytMaxDis, GPS_A, GPS_R, GPS_OK) OF
      normal, changes :
        RedefineMaxDist(myPoint, Radius, RysSytMaxDis);
        UpdateM(GPS_R, GPS_A, GPSRead.GetDirection(dtaSign));
      |
      nodata :
      ;
    END (* case resolveSituation *);
  END MakeMAP;

  PROCEDURE GdzieJest;
  VAR
    GPS_A              : REAL;
    GPS_R              : REAL;
    GPS_OK             : BITSET;
    dtaSign            : GPSRead.DtaSignType;
    PokazywacPolozenie : BOOLEAN;
    
  BEGIN (* GdzieJest *)
    PokazywacPolozenie := TRUE;
    WHILE PokazywacPolozenie DO
      IF redraw THEN
        redraw := FALSE;
        MakeMAP;
      END;
      CASE resolveSituation(RysSytMaxDis, GPS_A, GPS_R, GPS_OK) OF
        normal :
          UpdateM(GPS_R, GPS_A, GPSRead.GetDirection(dtaSign));
        |
        changes :
          RedefineMaxDist(myPoint, Radius, RysSytMaxDis);
          UpdateM(GPS_R, GPS_A, GPSRead.GetDirection(dtaSign));
        |
        nodata :
          (* FillRect(distRect, CHR(DistBackCol)); *)
          Stop_Polozenie;
          GPS_R := -1.0;
      END (* case resolveSituation *);
      Wait(TInOneSecond());
    END (* while PokazywacPolozenie *);
  END GdzieJest;
  
BEGIN
  WITH ScreenR  DO
    left := 0;
    top := 0;
    right := MaxHor();
    bottom := MaxVer();
  END;
  redraw := TRUE;
  myPoint.x := 436;   (* srodek kola *)
  myPoint.y := 3331;
  RysSytMaxDis := 40.0;
  Start_Polozenie(myPoint, Radius, RysSytMaxDis);
  Stop_Polozenie;
  IF InspekcjaEP() = AkceptIE  THEN
    ScannerI.Start(poZadanaPredkosc, pbnieZdef, 0.0, 0, 0, AzymANieElew,
                   LocationsTogether);
    GdzieJest;
  END;
END Trace_Map.
