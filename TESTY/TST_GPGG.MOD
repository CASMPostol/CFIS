(*.F- *)
(**********************************************************************
|  Title   : Test Analizatora
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

MODULE  TST_GPGG;
  
  FROM CommonTypes IMPORT
    WspGeo, NilValC, DisNilVal, N_GPSChannel, N_DGPSChannel, N_MGPSChannel, 
    PolozenieGeo;

  FROM NumberConversion IMPORT
    StringToCard, StringToInt;

  FROM RealConversions IMPORT
    StringToReal;

  FROM Strings IMPORT
    Copy, Concat, Length;

  FROM SpecConv IMPORT
    IncRound;
     
TYPE
  str110  = ARRAY [ 0 .. 110 ] OF CHAR;
  str14   = ARRAY [ 0 .. 14 ] OF CHAR;
  FrameType   = (FT_DOPA, FT_GPGGA, FT_GPVTG, FT_GPZDA);
  Quolity     = (NoFixAvailabl, GPSNormalMode, GPSDiffMode); 
  FrameData   = 
    RECORD
      CASE Frame:  FrameType OF
        FT_DOPA: 
          Gdop               : CARDINAL;
        |
        FT_GPGGA:
          polGeo             : PolozenieGeo;
          mode               : Quolity;
          NumberOfSattelites : CARDINAL;
        |
        FT_GPVTG:
          tog  : REAL;
        |
          FT_GPZDA:
          day   : CARDINAL;
          month : CARDINAL;
          year  : CARDINAL;
          hour  : CARDINAL;
          min   : CARDINAL;
          sec   : CARDINAL;
      END;
    END;

VAR
  bufor        : str110;  (* w bufor znajduje sie ramka z gps*)
  buforT      : str14;  (* bufor pomocniczy do konwersji*)

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
    RETURN NilValC
  END GetCardinal;

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
         ( gdopR * 500. < FLOAT(DisNilVal) )
      THEN
        Gdop := TRUNC( gdopR * 500.0 );
      ELSE
        Gdop := DisNilVal;
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
      NumberOfSattelites := GetCardinal( bufor, bufPosition );
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
VAR
  lastFrame: FrameData;
  ok : BOOLEAN;

BEGIN
  (* bufor := "$GPGGA,123456.9,,,,,0,03,4.6,,,,,"; *)
  bufor := "$GPGGA,100138.1,5144.6283553,N,01925.6228810,E,2,04,11.5,177.03,M,,,2,0000*37";
  An_Frame_GPGGA(lastFrame);
  bufor := "$DOPA,48,381692.55,18.2977,14.0337,16.4361,11.5015,11.7414,4,15,29,25,21*2E";
  An_Frame_DOPA(lastFrame);
  bufor := "$GPVTG,16.086,T,16.086,M,0.0205947,N,0.038141,K*7C";
  An_Frame_GPVTG(lastFrame);
  bufor := "$GPZDA,100138.30,27,07,2000,,*6";
  An_Frame_GPZDA(lastFrame);
END TST_GPGG.
