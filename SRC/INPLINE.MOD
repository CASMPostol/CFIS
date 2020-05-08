IMPLEMENTATION MODULE InpLine;

FROM SYSTEM IMPORT
  BYTE;
FROM GrafTypes IMPORT
  RECT;
FROM Graphics IMPORT
  _Wr16StrXY;
FROM MMMouse IMPORT
  Region, RegisterRegion, UnregisterRegion, HideConditionally, ShowCursor,
  Event, EventSet, ButtonSet, Button;
IMPORT
  MMMouse, Terminal;
FROM HiLevGraf IMPORT
  FillRect, FrameRect;
FROM Strings IMPORT
  Assign, Length;
FROM ASCII IMPORT
  cr, bs, ht, bel, esc, del, EOL;
FROM Storage IMPORT
  ALLOCATE, DEALLOCATE;
FROM MANAGER  IMPORT
  Assert;

  CONST
    Alive = 31415;
    Dead  = 27182;

TYPE
  HLINE = POINTER TO LineDesc;
  LineDesc = RECORD
    Next : HLINE;
    Rect : RECT;
    f, b : BYTE;
    kol  : INTEGER;
    valid: ValidateProc;
    Text : ARRAY [0..99] OF CHAR;
    Reg  : Region;
    Curs : INTEGER;
    len  : INTEGER;
    Enable: BOOLEAN;
    state      : CARDINAL;
  END;

  PROCEDURE CreateInpLine( x, y : INTEGER; (* polozenie lg rogu *)
                           IlKol: INTEGER; (* ilosc znakow *)
                           Valid: ValidateProc;
                           fore : BYTE;
                           back : BYTE;
                           VAR h : HLINE);
  VAR
    i : CARDINAL;
  BEGIN
    NEW( h );
    WITH h^ DO
      kol := IlKol+1;
      Rect.left := x;
      Rect.top := y;
      Rect.right := x+4+8*kol;
      Rect.bottom := y+4+16;
      len := 0;
      f := fore;
      b := back;
      FOR i := 0 TO HIGH( Text ) DO
        Text[i] := 0C;
      END;
      valid := Valid;
      Curs := 0;
      Next := Active;
      Active := h;
      SetActive( Next );
      Enable := TRUE;
      state := Alive;
      RegisterRegion( EventSet{LeftDown, RegionIn, Motion}, Rect, SetCursor,
                      NIL, Reg );

      FillRect( Rect, b );
      FrameRect( Rect, f );
      Draw( h );
    END;
  END CreateInpLine;

  PROCEDURE Enable( h : HLINE; en : BOOLEAN );
    BEGIN
      Assert(h^.state = Alive);
      h^.Enable := en;
    END Enable;

  PROCEDURE DeleteInpLine( h : HLINE );
  VAR
    t : HLINE;
  BEGIN
    Assert(h^.state = Alive);
    h^.state := Dead;
    UnregisterRegion( h^.Reg );
    IF h = Active THEN
      Active := h^.Next;
    ELSE
      t := Active;
      WHILE t^.Next # h DO
        t := t^.Next;
      END;
      t^.Next := h^.Next;
    END;
    DISPOSE( h );
  END DeleteInpLine;

  PROCEDURE SetText( h : HLINE; txt : ARRAY OF CHAR );
  BEGIN
    WITH h^ DO
      Assert(h^.state = Alive);
      Assert(state = Alive);
      Assign( txt, Text );
      Text[kol] := 0C;
      len := Length( txt );
      Draw( h );
    END;
  END SetText;

  PROCEDURE GetText( h : HLINE; VAR txt : ARRAY OF CHAR );
  BEGIN
    Assert(h^.state = Alive);
    Assign( h^.Text, txt );
  END GetText;

  PROCEDURE Key( h : HLINE; ch : CHAR; scan : CHAR );
  VAR
    i  : INTEGER;
    pText : ARRAY[0..99] OF CHAR;
  BEGIN
    WITH h^ DO
      Assert(h^.state = Alive);
      Assign( Text, pText );
      IF ch = bs THEN
        IF Curs > 0 THEN
          FOR i := Curs-1 TO kol-1 DO
            pText[i] := pText[i+1];
          END;
          pText[kol-1] := 0C;
          IF valid( h, pText, FALSE ) THEN
            Assign( pText, Text );
            DEC( Curs );
            DEC( len );
          ELSE
            Terminal.Write( bel );
          END;
        END;
      ELSIF ch = 0C THEN
        IF scan = CHR( 4BH ) THEN (* w lewo *)
          IF Curs > 0 THEN
            DEC( Curs );
          END;
        ELSIF scan = CHR( 4DH ) THEN (* w prawo *)
          IF Curs < len  THEN
            INC( Curs );
          END;
        ELSIF scan = CHR( 4FH ) THEN (* end *)
          Curs := len;
        ELSIF scan = CHR( 47H ) THEN (* home *)
          Curs := 0;
        ELSIF scan = CHR(053H) THEN (* del *)
          IF Curs # len THEN
            FOR i := Curs TO len DO
              pText[i] := pText[i+1];
            END;
            DEC( len );
            pText[len] := 0C;
            IF valid( h, pText, FALSE ) THEN
              Assign( pText, Text );
            ELSE
              Terminal.Write( bel );
            END;
          END;
        ELSE
          Terminal.Write( bel );
        END;
      ELSIF (ch >= ' ') & (ch < CHR( 80H )) THEN
        FOR i := kol-2 TO Curs BY -1 DO
          pText[i+1] := pText[i];
        END;
        pText[Curs] := ch;
        IF valid( h, pText, FALSE ) THEN
          IF Curs < kol-1 THEN
            INC( Curs );
          END;
          IF len < kol-1 THEN
            INC( len );
          END;
          Assign( pText, Text );
        ELSE
          Terminal.Write( bel );
        END;
      ELSE
        Terminal.Write( bel );
      END;
      Text[len] := 0C;
    END;
    Draw( h );
  END Key;

  PROCEDURE DoNothing( h : HLINE; VAR s : ARRAY OF CHAR; KillFocus : BOOLEAN ) : BOOLEAN;
  BEGIN
    RETURN TRUE;
  END DoNothing;

  PROCEDURE KillFocus( h : HLINE ):BOOLEAN;
  BEGIN
    Assert(h^.state = Alive);
    RETURN h^.valid( h, h^.Text, TRUE );
  END KillFocus;

  PROCEDURE Draw( h : HLINE );
  VAR
    t : ARRAY[0..0] OF CHAR;
    hi: BOOLEAN;
    r : RECT;
  BEGIN
    WITH h^ DO
      Assert(state = Alive);
      hi := HideConditionally( Rect );
      _Wr16StrXY( Text, Rect.left+2, Rect.top+2, f, b );
      r := Rect;
      INC( r.left, 2+len*8 );
      DEC( r.right );
      INC( r.top );
      DEC( r.bottom );
      FillRect( r, b );
      IF Curs > len-1 THEN
        t[0] := ' ';
      ELSE
        t[0] := Text[Curs];
      END;
      _Wr16StrXY( t, Rect.left+2+8*Curs, Rect.top+2, b, f );
      IF hi THEN
        ShowCursor;
      END;
    END;
  END Draw;

  PROCEDURE SetCursor( e : EventSet; b : ButtonSet; x,y : INTEGER );
  VAR
    r : Region;
    h : HLINE;
  BEGIN
    IF RegionIn IN e THEN
      r := MMMouse.GetRegion();
      h := Active;
      WHILE (h # NIL) & (h^.Reg # r) DO
        Assert(h^.state = Alive);
        h := h^.Next;
      END;
      IF NOT h^.Enable THEN
        RETURN;
      END;
      SetActive( h );
    ELSIF (LeftDown IN e) OR (Motion IN e) & (LeftButton IN b ) THEN
      DEC( x, 2 );
      WITH Active^ DO
        Assert(state = Alive);
        Curs := x DIV 8;
        IF Curs > len THEN
          Curs := len;
        END;
        Draw( Active );
      END;
    END;
  END SetCursor;

  PROCEDURE SetActive( h : HLINE );
  VAR
    t, u : HLINE;
  BEGIN
    IF (h # NIL) & (h # Active) THEN
      t := Active;
      WHILE t^.Next # h DO
      Assert(t^.state = Alive);
        t := t^.Next;
      END;
      t^.Next := Active;
      u := Active^.Next;
      Active^.Next := h^.Next;
      Active := h;
      h^.Next := u;
    END;
  END SetActive;

  PROCEDURE GetRegion( h : HLINE ) : Region;
  BEGIN
    Assert(h^.state = Alive);
    RETURN h^.Reg;
  END GetRegion;


VAR
  Active : HLINE;

BEGIN
  Active := NIL;
END InpLine.
