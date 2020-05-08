(*%T TV_NoDebug*)
(*# debug(vid=>off)*)
(*%E*)
(*%T InOneSegment *)
(*#call(seg_name=>TV)*)
(*%E*)
IMPLEMENTATION MODULE StaticTexts;

FROM Objects IMPORT
  TRect, String, PString, NewStr, DisposeStr;
FROM Storage IMPORT
  ALLOCATE, DEALLOCATE;
FROM Str IMPORT
  Copy, Length;
FROM Streams IMPORT
  TStream;
FROM Drivers IMPORT
  TDrawBuffer, MoveChar, MoveBuf;
FROM Views IMPORT
  PPalette;
FROM Texts IMPORT
  CStaticText;

  CLASS IMPLEMENTATION TStaticText;

    PROCEDURE Init(VAR Bounds: TRect;
                       AText: ARRAY OF CHAR);
    BEGIN
      TView.Init( Bounds );
      Text := NewStr(AText);
    END Init;

    PROCEDURE Load(VAR S: TStream);
    BEGIN
      TView.Load( S );
      Text := S.ReadStr(256);
    END Load;

    VIRTUAL PROCEDURE Done;
    BEGIN
      DisposeStr(Text);
      TView.Done;
    END Done;

    VIRTUAL PROCEDURE Draw;
    VAR
      color : CARDINAL;
      center : BOOLEAN;
      i, j, l, p, y : INTEGER;
      b : TDrawBuffer;
      s : String;
    BEGIN
      color := GetColor(1);
      GetText(s);
      l := Length(s);
      p := 0;
      y := 0;
      center := FALSE;
      WHILE y < Size.Y DO
        MoveChar( b, 0, ' ', color, Size.X);
        IF p < l THEN
          IF s[p] = 3C (*Ctrl-C *) THEN
            center := TRUE;
            INC(p);
          END;
          i := p;
          REPEAT
            j := p;
            WHILE (p < l) & (s[p] = ' ') DO
              INC(p);
            END;
            WHILE (p < l) & (s[p] # ' ') & (s[p] # 15C (*Ctrl-M*)) DO
              INC(p);
            END;
          UNTIL NOT((p < l) & (p < i + Size.X) & (s[p] # 15C(*Ctrl-M*)));
          IF p > i + Size.X THEN
            IF j > i THEN
              p := j;
            ELSE
              p := i + Size.X;
            END;
          END;
          IF center THEN
            j := (Size.X - p + i) DIV 2 ;
          ELSE
            j := 0;
          END;
          MoveBuf(b, j, PString(ADR(s[i]))^, color, p - i);
          WHILE (p < l) & (s[p] = ' ') DO
            INC(p);
          END;
          IF (p < l) & (s[p] = 15C (*Ctrl-M*)) THEN
            center := FALSE;
            INC(p);
            IF (p < l) & (s[p] = 12C (*Ctrl-J*)) THEN
              INC(p);
            END;
          END;
        END;
        WriteLine(0, y, Size.X, 1, b);
        INC(y);
      END;
    END Draw;

    VIRTUAL PROCEDURE GetPalette(): PPalette;
    BEGIN
      RETURN ADR(CStaticText);
    END GetPalette;

    VIRTUAL PROCEDURE GetText(VAR S: ARRAY OF CHAR);
    BEGIN
      IF Text = NIL THEN
        S[0] := 0C;
      ELSE
        Copy( S, Text^ );
      END;
    END GetText;

    PROCEDURE Store(VAR S: TStream);
    BEGIN
      TView.Store( S );
      S.WriteStr(Text);
    END Store;

    PROCEDURE ChangeString( s : ARRAY OF CHAR );
    BEGIN
      DisposeStr( Text );
      Text := NewStr( s );
      DrawView
    END ChangeString;

  BEGIN
  END TStaticText;


END StaticTexts.