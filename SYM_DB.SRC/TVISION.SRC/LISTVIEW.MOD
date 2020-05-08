(*%T TV_NoDebug*)
(*# debug(vid=>off)*)
(*%E*)
(*%T InOneSegment *)
(*#call(seg_name=>TV)*)
(*%E*)
IMPLEMENTATION MODULE ListViewers;

FROM ScrollBars IMPORT
   PScrollBar;
FROM Views IMPORT
  TViewState, TViewStates, TViewOption, TViewOptions, ShowMarkers, PPalette,
  Message;
FROM Drivers IMPORT
  EventType, EventTypes, TDrawBuffer, MoveChar, MoveStr, PutChar,
  CtrlToArrow, kbLeft, kbRight, kbUp, kbDown, kbHome, kbEnd, kbPgUp, kbPgDn,
  kbCtrlPgUp, kbCtrlPgDn;
FROM Lib IMPORT
  Move;
FROM Texts IMPORT
  SpecialChars, CListViewer;
FROM Commands IMPORT
  cmScrollBarClicked, cmScrollBarChanged, cmListItemSelected;

  CLASS IMPLEMENTATION TListViewer;

    PROCEDURE Init(VAR Bounds        : Objects.TRect;
                       ANumCols      : CARDINAL;
                       AHScrollBar,
                       AVScrollBar   : PScrollBar);    (* Constructor *)
    VAR
      arStep, pgStep : INTEGER;
    BEGIN
      TView.Init( Bounds );
      NumCols := ANumCols;
      INCL(Options, ofFirstClick);
      INCL(Options, ofSelectable);
      INCL(EventMask, evBroadcast);
      IF AVScrollBar # NIL THEN
        IF NumCols = 1 THEN
          pgStep := Size.Y - 1;
          arStep := 1;
        ELSE
          pgStep := Size.Y * NumCols;
          arStep := Size.Y;
        END;
        AVScrollBar^.SetStep( pgStep, arStep );
      END;
      IF AHScrollBar # NIL THEN
        AHScrollBar^.SetStep( Size.X DIV NumCols, 1 );
      END;
      HScrollBar := AHScrollBar;
      VScrollBar := AVScrollBar;
    END Init;

    PROCEDURE Load(VAR S: Streams.TStream);     (* Constructor *)
    BEGIN
      TView.Load( S );
      HScrollBar^.Load( S );
      VScrollBar^.Load( S );
      S.Rd(NumCols);
      S.Rd(TopItem);
      S.Rd(Focused);
      S.Rd(Range);
    END Load;

    VIRTUAL PROCEDURE ChangeBounds(VAR Bounds: Objects.TRect);
    BEGIN
      TView.ChangeBounds( Bounds );
      IF HScrollBar # NIL THEN
        HScrollBar^.SetStep( Size.X DIV NumCols, 1 );
      END;
    END ChangeBounds;

    VIRTUAL PROCEDURE Draw;
    VAR
      i, j : CARDINAL;
      item : INTEGER;
      normalColor, selectedColor, focusedColor, color : CARDINAL;
      colWidth, curCol, indent : CARDINAL;
      b : TDrawBuffer;
      scOff : SHORTCARD;
      text, buf : Objects.String;
    BEGIN
      IF TViewStates{ sfSelected, sfActive } * State # TViewStates{} THEN
        normalColor := GetColor(1);
        focusedColor := GetColor(3);
        selectedColor := GetColor(4);
      ELSE
        normalColor := GetColor(2);
        selectedColor := GetColor(4);
      END;
      IF HScrollBar # NIL THEN
        indent := HScrollBar^.Value;
      ELSE
        indent := 0;
      END;
      colWidth := Size.X DIV NumCols + 1;
      FOR i := 0 TO Size.Y-1 DO
        FOR j := 0 TO NumCols-1 DO
          item :=  VAL( INTEGER, j) * Size.Y + VAL( INTEGER, i) + TopItem;
          curCol := j * colWidth;
          IF (TViewStates{ sfSelected, sfActive } * State # TViewStates{}) &
             (Focused = item) &
             (Range > 0)
          THEN
            color := focusedColor;
            SetCursor( curCol + 1, i );
            scOff := 0;
          ELSIF ( item < Range ) & IsSelected(item) THEN
            color := selectedColor;
            scOff := 2;
          ELSE
            color := normalColor;
            scOff := 4;
          END;
          MoveChar( b, curCol, ' ', color, colWidth );
          IF item < Range THEN
            text := GetText( item, colWidth + indent );
            Move( ADR(text[indent]), ADR(buf), colWidth );
            buf[colWidth] := 0C;
            MoveStr( b, curCol+1, buf, color );
            IF ShowMarkers THEN
              PutChar( b, curCol, SpecialChars[ORD(scOff)] );
              PutChar( b, curCol+colWidth-2, SpecialChars[ORD(scOff+1)] );
            END;
          END;
          MoveChar( b, curCol+colWidth-1, CHR(179), GetColor(5), 1 );
        END;
        WriteLine( 0, i, Size.X, 1, b );
      END;
    END Draw;

    VIRTUAL PROCEDURE FocusItem(Item: INTEGER);
    BEGIN
      Focused := Item;
      IF VScrollBar # NIL THEN
        VScrollBar^.SetValue( Item );
      END;
      IF Item < TopItem THEN
        IF NumCols = 1 THEN
          TopItem := Item;
        ELSE
          TopItem := Item - Item MOD Size.Y;
        END;
      ELSE
        IF Item >= TopItem + Size.Y*NumCols THEN
          IF NumCols = 1 THEN
            TopItem := Item - Size.Y + 1;
          ELSE
            TopItem := Item - Item MOD Size.Y - (Size.Y * (NumCols-1));
          END;
        END;
      END;
      Draw;
    END FocusItem;

    VIRTUAL PROCEDURE GetPalette(): PPalette;
    BEGIN
      RETURN ADR(CListViewer)
    END GetPalette;

    VIRTUAL PROCEDURE GetText( Item: INTEGER;
                               MaxLen: INTEGER): Objects.String;
    BEGIN
      RETURN '';
    END GetText;

    VIRTUAL PROCEDURE IsSelected(Item: INTEGER): BOOLEAN;
    BEGIN
      RETURN Item = Focused;
    END IsSelected;

    VIRTUAL PROCEDURE HandleEvent(VAR Event: Drivers.TEvent);
    VAR
      Mouse : Objects.TPoint;
      colWidth : INTEGER;
      oldItem, newItem : INTEGER;
      count : CARDINAL;
      mouseAutosToSkip : CARDINAL;

      PROCEDURE FocusItemNum( item : INTEGER );
      BEGIN
        IF item < 0 THEN
          item := 0;
        ELSE
          IF (item >= Range) & ( Range > 0 ) THEN
            item := Range - 1;
          END;
        END;
        IF Range # 0 THEN
          FocusItem( item );
        END;
      END FocusItemNum;

    BEGIN
      TView.HandleEvent(Event);
      mouseAutosToSkip := 4;
      IF evMouseDown IN Event.What THEN
        colWidth := Size.X DIV NumCols + 1;
        oldItem := Focused;
        Mouse := MakeLocal( Event.Where );
        newItem := Mouse.Y + (Size.Y * (Mouse.X DIV colWidth)) + TopItem;
        count := 0;
        REPEAT
          IF newItem # oldItem THEN
            FocusItemNum( newItem );
          END;
          oldItem := newItem;
          Mouse := MakeLocal( Event.Where );
          IF MouseInView( Event.Where ) THEN
            newItem := Mouse.Y + (Size.Y * (Mouse.X DIV colWidth)) + TopItem;
          ELSE
            IF NumCols = 1 THEN
              IF evMouseAuto IN Event.What THEN
                INC(count);
              END;
              IF count = mouseAutosToSkip THEN
                count := 0;
                IF Mouse.Y < 0 THEN
                  newItem := Focused - 1;
                ELSIF Mouse.Y >= Size.Y THEN
                  newItem := Focused + 1;
                END;
              END;
            ELSE
              IF evMouseAuto IN Event.What THEN
                INC(count);
              END;
              IF count = mouseAutosToSkip THEN
                count := 0;
                IF Mouse.X < 0 THEN
                  newItem := Focused - Size.Y;
                ELSIF Mouse.X >= Size.X THEN
                  newItem := Focused + Size.Y;
                ELSIF Mouse.Y < 0 THEN
                  newItem := Focused - Focused MOD Size.Y;
                ELSIF Mouse.Y > Size.Y THEN
                  newItem := Focused - Focused MOD Size.Y + Size.Y - 1;
                END;
              END;
            END;
          END;
        UNTIL NOT MouseEvent( Event, EventTypes{ evMouseMove, evMouseAuto } );
        FocusItemNum( newItem );
        IF Event.Double & ( Range > Focused ) THEN
          SelectItem( Focused );
        END;
        ClearEvent( Event );
      ELSIF evKeyDown IN Event.What THEN
        IF ( Event.CharCode =  ' ' ) & ( Focused < Range ) THEN
          SelectItem( Focused );
          newItem := Focused;
        ELSE
          CASE CtrlToArrow(Event.KeyCode) OF
          | kbUp:       newItem := Focused - 1;
          | kbDown:     newItem := Focused + 1;
          | kbRight:
              IF NumCols > 1 THEN
                newItem := Focused + Size.Y;
              ELSE
                RETURN;
              END;
          | kbLeft:
              IF NumCols > 1 THEN
                newItem := Focused - Size.Y;
              ELSE
                RETURN;
              END;
          | kbPgDn:     newItem := Focused + Size.Y * NumCols;
          | kbPgUp:     newItem := Focused - Size.Y * NumCols;
          | kbHome:     newItem := TopItem;
          | kbEnd:      newItem := TopItem + (Size.Y * NumCols) - 1;
          | kbCtrlPgDn: newItem := Range - 1;
          | kbCtrlPgUp: newItem := 0;
          ELSE
            RETURN;
          END;
        END;
        FocusItemNum(newItem);
        ClearEvent(Event);
      ELSIF evBroadcast IN Event.What THEN
        IF ofSelectable IN Options THEN
          IF Event.Command = cmScrollBarClicked THEN
            Select();
          ELSIF Event.Command = cmScrollBarChanged THEN
            IF VScrollBar = Event.InfoPtr THEN
              FocusItemNum( VScrollBar^.Value );
              DrawView;
            ELSIF HScrollBar = Event.InfoPtr THEN
              DrawView;
            END;
          END;
        END;
      END;
    END HandleEvent;

    VIRTUAL PROCEDURE SelectItem(Item: INTEGER);
    VAR
      Dummy : ADDRESS;
    BEGIN
      Dummy := Message( Owner,
                        EventTypes{ evBroadcast },
                        cmListItemSelected,
                        ADR(SELF) );
    END SelectItem;

    PROCEDURE SetRange(ARange: INTEGER);
    BEGIN
      Range := ARange;
      IF VScrollBar # NIL THEN
        IF Focused > ARange THEN
          Focused := 0;
        END;
        WITH VScrollBar^ DO
          SetParams( Focused, 0, ARange - 1, PgStep, ArStep );
        END;
      END;
    END SetRange;

    VIRTUAL PROCEDURE SetState( AState: TViewStates;
                                Enable: BOOLEAN);
    BEGIN
      TView.SetState( AState, Enable );
      IF AState * TViewStates{ sfSelected, sfActive } # TViewStates{} THEN
        IF HScrollBar # NIL THEN
          IF GetState( TViewStates { sfActive } ) THEN
            HScrollBar^.Show;
          ELSE
            HScrollBar^.Hide;
          END;
        END;
        IF VScrollBar # NIL THEN
          IF GetState(TViewStates { sfActive } ) THEN
            VScrollBar^.Show;
          ELSE
            VScrollBar^.Hide;
          END;
        END;
        DrawView();
      END;
    END SetState;

    PROCEDURE Store(VAR S: Streams.TStream);
    BEGIN
      TView.Store( S );
      HScrollBar^.Store( S );
      VScrollBar^.Store( S );
      S.Wr(NumCols);
      S.Wr(TopItem);
      S.Wr(Focused);
      S.Wr(Range);
    END Store;

  BEGIN
    Range   := 0;
    Focused := 0;
    TopItem := 0;
  END TListViewer;


END ListViewers.