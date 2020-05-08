(*.F- *)
(**********************************************************************
|  Title   : Obsluga list
|  Author  : MMorawski
|  System  : LOGITECH MODULA-2/86 
|  History :
|    06-20-97 06:26pm: MM
|       Dostawiony Semafor w SetSelectionInt
|    Rel 3.11: MPostol
|      Nowa procedura LiczbaElementow
|
|  Copyright (C), CAS LODZ POLAND.
|  TEL: 42' 686 25 47
|  mailto: techsupp@cas.com.pl
|  http: www.cas.com.pl
|
**********************************************************************)
(*.F+ *)
IMPLEMENTATION MODULE GList;

FROM GrafTypes IMPORT
  RECT, WHITE, CYAN, BLUE, GREEN, BLACK, YELLOW, IsEqual;
FROM MMMouse IMPORT
  Region, Event, EventSet, HideConditionally, ShowCursor, RegisterRegion,
  UnregisterRegion, ButtonSet, GetRegionRect;
FROM Semafory IMPORT
  Semafor, Init, Register, Unregister, Free, Set;
IMPORT
  MMMouse;
FROM ShortCuts IMPORT
  DefineShortCut, DeleteShortCut, kbEnter, kbEsc, kbUp, kbDown,
  kbPgUp, kbPgDn;
FROM Graphics IMPORT
  _Wr16StrXY, SetWindow, GetWindow;
FROM HiLevGraf IMPORT
  FillRect, FrameRect;
FROM Storage IMPORT
  ALLOCATE, DEALLOCATE;
FROM SYSTEM IMPORT
  ADR, ADDRESS, BYTE;
FROM Strings IMPORT
  Assign, CompareStr;

TYPE
  HLIST = POINTER TO ListDesc;
  StrPtr = POINTER TO StrDesc;
  StrDesc = RECORD
    string : ARRAY [0..63] OF CHAR;
    Next   : StrPtr;
  END;
  HCONTENT = StrPtr;
  ListDesc = RECORD
    Rect : RECT;
    Wierszy : INTEGER;
    Zawartosc : StrPtr;
    IloscElementow : INTEGER;
    SaveBackground : BOOLEAN;
    KillContents   : BOOLEAN; (* jesli FALSE to nie usuwa listy stringow *)
    Notification   : NotificationProc;
    AktPolozenieKursora, IdxPierwszegoWidocznego : INTEGER;
    RectUp, RectDn : RECT;
    All, ScrollUp, ScrollDn : Region;
    Next : HLIST;
    Ended : BOOLEAN;
    WDialogu : BOOLEAN;
    Sorted   : BOOLEAN;
    Enabled  : BOOLEAN;
    ZakonczonaOperacja : Semafor;

    (* zmienne do uzytku wewnetrznego procedur *)
    ipw : INTEGER;
    sel : INTEGER;
    Background : ADDRESS;
  END;


VAR
  CurH       : HLIST;
  Lista      : HLIST;


PROCEDURE SetNotificationProc( l : HLIST; np : NotificationProc );
BEGIN
  l^.Notification := np;
END SetNotificationProc;

PROCEDURE DummyNotification( i : INTEGER );
END DummyNotification;

PROCEDURE TworzListe( VAR R : RECT; sb, wd : BOOLEAN ) : HLIST;
VAR
  v : HLIST;
  w : CARDINAL;
