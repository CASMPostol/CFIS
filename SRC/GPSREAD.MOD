(*.F- *)
(**********************************************************************
|  Title   : Read fro GPS receiver - Novatell version
|  Author  : T.Rozmarynowski
|  System  : LOGITECH MODULA-2/86
|  History :
|    Rel. 3.0: M.Postol
|      uporzadkowalem
|    Rel 3.16: MPostol
|      Aby zaoszczedzic pamiec proces uruchamiany jest tylko w programie 
|      pomiarowym
|
|  Copyright (C), CAS LODZ POLAND.
|  TEL: 42' 686 25 47
|  mailto: techsupp@cas.com.pl http: www.cas.com.pl
|
**********************************************************************)
(*.F+ *)

IMPLEMENTATION MODULE GPSRead [ 0 ];

  FROM CommonTypes IMPORT
    PolozenieGeo, NilValC, SigNilVal, DisNilVal;

  FROM MANAGER IMPORT
    STARTPROCESS;

  FROM Timer IMPORT
    Wait, TInOneSecond;

  IMPORT GPS_nov, GPS_TRIMBLE;

  FROM SpecConv IMPORT
      IncRound;

  FROM Czas  IMPORT
    SetTime, SetDate;

  FROM PA_PA IMPORT
   PomiarANieArchiwum;
   
  VAR
    ObecnyStan              : StanGPS;  (* zmienna opisana gdzie indziej zbior*)
    currentSign             : CARDINAL;
    Last_Gdop               : INTEGER;
    Last_NumberOfSattelites : INTEGER;
    Last_polGeo             : PolozenieGeo;
    Last_Diffmode           : BOOLEAN;
    Last_tog                : REAL;
    Last_EPE                : CARDINAL;
    CurrGPSAnalizer         : PROCEDURE;

PROCEDURE Read_Nic;
BEGIN

END Read_Nic;

PROCEDURE  Read_Nov;
VAR
  Last_Data   : GPS_nov.FrameData;
BEGIN
  WHILE GPS_nov.GetFrame ( Last_Data ) DO
    WITH Last_Data  DO
      CASE Frame  OF
        GPS_nov.FT_DOPA:
          Last_Gdop := Gdop;
        |
        GPS_nov.FT_GPGGA:
          Last_NumberOfSattelites := NumberOfSattelites;
          CASE mode OF
            GPS_nov.NoFixAvailabl:
              Last_Diffmode := FALSE;
              INCL(ObecnyStan, Flaga);
            |
            GPS_nov.GPSNormalMode, GPS_nov.GPSDiffMode:
              Last_polGeo := polGeo;
              Last_Diffmode := mode = GPS_nov.GPSDiffMode;
              IncRound( currentSign );
              IF mode = GPS_nov.GPSDiffMode  THEN
                INCL(ObecnyStan, InDiffMode);
              ELSE
                EXCL(ObecnyStan, InDiffMode);
              END;
              EXCL(ObecnyStan, Flaga);
              
          END;
        | 
        GPS_nov.FT_GPVTG:
          Last_tog  := tog;
        | 
        GPS_nov.FT_GPZDA:
          IF year # 0
          THEN
            SetTime( hour, min, sec );
            SetDate( year, month, day );
            GPS_nov.gpzdaOff;
          END (* if year *);
      ELSE
      ;
      END (* CASE Frame *);
    END (* WITH Last_Data *);
  END (* WHILE GetFrame *);
END Read_Nov;
    
PROCEDURE  Read_Trimble;
VAR
  Last_Data   : GPS_TRIMBLE.FrameData;
BEGIN
  WHILE GPS_TRIMBLE.GetFrame ( Last_Data ) DO
    Last_Diffmode := FALSE;
    WITH Last_Data  DO
      IF FixNotAvailable THEN
        INCL(ObecnyStan, Flaga);
      ELSE
        EXCL(ObecnyStan, Flaga);
        IncRound( currentSign );
        Last_EPE := epe;
        Last_polGeo.Szerokosc := WspSzerokosc; 
        Last_polGeo.Dlugosc := WspDlugosc; 
        Last_tog  := Kierunek;
        (* SetDate( year, month, day ); *)
        (* SetTime( hour, min, sec ); *)
        Last_NumberOfSattelites := NumberOfSattelites;
      END;
    END (* WITH Last_Data *);
  END (* WHILE GetFrame *);
