(*.F- *)
(**********************************************************************
|  Title   : Iterface to DGH modules connected through Digibord card.
|  Author  : D.Arend; M.Postol
|  System  : LOGITECH MODULA-2/86
|  History :
|    23.12.1994: orginal version;
|    12.09.1996: M.Postol
|      zmaina w reader - ogranicznik na petle
|    30-09-1996: M.Postol
|      po policzeniu sumy kontrolnej dla kanalow binarnych lapal sie w 
|      bledzie na konwersji ?! - wywalilem asercje i odrzucam wartosc 
|      (prawdopodobna przyczyna suma kontrolna nie wychwytuje tego bledu)
|      temat ten trzeba wyjasnic.
|    01-10-96: M.Postol
|      SetBinaryVal jesli dwa procesy wywolywaly wpadaly w asercje, 
|      a teraz czekaja grzecznie
|    04-10-96: M.Postol
|      wprowadzilem test naxClicks
|    04-12-96: M.Postol
|      maly blad w GetAnalogVal i potforny blad w Reader
|    07-02-97: M.Postol
|      blad przy wyznaczaniu czasu oczekiwania przez Writer'a
|      
|  Copyright (C), CAS LODZ POLAND.
|
**********************************************************************)
(*.F+ *)
(*$R- *)
IMPLEMENTATION MODULE DGHInterface [6];

  FROM SYSTEM IMPORT
    ADR;

  FROM MANAGER IMPORT
    WAITC, Condition, Broadcast, Assert;

  FROM Timer IMPORT
    Metronome;

  FROM NumberConversion IMPORT
    StringToNum, StringToInt;

  FROM DGHIni IMPORT
    SignalNames, signals, CommCh, ModuleType;
    
  FROM Messages IMPORT
    Display, NewMessage, Message;

  IMPORT
    DigiRS, Timer, MANAGER;

  FROM CommonTypes  IMPORT
    SigNilVal;
    
  FROM  Sounds IMPORT
    Sound, NoSound;
    
  FROM Strings IMPORT
    CompareStr;
    
  CONST
    DigiBoardBIOSPresent = TRUE;
    BaudRate = 384;  (* 12==1200, 384==38400 *)
    FirstCh  = 2;
    SecondCh = 3;

  VAR
    BufferFull    : Condition;
    currentSign   : CARDINAL;
    binaryDtaSign : CARDINAL;
    csErrorCnt    : CARDINAL;
    nvErrorCndF   : CARDINAL;
    nvErrorCndS   : CARDINAL;
    maxClicks     : CARDINAL;
    activated     : ARRAY CommCh OF CARDINAL;
    
  PROCEDURE GetCurrDataSign() : DtaSignType;

  BEGIN
    RETURN currentSign;
  END GetCurrDataSign;

  PROCEDURE WaitForNewData
            ( VAR dtaSign : DtaSignType );

  BEGIN
    IF dtaSign = currentSign  THEN
      WAITC( BufferFull );
    END;
    dtaSign := currentSign;
  END WaitForNewData;

  PROCEDURE TurnOff( what: SignalNames);
  BEGIN
    WITH signals[what] DO
      resultOK := 0;
      active := FALSE;
    END;
  END TurnOff;
  
  PROCEDURE TurnOn( what: SignalNames);
  BEGIN
    WITH signals[what] DO
      active := TRUE;
      activated[channel] := activated[channel] + waitPeriod;
    END;
  END TurnOn;
  
  PROCEDURE GetAnalogVal
            (     from    : SignalNames;
              VAR val     : INTEGER;
              VAR dtaSign : DtaSignType) : BOOLEAN;
  BEGIN
    dtaSign := currentSign;
    WITH signals[from] DO
      IF (resultOK = 0) OR (type # AnalogInput) THEN
        val := SigNilVal;
        RETURN FALSE;
      ELSE
        val := analogVAL;
        RETURN TRUE;
      END;
    END;
  END GetAnalogVal;

  PROCEDURE GetBinaryVal
            (     from    : SignalNames;
              VAR val     : BITSET;
              VAR dtaSign : DtaSignType) : BOOLEAN;
  BEGIN
    dtaSign := currentSign;
    WITH signals[from] DO
      IF (resultOK = 0) OR (type # DigitalInput) THEN
        RETURN FALSE;
      END;
      val := binaryVAL;
    END;
    RETURN TRUE;
  END GetBinaryVal;

  PROCEDURE SetAnalogVal
            (     from    : SignalNames;
                  val     : INTEGER;
              VAR dtaSign : DtaSignType);
  VAR
    count       : CARDINAL;
  BEGIN
    (* np. $<n>AO+12345.67<cr> *)
    WITH signals[from] DO
      Assert(type=AnalogOutput);
      IF val >= 0 THEN
        command[4] := '+';
      ELSE
        val := - val;
        command[4] := '-';
      END;
      FOR count := 9 TO 5 BY -1 DO
        command[ count ] := CHR(CARDINAL(val) MOD 10 + ORD('0'));
        val := val DIV 10;
      END;
      active := TRUE;
    END;
    dtaSign := currentSign;
  END SetAnalogVal;

  PROCEDURE SetBinaryVal
            (     from     : SignalNames;
                  val      : BITSET;
                  twoBytes : BOOLEAN);
  VAR
    count       : CARDINAL;
    cardinalVal : CARDINAL;
    lastDigit   : CARDINAL;
    fromLoop    : CARDINAL;
  BEGIN
    WITH signals[from] DO
      REPEAT
        WaitForNewData( binaryDtaSign);
      UNTIL NOT active;
      IF twoBytes THEN
        fromLoop := 7;
      ELSE
        fromLoop := 5;
        command[ 6 ] := 15C;
        command[ 7 ] := 0C;
      END (* if *);
      Assert(type = DigitalOutput);
      cardinalVal := CARDINAL(val);
      (* np. $<n>DO1234<cr> *)
      FOR count := fromLoop  TO 4 BY -1 DO
        lastDigit := cardinalVal MOD 16;
        IF lastDigit > 9 THEN
          command[ count ] := CHR(lastDigit -10 + ORD('A'));
        ELSE
          command[ count ] := CHR(lastDigit + ORD('0'));
        END;
        cardinalVal := cardinalVal DIV 16;
      END;
      active := TRUE;
    END;
  END SetBinaryVal;

  PROCEDURE  SetMessage
             (    num     : CARDINAL;
                  digits  : Number;
              VAR dtaSign : DtaSignType);
  VAR
    lastDigit   : CARDINAL;
    currDigit   : SignalNames;
    count       : CARDINAL;
    dtaSignIdx  : CARDINAL;
    
  BEGIN
    signals[CockpitDisplaySP].active := TRUE;
    dtaSignIdx := 0;
    FOR currDigit := CockpitDisplayD1 TO CockpitDisplayD4 DO
      WITH signals[currDigit]  DO
        FOR count := 7 TO 4 BY -1 DO
          lastDigit := digits[ dtaSignIdx ] MOD 16;
          IF lastDigit > 9 THEN
            command[ count ] := CHR(lastDigit -10 + ORD('A'));
          ELSE
            command[ count ] := CHR(lastDigit + ORD('0'));
          END;
          digits[ dtaSignIdx ] := digits[ dtaSignIdx ] DIV 16;
        END;
        active := TRUE;
      END;
      INC(dtaSignIdx);
    END;
    WITH signals[ CockpitDisplayMsg ] DO
      FOR count := 7 TO 4 BY -1 DO
        lastDigit := num MOD 16;
        IF lastDigit > 9 THEN
          command[ count ] := CHR(lastDigit -10 + ORD('A'));
        ELSE
          command[ count ] := CHR(lastDigit + ORD('0'));
        END;
        num := num DIV 16;
      END;
      active := TRUE;
    END;
    dtaSign := currentSign;
  END SetMessage;
  
  PROCEDURE Writer;

  CONST
    both     = 2;

  VAR
    clicks      : CARDINAL;
    ended       : CARDINAL;
    outLoop     : Metronome;
    currWait    : CARDINAL;
    idxFirstCh  : SignalNames;
    idxSecondCh : SignalNames;


    CONST
      buffLen = ORD( Terminator ) * 16 + 100H;
      startCH = "*";
      termCH  = 15C;

    VAR
      mix,
      ix,
      bix,
      len           : CARDINAL;  (* index max, buffer *)
      six           : CARDINAL;  (* pocz odp *)
      from          : CHAR;
      ires          : INTEGER;
      cres          : CARDINAL;
      ok            : BOOLEAN;
      currentSignal : SignalNames;
      responsePtr   : POINTER TO ARRAY [ 0 .. 15 ] OF CHAR;
      buff          : ARRAY [ 0 .. buffLen ] OF CHAR;
      currentChNum  : CARDINAL;
      currentChId   : CommCh;
      done          : BOOLEAN;

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
        IF sc = cc MOD 100H  THEN
          RETURN TRUE;
        ELSIF csErrorCnt < MAX(CARDINAL) THEN
          INC(csErrorCnt);
          RETURN FALSE;
        END;
        RETURN FALSE;
        (*$R= *)
      END CHKSRight;

    BEGIN (* Reader *)
      ix := 0;
      currentChNum := 2;
      currentChId := First;
      LOOP
        bix := 0;   (* indeks w buforze *)
        IF DigiBoardBIOSPresent THEN
          mix := DigiRS.ReadString( currentChNum, buff, buffLen );
        ELSE
          mix := 0;
        END;  
        Assert(mix # buffLen);   (* tu powinno byc zawsze true *)
        currentSignal := MIN(SignalNames);
        LOOP
          (* analiza danych w buforze najpierw szukaj poczatku *)
          (* 06-02-97:M.P zawsze szuka poczatku bo mogl byc blad w danych *)
          WHILE ( bix < mix ) & ( buff[bix] # startCH ) DO   (* do znaku =*= *)
            (* Assert(FALSE); *)
            INC( bix );
          END (* while *);
          IF bix = mix THEN   (* jest poczatek *)
            buff[bix] := 155C;
            EXIT;
          END (* if bix *);
          six := bix;   (* six = indeks poczatku odp. *)
          WHILE ( bix < mix ) & ( buff[bix] # termCH ) DO (* do znaku CR *)
            INC( bix );
          END (* while *);
          IF bix = mix THEN   (* jest koniec *)
            buff[bix] := 377C;
            EXIT;
          END (* if bix *);
          buff[bix] := 0C;
          len := bix - six + 1;
          CASE len OF
            16 : (* odp. analogowa *)
              (* np. *<n>RD+12345.67CS<cr> *)
              responsePtr := ADR( buff[six] );
              IF CHKSRight( responsePtr^, len ) THEN
                from := responsePtr^[1];
                responsePtr := ADR( buff[six + 4] );
                responsePtr^[6] := 0C;
                StringToInt( responsePtr^, ires,  done);
                IF done OR (CompareStr(responsePtr^, "+99999") = 0)
                THEN
                  IF NOT  done THEN
                    ires := MIN(INTEGER);
                  END (* if *);
                  LOOP
                    WITH signals[currentSignal] DO
                      IF (address = from) AND (currentChId = channel) AND
                         ( type = AnalogInput )
                      THEN
                        analogVAL := ires;
                        resultOK := 2;
                        INC( currentSignal );
                        EXIT;
                      END (* if signals *);
                    END (* with signals *);
                    IF currentSignal < MAX(SignalNames)  THEN
                      INC( currentSignal );
                    ELSE
                      (* Assert(FALSE); *)
                      EXIT
                    END;
                  END (* loop *);
                END;
              END (* if CHKSRight *);
          | 11 :
            (* np. *<n>DI1234CS<cr> *)
              responsePtr := ADR( buff[six] );
              IF CHKSRight( responsePtr^, len ) THEN
                from := responsePtr^[1];
                responsePtr := ADR( buff[six + 4] );
                responsePtr^[4] := 0C;
                StringToNum( responsePtr^, 16, cres, done );
                IF done THEN
                  LOOP
                    WITH signals[currentSignal] DO
                      IF ( address = from ) AND ( currentChId = channel ) AND
                         ( type = DigitalInput )
                      THEN
                        WITH signals[currentSignal] DO
                          binaryVAL := BITSET(cres);
                          resultOK := 2;
                        END (* with signals *);
                        INC( currentSignal );
                        EXIT;
                      END (* if signals *);
                    END;
                    IF currentSignal < MAX(SignalNames)  THEN
                      INC( currentSignal );
                    ELSE
                      (* Assert(FALSE); *)
                      EXIT
                    END;
                  END (* loop *);
                END;
              END (* if CHKSRight *);
          | 2 :
            ;
          ELSE
            (* Assert(FALSE); *)
          END (* case len *);
          INC( bix );
        END (* loop *);
        IF currentChNum = SecondCh THEN
          EXIT;
        ELSE
          INC( currentChNum );
          INC( currentChId );
        END (* if CurrentCh *);
      END (* loop *);
    END Reader;

  BEGIN (* Writer *)
    clicks := 0;
    Timer.NewMetronome( outLoop, 200 );(* 200 *)
    LOOP
      ended := 0;
      idxFirstCh  := MIN(SignalNames);
      idxSecondCh := MIN(SignalNames);
      LOOP
        currWait := 0;
        LOOP
          IF idxFirstCh = Terminator THEN
            EXIT;
          END (* if idxFirstCh *);
          WITH signals[idxFirstCh] DO
            IF active AND ( channel = First ) THEN
              IF controlled AND ( resultOK > 0 ) THEN
                DEC( resultOK );
                (* Assert( resultOK > 0 ); *)
                IF (resultOK = 0) AND (nvErrorCndF < MAX(CARDINAL)) THEN
                  INC(nvErrorCndF);
                END;
                IF (resultOK = 0) AND (locErrorCnd < MAX(CARDINAL)) THEN
                  INC(locErrorCnd);
                END;
              END (* if controlled *);
              currWait := waitPeriod;
              DigiRS.WriteString( FirstCh, command, commandLen );
              IF (type = AnalogOutput) OR (type = DigitalOutput) THEN
                active := FALSE;
              END;
              INC( idxFirstCh );
              IF idxFirstCh = Terminator THEN
                INC( ended );
              END (* if idxFirstCh *);
              EXIT;
            END (* if active *);
            INC( idxFirstCh );
            IF idxFirstCh = Terminator THEN
              INC( ended );
            END (* if idxFirstCh *);
          END (* with signals *);
        END (* loop *);
        LOOP
          IF idxSecondCh = Terminator THEN
            EXIT;
          END (* if idxSecondCh *);
          WITH signals[idxSecondCh] DO
            IF active AND ( channel = Second ) THEN
              IF controlled AND ( resultOK > 0 ) THEN
                DEC( resultOK );
                (* Assert( resultOK > 0 ); *)
                IF (resultOK = 0) AND (nvErrorCndS < MAX(CARDINAL)) THEN
                  INC(nvErrorCndS);
                END;
                IF (resultOK = 0) AND ( locErrorCnd < MAX(CARDINAL)) THEN
                  INC(locErrorCnd);
                END;
              END (* if controlled *);
              IF currWait < waitPeriod  THEN
                currWait := waitPeriod;
              END;
              DigiRS.WriteString( SecondCh, command, commandLen );
              IF (type = AnalogOutput) OR (type = DigitalOutput) THEN
                active := FALSE;
              END;
              INC( idxSecondCh );
              IF idxSecondCh = Terminator THEN
                INC( ended );
              END (* if idxSecondCh *);
              EXIT;
            END (* if active *);
            INC( idxSecondCh );
            IF idxSecondCh = Terminator THEN
              INC( ended );
            END (* if idxSecondCh *);
          END (* with signals *);
        END (* loop *);
        Timer.Wait( currWait );
        IF  ended = both THEN
          EXIT;
        END (* if *);
      END;
      Timer.Wait( 8 ); (* nie rozumiem *)
      Reader;
      (*$R-*)
      INC(currentSign);
      (*$R= *)
      Broadcast(BufferFull);
      Timer.WaitMetronome( outLoop, clicks, 200 );(* 200 *)
      IF clicks > 1  THEN
        Sound(1000);
      ELSE
        NoSound;
      END (* if *);
      IF clicks > maxClicks THEN
        (*
        Sound(1000 * clicks);
        *)
        maxClicks := clicks;
        (* Display( Ostrzezenie_ze_za_dlugo ); TO POWODUJE FATAL *)
      END;
    END (* loop *);
  END Writer;

VAR
  Ostrzezenie_ze_za_dlugo : Message;
BEGIN
  activated[ First ] := 0;
  activated[ Second ] := 0;
  
  csErrorCnt  := 0;
  nvErrorCndF := 0;
  nvErrorCndS := 0;
  maxClicks   := 0;
  NewMessage( Ostrzezenie_ze_za_dlugo, 
              "Nie nadazyl obslugiwac kostki DGH", 
              BITSET( 12345 ));
  currentSign := 0;
  binaryDtaSign := 0;
  Assert( DigiRS.SetBaudRate( FirstCh, BaudRate, 8 ) );
  Assert( DigiRS.SetBaudRate( SecondCh, BaudRate, 8 ) );
  MANAGER.InitC( BufferFull );
  MANAGER.STARTPROCESS( Writer, 01000H, 0 );
END DGHInterface.
