IMPLEMENTATION MODULE ArincService;

FROM ARINC IMPORT
  Data, ChannelNu,  ReInitialize,  WriteTXParity, ReInitialize,
  WriteTXChannel, WriteTXLabel, WriteTXData, WriteTXRate, WriteKillTime,
  WriteCardMode, ReadConfiguration, ReadTXSlot, ReadRXSlot;
FROM Lib IMPORT
  Fill;

FROM Views IMPORT
  Message;
FROM Drivers IMPORT
  EventType, EventTypes;
FROM LocCommands IMPORT
  cmdARINC;



  VAR
    disableMask : BITSET;
    speedMask   : BITSET;
    fineMode    : BOOLEAN;
    killTime    : CARDINAL;
    slot        : SHORTCARD;
    label       : SHORTCARD;
    data        : Data;
    rate        : CARDINAL;
    chan        : ChannelNu;
    mode        : SHORTCARD;


CONST
  Omnibearing_Slot  = 7;
  Localizer_Slot    = 9;
  GlidingSlope_Slot = 11;

  MARKER_BECON_400  = FALSE;
  MARKER_BECON_1300 = FALSE;
  MARKER_BECON_300  = FALSE;

  LOC_BlokStrojenie = FALSE;
  GS_BlokStrojenie  = FALSE;



PROCEDURE WriteOmnibearing( val : LONGREAL );
CONST
  Mul = 4096.0/180.0;
VAR
  d  : Data;
  ok : BOOLEAN;
  c  : CARDINAL;
  v  : LONGREAL;
BEGIN
  (* trzeba odwrocic o 180ø *)
  val := val+180.0;
  (*
   *)

  (* SDI = SM = 0 *)
  WHILE val >= 360.0 DO
    val := val-360.0;
  END;
  WHILE val < 0.0 DO
    val := 360.0 + val;
  END;
  IF val >= 180.0 THEN
    v := val - 180.0;
  ELSE
    v := val;
  END;
  Fill( ADR( d ), SIZE( d ), 0 );
  IF MARKER_BECON_400 THEN
    INCL( d[0].b, 2 );
  END;
  IF MARKER_BECON_1300 THEN
    INCL( d[0].b, 3 );
  END;
  IF MARKER_BECON_300 THEN
    INCL( d[0].b, 4 );
  END;
  c := TRUNC( v *  Mul );
  d[1].v := VAL( SHORTCARD, c MOD 256 );
  d[2].v := VAL( SHORTCARD, c DIV 256 );
  IF val >= 180.0 THEN
    INCL( d[2].b, 4 );
  END;

  ok := WriteTXData( Omnibearing_Slot, d );

  ok := WriteTXData( Omnibearing_Slot+1, d ) OR ok;

  Message( ARINCOwner, EventTypes{ evCommand }, cmdARINC, [0:ORD(ok)] );

END WriteOmnibearing;

PROCEDURE WriteLOC( val : LONGREAL );
CONST
  (* Mul = 4096.0/0.4 * 0.155 / 150.0; *)
  Mul = 1336.0 / 150.0; (* liczba z kalibracji *)
VAR
  d  : Data;
  ok : BOOLEAN;
  c  : CARDINAL;
BEGIN
  Fill( ADR( d ), SIZE( d ), 0 );
  IF LOC_BlokStrojenie THEN
    INCL( d[0].b, 5 );
  END;
  c := TRUNC( ABS( val ) * Mul );
  IF val < 0.0 THEN
    c := 2*4096-c;
  END;
  d[1].v := VAL( SHORTCARD, c MOD 256 );
  d[2].v := VAL( SHORTCARD, c DIV 256 );

  ok := WriteTXData( Localizer_Slot, d );
  ok := WriteTXData( Localizer_Slot+1, d ) OR ok;

  Message( ARINCOwner, EventTypes{ evCommand }, cmdARINC, [0:ORD(ok)] );
END WriteLOC;

PROCEDURE WriteGS( val : LONGREAL );
CONST
  Mul = 4096.0/0.8 * 0.175 / 150.0;
VAR
  d  : Data;
  ok : BOOLEAN;
  c  : CARDINAL;
BEGIN
  Fill( ADR( d ), SIZE( d ), 0 );
  IF GS_BlokStrojenie THEN
    INCL( d[0].b, 5 );
  END;
  c := TRUNC( ABS( val ) * Mul );
  IF val < 0.0 THEN
    c := 2*4096-c;
  END;
  d[1].v := VAL( SHORTCARD, c MOD 256 );
  d[2].v := VAL( SHORTCARD, c DIV 256 );

  ok := WriteTXData( GlidingSlope_Slot, d );

  ok := WriteTXData( GlidingSlope_Slot+1, d ) OR ok;

  Message( ARINCOwner, EventTypes{ evCommand }, cmdARINC, [0:ORD(ok)] );
END WriteGS;

CONST
    OmniberLab = 146;
    LOCDevLab  = 123;
    GSDevLab   = 124;
    Rate = 4;
VAR
  ok : BOOLEAN;
BEGIN
  ok := ReInitialize();
  IF NOT ReadConfiguration( disableMask, speedMask, fineMode, killTime ) THEN
    killTime := killTime;
  END (* if *);
  IF NOT WriteTXRate( Omnibearing_Slot, Rate ) THEN
  END;
  IF NOT WriteTXRate( Omnibearing_Slot+1, Rate ) THEN
  END;
  IF NOT WriteTXRate( Localizer_Slot, Rate ) THEN
  END;
  IF NOT WriteTXRate( Localizer_Slot+1, Rate ) THEN
  END;
  IF NOT WriteTXRate( GlidingSlope_Slot, Rate ) THEN
  END;
  IF NOT WriteTXRate( GlidingSlope_Slot+1, Rate ) THEN
  END;

  ok := WriteTXChannel( Omnibearing_Slot, 1 );
  ok := WriteTXChannel( Omnibearing_Slot+1, 2 ) OR ok;
  ok := WriteTXLabel( Omnibearing_Slot, OmniberLab ) OR ok;
  ok := WriteTXLabel( Omnibearing_Slot+1,  OmniberLab ) OR ok;

(*  ok := ok OR WriteTXParity( Omnibearing_Slot, TRUE ); (* na pale *)*)
(*  ok := ok OR WriteTXParity( Omnibearing_Slot+1, TRUE ); (* na pale *)*)

  ok := WriteTXChannel( Localizer_Slot, 1 ) OR ok;
  ok := WriteTXChannel( Localizer_Slot+1, 2 ) OR ok;
  ok := WriteTXLabel( Localizer_Slot, LOCDevLab ) OR ok;
  ok := WriteTXLabel( Localizer_Slot+1, LOCDevLab ) OR ok;

(*  ok := WriteTXParity( Localizer_Slot, TRUE ) OR ok; (* na pale *)*)
(*  ok := WriteTXParity( Localizer_Slot+1, TRUE ) OR ok; (* na pale *)*)

  ok := WriteTXChannel( GlidingSlope_Slot, 1 ) OR ok;
  ok := WriteTXChannel( GlidingSlope_Slot+1, 2 ) OR ok;
  ok := WriteTXLabel( GlidingSlope_Slot,  GSDevLab) OR ok;
  ok := WriteTXLabel( GlidingSlope_Slot+1, GSDevLab ) OR ok;

(*  ok := WriteTXParity( GlidingSlope_Slot, TRUE ) OR ok; (* na pale *)*)
(*  ok := WriteTXParity( GlidingSlope_Slot+1, TRUE ) OR ok; (* na pale *)*)

  ARINCOwner := NIL;
END ArincService.
