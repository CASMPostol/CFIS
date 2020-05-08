IMPLEMENTATION MODULE XMSService;

FROM XMS IMPORT
  XmsInstalled, ExtMemMoveStruct, MoveExtMemBlock, AllocateExtMem,
  FreeExtMem;
FROM SYSTEM IMPORT
  BYTE, WORD, ADR, ADDRESS, SETREG, SWI, DX, DS, AX;
FROM Storage IMPORT
  ALLOCATE, DEALLOCATE;
FROM Sounds IMPORT
  Sound, NoSound;
FROM StdIO IMPORT
  sprintf;
FROM RTSMain IMPORT
 Terminate, Status, InstallTermProc;

CONST
  WLK_BUFORA = 1000H;
TYPE
  GarbagePtr = POINTER TO Garbage;
  Garbage = RECORD
    handle : XMS_Handle;
    next : GarbagePtr;
  END;

VAR
(*
  Bufor : ARRAY [0..WLK_BUFORA-1] OF BYTE;
*)
  GarbageList : GarbagePtr;


PROCEDURE Allocate( Size : LONGINT ) : XMS_Handle;
  VAR
    h : XMS_Handle;
    g : GarbagePtr;
    w_kB : CARDINAL;
  BEGIN
    w_kB := VAL( CARDINAL, (Size+1023L) DIV 1024L );
    Blad( AllocateExtMem( w_kB, h ));
    g := GarbageList;
    NEW( GarbageList );
    WITH GarbageList^ DO
      handle := h;
      next := g;
    END;
    RETURN h;
  END Allocate;

PROCEDURE Deallocate( h : XMS_Handle );
  BEGIN
    Blad( FreeExtMem( h ));
    Free( h );
  END Deallocate;


PROCEDURE Copy( from : XMS_Handle; From : ExtMemPtr;
                to   : XMS_Handle; To   : ExtMemPtr;
                Size : CARDINAL );
  VAR
    ControlBlock : ExtMemMoveStruct;
    EvenSize     : CARDINAL;
    Bufor        : RECORD
      CASE :BOOLEAN OF
        FALSE:
          w : WORD;
      | TRUE:
          b : BYTE;
      END;
    END;
    bp           : POINTER TO BYTE;
  BEGIN
    EvenSize := Size;
    IF ODD(Size) THEN
      IF from = 0 THEN
        INC( EvenSize ); (* bo jak sie kopiuje <DO XMS> to mozna sobie skopiowac wiecej *)
      ELSE
        DEC( EvenSize );
      END;
    END;
    ControlBlock.SrcHand := from;
    ControlBlock.SrcOffs := From;
    ControlBlock.DestHand := to;
    ControlBlock.DestOffs := To;
    ControlBlock.Len      := VAL( LONGINT, EvenSize );
    Blad( MoveExtMemBlock( ControlBlock ));
    IF (Size # EvenSize) & (to = 0) THEN (* nieparzyste kopiowanie <Z XMS> *)
      INC( ControlBlock.SrcOffs.ProtectedPtr, EvenSize );
      ControlBlock.DestOffs.RealPtr := ADR( Bufor );
      ControlBlock.Len := 2L;
      Blad( MoveExtMemBlock( ControlBlock ));
      INC( To.RealPtr.OFFSET, EvenSize );
      bp := To.RealPtr;
(*$T-*)  (* bo sie kretyn czepia jak offset jest rowny ffff *)
      bp^ := Bufor.b;
(*$T=*)
    END;
  END Copy;


PROCEDURE Free( h : XMS_Handle );
  VAR
    g,t : GarbagePtr;
  BEGIN
    g := GarbageList;
    WHILE g^.handle # h DO
      g := g^.next;
    END;
    IF g = GarbageList THEN
      GarbageList := GarbageList^.next;
      DISPOSE( g );
    ELSE
      t := GarbageList;
      WHILE t^.next # g DO
        t := t^.next;
      END;
      t^.next := g^.next;
      DISPOSE( g );
    END;
  END Free;

PROCEDURE Terminator(  );
  VAR
    j : CARDINAL;
    u : GarbagePtr;
  BEGIN
    WHILE GarbageList # NIL DO
      FOR j := 0 TO 40000 DO
        Sound( j DIV 4 );
      END;
      FOR j := 40000 TO 0 BY -1 DO
        Sound( j DIV 4 );
      END;
      NoSound;
      u := GarbageList^.next;
      Free( GarbageList^.handle );
      GarbageList := u;
    END;
  END Terminator;

PROCEDURE Blad( b : CARDINAL );
  VAR
    s : ARRAY[0..47] OF CHAR;
    a : ADDRESS;
  BEGIN
    IF (b#0) THEN
      sprintf( s, 'Bˆ¥d sterownika XMS!!! (%d)$', b );
        (* a nie mowilem - tu ma byc $-terminated string MP *)
      a := ADR(s);
      SETREG( DS, a.SEGMENT );
      SETREG( DX, a.OFFSET );
      SETREG( AX, 900H );
      SWI( 21H );
      Terminate( Warning );
    END;
  END Blad;

PROCEDURE WrWarning(  );
  VAR
    s : ARRAY[0..47] OF CHAR;
    a : ADDRESS;
  BEGIN
    s := "Program wymaga zainstalowania sterownika XMS!$";
    a := ADR(s);
    SETREG( DS, a.SEGMENT );
    SETREG( DX, a.OFFSET );
    SETREG( AX, 900H );
    SWI( 21H );
    Terminate( Warning );
  END WrWarning;

BEGIN
  GarbageList := NIL;
  IF NOT XmsInstalled() THEN
    WrWarning;
  END;
  InstallTermProc( Terminator );
END XMSService.
