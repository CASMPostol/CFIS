(*.F- *)
(**********************************************************************
|  Title   : Iterface to DGH modules connected through Digibord card.
|  Author  : D.Arend; M.Postol
|  System  : LOGITECH MODULA-2/86
|  History :
|
|  Copyright (C), CAS LODZ POLAND.
|
**********************************************************************)
(*.F+ *)

MODULE DGHSpeed;

  FROM SYSTEM IMPORT
    ADR;

  FROM MANAGER IMPORT
    STARTPROCESS, Release, WAITC, Condition, Broadcast, Assert;

  FROM DigiRS IMPORT
    WriteString, ReadString;

  FROM Timer IMPORT
    Metronome;

  FROM  MathLib0 IMPORT 
    entier, real;
  
  FROM NumberConversion IMPORT
    StringToNum, StringToInt;

  FROM Terminal IMPORT
    Read, KeyPressed, ReadAgain, Write, WriteLn;
  
  IMPORT
    RTSMain, DigiRS, Timer, MANAGER, Strings, RealConversions, DGHIni;

  CONST
    BaudRate = 384;  (* 12==1200, 384==38400 *)
    Channel = 3;
    ExpectedLen = 11;
    commandLen = 5;
    Command = '#9DI';
    currWait = 7;

  VAR
    currentSign : CARDINAL;
    command     : ARRAY[ 0..13 ] OF CHAR;
    
  PROCEDURE Writer;

  VAR
    clicks      : CARDINAL;
    outLoop     : Metronome;
    
    PROCEDURE Reader;

    CONST
      buffLen  = 1000;
      startCH  = "*";
      termCH   = 15C;

    VAR
      mix,
      ix,
      bix,
      len           : CARDINAL;  (* index max, buffer *)
      six           : CARDINAL;  (* pocz odp *)
      responsePtr   : POINTER TO ARRAY [ 0 .. 115 ] OF CHAR;
      buff          : ARRAY [ 0 .. buffLen ] OF CHAR;

      PROCEDURE CHKSRight
                ( VAR str : ARRAY OF CHAR;
                      len : CARDINAL      ) : BOOLEAN;

      VAR
        ix,
        sc,
        cc : CARDINAL;
            (*$R-*)

        PROCEDURE HexDigit
                  (    ch : CHAR ) : CARDINAL;

        BEGIN
          IF ch <= '9' THEN
            RETURN ORD( ch ) - ORD( '0' );
          ELSE
            RETURN ORD( ch ) - ORD( 'A' ) + 10;
          END (* if ch *);
        END HexDigit;

      BEGIN
        cc := ORD( str[0] );
        ix := len - 4;
        REPEAT
          INC( cc, ORD( str[ix] ) );
          DEC( ix );
        UNTIL ix = 0;
        sc := HexDigit( str[len - 3] ) * 16 + HexDigit( str[len - 2] );
        RETURN sc = cc MOD 100H;
        (*$R= *)
      END CHKSRight;

    BEGIN (* Reader *)
      ix := 0;
      bix := 0;   (* indeks w buforze *)
      mix := DigiRS.ReadString( Channel, buff, buffLen );
      Assert(mix # buffLen);   (* tu powinno byc zawsze true *)
      (* analiza danych w buforze najpierw szukaj poczatku *)
      WHILE ( bix < mix ) & ( buff[bix] # startCH ) DO   (* do znaku =*= *)
        INC( bix );
      END (* while *);
      six := bix;   (* six = indeks poczatku odp. *)
      WHILE ( bix < mix ) & ( buff[bix] # termCH ) DO (* do znaku CR *)
        INC( bix );
      END (* while *);
      buff[bix] := 0C;
      responsePtr := ADR( buff[six] );
      len := bix - six + 1;
      IF (ExpectedLen # len) OR ((len > 3) AND 
         NOT CHKSRight( responsePtr^, len ))
      THEN
        len := len;
      END (* if *);
    END Reader;

  VAR
    cw    : CARDINAL;
    count : CARDINAL;
    maxcount: CARDINAL;
    
  BEGIN (* Writer *)
    cw := currWait;
    command := Command;
    command[commandLen-1]:=15C;
    clicks := 0;
    maxcount := 1000 DIV cw;
    Timer.NewMetronome( outLoop, 1000 );(* 200 *)
    LOOP
      FOR count := 1 TO maxcount DO
        Assert(DigiRS.WriteString( Channel,
                                 command, 
                                 commandLen ) = commandLen);
        Timer.Wait( cw );
        Reader;
      END;
      Timer.WaitMetronome( outLoop, clicks, 1000 );(* 200 *)
      IF  clicks # 1 THEN
        clicks := clicks;
      END (* if *);
      (* Assert(clicks = 1); *)
    END (* loop *);
  END Writer;

BEGIN
  Assert( DigiRS.SetBaudRate( 2, BaudRate ) );
  Assert( DigiRS.SetBaudRate( 3, BaudRate ) );
  MANAGER.STARTPROCESS( Writer, 1000H, 0 );
  REPEAT
  UNTIL KeyPressed();
  RTSMain.Terminate(RTSMain.Stopped);
END DGHSpeed.
