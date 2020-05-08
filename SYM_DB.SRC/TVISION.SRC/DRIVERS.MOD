(*%T TV_NoDebug*)
(*#debug(vid=>off)*)
(*%E*)
(*%T InOneSegment *)
(*#call(seg_name=>TV)*)
(*%E*)
IMPLEMENTATION MODULE Drivers;

FROM SYSTEM IMPORT
  Registers, ZeroFlag, DI, EI, TSIZE, Ret, GetFlags, SetFlags;
FROM Lib IMPORT
  Intr, Sound, NoSound, Delay, WordMove, Terminate, FatalError, WordFill, Fill,
  AddAddr, IncAddr, Dos, FarWordMove, DisableBreakCheck ,EnableBreakCheck,
  Compare;

(*%T UseMouse*)
FROM Mouse IMPORT
  EventSet, ButtonSet, Button, GetPosBut, Event, DriverInstalled, FlagReset,
  SetCursorPos, SetEventHandler, ShowCursor, HideCursor, SetHorizontalLimits,
  SetVerticalLimits;
(*%E*)
FROM Str IMPORT
  Concat, Pos, Length;
FROM Texts IMPORT
  ErrorString, RetryOrCancel, AltCodes1, AltCodes2;



(*# option(bit_opr=>on)*)

CONST
  ExtendedKeyboard = FALSE; (* Only 101/102 keys *)
  BiosSeg          = 40H;
  ScreenMonoBase   = 0B000H;
  ScreenColorBase  = 0B800H;


(*%T UseMouse*)

CONST
  EventQSize = 16;
TYPE
  TimerEvent = RECORD
    Time  : INTEGER;
    x, y : INTEGER;
    bs : ButtonSet;
    ks : KeyboardState;
  END;
(*%E*)
VAR
  StartupCursor : CARDINAL;
VAR

(*#save*)
(*#data(volatile=>on)*)
  TimerTicks : CARDINAL;


(*%T UseMouse*)
  EventQueue : ARRAY [0..EventQSize-1] OF TimerEvent;
  EventQCount, EventQHead, EventQTail : CARDINAL;
(*%E*)
  Ticks            [BiosSeg:6CH] : INTEGER; (* Tylko najmlodsza czesc *)
  Equipment        [BiosSeg:10H] : CARDINAL;
  CrtInfo          [BiosSeg:87H] : SHORTCARD;
  CrtRows          [BiosSeg:84H] : SHORTCARD;
(*#restore*)

TYPE
  Code26 = ARRAY[0..25] OF SHORTCARD ;

(*# save,
    call( reg_saved=>(dx,ax,bx,cx,si,di,es,ds,st1,st2),
          inline=>on )
*)

PROCEDURE PopStack()=Code26(
       08BH,0E5H,           (*  mov   sp,bp           *)
       083H,0C4H,01CH,      (*  add   sp,1CH          *)
       058H,                (*  pop   ax              *)
       05BH,                (*  pop   bx              *)
       059H,                (*  pop   cx              *)
       05AH,                (*  pop   dx              *)
       05EH,                (*  pop   si              *)
       05FH,                (*  pop   di              *)
       058H,                (*  pop   ax              *)
       01FH,                (*  pop   ds              *)
       007H,                (*  pop   es              *)
       08BH,0ECH,           (*  mov   bp,sp           *)
       080H,04EH,004H,001H, (*  or    byte [bp][4],1  *)
       08BH,0E8H,           (*  mov   bp,ax           *)
       0B8H,0FFH,000H,      (*  mov   ax,0FFH         *)
       0CFH);               (*  iret                  *)
(*#restore*)

VAR
  TerminateChain : PROC;
(*----------------------------------------------------------------------*)
(* Actual Int24 Interrupt Handler
*)

(* pragmas for interrupt handler *)
(*# save,
    call(interrupt => on,
         reg_param => (),
         same_ds   => off),
   check(stack=>off,index=>off,range=>off,overflow=>off,nil_ptr=>off),
   data(near_ptr=>off)
*)

OldInt8, Int8[0:4*8H] : PROCEDURE;
(* NB, The interrupt pragma sets up the registers as parameters to the
       procedure in the order defined below. This allows easy access to
       the entry registers
*)
  OldInt24, Int24[0:4*24H] : FarADDRESS;

(*----------------------------------------------------------------------*)
(* The pop stack inline code is required if the program should
   continue after an abort (returning 255 to the calling program).
*)

PROCEDURE OwnInt24Handler ( Flags : BITSET;        (* Registers on entry *)
                            CS,IP : CARDINAL;
                            AX,CX : CARDINAL;
                            DX,BX : CARDINAL;
                            SP,BP : CARDINAL;
                            SI,DI : CARDINAL;
                            DS,ES : CARDINAL ) ;
VAR
  Drive : SHORTCARD;
  r : Registers;
TYPE
  bp = POINTER TO SHORTCARD;
BEGIN
  (* N.B. Only DOS functions <= 12 may be called from a critical
     error handler
  *)
  Drive := VAL( SHORTCARD, AX MOD 100H );
  DI := DI MOD 100H;
  IF DI = 9 THEN (* Out of paper *)
    Drive := 0FFH;
  ELSIF AX < 8000H (* most significant bit NOT set *) THEN
    (* Disk Error *)
  ELSE
    DI := 13; (* Bad memory image of FAT *)
    (* BP:SI pointer to device header *)
    IF [BP:SI+5 bp]^ < 80H (* MSb NOT set *) THEN
      (* Block device *)
    ELSE
      INC( DI );   (* Device access error *)
      Drive := 0FFH
    END;
  END;

  IF NOT SysErrorFunc( Drive, DI (* Error *)) THEN
    (* Retry *)
    ADR(AX)^ := 1; (* Retry error code *)
    PopStack; (* Removes MSDOS call frame and Return 255 to caller *)
    (* Does not return here *)
  ELSE
    INC( DI, 19 );
    IF AX DIV 100H < 39H THEN
      (* DOS 2.0 style function *)
      DI := 0FFFFH;
    END;
    r.AH := 54H; (* Dummy Dos call to get DOS into stable state *)
    Dos( r );
    ADR(AX)^ := DI; (* return code *)
    PopStack; (* Removes MSDOS call frame and Return 255 to caller *)
    (* Does not return here *)
  END;
END OwnInt24Handler;
(*# restore *)


INLINE PROCEDURE MousePresent():BOOLEAN;
BEGIN
(*%F UseMouse*)
  RETURN FALSE;
(*%E*)
(*%T UseMouse*)
  RETURN ButtonCount # 0;
(*%E*)
END MousePresent;

(*%T UseMouse*)
INLINE PROCEDURE MouseButtonReverse(VAR bs : ButtonSet);
VAR
  b : ButtonSet;
BEGIN
  IF MouseReverse THEN
    b := ButtonSet{};
    IF LeftButton IN bs THEN
      INCL(b, RightButton);
    END;
    IF MiddleButton IN bs THEN
      INCL(b, MiddleButton);
    END;
    IF RightButton IN bs THEN
      INCL(b, LeftButton);
    END;
    bs := b;
  END;
END MouseButtonReverse;

VAR
  Last : TEvent;
  DownButtons : Buttons;
  DownWhere : Objects.TPoint;
  DownTicks : INTEGER;
  AutoTicks : INTEGER;
  AutoDelay : INTEGER;


PROCEDURE GetMouseEvent(VAR e : TEvent);
VAR
  EventTime : INTEGER;

  PROCEDURE GetMouseState;
  BEGIN
    DI;
    IF EventQCount = 0 THEN
      e.Buttons := MouseButtons;
      e.Where := MouseWhere;
      EventTime := Ticks;
      e.EState := BiosKeyboardState;
    ELSIF EventQCount < EventQSize THEN
      WITH EventQueue[ EventQTail ] DO
        e.Buttons := bs;
        e.Where.X := x;
        e.Where.Y := y;
        e.EState := ks;
        EventTime := Time;
      END;
      EventQTail := ( EventQTail+1 ) MOD EventQSize;
      DEC( EventQCount );
    END;
    EI;
    MouseButtonReverse(e.Buttons);
  END GetMouseState;

  PROCEDURE CheckAuto;
  BEGIN
    IF ( e.Where.X # Last.Where.X ) OR ( e.Where.Y # Last.Where.Y ) THEN
      e.What := EventTypes{ evMouseMove };
    ELSIF e.Buttons # ButtonSet{} THEN
      IF EventTime-AutoTicks >= AutoDelay THEN
        AutoTicks := EventTime;
        AutoDelay := 1;
        e.What := EventTypes{ evMouseAuto };
      END;
    END;
  END CheckAuto;

BEGIN
  e.What := evNothing;
  IF DriverInstalled THEN
    GetMouseState;
    e.Double := Last.Double;
    IF e.Buttons # Last.Buttons THEN
      IF Last.Buttons = ButtonSet{} THEN
        e.Double := FALSE;
        IF ( e.Buttons = DownButtons ) &
           ( e.Where.X = DownWhere.X ) &
           ( e.Where.Y = DownWhere.Y ) &
           ( EventTime - DownTicks <= VAL( INTEGER, DoubleDelay))
        THEN
          e.Double := TRUE;
        END;
        DownButtons := e.Buttons;
        DownWhere.X := e.Where.X;
        DownWhere.Y := e.Where.Y;
        DownTicks := EventTime;
        AutoTicks := EventTime;
        AutoDelay := RepeatDelay;
        e.What := EventTypes{ evMouseDown };
      ELSIF e.Buttons = ButtonSet{} THEN
        e.What := EventTypes{ evMouseUp };
      ELSE
        e.Buttons := Last.Buttons;
        CheckAuto;
      END;
    ELSE
      CheckAuto;
    END;
  END;
  Last := e;
END GetMouseEvent;

(*# save*)
(*# call(reg_param=>(ax, bx, cx, dx, si, di),near_call=>off,same_ds=>off) *)
(*# check(overflow=>off, range=>off, stack=>off) *)
PROCEDURE MouseIntHandler( ev : EventSet;
                           bs : ButtonSet;
                           x, y : INTEGER;
                           dx, dy : INTEGER);
VAR
  Tev : TimerEvent;
BEGIN
  x := x DIV 8;
  y := y DIV 8;
  MouseWhere.X := x;
  MouseWhere.Y := y;
  MouseButtons := bs;
  IF NOT ( Motion IN ev ) THEN
    DI;
    IF EventQCount < EventQSize THEN
      Tev.Time := Ticks;
      Tev.bs := bs;
      Tev.x := x;
      Tev.y := y;
      EventQueue[ EventQHead ] := Tev;
      EventQHead := (EventQHead+1) MOD EventQSize;
      INC( EventQCount );
    END;
    EI;
  END;
  MouseIntFlag := TRUE;
END MouseIntHandler;
(*# restore*)
(*%E*)

PROCEDURE InitEvents;
VAR
  st : INTEGER;
  bu : CARDINAL;
BEGIN
(*%F UseMouse*)
  RETURN;
(*%E*)
(*%T UseMouse*)
  IF NOT DriverInstalled THEN
    RETURN
  END;
  FlagReset(st, bu);
  IF st = 0 THEN
    RETURN;
  END;
  ButtonCount := VAL(SHORTCARD, bu);
  SetCursorPos(0,0);
  EventQHead := 0;
  EventQTail := 0;
  SetEventHandler(EventSet{Motion..MiddleUp}, MouseIntHandler);
(*%E*)
END InitEvents;

PROCEDURE GetTimeEvent( VAR Event : TEvent );
VAR
  flags : CARDINAL;
  t     : CARDINAL;
BEGIN
  flags := GetFlags();
  DI;
  t := TimerTicks;
  SetFlags( flags );
  IF t=0 THEN
    Event.What := evNothing;
  ELSE
    Event.What := EventTypes{evTimer};
    Event.TicksPending := t;
  END;
END GetTimeEvent;

PROCEDURE DoneEvents;
BEGIN
(*%F UseMouse*)
  RETURN;
(*%E*)
(*%T UseMouse*)
  IF NOT MousePresent() THEN
    RETURN;
  END;
  HideMouse;
  ButtonCount := 0;
  SetEventHandler(EventSet{}, MouseIntHandler);
(*%E*)
END DoneEvents;

VAR
  MouseShowLock : CARDINAL;

PROCEDURE ShowMouse;
BEGIN
(*%T UseMouse*)
  DEC(MouseShowLock);
  IF MouseShowLock = 0 THEN
    IF MousePresent() THEN
      ShowCursor;
    END;
  END;
(*%E*)
END ShowMouse;

PROCEDURE HideMouse;
BEGIN
(*%T UseMouse*)
  IF MouseShowLock = 0 THEN
    IF MousePresent() THEN
      HideCursor;
    END;
  END;
  INC(MouseShowLock);
(*%E*)
END HideMouse;

PROCEDURE GetKeyEvent(VAR Event: TEvent);
VAR
  r : Registers;
BEGIN
(*%T ExtendedKeyboard *)
  r.AH := 11H;
(*%E*)
(*%F ExtendedKeyboard *)
  r.AH := 01H;
(*%E*)
  Intr(r, 16H); (* Any KeyStoke pending? *)
  IF NOT (ZeroFlag IN r.Flags) THEN
(*%T ExtendedKeyboard *)
    r.AH := 10H;
(*%E*)
(*%F ExtendedKeyboard *)
    r.AH := 0H;
(*%E*)
    Intr(r, 16H); (* ReadKey & Wait *)
    Event.What := EventTypes { evKeyDown };
    Event.KeyCode := r.AX;
    Event.KState := BiosKeyboardState;
  ELSE
    Event.What := evNothing;
  END;
END GetKeyEvent;

PROCEDURE GetCursorType():CARDINAL;
VAR
  r : Registers;
BEGIN
  r.AH := 3;
  r.BH := 0;
  Intr(r, 10H);
  RETURN r.CX;
END GetCursorType;

PROCEDURE SetCursorType( ct : CARDINAL );
VAR
  r : Registers;
BEGIN
  r.AH := 1;
  r.CX := ct;
  Intr(r, 10H);
END SetCursorType;

PROCEDURE ClearDisplay( w, h : CARDINAL );
VAR
  r : Registers;
BEGIN
  r.BH := 7;
  r.CX := 0;
  r.DL := VAL( SHORTCARD, w);
  r.DH := VAL( SHORTCARD, h - 1);
  r.AX := 0600H;
  Intr(r, 10H);
END ClearDisplay;

PROCEDURE GetRows() : CARDINAL;
VAR
  r : Registers;
BEGIN
  r.AX := 01130H;
  r.BH := 0;
  r.DL := 0;
  Intr(r, 10H);
  IF r.DL = 0 THEN
    r.DL := 24;
  END;
  RETURN ORD(r.DL) + 1;
END GetRows;

PROCEDURE GetCols() : CARDINAL;
VAR
  r : Registers;
BEGIN
  r.AH := 00FH;
  Intr(r, 10H);
  RETURN ORD(r.AH);
END GetCols;

PROCEDURE GetCrtMode() : CARDINAL;
VAR
  r : Registers;
BEGIN
  r.AH := 0FH;
  Intr(r, 10H);
  r.AH := 0;
  IF GetRows() > 25 THEN
    r.AX := r.AX OR smFont8x8;
  END;
  RETURN r.AX;
END GetCrtMode;

PROCEDURE SetCrtMode( Mode : CARDINAL );
VAR
  r : Registers;
BEGIN
  Equipment := Equipment & 0FFCFH;
  IF Mode = smMono THEN
    Equipment := Equipment OR 30H;
  ELSE
    Equipment := Equipment OR 20H;
  END;
  CrtInfo := CrtInfo & 000FEH;
  r.AH := 0;
  r.AL := VAL(SHORTCARD, Mode MOD 100H);
  Intr(r, 10H);
  IF (Mode & smFont8x8) # 0 THEN
    r.AX := 01112H;
    r.BL := 0;
    Intr(r, 10H);
    IF GetRows() > 25 THEN
      INC(CrtInfo);
      r.AH := 1;
      r.CX := 00600H;
      Intr(r, 10H);
      r.AH := 012H;
      r.BL := 020H;
      Intr(r, 10H);
    END;
  END;
END SetCrtMode;

PROCEDURE FixCrtMode( Mode : CARDINAL ) : CARDINAL;
VAR
  m : CARDINAL;
BEGIN
  m := Mode MOD 100H;
  IF (m # smMono) & (m # smCO80) & (m # smBW80 ) THEN
    m := smCO80;
  END;
  RETURN m + ( Mode & 0FF00H);
END FixCrtMode;

PROCEDURE SetCrtData;
BEGIN
  ScreenMode := GetCrtMode();
  ScreenWidth := GetCols();
  ScreenHeight := GetRows();
  HiResScreen := ScreenHeight > 25;
  IF ScreenMode = smMono THEN
    ScreenBuffer := ScreenMonoBase;
    CheckSnow := FALSE;
  ELSE
    ScreenBuffer := ScreenColorBase;
    IF HiResScreen THEN
      CheckSnow := FALSE;
    END;
  END;
  CursorLines := GetCursorType();
  SetCursorType( 02000H );
(*%T UseMouse*)
  IF MousePresent() THEN
    SetHorizontalLimits( 0, (ScreenWidth-1)*8);
    SetVerticalLimits(0, (ScreenHeight-1)*8);
    SetCursorPos((ScreenWidth DIV 2)*8, (ScreenHeight DIV 2)*8);
    ShowMouse;
  END;
(*%E*)
END SetCrtData;

PROCEDURE SetVideoMode(Mode: CARDINAL);
BEGIN
  SetCrtMode( FixCrtMode( Mode ) );
  SetCrtData();
END SetVideoMode;

PROCEDURE ClearScreen;
BEGIN
  ClearDisplay( ScreenWidth, ScreenHeight );
END ClearScreen;

PROCEDURE InitVideo;
BEGIN
  StartupMode := GetCrtMode();
  StartupCursor := GetCursorType();
  SetCrtData();
END InitVideo;

PROCEDURE DoneVideo;
BEGIN
  IF StartupMode # ScreenMode THEN
    SetCrtMode( StartupMode );
  END;
  ClearScreen();
  SetCursorType( StartupCursor );
END DoneVideo;

PROCEDURE Beep;
BEGIN
  Sound(100);
  Delay(1000);
  NoSound;
END Beep;

PROCEDURE SwapStatusLine(VAR New : TDrawBuffer);
VAR
  Old : TDrawBuffer;
  Off : CARDINAL;
BEGIN
  Off := 2*ScreenHeight*(ScreenWidth-1);
  FarWordMove([ScreenBuffer:Off], FarADR(Old), ScreenWidth);
  FarWordMove(FarADR(New), [ScreenBuffer:Off], ScreenWidth);
  New := Old;
END SwapStatusLine;

PROCEDURE SelectKey():BOOLEAN;
VAR
  scrType : CARDINAL;
  Ev : TEvent;
BEGIN
  scrType := GetCursorType();
  SetCursorType( 02000H );
  LOOP
    REPEAT
      GetKeyEvent(Ev);
    UNTIL ( Ev.What = EventTypes { evKeyDown } );
    IF Ev.CharCode = 15C (* cr *) THEN
      SetCursorType( scrType );
      RETURN FALSE;
    ELSIF Ev.CharCode = 33C (* esc *) THEN
      SetCursorType( scrType );
      RETURN TRUE;
    ELSE
      Beep;
    END;
  END;
END SelectKey;

PROCEDURE SystemError(Drive: SHORTCARD; ErrorCode: CARDINAL ): BOOLEAN;
VAR
  c : CARDINAL;
  s : ARRAY [0..79 ] OF CHAR;
  b : TDrawBuffer;
  res : BOOLEAN;
BEGIN
  IF ScreenMode & 0FFH = smMono THEN
    c := SysMonoAttr;
  ELSE
    c := SysColorAttr;
  END;
  Concat(s, ErrorString[ErrorCode], CHR(Drive+41H));
  MoveChar( b, 0, ' ', c, 80);
  MoveCStr( b, 1, s, c);
  MoveCStr( b, 79-CStrLen(RetryOrCancel), RetryOrCancel, c);
  SwapStatusLine(b);
  res := SelectKey();
  SwapStatusLine(b);
  RETURN res;
END SystemError;

PROCEDURE Terminator;
BEGIN
  DoneVideo;
  DoneSysError;
  TerminateChain;
END Terminator;

(*#save, call( interrupt=>on ), check( stack=>off, range=>off, index=>off, overflow=>off)*)
PROCEDURE TimeInterruptHandler;
VAR
  flags : CARDINAL;
BEGIN
  flags := GetFlags();
  DI;
  INC( TimerTicks );
  SetFlags( flags );
  OldInt8;
END TimeInterruptHandler;
(*#restore*)

PROCEDURE InitSysError;
BEGIN
(*%F Debug *)
  DI;
  OldInt24 := Int24;
  Int24 := FarADDRESS( OwnInt24Handler );
  EI;
(*%E*)
(*%F SimulatedTimer *)
  DI;
  OldInt8 := Int8;
  Int8 := TimeInterruptHandler;
  EI;
(*%E*)
(*  Terminate(Terminator, TerminateChain);*)
(*  DisableBreakCheck;*)
END InitSysError;

PROCEDURE DoneSysError;
VAR
  r : FarADDRESS;
BEGIN
(*%F Debug *)
  DI;
  IF OldInt24 # FarNIL THEN
    Int24 := OldInt24;
    OldInt24 := FarNIL;
  END;
  EI;
(*%E*)
(*%F SimulatedTimer *)
  DI;
  r := [0:0];
  IF Compare( ADR( OldInt8 ), ADR( r ), SIZE( OldInt8 )) # 0 THEN
    Int8 := OldInt8;
    Fill( ADR( OldInt8 ), SIZE( OldInt8 ), 0 );
  END;
  EI;
(*%E*)
END DoneSysError;
(*
CONST
  AltCodes1 = "QWERTYUIOP    ASDFGHJKL     ZXCVBNM";
  AltCodes2 = '1234567890-=';
*)
PROCEDURE GetAltChar(KeyCode: CARDINAL): CHAR;
VAR
  tmp : CARDINAL;
BEGIN
  IF (KeyCode & 0FFH) = 0 THEN
    tmp := KeyCode >> 8;
    IF tmp = 2 THEN
      RETURN CHR(0F0H);      (* special case to handle alt-Space *)
    ELSIF (tmp >= 010H) & (tmp <= 032H ) THEN
      RETURN AltCodes1[tmp-010H];     (* alt-letter *)
    ELSIF (tmp >= 078H) & (tmp <= 083H ) THEN
      RETURN AltCodes2[tmp - 078H];   (* alt-number *)
    END;
  END;
  RETURN 0C;
END GetAltChar;

PROCEDURE GetAltCode( c : CHAR): CARDINAL;
VAR
  i : CARDINAL;
BEGIN
  IF  c = 0C THEN
    RETURN 0;
  END;
  c := CAP(c);
  IF c = CHR(0F0H) THEN
    RETURN 0200H;       (* special case to handle alt-Space *)
  END;
  FOR i := 0 TO SIZE(AltCodes1 )-1 DO
    IF AltCodes1[i] = c THEN
      RETURN (i+010H) << 8;
    END;
  END;
  FOR i := 0 TO SIZE(AltCodes2)-1 DO
    IF AltCodes2[i] = c THEN
      RETURN (i+078H) << 8;
    END;
  END;
  RETURN 0;
END GetAltCode;

PROCEDURE CtrlToArrow(KeyCode: CARDINAL): CARDINAL;
TYPE
  SpecCodes = ARRAY [0..10] OF CARDINAL;
CONST
  CtrlCodes = SpecCodes( kbCtrlS, kbCtrlD, kbCtrlE, kbCtrlX, kbCtrlA,
                         kbCtrlF, kbCtrlG, kbCtrlV, kbCtrlR, kbCtrlC,
                         kbCtrlH );
  ArrowCodes= SpecCodes( kbLeft, kbRight, kbUp, kbDown, kbHome,
                         kbEnd,  kbDel,   kbIns,kbPgUp, kbPgDn,
                         kbBack);
VAR
  i : CARDINAL;
BEGIN
  FOR i := 0 TO TSIZE(SpecCodes) DIV SIZE( CARDINAL )-1 DO
    IF KeyCode MOD 100H = CtrlCodes[i] THEN
      RETURN ArrowCodes[i];
    END;
  END;
  RETURN KeyCode;
END CtrlToArrow;

PROCEDURE HotKey(VAR str : ARRAY OF CHAR) : CHAR;
VAR
  p : CARDINAL;
BEGIN
  p := Pos(str, '~');
  IF p = MAX(CARDINAL) THEN
    RETURN 0C;
  ELSE
    IF p+1 >= Length(str) THEN
      RETURN 0C;
    ELSE
      RETURN str[p+1];
    END;
  END;
END HotKey;

PROCEDURE CStrLen(S: ARRAY OF CHAR): CARDINAL;
VAR
  len, ix : CARDINAL;
BEGIN
  len := 0;
  ix := 0;
  WHILE (ix <= HIGH(S)) & (S[ix] # 0C) DO
    IF S[ix] # '~' THEN
      INC(len);
    END;
    INC(ix);
  END;
  RETURN len;
END CStrLen;

PROCEDURE Assert(Val : BOOLEAN);
BEGIN
  IF Val THEN
    FatalError('Assert error...');
  END;
END Assert;

TYPE AA = ARRAY [0..9] OF SHORTCARD;

INLINE PROCEDURE PairCharAttr( ch : CHAR;
                               attr : CARDINAL;
                               Low : BOOLEAN) : CARDINAL =
AA(00AH, 0C9H, (*             or  cl, cl *)
   074H, 004H, (*             je  High   *)
   088H, 0DCH, (*             mov ah,bl  *)
   0EBH, 002H, (*             jmp Exit   *)
   088H, 0FCH  (* High:       mov ah,bh  *)
               (* Exit:                  *));


PROCEDURE MoveChar( VAR b      : TDrawBuffer;
                        XOfs   : CARDINAL;
                        ch     : CHAR;
                        attr   : CARDINAL;
                        Count  : CARDINAL);
VAR
  i : CARDINAL;
BEGIN
  IF ch = 0C THEN
    FOR i := XOfs TO XOfs+Count-1 DO
      PutAttribute( b, i, attr );
    END;
  ELSE
    WordFill( ADR( b[ XOfs ]), Count, PairCharAttr(ch, attr, TRUE));
  END;
END MoveChar;

PROCEDURE MoveStr( VAR b       : TDrawBuffer;
                       XOfs    : CARDINAL;
                       str     : ARRAY OF CHAR;
                       Attrs   : CARDINAL);
VAR
  ix : CARDINAL;
BEGIN
  IF Attrs = 0 THEN
    FOR ix := 1 TO Length( str ) DO
      b[ XOfs ] := PairCharAttr( str[ ix-1 ], b[ XOfs ], TRUE );
    END;
  ELSE
    ix := 0;
    WHILE (ix <= HIGH(str)) & (str[ix] # 0C) DO
      b[XOfs] := PairCharAttr(str[ix], Attrs, TRUE);
      INC( XOfs );
      INC(ix);
    END;
  END;
END MoveStr;

PROCEDURE MoveCStr( VAR b      : TDrawBuffer;
                        XOfs   : CARDINAL;
                        str    : ARRAY OF CHAR;
                        Attr   : CARDINAL );
VAR
  ix : CARDINAL;
  Low : BOOLEAN;
BEGIN
  ix := 0;
  Low := TRUE;
  WHILE (ix <= HIGH(str)) & (str[ix] # 0C) DO
    IF str[ix] = '~' THEN
      Low := NOT Low;
    ELSE
      b[XOfs] := PairCharAttr(str[ix], Attr, Low);
      INC(XOfs)
    END;
    INC(ix);
  END;
END MoveCStr;

PROCEDURE MoveBuf( VAR b       : TDrawBuffer;
                       XOfs    : CARDINAL;
                       Source  : ARRAY OF CHAR;
                       Attr    : CARDINAL;
                       Count   : CARDINAL);
VAR
 ix : CARDINAL;
BEGIN
  IF Count > 0 THEN
    IF Attr = 0 THEN
      FOR ix := 0 TO Count-1 DO
        b[XOfs] := PairCharAttr(Source[ix], b[XOfs], TRUE);
        INC(XOfs);
      END;
    ELSE
      FOR ix := 0 TO Count-1 DO
        b[XOfs] := PairCharAttr(Source[ix], Attr, TRUE);
        INC(XOfs);
      END;
    END;
  END;
END MoveBuf;

PROCEDURE PutAttribute( VAR b     : TDrawBuffer;
                            XOfs  : CARDINAL;
                            Attr  : CARDINAL);
BEGIN
  b[XOfs] := PairCharAttr(CHR(b[XOfs] MOD 100H), Attr, TRUE);
END PutAttribute;

PROCEDURE PutChar( VAR b    : TDrawBuffer;
                       XOfs : CARDINAL;
                       Ch   : CHAR);
BEGIN
  b[XOfs] := PairCharAttr(Ch, b[XOfs], FALSE);
END PutChar;


(*%F UseMouse*)
PROCEDURE GetMouseEvent(VAR e : TEvent);
BEGIN
  e.What := evNothing;
END GetMouseEvent;
(*%E*)

BEGIN
(*%T UseMouse*)
  Fill( ADR( Last ), SIZE( Last ), 0);
  ButtonCount  := 0;
  MouseReverse := FALSE;
  DoubleDelay  := 8;
  RepeatDelay  := 8;
  MouseShowLock := 1;
  MouseIntFlag := FALSE;
(*%E*)
  StartupMode  := 0FFFFH;
  SysErrorFunc := SystemError;
  SysColorAttr := 04E4FH;
  SysMonoAttr  := 07070H;
  CtrlBreakHit := FALSE;
  SaveCtrlBreak:= FALSE;
  SysErrActive := FALSE;
  OldInt24 := FarNIL;
(*%T Debug *)
  EnableBreakCheck;
(*%E*)
  TimerTicks := 0;
END Drivers.