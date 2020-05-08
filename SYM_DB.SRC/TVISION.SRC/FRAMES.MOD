(*%T TV_NoDebug*)
(*# debug(vid=>off)*)
(*%E*)
(*%T InOneSegment *)
(*#call(seg_name=>TV)*)
(*%E*)
IMPLEMENTATION MODULE Frames;

FROM Views IMPORT
  TViewGrowMode, TViewGrowModes, TViewState, TViewStates, PPalette,
  TViewDragMode, TViewDragModes;
FROM Drivers IMPORT
  TEvent, EventType, EventTypes, TDrawBuffer, MoveChar, PutChar, CStrLen,
  MoveBuf, MoveCStr;
FROM Texts IMPORT
  FrameChars, CloseIcon, ZoomIcon, UnZoomIcon, DragIcon, CFrame;
FROM Winds IMPORT
  PWindow, WindowFlags, WindowFlag, wnNoNumber;
FROM Commands IMPORT
  cmClose, cmZoom;

  CLASS IMPLEMENTATION TFrame;

    PROCEDURE Init(VAR Bounds: Objects.TRect);
    BEGIN
      TView.Init( Bounds );
      GrowMode := TViewGrowModes { gfGrowHiX, gfGrowHiY };
      INCL(EventMask, evBroadcast);
    END Init;

    VIRTUAL PROCEDURE Draw;
    VAR
      cFrame, cTitle : CARDINAL;
      f, i, l, width : INTEGER;
      b : TDrawBuffer;
      title : PTitleStr;
      MinSize, MaxSize : Objects.TPoint;

      PROCEDURE FrameLine( n : CARDINAL );
      BEGIN
        MoveChar( b, 0,        FrameChars[n],   cFrame, 1 );
        MoveChar( b, 1,        FrameChars[n+1], cFrame, Size.X-2 );
        MoveChar( b, Size.X-1, FrameChars[n+2], cFrame, 1 );
      END FrameLine;

    BEGIN
      IF NOT (sfActive IN State ) THEN
        cFrame := 00101H;
        cTitle := 00002H;
        f := 1;
      ELSE
        IF sfDragging IN State THEN
          cFrame := 00505H;
          cTitle := 00005H;
          f := 1;
        ELSE
          cFrame := 00503H;
          cTitle := 00004H;
          f := 24;
        END;
      END;
      cFrame := GetColor(cFrame);
      cTitle := GetColor(cTitle);

      width := Size.X;
      l := width - 10;

      IF WindowFlags { wfClose, wfZoom} * PWindow(Owner)^.Flags # WindowFlags {} THEN
        DEC(l, 6);
      END;
      FrameLine( f );
      IF (PWindow(Owner)^.Number # wnNoNumber) & (PWindow(Owner)^.Number < 10) THEN
        DEC(l, 4);
        IF wfZoom IN PWindow(Owner)^.Flags THEN
          i := 7;
        ELSE
          i := 3;
        END;
        PutChar( b, width-i, CHR( PWindow(Owner)^.Number + ORD('0') ) );
      END;
      IF Owner # NIL THEN
        title := PWindow(Owner)^.GetTitle();
        IF title # NIL THEN
          l := Objects.Min( CStrLen(title^), width - 10 );
          l := Objects.Max( l, 0 );
          i := (width - l) >> 1;
          PutChar( b, i-1, ' ' );
          MoveBuf( b, i, title^, cTitle, l );
          PutChar( b, i+l, ' ' );
        END;
      END;
      IF sfActive IN State THEN
        IF wfClose IN PWindow(Owner)^.Flags THEN
           MoveCStr( b, 2, CloseIcon, cFrame );
        END;
        IF wfZoom IN PWindow(Owner)^.Flags THEN
          Owner^.SizeLimits( MinSize, MaxSize );
          IF Owner^.Size = MaxSize THEN
            MoveCStr( b, width-5, UnZoomIcon, cFrame );
          ELSE
            MoveCStr( b, width-5, ZoomIcon, cFrame );
          END;
        END;
      END;
      WriteLine( 0, 0, Size.X, 1, b );
      FOR i := 1 TO Size.Y - 2 DO
        FrameLine( f + 10 );
        WriteLine( 0, i, Size.X, 1, b );
      END;
      FrameLine( f +  5 );
      IF sfActive IN State THEN
        IF wfGrow IN PWindow(Owner)^.Flags THEN
          MoveCStr( b, width-2, DragIcon, cFrame );
        END;
      END;
      WriteLine( 0, Size.Y - 1, Size.X, 1, b );
    END Draw;

    VIRTUAL PROCEDURE GetPalette(): PPalette;
    BEGIN
      RETURN ADR(CFrame);
    END GetPalette;

    VIRTUAL PROCEDURE HandleEvent(VAR Event: Drivers.TEvent);
    VAR
      Mouse : Objects.TPoint;

      PROCEDURE DragWindow( VAR Event : TEvent; Mode : TViewDragModes);
      VAR
        Limits : Objects.TRect;
        Min, Max : Objects.TPoint;
      BEGIN
        Limits := Owner^.Owner^.GetExtent();
        Owner^.SizeLimits( Min, Max );
        Owner^.DragView( Event, Owner^.DragMode + Mode, Limits, Min, Max );
        ClearEvent( Event );
      END DragWindow;
  
    BEGIN
      TView.HandleEvent(Event);
      IF (evMouseDown IN Event.What) & (sfActive IN State) THEN
        Mouse := MakeLocal( Event.Where );
        IF Mouse.Y = 0 THEN
          IF (wfClose IN PWindow(Owner)^.Flags) & (Mouse.X >= 2) & (Mouse.X <= 4 ) THEN
             Event.What := EventTypes { evCommand };
             Event.Command := cmClose;
             Event.InfoPtr := Owner;
             PutEvent( Event );
             ClearEvent( Event );
          ELSE
            IF (wfZoom IN PWindow(Owner)^.Flags) &
               ((Mouse.X >= Size.X - 5) & (Mouse.X <= Size.X - 3) OR Event.Double)
            THEN
              Event.What := EventTypes { evCommand };
              Event.Command := cmZoom;
              Event.InfoPtr := Owner;
              PutEvent( Event );
              ClearEvent( Event );
            ELSE
              IF wfMove IN PWindow(Owner)^.Flags THEN
                DragWindow( Event, TViewDragModes { dmDragMove });
              END;
            END;
          END;
        ELSE
          IF ( Mouse.X >= Size.X - 2) & (Mouse.Y >= Size.Y - 1 ) THEN
            IF wfGrow IN PWindow(Owner)^.Flags THEN
              DragWindow( Event, TViewDragModes { dmDragGrow } );
            END;
          END;
        END;
      END;
    END HandleEvent;

    VIRTUAL PROCEDURE SetState( AState: TViewStates;
                                Enable: BOOLEAN);
    BEGIN
      TView.SetState( AState, Enable );
      IF AState * TViewStates { sfActive, sfDragging } # TViewStates{} THEN
        DrawView();
      END;
    END SetState;

  BEGIN
  END TFrame;


END Frames.