BEGIN
  NEW( v );
  WITH v^ DO
    Rect := R;
    RectUp := R;
    RectUp.bottom := RectUp.top+8;
    INC( RectUp.left );
    DEC( RectUp.right );
    INC( RectUp.top );
    RectDn := R;
    RectDn.top := RectDn.bottom-8;
    INC( RectDn.left );
    DEC( RectDn.right );
    DEC( RectDn.bottom );
    w := R.bottom-R.top+1;
    DEC( w, 20 ); (* na scrollery *)
    Wierszy := w DIV 16;
    Zawartosc := NIL;
    Notification := DummyNotification;
    SaveBackground := sb;
    IloscElementow := 0;
    AktPolozenieKursora     := 0;
    IdxPierwszegoWidocznego := 0;
    Next := Lista;
    Lista := v;
    Ended := FALSE;
    Sorted := FALSE;
    KillContents := TRUE;
    WDialogu := wd;
    sel := 0;
    ipw := -7fffh;
    Enabled := TRUE;
    Init( ZakonczonaOperacja );

    RegisterRegion( EventSet{LeftDown}, Rect, RChoose, NIL, All);
    RegisterRegion( EventSet{LeftDown, RightDown}, RectUp, RScrollUp, NIL,
                    ScrollUp); (* MP zmaina w Dialog *)
    RegisterRegion( EventSet{LeftDown, RightDown}, RectDn, RScrollDn, NIL,
                    ScrollDn);
    IF SaveBackground THEN
      ALLOCATE( Background, ORD(Rect.bottom-Rect.top+1)*ORD(Rect.right-Rect.left+1));
      GetWindow( Background, Rect.left, Rect.top, Rect.right, Rect.bottom, 0, 0L );
    ELSE
      Background := NIL;
    END;
    FillRect( Rect, CYAN );
    FrameRect( Rect, YELLOW );
  END;
  RETURN v;
END TworzListe;

PROCEDURE SkasujWszystko( h : HLIST );

  PROCEDURE UsunStr( VAR s : StrPtr );
  BEGIN
    IF s # NIL THEN
      UsunStr( s^.Next );
      DISPOSE( s );
    END;
  END UsunStr;

BEGIN
  WITH h^ DO
    UsunStr( Zawartosc );
    IloscElementow := 0;
    AktPolozenieKursora := 0;
    IdxPierwszegoWidocznego := 0;
    sel := 0;
    (* Notification( -1 );*)
  END;
  Redraw( h );
END SkasujWszystko;

PROCEDURE Skasuj( h : HLIST; idx : INTEGER );
VAR
  s, p : StrPtr;
  i : INTEGER;
BEGIN
  WITH h^ DO
    IF idx >= IloscElementow THEN
      RETURN;
    END;
    p := Zawartosc;
    IF idx = 0 THEN
      Zawartosc := p^.Next;
      DISPOSE( p );
    ELSE
      FOR i := 2 TO idx DO
        p := p^.Next;
      END;
      s := p^.Next;
      p^.Next := s^.Next;
      DISPOSE( s );
    END;
    DEC( IloscElementow );
    IF AktPolozenieKursora > idx THEN
      SetSelection( h, AktPolozenieKursora-1 );
    END;
    IF IdxPierwszegoWidocznego > idx THEN
      DEC( IdxPierwszegoWidocznego );
    END;
    sel := -1000;
  END;
  Redraw( h );
END Skasuj;

PROCEDURE UsunListe( h : HLIST );
VAR
  li : HLIST;
BEGIN
  IF h^.KillContents THEN
    SkasujWszystko( h );
  END;
  IF Lista = h THEN
    Lista := h^.Next;
  ELSE
    li := Lista;
    WHILE li^.Next # h DO
      li := li^.Next;
    END;
    li^.Next := h^.Next;
  END;
  IF h = CurH THEN
    CurH := Lista;
  END;
  WITH h^ DO
    UnregisterRegion( All );
    UnregisterRegion( ScrollUp );
    UnregisterRegion( ScrollDn );
    IF SaveBackground THEN
      SetWindow( Background, Rect.left, Rect.top, Rect.right, Rect.bottom, 0, 0L );
      DEALLOCATE( Background, ORD(Rect.bottom-Rect.top+1)*ORD(Rect.right-Rect.top+1));
    ELSE
      FillRect( Rect, BLACK );
    END;
    Unregister( ZakonczonaOperacja );
  END;
  DISPOSE( h );
END UsunListe;

PROCEDURE DodajDoListy( h : HLIST; str : ARRAY OF CHAR );
VAR
  sp   : POINTER TO StrPtr;
  s, n : StrPtr;
  nr   : INTEGER;
