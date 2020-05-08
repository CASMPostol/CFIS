(*.F- *)
(**********************************************************************
|  Title   : Read data from GPS
|  Author  :
|  System  : LOGITECH MODULA-2/86
|  History :
|    M.Postol: 12.09.95:
|      DtaSignType concept was implemented
|
|  Copyright (C), CAS LODZ POLAND.
|  TEL: 42' 86 58 12, 42' 87 80 44 FAX/TEL: 42' 84 48 40
|
**********************************************************************)
(*.F+ *)

IMPLEMENTATION MODULE GPSRead [ 0 ];

  FROM Database IMPORT
    PolozenieGeo, WspGeo;

  FROM SYSTEM IMPORT
    ADR;

  FROM MANAGER IMPORT
    STARTPROCESS, InitS, InitC, SIGNAL, SEND, WAITS, WAITC, Assert, Condition;

  FROM NumberConversion IMPORT
    StringToCard, StringToInt;

  FROM Timer IMPORT
    Wait, TInOneSecond;

  FROM RTSMain IMPORT
    Terminate, Status, InstallTermProc;

  FROM ASCII IMPORT
    cr, etx, stx;

  FROM RS232Code IMPORT
    BusyRead, Init, StopReading, StartReading;

  IMPORT
    FIO;

  CONST
    DebugVersion = FALSE;
    CommPort     = 2;

  VAR
    F : FIO.File;

  VAR
    pg                  : PolozenieGeo;
    sanowedane          : BOOLEAN;
    BufIdx              : CARDINAL;
    Bufor               : ARRAY [ 0 .. 200 ] OF CHAR;
    OstatniaPrzeczytana : CARDINAL;
    currentSign         : CARDINAL;
    BufferFull          : Condition;

  PROCEDURE GPSReceive
            ( VAR pgret : PolozenieGeo;
              VAR GDOP  : CARDINAL;
              VAR NOS   : CARDINAL;
              VAR EPE   : CARDINAL ) : BOOLEAN;

  VAR
    res : BOOLEAN;

  BEGIN
    pgret := pg;
    res := sanowedane;
    sanowedane := FALSE;
    GDOP := 0;
    NOS := 0;
    EPE := 0;
    RETURN res;
  END GPSReceive;

  PROCEDURE WaitForNewData
            ( VAR dtaSign : DtaSignType );

  BEGIN (* WaitForNewData *)
    IF dtaSign = currentSign
    THEN
      WAITC( BufferFull );
    END (* if dtaSign *);
    dtaSign := currentSign;
  END WaitForNewData;

  PROCEDURE GPSReadPos
            ( VAR pgret   : PolozenieGeo;
              VAR GDOP    : CARDINAL;
              VAR NOS     : CARDINAL;
              VAR EPE     : CARDINAL ;
              VAR dtaSign : DtaSignType  );

  BEGIN (* GPSReadPos *)
    pgret := pg;
    GDOP := 0;
    NOS := 0;
    EPE := 0;
    dtaSign := currentSign;
  END GPSReadPos;

  PROCEDURE GetCurrDataSign() : DtaSignType;

  BEGIN
    RETURN currentSign;
  END GetCurrDataSign;

  PROCEDURE GPSMain;

  VAR
    c  : CHAR;
    ok : BOOLEAN;

    PROCEDURE AnalizujDaneZGPS;

    VAR
      p  : PolozenieGeo;
      s  : ARRAY [ 0 .. 19 ] OF CHAR;
      ok : BOOLEAN;

      PROCEDURE Poprawne
                ( VAR pg : PolozenieGeo ) : BOOLEAN;

        PROCEDURE Poprawne1
                  ( VAR wg        : WspGeo;
                        Szerokosc : BOOLEAN ) : BOOLEAN;

        BEGIN
          IF Szerokosc
          THEN
            IF ABS( wg.Stopnie ) > 90
            THEN
              RETURN FALSE;
            END (* if ABS *);
          ELSE
            IF ABS( wg.Stopnie ) > 180
            THEN
              RETURN FALSE;
            END (* if ABS *);
          END (* if Szerokosc *);
          IF wg.Minuty >= 60
          THEN
            RETURN FALSE;
          END (* if wg.Minuty *);
          IF wg.Setne >= 100
          THEN
            RETURN FALSE;
          END (* if wg.Setne *);
          RETURN TRUE;
        END Poprawne1;

      BEGIN
        RETURN Poprawne1( pg.Szerokosc, TRUE ) & Poprawne1( pg.Dlugosc, FALSE )
        ;
      END Poprawne;

      PROCEDURE ReadG
                ( VAR s  : ARRAY OF CHAR;
                  VAR wg : WspGeo        ) : BOOLEAN;

      VAR
        sub,
        str : ARRAY [ 0 .. 8 ] OF CHAR;
        idx : CARDINAL;
        ok  : BOOLEAN;

        PROCEDURE Isolate;

        VAR
          i : CARDINAL;

        BEGIN
          WHILE ( s[idx] < '0' ) OR ( s[idx] > '9' ) DO
            IF idx < HIGH( s )
            THEN
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
          UNTIL ( idx > HIGH( s ) ) OR ( s[idx] < '0' ) OR ( s[idx] > '9' );
          sub[i] := 0C;
        END Isolate;

      BEGIN
        idx := 0;
        Isolate;
        StringToInt( sub, wg.Stopnie, ok );
        IF NOT ok
        THEN
          RETURN FALSE;
        END (* if *);
        Isolate;
        str[0] := sub[2];
        str[1] := sub[3];
        str[2] := 0C;
        sub[2] := 0C;
        StringToCard( sub, wg.Minuty, ok );
        IF NOT ok
        THEN
          RETURN FALSE;
        END (* if *);
        StringToCard( str, wg.Setne, ok );
        IF NOT ok
        THEN
          RETURN FALSE;
        END (* if *);
        RETURN TRUE;
      END ReadG;

      PROCEDURE ReadString
                (     Marker : CHAR;
                  VAR s      : ARRAY OF CHAR ) : BOOLEAN;

      VAR
        i : CARDINAL;
        c : CHAR;

        PROCEDURE RdChar() : CHAR;

        VAR
          c : CHAR;

        BEGIN (* RdChar *)
          IF DebugVersion
          THEN
            IF NOT FIO.Read( F, ADR( c ), 1 )
            THEN
              RETURN 0C;
            ELSE
              RETURN c;
            END (* if *);
          ELSE
            IF OstatniaPrzeczytana >= BufIdx
            THEN
              RETURN 0C;
            END (* if OstatniaPrzeczytana *);
            c := Bufor[OstatniaPrzeczytana];
            INC( OstatniaPrzeczytana );
            RETURN c;
          END (* if DebugVersion *);
        END RdChar;

      BEGIN (* ReadString *)
        REPEAT
          c := RdChar( );
          IF c = 0C
          THEN
            RETURN FALSE;
          END (* if c *);
        UNTIL c = Marker;
        i := 0;
        REPEAT
          s[i] := RdChar( );
          INC( i );
        UNTIL s[i - 1] < ' ';
        s[i - 1] := 0C;
        RETURN TRUE;
      END ReadString;

    BEGIN (* AnalizujDaneZGPS *)
      ok := ReadString( "A", s ) & ReadG( s, p.Szerokosc );
      ok := ok & ReadString( "B", s ) & ReadG( s, p.Dlugosc );
      ok := ok & ReadString( "T", s ) & ( s[3] = "A" );
      BledyWTransmisji := NOT ( ok AND Poprawne( p ) );
      IF NOT BledyWTransmisji
      THEN
        pg := p;
        sanowedane := TRUE;
        (*$R-*)
        INC(currentSign);
        (*$R= *)
      ELSE
        sanowedane := FALSE;
      END (* if *)
    END AnalizujDaneZGPS;

  BEGIN (* GPSMain *)
    BufIdx := 0FFFFH;
    LOOP
      LOOP
        BusyRead( c, ok );
        IF ok
        THEN
          EXIT
        END (* if ok *);
        Wait( TInOneSecond( ) * 2 );
        NieMaTransmisji := TRUE;
      END (* loop *);
      NieMaTransmisji := FALSE;
      IF c = stx
      THEN
        BufIdx := 0;
      ELSIF BufIdx # 0FFFFH
      THEN
        IF c = etx
        THEN
          OstatniaPrzeczytana := 0;
          AnalizujDaneZGPS;
          BufIdx := 0FFFFH;
        ELSE
          Bufor[BufIdx] := c;
          IF BufIdx < HIGH( Bufor )
          THEN
            INC( BufIdx );
          END (* if BufIdx *);
        END (* if c *);
      END (* if c *);
    END (* loop *);
  END GPSMain;

  VAR
    ok : BOOLEAN;

BEGIN
  InitC( BufferFull );
  sanowedane := FALSE;
  BledyWTransmisji := FALSE;
  IF DebugVersion
  THEN
    F := FIO.Open( "GPS.LOG" );
  ELSE
    Init( 2400, 1, FALSE, FALSE, 8, ok );
    Assert( ok );
    StartReading;
    InstallTermProc( StopReading );
  END (* if DebugVersion *);
  STARTPROCESS( GPSMain, A00H, 0 );
END GPSRead.
