(*%T TV_NoDebug*)
(*# debug(vid=>off)*)
(*%E*)
(*%T InOneSegment *)
(*#call(seg_name=>TV)*)
(*%E*)
IMPLEMENTATION MODULE Views;

FROM Lib IMPORT
  Fill, WordFill, FastMove, Move, WordMove, IncAddr, Intr, FarWordMove,
  FatalError;
FROM SYSTEM IMPORT
  GetFlags, SetFlags, DI, Registers;
FROM Str IMPORT
  Length, Copy;
FROM Storage IMPORT
  ALLOCATE, DEALLOCATE;
FROM Objects IMPORT
  TRect, TPoint, TObject, PString, String, Min;
FROM Drivers IMPORT
  EventType, EventTypes, evNothing, KeyboardState, SpecialKeys, kbLeft,
  kbRight, kbUp, kbDown, kbHome, kbEnd, kbPgUp, kbPgDn, kbCtrlLeft,
  kbCtrlRight, kbEsc, kbEnter, TDrawBuffer, MoveChar, HideMouse, ShowMouse,
  MoveStr, PutAttribute, CursorLines, evMouse, evKeyboard, evMessage,
  ScreenBuffer, PDrawBuffer, BiosKeyboardState;
FROM Commands IMPORT
  hcNoContext, hcDragging, cmCancel, cmReceivedFocus, cmReleasedFocus,
  cmZoom, cmNext, cmPrev, cmClose, cmResize;
FROM Collections IMPORT
  BoolProcAddr, ProcAddr;
FROM Texts IMPORT
  ErrorInData;

INLINE PROCEDURE Range( val, min, max : INTEGER ) : INTEGER;
BEGIN
  IF val < min THEN
    RETURN min;
  ELSIF val > max THEN
    RETURN max;
  ELSE
    RETURN val;
  END;
END Range;

  PROCEDURE HighestView( p : PView ) : PView;
  BEGIN
    LOOP
      IF p^.Owner = NIL THEN
        RETURN p;
      END;
      p := p^.Owner;
    END;
  END HighestView;

  CLASS IMPLEMENTATION TView;

    PROCEDURE Init(VAR Bounds: Objects.TRect);
    BEGIN
      SetBounds(Bounds);
    END Init;

    PROCEDURE Load(VAR S: Streams.TStream);
    BEGIN
      S.Rd(Origin);
      S.Rd(Size);
      S.Rd(Cursor);
      S.Rd(GrowMode);
      S.Rd(DragMode);
      S.Rd(HelpCtx);
      S.Rd(State);
      S.Rd(Options);
      S.Rd(EventMask);
      Owner := NIL;
      Next := NIL;
    END Load;

    VIRTUAL PROCEDURE Done;
    BEGIN
      Hide();
      IF Owner # NIL THEN
        Owner^.Delete( ADR (SELF) );
      END;
      TObject.Done;
    END Done;

    PROCEDURE BlockCursor;
    BEGIN
      SetState(TViewStates{ sfCursorIns }, TRUE);
    END BlockCursor;

    VIRTUAL PROCEDURE CalcBounds(VAR Bounds : Objects.TRect;
                                     Delta  : Objects.TPoint);
    VAR
      s, d : INTEGER;
      MinLim, MaxLim : TPoint;

      INLINE PROCEDURE Grow(VAR i : INTEGER);
      BEGIN
        IF gfGrowRel IN GrowMode THEN
          i := (i * s + ((s - d) >> 1)) DIV (s - d);
        ELSE
          INC(i, d);
        END;
      END Grow;

    BEGIN
      Bounds := GetBounds();
      s := Owner^.Size.X;
      d := Delta.X;

      IF gfGrowLoX IN GrowMode THEN
        Grow(Bounds.A.X);
      END;
      IF gfGrowHiX IN GrowMode THEN
        Grow(Bounds.B.X);
      END;
      s := Owner^.Size.Y;
      d := Delta.Y;
      IF gfGrowLoY IN GrowMode THEN
        Grow(Bounds.A.Y);
      END;
      IF gfGrowHiY IN GrowMode THEN
        Grow(Bounds.B.Y);
      END;
      SizeLimits( MinLim, MaxLim );
      Bounds.B.X := Bounds.A.X + Range( Bounds.B.X-Bounds.A.X, MinLim.X, MaxLim.X );
      Bounds.B.Y := Bounds.A.Y + Range( Bounds.B.Y-Bounds.A.Y, MinLim.Y, MaxLim.Y );
    END CalcBounds;

    VIRTUAL PROCEDURE ChangeBounds(VAR Bounds: Objects.TRect);
    BEGIN
      SetBounds(Bounds);
      DrawView();
    END ChangeBounds;

    PROCEDURE ClearEvent(VAR Event: Drivers.TEvent);
    BEGIN
      Event.What := evNothing;
      Event.InfoPtr := ADR(SELF);
    END ClearEvent;

    VIRTUAL PROCEDURE DataSize(): CARDINAL;
    BEGIN
      RETURN 0;
    END DataSize;

    PROCEDURE DragView(    Event   : Drivers.TEvent;
                           Mode    : TViewDragModes;
                       VAR Limits  : Objects.TRect;
                           MinSize,
                           MaxSize : Objects.TPoint);

      PROCEDURE MoveGrow(    p, s    : TPoint;
                         VAR Limits  : TRect;
                             MinSize,
                             MaxSize : TPoint;
                             Mode    : TViewDragModes);
      VAR
        r : TRect;
      BEGIN
        s.X := Objects.Min(Objects.Max(s.X, MinSize.X), MaxSize.X);
        s.Y := Objects.Min(Objects.Max(s.Y, MinSize.Y), MaxSize.Y);
        p.X := Objects.Min(Objects.Max(p.X, Limits.A.X - s.X+1), Limits.B.X-1);
        p.Y := Objects.Min(Objects.Max(p.Y, Limits.A.Y - s.Y+1), Limits.B.Y-1);
        IF dmLimitLoX IN Mode THEN
          p.X := Objects.Max(p.X, Limits.A.X);
        END;
        IF dmLimitLoY IN Mode THEN
          p.Y := Objects.Max(p.Y, Limits.A.Y);
        END;
        IF dmLimitHiX IN Mode THEN
          p.X := Objects.Min(p.X, Limits.B.X-s.X);
        END;
        IF dmLimitHiY IN Mode THEN
          p.Y := Objects.Min(p.Y, Limits.B.Y-s.Y);
        END;
        r.Assign(p.X, p.Y, p.X+s.X, p.Y+s.Y);
        Locate(r);
      END MoveGrow;

      PROCEDURE Change(    Mode  : TViewDragModes;
                           Delta : TPoint;
                       VAR p, s  : TPoint);
      BEGIN
        IF (dmDragMove IN Mode) &
           (BiosKeyboardState * KeyboardState { kbRightShift, kbLeftShift } = KeyboardState {} )
        THEN
          INC(p.X, Delta.X);
          INC(p.Y, Delta.Y);
        ELSIF ( dmDragGrow IN Mode) &
           (BiosKeyboardState * KeyboardState { kbRightShift, kbLeftShift } # KeyboardState {} )
        THEN
          INC(s.X, Delta.X);
          INC(s.Y, Delta.Y);
        END;
      END Change;

    CONST
      goLeft      =   TPoint(-1, 0);
      goRight     =   TPoint( 1, 0);
      goUp        =   TPoint( 0,-1);
      goDown      =   TPoint( 0, 1);
      goCtrlLeft  =   TPoint(-8, 0);
      goCtrlRight =   TPoint( 8, 0);
    VAR
      SaveBounds : TRect;
      p, s       : TPoint;
    BEGIN
      SetState( TViewStates{ sfDragging }, TRUE );
      IF evMouseDown IN Event.What THEN
        IF dmDragMove IN Mode THEN
           p.X := Origin.X - Event.Where.X;
           p.Y := Origin.Y - Event.Where.Y;
           REPEAT
             INC(Event.Where.X, p.X);
             INC(Event.Where.Y, p.Y);
             MoveGrow( Event.Where,
                       Size,
                       Limits,
                       MinSize,
                       MaxSize,
                       Mode);
           UNTIL NOT MouseEvent(Event, EventTypes{evMouseMove}) ;
        ELSE
           p.X := Size.X - Event.Where.X;
           p.Y := Size.Y - Event.Where.Y;
           REPEAT
             INC(Event.Where.X, p.X);
             INC(Event.Where.Y, p.Y);
             MoveGrow( Origin,
                       Event.Where,
                       Limits,
                       MinSize,
                       MaxSize,
                       Mode);
           UNTIL NOT MouseEvent( Event, EventTypes{evMouseMove});
        END;
      ELSE
        SaveBounds := GetBounds();
        REPEAT
          p := Origin;
          s := Size;
          KeyEvent(Event);
          CASE ORD(Event.ScanCode)*256 OF
          | kbLeft:      Change(Mode,goLeft,p,s);
          | kbRight:     Change(Mode,goRight,p,s);
          | kbUp:        Change(Mode,goUp,p,s);
          | kbDown:      Change(Mode,goDown,p,s);
          | kbCtrlLeft:  Change(Mode,goCtrlLeft,p,s);
          | kbCtrlRight: Change(Mode,goCtrlRight,p,s);
          | kbHome:      p.X := Limits.A.X;
          | kbEnd:       p.X := Limits.B.X - s.X;
          | kbPgUp:      p.Y := Limits.A.Y;
          | kbPgDn:      p.Y := Limits.B.Y - s.Y;
          END;
          MoveGrow( p, s, Limits, MinSize, MaxSize, Mode );
        UNTIL (Event.KeyCode = kbEsc) OR (Event.KeyCode = kbEnter);
        IF Event.KeyCode = kbEsc THEN
          Locate(SaveBounds);
        END;
      END;
      SetState( TViewStates{ sfDragging }, FALSE);
    END DragView;

    VIRTUAL PROCEDURE Draw;
    VAR
      b : TDrawBuffer;
    BEGIN
      MoveChar( b, 0, ' ', GetColor(1), Size.X );
      WriteLine( 0, 0, Size.X, Size.Y, b );
    END Draw;

    PROCEDURE DrawShow( LastView : PView );
    BEGIN
      DrawView;
      IF sfShadow IN State THEN
        DrawUnderView( TRUE, LastView );
      END;
    END DrawShow;

    PROCEDURE DrawView;
    BEGIN
      IF Exposed() THEN
        Draw;
        DrawCursor;
      END;
    END DrawView;

    VIRTUAL PROCEDURE EndModal(Command: CARDINAL);
    BEGIN
      IF TopView() # NIL THEN
        TopView()^.EndModal(Command);
      END;
    END EndModal;

    PROCEDURE EventAvail(): BOOLEAN;
    VAR
      Event : Drivers.TEvent;
    BEGIN
      GetEvent(Event);
      IF Event.What # evNothing THEN
        PutEvent(Event);
      END;
      RETURN Event.What # evNothing ;
    END EventAvail;

    VIRTUAL PROCEDURE Execute(): CARDINAL;
    BEGIN
      RETURN cmCancel;
    END Execute;

    PROCEDURE Exposed(): BOOLEAN;
    VAR
      Row : INTEGER;

      PROCEDURE RowExposed(p : PView; left, right : INTEGER):BOOLEAN;
      VAR
        y      : INTEGER;
        Target : PView;
      BEGIN
        Target := p;
        WITH p^ DO
          y := Row+Origin.Y;
          INC( left, Origin.X );
          INC( right, Origin.X );
          IF Owner = NIL THEN
            RETURN TRUE;
          END;
          WITH Owner^ DO
            IF ( y < Clip.A.Y ) OR ( y >= Clip.B.Y ) THEN
              RETURN FALSE;
            END;
            IF left < Clip.A.X THEN
              left := Clip.A.X;
            END;
            IF right > Clip.B.X THEN
              right := Clip.B.X;
            END;
            IF left >= right THEN
              RETURN FALSE;
            END;
            p := Last;
          END;
        END;
        LOOP
          p := p^.Next;
          WITH p^ DO
            IF p = Target THEN
              IF Owner^.Buffer = FarNIL THEN
                RETURN TRUE;
              ELSE
                RETURN RowExposed( Owner, left, right );
              END;
            ELSE
              IF ( sfVisible IN State ) & ( y >= Origin.Y ) & ( y < Origin.Y+Size.Y ) THEN
                IF left < Origin.X THEN (*22*)
                  IF right > Origin.X THEN
                    IF right > Origin.X+Size.X THEN
                      IF RowExposed(p, left, right ) THEN
                        RETURN TRUE;
                      ELSE
                        right := Origin.X+Size.X;
                      END;
                    ELSE
                      right := Origin.X;
                    END;
                  END;
                ELSIF left < Origin.X+Size.X THEN
                  left := Origin.X+Size.X;
                  IF left >= right THEN
                    RETURN FALSE;
                  END;
                END;
              END;
            END;
          END;
        END;
      END RowExposed;

    BEGIN
      IF NOT ( sfExposed IN State ) OR ( Size.X <= 0 ) OR (Size.Y <= 0 ) THEN
        RETURN FALSE;
      END;
      FOR Row := 0 TO Size.Y-1 DO
        IF RowExposed( ADR(SELF), 0, Size.X ) THEN
          RETURN TRUE;
        END;
      END;
      RETURN FALSE;
    END Exposed;

    PROCEDURE GetBounds(): Objects.TRect;
    VAR
      Bounds: Objects.TRect;
    BEGIN
      Bounds.Assign(Origin.X, Origin.Y, Origin.X+Size.X, Origin.Y+Size.Y);
      RETURN Bounds;
    END GetBounds;

    PROCEDURE GetClipRect() : Objects.TRect;
    VAR
      clip : TRect;
    BEGIN
      clip := GetBounds();
      IF Owner # NIL THEN
        clip.Intersect(Owner^.Clip);
      END;
      clip.Move(-Origin.X, -Origin.Y);
      RETURN clip;
    END GetClipRect;

    PROCEDURE GetColor(Color: CARDINAL): CARDINAL;
    VAR
      ColorPair : CARDINAL;
    BEGIN
      ColorPair := Color >> 8;
      IF ColorPair # 0  THEN
        ColorPair := MapColor(ColorPair) << 8;
      END;
(*#save, option(bit_opr=>on)*)
      ColorPair := ColorPair OR MapColor( Color MOD 100H );
(*#restore*)
      RETURN ColorPair;
    END GetColor;

    PROCEDURE GetCommands(VAR Commands: TCommandSet);
    BEGIN
      Commands := CurCommandSet;
    END GetCommands;

    VIRTUAL PROCEDURE GetData(VAR Rec : ARRAY OF BYTE);
    END GetData;

    VIRTUAL PROCEDURE GetEvent(VAR Event: Drivers.TEvent);
    BEGIN
      IF Owner # NIL THEN
        Owner^.GetEvent(Event);
      END;
    END GetEvent;

    PROCEDURE GetExtent(): Objects.TRect;
    VAR
      Extent: Objects.TRect;
    BEGIN
      Extent.Assign(0, 0, Size.X, Size.Y);
      RETURN Extent;
    END GetExtent;

    VIRTUAL PROCEDURE GetHelpCtx(): CARDINAL;
    BEGIN
      IF sfDragging IN State THEN
        RETURN hcDragging;
      ELSE
        RETURN HelpCtx;
      END;
    END GetHelpCtx;

    VIRTUAL PROCEDURE GetPalette(): PPalette;
    BEGIN
      RETURN NIL;
    END GetPalette;

    PROCEDURE GetPeerViewPtr(VAR S: Streams.TStream; VAR P : ADDRESS);
    END GetPeerViewPtr;

    PROCEDURE GetState(AState: TViewStates): BOOLEAN;
    BEGIN
      RETURN AState <= State;
    END GetState;

    PROCEDURE GrowTo(X, Y: INTEGER);
    VAR
      r : TRect;
    BEGIN
      r.Assign (Origin.X, Origin.Y, Origin.X + X, Origin.Y + Y);
      Locate(r);
    END GrowTo;

    VIRTUAL PROCEDURE HandleEvent(VAR Event: Drivers.TEvent);
    BEGIN
      IF evMouseDown IN Event.What THEN
        IF (TViewStates{sfSelected, sfDisabled} * State = TViewStates{} ) &
           (ofSelectable IN Options)
        THEN
          Select();
          IF NOT (ofFirstClick IN Options) THEN
            ClearEvent(Event);
          END;
        END;
      END;
    END HandleEvent;

    PROCEDURE Hide;
    BEGIN
      IF sfVisible IN State THEN
        SetState( TViewStates{ sfVisible }, FALSE );
      END;
    END Hide;

    PROCEDURE HideCursor;
    BEGIN
      SetState( TViewStates{ sfCursorVis }, FALSE );
    END HideCursor;

    PROCEDURE KeyEvent(VAR Event: Drivers.TEvent);
    BEGIN
      REPEAT
        GetEvent(Event);
        IF evTimer IN Event.What THEN
          Message( HighestView( ADR( SELF)), Event.What, Event.TicksPending, ADR( SELF ));
        END;
      UNTIL evKeyDown IN Event.What;
    END KeyEvent;

    PROCEDURE DrawUnderRect( VAR r        : TRect;
                                 LastView : PView );
    BEGIN
      WITH Owner^ DO
        Clip.Intersect(r);
        DrawSubViews(SELF.NextView(), LastView);
        Clip := GetExtent();
      END;
    END DrawUnderRect;

    PROCEDURE Locate(VAR Bounds: Objects.TRect);
    VAR
      min, max : TPoint;
      r        : TRect;

    BEGIN
      SizeLimits(min, max);
      Bounds.B.X := Bounds.A.X + Range(Bounds.B.X - Bounds.A.X, min.X, max.X);
      Bounds.B.Y := Bounds.A.Y + Range(Bounds.B.Y - Bounds.A.Y, min.Y, max.Y);
      r := GetBounds();
      IF Bounds # r THEN
        ChangeBounds( Bounds );
        IF (Owner # NIL) & (sfVisible IN State) THEN
          IF sfShadow IN State THEN
            r.Union(Bounds);
            INC(r.B.X, ShadowSize.X);
            INC(r.B.Y, ShadowSize.Y);
          END;
          DrawUnderRect( r, NIL );
        END;
      END;
    END Locate;

    PROCEDURE MakeFirst;
    BEGIN
      PutInFrontOf(Owner^.First());
    END MakeFirst;

    PROCEDURE MakeGlobal( Source : Objects.TPoint) : Objects.TPoint;
    VAR
      temp : TPoint;
      cur  : PView;
    BEGIN
      temp.Y := Source.Y + Origin.Y;
      temp.X := Source.X + Origin.X;
      cur := ADR(SELF);
      WHILE cur^.Owner # NIL DO
        cur := cur^.Owner;
        INC(temp.Y, cur^.Origin.Y);
        INC(temp.X, cur^.Origin.X);
      END;
      RETURN temp;
    END MakeGlobal;

    PROCEDURE MakeLocal( Source : Objects.TPoint) : Objects.TPoint;
    VAR
      temp : TPoint;
      cur  : PView;
    BEGIN
      temp.Y := Source.Y - Origin.Y;
      temp.X := Source.X - Origin.X;
      cur := ADR(SELF);
      WHILE cur^.Owner # NIL DO
        cur := cur^.Owner;
        DEC(temp.Y, cur^.Origin.Y);
        DEC(temp.X, cur^.Origin.X);
      END;
      RETURN temp;
    END MakeLocal;

    PROCEDURE MouseEvent(VAR Event : Drivers.TEvent;
                             Mask  : Drivers.EventTypes): BOOLEAN;
    BEGIN
      REPEAT
        GetEvent(Event);
        IF evTimer IN Event.What THEN
          Message( HighestView( ADR( SELF )), Event.What, Event.TicksPending, ADR( SELF ));
        END;
      UNTIL (Mask + Drivers.EventTypes{ evMouseUp }) * Event.What # Drivers.EventTypes{};
      RETURN NOT ( evMouseUp IN Event.What);
    END MouseEvent;

    PROCEDURE MouseInView(Mouse: Objects.TPoint): BOOLEAN;
    VAR
      r : TRect;
    BEGIN
      Mouse := MakeLocal( Mouse );
      r := GetExtent();
      RETURN r.Contains(Mouse);
    END MouseInView;

    PROCEDURE MoveTo(X, Y: INTEGER);
    VAR
      r : TRect;
    BEGIN
      r.Assign( X, Y, X+Size.X, Y+Size.Y);
      Locate( r );
    END MoveTo;

    PROCEDURE NextView(): PView;
    BEGIN
      IF ADR(SELF) = Owner^.Last THEN
        RETURN NIL;
      ELSE
        RETURN Next;
      END;
    END NextView;

    PROCEDURE NormalCursor;
    BEGIN
      SetState( TViewStates{ sfCursorIns }, FALSE);
    END NormalCursor;

    PROCEDURE Prev(): PView;
    VAR
      res : PView;
    BEGIN
      res := ADR(SELF);
      WHILE res^.Next # ADR(SELF) DO
        res := res^.Next;
      END;
      RETURN res;
    END Prev;

    PROCEDURE PrevView(): PView;
    BEGIN
      IF ADR(SELF) = Owner^.First() THEN
        RETURN NIL;
      ELSE
        RETURN Prev();
      END;
    END PrevView;

    VIRTUAL PROCEDURE PutEvent(VAR Event: Drivers.TEvent);
    BEGIN
      IF Owner # NIL THEN
        Owner^.PutEvent(Event);
      END;
    END PutEvent;

    PROCEDURE DrawCursor;
    BEGIN
      IF sfFocused IN State THEN
        ResetCursor;
      END;
    END DrawCursor;

    PROCEDURE DrawUnderView( doShadow : BOOLEAN;
                             LastView : PView);
    VAR
      r : TRect;
    BEGIN
      r := GetBounds();
      IF doShadow THEN
        INC(r.B.Y, ShadowSize.Y);
        INC(r.B.X, ShadowSize.X);
      END;
      DrawUnderRect( r, LastView );
    END DrawUnderView;

    PROCEDURE DrawHide( LastView : PView );
    BEGIN
      DrawCursor;
      DrawUnderView( sfShadow IN State, LastView);
    END DrawHide;

    PROCEDURE PutInFrontOf(Target: PView);
    VAR
      p, LastView : PView;

    BEGIN
      IF (Owner # NIL) & (Target # ADR(SELF)) & (Target # NextView()) &
         ((Target = NIL) OR (Target^.Owner = Owner))
      THEN
        IF NOT (sfVisible IN State) THEN
          Owner^.DeleteView(ADR(SELF));
          Owner^.InsertView(ADR(SELF), Target);
        ELSE
          LastView := NextView();
          p := Target;
          WHILE ( p # NIL ) & (p # ADR(SELF) ) DO
            p := p^.NextView();
          END;
          IF p = NIL THEN
            LastView := Target;
          END;
          EXCL( State, sfVisible);
          IF LastView = Target THEN
            DrawHide(LastView);
          END;
          Owner^.DeleteView(ADR(SELF));
          Owner^.InsertView(ADR(SELF), Target);
          INCL(State, sfVisible);
          IF LastView # Target THEN
            DrawShow(LastView);
          END;
          IF ofSelectable IN Options THEN
            Owner^.ResetCurrent();
          END;
        END;
      END;
    END PutInFrontOf;

    PROCEDURE PutPeerViewPtr(VAR S: Streams.TStream; P: PView);
    END PutPeerViewPtr;

    PROCEDURE Select;
    BEGIN
      IF ofTopSelect IN Options THEN
        MakeFirst();
      ELSIF Owner # NIL THEN
        Owner^.SetCurrent( ADR(SELF), NormalSelect );
      END;
    END Select;

    PROCEDURE SetBounds(VAR Bounds: Objects.TRect);
    BEGIN
      Origin := Bounds.A;
      Size.X := Bounds.B.X - Bounds.A.X;
      Size.Y := Bounds.B.Y - Bounds.A.Y;
    END SetBounds;

    PROCEDURE SetCommands(Commands: TCommandSet);
    BEGIN
      CommandSetChanged := CommandSetChanged OR (CurCommandSet # Commands );
      CurCommandSet := Commands;
    END SetCommands;

    PROCEDURE SetCursor(X, Y: INTEGER);
    BEGIN
      Cursor.X := X;
      Cursor.Y := Y;
      DrawCursor();
    END SetCursor;

    VIRTUAL PROCEDURE SetData(VAR Rec : ARRAY OF BYTE);
    END SetData;

    VIRTUAL PROCEDURE SetState( AState: TViewStates;
                                Enable: BOOLEAN);
    VAR
      cmd : CARDINAL;
      Dummy : ADDRESS;
    BEGIN
      IF Enable THEN
        State := State + AState;
      ELSE
        State := State - AState;
      END;
      IF Owner = NIL THEN
        RETURN;
      END;
      IF sfVisible IN AState THEN
        IF sfExposed IN Owner^.State THEN
          SetState( TViewStates{ sfExposed }, Enable );
        END;
        IF Enable THEN
          DrawShow( NIL );
        ELSE
          DrawHide( NIL );
        END;
        IF ofSelectable IN Options THEN
          Owner^.ResetCurrent();
        END;
      ELSIF ( sfCursorVis IN AState ) OR ( sfCursorIns IN AState ) THEN
        DrawCursor();
      ELSIF sfShadow IN AState THEN
        DrawUnderView( TRUE, NIL );
      ELSIF sfFocused IN AState THEN
        ResetCursor;
        IF Enable THEN
          cmd := cmReceivedFocus;
        ELSE
          cmd := cmReleasedFocus;
        END;
        Dummy := Message( Owner, EventTypes { evBroadcast }, cmd, ADR(SELF));
(*Dummy := Message( PView(ADR( SELF)), EventTypes{evCommand}, cmd, ADR(SELF));*)
      END;
    END SetState;

    PROCEDURE Show;
    BEGIN
      IF NOT (sfVisible IN State) THEN
        SetState( TViewStates{ sfVisible }, TRUE);
      END;
    END Show;

    PROCEDURE ShowCursor;
    BEGIN
      SetState( TViewStates{ sfCursorVis }, TRUE );
    END ShowCursor;

    VIRTUAL PROCEDURE SizeLimits(VAR Min, Max: Objects.TPoint);
    BEGIN
      Min.X := 0;
      Min.Y := 0;
      IF Owner # NIL THEN
        Max := Owner^.Size;
      ELSE
        Max.X := MAX(INTEGER);
        Max.Y := MAX(INTEGER);
      END;
    END SizeLimits;

    PROCEDURE Store(VAR S: Streams.TStream);
    VAR
      SaveState : TViewStates;
    BEGIN
      SaveState := State - TViewStates{ sfActive, sfSelected, sfFocused, sfExposed};
      S.Wr(Origin);
      S.Wr(Size);
      S.Wr(Cursor);
      S.Wr(GrowMode);
      S.Wr(DragMode);
      S.Wr(HelpCtx);
      S.Wr(SaveState);
      S.Wr(Options);
      S.Wr(EventMask);
    END Store;

    PROCEDURE TopView(): PView;
    VAR
      p : PView;
    BEGIN
      IF TheTopView # NIL THEN
        RETURN TheTopView;
      ELSE
        p := ADR(SELF);
        WHILE ( p # NIL) & NOT (sfModal IN p^.State) DO
          p := p^.Owner;
        END;
        RETURN p;
      END;
    END TopView;

    VIRTUAL PROCEDURE Valid(Command: CARDINAL): BOOLEAN;
    BEGIN
      RETURN TRUE;
    END Valid;

    PROCEDURE ContainsMouse(VAR Event:Drivers.TEvent) : BOOLEAN;
    BEGIN
      RETURN (sfVisible IN State) & MouseInView(Event.Where);
    END ContainsMouse;

    PROCEDURE MapColor( Color : CARDINAL ) : CARDINAL;
    VAR
      cur : PView;
      p   : PPalette;
    BEGIN
      IF Color = 0 THEN
        RETURN ORD(ErrorAttr);
      END;
      cur := ADR(SELF);
      REPEAT
        p := cur^.GetPalette();
        IF (p # NIL) & (p^[0] # 0C) THEN
          IF Color > ORD(p^[0]) THEN
            RETURN ORD(ErrorAttr);
          END;
          Color := ORD(p^[Color]);
          IF Color = 0 THEN
            RETURN ORD(ErrorAttr);
          END;
        END;
        cur := cur^.Owner;
      UNTIL cur = NIL;
      RETURN Color;
    END MapColor;

    PROCEDURE WriteBuf( X, Y, W, H: INTEGER; Buff : PVideoBuf);
    VAR
      ix, h : INTEGER;
      lb : TDrawBuffer;
    BEGIN
      ix := 0;
      FOR h := 0 TO H-1 DO
        FarWordMove(FarADR( Buff^[ix] ), FarADR(lb), W);
        WriteView(X, Y, W, ADR(lb));
        INC(ix, W );
        INC(Y);
      END;
    END WriteBuf;

    PROCEDURE WriteChar(X, Y : INTEGER;
                        C    : CHAR;
                        Color: SHORTCARD;
                        Count: INTEGER);
    VAR
      CH : CARDINAL;
      b  : TDrawBuffer;
    BEGIN
      CH := MapColor(ORD(Color)) << 8 + ORD(C);
      IF Count >= MaxViewWidth THEN
        Count := MaxViewWidth-1;
      END;
      WordFill(ADR(b), CH, Count);
      WriteView(X, Y, Count, ADR(b));
    END WriteChar;

    PROCEDURE WriteLine(     X, Y, W, H: INTEGER;
                         VAR Buf : TDrawBuffer);
    VAR
      h : INTEGER;
    BEGIN
      FOR h := 0 TO H-1 DO
        WriteView(X, Y, W, ADR(Buf));
        INC(Y);
      END;
    END WriteLine;

(*# save, call(o_a_copy=>off)*)
    PROCEDURE WriteStr( X, Y: INTEGER;
                        Str: ARRAY OF CHAR;
                        Color: SHORTCARD);
    VAR
      b : TDrawBuffer;
    BEGIN
      MoveStr( b, 0, Str, MapColor(ORD(Color)));
      WriteView(X, Y, Length(Str), ADR(b));
    END WriteStr;
(*# restore *)

    PROCEDURE WriteView( x, y, w : INTEGER;
                         bp      : PDrawBuffer);
    TYPE
      A7 = ARRAY[0..6] OF SHORTCARD;

(*#save, call(reg_param=>(ds,si,es,di,ax,cx),reg_saved=>(bx,dx,st1,st2))*)
       INLINE PROCEDURE BuffMove( Source, Dest : FarADDRESS;
                                  Attr : SHORTCARD;
                                  Count : CARDINAL)=A7( 088H, 0C4H, (*   move ah, al *)
                                                        0ACH,       (* l:lodsb       *)
                                                        046H,       (*   inc si      *)
                                                        0ABH,       (*   stosw       *)
                                                        0E2H, 0FBH  (*   loop l      *));
(*#restore*)

    VAR
      Ofset : INTEGER;

       PROCEDURE DrawViewToBuff(     ScrPtr : CARDINAL;
                                     bpix   : CARDINAL;
                                     Count  : CARDINAL;
                                     ShadowView : CARDINAL;
                                 VAR Buff   : PVideoBuf );
       BEGIN
         (* Snow check not implemented *)
         IF ShadowView = 0 THEN
           WordMove(ADR(bp^[bpix]), ADR(Buff^[ScrPtr]), Count );
         ELSE
           BuffMove(ADR(bp^[bpix]), ADR(Buff^[ScrPtr]), ShadowAttr, Count);
         END;
       END DrawViewToBuff;

    VAR
      end : INTEGER;

       PROCEDURE DrawSelectedView( Target : PView );

         PROCEDURE CheckView( x, y, end : INTEGER;
                              p : PView;
                              ShadowView : CARDINAL);
         VAR
           tmpX, tmpY : INTEGER;

           INLINE PROCEDURE ShadowSubView;
           BEGIN
             IF x < tmpX THEN
               INC( ShadowView );
               IF tmpX < end THEN
                 CheckView( x, y, tmpX, p, ShadowView );
                 x := tmpX;
                 DEC( ShadowView );
               END;
             END;
           END ShadowSubView;

         LABEL
           NextViewL;
         BEGIN
           LOOP
         NextViewL:
             p := p^.Next;
             WITH p^ DO
               IF p = Target THEN
                 WITH Owner^ DO
                   IF (Buffer # NIL) & ( x < end ) THEN
                     IF Seg(Buffer^)=ScreenBuffer THEN
                     (*
                        Mozna ewentualnie sprawdzic czy konieczne
                        chowanie myszy (  DI ! )
                     *)
                       HideMouse;
                       DrawViewToBuff( y*Size.X+x,
                                       x-Ofset,
                                       end-x,
                                       ShadowView,
                                       Buffer);
                       ShowMouse;
                     ELSE
                       DrawViewToBuff( y*Size.X+x,
                                       x-Ofset,
                                       end-x,
                                       ShadowView,
                                       Buffer);
                     END;
                   END;
                   RETURN;
                 END;
               ELSE
                 tmpY := Origin.Y;
                 IF ( sfVisible IN State ) & ( y >= tmpY ) THEN
                   INC( tmpY, Size.Y );
                   IF y < tmpY THEN
                     tmpX := Origin.X;
                     IF x < tmpX THEN
                       IF end <= tmpX THEN
                         GOTO NextViewL;
                       END;
                       CheckView(x, y, tmpX, p, ShadowView );
                       x := tmpX;
                     END;
                     INC( tmpX, Size.X );
                     IF x < tmpX THEN
                       IF end <= tmpX THEN
                         RETURN;
                       END;
                       x := tmpX;
                     END;
                     IF (sfShadow IN State) & ( y >= Origin.Y+ShadowSize.Y ) THEN
                       INC( tmpX, ShadowSize.X );
                       ShadowSubView;
                     END;
                   ELSIF (sfShadow IN State) & ( y < tmpY+ShadowSize.Y ) THEN
                     tmpX := Origin.X+ShadowSize.X;
                     IF x < tmpX THEN
                       IF end <= tmpX THEN
                         GOTO NextViewL;
                       END;
                       CheckView( x, y, tmpX, p, ShadowView );
                       x := tmpX;
                     END;
                     INC( tmpX, Size.X );
                     ShadowSubView;
                   END;
                 END;
               END;
             END;
           END;
         END CheckView;

       BEGIN
         LOOP
           WITH Target^ DO
             IF NOT ( sfVisible IN State ) THEN
               RETURN;
             END;
             IF Owner=NIL THEN
               RETURN;
             END;
             INC( y, Origin.Y );
             INC( x, Origin.X );
             INC( end, Origin.X );
             INC( Ofset, Origin.X );
             WITH Owner^ DO
               IF (y < Clip.A.Y) OR (y >= Clip.B.Y) THEN
                 RETURN;
               END;
               IF x < Clip.A.X THEN
                 x := Clip.A.X;
               END;
               IF end > Clip.B.X THEN
                 end := Clip.B.X;
               END;
               IF end <= x THEN
                 RETURN;
               END;
               CheckView( x, y, end, Last, 0 );
               IF LockFlag = 0 THEN
                 IF Buffer = NIL THEN
                   RETURN;
                 ELSE
                   bp := ADR( Buffer^[y*Size.X]);
                   Ofset := 0;
                   Target := Target^.Owner;
                 END;
               ELSE
                 RETURN;
               END;
             END;
           END;
         END;
       END DrawSelectedView;

    BEGIN
      Ofset := x;
      end := x+w;
      IF (y < 0) OR ( y>=Size.Y) THEN
        RETURN;
      END;
      IF x < 0 THEN
        x := 0;
      END;
      IF end > Size.X THEN
        end := Size.X;
      END;
      IF end <= x THEN
        RETURN;
      END;
      DrawSelectedView( ADR( SELF ));
    END WriteView;

    PROCEDURE ResetCursor;
    VAR
      r : Registers;

      PROCEDURE RemoveCursor;
      BEGIN
        r.CX := 2000H;
        r.AH := 1;
        Intr( r, 10H );
      END RemoveCursor;

      PROCEDURE CursorExposed( o : PGroup; v : PView; x, y : INTEGER ) : BOOLEAN;
      VAR
        p : PView;
      BEGIN
        IF sfVisible IN o^.State THEN
          p := o^.Last^.Next; (* tzn. First *)
          WHILE p # v DO
            WITH p^ DO
              IF ( x >= Origin.X ) & ( x < Origin.X+Size.X ) &
                 ( y >= Origin.Y ) & ( y < Origin.Y+Size.Y )
              THEN
                RETURN FALSE;
              END;
              p := Next;
            END;
          END;
          RETURN TRUE;
        ELSE
          RETURN FALSE;
        END;
      END CursorExposed;

    VAR
      x, y : INTEGER;
      p : PView;
    BEGIN
      IF TViewStates{ sfVisible, sfCursorVis, sfFocused } <= State THEN
        x := Cursor.X;
        y := Cursor.Y;
        p := ADR(SELF);
        LOOP
          WITH p^ DO
            IF (x < 0) OR ( x >= Size.X ) OR ( y < 0 ) OR ( y >= Size.Y ) THEN
              RemoveCursor;
              RETURN;
            END;
            IF Owner = NIL THEN
              EXIT;
            END;
            INC( x, Origin.X );
            INC( y, Origin.Y );
            IF NOT CursorExposed( Owner, p, x, y ) THEN
              RemoveCursor;
              RETURN;
            END;
            p := Owner;
          END;
        END;
        r.AH := 2;
        r.DH := VAL( SHORTCARD, y );
        r.DL := VAL( SHORTCARD, x );
        r.BX := 0;
        Intr( r, 10H );
        r.CX := CursorLines;
        IF sfCursorIns IN State THEN
          r.CH := 0;
          IF r.CL = 0 THEN
            r.CL := 7;
          END;
        END;
        r.AH := 1;
        Intr( r, 10H );
      ELSE
        RemoveCursor;
      END;
    END ResetCursor;

    PROCEDURE FocusView( Enable : BOOLEAN );
    VAR
      Command : CARDINAL;
      Dummy   : ADDRESS;
    BEGIN
      IF (sfFocused IN State) # Enable THEN
        SetState( TViewStates{ sfFocused }, Enable );
(*
        IF Enable THEN
          Command := cmReceivedFocus;
        ELSE
          Command := cmReleasedFocus;
        END;
        Dummy := Message( PView( ADR( SELF )), EventTypes{evCommand}, Command, ADR( SELF ));
*)
      END;
    END FocusView;

  BEGIN
    Owner := NIL;
    Next := NIL;
    Options := TViewOptions{};
    State := TViewStates{ sfVisible };
    GrowMode := TViewGrowModes{};
    DragMode := TViewDragModes{ dmLimitLoY };
    HelpCtx  := hcNoContext;
    EventMask := EventTypes { evMouseDown, evKeyDown, evCommand };
    Cursor.X := 0;
    Cursor.Y := 0;
  END TView;

TYPE
  HandleStruct = RECORD
    Event : POINTER TO Drivers.TEvent;
    Grp   : PGroup;
  END;

  SetBlock = RECORD
    st : TViewStates;
    en : BOOLEAN;
  END ;

  Expo = RECORD
    b : BOOLEAN;
    p : PGroup;
  END;

(*# save *)
(*%T _fcall *)
(*# call(near_call=>off) *)
(*%E*)
  PROCEDURE DoCalcChange(p : ADDRESS; d : ADDRESS);
  VAR
    r : TRect;
    t : POINTER TO TPoint;
  BEGIN
    t := d;
    PGroup(p)^.CalcBounds(r, t^);
    PGroup(p)^.ChangeBounds(r);
   END DoCalcChange;

   PROCEDURE AddSubViewDataSize(p : ADDRESS; a : ADDRESS);
   BEGIN
     INC(a^, PGroup(p)^.DataSize());
   END AddSubViewDataSize;

   PROCEDURE DoHandleEvent( _p : ADDRESS; s : ADDRESS );
   VAR
     ptr : POINTER TO HandleStruct;
     p : PView;
   BEGIN
     ptr := s ;
     p := _p;
     IF ( p = NIL ) OR
        (( sfDisabled IN p^.State) &
         ( (PositionalEvents + FocusedEvents) * ptr^.Event^.What # EventTypes{} ))
     THEN
       RETURN;
     END;
     CASE ptr^.Grp^.Phase OF
     | phPreProcess:
         IF NOT ( ofPreProcess IN p^.Options ) THEN
           RETURN;
         END;
     | phPostProcess:
         IF NOT ( ofPostProcess IN p^.Options ) THEN
           RETURN;
         END;
     END;
     IF ptr^.Event^.What * p^.EventMask #  EventTypes {} THEN
       p^.HandleEvent( ptr^.Event^ );
     END;
   END DoHandleEvent;

   PROCEDURE HasMouse( p : ADDRESS; s : ADDRESS) : BOOLEAN;
   VAR
     e : POINTER TO Drivers.TEvent;
   BEGIN
     e := s;
     RETURN PView(p)^.ContainsMouse( e^ );
   END HasMouse;

    PROCEDURE DoExpose( p : ADDRESS; Enable : ADDRESS );
    VAR
      e : POINTER TO Expo;
    BEGIN
      e := Enable;
      IF sfVisible IN e^.p^.State THEN
        PView(p)^.SetState( TViewStates{ sfExposed }, e^.b );
      END;
    END DoExpose;

    PROCEDURE DoSetState( p : ADDRESS; b : ADDRESS );
    VAR
      ptr : POINTER TO SetBlock;
    BEGIN
      ptr := b;
      PView(p)^.SetState( ptr^.st, ptr^.en );
    END DoSetState;

    PROCEDURE DoPut( p : PView; s : ADDRESS );
    VAR
      PS : POINTER TO Streams.TStream;
    BEGIN
      PS := s;
      p^.Store ( PS^ );
    END DoPut;

    PROCEDURE IsInvalid( p : PView; cmd : ADDRESS ) : BOOLEAN;
    BEGIN
      RETURN NOT p^.Valid( CARDINAL(cmd^) ) ;
    END IsInvalid;

(*# restore *)

  CLASS IMPLEMENTATION TGroup;

    PROCEDURE Init(VAR Bounds: Objects.TRect);   (* Constructor *)
    BEGIN
      TView.Init ( Bounds );
      INCL( Options, ofSelectable );
      INCL( Options, ofBuffered );
      Clip := GetExtent();
      EventMask := evMouse + evKeyboard + evMessage;
    END Init;

    PROCEDURE Load(VAR S: Streams.TStream);      (* Constructor *)
    VAR
      index, count, i : CARDINAL;
      OwnerSave : PGroup;
      tv, current : PView;
    BEGIN
      TView.Load( S );
      Clip := GetExtent();
      OwnerSave := Owner;
      Owner := ADR( SELF );
      S.Rd(count);
      FOR i := 0 TO count-1 DO
        NEW(tv);
        tv^.Load(S);
        IF tv # NIL THEN
          InsertView( tv, NIL );
        END;
      END;
      Owner := OwnerSave;
      S.Rd(index);
      current := At(index);
      SetCurrent( current, NormalSelect );
    END Load;

    VIRTUAL PROCEDURE Done;                      (* Destructor *)
    VAR
      p, tmp : PView;
    BEGIN
      p := Last;
      IF p # NIL THEN
        REPEAT
          tmp := p^.Prev();
          Delete( p );
          p := tmp;
        UNTIL Last = NIL;
      END;
      FreeBuffer();
      Current := NIL;
      TView.Done;
    END Done;

    VIRTUAL PROCEDURE ChangeBounds(VAR Bounds: Objects.TRect);
    VAR
      d : TPoint;
    BEGIN
      d.X := (Bounds.B.X - Bounds.A.X) - Size.X;
      d.Y := (Bounds.B.Y - Bounds.A.Y) - Size.Y;
      IF ( d.X = 0 ) &  ( d.Y = 0 ) THEN
        SetBounds(Bounds);
        DrawView();
      ELSE
        FreeBuffer;
        SetBounds( Bounds );
        Clip := GetExtent();
        GetBuffer;
        Lock;
        ForEach( DoCalcChange, ADR( d ) );
        Unlock;
      END;
    END ChangeBounds;

    VIRTUAL PROCEDURE DataSize(): CARDINAL;
    VAR
      t : CARDINAL;
    BEGIN
      t := 0;
      ForEach( AddSubViewDataSize, ADR(t) );
      RETURN t;
    END DataSize;

    PROCEDURE DeleteView(P : PView);
    VAR
      w, v : PView;
    BEGIN
      IF Last # NIL THEN
        IF P # Last THEN
          w := Last;
          WHILE w^.Next # P DO
            w := w^.Next;
          END;
          w^.Next := P^.Next;
        ELSE
          IF P^.Next = P THEN
            Last := NIL;
          ELSE
            WHILE Last^.Next # P DO
              Last := Last^.Next;
            END;
            Last^.Next := P^.Next;
          END;
        END;
      END;
    END DeleteView;

    PROCEDURE Delete(P: PView);
    VAR
      SaveState : TViewStates;

    BEGIN
      SaveState := P^.State;
      P^.Hide;
      DeleteView(P);
      P^.Owner := NIL;
      P^.Next := NIL;
      IF sfVisible IN SaveState THEN
        P^.Show;
      END;
    END Delete;

    VIRTUAL PROCEDURE Draw;
    BEGIN
      IF Buffer = FarNIL THEN
        GetBuffer();
        IF Buffer # FarNIL THEN
          INC(LockFlag);
          Redraw;
          DEC(LockFlag);
        END;
      END;
      IF Buffer # FarNIL THEN
        WriteBuf( 0, 0, Size.X, Size.Y, Buffer );
      ELSE
        Clip := GetClipRect();
        Redraw();
        Clip := GetExtent();
      END;
    END Draw;

    PROCEDURE DrawSubViews( p, Bottom : PView );
    BEGIN
      WHILE p # Bottom DO
        p^.DrawView;
        p := p^.NextView();
      END;
    END DrawSubViews;

    VIRTUAL PROCEDURE EndModal(Command: CARDINAL);
    BEGIN
      IF sfModal IN State THEN
        EndState := Command;
      ELSE
        TView.EndModal( Command );
      END;
    END EndModal;

    VIRTUAL PROCEDURE EventError(VAR Event: Drivers.TEvent);
    BEGIN
      IF Owner # NIL THEN
        Owner^.EventError( Event );
      END;
    END EventError;

    VIRTUAL PROCEDURE Execute(): CARDINAL;
    VAR
      e : Drivers.TEvent;
    BEGIN
      REPEAT
        EndState := 0;
        REPEAT
          GetEvent( e );
          HandleEvent( e );
          IF e.What # evNothing THEN
            EventError( e );
          END;
        UNTIL EndState # 0 ;
      UNTIL Valid( EndState );
      RETURN EndState;
    END Execute;

    PROCEDURE ExecView(p: PView): CARDINAL;
    VAR
      SaveOptions : TViewOptions;
      SaveOwner   : PGroup;
      SaveTopView : PView;
      SaveCurrent : PView;
      SaveCommands : TCommandSet;
      RetVal       : CARDINAL;
    BEGIN
      IF p = NIL THEN
        RETURN cmCancel;
      END;
      SaveOptions := p^.Options;
      SaveOwner := p^.Owner;
      SaveTopView := TheTopView;
      SaveCurrent := Current;
      GetCommands( SaveCommands );
      TheTopView := p;
      EXCL ( p^.Options, ofSelectable);
      p^.SetState( TViewStates{ sfModal }, TRUE);
      SetCurrent(p, EnterSelect);
      IF SaveOwner = NIL THEN
        Insert(p);
      END;
      RetVal := p^.Execute();
      IF SaveOwner = NIL THEN
        Delete(p);
      END;
      SetCurrent(SaveCurrent, LeaveSelect);
      p^.SetState( TViewStates{ sfModal }, FALSE);
      p^.Options := SaveOptions;
      TheTopView := SaveTopView;
      SetCommands(SaveCommands);
      RETURN RetVal;
    END ExecView;

    PROCEDURE First(): PView;
    BEGIN
      IF Last = NIL THEN
        RETURN NIL;
      ELSE
        RETURN Last^.Next;
      END;
    END First;

    PROCEDURE At( index : INTEGER ) : PView;
    VAR
      temp : PView;
    BEGIN
      temp := Last;
      WHILE index > 0 DO
        DEC ( index );
        temp := temp^.Next;
      END;
      RETURN temp;
    END At;

    PROCEDURE FirstThat(func: BoolProcAddr; args : ADDRESS) : PView;
    VAR
      temp : PView;
    BEGIN
      temp := Last;
      IF temp = NIL THEN
        RETURN NIL;
      END;
      REPEAT
        temp := temp^.Next;
        IF func( temp, args ) THEN
          RETURN temp;
        END;
      UNTIL temp = Last;
      RETURN NIL;
    END FirstThat;

    PROCEDURE ForEach(func : ProcAddr; args : ADDRESS);
    VAR
      term, temp, next : PView;
    BEGIN
      term := Last;
      temp := Last;
      IF temp = NIL THEN
        RETURN;
      END;
      next := temp^.Next;
      REPEAT
        temp := next;
        next := temp^.Next;
        func( temp, args );
      UNTIL temp = term ;
    END ForEach;

    PROCEDURE IndexOf( p : PView ) : CARDINAL;
    VAR
      index : INTEGER;
      temp  : PView;
    BEGIN
      IF Last = NIL THEN
        RETURN 0;
      END;
      index := 0;
      temp := Last;
      REPEAT
        INC ( index );
        temp := temp^.Next;
      UNTIL ( temp = p ) OR ( temp = Last );
      IF temp # p THEN
        RETURN 0;
      ELSE
        RETURN index;
      END;
    END IndexOf;

    PROCEDURE FirstMatch( AState : TViewStates;
                          AOptions : TViewOptions ) : PView;
    VAR
      temp : PView;
    BEGIN
      IF Last = NIL THEN
        RETURN NIL;
      END;
      temp := Last;
      LOOP
        IF ( AState <= temp^.State ) & (AOptions <= temp^.Options ) THEN
          RETURN temp;
        END;
        temp := temp^.Next;
        IF temp = Last THEN
          RETURN NIL;
        END;
      END;
    END FirstMatch;

    PROCEDURE FreeBuffer;
    BEGIN
      IF (ofBuffered IN Options) & ( Buffer # FarNIL ) THEN
(*          TVMemMgr::freeDiscardable( buffer ); *)
        DEALLOCATE( Buffer, Size.X * Size.Y * SIZE(CARDINAL));
      END;
    END FreeBuffer;

    PROCEDURE GetBuffer;
    BEGIN
      IF sfExposed IN State THEN
        IF ( ofBuffered IN Options ) & ( Buffer = FarNIL ) THEN
          ALLOCATE( Buffer, Size.X * Size.Y * SIZE( CARDINAL ));
        END;
      END;
    END GetBuffer;

    VIRTUAL PROCEDURE GetData(VAR Rec : ARRAY OF BYTE);
    VAR
      i, d : CARDINAL;
      v : PView;
    BEGIN
      i := 0;
      IF Last # NIL THEN
        v := Last;
        REPEAT
          d := v^.DataSize();
          IF i+d > HIGH( Rec )+1 THEN
            FatalError(ErrorInData);
          END;
(*#save,check(index=>off)*)
          v^.GetData( Rec [ i ] );
(*#restore*)
          INC ( i, d );
          v := v^.Prev();
        UNTIL v = Last;
      END;
    END GetData;

    PROCEDURE GetSubViewPtr(VAR S: Streams.TStream; VAR P : ARRAY OF BYTE);
    END GetSubViewPtr;

    VIRTUAL PROCEDURE HandleEvent(VAR Event: Drivers.TEvent);
    VAR
      hs : HandleStruct;
    BEGIN
      hs.Event := ADR(Event);
      hs.Grp := ADR(SELF);
      TView.HandleEvent( Event );
      IF FocusedEvents * Event.What # EventTypes{} THEN
        Phase := phPreProcess;
        ForEach( DoHandleEvent, ADR(hs) );
        Phase := phFocused;
        DoHandleEvent( Current, ADR(hs) );
        Phase := phPostProcess;
        ForEach( DoHandleEvent, ADR(hs) );
      ELSE
        Phase := phFocused;
        IF PositionalEvents * Event.What # EventTypes{} THEN
          DoHandleEvent( FirstThat( HasMouse, ADR( Event ) ), ADR(hs) );
        ELSE
          ForEach( DoHandleEvent, ADR(hs) );
        END;
      END;
    END HandleEvent;

    PROCEDURE Insert(P: PView);
    BEGIN
      InsertBefore( P, First() );
    END Insert;

    PROCEDURE InsertBefore(p, Target: PView);
    VAR
      SaveState : TViewStates;
    BEGIN
      IF ( p # NIL ) &
         (p^.Owner = NIL) &
         ((Target = NIL) OR (Target^.Owner = ADR(SELF)))
      THEN
        IF ofCenterX IN p^.Options THEN
          p^.Origin.X := (Size.X - p^.Size.X) DIV 2;
        END;
        IF ofCenterY IN p^.Options THEN
          p^.Origin.Y := (Size.Y - p^.Size.Y) DIV 2;
        END;
        SaveState := p^.State;
        p^.Hide;
        InsertView( p, Target );
        IF sfVisible IN SaveState THEN
          p^.Show;
        END;
      END;
    END InsertBefore;

    PROCEDURE InsertView( p : PView; Target : PView );
    BEGIN
      p^.Owner := ADR( SELF );
      IF Target # NIL THEN
        Target := Target^.Prev();
        p^.Next := Target^.Next;
        Target^.Next := p;
      ELSE
        IF Last = NIL THEN
          p^.Next := p;
        ELSE
          p^.Next := Last^.Next;
          Last^.Next := p;
        END;
        Last := p;
      END;
    END InsertView;

    PROCEDURE Lock;
    BEGIN
      IF ( Buffer # FarNIL ) OR ( LockFlag # 0 ) THEN
        INC(LockFlag);
      END;
    END Lock;

    PROCEDURE PutSubViewPtr(VAR S: Streams.TStream; P: PView);
    END PutSubViewPtr;

    PROCEDURE Redraw;
    BEGIN
      DrawSubViews( First(), NIL );
    END Redraw;

    PROCEDURE ResetCurrent;
    BEGIN
      SetCurrent( FirstMatch( TViewStates{ sfVisible },
                              TViewOptions{ ofSelectable } ),
                  NormalSelect );
    END ResetCurrent;
(*
    VIRTUAL PROCEDURE ResetCursor;
    BEGIN
      IF Current # NIL THEN
        Current^.ResetCursor;
      END;
    END ResetCursor;
*)
    PROCEDURE SelectNext(Forwards: BOOLEAN);
    VAR
      p : PView;
    BEGIN
      IF Current # NIL THEN
        p := Current;
        REPEAT
          IF Forwards THEN
            p := p^.Next;
          ELSE
            p := p^.Prev();
          END;
        UNTIL ( p^.State * TViewStates{ sfVisible, sfDisabled } = TViewStates{ sfVisible } ) &
              ( ofSelectable IN p^.Options ) OR (p = Current);
        p^.Select();
      END;
    END SelectNext;

    PROCEDURE SelectView( p : PView; Enable : BOOLEAN );
    BEGIN
      IF p # NIL THEN
        p^.SetState( TViewStates{ sfSelected }, Enable );
      END;
    END SelectView;

    PROCEDURE FocusView( p : PView; Enable : BOOLEAN );
    VAR
      Command : CARDINAL;
      Dummy   : ADDRESS;
    BEGIN
      IF p # NIL THEN
        p^.FocusView( Enable );
      END;
    END FocusView;

    PROCEDURE SetCurrent( p : PView; Mode : SelectMode );
    BEGIN
      IF Current # p THEN
        Lock();
        FocusView( Current, FALSE );
        IF Mode # EnterSelect THEN
          IF Current # NIL THEN
            Current^.SetState( TViewStates{ sfSelected }, FALSE );
          END;
        END;
        IF Mode # LeaveSelect THEN
          IF p # NIL THEN
            p^.SetState( TViewStates{ sfSelected }, TRUE );
          END;
        END;
        FocusView( p, TRUE );
        (*
        IF ( sfFocused IN State ) & ( p # NIL ) THEN
          p^.SetState( TViewStates{ sfFocused }, TRUE );
        END;
        *)
        Current := p;
        Unlock();
      END;
    END SetCurrent;

    VIRTUAL PROCEDURE SetData(VAR Rec : ARRAY OF BYTE);
    VAR
      i, d : CARDINAL;
      v : PView;
    BEGIN
      i := 0;
      IF Last # NIL THEN
        v := Last;
        REPEAT
          d := v^.DataSize();
          IF i+d > HIGH( Rec )+1 THEN
            FatalError( ErrorInData );
          END;
(*#save,check(index=>off)*)
          v^.SetData( Rec [ i ] );
(*#restore*)
          INC ( i, d );
          v := v^.Prev();
        UNTIL v = Last;
      END;
    END SetData;

    VIRTUAL PROCEDURE SetState( AState: TViewStates;
                                Enable: BOOLEAN);
    VAR
      sb : SetBlock;
      ex : Expo;
    BEGIN
      sb.st := AState;
      sb.en := Enable;
      ex.b := Enable;
      ex.p := ADR(SELF);
      TView.SetState( AState, Enable );
      IF TViewStates{ sfActive, sfDragging } * AState # TViewStates{} THEN
        Lock();
        ForEach( DoSetState, ADR(sb) );
        Unlock();
      END;
      IF Current # NIL THEN
        Current^.FocusView( Enable );
      END;
(*
      IF sfFocused IN AState THEN
        IF Current # NIL THEN
          Current^.SetState( TViewStates{ sfFocused }, Enable );
        END;
      END;
*)
      IF sfExposed IN AState THEN
        ForEach( DoExpose, ADR(ex) );
        IF NOT Enable THEN
          FreeBuffer;
        END;
      END;
    END SetState;

    PROCEDURE Store(VAR S: Streams.TStream);
    VAR
      index, count : CARDINAL;
      OwnerSave : PGroup;

    BEGIN
      TView.Store( S );
      OwnerSave := Owner;
      Owner := ADR(SELF);
      count := IndexOf( Last );
      S.Wr(count);
      ForEach( DoPut, ADR(S) );
      IF Current = NIL THEN
        index := 0;
      ELSE
       index := IndexOf(Current);
      END;
      S.Wr(index);
      Owner := OwnerSave;
    END Store;

    PROCEDURE Unlock;
    BEGIN
      IF LockFlag # 0 THEN
        DEC(LockFlag);
        IF LockFlag = 0 THEN
          DrawView;
        END;
      END;
    END Unlock;

    VIRTUAL PROCEDURE Valid(Command: CARDINAL): BOOLEAN;
    VAR
      cmd : CARDINAL;

    BEGIN
      cmd := Command;
      RETURN FirstThat( IsInvalid, ADR(cmd) ) = NIL;
    END Valid;

    VIRTUAL PROCEDURE GetHelpCtx():CARDINAL;
    VAR
      h : CARDINAL;
    BEGIN
      h := hcNoContext;
      IF Current # NIL THEN
        h := Current^.GetHelpCtx();
      END;
      IF h = hcNoContext THEN
        h := TView.GetHelpCtx();
      END;
      RETURN h;
    END GetHelpCtx;

  BEGIN
    Last := NIL;
    Phase := phFocused;
    Current := NIL;
    Buffer := FarNIL;
    LockFlag := 0;
    EndState := 0;
    T := 0;
  END TGroup;

PROCEDURE Message(Receiver      : PView;
                  What          : Drivers.EventTypes;
                  Command       : CARDINAL;
                  InfoPtr       : ADDRESS     ): ADDRESS;
VAR
  Event : Drivers.TEvent;
BEGIN
  IF Receiver = NIL THEN
    RETURN NIL;
  END;
  Event.What := What;
  Event.Command := Command;
  Event.InfoPtr := InfoPtr;
  Receiver^.HandleEvent( Event );
  IF Event.What = evNothing THEN
    RETURN Event.InfoPtr;
  ELSE
    RETURN NIL;
  END;
END Message;

PROCEDURE CommandEnabled(Command: SHORTCARD): BOOLEAN;
BEGIN
  RETURN (Command > 255) OR (Command IN CurCommandSet);
END CommandEnabled;

PROCEDURE DisableCommands(Commands: TCommandSet);
BEGIN
  CommandSetChanged := CommandSetChanged OR
                       (Commands * CurCommandSet # TCommandSet{});
  CurCommandSet := CurCommandSet - Commands;
END DisableCommands;

PROCEDURE DisableCommand(Command : SHORTCARD);
BEGIN
  CommandSetChanged := CommandSetChanged OR (Command IN CurCommandSet);
  EXCL(CurCommandSet, Command);
END DisableCommand;

PROCEDURE EnableCommands(Commands: TCommandSet);
BEGIN
  CommandSetChanged := CommandSetChanged OR NOT ( Commands <= CurCommandSet );
  CurCommandSet := CurCommandSet+Commands;
END EnableCommands;

PROCEDURE EnableCommand( Command : SHORTCARD);
BEGIN
  CommandSetChanged := CommandSetChanged OR NOT (Command IN CurCommandSet);
  INCL(CurCommandSet, Command);
END EnableCommand;

BEGIN
  TheTopView := NIL;
  CommandSetChanged := FALSE;
  CurCommandSet := TCommandSet{0..255} -
                   TCommandSet{cmZoom, cmClose, cmResize, cmPrev, cmNext};
  PositionalEvents := Drivers.evMouse;
  FocusedEvents    := Drivers.evKeyboard + Drivers.EventTypes{Drivers.evCommand};
  ShowMarkers := FALSE;
  ErrorAttr := 0CFH;
  MinWinSize := Objects.TPoint(16, 6);
  ShadowSize := Objects.TPoint(2, 1);
  ShadowAttr := 08H;
END Views.