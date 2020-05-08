(* $S-*)
(* $R-*)
(* $T-*)
(*.F- *)
(**********************************************************************
|  Title   : Two RS232C handling proceduress
|  Author  : D.Arendt.
|  System  : LOGITECH MODULA-2/86
|  History :
|    04 May 1991: M.Postol
|      derivev from DTCRS232 IBM version
|      Time out was added to read nad write procedures.
|      comments were changed.
|   7 May 91/D.A : Four Com Board extension;
|   18 Nov 1991/DA : obsluga IRQ4 blad poprawiony.
|   20 May 1992: M.Postol
|     implementation of the new definition
|
|  Copyright (C), Optimal Control Laboratory.
|
**********************************************************************)
(*.F+ *)

IMPLEMENTATION MODULE RS232 [ 6 ];

  FROM MANAGER IMPORT
    InitC, Condition, WAITC, Notify, AWAITEDC,
    DOIO, STARTPROCESS;

  FROM SYSTEM IMPORT
    INBYTE, OUTBYTE;

  IMPORT
    RTSMain;

  CONST
    ReceiverReg     = 00H;  (* received char is in this register *)
    LowBaudRateDiv  = 00H;  (* lower byte of divisor *)
    TransmitReg     = 00H;  (* char to send is to put in this reg *)
    IntEnableReg    = 01H;  (* to enable the selected interrupt *)
    HighBaudRateDiv = 01H;  (* higher byte of divisor *)
    IntSourceReg    = 02H;  (* to find interrupt reason *)
    LineContrReg    = 03H;  (* to specify format of transmitted data *)
    ModemContrReg   = 04H;  (* controls the interface to a modem *)
    LineStatusReg   = 05H;  (* holds status info on the data transfer *)
    ModemStatuReg   = 06H;  (* holds the current state of modem signals *)
    AsyncInterrupt4 = 4;  (* IRQ nr *)
    AsyncInterrupt3 = 3;  (* IRQ nr *)

  TYPE
    set8 =
      SET OF [ 0 .. 7 ];

  CONST
    IBuffLen             = 400H;  (* must be power of 2 *)
    OBuffLen             = 20H;  (* must be power of 2 *)
    PartOfBufferCapacity = OBuffLen DIV 4;  (* arbitrary selected *)
    OneChar              = 1B;
    Zero                 = 0B;

  CONST
    RS1 = 1;
    RS2 = 2;
    RS3 = 3;
    RS4 = 4;

  VAR
    irq3Initialized : BOOLEAN;
    irq4Initialized : BOOLEAN;
    RS : ARRAY [ RS1 .. RS4 ] OF RECORD
                                   IOBase             : CARDINAL;
                                   NumOfCharI, HeadI,
                                 TailI              : CARDINAL;
                                   IBuffer            : ARRAY [ Zero ..
                                 IBuffLen - 1 ] OF CHAR;
                                   AtLeastOneInBuffer : Condition;
                                   NumOfCharO, HeadO,
                                 TailO              : CARDINAL;
                                   OBuffer            : ARRAY [ Zero ..
                                 OBuffLen - 1 ] OF CHAR;
                                   InPartEmpty        : Condition;
                                 END;

  PROCEDURE IRQ
            (    nr : CARDINAL ) : BOOLEAN;
    (* procedure designated to handle interrupt request from 8250 *)
  (* it reads/writes one char and returns if !!! NO interrupt is reqested from
  *)
  (* chip related to parameter nr ? *)

  CONST
    RxRDY           = 2;
    TxRDY           = 1;
    NoIntrRequested = 0;  (* if '1' then NO interrupt pending flag *)

  VAR
    IntSource : set8;
    LastChar  : CHAR;
    BaseAddr  : CARDINAL;

  BEGIN
    IF RS[nr].IOBase = 0
    THEN
      RETURN TRUE
    END (* if RS *);
    WITH RS[nr] DO
      BaseAddr := IOBase;
      IF BaseAddr = 0
      THEN   (* no COM that's nothing to do *)
        RETURN TRUE;   (* and this may not be source of interrupt *)
      END (* if BaseAddr *);
      INBYTE( BaseAddr + IntSourceReg, IntSource );
      IF RxRDY IN IntSource
      THEN
        INBYTE( BaseAddr + ReceiverReg, LastChar );
        IF NumOfCharI < IBuffLen
        THEN
          INC( NumOfCharI );
          IBuffer[HeadI] := LastChar;
          INC( HeadI );
          HeadI := CARDINAL( BITSET( HeadI ) * BITSET( IBuffLen - 1 ) );
          IF NumOfCharI = OneChar
          THEN
            Notify( AtLeastOneInBuffer )
          END (* if *);
        END (* if NumOfCharI *)
      END (* if RxRDY *);
      IF ( TxRDY IN IntSource )
      THEN
        IF NumOfCharO # Zero
        THEN
          IF NumOfCharO = PartOfBufferCapacity
          THEN
            Notify( InPartEmpty );
          END (* if NumOfCharO *);
          DEC( NumOfCharO );
          LastChar := OBuffer[HeadO];
          INC( HeadO );
          HeadO := CARDINAL( BITSET( HeadO ) * BITSET( OBuffLen - 1 ) );
          OUTBYTE( BaseAddr + TransmitReg, LastChar );
        ELSE   (* disable transmiter *)
          OUTBYTE( BaseAddr + IntEnableReg, set8 { 0 } );   (* enable receiver
                                                               only *)
        END (* if NumOfCharO *);
      END (* if *);
    END (* with *);
    RETURN NoIntrRequested IN IntSource;
  END IRQ;

  PROCEDURE IntHandlerIRQ4;

  VAR
    NoIntrRequested : BOOLEAN;

  BEGIN
    (* enable interrupts in the communications controller (8250): *)
    IF RS[RS1].IOBase # 0
    THEN
      OUTBYTE( RS[RS1].IOBase + IntEnableReg, set8 { 1, 0 } );   (* enable
                                                                    receiver &
                                                                    transmiter
                                                                 *)
    END (* if RS *);
    IF RS[RS3].IOBase # 0
    THEN
      OUTBYTE( RS[RS3].IOBase + IntEnableReg, set8 { 1, 0 } );   (* enable
                                                                    receiver &
                                                                    transmiter
                                                                 *)
    END (* if RS *);
    LOOP
      NoIntrRequested := IRQ( RS1 );
      NoIntrRequested := IRQ( RS3 ) AND NoIntrRequested;
      IF NoIntrRequested
      THEN
        DOIO( AsyncInterrupt4 );
      END (* if *);
    END (* loop *);
  END IntHandlerIRQ4;

  PROCEDURE IntHandlerIRQ3;

  VAR
    NoIntrRequested : BOOLEAN;

  BEGIN
    (* enable interrupts in the communications controller (8250): *)
    IF RS[RS2].IOBase # 0
    THEN
      OUTBYTE( RS[RS2].IOBase + IntEnableReg, set8 { 1, 0 } );   (* enable
                                                                    receiver &
                                                                    transmiter
                                                                 *)
    END (* if RS *);
    IF RS[RS4].IOBase # 0
    THEN
      OUTBYTE( RS[RS4].IOBase + IntEnableReg, set8 { 1, 0 } );   (* enable
                                                                    receiver &
                                                                    transmiter
                                                                 *)
    END (* if RS *);
    LOOP
      NoIntrRequested := IRQ( RS2 );
      NoIntrRequested := IRQ( RS4 ) AND NoIntrRequested;
      IF NoIntrRequested
      THEN   (* if no more requested then wait request *)
        DOIO( AsyncInterrupt3 );
      END (* if *);
    END (* loop *);
  END IntHandlerIRQ3;

  PROCEDURE Read
            (     Comm : CARDINAL;
              VAR Ch   : CHAR     ) : BOOLEAN;

  VAR

  BEGIN
    WITH RS[Comm] DO
      (*IF NumOfCharI = Zero
      THEN
         WAITC( AtLeastOneInBuffer );
      END (* if *);*)
      DEC( NumOfCharI );
      Ch := IBuffer[TailI];
      INC( TailI );
      TailI := CARDINAL( BITSET( TailI ) * BITSET( IBuffLen - 1 ) );
    END (* with RS *);
    RETURN TRUE;
  END Read;

  PROCEDURE IBF
            (    CommNum : CARDINAL ) : BOOLEAN;

  BEGIN
    RETURN RS[CommNum].NumOfCharI # Zero;
  END IBF;

  PROCEDURE Write
            (    Comm : CARDINAL;
                 Ch   : CHAR     ) : BOOLEAN;

  VAR

  BEGIN
    WITH RS[Comm] DO
      (*IF NumOfCharO = OBuffLen
      THEN
         WAITC( InPartEmpty );
      END  ;*)
      INC( NumOfCharO );
      OBuffer[TailO] := Ch;
      INC( TailO );
      TailO := CARDINAL( BITSET( TailO ) * BITSET( OBuffLen - 1 ) );
      IF ( IOBase # 0 ) AND ( NumOfCharO = OneChar )
      THEN
        OUTBYTE( IOBase + IntEnableReg, set8 { 1, 0 } );   (* enable receiver
                                                              only *)
      END (* if *);
    END (* with RS *);
    RETURN TRUE;
  END Write;

  VAR
    oldMCR : ARRAY [ RS1 .. RS4 ] OF set8;

  PROCEDURE Terminator;

  VAR
    rs : CARDINAL;

  BEGIN
    FOR rs := RS1 TO RS4 DO
      IF RS[rs].IOBase # 0
      THEN
        OUTBYTE( RS[rs].IOBase + ModemContrReg, oldMCR[rs] );
      END (* if RS *);
    END (* for rs *);
  END Terminator;

  PROCEDURE Init
            (    CommNum     : CARDINAL;
                 Baud        : BaudRates;
                 FlowControl : FlowControlType ) : BOOLEAN;

  VAR
    divisorHigh : CHAR;
    divisorLow  : CHAR;
    dummy       : CHAR;
    tempSet     : set8;
    ADDR        : CARDINAL;

  BEGIN
    IF ( CommNum < RS1 ) OR ( CommNum > RS4 )
    THEN   (* no1..3 *)
      RETURN FALSE;
    END (* if *);
    divisorHigh := 0C;
    CASE Baud OF
      Baud300 :
        divisorLow := 200C;
        divisorHigh := 1C;
      |
      Baud600 :
        divisorLow := 300C;
      |
      Baud1200 :
        divisorLow := 140C;
      |
      Baud2400 :
        divisorLow := 60C;
      |
      Baud4800 :
        divisorLow := 30C;
      |
      Baud9600 :
        divisorLow := 14C;
      |
      Baud19200 :
        divisorLow := 6C;
    END (* case *);
    WITH RS[CommNum] DO
      NumOfCharI := Zero;
      HeadI := Zero;
      TailI := Zero;
      NumOfCharO := Zero;
      HeadO := Zero;
      TailO := Zero;
      ADDR := IOBase;
    END (* with RS *);
    IF ADDR = 0
    THEN
      RETURN FALSE
    END;   (* DOS did not found it so we trust it *)
    (* load the divisor of the baud rate generator: *)
    OUTBYTE( ADDR + LineContrReg, 80H );   (* DLAB=1 *)
    OUTBYTE( ADDR + HighBaudRateDiv, divisorHigh );
    OUTBYTE( ADDR + LowBaudRateDiv, divisorLow );
    (* prepare the parameters: *)
    OUTBYTE( ADDR + LineContrReg, set8 { 0, 1 } );   (* 8 bits, no par, stop 1
                                                     *)
    INBYTE( ADDR + LineStatusReg, tempSet );
    IF 0 IN tempSet
    THEN   (* data ready *)
      INBYTE( ADDR + ReceiverReg, dummy );
    END (* if *);
    (* select interrupts upon reception (in communications contr.): *)
    INBYTE( ADDR + ModemContrReg, tempSet );
    INCL( tempSet, 3 );   (* bit 3 must be set, otherwise no *)
    (* interrupts will be generated; *)
    INCL( tempSet, 0 );   (* set DTR *)
    INCL( tempSet, 1 );   (* set RTS *)
    OUTBYTE( ADDR + ModemContrReg, tempSet );
    IF NOT irq4Initialized AND (CommNum = RS1) OR (CommNum = RS3)  THEN
      STARTPROCESS( IntHandlerIRQ4, 200H, 0 );
    END;
    IF NOT irq3Initialized AND (CommNum = RS2) OR (CommNum = RS4)  THEN
      STARTPROCESS( IntHandlerIRQ3, 200H, 0 );
    END;
    RETURN TRUE
  END Init;


  PROCEDURE DropDtr
            (    CommNum : CARDINAL );

  VAR
    oldMCR : set8;

  BEGIN
    INBYTE( RS[CommNum].IOBase + ModemContrReg, oldMCR );
    EXCL( oldMCR, 0 );   (* reset DTR *)
    OUTBYTE( RS[CommNum].IOBase + ModemContrReg, oldMCR );
  END DropDtr;

  PROCEDURE SetDtr
            (    CommNum : CARDINAL );

  VAR
    oldMCR : set8;

  BEGIN
    INBYTE( RS[CommNum].IOBase + ModemContrReg, oldMCR );
    INCL( oldMCR, 0 );   (* set DTR *)
    OUTBYTE( RS[CommNum].IOBase + ModemContrReg, oldMCR );
  END SetDtr;

  PROCEDURE ReadModemStatuReg
            (     CommNum  : CARDINAL;
              VAR Contents : ModemStatuRegSet );

  BEGIN
    INBYTE( RS[CommNum].IOBase + ModemStatuReg, Contents );
  END ReadModemStatuReg;

  PROCEDURE Initial;

  VAR
    DOSRS  [ 40H:0 ] : ARRAY [ RS1 .. RS4 ] OF CARDINAL;
    dummy : BOOLEAN;
    rs    : CARDINAL;
    Num   : CARDINAL;

  BEGIN (* find addresses from DOS *)
    irq3Initialized := FALSE;
    irq4Initialized := FALSE;
    Num := 0;
    FOR rs := RS1 TO RS4 DO
      WITH RS[rs] DO
        InitC( AtLeastOneInBuffer );
        InitC( InPartEmpty );
        IOBase := DOSRS[rs];
        IF IOBase # 0
        THEN
          INBYTE( IOBase + ModemContrReg, oldMCR[rs] );
          INC( Num );
        END (* if IOBase *);
      END (* with *);
      (*dummy := Init( rs, Baud1200,  NoOne );*)
    END (* for *);
  END Initial;

BEGIN
  Initial;
END RS232.
