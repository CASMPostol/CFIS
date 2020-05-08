(*.F- *)
(**********************************************************************
|  Title   : Obsluga ekranu - wspolne definicje 
|  Author  : M.Postol
|  System  : LOGITECH MODULA-2/86 
|  History :
|
|  Copyright (C), CAS LODZ POLAND.
|  TEL: 42' 862 547, 42' 87 80 44 FAX/TEL: 42' 84 48 40
|
**********************************************************************)
(*.F+ *)
IMPLEMENTATION MODULE ScreenCTypes;

  FROM GrafTypes IMPORT
     RECT, MoveRect, POINT;

  CONST
    Slupek1Left   = 14;
    SlupekXSize   = 60;
    SlupekXOffset = 70;
    DibVSize = 160;
    
PROCEDURE  Init;
BEGIN
  WITH slL_rec  DO
      left  := Slupek1Left;
      right := left + SlupekXSize;
      top := 35 + 600 - DibVSize;
      bottom := top + 60;
  END;
  slL_pnt.x := slL_rec.left;
  slL_pnt.y := slL_rec.top;
  slLReg_rec:= slL_rec;
  slLReg_rec.bottom := 600-16-3;
  slLDib_rec :=   slL_rec;
  MoveRect(slLDib_rec, 0, -(600-DibVSize));
  
  slS_rec := slL_rec;
  MoveRect(slS_rec, SlupekXOffset, 0);
  slS_pnt.x := slS_rec.left;
  slS_pnt.y := slS_rec.top;
  slSReg_rec := slLReg_rec;
  MoveRect(slSReg_rec, SlupekXOffset, 0);
  slSDib_rec := slLDib_rec;
  MoveRect(slSDib_rec, SlupekXOffset, 0);
  
  slP_rec := slS_rec;
  MoveRect(slP_rec, SlupekXOffset, 0);
  slP_pnt.x := slP_rec.left;
  slP_pnt.y := slP_rec.top;
  slPReg_rec := slSReg_rec;
  MoveRect(slPReg_rec, SlupekXOffset, 0);
  slPDib_rec  := slSDib_rec;
  MoveRect(slPDib_rec, SlupekXOffset, 0);
  
END Init;


BEGIN
  Init;
END ScreenCTypes.

