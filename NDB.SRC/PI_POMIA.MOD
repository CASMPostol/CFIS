(*.F- *)
(**********************************************************************
|  Title   : Inicjacja procedury pomiarowej dla LOC
|  Author  : M.POSTOL
|  System  : LOGITECH MODULA-2/86
|  History :
|    28-01-97: M.Postol
|      zmiany w zwiazku z podzielnikiem
|    Rel.3.0 MPostol
|      nowa definicja modulu Czas
|
|  Copyright (C), CAS LODZ POLAND.
|  TEL: 42' 686 25 47
|  mailto: techsupp@cas.com.pl
|  http: www.cas.com.pl
|
**********************************************************************)
(*.F+ *)

IMPLEMENTATION MODULE PI_Pomiar;

  IMPORT
    Pomiar, N_results, N_DAcquizition, CommonTypes, SpecConv, N_Count;

  FROM Pomiar IMPORT
    frstButState;

  FROM CommonData IMPORT
    GlownyOdbiornik, Nadajnik1, CisnienieOdniesienia, NazwaOblotu, NazwaUrzadz1
    , Promien, Orbita;

  FROM N_CP_ControlProc IMPORT
    StartCPLoop, StopCPLoop;

  FROM SpecConv IMPORT
    Angle100;

  FROM N_CommonTypes IMPORT
    Procedura, ProceduraT;

  FROM CommonTypes IMPORT
    OdnDlaPomBleduT, OdnDlaPomOdlT;

  FROM Czas IMPORT
    GetTimeAndDate, TimeAndDate;

  FROM N_DataBase IMPORT
    NadajnikNDB;

  FROM AltInterface IMPORT
    SetPressure;

  FROM PA_PA IMPORT
    PomiarANieArchiwum;

  CONST
    DMEInBack = FALSE;
    Format360 = TRUE;
    Format180 = NOT Format360;

  PROCEDURE Analiza
            ( VAR synResult : INTEGER;
              VAR podzielnik: INTEGER );

  BEGIN
    IF PomiarANieArchiwum
    THEN
      N_Count.Analiza(synResult, podzielnik);
    END (* if PomiarANieArchiwum *);
  END Analiza;

  PROCEDURE NullPolV
            (    dumm : CARDINAL );

  BEGIN
  END NullPolV;

  PROCEDURE InitPomiar
            ( VAR switchAble : BOOLEAN );

  CONST
    ILS_Pomiar = FALSE;
    znakSL     = 1;
  VAR
    currfrstBut : ARRAY BOOLEAN OF Pomiar.frstButState;
    cpOfset     : INTEGER;
    currDT      : TimeAndDate;
    currSecDumm : CARDINAL;

  BEGIN
    switchAble := FALSE;
    currfrstBut[ILS_Pomiar] := NoactiveFBS;
    GetTimeAndDate(currDT);
    IF Procedura = pPromien
    THEN
      IF PomiarANieArchiwum
      THEN
        N_results.Init(NazwaOblotu, NazwaUrzadz1, currDT, Procedura, Promien,
                       GlownyOdbiornik, CisnienieOdniesienia, Nadajnik1);
      END (* if PomiarANieArchiwum *);
      Pomiar.InitPomiar(RestartFBS, TRUE, Promien, Format360, 0, 0.0, FALSE,
                        N_DAcquizition.Start, N_DAcquizition.IniDataRadial,
                        N_DAcquizition.Stop, N_DAcquizition.Restart,
                        N_DAcquizition.Abort, N_DAcquizition.RedrawReq,
                        N_DAcquizition.RedrawMarksReq, N_DAcquizition.ConsoleEv
                        , Analiza, N_DAcquizition.PolV);
    ELSE
      IF PomiarANieArchiwum
      THEN
        N_results.Init(NazwaOblotu, NazwaUrzadz1, currDT, Procedura, Orbita,
                       GlownyOdbiornik, CisnienieOdniesienia, Nadajnik1);
      END (* if PomiarANieArchiwum *);
      Pomiar.InitPomiar(RestartFBS, FALSE, Orbita, Format360, 0, 0.0, FALSE,
                        N_DAcquizition.Start, N_DAcquizition.IniDataOrbit,
                        N_DAcquizition.Stop, N_DAcquizition.Restart,
                        N_DAcquizition.Abort, N_DAcquizition.RedrawReq,
                        N_DAcquizition.RedrawMarksReq, N_DAcquizition.ConsoleEv
                        , Analiza, N_DAcquizition.PolV);
    END (* if Procedura *);
    IF Procedura = pPromien
    THEN
      StartCPLoop(Procedura, Angle100(Promien));
    ELSE
      StartCPLoop(Procedura, Orbita);
    END (* if Procedura *);
    SetPressure(CisnienieOdniesienia);
  END InitPomiar;

END PI_Pomiar.
