(*.F- *)
(**********************************************************************
|  Title   : Modul strojenia odbiornikow nawigacyjnych
|  Author  : M.Postol
|  System  : LOGITECH MODULA-2/86
|  History :
|
|  Copyright (C), CAS LODZ POLAND.
|  TEL: 42' 86 58 12, 42' 87 80 44 FAX/TEL: 42' 84 48 40
|
**********************************************************************)
(*.F+ *)

IMPLEMENTATION MODULE Tune;

  FROM MANAGER IMPORT
    Assert;

  FROM SYSTEM IMPORT
    BYTE, INBYTE, OUTBYTE;

  FROM DGHInterface IMPORT
    DtaSignType, SetBinaryVal;

  FROM DGHIni IMPORT
    SignalNames;

  FROM Conversions IMPORT
    ConvertCardinal;

  FROM Strings IMPORT
    Concat;

  CONST
    PortA      = 1B0H;
    PortC      = PortA + 2;
    PortCont   = PortA + 3;
    Mode       = 253C;  (* 233C; *)
    WDLimit    = 100H;
    ADFAsel    = 0;
    ADFBsel    = 1;
    NAVlocAsel = 2;
    NAVgsAsel  = 3;
    NAVlocBsel = 4;
    NAVgsBsel  = 5;
    Ntmin      = 0;
    OnLevel    = { };
    OffLevel   = { 0..6 };

  TYPE
    set8 =
      SET OF [ 0 .. 7 ];

  VAR
    VORfreqCRT : ARRAY VORfrqIdx OF CARDINAL;
    GSfreqCRT  : ARRAY VORfrqIdx OF CARDINAL;
    DMEfreqCRT : ARRAY VORfrqIdx OF CARDINAL;

  PROCEDURE Send
            (    toBeSent : ARRAY OF BYTE ) : BOOLEAN;

  CONST
    strobe      = 5;
    bufferempty = 7;

  VAR
    control  : set8;
    id       : CARDINAL;
    watchDog : CARDINAL;

  BEGIN
    id := 0;
    watchDog := WDLimit;
    LOOP   (* Send *)
      DEC( watchDog );
      IF watchDog = 0
      THEN
        RETURN FALSE;
      END (* if *);
      INBYTE( PortC, control );
      IF ( bufferempty IN control ) AND ( strobe IN control )
      THEN
        OUTBYTE( PortA, toBeSent[id] );
        INBYTE( PortC, control );
        INC( id );
        watchDog := WDLimit;
        IF id > HIGH( toBeSent )
        THEN
          RETURN TRUE;
        END (* if id *);
      END (* if *);
    END (* loop *);
    RETURN FALSE;
  END Send;

  PROCEDURE TurnOffADF
            (    rec : Receiver );

  VAR
    dtaSign : DtaSignType;

  BEGIN (* TurnOffADF *)
    CASE rec OF
      AReceiver :
        SetBinaryVal( ADFaON, OnLevel, dtaSign );
      |
      BReceiver :
        SetBinaryVal( ADFbON, OnLevel, dtaSign );
    END (* case rec *);
  END TurnOffADF;

  PROCEDURE TurnOffVOR_ILS
            (    rec : Receiver );

  VAR
    dtaSign : DtaSignType;

  BEGIN (* TurnOffVOR_ILS *)
    CASE rec OF
      AReceiver :
        SetBinaryVal( NAVaON, OnLevel, dtaSign );
      |
      BReceiver :
        SetBinaryVal( NAVbON, OnLevel, dtaSign );
    END (* case rec *);
  END TurnOffVOR_ILS;

  PROCEDURE TuneADF
            (    rec     : Receiver;
                 frq     : CARDINAL; (* in kHz *)
                 bfo     : BOOLEAN;
                 adfMode : BOOLEAN;
                 loc     : BOOLEAN  );

  TYPE
    ADFControlString =
      RECORD
        bits    : CHAR;
        synchro : set8;
        string  : ARRAY [ 0 .. 3 ] OF CHAR;
      END;

  VAR
    control : ADFControlString;
    npc     : CARDINAL;
    ns      : CARDINAL;
    nt      : CARDINAL;
    filter  : CARDINAL;
    recName : SignalNames;
    dtaSign : DtaSignType;

  BEGIN
    IF frq >= 400
    THEN
      IF frq < 600
      THEN
        filter := 4;
      ELSIF frq < 900
      THEN
        filter := 2;
      ELSE
        filter := 1;
      END (* if *);
    ELSIF frq < 285
    THEN
      filter := 16;
    ELSE
      filter := 8;
    END (* if *);
    nt := frq + 12428;
    npc := nt DIV 16 + 1;
    ns := 16 - nt MOD 16;
    WITH control DO
      bits := CHAR( 27 );
      IF rec = AReceiver
      THEN
        recName := ADFaON;
        synchro := set8 { ADFAsel };
      ELSE
        recName := ADFbON;
        synchro := set8 { ADFBsel };
      END (* if rec *);
      string[0] := CHR( 0E0H + ns * 2 + npc DIV 0800H );
      npc := npc MOD 0800H;
      string[1] := CHR( npc DIV 8 );
      npc := npc MOD 8;
      string[2] := CHR( npc * 020H + filter MOD 20H );
      string[3] := CHR( ORD( bfo ) * 80H + ORD( adfMode ) * 040H + ORD( loc ) *
                        020H );
    END (* with *);
    SetBinaryVal( recName, OffLevel, dtaSign );
    Assert( Send( control ) );
  END TuneADF;

  PROCEDURE TuneVOR_ILS
            (    rec            : Receiver;
                 frq            : VORfrqIdx;
                 ilsMode        : BOOLEAN;
                 markerLowSense : BOOLEAN   );

  TYPE
    NAVControlString =
      RECORD
        bits    : CHAR;
        synchro : set8;
        string  : ARRAY [ 0 .. 2 ] OF CHAR;
      END;

  VAR
    control      : NAVControlString;
    Npc          : CARDINAL;
    Ns           : CARDINAL;
    Nt           : CARDINAL;
    dtaSign      : DtaSignType;
    recName      : SignalNames;
    ilsEnergName : SignalNames;
    mkrHLSenName : SignalNames;

    PROCEDURE TuneGS
              (    rec : Receiver;
                   frq : CARDINAL
                      (* Fch-328)*60 *) );

    VAR
      control : NAVControlString;
      Npc     : CARDINAL;
      Ns      : CARDINAL;
      Nt      : CARDINAL;

    BEGIN (* TuneGS *)
      Nt := frq - 2;
      Npc := Nt DIV 16 + 4CEH + 1;
      Ns := 16 - Nt MOD 16;
      WITH control DO
        bits := CHAR( 19 );
        IF rec = AReceiver
        THEN
          synchro := set8 { NAVgsAsel }
        ELSE
          synchro := set8 { NAVgsBsel }
        END (* if rec *);
        string[0] := CHR( 5 * 20H + 2 * Ns + Npc DIV 0800H );
        Npc := Npc MOD 0800H;
        string[1] := CHR( Npc DIV 8 );
        Npc := Npc MOD 8;
        string[2] := CHR( Npc * 020H );
      END (* with *);
      Assert( Send( control ) );
    END TuneGS;

  BEGIN (* TuneVOR_ILS *)
    Nt := (VORfreqCRT[frq]  - 1110 ) DIV 5;
    Npc := Nt DIV 16 + 1;
    Ns := 16 - Nt MOD 16;
    WITH control DO
      bits := CHAR( 19 );
      IF rec = AReceiver
      THEN
        recName := NAVaON;
        ilsEnergName := ILSaEnergize;
        mkrHLSenName := MKRaHiLoSense;
        synchro := set8 { NAVlocAsel };
      ELSE
        recName := NAVbON;
        ilsEnergName := ILSbEnergize;
        mkrHLSenName := MKRaHiLoSense;
        synchro := set8 { NAVlocBsel };
      END (* if rec *);
      string[0] := CHR( 2 * 10H + 2 * Ns + Npc DIV 0800H );
      Npc := Npc MOD 0800H;
      string[1] := CHR( Npc DIV 8 );
      Npc := Npc MOD 8;
      string[2] := CHR( Npc * 020H );
    END (* with *);
    SetBinaryVal( recName, OffLevel, dtaSign );
    Assert( Send( control ) );
    IF ilsMode
    THEN
      SetBinaryVal( ilsEnergName, OffLevel, dtaSign );
      TuneGS( rec, GSfreqCRT[frq] );
      IF markerLowSense
      THEN
        SetBinaryVal( ilsEnergName, OffLevel, dtaSign );
      ELSE
        SetBinaryVal( ilsEnergName, OnLevel, dtaSign );
      END (* if markerLowSense *);
    ELSE
      SetBinaryVal( ilsEnergName, OnLevel, dtaSign );
    END (* if ilsMode *);
  END TuneVOR_ILS;

  PROCEDURE TuneDME
            (    rec : Receiver;
                 frq : VORfrqIdx );

  VAR
    nt         : CARDINAL;
    dtaSign    : DtaSignType;
    recName    : SignalNames;
    frqControl : CARDINAL;

  BEGIN
    frqControl := DMEfreqCRT[frq];
    CASE rec OF
      AReceiver :
        recName := DMEaTune;
      |
      BReceiver :
        recName := DMEbTune;
    END (* case rec *);
    SetBinaryVal( recName, BITSET( frqControl ), dtaSign );
  END TuneDME;

  PROCEDURE VORfrqString
            (     frq : VORfrqIdx;
              VAR str : ARRAY OF CHAR );

  BEGIN
    ConvertCardinal( VORfreqCRT[frq], 5, str );
    Concat( str, '0kHz', str );
  END VORfrqString;

