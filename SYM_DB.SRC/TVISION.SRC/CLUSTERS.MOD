(*%T TV_NoDebug*)
(*# debug(vid=>off)*)
(*%E*)
(*%T InOneSegment *)
(*#call(seg_name=>TV)*)
(*%E*)
IMPLEMENTATION MODULE Clusters;

FROM Views IMPORT
  TView, TViewOption, TViewOptions, TViewState, TViewStates, ShowMarkers,
  PVideoBuf, PPalette, TGroupPhase;
FROM Objects IMPORT
  TRect, PString, TPoint, NewStr, DisposeStr;
FROM Storage IMPORT
  ALLOCATE, DEALLOCATE;
FROM Streams IMPORT
  TStream;
FROM Drivers IMPORT
  TDrawBuffer, MoveCStr, MoveChar, PutChar, TEvent, EventTypes, EventType,
  CtrlToArrow, kbUp, kbDown, kbRight, kbLeft, HotKey, GetAltCode, CStrLen;
FROM Texts IMPORT
  SpecialChars, CCluster;
FROM Commands IMPORT
  hcNoContext;

  CLASS IMPLEMENTATION TCluster;

    PROCEDURE Init(VAR Bounds: TRect;
                       AStrings: PSItem);
    VAR
      i : INTEGER;
      p : PSItem;
    BEGIN
      TView.Init( Bounds );
      Value := {};
      Sel := 0;
      Options := Options + TViewOptions{ ofSelectable, ofFirstClick,
                                         ofPreProcess, ofPostProcess };
      i := 0;
      p := AStrings;
      WHILE p # NIL DO
        p := p^.Next;
        INC( i );
      END;
      Strings.Init(i, 0);

      WHILE AStrings # NIL DO
        p := AStrings;
        WITH Strings DO
          AtInsert( Count, AStrings^.Value );
          AStrings := AStrings^.Next;
        END;
        DISPOSE ( p );
      END;
      SetCursor( 2, 0 );
      ShowCursor;
    END Init;

    PROCEDURE Load(VAR S: TStream);
    BEGIN
      TView.Load( S );
      S.Rd(Value);
      S.Rd(Sel);
      Strings.Load( S );
      SetCursor( 2, 0 );
      ShowCursor;
    END Load;

    VIRTUAL PROCEDURE Done;
    BEGIN
      TView.Done;
      Strings.Done;
    END Done;

    VIRTUAL PROCEDURE DataSize(): CARDINAL;
    BEGIN
      RETURN SIZE(Value);
    END DataSize;

    PROCEDURE DrawBox( Icon: ARRAY OF CHAR;
                       Marker: CHAR);
    VAR
      b : TDrawBuffer;
      Color : CARDINAL;
      cNorm : CARDINAL;
      cSel  : CARDINAL;
      i, j : INTEGER;
      cur : INTEGER;
      col : INTEGER;
    BEGIN
      cNorm := GetColor( 0301H );
      cSel := GetColor( 0402H );
      WITH Strings DO
        FOR i := 0 TO Size.Y DO
          FOR j := 0 TO VAL(INTEGER, Count-1) DIV Size.Y + 1 DO
            cur := j * Size.Y + i;
            IF cur < VAL( INTEGER, Count) THEN
              col := Column( cur );
              IF (cur = Sel) & (sfSelected IN State) THEN
                Color := cSel;
              ELSE
                Color := cNorm;
              END;
              MoveChar( b, col, ' ', Color, Size.X - col );
              MoveCStr( b, col, Icon, Color );
              IF Mark(cur) THEN
                PutChar( b, col+2, Marker );
              END;
              MoveCStr( b, col+5, PString(At(cur))^, Color );
              IF ShowMarkers & (sfSelected IN State) & (cur = Sel ) THEN
                PutChar( b, col, SpecialChars[0] );
                PutChar( b, Column(cur+Size.Y)-1, SpecialChars[1] );
              END;
            END;
          END;
          WriteBuf( 0, i, Size.X, 1, PVideoBuf(ADR(b)) );
        END;
      END;
      SetCursor( Column(Sel)+2, Row(Sel) );
    END DrawBox;

    VIRTUAL PROCEDURE GetData(VAR Rec : ARRAY OF BYTE);
    VAR
      adr : ADDRESS;
    BEGIN
      adr := ADR(Rec);
      adr^ := Value;
      DrawView;
    END GetData;

    VIRTUAL PROCEDURE GetHelpCtx(): CARDINAL;
    BEGIN
      IF HelpCtx = hcNoContext THEN
        RETURN hcNoContext;
      ELSE
        RETURN HelpCtx + VAL(CARDINAL, Sel);
      END;
    END GetHelpCtx;

    VIRTUAL PROCEDURE GetPalette(): PPalette;
    BEGIN
      RETURN ADR(CCluster);
    END GetPalette;

    VIRTUAL PROCEDURE HandleEvent(VAR Event: TEvent);
    VAR
      mouse : TPoint;
      i     : INTEGER;
      c     : CHAR;
    BEGIN
      TView.HandleEvent(Event);
      IF Event.What = EventTypes { evMouseDown } THEN
        mouse := MakeLocal( Event.Where );
        i := FindSel(mouse);
        IF i # -1 THEN
          Sel := i;
        END;
        DrawView;
        REPEAT
          mouse := MakeLocal( Event.Where );
          IF FindSel(mouse) = Sel THEN
            ShowCursor;
          ELSE
            HideCursor;
          END;
        UNTIL NOT MouseEvent(Event, EventTypes { evMouseMove } );
        ShowCursor();
        mouse := MakeLocal( Event.Where );
        IF FindSel(mouse) = Sel THEN
          Press(Sel);
          DrawView;
        END;
        ClearEvent(Event);
      ELSIF Event.What = EventTypes { evKeyDown } THEN
        CASE CtrlToArrow(Event.KeyCode) OF
        | kbUp:
            IF sfFocused IN State THEN
              DEC(Sel);
              IF Sel < 0 THEN
                Sel := Strings.Count-1;
              END;
              MovedTo(Sel);
              DrawView;
              ClearEvent(Event);
            END;
        | kbDown:
            IF sfFocused IN State THEN
              INC(Sel);
              IF Sel >= VAL(INTEGER, Strings.Count) THEN
                Sel := 0;
              END;
              MovedTo(Sel);
              DrawView;
              ClearEvent(Event);
            END;
        | kbRight:
            IF sfFocused IN State THEN
              INC(Sel, Size.Y);
              IF Sel >= VAL( INTEGER, Strings.Count) THEN
                Sel := (Sel + 1) MOD Size.Y;
                IF Sel >= VAL( INTEGER, Strings.Count) THEN
                  Sel := 0;
                END;
              END;
              MovedTo(Sel);
              DrawView();
              ClearEvent(Event);
            END;
        | kbLeft:
            IF sfFocused IN State THEN
              IF Sel > 0 THEN
                DEC( Sel, Size.Y);
                IF Sel < 0 THEN
                  Sel := ((VAL( INTEGER, Strings.Count)+Size.Y-1) DIV Size.Y)*Size.Y + Sel - 1;
                  IF Sel >= VAL( INTEGER, Strings.Count) THEN
                    Sel := Strings.Count-1;
                  END;
                END;
              ELSE
                Sel := Strings.Count-1;
              END;
              MovedTo(Sel);
              DrawView;
              ClearEvent(Event);
            END;
        ELSE
          FOR i := 0 TO Strings.Count-1 DO
            c := HotKey( PString(Strings.At(i))^ );
            IF ( GetAltCode(c) = Event.KeyCode ) OR
               ( ( Owner^.Phase = phPostProcess ) OR
                 ( sfFocused IN State )
               ) &
               ( c # 0C) & (CAP(Event.CharCode) = c)
            THEN
              Select;
              Sel := i;
              MovedTo(Sel);
              Press(Sel);
              DrawView;
              ClearEvent(Event);
              RETURN;
            END;
          END;
          IF ( Event.CharCode = ' ' ) & ( sfFocused IN State ) THEN
            Press(Sel);
            DrawView;
            ClearEvent(Event);
          END;
        END;
      END;
    END HandleEvent;

    VIRTUAL PROCEDURE Mark(Item: INTEGER): BOOLEAN;
    BEGIN
      RETURN FALSE;
    END Mark;

    VIRTUAL PROCEDURE Press(Item: INTEGER);
    END Press;

    VIRTUAL PROCEDURE MovedTo(Item: INTEGER);
    END MovedTo;

    VIRTUAL PROCEDURE SetData(VAR Rec : ARRAY OF BYTE);
    BEGIN
      Value := BITSET(Rec);
      DrawView;
    END SetData;

    VIRTUAL PROCEDURE SetState( AState: TViewStates;
                                Enable: BOOLEAN);
    BEGIN
      TView.SetState( AState, Enable );
      IF sfSelected IN AState THEN
        DrawView;
      END;
    END SetState;

    PROCEDURE Store(VAR S: TStream);
    BEGIN
      TView.Store( S );
      S.Wr(Value);
      S.Wr(Sel);
      Strings.Store( S );
    END Store;

    PROCEDURE Column( item  : INTEGER ) : INTEGER;
    VAR
      width, col, l, i : INTEGER;
    BEGIN
      IF item < Size.Y THEN
        RETURN 0;
      ELSE
        width := 0;
        col := -6;
        l := 0;
        FOR i := 0 TO item DO
          IF i MOD Size.Y = 0 THEN
            INC( col, width + 6 );
            width := 0;
          END;
          IF i < VAL( INTEGER, Strings.Count ) THEN
            l := CStrLen( PString(Strings.At(i))^ );
          END;
          IF l > width THEN
            width := l;
          END;
        END;
        RETURN col;
      END;
    END Column;

    PROCEDURE FindSel( p : TPoint ) : INTEGER;
    VAR
      r : TRect;
      i, s : INTEGER;
    BEGIN
      r := GetExtent();
      IF NOT r.Contains(p) THEN
        RETURN -1;
      ELSE
        i := 0;
        WHILE p.X >= Column( i + Size.Y ) DO
          INC (i, Size.Y);
        END;
        s := i + p.Y;
        IF s >= VAL( INTEGER, Strings.Count ) THEN
          RETURN -1;
        ELSE
          RETURN s;
        END;
      END;
    END FindSel;

    PROCEDURE Row( item : INTEGER ) : INTEGER;
    BEGIN
      RETURN item MOD Size.Y;
    END Row;

  BEGIN
  END TCluster;

PROCEDURE NewSItem( Str: ARRAY OF CHAR;
                    ANext: PSItem): PSItem;
VAR
  S : PSItem;
BEGIN
  NEW(S);
  WITH S^ DO
    Value := NewStr(Str);
    Next := ANext;
  END;
  RETURN S;
END NewSItem;


END Clusters.