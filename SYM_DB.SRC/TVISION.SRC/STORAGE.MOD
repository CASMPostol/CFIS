(* Release 3.00 *)

(* Copyright (C) 1987..1991 Jensen & Partners International *)

(*%F _fdata *)
(*# call(seg_name => null) *)
(*%E *)
(*%T _fdata *)
(*# call(ds_entry => null) *)
(*# data(seg_name => null) *)
(*%E *)
(*# module(implementation=>off) *)

IMPLEMENTATION MODULE Storage;

IMPORT SYSTEM, Lib, CoreMain, CoreSig, ModCore;
(*%T _OS2 *)
IMPORT CoreMem, Dos;
(*%T _mthread *)
IMPORT Process;
(*%E *)
(*%E *)
CONST
  EndMarker = 0FFFFH;
  Align = 4;

(*%F _OS2 *)
VAR
  NearHeapSetup, FarHeapSetup: BOOLEAN;
  LastBlock: FarHeapRecPtr;
(*%E *)

(*%F _OS2 *)
(*# save *)
(*# call(reg_param=>(ax)) *)

PROCEDURE FarHeapShrink(): CARDINAL;

VAR
  Curr, Prev, New: FarHeapRecPtr;
BEGIN
  Curr := MainHeap;
  Prev := FarNIL;
  WHILE Curr^.size <> EndMarker DO
    Prev := Curr;
    Curr := Curr^.next;
  END;
  New := [Seg(Prev^) + Prev^.size:0 ];
  LastBlock := Prev;
  IF (New = Curr) AND (Prev^.size > 4) THEN  (* Last free block is last block *)
    ModCore.AdjustMem(Seg(Prev^) + 4);
    RETURN 0;
  END;
  RETURN 1;
END FarHeapShrink;

PROCEDURE FarHeapRestore;

BEGIN
  ModCore.AdjustMem(0);
  LastBlock := LastBlock^.next;
  LastBlock^.size := EndMarker;
  LastBlock^.next := MainHeap;
END FarHeapRestore;

PROCEDURE FarHeapFix(Space: CARDINAL);

VAR
  Curr, Prev, New: FarHeapRecPtr;
BEGIN
  Curr := MainHeap;
  Prev := FarNIL;
  WHILE Curr^.size <> EndMarker DO
    Prev := Curr;
    Curr := Curr^.next;
  END;
  New := [Seg(Prev^) + Prev^.size:0 ];
  LastBlock := Prev;
  IF (New = Curr) AND (Prev^.size > Space + 4) THEN  (* Last free block is last block *)
    Prev^.size := Space;
    New := [Seg(Prev^) + Space:0 ];
    Prev^.next := New;
    New^.size := EndMarker;
    New^.next := MainHeap;
    ModCore.AdjustMem(Seg(Prev^)+Space+4);
  END;
END FarHeapFix;
(*# restore *)


PROCEDURE InitFarHeap;
TYPE
(*# save, data(near_ptr=>off) *)
  CPtr = POINTER TO CARDINAL;
(*# restore *)
VAR
  P: CPtr;
  Size, Start: CARDINAL;
BEGIN
  FarHeapSetup := TRUE;
  CoreMain._shr_mem := FarHeapShrink;
  CoreMain._fix_mem := FarHeapFix;
  CoreMain._res_mem := FarHeapRestore;
  CoreMain._fmodmemsetup := TRUE;
  P := [Lib.PSP:2 CPtr];
  Start := ModCore._getheapmem();
  Size := P^ - Start;
  MainHeap:=FarMakeHeap(Start, Size);
END InitFarHeap;

PROCEDURE InitNearHeap;

VAR
  Size, Start: CARDINAL;
BEGIN
  NearHeapSetup := TRUE;
  Size := CoreMain._heap_size;
  Start := CARDINAL(ADR(CoreMain._near_heap_start));
  IF LONGCARD(Size) + LONGCARD(Start) > 0FFFEH THEN
    Size := 0FFFEH - Start;
  END;
  NearHeap := NearMakeHeap(NearADR(CoreMain._near_heap_start), Size);
END InitNearHeap;



PROCEDURE FarMakeHeap( Source : CARDINAL;     (* base segment of heap *)
                        Size   : CARDINAL      (* size in paragraphs *)
                     ) : FarHeapRecPtr;
VAR
  storage,first,last : FarHeapRecPtr;
  ie: CARDINAL;
BEGIN
(*%T _mthread *)
  ie := SYSTEM.GetFlags(); SYSTEM.DI;
(*%E *)
  storage := [Source:0];
  first   := [Source+1:0];
  last    := [Source+Size-1:0];
  storage^.next := first;
  storage^.size := 0;
  first^.next := last;
  last^.next  := storage;
  first^.size := Size-2;
  last^.size  := EndMarker;
(*%T _mthread *)
  SYSTEM.SetFlags(ie);;
(*%E *)
  RETURN storage;
END FarMakeHeap;


PROCEDURE FarHeapAllocate(Source : FarHeapRecPtr;  (* source heap                *)
                          VAR A  : FarADDRESS; (* result                     *)
                          Size   : CARDINAL);      (* request size in paragraphs *)

VAR
  res,prev,split : FarHeapRecPtr;
  ie: CARDINAL;
BEGIN
(*%T _mthread *)
  ie := SYSTEM.GetFlags(); SYSTEM.DI;
(*%E *)
  IF (NOT FarHeapSetup) AND (Source = MainHeap) THEN InitFarHeap; END;
  IF Size=0 THEN INC(Size) END ;
  prev := Source;
  WHILE prev^.next^.size < Size DO
    prev := prev^.next;
  END;
  res := prev^.next;
  IF res^.size = EndMarker THEN (* heap run out of space *)
    SYSTEM.EI ;
    IF Check THEN
      Lib.RunTimeError(CoreSig._FatalErrorPos(), 90H, 'FarHeapAllocate : Out Of Space');
    END;
    A := FarNIL;
    RETURN;
  END;
  IF res^.size = Size THEN (* block correct size *)
    prev^.next := res^.next;
  ELSE (* split block, bottom half returned, top half linked to free chain *)
    split := [CARDINAL(Seg(res^))+Size:0];
    prev^.next := split;
    split^.next := res^.next;
    split^.size := res^.size - Size;
  END;
(*%T _mthread *)
  SYSTEM.SetFlags(ie);;
(*%E *)
  A := FarADR(res^);
END FarHeapAllocate;


PROCEDURE FarHeapAvail(Source: FarHeapRecPtr) : CARDINAL;
(* returns the largest block size available for allocation in paragraphs *)
VAR
  size : CARDINAL;
  p    : FarHeapRecPtr;
  ie: CARDINAL;
BEGIN
(*%T _mthread *)
  ie := SYSTEM.GetFlags(); SYSTEM.DI;
(*%E *)
  IF (NOT FarHeapSetup) AND (Source = MainHeap) THEN InitFarHeap; END;
  p  := Source^.next;
  size := 0;
  WHILE p^.size <> EndMarker DO
    IF p^.size>size THEN size := p^.size END;
    p := p^.next;
  END;
(*%T _mthread *)
  SYSTEM.SetFlags(ie);;
(*%E *)
  RETURN size;
END FarHeapAvail;


PROCEDURE FarHeapTotalAvail(Source: FarHeapRecPtr) : CARDINAL;
(* returns the total block size available for allocation in paragraphs *)
VAR
  size : CARDINAL;
  p    : FarHeapRecPtr;
  ie: CARDINAL;
BEGIN
(*%T _mthread *)
  ie := SYSTEM.GetFlags(); SYSTEM.DI;
(*%E *)
  IF (NOT FarHeapSetup) AND (Source = MainHeap) THEN InitFarHeap; END;
  p  := Source^.next;
  size := 0;
  WHILE p^.size <> EndMarker DO
    INC(size,p^.size);
    p := p^.next;
  END;
(*%T _mthread *)
  SYSTEM.SetFlags(ie);;
(*%E *)
  RETURN size;
END FarHeapTotalAvail;



PROCEDURE FarHeapDeallocate(Source : FarHeapRecPtr;  (* source heap         *)
                            VAR A: FarADDRESS;
                            Size   : CARDINAL );     (* size of block
                                                        in paragraphs       *)
VAR
  target,prev,split : FarHeapRecPtr;
  tseg : CARDINAL;
  ie: CARDINAL;
BEGIN
  IF (CARDINAL(Seg(A^))=0)OR(CARDINAL(Ofs(A^))<>0) THEN
      Lib.RunTimeError(CoreSig._FatalErrorPos(), 91H,  'FarHeapDeallocate : Invalid Argument');
  END;
(*%T _mthread *)
  ie := SYSTEM.GetFlags(); SYSTEM.DI;
(*%E *)
  IF Size=0 THEN INC(Size) END ;
  target := A;
  prev   := Source;
  tseg   := Seg(target^);
  WHILE CARDINAL(Seg(prev^.next^)) < tseg DO
    prev := prev^.next;
  END;
  IF CARDINAL(Seg(prev^))+prev^.size = tseg THEN (* amalgamate with prev *)
    prev^.size := prev^.size + Size;
    target := prev;
  ELSIF CARDINAL(Seg(prev^))+prev^.size > tseg THEN (* Heap corrupt *)
    SYSTEM.EI;
      Lib.RunTimeError(CoreSig._FatalErrorPos(), 92H,  'FarHeapDeallocate : Heap Corrupt');
  ELSE
    (* link after prev *)
    target^.next := prev^.next;
    prev^.next := target;
    target^.size := Size;
  END;
  IF (target^.next^.size <> EndMarker)
     AND (CARDINAL(Seg(target^.next^)) = CARDINAL(Seg(target^))+target^.size) THEN
    (* amalgamate with next block *)
    target^.size := target^.size+target^.next^.size;
    target^.next := target^.next^.next;
  END;
  A := SYSTEM.FarNIL;
(*%T _mthread *)
  SYSTEM.SetFlags(ie);;
(*%E *)
END FarHeapDeallocate;


PROCEDURE FarHeapChangeAlloc(Source  : FarHeapRecPtr;  (* source heap       *)
                             A       : FarADDRESS; (* block to change   *)
                             OldSize,               (* old size of block *)
                             NewSize : CARDINAL)    (* new size of block *)
                                                    (* in paragraphs     *)
                             : BOOLEAN;             (* if sucessful      *)

(* This procedure attempts to change the size of an allocated block
   It returns TRUE if succeeded (only expansion can fail)
*)

VAR
  target,prev,
  split      : FarHeapRecPtr;
  tseg       : CARDINAL;
  result     : BOOLEAN;
  extendsize : CARDINAL;
  Res        : FarADDRESS;
  ie: CARDINAL;
BEGIN
  IF (CARDINAL(Seg(A^))=0)OR(CARDINAL(Ofs(A^))<>0) THEN
      Lib.RunTimeError(CoreSig._FatalErrorPos(), 93H,  'FarHeapChangeAlloc : Invalid Argument');
  END;
  IF OldSize = NewSize THEN RETURN TRUE END;
  IF OldSize > NewSize THEN
    target := [CARDINAL(Seg(A^))+NewSize:0];
    FarHeapDeallocate(Source,target,OldSize-NewSize);
    RETURN TRUE;
  END;
  extendsize := NewSize-OldSize;
(*%T _mthread *)
  ie := SYSTEM.GetFlags(); SYSTEM.DI;
(*%E *)
  target := A;
  prev := Source;
  tseg := Seg(target^);
  WHILE CARDINAL(Seg(prev^.next^)) < tseg DO
    prev := prev^.next;
  END;
  IF (prev^.next^.size <> EndMarker) AND
     (CARDINAL(Seg(prev^.next^)) = CARDINAL(Seg(target^))+OldSize) AND
     (extendsize <= prev^.next^.size) THEN
    IF (extendsize = prev^.next^.size) THEN
      prev^.next := prev^.next^.next
    ELSE
      split := [CARDINAL(Seg(target^))+NewSize:0];
      split^.next := prev^.next^.next;
      split^.size := prev^.next^.size - extendsize;
      prev^.next  := split;
    END;
    result := TRUE;
  ELSE
    result := FALSE;
  END;
(*%T _mthread *)
  SYSTEM.SetFlags(ie);;
(*%E *)
  RETURN result;
END FarHeapChangeAlloc;



PROCEDURE FarHeapChangeSize(Source  : FarHeapRecPtr;         (* source heap       *)
                            VAR A   : FarADDRESS; (* block to change   *)
                            OldSize,                         (* old size of block *)
                            NewSize : CARDINAL );            (* new size of block
                                                                in paragraphs  *)

(*
   This procedure will change the size of an allocated block
   avoiding any copy of data if possible
   calls HeapChangeAlloc
*)

VAR
  na : FarADDRESS;
BEGIN
  IF NOT FarHeapChangeAlloc ( Source, A, OldSize, NewSize ) THEN
    FarHeapAllocate(Source,na,NewSize);
    IF na # FarNIL THEN
      Lib.FarWordMove(A, na, OldSize*8);
      FarHeapDeallocate(Source,A,OldSize);
    END;
    A := na;
  END;
END FarHeapChangeSize;

PROCEDURE FarAllocate(VAR a: FarADDRESS; size: CARDINAL);


VAR ps : CARDINAL;
BEGIN
  IF size>0FFF0H THEN ps := 1000H
  ELSE                ps := (size+15) DIV 16;
  END ;
  FarHeapAllocate(MainHeap,a,ps);
  IF ClearOnAllocate AND (a # FarNIL) THEN
    Lib.FarWordFill( a,ps*8,0);
  END;
END FarAllocate;


PROCEDURE FarDeallocate(VAR a: FarADDRESS; size: CARDINAL);
VAR
  ps : CARDINAL ;
BEGIN
  IF size>0FFF0H THEN ps := 1000H
  ELSE                ps := (size+15) DIV 16;
  END ;
  FarHeapDeallocate(MainHeap,a,ps);
END FarDeallocate;


PROCEDURE FarAvailable(size: CARDINAL) : BOOLEAN;
VAR
  ps : CARDINAL ;
BEGIN
  IF size=0 THEN          ps := 1
  ELSIF size>0FFF0H THEN  ps := 1000H
  ELSE                    ps := (size+15) DIV 16;
  END ;
  RETURN ps <= FarHeapAvail(MainHeap);
END FarAvailable;
(*%E *)

(*%T _OS2 *)
PROCEDURE FarMakeHeap( Source : CARDINAL;     (* base segment of heap *)
                        Size   : CARDINAL      (* size in paragraphs *)
                     ) : FarHeapRecPtr;
BEGIN
    Lib.RunTimeError(CoreSig._FatalErrorPos(), 099H, 'FarMakeHeap : Not Supported Under OS2 *)');
    RETURN FarNIL;
END FarMakeHeap;


PROCEDURE FarHeapAllocate(Source : FarHeapRecPtr;  (* source heap                *)
                          VAR A  : FarADDRESS; (* result                     *)
                          Size   : CARDINAL);      (* request size in paragraphs *)

BEGIN
    Lib.RunTimeError(CoreSig._FatalErrorPos(), 099H, 'FarHeapAllocate : Not Supported Under OS2 *)');
END FarHeapAllocate;


PROCEDURE FarHeapAvail(Source: FarHeapRecPtr) : CARDINAL;
(* returns the largest block size available for allocation in paragraphs *)

BEGIN
    Lib.RunTimeError(CoreSig._FatalErrorPos(), 099H, 'FarHeapAvail : Not Supported Under OS2 *)');
    RETURN 0;
END FarHeapAvail;


PROCEDURE FarHeapTotalAvail(Source: FarHeapRecPtr) : CARDINAL;

BEGIN
    Lib.RunTimeError(CoreSig._FatalErrorPos(), 099H, 'FarHeapTotalAvail : Not Supported Under OS2 *)');
    RETURN 0;
END FarHeapTotalAvail;



PROCEDURE FarHeapDeallocate(Source : FarHeapRecPtr;  (* source heap         *)
                            VAR A: FarADDRESS;
                            Size   : CARDINAL );     (* size of block
                                                        in paragraphs       *)
BEGIN
    Lib.RunTimeError(CoreSig._FatalErrorPos(), 099H, 'FarHeapDeallocate: Not Supported Under OS2 *)');
END FarHeapDeallocate;


PROCEDURE FarHeapChangeAlloc(Source  : FarHeapRecPtr;  (* source heap       *)
                             A       : FarADDRESS; (* block to change   *)
                             OldSize,               (* old size of block *)
                             NewSize : CARDINAL)    (* new size of block *)
                                                    (* in paragraphs     *)
                             : BOOLEAN;             (* if sucessful      *)

(* This procedure attempts to change the size of an allocated block
   It returns TRUE if succeeded (only expansion can fail)
*)

BEGIN
    Lib.RunTimeError(CoreSig._FatalErrorPos(), 099H, 'FarHeapChangeAlloc: Not Supported Under OS2 *)');
    RETURN FALSE;
END FarHeapChangeAlloc;



PROCEDURE FarHeapChangeSize(Source  : FarHeapRecPtr;         (* source heap       *)
                            VAR A   : FarADDRESS; (* block to change   *)
                            OldSize,                         (* old size of block *)
                            NewSize : CARDINAL );            (* new size of block
                                                                in paragraphs  *)

(*
   This procedure will change the size of an allocated block
   avoiding any copy of data if possible
   calls HeapChangeAlloc
*)

BEGIN
    Lib.RunTimeError(CoreSig._FatalErrorPos(), 099H, 'FarHeapChangeSize: Not Supported Under OS2 *)');
END FarHeapChangeSize;


PROCEDURE FarAllocate(VAR a: FarADDRESS; size: CARDINAL);

VAR
  Res: FarADDRESS;
BEGIN
  IF size = 0 THEN size := 2 END;
  IF ClearOnAllocate THEN
      Res := CoreMem._fcalloc(1, size);
  ELSE
      Res := CoreMem._fmalloc(size);
  END;
  IF Res = FarNIL THEN
    IF Check THEN
      Lib.RunTimeError(CoreSig._FatalErrorPos(), 94H, 'FarAllocate: Out Of Memory');
    END;
  END;
  a := Res;
END FarAllocate;


PROCEDURE FarDeallocate(VAR a: FarADDRESS; size: CARDINAL);

BEGIN
    CoreMem._ffree(a);
    a:= SYSTEM.FarNIL;
END FarDeallocate;


PROCEDURE FarAvailable(size: CARDINAL) : BOOLEAN;

BEGIN
  RETURN TRUE;
END FarAvailable;
(*%E *)

PROCEDURE NearMakeHeap(Source: NearADDRESS; Size: CARDINAL): NearHeapRecPtr;
         (* ========== *)
  VAR Storage, FirstFree: NearHeapRecPtr;
  BEGIN
    Size := (Size DIV Align) * Align;
    IF Size < Align*3 THEN
      Lib.RunTimeError(CoreSig._FatalErrorPos(), 95H, 'NearMakeHeap: Size Too Small');
    END;
    IF Source = SYSTEM.NearNIL THEN
      Lib.RunTimeError(CoreSig._FatalErrorPos(), 89H, 'NearMakeHeap: Invalid Argument');
    END;
    Storage := NearHeapRecPtr(Source);
    FirstFree := NearHeapRecPtr(CARDINAL(Source)+CARDINAL(Align));
    Storage^.size := Size;
    Storage^.next := FirstFree;
    FirstFree^.size := Size - Align;
    FirstFree^.next := SYSTEM.NearNIL;
    RETURN Storage;
END NearMakeHeap;

PROCEDURE NearHeapAllocate(Source: NearHeapRecPtr; VAR A: NearADDRESS; Size: CARDINAL);
         (* ======== *)
  VAR
    Base, Free, New: NearHeapRecPtr;
(*%T _OS2 *)
    Res: NearADDRESS;
(*%E *)
  BEGIN
(*%F _OS2 *)
(*%F _DLL *)
    IF (NOT NearHeapSetup) AND (Source = NearHeap) THEN
      InitNearHeap;
      Source := NearHeap;
    END;
(*%E *)
(*%E *)
(*%T _OS2 *)
  IF Source = NearHeap THEN
    IF Size = 0 THEN Size := 2 END;
    IF ClearOnAllocate THEN
        Res := CoreMem._ncalloc(1, Size);
    ELSE
        Res := CoreMem._nmalloc(Size);
    END;
    IF Res = NearNIL THEN
        IF Check THEN
          Lib.RunTimeError(CoreSig._FatalErrorPos(), 98H, 'NearAllocate: Out Of Memory');
        END;
    END;
    A := Res;
    RETURN;
  END;
(*%E *)
    IF Source = SYSTEM.NearNIL THEN
      Lib.RunTimeError(CoreSig._FatalErrorPos(), 8AH, 'NearHeapAllocate: Invalid Argument');
    END;
    IF Size < Align THEN
      Size := Align;
    ELSE
      Size := ( (Size+Align-1) DIV Align) * Align;
      IF Size = 0 THEN
          Size:=MAX(CARDINAL);
      END;
    END;
    Base := Source;
    LOOP
      Free := Base^.next;
      IF Free = SYSTEM.NearNIL THEN
        IF Check THEN
            Lib.RunTimeError(CoreSig._FatalErrorPos(), 96H, 'NearHeapAllocate: Out Of Memory');
        ELSE
            A := SYSTEM.NearNIL;
            RETURN;
        END;
      ELSIF Free^.size >= Size THEN
        EXIT;
      END;
      Base := Free;
    END;
    IF Free^.size = Size THEN
      Base^.next := Free^.next;
    ELSE
      New := NearHeapRecPtr(CARDINAL(Free)+Size);
      Base^.next := New;
      New^.size := Free^.size - Size;
      New^.next := Free^.next;
    END;
    IF ClearOnAllocate THEN
      Lib.WordFill ( ADR(Free^) , Size DIV 2 , 0 );
    END;
    A := NearADDRESS(Free);
END NearHeapAllocate;

PROCEDURE NearHeapDeallocate(Source: NearHeapRecPtr; VAR A: NearADDRESS; Size: CARDINAL );

VAR
    Curr, Base, Free: NearHeapRecPtr;

BEGIN
    IF (Source = SYSTEM.NearNIL) OR (A = SYSTEM.NearNIL) THEN
      Lib.RunTimeError(CoreSig._FatalErrorPos(), 8BH, 'NearHeapDeallocate: Invalid Argument');
    END;
(*%T _OS2 *)
    IF Source = NearHeap THEN
      CoreMem._nfree(A);
      A:= NearADDRESS(NIL);
      RETURN;
    END;
(*%E *)
    IF Size < Align THEN
      Size := Align;
    ELSE
      Size := ( (Size+Align-1) DIV Align) * Align;
      IF Size = 0 THEN
          Size:=MAX(CARDINAL);
      END;
    END;
    Curr := NearHeapRecPtr(A);
    A := SYSTEM.NearNIL;
    Base:=Source;
    LOOP
      Free := Base^.next;
      IF (Free = SYSTEM.NearNIL) OR (CARDINAL(Curr) < CARDINAL(Free)) THEN EXIT; END;
      Base := Free;
    END;
    IF CARDINAL(Base) + Base^.size = CARDINAL(Curr) THEN
      INC ( Base^.size , Size );
      Curr := Base;
    ELSE
      Base^.next := Curr;
      Curr^.next := Free;
      Curr^.size := Size;
    END;
    IF (Free # SYSTEM.NearNIL) AND (CARDINAL(Curr) + Curr^.size = CARDINAL(Free)) THEN
      INC ( Curr^.size, Free^.size);
      Curr^.next := Free^.next;
    END;
END NearHeapDeallocate;

PROCEDURE NearHeapAvail(Source: NearHeapRecPtr): CARDINAL;

VAR
    Curr: NearHeapRecPtr;
    Size, av: CARDINAL;
BEGIN
(*%F _OS2 *)
(*%F _DLL *)
    IF (NOT NearHeapSetup) AND (Source = NearHeap) THEN
      InitNearHeap;
      Source := NearHeap;
    END;
(*%E *)
(*%E *)
(*%T _OS2 *)
  IF Source = NearHeap THEN
      av := CoreMem._memmax();
      IF av <= 4 THEN
        av := 0;
      ELSE
        DEC(av, 4);
      END;
      RETURN av;
  END;
(*%E *)
    IF Source = SYSTEM.NearNIL THEN
      Lib.RunTimeError(CoreSig._FatalErrorPos(), 8CH, 'NearHeapAvail: Invalid Argument');
    END;
    Curr := Source^.next;
    Size := 0;
    WHILE Curr # SYSTEM.NearNIL DO
      IF Size < Curr^.size THEN
        Size := Curr^.size;
      END;
      Curr := Curr^.next;
    END;
    RETURN Size;
END NearHeapAvail;


PROCEDURE NearHeapTotalAvail(Source: NearHeapRecPtr): CARDINAL;

VAR
    Curr: NearHeapRecPtr;
    Size: CARDINAL;
BEGIN
(*%F _OS2 *)
(*%F _DLL *)
    IF (NOT NearHeapSetup) AND (Source = NearHeap) THEN
      InitNearHeap;
      Source := NearHeap;
    END;
(*%E *)
(*%E *)
(*%T _OS2 *)
  IF Source = NearHeap THEN
    RETURN CoreMem.nearcoreleft();
  END;
(*%E *)
    IF Source = SYSTEM.NearNIL THEN
      Lib.RunTimeError(CoreSig._FatalErrorPos(), 8DH, 'NearHeapTotalAvail: Invalid Argument');
    END;
    Curr := Source^.next;
    Size := 0;
    WHILE Curr # SYSTEM.NearNIL DO
      INC ( Size , Curr^.size );
      Curr := Curr^.next;
    END;
    RETURN Size;
END NearHeapTotalAvail;


PROCEDURE Merge(LowRec, HighRec: NearHeapRecPtr);

BEGIN
    IF (LowRec = SYSTEM.NearNIL) AND (HighRec = SYSTEM.NearNIL) AND
       (NearHeapRecPtr(CARDINAL(LowRec)+LowRec^.size) = HighRec) THEN
      LowRec^.next:=HighRec^.next;
      INC(LowRec^.size, HighRec^.size);
    END;
END Merge;

PROCEDURE NearHeapChangeSize(Source: NearHeapRecPtr; VAR A: NearADDRESS;
                          OldSize, NewSize : CARDINAL);

VAR
    OldA: NearADDRESS;
BEGIN
    IF (Source = SYSTEM.NearNIL) OR (A = SYSTEM.NearNIL) THEN
      Lib.RunTimeError(CoreSig._FatalErrorPos(), 8EH, 'NearHeapChangeSize: Invalid Argument');
    END;
    IF NearHeapChangeAlloc(Source, A, OldSize, NewSize) THEN
        RETURN;
    END;
    OldA := A;
    NearHeapAllocate(Source, A, NewSize);
    Lib.WordMove(ADR(OldA^), ADR(A^), OldSize DIV 2);
    NearHeapDeallocate(Source, OldA, OldSize);
END NearHeapChangeSize;

PROCEDURE NearHeapChangeAlloc(Source: NearHeapRecPtr; A: NearADDRESS;
                          OldSize, NewSize : CARDINAL): BOOLEAN;

VAR
    Curr, SplitRec, NextRec, PrevRec, NewRec: NearHeapRecPtr;
    Temp: NearHeapRec;
    SplitSize: CARDINAL;
(*%T _OS2 *)
    T: NearADDRESS;
(*%E *)
BEGIN
    IF (Source = SYSTEM.NearNIL) OR (A = SYSTEM.NearNIL) THEN
      Lib.RunTimeError(CoreSig._FatalErrorPos(), 8FH, 'NearHeapChangeAlloc: Invalid Argument');
    END;
(*%T _OS2 *)
    IF Source = NearHeap THEN
      T := CoreMem._nexpand(A, NewSize);
      RETURN  T # NearNIL;
    END;
(*%E *)
    IF NewSize < Align THEN
      NewSize := Align;
    ELSE
      NewSize := ( (NewSize+Align-1) DIV Align) * Align;
      IF NewSize = 0 THEN
          NewSize:=MAX(CARDINAL);
      END;
    END;
    IF OldSize < Align THEN
      OldSize := Align;
    ELSE
      OldSize := ( (OldSize+Align-1) DIV Align) * Align;
      IF OldSize = 0 THEN
          OldSize:=MAX(CARDINAL);
      END;
    END;
    IF OldSize = NewSize THEN RETURN TRUE END;
    Curr:=NearHeapRecPtr(A);
    NextRec:=Source;
    LOOP
        PrevRec:=NextRec;
        NextRec:=NextRec^.next;
        IF (NextRec = SYSTEM.NearNIL) OR (CARDINAL(NextRec) > CARDINAL(Curr)) THEN EXIT END;
    END;
    IF OldSize > NewSize THEN
        SplitSize:=OldSize-NewSize;
        SplitRec:=NearHeapRecPtr(CARDINAL(Curr)+NewSize);
        SplitRec^.size:=SplitSize;
        SplitRec^.next:=NextRec;
        PrevRec^.next:=SplitRec;
        Merge(SplitRec, NextRec);
        RETURN TRUE;
    END;
    IF (NextRec # SYSTEM.NearNIL) AND (NearHeapRecPtr(CARDINAL(Curr)+OldSize) = NextRec) THEN (* Next Block is free *)
        Temp.size := OldSize+NextRec^.size;
        Temp.next := NextRec^.next;
        IF Temp.size = NewSize THEN
            PrevRec^.next := Temp.next;
        ELSE
            NewRec := NearHeapRecPtr(CARDINAL(Curr)+NewSize);
            PrevRec^.next := NewRec;
            NewRec^.size := Temp.size-NewSize;
            NewRec^.next := Temp.next;
        END;
        RETURN TRUE;
    ELSE
        RETURN FALSE;
    END;
END NearHeapChangeAlloc;


(*%F _DLL *)
PROCEDURE NearAllocate(VAR a: NearADDRESS; size: CARDINAL);

BEGIN
  NearHeapAllocate(NearHeap,a,size);
END NearAllocate;


PROCEDURE NearDeallocate(VAR a: NearADDRESS; size: CARDINAL);

BEGIN
  NearHeapDeallocate(NearHeap,a,size);
END NearDeallocate;


PROCEDURE NearAvailable(size: CARDINAL) : BOOLEAN;

BEGIN
  RETURN size <= NearHeapAvail(NearHeap);
END NearAvailable;
(*%E *)

(*%T _DLL *)
PROCEDURE NearAllocate(VAR a: NearADDRESS; size: CARDINAL);

BEGIN
  a := NearNIL;
END NearAllocate;


PROCEDURE NearDeallocate(VAR a: NearADDRESS; size: CARDINAL);

BEGIN
END NearDeallocate;


PROCEDURE NearAvailable(size: CARDINAL) : BOOLEAN;

BEGIN
  RETURN FALSE;
END NearAvailable;
(*%E *)


(*%F _OS2 *)
PROCEDURE SegAllocate(Size: CARDINAL): CARDINAL;

VAR
  S: FarADDRESS;
BEGIN
  FarAllocate(S, Size);
  RETURN Seg(S^);
END SegAllocate;

PROCEDURE SegDeallocate(Sel: CARDINAL; Size: CARDINAL);

VAR
  S: FarADDRESS;
BEGIN
  S := [Sel: 0];
  FarDeallocate(S, Size);
END SegDeallocate;
(*%E *)

(*%T _OS2 *)
PROCEDURE SegAllocate(Size: CARDINAL): CARDINAL;

VAR
  S: CARDINAL;
BEGIN
  IF Dos.AllocSeg(Size, S, 0) = 0 THEN
    RETURN S;
  END;
  RETURN 0;
END SegAllocate;

PROCEDURE SegDeallocate(Sel: CARDINAL; Size: CARDINAL);

BEGIN
  IF Dos.FreeSeg(Sel) # 0 THEN END;
END SegDeallocate;
(*%E *)

BEGIN
    Check := TRUE;
    ClearOnAllocate := FALSE;
    NearHeap := NearHeapRecPtr(0FFFFH);
(*%F _OS2 *)
    MainHeap := [SYSTEM.HeapBase: 0];
    NearHeapSetup := FALSE;
    FarHeapSetup := FALSE;
(*%E *)
END Storage.
