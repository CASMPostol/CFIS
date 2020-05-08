(*%T TV_NoDebug*)
(*# debug(vid=>off)*)
(*%E*)
(*%T InOneSegment *)
(*#call(seg_name=>TV)*)
(*%E*)
IMPLEMENTATION MODULE Buttons;

FROM Objects IMPORT
  TRect, TPoint, NewStr, DisposeStr;
FROM Views IMPORT
  TView, TViewOption, TViewOptions, TViewState, TViewStates, CommandEnabled,
  ShowMarkers, PPalette, Message, TGroupPhase;
FROM Commands IMPORT
  cmDefault, cmGrabDefault, cmReleaseDefault, cmCommandSetChanged,
  cmRecordHistory;
FROM Storage IMPORT
  ALLOCATE, DEALLOCATE;
FROM Str IMPORT
  Copy, Length;
FROM Streams IMPORT
  TStream;
FROM Drivers IMPORT
  EventType, EventTypes, TDrawBuffer, CStrLen, MoveCStr, PutChar, MoveChar,
  PutAttribute, TEvent, HotKey, GetAltCode;
FROM Texts IMPORT
  SpecialChars, ButtonShadows, CButton, ButtonMarkers;


  CLASS IMPLEMENTATION TButton;

    PROCEDURE Init(VAR Bounds: TRect;
                       ATitle: ARRAY OF CHAR;
                       ACommand: CARDINAL;
                       AFlags: ButtonFlags);
    BEGIN
      TView.Init( Bounds );
      Flags := AFlags;
      AmDefault := bfDefault IN Flags;
      Title := NewStr(ATitle);
      Command := ACommand;
      Options := Options + TViewOptions{ ofSelectable, ofFirstClick,
                                         ofPreProcess, ofPostProcess };
      INCL(EventMask, evBroadcast);
      IF NOT CommandEnabled( VAL(SHORTCARD, ACommand) ) THEN
        INCL(State, sfDisabled);
      END;
    END Init;

    PROCEDURE Load(VAR S: TStream);
    BEGIN
      TView.Load( S );
      Title := S.ReadStr( 256 );
      S.Rd(Command);
      S.Rd(Flags);
      S.Rd(AmDefault);
      IF CommandEnabled( VAL(SHORTCARD, Command ) ) THEN
        EXCL(State, sfDisabled);
      ELSE
        INCL(State, sfDisabled);
      END;
    END Load;

    VIRTUAL PROCEDURE Done;
    BEGIN
      DisposeStr(Title);
      TView.Done;
    END Done;

    VIRTUAL PROCEDURE Draw;
    BEGIN
      DrawState(FALSE);
    END Draw;

    PROCEDURE DrawState(Down: BOOLEAN);
    VAR
      cButton, cShadow : CARDINAL;
      ch  : CHAR;
      i, s, T, y   : INTEGER;
      b : TDrawBuffer;

      PROCEDURE DrawTitle( VAR b : TDrawBuffer;
                               s, i : INTEGER;
                               cButton : CARDINAL;
                               Down : BOOLEAN);
      VAR
        l, scOff : INTEGER;
      BEGIN
        IF bfLeftJust IN Flags THEN
          l := 1;
        ELSE
          l := (s - VAL(INTEGER, CStrLen(Title^)) - 1) DIV 2;
          IF l < 1 THEN
            l := 1;
          END;
        END;
        MoveCStr( b, i+l, Title^, cButton );
        IF ShowMarkers & NOT Down THEN
          IF sfSelected IN State THEN
            scOff := 0;
          ELSIF AmDefault THEN
            scOff := 2;
          ELSE
            scOff := 4;
          END;
          PutChar( b, 0, SpecialChars[scOff] );
          PutChar( b, s, SpecialChars[scOff+1] );
        END;
      END DrawTitle;
  
    BEGIN
      IF sfDisabled IN State THEN
        cButton := GetColor(0404H);
      ELSE
        cButton := GetColor(0501H);
        IF sfActive IN State THEN
          IF sfSelected IN State THEN
            cButton := GetColor(0703H);
          ELSIF AmDefault THEN
            cButton := GetColor(0602H);
          END;
        END;
      END;
      cShadow := GetColor(8);
      s := Size.X-1;
      T := Size.Y DIV 2 - 1;
      FOR y := 0 TO Size.Y-2 DO
        MoveChar( b, 0, ' ', cButton, Size.X );
        PutAttribute( b, 0, cShadow );
        IF Down THEN
          PutAttribute( b, 1, cShadow );
          ch :=  ' ';
          i := 2;
        ELSE
          PutAttribute( b, s, cShadow );
          IF ShowMarkers THEN
            ch := ' ';
          ELSE
            IF y = 0 THEN
              PutChar( b, s, ButtonShadows[0] );
            ELSE
              PutChar( b, s, ButtonShadows[1] );
            END;
            ch := ButtonShadows[2];
          END;
          i :=  1;
        END;
        IF ( y = T ) & (Title # NIL) THEN
          DrawTitle( b, s, i, cButton, Down );
        END;
        IF ShowMarkers & NOT Down THEN
          PutChar( b, 1, ButtonMarkers[0] );
          PutChar( b, s-1, ButtonMarkers[1] );
        END;
        WriteLine( 0, y, Size.X, 1, b );
      END;
      MoveChar( b, 0, ' ', cShadow, 2 );
      MoveChar( b, 2, ch, cShadow, s-1 );
      WriteLine( 0, Size.Y-1, Size.X, 1, b );
    END DrawState;

    VIRTUAL PROCEDURE GetPalette(): PPalette;
    BEGIN
      RETURN ADR(CButton);
    END GetPalette;

    VIRTUAL PROCEDURE HandleEvent(VAR Event: TEvent);
    VAR
      mouse : TPoint;
      clickRect : TRect;
      Down : BOOLEAN;
      c : CHAR;
    BEGIN
      clickRect := GetExtent();
      INC(clickRect.A.X);
      DEC(clickRect.B.X);
      DEC(clickRect.B.Y);

      IF Event.What = EventTypes { evMouseDown } THEN
        mouse := MakeLocal( Event.Where );
        IF NOT clickRect.Contains(mouse) THEN
          ClearEvent( Event);
        END;
      END;
      TView.HandleEvent(Event);

      IF evMouseDown IN Event.What THEN
        INC(clickRect.B.X);
        Down := FALSE;
        REPEAT
          mouse := MakeLocal( Event.Where );
          IF Down # clickRect.Contains( mouse ) THEN
            Down := NOT Down;
            DrawState( Down );
          END;
        UNTIL NOT MouseEvent( Event, EventTypes { evMouseMove } );
        IF Down THEN
          Press();
          DrawState( FALSE );
        END;
        ClearEvent( Event);
      ELSIF evKeyDown IN Event.What THEN
        c := HotKey( Title^ );
        IF (Event.KeyCode = GetAltCode(c)) OR
           (Owner^.Phase = phPostProcess) & (c # 0C) & (CAP(Event.CharCode)=c) OR
           (sfFocused IN State) & (Event.CharCode = ' ')
        THEN
          Press();
          ClearEvent( Event);
        END;
      ELSIF evBroadcast IN Event.What THEN
        CASE Event.Command OF
        | cmDefault:
            IF AmDefault THEN
              Press();
              ClearEvent(Event);
            END;
        | cmGrabDefault, cmReleaseDefault:
            IF bfDefault IN Flags THEN
              AmDefault := Event.Command = cmReleaseDefault;
              DrawView();
            END;
        | cmCommandSetChanged:
            SetState(TViewStates{sfDisabled}, NOT CommandEnabled(VAL(SHORTCARD, Command)));
            DrawView();
        ELSE
        END;
      END;
    END HandleEvent;

    PROCEDURE MakeDefault(Enable: BOOLEAN);
    VAR
      Dummy : ADDRESS;
      cmd : CARDINAL;
    BEGIN
      IF NOT(bfDefault  IN Flags) THEN
        IF Enable THEN
          cmd := cmGrabDefault;
        ELSE
          cmd := cmReleaseDefault;
        END;
        Dummy := Message( Owner,
                          EventTypes{ evBroadcast },
                          cmd,
                          ADR(SELF));
        AmDefault := Enable;
        DrawView();
      END;
    END MakeDefault;

    VIRTUAL PROCEDURE Press;
    VAR
      Dummy : ADDRESS;
      e : TEvent;
    BEGIN
      Dummy := Message( Owner, EventTypes{evBroadcast}, cmRecordHistory, NIL );
      IF bfBroadcast IN Flags THEN
        Dummy := Message( Owner, EventTypes{evBroadcast}, Command, ADR(SELF));
      ELSE
        e.What := EventTypes{evCommand};
        e.Command := Command;
        e.InfoPtr := ADR(SELF);
        PutEvent( e );
      END;
    END Press;

    VIRTUAL PROCEDURE SetState( AState: TViewStates;
                                Enable: BOOLEAN);
    BEGIN
      TView.SetState(AState, Enable);
      IF (sfSelected IN AState) OR (sfActive IN AState) THEN
        DrawView;
      END;
      IF sfFocused IN AState THEN
        MakeDefault( Enable );
      END;
    END SetState;

    PROCEDURE Store(VAR S: TStream);
    BEGIN
      TView.Store( S );
      S.WriteStr( Title );
      S.Wr(Command);
      S.Wr(Flags);
      S.Wr(AmDefault);
    END Store;

  BEGIN
  END TButton;


END Buttons.