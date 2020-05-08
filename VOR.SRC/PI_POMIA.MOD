(*.F- *)
(**********************************************************************
|  Title   : Inicjacja procedury pomiarowej dla VOR
|  Author  : M.POSTOL
|  System  : LOGITECH MODULA-2/86
|  History :
|    29-01-96:
|      dostosowalem do nowej definicji V_results.
|      modyfikacja w zwiazku z przekazywaniem precyzji
|    Rel. 3.0.MPostol
|      Zmienna switchAble w InitPomiar ustawian jest w zaleznosci
|      od tego czy jest DME na urzadzeniu, a nie co zostanie wcisniete na 
|      ekranie glownym
|      dostosowalem do nowej definicji D_results
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
    Pomiar, V_Count, D_Count, D_DAcquizition, V_DAcquizition, V_results,
    D_results, CommonData;

  FROM PI_PA IMPORT
    PomiarANieArchiwum;

  FROM Pomiar IMPORT
    frstButState;

  FROM V_CP_ControlProc IMPORT
    StartCPLoop;

  FROM SpecConv IMPORT
    Angle100;

  FROM V_CommonTypes IMPORT
    Procedura, ProceduraT;

  FROM AltInterface IMPORT
    SetPressure;

  FROM CommonData IMPORT
    OdnDlaPomBledu, OdnDlaPomOdl, Promien, Predkosc, GlownyOdbiornik, Orbita,
    CisnienieOdniesienia, NazwaOblotu, NazwaUrzadz1, NazwaUrzadz2,
    Nadajnik1, Nadajnik2;

  FROM V_Database IMPORT
    twoLocations, CurVor1;

  FROM Czas IMPORT
    TimeAndDate, GetTimeAndDate;
    
  CONST
    Format360 = TRUE;

  PROCEDURE V_Analiza
            ( VAR synResult : INTEGER;
              VAR precision : INTEGER );

  BEGIN
    IF PomiarANieArchiwum
    THEN
      V_Count.Analiza(Procedura, OdnDlaPomOdl, OdnDlaPomBledu, GlownyOdbiornik,
                      twoLocations, synResult, precision);
    END (* if PomiarANieArchiwum *);
  END V_Analiza;

  PROCEDURE D_Analiza
            ( VAR synResult : INTEGER;
              VAR precision : INTEGER );

  BEGIN
    IF PomiarANieArchiwum
    THEN
      D_Count.Analiza(Procedura, OdnDlaPomOdl, OdnDlaPomBledu, GlownyOdbiornik,
                      synResult, precision);
    END (* if PomiarANieArchiwum *);
  END D_Analiza;

  PROCEDURE NullPolV
            (    dumm : CARDINAL );

  BEGIN
  END NullPolV;

  PROCEDURE InitPomiar
            ( VAR switchAble : BOOLEAN );

  CONST
    radNoOrbit = TRUE;
    VOR_Pomiar = FALSE;
    DME_Pomiar = NOT VOR_Pomiar;
  VAR
    currfrstBut : ARRAY BOOLEAN OF Pomiar.frstButState;
    currDT      : TimeAndDate;
    sec         : CARDINAL;

  BEGIN
    switchAble := CurVor1.CzyJestDME;
    CASE Procedura OF
      pOkragBlad, pOkragZakres :
        StartCPLoop(Procedura, Orbita);
      |
      pPromienBlad, pPromienZakres :
        StartCPLoop(Procedura, Angle100(Promien));
    END (* case V_Oblot.Procedura *);
    GetTimeAndDate( currDT );
    SetPressure(CisnienieOdniesienia);
    IF (Procedura = pPromienBlad) OR (Procedura = pPromienZakres)
    THEN
      IF (Procedura = pPromienBlad)
      THEN
        IF PomiarANieArchiwum
        THEN
          currfrstBut[VOR_Pomiar] := PolFBS;
          currfrstBut[DME_Pomiar] := NoactiveFBS;
        ELSE
          currfrstBut[VOR_Pomiar] := NoactiveFBS;
          currfrstBut[DME_Pomiar] := NoactiveFBS;
        END (* if PomiarANieArchiwum *);
      ELSE
        IF PomiarANieArchiwum
        THEN
          currfrstBut[VOR_Pomiar] := RestartFBS;
          currfrstBut[DME_Pomiar] := RestartFBS;
        ELSE
          currfrstBut[VOR_Pomiar] := NoactiveFBS;
          currfrstBut[DME_Pomiar] := NoactiveFBS;
        END (* if PomiarANieArchiwum *);
      END (* if Procedura *);
      IF PomiarANieArchiwum
      THEN
        V_results.Init(V_results.anRes, NazwaOblotu, NazwaUrzadz1, NazwaUrzadz2
                       , currDT, Procedura, Promien, OdnDlaPomOdl,
                       GlownyOdbiornik, Nadajnik1, Nadajnik2, Predkosc,
                       CisnienieOdniesienia, OdnDlaPomBledu);
        D_results.Init(D_results.anRes, NazwaOblotu, NazwaUrzadz1, NazwaUrzadz2
                       , currDT, Procedura, Promien, OdnDlaPomOdl,
                       GlownyOdbiornik, Nadajnik1, Nadajnik2, Predkosc,
                       CisnienieOdniesienia, FALSE);
      END (* if PomiarANieArchiwum *);
      Pomiar.InitPomiar(currfrstBut[VOR_Pomiar], radNoOrbit, Promien, Format360
                        , 0, 0.0, VOR_Pomiar, V_DAcquizition.Start,
                        V_DAcquizition.IniDataRadial, V_DAcquizition.Stop,
                        V_DAcquizition.Restart, V_DAcquizition.Abort,
                        V_DAcquizition.RedrawReq, V_DAcquizition.RedrawMarksReq
                        , V_DAcquizition.ConsoleEv, V_Analiza,
                        V_DAcquizition.PolV);
      IF switchAble
      THEN
        Pomiar.InitPomiar(currfrstBut[DME_Pomiar], radNoOrbit, Promien,
                          Format360, 0, 0.0, DME_Pomiar, D_DAcquizition.Start,
                          D_DAcquizition.IniDataRadial, D_DAcquizition.Stop,
                          D_DAcquizition.Restart, D_DAcquizition.Abort,
                          D_DAcquizition.RedrawReq,
                          D_DAcquizition.RedrawMarksReq,
                          D_DAcquizition.ConsoleEv, D_Analiza, NullPolV);
      END (* if switchAble *);
    ELSE
      IF PomiarANieArchiwum
      THEN
        V_results.Init(V_results.anRes, NazwaOblotu, NazwaUrzadz1, NazwaUrzadz2
                       , currDT, Procedura, Orbita, OdnDlaPomOdl,
                       GlownyOdbiornik, Nadajnik1, Nadajnik2, Predkosc,
                       CisnienieOdniesienia, OdnDlaPomBledu);
        D_results.Init(D_results.anRes, NazwaOblotu, NazwaUrzadz1, NazwaUrzadz2
                       , currDT, Procedura, Orbita, OdnDlaPomOdl,
                       GlownyOdbiornik, Nadajnik1, Nadajnik2, Predkosc,
                       CisnienieOdniesienia, FALSE);
      END (* if PomiarANieArchiwum *);
      Pomiar.InitPomiar(RestartFBS, NOT radNoOrbit, Orbita, Format360, 0, 0.0,
                        VOR_Pomiar, V_DAcquizition.Start,
                        V_DAcquizition.IniDataOrbit, V_DAcquizition.Stop,
                        V_DAcquizition.Restart, V_DAcquizition.Abort,
                        V_DAcquizition.RedrawReq, V_DAcquizition.RedrawMarksReq
                        , V_DAcquizition.ConsoleEv, V_Analiza,
                        V_DAcquizition.PolV);
      IF switchAble
      THEN
        Pomiar.InitPomiar(RestartFBS, NOT radNoOrbit, Orbita, Format360, 0, 0.0
                          , DME_Pomiar, D_DAcquizition.Start,
                          D_DAcquizition.IniDataOrbit, D_DAcquizition.Stop,
                          D_DAcquizition.Restart, D_DAcquizition.Abort,
                          D_DAcquizition.RedrawReq,
                          D_DAcquizition.RedrawMarksReq,
                          D_DAcquizition.ConsoleEv, D_Analiza, NullPolV);
      END (* if switchAble *);
    END (* if *);
  END InitPomiar;

END PI_Pomiar.
