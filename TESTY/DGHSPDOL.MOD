(*.F- *)
(**********************************************************************
|  Title   : Iterface to DGH modules connected through Digibord card.
|  Author  : M.Postol
|  System  : LOGITECH MODULA-2/86
|  History :
|
|  Copyright (C), CAS LODZ POLAND.
|
**********************************************************************)
(*.F+ *)

MODULE DGHSPDOL;

  IMPORT DebugPMD;
  
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
  
  FROM Sounds IMPORT
    Sound, NoSound;
    
  IMPORT
    RTSMain, DigiRS, Timer, MANAGER, Strings, RealConversions, DGHIni;

  CONST
    BaudRate = 384;  (* 12==1200, 384==38400 *)
    Channel = 2;
    ExpectedLen = 2;
    commandLen = 9;
    Command = '$9DO008F';
    currWait = 7;

  VAR
    currentSign : CARDINAL;
    command     : ARRAY[ 0..13 ] OF CHAR;
    errors      : CARDINAL;
    maxClicks   : CARDINAL;
    
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

  PROCEDURE Writer;

  VAR
    clicks      : CARDINAL;
    outLoop     : Metronome;
    
    PROCEDURE Reader;

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
      IF (ExpectedLen # len) THEN
        Write('?');
      END;
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
      IF (ExpectedLen # len) OR ((len > 3) AND NOT CHKSRight( responsePtr^, len ))
      THEN
        INC(errors);
        Write('*');
      ELSE
        Write("-");
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
    maxcount := 200 DIV cw - 1;
    Timer.NewMetronome( outLoop, 200 );(* 200 *)
    LOOP
      FOR count := 1 TO maxcount DO
        DigiRS.WriteString( Channel, command, commandLen );
        Timer.Wait( cw );
        Reader;
        (*$R-*)
        INC(currentSign);
        (*$R= *)
      END;
      Timer.WaitMetronome( outLoop, clicks, 1000 );(* 200 *)
      Write("/");
      IF  clicks > maxClicks THEN
        Sound(1000 * clicks);
        maxClicks := clicks;
      ELSE
        NoSound;
      END (* if *);
    END (* loop *);
  END Writer;

BEGIN
  buff := '                                        ';
  errors := 0;
  currentSign := 0;
  maxClicks := 0;
  Assert( DigiRS.SetBaudRate( 2, BaudRate, 8 ) );
  Assert( DigiRS.SetBaudRate( 3, BaudRate, 8 ) );
  MANAGER.STARTPROCESS( Writer, 1000H, 0 );
  REPEAT
  UNTIL KeyPressed();
  RTSMain.Terminate(RTSMain.Stopped);
END DGHSPDOL.
