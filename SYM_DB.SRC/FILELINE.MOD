IMPLEMENTATION MODULE FileLines;

FROM Views IMPORT
  SelectMode;
FROM Objects IMPORT
  NewStr, DisposeStr, String;
FROM Storage IMPORT
  ALLOCATE, DEALLOCATE;
FROM Str IMPORT
  Compare, CHARSET, Delete, Copy;
FROM Commands IMPORT
  cmReleasedFocus;
FROM Drivers IMPORT
  evBroadcast;
FROM Lib IMPORT
  Move;
FROM InputLines IMPORT
  PInputLine, TInputLine;
FROM RealInputLines IMPORT
  TRealInputLine;
FROM MsgBox IMPORT
  MessageBox, MsgOption, MsgOptions;
FROM stdio IMPORT
  sscanf, sprintf;
IMPORT
  FIO, FIOR;


CONST
  FileChars = CHARSET{ 'A'..'Z', 'a'..'z', '!', '@', '#', '$', '^', '&', '~', '_', '{', '}'};
  Digits    = CHARSET{ '+', '-', '0'..'9' };

PROCEDURE DelSpaces( VAR s : ARRAY OF CHAR );
VAR
  i : CARDINAL;
BEGIN
  i := 0;
  WHILE ( i <= HIGH( s )) & ( s[i] = ' ' ) DO
    INC( i );
  END;
  Delete( s, 0, i );
END DelSpaces;


