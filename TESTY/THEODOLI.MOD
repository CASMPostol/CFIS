(*.F- *)
(**********************************************************************
|  Title   : Obsluga Teodolitu
|  Author  : M.Postol
|  System  : LOGITECH MODULA-2/86
|  History :
|     04-10-96:
|       nastepuje ciagla rejestracja eventow TEO - wprowadzilem filtr
|     12-12-96: M.Postol
|       niepotrzebna instrukcja w GetTheoR
|
|  Copyright (C), CAS LODZ POLAND.
|  TEL: 42' 862 547, 42' 87 80 44 FAX/TEL: 42' 84 48 40
|
**********************************************************************)
(*.F+ *)

IMPLEMENTATION MODULE TheodolitRead [ 0 ];

  FROM DigiRS IMPORT
    ReadString, SetBaudRate;

  FROM Strings IMPORT
    Copy;

  FROM RealConversions IMPORT
    StringToReal;

  FROM GrafUtil IMPORT
    InfoBeep;

  FROM CommonTypes IMPORT
    PolozenieBiegunowe, SigNilVal;

  FROM MathLib0 IMPORT
    cos, sqrt, entier;

  FROM Math IMPORT
    ACos, Sqr, M_PI;

  FROM FIltr1St IMPORT
    ContinerBT, InitContB, FiltrB, InitContBCoun, BinaryCounter,
    BinaryCounterCon;

  TYPE
    PMState        =
      ( Outside,
        WaitAzymuth,
        Azymuth,
        WaitElevation,
        Elevation,
        Event,
        Tracking,
        CheckSumPre,
        CheckSum );
    NumLength    =
      [0 .. 5];
    GetNumResult =
      ( copletedGN,
        errorGN,
        inProg );
    NumTab       =
      ARRAY NumLength OF CHAR;
    CRCNum       =
      [0 .. 1];
    CrcTab       =
      ARRAY CRCNum OF CHAR;
  VAR
    State        : TeoStates;
    Azymut,
    Elewacja     : REAL;
    currentSign  : CARDINAL;
    currState    : PMState;
    lastNum      : NumTab;
    lastCrc      : CrcTab;
    numPos       : NumLength;
    lstAzymuth   : REAL;
    lstElevation : REAL;
    lstEvent     : BOOLEAN;
    lstTracking  : BOOLEAN;
    CheckSumIdx  : CRCNum;
    tRSZepsutyidx: CARDINAL;
    teoEvCon     : ContinerBT;
    teoEvNrCOn   : BinaryCounterCon;
    teoEvBit     : BOOLEAN;
    TeoEvNr      : CARDINAL;

  CONST
    MaxTeoEvFil     = 3;
    ChannelTeodolit = 5;

  PROCEDURE TheodolitView
            (     pk : PolozenieBiegunowe;
              VAR t  : PolozenieBiegunowe );
  VAR
    kat : REAL;

    PROCEDURE Angle360
              (    ang : REAL ) : REAL;

    BEGIN
      WHILE ang < 0.0 DO
        ang := ang + 360.0;
      END (* while ang *);
      WHILE ang >= 360.0 DO
        ang := ang - 360.0;
      END (* while ang *);
      RETURN ang;
    END Angle360;

  BEGIN
    IF PolozenieTeodolitu.Odleglosc > 0.001
    THEN
      t := pk;
    ELSE
    (* sprawdzic algorytm - inny niz w spec *)
      kat := ABS(pk.Kat - PolozenieTeodolitu.Kat);   (* kat pomiedzy *)
      kat := kat * M_PI / 180.0;
      t.Odleglosc := sqrt(Sqr(PolozenieTeodolitu.Odleglosc) + Sqr(pk.Odleglosc)
                          - 2.0 * PolozenieTeodolitu.Odleglosc * pk.Odleglosc *
                          cos(kat));
      IF (t.Odleglosc = 0.0) OR (pk.Odleglosc = 0.0)
      THEN
        kat := 0.0;
      ELSE
        kat := ACos((Sqr(pk.Odleglosc) + Sqr(t.Odleglosc) - Sqr(
                    PolozenieTeodolitu.Odleglosc)) /
                    (2.0 * t.Odleglosc * pk.Odleglosc));
      END (* if *);
      kat := kat * 180.0 / M_PI;
      IF Angle360(PolozenieTeodolitu.Kat - pk.Kat) < 180.0
      THEN
        t.Kat := pk.Kat + kat;
      ELSE
        t.Kat := pk.Kat - kat;
      END (* if Angle360 *);
    END (* if CurVor.Teodolit.Odleglosc *);
  END TheodolitView;

  PROCEDURE GetCurrDataSign() : DtaSignType;

  BEGIN
    RETURN currentSign;
  END GetCurrDataSign;

  PROCEDURE InitTeoEventId
            ( VAR ident : TeoEvSignType );

  BEGIN
    ident := TeoEvNr;
  END InitTeoEventId;

  PROCEDURE GetTeoEvent
            ( VAR ident : TeoEvSignType ) : BOOLEAN;

  BEGIN
    IF ident <> TeoEvNr
    THEN
      ident := TeoEvNr;
      RETURN TRUE;
    END (* if ident *);
    RETURN FALSE;
  END GetTeoEvent;

  PROCEDURE GetTheoR
            ( VAR dtaSign  : DtaSignType;
              VAR azymut   : REAL;
              VAR elewacja : REAL ) : TeoStates;
  VAR
    s : TeoStates;

  BEGIN (* GetTheoR *)
    Analizer;
    azymut   := Azymut / 100.0;
    elewacja := Elewacja / 100.0;
    s := State;
    IF dtaSign <> currentSign THEN
      dtaSign := currentSign;
      INCL(State, tNoweDane);
    ELSE
      EXCL(State, tNoweDane)
    END;
    RETURN s;
  END GetTheoR;

  PROCEDURE GetTheoI
            ( VAR dtaSign  : DtaSignType;
              VAR azymut   : INTEGER;
              VAR elewacja : INTEGER );
  BEGIN (* TheodolitReceive *)
    Analizer;
    IF dtaSign <> currentSign THEN
      dtaSign  := currentSign;
      IF Azymut <= 18000.0 THEN
        azymut := entier(Azymut);
      ELSE
        azymut := entier(Azymut - 36000.00+0.5)
      END;
      IF Elewacja <= 18000.0  THEN
        elewacja := entier(Elewacja);
      ELSE
        elewacja := entier(Elewacja - 36000.00+0.5);
      END (* if *);
    ELSE
      azymut   := SigNilVal;
      elewacja := SigNilVal;
    END;
  END GetTheoI;

  PROCEDURE AssignRes
            (    lstAzymuth   : REAL;
                 lstElevation : REAL;
                 lstEvent     : BOOLEAN;
                 lstTracking  : BOOLEAN );

  BEGIN
    (*$R-*)
    INC(currentSign);
    (*$R= *)
    EXCL(State, tRSZepsuty);
    EXCL(State, tBledy);
    Azymut := lstAzymuth;
    Elewacja := lstElevation;
    INCL(State, tNoweDane);
    FiltrB(teoEvCon, lstEvent, teoEvBit);
    TeoEvNr := BinaryCounter(teoEvBit, teoEvNrCOn);
    IF teoEvBit
    THEN
      INCL(State, tEvent);
    ELSE
      EXCL(State, tEvent);
    END (* if lstEvent *);
  END AssignRes;

  PROCEDURE signalError;

  BEGIN
    INCL(State, tBledy);
  END signalError;

    
  PROCEDURE Analizer;


    PROCEDURE Rd
              ( VAR ch : CHAR ) : BOOLEAN;
    VAR
      ok: BOOLEAN;
    BEGIN
      ok := ReadString(ChannelTeodolit, ch, 1) = 1;
      IF ok  THEN
        EXCL(State, tRSZepsuty);
      ELSE
        IF tRSZepsutyidx >= 5 THEN
          tRSZepsutyidx := 0;
          INCL(State, tRSZepsuty);
        ELSE
          INC(tRSZepsutyidx)
        END;
      END;
      RETURN ok
    END Rd;

    PROCEDURE CountCrc
              (    crc : CrcTab ) : BOOLEAN;

    BEGIN
      RETURN TRUE;
    END CountCrc;

    PROCEDURE GetNum
              (     lastCh  : CHAR;
                VAR lastNum : NumTab;
                VAR numPos  : NumLength;
                VAR result  : REAL      ) : GetNumResult;
    VAR
      ok : BOOLEAN;

    BEGIN (* GetNum *)
      IF (lastCh >= '0') AND (lastCh <= '9')
      THEN
        lastNum[numPos] := lastCh;
        INC(numPos);
        IF numPos = MAX(NumLength)
        THEN
          StringToReal(lastNum, result, ok);
          IF NOT ok
          THEN
            RETURN errorGN
          END (* if *);
          RETURN copletedGN
        ELSE
          RETURN inProg
        END (* if numPos *);
      ELSE
        RETURN errorGN
      END (* if *);
    END GetNum;
  VAR
    lastCh       : CHAR;

  BEGIN (* Analizer *)
    WHILE Rd(lastCh) DO
      CASE currState OF
        Outside :
          IF lastCh = 12C
          THEN
            currState := WaitAzymuth;
          END (* if lastCh *);
        |
        WaitAzymuth :
          IF lastCh = 'A'
          THEN
            currState := Azymuth;
            lastNum[MAX(NumLength)] := 0C;
            numPos := 0;
          ELSE
            signalError;
            currState := Outside;
          END (* if lastCh *);
        |
        Azymuth :
          CASE GetNum(lastCh, lastNum, numPos, lstAzymuth) OF
            copletedGN :
              currState := WaitElevation;
            |
            errorGN :
              signalError;
              currState := Outside;
            |
            inProg :
              ;
          END (* case GetNum *);
        |
        WaitElevation :
          IF lastCh = 'E'
          THEN
            currState := Elevation;
            lastNum[MAX(NumLength)] := 0C;
            numPos := 0;
          ELSE
            signalError;
            currState := Outside;
          END (* if lastCh *);
        |
        Elevation :
          CASE GetNum(lastCh, lastNum, numPos, lstElevation) OF
            copletedGN :
              currState := Event;
            |
            errorGN :
              signalError;
              currState := Outside;
            |
            inProg :
              ;
          END (* case GetNum *);
        |
        Event :
          CheckSumIdx := MIN(CRCNum);
          IF lastCh = 'X'
          THEN
            currState :=  Tracking;
            (*<currState :=  CheckSum;>*)
            lstEvent := TRUE;
          ELSIF lastCh = '0'
          THEN
            currState :=  Tracking;
            (*<currState :=  CheckSum;>*)
            lstEvent  := FALSE;
          ELSE
            signalError;
            currState := Outside;
          END (* if lastCh *);
        |
        Tracking :
          CheckSumIdx := MIN(CRCNum);
          IF lastCh = 'X'
          THEN
            currState := CheckSumPre;
            lstTracking := TRUE;
          ELSIF lastCh = '0'
          THEN
            currState := CheckSumPre;
            lstTracking := FALSE;
          ELSE
            signalError;
            currState := Outside;
          END (* if lastCh *);
        |
        CheckSumPre :
          CheckSumIdx := MIN(CRCNum);
          IF lastCh = 'S'
          THEN
            currState := CheckSum;
          ELSE
            signalError;
            currState := Outside;
          END (* if lastCh *);
        |
        CheckSum :
          IF (lastCh >= '0') AND (lastCh <= '9') OR
             (lastCh >= 'A') AND (lastCh <= 'F')
          THEN
            lastCrc[CheckSumIdx] := lastCh;
            IF CheckSumIdx < MAX(CRCNum)
            THEN
              INC(CheckSumIdx);
            ELSIF CountCrc(lastCrc)
            THEN
              AssignRes(lstAzymuth, lstElevation, lstEvent, lstTracking);
              currState := Outside;
            ELSE
              signalError;
              currState := Outside;
            END (* if CheckSumIdx *);
            EXCL(State, tFlaga);
          ELSIF lastCh = 'T' THEN
            INCL(State, tFlaga);
            currState := Outside;
          ELSE
            signalError;
            currState := Outside;
          END (* if *);
      END (* case currState *);
    END (* while Rd *);
  END Analizer;
BEGIN
  PolozenieTeodolitu.Kat := 0.0;
  PolozenieTeodolitu.Odleglosc := 0.0;
  teoEvBit     := FALSE;
  InitContB(teoEvCon, MaxTeoEvFil, teoEvBit);
  InitContBCoun(teoEvNrCOn, FALSE);
  currState    := MIN(PMState);
  lstAzymuth   := 0.0;
  lstElevation := 0.0;
  lstEvent     := FALSE;
  lstTracking  := FALSE;
  currentSign  := 0;
  Azymut       := 0.0;
  Elewacja     := 0.0;
  State := TeoStates {tRSZepsuty};
  IF NOT SetBaudRate(ChannelTeodolit, 12, 8)
  THEN
    InfoBeep("Kanal teodolitu nie dziala", 2, 500);
  END (* if *);
END TheodolitRead.
