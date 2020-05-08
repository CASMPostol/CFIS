
MODULE THG;

IMPORT
  DebugPMD, DOSEntry, MANAGER;
FROM Timer  IMPORT
  Wait, TInOneSecond;
FROM HiLevGraf IMPORT
  LoadDIB, CloseDIB, ShowDIB, DIBWidth, DIBHeight, HDIB, Point,
  Line, FillRect;
FROM Graphics IMPORT
  Tryb,DP;
FROM RTSMain IMPORT
  Terminate, Status;
FROM Terminal IMPORT
  Read, KeyPressed, WriteString;
FROM GrafTypes IMPORT
  RECT, POINT;

VAR
  d : HDIB;
  r : RECT;
  p : POINT;
  c : CHAR;
  x, z : INTEGER;
BEGIN
  d := LoadDIB( 'insp_l.dib' );
  WriteString('po LoadDIB');
  Wait(2*TInOneSecond());
(*  Tryb(103H);*)
  r.left := 0;
  r.top := 0;
  r.right := DIBWidth( d );
  r.bottom := DIBHeight( d );
  x := 0;
  REPEAT
    p.x := x;
    p.y := x;
    FillRect( r, 0 );
    ShowDIB( d, r, p );
    INC( x, 11 );
    IF x > 450  THEN
      x:= 0;
    END;
    (*
    FOR z := 0 TO 599 DO
      Point( z, z, CHR(z MOD 256) );
    END;
    FOR z := 0 TO 599 DO
      DP(z, 599-z, CHR(z MOD 256) );
    END;
    *)
    (* Read( c ); *)
    Wait(TInOneSecond() DIV 2);
  UNTIL KeyPressed();
  (*
  FOR z := 0 TO 599 BY 2 DO
    Line( 0, 0, DIBWidth(d), z, CHR(z DIV 2 MOD 256) );
  END;
  *)
  CloseDIB(d);
  Terminate( Stopped );
END THG.
