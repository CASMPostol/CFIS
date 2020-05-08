IMPLEMENTATION MODULE GrafTypes;

PROCEDURE IsIntersect( VAR a,b : RECT ) : BOOLEAN;
BEGIN
  IF (a.left > b.right) OR ( a.right < b.left ) THEN
    RETURN FALSE;
  END;
  IF (a.top > b.bottom) OR ( a.bottom < b.top ) THEN
    RETURN FALSE;
  END;
  RETURN TRUE;
END IsIntersect;

PROCEDURE Intersection( VAR Dest : RECT; a,b : RECT ) : BOOLEAN;
BEGIN
  Dest := a;
  IF Dest.left < b.left THEN
    Dest.left := b.left;
  END;
  IF Dest.top < b.top THEN
    Dest.top := b.top;
  END;
  IF Dest.right > b.right THEN
    Dest.right := b.right;
  END;
  IF Dest.bottom > b.bottom THEN
    Dest.bottom := b.bottom;
  END;
  RETURN (Dest.left <= Dest.right) & (Dest.top <= Dest.bottom);
END Intersection;

PROCEDURE MoveRect( VAR r : RECT; offsetX : INTEGER; offsetY : INTEGER );
BEGIN
  INC( r.left, offsetX );
  INC( r.right, offsetX );
  INC( r.top, offsetY );
  INC( r.bottom, offsetY );
END MoveRect;

PROCEDURE IsEqual( VAR r1, r2 : RECT ) : BOOLEAN;
BEGIN
  RETURN ( r1.left  = r2.left )		&
         ( r1.top   = r2.top  )		&
         ( r1.right = r2.right)		&
         ( r1.bottom= r2.bottom );
END IsEqual;

PROCEDURE AssignRect( VAR R : RECT; left, top, right, bottom : INTEGER );
BEGIN
  R.left := left;
  R.top := top;
  R.right := right;
  R.bottom := bottom;
END AssignRect;

PROCEDURE AssignPoint( VAR p : POINT; x, y : INTEGER );
BEGIN
  p.x := x;
  p.y := y;
END AssignPoint;

END GrafTypes.
