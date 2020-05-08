IMPLEMENTATION MODULE RealInputLines;

FROM stdio IMPORT
  sprintf, sscanf;
IMPORT
  Str;
FROM Lib IMPORT
  Move;
FROM Views IMPORT
  TViewState, TViewOption, TViewOptions, TView, Message;
FROM MsgBox IMPORT
  MessageBox, MsgOption, MsgOptions;
FROM Buttons IMPORT
  PButton, ButtonFlags, ButtonFlag;
FROM Storage IMPORT
  ALLOCATE, DEALLOCATE;
FROM Drivers IMPORT
  evMessage, EventTypes, EventType, TDrawBuffer, MoveChar, kbCtrlPgUp,
  kbPgUp, kbPgDn, kbCtrlPgDn;
FROM Commands IMPORT
  cmReleasedFocus;
FROM Drivers IMPORT
  kbEnter, kbTab;

  CLASS IMPLEMENTATION TRealInputLine;

    PROCEDURE Init( VAR Bounds  : TRect;
                        StrSize : CARDINAL;
                        AMin,
                        AMax    : LONGREAL );
    BEGIN
      TInputLine.Init( Bounds, StrSize );
      Min := AMin;
      Max := AMax;
      Value := AMin;
      sprintf( Format, "%%%dlf", TInputLine.DataSize()-1);
(*      INCL( EventMask, evBroadcast );*)
    END Init;

    VIRTUAL PROCEDURE SetData( VAR AData : ARRAY OF BYTE );
    VAR
      s : ARRAY [0..StringSize-1] OF CHAR;
    BEGIN
      Move( ADR( AData ), ADR( Value ), SIZE( LONGREAL ));
      sprintf( s, Format, Value );
      TInputLine.SetData( s );
    END SetData;

    VIRTUAL PROCEDURE GetData( VAR AData : ARRAY OF BYTE );
    VAR
      s : ARRAY [0..StringSize-1] OF CHAR;
      v : LONGREAL;
    BEGIN
      TInputLine.GetData( s );
      sscanf( s, "%lf", ADR( v ));
      IF ( v >= Min ) & ( v <= Max ) THEN
        Value := v;
      END;
      Move(  ADR( Value ), ADR( AData ),SIZE( LONGREAL ));
    END GetData;

    VIRTUAL PROCEDURE KillFocus();
    VAR
      s : ARRAY [0..StringSize-1] OF CHAR;
      v : LONGREAL;
    BEGIN
      IF DataMustBeValid THEN
        TInputLine.GetData( s );
        v := Value;
        sscanf( s, "%lf", ADR(v));
        IF ( v < Min ) OR ( v > Max ) THEN
(*%F PoPolsku *)
          MessageBox( 3C+"This value is out of range", NIL, MsgOptions{mfError, mfOKButton});
(*%E*)
(*%T PoPolsku *)
          MessageBox( 3C+"Wartoûç poza dopuszczalnym zakresem", NIL, MsgOptions{mfError, mfOKButton});
(*%E*)
        ELSE
          Value := v;
        END;
        SetData( Value );
      END;
      IF Owner # NIL THEN
        Message( Owner, EventTypes{evBroadcast}, cmReleasedFocus, ADR( SELF));
      END;
    END KillFocus;

    VIRTUAL PROCEDURE SetState( AState : TViewStates; Enable : BOOLEAN );
    BEGIN
      TInputLine.SetState( AState, Enable );
      IF ( sfFocused IN AState ) & NOT Enable & NOT( sfFocused IN State ) THEN
        KillFocus;
      END;
    END SetState;

    VIRTUAL PROCEDURE HandleEvent( VAR Event : TEvent );
    VAR
      e : TEvent;
    BEGIN
      TInputLine.HandleEvent( Event );
      IF evMessage*Event.What # EventTypes{} THEN
        IF Event.Command = cmReleasedFocus THEN
          KillFocus;
        END;
      ELSIF Enter2Tab & (evKeyDown IN Event.What ) & (Event.KeyCode=kbEnter) THEN
        e := Event;
        e.KeyCode := kbTab;
        PutEvent( e );
        ClearEvent( Event );
      END;
    END HandleEvent;

    VIRTUAL PROCEDURE DataSize(): CARDINAL;
    BEGIN
      RETURN SIZE( Value );
    END DataSize;

    PROCEDURE SetFormat( a : ARRAY OF CHAR );
    BEGIN
      Str.Copy( Format, a );
    END SetFormat;


  BEGIN
    DataMustBeValid := TRUE;
    Enter2Tab := FALSE;
  END TRealInputLine;

TYPE
  PInterior = POINTER TO TInterior;

CLASS TInterior( TView );
  VIRTUAL PROCEDURE Draw;
END TInterior;

CLASS IMPLEMENTATION TInterior;

  VIRTUAL PROCEDURE Draw;
  VAR
    Color: CARDINAL;
    y    : INTEGER;
    b    : TDrawBuffer;
  BEGIN
    Color := GetColor(1);
    FOR y := 0 TO Size.Y - 1 DO
      MoveChar(b, 0, ' ', Color, Size.X);
      WriteLine(0, y, Size.X, 1, b);
    END;
  END Draw;

BEGIN
END TInterior;





CONST
  Down2 = 222;
  Down  = 223;
  Up    = 224;
  Up2   = 225;

  CLASS IMPLEMENTATION TSpeedBoxReal;

    PROCEDURE Init( VAR Bounds  : TRect;
                        StrSize : CARDINAL;
                        AMin,
                        AMax    : LONGREAL;
                        APR     : PReal );
    VAR
      r : TRect;
      i : PInterior;
    BEGIN
      TGroup.Init( Bounds );
      Def := APR;
