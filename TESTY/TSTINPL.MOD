MODULE TstInpL;

IMPORT
  DebugPMD, MANAGER;
FROM GrafTypes IMPORT
  WHITE, BLUE, GREEN;
FROM InpLine IMPORT
  CreateInpLine, HLINE, SetText, DoNothing;

VAR
  l1, l2 : HLINE;

BEGIN
  l1 := CreateInpLine( 100, 100, 15, DoNothing, WHITE, BLUE );
  l2 := CreateInpLine( 100, 200, 15, DoNothing, WHITE, GREEN );
  SetText( l1, "1234" );
  SetText( l2, "ancd" );
END TstInpL.
