(*%T TV_NoDebug*)
(*# debug(vid=>off)*)
(*%E*)
(*%T InOneSegment *)
(*#call(seg_name=>TV)*)
(*%E*)
IMPLEMENTATION MODULE History;

FROM Objects IMPORT
  PString, String, TRect, Max;
FROM ScrollBars IMPORT
  PScrollBar, ScrollBarOptions, ScrollBarOption;
FROM Streams IMPORT
  TStream;
FROM HistList IMPORT
  HistoryCount, HistoryStr, HistoryAdd, HistorySort;
FROM Views IMPORT
  PPalette, TGroupPhase, TViewOption, TViewOptions, TViewState, TViewStates;
FROM Texts IMPORT
  CHistoryViewer, CHistoryWindow, HistoryIcon, CHistory;
FROM Str IMPORT
  Copy, Delete, Length, Slice;
FROM Drivers IMPORT
  TEvent, EventType, EventTypes, kbEnter, kbEsc, TDrawBuffer, MoveCStr,
  CtrlToArrow, kbDown;
FROM Commands IMPORT
  cmOK, cmCancel, cmReleasedFocus, cmRecordHistory;
FROM Winds IMPORT
  wnNoNumber, WindowFlag, WindowFlags, PWindow;
FROM Storage IMPORT
  ALLOCATE, DEALLOCATE;
FROM InputLines IMPORT
  PInputLine;

  CLASS IMPLEMENTATION THistoryViewer ;

    PROCEDURE Init(VAR Bounds: TRect;
                       AHScrollBar,
                       AVScrollBar: PScrollBar;
                       AHistoryId: CARDINAL);
    BEGIN
      TListViewer.Init ( Bounds, 1, AHScrollBar, AVScrollBar);
      HistoryId := AHistoryId;
      SetRange( HistoryCount( VAL( SHORTCARD, AHistoryId ) ) );
      IF Range > 1 THEN
        FocusItem( 1 );
      END;
      HScrollBar^.SetRange( 0, VAL(INTEGER, HistoryWidth()) - Size.X + 3 );
(*      HScrollBar^.SetRange( 1, HistoryWidth() - Size.X + 3 ); *)
    END Init;

    VIRTUAL PROCEDURE GetPalette(): PPalette;
    BEGIN
      RETURN ADR(CHistoryViewer);
    END GetPalette;

    VIRTUAL PROCEDURE GetText( Item: INTEGER;
                               MaxLen: INTEGER): String;
    VAR
      Res : String;
      str : String;
      tmp : PString;
    BEGIN
      tmp := HistoryStr( VAL( SHORTCARD, HistoryId ), Item );
      IF tmp = NIL THEN
        str := '';
        RETURN str;
      END;
      Copy( str, tmp^ );
      Copy( Res, str );
      Delete(Res, MaxLen, 0FFFH);
      RETURN Res;
    END GetText;

    VIRTUAL PROCEDURE HandleEvent(VAR Event: TEvent);
    BEGIN
      IF (Event.What = EventTypes { evMouseDown }) & (Event.Double) OR
         (Event.What = EventTypes { evKeyDown }) & (Event.KeyCode = kbEnter)
      THEN
        EndModal( cmOK );
        ClearEvent( Event );
      ELSE
        IF (Event.What =  EventTypes { evKeyDown }) & (Event.KeyCode = kbEsc) OR
           (Event.What =  EventTypes { evCommand }) & (Event.Command = cmCancel)
        THEN
          EndModal( cmCancel );
          ClearEvent( Event );
        ELSE
          TListViewer.HandleEvent( Event );
        END;
      END;
    END HandleEvent;

    PROCEDURE HistoryWidth(): CARDINAL;
    VAR
      width, count, i, T : INTEGER;
    BEGIN
      width := 0;
      count := HistoryCount( VAL( SHORTCARD, HistoryId ) );
      FOR i := 0 TO count-1 DO
        T := Length( HistoryStr( VAL( SHORTCARD, HistoryId ), i )^ );
        width := Max( width, T );
      END;
      RETURN width;
    END HistoryWidth;

  BEGIN
  END THistoryViewer;

  CLASS IMPLEMENTATION THistoryWindow;

    PROCEDURE Init(VAR Bounds: TRect;
                       HistoryId: CARDINAL);
    VAR
      r : TRect;
    BEGIN
      TWindow.Init( Bounds, '', wnNoNumber);
      Flags := WindowFlags{wfClose};
      NEW( Viewer );
      IF Viewer # NIL THEN
        r := GetExtent();
        Viewer := InitViewer( r, ADR(SELF), HistoryId);
        Insert(Viewer);
      END;
    END Init;

    VIRTUAL PROCEDURE GetPalette(): PPalette;
    BEGIN
      RETURN ADR(CHistoryWindow);
    END GetPalette;

    VIRTUAL PROCEDURE GetSelection(): String;
    BEGIN
      RETURN Viewer^.GetText( Viewer^.Focused, 255 );
    END GetSelection;

    VIRTUAL PROCEDURE InitViewer( r : TRect;
                                  win : PWindow;
                                  HistoryId: CARDINAL) : PHistoryViewer;
    VAR
      Res : PHistoryViewer;
    BEGIN
      r.Grow( -1, -1 );
      NEW(Res);
      Res^.Init( r,
                 win^.StandardScrollBar( ScrollBarOptions {sbHorizontal,
                                                           sbHandleKeyboard } ),
                 win^.StandardScrollBar( ScrollBarOptions {sbVertical,
                                                           sbHandleKeyboard } ),
                 HistoryId);
      RETURN Res;
    END InitViewer;

  BEGIN
  END THistoryWindow;


  CLASS IMPLEMENTATION THistory;

    PROCEDURE Init(VAR Bounds: TRect;
                       ALink: PInputLine;
                       AHistoryId: CARDINAL);
    BEGIN
      TView.Init ( Bounds );
      Link := ALink;
      HistoryId := AHistoryId;
      INCL(Options, ofPostProcess);
      INCL(EventMask, evBroadcast);
    END Init;

    PROCEDURE Load(VAR S: TStream);
    BEGIN
      TView.Load( S );
      NEW(Link);
      Link^.Load( S );
      S.Rd(HistoryId);
    END Load;

    VIRTUAL PROCEDURE Draw;
    VAR
      b : TDrawBuffer;
    BEGIN
      MoveCStr( b, 0, HistoryIcon, GetColor(0102H) );
      WriteLine( 0, 0, Size.X, Size.Y, b );
    END Draw;

    VIRTUAL PROCEDURE GetPalette(): PPalette;
    BEGIN
      RETURN ADR(CHistory);
    END GetPalette;

    VIRTUAL PROCEDURE HandleEvent(VAR Event: TEvent);
    VAR
      historyWindow : PHistoryWindow;
      r, p : TRect;
      c : CARDINAL;
      rslt : String;
    BEGIN
      TView.HandleEvent( Event );
      IF (Event.What = EventTypes { evMouseDown } ) OR
         (Event.What = EventTypes { evKeyDown }) &
         (CtrlToArrow( Event.KeyCode ) =  kbDown) &
         (sfFocused IN Link^.State)
      THEN
        Link^.Select();
        HistoryAdd( VAL( SHORTCARD, HistoryId ), Link^.Data^ );
        r := Link^.GetBounds();
        DEC(r.A.X);
        INC(r.B.X);
        INC(r.B.Y, 7);
        DEC(r.A.Y);
        p := Owner^.GetExtent();
        r.Intersect( p );
        DEC(r.B.Y);
        historyWindow := InitHistoryWindow( r );
        IF historyWindow # NIL THEN
          c := Owner^.ExecView( historyWindow );
          IF c = cmOK THEN
            rslt := historyWindow^.GetSelection( );
            Slice( Link^.Data^, rslt, 0, Link^.MaxLen );
            Link^.SelectAll( TRUE );
            Link^.DrawView;
          END;
          historyWindow^.Done;
          DISPOSE( historyWindow );
        END;
        ClearEvent( Event );
      ELSIF Event.What = EventTypes{ evBroadcast } THEN
        IF (Event.Command = cmReleasedFocus) & (Event.InfoPtr = Link) OR
           (Event.Command = cmRecordHistory)
        THEN
          HistoryAdd( VAL( SHORTCARD, HistoryId ), Link^.Data^ );
          HistorySort( VAL( SHORTCARD, HistoryId ) );
        END;
      END;
    END HandleEvent;

    VIRTUAL PROCEDURE InitHistoryWindow(VAR Bounds: TRect): PHistoryWindow;
    VAR
      p : PHistoryWindow;
    BEGIN
      NEW(p);
      p^.Init ( Bounds, HistoryId );
      p^.HelpCtx := Link^.HelpCtx;
      RETURN p;
    END InitHistoryWindow;

    PROCEDURE Store(VAR S: TStream);
    BEGIN
      TView.Store( S );
      Link^.Store( S );
      S.Wr(HistoryId);
    END Store;

  BEGIN
  END THistory;

END History.