(*      EXCL( Options, ofBuffered );*)
      Bounds.Move( -Bounds.A.X, -Bounds.A.Y );
      NEW(i);
      i^.Init( Bounds );
      Insert(i);

(*      Bounds.B.Y := Bounds.A.Y+1;*)
      r := Bounds;
      DEC( r.B.X, 19 );
      r.B.Y := r.A.Y+1;
      NEW( Inp );
      Inp^.Init( r, StrSize, AMin, AMax );
      IF Def # NIL THEN
        Inp^.SetData( Def^ );
      END;
      Insert( Inp );

      Bounds.A.X := r.B.X;
      r := Bounds;

      r.B.X := r.A.X+5;
      NEW( Qdown );
      Qdown^.Init( r, "<<", Down2, ButtonFlags{ bfNormal } );
      Insert( Qdown );

      r.A.X := r.B.X;
      INC( r.B.X, 4 );
      NEW( down );
      down^.Init( r, "<", Down, ButtonFlags{ bfNormal } );
      Insert( down );

      r.A.X := r.B.X;
      INC( r.B.X, 4 );
      NEW( up );
      up^.Init( r, ">", Up, ButtonFlags{ bfNormal } );
      Insert( up );

      r.A.X := r.B.X;
      INC( r.B.X, 5 );
      NEW( Qup );
      Qup^.Init( r, ">>", Up2, ButtonFlags{ bfNormal } );
      Insert( Qup );

      Options := Options+TViewOptions{ ofSelectable, ofFirstClick,
                                       ofPreProcess, ofPostProcess };
      Inp^.Options := Inp^.Options+TViewOptions{ ofPreProcess, ofPostProcess };
      Inp^.Enter2Tab := TRUE;
    END Init;

    VIRTUAL PROCEDURE HandleEvent( VAR Event : TEvent );

    VAR
      v : LONGREAL;
    BEGIN
      TGroup.HandleEvent( Event );
      IF NOT ( sfSelected IN State ) OR (sfDisabled IN Inp^.State) THEN
        RETURN;
      END;
      Inp^.GetData( v );
      IF evMessage*Event.What # EventTypes{} THEN
(*
        IF Event.Command = cmReleasedFocus THEN
          Inp^.KillFocus;
        END;
*)
        CASE Event.Command OF
        | Down2:
               IF Event.InfoPtr = Qdown THEN
              v := v-1.0;
            ELSE
              RETURN;
            END;
        | Down:
            IF Event.InfoPtr = down THEN
              v := v-0.1;
            ELSE
              RETURN;
            END;
        | Up:
            IF Event.InfoPtr = up THEN
              v := v+0.1;
            ELSE
              RETURN;
            END;
        | Up2:
            IF Event.InfoPtr = Qup THEN
              v := v+1.0;
            ELSE
              RETURN;
            END;
        | cmReleasedFocus:
            (* nic wiecej *)
        ELSE
          RETURN;
        END;
      ELSIF evKeyDown IN Event.What THEN
        CASE Event.KeyCode OF
        | kbPgUp :
            v := v+0.1;
        | kbCtrlPgUp:
            v := v+1.0;
        | kbPgDn:
            v := v-0.1;
        | kbCtrlPgDn:
            v := v-1.0;
        ELSE
          RETURN;
        END;
      ELSE
        RETURN;
      END;
      Validate( v );
      IF Event.Command # cmReleasedFocus THEN
        ManualyChanged := TRUE;
      END;
      SetData( v );
      IF Event.Command # cmReleasedFocus THEN
        ManualyChanged := FALSE;
      END;
      IF Def # NIL THEN
        Def^ := v;
      END;
      IF Event.Command # cmReleasedFocus THEN
        ClearEvent( Event );
      END;
    END HandleEvent;

    VIRTUAL PROCEDURE SetState( AState : TViewStates; Enable : BOOLEAN );
    VAR
      s : BOOLEAN;
    BEGIN
      TGroup.SetState( AState, Enable );
      IF sfSelected IN AState THEN
        s := sfSelected IN State;
        SelectView( Inp, s );
(*
        Inp^.SetState( TViewStates{sfDisabled}, NOT s );
        Inp^.DrawView;
*)
        down^.SetState( TViewStates{sfDisabled}, NOT s );
        down^.DrawView;
        Qdown^.SetState( TViewStates{sfDisabled}, NOT s );
        Qdown^.DrawView;
        up^.SetState( TViewStates{sfDisabled}, NOT s );
        up^.DrawView;
        Qup^.SetState( TViewStates{sfDisabled}, NOT s );
        Qup^.DrawView;
        Inp^.FocusView( s );
        Inp^.SetState( TViewStates{ sfCursorVis }, s );
      END;
    END SetState;

    VIRTUAL PROCEDURE Validate( VAR v : LONGREAL );
    BEGIN
      IF v < Inp^.Min THEN
        v := Inp^.Min;
      ELSIF v > Inp^.Max THEN
        v := Inp^.Max;
      END;
    END Validate;

    VIRTUAL PROCEDURE DataSize(): CARDINAL;
    BEGIN
      RETURN Inp^.DataSize();
    END DataSize;

    VIRTUAL PROCEDURE SetData( VAR Data : ARRAY OF BYTE );
    BEGIN
      Inp^.SetData( Data );
    END SetData;

    VIRTUAL PROCEDURE GetData( VAR Data : ARRAY OF BYTE );
    BEGIN
      Inp^.GetData( Data );
    END GetData;

  BEGIN
    ManualyChanged := FALSE;
  END TSpeedBoxReal;

END RealInputLines.
