MODULE XmsZas;

FROM XMS IMPORT
  AllocateExtMem, UnlockExtMemBlock, LockExtMemBlock, FreeExtMem,
  ExtMemPtr;
FROM SYSTEM IMPORT
  SETREG, GETREG, CX, BX, DX, CODE, WORD;


PROCEDURE Get( From : ExtMemPtr ) : WORD;
  VAR
    a : WORD;
  BEGIN
    SETREG( DX, From.RealPtr.SEGMENT );
    SETREG( BX, From.RealPtr.OFFSET );
    CODE( 033h, 0c0h );                  (* xor ax, ax *)
    CODE( 08eh, 0c0h );                  (* mov es,ax *)
    CODE( 08bh, 0fah );                  (* mov di,dx *)
    CODE( 066h, 0c1h, 0e7h, 010h );      (* shl edi, 16 *)
    CODE( 08bh, 0fbh );                  (* mov di,bx *)
    CODE( 067h, 026h, 08bh, 00fh );      (* mov cx, es:[edi] *)
    GETREG( CX, a );
    RETURN a;
  END Get;

PROCEDURE Set( From  : ExtMemPtr; a : WORD);
  BEGIN
    SETREG( DX, From.RealPtr.SEGMENT );
    SETREG( BX, From.RealPtr.OFFSET );
    SETREG( CX, a );
    CODE( 033h, 0c0h );                  (* xor ax, ax *)
    CODE( 08eh, 0c0h );                  (* mov es,ax *)
    CODE( 08bh, 0fah );                  (* mov di,dx *)
    CODE( 066h, 0c1h, 0e7h, 010h );      (* shl edi, 16 *)
    CODE( 08bh, 0fbh );                  (* mov di,bx *)
    CODE( 067h, 026h, 089h, 00fh );      (* mov es:[edi], cx *)
  END Set;


VAR
  xms : CARDINAL;
  b   : CARDINAL;
  bl  : ExtMemPtr;
  a   : WORD;
BEGIN
  b := AllocateExtMem( 256, xms );
  b := LockExtMemBlock( xms, bl );
  Set( bl, 1234H );
  a := Get( bl );
  b := UnlockExtMemBlock( xms );
  b := FreeExtMem( xms );
END XmsZas.
