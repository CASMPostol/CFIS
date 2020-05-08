(**********************************************************************
|  Title   : Storage management
|  Author  : M.Morawski
|  System  : LOGITECH MODULA-2/86
|  Version : 1.01
|  Copyright (C), Optimal Control Laboratory.
|        allocated blocks are at paragraph begining with offset zero
|        size is rounded 10H upward
|
**********************************************************************)
IMPLEMENTATION MODULE Storage[8];

  FROM RTSMain IMPORT
    activProcess, OverlayPtr, Status, Terminate, InstallTermProc;

  FROM SYSTEM IMPORT
    WORD, ADDRESS, TSIZE, GETREG, SETREG, SWI, AX, BX, ADR;

  IMPORT
    XMS;

  CONST

    MinElSize = 10H;
    (*  Memory partitions must at least have the paragraph size. *)

    MaxCard = 0FFFFH;
    None    = 0FFFFH;
    NullADR = 0FFFFH:0;  (* None : 0 *)

    MaxAllocatableSize = 0FFFH; (* para *)

    MaxSearchLimit = 11;
    (*
     This constant is used when searching the free list upon allocate.
     An 'exact fit' is defined to be a free list element which has
     exactly the size of the space to be allocated. A 'first fit' is
     defined to be the first free list element found, which is of a
     size larger than the space to be allocated, and which does not
     leave a remainder of less than the size of a free list record
     when space from it is allocated.

     After a first fit has been found, we additionally check up to
     "MaxSearchLimit" number of free list elements for an exact fit,
     before we decide to allocate space from the first fit found.
    *)

  TYPE
    FreeElementPtr = POINTER TO FreeElement;

    FreeList    = RECORD
                    CASE CARDINAL OF
                      1  : p : FreeElementPtr;
                    | 2  : a : ADDRESS;
                    | 3  : off, seg : CARDINAL;
                    END;
                  END;

    FreeElement = RECORD
                    next    : FreeList;
                    sizeSEG : CARDINAL;
                  END;

    HeapElement = RECORD
                    BEGaddr    : CARDINAL;
                    ENDaddr    : CARDINAL;
                    Upper      : BOOLEAN;
                  END;

    HeapList    = ARRAY [1..10H] OF HeapElement;


  VAR
    firstFree : FreeList;
    Heap      : HeapList;
    FreeH     : CARDINAL;
    Occupied  : BOOLEAN;
    numberOfHeapBlock : CARDINAL;


    PROCEDURE BelongsToHeap ( adr  : ADDRESS;
                             size : CARDINAL ) : BOOLEAN;
    (*  returns TRUE if the memory between 'adr' and 'adr' + 'size'
       is included in the heap list.    *)
    VAR
      index      : CARDINAL;
    BEGIN
      IF (adr.OFFSET#0) THEN
        RETURN (adr=NIL)
      END;
      size   := (size+15) DIV 10H;
      index  := 1;
      WHILE (index <= numberOfHeapBlock) DO
        WITH Heap[index] DO
          IF ((adr.SEGMENT)>=BEGaddr) AND ((adr.SEGMENT+size)<ENDaddr) THEN
            RETURN TRUE;
          END;
        END;
        INC (index);
      END; (*while*)
      RETURN FALSE
    END BelongsToHeap;

    PROCEDURE DosAvailable():CARDINAL; (* w segmentach *)
      VAR
        IleSegmentow : CARDINAL;
      BEGIN
        SETREG( BX, 0FFFFH );
        SETREG( AX, 04800H );
        SWI( 21H );
        GETREG( BX, IleSegmentow );
        RETURN IleSegmentow;
      END DosAvailable;

    PROCEDURE DosAlloc( Ile : CARDINAL ):CARDINAL; (* adres segmentu *)
      VAR
        AdrSegmentu : CARDINAL;
      BEGIN
        SETREG( BX, Ile );
        SETREG( AX, 04800H );
        SWI( 21H );
        GETREG( AX, AdrSegmentu );
        RETURN AdrSegmentu;
      END DosAlloc;

    PROCEDURE UMBAvailable(  ) : CARDINAL;
      VAR
        r, dummy, IleP : CARDINAL;
      BEGIN
        r := XMS.AllocUpperMemBlock( 0FFFFH, dummy, IleP );
        r := r MOD 100H;
        IF r = 0B0H THEN
          RETURN IleP;
        ELSE
          RETURN 0;
        END;
      END UMBAvailable;

    PROCEDURE UMBAlloc( Ile : CARDINAL ) : CARDINAL;
      VAR
        r, adr : CARDINAL;
      BEGIN
        r := XMS.AllocUpperMemBlock( Ile, adr, Ile );
        r := r MOD 100H;
        IF r # 0 THEN
          Terminate( Fatal );
        END;
        RETURN adr;
      END UMBAlloc;

    PROCEDURE Link( VAR Lista  : FreeList;
                        Start,
                        Size   : CARDINAL);
      VAR
        fe : FreeElementPtr;
      BEGIN
        fe := ADR( Lista );
        WHILE fe^.next.a # NullADR DO
          fe := fe^.next.p;
        END;
        WITH fe^.next DO
          seg := Start;
          off := 0;
          p^.sizeSEG := Size;
          p^.next.a    := NullADR;
        END;
      END Link;

    PROCEDURE Install;
    (* the free list and the heap list are created *)
    VAR
      IleP  : CARDINAL;
    BEGIN
      firstFree.a := NullADR;
      numberOfHeapBlock := 0;
      LOOP
        IleP := DosAvailable();
        IF IleP = 0 THEN
          IF numberOfHeapBlock = 0 THEN
            Terminate( HeapOvf );
          END;
          EXIT;
        END;
        INC( numberOfHeapBlock );
        WITH Heap[numberOfHeapBlock] DO
          BEGaddr := DosAlloc( IleP );
          ENDaddr := BEGaddr + IleP;
          Upper := FALSE;
          Link( firstFree,
                BEGaddr,
                IleP );
        END;
      END;
      LOOP
        IleP := UMBAvailable();
        IF IleP = 0 THEN
          EXIT;
        END;
        INC( numberOfHeapBlock );
        WITH Heap[numberOfHeapBlock] DO
          BEGaddr := UMBAlloc( IleP );
          ENDaddr := BEGaddr + IleP;
          Upper := TRUE;
          Link( firstFree,
                BEGaddr,
                IleP );
        END;
      END;
      InitializeHeapSize;
    END Install;


    PROCEDURE InitializeHeapSize;
    VAR
      h : FreeList;
    BEGIN
      FreeH := 0;
      h := firstFree ;
      WHILE h.seg # None DO
        WITH h.p^ DO
          INC( FreeH, sizeSEG );
          h := next;
        END;
      END;
    END InitializeHeapSize;

  PROCEDURE Concatenate ( thisFree  : FreeList);
  (*    Concatenates adjacent free list elements following "thisFree"  *)
    VAR
      nextFree  : FreeList;
      thisSize  : CARDINAL;
  BEGIN
    nextFree := thisFree.p^.next;
    WHILE nextFree.seg # None DO
      thisSize := thisFree.p^.sizeSEG;
      IF (thisFree.seg+thisSize)=nextFree.seg THEN
        INC(thisFree.p^.sizeSEG, nextFree.p^.sizeSEG);
        nextFree := nextFree.p^.next;
        thisFree.p^.next := nextFree;
      ELSE
        RETURN;
      END;
    END; (*while*)
  END Concatenate;


  PROCEDURE ALLOCATE ( VAR adr       : ADDRESS;
                           nrOfBytes : CARDINAL );
  (*
   Allocate some storage from the heap.
     in:  nrOfBytes  Number of bytes to allocate.
     out: adr        Modula-2 data address of the storage allocated.
                   NIL is returned if not enough contiguous memory
  *)

    VAR
      previousFree : FreeList;
      nextFree     : FreeList;
      firstFit     : FreeList;
      availSize    : CARDINAL;
      searchTries  : CARDINAL;

  BEGIN
    IF Occupied THEN
      HALT;
    END;
    Occupied := TRUE;
    IF (nrOfBytes > 0) THEN
      adr := NullADR;
      nrOfBytes := (nrOfBytes+15) DIV 16;
      firstFit.a := NullADR;
      previousFree.a := NullADR;
      nextFree := firstFree;
      LOOP
 (* This loop will search an exact fit or a firstfit free block element *)
        IF (nextFree.seg = None) THEN
          EXIT;
        END;
        availSize := nextFree.p^.sizeSEG;
        IF availSize = nrOfBytes THEN (* exact fit *)
          adr := nextFree.a;
          EXIT;
        ELSIF (firstFit.seg=None) THEN
          IF  (availSize > nrOfBytes) THEN (* can it be a 'first fit' element *)
            firstFit.seg := nextFree.seg;
            searchTries := MaxSearchLimit;
          END;
        ELSE  (* first fit was found search *)
          IF (searchTries = 0) THEN
            EXIT;
          END;
          DEC (searchTries);
        END;
        previousFree := nextFree;
        nextFree := nextFree.p^.next;
      END; (*loop*)

      IF adr.SEGMENT # None THEN
        (* An exactly fitting free list element was found and
           is allocated at nextFree. Remove it from the free list:  *)
        nextFree :=  nextFree.p^.next;
        IF previousFree.seg = None THEN
          firstFree := nextFree;
        ELSE
          previousFree.p^.next := nextFree;
        END;
      ELSIF firstFit.seg # None THEN
        (*Allocate space from the first fitting element found. *)
        (* get from end *)
          DEC (firstFit.p^.sizeSEG, nrOfBytes);
          adr.SEGMENT := firstFit.p^.sizeSEG + firstFit.seg;
      ELSE
        adr := NIL;
        (* No exact fit or first fit have been found. *)
        Terminate (HeapOvf);
        (* extending the heap is impossible *)
      END;
    ELSE  (* size is 0 *)
      adr := NIL;
    END;
    DEC( FreeH, nrOfBytes );
    Occupied := FALSE;
  END ALLOCATE;


  PROCEDURE DEALLOCATE ( VAR adr       : ADDRESS;
                             nrOfBytes : CARDINAL);
  (*
   Deallocate some storage allocated from the heap previously.

   in:  adr        Modula-2 data address of the storage area
                   to be Deallocated.
        nrOfBytes  Number of bytes to Deallocate.

   out: adr        Always returns NIL.

   The storage released by this procedure is made available for
   subsequent calls to "ALLOCATE".
   A 'BadOperand' error occurs if the memory given as parameter does
   not belong to the heap  *)

    VAR
      previousFree,
      nextFree,
      newL         : FreeList;

  BEGIN
    IF adr = NIL THEN
      RETURN;
    END;
    IF Occupied THEN
      HALT;
    END;
    Occupied := TRUE;
    IF NOT BelongsToHeap(adr,nrOfBytes ) THEN
      Terminate(BadOperand);
    END (* if *);
    IF adr=NIL THEN
      RETURN
    END (* if *);
    nrOfBytes := (nrOfBytes+15) DIV 10H;
    newL.a := adr;
    previousFree.a := NullADR;
    nextFree := firstFree;
    WHILE (nextFree.seg # None) AND (nextFree.seg < adr.SEGMENT) DO
      (* free list is ordered from lower to higher addresses *)
      previousFree := nextFree;
      nextFree := nextFree.p^.next;
    END; (*while*)
    (*
     At this point the following condition is always true:
     ((nextFree = Null) OR (nextFree >= adr))
     AND
     ((previousFree = Null)) OR (previousFree < adr))
    *)

    (* Now insert the new free element into the free list: *)
    IF previousFree.seg = None THEN
      (* Insert new free element before the current firstFree of the
         free list, make it the new firstFree     *)

      newL.p^.next := nextFree;
      newL.p^.sizeSEG := nrOfBytes;
      firstFree := newL;
      IF (firstFree.seg+firstFree.p^.sizeSEG) = newL.seg THEN
        Concatenate (firstFree);
      END;
      (*  After a DEALLOCATE a concatenation is done if possible.  *)
    ELSIF nextFree.seg = None THEN
      (* Insert the new free element after the firstFree of the free
       list, after the previous element:                            *)
      previousFree.p^.next := newL;
      newL.p^.next.a := NullADR;
      newL.p^.sizeSEG := nrOfBytes;
    (*After a DEALLOCATE a concatenation is done if possible.   *)
      IF (previousFree.seg+previousFree.p^.sizeSEG) = newL.seg THEN
        Concatenate (previousFree);
      END;
    ELSE
      (*nextFree and previousFree <> NullADR.
        Insert the new free element after the firstFree of the free
        list, between the previous and the next free element: *)

      previousFree.p^.next := newL;
      newL.p^.next := nextFree;
      newL.p^.sizeSEG := nrOfBytes;

      IF (previousFree.seg+previousFree.p^.sizeSEG) = newL.seg THEN
        (* Concatenation with nextFree is done in this call
          if nextFree is adjacent to newL:  *)
        Concatenate (previousFree);
      ELSIF (newL.seg+newL.p^.sizeSEG)=nextFree.seg THEN
        Concatenate (newL);
      END;
      (* After a DEALLOCATE a concatenation is done if possible. *)
    END;
    adr := NIL;
    INC( FreeH, nrOfBytes );
    Occupied := FALSE;
  END DEALLOCATE;


  PROCEDURE Available ( nrOfBytes: CARDINAL ) : BOOLEAN;
  (* Test whether some amount of storage could be allocated.
   in:  nrOfBytes  Number of bytes to allocate.
   out:            TRUE if ALLOCATE (adr, nrOfBytes) would
                   succeed.  *)
    VAR
      availSize : CARDINAL;
      nextFree  : FreeList;
  BEGIN
    IF Occupied THEN
      HALT;
    END;
    Occupied := TRUE;
    nrOfBytes:= (nrOfBytes+15) DIV 16;
    nextFree:= firstFree;
    WHILE nextFree.seg <> None DO
      (* Check if space from this free element could be allocated: *)
      availSize := nextFree.p^.sizeSEG;
      IF (availSize >= nrOfBytes) THEN
        RETURN TRUE;
      END;
      nextFree := nextFree.p^.next;
    END;
    Occupied := FALSE;
    RETURN FALSE;
  END Available;

  PROCEDURE InstallHeap;
  (* Call the initialization procedure 'Install' so the current Heap List
     is initialized, this is a simple way to reinitialize the heap list
     without making the effort to call the 'DEALLOCATE' procedure.  *)
  BEGIN
    Install;
  END InstallHeap;

  PROCEDURE RemoveHeap;
  BEGIN
    (*nothing done*)
  END RemoveHeap;

  PROCEDURE Terminator(  );
    VAR
      i : CARDINAL;
    BEGIN
      FOR i := 1 TO numberOfHeapBlock DO
        IF Heap[i].Upper THEN
          IF XMS.FreeUpperMemBlock( Heap[i].BEGaddr ) # 0 THEN
          END;
        END;
        SetStrategia( StaraStrategia );
        SetChain( StaryCh );
      END;
    END Terminator;

  PROCEDURE SetStrategia( Mode : CARDINAL ) ;
    BEGIN
      SETREG( AX, 5801H );
      SETREG( BX, Mode  );
      SWI( 21H );
    END SetStrategia;

  PROCEDURE GetStrategia( ) : CARDINAL ;
    VAR
      i : CARDINAL;
    BEGIN
      SETREG( AX, 5800H );
      SWI( 21H );
      GETREG( AX, i );
      RETURN i;
    END GetStrategia;

  PROCEDURE SetChain( Mode : CARDINAL ) ;
    BEGIN
      SETREG( AX, 5803H );
      SETREG( BX, Mode  );
      SWI( 21H );
    END SetChain;

  PROCEDURE GetChain( ) : CARDINAL ;
    VAR
      i : CARDINAL;
    BEGIN
      SETREG( AX, 5802H );
      SWI( 21H );
      GETREG( AX, i );
      RETURN i MOD 256;
    END GetChain;

VAR
  StaraStrategia : CARDINAL;
  StaryCh        : CARDINAL;
BEGIN
  StaraStrategia := GetStrategia();
  StaryCh        := GetChain();
  SetStrategia(80H);
  SetChain(1);
  Occupied := FALSE;
  Install;
  InstallTermProc( Terminator );
END Storage.
