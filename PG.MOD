(*.F- *)
(**********************************************************************
|  Title   : Program pomiaru GS
|  Author  : M.Postol
|  System  : LOGITECH MODULA-2/86
|  History :
|    01.01.96: wersja oryginalna
|    Rel. 01 18.02.96: Mariusz Postol
|      Rozbicie na osobne moduly PV, VORPomiar, VORScreen
|      Bardzo duzo zmian
|    27-10-96: M.Postol
|      zmienilem odwolanie z L_CP_ControlProc na G_CP_ControlProc
|    15-12-96: M.Postol
|      zmiana definicji refTab.
|    28-01-97: M.Postol
|      zmiany w zwiazku w wprowadzeniem podzielnika
|    05-02-97 : M.Postol
|      W procedurach zasiegowych wykorzystuje sie azymut a nie elewacje
|    25-02-97: M.Postol
|      Kopiowanie pliku jest realizowane zawsze po wcisnieciu klawisza Accept
|    25-03-97: M.Postol
|      we wszystkich procedurach RefAlfa jest elewacja
|    29-03-97: M.Postol
|      inicjacja SetLastPointToBeTraced tylko w przypadku zaakceptowania 
|      inspekcji
|    12-05-97: M.Postol
|      nowa def ScannerI
|
|  Copyright (C), CAS LODZ POLAND.
|  TEL: 42' 862 547, 42' 87 80 44 FAX/TEL: 42' 84 48 40
|
**********************************************************************)
(*.F+ *)

MODULE PG;

  IMPORT
    DebugPMD, MANAGER, DOSEntry, ErrorMess, PA_PA;

  IMPORT
    Tune, PI_Qcheck, ScannerI, G_Files;

  FROM PI_Glowny IMPORT
    GlownyEP;

  FROM G_Inspekcja  IMPORT
    InspekcjaEvent, InspekcjaEP;

  FROM G_Oblot IMPORT
    (* PROCEDURE *) Zapisz;

  FROM CommonData IMPORT
    SciezkaOpisuPomiaru, GlownyOdbiornik;

  FROM Files IMPORT
    GoHomeDir;

  FROM G_CP_ControlProc IMPORT
    StopCPLoop;

  FROM CommonTypes IMPORT
    (* TYPE *) SigNilVal, OdnDlaPomBleduT, OdnDlaPomOdlT, glownyEvent;

  FROM RTSMain IMPORT
    Terminate, Status;

  FROM Pomiar IMPORT
    pomiarEvent, PomiarEP;

  FROM PI_Analiza IMPORT
    (* TYPE *) analizaEvent,
    (* PROCEDURE *) AnalizaEP;

  FROM PI_Pomiar IMPORT
    InitPomiar;

  FROM PI_ArchDate IMPORT
    okTab, LoadData;

  FROM PI_Drukuj IMPORT
    Druk;

  FROM L_DataBase  IMPORT
    Lotnisko;

  FROM SpecConv IMPORT
    SubAngle100, Angle100;

  FROM G_CommonTypes   IMPORT
     ProceduraT;

  FROM ILS_ZoneMngmnt IMPORT
    SetLastPointToBeTraced;

  TYPE
    MainStates     =
      ( InspekcjaMS,
        GlownyMS,
        TestMS,
        PomiarPrologMS,
        PomiarMS,
        LadujDaneDoDrukMS,
        AnalizaMS,
        DrukujMS,
        KoniecProgMS );

  CONST
    Zestaw            = FALSE;
    AzymANieElew      = TRUE;
    ElewANieAzym      = NOT AzymANieElew;
    LocationsTogether = TRUE;
  VAR
    mainState     : MainStates;
    podzielnik    : INTEGER;
    switchAble    : BOOLEAN;
    polaryzacjaOK : BOOLEAN;
    synResult     : INTEGER;
    dataOk        : okTab;
    archData      : BOOLEAN;
    offset        : INTEGER;


BEGIN (* main *)
  MANAGER.Assert( PA_PA.PomiarANieArchiwum );
  switchAble := FALSE;
  mainState := InspekcjaMS;
  archData := FALSE;
  LOOP
    CASE mainState OF
      InspekcjaMS :
        CASE InspekcjaEP() OF
          AbortIE :
            mainState := KoniecProgMS;
          |
          AkceptIE :
            SetLastPointToBeTraced( Lotnisko.Kategoria, TRUE );
            mainState := GlownyMS;
        END (* case InspekcjaEP *);
      |
      GlownyMS :
        archData := FALSE;
        polaryzacjaOK := FALSE;
        synResult  := SigNilVal;
        podzielnik := SigNilVal;
        GoHomeDir;
        CASE GlownyEP() OF
          AbortGE :
            mainState := KoniecProgMS;
          |
          AkceptGE :
            mainState := PomiarPrologMS;
          |
          DrukujGE :
            mainState := LadujDaneDoDrukMS;
          |
          TestGE :
            mainState := TestMS;
        END (* case GlownyEP *);
      |
      TestMS :
        ScannerI.Start(0, ElewANieAzym, LocationsTogether);
        PI_Qcheck.Sprawdz;   (* !!! ta procedura powinna zwracac wynik testu *)
        ScannerI.Stop;
        mainState := GlownyMS;
      |
      LadujDaneDoDrukMS :
        archData := TRUE;
        LoadData(dataOk);
        IF dataOk[Zestaw]
        THEN
          mainState := AnalizaMS;
        ELSE
          mainState := GlownyMS;
        END (* if dataOk *);
      |
      PomiarPrologMS :
        offset := SubAngle100(Angle100(Lotnisko.KierunekPasa), 18000);
        ScannerI.Start(offset, ElewANieAzym, LocationsTogether);
        InitPomiar(switchAble);
        mainState := PomiarMS;
      |
      PomiarMS :
        CASE PomiarEP(switchAble, Zestaw, polaryzacjaOK, synResult, podzielnik)
        OF
          AbortPE :
            mainState := GlownyMS;
            StopCPLoop;
            ScannerI.Stop;
          |
          ZakonczPE :
            mainState := AnalizaMS;
            StopCPLoop;
            ScannerI.Stop;
        END (* case PomiarEP *);
      |
      AnalizaMS :
        CASE AnalizaEP(switchAble,
                       archData,
                       Zestaw,
                       GlownyOdbiornik,
                       pbTeodolit)
        OF
          AbortAE :
            mainState := GlownyMS;
          |
          DrukujAE :
            mainState := DrukujMS;
          |
          ZakonczAE :
            G_Files.KopiujWszystkiePliki(SciezkaOpisuPomiaru);
            Zapisz(polaryzacjaOK, synResult, podzielnik);
            mainState := GlownyMS;
        END (* case AnalizaEP *);
      |
      DrukujMS :
        Druk(Zestaw);
        mainState := AnalizaMS;
      |
      KoniecProgMS :
        Tune.TurnOffVOR_ILS(Tune.AReceiver);
        Tune.TurnOffVOR_ILS(Tune.BReceiver);
        EXIT;
    END (* case mainState *);
  END (* loop *);
  Terminate(Normal);
END PG.
