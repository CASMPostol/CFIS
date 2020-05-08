(*.F- *)
(**********************************************************************
|  Title   :
|  Author  :
|  System  : LOGITECH MODULA-2/86
|  History :
|
|  Copyright (C), CAS LODZ POLAND.
|  TEL: 42' 862 547, 42' 87 80 44 FAX/TEL: 42' 84 48 40
|
**********************************************************************)
(*.F+ *)
(* | 04-12-96: M.Postol | wywalilem niepotrzebne odwolania | 12-12-96: M.Postol
   | wprowadzilem koncepcje currentSign |TOMEK MODUL *)

IMPLEMENTATION MODULE GPSRead [ 0 ]; (* Trimble *) (* Priorytet 0*)

  FROM CommonTypes IMPORT
    PolozenieGeo, WspGeo, DisNilValR, NilValC, DisNilVal;

  FROM MANAGER IMPORT
    STARTPROCESS, InitS, InitC, SIGNAL, SEND, WAITS, WAITC, Assert, Condition;

  FROM StdIO IMPORT
    sprintf;

  FROM NumberConversion IMPORT
    StringToCard, StringToInt;

  FROM RealConversions IMPORT
    StringToReal;

  FROM BitByteOps IMPORT
    ByteXor;

  FROM Timer IMPORT
    Wait, TInOneSecond;

  FROM ASCII IMPORT
    cr, etx, stx;

  FROM DigiRS IMPORT
    ReadString, WriteString, SetBaudRate;

  FROM MathLib0 IMPORT
    entier, real;

  FROM Strings IMPORT
    Copy, Delete, Concat, Length;

  FROM Messages IMPORT
    Message, NewMessage, Display, AcknowledgeFirst;

  FROM Czas IMPORT
    SetDate, SetTime;

  CONST
    GPSChannel  = 4;
    MaxErrCount = 10;

  TYPE
    str110 =
      ARRAY [ 0 .. 110 ] OF CHAR;
    part   =
      ( head,
        body,
        CRC );

  VAR
    pg                             : PolozenieGeo;  (* zmienna opisana gdzie
                                                    indziej*)
    gdop                           : CARDINAL;
    NumberOfSattelites             : CARDINAL;
    ObecnyStan                     : StanGPS;  (* zmienna opisana gdzie indziej
                                               zbior*)
    tog                            : REAL;  (* co okresla*)
    diffmode                       : BOOLEAN;
    currentSign                    : CARDINAL;
    bufor                          : str110;  (* w bufor znajduje sie ramka z
                                              gps*)
    posInRecBuf                    : CARDINAL;
    sumaModC                       : CHAR;
    sumaModF                       : CARDINAL;
    actPart                        : part;
    eos                            : ARRAY [ 0 .. 2 ] OF CHAR;
    Nie_mozna_uruchomic_kanalu_GPS : Message;
    T_BylDolar,
    T_OlalZnak,
    T_ZlyZnakNaKoncu,
    T_ZlSuma,
    T_CalaRamka,
    T_BrakRamki,
    T_BylaInicjacja,
    T_BylaFlaga                    : CARDINAL;
        (* przepisanie danych*)

  PROCEDURE GPSReceive
            ( VAR pgret    : PolozenieGeo;
              VAR GDOP     : CARDINAL;
              VAR NOS      : CARDINAL;
              VAR EPE      : CARDINAL;
              VAR DiffMode : BOOLEAN;
              VAR dtaSign  : DtaSignType  ) : StanGPS;
    (* czytanie z GPS*)

    PROCEDURE GetFrame();

    TYPE
      str14 =
        ARRAY [ 0 .. 14 ] OF CHAR;

    VAR
      ok          : BOOLEAN;
      buforT      : str14;  (* bufor pomocniczy do konwersji*)
      bufPosition : CARDINAL;

      PROCEDURE szukaniePola
                ( VAR bufor : ARRAY OF CHAR;
                  VAR n     : CARDINAL      ) : BOOLEAN;

      VAR
        c : CHAR;

      BEGIN
        REPEAT
          c := bufor[n];
          INC( n );
        UNTIL ( c = ',' ) OR ( c = 0C );
        RETURN c <> 00C;
      END szukaniePola;

      PROCEDURE DekomozycjaRamki
                ( VAR bufor  : ARRAY OF CHAR;
                  VAR n      : CARDINAL;
                  VAR buforT : ARRAY OF CHAR );

      VAR
        k : CARDINAL;

      BEGIN
        k := 0;
        WHILE ( bufor[n] <> ',' ) AND ( bufor[n] <> 0C ) AND ( k <= HIGH(
              buforT ) ) DO
          buforT[k] := bufor[n];
          INC( k );
          INC( n )
        END (* while *);
        IF k < HIGH( buforT )
        THEN
          buforT[k] := 00C;
        ELSE
          WHILE ( bufor[n] <> ',' ) AND ( bufor[n] <> 0C ) DO
            INC( n );
          END (* while *);
        END (* if k *);
      END DekomozycjaRamki;

      PROCEDURE GetStrFromGps
                ( VAR s : str110 ) : BOOLEAN;

      VAR
        cChar : CHAR;

        PROCEDURE ConvertHexChar
                  (     c  : CHAR;
                    VAR ok : BOOLEAN ) : CARDINAL;

        BEGIN
          ok := TRUE;
          IF ( c >= '0' ) AND ( c <= '9' )
          THEN
            RETURN ORD( c ) - ORD( '0' )
          ELSIF ( c >= 'A' ) AND ( c <= 'F' )
          THEN
            RETURN ORD( c ) - ORD( 'A' ) + 10;
          ELSE
            ok := FALSE;
            RETURN 0
          END (* if *);
        END ConvertHexChar;

        PROCEDURE RdChar
                  ( VAR ch : CHAR ) : BOOLEAN;

        BEGIN
          RETURN ReadString( GPSChannel, ch, 1 ) = 1
        END RdChar;

      BEGIN (* GetStrFromGps *)
        (* szukanie poczatka ramki*)
        (* w nowej wersji szukanie pocz ramki Tomek*)
        LOOP
          IF NOT RdChar( cChar )
          THEN
            RETURN FALSE;
          END (* if RdChar *);
          CASE actPart OF
            head :
              IF cChar = '$'
              THEN
                INC( T_BylDolar );
                actPart := body;
                sumaModC := 0C;   (* znacznik sumy*)
                posInRecBuf := 0;
              ELSE
                INC( T_OlalZnak );
              END (* if cChar *);
            |
            body :
              Assert( posInRecBuf <= HIGH( s ) );
              IF cChar = '*'
              THEN
                s[posInRecBuf] := 0C;
                actPart := CRC;
                sumaModF := 0;
                posInRecBuf := 16;
              ELSE
                s[posInRecBuf] := cChar;
                INC( posInRecBuf );
                sumaModC := CHAR( ByteXor( sumaModC, cChar ) );
              END (* if *);
            |
            CRC :
              IF cChar <= ' '
              THEN
                INC( T_ZlyZnakNaKoncu );
                actPart := head;
              ELSE
                sumaModF := ConvertHexChar( cChar, ok ) * posInRecBuf +
                            sumaModF;
                posInRecBuf := posInRecBuf DIV 16;
                IF posInRecBuf = 0
                THEN
                  actPart := head;
                  IF sumaModF = ORD( sumaModC )
                  THEN
                    EXCL( ObecnyStan, BledyWTransmisji );
                    RETURN TRUE;
                  ELSE
                    INC( T_ZlSuma );
                    INCL( ObecnyStan, BledyWTransmisji );
                  END (* if sumaModF *);
                END (* if i *);
              END (* if *);
          END (* case actPart *);
        END (* loop *);
      END GetStrFromGps; (* koniec czytania ramki*)

      PROCEDURE GetReal
                ( VAR bufor       : ARRAY OF CHAR;
                  VAR bufPosition : CARDINAL      ) : REAL;

      VAR
        buforT    : str14;
        wynikReal : REAL;

      BEGIN
        DekomozycjaRamki( bufor, bufPosition, buforT );
        StringToReal( buforT, wynikReal, ok );
        RETURN wynikReal
      END GetReal;

      PROCEDURE GetCardinal
                ( VAR bufor       : ARRAY OF CHAR;
                  VAR bufPosition : CARDINAL      ) : CARDINAL;

      VAR
        buforT        : str14;
        wynikCardianl : CARDINAL;
        ok            : BOOLEAN;

      BEGIN
        DekomozycjaRamki( bufor, bufPosition, buforT );
        StringToCard( buforT, wynikCardianl, ok );
        IF ok
        THEN
          RETURN wynikCardianl
        END (* if ok *);
        RETURN NilValC
      END GetCardinal;

      PROCEDURE UstawFlage;

      BEGIN
        INCL( ObecnyStan, Flaga );
        gdop := DisNilVal;
        tog := 0.0;
        NumberOfSattelites := NilValC;
        diffmode := FALSE;   (* jesli brak pozycji to rowniez FALSE potrzebne
                                do screna*)
      END UstawFlage;

      PROCEDURE An_Frame_DOPA;

      TYPE
        ramkaDOPA =
          ( headerD,
            weekD,
            secondsD,
            gdopD,
            pdopD,
            htdopD,
            hdopD,
            tdopD,
            satsD,
            sats1D,
            sat2D,
            sats3D,
            sat4D,
            sats6D,
            sat6D,
            sats7D,
            sat8D,
            sats9D,
            sat10D,
            sats11D,
            sat12D,
            endD );

      VAR
        stanDOPA    : ramkaDOPA;
        bufPosition : CARDINAL;
        gdopR       : REAL;

      BEGIN
        bufPosition := 0;   (* GDOP*)
        stanDOPA := headerD;
        LOOP
          IF NOT szukaniePola( bufor, bufPosition )
          THEN
            EXIT
          END (* if *);
          IF stanDOPA < endD
          THEN
            INC( stanDOPA );
          END (* if CzescRamki *);
          CASE stanDOPA OF
            gdopD :
              gdopR := GetReal( bufor, bufPosition );
              IF gdopR * 500. <= DisNilValR
              THEN
                gdop := TRUNC( gdopR * 500.0 );
              ELSE
                gdop := DisNilVal;
              END (* if gdop *);
            |
            satsD :
              NumberOfSattelites := GetCardinal( bufor, bufPosition );
              IF NumberOfSattelites = NilValC
              THEN
                UstawFlage;
                EXIT
              END (* if *);
          ELSE
            ;
          END (* case CzescRamki *);
        END (* while szukaniePola *);
      END An_Frame_DOPA;

      PROCEDURE An_Frame_GPGGA;

      TYPE
        ramkaGPGGA =
          ( headerGPG,
            utcGPG,
            latGPG,
            latdirGPG,
            lonGPG,
            londirGPG,
            gpsqualGPG,
            satsGPGAG,
            hdopGPG,
            altGPG,
            unitsGPG,
            null1GPG,
            null2GPG,
            ageGPG,
            stnIDGPG,
            endGPG );

      VAR
        stanGPGGA   : ramkaGPGGA;
        bufPosition : CARDINAL;

        PROCEDURE GetWspGeo
                  ( VAR bufor       : ARRAY OF CHAR;
                    VAR bufPosition : CARDINAL;
                    VAR wg          : WspGeo        ) : BOOLEAN;

        VAR
          buforT : str14;
          ok     : BOOLEAN;

          PROCEDURE ConvertStrToWspGeo
                    ( VAR s  : ARRAY OF CHAR;
                      VAR wg : WspGeo        ) : BOOLEAN;

          VAR
            sub,
            str,
            scr : ARRAY [ 0 .. 8 ] OF CHAR;
            ok  : BOOLEAN;

            PROCEDURE Isolate
                      ( VAR sub : ARRAY OF CHAR;
                        VAR str : ARRAY OF CHAR;
                        VAR scr : ARRAY OF CHAR );

            VAR
              i     : CARDINAL;
              idx   : CARDINAL;
              idy   : CARDINAL;
              lngth : CARDINAL;

            BEGIN
              idx := 0;
              idy := 0;
              lngth := Length( s );
              IF lngth < 2
              THEN
                sub[0] := 0C;
                str[0] := 0C;
                scr[0] := 0C;
                RETURN;
              END (* if lngth *);
              WHILE ( idx < lngth ) AND ( ( s[idx] < '0' ) OR ( s[idx] > '9' )
                    ) DO
                IF idx < lngth
                THEN
                  INC( idx );
                ELSE
                  sub[0] := 0C;
                  str[0] := 0C;
                  scr[0] := 0C;
                  RETURN;
                END (* if idx *);
              END;   (* odwalone niecyfry *)
              idy := idx;
              (* przepisanie ramki z pominieciem liter z s do sub *)
              WHILE ( idx < lngth ) AND ( s[idx] >= '0' ) AND ( s[idx] <= '9' )
              DO
                INC( idx );
              END (* while *);
              Copy( s, idy, idx - idy - 2, sub );
              Copy( s, idx - 2, 2, str );
              i := 0;
              INC( idx );
              WHILE ( idx < lngth ) AND ( i <= 3 ) AND ( s[idx] >= '0' ) AND
                    ( s[idx] <= '9' ) DO
                scr[i] := s[idx];
                INC( i );
                INC( idx );
              END (* while *);
              scr[i] := 0C;
            END Isolate;

          BEGIN
            Isolate( sub, str, scr );   (* wyeliminowanie nie cyfr*)
            StringToInt( sub, wg.Stopnie, ok );   (* zamiana sub na
                                                  wg.Stopnie*)
            IF NOT ok
            THEN
              RETURN FALSE
            END (* if *);
            StringToCard( str, wg.Minuty, ok );   (* zamiana sub nawg.Minuty*)
            IF NOT ok
            THEN
              RETURN FALSE
            END (* if *);
            StringToCard( scr, wg.DziesTys, ok );   (* zamiana str na
                                                    wg.Setne*)
            IF NOT ok
            THEN
              RETURN FALSE
            END (* if *);
            RETURN TRUE
          END ConvertStrToWspGeo;

        BEGIN
          DekomozycjaRamki( bufor, bufPosition, buforT );
          ok := ConvertStrToWspGeo( buforT, wg );
          IF NOT ok
          THEN
            RETURN FALSE
          END (* if *);
          RETURN TRUE
        END GetWspGeo;

      BEGIN
        bufPosition := 0;   (* CZAS*)
        stanGPGGA := headerGPG;
        LOOP
          IF NOT szukaniePola( bufor, bufPosition )
          THEN
            EXIT
          END (* if *);
          IF stanGPGGA < endGPG
          THEN
            INC( stanGPGGA );
          END (* if CzescRamki *);
          CASE stanGPGGA OF
            latGPG :
              ok := GetWspGeo( bufor, bufPosition, pg.Szerokosc );
              IF NOT ok
              THEN
                UstawFlage;
                EXIT
              END (* if *);
            |
            lonGPG :
              ok := GetWspGeo( bufor, bufPosition, pg.Dlugosc );
              IF NOT ok
              THEN
                UstawFlage;
                EXIT
              END (* if *);
            |
            gpsqualGPG :
              DekomozycjaRamki( bufor, bufPosition, buforT );
              IF buforT[0] = '1'
              THEN
              (* $R-*)
                INC( currentSign );
                (* $R= *)
                diffmode := FALSE;
                ObecnyStan := StanGPS { SaNoweDane };
              ELSIF buforT[0] = '2'
              THEN
              (* $R-*)
                INC( currentSign );
                (* $R= *)
                diffmode := TRUE;
                ObecnyStan := StanGPS { SaNoweDane };
              ELSE
                UstawFlage;
                EXIT
              END (* if buforT *);
          ELSE
            ;
          END (* case CzescRamki *);
        END (* loop *);
      END An_Frame_GPGGA;

      PROCEDURE An_Frame_GPVTG;

      TYPE
        ramkaGPVTG =
          ( headerGPV,
            tracktrueGPV,
            TGPV,
            trackmagGPV,
            MGPV,
            speedKnGPV,
            NGPV,
            speedKmGPV,
            KGPV,
            endGPV );

      VAR
        stanGPVTG   : ramkaGPVTG;
        bufPosition : CARDINAL;

      BEGIN
        bufPosition := 0;   (* CZAS*)
        stanGPVTG := headerGPV;
        LOOP
          IF NOT szukaniePola( bufor, bufPosition )
          THEN
            EXIT
          END (* if *);
          IF stanGPVTG < endGPV
          THEN
            INC( stanGPVTG );
          END (* if CzescRamki *);
          CASE stanGPVTG OF
            tracktrueGPV :
              tog := GetReal( bufor, bufPosition );
          ELSE
            ;
          END (* case CzescRamki *);
        END (* loop *);
      END An_Frame_GPVTG;

      PROCEDURE An_Frame_GPZDA;

      TYPE
        ramkaGPZDA =
          ( headerGPZ,
            utcGPZ,
            dayGPZ,
            monthGPZ,
            yearGPZ,
            null1GPZ,
            null2GPZ,
            endGPZ );

      VAR
        stanGPZDA   : ramkaGPZDA;
        day,
        month,
        year,
        hour,
        min,
        sec,
        bufPosition : CARDINAL;

        PROCEDURE Wydziel
                  ( VAR buf : ARRAY OF CHAR;
                    VAR a,
                        b,
                        c   : CARDINAL      ) : BOOLEAN;

        VAR
          s1,
          s2 : ARRAY [ 0 .. 5 ] OF CHAR;
          ok : BOOLEAN;

        BEGIN
          Copy( buf, 2, 2, s1 );
          Copy( buf, 4, 2, s2 );
          buf[2] := 0C;
          StringToCard( buf, a, ok );
          IF NOT ok
          THEN
            RETURN FALSE
          END (* if *);
          StringToCard( s1, b, ok );
          IF NOT ok
          THEN
            RETURN FALSE
          END (* if *);
          StringToCard( s2, c, ok );
          IF NOT ok
          THEN
            RETURN FALSE
          END (* if *);
          RETURN TRUE;
        END Wydziel;

      BEGIN
        day := 0;
        month := 0;
        year := 0;
        hour := 0;
        min := 0;
        sec := 0;
        bufPosition := 0;
        stanGPZDA := headerGPZ;
        LOOP
          IF NOT szukaniePola( bufor, bufPosition )
          THEN
            EXIT
          END (* if *);
          IF stanGPZDA < endGPZ
          THEN
            INC( stanGPZDA );
          END (* if CzescRamki *);
          CASE stanGPZDA OF
            utcGPZ :
              DekomozycjaRamki( bufor, bufPosition, buforT );
              ok := Wydziel( buforT, hour, min, sec );
              IF NOT ok
              THEN
                UstawFlage;
                EXIT;
              END (* if *);
            |
            dayGPZ :
              day := GetCardinal( bufor, bufPosition );
              IF day = NilValC
              THEN
                UstawFlage;
                EXIT
              END (* if *);
            |
            monthGPZ :
              month := GetCardinal( bufor, bufPosition );
              IF month = NilValC
              THEN
                UstawFlage;
                EXIT
              END (* if *);
            |
            yearGPZ :
              year := GetCardinal( bufor, bufPosition );
              IF year = NilValC
              THEN
                UstawFlage;
                EXIT
              END (* if *);
              IF year # 0
              THEN
                SetTime( hour, min, sec );
                SetDate( year, month, day );
                Concat( 'unlog com1 gpzda', eos, bufor );   (* komunikat
                                                               inicjacyjny
                                                            DGPS*)
                WriteString( GPSChannel, bufor, 18 );   (* inicjacja dgps*)
              END (* if year *);
          ELSE
            ;
          END (* case CzescRamki *);
        END (* loop *);
      END An_Frame_GPZDA;

    BEGIN (* GetFrame *)
      ok := TRUE;
      LOOP   (* poczatek glownej funkcji programu*)
        IF GetStrFromGps( bufor )
        THEN
          INC( T_CalaRamka );
          EXCL( ObecnyStan, NieMaTransmisji );
          Copy( bufor, 0, 4, buforT );
          buforT[4] := 0C;
          IF buforT[0] = 'D'
           THEN
            An_Frame_DOPA;
          ELSIF ( buforT[0] = 'G' ) AND ( buforT[2] = 'G' )
          THEN
            An_Frame_GPGGA;
          ELSIF ( buforT[0] = 'G' ) AND ( buforT[2] = 'V' )
          THEN
            An_Frame_GPVTG;
          ELSIF ( buforT[0] = 'G' ) AND ( buforT[2] = 'Z' )
          THEN
            An_Frame_GPZDA;
          END;   (* koniec dekompozycji ramki*)
        ELSE
          INC( T_BrakRamki );
          EXIT;
        END (* if GetStrFromGps *);
      END (* loop *);
    END GetFrame;

  VAR
    CosPrzyszlo : StanGPS;

  BEGIN (* GPSReadPos *)
    EPE := DisNilVal;
    GetFrame;
    dtaSign := currentSign;
    IF DaneZatechle IN ObecnyStan
    THEN
      GDOP := DisNilVal;
      NOS := NilValC;
      DiffMode := FALSE;
      RETURN ObecnyStan;
    ELSE
      pgret := pg;   (* przepisanie danych *)
      GDOP := gdop;
      NOS := NumberOfSattelites;
      DiffMode := diffmode;
      CosPrzyszlo := ObecnyStan;
      EXCL( ObecnyStan, SaNoweDane );
      RETURN CosPrzyszlo;   (* zwrocenie stanu gps *)
    END (* if DaneZatechle *);
  END GPSReceive;

  PROCEDURE GetDirection
            ( VAR dtaSign : DtaSignType ) : REAL;
    (* kierunek lotu wzg N*)

  BEGIN
    dtaSign := currentSign;
    RETURN tog;
  END GetDirection;

  PROCEDURE GetCurrDataSign() : DtaSignType;

  BEGIN
    RETURN currentSign;
  END GetCurrDataSign;

  PROCEDURE WatchDog;

  TYPE
    stanyGPS =
      ( inicjacja,
        odczyt );

  VAR
    StanHGPS    : stanyGPS;
    wd_currSign : CARDINAL;
    wd_prevSign : CARDINAL;
    pg          : PolozenieGeo;
    GDOP        : CARDINAL;
    NOS         : CARDINAL;
    EPE         : CARDINAL;
    DiffMode    : BOOLEAN;
    stan        : StanGPS;
    waitTime    : CARDINAL;

  BEGIN
    wd_prevSign := GetCurrDataSign( );
    StanHGPS := inicjacja;
    waitTime := 0;
    LOOP
      Wait( waitTime );
      CASE StanHGPS OF
        inicjacja :
          Concat( 'messages com2 off', eos, bufor );   (* komunikat inicjacyjny
                                                       DGPS*)
          WriteString( GPSChannel, bufor, 19 );   (* inicjacja dgps*)
          Concat( 'log com1 dopa ontime 3.0 1', eos, bufor );   (* komunikat
                                                                   inicjacyjny
                                                                DGPS*)
          WriteString( GPSChannel, bufor, 29 );
          Concat( 'log com1 gpvtg ontime 3.2 1', eos, bufor );   (* komunikat
                                                                    inicjacyjny
                                                                 DGPS*)
          WriteString( GPSChannel, bufor, 29 );
          Concat( 'com2 9600,n,8,1,n,on', eos, bufor );   (* komunikat
                                                             inicjacyjny DGPS*)
          WriteString( GPSChannel, bufor, 23 );   (* inicjacja dgps*)
          Concat( 'accept com2 commands', eos, bufor );   (* komunikat
                                                             inicjacyjny DGPS*)
          WriteString( GPSChannel, bufor, 23 );   (* inicjacja dgps*)
          Concat( 'log com1 gpzda ontime 3 1', eos, bufor );   (* komunikat
                                                                  inicjacyjny
                                                               DGPS*)
          WriteString( GPSChannel, bufor, 29 );
          Concat( 'log com1 gpgga ontime 0.13', eos, bufor );   (* komunikat
                                                                   inicjacyjny
                                                                DGPS*)
          WriteString( GPSChannel, bufor, 28 );   (* inicjacja dgps*)
          T_BylDolar := 0;
          T_OlalZnak := 0;
          T_ZlyZnakNaKoncu := 0;
          T_ZlSuma := 0;
          T_CalaRamka := 0;
          T_BrakRamki := 0;
          T_BylaFlaga := 0;
          INC( T_BylaInicjacja );
          StanHGPS := odczyt;
          waitTime := TInOneSecond( ) * 5;
          actPart := head;
        |
        odczyt :
          stan := GPSReceive( pg, GDOP, NOS, EPE, DiffMode, wd_currSign );
          IF wd_currSign = wd_prevSign
          THEN
            gdop := DisNilVal;
            diffmode := FALSE;
            tog := 0.0;
            NumberOfSattelites := NilValC;
            StanHGPS := inicjacja;
            waitTime := 0;
            ObecnyStan := StanGPS { NieMaTransmisji, Flaga, BledyWTransmisji,
                          DaneZatechle };
          ELSE
            wd_prevSign := wd_currSign;
            waitTime := TInOneSecond( ) * 2;
          END (* if wd_currSign *);
      END (* case StanHGPS *);
    END (* loop *);
  END WatchDog;

BEGIN
  actPart := head;
  posInRecBuf := 0;
  diffmode := FALSE;
  ObecnyStan := StanGPS { NieMaTransmisji, Flaga, BledyWTransmisji,
                DaneZatechle };
  gdop := DisNilVal;
  tog := 0.0;
  eos[0] := CHR( 0DH );   (* nowa linnia*)
  eos[1] := CHR( 0AH );   (* powrot karetki*)
  eos[2] := CHR( 0H );   (* powrot karetki*)
  T_BylaInicjacja := 0;
  NumberOfSattelites := NilValC;
  IF NOT SetBaudRate( GPSChannel, 96, 8 )
  THEN
    NewMessage( Nie_mozna_uruchomic_kanalu_GPS,
                "Nie mo¾na uruchomi† kanaˆu GPS", BITSET( 9090H ) );
    Display( Nie_mozna_uruchomic_kanalu_GPS );
  END (* if *);
  STARTPROCESS( WatchDog, 0800H, 0 );
END GPSRead.
