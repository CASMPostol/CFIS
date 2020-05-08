(*.F- *)
(**********************************************************************
|  Title   : Program pomiaru VORa trasowego
|  Author  : M.Morawski
|  System  : LOGITECH MODULA-2/86
|  History :
|    15-12-96: M.Postol
|      zmiana def Start ze wzgledu na VOR'a trasowego
|    29-01-97: M.Postol
|      zmiany w zwiazku w wprowadzeniem podzielnik
|    25-02-97: M.Postol
|      Kopiowanie pliku jest realizowane zawsze po wcisnieciu klawisza Accept
|    12-05-97: M.Postol
|      nowa def w ScannerI
|
|  Copyright (C), CAS LODZ POLAND.
|  TEL: 42' 862 547, 42' 87 80 44 FAX/TEL: 42' 84 48 40
|
**********************************************************************)
(*.F+ *)

MODULE PT;

  IMPORT
    DebugPMD, MANAGER, PI_PA, DOSEntry, ErrorMess;

  IMPORT
    Tune, PI_Qcheck, ScannerI, V_Files, D_Files;

  FROM PI_Glowny IMPORT
    GlownyEP;

  FROM T_Oblot IMPORT
    (* PROCEDURE *) Zapisz;

  FROM T_Inspekcja  IMPORT
    InspekcjaEvent, InspekcjaEP;

  FROM CommonData IMPORT
    SciezkaOpisuPomiaru;

  FROM Files IMPORT
    GoHomeDir;

  FROM V_CP_ControlProc IMPORT
    StopCPLoop;

  FROM CommonTypes IMPORT
    (* TYPE *) SigNilVal, OdnDlaPomOdlT, OdnDlaPomBleduT, GlownyOdbiornikT,
               glownyEvent;

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
    GPSAlfaOffset  = 0;
    AzymANieElew   = TRUE;
    LocationSpread = FALSE;

  VAR
    mainState     : ARRAY BOOLEAN OF MainStates;
    switchAble    : BOOLEAN;
    Zestaw        : BOOLEAN;
    polaryzacjaOK : ARRAY BOOLEAN OF BOOLEAN;
    podzielnik    : ARRAY BOOLEAN OF INTEGER;
    synResult     : ARRAY BOOLEAN OF INTEGER;
    dataOk        : okTab;
    archData      : BOOLEAN;

  PROCEDURE SwitchContext
            ( VAR Zestaw : BOOLEAN );

  BEGIN
    Zestaw := NOT Zestaw;
  END SwitchContext;

BEGIN (* main *)
  MANAGER.Assert( PI_PA.PomiarANieArchiwum );
  Zestaw := FALSE;
  switchAble := FALSE;
  mainState[FALSE] := InspekcjaMS;
  mainState[TRUE] := InspekcjaMS;
  archData := FALSE;
  LOOP
    CASE mainState[Zestaw] OF
      InspekcjaMS :
        CASE InspekcjaEP( ) OF
          AbortIE :
            mainState[Zestaw] := KoniecProgMS;
          |
          AkceptIE :
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
            mainState[Zestaw] := PomiarPrologMS;
          |
          DrukujGE :
            mainState[Zestaw] := LadujDaneDoDrukMS;
          |
          TestGE :
            mainState[Zestaw] := TestMS;
        END (* case GlownyEP *);
      |
      TestMS :
        ScannerI.Start( GPSAlfaOffset, AzymANieElew, LocationSpread);
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
        ScannerI.Start(GPSAlfaOffset, AzymANieElew, LocationSpread);
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
                       goA,
                       pbGPS)
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
              V_Files.KopiujWszystkiePliki(SciezkaOpisuPomiaru);
              Zapisz( polaryzacjaOK[Zestaw], synResult[Zestaw], 
                      podzielnik[Zestaw]);
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
END PT.
