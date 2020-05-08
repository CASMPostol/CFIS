(*%T TV_NoDebug*)
(*# debug(vid=>off)*)
(*%E*)
(*%T InOneSegment *)
(*#call(seg_name=>TV)*)
(*%E*)
IMPLEMENTATION MODULE App;

FROM Views IMPORT
  TView, PView, TGroup, PPalette, TViewGrowModes, TViewGrowMode, TViewState,
  TViewStates, TViewOption, TViewOptions, Message, CommandSetChanged,
  ShadowSize, ShowMarkers;
FROM Commands IMPORT
  cmSelectWindowNum, cmNext, cmCommandSetChanged, cmQuit, cmPrev,
  cmMenu, cmClose, cmZoom, cmResize, cmValid;
FROM Drivers IMPORT
  TEvent, TDrawBuffer, EventTypes, EventType, ScreenWidth, ScreenHeight,
  ScreenBuffer, evNothing, GetKeyEvent, GetMouseEvent, GetAltChar,
  ScreenMode, smMono, InitVideo, DoneVideo, InitEvents, InitSysError,
  DoneSysError, DoneEvents, MoveChar, GetTimeEvent,
  smFont8x8, smBW80, HideMouse, SetVideoMode, ShowMouse,
  kbAltX, kbF10, kbAltF3, kbF5, kbCtrlF5, kbF6;
FROM Objects IMPORT
  TRect, TPoint, LongMul, LongDiv;
FROM Streams IMPORT
  TStream;
FROM Menus IMPORT
  PStatusLine, PMenuView, NewStatusDef, NewStatusKey;
FROM HistList IMPORT
  InitHistory, DoneHistory;
FROM Texts IMPORT
  DefaultBkgrnd, CBackground, CColor, CBlackWhite, CMonochrome;
FROM Storage IMPORT
  ALLOCATE, DEALLOCATE, HeapAvail, MainHeap, NearHeap;
FROM SYSTEM IMPORT
  Registers;
FROM Lib IMPORT
  Intr;

INLINE PROCEDURE LowMemory() : BOOLEAN;
BEGIN
(*%F _fptr *)
  RETURN HeapAvail(NearHeap) < 08000H;
(*%E*)
(*%T _fptr *)
  RETURN HeapAvail(MainHeap) < 08000H;
(*%E*)
END LowMemory;

VAR
  Pending : TEvent;
(*#save, data(volatile=>on)*)
  Counter[40H:6CH] : LONGCARD;
(*#restore*)
  SavedCounter : LONGCARD;




  CLASS IMPLEMENTATION TBackground;

    PROCEDURE Init( VAR Bounds   : TRect;
                        APattern : CHAR);
    BEGIN
      TView.Init( Bounds );
      Pattern := APattern;
      GrowMode := TViewGrowModes{ gfGrowHiX, gfGrowHiY };
    END Init;

    PROCEDURE Load(VAR S: TStream);
    BEGIN
      TView.Load(S);
      S.Rd(Pattern);
    END Load;

    VIRTUAL PROCEDURE Draw;
    VAR
      B: TDrawBuffer;
    BEGIN
      MoveChar( B, 0, Pattern, GetColor(1), Size.X);
      WriteLine(0, 0, Size.X, Size.Y, B);
    END Draw;

    VIRTUAL PROCEDURE GetPalette(): PPalette;
    BEGIN
      RETURN ADR(CBackground);
    END GetPalette;

    PROCEDURE Store(VAR S: TStream);
    BEGIN
      TView.Store(S);
      S.Wr(Pattern);
    END Store;

  BEGIN
  END TBackground;

  PROCEDURE Tileable(P: PView): BOOLEAN;
  BEGIN
    WITH P^ DO
      RETURN (ofTileable IN Options) & (sfVisible IN State);
    END;
  END Tileable;

TYPE
  PDoCnt = POINTER TO TDoCnt;
  TDoCnt = RECORD
    CascadeNum : INTEGER;
    LastView : PView;
    R : TRect;
  END;

  PROCEDURE DoCount(a, param : ADDRESS);
  BEGIN
    IF Tileable(a) THEN
      WITH PDoCnt(param)^ DO
        INC(CascadeNum);
        LastView := a;
      END;
    END;
  END DoCount;

  PROCEDURE DoCascade(a, param : ADDRESS);
  VAR
    NR: TRect;
  BEGIN
    WITH PDoCnt(param)^ DO
      IF Tileable(a) AND (CascadeNum >= 0) THEN
        NR := R;
        INC(NR.A.X, CascadeNum);
        INC(NR.A.Y, CascadeNum);
        PView(a)^.Locate(NR);
        DEC(CascadeNum);
      END;
    END;
  END DoCascade;

PROCEDURE MostEqualDivisors(    N: INTEGER;
                            VAR X, Y: INTEGER);

  PROCEDURE ISqr(N:INTEGER):INTEGER;
  VAR
    a : INTEGER;
  BEGIN
    a := 0;
    REPEAT
      INC( a );
    UNTIL a*a > N;
    RETURN a-1;
  END ISqr;

VAR
  I: INTEGER;
BEGIN
  I := ISqr(N);
  IF N MOD I # 0 THEN
    IF N MOD (I+1) = 0 THEN
      INC(I);
    END;
  END;
  IF I < N DIV I THEN
    I := N DIV I;
  END;
  X := N DIV I;
  Y := I;
END MostEqualDivisors;

PROCEDURE DoCountTileable(a, param : ADDRESS);
BEGIN
  IF Tileable(a) THEN
    INC(param^);
  END;
END DoCountTileable;

TYPE
  PDoT = POINTER TO TDoT;
  TDoT = RECORD
    NumCols : INTEGER;
    LeftOver : INTEGER;
    NumRows : INTEGER;
    TileNum : INTEGER;
  END;

PROCEDURE DoTile(a, param : ADDRESS);
VAR
  R: TRect;

  PROCEDURE DividerLoc(Lo, Hi, Num, Pos: INTEGER): INTEGER;
  BEGIN
    RETURN  LongDiv(LongMul(Hi - Lo, Pos), Num) + Lo;
  END DividerLoc;

  PROCEDURE CalcTileRect(    Pos: INTEGER;
                         VAR NR: TRect);
  VAR
    X,Y,D: INTEGER;
  BEGIN
    WITH PDoT(param)^ DO
      D := (NumCols - LeftOver) * NumRows;
      IF Pos < D THEN
        X := Pos DIV NumRows;
        Y := Pos MOD NumRows;
      ELSE
        X := (Pos - D) DIV (NumRows + 1) + (NumCols - LeftOver);
        Y := (Pos - D) MOD (NumRows + 1);
      END;
      NR.A.X := DividerLoc(R.A.X, R.B.X, NumCols, X);
      NR.B.X := DividerLoc(R.A.X, R.B.X, NumCols, X+1);
      IF Pos >= D THEN
        NR.A.Y := DividerLoc(R.A.Y, R.B.Y, NumRows+1, Y);
        NR.B.Y := DividerLoc(R.A.Y, R.B.Y, NumRows+1, Y+1);
      ELSE
        NR.A.Y := DividerLoc(R.A.Y, R.B.Y, NumRows, Y);
        NR.B.Y := DividerLoc(R.A.Y, R.B.Y, NumRows, Y+1);
      END;
    END;
  END CalcTileRect;

BEGIN
  WITH PDoT(param)^ DO
    IF Tileable(a) THEN
      CalcTileRect(TileNum, R);
      PView(a)^.Locate(R);
      DEC(TileNum);
    END;
  END;
END DoTile;

  CLASS IMPLEMENTATION TDeskTop;

    PROCEDURE Init(VAR Bounds: TRect);
    BEGIN
      TGroup.Init( Bounds );
      GrowMode := TViewGrowModes{ gfGrowHiX, gfGrowHiY };
      InitBackground;
      IF Background <> NIL THEN
        Insert( Background );
      END;
    END Init;

    PROCEDURE Cascade(VAR R: TRect);
    VAR
      DC : TDoCnt;
      Min, Max   : TPoint;
    BEGIN
      DC.R := R;
      DC.CascadeNum := 0;
      ForEach(DoCount, ADR(DC));
      IF DC.CascadeNum > 0 THEN
        DC.LastView^.SizeLimits(Min, Max);
        IF (Min.X > R.B.X - R.A.X - DC.CascadeNum) OR
           (Min.Y > R.B.Y - R.A.Y - DC.CascadeNum) THEN
          TileError;
        ELSE
          DEC(DC.CascadeNum);
          Lock;
          ForEach(DoCascade, ADR(DC));
          Unlock;
        END;
      END;
    END Cascade;

    VIRTUAL PROCEDURE HandleEvent(VAR Event: TEvent);
    BEGIN
      TGroup.HandleEvent(Event);
      IF Event.What = EventTypes { evCommand } THEN
        CASE Event.Command OF
        | cmNext:
            SelectNext(FALSE);
        | cmPrev:
            Current^.PutInFrontOf(Background);
        ELSE
          RETURN;
        END;
        ClearEvent(Event);
      END;
    END HandleEvent;

    VIRTUAL PROCEDURE InitBackground;
    VAR
      R: TRect;
    BEGIN
      R := GetExtent();
      NEW(Background);
      Background^.Init(R, DefaultBkgrnd);
    END InitBackground;

    PROCEDURE Tile(VAR R: TRect);
    VAR
      NumTileable : INTEGER;
      DT : TDoT;
    BEGIN
      NumTileable := 0;
      ForEach(DoCountTileable, ADR(NumTileable));
      IF NumTileable > 0 THEN
        MostEqualDivisors(NumTileable, DT.NumCols, DT.NumRows);
        IF ((R.B.X - R.A.X) DIV DT.NumCols = 0) OR
           ((R.B.Y - R.A.Y) DIV DT.NumRows = 0)
        THEN
          TileError;
        ELSE
          DT.LeftOver := NumTileable MOD DT.NumCols;
          DT.TileNum := NumTileable-1;
          Lock;
          ForEach(DoTile, ADR(DT));
          Unlock;
        END;
      END;
    END Tile;

    VIRTUAL PROCEDURE TileError;
    END TileError;

  BEGIN
  END TDeskTop;

  PROCEDURE DoContainsMouse(a, param : ADDRESS): BOOLEAN;
  TYPE
    PEvent = POINTER TO TEvent;
  BEGIN
    WITH PView(a)^ DO
      RETURN (sfVisible IN State) & MouseInView(PEvent(param)^.Where);
    END;
  END DoContainsMouse;

  CLASS IMPLEMENTATION TProgram;

    PROCEDURE Init;
    VAR
      R: TRect;
    BEGIN
      Application := ADR(SELF);
      InitScreen;
      R.Assign(0, 0, ScreenWidth, ScreenHeight);
      TGroup.Init(R);
      State := TViewStates{ sfVisible, sfSelected, sfFocused, sfModal, sfExposed };
      Options := TViewOptions{};
      InitDeskTop;
      InitStatusLine;
      InitMenuBar;
      Buffer := [ScreenBuffer:0];
      IF Desktop <> NIL THEN
        Insert(Desktop);
      END;
      IF StatusLine <> NIL THEN
        Insert(StatusLine);
      END;
      IF MenuBar <> NIL THEN
        Insert(MenuBar);
      END;
    END Init;

    VIRTUAL PROCEDURE Done;
    BEGIN
      IF Desktop <> NIL THEN
        Desktop^.Done;
        DISPOSE(Desktop);
      END;
      IF MenuBar <> NIL THEN
        MenuBar^.Done;
        DISPOSE(MenuBar);
      END;
      IF StatusLine <> NIL THEN
        StatusLine^.Done;
        DISPOSE(StatusLine);
      END;
      Application := NIL;
    END Done;

    VIRTUAL PROCEDURE GetEvent(VAR Event: TEvent);
    VAR
      R : TRect;
      c : LONGCARD;
    BEGIN
      IF Pending.What <> evNothing THEN
        Event := Pending;
        Pending.What := evNothing;
      ELSE
        GetMouseEvent(Event);
        IF Event.What = evNothing THEN
          GetKeyEvent(Event);
          IF Event.What = evNothing THEN
(*%F SimulatedTimer *)
            GetTimeEvent(Event);
            IF Event.What = evNothing THEN
              Idle;
            END;
(*%E*)
(*%T SimulatedTimer *)
            c := Counter;
            IF SavedCounter = c THEN
              Idle;
            ELSE
              Event.What := EventTypes{evTimer(*,evBroadcast*)};
(*#save, check(overflow=>off)*)
              Event.TicksPending := ORD( c-SavedCounter );
(*#restore*)
            END;
            SavedCounter := c;
(*%E*)
(*%T Debug*)
          ELSE
            Event := Event;
(*%E*)
          END;
(*%T Debug*)
        ELSE
          IF evMouseDown IN Event.What THEN
            Event := Event;
          END;
(*%E*)
        END;
      END;
      IF StatusLine <> NIL THEN
        IF (evKeyDown IN Event.What) OR
           (evMouseDown IN Event.What ) AND
           (FirstThat(DoContainsMouse, ADR(Event)) = PView(StatusLine))
        THEN
          StatusLine^.HandleEvent(Event);
        END;
      END;
    END GetEvent;

    VIRTUAL PROCEDURE GetPalette(): PPalette;
    BEGIN
      CASE AppPalette OF
      | 0 : RETURN ADR(CColor);
      | 1 : RETURN ADR(CBlackWhite);
      | 2 : RETURN ADR(CMonochrome);
      END;
    END GetPalette;

    VIRTUAL PROCEDURE HandleEvent(VAR Event: TEvent);
    VAR
      I: CARDINAL;
      C: CHAR;
    BEGIN
      IF evKeyDown IN Event.What THEN
        C := GetAltChar(Event.KeyCode);
        IF (C >= '1') & (C <= '9') THEN
          IF Message( Desktop,
                      EventTypes { evBroadcast },
                      cmSelectWindowNum,
                      ADDRESS(VAL( LONGCARD, C) - 30H)) <> NIL
          THEN
            ClearEvent(Event);
          END;
        END;
      END;
      TGroup.HandleEvent(Event);
      IF evCommand IN Event.What THEN
        IF Event.Command = cmQuit THEN
          EndModal(cmQuit);
          ClearEvent(Event);
        END;
      END;
    END HandleEvent;

    VIRTUAL PROCEDURE Idle;
    VAR
      r : Registers;
    BEGIN
      IF StatusLine <> NIL THEN
        StatusLine^.Update;
      END;
      IF CommandSetChanged THEN
        Message( ADR(SELF),
                 EventTypes { evBroadcast },
                 cmCommandSetChanged,
                 NIL);
        CommandSetChanged := FALSE;
      ELSE
        Intr( r, 28H ); (* idle iterrupt *)
      END;
    END Idle;

    VIRTUAL PROCEDURE InitDeskTop;
    VAR
      R: TRect;
    BEGIN
      R := GetExtent();
      INC(R.A.Y);
      DEC(R.B.Y);
      NEW(Desktop);
      Desktop^.Init(R);
    END InitDeskTop;

    VIRTUAL PROCEDURE InitMenuBar;
    VAR
      R: TRect;
    BEGIN
      R := GetExtent();
      R.B.Y := R.A.Y + 1;
      NEW(MenuBar);
      MenuBar^.Init(R, NIL);
    END InitMenuBar;

    VIRTUAL PROCEDURE InitScreen;
    BEGIN
      IF ScreenMode MOD 100H <> smMono THEN
(*#save, option(bit_opr=>on)*)
        IF ScreenMode AND smFont8x8 <> 0 THEN
(*#restore*)
          ShadowSize.X := 1
        ELSE
          ShadowSize.X := 2;
        END;
        ShadowSize.Y := 1;
        ShowMarkers := FALSE;
        IF ScreenMode MOD 100H = smBW80 THEN
          AppPalette := apBlackWhite
        ELSE
          AppPalette := apColor;
        END;
      ELSE
        ShadowSize.X := 0;
        ShadowSize.Y := 0;
        ShowMarkers := TRUE;
        AppPalette := apMonochrome;
      END;
    END InitScreen;

    VIRTUAL PROCEDURE InitStatusLine;
    VAR
      R: TRect;
    BEGIN
      R := GetExtent();
      R.A.Y := R.B.Y - 1;
      NEW(StatusLine);
      StatusLine^.Init(R,
                       NewStatusDef(0, 0FFFFH,
                         NewStatusKey('~Alt-X~ Exit', kbAltX, cmQuit,
                         NewStatusKey('', kbF10, cmMenu,
                         NewStatusKey('', kbAltF3, cmClose,
                         NewStatusKey('', kbF5, cmZoom,
                         NewStatusKey('', kbCtrlF5, cmResize,
                         NewStatusKey('', kbF6, cmNext,
                         NIL)))))),
                       NIL));
    END InitStatusLine;

    VIRTUAL PROCEDURE OutOfMemory;
    END OutOfMemory;

    VIRTUAL PROCEDURE PutEvent(VAR Event: TEvent);
    BEGIN
      Pending := Event;
    END PutEvent;

    VIRTUAL PROCEDURE Run;
    VAR
      Dummy : CARDINAL;
    BEGIN
      Dummy := Execute();
    END Run;

    PROCEDURE SetScreenMode(Mode: CARDINAL);
    VAR
      R: TRect;
    BEGIN
      HideMouse;
      InitEvents;
      InitSysError;
      SetVideoMode(Mode);
(*      DoneMemory; *)
      InitScreen;
      Buffer := [ScreenBuffer:0];
      R.Assign(0, 0, ScreenWidth, ScreenHeight);
      ChangeBounds(R);
      Redraw;
(*      ShowMouse;  bo SetVideoMode wlacza mysz *)
    END SetScreenMode;

    PROCEDURE ValidView(P: PView): PView;
    BEGIN
      IF P <> NIL THEN
        IF LowMemory() THEN
          P^.Done;
          DISPOSE(P);
          OutOfMemory;
          RETURN NIL;
        END;
        IF NOT P^.Valid(cmValid) THEN
          P^.Done;
          DISPOSE(P);
          RETURN NIL;
        END;
        RETURN( P );
      ELSE
        RETURN NIL;
      END;
    END ValidView;

  BEGIN
    StatusLine  := NIL;
    MenuBar     := NIL;
    AppPalette  := apColor;
  END TProgram;

  CLASS IMPLEMENTATION TApplication;

    PROCEDURE Init;
    BEGIN
(*      InitMemory; *)
      InitEvents;
      InitVideo;
      InitSysError;
      InitHistory;
      TProgram.Init;
    END Init;

    VIRTUAL PROCEDURE Done;
    BEGIN
      TProgram.Done;
      DoneHistory;
      DoneSysError;
      DoneEvents;
      DoneVideo;
(*      DoneMemory;*)
    END Done;

  BEGIN
(*    Init;*)
  END TApplication;

  PROCEDURE RegisterApp;
  END RegisterApp;

BEGIN
  Pending.What := evNothing;
  Application := NIL;
  Desktop := NIL;
END App.
