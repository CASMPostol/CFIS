(*%T TV_NoDebug*)
(* # debug(vid=>off)*)
(*%E*)
(*%T InOneSegment *)
(*#call(seg_name=>TV)*)
(*%E*)
IMPLEMENTATION MODULE InputLines;

FROM Objects IMPORT
  TPoint, TRect, Min, Max;
FROM Views IMPORT
  TView, TViewOption, TViewOptions, TViewStates, TViewState, PPalette;
FROM Storage IMPORT
  ALLOCATE, DEALLOCATE;
FROM Streams IMPORT
  TStream;
FROM Str IMPORT
  Length, Slice, Delete, Insert;
FROM Drivers IMPORT
  TDrawBuffer, MoveChar, MoveStr, TEvent, EventType, EventTypes, CtrlToArrow,
  kbLeft, kbRight, kbHome, kbEnd, kbBack, kbDel, kbIns, SpecialKeys,
  KeyboardState;
FROM Texts IMPORT
  RightArrow, LeftArrow, CInputLine;
FROM Lib IMPORT
  Move;


CONST
  Shifts = KeyboardState{ kbLeftShift, kbRightShift };


  CLASS IMPLEMENTATION TInputLine;

    PROCEDURE Init(VAR Bounds: TRect;
                       AMaxLen: CARDINAL);
    BEGIN
      TView.Init( Bounds );
      ALLOCATE( Data, AMaxLen );
      MaxLen := AMaxLen-1;
      INCL(State, sfCursorVis);
      Options := Options + TViewOptions { ofSelectable, ofFirstClick };
      Data^[0] := 0C;
    END Init;

    PROCEDURE Load(VAR S: Streams.TStream);
    BEGIN
      TView.Load( S );
      S.Rd(MaxLen);
      S.Rd(CurPos);
      S.Rd(FirstPos);
      S.Rd(SelStart);
      S.Rd(SelEnd);
      Data := S.ReadStr( MaxLen );
      INCL(State, sfCursorVis);
      Options := Options + TViewOptions { ofSelectable, ofFirstClick };
    END Load;

    VIRTUAL PROCEDURE Done;
    BEGIN
      DEALLOCATE(Data, MaxLen+1);
      TView.Done;
    END Done;

    PROCEDURE CanScroll( Delta : INTEGER ) : BOOLEAN;
    BEGIN
      IF Delta < 0 THEN
        RETURN FirstPos > 0 ;
      ELSIF Delta > 0 THEN
        RETURN VAL(INTEGER, Length(Data^)) - FirstPos + 2 > Size.X;
      ELSE
        RETURN FALSE;
      END;
    END CanScroll;

    VIRTUAL PROCEDURE DataSize(): CARDINAL;
    BEGIN
      RETURN LineDataSize();
    END DataSize;

    PROCEDURE LineDataSize(): CARDINAL;
    BEGIN
      RETURN MaxLen+1;
    END LineDataSize;

    VIRTUAL PROCEDURE Draw;
    VAR
      l, r : INTEGER;
      b    : TDrawBuffer;
      Color : CARDINAL;
      buf   : ARRAY [0..255] OF CHAR;
    BEGIN
      IF sfFocused IN State THEN
        Color := GetColor(2);
      ELSE
        Color := GetColor(1);
      END;
      MoveChar( b, 0, ' ', Color, Size.X );
      Slice( buf, Data^, FirstPos, Size.X - 2 );
      MoveStr( b, 1, buf, Color );
      IF CanScroll(1) THEN
        MoveChar( b, Size.X-1, RightArrow, GetColor(4), 1 );
      END;
      IF sfSelected IN State THEN
        IF CanScroll(-1) THEN
          MoveChar( b, 0, LeftArrow, GetColor(4), 1 );
        END;
        l := SelStart - FirstPos;
        r := SelEnd - FirstPos;
        l := Max( 0, l );
        r := Min( Size.X - 2, r );
        IF l <  r THEN
          MoveChar( b, l+1, 0C, GetColor(3), r - l );
        END;
      END;
      WriteLine( 0, 0, Size.X, Size.Y, b );
      SetCursor( CurPos-FirstPos+1, 0);
    END Draw;

    VIRTUAL PROCEDURE GetData(VAR Rec : ARRAY OF BYTE);
    BEGIN
      Move( Data, ADR(Rec), LineDataSize() );
    END GetData;

    VIRTUAL PROCEDURE GetPalette(): PPalette;
    BEGIN
      RETURN ADR(CInputLine);
    END GetPalette;

    VIRTUAL PROCEDURE HandleEvent(VAR Event: TEvent);
    VAR
      delta, anchor, i : INTEGER;

      PROCEDURE MouseDelta( VAR Event : TEvent ) : INTEGER;
      VAR
        mouse : TPoint;
      BEGIN
        mouse := MakeLocal( Event.Where );
        IF mouse.X <= 0 THEN
          RETURN -1;
        ELSIF mouse.X >= Size.X - 1 THEN
          RETURN 1;
        ELSE
          RETURN 0;
        END;
      END MouseDelta;
  
      PROCEDURE MousePos( VAR Event : TEvent ) : INTEGER;
      VAR
        mouse : TPoint;
        pos : INTEGER;
      BEGIN
        mouse := MakeLocal( Event.Where );
        mouse.X := Max( mouse.X, 1 );
        pos := mouse.X + FirstPos - 1;
        pos := Max( pos, 0 );
        pos := Min( pos, Length(Data^) );
        RETURN pos;
      END MousePos;

      PROCEDURE DeleteSelect;
      BEGIN
        IF SelStart < SelEnd THEN
          Delete( Data^, SelStart, SelEnd-SelStart );
          CurPos := SelStart;
        END;
      END DeleteSelect;
  

    BEGIN
      TView.HandleEvent(Event);
      IF sfSelected IN State THEN
        IF evMouseDown IN Event.What THEN
          delta := MouseDelta(Event);
          IF CanScroll(delta) THEN
            REPEAT
              IF CanScroll(delta) THEN
                INC( FirstPos, delta);
                DrawView();
              END;
            UNTIL NOT MouseEvent( Event, EventTypes { evMouseAuto } ) ;
          ELSIF Event.Double THEN
            SelectAll(TRUE);
          ELSE
            anchor := MousePos(Event);
            REPEAT
              delta := MouseDelta(Event);
              IF (evMouseAuto IN Event.What) & CanScroll( delta ) THEN
                INC( FirstPos, delta);
              END;
              CurPos := MousePos(Event);
              IF CurPos < anchor THEN
                SelStart := CurPos;
                SelEnd := anchor;
              ELSE
                SelStart := anchor;
                SelEnd := CurPos;
              END;
              DrawView();
            UNTIL NOT MouseEvent(Event, EventTypes {evMouseMove, evMouseAuto});
          END;
          ClearEvent(Event);
        ELSIF evKeyDown IN Event.What THEN
          CASE CtrlToArrow(Event.KeyCode) OF
          | kbLeft:
              IF CurPos > 0 THEN
                DEC(CurPos);
                IF Shifts * Event.KState # KeyboardState{} THEN
                  IF SelStart = CurPos+1 THEN
                    SelStart := CurPos;
                  ELSE
                    SelEnd := CurPos;
                  END
                ELSE
                  SelStart := CurPos;
                  SelEnd := CurPos;
                END;
              END;
          | kbRight:
              IF CurPos < VAL(INTEGER, Length(Data^)) THEN
                INC(CurPos);
                IF Shifts * Event.KState # KeyboardState{} THEN
                  IF SelEnd = CurPos-1 THEN
                    SelEnd := CurPos;
                  ELSE
                    SelStart := CurPos;
                  END
                ELSE
                  SelStart := CurPos;
                  SelEnd := CurPos;
                END;
              END;
          | kbHome:
              CurPos :=  0;
              IF Shifts * Event.KState # KeyboardState{} THEN
                SelStart := 0;
              ELSE
                SelStart := CurPos;
                SelEnd := CurPos;
              END;
          | kbEnd:
              CurPos := Length(Data^);
              IF Shifts * Event.KState # KeyboardState{} THEN
                SelEnd := CurPos;
              ELSE
                SelStart := CurPos;
                SelEnd := CurPos;
              END;
          | kbBack:
              IF CurPos > 0 THEN
                Delete(Data^, CurPos-1, 1);
                DEC(CurPos);
                IF FirstPos > 0 THEN
                  DEC(FirstPos);
                END;
              END;
          | kbDel:
              IF SelStart = SelEnd THEN
                IF CurPos < VAL(INTEGER, Length(Data^)) THEN
                  SelStart := CurPos;
                  SelEnd := CurPos + 1;
                END;
              END;
              DeleteSelect();
          | kbIns: SetState( TViewStates { sfCursorIns },
                             NOT (sfCursorIns IN State));
          ELSE
            IF Event.CharCode >= ' ' THEN
              IF sfCursorIns IN State THEN
                Delete( Data^, CurPos, 1 );
              ELSE
                DeleteSelect();
              END;
              IF VAL(INTEGER, Length(Data^)) < MaxLen THEN
                IF FirstPos > CurPos THEN
                  FirstPos := CurPos;
                END;
                Insert(Data^, Event.CharCode, CurPos);
                INC(CurPos);
              END;
              SelStart := CurPos;
              SelEnd   := CurPos;
            ELSIF Event.CharCode = '' (* Ctrl-Y *) THEN
              Data^[0] := 0C;
              CurPos := 0;
            ELSE
              RETURN;
            END;
          END;
(*
          SelStart := 0;
          SelEnd := 0;
*)
          IF FirstPos > CurPos THEN
            FirstPos := CurPos;
          END;
          i := CurPos - Size.X + 3;
          IF FirstPos < i THEN
            FirstPos := i;
          END;
          DrawView;
          ClearEvent( Event );
        END;
      END;
    END HandleEvent;

    PROCEDURE SelectAll(Enable: BOOLEAN);
    BEGIN
      SelStart := 0;
      IF Enable THEN
        CurPos := Length(Data^);
        SelEnd := CurPos;
      ELSE
        CurPos := 0;
        SelEnd := 0;
      END;
      FirstPos := Max( 0, CurPos-Size.X+3 );
      DrawView;
    END SelectAll;

    VIRTUAL PROCEDURE SetData(VAR Rec : ARRAY OF BYTE);
    BEGIN
      Move( ADR(Rec), Data, LineDataSize()-1 );
      Data^[LineDataSize()-1] := 0C;
      SelectAll( TRUE );
    END SetData;

    VIRTUAL PROCEDURE SetState( AState: TViewStates;
                                Enable: BOOLEAN);
    BEGIN
      TView.SetState( AState, Enable );
      IF ( AState = TViewStates { sfSelected } ) OR
         ( AState = TViewStates { sfActive } ) & (sfSelected IN State)
      THEN
        SelectAll( Enable );
      END;
    END SetState;

    PROCEDURE Store(VAR S: TStream);
    BEGIN
      TView.Store( S );
      S.Wr(MaxLen);
      S.Wr(CurPos);
      S.Wr(FirstPos);
      S.Wr(SelStart);
      S.Wr(SelEnd);
      S.WriteStr( Data );
    END Store;

  BEGIN
    CurPos := 0;
    FirstPos := 0;
    SelStart := 0;
    SelEnd := 0;
   END TInputLine;


END InputLines.