CLASS IMPLEMENTATION TFileLine;

    PROCEDURE Init( VAR Bounds  : TRect;
                        StrSize : CARDINAL; (* < StringSize *)
                        AMin,
                        AMax    : LONGREAL;
                        ADef    : PReal;
                        AFileName : ARRAY OF CHAR );
    BEGIN
      xy := NIL;
      Count := 0;
      FileName := NIL;
      TSpeedBoxReal.Init( Bounds, StrSize, AMin, AMax, ADef );
      Saved := ADef^;
      StringOrReal( AFileName );
      IF AFileName[0] # 0C THEN
        FileName := NewStr( AFileName );
      END;
    END Init;

    VIRTUAL PROCEDURE StringOrReal( String : ARRAY OF CHAR );
    VAR
      F : FIO.File;
      i : CARDINAL;
      Line : ARRAY [0..255] OF CHAR;
    BEGIN
      IF String[0] = 0C THEN
        IF FileName # NIL THEN
          DisposeStr( FileName );
          Inp^.DataMustBeValid := TRUE;
          DEALLOCATE( xy, Count*SIZE( XY ));
        END;
      ELSIF ( FileName # NIL ) & ( Compare( FileName^, String ) = 0) THEN
        RETURN;
      ELSE
        StringOrReal( "" );
        Inp^.DataMustBeValid := FALSE;
        FileName := NewStr( String );
        F := FIOR.Open( String );
        IF F = MAX( CARDINAL ) THEN
          sprintf( Line, 3C+"Na wyspecyfikowanych žcie§kach nie mo§na znale¦ pliku '%s'", String );
          StringOrReal( "" );
          MessageBox( Line, NIL, MsgOptions{ mfOKButton, mfError });
        ELSE
          FIO.RdStr( F, Line );
          sscanf( Line, "Items=%ud", ADR( Count ));
          ALLOCATE( xy, Count*SIZE( XY ));
          FOR i := 0 TO Count-1 DO
            IF FIO.EOF THEN
              MessageBox( 3C+"Plik opisuj†cy funkcj‘ zawiera zbyt ma’o danych!", NIL, MsgOptions{ mfOKButton, mfError });
              StringOrReal( "" );
              RETURN;
            ELSE
              FIO.RdStr( F, Line );
              sscanf( Line, "x=%lf,y=%lf", ADR( xy^[i].x ), ADR( xy^[i].y ));
            END;
          END;
        END;
        FIO.Close( F );
        IF FileName # NIL THEN
          Inp^.TInputLine.SetData( FileName^ );
        END;
      END;
    END StringOrReal;

    VIRTUAL PROCEDURE GetPalette(): PPalette;
    BEGIN
      IF FileName = NIL THEN
        IF sfDisabled IN State THEN
          RETURN ADR(CHR(32)+
                     01C+01C+02C+03C+ 04C+05C+06C+07C+
                     10C+11C+12C+13C+ 14C+15C+16C+17C+
                     20C+21C+33C+34C+ 35C+25C+26C+27C+
                     30C+31C+32C+33C+ 34C+35C+36C+37C );
        ELSE
          RETURN TSpeedBoxReal.GetPalette();
        END;
      ELSE
        RETURN ADR(CHR(32)+
                   01C+01C+02C+03C+ 04C+05C+06C+07C+
                   10C+11C+12C+13C+ 14C+15C+16C+17C+
                   20C+21C+17C+20C+ 21C+25C+26C+27C+
                   30C+31C+32C+33C+ 34C+35C+36C+37C );
(*
        RETURN ADR(CHR(32)+
                   40C+41C+42C+43C+ 44C+45C+46C+47C+
                   50C+51C+52C+53C+ 54C+55C+56C+57C+
                   60C+61C+57C+60C+ 61C+65C+66C+67C+
                   70C+71C+72C+73C+ 74C+75C+76C+77C );
*)
      END;
    END GetPalette;

(*
    VIRTUAL PROCEDURE HandleEvent( VAR Event : TEvent );
    VAR
      s  : ARRAY [0..255] OF CHAR;
    BEGIN
        TSpeedBoxReal.HandleEvent( Event );
(*
      IF ( evBroadcast IN Event.What  ) &
         ( Event.Command = cmReleasedFocus ) &
         ( Event.InfoPtr = ADDRESS( Inp ))
      THEN
        Inp^.TInputLine.GetData( s );
        DelSpaces(s);
        IF ( FileName # NIL ) # ( s[0] IN FileChars ) THEN
          IF s[0] IN FileChars THEN
            StringOrReal( s );
          ELSIF s[0] IN Digits THEN
            StringOrReal( "" );
          END;
        END;
        ClearEvent( Event );
      ELSE
        TSpeedBoxReal.HandleEvent( Event );
      END;
*)
    END HandleEvent;
*)
    VIRTUAL PROCEDURE SetState( AState : TViewStates; Enable : BOOLEAN );
    VAR
      s : ARRAY [0..31] OF CHAR;
      Switch : BOOLEAN;
      r : LONGREAL;
    BEGIN
      IF SyntaxCheckInProgress THEN
        TSpeedBoxReal.SetState( AState, Enable );
        RETURN;
      END;
      SyntaxCheckInProgress := TRUE;
      IF sfFocused IN AState THEN
(*
        IF FileName # NIL THEN
          IF Enable THEN
            Inp^.TInputLine.SetData( FileName^ );
          ELSE
            Inp^.GetData( r );
            IF r # Inp^.Value THEN
              StringOrReal( "" );
            END;
            Inp^.SetData( Inp^.Value );
          END;
        END;
*)
        Inp^.TInputLine.GetData( s );
        DelSpaces(s);
        IF s[0] IN FileChars THEN
          r := Saved; (* na wszelki wypadek *)
        ELSE
          Inp^.GetData( r );
        END;
        IF r = 0.0 THEN
          r := 1.0E-30;
          IF Saved = 0.0 THEN
            Saved := r;
          END;
        END;
        Switch := FALSE;
        IF NOT Enable THEN
          IF ABS(Saved-r)/r > 1.0E-4 THEN (* odpowiednio mala roznica, bo dokladnie to na pewno nie bedzie *)
            StringOrReal( "" );
          ELSE
            Switch := TRUE;
          END;
        ELSE
          Saved := r;
        END;
        IF s[0] IN FileChars THEN
          StringOrReal( s );
          IF FileName = NIL THEN
            Inp^.SetData(r);
            Inp^.TInputLine.GetData(s);
            Owner^.SetCurrent( ADR(SELF), LeaveSelect );
          END;
        ELSIF (FileName # NIL) & Switch THEN
          StringOrReal( FileName^ );
        ELSIF (s[0] IN Digits) & (ABS(Saved-r)/r > 1.0E-4) THEN
          StringOrReal( "" );
        END;
        Inp^.DataMustBeValid := NOT(s[0] IN FileChars);
        TSpeedBoxReal.SetState( AState, Enable );
        IF FileName # NIL THEN
          IF sfFocused IN State THEN
            Inp^.TInputLine.SetData( FileName^ );
(*            r := Update( r );
            Inp^.SetData( r );  *)
          ELSE
            Inp^.SetData( Inp^.Value );
          END;
          down^.Hide;
          Qdown^.Hide;
          up^.Hide;
          Qup^.Hide;
        ELSE
          down^.Show;
          Qdown^.Show;
          up^.Show;
          Qup^.Show;
        END;
      ELSE
        TSpeedBoxReal.SetState( AState, Enable );
      END;
      SyntaxCheckInProgress := FALSE;
    END SetState;

    VIRTUAL PROCEDURE SetData( VAR AData : ARRAY OF BYTE );
    BEGIN
      IF (NOT ( sfFocused IN Inp^.State ) OR ManualyChanged) (*& (FileName = NIL)*) THEN
        TSpeedBoxReal.SetData( AData );
      ELSE
        Move( ADR( AData ), ADR( Inp^.Value ), SIZE( Inp^.Value ));
      END;
      Def^ := Inp^.Value;
      Saved := Inp^.Value;
    END SetData;

(*
    VIRTUAL PROCEDURE DataSize(): CARDINAL;
    BEGIN
      IF FileName # NIL THEN
        RETURN SIZE( FileName^ );
      ELSE
        RETURN TSpeedBoxReal.DataSize();
      END;
    END DataSize;

    VIRTUAL PROCEDURE SetData( VAR AData : ARRAY OF BYTE );
    VAR
      u : String;
    BEGIN
      IF ( FileName # NIL ) & ( sfFocused IN State ) THEN
        Move( ADR(AData), FileName, DataSize());
        StringOrReal( u );
      ELSE
        Inp^.SetData( AData );
      END;
    END SetData;

    VIRTUAL PROCEDURE GetData( VAR AData : ARRAY OF BYTE );
    BEGIN
      IF ( FileName # NIL ) & ( sfFocused IN State ) THEN
        Move( FileName, ADR(AData), DataSize());
      ELSE
        Inp^.GetData( AData );
      END;
    END GetData;
*)

    PROCEDURE Update( r : LONGREAL ) : LONGREAL;
    VAR
      i : CARDINAL;
      x, y : LONGREAL;
    BEGIN
      IF FileName = NIL THEN
        RETURN Def^;
(*
        IF r <= Inp^.Min THEN
          RETURN Inp^.Min;
        ELSIF r >= Inp^.Max THEN
          RETURN Inp^.Max;
        ELSE
          RETURN r;
        END;
*)
      ELSE
        IF r >= xy^[Count-1].x THEN
          RETURN xy^[Count-1].y;
        END;
        IF r <= xy^[0].x THEN
          RETURN xy^[0].y;
        END;
        i := 1;
        WHILE r > xy^[i].x DO
          INC( i );
        END;
        r := r - xy^[i-1].x;
        x := xy^[i].x-xy^[i-1].x;
        y := xy^[i].y-xy^[i-1].y;
        RETURN r*y/x+xy^[i-1].y;
      END;
    END Update;

    VIRTUAL PROCEDURE Done;
    BEGIN
      StringOrReal( "" );
      TSpeedBoxReal.Done;
    END Done;

BEGIN
  SyntaxCheckInProgress := FALSE;
END TFileLine;


END FileLines.
