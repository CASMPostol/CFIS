(*.F- *)
(**********************************************************************
|  Title   : Wyznaczanie danych w  ScannerI
|  Author  : M.Morawski
|  System  : LOGITECH MODULA-2/86 
|  History :
|    12-05-97: M.Postol
|      Zle wyznaczany kat GPS_A
|
|  Copyright (C), CAS LODZ POLAND.
|  TEL: 42' 86 58 12, 42' 87 80 44 FAX/TEL: 42' 84 48 40
|
**********************************************************************)
(*.F+ *)
IMPLEMENTATION MODULE SimScanner;


FROM ScannerI IMPORT
  RefAlfa, RefDis, Alfa, AlfaF, Delta, GPS_OK, GPS_R, GPS_A, TEO_OK, DeltaF,
  TEO_E, TEO_A, Flag_Set, gDOP, GPS_GDOP, flg, NewData, LocationsTogether;
FROM CommonTypes IMPORT
  OdnDlaPomBleduT, OdnDlaPomOdlT, NilValI, NilValC, GPS_flg, TEO_flg,
  GlownyOdbiornikT;
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
        GPS_OK := { NewData };
      ELSE
        GPS_OK := { Flag_Set };
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
        GPS_OK := { NewData };
      ELSE
        GPS_OK := { Flag_Set };
      END;
    END;
    IF LocationsTogether() THEN
      IF ( Alfa.Together[pbTeodolit] # NilValI ) & NOT ( TEO_flg IN flg ) THEN
        IF AzymANieElew  THEN
          TEO_A := real( Alfa.Together[pbTeodolit] ) / 100.0;
        ELSE
          TEO_E := real( Alfa.Together[pbTeodolit] ) / 100.0;
        END;
        TEO_OK := { NewData };
      ELSE
        TEO_OK := { Flag_Set };
      END;
    ELSE
      TEO_OK := { Flag_Set };
    END;
    AlfaF    := Alfa;
    gDOP     := GPS_GDOP;

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
