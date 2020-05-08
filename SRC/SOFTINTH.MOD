(*.F- *)
(**********************************************************************
|  Title   : Software Interrupts Handlig Manager.
|  Author  : M.Postol
|  System  : LOGITECH MODULA-2/86
|  History :
|    20 Apr 1992:
|      Original version
|    15-11-1996: M.Postol
|      BP was not saved - corrected
|    27-12-1996: M.Postol
|      in Epilogue flags was not saved - corrected
|
**********************************************************************)
(*.F+ *)

IMPLEMENTATION MODULE SoftIntHandlingManager;
  IMPORT RTSMain, SYSTEM, Devices(*,  Sounds *);

FROM SYSTEM IMPORT
  ADR, CODE, DOSCALL, BYTE, ADDRESS;

  (*$S-*)
  (*$T-*)
  (*$R-*)
  
  CONST
    GetVector = 35H;
    SetVector = 25H;

  PROCEDURE SetEventHandler
            ( VAR handlerRec    : PrivateHandler;
                  handler       : EventHandler;
                  interruptNum  : CARDINAL);
  
  BEGIN
    WITH handlerRec DO
      FarCall     := BYTE(9AH);
      FarRet      := BYTE(0CFH); (* musi byc iret *)
      handlerProc := handler;
      DOSCALL(GetVector, interruptNum, oldVector);
    END; (* WITH *)
    DOSCALL(SetVector, ADR(handlerRec), interruptNum);
  END SetEventHandler;
  
  PROCEDURE RestoreEventHandler
            (     handlerRec    : PrivateHandler;
                  interruptNum  : CARDINAL);
  BEGIN
    WITH handlerRec DO
      DOSCALL(SetVector, oldVector, interruptNum);
    END; (* WITH *)
  END RestoreEventHandler;
  
  (*$S=*)
  (*$T=*)
  (*$R=*)

VAR
  break: BOOLEAN;
  
  (*$S- *)
  PROCEDURE checkBreak;
  BEGIN
    CODE(051H);   (* push cx *)
    CODE(01EH);   (* push ds *)
    IF break THEN
      break := FALSE;
      CODE(01FH);  (* pop ds *)
      CODE(059H);  (* pop cx *)
      CODE(0C9H);  (* LEAVE  *)
      CODE(044H);  (* INC SP *)
      CODE(044H);  (* INC SP *)
      CODE(044H);  (* INC SP *)
      CODE(044H);  (* INC SP *)
      CODE(0CFH);  (* IRET   *)
    END;
    CODE(01FH);    (* pop ds *)
    CODE(059H);    (* pop cx *)
  END checkBreak;
  (*$S= *)
  
  PROCEDURE  BreakChain;
  BEGIN
    break := TRUE;
  END BreakChain;
  
