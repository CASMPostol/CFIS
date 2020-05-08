MODULE TstGPS;

IMPORT
  DebugPMD, GPSRead;

  FROM MANAGER IMPORT
    STARTPROCESS, InitS, InitC, SIGNAL, SEND, WAITS, WAITC, Assert, Condition;

  FROM NumberConversion IMPORT
    StringToCard, StringToInt;

 FROM Graphics IMPORT
  Wr2fStrXY;
 FROM GrafTypes IMPORT
  WHITE, BLACK;
FROM CommonTypes IMPORT
  PolozenieGeo;
FROM StdIO IMPORT
  sprintf;
FROM Timer IMPORT
  Wait;  

VAR
  pg : PolozenieGeo;
  wyn,gdop,nos,epe : CARDINAL;
  s  : ARRAY[0..100] OF CHAR;
BEGIN
  LOOP
    (*wyn := CARDINAL( GPSRead.GPSReceive( pg, gdop, nos, epe ) );*)
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
    Wait( 200 );
  END;
END TstGPS.