(**********************************************************************
|  Title   : Regions management
|  Author  : M.Morawski
|  System  : LOGITECH MODULA-2/86
|  History :
|     21-06-96: M.Postol
|       RegisterRegion - odwolanie do procedury, ktora brala adres
|         regionu ze zmiennej o adresie podstawianym po powrocie
|         - musi byc VAR ciekawe kto popawi teraz te wszystkie
|        odwolania???
|        TerazDzialaMouseLoop to jakies nieporozumienie - przeciez to wylaczalo
|        semafor calkowicie ?!!!
|        dolozylem kontrole egzystencjalna regionow bo lapalem go gdy mial
|        glupoty w PrevReg
|     09-28-96 07:41pm MM
|        Z nieznanych powodow OldButtons bylo zawsze = {} ?!
|
|  Copyright (C), CAS LODZ POLAND.
|  TEL: 42' 862 547, 42' 87 80 44 FAX/TEL: 42' 84 48 40
|
**********************************************************************)
(* $ R- *)
(*$S-*)
(* $ T-*)
(*$O+*)
IMPLEMENTATION MODULE MMMouse;

IMPORT
  Mouse, Semafory;
FROM GrafTypes IMPORT
  RECT, WHITE, BLACK, IsIntersect;
FROM Graphics IMPORT
  GetWindow, SetWindow, MaxVer, MaxHor, GetBank, SetBank;
FROM Storage IMPORT
  ALLOCATE, DEALLOCATE;
FROM SYSTEM IMPORT
  OUTBYTE, INBYTE, BYTE, ADR, SIZE, CODE, AX, SETREG, GETREG, WORD;
FROM BlockOps IMPORT
  BlockMove, BlockClear, BlockSet;
FROM MANAGER IMPORT
  WAITC, InitC, STARTPROCESS, Notify, Condition, Assert;
FROM RTSMain IMPORT
  InstallTermProc;


CONST
  mOwn    = TRUE;
  mDriver = FALSE;
  mS3     = FALSE;
  Alive = 31415;
  Dead  = 27182;


TYPE
  Region = POINTER TO RegionDesc;
  RegionDesc = RECORD
    Next	: Region;
    Rect	: RECT;
    Proc	: EventHandler;
    Mask	: EventSet;
    Shape	: CursorShape;
    Parent      : Region;
    Active      : CARDINAL;
  END;

