MODULE TstTTM;

IMPORT
  DebugPMD;
  FROM TheodolitRead  IMPORT TheodolitReceive, TeoStates;
  
FROM RealConversions IMPORT
  RealToString;
FROM Graphics IMPORT
  Wr2fStrXY;
FROM GrafTypes IMPORT
  WHITE, BLACK;
FROM Database IMPORT
  PolozenieGeo;
FROM StdIO IMPORT
  sprintf;
FROM Timer IMPORT
  Wait;  

VAR
  pg : PolozenieGeo;
  azymut: REAL;
  elewacja: REAL;
  cuuTStates:  TeoStates;
  okay: BOOLEAN;
  s: ARRAY[0..100] OF CHAR;
BEGIN
  LOOP
    cuuTStates := TheodolitReceive(azymut, elewacja);
    RealToString(azymut, 3, 10, s, okay);
    Wr2fStrXY( 'AZYMUT = ', 0,0, WHITE, BLACK );
    IF okay  THEN
      Wr2fStrXY( s, 200,0, WHITE, BLACK );
    ELSE
      Wr2fStrXY( '##########', 200,0, WHITE, BLACK );
    END;
    RealToString(elewacja, 3, 10, s, okay);
    Wr2fStrXY( 'ELEWACJA = ', 0, 50, WHITE, BLACK );
    IF okay  THEN
      Wr2fStrXY( s, 200, 50, WHITE, BLACK );
    ELSE
      Wr2fStrXY( '##########', 200, 50, WHITE, BLACK );
    END;
    Wait( 200 );
  END;
END TstTTM.
