(*.F- *)
(**********************************************************************
|  Title   : Program pomiaru LOC
|  Author  : M.Postol
|  System  : LOGITECH MODULA-2/86
|  History :
|    12-07-96 07:55pm: wersja oryginalna
|    29-03-97: M.Postol
|      inicjacja SetLastPointToBeTraced tylko w przypadku zaakceptowania
|      inspekcji
|    12-05-97: M.Postol
|      zmiana nazwy modulu D_Report
|      OdnDlaPomBledu bylo zawsze ustawiane jaw anRes dla danych Dynamicnych,
|      zupelnie nie potrzebnie
|
|  Copyright (C), CAS LODZ POLAND.
|  TEL: 42' 862 547, 42' 87 80 44 FAX/TEL: 42' 84 48 40
|
**********************************************************************)
(*.F+ *)

MODULE AL;

  IMPORT
    FCBS, DebugPMD, DOSEntry, MANAGER, PI_PA, ErrorMess, D_Report,
    SimScanner, Strings, CommonData, ILS_ZoneMngmnt;

  IMPORT
    Tune, PI_Qcheck, ScannerI, L_Files, D_Files, ZoomInterface,
    L_CommonTypes, L_results;

  FROM PI_Glowny IMPORT
    GlownyEP;

  FROM L_Oblot IMPORT
    (* PROCEDURE *) InitOblot, Zapisz;

  FROM CommonData IMPORT
    GlownyOdbiornik, OdnDlaPomOdl, OdnDlaPomBledu;

  FROM L_CommonTypes IMPORT
    Procedura, Odl_dla_pom_pB, Szer_sekt_kier;


  FROM Files IMPORT
    GoHomeDir;

  FROM L_CP_ControlProc IMPORT
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

  FROM PI_Report IMPORT
    RaportKoncowy;

  FROM ILS_ZoneMngmnt IMPORT
    SetLastPointToBeTraced;




  TYPE
    inspekcjaEvent =
      ( abortIE,
        AkceptIE );
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
    AzymANieElew = TRUE;
    LocationsTogether = TRUE;

  VAR
    mainState     : ARRAY BOOLEAN OF MainStates;
    switchAble    : BOOLEAN;
    Zestaw        : BOOLEAN;
    polaryzacjaOK : ARRAY BOOLEAN OF BOOLEAN;
    podzielnik    : ARRAY BOOLEAN OF INTEGER;
    synResult     : ARRAY BOOLEAN OF INTEGER;
    dataOk        : okTab;
    archData      : BOOLEAN;
    offset        : INTEGER;

  PROCEDURE InspekcjaEP() : inspekcjaEvent;

  BEGIN
    IF InitOblot()
    THEN
      RETURN AkceptIE;
    ELSE
      RETURN abortIE;
    END (* if InitOblot *);
  END InspekcjaEP;

  PROCEDURE SwitchContext
            ( VAR Zestaw : BOOLEAN );

  BEGIN
    Zestaw := NOT Zestaw;
  END SwitchContext;