END Read_Trimble;

  PROCEDURE GPSReceive
            ( VAR pgret    : PolozenieGeo;
              VAR GDOP     : INTEGER;
              VAR NOS      : INTEGER;
              VAR EPE      : CARDINAL;
              VAR DiffMode : BOOLEAN;
              VAR dtaSign  : DtaSignType  ) : StanGPS;
    (* czytanie z GPS*)


  BEGIN (* GPSReceive *)
    CurrGPSAnalizer;
    dtaSign  := currentSign;
    pgret    := Last_polGeo;   (* przepisanie danych *)
    GDOP     := Last_Gdop;
    NOS      := Last_NumberOfSattelites;
    EPE      := Last_EPE;
    DiffMode := Last_Diffmode;
    RETURN ObecnyStan;
  END GPSReceive;

  PROCEDURE GetDirection
            ( VAR dtaSign : DtaSignType ) : REAL;
    (* kierunek lotu wzg N*)

  BEGIN
    dtaSign := currentSign;
    RETURN Last_tog;
  END GetDirection;

  PROCEDURE GetCurrDataSign() : DtaSignType;

  BEGIN
    RETURN currentSign;
  END GetCurrDataSign;

  PROCEDURE WatchDog;

  TYPE
    stanyGPS =
      ( inicjacjaNov, odczytNov, inicjacjaTr, odczytTr);

  VAR
    StanHGPS       : stanyGPS;
    wd_currSign    : CARDINAL;
    wd_prevSign    : CARDINAL;
    pg             : PolozenieGeo;
    GDOP           : INTEGER;
    NOS            : INTEGER;
    EPE            : CARDINAL;
    DiffMode       : BOOLEAN;
    stan           : StanGPS;
    waitTime       : CARDINAL;
    L_framesWError : CARDINAL;
    L_chrCount     : CARDINAL;
    L_frmCount     : CARDINAL;
    
  BEGIN
    wd_prevSign    := currentSign;
    StanHGPS       := inicjacjaNov     ;
    waitTime       := 0;
    LOOP
      Wait( waitTime );
      CASE StanHGPS OF
        inicjacjaNov :
          L_framesWError  := GPS_nov.framesWError;
          L_chrCount      := GPS_nov.chrCount;
          ObecnyStan      := StanGPS { NieMaTransmisji };
          StanHGPS        := odczytNov;
          waitTime        := TInOneSecond( ) * 10;
          GPS_nov.Inicjacja;
          CurrGPSAnalizer := Read_Nov;
        |
        odczytNov :
          stan := GPSReceive( pg, GDOP, NOS, EPE, DiffMode, wd_currSign );
          IF L_framesWError = GPS_nov.framesWError THEN
            EXCL(ObecnyStan, BledyWTransmisji);
          ELSE
            L_framesWError := GPS_nov.framesWError;
            INCL(ObecnyStan, BledyWTransmisji);
          END;
          IF L_chrCount  = GPS_nov.chrCount THEN
            INCL(ObecnyStan, NieMaTransmisji);
          ELSE
            L_chrCount := GPS_nov.chrCount;
            EXCL(ObecnyStan, NieMaTransmisji);
          END;
          IF (wd_currSign = wd_prevSign) AND (L_frmCount = GPS_nov.frmCount)
          THEN
            Last_Gdop := SigNilVal;
            Last_Diffmode := FALSE;
            Last_tog := 0.0;
            Last_NumberOfSattelites := SigNilVal;
            StanHGPS := inicjacjaTr;
            waitTime := 0;
          ELSE
            wd_prevSign := wd_currSign;
            L_frmCount := GPS_nov.frmCount;
            waitTime := TInOneSecond( ) * 2;
          END (* if wd_currSign *);
        |
        inicjacjaTr :
          L_framesWError  := GPS_TRIMBLE.framesWError;
          L_chrCount      := GPS_TRIMBLE.chrCount;
          StanHGPS        := odczytTr;
          ObecnyStan      := StanGPS { NieMaTransmisji };
          waitTime        := TInOneSecond( ) * 2;
          GPS_TRIMBLE.Inicjacja;
          CurrGPSAnalizer := Read_Trimble;
        |
        odczytTr :
          stan := GPSReceive( pg, GDOP, NOS, EPE, DiffMode, wd_currSign );
          IF L_framesWError = GPS_TRIMBLE.framesWError THEN
            EXCL(ObecnyStan, BledyWTransmisji);
          ELSE
            L_framesWError := GPS_TRIMBLE.framesWError;
            INCL(ObecnyStan, BledyWTransmisji);
          END;
          IF L_chrCount  = GPS_TRIMBLE.chrCount THEN
            INCL(ObecnyStan, NieMaTransmisji);
          ELSE
            L_chrCount := GPS_TRIMBLE.chrCount;
            EXCL(ObecnyStan, NieMaTransmisji);
          END;
          IF (wd_currSign = wd_prevSign) AND 
             (L_frmCount = GPS_TRIMBLE.frmCount)
          THEN
            Last_Gdop               := SigNilVal;
            Last_Diffmode           := FALSE;
            Last_tog                := 0.0;
            Last_NumberOfSattelites := SigNilVal;
            StanHGPS                := inicjacjaNov;
            waitTime                := 0;
          ELSE
            wd_prevSign := wd_currSign;
            L_frmCount  := GPS_TRIMBLE.frmCount;
            waitTime    := TInOneSecond( ) * 2;
          END (* if wd_currSign *);
      END (* case StanHGPS *);
    END (* loop *);
  END WatchDog;

BEGIN
  CurrGPSAnalizer := Read_Nic;
  ObecnyStan := StanGPS { NieMaTransmisji };
  currentSign := 0;
  Last_Gdop := SigNilVal;
  Last_NumberOfSattelites := SigNilVal;
  Last_Diffmode := FALSE;
  Last_tog := 0.0;
  Last_EPE := DisNilVal;
  IF PomiarANieArchiwum  THEN
    STARTPROCESS( WatchDog, 0800H, 0 );
  END (* IF *);
END GPSRead.
