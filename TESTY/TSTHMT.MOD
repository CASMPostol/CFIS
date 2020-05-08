MODULE HMT;
(* himem test,  for XMS assembler module *)
FROM XMS IMPORT
 ExtMemPtr, ExtMemMoveStruct,
 XmsInstalled, QueryFreeExtMem, AllocateExtMem, FreeExtMem, MoveExtMemBlock,
 ResizeExtMemBlock ;
FROM Terminal IMPORT WriteLn, WriteString, Read;

CONST
     BaseMem = 0;
VAR
  ch : CHAR;
  TotalFree, LargestBlock,res,hand : CARDINAL;
  MoveCTRL : ExtMemMoveStruct;
 
BEGIN
  WriteLn;  
  IF XmsInstalled() THEN
    WriteString(" jest pamiec XMS");
  ELSE  
    WriteString(" nie ma pamieci XMS");
  END;
  res := 90;
  res := QueryFreeExtMem(TotalFree, LargestBlock );
  res := AllocateExtMem(6, hand );
  res := QueryFreeExtMem(TotalFree, LargestBlock );
  MoveCTRL.Len := VAL(LONGINT,80*25*2);
  MoveCTRL.SrcHand := BaseMem;
  MoveCTRL.SrcOffs.RealPtr       := 0B800H:0;
  MoveCTRL.DestHand := hand;
  MoveCTRL.DestOffs.ProtectedPtr := VAL(LONGINT,0);
  res := MoveExtMemBlock(MoveCTRL);
  Read(ch);
  MoveCTRL.Len := VAL(LONGINT,80*25*2);
  MoveCTRL.SrcHand := hand;
  MoveCTRL.SrcOffs.ProtectedPtr := VAL(LONGINT,0);
  MoveCTRL.DestHand := BaseMem;
  MoveCTRL.DestOffs.RealPtr       := 0B800H:10H;
  res := MoveExtMemBlock(MoveCTRL);
  Read(ch);
  res := ResizeExtMemBlock(hand,40);
  res := QueryFreeExtMem(TotalFree, LargestBlock );
  res := FreeExtMem(hand );
  res := QueryFreeExtMem(TotalFree, LargestBlock );
  
  WriteLn;  
END HMT.
