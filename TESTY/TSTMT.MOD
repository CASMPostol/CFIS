MODULE MT;
  IMPORT
    Graphics, Terminal, MMMouse, RTSMain, HiLevGraf, Sounds, SYSTEM,
    GrafTypes;
  IMPORT
    DebugPMD;
VAR
  g : BOOLEAN;
  
  
   PROCEDURE Handler1( e : MMMouse.EventSet;
   		       b : MMMouse.ButtonSet;
   		       x, y : INTEGER );
   BEGIN
     IF MMMouse.RightDown IN e THEN
       RTSMain.Terminate(RTSMain.Stopped);
     END;
     IF MMMouse.LeftDown IN e THEN
       IF g THEN
         Sounds.NoSound;
       ELSE
         Sounds.Sound(1000);
       END;
       g := NOT g;
     END;
   END Handler1;
  
   PROCEDURE Handler2( e : MMMouse.EventSet;
   		       b : MMMouse.ButtonSet;
   		       x, y : INTEGER );
   BEGIN
     IF MMMouse.RegionIn IN e THEN
       Sounds.Sound(1000);
       g := TRUE;
     ELSIF MMMouse.RegionOut IN e THEN
       Sounds.NoSound();
       g := FALSE;
     END;
   END Handler2;
  
VAR
  ch : CHAR;
  r  : GrafTypes.RECT;
  reg1, reg2 : MMMouse.Region;
  cur : MMMouse.GraphicCursor;
BEGIN
  WITH cur DO
    screenMask[ 0] := {4..10};
    screenMask[ 1] := {2..12};
    screenMask[ 2] := {1..3,6..8,11..13};
    screenMask[ 3] := {1..3,6..8,12..14};
    screenMask[ 4] := {0..2,6..8,13..15};
    screenMask[ 5] := {0..2,6..8,13..15};
    screenMask[ 6] := {0..1,6..8,14..15};
    screenMask[ 7] := {0..15};
    screenMask[ 8] := {0..15};
    screenMask[ 9] := {0..15};
    screenMask[10] := {0..1,6..8,14..15};
    screenMask[11] := {0..2,6..8,13..15};
    screenMask[12] := {1..3,6..8,13..15};
    screenMask[13] := {1..3,6..8,11..14};
    screenMask[14] := {2..12};
    screenMask[15] := {4..10};
    cursorMask[ 0] := {5..9};
    cursorMask[ 1] := {3,4,7,10,11};
    cursorMask[ 2] := {2,7,12};
    cursorMask[ 3] := {2,7,13};
    cursorMask[ 4] := {2,7,14};
    cursorMask[ 5] := {2,7,14};
    cursorMask[ 6] := {0,7,15};
    cursorMask[ 7] := {0,7,15};
    cursorMask[ 8] := {0..15};
    cursorMask[ 9] := {0,7,15};
    cursorMask[10] := {0,7,15};
    cursorMask[11] := {1,7,14};
    cursorMask[12] := {2,7,14};
    cursorMask[13] := {2,7,12,13};
    cursorMask[14] := {3,4,7,10,11};
    cursorMask[15] := {5..9};
    hotX           := 7;
    hotY           := 7;
  END;
  g := FALSE;
  MMMouse.HideCursor;
  Graphics.FillRect( 100, 100, 700, 500, GrafTypes.RED );
  r.left := 200;
  r.top := 200;
  r.right := 300;
  r.bottom := 300;
  Graphics.FillRect( r.left, r.top, r.right, r.bottom, GrafTypes.GREEN );
  reg1 := MMMouse.RegisterRegion(
  			MMMouse.EventSet{MMMouse.LeftDown,MMMouse.RightDown},
  			r,
  			Handler1,
  			NIL );
  r.left := 500;
  r.top := 200;
  r.right := 600;
  r.bottom := 300;
  Graphics.FillRect( r.left, r.top, r.right, r.bottom, GrafTypes.BLUE );
  reg2 := MMMouse.RegisterRegion(
  			MMMouse.EventSet{MMMouse.RegionIn,MMMouse.RegionOut},
  			r,
  			Handler2,
  			SYSTEM.ADR(cur) );
  MMMouse.ShowCursor;
  Terminal.Read( ch );
  RTSMain.Terminate( RTSMain.Stopped );
END MT.
