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
|     20-01-98: TOMEK
|        gruntowna przebudowa pliku
|       w Analizer wprowadzona mozliwosc odbierania poprawek DGPS
|       w Rd usunieto ustawianie tRSZepsuty
|       wprowadzono koncepcje WatchDog
|       inicjowany jest DIGI do odbioru poprawek
|     Rel.3.0:MPostol
|       wywalilem definicje kanalow komunikacyjnych do CommonTypes
|       Wprowadzilem Kopiowanie aby uniknac bezposredniego uzywania 
|       kanalu GPS
|
|  Copyright (C), CAS LODZ POLAND.
|  TEL: 42' 862 547, 42' 87 80 44 FAX/TEL: 42' 84 48 40
|
**********************************************************************)
(*.F+ *)

IMPLEMENTATION MODULE TheodolitRead [ 0 ];

  FROM DigiRS IMPORT
    ReadString, SetBaudRate;

  FROM RealConversions IMPORT
    StringToReal;

  FROM Messages IMPORT
    Message, NewMessage, Display;

  FROM CommonTypes IMPORT
    PolozenieBiegunowe, SigNilVal, ChannelTeodolit;

  FROM MANAGER IMPORT
    STARTPROCESS;

  FROM Timer IMPORT
    Wait, TInOneSecond;

  FROM MathLib0 IMPORT
    cos, sqrt, entier;

  FROM Math IMPORT
    ACos, Sqr, M_PI;

  FROM FIltr1St IMPORT
    ContinerBT, InitContB, FiltrB, InitContBCoun, BinaryCounter,
    BinaryCounterCon;

  FROM BitByteOps IMPORT
    ByteAnd;

  FROM ASCII IMPORT
    lf, cr;
  
  FROM SpecConv IMPORT
    IncRound;
    
  TYPE
    PMState      =
      ( Outside,
        WaitAzymuth,
        CopyGPSFrame,
        Azymuth,
        WaitElevation,
        Elevation,
        Event,
        Tracking,
        CheckSumPre,
        CheckSum );
    NumLength    =
      [ 0 .. 5 ];
    GetNumResult =
      ( copletedGN,
        errorGN,
        inProg );
    NumTab       =
      ARRAY NumLength OF CHAR;
    CRCNum       =
      [ 0 .. 1 ];
    CrcTab       =
      ARRAY CRCNum OF CHAR;

  VAR
    Azymut,
    Elewacja,
    lstAzymuth,
    lstElevation                               : REAL;
    currentSign,
    TeoEvNr,
    wd_dgps_currSign                           : CARDINAL;
    lstEvent,
    lstTracking,
    teoEvBit                                   : BOOLEAN;
    State                                      : TeoStates;
    currState                                  : PMState;
    lastNum                                    : NumTab;
    lastCrc                                    : CrcTab;
    numPos                                     : NumLength;
    CheckSumIdx                                : CRCNum;
    teoEvCon                                   : ContinerBT;
    teoEvNrCOn                                 : BinaryCounterCon;
    Nie_mozna_uruchomic_kanalu_Teodolit_i_DGPS : Message;

  CONST
    MaxTeoEvFil     = 3;

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

  BEGIN (* TheodolitView *)
    IF PolozenieTeodolitu.Odleglosc > 0.001
    THEN
      t := pk;
    ELSE
    (* sprawdzic algorytm - inny niz w spec *)
      kat := ABS( pk.Kat - PolozenieTeodolitu.Kat );   (* kat pomiedzy *)
      kat := kat * M_PI / 180.0;
      t.Odleglosc := sqrt( Sqr( PolozenieTeodolitu.Odleglosc ) + Sqr(
                           pk.Odleglosc ) - 2.0 * PolozenieTeodolitu.Odleglosc
                           * pk.Odleglosc * cos( kat ) );
      IF ( t.Odleglosc = 0.0 ) OR ( pk.Odleglosc = 0.0 )
      THEN
        kat := 0.0;
      ELSE
        kat := ACos( ( Sqr( pk.Odleglosc ) + Sqr( t.Odleglosc ) - Sqr(
                     PolozenieTeodolitu.Odleglosc ) ) /
                     ( 2.0 * t.Odleglosc * pk.Odleglosc ) );
      END (* if *);
      kat := kat * 180.0 / M_PI;
      IF Angle360( PolozenieTeodolitu.Kat - pk.Kat ) < 180.0
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

  (* event z teodolitu zmieniany zboczem *)

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

  (* polaozenie z teodolitu azymut i elewacja real *)

  PROCEDURE GetTheoR
            ( VAR dtaSign  : DtaSignType;
              VAR azymut   : REAL;
              VAR elewacja : REAL        ) : TeoStates;

  VAR
    s : TeoStates;

  BEGIN (* GetTheoR *)
    Analizer;   (* pobranie ramki z teodloitu i jej dekompozycja *)
    azymut := Azymut / 100.0;
    elewacja := Elewacja / 100.0;
    s := State;
    IF dtaSign <> currentSign
    THEN   (* sprawdzenie czy przyszla nowa ramka*)
      dtaSign := currentSign;
      INCL( State, tNoweDane );
    ELSE
      EXCL( State, tNoweDane )
    END (* if dtaSign *);
    RETURN s;
  END GetTheoR;

  (* polaozenie z teodolitu azymut i elewacja integer *)

  PROCEDURE GetTheoI
            ( VAR dtaSign  : DtaSignType;
              VAR azymut   : INTEGER;
              VAR elewacja : INTEGER     );

  BEGIN (* TheodolitReceive *)
    Analizer;   (* pobranie ramki z teodloitu i jej dekompozycja *)
    IF dtaSign <> currentSign
    THEN   (* sprawdzenie czy przyszla nowa ramka*)
      dtaSign := currentSign;
      IF Azymut <= 18000.0
      THEN   (* zamiana azymutu na integer *)
        azymut := entier( Azymut );
      ELSE
        azymut := entier( Azymut - 36000.00 + 0.5 )
      END (* if Azymut *);
      IF Elewacja <= 18000.0
      THEN   (* zamiana elewacji na integer *)
        elewacja := entier( Elewacja );
      ELSE
        elewacja := entier( Elewacja - 36000.00 + 0.5 );
      END (* if *);
    ELSE
      azymut := SigNilVal;
      elewacja := SigNilVal;
    END (* if dtaSign *);
  END GetTheoI;

  PROCEDURE signalError;

  BEGIN
    INCL( State, tBledy );
  END signalError;

  PROCEDURE Analizer;

    PROCEDURE AssignRes
              (    lstAzymuth   : REAL;
                   lstElevation : REAL;
                   lstEvent     : BOOLEAN;
                   lstTracking  : BOOLEAN );
      (* zwrocenie kompletnych danych zwiekszenie licznika danych *)

    BEGIN
      (* $R-*)
      INC( currentSign );
      (* $R= *)
      EXCL( State, tRSZepsuty );   (* ustawienie znacznikow *)
      EXCL( State, tBledy );
      Azymut := lstAzymuth;   (* ustawienie danych *)
      Elewacja := lstElevation;
      INCL( State, tNoweDane );
      FiltrB( teoEvCon, lstEvent, teoEvBit );
      TeoEvNr := BinaryCounter( teoEvBit, teoEvNrCOn );
      IF teoEvBit
      THEN
        INCL( State, tEvent );
      ELSE
        EXCL( State, tEvent );
      END (* if lstEvent *);
    END AssignRes;

    PROCEDURE Rd (* odbieranie kolejnych znakow *)
              ( VAR ch : CHAR ) : BOOLEAN;

    VAR
      ok : BOOLEAN;

    BEGIN
      ok := ReadString( ChannelTeodolit, ch, 1 ) = 1;
      (* poprawnie odebrany znak *)
      IF ok
      THEN
        ch := CHAR( ByteAnd( ch, 7FH ) );   (* wyeliminowanie 7 bitu danych gdy
                                               parzystosc *)
      END (* if ok *);
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
          (* zbieranie danych do bufora azymutu lub elewacji *)

    BEGIN (* GetNum *)
      IF ( lastCh >= '0' ) AND ( lastCh <= '9' ) (* czy znak jest cyfra*)
      THEN
        lastNum[numPos] := lastCh;   (* zbieranie kolejnych znakow do bufora *)
        INC( numPos );
        IF numPos = MAX( NumLength )
        THEN
          StringToReal( lastNum, result, ok );   (* zamiana kompletnego bufora
                                                    znakow elewacji lub azymutu
                                                    na wartosc real *)
          IF NOT ok (* blad konwersji powrot z bledem *)
          THEN
            RETURN errorGN
          END (* if *);
          RETURN copletedGN (* zwrocenie stopni po konwersji *)
        ELSE
          RETURN inProg
        END (* if numPos *);
      ELSE
        RETURN errorGN
      END (* if *);
    END GetNum;

  VAR
    lastCh : CHAR;
        (* analiza odbieranych danych z kanalu teodolitu *)

  BEGIN (* Analizer *)
    WHILE Rd( lastCh ) DO   (* czytanie kolejnego znaku *)
      CASE currState OF
        Outside :
        (* czekanie na koniec ramki poprzedniej by rozpoczac dekompozycje *)
          IF lastCh = lf
          THEN
            currState := WaitAzymuth;
          END (* if lastCh *);
        |
        WaitAzymuth :
          IF lastCh = 'A' (* dane z teodolitu *)
          THEN
            currState := Azymuth;
            lastNum[MAX( NumLength )] := 0C;
            numPos := 0;
          ELSIF lastCh = '$'
          THEN   (* poprawki z dgps *)
               (* ustawienie znacznikow odbioru brak teodolitu przyszedl 
                  dgps *)
            Kopiowanie(lastCh);   
              (* wyslanie pierwszego znaku *)
            currState := CopyGPSFrame;
          ELSIF lastCh = cr
          THEN
            signalError;
            currState := Outside;
          END (* if lastCh *);
        |
        CopyGPSFrame : (* kopiowanie poszczegolnych znakow poprawek DGPS *)
          Kopiowanie(lastCh); (* wysylanie kolejnych znakow do GPS*)
          IF lastCh = cr
          THEN
            Kopiowanie(lastCh); (* wysylanie kolejnych znakow do GPS*)
            lastCh := lf;
            Kopiowanie(lastCh); (* wysylanie kolejnych znakow do GPS*)
            IncRound( wd_dgps_currSign );
            currState := WaitAzymuth;
          END (* if lastCh *)
        |
        Azymuth : (* ustalanie azymutu *)
          CASE GetNum( lastCh, lastNum, numPos, lstAzymuth ) OF
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
        WaitElevation : (* ustalannie poczatku elewacji *)
          IF lastCh = 'E'
          THEN
            currState := Elevation;
            lastNum[MAX( NumLength )] := 0C;
            numPos := 0;
          ELSE
            signalError;
            currState := Outside;
          END (* if lastCh *);
        |
        Elevation : (* ustalenie elewacji *)
          CASE GetNum( lastCh, lastNum, numPos, lstElevation ) OF
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
        Event : (* znacznik eventu *)
          CheckSumIdx := MIN( CRCNum );
          IF lastCh = 'X' (* byl event *)
          THEN
            currState := Tracking;
            (* <currState := CheckSum;>*)
            lstEvent := TRUE;
          ELSIF lastCh = '0' (* brak eventu *)
          THEN
            currState := Tracking;
            (* <currState := CheckSum;>*)
            lstEvent := FALSE;
          ELSE
            signalError;
            currState := Outside;
          END (* if lastCh *);
        |
        Tracking : (* znacznik sledzenia *)
          CheckSumIdx := MIN( CRCNum );
          (* IF lastCh = 'X'nowa *)
          IF lastCh = 'T' (* samolot sledzony tracking stara *)
          THEN
          (* currState := CheckSumPre; nowa *)
            currState := CheckSum;   (* stara *)
            lstTracking := TRUE;
            (* ELSIF lastCh = '0' nowa *)
          ELSIF lastCh = 'S' (* samolot szukany serch stara *)
          THEN
          (* currState := CheckSumPre; nowa *)
            currState := CheckSum;   (* stara *)
            lstTracking := FALSE;
          ELSE
            signalError;
            currState := Outside;
          END (* if lastCh *);
        |
        CheckSumPre : (* suma kontrolna nowa *)
          CheckSumIdx := MIN( CRCNum );
          IF lastCh = 'S'
          THEN
            currState := CheckSum;
          ELSE
            signalError;
            currState := Outside;
          END (* if lastCh *);
        |
        CheckSum : (* suma kontrolna stara *)
          IF ( lastCh >= '0' ) AND ( lastCh <= '9' ) OR ( lastCh >= 'A' ) AND
             ( lastCh <= 'F' )
          THEN
            lastCrc[CheckSumIdx] := lastCh;
            IF CheckSumIdx < MAX( CRCNum )
            THEN
              INC( CheckSumIdx );
            ELSIF CountCrc( lastCrc )
            THEN   (* poprawnie odebrana ramka *)
            (* przepisanie danych do zmiennych wyjsciowych *)
              AssignRes( lstAzymuth, lstElevation, lstEvent, lstTracking );
              currState := Outside;
            ELSE
              signalError;
              currState := Outside;
            END (* if CheckSumIdx *);
          ELSE   (* bledy w odbieraniu ramki *)
            signalError;
            currState := Outside;
          END (* if *);
      END (* case currState *);
    END (* while Rd *);
  END Analizer;

  PROCEDURE WatchDog;

  VAR
    wd_teo_currSign  : CARDINAL;
    wd_teo_prevSign  : CARDINAL;
    wd_dgps_prevSign : CARDINAL;
    wd_azymut        : INTEGER;
    wd_elewacja      : INTEGER;
    dgpsDiff         : ContinerBT;
    InDiffMode       : BOOLEAN;
    
  BEGIN
    wd_teo_prevSign := GetCurrDataSign( );
    wd_dgps_prevSign := wd_dgps_currSign;
    InitContB(dgpsDiff, 3, FALSE);
    InDiffMode := FALSE;
    LOOP
      Wait( TInOneSecond( ) );
      GetTheoI( wd_teo_currSign, wd_azymut, wd_elewacja );
      IF wd_dgps_currSign = wd_dgps_prevSign
      THEN
        FiltrB(dgpsDiff, FALSE, InDiffMode);
      ELSE
        FiltrB(dgpsDiff, TRUE, InDiffMode);
        wd_dgps_prevSign := wd_dgps_currSign;
      END (* if wd_currSign *);
      IF InDiffMode THEN
        EXCL( State, tgpsRSZepsuty );
      ELSE 
        INCL( State, tgpsRSZepsuty );
      END;
      IF wd_teo_prevSign = wd_teo_currSign  THEN
        INCL(State, tRSZepsuty);
      ELSE
        wd_teo_prevSign := wd_teo_currSign;
      END;
    END (* loop *);
  END WatchDog;