BEGIN
  OUTBYTE( PortCont, Mode );
  VORfreqCRT[0] := 10810;
  GSfreqCRT[0] := ( 33470 - 32800 ) * 60;
  VORfreqCRT[1] := 10815;
  GSfreqCRT[1] := ( 33455 - 32800 ) * 60;
  VORfreqCRT[2] := 10830;
  GSfreqCRT[2] := ( 33410 - 32800 ) * 60;
  VORfreqCRT[3] := 10835;
  GSfreqCRT[3] := ( 33395 - 32800 ) * 60;
  VORfreqCRT[4] := 10850;
  GSfreqCRT[4] := ( 32990 - 32800 ) * 60;
  VORfreqCRT[5] := 10855;
  GSfreqCRT[5] := ( 32975 - 32800 ) * 60;
  VORfreqCRT[6] := 10870;
  GSfreqCRT[6] := ( 33050 - 32800 ) * 60;
  VORfreqCRT[7] := 10875;
  GSfreqCRT[7] := ( 33035 - 32800 ) * 60;
  VORfreqCRT[8] := 10890;
  GSfreqCRT[8] := ( 32930 - 32800 ) * 60;
  VORfreqCRT[9] := 10895;
  GSfreqCRT[9] := ( 32915 - 32800 ) * 60;
  VORfreqCRT[10] := 10910;
  GSfreqCRT[10] := ( 33140 - 32800 ) * 60;
  VORfreqCRT[11] := 10915;
  GSfreqCRT[11] := ( 33125 - 32800 ) * 60;
  VORfreqCRT[12] := 10930;
  GSfreqCRT[12] := ( 33200 - 32800 ) * 60;
  VORfreqCRT[13] := 10935;
  GSfreqCRT[13] := ( 33185 - 32800 ) * 60;
  VORfreqCRT[14] := 10950;
  GSfreqCRT[14] := ( 33260 - 32800 ) * 60;
  VORfreqCRT[15] := 10955;
  GSfreqCRT[15] := ( 33245 - 32800 ) * 60;
  VORfreqCRT[16] := 10970;
  GSfreqCRT[16] := ( 33320 - 32800 ) * 60;
  VORfreqCRT[17] := 10975;
  GSfreqCRT[17] := ( 33305 - 32800 ) * 60;
  VORfreqCRT[18] := 10990;
  GSfreqCRT[18] := ( 33380 - 32800 ) * 60;
  VORfreqCRT[19] := 10995;
  GSfreqCRT[19] := ( 33365 - 32800 ) * 60;
  VORfreqCRT[20] := 11010;
  GSfreqCRT[20] := ( 33440 - 32800 ) * 60;
  VORfreqCRT[21] := 11015;
  GSfreqCRT[21] := ( 33425 - 32800 ) * 60;
  VORfreqCRT[22] := 11030;
  GSfreqCRT[22] := ( 33500 - 32800 ) * 60;
  VORfreqCRT[23] := 11035;
  GSfreqCRT[23] := ( 33485 - 32800 ) * 60;
  VORfreqCRT[24] := 11050;
  GSfreqCRT[24] := ( 32960 - 32800 ) * 60;
  VORfreqCRT[25] := 11055;
  GSfreqCRT[25] := ( 32945 - 32800 ) * 60;
  VORfreqCRT[26] := 11070;
  GSfreqCRT[26] := ( 33020 - 32800 ) * 60;
  VORfreqCRT[27] := 11075;
  GSfreqCRT[27] := ( 33005 - 32800 ) * 60;

  VORfreqCRT[28] := 11090;
  GSfreqCRT[28] := ( 33080 - 32800 ) * 60;
  VORfreqCRT[29] := 11095;
  GSfreqCRT[29] := ( 33065 - 32800 ) * 60;
  VORfreqCRT[30] := 11110;
  GSfreqCRT[30] := ( 33170 - 32800 ) * 60;
  VORfreqCRT[31] := 11115;
  GSfreqCRT[31] := ( 33155 - 32800 ) * 60;
  VORfreqCRT[32] := 11130;
  GSfreqCRT[32] := ( 33230 - 32800 ) * 60;
  VORfreqCRT[33] := 11135;
  GSfreqCRT[33] := ( 33215 - 32800 ) * 60;

  VORfreqCRT[34] := 11150;
  GSfreqCRT[34] := ( 33290 - 32800 ) * 60;
  VORfreqCRT[35] := 11155;
  GSfreqCRT[35] := ( 33275 - 32800 ) * 60;
  VORfreqCRT[36] := 11170;
  GSfreqCRT[36] := ( 33350 - 32800 ) * 60;
  VORfreqCRT[37] := 11175;
  GSfreqCRT[37] := ( 33335 - 32800 ) * 60;
  VORfreqCRT[38] := 11190;
  GSfreqCRT[38] := ( 33110 - 32800 ) * 60;
  VORfreqCRT[39] := 11195;
  GSfreqCRT[39] := ( 33095 - 32800 ) * 60;
  DMEfreqCRT[0] := 0;   (* wypelnic ta tablice *)
END Tune.
