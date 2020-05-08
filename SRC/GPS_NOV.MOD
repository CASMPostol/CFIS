(*.F- *)
(**********************************************************************
|  Title   : Analizator ramek dla GPS Novatel 
|            Uwaga: modul nie jest monitore - moze byc wykorzystywany 
|            tylko przez jedenego urzytkownika
|  Author  : M.Postol
|  System  : LOGITECH MODULA-2/86 
|  History :
|    Rel. 3.00
|      utworzony
|
|  Copyright (C), CAS LODZ POLAND.
|  TEL: 42' 686 25 47
|  mailto: techsupp@cas.com.pl
|  http: www.cas.com.pl
|
**********************************************************************)
(*.F+ *)

IMPLEMENTATION  MODULE  GPS_nov;
  
  FROM CommonTypes IMPORT
    WspGeo, SigNilVal, NilValC, N_GPSChannel, N_DGPSChannel, 
    N_MGPSChannel;

  FROM NumberConversion IMPORT
    StringToCard, StringToInt;

  FROM RealConversions IMPORT
    StringToReal;

  FROM BitByteOps IMPORT
    ByteXor;

  FROM DigiRS IMPORT
    ReadString, WriteString, SetBaudRate;

  FROM Strings IMPORT
    Copy, Concat, Length;

  FROM Messages IMPORT
    Message, NewMessage, Display;

  FROM SpecConv IMPORT
    IncRound, entierCheck;
    
  FROM TheodolitRead IMPORT
    Kopiowanie;
    
   FROM MANAGER IMPORT
     Assert;
     
   FROM MathLib0  IMPORT
     real, entier;
     
TYPE
  str110  = ARRAY [ 0 .. 110 ] OF CHAR;
  part    = (head, body, CRC);
  
VAR
  actPart      : part;
  sumaModC     : CHAR;
  sumaModF     : CARDINAL;
  posInRecBuf  : CARDINAL;
  bufor        : str110;  (* w bufor znajduje sie ramka z gps*)
  eos          : ARRAY [ 0 .. 2 ] OF CHAR;
  err_unrec_cnt: CARDINAL;
  
PROCEDURE KopijZnakZTeo (ch : CHAR);
BEGIN
  WriteString( N_DGPSChannel, ch, 1 );   
END KopijZnakZTeo;

PROCEDURE KopZnakDoKanaluMonitora (ch : CHAR);
  (* kopiowanie znaku w celach serwisowych do kanalu monitorujacego *)
BEGIN
  WriteString(N_MGPSChannel , ch, 1 );   
END KopZnakDoKanaluMonitora;

