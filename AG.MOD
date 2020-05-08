(*.F- *)
(**********************************************************************
|  Title   : Program archiwalny GS
|  Author  : M.Morawski
|  System  : LOGITECH MODULA-2/86
|  History :
|    29-01-97: M.Postol
|      zmiany w zwiazku w wprowadzeniem podzielnika
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

MODULE AG;

  IMPORT
    DebugPMD, DOSEntry, MANAGER, PA_PA, ErrorMess, SimScanner, Strings,
    ILS_ZoneMngmnt, G_results;

  IMPORT
    Tune, PI_Qcheck, ScannerI, G_Files, ZoomInterface;

  FROM G_CommonTypes IMPORT
    Szer_sekt_kier;

  FROM PI_Glowny IMPORT
    GlownyEP;

  FROM G_Inspekcja  IMPORT
    InspekcjaEvent, InspekcjaEP;

  FROM G_Oblot IMPORT
    Zapisz;

  FROM CommonData IMPORT
     SciezkaOpisuPomiaru, OdnDlaPomOdl, GlownyOdbiornik, OdnDlaPomBledu;

  FROM Files IMPORT
    GoHomeDir;

  FROM G_CP_ControlProc IMPORT
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

  FROM L_DataBase  IMPORT
    Lotnisko;

  FROM SpecConv IMPORT
    SubAngle100, Angle100;

  FROM PI_Report IMPORT
    RaportKoncowy;

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
  MANAGER.Assert( NOT PA_PA.PomiarANieArchiwum );
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

            ILS_ZoneMngmnt.IdentPunktow := G_results.anRes.identPunktow;
            OdnDlaPomOdl := G_results.anRes.odnDlaPomOdl;
            OdnDlaPomBledu := pbTeodolit;
            Szer_sekt_kier := G_results.anRes.secWith;
          |
          PreviewGE:
            LoadData(dataOk);
            GoHomeDir;

            ZoomInterface.Show( dataOk[FALSE], dataOk[TRUE] );
          |
          RaportKoncowyGE:
            RaportKoncowy;
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
            G_Files.KopiujWszystkiePliki(SciezkaOpisuPomiaru);
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
END AG.
