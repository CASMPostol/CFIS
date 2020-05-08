(*.F- *)
(**********************************************************************
|  Title   : Program pomiaru LOC
|  Author  : M.Postol
|  System  : LOGITECH MODULA-2/86
|  History :
|    01.01.96: wersja oryginalna
|    Rel. 01 18.02.96: Mariusz Postol
|      Rozbicie na osobne moduly PV, VORPomiar, VORScreen
|      Bardzo duzo zmian
|    15-12-96: M.Postol
|      zmiana def ScannerI
|    27-01-97: M.Postol
|      modyfikacja w zwiazku z przekazywaniem precyzji
|    25-02-97: M.Postol
|      Kopiowanie pliku jest realizowane zawsze po wcisnieciu klawisza Accept
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

MODULE PL;

  IMPORT
    DebugPMD, DOSEntry, MANAGER, ErrorMess, PA_PA, Tune, PI_Qcheck,
    ScannerI, L_Files, D_Files;

  FROM PI_Glowny IMPORT
    GlownyEP;

  FROM CommonData IMPORT
    OdnDlaPomOdl, OdnDlaPomBledu, SciezkaOpisuPomiaru,
    (* VAR *) GlownyOdbiornik;

  FROM L_Oblot IMPORT
    (* PROCEDURE *) InitOblot, Zapisz;

  FROM Files IMPORT
    GoHomeDir;

  FROM L_CP_ControlProc IMPORT
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
    AzymANieElew      = TRUE;
    LocationsTogether = TRUE;

  VAR
    mainState     : ARRAY BOOLEAN OF MainStates;
    switchAble    : BOOLEAN;
    Zestaw        : BOOLEAN;
    polaryzacjaOK : ARRAY BOOLEAN OF BOOLEAN;
    synResult     : ARRAY BOOLEAN OF INTEGER;
    podzielnik    : ARRAY BOOLEAN OF INTEGER;
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
  MANAGER.Assert(PA_PA.PomiarANieArchiwum);
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
        synResult[FALSE] := SigNilVal;
        synResult[TRUE] := SigNilVal;
        podzielnik[FALSE] := SigNilVal;
        podzielnik[TRUE] := SigNilVal;
        GoHomeDir;
        CASE GlownyEP() OF
          AbortGE :
            mainState[Zestaw] := KoniecProgMS;
          |
          AkceptGE :
            mainState[Zestaw] := PomiarPrologMS;
            dataOk[FALSE] := TRUE;
            dataOk[TRUE] := TRUE;
          |
          DrukujGE :
            mainState[Zestaw] := LadujDaneDoDrukMS;
          |
          TestGE :
            mainState[Zestaw] := TestMS;
        END (* case GlownyEP *);
      |
      TestMS :
        ScannerI.Start(0, AzymANieElew,LocationsTogether);
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
        mainState[FALSE] := PomiarMS;
        IF switchAble
        THEN
          mainState[TRUE] := PomiarMS;
        ELSE
          mainState[TRUE] := GlownyMS;
        END (* if switchAble *);
      |
      PomiarMS :
        CASE PomiarEP(switchAble, Zestaw, polaryzacjaOK[Zestaw], synResult[
                      Zestaw], podzielnik[Zestaw]) OF
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
                       OdnDlaPomBledu) 
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
            IF Zestaw
            THEN
              D_Files.KopiujWszystkiePliki(SciezkaOpisuPomiaru);
            ELSE
              L_Files.KopiujWszystkiePliki(SciezkaOpisuPomiaru);
              Zapisz(polaryzacjaOK[Zestaw], synResult[Zestaw], podzielnik[Zestaw]);
            END (* if Zestaw *);
            mainState[Zestaw] := GlownyMS;
            IF switchAble
            THEN
              switchAble := FALSE;
              SwitchContext(Zestaw);
            END (* if switchAble *);
        END (* case AnalizaEP *);
      |
      DrukujMS :
        Druk(Zestaw);
        mainState[Zestaw] := AnalizaMS;
      |
      KoniecProgMS :
        Tune.TurnOffVOR_ILS(Tune.AReceiver);
        Tune.TurnOffVOR_ILS(Tune.BReceiver);
        EXIT;
    END (* case mainState *);
  END (* loop *);
  Terminate(Normal);
END PL.