PROCEDURE GetFrame
         ( VAR Last_Data   : FrameData ) : BOOLEAN;

  TYPE
    str14 = ARRAY [ 0 .. 14 ] OF CHAR;

  VAR
    buforT      : str14;  (* bufor pomocniczy do konwersji*)

  PROCEDURE ReadGPS
            ( VAR s : str110 ) : BOOLEAN;
  VAR
    ok :BOOLEAN;
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

  BEGIN (* ReadGPS *)
    (* szukanie poczatka ramki*)
    LOOP
      IF ReadString( N_DGPSChannel, cChar, 1 ) <> 1
      THEN
        RETURN FALSE;
      END (* if RdChar *);
      KopZnakDoKanaluMonitora( cChar);
      IncRound(chrCount);
      
      CASE actPart OF

      head :
        IF cChar = '$'
        THEN
          actPart := body;
          sumaModC := 0C;   (* znacznik sumy*)
          posInRecBuf := 0;
        END (* if cChar *);
      |
      body :
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
          IF posInRecBuf >  HIGH( s ) THEN
            actPart := head;
          END;
        END (* if *);

        |
        CRC :
          IF cChar <= ' '
          THEN
            actPart := head;
          ELSE
            sumaModF := ConvertHexChar(cChar, ok) * posInRecBuf + sumaModF;
            posInRecBuf := posInRecBuf DIV 16;
            IF posInRecBuf = 0
            THEN
              actPart := head;
              IF sumaModF = ORD( sumaModC )
              THEN
                RETURN TRUE;
              END (* if sumaModF *);
              IncRound(framesWError);
              RETURN FALSE;
            END (* if i *);
          END (* if *);
      END (* case actPart *);
    END (* loop *);
  END ReadGPS; (* koniec czytania ramki*)


  PROCEDURE szukaniePola
            ( VAR bufor : ARRAY OF CHAR;
              VAR pos   : CARDINAL      );
  (* procedura szuka przecika w buforze *)
  
  BEGIN
    WHILE ( bufor[pos] <> ',' ) AND ( bufor[pos] <> 0C)   DO
      INC( pos );
    END;
    IF bufor[pos] <> 0C THEN
      INC( pos );
    END;
  END szukaniePola;

  PROCEDURE DekomozycjaRamki
            ( VAR bufor  : ARRAY OF CHAR;
              VAR n      : CARDINAL;
              VAR buforT : ARRAY OF CHAR );
     (* procedura kopiuje pole (do przecinka) ramki do buforT *)
      
  VAR
    k : CARDINAL;

  BEGIN
    k := 0;
    WHILE ( bufor[n] <> ',' ) AND ( bufor[n] <> 0C ) AND 
          ( k <= HIGH( buforT ) ) 
    DO
      buforT[k] := bufor[n];
      INC( k );
      INC( n )
    END (* while *);
    IF k < HIGH( buforT )
    THEN
      buforT[k] := 0C;
    END (* if k *);
    szukaniePola( bufor, n);
  END DekomozycjaRamki;


  PROCEDURE GetReal
            ( VAR bufor       : ARRAY OF CHAR;
              VAR bufPosition : CARDINAL;
              VAR gdop        : REAL): BOOLEAN;

  VAR
    buforT    : str14;
    ok        : BOOLEAN;

  BEGIN
    DekomozycjaRamki( bufor, bufPosition, buforT );
    StringToReal( buforT, gdop, ok );
    RETURN ok
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
    RETURN 0
  END GetCardinal;

  PROCEDURE GetInteger
            ( VAR bufor       : ARRAY OF CHAR;
              VAR bufPosition : CARDINAL      ) : INTEGER;

  VAR
    buforT : str14;
    wynik  : INTEGER;
    ok     : BOOLEAN;

  BEGIN
    DekomozycjaRamki( bufor, bufPosition, buforT );
    StringToInt( buforT, wynik, ok );
    IF ok
    THEN
      RETURN wynik
    END (* if ok *);
    RETURN SigNilVal;
  END GetInteger;

  PROCEDURE An_Frame_DOPA
            ( VAR Data : FrameData);


  VAR
    bufPosition : CARDINAL;
    gdopR       : REAL;

  BEGIN (* An_Frame_DOPA *)
    bufPosition := 0;
    WITH Data  DO
      Frame := FT_DOPA;
      (* DOPA *)
      szukaniePola( bufor, bufPosition );
      (* weekD *)
      szukaniePola( bufor, bufPosition );
      (* secondsD *)
      szukaniePola( bufor, bufPosition );
      IF GetReal( bufor, bufPosition, gdopR ) AND  
         entierCheck(gdopR * 100., Gdop )
         (* AND musi byc by wykonal sie entierCheck *)
      THEN
      ELSE
        Gdop := SigNilVal;
      END (* if gdop *);
    END (* WITH Data *)
  END An_Frame_DOPA;

  PROCEDURE An_Frame_GPGGA
            ( VAR Data : FrameData);

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
          WHILE ( idx < lngth ) AND 
                ( ( s[idx] < '0' ) OR ( s[idx] > '9' ) ) 
          DO
            IF idx < lngth
            THEN
              INC( idx );
            ELSE
              sub[0] := 0C;
              str[0] := 0C;
              scr[0] := 0C;
              RETURN;
            END (* if idx *);
          END; (* odwalone niecyfry *)
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
                ( s[idx] <= '9' ) 
          DO
            scr[i] := s[idx];
            INC( i );
            INC( idx );
          END (* while *);
            scr[i] := 0C;
          END Isolate;

      BEGIN (* ConvertStrToWspGeo *)
        Isolate( sub, str, scr );  (* wyeliminowanie nie cyfr*)
        StringToInt( sub, wg.Stopnie, ok ); (* zamiana sub na wg.Stopnie*)
        IF NOT ok THEN
          RETURN FALSE
        END (* if *);
        StringToCard( str, wg.Minuty, ok ); (* zamiana sub nawg.Minuty*)
        IF NOT ok THEN
          RETURN FALSE
        END (* if *);
        StringToCard( scr, wg.DziesTys, ok ); (* zamiana str na wg.Setne*)
        IF NOT ok THEN
          RETURN FALSE
        END (* if *);
        RETURN TRUE
      END ConvertStrToWspGeo;

    BEGIN (* GetWspGeo *)
      DekomozycjaRamki( bufor, bufPosition, buforT );
      IF NOT ConvertStrToWspGeo( buforT, wg )
      THEN
        RETURN FALSE
      END (* if *);
      RETURN TRUE
    END GetWspGeo;

  BEGIN (* An_Frame_GPGGA *)
    bufPosition := 0;
    stanGPGGA := headerGPG;
    WITH Data DO
      Frame := FT_GPGGA;
      szukaniePola( bufor, bufPosition );
      szukaniePola( bufor, bufPosition) ;
      IF NOT GetWspGeo( bufor, bufPosition, polGeo.Szerokosc )
      THEN
      END (* if *);
      szukaniePola( bufor, bufPosition );
      IF NOT GetWspGeo( bufor, bufPosition, polGeo.Dlugosc )
      THEN
      END (* if *);
      szukaniePola( bufor, bufPosition );
      mode := VAL(Quolity, GetCardinal( bufor, bufPosition ));
      NumberOfSattelites := GetInteger( bufor, bufPosition );
    END (* WITH Data *);
  END An_Frame_GPGGA;

  PROCEDURE An_Frame_GPVTG
            ( VAR Data : FrameData);

  VAR
    bufPosition : CARDINAL;

  BEGIN (* An_Frame_GPVTG *)
    bufPosition := 0;
    WITH Data DO
      Frame := FT_GPVTG;
      szukaniePola( bufor, bufPosition );
      IF NOT GetReal( bufor, bufPosition, tog) THEN
        tog := 0.0
      END;
    END (* WITH Data *);
  END An_Frame_GPVTG;

  PROCEDURE An_Frame_GPZDA
            (VAR Data : FrameData);

  VAR
    bufPosition : CARDINAL;

    PROCEDURE Wydziel
              ( VAR buf : ARRAY OF CHAR;
                VAR a,
                    b,
                    c   : CARDINAL      );
    TYPE
      Str5 = ARRAY [ 0 .. 5 ] OF CHAR;
    VAR
      s1 : Str5; 
      s2 : Str5;
      ok : BOOLEAN;

    BEGIN (* Wydziel *)
      Copy( buf, 2, 2, s1 );
      Copy( buf, 4, 2, s2 );
      buf[2] := 0C;
      StringToCard( buf, a, ok );
      StringToCard( s1, b, ok );
      StringToCard( s2, c, ok );
    END Wydziel;

  BEGIN (* An_Frame_GPZDA *)
    WITH Data  DO
      Frame := FT_GPZDA;
      bufPosition := 0;
      szukaniePola( bufor, bufPosition );
      DekomozycjaRamki( bufor, bufPosition, buforT );
      Wydziel( buforT, hour, min, sec );
      day := GetCardinal( bufor, bufPosition );
      month := GetCardinal( bufor, bufPosition );
      year := GetCardinal( bufor, bufPosition );
    END (* WITH Data*);
  END An_Frame_GPZDA;

  BEGIN (* GetFrame *)
    IF NOT ReadGPS( bufor )
    THEN
      RETURN FALSE;
    END; (* IF NOT GetStrFromGp *)
    Copy( bufor, 0, 4, buforT );
    buforT[4] := 0C;
    IncRound(frmCount);
    IF (buforT[0] = 'D')  AND ( buforT[2] = 'P')
    THEN
      An_Frame_DOPA(Last_Data);
    ELSIF ( buforT[0] = 'G' ) AND ( buforT[2] = 'G' )
    THEN
      An_Frame_GPGGA(Last_Data);
    ELSIF ( buforT[0] = 'G' ) AND ( buforT[2] = 'V' )
    THEN
      An_Frame_GPVTG(Last_Data);
    ELSIF ( buforT[0] = 'G' ) AND ( buforT[2] = 'Z' )
    THEN
      An_Frame_GPZDA(Last_Data);
    ELSE
      IncRound(err_unrec_cnt);
      RETURN FALSE;
    END; (* IF buforT *)
    RETURN TRUE;
