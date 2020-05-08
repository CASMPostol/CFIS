(*.F- *)
(**********************************************************************
|  Title   : Inicjacja procedury pomiarowej dla LOC
|  Author  : M.POSTOL
|  System  : LOGITECH MODULA-2/86
|  History :
|    27-10-96: M.Postol
|      created
|    12-12-96: M.Postol
|      zamiast Promien w D_results.Init podstawilem 0
|    12-23-96 09:54am: MM
|      Zablokowalem polaryzacje w programach archiwalnych
|    Rel 3.0. MPostol
|      Zmiana listy importowej - nowa definicja Czas.
|      Wysietlanie katow dla DME Format180
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
    Pomiar, L_Count, D_Count, D_DAcquizition, L_DAcquizition, L_results,
    D_results, D_CommonTypes, CommonTypes, SpecConv;

  FROM PI_PA IMPORT
    PomiarANieArchiwum;

  FROM Pomiar IMPORT
    frstButState;

  FROM L_CP_ControlProc IMPORT
    Trajektoria, StartCPLoop;

  FROM L_CommonTypes IMPORT
    (* VAR *) Szer_sekt_kier, Procedura, Strona, Odl_dla_pom_pB,
    (* TYPE *) StronaT, ProceduraT,
    (* CONST *) znakSL;

  FROM Czas IMPORT
    TimeAndDate, GetTimeAndDate;

  FROM L_DataBase IMPORT
    Lotnisko;

  FROM ILS_ZoneMngmnt IMPORT
    IdentPunktow, SetLastPointToBeTraced;

  FROM AltInterface IMPORT
    SetPressure;

  FROM CommonData IMPORT
    OdnDlaPomBledu, OdnDlaPomOdl, Orbita, Predkosc, GlownyOdbiornik,
    CisnienieOdniesienia, NazwaOblotu, NazwaUrzadz1, NazwaUrzadz2, Nadajnik1,
    Nadajnik2;

  CONST
    Format360 = TRUE;
    Format180 = NOT Format360;

  VAR
    D_Procedura : D_CommonTypes.ProceduraT;

  PROCEDURE L_Analiza
            ( VAR synResult : INTEGER;
              VAR podzielnik: INTEGER );

  BEGIN
    IF PomiarANieArchiwum
    THEN
      L_Count.Analiza(synResult, podzielnik);
    END (* if PomiarANieArchiwum *);
  END L_Analiza;

  PROCEDURE D_Analiza
            ( VAR synResult : INTEGER;
              VAR podzielnik: INTEGER );
  BEGIN
    IF PomiarANieArchiwum
    THEN
      D_Count.Analiza(D_Procedura, CommonTypes.poGPS, OdnDlaPomBledu,
                      GlownyOdbiornik, synResult, podzielnik);
    END (* if PomiarANieArchiwum *);
  END D_Analiza;

  PROCEDURE NullPolV
            (    dumm : CARDINAL );

  BEGIN
  END NullPolV;

  PROCEDURE InitPomiar
            ( VAR switchAble : BOOLEAN );

  CONST
    ILS_Pomiar = FALSE;
    DME_Pomiar = NOT ILS_Pomiar;
  VAR
    currfrstBut : ARRAY BOOLEAN OF Pomiar.frstButState;
    cpProcedura : Trajektoria;
    cpOfset     : INTEGER;
    currDT      : TimeAndDate;
    currSecDumm : CARDINAL;

    PROCEDURE Ofset
              (    strona : StronaT ) : INTEGER;

    BEGIN
      CASE strona OF
        sL150 :
          RETURN znakSL * 1500;
        |
        sL75 :
          RETURN znakSL * 750;
        |
        sP75 :
          RETURN -znakSL * 750;
        |
        sP150 :
          RETURN -znakSL * 1500;
      END (* case strona *);
    END Ofset;

  BEGIN
    switchAble := Lotnisko.CzyJestDME;
    cpOfset := 0;
    currfrstBut[ILS_Pomiar] := NoactiveFBS;
    currfrstBut[DME_Pomiar] := NoactiveFBS;
    CASE Procedura OF
      pAlarmOsi :
        D_Procedura := D_CommonTypes.pPromienZakres;
        currfrstBut[DME_Pomiar] := RestartFBS;
        IF PomiarANieArchiwum
        THEN
          currfrstBut[ILS_Pomiar] := PolFBS;
        ELSE
          currfrstBut[ILS_Pomiar] := NoactiveFBS;
        END (* if PomiarANieArchiwum *);
        cpProcedura := Kierunek;
      |
      pSzerSektora_pA :
        D_Procedura := D_CommonTypes.pPromienZakres;
        currfrstBut[DME_Pomiar] := RestartFBS;
        cpProcedura := Kierunek;
        cpOfset := Ofset(Strona);
      |
      pAlarmSzeroki_pA :
        D_Procedura := D_CommonTypes.pPromienZakres;
        currfrstBut[DME_Pomiar] := RestartFBS;
        cpProcedura := Kierunek;
        cpOfset := Ofset(Strona);
      |
      pAlarmWaski_pA :
        D_Procedura := D_CommonTypes.pPromienZakres;
        currfrstBut[DME_Pomiar] := RestartFBS;
        cpProcedura := Kierunek;
        cpOfset := Ofset(Strona);
      |
      pUstawienieOsi_Struktura :
        D_Procedura := D_CommonTypes.pPromienZakres;
        currfrstBut[DME_Pomiar] := RestartFBS;
        IF PomiarANieArchiwum
        THEN
          currfrstBut[ILS_Pomiar] := PolFBS;
        ELSE
          currfrstBut[ILS_Pomiar] := NoactiveFBS;
        END (* if PomiarANieArchiwum *);
        cpProcedura := Kierunek;
      |
      pUstawienieOsi_Szer_pA :
        D_Procedura := D_CommonTypes.pPromienZakres;
        currfrstBut[DME_Pomiar] := RestartFBS;
        IF PomiarANieArchiwum
        THEN
          currfrstBut[ILS_Pomiar] := PolFBS;
        ELSE
          currfrstBut[ILS_Pomiar] := NoactiveFBS;
        END (* if PomiarANieArchiwum *);
        cpProcedura := Kierunek;
      |
      pUstawienieOsi_Waski_pA :
         D_Procedura := D_CommonTypes.pPromienZakres;
        currfrstBut[DME_Pomiar] := RestartFBS;
        IF PomiarANieArchiwum
        THEN
          currfrstBut[ILS_Pomiar] := PolFBS;
        ELSE
          currfrstBut[ILS_Pomiar] := NoactiveFBS;
        END (* if PomiarANieArchiwum *);
        cpProcedura := Kierunek;
      |
      pSzer_i_Osi_pB :
        D_Procedura := D_CommonTypes.pOkragZakres;
        Orbita := Odl_dla_pom_pB;
        currfrstBut[DME_Pomiar] := RestartFBS;
        cpProcedura := Kolko;
      |
      pAlarmSzer_pB :
        D_Procedura := D_CommonTypes.pOkragZakres;
        Orbita := Odl_dla_pom_pB;
        currfrstBut[DME_Pomiar] := RestartFBS;
        cpProcedura := Kolko;
      |
      pAlarmWaski_pB :
        D_Procedura := D_CommonTypes.pOkragZakres;
        Orbita := Odl_dla_pom_pB;
        currfrstBut[DME_Pomiar] := RestartFBS;
        cpProcedura := Kolko;
      |
      pRownowagaModulacji :
        D_Procedura := D_CommonTypes.pPromienZakres;
        currfrstBut[DME_Pomiar] := RestartFBS;
        cpProcedura := Kierunek;
      |
      pFazowanie :
        D_Procedura := D_CommonTypes.pPromienZakres;
        currfrstBut[DME_Pomiar] := RestartFBS;
        cpProcedura := Kierunek;
      |
      pWyrazistosc_na_d_katach :
        D_Procedura := D_CommonTypes.pOkragZakres;
        Orbita := Odl_dla_pom_pB;
        currfrstBut[DME_Pomiar] := RestartFBS;
        cpProcedura := Kolko;
      |
      pZasieg_do_10 :
        D_Procedura := D_CommonTypes.pOkragZakres;
        Orbita := Odl_dla_pom_pB;
        currfrstBut[DME_Pomiar] := RestartFBS;
        cpProcedura := Kolko;
      |
      pZasieg_10_35 :
        D_Procedura := D_CommonTypes.pOkragZakres;
        Orbita := Odl_dla_pom_pB;
        currfrstBut[DME_Pomiar] := RestartFBS;
        cpProcedura := Kolko;
      |
      pZasieg_ponad_35 :
        D_Procedura := D_CommonTypes.pOkragZakres;
        Orbita := Odl_dla_pom_pB;
        currfrstBut[DME_Pomiar] := RestartFBS;
        cpProcedura := Kolko;
      |
      pMarker :
        D_Procedura := D_CommonTypes.pPromienZakres;
        currfrstBut[DME_Pomiar] := RestartFBS;
        cpProcedura := Kierunek;
        cpOfset := Ofset(Strona);
    END (* case Procedura *);
    GetTimeAndDate(currDT);
    IF PomiarANieArchiwum
    THEN
      L_results.Init(Odl_dla_pom_pB, NazwaOblotu, NazwaUrzadz1, Procedura,
                     currDT, OdnDlaPomOdl, cpOfset, 0, Szer_sekt_kier, Strona,
                     IdentPunktow, GlownyOdbiornik, OdnDlaPomBledu, Nadajnik1);
    END (* if PomiarANieArchiwum *);
    IF cpProcedura = Kierunek
    THEN
      IF PomiarANieArchiwum
      THEN
        D_results.Init(D_results.anRes, NazwaOblotu, NazwaUrzadz1, NazwaUrzadz2
                       , currDT, D_Procedura, 0, (* Promien *) OdnDlaPomOdl,
                       GlownyOdbiornik, Nadajnik1, Nadajnik2, Predkosc,
                       CisnienieOdniesienia, TRUE);
      END (* if PomiarANieArchiwum *);
      Pomiar.InitPomiar(currfrstBut[ILS_Pomiar], cpProcedura <> Kolko,
                        Lotnisko.KierunekPasa, Format180, Lotnisko.ProgPasa,
                        SpecConv.SubAng360(FLOAT(Lotnisko.KierunekPasa), 180.0)
                        , ILS_Pomiar, L_DAcquizition.Start,
                        L_DAcquizition.IniDataRadial, L_DAcquizition.Stop,
                        L_DAcquizition.Restart, L_DAcquizition.Abort,
                        L_DAcquizition.RedrawReq, L_DAcquizition.RedrawMarksReq
                        , L_DAcquizition.ConsoleEv, L_Analiza,
                        L_DAcquizition.PolV);
      IF switchAble
      THEN
        Pomiar.InitPomiar(currfrstBut[DME_Pomiar], 
                          cpProcedura <> Kolko,
                          Lotnisko.KierunekPasa, 
                          Format180, 
                          Lotnisko.ProgPasa,
                          SpecConv.SubAng360(FLOAT(Lotnisko.KierunekPasa),
                                             180.0), 
                          DME_Pomiar,
                          D_DAcquizition.Start, 
                          D_DAcquizition.IniDataRadial,
                          D_DAcquizition.Stop, 
                          D_DAcquizition.Restart,
                          D_DAcquizition.Abort, 
                          D_DAcquizition.RedrawReq,
                          D_DAcquizition.RedrawMarksReq,
                          D_DAcquizition.ConsoleEv, 
                          D_Analiza, 
                          NullPolV);
      END (* if switchAble *);
    ELSE
      IF PomiarANieArchiwum
      THEN
        D_results.Init(D_results.anRes, NazwaOblotu, NazwaUrzadz1, NazwaUrzadz2
                       , currDT, D_Procedura, Orbita, OdnDlaPomOdl,
                       GlownyOdbiornik, Nadajnik1, Nadajnik2, Predkosc,
                       CisnienieOdniesienia, TRUE);
      END (* if PomiarANieArchiwum *);
      Pomiar.InitPomiar(currfrstBut[ILS_Pomiar], cpProcedura <> Kolko,
                        Odl_dla_pom_pB, Format180, 0, SpecConv.SubAng360(FLOAT(
                                                                         Lotnisko.KierunekPasa
                                                                         ),
                                                                         180.0)
                        , ILS_Pomiar, L_DAcquizition.Start,
                        L_DAcquizition.IniDataOrbit, L_DAcquizition.Stop,
                        L_DAcquizition.Restart, L_DAcquizition.Abort,
                        L_DAcquizition.RedrawReq, L_DAcquizition.RedrawMarksReq
                        , L_DAcquizition.ConsoleEv, L_Analiza,
                        L_DAcquizition.PolV);
      IF switchAble
      THEN
        Pomiar.InitPomiar(currfrstBut[DME_Pomiar], cpProcedura <> Kolko,
                          Odl_dla_pom_pB, Format180, 0, SpecConv.SubAng360(
                          FLOAT(Lotnisko.KierunekPasa), 180.0), DME_Pomiar,
                          D_DAcquizition.Start, D_DAcquizition.IniDataOrbit,
                          D_DAcquizition.Stop, D_DAcquizition.Restart,
                          D_DAcquizition.Abort, D_DAcquizition.RedrawReq,
                          D_DAcquizition.RedrawMarksReq,
                          D_DAcquizition.ConsoleEv, D_Analiza, NullPolV);
      END (* if switchAble *);
    END (* if *);
    CASE cpProcedura OF
      Kierunek :
        StartCPLoop(cpProcedura, cpOfset, GlownyOdbiornik);
      |
      Kolko :
        StartCPLoop(cpProcedura, Odl_dla_pom_pB, GlownyOdbiornik);
    END (* case cpProcedura *);
    SetPressure(CisnienieOdniesienia);
    SetLastPointToBeTraced(Lotnisko.Kategoria, TRUE);
  END InitPomiar;

END PI_Pomiar.
