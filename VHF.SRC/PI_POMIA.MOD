(*.F- *)
(**********************************************************************
|  Title   : Inicjacja procedury pomiarowej dla VHF
|  Author  : M.POSTOL
|  System  : LOGITECH MODULA-2/86
|  History :
|    08-12-96: created
|    Rel 3.0. Mpostol
|     Zmiana definicji modulu Czas
|
|  Copyright (C), CAS LODZ POLAND.
|  TEL: 42' 862 547, 42' 87 80 44 FAX/TEL: 42' 84 48 40
|
**********************************************************************)
(*.F+ *)

IMPLEMENTATION MODULE PI_Pomiar;

  IMPORT
    Pomiar, H_results, H_DAcquizition, H_Count;

  FROM Pomiar IMPORT
    frstButState;

  FROM CommonData IMPORT
    Nadajnik1, CisnienieOdniesienia, NazwaOblotu, NazwaUrzadz1, Promien, Orbita
    ;

  FROM H_CP_ControlProc IMPORT
    StartCPLoop;

  FROM H_CommonTypes IMPORT
    Procedura, ProceduraT;

  FROM Czas IMPORT
    TimeAndDate, GetTimeAndDate;

  FROM AltInterface IMPORT
    SetPressure;

  FROM SpecConv IMPORT
    Angle100;

  FROM PI_PA IMPORT
    PomiarANieArchiwum;

  CONST
    Format360 = TRUE;

  PROCEDURE Analiza
            ( VAR synResult  : INTEGER;
              VAR podzielnik : INTEGER);

  BEGIN
    IF PomiarANieArchiwum
    THEN
      H_Count.Analiza(synResult, podzielnik);
    END (* if PomiarANieArchiwum *);
  END Analiza;

  PROCEDURE InitPomiar
            ( VAR switchAble : BOOLEAN );
  VAR
    cpOfset     : INTEGER;
    currDT      : TimeAndDate;
    currSecDumm : CARDINAL;

  BEGIN
    switchAble := FALSE;
    GetTimeAndDate(currDT);
    IF Procedura = pPromien
    THEN
      IF PomiarANieArchiwum
      THEN
        H_results.Init(NazwaOblotu, NazwaUrzadz1, Procedura, currDT, Promien,
                       Nadajnik1);
      END (* if PomiarANieArchiwum *);
      Pomiar.InitPomiar(RestartFBS, TRUE, Promien, Format360, 0, 0.0, FALSE,
                        H_DAcquizition.Start, H_DAcquizition.IniDataRadial,
                        H_DAcquizition.Stop, H_DAcquizition.Restart,
                        H_DAcquizition.Abort, H_DAcquizition.RedrawReq,
                        H_DAcquizition.RedrawMarksReq, H_DAcquizition.ConsoleEv
                        , Analiza, H_DAcquizition.PolV);
    ELSE
      IF PomiarANieArchiwum
      THEN
        H_results.Init(NazwaOblotu, NazwaUrzadz1, Procedura, currDT, Orbita,
                       Nadajnik1);
      END (* if PomiarANieArchiwum *);
      Pomiar.InitPomiar(RestartFBS, FALSE, Orbita, Format360, 0, 0.0, FALSE,
                        H_DAcquizition.Start, H_DAcquizition.IniDataOrbit,
                        H_DAcquizition.Stop, H_DAcquizition.Restart,
                        H_DAcquizition.Abort, H_DAcquizition.RedrawReq,
                        H_DAcquizition.RedrawMarksReq, H_DAcquizition.ConsoleEv
                        , Analiza, H_DAcquizition.PolV);
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
