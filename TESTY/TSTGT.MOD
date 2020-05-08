MODULE TstGT;

IMPORT
  DebugPMD, GPSRead;
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

CONST
  teoY = 400;
VAR
  pg : PolozenieGeo;
  wyn,gdop,nos,epe : CARDINAL;
  azymut: REAL;
  elewacja: REAL;
  cuuTStates:  TeoStates;
  okay: BOOLEAN;
  s: ARRAY[0..100] OF CHAR;
BEGIN
  LOOP
    wyn := CARDINAL( GPSRead.GPSReceive( pg, gdop, nos, epe ) );
    sprintf( s, "Szerokosc: %dø%d'%d                ", pg.Szerokosc );
    Wr2fStrXY( s, 0,0, WHITE, BLACK );
    sprintf( s, "Dlugosc: %dø%d'%d                  ", pg.Dlugosc );
    Wr2fStrXY( s, 0,50, WHITE, BLACK );
    sprintf( s, "GDOP=%d", gdop );
    Wr2fStrXY( s, 0,100, WHITE, BLACK );
    sprintf( s, "Liczba Satelitow = %d", nos );
    Wr2fStrXY( s, 0,150, WHITE, BLACK );
    sprintf( s, "EPE=%d", epe );
    Wr2fStrXY( s, 0,200, WHITE, BLACK );
    sprintf( s, "Stan = %0d  ", wyn );
    Wr2fStrXY( s, 0,250, WHITE, BLACK );
    cuuTStates := TheodolitReceive(azymut, elewacja);
    RealToString(azymut, 3, 10, s, okay);
    Wr2fStrXY( 'AZYMUT = ', 0, teoY, WHITE, BLACK );
    IF okay  THEN
      Wr2fStrXY( s, 200, teoY, WHITE, BLACK );
    ELSE
      Wr2fStrXY( '##########', 200, teoY, WHITE, BLACK );
    END;
    RealToString(elewacja, 3, 10, s, okay);
    Wr2fStrXY( 'ELEWACJA = ', 0, teoY+50, WHITE, BLACK );
    IF okay  THEN
      Wr2fStrXY( s, 200, teoY+50, WHITE, BLACK );
    ELSE
      Wr2fStrXY( '##########', 200, teoY+50, WHITE, BLACK );
    END;
    Wait( 200 );
  END;
END TstGT.
