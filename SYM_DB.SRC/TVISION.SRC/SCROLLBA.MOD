(*%T TV_NoDebug*)
(*# debug(vid=>off)*)
(*%E*)
(*%T InOneSegment *)
(*#call(seg_name=>TV)*)
(*%E*)
IMPLEMENTATION MODULE ScrollBars;

FROM Views IMPORT
  TViewGrowMode, TViewGrowModes, PPalette, Message, TViewState, TViewStates;
FROM Lib IMPORT
  FastMove;
FROM Texts IMPORT
  VChars, HChars, CScrollBar;
FROM Drivers IMPORT
  EventType, EventTypes, TDrawBuffer, MoveChar, CtrlToArrow, kbLeft, kbRight,
  kbCtrlLeft, kbCtrlRight, kbHome, kbEnd, kbUp, kbDown, kbPgDn, kbPgUp,
  kbCtrlPgUp, kbCtrlPgDn;
FROM Commands IMPORT
  cmScrollBarClicked, cmScrollBarChanged;

  CLASS IMPLEMENTATION TScrollBar;

    PROCEDURE Init(VAR Bounds: Objects.TRect); (* Constructor *)
    BEGIN
      TView.Init( Bounds );
      IF Size.X = 1 THEN
        GrowMode := TViewGrowModes { gfGrowLoX, gfGrowHiX, gfGrowHiY };
        FastMove(ADR(VChars), ADR(Chars), SIZE(Chars));
      ELSE
        GrowMode := TViewGrowModes { gfGrowLoY, gfGrowHiX, gfGrowHiY };
        FastMove(ADR(HChars), ADR(Chars), SIZE(Chars));
      END;
    END Init;

    PROCEDURE Load(VAR S: Streams.TStream);    (* Constructor *)
    BEGIN
      TView.Load( S );
      S.Rd(Value);
      S.Rd(MinVal);
      S.Rd(MaxVal);
      S.Rd(PgStep);
      S.Rd(ArStep);
      S.Rd(Chars);
    END Load;

    PROCEDURE DrawPos( Pos : CARDINAL );
    VAR
      b : TDrawBuffer;
      _s : CARDINAL;
    BEGIN
      _s := GetSize() - 1;
      MoveChar( b, 0, Chars[0], GetColor(2), 1 );
      IF MaxVal = MinVal THEN
        MoveChar( b, 1, Chars[4], GetColor(1), _s-1 );
      ELSE
        MoveChar( b, 1, Chars[2], GetColor(1), _s-1 );
        MoveChar( b, Pos, Chars[3], GetColor(3), 1 );
      END;
      MoveChar( b, _s, Chars[1], GetColor(2), 1 );
      WriteBuf( 0, 0, Size.X, Size.Y, FarADR(b) );
    END DrawPos;

    PROCEDURE GetPos():CARDINAL;
    VAR
      r : CARDINAL;
    BEGIN
      r := MaxVal - MinVal;
      IF r = 0 THEN
        RETURN 1;
      ELSE
        RETURN VAL( CARDINAL, (VAL(LONGCARD, Value-MinVal) *
                               VAL(LONGCARD, GetSize()-3) +
                               VAL(LONGCARD, r >> 1)
                              ) DIV VAL(LONGCARD, r) + 1);
      END;
    END GetPos;

    VIRTUAL PROCEDURE Draw;
    BEGIN
      DrawPos(GetPos());
    END Draw;

    VIRTUAL PROCEDURE GetPalette(): PPalette;
    BEGIN
      RETURN ADR(CScrollBar);
    END GetPalette;

    PROCEDURE GetSize() : CARDINAL;
    VAR
      _s : CARDINAL;
    BEGIN
      IF Size.X = 1 THEN
        _s := Size.Y;
      ELSE
        _s := Size.X;
      END;
      RETURN Objects.Max( 3, _s );
    END GetSize;

     PROCEDURE GetPartCode() : ScrollBarPart;
     VAR
       part : ScrollBarPart;
       mark : CARDINAL;
     BEGIN
      part := sbNothing;
      IF Extent.Contains(Mouse) THEN
        IF Size.X = 1 THEN
          mark := Mouse.Y;
        ELSE
          mark := Mouse.X;
        END;
        IF mark = p THEN
          part := sbIndicator;
        ELSE
          IF mark < 1 THEN
            part := sbLeftArrow;
          ELSIF mark < p THEN
            part := sbPageLeft;
          ELSIF mark < s THEN
            part := sbPageRight;
          ELSE
            part := sbRightArrow;
          END;
          IF Size.X = 1 THEN
            INC ( part, 4 );
          END;
        END;
      END;
      RETURN part;
    END GetPartCode;

    VIRTUAL PROCEDURE HandleEvent(VAR Event: Drivers.TEvent);
    VAR
      Tracking : BOOLEAN;
      i         : CARDINAL;
      sc        : INTEGER;
      clickPart : ScrollBarPart;
      Dummy : ADDRESS;
    BEGIN
      TView.HandleEvent(Event);
      IF evMouseDown IN Event.What THEN
        Dummy := Message( Owner,
                          EventTypes{ evBroadcast },
                          cmScrollBarClicked,
                          ADR(SELF)); (* Clicked() *)
        Mouse := MakeLocal( Event.Where );
        Extent := GetExtent();
        Extent.Grow(1, 1);
        p := GetPos();
        s := GetSize() - 1;
        clickPart := GetPartCode();
        IF clickPart # sbIndicator THEN
          REPEAT
            Mouse := MakeLocal( Event.Where );
            IF GetPartCode() = clickPart THEN
              SetValue(Value + ScrollStep(clickPart) );
            END;
          UNTIL NOT MouseEvent(Event, EventTypes{ evMouseAuto });
        ELSE
          REPEAT
            Mouse := MakeLocal( Event.Where );
            Tracking := Extent.Contains(Mouse);
            IF Tracking THEN
              IF Size.X = 1 THEN
                i := Mouse.Y;
              ELSE
                i := Mouse.X;
              END;
              i := Objects.Max( i, 1 );
              i := Objects.Min( i, s-1 );
            ELSE
              i := GetPos();
            END;
            IF i # p THEN
              DrawPos(i);
              p := i;
            END;
          UNTIL NOT MouseEvent(Event, EventTypes{ evMouseMove }) ;
          IF Tracking & ( s > 2 ) THEN
            DEC ( s, 2);
            SetValue(VAL ( CARDINAL, (VAL( LONGCARD, p-1 ) *
                                      VAL( LONGCARD, MaxVal-MinVal ) +
                                      VAL( LONGCARD, s >> 1 )
                                     ) DIV LONGCARD (s) ) + VAL( CARDINAL, MinVal)
                    );
(*            SetValue(LongDiv(LongMul(P - 1, Max -  Min) +  S >>  1, S) +  MIN); *)
          END;
        END;
        ClearEvent(Event);
      END;
      IF evKeyDown IN Event.What THEN
        IF sfVisible IN State THEN
          clickPart := sbIndicator;
          IF Size.Y = 1 THEN
            CASE CtrlToArrow(Event.KeyCode) OF
            | kbLeft:      clickPart := sbLeftArrow;
            | kbRight:     clickPart := sbRightArrow;
            | kbCtrlLeft:  clickPart := sbPageLeft;
            | kbCtrlRight: clickPart := sbPageRight;
            | kbHome:      i := MinVal;
            | kbEnd:       i := MaxVal;
            ELSE
              RETURN;
            END;
          ELSE
            CASE CtrlToArrow(Event.KeyCode) OF
            | kbUp:       clickPart := sbUpArrow;
            | kbDown:     clickPart := sbDownArrow;
            | kbPgUp:     clickPart := sbPageUp;
            | kbPgDn:     clickPart := sbPageDown;
            | kbCtrlPgUp: i := MinVal;
            | kbCtrlPgDn: i := MaxVal;
            ELSE
              RETURN;
            END;
          END;
          Dummy := Message( Owner,
                            EventTypes{ evBroadcast },
                            cmScrollBarClicked,
                            ADR(SELF)); (* Clicked *)
          IF clickPart # sbIndicator THEN
            sc := ScrollStep(clickPart);
            IF (sc < 0 ) & ( ABS( sc ) > Value ) THEN
              i := 0;
            ELSE
              i := Value + sc;
            END;
          END;
          SetValue(i);
          ClearEvent(Event);
        END;
      END;
    END HandleEvent;

    VIRTUAL PROCEDURE ScrollDraw;
    VAR
      Dummy : ADDRESS;
    BEGIN
      Dummy := Message( Owner,
                        EventTypes{evBroadcast},
                        cmScrollBarChanged,
                        ADR(SELF));
    END ScrollDraw;

    VIRTUAL PROCEDURE ScrollStep(Part: ScrollBarPart): INTEGER;
    TYPE
      SP = SET OF ScrollBarPart;
    VAR
      Step : INTEGER;
    BEGIN
      IF NOT ( Part IN SP { sbPageLeft, sbPageRight, sbPageUp, sbPageDown } ) THEN
        Step := ArStep;
      ELSE
        Step := PgStep;
      END;
      IF NOT (Part IN SP { sbRightArrow, sbPageRight, sbDownArrow, sbPageDown }) THEN
        RETURN -Step;
      ELSE
        RETURN Step;
      END;
    END ScrollStep;

    PROCEDURE SetParams(AValue, AMin, AMax, APgStep, AArStep: INTEGER);
    VAR
      sValue : INTEGER;
    BEGIN
      AMax := Objects.Max( AMax, AMin );
      AValue := Objects.Max( AMin, AValue );
      AValue := Objects.Min( AMax, AValue );
      sValue := Value;
      IF ( sValue # AValue) OR (MinVal # AMin) OR (MaxVal # AMax ) THEN
        Value := AValue;
        MinVal := AMin;
        MaxVal := AMax;
        DrawView();
        IF sValue # AValue THEN
          ScrollDraw();
        END;
      END;
      PgStep := APgStep;
      ArStep := AArStep;
    END SetParams;

    PROCEDURE SetRange(AMin, AMax: INTEGER);
    BEGIN
      SetParams( Value, AMin, AMax, PgStep, ArStep );
    END SetRange;

    PROCEDURE SetStep(APgStep, AArStep: INTEGER);
    BEGIN
      SetParams( Value, MinVal, MaxVal, APgStep, ArStep );
    END SetStep;

    PROCEDURE SetValue(AValue: INTEGER);
    BEGIN
      SetParams( AValue, MinVal, MaxVal, PgStep, ArStep );
    END SetValue;

    PROCEDURE Store(VAR S: Streams.TStream);
    BEGIN
      TView.Store( S );
      S.Wr(Value);
      S.Wr(MinVal);
      S.Wr(MaxVal);
      S.Wr(PgStep);
      S.Wr(ArStep);
      S.Wr(Chars);
    END Store;

  BEGIN
    Value  := 0;
    MinVal := 0;
    MaxVal := 0;
    PgStep := 1;
    ArStep := 1;
    s := 0;
    p := 0;
    Extent.Assign(0,0,0,0);
  END TScrollBar;


END ScrollBars.