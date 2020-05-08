(*.F- *)
(**********************************************************************
|  Title   : Analizator ramek dla GPS tRIMBLE 
|            Uwaga: modul nie jest monitore - moze byc wykorzystywany 
|            tylko przez jedenego urzytkownika
|  Author  : M.Postol
|  System  : LOGITECH MODULA-2/86 
|  History :
|    Rel. 3.00
|       utworzony
|
|  Copyright (C), CAS LODZ POLAND.
|  TEL: 42' 686 25 47
|  mailto: techsupp@cas.com.pl
|  http: www.cas.com.pl
|
**********************************************************************)
(*.F+ *)

IMPLEMENTATION MODULE GPS_TRIMBLE;  

  FROM ASCII IMPORT
    stx, etx;
    
  FROM CommonTypes IMPORT
    WspGeo, T_GPSChannel;

  FROM NumberConversion IMPORT
    StringToCard, StringToInt;

  FROM DigiRS IMPORT
    ReadString, SetBaudRate;

  FROM Strings IMPORT
    Copy, Delete;

  FROM Messages IMPORT
    Message, NewMessage, Display;

  FROM SpecConv IMPORT
    IncRound;

TYPE
    str63         = ARRAY[0..63] OF CHAR;
    part          = (Heading, SkipEOL, Body);

VAR
    actPart                : part;
    posInRecBuf            : CARDINAL;
    bufor                  : str63;
    L_epe                  : CARDINAL;
    L_WspSzerokosc         : WspGeo;
    L_WspDlugosc           : WspGeo;
    L_Kierunek             : REAL;
    L_FixNotAvailable      : BOOLEAN;
    L_month, L_day, L_year : CARDINAL;
    L_hour, L_min, L_sec   : CARDINAL;
    L_NumberOfSattelites   : CARDINAL;
    
