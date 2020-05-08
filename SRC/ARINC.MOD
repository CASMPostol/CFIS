(*.F- *)
(**********************************************************************
|  Title   : ARINC429 card interface
|  Author  : M.Postol
|  System  : LOGITECH MODULA-2/86
|  History :
|    28-12-94: orginal version
|
|  Copyright (C), CAS LODZ POLAND.
|  TEL: 42' 86 58 12, 42' 87 80 44 FAX/TEL: 42' 84 48 40
|
**********************************************************************)
(*.F+ *)

IMPLEMENTATION MODULE ARINC;

  FROM SYSTEM IMPORT
    INBYTE, OUTBYTE, BYTE;

  CONST
    PortData    = 300H;
    PortComtrol = PortData + 1;
    MaxCount    = 06000H;
    Header      = 0AAH;


  VAR
    maxCountW : CARDINAL;
    maxCountR : CARDINAL;

  PROCEDURE INByte
            ( VAR ch : BYTE ) : BOOLEAN;

  VAR
    status  : BITSET;
    counter : CARDINAL;

  BEGIN
    counter := 0;
    LOOP
      INBYTE( PortComtrol, status );
      IF 0 IN status
      THEN
        INBYTE( PortData, ch );
        RETURN TRUE;
      END (* if *);
      INC( counter );
      IF counter > maxCountR
      THEN
        maxCountR := counter;
      END (* if counter *);
      IF counter > MaxCount
      THEN
        RETURN FALSE;
      END (* if counter *);
    END (* loop *);
  END INByte;

  PROCEDURE OUTByte
            (    ch : BYTE ) : BOOLEAN;

  VAR
    status  : BITSET;
    counter : CARDINAL;

  BEGIN
    counter := 0;
    LOOP
      INBYTE( PortComtrol, status );
      IF NOT ( 1 IN status )
      THEN
        OUTBYTE( PortData, ch );
        RETURN TRUE;
      END (* if *);
      INC( counter );
      IF counter > maxCountW
      THEN
        maxCountW := counter;
      END (* if counter *);
      IF counter > MaxCount
      THEN
        RETURN FALSE;
      END (* if counter *);
    END (* loop *);
  END OUTByte;

  PROCEDURE ReInitialize() : BOOLEAN;

  BEGIN
    IF NOT OUTByte( Header )
    THEN
      RETURN FALSE;
    END (* if *);
    IF NOT OUTByte( 01C )
    THEN
      RETURN FALSE;
    END (* if *);
    IF NOT OUTByte( 00H )
    THEN
      RETURN FALSE;
    END (* if *);
    RETURN TRUE
  END ReInitialize;

  PROCEDURE WriteTXParity
            (    slot       : ShortCardinal;
                 parityEven : BOOLEAN       ) : BOOLEAN;

  BEGIN
    IF NOT OUTByte( Header )
    THEN
      RETURN FALSE;
    END (* if *);
    IF NOT OUTByte( 03C )
    THEN
      RETURN FALSE;
    END (* if *);
    IF NOT OUTByte( 01H )
    THEN
      RETURN FALSE;
    END (* if *);
    IF NOT OUTByte( CHR( slot ) )
    THEN
      RETURN FALSE;
    END (* if *);
    IF NOT OUTByte( parityEven )
    THEN
      RETURN FALSE;
    END (* if *);
    RETURN TRUE
  END WriteTXParity;

  PROCEDURE WriteTXChannel
            (    slot : ShortCardinal;
                 chan : ChannelNu     ) : BOOLEAN;

  BEGIN
    IF NOT OUTByte( Header )
    THEN
      RETURN FALSE;
    END (* if *);
    IF NOT OUTByte( 03C )
    THEN
      RETURN FALSE;
    END (* if *);
    IF NOT OUTByte( 02H )
    THEN
      RETURN FALSE;
    END (* if *);
    IF NOT OUTByte( CHR( slot ) )
    THEN
      RETURN FALSE;
    END (* if *);
    IF NOT OUTByte( CHR( chan ) )
    THEN
      RETURN FALSE;
    END (* if *);
    RETURN TRUE
  END WriteTXChannel;

  PROCEDURE WriteTXLabel
            (    slot  : ShortCardinal;
                 label : ShortCardinal ) : BOOLEAN;

  BEGIN
    IF NOT OUTByte( Header )
    THEN
      RETURN FALSE;
    END (* if *);
    IF NOT OUTByte( 03C )
    THEN
      RETURN FALSE;
    END (* if *);
    IF NOT OUTByte( 03H )
    THEN
      RETURN FALSE;
    END (* if *);
    IF NOT OUTByte( CHR( slot ) )
    THEN
      RETURN FALSE;
    END (* if *);
    IF NOT OUTByte( CHR( label ) )
    THEN
      RETURN FALSE;
    END (* if *);
    RETURN TRUE
  END WriteTXLabel;

  PROCEDURE WriteTXData
            (    slot : ShortCardinal;
                 data : Data          ) : BOOLEAN;

  TYPE
    State =
      ( HeaderSt,
        CountSt,
        CommandTypeSt,
        SlotSt,
        DataBits1St,
        DataBits2St,
        DataBits3St,
        Exit );

  VAR
    lastChar  : CHAR;
    currState : State;

  BEGIN
    currState := HeaderSt;
    LOOP
      CASE currState OF
        HeaderSt :
          lastChar := CHR( Header );
        |
        CountSt :
          lastChar := 05C;
        |
        CommandTypeSt :
          lastChar := 04C;
        |
        SlotSt :
          lastChar := CHR( slot );
        |
        DataBits1St :
          lastChar := data[0];
        |
        DataBits2St :
          lastChar := data[1];
        |
        DataBits3St :
          lastChar := data[2];
        |
        Exit :
          RETURN TRUE;
      END (* case currState *);
      IF NOT OUTByte( lastChar )
      THEN
        RETURN FALSE;
      END (* if *);
      INC( currState );
    END (* loop *);
  END WriteTXData;

  PROCEDURE WriteTXRate
            (    slot : ShortCardinal;
                 rate : CARDINAL      ) : BOOLEAN;

  TYPE
    State =
      ( HeaderSt,
        CountSt,
        CommandTypeSt,
        SlotSt,
        RateLoByteSt,
        RateHiByteSt,
        Exit );

  VAR
    lastChar  : CHAR;
    currState : State;

  BEGIN
    currState := HeaderSt;
    LOOP
      CASE currState OF
        HeaderSt :
          lastChar := CHR( Header );
        |
        CountSt :
          lastChar := 04C;
        |
        CommandTypeSt :
          lastChar := 05C;
        |
        SlotSt :
          lastChar := CHR( slot );
        |
        RateLoByteSt :
          lastChar := CHR( rate MOD 100H );
        |
        RateHiByteSt :
          lastChar := CHR( rate DIV 100H );
        |
        Exit :
          RETURN TRUE;
      END (* case currState *);
      IF NOT OUTByte( lastChar )
      THEN
        RETURN FALSE;
      END (* if *);
      INC( currState );
    END (* loop *);
  END WriteTXRate;

  PROCEDURE WriteKillTime
            (    killTime : CARDINAL ) : BOOLEAN;

  TYPE
    State =
      ( HeaderSt,
        CountSt,
        CommandTypeSt,
        DontCare,
        KillTimeLoSt,
        KillTimeHiSt,
        Exit );

  VAR
    lastChar  : CHAR;
    currState : State;

  BEGIN
    currState := HeaderSt;
    LOOP
      CASE currState OF
        HeaderSt :
          lastChar := CHR( Header );
        |
        CountSt :
          lastChar := 04C;
        |
        CommandTypeSt :
          lastChar := 011C;
        |
        DontCare :
          lastChar := 0C;
        |
        KillTimeLoSt :
          lastChar := CHR( killTime MOD 100H );
        |
        KillTimeHiSt :
          lastChar := CHR( killTime DIV 100H );
        |
        Exit :
          RETURN TRUE;
      END (* case currState *);
      IF NOT OUTByte( lastChar )
      THEN
        RETURN FALSE;
      END (* if *);
      INC( currState );
    END (* loop *);
  END WriteKillTime;

  PROCEDURE WriteCardMode
            (    Fine : BOOLEAN ) : BOOLEAN;

  BEGIN
    IF NOT OUTByte( Header )
    THEN
      RETURN FALSE;
    END (* if *);
    IF NOT OUTByte( 03C )
    THEN
      RETURN FALSE;
    END (* if *);
    IF NOT OUTByte( 08H )
    THEN
      RETURN FALSE;
    END (* if *);
    IF NOT OUTByte( 0C )
    THEN
      RETURN FALSE;
    END (* if *);
    IF NOT OUTByte( Fine )
    THEN
      RETURN FALSE;
    END (* if *);
    RETURN TRUE
  END WriteCardMode;

  PROCEDURE ReadConfiguration
            ( VAR disableMask : BITSET;
              VAR speedMask   : BITSET;
              VAR fineMode    : BOOLEAN;
              VAR killTime    : CARDINAL ) : BOOLEAN;

  TYPE
    State =
      ( HeaderSt,
        CountSt,
        CommandTypeSt,
        DisableMaskSt,
        SpeeadMaskSt,
        ModeSt,
        KillTimeLoSt,
        KillTimeHiSt );

  VAR
    lastChar  : CHAR;
    currState : State;

  BEGIN
    IF NOT OUTByte( Header )
    THEN
      RETURN FALSE;
    END (* if *);
    IF NOT OUTByte( 01C )
    THEN
      RETURN FALSE;
    END (* if *);
    IF NOT OUTByte( 0DH )
    THEN
      RETURN FALSE;
    END (* if *);
    currState := HeaderSt;
    LOOP
      IF NOT INByte( lastChar )
      THEN
        RETURN FALSE;
      END (* if *);
      CASE currState OF
        HeaderSt,
        CountSt,
        CommandTypeSt :
          ;
        |
        DisableMaskSt :
          disableMask := BITSET( ORD( lastChar ) );
        |
        SpeeadMaskSt :
          speedMask := BITSET( ORD( lastChar ) );
        |
        ModeSt :
          IF lastChar > 0C
          THEN
            fineMode := TRUE;
          ELSE
            fineMode := FALSE;
          END (* if lastChar *);
        |
        KillTimeLoSt :
          killTime := ORD( lastChar );
        |
        KillTimeHiSt :
          killTime := killTime + ORD( lastChar ) * 100H;
          RETURN TRUE;
      END (* case currState *);
      INC( currState );
    END (* loop *);
  END ReadConfiguration;

  PROCEDURE ReadTXSlot
            (     slot  : ShortCardinal;
              VAR label : ShortCardinal;
              VAR data  : Data;
              VAR rate  : CARDINAL;
              VAR chan  : ChannelNu     ) : BOOLEAN;

  TYPE
    State =
      ( HeaderSt,
        CountSt,
        CommandTypeSt,
        SlotSt,
        LabelSt,
        DataBits1St,
        DataBits2St,
        DataBits3St,
        RateLoByteSt,
        RateHiByteSt,
        ChanSt );

  VAR
    lastChar  : CHAR;
    currState : State;

  BEGIN
    IF NOT OUTByte( Header )
    THEN
      RETURN FALSE;
    END (* if *);
    IF NOT OUTByte( 02C )
    THEN
      RETURN FALSE;
    END (* if *);
    IF NOT OUTByte( 0CH )
    THEN
      RETURN FALSE;
    END (* if *);
    IF NOT OUTByte( CHR( slot ) )
    THEN
      RETURN FALSE;
    END (* if *);
    currState := HeaderSt;
    LOOP
      IF NOT INByte( lastChar )
      THEN
        RETURN FALSE;
      END (* if *);
      CASE currState OF
        HeaderSt,
        CountSt,
        CommandTypeSt,
        SlotSt :
          ;
        |
        LabelSt :
          label := ORD( lastChar );
        |
        DataBits1St :
          data[0] := lastChar;
        |
        DataBits2St :
          data[1] := lastChar;
        |
        DataBits3St :
          data[2] := lastChar;
        |
        RateLoByteSt :
          rate := ORD( lastChar );
        |
        RateHiByteSt :
          rate := rate + 100H * ORD( lastChar );
        |
        ChanSt :
          chan := ORD( lastChar );
          RETURN TRUE;
      END (* case currState *);
      INC( currState );
    END (* loop *);
  END ReadTXSlot;

  PROCEDURE ReadRXSlot
            (     slot  : ShortCardinal;
              VAR label : ShortCardinal;
              VAR data  : Data;
              VAR rate  : CARDINAL;
              VAR chan  : ChannelNu;
              VAR mode  : ShortCardinal ) : BOOLEAN;

  TYPE
    State =
      ( HeaderSt,
        CountSt,
        CommandTypeSt,
        SlotSt,
        LabelSt,
        DataBits1St,
        DataBits2St,
        DataBits3St,
        RateLoByteSt,
        RateHiByteSt,
        ChanSt,
        ModeSt );

  VAR
    lastChar  : CHAR;
    currState : State;

  BEGIN
    IF NOT OUTByte( Header )
    THEN
      RETURN FALSE;
    END (* if *);
    IF NOT OUTByte( 03C )
    THEN
      RETURN FALSE;
    END (* if *);
    IF NOT OUTByte( 0BH )
    THEN
      RETURN FALSE;
    END (* if *);
    IF NOT OUTByte( CHR( slot ) )
    THEN
      RETURN FALSE;
    END (* if *);
    IF NOT OUTByte( CHR( chan ) )
    THEN
      RETURN FALSE;
    END (* if *);
    currState := HeaderSt;
    LOOP
      IF NOT INByte( lastChar )
      THEN
        RETURN FALSE;
      END (* if *);
      CASE currState OF
        HeaderSt,
        CountSt,
        CommandTypeSt,
        SlotSt :
          ;
        |
        LabelSt :
          label := ORD( lastChar );
        |
        DataBits1St :
          data[0] := lastChar;
        |
        DataBits2St :
          data[1] := lastChar;
        |
        DataBits3St :
          data[2] := lastChar;
        |
        RateLoByteSt :
          rate := ORD( lastChar );
        |
        RateHiByteSt :
          rate := rate + 100H * ORD( lastChar );
        |
        ChanSt :
          chan := ORD( lastChar );
        |
        ModeSt :
          mode := ORD( lastChar );
          RETURN TRUE;
      END (* case currState *);
      INC( currState );
    END (* loop *);
  END ReadRXSlot;


BEGIN
  maxCountW := 0;
  maxCountR := 0;
END ARINC.
