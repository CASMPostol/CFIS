(*%T TV_NoDebug*)
(*# debug(vid=>off)*)
(*%E*)
(*%T InOneSegment *)
(*#call(seg_name=>TV)*)
(*%E*)
IMPLEMENTATION MODULE Scroller;

FROM ScrollBars IMPORT
  PScrollBar;
FROM Views IMPORT
  TViewOption, TViewOptions, TViewState, TViewStates, PPalette;
FROM Drivers IMPORT
  EventType, EventTypes;
FROM Texts IMPORT
  CScroller;
FROM Commands IMPORT
  cmScrollBarChanged;

  CLASS IMPLEMENTATION TScroller;

    PROCEDURE Init(VAR Bounds       : Objects.TRect;
                       AHScrollBar,
                       AVScrollBar  : PScrollBar);       (* Constructor *)
    BEGIN
      TView.Init ( Bounds );
      HScrollBar := AHScrollBar;
      VScrollBar := AVScrollBar;
      DrawLock := 0 ;
      DrawFlag := FALSE;
      Delta.X  := 0;
      Delta.Y  := 0;
      Limit.X  := 0;
      Limit.Y  := 0;
      INCL(Options, ofSelectable);
      INCL(EventMask, evBroadcast);
    END Init;

    PROCEDURE Load(VAR S: Streams.TStream);              (* Constructor *)
    BEGIN
      TView.Load( S );
      HScrollBar^.Load( S );
      VScrollBar^.Load( S );
      S.Rd(Delta);
      S.Rd(Limit);
      DrawLock := 0;
      DrawFlag := FALSE;
    END Load;

    VIRTUAL PROCEDURE ChangeBounds(VAR Bounds: Objects.TRect);
    BEGIN
      SetBounds( Bounds );
      INC(DrawLock);
      SetLimit(Limit.X, Limit.Y);
      DEC(DrawLock);
      DrawFlag := FALSE;
      DrawView();
    END ChangeBounds;

    VIRTUAL PROCEDURE GetPalette(): PPalette;
    BEGIN
      RETURN ADR(CScroller);
    END GetPalette;

    PROCEDURE CheckDraw;
    BEGIN
      IF (DrawLock = 0) & DrawFlag THEN
        DrawFlag := FALSE;
        DrawView();
      END;
    END CheckDraw;

    VIRTUAL PROCEDURE HandleEvent(VAR Event: Drivers.TEvent);
    BEGIN
      TView.HandleEvent(Event);
      IF ( evBroadcast IN Event.What ) & ( Event.Command = cmScrollBarChanged) &
         (( Event.InfoPtr = HScrollBar) OR (Event.InfoPtr = VScrollBar ))
      THEN
        ScrollDraw();
      END;
    END HandleEvent;

    VIRTUAL PROCEDURE ScrollDraw;
    VAR
      d: Objects.TPoint;
    BEGIN
      IF HScrollBar # NIL THEN
        d.X := HScrollBar^.Value;
      ELSE
        d.X := 0;
      END;
      IF VScrollBar # NIL THEN
        d.Y := VScrollBar^.Value;
      ELSE
        d.Y := 0;
      END;
      IF (d.X # Delta.X) OR (d.Y # Delta.Y ) THEN
        SetCursor( Cursor.X + Delta.X - d.X, Cursor.Y + Delta.Y - d.Y );
        Delta := d;
        IF DrawLock # 0 THEN
          DrawFlag := TRUE;
        ELSE
          DrawView();
        END;
      END;
    END ScrollDraw;

    PROCEDURE ScrollTo(X, Y: INTEGER);
    BEGIN
      INC(DrawLock);
      IF HScrollBar # NIL THEN
        HScrollBar^.SetValue(X);
      END;
      IF VScrollBar # NIL THEN
        VScrollBar^.SetValue(Y);
      END;
      DEC(DrawLock);
      CheckDraw();
    END ScrollTo;

    PROCEDURE SetLimit(X, Y: INTEGER);
    BEGIN
      Limit.X := X;
      Limit.Y := Y;
      INC(DrawLock);
      IF HScrollBar # NIL THEN
        WITH HScrollBar^ DO
          SetParams( Value, 0, X - Size.X, Size.X-1, 1 );
        END;
      END;
      IF VScrollBar # NIL THEN
        WITH VScrollBar^ DO
          SetParams( Value, 0, Y - Size.Y, Size.Y-1, 1 );
        END;
      END;
      DEC(DrawLock);
      CheckDraw();
    END SetLimit;

    VIRTUAL PROCEDURE SetState( AState: TViewStates;
                                Enable: BOOLEAN);

      PROCEDURE ShowSBar( sBar : PScrollBar );
      BEGIN
        IF sBar # NIL THEN
          IF GetState( TViewStates { sfActive, sfSelected } ) THEN
            sBar^.Show();
          ELSE
            sBar^.Hide();
          END;
        END;
      END ShowSBar;

    BEGIN
      TView.SetState(AState, Enable);
      IF AState * TViewStates{ sfActive, sfSelected } # TViewStates{} THEN
        ShowSBar(HScrollBar);
        ShowSBar(VScrollBar);
      END;
    END SetState;

    PROCEDURE Store(VAR S: Streams.TStream);
    BEGIN
      TView.Store( S );
      HScrollBar^.Store( S );
      VScrollBar^.Store( S );
      S.Wr(Delta);
      S.Wr(Limit);
    END Store;

  BEGIN
  END TScroller;



END Scroller.