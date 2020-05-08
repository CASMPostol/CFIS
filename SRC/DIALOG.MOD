(*.F- *)
(**********************************************************************
|  Title   : Okna dialogowe
|  Author  : M.Morawski
|  System  : LOGITECH MODULA-2/86
|  History :
|    16-09-96:M.Postol
|      tlo dialogu ustawia palete
|
|  Copyright (C), CAS LODZ POLAND.
|  TEL: 42' 862 547, 42' 87 80 44 FAX/TEL: 42' 84 48 40
|
**********************************************************************)
(*.F+ *)
IMPLEMENTATION MODULE Dialog;

FROM GrafTypes IMPORT
  RECT, POINT, AssignRect, AssignPoint, WHITE, MoveRect, BLACK, LT_GREEN;
FROM MMMouse IMPORT
  ShowCursor, HideConditionally, Region, RegisterRegion, UnregisterRegion,
  SetParent, EventSet, Event, ButtonSet, InsertEvent;
FROM SYSTEM IMPORT
  BYTE, ADDRESS;
FROM Graphics IMPORT
  GetWindow, SetWindow;
FROM HiLevGraf IMPORT
  DIBHeight, DIBWidth, HDIB, LoadDIB, ShowDIB, FrameRect,CloseDIB,FillRect;
FROM Storage IMPORT
  ALLOCATE, DEALLOCATE;
FROM ASCII IMPORT
  cr, esc;
FROM MANAGER IMPORT
  Assert;

IMPORT
  InpLine, Buttons, GList, XMSService, ShortCuts, Terminal, MANAGER, Timer,
  MMMouse;

  CONST
    Alive = 31415;
    Dead  = 27182;

TYPE
  TypPola=( tpButton, tpInpLine, tpLista );
  RadioP = POINTER TO RadioDesc;
  HDLG = POINTER TO DialogDesc;
  PPole = POINTER TO Pole;
  Pole = RECORD
    r : RECT;
    CASE t  : TypPola OF
      tpButton : bu : Buttons.Button;
    | tpInpLine: il : InpLine.HLINE;
    | tpLista  : gl : GList.HLIST;
    END;
    Next : PPole;
  END;

  DialogDesc = RECORD
    Next  : HDLG;
    R   : RECT;
    dib : HDIB;
    pola, aktywny, term : PPole; (* te od term wzwyz sa do wewnetrznego uzytku *)
    SaveBackground : BOOLEAN;
    Where : XMSService.XMS_Handle;
    Reg   : Region;
    Radio : RadioP;
    RadioSelect : RadioP;
    ChwilowoNieczynny : BOOLEAN;
    Active    : CARDINAL;

  END;

  RadioDesc = RECORD
    Next : RadioP;
    but  : Buttons.Button;
    Proc : PROC;
    Active    : CARDINAL;
  END;


VAR
  ListaDlg : HDLG;
  FocusChanged : MANAGER.SIGNAL;


PROCEDURE GetDialogDIBHandle( h : HDLG ) : HDIB;
BEGIN
  RETURN h^.dib;
END GetDialogDIBHandle;

PROCEDURE WstawButton( h   : HDLG;
                       Rect: RECT;
                       t   : ARRAY OF CHAR;(* text *)
                       k   : INTEGER; (* numer wyroznionego znaku w tekscie *)
                       sh  : CARDINAL;  (* shortcut *)
                       P   : PROC;
                       VAR nb : Buttons.Button);
VAR
  np : PPole;
  rect : RECT;
BEGIN
  WITH h^ DO
    Assert(Active=Alive);
    rect := Rect;
    MoveRect( Rect, R.left, R.top );
    nb := Buttons.CreateButton( Rect, t, k, sh, P );
    Buttons.EnableButton( nb, FALSE );
    NEW( np );
    WITH np^ DO
      r := rect;
      t := tpButton;
      bu := nb;
      Next := pola;
      SetParent( Buttons.GetRegion( nb ), Reg );
    END;
    pola := np;
  END;
END WstawButton;

PROCEDURE WstawRadioButton( h   : HDLG;
                            Rect: RECT;
                            t   : ARRAY OF CHAR;(* text *)
                            k   : INTEGER; (* numer wyroznionego znaku w tekscie *)
                            sh  : CARDINAL;  (* shortcut *)
                            P   : PROC;
                            VAR nb : Buttons.Button);
VAR
  np : PPole;
  rect : RECT;
  r    : RadioP;
