(*.F- *)
(**********************************************************************
|  Title   : Program archiwalny dla VORa
|  Author  : M.Morawski
|  System  : LOGITECH MODULA-2/86
|  History :
|    29-01-97: M.Postol
|      zmiany w zwiazku w wprowadzeniem podzielnika
|    12-05-97: M.Postol
|      zmiana nazwy modulu D_Report
|      wywalilem Tune
|
|  Copyright (C), CAS LODZ POLAND.
|  TEL: 42' 862 547, 42' 87 80 44 FAX/TEL: 42' 84 48 40
|
**********************************************************************)
(*.F+ *)

MODULE AV;

  IMPORT
    FCBS, DebugPMD, DOSEntry, MANAGER, ErrorMess, V_results, Strings,
    V_Files, D_Files, ZoomInterface, PrintScreen, D_Report;

  FROM PA_PA IMPORT
    PomiarANieArchiwum;

  FROM PI_Glowny IMPORT
    GlownyEP;

  FROM V_CommonTypes IMPORT
    ProceduraT, Procedura;

  FROM V_Oblot IMPORT
    InitOblot, Zapisz;

  FROM CommonData IMPORT
    OdnDlaPomOdl, OdnDlaPomBledu, SciezkaOpisuPomiaru, CisnienieOdniesienia,
    Predkosc, GlownyOdbiornik, Promien, Orbita;

  FROM Files IMPORT
    GoHomeDir;

  FROM V_CP_ControlProc IMPORT
    StopCPLoop;

  FROM CommonTypes IMPORT
    (* TYPE *) glownyEvent, SigNilVal;

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

  FROM PI_Report IMPORT
    RaportKoncowy;

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
    GPSAlfaOffset = 0;
    AzymANieElew  = TRUE;

  VAR
    mainState     : ARRAY BOOLEAN OF MainStates;
    switchAble    : BOOLEAN;
    Zestaw        : BOOLEAN;
    polaryzacjaOK : ARRAY BOOLEAN OF BOOLEAN;
    podzielnik    : ARRAY BOOLEAN OF INTEGER;
    synResult     : ARRAY BOOLEAN OF INTEGER;
    dataOk        : okTab;

  PROCEDURE InspekcjaEP() : inspekcjaEvent;

  BEGIN
    IF InitOblot( )
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
  MANAGER.Assert( NOT PomiarANieArchiwum );
  Zestaw := FALSE;
  switchAble := FALSE;
  mainState[FALSE] := InspekcjaMS;
  mainState[TRUE] := InspekcjaMS;
  dataOk[FALSE] := TRUE;
  dataOk[TRUE] := TRUE;
  LOOP
    CASE mainState[Zestaw] OF
      InspekcjaMS :
        CASE InspekcjaEP() OF
          abortIE :
            mainState[Zestaw] := KoniecProgMS;
          |
          AkceptIE :
            mainState[Zestaw] := GlownyMS;
        END (* case InspekcjaEP *);
      |
      GlownyMS :
        Zestaw := FALSE;
        polaryzacjaOK[FALSE] := FALSE;
        polaryzacjaOK[TRUE] := FALSE;
        podzielnik[FALSE] := SigNilVal;
        podzielnik[TRUE] := SigNilVal;
        synResult[FALSE] := SigNilVal;
        synResult[TRUE] := SigNilVal;
        GoHomeDir;
        CASE GlownyEP(  ) OF
          AbortGE :
            mainState[Zestaw] := KoniecProgMS;
          |
          AkceptGE :
            HALT;
          |
          PlayGE:
            mainState[Zestaw] := PomiarPrologMS;
            LoadData(dataOk);
            Orbita := CARDINAL(V_results.anRes.PromienLubOrbita);
            Promien := CARDINAL(V_results.anRes.PromienLubOrbita);
            CisnienieOdniesienia := V_results.anRes.CisnienieOdniesienia;
            Predkosc := V_results.anRes.Predkosc;
            GlownyOdbiornik := V_results.anRes.GlownyOdbiornik;

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
        HALT;
      |
      LadujDaneDoDrukMS :
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
(*
        InitPomiar(switchAble);
        mainState[FALSE] := PomiarMS;
        IF switchAble
        THEN
          mainState[TRUE] := PomiarMS;
        ELSE
          mainState[TRUE] := GlownyMS;
        END (* if switchAble *);
*)
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
            END (* if switchAble *);
            IF switchAble AND (mainState[NOT Zestaw] = PomiarMS)
            THEN
              SwitchContext(Zestaw);
            END (* if switchAble *);
        END (* case PomiarEP *);
      |
      AnalizaMS :
        CASE AnalizaEP(switchAble,
                       TRUE, (*archData,*)
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
(*
            IF Zestaw
            THEN
              D_Files.KopiujWszystkiePliki(SciezkaOpisuPomiaru);
            ELSE
              Zapisz(polaryzacjaOK[Zestaw], synResult[Zestaw]);
              V_Files.KopiujWszystkiePliki(SciezkaOpisuPomiaru);
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
        EXIT;
    END (* case mainState *);
  END (* loop *);
  Terminate(Normal);
END AV.
