(*.F- *)
(**********************************************************************
|  Title   : Program pomiaru VHF
|  Author  : M.Morawski
|  System  : LOGITECH MODULA-2/86
|  History :
|    08-12-96: M.Postol
|      nie ustawione switchAble przy danych archiwalnych.
|    15-12-96: M.Postol
|      zmiana definicji ScannerI.
|    25-02-97: M.Postol
|      Kopiowanie pliku jest realizowane zawsze po wcisnieciu klawisza Accept
|    12-05-97: M.Postol
|      nowa def ScannerI
|
|  Copyright (C), CAS LODZ POLAND.
|  TEL: 42' 862 547, 42' 87 80 44 FAX/TEL: 42' 84 48 40
|
**********************************************************************)
(*.F+ *)

MODULE PH;

  IMPORT
    DebugPMD, MANAGER, PI_PA, DOSEntry, ErrorMess;

  IMPORT
    Tune, PI_Qcheck, ScannerI, H_Files;

  FROM PI_Glowny IMPORT
    GlownyEP;

  FROM H_Inspekcja  IMPORT
    InspekcjaEvent, InspekcjaEP;

  FROM H_Oblot IMPORT
    (* PROCEDURE *) Zapisz;

  FROM CommonData IMPORT
    SciezkaOpisuPomiaru, GlownyOdbiornik, Promien;

  FROM Files IMPORT
    GoHomeDir;

  FROM H_CP_ControlProc IMPORT
    StopCPLoop;

  FROM CommonTypes IMPORT
    (* TYPE *) glownyEvent, SigNilVal, OdnDlaPomBleduT, OdnDlaPomOdlT;

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

  FROM H_DataBase  IMPORT
    NadajnikVHF;

  FROM SpecConv IMPORT
    SubAngle100, Angle100;

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
    LocationsTogether = TRUE;
  VAR
    mainState     : MainStates;
    switchAble    : BOOLEAN;
    podzielnik    : INTEGER;
    polaryzacjaOK : BOOLEAN;
    synResult     : INTEGER;
    dataOk        : okTab;
    archData      : BOOLEAN;
    offset        : INTEGER;


BEGIN (* main *)
  MANAGER.Assert( PI_PA.PomiarANieArchiwum );
  mainState := InspekcjaMS;
  archData := FALSE;
  LOOP
    CASE mainState OF
      InspekcjaMS :
        CASE InspekcjaEP( ) OF
          AbortIE :
            mainState := KoniecProgMS;
          |
          AkceptIE :
            mainState := GlownyMS;
        END (* case InspekcjaEP *);
      |
      GlownyMS :
        archData := FALSE;
        polaryzacjaOK := FALSE;
        synResult := SigNilVal;
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
        ScannerI.Start(0, AzymANieElew, LocationsTogether);
        PI_Qcheck.Sprawdz;   (* !!! ta procedura powinna zwracac wynik testu *)
        ScannerI.Stop;
        mainState := GlownyMS;
      |
      LadujDaneDoDrukMS :
        archData := TRUE;
        LoadData(dataOk);
        switchAble := FALSE;
        IF dataOk[Zestaw]
        THEN
          mainState := AnalizaMS;
        ELSE
          mainState := GlownyMS;
        END (* if dataOk *);
      |
      PomiarPrologMS :
        ScannerI.Start( 0, AzymANieElew, LocationsTogether);
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
            H_Files.KopiujWszystkiePliki(SciezkaOpisuPomiaru);
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
END PH.
