IMPLEMENTATION MODULE XMS;

FROM SYSTEM IMPORT
  Registers;
FROM Lib IMPORT
  Intr;
FROM Str IMPORT
  CardToStr, Concat;
  
PROCEDURE CallXMS;
BEGIN
  CODE( 02EH, 0FFH, 01EH,      (* call far cs:XMS@XmsControl *)
        
END CallXMS;

PROCEDURE Xms(VAR r : Registers); IN XmsAsm;
PROCEDURE XmsInstalled():BOOLEAN; IN XmsAsm;
PROCEDURE TryToInstall; IN XmsAsm;

PROCEDURE RequestHMA(Bytes : CARDINAL ) : SHORTCARD;
VAR
  r : Registers;
BEGIN
  r.DX := Bytes;
  r.AH := 1;
  Xms(r);
  IF r.AX = 0 THEN
    RETURN r.BL;
  ELSE
    RETURN r.AL;
  END;
END RequestHMA;

PROCEDURE ReleaseHMA() : SHORTCARD;
VAR
  r : Registers;
BEGIN
  r.AH := 2;
  Xms(r);
  IF r.AX = 0 THEN
    RETURN r.BL;
  ELSE
    RETURN r.AL;
  END;
END ReleaseHMA;

PROCEDURE GlobalEnableA20() : SHORTCARD;
VAR
  r : Registers;
BEGIN
  r.AH := 3;
  Xms(r);
  IF r.AX = 0 THEN
    RETURN r.BL;
  ELSE
    RETURN r.AL;
  END;
END GlobalEnableA20;

PROCEDURE GlobalDisableA20() : SHORTCARD;
VAR
  r : Registers;
BEGIN
  r.AH := 4;
  Xms(r);
  IF r.AX = 0 THEN
    RETURN r.BL;
  ELSE
    RETURN r.AL;
  END;
END GlobalDisableA20;

PROCEDURE LocalEnableA20() : SHORTCARD;
VAR
  r : Registers;
BEGIN
  r.AH := 5;
  Xms(r);
  IF r.AX = 0 THEN
    RETURN r.BL;
  ELSE
    RETURN r.AL;
  END;
END LocalEnableA20;

PROCEDURE LocalDisableA20() : SHORTCARD;
VAR
  r : Registers;
BEGIN
  r.AH := 6;
  Xms(r);
  IF r.AX = 0 THEN
    RETURN r.BL;
  ELSE
    RETURN r.AL;
  END;
END LocalDisableA20;

PROCEDURE QueryA20() : SHORTCARD;
VAR
  r : Registers;
BEGIN
  r.AH := 7;
  Xms(r);
  IF r.AX = 0 THEN
    RETURN r.BL;
  ELSE
    RETURN r.AL;
  END;
END QueryA20;


PROCEDURE QueryFreeExtMem(VAR TotalFree,
                              LargestBlock : CARDINAL ) : SHORTCARD;
VAR
  r : Registers;
BEGIN
  r.AH := 8;
  Xms(r);
  IF r.AX = 0 THEN
    RETURN r.BL;
  ELSE
    TotalFree := r.DX;
    LargestBlock := r.AX;
    RETURN 0;
  END;
END QueryFreeExtMem;

PROCEDURE AllocateExtMem(    SizeInK     : CARDINAL;
                         VAR XmsHandle   : CARDINAL
                        ) : SHORTCARD;
VAR
  r : Registers;
BEGIN
  r.AH := 9;
  r.DX := SizeInK;
  Xms(r);
  IF NOT ODD(r.AX) THEN
    RETURN r.BL;
  ELSE
    XmsHandle := r.DX;
    RETURN 0;
  END;
END AllocateExtMem;

PROCEDURE FreeExtMem (XmsHandle : CARDINAL ) : SHORTCARD;
VAR
  r : Registers;
BEGIN
  r.AH := 10;
  r.DX := XmsHandle;
  Xms(r);
  IF NOT ODD(r.AX) THEN
    RETURN r.BL;
  ELSE
    RETURN 0;
  END;
END FreeExtMem;

PROCEDURE MoveExtMemBlock( ControlBlock : ExtMemMoveStruct ) : SHORTCARD;
VAR
  r : Registers;
BEGIN
  r.AH := 11;
  r.DS := Seg(ControlBlock);
  r.SI := Ofs(ControlBlock);
  Xms(r);
  IF NOT ODD(r.AX) THEN
    RETURN r.BL;
  ELSE
    RETURN 0;
  END;
END MoveExtMemBlock;

PROCEDURE LockExtMemBlock (    XmsHandle   : CARDINAL;
                           VAR LockedBlock : ExtMemPtr ) : SHORTCARD;
VAR
  r : Registers;
BEGIN
  r.AH := 12;
  r.DX := XmsHandle;
  Xms(r);
  IF NOT ODD(r.AX) THEN
    RETURN r.BL;
  ELSE
    LockedBlock := ExtMemPtr([r.BX:r.DX]); (* ???? mlodszy-starszy *)
    RETURN 0;
  END;
END LockExtMemBlock;

PROCEDURE UnlockExtMemBlock(XmsHandle : CARDINAL ) : SHORTCARD;
VAR
  r : Registers;
BEGIN
  r.AH := 13;
  r.DX := XmsHandle;
  Xms(r);
  IF NOT ODD(r.AX) THEN
    RETURN r.BL;
  ELSE
    RETURN 0;
  END;
END UnlockExtMemBlock;

PROCEDURE GetHandleInfo(    XmsHandle    : CARDINAL;
                        VAR LockCount    : SHORTCARD;
                        VAR HandlesLeft  : SHORTCARD;
                        VAR BlockSizeInK : CARDINAL  ) : SHORTCARD;
VAR
  r : Registers;
BEGIN
  r.AH := 14;
  r.DX := XmsHandle;
  Xms(r);
  IF NOT ODD(r.AX) THEN
    RETURN r.BL;
  ELSE
    LockCount := r.BH;
    HandlesLeft := r.BL;
    BlockSizeInK := r.DX;
    RETURN 0;
  END;
END GetHandleInfo;

PROCEDURE ResizeExtMemBlock(XmsHandle  : CARDINAL;
                            NewSizeInK : CARDINAL ) : SHORTCARD;
VAR
  r : Registers;
BEGIN
  r.AH := 15;
  r.DX := XmsHandle;
  r.BX := NewSizeInK;
  Xms(r);
  IF NOT ODD(r.AX) THEN
    RETURN r.BL;
  ELSE
    RETURN 0;
  END;
END ResizeExtMemBlock;

PROCEDURE AllocUpperMemBlock(    SizeInParas : CARDINAL;
                             VAR SegmentBase : CARDINAL;
                             VAR Size        : CARDINAL ) : SHORTCARD;
VAR
  r : Registers;
BEGIN
  r.AH := 16;
  r.DX := SizeInParas;
  Xms(r);
  Size := r.DX;
  IF NOT ODD(r.AX) THEN
    RETURN r.BL;
  ELSE
    SegmentBase := r.BX;
    RETURN 0;
  END;
END AllocUpperMemBlock;

PROCEDURE FreeUpperMemBlock(SegmentBase : CARDINAL ) : SHORTCARD;
VAR
  r : Registers;
BEGIN
  r.AH := 17;
  r.DX := SegmentBase;
  Xms(r);
  IF NOT ODD(r.AX) THEN
    RETURN r.BL;
  ELSE
    RETURN 0;
  END;
END FreeUpperMemBlock;

PROCEDURE XmsErrorString(ErrorCode : SHORTCARD ) : Text;
VAR
  s : Text;
  ok : BOOLEAN;
BEGIN
  CASE ErrorCode OF
  | NoError:
      RETURN 'No Error';
  | FuncNotImplemented:
      RETURN 'Function is not implemented';
  | VDiskDeviceDetected:
      RETURN 'A VDISK compatible device found';
  | A20Error:
      RETURN 'An A20 error occurred';
  | GeneralDriverError:
      RETURN 'General driver error';
  | UnrecoverableError:
      RETURN 'Unrecoverable driver error';
  | HmaDoesNotExist:
      RETURN 'High memory area does not exist';
  | HmaAlreadyInUse:
      RETURN 'High memory area already in use';
  | HmaSizeTooSmall:
      RETURN 'Size requested less than /HMAMIN';
  | HmaNotAllocated:
      RETURN 'High memory area not allocated';
  | A20StillEnabled:
      RETURN 'A20 line is still enabled';
  | AllExtMemAllocated:
      RETURN 'All extended memory is allocated';
  | OutOfExtMemHandles:
      RETURN 'Extended memory handles exhausted';
  | InvalidHandle:
      RETURN 'Invalid handle';
  | InvalidSourceHandle:
      RETURN 'Invalid source handle';
  | InvalidSourceOffset:
      RETURN 'Invalid source offset';
  | InvalidDestHandle:
      RETURN 'Invalid destination handle';
  | InvalidDestOffset:
      RETURN 'Invalid destination offset';
  | InvalidLength:
      RETURN 'Invalid length';
  | OverlapInMoveReq:
      RETURN 'Overlap in move request';
  | ParityErrorDetected:
      RETURN 'Parity error detected';
  | BlockIsNotLocked:
      RETURN 'Block is not locked';
  | BlockIsLocked:
      RETURN 'Block is locked';
  | LockCountOverflowed:
      RETURN 'Lock count overflowed';
  | LockFailed:
      RETURN 'Lock failed';
  | SmallerUMBAvailable:
      RETURN 'A smaller upper memory block is available';
  | NoUMBAvailable:
      RETURN 'No upper memory blocks are available';
  | InvalidUMBSegment:
      RETURN 'Invalid upper memory block segment';
  ELSE
    CardToStr(VAL(LONGCARD, ErrorCode), s, 16, ok);
    Concat(s, 'Unknown error nr: ', s);
    RETURN s;
  END;
END XmsErrorString;

BEGIN
  TryToInstall;
END XMS.