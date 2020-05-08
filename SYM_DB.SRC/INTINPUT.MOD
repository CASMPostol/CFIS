IMPLEMENTATION MODULE IntInputLines;

FROM stdio IMPORT
  sprintf, sscanf;
FROM Lib IMPORT
  Move;
IMPORT
  Str;
FROM Views IMPORT
  TViewState;
FROM MsgBox IMPORT
  MessageBox, MsgOption, MsgOptions;
FROM Drivers IMPORT
  evMessage, EventType, EventTypes;
FROM Commands IMPORT
  cmReleasedFocus;
FROM Buttons IMPORT
  PButton, ButtonFlag, ButtonFlags;
FROM Storage IMPORT
  ALLOCATE, DEALLOCATE;

TYPE
  IntPtr = POINTER TO INTEGER;

  CLASS IMPLEMENTATION TIntInputLine;

    PROCEDURE Init( VAR Bounds  : TRect;
                        StrSize : CARDINAL;
                        AMin,
                        AMax    : INTEGER );
    BEGIN
      TInputLine.Init( Bounds, StrSize );
      Min := AMin;
      Max := AMax;
      Value := Min;
    END Init;

    VIRTUAL PROCEDURE SetData( VAR AData : ARRAY OF BYTE );
    VAR
      s : ARRAY [0..StringSize-1] OF CHAR;
    BEGIN
      Move( ADR( AData ), ADR( Value ), SIZE( INTEGER ));
      sprintf( s, Format, Value );
      TInputLine.SetData( s );
    END SetData;

    VIRTUAL PROCEDURE GetData( VAR AData : ARRAY OF BYTE );
    VAR
      s : ARRAY [0..StringSize-1] OF CHAR;
    BEGIN
      TInputLine.GetData( s );
      sscanf( s, "%d", ADR( Value ));
      Move( ADR( Value ), ADR( AData ), SIZE( INTEGER ));
    END GetData;

    VIRTUAL PROCEDURE SetState( AState: TViewStates; Enable : BOOLEAN );
    VAR
      s : ARRAY [0..StringSize-1] OF CHAR;
      v : INTEGER;
    BEGIN
      IF ( sfFocused IN AState ) & NOT Enable & ( sfFocused IN State ) THEN
        TInputLine.SetState( AState, Enable );
        TInputLine.GetData( s );
        v := Value;
        sscanf( s, "%d", ADR(v));
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
      ELSE
        TInputLine.SetState( AState, Enable );
      END;
    END SetState;

    VIRTUAL PROCEDURE DataSize(): CARDINAL;
    BEGIN
      RETURN SIZE( Value );
    END DataSize;

    PROCEDURE SetFormat( a : ARRAY OF CHAR );
    BEGIN
      Str.Copy( Format, a );
    END SetFormat;


  BEGIN
    Format := '%d';
  END TIntInputLine;

CONST
  Down2 = 22222;
  Down  = 22223;
  Up    = 22224;
  Up2   = 22225;

  CLASS IMPLEMENTATION TSpeedBoxInt;

    PROCEDURE Init( VAR Bounds  : TRect;
                        StrSize : CARDINAL;
                        AMin,
                        AMax    : INTEGER );
    VAR
      r : TRect;
      b : PButton;
    BEGIN
      TGroup.Init( Bounds );
      r := Bounds;
      DEC( r.B.X, 10 );
      NEW( Inp );
      Inp^.Init( r, StrSize, AMin, AMax );
      Bounds.A.X := r.B.X;
      r := Bounds;

      r.B.X := r.A.X+3;
      NEW( b );
      b^.Init( r, "<<", Down2, ButtonFlags{ bfNormal } );
      Insert( b );

      r.A.X := r.B.X;
      INC( r.B.X, 2 );
      NEW( b );
      b^.Init( r, "<", Down, ButtonFlags{ bfNormal } );
      Insert( b );

      r.A.X := r.B.X;
      INC( r.B.X, 2 );
      NEW( b );
      b^.Init( r, ">", Up, ButtonFlags{ bfNormal } );
      Insert( b );

      r.A.X := r.B.X;
      INC( r.B.X, 3 );
      NEW( b );
      b^.Init( r, ">>", Up2, ButtonFlags{ bfNormal } );
      Insert( b );

    END Init;

    VIRTUAL PROCEDURE HandleEvent( VAR Event : TEvent );
    VAR
      v : INTEGER;
    BEGIN
      IF evMessage*Event.What # EventTypes{} THEN
        Inp^.GetData( v );
        CASE Event.Command OF
        | Down2:
            DEC( v, 10 );
        | Down:
            DEC( v );
        | Up:
            INC( v );
        | Up2:
            INC( v, 10 );
        ELSE
          TGroup.HandleEvent( Event );
        END;
      ELSE
        TGroup.HandleEvent( Event );
      END;
      IF v < Inp^.Min THEN
        v := Inp^.Min;
      ELSIF v > Inp^.Max THEN
        v := Inp^.Max;
      END;
      SetData( v );
      ClearEvent( Event );
    END HandleEvent;

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
  END TSpeedBoxInt;

END IntInputLines.