END GetFrame;
 
PROCEDURE Inicjacja;
VAR
  bufor        : ARRAY [0..40] OF CHAR;  (* w bufor znajduje sie ramka z gps*)
BEGIN
  (* USTAWIENIE COM2 *)
  
  (* komunikat inicjacyjny DGPS *)
  Concat( 'messages com2 off', eos, bufor );
  WriteString( N_GPSChannel, bufor, Length(bufor) );

  (* GPS Com2 uzywany jest do czytania poprawekkomunikat inicjacyjny DGPS *)
  Concat( 'com2 115200,n,8,1,n,off', eos, bufor );   
  WriteString( N_GPSChannel, bufor, Length(bufor) );   
          
  (* komunikat inicjacyjny DGPS*)
  Concat( 'accept com2 commands', eos, bufor );   
  WriteString( N_GPSChannel, bufor, Length(bufor) );

  (* komunikat inicjacyjny DGPS*)
  Concat( 'UNLOGALL', eos, bufor );   
  WriteString( N_GPSChannel, bufor, Length(bufor) );

  (* NEMA Global position fix data - komunikat inicjacyjny DGPS *)
  Concat( 'log com2 gpgga ontime 0.14', eos, bufor );   
  WriteString( N_GPSChannel, bufor, Length(bufor) );
  
  (* Novatell - Dilution of precision - komunikat inicjacyjny DGPS *)
  Concat( 'log com2 dopa ontime 10.0 0.1', eos, bufor );   
  WriteString( N_GPSChannel, bufor, Length(bufor) );

  (* NEMA Track and ground speed - komunikat inicjacyjny DGPS *)
  Concat( 'log com2 gpvtg ontime 3.0 0.2', eos, bufor );   
  WriteString( N_GPSChannel, bufor, Length(bufor) );

  (* NEMA - Time and Date - komunikat inicjacyjny DGPS *)
  Concat( 'log com2 gpzda ontime 30.0 0.3', eos, bufor );   
  WriteString( N_GPSChannel, bufor, Length(bufor) );

  (* NEMA - Time and Date - komunikat inicjacyjny DGPS *)
  Concat( 'log com1 rcca ontime 10.0 0.0', eos, bufor );   
  WriteString( N_GPSChannel, bufor, Length(bufor) );
  
  (* NEMA - Time and Date - komunikat inicjacyjny DGPS *)
  Concat( 'log com1 rcsa ontime 10.0 5', eos, bufor );   
  WriteString( N_GPSChannel, bufor, Length(bufor) );
  
  (* DGPS timeout *)
  Concat( 'DGPSTIMEOUT 22,300', eos, bufor );   
  WriteString( N_GPSChannel, bufor, Length(bufor) );
  
END Inicjacja;

PROCEDURE gpzdaOff;
BEGIN
  Concat( 'unlog com2 gpzda', eos, bufor );   
  WriteString( N_GPSChannel, bufor, Length(bufor) );
END gpzdaOff;

VAR
  BladKanaluGPS : Message;

BEGIN
  Kopiowanie := KopijZnakZTeo;
  actPart := head;
  sumaModC := 0C;
  posInRecBuf := 0;
  framesWError:= 0;
  err_unrec_cnt := 0;
  eos[0] := CHR( 0DH );   (* nowa linnia*)
  eos[1] := CHR( 0AH );   (* powrot karetki*)
  eos[2] := CHR( 0H );   (* powrot karetki*)
  chrCount := 0;
  frmCount := 0;
  IF NOT (SetBaudRate( N_GPSChannel,    96, 8 ) AND
          SetBaudRate( N_DGPSChannel, 1152, 8 ) AND
          SetBaudRate( N_MGPSChannel, 1152, 8 ))
  THEN
    NewMessage( BladKanaluGPS,
                "Nie mo¾na uruchomi† kanaˆu GPS", BITSET( 9090H ) );
    Display( BladKanaluGPS );
  END (* if *);
END GPS_nov.