BEGIN
  WITH h^ DO
    nr := 0;
    INC( IloscElementow );
    IF Zawartosc = NIL THEN
      sp := ADR( Zawartosc );
      n := NIL;
    ELSE
      s := Zawartosc;
      IF Sorted THEN
        IF CompareStr( str, Zawartosc^.string ) < 0  THEN
          sp := ADR( Zawartosc );
        ELSE
          WHILE (s^.Next # NIL) & ( CompareStr(str, s^.Next^.string) >= 0 ) DO
            s := s^.Next;
            INC( nr );
          END;
          sp := ADR( s^.Next );
        END;
      ELSE
        WHILE s^.Next # NIL DO
          s := s^.Next;
        END;
        sp := ADR( s^.Next );
      END;
    END;
    n := sp^;
    NEW( sp^ );
    WITH sp^^ DO
      Assign( str, string );
      Next := n;
    END;
    IF Sorted THEN
      Redraw( h );
    ELSE
      Draw( h );
    END;
(*
    IF nr <= AktPolozenieKursora THEN
      Notification( AktPolozenieKursora );
    END;
*)
    IF ( IloscElementow = 1 ) THEN (* tzn. zostal dostawiony pierwszy element *)
      Notification( 0 );
    END;

  END;
END DodajDoListy;

PROCEDURE WstawDoListy( h : HLIST; idx : INTEGER; str : ARRAY OF CHAR );
VAR
  s, sp : StrPtr;
  i : INTEGER;
BEGIN
  WITH h^ DO
    IF idx >= IloscElementow THEN
      DodajDoListy( h, str );
    ELSE
      NEW( sp );
      WITH sp^ DO
        Assign( str, string );
        Next := NIL;
      END;
      IF idx = 0 THEN
        sp^.Next := Zawartosc;
        Zawartosc := sp;
      END;
      s := Zawartosc;
      FOR i := 0 TO idx-1 DO
        s := s^.Next;
      END;
      sp^.Next := s^.Next;
      s^.Next := sp;
    END;
  END;
  Redraw( h );
END WstawDoListy ;

PROCEDURE Idx2Str( h : HLIST; idx : INTEGER; VAR s : ARRAY OF CHAR );
VAR
  sp : StrPtr;
  i : CARDINAL;
BEGIN
  WITH h^ DO
    IF (idx >= IloscElementow ) OR (idx < 0 ) THEN
      s[0] := 0C;
      RETURN;
    END;
    sp := Zawartosc;
    FOR i := 1 TO idx DO
      sp := sp^.Next;
    END;
    Assign( sp^.string, s );
  END;
END Idx2Str;


PROCEDURE ZmienListe( h : HLIST; idx : INTEGER; s : ARRAY OF CHAR );
VAR
  sp : StrPtr;
  i : CARDINAL;
BEGIN
  WITH h^ DO
    IF idx > IloscElementow THEN
      RETURN;
    END;
    sp := Zawartosc;
    FOR i := 1 TO idx DO
      sp := sp^.Next;
    END;
    Assign( s, sp^.string );
  END;
  Redraw( h );
END ZmienListe;

PROCEDURE LiczbaElementow
          (     h : HLIST): INTEGER;
BEGIN
  RETURN h^.IloscElementow;
END LiczbaElementow;

PROCEDURE kbHandler( a : ADDRESS );
VAR
  Event : ListEvent;
BEGIN
  IF CurH = NIL THEN
    RETURN;
  END;
  WITH Event DO
    CASE a.OFFSET OF
      kbEnter:
        Action := atChoose;
    | kbEsc:
        Action := atCancel;
    | kbDown:
        Action := atMove;
        Shift := +1;
    | kbUp:
        Action := atMove;
        Shift := -1;
    | kbPgDn:
        Action := atMove;
        Shift := +CurH^.Wierszy;
    | kbPgUp:
        Action := atMove;
        Shift := -CurH^.Wierszy;
    ELSE
      RETURN;
    END;
  END;
  HandleEvent( CurH, Event );
END kbHandler;

PROCEDURE RScrollUp( ev : EventSet; bs : ButtonSet; x, y : INTEGER );
VAR
  R : RECT;
  l : HLIST;
  Event : ListEvent;
BEGIN
  IF CurH = NIL THEN
    RETURN;
  END;
  GetRegionRect( MMMouse.GetRegion(), R );
  IF NOT IsEqual( R, CurH^.RectUp ) THEN
    l := Lista;
    WHILE NOT IsEqual( R, l^.RectUp ) DO
      l := l^.Next;
    END;
    IF l^.Enabled THEN
      Enable( l );
    ELSE
      RETURN;
    END;
  END;
  Event.Action := atMove;
  IF LeftDown IN ev THEN
    Event.Shift := -1;
  ELSE
    Event.Shift := -CurH^.Wierszy;
  END;
  HandleEvent( CurH, Event );
END RScrollUp;

PROCEDURE RScrollDn( ev : EventSet; bs : ButtonSet; x, y : INTEGER );
VAR
  R : RECT;
  l : HLIST;
  Event : ListEvent;
BEGIN
  IF CurH = NIL THEN
    RETURN;
  END;
  GetRegionRect( MMMouse.GetRegion(), R );
  IF NOT IsEqual( R, CurH^.RectDn ) THEN
    l := Lista;
    WHILE NOT IsEqual( R, l^.RectDn ) DO
      l := l^.Next;
    END;
    IF l^.Enabled THEN
      Enable( l );
    ELSE
      RETURN;
    END;
  END;
  Event.Action := atMove;
  IF LeftDown IN ev THEN
    Event.Shift := +1;
  ELSE
    Event.Shift := +CurH^.Wierszy;
  END;
  HandleEvent( CurH, Event );
END RScrollDn;

PROCEDURE RChoose( ev : EventSet; bs : ButtonSet; x, y : INTEGER );
VAR
  R : RECT;
  l : HLIST;
  Event : ListEvent;
  Reg : MMMouse.Region;
BEGIN
  IF CurH = NIL THEN
    RETURN;
  END;
  Reg := MMMouse.GetRegion();
  GetRegionRect( Reg, R );
  IF (Reg # Region(NIL)) & NOT IsEqual( R, CurH^.Rect ) THEN
    l := Lista;
    WHILE NOT IsEqual( R, l^.Rect ) DO
      l := l^.Next;
    END;
    IF l^.Enabled THEN
      Enable( l );
    ELSE
      RETURN;
    END;
  END;
  WITH CurH^ DO
    Event.Shift := (y-10) DIV 16;
    INC( Event.Shift, IdxPierwszegoWidocznego );
    DEC( Event.Shift, AktPolozenieKursora );
    Event.Action := atMoveAndChoose;
    HandleEvent( CurH, Event );
  END;
END RChoose;

PROCEDURE CP( c : CARDINAL ) : ADDRESS;
VAR
  a : ADDRESS;
BEGIN
  a.SEGMENT := 0;
  a.OFFSET := c;
  RETURN a;
END CP;

PROCEDURE Wybor( h : HLIST ) : INTEGER;
BEGIN
  Enable( h );
  Redraw( h );
  REPEAT
  UNTIL h^.Ended;
END Wybor;

PROCEDURE Redraw( h : HLIST );
BEGIN
  WITH h^ DO
    ipw := -1000;
    sel := -1000;
  END;
  Draw( h );
END Redraw;

PROCEDURE Draw( h : HLIST );

  PROCEDURE WrStr( idx : INTEGER; fore, back : BYTE );
  VAR
    s : ARRAY[0..99] OF CHAR;
    r : RECT;
    hid : BOOLEAN;
  BEGIN
    IF idx < 0 THEN
      RETURN;
    END;
    Idx2Str( h, idx, s );
    WITH h^ DO
      DEC( idx, IdxPierwszegoWidocznego );
      r := Rect;
      INC( r.top, 10 );
      INC( r.top, idx*16 );
      r.bottom := r.top+16;
      INC( r.left, 3 );
      DEC( r.right, 3 );
      hid := HideConditionally( r );
      FillRect( r, back );
      _Wr16StrXY( s, r.left, r.top, fore, back );
      IF hid THEN
        ShowCursor;
      END;
    END;
  END WrStr;

VAR
  i : INTEGER;
BEGIN
  WITH h^ DO
    IF ipw # IdxPierwszegoWidocznego THEN
      i := IdxPierwszegoWidocznego;
      WHILE (i < IdxPierwszegoWidocznego+Wierszy) (*& (i < IloscElementow)*) DO
        IF i # AktPolozenieKursora THEN
          WrStr( i, WHITE, CYAN );
        ELSE
          WrStr( i, CYAN, WHITE );
        END;
        INC(i);
      END;
      sel := -7FFFH;
(*      ipw := IdxPierwszegoWidocznego; *)
    ELSIF sel # AktPolozenieKursora THEN
      IF sel # -07FFFH THEN
        WrStr( sel, WHITE, CYAN );
      END;
      WrStr( AktPolozenieKursora, CYAN, WHITE );
    END;
    IF IdxPierwszegoWidocznego # 0 THEN
      FillRect( RectUp, GREEN );
    ELSE
      FillRect( RectUp, CYAN );
    END;
    IF IdxPierwszegoWidocznego+Wierszy < IloscElementow THEN
      FillRect( RectDn, BLUE );
    ELSE
      FillRect( RectDn, CYAN );
    END;
  END;
END Draw;

PROCEDURE HandleEvent( h : HLIST; e : ListEvent );
VAR
  i   : INTEGER;
BEGIN
  WITH h^ DO
    sel := AktPolozenieKursora;
    ipw := IdxPierwszegoWidocznego;
    CASE e.Action OF
      atChoose:
        Ended := TRUE;
    | atMove, atMoveAndChoose:
        INC( AktPolozenieKursora, e.Shift );
        IF AktPolozenieKursora < 0 THEN
          AktPolozenieKursora := 0;
        END;
        IF AktPolozenieKursora >= IloscElementow THEN
          AktPolozenieKursora := IloscElementow-1;
        END;
        IF AktPolozenieKursora > sel THEN (* do przodu *)
          WHILE AktPolozenieKursora > IdxPierwszegoWidocznego+Wierszy-1 DO
            IF ABS( e.Shift ) = 1 THEN
              INC( IdxPierwszegoWidocznego );
            ELSE
              INC( IdxPierwszegoWidocznego, Wierszy );
            END;
          END;
          IF IdxPierwszegoWidocznego+Wierszy > IloscElementow THEN
            IdxPierwszegoWidocznego := IloscElementow - Wierszy;
          END;
        ELSE (*  do tylu *)
          WHILE AktPolozenieKursora < IdxPierwszegoWidocznego DO
            IF ABS( e.Shift ) = 1 THEN
              DEC( IdxPierwszegoWidocznego );
            ELSE
              DEC( IdxPierwszegoWidocznego, Wierszy );
            END;
          END;
        END;
        IF IdxPierwszegoWidocznego < 0 THEN
          IdxPierwszegoWidocznego := 0;
        END;
        IF e.Action = atMoveAndChoose THEN
          Ended := TRUE;
        END;
        Notification( AktPolozenieKursora );
    | atCancel:
        AktPolozenieKursora := -7FFFH;
        Ended := TRUE;
        RETURN (* zeby nie rysowal *)
    END;
    Draw( h );
  END;
END HandleEvent;

PROCEDURE CanEnable( h : HLIST; en : BOOLEAN );
  BEGIN
    h^.Enabled := en;
  END CanEnable;

PROCEDURE Disable( h : HLIST );
BEGIN
  WITH h^ DO
    Set( ZakonczonaOperacja );
    IF TRUE(*h = CurH*) THEN
      IF NOT WDialogu THEN
        DeleteShortCut( kbEnter );
        DeleteShortCut( kbEsc );
      END;
      DeleteShortCut( kbUp );
      DeleteShortCut( kbDown );
      DeleteShortCut( kbPgUp );
      DeleteShortCut( kbPgDn );
      CurH := NIL;
    END;
    Free( ZakonczonaOperacja );
  END;
END Disable;

PROCEDURE GetSelection( h : HLIST ) : INTEGER;
BEGIN
  RETURN h^.AktPolozenieKursora;
END GetSelection;

PROCEDURE Enable( h : HLIST );
BEGIN
  IF CurH # NIL THEN
    Disable( CurH );
  END;
  CurH := h;
  WITH h^ DO
    Set( ZakonczonaOperacja );
    IF NOT WDialogu THEN
      DefineShortCut( kbEnter, kbHandler, CP(kbEnter) );
      DefineShortCut( kbEsc, kbHandler, CP(kbEsc) );
    END;
    DefineShortCut( kbUp, kbHandler, CP(kbUp) );
    DefineShortCut( kbDown, kbHandler, CP(kbDown) );
    DefineShortCut( kbPgUp, kbHandler, CP(kbPgUp) );
    DefineShortCut( kbPgDn, kbHandler, CP(kbPgDn) );

    ipw := -7FFFH;
    sel := -7FFFH;
    Free( ZakonczonaOperacja );
  END;
END Enable;

PROCEDURE GetRegion( h : HLIST; Ktory : CARDINAL ) : Region;
BEGIN
  CASE Ktory OF
    0 : RETURN h^.All;
  | 1 : RETURN h^.ScrollUp;
  | 2 : RETURN h^.ScrollDn;
  ELSE
    HALT;
  END;
END GetRegion;

PROCEDURE Sortowana( h : HLIST; s : BOOLEAN );
BEGIN
  h^.Sorted := s;
END Sortowana;

PROCEDURE SetSelectionInt( h : HLIST; s : INTEGER; Force : BOOLEAN );
BEGIN
  WITH h^ DO
    Set( ZakonczonaOperacja );
    IF (s >= IloscElementow) THEN
      s := IloscElementow-1;
    END;
    IF NOT Force & (AktPolozenieKursora = s) THEN
      Free( ZakonczonaOperacja );
      RETURN;
    END;
    AktPolozenieKursora := s;
    Notification( s );
  END;
  SetPositions( h );
  Redraw( h );
  Free( h^.ZakonczonaOperacja );
END SetSelectionInt;

PROCEDURE SetSelectionNotf( h : HLIST; s : INTEGER );
  BEGIN
    SetSelectionInt( h, s, TRUE );
  END SetSelectionNotf;

PROCEDURE SetSelection( h : HLIST; s : INTEGER );
  BEGIN
    SetSelectionInt( h, s, FALSE );
  END SetSelection;

PROCEDURE SetPositions( h : HLIST );
BEGIN
  WITH h^ DO
    IF (AktPolozenieKursora < IdxPierwszegoWidocznego) THEN
      IdxPierwszegoWidocznego := AktPolozenieKursora;
    ELSIF AktPolozenieKursora >= IdxPierwszegoWidocznego+Wierszy THEN
      IdxPierwszegoWidocznego := AktPolozenieKursora;
      IF (IdxPierwszegoWidocznego+Wierszy >= IloscElementow) THEN
        IdxPierwszegoWidocznego := IloscElementow-Wierszy;
      END;
    END;
  END;
END SetPositions;

PROCEDURE GetRect( h : HLIST; VAR r : RECT );
BEGIN
  r := h^.Rect;
END GetRect;

PROCEDURE GetContents( h : HLIST ) : HCONTENT;
BEGIN
  RETURN h^.Zawartosc;
END GetContents;

PROCEDURE SetContents( hl : HLIST; hc : HCONTENT );
BEGIN
  WITH hl^ DO
    IF Zawartosc # NIL THEN
      SkasujWszystko( hl );
    END;
    Zawartosc := hc;
    WHILE hc # NIL DO
      INC( IloscElementow );
      hc := hc^.Next;
    END;
  END;
  Redraw( hl );
END SetContents;

PROCEDURE KillContents( hl : HLIST; Enable : BOOLEAN );
BEGIN
  hl^.KillContents := Enable;
END KillContents;

BEGIN
  CurH := NIL;
  Lista := NIL;
END GList.