MODULE Monitor  [ 8 ];

  IMPORT
    TemplatePtr, ISR, Result, checkBreak;
    
  FROM RTSMain IMPORT
    InstallTermProc;

  FROM SYSTEM IMPORT
    ADDRESS, BYTE, ADR;

  FROM Devices IMPORT
    SaveInterruptVector, RestoreInterruptVector;

  (* 
  FROM Sounds IMPORT Sound, NoSound;
  *)
  EXPORT
    InstEpilogueHnd, InstPrologueHnd, UnInstallHandler;

  CONST
    Destroyed      = 27182;
    Active         = 31415;
    vectorPoz_Prol = 35;
    
  TYPE
    ISRDescriptorPtr = POINTER TO ISRDescriptor;
    ISRDescriptor    = RECORD
                         currState   : CARDINAL;
                         intVector   : CARDINAL;
                         nextDes     : ISRDescriptorPtr;
                         prevDes     : ISRDescriptorPtr;
                         prologue    : BOOLEAN;
                         ISRTemplate : ARRAY[ 0 .. 40 ] OF BYTE;
                       END;

  VAR
    firstISRDescriptorPtr : ISRDescriptorPtr;


  PROCEDURE InstPrologueHnd(IntVector       : CARDINAL;
                            ISRCallTemplate : TemplatePtr;
                            Handler         : ISR;
                            handlerPar      : ADDRESS     );

  VAR
    currISRDescriptorPtr : ISRDescriptorPtr;
    AddrPtr              : POINTER TO ADDRESS;
    ProcPtr              : POINTER TO ISR;
    PROCPtr              : POINTER TO PROC;
    CardPtr              : POINTER TO CARDINAL;

  BEGIN
    currISRDescriptorPtr := ADDRESS( ISRCallTemplate );
    (* setup the new interrupt services routine: *)
    WITH currISRDescriptorPtr^ DO
      ISRTemplate[0] := BYTE( 50H );   (* push ax *)
      ISRTemplate[1] := BYTE( 51H );   (* push cx *)
      ISRTemplate[2] := BYTE( 52H );   (* push dx *)
      ISRTemplate[3] := BYTE( 53H );   (* push bx *)
      ISRTemplate[4] := BYTE( 56H );   (* push si *)
      ISRTemplate[5] := BYTE( 57H );   (* push di *)
      ISRTemplate[6] := BYTE( 1EH );   (* push ds *)
      ISRTemplate[7] := BYTE( 06H );   (* push es *)
      ISRTemplate[8] := BYTE( 55H );   (* push bp *)
      (* push address of the condition *)
      ISRTemplate[9] := BYTE( 68H );   (* push immediate *)
      ISRTemplate[10] := BYTE( 00H );   (* address will be fixed below *)
      ISRTemplate[11] := BYTE( 00H );
      ISRTemplate[12] := BYTE( 68H );   (* push immediate *)
      ISRTemplate[13] := BYTE( 00H );   (* address will be fixed below *)
      ISRTemplate[14] := BYTE( 00H );
      ISRTemplate[15] := BYTE( 9AH );   (* call far *)
      ISRTemplate[16] := BYTE( 00H );   (* address will be fixed below *)
      ISRTemplate[17] := BYTE( 00H );   (* that routine saves and restores bp
                                        *)
      ISRTemplate[18] := BYTE( 00H );
      ISRTemplate[19] := BYTE( 00H );
      (* restore registers *)
      ISRTemplate[20] := BYTE( 5DH);    (* pop BP *)
      ISRTemplate[21] := BYTE( 07H );   (* pop es *)
      ISRTemplate[22] := BYTE( 1FH );   (* pop ds *)
      ISRTemplate[23] := BYTE( 5FH );   (* pop di *)
      ISRTemplate[24] := BYTE( 5EH );   (* pop si *)
      ISRTemplate[25] := BYTE( 5BH );   (* pop bx *)
      ISRTemplate[26] := BYTE( 5AH );   (* pop dx *)
      ISRTemplate[27] := BYTE( 59H );   (* pop cx *)
      ISRTemplate[28] := BYTE( 58H );   (* pop ax *)
      ISRTemplate[29] := BYTE( 9AH );   (* call far *)
      ISRTemplate[30] := BYTE( 00H );   (* address will be fixed below *)
      ISRTemplate[31] := BYTE( 00H );   (* break chain *)
      ISRTemplate[32] := BYTE( 00H );
      ISRTemplate[33] := BYTE( 00H );
      ISRTemplate[34] := BYTE( 0EAH );  (* JMP far *)
      ISRTemplate[35] := BYTE( 00H );   (* address will be fixed below *)
      ISRTemplate[36] := BYTE( 00H );   (* execute other interrupt handlers in
                                           chain *)
      ISRTemplate[37] := BYTE( 00H );
      ISRTemplate[38] := BYTE( 00H );
      AddrPtr := ADR( ISRTemplate[vectorPoz_Prol] );
      (* save current interrupt service routine: *)
      SaveInterruptVector( IntVector, AddrPtr^ );
      (* install new interrupt services routine: *)
      RestoreInterruptVector( IntVector, ADR( ISRTemplate[0] ) );
      PROCPtr := ADR( ISRTemplate[30] );
      PROCPtr^ := checkBreak;
      ProcPtr := ADR( ISRTemplate[16] );
      ProcPtr^ := Handler;
      CardPtr := ADR( ISRTemplate[10] );
      CardPtr^ := handlerPar.SEGMENT;
      CardPtr := ADR( ISRTemplate[13] );
      CardPtr^ := handlerPar.OFFSET;
      IF firstISRDescriptorPtr # NIL THEN
        firstISRDescriptorPtr^.prevDes := currISRDescriptorPtr;
      END (* if firstISRDescriptorPtr *);
      currState := Active;
      prevDes := NIL;
      intVector := IntVector;
      nextDes := firstISRDescriptorPtr;
      prologue := TRUE;
    END (* with currISRDescriptorPtr *);
    firstISRDescriptorPtr := currISRDescriptorPtr;
  END InstPrologueHnd;


  PROCEDURE InstEpilogueHnd(IntVector       : CARDINAL;
                            ISRCallTemplate : TemplatePtr;
                            Handler         : ISR;
                            handlerPar      : ADDRESS     );

  VAR
    currISRDescriptorPtr : ISRDescriptorPtr;
    AddrPtr              : POINTER TO ADDRESS;
    ProcPtr              : POINTER TO ISR;
    CardPtr              : POINTER TO CARDINAL;

  BEGIN
    currISRDescriptorPtr := ADDRESS( ISRCallTemplate );
    (* setup the new interrupt services routine: *)
    WITH currISRDescriptorPtr^ DO
      ISRTemplate[0] := BYTE( 9CH );   (* push flags *)
      ISRTemplate[1] := BYTE( 9AH );   (* call far *)
      ISRTemplate[2] := BYTE( 00H );   (* address will be fixed below *)
      ISRTemplate[3] := BYTE( 00H );   (* execute other interrupt handlers in
                                          chain *)
      ISRTemplate[4] := BYTE( 00H );
      ISRTemplate[5] := BYTE( 00H );
      ISRTemplate[6] := BYTE( 9CH );   (* push flags *)
      ISRTemplate[7] := BYTE( 50H );   (* push ax *)
      ISRTemplate[8] := BYTE( 51H );   (* push cx *)
      ISRTemplate[9] := BYTE( 52H );   (* push dx *)
      ISRTemplate[10] := BYTE( 53H );   (* push bx *)
      ISRTemplate[11] := BYTE( 56H );   (* push si *)
      ISRTemplate[12] := BYTE( 57H );   (* push di *)
      ISRTemplate[13] := BYTE( 1EH );   (* push ds *)
      ISRTemplate[14] := BYTE( 06H );   (* push es *)
      (* push address of the condition *)
      ISRTemplate[15] := BYTE( 68H );   (* push immediate *)
      ISRTemplate[16] := BYTE( 00H );   (* address will be fixed below *)
      ISRTemplate[17] := BYTE( 00H );
      ISRTemplate[18] := BYTE( 68H );   (* push immediate *)
      ISRTemplate[19] := BYTE( 00H );   (* address will be fixed below *)
      ISRTemplate[20] := BYTE( 00H );
      ISRTemplate[21] := BYTE( 9AH );   (* call far *)
      ISRTemplate[22] := BYTE( 00H );   (* address will be fixed below *)
      ISRTemplate[23] := BYTE( 00H );   (* that routine saves and restores bp
                                        *)
      ISRTemplate[24] := BYTE( 00H );
      ISRTemplate[25] := BYTE( 00H );
      (* restore registers *)
      ISRTemplate[26] := BYTE( 07H );   (* pop es    *)
      ISRTemplate[27] := BYTE( 1FH );   (* pop ds    *)
      ISRTemplate[28] := BYTE( 5FH );   (* pop di    *)
      ISRTemplate[29] := BYTE( 5EH );   (* pop si    *)
      ISRTemplate[30] := BYTE( 5BH );   (* pop bx    *)
      ISRTemplate[31] := BYTE( 5AH );   (* pop dx    *)
      ISRTemplate[32] := BYTE( 59H );   (* pop cx    *)
      ISRTemplate[33] := BYTE( 58H );   (* pop ax    *)
      ISRTemplate[34] := BYTE( 09DH );  (* pop flags *)
      ISRTemplate[35] := BYTE( 0CAH );  (* ret far 2 *)
      ISRTemplate[36] := BYTE( 002H );  
      ISRTemplate[37] := BYTE( 000H );  
      AddrPtr := ADR( ISRTemplate[2] );
      (* save current interrupt service routine: *)
      SaveInterruptVector( IntVector, AddrPtr^ );
      (* install new interrupt services routine: *)
      RestoreInterruptVector( IntVector, ADR( ISRTemplate[0] ) );
      ProcPtr := ADR( ISRTemplate[22] );
      ProcPtr^ := Handler;
      CardPtr := ADR( ISRTemplate[16] );
      CardPtr^ := handlerPar.SEGMENT;
      CardPtr := ADR( ISRTemplate[19] );
      CardPtr^ := handlerPar.OFFSET;
      IF firstISRDescriptorPtr # NIL THEN
        firstISRDescriptorPtr^.prevDes := currISRDescriptorPtr;
      END (* if firstISRDescriptorPtr *);
      currState := Active;
      prevDes := NIL;
      intVector := IntVector;
      nextDes := firstISRDescriptorPtr;
      prologue := FALSE;
    END (* with currISRDescriptorPtr *);
    firstISRDescriptorPtr := currISRDescriptorPtr;
  END InstEpilogueHnd;


  PROCEDURE UnInstallHandler(ISRCallTemplate : TemplatePtr ) : Result;

  VAR
    oldVector            : ADDRESS;
    AddrPtr              : POINTER TO ADDRESS;
    currISRDescriptorPtr : ISRDescriptorPtr;

  BEGIN (* UnInstallHandler *)
    currISRDescriptorPtr := ADDRESS( ISRCallTemplate );
    WITH currISRDescriptorPtr^ DO
      IF currState # Active THEN
        IF currState = Destroyed THEN
          RETURN ISRPrevDestroyed;
        ELSE
          RETURN ISRDonotExist;
        END (* if currState *);
      END (* if currState *);
      SaveInterruptVector( intVector, oldVector );
      IF oldVector <> ADR( ISRTemplate[0] ) THEN
        RETURN ErrorInISRsChain;
      END (* if oldVector *);
      currState := Destroyed;
      IF prologue  THEN
        AddrPtr := ADR( ISRTemplate[vectorPoz_Prol] );
      ELSE
        AddrPtr := ADR( ISRTemplate[2] );
      END;
      (* install old interrupt services routine: *)
      RestoreInterruptVector( intVector, AddrPtr^ );
      IF prevDes = NIL THEN
        firstISRDescriptorPtr := nextDes;
      ELSE
        prevDes^.nextDes := nextDes;
      END (* if prevDes *);
      IF nextDes # NIL THEN
        nextDes^.prevDes := prevDes;
      END (* if nextDes *);
    END (* with currISRDescriptorPtr *);
    RETURN OK;
  END UnInstallHandler;


  PROCEDURE UnInstallAllHandlers;

  VAR
    currRes : Result; 
    hz      : CARDINAL;
    idx1     : CARDINAL;
    idx2     : CARDINAL;
  BEGIN
    hz := 1000;
    WHILE firstISRDescriptorPtr # NIL DO
      (* Sound(hz); *)
      FOR idx2 := 0 TO 10 DO 
        FOR idx1 := 0 TO 50000 DO END;
      END;
      currRes := UnInstallHandler( TemplatePtr( firstISRDescriptorPtr ) );
      IF currRes <> OK  THEN
        currRes := currRes; (* miejsce na break point *)
      END;
      (* NoSound; *)
      hz := 2 * hz;
    END (* while firstISRDescriptorPtr *);
  END UnInstallAllHandlers;

BEGIN
  firstISRDescriptorPtr := NIL;
  InstallTermProc( UnInstallAllHandlers );
  (* zrobic: - definicje - zadeklarowac stale dla znanych wektorow - procedure
     likwidujaca wszystkie wektory przed zakonczeniem programu *)
END Monitor;

BEGIN
  break := FALSE;
END SoftIntHandlingManager.