PROCEDURE NicNieRob (ch: CHAR);
BEGIN

END NicNieRob;

BEGIN
  (* inicjacja zmiennych *)
  Kopiowanie := NicNieRob;
  PolozenieTeodolitu.Kat := 0.0;
  PolozenieTeodolitu.Odleglosc := 0.0;
  teoEvBit := FALSE;
  InitContB( teoEvCon, MaxTeoEvFil, teoEvBit );
  InitContBCoun( teoEvNrCOn, FALSE );
  currState := MIN( PMState );
  lstAzymuth := 0.0;
  lstElevation := 0.0;
  lstEvent := FALSE;
  lstTracking := FALSE;
  currentSign := 0;
  Azymut := 0.0;
  Elewacja := 0.0;
  State := TeoStates { tRSZepsuty, tgpsRSZepsuty };
  (* inicjacja kanalow DIGI dla odbioru telemetri/poprawek DGPS i wysylania
     poprawek *)
  IF NOT SetBaudRate( ChannelTeodolit, 12, 8 ) 
  THEN
    (* w przypadku bledow inicjacji komunikat *)
    NewMessage( Nie_mozna_uruchomic_kanalu_Teodolit_i_DGPS,
                "Nie mo¾na uruchomi† kanaˆu Toedolitu", BITSET( 9090H ) );
    Display( Nie_mozna_uruchomic_kanalu_Teodolit_i_DGPS );
  END (* if *);
  STARTPROCESS( WatchDog, 0800H, 0 );   (* wystartowanie procesu czytania*)
END TheodolitRead.
