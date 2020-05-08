(*%T TV_NoDebug*)
(*# debug(vid=>off)*)
(*%E*)
(*%T InOneSegment *)
(*#call(seg_name=>TV)*)
(*%E*)
IMPLEMENTATION MODULE Labels;

FROM Objects IMPORT
  TRect;
FROM Views IMPORT
  PView, TViewState, TViewOption, TViewOptions, ShowMarkers, PPalette,
  TGroupPhase;
FROM Drivers IMPORT
  TEvent, EventType, EventTypes, TDrawBuffer, MoveCStr, MoveChar, PutChar,
  HotKey, GetAltCode;
FROM Streams IMPORT
  TStream;
FROM Texts IMPORT
  CLabel, SpecialChars;
FROM Commands IMPORT
  cmReceivedFocus, cmReleasedFocus;

  CLASS IMPLEMENTATION TLabel;

    PROCEDURE Init(VAR Bounds: TRect;
                       AText: ARRAY OF CHAR;
                       ALink: PView);
    BEGIN
      TStaticText.Init( Bounds, AText );
      Link := ALink;
      Light := FALSE;
      Options := Options + TViewOptions { ofPreProcess, ofPostProcess };
      INCL( EventMask, evBroadcast);
    END Init;

    PROCEDURE Load(VAR S: TStream);
    BEGIN
      TStaticText.Load( S );
      Link^.Load ( S );
    END Load;

    VIRTUAL PROCEDURE Draw;
    VAR
      color : CARDINAL;
      b : TDrawBuffer;
      scOff : SHORTCARD;
    BEGIN
      IF Light THEN
        color := GetColor(0402H);
        scOff := 0;
      ELSE
        color := GetColor(0301H);
        scOff := 4;
      END;
      MoveChar( b, 0, ' ', color, Size.X );
      IF Text # NIL THEN
        MoveCStr( b, 1, Text^, color );
      END;
      IF ShowMarkers THEN
        PutChar( b, 0, SpecialChars[ORD(scOff)] );
      END;
      WriteLine( 0, 0, Size.X, 1, b );
    END Draw;

    VIRTUAL PROCEDURE GetPalette(): PPalette;
    BEGIN
      RETURN ADR(CLabel);
    END GetPalette;

    VIRTUAL PROCEDURE HandleEvent(VAR Event: TEvent);
    VAR
      c : CHAR;
    BEGIN
      TStaticText.HandleEvent(Event);
      IF Event.What = EventTypes { evMouseDown } THEN
        IF Link # NIL THEN
          Link^.Select;
        END;
        ClearEvent( Event );
      ELSIF Event.What = EventTypes { evKeyDown } THEN
        c := HotKey( Text^ );
        IF (GetAltCode(c) = Event.KeyCode) OR
           (c # 0C) & (Owner^.Phase = phPostProcess) & (CAP(Event.CharCode) = c )
        THEN
          IF Link # NIL THEN
            Link^.Select;
          END;
          ClearEvent( Event );
        END;
      ELSIF ( Event.What = EventTypes { evBroadcast } ) &
            ( ( Event.Command = cmReceivedFocus ) OR (Event.Command = cmReleasedFocus ))
      THEN
        Light := sfFocused IN Link^.State;
        DrawView;
      END;
    END HandleEvent;

    PROCEDURE Store(VAR S: TStream);
    BEGIN
      TStaticText.Store( S );
      Link^.Store ( S );
    END Store;

  BEGIN
  END TLabel;


END Labels.