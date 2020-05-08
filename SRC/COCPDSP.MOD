(*.F- *)
(**********************************************************************
|  Title   : Sterowanie wyswietlaczem pilotow.
|  Author  : M.Postol
|  System  : LOGITECH MODULA-2/86
|  History :
|    Rel. 001 27.04.96: new
|    Rel. 002 01.10.96: M.Postol
|      poniewaz nie ma pewnosci, ze dane dotra do modulow sterujacych, 
|      co MaxFlgCount falgi sa ustawiane bezwzglednie oraz w trybie Idle 
|      wskaznik jest wysterowywany co 2 s.
|   06-02-97: M.Postol
|     jesli skala jest MAX(CARDINAL) to odpowiednia strzalka nie dziala
|     ze wzgledu na klopoty z czase w kanale DGH wyswietlacz i wskazniki CP
|     sa sterowane naprzemiennie.
|   Rel: 3.16: MPOstol
|     Procesy sa startowane tylko dla wersji pomiarowej
|
|  Copyright (C), CAS LODZ POLAND.
|  TEL: 42' 86 58 12, 42' 87 80 44 FAX/TEL: 42' 84 48 40
|
**********************************************************************)
(*.F+ *)

IMPLEMENTATION MODULE CocpDsp [ 0 ];

  FROM MANAGER IMPORT
    STARTPROCESS, Condition, InitC, WAITC, Notify;

  FROM DGHInterface IMPORT
    SetMessage, SetAnalogVal, DtaSignType, Number;

  FROM DGHIni IMPORT
    CockpitCPLOCNeedle, CockpitCPGSNeedle, ConsoleCPLOCNeedle,
    ConsoleCPGSNeedle;

  FROM Tune IMPORT
    SetCPFlags;

  FROM CommonTypes IMPORT
    NilValI;
  
  FROM Timer  IMPORT
    Wait, TInOneSecond;
  
  FROM PA_PA IMPORT
    PomiarANieArchiwum;
    
  CONST
    iloscPolCP              = 50;
    SrodekSkaliCP           = 5000;
    ZakresCP                = 3800;
    WzmocnienieCP           = ZakresCP DIV iloscPolCP;
    StdIloscStrzal          = 5;
    IloscKomunikatowDlaProc = StdIloscStrzal * 2 + 1 + 1;
        (* dodatkowy komunikat na srodek Skali dla zerowego bledu i
           srodekSkali- StdIloscStrzal-1 dla braku danych *)
    VORSrodekSkali          = 6;
    ILS_P_SrodekSkali       = 18;
    ILS_POfse_SrodekSkali   = 42;
    ILS_Kat_SrodekSkali     = 66;
    ILS_GS_SrodekSkali      = 72;
    ILS_GSOfse_SrodekSkali  = 74;
    ILS_GSElew_SrodekSkali  = 78; (* sztuczne przesuniecie bo 1 strzalka *)
    LewaLiczPCyf            = 1;
    PrawaLiczPCyf           = 5;
    StartMsg                = 198;
    MaxFlgCount             = 10; (* co ile beda przestawiane flagi wskaznika 
                                     bezwzglednir
                                   *)
  VAR
    currGSflg   : BOOLEAN;
    currNAVflg  : BOOLEAN;
    currFROMflg : BOOLEAN;
    currTOflg   : BOOLEAN;
    dirCP       : INTEGER;
    dirWP       : INTEGER;
    SkalaCP     : CARDINAL;
    Skala       : CARDINAL;
    SkalaCPMax  : CARDINAL;
    SkalaWPMax  : CARDINAL;
    srodekSkali : CARDINAL;
    iloscStrzal : CARDINAL;
    currState   : State;
    currLNumber : INTEGER;
    currRNumber : INTEGER;
    currErrorCP : INTEGER;
    currErrorWP : INTEGER;
    currErrorGS : INTEGER;
    newState    : Condition;
    dtaSign     : DtaSignType;
    force       : BOOLEAN;
    currMsg     : CARDINAL;

  PROCEDURE UstawFormat
            (    format      : State;
                 nowaSkalaWP : CARDINAL;
                 nowaSkalaCP : CARDINAL );

  BEGIN
    currState := format;
    SkalaCP := nowaSkalaCP DIV iloscPolCP;
    SkalaWPMax := nowaSkalaWP;
    SkalaCPMax := nowaSkalaCP;
    UstawZmienne(NilValI, NilValI, NilValI, NilValI);
    CASE format OF
      Idle :
        force := TRUE;
        currGSflg := FALSE;
        currNAVflg := FALSE;
        currTOflg := FALSE;
        currFROMflg := FALSE;
        dirCP := 0;
        dirWP := 0;
      |
      VORKatTO, VORKatFROM :
        currNAVflg := TRUE;
        IF format = VORKatTO
        THEN
          currTOflg := TRUE;
          currFROMflg := FALSE;
          dirCP := 1;
        ELSE
          currFROMflg := TRUE;
          currTOflg := FALSE;
          dirCP := -1;
        END (* if format *);
        dirWP := dirCP;
        srodekSkali := VORSrodekSkali;
        iloscStrzal := StdIloscStrzal;
        Skala := nowaSkalaWP DIV iloscStrzal;
      |
      VOROdlegloscRgh, VOROdlegloscLft :
        currNAVflg := TRUE;
        IF format = VOROdlegloscRgh
        THEN
          dirCP := 1;
        ELSE
          dirCP := -1;
        END (* if format *);
        dirWP := dirCP;
        srodekSkali := VORSrodekSkali;
        iloscStrzal := StdIloscStrzal;
        Skala := nowaSkalaWP DIV iloscStrzal;
      |
      LOCOdlegloscRgh, LOCOdlegloscLft :
        currNAVflg := TRUE;
        IF format = LOCOdlegloscRgh
        THEN
          dirCP := 1;
        ELSE
          dirCP := -1;
        END (* if format *);
        dirWP := dirCP;
        srodekSkali := ILS_Kat_SrodekSkali;
        iloscStrzal := StdIloscStrzal;
        Skala := nowaSkalaWP DIV iloscStrzal;
      |
      LOCPrad, LOCPradOffset :
        currGSflg := TRUE;
        currNAVflg := TRUE;
        dirCP := 1;
        dirWP := dirCP;
        IF format = LOCPrad
        THEN
          srodekSkali := ILS_P_SrodekSkali;
        ELSE
          srodekSkali := ILS_POfse_SrodekSkali;
        END (* if format *);
        iloscStrzal := StdIloscStrzal;
        Skala := nowaSkalaWP DIV iloscStrzal;
      |
      GS :
        currGSflg := TRUE;
        currNAVflg := TRUE;
        dirCP := 1;
        dirWP := dirCP;
        srodekSkali := ILS_GS_SrodekSkali;
        iloscStrzal := 1;
        Skala := 0FFFFH;
      |
      GSOffset :
        currGSflg := TRUE;
        currNAVflg := TRUE;
        dirCP := 1;
        dirWP := dirCP;
        srodekSkali := ILS_GSOfse_SrodekSkali;
        iloscStrzal := 1;
        Skala := 0FFFFH;
      |
      GSElew :
        currGSflg := TRUE;
        currNAVflg := TRUE;
        dirCP := 1;
        dirWP := dirCP;
        srodekSkali := ILS_GSElew_SrodekSkali;
        iloscStrzal := 1;
        Skala := nowaSkalaWP DIV iloscStrzal;
    END (* case format *);
    Notify(newState);
  END UstawFormat;

  PROCEDURE PodajFormat() : State;

  BEGIN
    RETURN currState
  END PodajFormat;

  PROCEDURE UstawZmienne
            (    rNumber       : INTEGER;
                 lNumber       : INTEGER;
                 flightError   : INTEGER;
                 flightErrorGS : INTEGER );

  BEGIN (* UstawZmienne *)
    currLNumber := lNumber;
    currRNumber := rNumber;
    IF flightError = MIN(INTEGER)
    THEN
      currErrorWP := flightError;
      currErrorCP := flightError;
    ELSE
      IF SkalaWPMax = MAX(CARDINAL) THEN
        currErrorWP := MIN(INTEGER);
      ELSIF flightError < -2 * INTEGER(SkalaWPMax)
      THEN
        currErrorWP := -2 * dirWP * INTEGER(SkalaWPMax);
      ELSIF flightError > 2 * INTEGER(SkalaWPMax)
      THEN
        currErrorWP := dirWP * 2 * INTEGER(SkalaWPMax);
      ELSE
        currErrorWP := dirWP * flightError;
      END (* if flightError *);
      IF SkalaCPMax  = MAX(CARDINAL) THEN
        currErrorCP := MIN(INTEGER);
      ELSIF flightError < -2 * INTEGER(SkalaCPMax)
      THEN
        currErrorCP := -2 * dirCP * INTEGER(SkalaCPMax);
      ELSIF flightError > 2 * INTEGER(SkalaCPMax)
      THEN
        currErrorCP := 2 * dirCP * INTEGER(SkalaCPMax);
      ELSE
        currErrorCP := dirCP * flightError;
      END (* if flightError *);
    END (* if flightError *);
    IF flightErrorGS = NilValI
    THEN
      currErrorGS := flightErrorGS;
    ELSIF flightErrorGS < -2 * INTEGER(SkalaCPMax)
    THEN
      currErrorGS := -2 * INTEGER(SkalaCPMax);
    ELSIF flightErrorGS > 2 * INTEGER(SkalaCPMax)
    THEN
      currErrorGS := 2 * INTEGER(SkalaCPMax);
    ELSE
      currErrorGS := flightErrorGS;
    END (* if flightErrorGS *);
    Notify(newState);
  END UstawZmienne;

  PROCEDURE SetIdleMsg
            (    msg : CARDINAL );

  BEGIN
    currMsg := msg;
  END SetIdleMsg;

  PROCEDURE ControlLoop;

    PROCEDURE SendMsg
              (    val      : INTEGER;
                   firstPos : CARDINAL;
                   msgNum   : CARDINAL );
    VAR
      compiledVal : Number;
      count       : CARDINAL;
      valC        : CARDINAL;
      ujemna      : BOOLEAN;
      dtaSign     : DtaSignType;

    BEGIN (* SendMsg *)
      IF val = NilValI
      THEN
        FOR count := 3 TO 0 BY -1 DO
          compiledVal[count] := 100H + (firstPos + count) * 10H + 10;
        END (* for count *);
      ELSE
        IF val < 0
        THEN
          valC := -val;
          ujemna := TRUE;
        ELSE
          valC := val;
          ujemna := FALSE;
        END (* if val *);
        FOR count := 3 TO 0 BY -1 DO
          IF ujemna AND (valC = 0)
          THEN
            compiledVal[count] := 100H + (firstPos + count) * 10H + 11;
          ELSE
            compiledVal[count] := 100H + (firstPos + count) * 10H + valC MOD 10
            ;
            valC := valC DIV 10;
          END (* if *);
        END (* for count *);
      END (* if val *);
      SetMessage(msgNum, compiledVal, dtaSign);
    END SendMsg;

    PROCEDURE SetLOC_G_SCP
              (    error   : INTEGER;
                   errorGS : INTEGER;
                   force   : BOOLEAN );
    VAR
      dtaSign : DtaSignType;

      PROCEDURE PozWskazowki
                (     error : INTEGER;
                  VAR flg   : BOOLEAN ) : INTEGER;

      BEGIN
        IF error = NilValI
        THEN
          flg := FALSE;
          error := 0;
        ELSE
          flg := TRUE;
        END (* if error *);
        error := error DIV INTEGER(SkalaCP) * WzmocnienieCP + SrodekSkaliCP;
        IF error < 0
        THEN
          RETURN 0;
        ELSIF error > 9999
        THEN
          RETURN 9999;
        END (* if error *);
        RETURN error
      END PozWskazowki;
    VAR
      okVAVflg : BOOLEAN;
      okGSFlg  : BOOLEAN;

    BEGIN (* SetLOC_G_SCP *)
      error := PozWskazowki(error, okVAVflg);
      SetAnalogVal(CockpitCPLOCNeedle, error, dtaSign);
      SetAnalogVal(ConsoleCPLOCNeedle, error, dtaSign);
      errorGS := PozWskazowki(errorGS, okGSFlg);
      okVAVflg := currNAVflg AND okVAVflg;
      SetAnalogVal(ConsoleCPGSNeedle, errorGS, dtaSign);
      SetAnalogVal(CockpitCPGSNeedle, errorGS, dtaSign);
      okGSFlg := currGSflg AND okGSFlg;
      SetCPFlags(okVAVflg, okGSFlg, currTOflg AND okVAVflg, currFROMflg AND
                 okVAVflg, force);
    END SetLOC_G_SCP;

    PROCEDURE pozycjaStrzalki
              (    currError : INTEGER ) : CARDINAL;
    VAR
      Strzalka : INTEGER;
      myError  : INTEGER;

    BEGIN
      IF currError = NilValI
      THEN
        Strzalka := srodekSkali - iloscStrzal - 1;
        (* ma powiedziec ze nie nie ma *)
      ELSE
        IF currError > 0
        THEN
          myError := currError + INTEGER(Skala) DIV 2
        ELSE
          myError := currError - INTEGER(Skala) DIV 2
        END (* if currError *);
        Strzalka := myError DIV INTEGER(Skala) + INTEGER(srodekSkali);
        IF Strzalka < INTEGER(srodekSkali - iloscStrzal)
        THEN
          Strzalka := INTEGER(srodekSkali - iloscStrzal);
        ELSIF Strzalka > INTEGER(srodekSkali + iloscStrzal)
        THEN
          Strzalka := srodekSkali + iloscStrzal;
        END (* if ograniczenia *);
      END (* if currError *);
      RETURN Strzalka;
    END pozycjaStrzalki;

  TYPE
    CoWyswietlac = (LewaLiczWP, PrawaLiczWP, WskaznikCP);
  
  VAR
    Strzalka   : CARDINAL;
    coWys      : CoWyswietlac;
    saftyCount : CARDINAL;
    
  BEGIN (* ControlLoop *)
    saftyCount := MaxFlgCount;
    coWys := LewaLiczWP;
    LOOP
      IF currState = Idle
      THEN
        SendMsg(NilValI, 0, currMsg);
        currGSflg := FALSE;
        currNAVflg := FALSE;
        currFROMflg := FALSE;
        currTOflg := FALSE;
        SetLOC_G_SCP(NilValI, NilValI, force);
        force := FALSE;
      ELSE
        DEC(saftyCount);
        IF saftyCount = 0 THEN
          force := TRUE;
          saftyCount := MaxFlgCount;
        END;
        CASE coWys  OF
          LewaLiczWP:
            Strzalka := pozycjaStrzalki(currErrorWP);
            IF (currLNumber >= 0) OR (currLNumber = NilValI)
            THEN
              SendMsg(currLNumber, LewaLiczPCyf, Strzalka)
            ELSE
              SendMsg(ABS(currLNumber), LewaLiczPCyf, Strzalka +
                      IloscKomunikatowDlaProc)
            END (* if *);
            coWys := PrawaLiczWP;
          |
          PrawaLiczWP:
            Strzalka := pozycjaStrzalki(currErrorWP);
            IF (currLNumber < 0) AND (currLNumber <> NilValI)
            THEN
              Strzalka := Strzalka + IloscKomunikatowDlaProc;
            END (* if *);
            SendMsg(currRNumber, PrawaLiczPCyf, Strzalka);
            coWys := WskaznikCP;
          |
          WskaznikCP:
            SetLOC_G_SCP(currErrorCP, currErrorGS, force);
            force := FALSE;
            coWys := LewaLiczWP;
        END;
      END (* if currState *);
      WAITC(newState);
    END (* loop *);
  END ControlLoop;
  
  PROCEDURE WatchDogProcess;
  BEGIN
    LOOP
      Wait(TInOneSecond()*2);
      IF currState = Idle THEN
        force := TRUE;
        Notify(newState);
      END;
    END (* loop *);
  END WatchDogProcess;
  
BEGIN
  currMsg := StartMsg;
  force := TRUE;
  currState := Idle;
  SkalaCPMax := 0;
  SkalaWPMax := 0;
  dirCP := 0;
  dirWP := 0;
  SkalaCP := 0FFFFH;
  Skala := 0FFFFH;
  srodekSkali := VORSrodekSkali;
  iloscStrzal := 1;
  currLNumber := 0;
  currRNumber := 0;
  currErrorWP := NilValI;
  currErrorCP := NilValI;
  currErrorGS := NilValI;
  InitC(newState);
  SetAnalogVal(CockpitCPLOCNeedle, SrodekSkaliCP, dtaSign);
  SetAnalogVal(ConsoleCPLOCNeedle, SrodekSkaliCP, dtaSign);
  SetAnalogVal(ConsoleCPGSNeedle, SrodekSkaliCP, dtaSign);
  SetAnalogVal(CockpitCPGSNeedle, SrodekSkaliCP, dtaSign);
  IF PomiarANieArchiwum THEN
    STARTPROCESS(ControlLoop, 800H, 0);
    STARTPROCESS(WatchDogProcess, 800H, 0);
  END (* IF *);
END CocpDsp.
