(*.F- *)
(**********************************************************************
|  Title   : Obsluga ekranu pomiarowego
|  Author  : M.POSTOL Na podstawie VOR.MOD
|  System  : LOGITECH MODULA-2/86
|  History :
|    16-12-96: M.Postol
|      zablokowalem przelaczanie pomiarow dla programow arch.
|    27-01-97: M.Postol
|      zmiany w zwiazku z przekazywaniem precyzji rezultatu
|    31-03-97: M.Postol
|      polskie litery
|
|  Copyright (C), CAS LODZ POLAND.
|  TEL: 42' 862 547, 42' 87 80 44 FAX/TEL: 42' 84 48 40
|
**********************************************************************)
(*.F+ *)

IMPLEMENTATION MODULE Pomiar;


  FROM SYSTEM IMPORT
    WORD;

  IMPORT
    ShortCuts, Screen;

  FROM PI_PA IMPORT
    PomiarANieArchiwum;

  FROM Screen IMPORT
    (* TYPE *) Term,
    (* PROCEDURE *) RedrawReqPT, RredrawMarksReqPT, SetButtons, Update, Init, 
                    ScreenStart;

  FROM GrafTypes IMPORT
    RECT, MoveRect;

  FROM Buttons IMPORT
    Button, CreateButton, ChangeButton, DisposeButton, EnableButton;

  FROM Timer IMPORT
    Wait, TInOneSecond;

  FROM MsgBox IMPORT
    Info;

  FROM ScannerI IMPORT
    RefAlfa, RefDis;

  FROM CommonTypes IMPORT
    SigNilVal, DisNilVal;

  TYPE
    buttonsEvent  =
      ( RestartBut,
        StartBut,
        StopBut,
        PageUPbut,
        PageDwnBut,
        KoniecBut,
        AnalizaBut,
        PolaryzacjaOnBut,
        PolaryzacjaOffBut,
        PrzelaczPomBut );
    PomiarStates  =
      ( PrologPS,
        RejestracjaPS,
        PolaryzacjaPS,
        ZatrzymaniePS );
    MyButtonSet   =
      SET OF buttonsEvent;
    proceduresDsc =
      RECORD
        Pstart          :
          PROC;
        Pinidata        :
          PROC;
        Pstop           :
          PROC;
        Prestart        :
          PROC;
        Pabort          :
          PROC;
        Predrawreq      :
          RedrawReqPT;
        Predrawmarksreq :
          RredrawMarksReqPT;
        ConsoleEv       :
          PROC;
        PAnaliza        :
          PAnalizaT;
        EtapPolV        :
          EtapPolVT;
      END;

  VAR
    ProcPom         : ARRAY BOOLEAN OF proceduresDsc;
    EtapPolaryzacji : ARRAY BOOLEAN OF INTEGER;
    StanButtonow    : ARRAY BOOLEAN OF BITSET;
    currButtonSet   : MyButtonSet;
    B_01            : Button;  (* RESTART, POL-V, JU½, Lewo, Zero, Prawo,
                                  KONIEC *)
    B_02            : Button;  (* START *)
    B_03            : Button;  (* STOP, DRUKUJ *)
    B_04            : Button;  (* ANALIZA, AKCEPT *)
    B_05            : Button;  (* WYJ—CIE, KONIEC *)
    NapisB_01       : ARRAY [0 .. 6] OF CHAR;
    StanZestawu     : ARRAY BOOLEAN OF PomiarStates;
    frstBut         : ARRAY BOOLEAN OF frstButState;
    katPromien      : WORD;
    promien         : BOOLEAN;
    format360       : ARRAY BOOLEAN OF BOOLEAN;
    distOff         : ARRAY BOOLEAN OF CARDINAL;
    alfaOff         : ARRAY BOOLEAN OF REAL;
    currZestaw      : BOOLEAN;
    dataInBuff      : ARRAY BOOLEAN OF BOOLEAN;

  PROCEDURE StartBP;

  BEGIN
    INCL(currButtonSet, StartBut);
  END StartBP;

  PROCEDURE RestartBP;

  BEGIN
    INCL(currButtonSet, RestartBut);
  END RestartBP;

  PROCEDURE AbortBP;

  BEGIN
    INCL(currButtonSet, KoniecBut);
  END AbortBP;

  PROCEDURE CallStopButton(  );
    BEGIN
      StopBP;
    END CallStopButton;


  PROCEDURE StopBP;

  BEGIN
    INCL(currButtonSet, StopBut);
  END StopBP;

  PROCEDURE PrzelaczPomiaryBP;

  BEGIN
    INCL(currButtonSet, PrzelaczPomBut);
  END PrzelaczPomiaryBP;

  PROCEDURE AkceptacjaBP;

  BEGIN
    INCL(currButtonSet, AnalizaBut);
  END AkceptacjaBP;

  PROCEDURE PolaryzacjaBP;

    PROCEDURE Sek2;

    BEGIN
      ChangeButton(B_01, "CZEKAJ", -1);
      ProcPom[currZestaw].EtapPolV(EtapPolaryzacji[currZestaw] + 10);
    END Sek2;

  BEGIN (* PolaryzacjaBP *)
    IF EtapPolaryzacji[currZestaw] > 4
    THEN
      RETURN;
    END (* if EtapPolaryzacji *);
    IF EtapPolaryzacji[currZestaw] = 0
    THEN
      INCL(currButtonSet, PolaryzacjaOnBut);
      Sek2;
      ChangeButton(B_01, "LEWO", -1);
    ELSIF EtapPolaryzacji[currZestaw] = 1
    THEN
      Sek2;
      ChangeButton(B_01, "ZERO", -1);
    ELSIF EtapPolaryzacji[currZestaw] = 2
    THEN
      Sek2;
      ChangeButton(B_01, "PRAWO", -1);
    ELSIF EtapPolaryzacji[currZestaw] = 3
    THEN
      Sek2;
      ChangeButton(B_01, "KONIEC", -1);
    ELSIF EtapPolaryzacji[currZestaw] = 4
    THEN
      INCL(currButtonSet, PolaryzacjaOffBut);
      Sek2;
      NapisB_01 := "-----";
      ChangeButton(B_01, NapisB_01, -1);
    END (* if EtapPolaryzacji *);
    INC(EtapPolaryzacji[currZestaw]);
  END PolaryzacjaBP;

  (* *********************** Menu *********************************)

  PROCEDURE InitPomiar
            (    currfrstBut      : frstButState;
                 radNoOrbit       : BOOLEAN;
                 currkatPromien   : WORD;
                 currFormat360    : BOOLEAN;
                 currDistOff      : CARDINAL;
                 currAlfaOff      : REAL;
                 Pomiar           : BOOLEAN;
                 P_Start          : PROC;
                 P_Inidata        : PROC;
                 P_Stop           : PROC;
                 P_Restart        : PROC;
                 P_Abort          : PROC;
                 P_Redrawreq      : RedrawReqPT;
                 P_Redrawmarksreq : RredrawMarksReqPT;
                 P_ConsoleEv      : PROC;
                 P_Analiza        : PAnalizaT;
                 P_EtapPolV       : EtapPolVT         );

  BEGIN (* InitPomiar *)
    frstBut[Pomiar] := currfrstBut;
    promien := radNoOrbit;
    katPromien := currkatPromien;
    format360[Pomiar] := currFormat360;
    distOff[Pomiar] := currDistOff;
    alfaOff[Pomiar] := currAlfaOff;
    WITH ProcPom[Pomiar] DO
      Pinidata := P_Inidata;
      Pstart := P_Start;
      Pstop := P_Stop;
      Prestart := P_Restart;
      Pabort := P_Abort;
      Predrawreq := P_Redrawreq;
      Predrawmarksreq := P_Redrawmarksreq;
      ConsoleEv := P_ConsoleEv;
      PAnaliza := P_Analiza;
      EtapPolV := P_EtapPolV
    END (* with ProcPom *);
    EtapPolaryzacji[Pomiar] := 0;
    StanButtonow[Pomiar] := {1, 4};
    currButtonSet := MyButtonSet {};
    StanZestawu[Pomiar] := PrologPS;
    ProcPom[Pomiar].Pinidata;
    dataInBuff[Pomiar] := FALSE;
  END InitPomiar;

  PROCEDURE PomiarEP
            (     switcxhAble   : BOOLEAN;
                  zestaw        : BOOLEAN;
              VAR polaryzacjaOK : BOOLEAN;
              VAR synResult     : INTEGER;
              VAR Podzielnik    : INTEGER ) : pomiarEvent;

  TYPE
    Event =
      ( Time1sPE,
        Time0_3sPE,
        RestartPE,
        StartPE,
        StopPE,
        AnalizaPE,
        KoniecPE,
        PolaryzacjaOnPE,
        PolaryzacjaOffPE,
        PrzelaczPomPE );
  VAR
    result      : pomiarEvent;
    timeCounter : CARDINAL;
    B_XCHG      : Button;
    State       : PomiarStates;
    lastEvent   : Event;
    exit        : BOOLEAN;

    PROCEDURE PoprawnieUstawButtony
              (    stan : BITSET );

    BEGIN
      StanButtonow[zestaw] := stan;
      EnableButton(B_01, 0 IN stan);
      EnableButton(B_02, 1 IN stan);
      EnableButton(B_03, 2 IN stan);
      EnableButton(B_04, 3 IN stan);
      EnableButton(B_05, 4 IN stan);
      IF 5 IN stan
      THEN
        SetButtons(TRUE);
      ELSE
        SetButtons(FALSE);
      END (* if *);
    END PoprawnieUstawButtony;

    PROCEDURE GetEvent() : Event;
    VAR
      currResult : Event;

    TYPE
      TimePhase =
        ( ZadnaTP,
          JednaSekTP,
          JednaTrzeciaSekTP );

      PROCEDURE NastepnyStan() : TimePhase;

      BEGIN
        Wait(TInOneSecond() DIV 30);   (* to dziala szybciej aby byla szybka
                                          reakcja na przyciski wykresow *)
        INC(timeCounter);
        timeCounter := timeCounter MOD 30;
        IF timeCounter = 0
        THEN
          RETURN JednaSekTP;
        ELSIF timeCounter = 10
        THEN
          RETURN JednaTrzeciaSekTP;
        ELSE
          RETURN ZadnaTP;
        END (* if timeCounter *);
      END NastepnyStan;

    BEGIN (* GetEvent *)
      LOOP
        IF currButtonSet # MyButtonSet {}
        THEN
          IF RestartBut IN currButtonSet
          THEN
            EXCL(currButtonSet, RestartBut);
            currResult := RestartPE;
            EXIT;
          ELSIF StartBut IN currButtonSet
          THEN
            EXCL(currButtonSet, StartBut);
            currResult := StartPE;
            EXIT;
          ELSIF StopBut IN currButtonSet
          THEN
            EXCL(currButtonSet, StopBut);
            currResult := StopPE;
            EXIT;
          ELSIF PageUPbut IN currButtonSet
          THEN
            EXCL(currButtonSet, PageUPbut);
          ELSIF PageDwnBut IN currButtonSet
          THEN
            EXCL(currButtonSet, PageDwnBut);
          ELSIF KoniecBut IN currButtonSet
          THEN
            EXCL(currButtonSet, KoniecBut);
            currResult := KoniecPE;
            EXIT;
          ELSIF AnalizaBut IN currButtonSet
          THEN
            EXCL(currButtonSet, AnalizaBut);
            currResult := AnalizaPE;
            EXIT;
          ELSIF PolaryzacjaOnBut IN currButtonSet
          THEN
            EXCL(currButtonSet, PolaryzacjaOnBut);
            currResult := PolaryzacjaOnPE;
            EXIT;
          ELSIF PolaryzacjaOnBut IN currButtonSet
          THEN
            EXCL(currButtonSet, PolaryzacjaOnBut);
            currResult := PolaryzacjaOnPE;
            EXIT;
          ELSIF PolaryzacjaOffBut IN currButtonSet
          THEN
            EXCL(currButtonSet, PolaryzacjaOffBut);
            currResult := PolaryzacjaOffPE;
            EXIT;
          ELSIF PrzelaczPomBut IN currButtonSet
          THEN
            EXCL(currButtonSet, PrzelaczPomBut);
            currResult := PrzelaczPomPE;
            EXIT;
          END (* if RestartBut *);
        END (* if currButtonSet *);
        CASE NastepnyStan() OF
          ZadnaTP :
          |
          JednaSekTP :
            currResult := Time1sPE;
            EXIT;
          |
          JednaTrzeciaSekTP :
            currResult := Time0_3sPE;
            EXIT;
        END (* case NastepnyStan *);
      END (* loop *);
      RETURN currResult;
    END GetEvent;

    PROCEDURE InitButtony
              (    frstBut : frstButState );
    VAR
      r : RECT;

    BEGIN
      r.top := 19;
      r.bottom := 40;
      r.left := 0;
      r.right := 71;
      CASE frstBut OF
        PolFBS :
          NapisB_01 := ' POL-V ';
          B_01 := CreateButton(r, NapisB_01, 1, ShortCuts.kbAltP, PolaryzacjaBP
                  );
        |
        RestartFBS :
          NapisB_01 := "RESTART";
          B_01 := CreateButton(r, NapisB_01, 0, ShortCuts.kbAltR, RestartBP);
        |
        NoactiveFBS :
          NapisB_01 := "-------";
          B_01 := CreateButton(r, NapisB_01, 0, ShortCuts.kbAltR, RestartBP);
      END (* case frstBut *);
      MoveRect(r, +66 + 20, 0);
      B_02 := CreateButton(r, "START", 0, ShortCuts.kbAltS, StartBP);
      MoveRect(r, +66 + 20, 0);
      B_03 := CreateButton(r, "STOP", 1, ShortCuts.kbAltT, StopBP);
      MoveRect(r, +66 + 20, 0);
      B_04 := CreateButton(r, "ANALIZA", 0, ShortCuts.kbAltA, AkceptacjaBP);
      MoveRect(r, +66 + 20, 0);
      B_05 := CreateButton(r, "WYJ—CIE", 0, ShortCuts.kbAltW, AbortBP);
      MoveRect(r, +66 + 20, 0);
      IF switcxhAble
      THEN
        IF NOT zestaw
        THEN   (* jest DME *)
          B_XCHG := CreateButton(r, "D M E", 2, ShortCuts.kbAltM,
                                 PrzelaczPomiaryBP);
        ELSE
          B_XCHG := CreateButton(r, "N A V", 0, ShortCuts.kbAltN,
                                 PrzelaczPomiaryBP);
        END (* if Zestaw *);
      END (* if switcxhAble *);
      currButtonSet := MyButtonSet {};
    END InitButtony;

    PROCEDURE Done;

      PROCEDURE DisposeButtons;

      BEGIN
        DisposeButton(B_01);
        DisposeButton(B_02);
        DisposeButton(B_03);
        DisposeButton(B_04);
        DisposeButton(B_05);
        IF switcxhAble
        THEN
          DisposeButton(B_XCHG)
        END (* if switcxhAble *);
      END DisposeButtons;

    BEGIN
      DisposeButtons;
      Screen.Done;
    END Done;

    PROCEDURE AlfaRefInfo() : BOOLEAN;

    BEGIN
      IF (RefAlfa = SigNilVal) AND PomiarANieArchiwum
      THEN
        RETURN Info("Nie ma pomiaru k¥ta - kontunuowa† ?!")
      END (* if RefAlfa *);
      RETURN TRUE
    END AlfaRefInfo;

    PROCEDURE DeltaRefInfo() : BOOLEAN;

    BEGIN
      IF (RefDis = DisNilVal) AND PomiarANieArchiwum
      THEN
        RETURN Info("Nie ma pomiaru odlegˆo˜ci - kontunuowa† ?!")
      END (* if RefDis *);
      RETURN TRUE
    END DeltaRefInfo;

    PROCEDURE DataLosInfo() : BOOLEAN;

    BEGIN
      RETURN NOT PomiarANieArchiwum OR
             Info("Jeste˜ pewien, ¾e chcesz usun¥† dane?") AND
             Info("Dane zostan¥ usuni©te...")
    END DataLosInfo;

    PROCEDURE PrologAnalyse
              (     lastEvent : Event;
                VAR result    : pomiarEvent;
                VAR exit      : BOOLEAN;
                VAR State     : PomiarStates );

    BEGIN
      CASE lastEvent OF
        Time1sPE :
          Update(Long);
        |
        Time0_3sPE :
          Update(Short);
        |
        StartPE :
          IF NOT AlfaRefInfo()
          THEN
            ProcPom[zestaw].Pabort;
            result := AbortPE;
            exit := TRUE;
          ELSIF NOT DeltaRefInfo()
          THEN
            ProcPom[zestaw].Pabort;
            result := AbortPE;
            exit := TRUE;
          ELSE
            IF switcxhAble AND NOT PomiarANieArchiwum THEN
              EnableButton(B_XCHG, FALSE);
            END;
            Update(Redraw);
            dataInBuff[zestaw] := TRUE;
            CASE frstBut[zestaw] OF
              PolFBS :
                PoprawnieUstawButtony(BITSET {0, 2, 5});
              |
              RestartFBS :
                PoprawnieUstawButtony(BITSET {2, 5});
              |
              NoactiveFBS :
                PoprawnieUstawButtony(BITSET {2, 5});
            END (* case frstBut *);
            ProcPom[zestaw].Pstart;
            State := RejestracjaPS;
          END (* if *);
        |
        KoniecPE :
          ProcPom[zestaw].Pabort;
          result := AbortPE;
          exit := TRUE;
        |
        PrzelaczPomPE :
          result := SwitchPE;
          exit := TRUE;
      ELSE
      END (* case lastEvent *);
    END PrologAnalyse;

  BEGIN (* PomiarEP *)
    currZestaw := zestaw;
    exit := FALSE;
    Init(zestaw, ProcPom[zestaw].Predrawreq, ProcPom[zestaw].Predrawmarksreq,
         ProcPom[zestaw].ConsoleEv, promien, katPromien, distOff[zestaw],
         alfaOff[zestaw], format360[zestaw]);
    State := StanZestawu[zestaw];
    timeCounter := 0;
    InitButtony(frstBut[zestaw]);;
    PoprawnieUstawButtony(StanButtonow[zestaw]);
    LOOP
      lastEvent := GetEvent();
      CASE State OF
        PrologPS :
          PrologAnalyse(lastEvent, result, exit, State)
        |
        RejestracjaPS :
          CASE lastEvent OF
            Time1sPE :
              Update(Long);
            |
            Time0_3sPE :
              Update(Short);
            |
            StopPE :
              ProcPom[zestaw].Pstop;
              CASE frstBut[zestaw] OF
                PolFBS, NoactiveFBS:
                  IF PomiarANieArchiwum  THEN
                    PoprawnieUstawButtony(BITSET {1, 3, 4, 5});
                  ELSE
                    PoprawnieUstawButtony(BITSET {1, 3, 5});
                  END;
                |
                RestartFBS :
                  IF PomiarANieArchiwum  THEN
                    PoprawnieUstawButtony(BITSET {0, 1, 3, 4, 5});
                  ELSE
                    PoprawnieUstawButtony(BITSET {0, 1, 3, 5});
                  END;
              END (* case frstBut *);
              State := ZatrzymaniePS;
            |
            KoniecPE :
            |
            AnalizaPE :
            |
            PolaryzacjaOnPE :
              IF switcxhAble
              THEN
                EnableButton(B_XCHG, FALSE);
              END (* if switcxhAble *);
              EnableButton(B_03, FALSE);   (* stop *)
              State := PolaryzacjaPS;
            |
            PrzelaczPomPE :
              result := SwitchPE;
              exit := TRUE;
          ELSE
          END (* case lastEvent *);
        |
        PolaryzacjaPS :
          CASE lastEvent OF
            Time1sPE :
              Update(Long);
            |
            Time0_3sPE :
              Update(Short);
            |
            PolaryzacjaOffPE :
              PoprawnieUstawButtony(BITSET {2, 5});
              IF switcxhAble
              THEN
                EnableButton(B_XCHG, TRUE);
              END (* if switcxhAble *);
              State := RejestracjaPS;
          ELSE
          END (* case lastEvent *);
        |
        ZatrzymaniePS :
          CASE lastEvent OF
            Time1sPE :
              Update(Long);
            |
            Time0_3sPE :
              Update(Short);
            |
            RestartPE :
              ProcPom[zestaw].Prestart;
              Update(Redraw);
              CASE frstBut[zestaw] OF
                PolFBS :
                  PoprawnieUstawButtony(BITSET {0, 2, 5});
                |
                RestartFBS :
                  PoprawnieUstawButtony(BITSET {2, 5});
                |
                NoactiveFBS :
                  PoprawnieUstawButtony(BITSET {2, 5});
              END (* case frstBut *);
              State := RejestracjaPS;
            |
            KoniecPE :
              IF DataLosInfo()
              THEN
                ProcPom[zestaw].Pabort;
                result := AbortPE;
                exit := TRUE;
              END (* if Info *);
            |
            AnalizaPE :
              WITH ProcPom[zestaw] DO
                Pabort;
                PoprawnieUstawButtony(BITSET {});
                PAnaliza(synResult, Podzielnik);
              END (* with ProcPom *);
              result := ZakonczPE;
              exit := TRUE;
            |
            PrzelaczPomPE :
              result := SwitchPE;
              exit := TRUE;
            |
            StartPE :
              IF dataInBuff[zestaw] AND DataLosInfo()
              THEN
                ProcPom[zestaw].Pstart;
                Update(Redraw);
                CASE frstBut[zestaw] OF
                  PolFBS :
                    PoprawnieUstawButtony(BITSET {0, 2, 5});
                  |
                  RestartFBS :
                    PoprawnieUstawButtony(BITSET {2, 5});
                  |
                  NoactiveFBS :
                    PoprawnieUstawButtony(BITSET {2, 5});
                END (* case frstBut *);
                State := RejestracjaPS;
              END (* if dataInBuff *);
              ScreenStart;
          ELSE
          END (* case lastEvent *);
      END (* case State *);
      IF exit
      THEN
        EXIT;
      END (* if exit *);
    END (* loop *);
    StanZestawu[zestaw] := State;
    Done;
    polaryzacjaOK := EtapPolaryzacji[zestaw] > 4;
    RETURN result;
  END PomiarEP;

BEGIN
  EtapPolaryzacji[TRUE] := 0;
  EtapPolaryzacji[FALSE] := 0;
  B_01 := Button(NIL);
  B_02 := Button(NIL);
  B_03 := Button(NIL);
  B_04 := Button(NIL);
  B_05 := Button(NIL);
  StanButtonow[FALSE] := BITSET {};
  StanButtonow[TRUE] := BITSET {};
END Pomiar.