BEGIN
  WITH h^ DO
    Assert(Active=Alive);
    rect := Rect;
    MoveRect( Rect, R.left, R.top );
    nb := Buttons.CreateRadioButton( Rect, t, k, sh, RadioBProc );
    Buttons.EnableButton( nb, FALSE );
    NEW( np );
    WITH np^ DO
      r := rect;
      t := tpButton;
      bu := nb;
      Next := pola;
      SetParent( Buttons.GetRegion( nb ), Reg );
    END;
    pola := np;
    r := Radio;
    NEW( Radio );
    WITH Radio^ DO
      Active := Alive;
      Next := r;
      but  := nb;
      Proc := P;
    END;
    IF (r = NIL) THEN
      RadioSelect := Radio;
    END;
  END;
END WstawRadioButton;

PROCEDURE RadioBProc( b : Buttons.Button );
  VAR
    h : HDLG;
    r : RadioP;
  BEGIN
    h := ListaDlg;
    REPEAT
      WITH h^ DO
        Assert(Active=Alive);
        r := Radio;
        WHILE (r # NIL) DO
          WITH r^ DO
            Assert(Active=Alive);
            IF (but = b) THEN
              Buttons.PressRadio( RadioSelect^.but, FALSE );
              RadioSelect := r;
              Proc;
              RETURN;
            END;
            r := Next;
          END;
        END;
        h := Next;
      END;
    UNTIL h = NIL;
    HALT; (* w zadnym razie tu sie nie moze znalezc *)
  END RadioBProc;

PROCEDURE WstawInpLine( h    : HDLG;
                        x, y : INTEGER; (* polozenie lg rogu *)
                        IlKol: INTEGER; (* ilosc znakow *)
                        Valid: InpLine.ValidateProc;
                        fore : BYTE;
                        back : BYTE;
                        VAR i: InpLine.HLINE);
VAR
  p : PPole;
BEGIN
  WITH h^ DO
    Assert(Active=Alive);
    InpLine.CreateInpLine( x+R.left,
    				y+R.top,
    				IlKol, Valid, fore, back, i );
    NEW( p );
    WITH p^ DO
      AssignRect( r, x, y, x+IlKol*8+10, y+20 );
      t := tpInpLine;
      il := i;
      Next := pola;
      SetParent( InpLine.GetRegion( i ), Reg );
    END;
    pola := p;
  END;
END WstawInpLine;

PROCEDURE WstawListe( h   : HDLG;
                      Rect: RECT;
                      SaveBckg : BOOLEAN ) : GList.HLIST;
VAR
  l : GList.HLIST;
  p : PPole;
  rect : RECT;
BEGIN
  WITH h^ DO
    Assert(Active=Alive);
    rect := Rect;
    MoveRect( Rect, R.left, R.top );
    l := GList.TworzListe( Rect, SaveBckg, TRUE );
    NEW( p );
    WITH p^ DO
      r := rect;
      t := tpLista;
      gl := l;
      Next := pola;
      SetParent( GList.GetRegion( l, 0 ), Reg );
      SetParent( GList.GetRegion( l, 1 ), Reg );
      SetParent( GList.GetRegion( l, 2 ), Reg );
    END;
    pola := p;
  END;
  RETURN l;
END WstawListe;

PROCEDURE TworzDialog( Rect    : RECT;
                       dibName : ARRAY OF CHAR;
                       SB      : BOOLEAN ) : HDLG;
VAR
  hdlg : HDLG;
  tmp  : HDLG;
  w, h : CARDINAL;
  l    : CARDINAL;
  p    : CARDINAL;
  i : CARDINAL;
  isHid : BOOLEAN;
  dibRect : RECT;
  pnt     : POINT;
  tab, shtab, altF4, Spacja : Buttons.Button;
BEGIN
  IF ListaDlg # NIL THEN
    EnableDlg( ListaDlg, FALSE );
  END;
  NEW( hdlg );
  WITH hdlg^ DO
    Active := Alive;
    dib := LoadDIB( dibName );
    Radio := NIL;
    RadioSelect := NIL;
    ChwilowoZablokujDialog( hdlg, TRUE );
    R := Rect;
    pola := NIL;
    aktywny := NIL;
    SaveBackground := SB;
    w := R.right-R.left+1;
    h := R.bottom-R.top+1;
    IF SaveBackground THEN
      l := 4000H DIV w; (* lini na strone *)
      p := (h+l-1) DIV l;
      Where := XMSService.Allocate( VAL( LONGINT, w )*VAL(LONGINT,h) );
      isHid := HideConditionally( R );
      GetWindow( NIL,
                 R.left,
                 R.top,
                 R.right,
                 R.bottom,
                 Where,
                 0L
               );
      IF isHid THEN
        ShowCursor;
      END;
    END;
    Next := ListaDlg;
    WITH dibRect DO
      left := 0;
      top := 0;
      bottom := DIBHeight( dib )-1;
      right  := DIBWidth( dib ) -1;
      IF bottom >= VAL( INTEGER, h ) THEN
        bottom := h-1;
      END;
      IF right >= VAL( INTEGER, w ) THEN
        right := w-1;
      END;
    END;
    FillRect( R, BLACK );
    AssignPoint( pnt, R.left, R.top );
    ShowDIB( dib, dibRect, pnt, TRUE );
(*    FrameRect( R, WHITE );*)
    RegisterRegion( EventSet{LeftDown}, R, DialogMouseHandle, NIL, Reg);
    (* MP zmiana MMMouse *)
    AssignRect( dibRect, 10000, 10000, 10000, 10000 ); (* niewidoczny *)
    WstawButton( hdlg, dibRect, "", -1, ShortCuts.kbTab, KlawiszTab, tab );
    WstawButton( hdlg, dibRect, "", -1, ShortCuts.kbShiftTab,
                 KlawiszShiftTab, shtab );
    WstawButton( hdlg, dibRect, "", -1, ShortCuts.kbAltF4, AltF4, altF4 );
    WstawButton( hdlg, dibRect, "", -1, 03920H, KlawiszSpacji, Spacja );
    term := pola;
  END;
  IF ListaDlg # NIL THEN
    ShortCuts.PutKeyStrokeIntoBuffer( 0FEFFH );
  END;
  Timer.Wait( Timer.TInOneSecond() DIV 4 );
  ListaDlg := hdlg;
  RETURN hdlg;
END TworzDialog;

PROCEDURE UsunDialog( hDlg : HDLG );

  PROCEDURE UsunPola( VAR p : PPole );
  BEGIN
    IF p # NIL THEN
      WITH p^ DO
        UsunPola( Next );
        CASE t OF
          tpButton  : Buttons.DisposeButton( bu );
        | tpInpLine : InpLine.DeleteInpLine( il );
        | tpLista   : GList.UsunListe( gl );
        END;
      END;
      DISPOSE( p );
    END;
  END UsunPola;

VAR
  w, h : CARDINAL;
  th    : HDLG;
  l    : CARDINAL;
  p    : CARDINAL;
  isHid: BOOLEAN;
  i : CARDINAL;
BEGIN
  WITH hDlg^ DO
    Assert(Active=Alive);
    UsunPola( pola );
    CloseDIB( dib );
    IF SaveBackground THEN
      w := R.right-R.left+1;
      h := R.bottom-R.top+1;
      l := 4000H DIV w; (* lini na strone *)
      p := (h+l-1) DIV l;
      isHid := HideConditionally( R );
      SetWindow( NIL,
                 R.left,
                 R.top,
                 R.right,
                 R.bottom,
                 Where,
                 0L );
      IF isHid THEN
        ShowCursor;
      END;
      XMSService.Deallocate( Where );
    ELSE
      FillRect( R, BLACK );
    END;
    UnregisterRegion( Reg );
  END;
  IF ListaDlg = hDlg THEN
    ListaDlg := hDlg^.Next;
  ELSE
    th := ListaDlg;
    WHILE th^.Next # hDlg DO
      th := th^.Next;
    END;
    th^.Next := hDlg^.Next;
  END;
  hDlg^.Active := Dead;
  DISPOSE( hDlg );
  IF ListaDlg # NIL THEN
    EnableDlg( ListaDlg, TRUE );
  ELSE
    Buttons.EnableDisableAllButtons( TRUE );
  END;
END UsunDialog;

PROCEDURE KlawiszSpacji(  );
  BEGIN
    WITH ListaDlg^ DO
      Assert(Active=Alive);
      IF aktywny = NIL  THEN
        RETURN;
      END;
      IF aktywny^.t = tpButton THEN
        Buttons.CallProc( aktywny^.bu );
      ELSE
        ShortCuts.PutKeyStrokeIntoBuffer( 03920H );
      END;
    END;
  END KlawiszSpacji;

PROCEDURE KlawiszTab;
BEGIN
  WITH ListaDlg^ DO
    Assert(Active=Alive);
    IF aktywny^.Next # term THEN
      Aktywizuj( aktywny^.Next );(* bo 2 ostatnie sa wykorzystywane wewnetrznie *)
    ELSE
      Aktywizuj( pola );
    END;
  END;
END KlawiszTab;

PROCEDURE KlawiszShiftTab;
VAR
  p : PPole;
BEGIN
  WITH ListaDlg^ DO
    Assert(Active=Alive);
    p := pola;
(*     IF p = aktywny THEN na koniec kolejki *)
    WHILE (p^.Next # aktywny) & (p^.Next # term) DO
      p := p^.Next;
    END;
    Aktywizuj( p );
  END;
END KlawiszShiftTab;


PROCEDURE Aktywizuj( p : PPole )(* : BOOLEAN*);
VAR
  s : ARRAY [0..99] OF CHAR;
  ramka : RECT;

  PROCEDURE Expand;
  BEGIN
    WITH ramka DO
      DEC( left );
      DEC( top );
      INC( right );
      INC( bottom );
    END;
    MoveRect( ramka, ListaDlg^.R.left, ListaDlg^.R.top );
  END Expand;

BEGIN
  WITH ListaDlg^ DO
    Assert(Active=Alive);
    ChwilowoZablokujDialog( ListaDlg, TRUE );
    IF aktywny # p THEN
      IF aktywny # NIL THEN
        ramka := aktywny^.r;
        Expand;
        FrameRect( ramka, BLACK );
        IF aktywny^.t = tpInpLine THEN
          IF NOT InpLine.KillFocus( aktywny^.il ) THEN
            ChwilowoZablokujDialog( ListaDlg, FALSE );
            RETURN (*FALSE*);
          END;
(*
          ShortCuts.PutKeyStrokeIntoBuffer( ShortCuts.kbEnter ); (* wylaczenie
        							inpline *)
*)
        ELSIF aktywny^.t = tpLista THEN
          GList.Disable( aktywny^.gl );
        END;
      END;
      aktywny := p;
      ramka := aktywny^.r;
      Expand;
      FrameRect( ramka, LT_GREEN );
      IF aktywny^.t = tpInpLine THEN

      ELSIF aktywny^.t = tpLista THEN
        GList.Enable( aktywny^.gl );
      END;
    END;
    ChwilowoZablokujDialog( ListaDlg, FALSE );
  END;
(*  RETURN TRUE;*)
END Aktywizuj;

PROCEDURE CzyMoznaSkonczyc( h : HDLG ) : BOOLEAN;
  VAR
    p             : PPole;
    MoznaSkonczyc : BOOLEAN;
  BEGIN
    Timer.Wait( Timer.TInOneSecond() DIV 2 ); (* to jest po to, zeby sie
              skonczyl proces, ktory
              wyslal sygnal
              EndDialog
          *)
    p := h^.pola;
    Assert(h^.Active = Alive);
    MoznaSkonczyc := TRUE;
    WHILE p # NIL DO
      IF (p^.t = tpInpLine) THEN
        IF NOT InpLine.KillFocus( p^.il ) THEN
          MoznaSkonczyc := FALSE;
        END;
      END;
      p := p^.Next;
    END;
    RETURN MoznaSkonczyc;
  END CzyMoznaSkonczyc;

PROCEDURE Go( h : HDLG ) : BOOLEAN;
VAR
  t : HDLG;
  ch, scan : CHAR;
BEGIN
(*
  IF h # ListaDlg THEN
    IF ListaDlg # NIL THEN
      EnableDlg( ListaDlg, FALSE );
      t := ListaDlg;
      WHILE t^.Next # h DO
        Assert(Active=t^.Alive);
        t := t^.Next;
      END;
      t^.Next := h^.Next;
      h^.Next := ListaDlg;
    END;
    ListaDlg := h;
  END;
*)
  Assert(h^.Active = Alive);
  EnableDlg( h^.Next, FALSE );
  EnableDlg( h, TRUE );
  IF h^.aktywny = NIL THEN
    Aktywizuj( h^.pola );  (* !!!!!!!!!!! MP *)
  END;
  ShortCuts.ClearBuffer;
  WITH h^ DO
    ChwilowoZablokujDialog( ListaDlg, FALSE );
    IF RadioSelect # NIL THEN
      Buttons.PressRadio( RadioSelect^.but, TRUE );
      RadioSelect^.Proc;
    END;
    Aktywizuj( h^.pola );
  END;
  LOOP
    ShortCuts.Rd( ch, scan );
(*
    IF ch = esc THEN
      RETURN FALSE;
    END;
*)
    IF ch = 376C THEN
      IF CzyMoznaSkonczyc( h ) THEN
        RETURN FALSE;
      ELSE
        ChwilowoZablokujDialog( ListaDlg, FALSE );
      END;
    END;
    IF ch = 377C THEN
      IF scan = 377C THEN (* zdarzenie sztuczne *)
        IF CzyMoznaSkonczyc( h ) THEN
          RETURN TRUE;
        ELSE
          ChwilowoZablokujDialog( ListaDlg, FALSE );
        END;
      ELSE
        h^.ChwilowoNieczynny := TRUE;
        REPEAT
          MANAGER.WAITS( FocusChanged );
        UNTIL h = ListaDlg;
(*        Timer.Wait( Timer.TInOneSecond() );*)
        h^.ChwilowoNieczynny := FALSE;
      END;
(*
    ELSIF ch = 0C THEN
      ShortCuts.Read( scan );
*)
    END;
    WITH h^.aktywny^ DO
      CASE t OF
        tpButton :
          IF ch = cr THEN
            Buttons.UniversalKBD( ADDRESS(bu) );
          END;
      | tpInpLine:
          InpLine.Key( il, ch, scan );
      | tpLista:
      END;
    END;
  END;
END Go;

PROCEDURE DialogMouseHandle( e : EventSet; bs : ButtonSet; x,y : INTEGER );
VAR
  p : PPole;
BEGIN
  IF ListaDlg = NIL THEN
    RETURN;
  END;
  (* uczulone tylko na lewy klawisz *)
  WITH ListaDlg^ DO
    Assert(ListaDlg^.Active = Alive);
    p := pola;
    LOOP
      IF p = NIL THEN
        EXIT;
      END;
      WITH p^.r DO
        IF ( x >= left ) & ( x <= right ) & ( y >= top ) & ( y <= bottom ) THEN
          IF (p^.t = tpLista) & (p#aktywny) THEN
            InsertEvent( EventSet{LeftDown},
                         ButtonSet{MMMouse.LeftButton},
                         x + R.left,
                         y + R.top );
          END;
          Aktywizuj( p );
          EXIT;
        END;
      END;
      p := p^.Next;
    END;
  END;
END DialogMouseHandle;


PROCEDURE ChwilowoZablokujDialog( h : HDLG; Zablokuj : BOOLEAN );
  BEGIN
    Buttons.EnableDisableAllButtons( NOT Zablokuj );
    h^.ChwilowoNieczynny := Zablokuj;
  END ChwilowoZablokujDialog;

PROCEDURE EndDialog( flaga : BOOLEAN );
BEGIN
  IF ListaDlg^.ChwilowoNieczynny THEN
    Assert(ListaDlg^.Active = Alive);
    RETURN;
  END;
  ChwilowoZablokujDialog( ListaDlg, TRUE );
  IF flaga THEN
    ShortCuts.PutKeyStrokeIntoBuffer(0FFFFH);
  ELSE
    ShortCuts.PutKeyStrokeIntoBuffer(0FEFEH);
  END;
(*  Timer.Wait( Timer.TInOneSecond() DIV 2 );*)
(*  DblClick := FALSE;*)
END EndDialog;

PROCEDURE AltF4(  );
BEGIN
  EndDialog( FALSE );
END AltF4;

PROCEDURE EnableDlg( h : HDLG; Enable : BOOLEAN );
VAR
  p : PPole;
BEGIN
  IF h = NIL THEN
    RETURN;
  END;
  WITH h^ DO
    Assert(Active = Alive);
    ChwilowoZablokujDialog( ListaDlg, TRUE );
    p := pola;
    WHILE p # NIL DO
      WITH p^ DO
        CASE t OF
          tpButton:
            Buttons.EnableButton( bu, Enable );
        | tpLista:
            GList.CanEnable( gl, Enable );
        | tpInpLine:
            InpLine.Enable( il, Enable );
        END;
      END;
      p := p^.Next;
    END;
    ChwilowoZablokujDialog( ListaDlg, FALSE );
  END;
  MANAGER.SEND( FocusChanged );
END EnableDlg;

PROCEDURE IsBusy( h : HDLG ) : BOOLEAN;
  BEGIN
    WITH h^ DO
      Assert(Active = Alive);
      RETURN ChwilowoNieczynny;
    END;
  END IsBusy;

PROCEDURE Redraw( h : HDLG; ReR : RECT );
VAR
  R1 : RECT;
  p  : POINT;
BEGIN
  WITH h^ DO
    Assert(h^.Active = Alive);
    R1 := ReR;
    MoveRect( R1, R.left, R.top );
    FillRect( R1, BLACK );
    AssignPoint( p, R.left+ReR.left, R.top+ReR.top );
    ShowDIB( dib, ReR, p, TRUE );
  END;
END Redraw;

BEGIN
  ListaDlg := NIL;
  MANAGER.InitS( FocusChanged );
END Dialog.