PROCEDURE GetFrame
         ( VAR Data   : FrameData ) : BOOLEAN;

  PROCEDURE ReadPacketHead (): BOOLEAN ;
  VAR
    cChar : CHAR;
  BEGIN
    WHILE ReadString( T_GPSChannel, cChar, 1) = 1   DO
      IncRound(chrCount);
      IF cChar = stx THEN
        RETURN TRUE
      END (* if IF cChar *);
    END (* WHILE ReadString *);
    RETURN FALSE
  END ReadPacketHead;

  PROCEDURE  ReadEOL(VAR cChar : CHAR): BOOLEAN;
  BEGIN
    WHILE ReadString( T_GPSChannel, cChar, 1) = 1   DO
      IncRound(chrCount);
      IF cChar = etx THEN
        RETURN TRUE
      ELSIF cChar > ' ' THEN
        RETURN TRUE
      END (* if IF cChar *);
    END (* WHILE ReadString *);
    RETURN FALSE
  END ReadEOL;
  
  PROCEDURE ReadGPS
            ( VAR s : str63 ) : BOOLEAN;
  VAR
    cChar : CHAR;

  BEGIN (* ReadGPS *)
    WHILE ReadString( T_GPSChannel, cChar, 1) = 1  DO
      IncRound(chrCount);
      IF cChar >= ' '  THEN
        s[ posInRecBuf ] := cChar;
        INC( posInRecBuf );
      ELSE
        s[posInRecBuf] := 0C;
        RETURN TRUE;
      END (* IF cChar > ' ' *);
    END;
    RETURN FALSE;
  END ReadGPS;

  PROCEDURE ReadG( VAR s  : ARRAY OF CHAR;
                   VAR wg : WspGeo;
                       Sz : BOOLEAN        ) : BOOLEAN;

  VAR
    sub,
    str : ARRAY [ 0 .. 8 ] OF CHAR;
    idx : CARDINAL;
    ok  : BOOLEAN;

  PROCEDURE WspGeoPoprawne
            ( VAR wg        : WspGeo;
                  Szerokosc : BOOLEAN ) : BOOLEAN;

  BEGIN
    IF Szerokosc THEN
      IF ABS( wg.Stopnie ) > 90
      THEN
        RETURN FALSE;
      END (* if ABS *);
    ELSE
      IF ABS( wg.Stopnie ) > 180 THEN
        RETURN FALSE;
      END (* if ABS *);
    END (* if Szerokosc *);
    IF wg.Minuty >= 60 THEN
      RETURN FALSE;
    END (* if wg.Minuty *);
    IF wg.DziesTys > 9900 THEN
      RETURN FALSE;
    END (* if wg.Setne *);
    RETURN TRUE;
  END WspGeoPoprawne;

    PROCEDURE Isolate;

    VAR
      i : CARDINAL;

    BEGIN
      WHILE ( s[idx] < '0' ) OR ( s[idx] > '9' ) DO
        IF idx < HIGH( s ) THEN
          INC( idx );
        ELSE
          sub[0] := 0C;
          RETURN;
        END (* if idx *);
      END;   (* odwalone niecyfry *)
      i := 0;
      REPEAT
        sub[i] := s[idx];
        INC( i );
        INC( idx );
      UNTIL ( idx > HIGH( s ) ) OR
            ( s[idx] < '0' ) OR ( s[idx] > '9' );
      sub[i] := 0C;
    END Isolate;

  BEGIN (* ReadG *)
    idx := 0;
    Isolate;
    WITH wg DO
      StringToInt( sub, Stopnie, ok );
      IF NOT ok THEN
        RETURN FALSE;
      END (* if *);
      Isolate;
      str[0] := sub[2];
      str[1] := sub[3];
      str[2] := 0C;
      sub[2] := 0C;
      StringToCard( sub, Minuty, ok );
      IF NOT ok THEN
        RETURN FALSE;
      END (* if *);
      StringToCard( str, DziesTys, ok );
      IF NOT ok THEN
        RETURN FALSE;
      END (* if *);
      DziesTys := DziesTys * 100;
    END;
    RETURN WspGeoPoprawne( wg, Sz );
  END ReadG;

  PROCEDURE TypGPS( VAR str     : ARRAY OF CHAR;
                    VAR NrOfSat : CARDINAL     ) : BOOLEAN;
  VAR
    ok : BOOLEAN;
  BEGIN
    IF str[0] # 'G' THEN (* albo Loran albo roznicowy GPS *)
      RETURN FALSE;
    END;
    Delete( str, 0, 9 );
    str[1] := 0C;
    StringToCard( str, NrOfSat, ok );
    RETURN ok;
  END TypGPS;

  PROCEDURE Wydziel( VAR buf : ARRAY OF CHAR; VAR a, b, c : CARDINAL ) : BOOLEAN;
  VAR
    s1, s2 : ARRAY[0..5] OF CHAR;
    ok : BOOLEAN;
  BEGIN
    Copy( buf, 3, 2, s1 );
    Copy( buf, 6, 2, s2 );
    buf[2] := 0C;
    StringToCard( buf, a, ok );
    IF NOT ok THEN
      RETURN FALSE;
    END;
    StringToCard( s1, b, ok );
    IF NOT ok THEN
      RETURN FALSE;
    END;
    StringToCard( s2, c, ok );
    IF NOT ok THEN
      RETURN FALSE;
    END;
    RETURN TRUE;
  END Wydziel;

  PROCEDURE PodstawWyniki;
  BEGIN
    WITH Data DO
      epe               := L_epe;
      WspSzerokosc      := L_WspSzerokosc;
      WspDlugosc        := L_WspDlugosc;
      Kierunek          := L_Kierunek;
      FixNotAvailable   := L_FixNotAvailable;
      month             := L_month;
      day               := L_day;
      year              := L_year;
      hour              := L_hour;
      min               := L_min;
      sec               := L_sec;
      NumberOfSattelites:= L_NumberOfSattelites;
    END;
  END PodstawWyniki;
  
  VAR
    KierunekC : CARDINAL;
    ok        : BOOLEAN;
    lastchar  : CHAR;

  BEGIN (* GetFrame *)
    LOOP 
      ok := FALSE;
      CASE actPart  OF
        Heading:
          IF ReadPacketHead() THEN
            actPart := SkipEOL;
          ELSE
            RETURN FALSE;
          END;
        |
        SkipEOL:
          IF ReadEOL(lastchar) THEN
            IF lastchar = etx  THEN
              IncRound(frmCount);
              actPart := Heading;
              PodstawWyniki;
              RETURN TRUE;
            END;
            posInRecBuf := 0;
            actPart     := Body;
          ELSE
            RETURN FALSE;
          END (* if *);
        |
        Body:
          IF ReadGPS( bufor ) THEN
            WITH Data DO
              CASE lastchar OF
                'A' :
                   ok := ReadG( bufor, L_WspSzerokosc, TRUE );
              | 'B' :
                   ok := ReadG( bufor, L_WspDlugosc, FALSE );
              | 'C' :
                   StringToCard( bufor, KierunekC, ok );
                   L_Kierunek := FLOAT( KierunekC );
              | 'P' : (* EPE *)
                   StringToCard( bufor, epe, ok );
              | 'T' :
                   L_FixNotAvailable := bufor[3] = "A";
                   ok := TRUE;
              | 'i' :
                   ok := Wydziel( bufor, L_month, L_day, L_year );
              | 'j' :
                   ok := Wydziel( bufor, L_hour, L_min, L_sec );
              | 'z' :
                   ok := TypGPS( bufor, L_NumberOfSattelites );
              ELSE
                ok := TRUE;
              END (* CASE c *);
            END (* WITH Data *);
            IF ok THEN
              actPart := SkipEOL;
            ELSE
              IncRound(framesWError);
              actPart := Heading;
            END (* IF ok *);
          END (* IF ReadGPS *);
      END (* CASE *);
    END (* LOOP *); 
    RETURN ok;
  END GetFrame;

  PROCEDURE Inicjacja;
    (* Procedura inicjuje GPS'a - definjuje jaki ramki maja przychodzic *)
  BEGIN
    framesWError := 0;
    chrCount     := 0;
    frmCount     := 0;
  END Inicjacja;
    
VAR
   BladKanaluGPS : Message;

BEGIN
  framesWError := 0;
  chrCount     := 0;
  frmCount     := 0;
  actPart      := Heading;
  posInRecBuf  := 0;
  IF NOT SetBaudRate( T_GPSChannel, 96, 8 ) THEN
    NewMessage(BladKanaluGPS,
               "Nie mo¾na uruchomi† kanaˆu GPS",
                BITSET(9090H) );
    Display( BladKanaluGPS );
  END;
END GPS_TRIMBLE.
