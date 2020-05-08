(*.F- *)
(**********************************************************************
|  Title   : Inicjacja procedury pomiarowej dla LOC
|  Author  : M.POSTOL
|  System  : LOGITECH MODULA-2/86
|  History :
|    27-10-96: M.Postol
|      created
|    23-11-97: M.Postol
|      zly parametr okreslajacy GS w SetLastPointToBeTraced
|    Rel. 3.0: MPostol
|      Dostosowalem do nowej definicji Czas
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
    Pomiar, G_results, G_DAcquizition, SpecConv, L_Count;

  FROM Pomiar IMPORT
    frstButState;

  FROM G_CommonTypes IMPORT
    Procedura, Strona, Szer_sekt_kier, znakGora, StronaT, ProceduraT;

  FROM ILS_ZoneMngmnt IMPORT
    IdentPunktow;

  FROM CommonData IMPORT
    OdnDlaPomOdl, GlownyOdbiornik, Nadajnik1, NazwaOblotu, CisnienieOdniesienia
    , NazwaUrzadz1;

  FROM G_CP_ControlProc IMPORT
    StartCPLoop;

  FROM Czas IMPORT
    GetTimeAndDate, TimeAndDate;

  FROM L_DataBase IMPORT
    Lotnisko;

  FROM AltInterface IMPORT
    SetPressure;

  FROM ILS_ZoneMngmnt IMPORT
    SetLastPointToBeTraced;

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
      L_Count.Analiza(synResult, podzielnik);
    END (* if PomiarANieArchiwum *);
  END Analiza;

  PROCEDURE InitPomiar
            ( VAR switchAble : BOOLEAN );

  CONST
    ILS_Pomiar = FALSE;
  VAR
    currfrstBut : ARRAY BOOLEAN OF Pomiar.frstButState;
    pomOfset    : INTEGER;
    cpOfset     : INTEGER;
    currDT      : TimeAndDate;
    currSecDumm : CARDINAL;

    PROCEDURE Ofset
              (    strona : StronaT ) : INTEGER;

    BEGIN
      CASE strona OF
        Gora :
          RETURN znakGora * 750;
        |
        Dol :
          RETURN -znakGora * 750;
      END (* case strona *);
    END Ofset;

  BEGIN
    switchAble := DMEInBack;
    cpOfset := 0;
    pomOfset := 0;
    currfrstBut[ILS_Pomiar] := NoactiveFBS;
    CASE Procedura OF
      pSzerSektora_pA, pAlarmSzeroki_pA, pAlarmWaski_pA:
        cpOfset := Ofset(Strona);
        pomOfset := cpOfset;
      |
      pZabezpieczenie :
        cpOfset := -znakGora * 1800;
        pomOfset := cpOfset;
      |
      pPokrycie8stP :
        cpOfset := -800;
      |
      pPokrycie8stL :
        cpOfset := 800;
    ELSE
    END (* case Procedura *);
    GetTimeAndDate(currDT);
    IF PomiarANieArchiwum
    THEN
      G_results.Init(NazwaOblotu, NazwaUrzadz1, Procedura, currDT, OdnDlaPomOdl
                     , pomOfset, Lotnisko.Kat_GS, Szer_sekt_kier, Strona,
                     IdentPunktow, GlownyOdbiornik, Nadajnik1);
    END (* if PomiarANieArchiwum *);
    Pomiar.InitPomiar(currfrstBut[ILS_Pomiar], TRUE, Lotnisko.KierunekPasa,
                      Format180, Lotnisko.ProgPasa, SpecConv.SubAng360(FLOAT(
                                                                       Lotnisko.KierunekPasa
                                                                       ), 180.0
                      ), ILS_Pomiar, G_DAcquizition.Start,
                      G_DAcquizition.IniDataRadial, G_DAcquizition.Stop,
                      G_DAcquizition.Restart, G_DAcquizition.Abort,
                      G_DAcquizition.RedrawReq, G_DAcquizition.RedrawMarksReq,
                      G_DAcquizition.ConsoleEv, Analiza, G_DAcquizition.PolV);
    StartCPLoop(Procedura, cpOfset, GlownyOdbiornik);
    SetPressure(CisnienieOdniesienia);
    SetLastPointToBeTraced(Lotnisko.Kategoria, FALSE);
  END InitPomiar;

END PI_Pomiar.
