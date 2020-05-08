(*%T TV_NoDebug*)
(*# debug(vid=>off)*)
(*%E*)
(*%T InOneSegment *)
(*#call(seg_name=>TV)*)
(*%E*)
IMPLEMENTATION MODULE Winds;

FROM Views IMPORT
  TViewState, TViewStates, TViewOption, TViewOptions, PPalette, PView,
  TViewGrowMode, TViewGrowModes, TViewDragMode, TViewDragModes,
  TCommandSet, EnableCommands, DisableCommands, MinWinSize, MaxViewWidth;
FROM Storage IMPORT
  ALLOCATE, DEALLOCATE;
FROM Str IMPORT
  Copy;
FROM Commands IMPORT
  cmClose, cmResize, cmCancel, cmZoom, cmSelectWindowNum, cmNext, cmPrev;
FROM Texts IMPORT
  CBlueWindow, CGrayWindow, CCyanWindow, FrameChars, CloseIcon, ZoomIcon,
  UnZoomIcon, DragIcon, CFrame, InitFrame;
FROM Drivers IMPORT
  EventType, EventTypes, kbTab, kbShiftTab, TEvent, TDrawBuffer, MoveChar,
  PutChar, CStrLen, MoveBuf, MoveCStr, MoveStr;
FROM ScrollBars IMPORT
  ScrollBarOptions, ScrollBarOption, PScrollBar;
FROM Lib IMPORT
  Fill;
FROM Objects IMPORT
  NewStr;


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

      PROCEDURE FrameLine( y, n      : INTEGER;
                           Color     : CARDINAL );
      VAR
        FrameMask : ARRAY[ 0..MaxViewWidth-1 ] OF CHAR;
      TYPE
        A2 = ARRAY [ 0..1 ] OF SHORTCARD;
        A5 = ARRAY [ 0..4 ] OF SHORTCARD;
        A6 = ARRAY [ 0..5 ] OF SHORTCARD;

        INLINE PROCEDURE Xor( Val : INTEGER ) : INTEGER =
              A2( 032H, 0C4H (* xor al,ah *));

(*#save, call(reg_param=>(si, ds, ax, cx))*)
        INLINE PROCEDURE Or(adr : FarADDRESS; byte : CARDINAL; ile : CARDINAL )=
           A5( 008H, 024H, (* l:or [si], ah *)
               046H,       (*   inc si      *)
               0E2H, 0FBH  (*   loop l      *));
(*#restore*)
(*#save, call(reg_param=>(di, es, si, bx, ds, ax, cx))*)
        INLINE PROCEDURE Xlat( Buff : FarADDRESS;
                               Mask : NearADDRESS;
                               Table : FarADDRESS;
                               Count : CARDINAL;
                               Color : CARDINAL)=
           A6( 036H,       (* l:seg ss *)
               0ACH,       (*   lodsb  *)
               0D7H,       (*   xlat   *)
               0ABH,       (*   stosw  *)
               0E2H, 0FAH  (*   loop l *));
(*#restore*)

      VAR
        tmpY, pos, Sx, Ex, col : INTEGER;
        v : PView;
      LABEL
        NextViewL;
      BEGIN
        FrameMask[0] := InitFrame[n];
        Fill( ADR( FrameMask[1] ), Size.X-2, InitFrame[n+1]);
        FrameMask[ Size.X-1 ] := InitFrame[n+2];
        pos := Size.X-1;
        v := Owner^.Last;
        LOOP
          NextViewL:
          v := v^.Next;
          IF v = ADR( SELF ) THEN
            EXIT;
          END;
          WITH v^ DO
            IF (ofFramed IN Options) & (sfVisible IN State) THEN
              tmpY := y-Origin.Y;
              IF tmpY < 0 THEN
                IF tmpY # -1 THEN
                  GOTO NextViewL;
                END;
                col := 0A06H;
              ELSE
                IF tmpY > Size.Y THEN
                  GOTO NextViewL;
                ELSIF tmpY < Size.Y THEN
                  col := 0005H;
                ELSE
                  col := 0A03H;
                END;
              END;
              Sx := Origin.X;
              Ex := Origin.X+Size.X;
              IF Sx < 1 THEN
                Sx := 1;
              END;
              IF Ex > pos THEN
                Ex := pos;
              END;
              IF Sx < Ex THEN
(*#save, option(bit_opr=>on)*)
                FrameMask[Sx-1] := FrameMask[Sx-1] OR VAL(CHAR, col MOD 100H);
                col := Xor(col);
                FrameMask[Ex] := FrameMask[Ex] OR VAL(CHAR, col MOD 100H);
(*#restore*)
                IF col DIV 100H # 0 THEN
                  Or( FarADR( FrameMask[Sx]), col, Ex-Sx );
                END;
              END;
            END;
          END;
        END;
        Xlat( FarADR( b ),
              NearADR( FrameMask ),
              FarADR( FrameChars ),
              Color << 8,
              Size.X );
      END FrameLine;

    BEGIN
      IF NOT (sfActive IN State ) THEN
        cFrame := 00101H;
        cTitle := 00002H;
        f := 0;
      ELSIF sfDragging IN State THEN
        cFrame := 00505H;
        cTitle := 00005H;
        f := 0;
      ELSE
        cFrame := 00503H;
        cTitle := 00004H;
        f := 9;
      END;
      cFrame := GetColor(cFrame);
      cTitle := GetColor(cTitle);

      width := Size.X;
      l := width - 10;

      IF WindowFlags { wfClose, wfZoom} * (Owner::PWindow)^.Flags # WindowFlags {} THEN
        DEC(l, 6);
      END;
      FrameLine( 0, f, cFrame );
      IF ((Owner::PWindow)^.Number # wnNoNumber) & ((Owner::PWindow)^.Number < 10) THEN
        DEC(l, 4);
        IF wfZoom IN (Owner::PWindow)^.Flags THEN
          i := 7;
        ELSE
          i := 3;
        END;
        PutChar( b, width-i, CHR( (Owner::PWindow)^.Number + ORD('0') ) );
      END;
      IF Owner # NIL THEN
        title := (Owner::PWindow)^.GetTitle();
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
        IF wfClose IN (Owner::PWindow)^.Flags THEN
           MoveCStr( b, 2, CloseIcon, cFrame );
        END;
        IF wfZoom IN (Owner::PWindow)^.Flags THEN
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
        FrameLine( i, f + 3, cFrame );
        WriteLine( 0, i, Size.X, 1, b );
      END;
      FrameLine( Size.Y-1, f +  6, cFrame );
      IF sfActive IN State THEN
        IF wfGrow IN (Owner::PWindow)^.Flags THEN
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
          ELSIF (wfZoom IN PWindow(Owner)^.Flags) &
               ((Mouse.X >= Size.X - 5) & (Mouse.X <= Size.X - 3) OR Event.Double)
          THEN
            Event.What := EventTypes { evCommand };
            Event.Command := cmZoom;
            Event.InfoPtr := Owner;
            PutEvent( Event );
            ClearEvent( Event );
          ELSIF wfMove IN PWindow(Owner)^.Flags THEN
            DragWindow( Event, TViewDragModes { dmDragMove });
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


  CLASS IMPLEMENTATION TWindow;

    PROCEDURE Init(VAR Bounds: Objects.TRect;
                       ATitle: ARRAY OF CHAR;
                       ANumber: CARDINAL);    (* Constructor *)
    BEGIN
      TGroup.Init( Bounds );
      Flags := WindowFlags { wfMove, wfGrow, wfClose, wfZoom };
      ZoomRect := GetBounds();
      Number := ANumber;
      Palette := 0; (* CBlueWindow *)
      Title := NewStr( ATitle );
(*
      NEW(Title);
      Copy(Title^, ATitle);
*)
(*???      TWindowInit( &TWindow::initFrame ) *)
      INCL(State, sfShadow);
      INCL(Options, ofSelectable);
      INCL(Options, ofTopSelect);
      INCL(GrowMode, gfGrowAll);
      INCL(GrowMode, gfGrowRel);
      IF Frame = NIL THEN
        InitFrame( );
        IF Frame # NIL THEN
          Insert( Frame );
        END;
      END;
    END Init;

    PROCEDURE Load(VAR S: Streams.TStream);   (* Constructor *)
    BEGIN
      TGroup.Load( S );
      S.Rd(Flags);
      S.Rd(ZoomRect);
      S.Rd(Number);
      S.Rd(Palette);
      NEW(Frame);
      Frame^.Load(S);
      Title := S.ReadStr(255);
    END Load;

    VIRTUAL PROCEDURE Done;                   (* Destructor *)
    BEGIN
      DISPOSE(Title);
      Frame := NIL;
      TGroup.Done;
    END Done;

    VIRTUAL PROCEDURE Close;
    BEGIN
      IF Frame # NIL THEN
        Frame^.Done;
        DISPOSE( Frame );
      END;
(*      Frame := NIL;  (* so we don't try to use the frame after it's been deleted *)*)
      IF Valid( cmClose ) THEN
        Done;
      END;
    END Close;

    VIRTUAL PROCEDURE GetPalette(): PPalette;
    BEGIN
      CASE Palette OF
      | 0 : RETURN ADR(CBlueWindow);
      | 1 : RETURN ADR(CCyanWindow);
      | 2 : RETURN ADR(CGrayWindow);
      END;
    END GetPalette;

    VIRTUAL PROCEDURE GetTitle((*MaxSize: INTEGER*)): PTitleStr;
    BEGIN
      RETURN Title;
    END GetTitle;

    VIRTUAL PROCEDURE HandleEvent(VAR Event: Drivers.TEvent);
    VAR
      limits : Objects.TRect;
      min, max : Objects.TPoint;
      dm : TViewDragModes;
    BEGIN
      TGroup.HandleEvent(Event);
      IF evCommand IN Event.What THEN
        CASE Event.Command OF
        | cmResize:
            IF WindowFlags { wfMove, wfGrow } * Flags # WindowFlags{} THEN
              limits := Owner^.GetExtent();
              SizeLimits(min, max);
              dm := DragMode;
              IF wfMove IN Flags THEN
                INCL(dm, dmDragMove);
              END;
              IF wfGrow IN Flags THEN
                INCL(dm, dmDragGrow);
              END;
              DragView( Event, dm, limits, min, max);
              ClearEvent(Event);
            END;
        | cmClose:
            IF (wfClose IN Flags) & (( Event.InfoPtr = NIL) OR (Event.InfoPtr = ADR(SELF) )) THEN
              IF NOT( sfModal IN State ) THEN
                Close();
              ELSE
                Event.What := EventTypes{ evCommand };
                Event.Command := cmCancel;
                PutEvent( Event );
              END;
              ClearEvent( Event );
            END;
        | cmZoom:
            IF (wfZoom IN Flags) & (( Event.InfoPtr = NIL) OR (Event.InfoPtr = ADR(SELF) )) THEN
              Zoom();
              ClearEvent(Event);
            END;
        END;
      ELSIF evKeyDown IN Event.What THEN
        CASE Event.KeyCode OF
        | kbTab:
            SelectNext(FALSE);
            ClearEvent(Event);
        | kbShiftTab:
            SelectNext(TRUE);
            ClearEvent(Event);
        END;
      ELSIF (Event.What = EventTypes { evBroadcast }) &
            (Event.Command = cmSelectWindowNum) &
            (Event.InfoInt = VAL( INTEGER, Number)) &
            (ofSelectable IN Options)
      THEN
        Select();
        ClearEvent(Event);
      END;
    END HandleEvent;

    VIRTUAL PROCEDURE InitFrame;
    VAR
      r : Objects.TRect;
    BEGIN
      r := GetExtent ();
      NEW( Frame );
      Frame^.Init( r );
    END InitFrame;

    VIRTUAL PROCEDURE SetState( AState: TViewStates;
                                Enable: BOOLEAN);
    VAR
      WindowCommands: TCommandSet;
    BEGIN
      WindowCommands := TCommandSet{};
      TGroup.SetState(AState, Enable);
      IF sfSelected IN AState THEN
        SetState( TViewStates { sfActive }, Enable);
        IF Frame # NIL THEN
          Frame^.SetState( TViewStates { sfActive}, Enable);
        END;
        INCL( WindowCommands, cmNext);
        INCL( WindowCommands, cmPrev);
        IF WindowFlags { wfGrow, wfMove } * Flags # WindowFlags {} THEN
          INCL(WindowCommands, cmResize);
        END;
        IF wfClose IN Flags THEN
          INCL(WindowCommands, cmClose);
        END;
        IF wfZoom IN Flags THEN
          INCL(WindowCommands, cmZoom);
        END;
        IF Enable THEN
          EnableCommands(WindowCommands);
        ELSE
          DisableCommands(WindowCommands);
        END;
      END;
    END SetState;

    VIRTUAL PROCEDURE SizeLimits(VAR Min, Max: Objects.TPoint);
    BEGIN
      TView.SizeLimits(Min, Max);
      Min := MinWinSize;
    END SizeLimits;

    PROCEDURE StandardScrollBar(AOptions: ScrollBarOptions): PScrollBar;
    VAR
      r : Objects.TRect;
      s : PScrollBar;
    BEGIN
      r := GetExtent();
      IF sbVertical IN AOptions THEN
        r.Assign( r.B.X-1, r.A.Y+1, r.B.X, r.B.Y-1 );
      ELSE
        r.Assign( r.A.X+2, r.B.Y-1, r.B.X-2, r.B.Y );
      END;
      NEW(s);
      s^.Init(r);
      Insert( s );
      IF sbHandleKeyboard IN AOptions THEN
        INCL(s^.Options, ofPostProcess);
      END;
      RETURN s;
    END StandardScrollBar;

    PROCEDURE Store(VAR S: Streams.TStream);
    BEGIN
      TGroup.Store( S );
      S.Wr(Flags);
      S.Wr(ZoomRect);
      S.Wr(Number);
      S.Wr(Palette);
      Frame^.Store( S );
      S.WriteStr(Title);
    END Store;

    VIRTUAL PROCEDURE Zoom;
    VAR
      minSize, maxSize : Objects.TPoint;
      r : Objects.TRect;
    BEGIN
      SizeLimits( minSize, maxSize );
      IF Size # maxSize THEN
        ZoomRect := GetBounds();
        r.Assign( 0, 0, maxSize.X, maxSize.Y );
        Locate( r );
      ELSE
        Locate( ZoomRect );
      END;
    END Zoom;

  BEGIN
    Frame := NIL;
  END TWindow;

END Winds.