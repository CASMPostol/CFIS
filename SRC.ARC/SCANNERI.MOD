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
|
|  Copyright (C), CAS LODZ POLAND.
|  TEL: 42' 862 547, 42' 87 80 44 FAX/TEL: 42' 84 48 40
|
**********************************************************************)
(*.F+ *)

IMPLEMENTATION MODULE ScannerI [ 0 ];

  FROM CommonTypes IMPORT
    (* TYPE *) GlownyOdbiornikT, OdnDlaPomBleduT, OdnDlaPomOdlT, signTabBin,
               PolozenieBiegunowe, PolozenieGeo,
    (* CONST *) SigNilVal, NilValC, NilValI, DisNilVal, TEO_flg, GPS_flg;

  FROM SYSTEM IMPORT
    INBYTE;

  FROM MANAGER IMPORT
    STARTPROCESS, Condition, InitC, WAITC, Broadcast, Assert;

  FROM Timer IMPORT
    Wait;

  FROM SpecConv IMPORT
    SubAngle100;

  IMPORT
    Strings, PI_PA;

  FROM RTSMain IMPORT
    Terminate, Status;

  TYPE
    DtaSignType =
      CARDINAL;

  CONST
    SCROLLOCK = 4;

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
  gDOP     := MAX(CARDINAL);
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
  TEO_OK   := {NoTrans_Warning};
  GPS_A    := 0.0;
  GPS_R    := 0.0;
  GPS_OK   := {NoTrans_Warning};
  GPS_SAT  := 3;
  GPS_GDOP := MAX(CARDINAL);
  GPS_PREC := 0;
  Simul    := FALSE;
  Assert( NOT PI_PA.PomiarANieArchiwum );
END ScannerI.
