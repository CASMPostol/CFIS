(*%T TV_NoDebug*)
(*# debug(vid=>off)*)
(*%E*)
(*%T InOneSegment *)
(*#call(seg_name=>TV)*)
(*%E*)
IMPLEMENTATION MODULE Menus;

FROM Objects IMPORT
  PString, TRect, String, TPoint, NewStr, DisposeStr;
FROM Streams IMPORT
  TStream;
FROM Views IMPORT
  PView, TView, PPalette, TCommandSet, TViewGrowMode, TViewGrowModes,
  TViewOption, TViewOptions, TViewState, TViewStates, CommandEnabled;
FROM Commands IMPORT
  cmMenu, hcNoContext, cmCommandSetChanged;
FROM Drivers IMPORT
  Assert, TEvent, EventTypes, EventType, Button, Buttons, TDrawBuffer,
  CtrlToArrow, GetAltChar, evNothing, kbNoKey, CStrLen, MoveChar, MoveCStr,
  MoveBuf, PutChar, MoveStr,
  kbUp, kbDown, kbLeft, kbRight, kbHome, kbEnd, kbEnter, kbNoKey, kbEsc ;
FROM Texts IMPORT
  MenuFrameChars, HintSeparator, CMenuView, CStatusLine;
FROM Storage IMPORT
  ALLOCATE, DEALLOCATE;
FROM Str IMPORT
  Pos, Length, Copy, Delete;

  CLASS IMPLEMENTATION TMenuView;

    PROCEDURE Init(VAR Bounds: TRect);
    BEGIN
      TView.Init ( Bounds );
      INCL( EventMask, evBroadcast );
    END Init;

    PROCEDURE Load(VAR S: TStream);

      PROCEDURE ReadMenu( ) : PMenu;
      VAR
        menu : PMenu;
        last : POINTER TO PMenuItem;
        item : PMenuItem;
        tok  : SHORTCARD;
      BEGIN
        NEW( menu );
        last := ADR(menu^.Items);
        item := NIL;
        S.Rd(tok);
        WHILE tok # 0 DO
          Assert( tok = 0FFH );
          item := NewItem( '', '', 0, 0, 0, NIL );
          last^ := item;
          last := ADR(item^.Next);
          item^.Name := S.ReadStr(255);
          S.Rd(item^.Command);
          S.Rd(item^.Disabled);
          S.Rd(item^.KeyCode);
          S.Rd(item^.HelpCtx);
          IF item^.Name # NIL THEN
            IF item^.Command = 0 THEN
              item^.SubMenu := ReadMenu( );
            ELSE
              item^.Param := S.ReadStr(255);
            END;
          END;
          S.Rd(tok);
        END;
        last^ := NIL;
        menu^.Default := menu^.Items;
        RETURN menu;
      END ReadMenu;

    BEGIN
      TView.Load( S );
      Menu := ReadMenu( );
    END Load;

    VIRTUAL PROCEDURE Execute(): CARDINAL;

      PROCEDURE TrackMouse( VAR e : TEvent );
      VAR
        mouse : TPoint;
        r     : TRect;
      BEGIN
        mouse := MakeLocal( e.Where );
        Current := Menu^.Items;
        WHILE Current # NIL DO
          r := GetItemRect( Current );
          IF r.Contains( mouse ) THEN
            RETURN;
          END;
          Current := Current^.Next;
        END;
      END TrackMouse;
  
      PROCEDURE NextItem;
      BEGIN
        Current := Current^.Next;
        IF Current = NIL THEN
          Current := Menu^.Items;
        END;
      END NextItem;
  
      PROCEDURE PrevItem;
      VAR
        p : PMenuItem;
      BEGIN
        p := Current;
        IF p = Menu^.Items THEN
          p := NIL;
        END;
        REPEAT
          NextItem;
        UNTIL Current^.Next = p;
      END PrevItem;
  
      PROCEDURE TrackKey( FindNext : BOOLEAN );
      BEGIN
        IF Current = NIL THEN
          RETURN;
        END;
        REPEAT
          IF FindNext THEN
            NextItem;
          ELSE
            PrevItem();
          END;
        UNTIL Current^.Name # NIL;
      END TrackKey;
  
      PROCEDURE MouseInOwner( VAR e : TEvent ) : BOOLEAN;
      VAR
        mouse : TPoint;
        r     : TRect;
      BEGIN
        IF (ParentMenu = NIL) OR (ParentMenu^.Size.Y # 1 ) THEN
          RETURN FALSE;
        ELSE
          mouse := ParentMenu^.MakeLocal( e.Where );
          r := ParentMenu^.GetItemRect( ParentMenu^.Current );
          RETURN r.Contains( mouse );
        END;
      END MouseInOwner;
  
      PROCEDURE MouseInMenus( VAR e : TEvent ) : BOOLEAN;
      VAR
        p : PMenuView;
      BEGIN
        p := ParentMenu;
        WHILE ( p # NIL ) & NOT p^.MouseInView(e.Where) DO
          p := p^.ParentMenu;
        END;
        RETURN p # NIL;
      END MouseInMenus;
  
      PROCEDURE TopMenu():PMenuView;
      VAR
        p : PMenuView;
      BEGIN
        p := ADR(SELF);
        WHILE p^.ParentMenu # NIL DO
          p := p^.ParentMenu;
        END;
        RETURN p;
      END TopMenu;




    TYPE
      MenuAction = ( doNothing, doSelect, doReturn );
    VAR
      autoSelect : BOOLEAN;
      action     : MenuAction;
      ch         : CHAR;
      result     : CARDINAL;
      itemShown  : PMenuItem;
      p          : PMenuItem;
      target     : PMenuView;
      r          : TRect;
      e          : TEvent;
    BEGIN
      autoSelect := FALSE;
      result := 0;
      itemShown := NIL;
      Current := Menu^.Default;
      REPEAT
        action := doNothing;
        GetEvent(e);
        IF evMouseDown IN e.What THEN
          IF MouseInView(e.Where) OR MouseInOwner(e) THEN
            TrackMouse(e);
            IF Size.Y = 1 THEN
              autoSelect := TRUE;
            END;
          ELSE
            action :=  doReturn;
          END;
        ELSIF evMouseUp IN e.What THEN
          TrackMouse(e);
          IF MouseInOwner(e) THEN
            Current := Menu^.Default;
          ELSIF (Current # NIL) & (Current^.Name # NIL ) THEN
            action := doSelect;
          ELSE
            action := doReturn;
          END;
        ELSIF evMouseMove IN e.What THEN
          IF e.Buttons # Buttons{} THEN
            TrackMouse(e);
            IF NOT MouseInView(e.Where) OR MouseInOwner(e) & MouseInMenus(e) THEN
              action := doReturn;
            END;
          END;
        ELSIF evKeyDown IN e.What THEN
          CASE CtrlToArrow(e.KeyCode) OF
          | kbUp, kbDown:
              IF Size.Y # 1 THEN
                TrackKey(CtrlToArrow(e.KeyCode) = kbDown);
              ELSIF e.KeyCode = kbDown THEN
                autoSelect :=  TRUE;
              END;
          | kbLeft, kbRight:
              IF ParentMenu = NIL THEN
                TrackKey(CtrlToArrow(e.KeyCode) = kbRight);
              ELSE
                action :=  doReturn;
              END;
          | kbHome, kbEnd:
              IF Size.Y # 1 THEN
                Current := Menu^.Items;
                IF e.KeyCode = kbEnd THEN
                  TrackKey(FALSE);
                END;
              END;
          | kbEnter:
              IF Size.Y = 1 THEN
                autoSelect := TRUE;
              END;
              action := doSelect;
          | kbEsc:
              action := doReturn;
              IF (ParentMenu = NIL) OR (ParentMenu^.Size.Y # 1) THEN
                ClearEvent(e);
              END;
          ELSE
            target := ADR(SELF);
            ch := GetAltChar(e.KeyCode);
            IF ch = 0C THEN
              ch := e.CharCode;
            ELSE
              target := TopMenu();
            END;
            p := target^.FindItem(ch);
            IF p = NIL THEN
              p := TopMenu()^.HotKey(e.KeyCode);
              IF (p # NIL) & CommandEnabled( VAL( SHORTCARD, p^.Command) ) THEN
                result := p^.Command;
                action := doReturn;
              END;
            ELSIF target = ADR(SELF) THEN
              IF Size.Y = 1 THEN
                autoSelect := TRUE;
              END;
              action := doSelect;
              Current := p;
            ELSIF (ParentMenu # target) OR (ParentMenu^.Current # p ) THEN
              action := doReturn;
            END;
          END;
        ELSIF evCommand IN e.What THEN
          IF e.Command = cmMenu THEN
            autoSelect := FALSE;
            IF ParentMenu # NIL THEN
              action := doReturn;
            END;
          ELSE
            action := doReturn;
          END;
        END;
        IF itemShown # Current THEN
          itemShown := Current;
          DrawView();
        END;
        IF ((action = doSelect) OR (action = doNothing) & autoSelect) &
           (Current # NIL) & (Current^.Name # NIL)
        THEN
          IF Current^.Command = 0 THEN
(*
            IF EventTypes{ evMouseDown, evMouseMove } * e.What # EventTypes{} THEN
              PutEvent(e);
            END;
*)
            r := GetItemRect( Current );
            r.A.X := r.A.X + Origin.X;
            r.A.Y := r.B.Y + Origin.Y;
            r.B := Owner^.Size;
            IF Size.Y = 1 THEN
              DEC( r.A.X );
            END;
            target := TopMenu()^.NewSubView(r, Current^.SubMenu, ADR(SELF));
            result := Owner^.ExecView(target);
            target^.Done;
            DISPOSE( target );
          ELSIF action = doSelect THEN
            result := Current^.Command;
          END;
        END;
        IF (result # 0) & CommandEnabled(VAL(SHORTCARD, result)) THEN
          action :=  doReturn;
          ClearEvent(e);
        END;
      UNTIL action = doReturn;
      IF (e.What # evNothing) &
         ((ParentMenu # NIL) OR (e.What = EventTypes{evCommand}))
      THEN
        PutEvent(e);
      END;
      IF Current # NIL THEN
        Menu^.Default := Current;
        Current := NIL;
        DrawView;
      END;
      RETURN result;
    END Execute;

    PROCEDURE FindItem(Ch: CHAR): PMenuItem;
    VAR
      p : PMenuItem;
      loc : CARDINAL;
    BEGIN
      Ch := CAP(Ch);
      p := Menu^.Items;
      WHILE p # NIL DO
        IF (p^.Name # NIL) & NOT p^.Disabled THEN
          loc := Pos(p^.Name^, '~');
          IF (loc # MAX(CARDINAL)) & ( Ch = CAP( p^.Name^[loc+1] )) THEN
            RETURN p;
          END;
        END;
        p :=  p^.Next;
      END;
      RETURN NIL;
    END FindItem;

    VIRTUAL PROCEDURE GetItemRect( Item: PMenuItem ) : TRect;
    VAR
      r : TRect;
    BEGIN
      r.Assign(0, 0, 0, 0);
      RETURN r;
    END GetItemRect;

    VIRTUAL PROCEDURE GetHelpCtx(): CARDINAL;
    VAR
      c : PMenuView;
    BEGIN
      c := ADR(SELF);
      WHILE (c # NIL) &
            ((c^.Current = NIL) OR (c^.Current^.HelpCtx = hcNoContext) OR
             (c^.Current^.Name = NIL ))
      DO
          c := c^.ParentMenu;
      END;
      IF c # NIL THEN
        RETURN c^.Current^.HelpCtx;
      ELSE
        RETURN hcNoContext;
      END;
    END GetHelpCtx;

    VIRTUAL PROCEDURE GetPalette(): PPalette;
    BEGIN
      RETURN ADR(CMenuView);
    END GetPalette;

    VIRTUAL PROCEDURE HandleEvent(VAR Event: TEvent);

      PROCEDURE UpdateMenu( menu : PMenu ) : BOOLEAN;
      VAR
        res : BOOLEAN;
        p   : PMenuItem;
        commandState : BOOLEAN;
      BEGIN
        res := FALSE;
        p := menu ^.Items;
        WHILE p # NIL DO
          IF p^.Name # NIL THEN
            IF p^.Command = 0 THEN
              IF UpdateMenu(p^.SubMenu) THEN
                res := TRUE;
              END;
            ELSE
              commandState := CommandEnabled( VAL(SHORTCARD, p^.Command ));
              IF p^.Disabled = commandState THEN
                p^.Disabled := NOT commandState;
                res := TRUE;
              END;
            END;
          END;
          p := p^.Next;
        END;
        RETURN res;
      END UpdateMenu;

      PROCEDURE Do_a_select( VAR Event : TEvent );
      BEGIN
        PutEvent( Event );
        Event.Command := Owner^.ExecView(ADR(SELF));
        IF (Event.Command # 0) & CommandEnabled(VAL(SHORTCARD, Event.Command)) THEN
          Event.What := EventTypes{ evCommand };
          Event.InfoPtr := NIL;
          PutEvent(Event);
        END;
        ClearEvent(Event);
      END Do_a_select;

    VAR
      p : PMenuItem;
    BEGIN
      IF Menu # NIL THEN
        IF evMouseDown IN Event.What THEN
          Do_a_select(Event);
        ELSIF evKeyDown IN Event.What THEN
          IF FindItem(GetAltChar(Event.KeyCode)) # NIL THEN
            Do_a_select(Event);
          ELSE
            p := HotKey(Event.KeyCode);
            IF (p # NIL) & CommandEnabled(VAL(SHORTCARD, p^.Command)) THEN
              Event.What := EventTypes{ evCommand };
              Event.Command := p^.Command;
              Event.InfoPtr := NIL;
              PutEvent(Event);
              ClearEvent(Event);
            END;
          END;
        ELSIF evCommand IN Event.What THEN
          IF Event.Command = cmMenu THEN
            Do_a_select(Event);
          END;
        ELSIF evBroadcast IN Event.What THEN
          IF Event.Command = cmCommandSetChanged THEN
            IF UpdateMenu(Menu) THEN
              DrawView;
            END;
          END;
        END;
      END;
    END HandleEvent;

    PROCEDURE HotKey(KeyCode: CARDINAL): PMenuItem;

      PROCEDURE FindHotKey(p : PMenuItem; _keyCode : CARDINAL) : PMenuItem;
      VAR
        T : PMenuItem;
      BEGIN
        WHILE p # NIL DO
          WITH p^ DO
            IF Name # NIL THEN
              IF Command = 0 THEN
                T := FindHotKey( SubMenu^.Items, _keyCode );
                IF T # NIL THEN
                  RETURN T;
                END;
              ELSIF NOT Disabled & (KeyCode # kbNoKey) & (KeyCode = _keyCode) THEN
                RETURN p;
              END;
            END;
            p := Next;
          END;
        END;
        RETURN NIL;
      END FindHotKey;
 
    BEGIN
      RETURN FindHotKey( Menu^.Items, KeyCode );
    END HotKey;

    VIRTUAL PROCEDURE NewSubView(VAR Bounds: TRect;
                                     AMenu: PMenu;
                                     AParentMenu: PMenuView): PMenuView;
    VAR
      p : PMenuBox;
    BEGIN
     NEW(p);
     p^.Init( Bounds, AMenu, AParentMenu );
     RETURN p;
    END NewSubView;

    PROCEDURE Store(VAR S: TStream);

      PROCEDURE StoreMenu( menu : PMenu );
      VAR
        tok : SHORTCARD;
        item : PMenuItem;
      BEGIN
        tok := 0FFH;
        item := menu^.Items;
        WHILE item # NIL DO
          WITH item^ DO
            S.Wr(tok);
            S.WriteStr( Name );
            S.Wr(Command);
            S.Wr(Disabled);
            S.Wr(KeyCode);
            S.Wr(HelpCtx);
            IF Name # NIL THEN
              IF Command = 0 THEN
                StoreMenu( SubMenu );
              ELSE
                S.WriteStr( Param );
              END;
            END;
            item := Next;
          END;
        END;
        tok := 0;
        S.Wr(tok);
      END StoreMenu;

    BEGIN
      TView.Store( S );
      StoreMenu( Menu );
    END Store;

  BEGIN
    ParentMenu := NIL;
    Menu := NIL;
    Current := NIL;
  END TMenuView;

  CLASS IMPLEMENTATION TMenuBar;

    PROCEDURE Init(VAR Bounds: TRect;
                       AMenu: PMenu);
    BEGIN
      TMenuView.Init( Bounds );
      Menu := AMenu;
      GrowMode := TViewGrowModes{ gfGrowHiX };
      INCL( Options, ofPreProcess);
    END Init;

    VIRTUAL PROCEDURE Done;
    BEGIN
      DISPOSE( Menu );
      TMenuView.Done;
    END Done;

    VIRTUAL PROCEDURE Draw;
    VAR
      color : CARDINAL;
      x, l  : INTEGER;
      p     : PMenuItem;
      b     : TDrawBuffer;
      cNormal,
      cSelect,
      cNormDisabled,
      cSelDisabled : CARDINAL;
    BEGIN
      cNormal := GetColor(00301H);
      cSelect := GetColor(00604H);
      cNormDisabled := GetColor(00202H);
      cSelDisabled := GetColor(00505H);
      MoveChar( b, 0, ' ', cNormal, Size.X );
      IF Menu # NIL THEN
        x := 1;
        p := Menu^.Items;
        WHILE p # NIL DO
          IF p^.Name # NIL THEN
            l := CStrLen(p^.Name^);
            IF x + l < Size.X THEN
              IF p^.Disabled THEN
                IF p = Current THEN
                  color := cSelDisabled;
                ELSE
                  color := cNormDisabled;
                END;
              ELSE
                IF p = Current THEN
                  color := cSelect;
                ELSE
                  color := cNormal;
                END;
              END;
              MoveChar( b, x, ' ', color, 1 );
              MoveCStr( b, x+1, p^.Name^, color );
              MoveChar( b, x+l+1, ' ', color, 1 );
            END;
            INC(x, l + 2 );
          END;
          p := p^.Next;
        END;
      END;
      WriteBuf( 0, 0, Size.X, 1, FarADR(b) );
    END Draw;

    VIRTUAL PROCEDURE GetItemRect(Item: PMenuItem): TRect;
    VAR
      r : TRect;
      p : PMenuItem;
    BEGIN
      r.Assign( 1, 0, 1, 1 );
      p := Menu^.Items;
      LOOP
        r.A.X := r.B.X;
        IF p^.Name # NIL THEN
          INC( r.B.X, CStrLen(p^.Name^) + 2);
        END;
        IF p = Item THEN
          RETURN r;
        END;
        p := p^.Next;
      END;
    END GetItemRect;

  BEGIN
  END TMenuBar;

  PROCEDURE GetRect( Bounds : TRect; AMenu : PMenu ) : TRect;
  VAR
    l, w, h : INTEGER;
    p : PMenuItem;
  BEGIN
    w :=  10;
    h :=  2;
    IF AMenu # NIL THEN
      p := AMenu^.Items;
      WHILE p # NIL DO
        IF p^.Name # NIL THEN
          l := CStrLen(p^.Name^) + 6;
          IF p^.Command = 0 THEN
            INC( l, 3);
          ELSE
            IF p^.Param # NIL THEN
              INC( l, CStrLen(p^.Param^) + 2);
            END;
          END;
          IF l > w THEN
            w := l;
          END;
        END;
        INC(h);
        p := p^.Next;
      END;
    END;
    IF Bounds.A.X + w < Bounds.B.X THEN
      Bounds.B.X := Bounds.A.X + w;
    ELSE
      Bounds.A.X := Bounds.B.X - w;
    END;
    IF Bounds.A.Y + h < Bounds.B.Y THEN
      Bounds.B.Y := Bounds.A.Y + h;
    ELSE
      Bounds.A.Y := Bounds.B.Y - h;
    END;
    RETURN Bounds;
  END GetRect;

  CLASS IMPLEMENTATION TMenuBox;

    PROCEDURE Init(VAR Bounds: TRect;
                       AMenu: PMenu;
                       AParentMenu: PMenuView);
    VAR
      r : TRect;
    BEGIN
      r := GetRect( Bounds, AMenu );
      TMenuView.Init( r );
      Menu := AMenu;
      ParentMenu := AParentMenu;
      INCL( State, sfShadow );
      INCL( Options, ofPreProcess );
    END Init;

    VIRTUAL PROCEDURE Draw;
    VAR
      cNormal,
      cSelect,
      cNormDisabled,
      cSelDisabled,
      color : CARDINAL;
      y : CARDINAL;
      b : TDrawBuffer;
      p : PMenuItem;

      PROCEDURE FrameLine( n : CARDINAL );
      BEGIN
        MoveBuf( b, 0, PString(ADR(MenuFrameChars[n]))^, cNormal, 2 );
        MoveChar( b, 2, MenuFrameChars[n+2], color, Size.X - 4 );
        MoveBuf( b, Size.X-2, PString(ADR(MenuFrameChars[n+3]))^, cNormal, 2 );
      END FrameLine;

    BEGIN
      cNormal := GetColor(00301H);
      cSelect := GetColor(00604H);
      cNormDisabled := GetColor(00202H);
      cSelDisabled := GetColor(00505H);
      y := 0;
      color :=  cNormal;
      FrameLine( 0 );
      WriteBuf( 0, y, Size.X, 1, FarADR(b) );
      INC(y);
      IF Menu # NIL THEN
        p := Menu^.Items;
        WHILE p # NIL DO
          color := cNormal;
          IF p^.Name = NIL THEN
            FrameLine( 15 );
          ELSE
            IF p^.Disabled THEN
              IF p = Current THEN
                color := cSelDisabled;
              ELSE
                color := cNormDisabled;
              END;
            ELSIF p = Current THEN
              color := cSelect;
            END;
            FrameLine( 10 );
            MoveCStr( b, 3, p^.Name^, color );
            IF p^.Command = 0 THEN
              PutChar( b, Size.X-4, CHR(16) );
            ELSIF p^.Param # NIL THEN
              MoveStr( b, Size.X-3-VAL(INTEGER, Length(p^.Param^)), p^.Param^, color);
            END;
          END;
          WriteBuf( 0, y, Size.X, 1, FarADR(b) );
          INC(y);
          p := p^.Next;
        END;
      END;
      color := cNormal;
      FrameLine( 5 );
      WriteBuf( 0, y, Size.X, 1, FarADR(b) );
(*      INC(y);*)
    END Draw;

    VIRTUAL PROCEDURE GetItemRect( Item: PMenuItem) : TRect;
    VAR
      y : CARDINAL;
      p : PMenuItem;
      r : TRect;
    BEGIN
      y := 1;
      p := Menu^.Items;
      WHILE p # Item DO
        INC( y );
        p := p^.Next;
      END;
      r.Assign( 2, y, Size.X-2, y+1 );
      RETURN r;
    END GetItemRect;

  BEGIN
  END TMenuBox;

  CLASS IMPLEMENTATION TStatusLine;

    PROCEDURE Init(VAR Bounds: TRect;
                       ADefs: PStatusDef);
    BEGIN
      TView.Init( Bounds );
      Defs := ADefs;
      INCL( Options, ofPreProcess);
      INCL(EventMask, evBroadcast);
      GrowMode := TViewGrowModes{ gfGrowLoY, gfGrowHiX, gfGrowHiY };
      FindItems;
    END Init;

    PROCEDURE Load(VAR S: TStream);

      PROCEDURE ReadItems( ) : PStatusItem;
      VAR
        cur, first : PStatusItem;
        last : POINTER TO PStatusItem;
        count, key, cmd : INTEGER;
        t : PString;
      BEGIN
        cur := NIL;
        last := ADR(first);
        S.Rd(count);
        WHILE count > 0  DO
          t := S.ReadStr(255);
          S.Rd(key);
          S.Rd(cmd);
          cur := NewStatusKey(t^, key, cmd, NIL);
          last^ := cur;
          last := ADR(cur^.Next);
          DEC( count );
        END;
        last^ := NIL;
        RETURN first;
      END ReadItems;

      PROCEDURE ReadDefs( ) : PStatusDef;
      VAR
        cur, first : PStatusDef;
        last : POINTER TO PStatusDef;
        count, Max, Min : INTEGER;
      BEGIN
        cur := NIL;
        last := ADR(first);
        S.Rd(count);
        WHILE count > 0  DO
          S.Rd(Min);
          S.Rd(Max);
          cur := NewStatusDef(Min, Max, ReadItems(), NIL);
          last^ := cur;
          last := ADR(cur^.Next);
          DEC( count );
        END;
        last^ := NIL;
        RETURN first;
     END ReadDefs;

    BEGIN
        TView.Load( S );
        Defs := ReadDefs( );
        FindItems;
    END Load;

    VIRTUAL PROCEDURE Done;

      PROCEDURE DisposeItems(Item : PStatusItem);
      VAR
        T : PStatusItem;
      BEGIN
        WHILE Item # NIL DO
          T := Item;
          Item := Item^.Next;
          IF T^.Text # NIL THEN
            DisposeStr( T^.Text );
          END;
          DISPOSE(T);
        END;
      END DisposeItems;

    VAR
      T : PStatusDef;
    BEGIN
      WHILE Defs # NIL DO
        T := Defs;
        Defs := Defs^.Next;
        DisposeItems( T^.Items );
        DISPOSE( T );
      END;
      TView.Done;
    END Done;

    VIRTUAL PROCEDURE Draw;
    BEGIN
      DrawSelect(NIL);
    END Draw;

    PROCEDURE DrawSelect( selected : PStatusItem );
    VAR
      b: TDrawBuffer;
      color : CARDINAL;
      hintBuf : String;
      cNormal,
      cSelect,
      cNormDisabled,
      cSelDisabled : CARDINAL;
      T : PStatusItem;
      i, l : INTEGER;
    BEGIN
      cNormal := GetColor(00301H);
      cSelect := GetColor(00604H);
      cNormDisabled := GetColor(00202H);
      cSelDisabled := GetColor(00505H);
      MoveChar( b, 0, ' ', cNormal, Size.X );
      T := Items;
      i := 0;
      WHILE T # NIL DO
        IF T^.Text # NIL THEN
          l := CStrLen( T^.Text^ );
          IF i + l < Size.X THEN
            IF CommandEnabled( VAL(SHORTCARD, T^.Command)) THEN
              IF T = selected THEN
                color := cSelect;
              ELSE
                color := cNormal;
              END;
            ELSE
              IF T = selected THEN
                color := cSelDisabled;
              ELSE
                color := cNormDisabled;
              END;
            END;
            MoveChar( b, i, ' ', color, 1 );
            MoveCStr( b, i+1, T^.Text^, color );
            MoveChar( b, i+l+1, ' ', color, 1 );
          END;
          INC( i, l+2);
        END;
        T := T^.Next;
      END;
      IF i < Size.X - 2 THEN
        Copy( hintBuf, Hint( HelpCtx ) );
        IF hintBuf[0] # 0C THEN
          MoveStr( b, i, HintSeparator, cNormal );
          INC( i, 2);
          IF VAL(INTEGER, Length(hintBuf)) + i > Size.X THEN
            hintBuf[Size.X-i] := 0C;
          END;
          MoveStr( b, i, hintBuf, cNormal );
          INC( i, Length(hintBuf));
         END;
       END;
      WriteLine( 0, 0, Size.X, 1, b );
    END DrawSelect;

    VIRTUAL PROCEDURE GetPalette(): PPalette;
    BEGIN
      RETURN ADR(CStatusLine);
    END GetPalette;

    VIRTUAL PROCEDURE HandleEvent(VAR Event: TEvent);

      PROCEDURE ItemMouseIsIn( mouse : TPoint ) : PStatusItem;
      VAR
        k, i : INTEGER;
        T : PStatusItem;
      BEGIN
        IF mouse.Y # 0 THEN
          RETURN NIL;
        END;
        i := 0;
        T := Items;
        WHILE T # NIL DO
          IF T^.Text # NIL THEN
            k := i + VAL(INTEGER, CStrLen(T^.Text^)) + 2;
            IF (mouse.X >= i) & (mouse.X < k ) THEN
              RETURN T;
            END;
            i := k;
          END;
          T := T^.Next;
        END;
        RETURN NIL;
      END ItemMouseIsIn;

    VAR
      T : PStatusItem;
      mouse : TPoint;
    BEGIN
      TView.HandleEvent(Event);
      IF evMouseDown IN Event.What THEN
        T := NIL;
        REPEAT
          mouse := MakeLocal( Event.Where );
          IF T # ItemMouseIsIn(mouse) THEN
            T := ItemMouseIsIn(mouse);
            DrawSelect( T );
          END;
        UNTIL NOT MouseEvent( Event, EventTypes{ evMouseMove } );
        IF (T # NIL) & CommandEnabled( VAL( SHORTCARD, T^.Command)) THEN
          Event.What := EventTypes{ evCommand };
          Event.Command := T^.Command;
          Event.InfoPtr := NIL;
          PutEvent(Event);
        END;
        ClearEvent(Event);
        DrawView();
      ELSIF evKeyDown IN Event.What THEN
        T := Items;
        WHILE T # NIL DO
          IF (Event.KeyCode = T^.KeyCode) & CommandEnabled( VAL(SHORTCARD, T^.Command)) THEN
            Event.What := EventTypes{ evCommand };
            Event.Command := T^.Command;
            Event.InfoPtr := NIL;
            RETURN;
          END;
          T := T^.Next;
        END;
      ELSIF evBroadcast IN Event.What THEN
        IF Event.Command = cmCommandSetChanged THEN
          DrawView;
        END;
      END;
    END HandleEvent;

    VIRTUAL PROCEDURE Hint(AHelpCtx: CARDINAL): String;
    BEGIN
      RETURN '';
    END Hint;

    PROCEDURE Store(VAR S: TStream);

      PROCEDURE WriteItems(ts : PStatusItem);
      VAR
        count : INTEGER;
        t : PStatusItem;
      BEGIN
        count := 0;
        t := ts;
        WHILE t # NIL DO
          INC( count );
          t := t^.Next;
        END;
        S.Wr( count );
        WHILE ts # NIL DO
          S.WriteStr( ts^.Text );
          S.Wr(ts^.KeyCode);
          S.Wr(ts^.Command);
          ts := ts^.Next;
        END;
      END WriteItems;

      PROCEDURE WriteDefs( td : PStatusDef );
      VAR
        count : INTEGER;
        t : PStatusDef;
      BEGIN
        count := 0;
        t := td;
        WHILE t # NIL DO
          INC( count );
          t := t^.Next;
        END;
        S.Wr( count );
        WHILE td # NIL DO
          S.Wr(td^.Min);
          S.Wr(td^.Max);
          WriteItems(td^.Items);
          td := td^.Next;
        END;
      END WriteDefs;

    BEGIN
      TView.Store( S );
      WriteDefs( Defs );
    END Store;

    VIRTUAL PROCEDURE Update;
    VAR
      p : PView;
      h : CARDINAL;
    BEGIN
      p := TopView();
      IF p # NIL THEN
        h := p^.GetHelpCtx();
      ELSE
        h := hcNoContext;
      END;
      IF HelpCtx # h THEN
        HelpCtx := h;
        FindItems;
        DrawView;
      END;
    END Update;

    PROCEDURE FindItems;
    VAR
      p : PStatusDef;
    BEGIN
      p := Defs;
      WHILE (p # NIL) & ((HelpCtx < p^.Min) OR (HelpCtx > p^.Max )) DO
        p := p^.Next;
      END;
      IF p = NIL THEN
        Items := NIL;
      ELSE
        Items := p^.Items;
      END;
    END FindItems;

  BEGIN
  END TStatusLine;

PROCEDURE Allocate(VAR s : ARRAY OF CHAR) : PString;
BEGIN
  Delete(s, 32, 0FFFH);
  IF s[0] # 0C THEN
    RETURN NewStr( s )
  ELSE
    RETURN NIL;
  END;
END Allocate;

PROCEDURE NewItem( AName,
                   AParam: ARRAY OF CHAR;
                   AKeyCode: CARDINAL;
                   ACommand: CARDINAL;
                   AHelpCtx: CARDINAL;
                   ANext: PMenuItem): PMenuItem;
VAR
  p : PMenuItem;
BEGIN
  NEW(p);
  WITH p^ DO
    Next := ANext;
    Name := Allocate(AName);
    Command := ACommand;
    Disabled := NOT CommandEnabled( VAL( SHORTCARD, ACommand ));
    KeyCode := AKeyCode;
    HelpCtx := AHelpCtx;
    Param := Allocate(AParam);
  END;
  RETURN p;
END NewItem;

PROCEDURE NewLine(Next: PMenuItem): PMenuItem;
BEGIN
  RETURN NewItem( '', '', 0, 0, hcNoContext, Next);
END NewLine;

PROCEDURE NewSubMenu( AName: ARRAY OF CHAR;
                      AHelpCtx: CARDINAL;
                      ASubMenu: PMenu;
                      ANext: PMenuItem): PMenuItem;
VAR
  p : PMenuItem;
BEGIN
  NEW(p);
  WITH p^ DO
    Next := ANext;
    Name := Allocate(AName);
    Command := 0;
    Disabled := FALSE;
    KeyCode := kbNoKey;
    HelpCtx := AHelpCtx;
    SubMenu := ASubMenu;
  END;
  RETURN p;
END NewSubMenu;

PROCEDURE NewMenu(AItems: PMenuItem): PMenu;
VAR
  p : PMenu;
BEGIN
  NEW(p);
  WITH p^ DO
    Items := AItems;
    Default := AItems;
  END;
  RETURN p;
END NewMenu;

PROCEDURE DisposeMenu(Menu: PMenu);

  PROCEDURE DisposeSubMenu(i : PMenu);
  VAR
    p, q : PMenuItem;
  BEGIN
    q := i^.Items;
    WHILE q # NIL DO
      p := q;
      WITH p^ DO
        IF p^.Command = 0 THEN
          DisposeSubMenu(p^.SubMenu);
        ELSE
          IF Name # NIL THEN
            DisposeStr(Name);
          END;
          IF Param # NIL THEN
            DisposeStr(Param);
          END;
        END;
      END;
      q := q^.Next;
    END;
  END DisposeSubMenu;

BEGIN
  DisposeSubMenu(Menu);
END DisposeMenu;

PROCEDURE NewStatusDef( AMin,
                        AMax: CARDINAL;
                        AItems: PStatusItem;
                        ANext: PStatusDef): PStatusDef;
VAR
  p : PStatusDef;
BEGIN
  NEW(p);
  WITH p^ DO
    Min := AMin;
    Max := AMax;
    Items := AItems;
    Next := ANext;
  END;
  RETURN p;
END NewStatusDef;

PROCEDURE NewStatusKey( AText: ARRAY OF CHAR;
                        AKeyCode: CARDINAL;
                        ACommand: CARDINAL;
                        ANext: PStatusItem): PStatusItem;
VAR
  p : PStatusItem;
BEGIN
  NEW(p);
  WITH p^ DO
    Text := Allocate(AText);
    KeyCode := AKeyCode;
    Command := ACommand;
    Next := ANext;
  END;
  RETURN p;
END NewStatusKey;

PROCEDURE RegisterMenus;
END RegisterMenus;

END Menus.