VAR
  Regiony       : Region;
  LastX, LastY  : INTEGER; (* hot spot od ostatniego miejsca *)
  CursorShapePtr: CursorShape;
  DefaultShape  : Mouse.GraphicCursor;
  maxX, maxY    : INTEGER;


  PROCEDURE DefineStdCursor;
  BEGIN
    WITH DefaultShape DO
      screenMask[ 0] := {14..15};
      screenMask[ 1] := {13..15};
      screenMask[ 2] := {12..15};
      screenMask[ 3] := {11..15};
      screenMask[ 4] := {10..15};
      screenMask[ 5] := {09..15};
      screenMask[ 6] := {08..15};
      screenMask[ 7] := {07..15};
      screenMask[ 8] := {06..15};
      screenMask[ 9] := {05..15};
      screenMask[10] := {09..15};
      screenMask[11] := {08..11, 13..15};
      screenMask[12] := {08..11, 14..15};
      screenMask[13] := {07..10};
      screenMask[14] := {07..10};
      screenMask[15] := {06..09};
      cursorMask[ 0] := {};
      cursorMask[ 1] := {14};
      cursorMask[ 2] := {13..14};
      cursorMask[ 3] := {12..14};
      cursorMask[ 4] := {11..14};
      cursorMask[ 5] := {10..14};
      cursorMask[ 6] := {09..14};
      cursorMask[ 7] := {08..14};
      cursorMask[ 8] := {07..14};
      cursorMask[ 9] := {06..14};
      cursorMask[10] := {10..14};
      cursorMask[11] := {09..10, 14};
      cursorMask[12] := {09..10};
      cursorMask[13] := {08..09};
      cursorMask[14] := {08..09};
      cursorMask[15] := {07..08};
      hotX           := 0;
      hotY	     := 0;
    END;
  END DefineStdCursor;

  PROCEDURE Init;
  BEGIN
    IF mS3 THEN
      WrIdx( 3d4h, 38h, 048h );
      WrIdx( 3d4h, 39h, 0a5h );
      RedrawAt( maxX DIV 2, maxY DIV 2 );
      WrIdx( 3d4h, 45h, 03h );
      WrIdx( 3d4h, 39h, 05ah );
      WrIdx( 3d4h, 0eh, WHITE );
      WrIdx( 3d4h, 0fh, BLACK );
      WrBit( 3d4h, 31h, 3, TRUE );
    END;
  END Init;


  PROCEDURE HideConditionally( VAR r : RECT ) : BOOLEAN;
  VAR
    mReg : RECT;
  BEGIN
    IF mOwn OR mDriver THEN
      IF Hidden THEN
        RETURN FALSE;
      END;
      mReg.left   := LastX-CursorShapePtr^.hotX;
      mReg.top    := LastY-CursorShapePtr^.hotY;
      mReg.right  := mReg.left+15;
      mReg.bottom := mReg.top+15;
      IF IsIntersect( mReg, r ) THEN
        HideCursor;
        RETURN TRUE;
      ELSE
        RETURN FALSE;
      END;
    ELSIF mS3 THEN
      RETURN FALSE;
    END;
  END HideConditionally;

  PROCEDURE IsHidden():BOOLEAN;
  BEGIN
    RETURN Hidden;
  END IsHidden;

  PROCEDURE RegisterRegion(
                            mask  : EventSet;
                            rect  : RECT;
                            proc  : EventHandler; (* podaje polozenia wzgledne *)
                            shape : CursorShape;
                          VAR reg : Region); (* MP mow na mnie geniusz *)

  VAR
    bs : ButtonSet;
    dummy : INTEGER;
  BEGIN
    NEW( reg );
    WITH  reg^ DO
      Next := Regiony;
      Rect := rect;
      Proc := proc;
      Shape:= shape;
      Mask := mask;
      Parent := NIL;
      Active := Alive;
    END (* with *);
    Semafory.Set( MSemafor ); (* MP *)
    Regiony := reg;
    IF (LastX >= rect.left) & (LastX <= rect.right) &
       (LastY >= rect.top ) & (LastY <= rect.bottom )
    THEN
      PrevReg := Regiony;
      Mouse.GetPosBut( bs, dummy, dummy );
      proc( EventSet{RegionIn}, bs, LastX-rect.left, LastY-rect.top );
    END;
    Semafory.Free( MSemafor );
  END RegisterRegion;

  PROCEDURE SetOnTop( Reg : Region );
  VAR
    r,t : Region;
  BEGIN
    Assert(Reg^.Active = Alive);
    Semafory.Set( MSemafor );
    r := Regiony;
    WHILE (r # NIL) & (r^.Next # Reg) DO
      Assert(r^.Active = Alive);
      r := r^.Next;
    END;
    IF r^.Next = Reg THEN
      r^.Next := Reg^.Next;
      Reg^.Next := Regiony;
      Regiony := Reg;
    END;
    Semafory.Free( MSemafor );
  END SetOnTop;

  PROCEDURE UnregisterRegion( VAR Reg:Region );
  VAR
    r : Region;
    bs : ButtonSet;
    dummy : INTEGER ;
  BEGIN
    IF Reg = NIL THEN
      RETURN;
    END;
    Assert(Reg^.Active = Alive);
    Semafory.Set( MSemafor );
    IF Reg = Regiony THEN
      Regiony := Regiony^.Next;
    ELSE
      r := Regiony;
      WHILE (r # NIL) & (r^.Next # Reg ) DO
        Assert(r^.Active = Alive);
        r := r^.Next;
      END;
      IF r = NIL THEN
        Assert(FALSE);
        HALT; (* ktos cos porabal *)
      END;
      r^.Next := Reg^.Next;
    END;
    IF Reg = PrevReg THEN
      SetShape( ADR( DefaultShape ) );
    END;
    WITH Reg^ DO
      IF (LastX >= Rect.left) & (LastX <= Rect.right) &
         (LastY >= Rect.top ) & (LastY <= Rect.bottom )
      THEN
        Mouse.GetPosBut( bs, dummy, dummy );
        IF RegionOut IN Mask THEN
          Proc( EventSet{RegionOut}, bs, LastX-Rect.left, LastY-Rect.top );
        END;
      END;
    END;
    IF Reg = PrevReg THEN
      PrevReg := NIL;
    END;
    Reg^.Active := Dead;
    Semafory.Free( MSemafor );
    DISPOSE( Reg ); (* MP to moze byc poza semaforem *)
  END UnregisterRegion;

  PROCEDURE Swap( w : WORD ) : WORD;
  BEGIN
    SETREG(AX,w );
    CODE( 086h,0c4h (*xchg ah,al *));
    GETREG(AX,w );
    RETURN w;
  END Swap;

  PROCEDURE SetShape( csp : CursorShape );
  VAR
    b, i : CARDINAL;
    a[0a000h:0fc00h] : ARRAY[0..64-1] OF
                          RECORD
                            mask, dat,
                            m1, d1,
                            m2, d2,
                            m3, d3 : WORD;
                          END;

  BEGIN
    CursorShapePtr := csp;
    IF mOwn THEN
      (* nic *)
    ELSIF mDriver THEN
      Mouse.SetGraphicCursor( csp^ );
    ELSIF mS3 THEN
      OUTBYTE( 3d4h, 35h );
      INBYTE( 3d5h, b );
(*      b := GetBank();*)
      WrIdx( 3d4h, 35h, 15 );
(*      SetBank( 15 ); (* ostatni bank *)*)
      FOR i := 0 TO 15 DO
        WITH a[i] DO
          WITH csp^ DO
            mask := Swap(screenMask[i]/{0..15});
            dat  := Swap(cursorMask[i]);
            m1   := WORD(0ffffh);
            d1   := WORD(0h);
            m2   := m1;
            d2   := d1;
            m3   := m1;
            d3   := d1;
          END;
        END;
      END;
      a[16] := a[15];
      a[16].mask := a[16].m1;
      a[16].dat  := a[16].d1;
      FOR i := 17 TO 63 DO
        a[i] := a[16];
      END;
(*      SetBank( b );*)

      WrIdx( 3d4h, 39h, 0a5h );
      WrIdx( 3d4h, 4ah, 0ffh );
      WrIdx( 3d4h, 4bh, 0 );

      WrIdx( 3d4h, 4ch, 003h );
      WrIdx( 3d4h, 4dh, 0ffh );

      WrIdx( 3d4h, 4eh, csp^.hotX );
      WrIdx( 3d4h, 4fh, csp^.hotY );

      WrIdx( 3d4h, 35h, b );
(*      SetBank( b );*)
(*      WrIdx( 3d4h, 39h, 05ah );*)
    END;
  END SetShape;


  PROCEDURE WrIdx( Port, Idx, val : CARDINAL );
  BEGIN
    OUTBYTE( Port, Idx );
    OUTBYTE( Port+1, val );
  END WrIdx;

  PROCEDURE WrBit( Port, Idx, BitNo : CARDINAL; Set : BOOLEAN );
  VAR
    b : BITSET;
  BEGIN
    OUTBYTE( Port, Idx );
    INBYTE( Port+1, b );
    IF Set THEN
      INCL( b, BitNo );
    ELSE
      EXCL( b, BitNo );
    END;
  END WrBit;


VAR
  PrevReg : Region;


  PROCEDURE GetRegion() : Region;
  BEGIN
    IF PrevReg <> NIL  THEN
      Assert(PrevReg^.Active = Alive);
    END;
    RETURN PrevReg;
  END GetRegion;

  PROCEDURE GetRegionRect( r : Region; VAR rect : RECT );
  BEGIN
    IF r = NIL THEN
      rect.top    := -1;
      rect.bottom := -1;
      rect.left   := -1;
      rect.right  := -1;
    ELSE
      Assert(r^.Active = Alive);
      rect := r^.Rect;
    END;
  END GetRegionRect;

  PROCEDURE SetParent( For, Parent : Region );
  BEGIN
    Assert((For^.Active = Alive) AND (Parent^.Active = Alive));
    Semafory.Set( MSemafor );
    For^.Parent := Parent;
    Semafory.Free( MSemafor );
  END SetParent;

MODULE BezPrzerwanOdMyszy[4];

IMPORT
  Condition, ButtonSet, Mouse, Event, EventSet, Notify, WAITC, InitC, Button,
  BYTE, LastX, LastY, mOwn, mDriver, mS3, WrIdx, GetBank, maxX, maxY,
  SetWindow, ADR, SetBank, CursorShapePtr, GetWindow, BlockMove,
  WHITE, BLACK, SIZE;

EXPORT
  EventDispatcher, GetEvent, InsertEvent;


CONST
     EventBuffLen = 64;
VAR
  MouseEvent : Condition;
  OldButtons : ButtonSet;
  EVF,EVL,EVC: CARDINAL;
  EventBuff  : ARRAY [0..EventBuffLen-1] OF RECORD
                                              posx,posy : INTEGER;
                                              EV : Mouse.EventSet;
                                              BS : Mouse.ButtonSet;
                                            END;


  PROCEDURE EventDispatcher( e : Mouse.EventSet;
                             b : Mouse.ButtonSet;
                             x,
                             y : INTEGER );
  BEGIN
    IF EVC<EventBuffLen THEN
      WITH EventBuff[EVF] DO
        posx := x; posy := y;
        EV := e;
        BS := b;
      END;
      EVF := (EVF+1) MOD EventBuffLen;
      INC(EVC);
      IF TRUE OR (EVC=1) THEN   (* MP na wypadek dzialanosci myszy nie
                                   tylko w przerwaniu *)
        Notify( MouseEvent );
      END;
    END;
  END EventDispatcher;

  PROCEDURE GetEvent( VAR ev : EventSet;
                      VAR bs : ButtonSet;
                      VAR mx,
                          my : INTEGER );

    PROCEDURE Button2Ev( b : Mouse.Button; on, off : Event );
    BEGIN
      IF (b IN bs) # (b IN OldButtons) THEN
        IF b IN bs THEN
          INCL( ev, on );
        ELSE
          INCL( ev, off );
        END;
      END;
    END Button2Ev;

  BEGIN
    IF Stored.ev # EventSet{} THEN
      ev := Stored.ev;
      bs := Stored.bs;
      mx := Stored.x;
      my := Stored.y;
      Stored.ev := EventSet{};
    ELSE
      IF EVC=0 THEN
        WAITC( MouseEvent );
      END;
      DEC(EVC);
      WITH EventBuff[EVL] DO
        mx := posx; my := posy;
        bs := BS;
        ev := EventSet(ORD(CHAR(EV)));
      END;
      EVL := (EVL+1) MOD EventBuffLen;
      Button2Ev( LeftButton, LeftDown, LeftUp );
      Button2Ev( RightButton, RightDown, RightUp );
      OldButtons := bs;
    END;
  END GetEvent;


  PROCEDURE InsertEvent( e : EventSet; b : ButtonSet; x, y : INTEGER );
  BEGIN
    Stored.ev := e;
    Stored.bs := b;
    Stored.x := x;
    Stored.y := y;
  END InsertEvent;

VAR
  Stored : RECORD
    ev : EventSet;
    bs : ButtonSet;
    x, y : INTEGER;
  END;

BEGIN
  InitC( MouseEvent );
  EVF := 0;
  EVL := 0;
  EVC := 0;
  Stored.ev := EventSet{};
  OldButtons := ButtonSet{};
END BezPrzerwanOdMyszy;





MODULE BezWyszeregowania[0];

IMPORT
  Condition, ButtonSet, Mouse, Event, EventSet, Notify, WAITC, InitC, Button,
  BYTE, LastX, LastY, mOwn, mDriver, mS3, WrIdx, GetBank, maxX, maxY,
  SetWindow, ADR, SetBank, CursorShapePtr, GetWindow, BlockMove,
  WHITE, BLACK, SIZE;
EXPORT
  ShowCursor, HideCursor, Hidden, RedrawAt;


TYPE
  CursorBufType = ARRAY[0..16*16-1] OF BYTE;

VAR
  lx, ly, rx, ry : INTEGER;
  CursorBuf     : CursorBufType;


VAR
  Hidden	: BOOLEAN;

  PROCEDURE RedrawAt( x, y : INTEGER );
  BEGIN
    IF( x # LastX ) OR (y # LastY) THEN
      LastX := x;
      LastY := y;
      IF mOwn OR mDriver THEN
        IF NOT Hidden THEN
          RemoveCursor;
          DrawCursor;
        END;
      END;
    ELSIF mS3 THEN
      WrIdx( 3d4h, 46h, x DIV 100H );
      WrIdx( 3d4h, 47h, x MOD 100H );
      WrIdx( 3d4h, 48h, y DIV 100H );
      WrIdx( 3d4h, 49h, y MOD 100H );
    END;
  END RedrawAt;

  PROCEDURE ShowCursor;
  BEGIN
    IF mOwn THEN
      IF Hidden THEN
        DrawCursor;
      END;
      Hidden := FALSE;
    ELSIF mDriver THEN
      Mouse.ShowCursor;
      Hidden := FALSE;
    ELSIF mS3 THEN
      Hidden := FALSE;
    END;
  END ShowCursor;

  PROCEDURE HideCursor;
  BEGIN
    IF mOwn THEN
      IF NOT Hidden THEN
        RemoveCursor;
      END;
      Hidden := TRUE;
    ELSIF mDriver THEN
      Mouse.HideCursor;
      Hidden := TRUE;
    ELSIF mS3 THEN
      (* nic *)
    END;
  END HideCursor;

  PROCEDURE RemoveCursor;
  VAR
    bank : CARDINAL;
  BEGIN
    IF mOwn THEN
      bank := GetBank();
      SetWindow( ADR(CursorBuf), lx, ly, rx, ry, 0, 0L );
      SetBank(bank);
    END;
  END RemoveCursor;


VAR
  CursorB : CursorBufType; (* zmienna lokalna procedury DrawCursor ale
  				umieszczona tu ze wzgledu na oszczednosc
  				stosu *)

  PROCEDURE DrawCursor;
  VAR
    w, h : INTEGER;
    dlx, drx, dly, dry : INTEGER;
    x, y : INTEGER;
    col : BYTE;
    ix : CARDINAL;
    bank : CARDINAL;
  BEGIN
    IF mOwn THEN
      WITH CursorShapePtr^ DO
        lx := LastX-hotX;
        rx := lx+15;
        ly := LastY-hotY;
        ry := ly+15;
        IF lx < 0 THEN
          dlx := -lx;
          lx := 0;
        ELSE
          dlx := 0;
        END;
        IF ly < 0 THEN
          dly := -ly;
          ly := 0;
        ELSE
          dly := 0;
        END;
        IF rx > maxX THEN
          drx := rx-maxX;
          rx := maxX;
        ELSE
          drx := 0;
        END;
        IF ry > maxY THEN
          dry := ry-maxY;
          ry := maxY;
        ELSE
          dry := 0;
        END;
        w := rx-lx+1;
        h := ry-ly+1;
        bank := GetBank();
        GetWindow( ADR(CursorBuf), lx, ly, rx, ry, 0, 0L );
        BlockMove( ADR(CursorB), ADR(CursorBuf), SIZE( CursorB ));
        FOR y := dly TO 15-dry DO
          FOR x := dlx TO 15-drx DO
            ix := 15-x;
            IF ix IN screenMask[y] THEN
              IF ix IN cursorMask[y] THEN
                col := BYTE(WHITE);
              ELSE
                col := BYTE(BLACK);
              END;
              CursorB[ (y-dly)*w+x-dlx] := col;
            END;
          END;
        END;
        SetWindow( ADR(CursorB), lx, ly, rx, ry, 0, 0L );
        SetBank( bank );
      END;
    END;
  END DrawCursor;

END BezWyszeregowania;




  PROCEDURE MouseLoop;
  VAR
    r, pr  : Region;
    ev, evm : EventSet;
    bs : ButtonSet;
    mx : INTEGER;
    my : INTEGER;
  BEGIN
    LOOP
      GetEvent( ev, bs, mx, my );
      Semafory.Set( MSemafor );
      r := Regiony;
      LOOP
        IF r = NIL THEN
          EXIT;
        END;
        Assert(r^.Active = Alive);
        WITH r^ DO
          IF (mx >= Rect.left) & (mx <= Rect.right) &
             (my >= Rect.top ) & (my <= Rect.bottom )
          THEN
            EXIT;
          END;
          r := Next;
        END;
      END;
      IF r = NIL THEN
        SetShape( ADR( DefaultShape ) );
        IF PrevReg # NIL THEN
          Assert(PrevReg^.Active = Alive);
          WITH PrevReg^ DO
            IF RegionOut IN Mask THEN
              Proc( ev+EventSet{RegionOut}, bs, mx-Rect.left, my-Rect.top );
            END;
          END;
        END;
      ELSE
        WITH r^ DO
          IF r # PrevReg THEN
            IF PrevReg # NIL THEN
              Assert( PrevReg^.Active = Alive );
              WITH PrevReg^ DO
                IF RegionOut IN Mask THEN
                  Proc( ev+EventSet{RegionOut}, bs, mx-Rect.left, my-Rect.top );
                END;
              END;
            END;
            INCL( ev, RegionIn );
          END;
          pr      := r;
          REPEAT
            WITH pr^ DO
              Assert( pr^.Active = Alive );
              evm := ev * Mask;
              IF evm # EventSet{} THEN
                PrevReg := pr;  (* zeby mozna bylo zidentyfikowac region *)
                Proc( evm, bs, mx-Rect.left, my-Rect.top );
              END;
              pr := Parent;
            END;
          UNTIL pr = NIL;
          PrevReg := r; (* zeby mozna bylo zidentyfikowac region *)
          IF Shape # NIL THEN
            SetShape( Shape );
          END;
        END;
      END;
      RedrawAt(mx,my);
      PrevReg := r;
      Semafory.Free( MSemafor );
    END;
  END MouseLoop;


  PROCEDURE Terminator;
  BEGIN
    Mouse.SetEventHandler( Mouse.EventSet{}, EventDispatcher );
    IF mS3 THEN
      WrIdx( 3d4h, 39h, 0a5h );
      WrIdx( 3d4h, 45h, 02h);
      WrIdx( 3d4h, 39h, 05ah );
      WrIdx( 3d4h, 38h, 0 );
    END;
  END Terminator;

VAR
  MSemafor : Semafory.Semafor;
BEGIN
  Semafory.Init( MSemafor );
  Hidden := TRUE;
  PrevReg := NIL;
  IF ORD( mOwn )+ ORD( mDriver ) +ORD( mS3 ) # 1 THEN
    HALT; (* bledne opcje *)
  END;
  Regiony := NIL;
  maxX   := MaxHor()-1;
  maxY   := MaxVer()-1;
  DefineStdCursor;
  Init;
  SetShape( ADR( DefaultShape ) );
  IF Mouse.DriverInstalled THEN
    InstallTermProc( Terminator );
    Mouse.SetHorizontalLimits( 0, maxX );
    Mouse.SetVerticalLimits( 0, maxY );
    Mouse.SetCursorPos( maxX DIV 2, maxY DIV 2 );
    Mouse.SetEventHandler( Mouse.EventSet{Mouse.Motion..Mouse.MiddleUp}, EventDispatcher );
    LastX := maxX DIV 2;
    LastY := maxY DIV 2;
    ShowCursor;
  END;
  STARTPROCESS( MouseLoop, 01000H, 0 );
END MMMouse.