BEGIN (* main *)
  MANAGER.Assert( NOT PI_PA.PomiarANieArchiwum );
  Zestaw := FALSE;
  switchAble := FALSE;
  mainState[FALSE] := InspekcjaMS;
  mainState[TRUE] := InspekcjaMS;
  archData := FALSE;
  LOOP
    CASE mainState[Zestaw] OF
      InspekcjaMS :
        CASE InspekcjaEP() OF
          abortIE :
            mainState[Zestaw] := KoniecProgMS;
          |
          AkceptIE :
            SetLastPointToBeTraced( Lotnisko.Kategoria, TRUE );
            mainState[Zestaw] := GlownyMS;
        END (* case InspekcjaEP *);
      |
      GlownyMS :
        archData := FALSE;
        Zestaw := FALSE;
        polaryzacjaOK[FALSE] := FALSE;
        polaryzacjaOK[TRUE] := FALSE;
        podzielnik[FALSE] := SigNilVal;
        podzielnik[TRUE] := SigNilVal;
        synResult[FALSE] := SigNilVal;
        synResult[TRUE] := SigNilVal;
        GoHomeDir;
        CASE GlownyEP( ) OF
          AbortGE :
            mainState[Zestaw] := KoniecProgMS;
          |
          AkceptGE :
            HALT;
          |
          PlayGE:
            mainState[Zestaw] := PomiarPrologMS;
            archData := TRUE;
            LoadData(dataOk);

            Odl_dla_pom_pB := L_results.anRes.Orbita;
            Szer_sekt_kier := L_results.anRes.secWith;
            ILS_ZoneMngmnt.IdentPunktow := L_results.anRes.identPunktow;
            OdnDlaPomOdl := L_results.anRes.odnDlaPomOdl;
            (* OdnDlaPomBledu := L_results.anRes.odnDlaPomBledu; *)

            GoHomeDir;
          |
          DrukujGE :
            mainState[Zestaw] := LadujDaneDoDrukMS;
          |
          TestGE :
            HALT;
          |
          PreviewGE:
            LoadData( dataOk );
            GoHomeDir;
            ZoomInterface.Show( dataOk[FALSE], dataOk[TRUE] );
          |
          RaportKoncowyGE:
            RaportKoncowy;
          |
          RaportKoncowy_DME_GE:
            D_Report.RaportKoncowy;
        END (* case GlownyEP *);
      |
      TestMS :
        ScannerI.Start(0, AzymANieElew, LocationsTogether);
        PI_Qcheck.Sprawdz;   (* !!! ta procedura powinna zwracac wynik testu *)
        ScannerI.Stop;
        mainState[Zestaw] := GlownyMS;
      |
      LadujDaneDoDrukMS :
        archData := TRUE;
        LoadData(dataOk);
        switchAble := FALSE;
        IF dataOk[FALSE] AND dataOk[TRUE]
        THEN
          Zestaw := FALSE;
          switchAble := TRUE;
          mainState[FALSE] := AnalizaMS;
          mainState[TRUE] := AnalizaMS;
        ELSIF dataOk[FALSE]
        THEN
          Zestaw := FALSE;
          mainState[FALSE] := AnalizaMS;
          mainState[TRUE] := GlownyMS;
        ELSE
          Zestaw := TRUE;
          mainState[FALSE] := GlownyMS;
          mainState[TRUE] := AnalizaMS;
        END (* if dataOk *);
      |
      PomiarPrologMS :
        offset := SubAngle100(Angle100(Lotnisko.KierunekPasa), 18000);
        ScannerI.Start(offset, AzymANieElew, LocationsTogether);
        InitPomiar(switchAble);
        switchAble := switchAble & dataOk[FALSE] & dataOk[TRUE];
        mainState[FALSE] := PomiarMS;
        IF switchAble
        THEN
          mainState[TRUE] := PomiarMS;
        ELSE
          IF dataOk[FALSE]
          THEN
            Zestaw := FALSE;
            mainState[FALSE] := PomiarMS;
            mainState[TRUE] := GlownyMS;
          ELSE
            Zestaw := TRUE;
            mainState[FALSE] := GlownyMS;
            mainState[TRUE] := PomiarMS;
          END (* if dataOk *);
        END (* if switchAble *);
      |
      PomiarMS :
        CASE PomiarEP(switchAble, Zestaw, polaryzacjaOK[Zestaw],
                      synResult[Zestaw], podzielnik[Zestaw])
        OF
          AbortPE :
            mainState[Zestaw] := GlownyMS;
            IF mainState[NOT Zestaw] <> PomiarMS
            THEN
              StopCPLoop;
              ScannerI.Stop;
            END (* if switchAble *);
            IF switchAble
            THEN
              switchAble := FALSE;
              SwitchContext(Zestaw);
            END (* if switchAble *);
          |
          SwitchPE :
            SwitchContext(Zestaw);
          |
          ZakonczPE :
            mainState[Zestaw] := AnalizaMS;
            IF mainState[NOT Zestaw] <> PomiarMS
            THEN
              StopCPLoop;
              ScannerI.Stop;
            END (* if switchAble *);
            IF switchAble AND (mainState[NOT Zestaw] = PomiarMS)
            THEN
              SwitchContext(Zestaw);
            END (* if switchAble *);
        END (* case PomiarEP *);
      |
      AnalizaMS :
        CASE AnalizaEP(switchAble,
                       archData,
                       Zestaw,
                       GlownyOdbiornik,
                       CommonData.OdnDlaPomBledu)
        OF
          AbortAE :
            mainState[Zestaw] := GlownyMS;
            IF switchAble
            THEN
              switchAble := FALSE;
              SwitchContext(Zestaw);
            END (* if switchAble *);
          |
          SwitchAE :
            SwitchContext(Zestaw);
          |
          DrukujAE :
            mainState[Zestaw] := DrukujMS;
          |
          ZakonczAE :
(*
            IF Zestaw
            THEN
              D_Files.KopiujWszystkiePliki(SciezkaOpisuPomiaru);
            ELSE
              Zapisz(polaryzacjaOK[Zestaw], synResult[Zestaw]);
              L_Files.KopiujWszystkiePliki(SciezkaOpisuPomiaru);
            END (* if Zestaw *);
*)
            mainState[Zestaw] := GlownyMS;
            IF switchAble
            THEN
              switchAble := FALSE;
              SwitchContext(Zestaw);
            END (* if switchAble *);
        END (* case AnalizaEP *);
      |
      DrukujMS :
        LoadData( dataOk );
        Druk(Zestaw);
        GoHomeDir;
        mainState[Zestaw] := AnalizaMS;
      |
      KoniecProgMS :
        Tune.TurnOffVOR_ILS(Tune.AReceiver);
        Tune.TurnOffVOR_ILS(Tune.BReceiver);
        EXIT;
    END (* case mainState *);
  END (* loop *);
  Terminate(Normal);
END AL.
