(*.F- *)
(**********************************************************************
|  Title   : Wyznaczanie danych w  ScannerI
|  Author  : M.Morawski
|  System  : LOGITECH MODULA-2/86 
|  History :
|    12-05-97: M.Postol
|      Zle wyznaczany kat GPS_A
|    Rel 3.0. : M.Postol
|      dostosowalem do nowej definicji ScannerI
|
|  Copyright (C), CAS LODZ POLAND.
|  TEL: 42' 686 25 47
|  mailto: techsupp@cas.com.pl
|  http: www.cas.com.pl
|
**********************************************************************)
(*.F+ *)
IMPLEMENTATION MODULE SimScanner;

FROM ScannerI IMPORT
  RefAlfa, RefDis, Alfa, AlfaF, Delta, GPS_OK, GPS_R, GPS_A, TEO_OK, DeltaF,
  TEO_E, TEO_A, GPS_GDOP, flg, LocationsTogether, 
  TeoStates, TeoState, StanyGPS, StanGPS, GPS_DIFFMODE;
FROM CommonTypes IMPORT
  OdnDlaPomBleduT, OdnDlaPomOdlT, NilValI, NilValC, GPS_flg, 
  GlownyOdbiornikT, GPSDiff_flg;
FROM MathLib0 IMPORT
  real;
FROM EventsMng IMPORT
  Events, LoadDistEvents, EventsIdxTyp;
FROM DataCollect IMPORT
  SampleNr;
FROM RTSMain IMPORT
  Terminate, Warning;
FROM Strings IMPORT
  Assign, Length;
FROM FIO IMPORT
  GetDir, CD;
FROM CommonData IMPORT
  OdnDlaPomBledu, OdnDlaPomOdl, SciezkaOpisuPomiaru;
FROM SpecConv IMPORT
  AddAngle100;
   
VAR
  CalkowitaLiczbaEventow : ARRAY BOOLEAN OF CARDINAL;



PROCEDURE Simulate( AzymANieElew : BOOLEAN;
                    Pomiar       : BOOLEAN;
                    Offset       : INTEGER );
  BEGIN
    IF LocationsTogether() THEN
      RefAlfa := Alfa.Together[OdnDlaPomBledu];
      RefDis  := Delta[OdnDlaPomOdl];
      DeltaF[poGPS]  := Delta[poGPS];
      IF (Alfa.Together[pbGPS] # NilValI) &
         (Delta[poGPS] # NilValC) &
         NOT (GPS_flg IN flg )
      THEN
        GPS_A := real( AddAngle100( Alfa.Together[pbGPS], Offset ) ) / 100.0;
        GPS_R := FLOAT( Delta[poGPS] ) / 500.0;
        GPS_OK := StanGPS{ };
      ELSE
        GPS_OK := StanGPS{ Flaga };
      END;
    ELSE
      RefAlfa := Alfa.Spread[goA];
      RefDis  := Delta[poGPS];
      DeltaF[poGPS]  := Delta[poGPS];
      IF (Alfa.Spread[goA] # NilValI) &
         (Delta[poGPS] # NilValC) &
         NOT (GPS_flg IN flg )
      THEN
        GPS_A := real( Alfa.Spread[goA] ) / 100.0;
        GPS_R := FLOAT( Delta[poGPS] ) / 500.0;
        GPS_OK := StanGPS{ };
      ELSE
        GPS_OK := StanGPS{ Flaga };
      END;
    END;
    IF LocationsTogether() THEN
      IF ( Alfa.Together[pbTeodolit] # NilValI ) THEN
        IF AzymANieElew  THEN
          TEO_A := real( Alfa.Together[pbTeodolit] ) / 100.0;
        ELSE
          TEO_E := real( Alfa.Together[pbTeodolit] ) / 100.0;
        END;
        TEO_OK := TeoStates{ tNoweDane };
      ELSE
        TEO_OK := TeoStates{ tFlaga };
      END;
    ELSE
      TEO_OK := TeoStates{ tFlaga};
    END;
    AlfaF    := Alfa;
    GPS_DIFFMODE := GPSDiff_flg IN flg;
    (* a teraz eventy *)
    WITH Events[Pomiar] DO
      IF events[EventIDX].atSample <= SampleNr( Pomiar ) THEN
        INC( EventIDX );
      END;
    END;
  END Simulate;

  PROCEDURE LoadEvents( Pomiar : BOOLEAN );
    VAR
      CurDir,
      Dir    : ARRAY[0..99] OF CHAR;
    BEGIN
      GetDir( CurDir );
      Assign( SciezkaOpisuPomiaru, Dir );
      Dir[ Length( Dir )-1 ] := 0C;
      IF NOT CD( Dir ) THEN
        Terminate( Warning ); (* jakas grubsza sprawa *)
      END;
      IF NOT LoadDistEvents( Events[Pomiar], Pomiar ) THEN
        Events[Pomiar].EventIDX := 0;
(*        Terminate( Warning );*)
      END;
      IF NOT CD( CurDir ) THEN
        Terminate( Warning ); (* jakas grubsza sprawa *)
      END;
      CalkowitaLiczbaEventow[Pomiar] := Events[Pomiar].EventIDX;
      Events[Pomiar].events[Events[Pomiar].EventIDX].atSample := 0FFFFH; (* zeby nie wyszlo za zakres *)
      Events[Pomiar].EventIDX := 0;
    END LoadEvents;

  PROCEDURE OdtworzEventy( Pomiar : BOOLEAN );
    BEGIN
      Events[Pomiar].EventIDX := CalkowitaLiczbaEventow[Pomiar];
    END OdtworzEventy;

END SimScanner.
