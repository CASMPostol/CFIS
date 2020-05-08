(*.F- *)
(**********************************************************************
|  Title   : Przegladanie wejsc analogowych i cyfrowych
|  Author  : D.Arendt
|  System  : LOGITECH MODULA-2/86
|  History :
|   18-02-96: M.Postol
|     procedura Start zostala zmieniona by umozliwic przekazanie
|     parametrow lotu
|   17-03-95: M.Postol
|     duzo roznych zmian - generalne pozadki
|   02-05-96: M.Postol
|     DME wywalilem do D_Odb, tu zostalo tylko czytanie odleglosci
|   15-12-96: M.Postol
|     zmiana def Start ze wzgledu na VOR'a trasowego
|   10-05-97: M.Postol
|     - zdefiniowalem DeltaF, bo ciagle byly problemy z GPS'em
|     - zdefiniowalem procedure CurrGPSAlfaOffset potrzebna dla DME w LOCarch
|     - dostosowalem do nowej definicji
|   15-06-00: M.Postol
|     zmodyfikowale zgodnie ze zmianami w def
|     wywalilem niepotrzebne odwolania
|   Rel 3.0. MPostol
|     Zmiana typu dla GDOP
|
|  Copyright (C), CAS LODZ POLAND.
|  TEL: 42' 686 25 47
|  mailto: techsupp@cas.com.pl
|  http: www.cas.com.pl
|
**********************************************************************)
(*.F+ *)
IMPLEMENTATION MODULE ScannerI [ 0 ];

  FROM CommonTypes IMPORT
    (* TYPE *) OdnDlaPomBleduT, OdnDlaPomOdlT, PolozenieGeo,
    (* CONST *) NilValC, NilValI, SigNilVal;

  FROM MANAGER IMPORT
    Assert;

  IMPORT
    Strings, PI_PA;

  FROM TheodolitRead IMPORT 
    TeoState;
    
  FROM GPSRead IMPORT
    StanyGPS;

  TYPE
    DtaSignType =
      CARDINAL;

  VAR
    currAlfaOff        : INTEGER;
    
  PROCEDURE AssSim_Dis
            (    currSim_Dis_CP : Sim_Dis_PROC );

  BEGIN
  END AssSim_Dis;

  PROCEDURE AssSim_Alfa
            (    currSim_Alfa_CP : Sim_Alfa_PROC );

  BEGIN
  END AssSim_Alfa;

  PROCEDURE NewDataAvailable;
  BEGIN
  END NewDataAvailable;

  VAR
    loc_tog : BOOLEAN;

  PROCEDURE Start
            (    GPSAlfaOffset     : INTEGER;
                 aktAzymANieElew   : BOOLEAN;
                 locationsTogether : BOOLEAN    );
  BEGIN
    currAlfaOff := GPSAlfaOffset;
    loc_tog := locationsTogether;
  END Start;

  PROCEDURE CurrGPSAlfaOffset(): INTEGER;
  BEGIN
    RETURN currAlfaOff;
  END CurrGPSAlfaOffset;
  
  PROCEDURE  LocationsTogether(): BOOLEAN;
  BEGIN
    RETURN loc_tog;
  END LocationsTogether;

  PROCEDURE Stop;
  BEGIN
  END Stop;

  PROCEDURE InitPilotEventId
            ( VAR ident : DtaSignType );

  BEGIN
  END InitPilotEventId;

  PROCEDURE GetPilotEvent
            ( VAR ident : DtaSignType ) : BOOLEAN;
  BEGIN
    RETURN FALSE;
  END GetPilotEvent;

  PROCEDURE SetEvalPROC
            (    P   : PROC;
                 add : BOOLEAN );
  BEGIN
  END SetEvalPROC;

BEGIN
  currAlfaOff := 0;
  flg      := {};
  Alfa.Together[pbTeodolit]:= NilValI;
  Alfa.Together[pbGPS]:= NilValI;
  AlfaF    := Alfa;
  RefAlfa  := NilValI;
  Delta[poDMEA]    := NilValC;
  Delta[poDMEB]    := NilValC;
  Delta[poGPS]    := NilValC;
  Delta[poZadanaPredkosc]    := NilValC;
  RefDis   := NilValC;  (* 1 == 0.002 NM *)
  ABOVESL  := NilValI;  (* 100 FT tyle ile z wysokosciomierza *)
  pilErr   := NilValI;
  TEO_A    := 0.0;
  TEO_E    := 0.0;
  GPS_OK   := StanGPS { NieMaTransmisji  };
  TEO_OK   := TeoStates { tRSZepsuty };
  GPS_A    := 0.0;
  GPS_R    := 0.0;
  GPS_SAT  := 3;
  GPS_GDOP := SigNilVal;
  GPS_PREC := 0;
  Simul    := FALSE;
  Assert( NOT PI_PA.PomiarANieArchiwum );
END ScannerI.
