(*.F- *)
(**********************************************************************
|  Title   : Program pomiaru NDB
|  Author  : M.Postol
|  System  : LOGITECH MODULA-2/86
|  History :
|    31-03-97: M.Postol
|      dla raportu wlaczal DME
|    12-05-97: M.Postol
|      nowa def ScannerI
|
|  Copyright (C), CAS LODZ POLAND.
|  TEL: 42' 862 547, 42' 87 80 44 FAX/TEL: 42' 84 48 40
|
**********************************************************************)
(*.F+ *)

MODULE AN;

  IMPORT
    DebugPMD, DOSEntry, MANAGER, PI_PA, ErrorMess, SimScanner, Strings,
    N_Report;

  IMPORT
    Tune, PI_Qcheck, ScannerI, N_Files, ZoomInterface;

  FROM PI_Glowny IMPORT
    GlownyEP;

  FROM N_Inspekcja  IMPORT
    InspekcjaEvent, InspekcjaEP;

  FROM N_Oblot IMPORT
    Zapisz;

  FROM CommonData IMPORT
     SciezkaOpisuPomiaru, OdnDlaPomOdl, GlownyOdbiornik, Promien, Orbita;

  FROM N_results IMPORT
    anRes;

  FROM Files IMPORT
    GoHomeDir;

  FROM N_CP_ControlProc IMPORT
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

  FROM N_DataBase  IMPORT
    NadajnikNDB;

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
    Zestaw          = FALSE;
    AzymANieElew    = TRUE;
    ElewANieAzym    = NOT AzymANieElew;
    LocationsTogether = TRUE;
  VAR
    mainState     : MainStates;
    switchAble    : BOOLEAN;
    polaryzacjaOK : BOOLEAN;
    podzielnik    : INTEGER;
    synResult     : INTEGER;
    dataOk        : okTab;
    archData      : BOOLEAN;
    offset        : INTEGER;


BEGIN (* main *)
  MANAGER.Assert( NOT PI_PA.PomiarANieArchiwum );
  mainState := InspekcjaMS;
  switchAble := FALSE;
  archData := FALSE;
  LOOP
    CASE mainState OF
      InspekcjaMS :
        CASE InspekcjaEP() OF
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
        podzielnik := SigNilVal;
        synResult := SigNilVal;
        GoHomeDir;
        CASE GlownyEP( ) OF
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
          |
          PlayGE:
            mainState := PomiarPrologMS;
            archData := TRUE;
            LoadData(dataOk);
            GoHomeDir;

            Promien := CARDINAL(anRes.promienLubOrbita);
            Orbita  := INTEGER(anRes.promienLubOrbita);

          |
          PreviewGE:
            LoadData(dataOk);
            GoHomeDir;
            ZoomInterface.Show( dataOk[FALSE], dataOk[TRUE] );
          |
          RaportKoncowyGE:
            N_Report.RaportKoncowy;
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
        ScannerI.Start(0, AzymANieElew, LocationsTogether);
        InitPomiar(switchAble);
        mainState := PomiarMS;
      |
      PomiarMS :
        CASE PomiarEP(switchAble, Zestaw, polaryzacjaOK, synResult, podzielnik) OF
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
(*
            Zapisz(polaryzacjaOK, synResult);
            N_Files.KopiujWszystkiePliki(SciezkaOpisuPomiaru);
*)
            mainState := GlownyMS;
        END (* case AnalizaEP *);
      |
      DrukujMS :
        LoadData( dataOk );
        Druk(Zestaw);
        GoHomeDir;
        mainState := AnalizaMS;
      |
      KoniecProgMS :
        Tune.TurnOffVOR_ILS(Tune.AReceiver);
        Tune.TurnOffVOR_ILS(Tune.BReceiver);
        EXIT;
    END (* case mainState *);
  END (* loop *);
  Terminate(Normal);
END AN.
