MODULE TstGPSS;

IMPORT
  DebugPMD, GPSRead;

  FROM MANAGER IMPORT
    STARTPROCESS, InitS, InitC, SIGNAL, SEND, WAITS, WAITC, Assert, Condition;

  FROM NumberConversion IMPORT
    StringToCard, StringToInt;

(* FROM Graphics IMPORT
  Wr2fStrXY; *)
(* FROM GrafTypes IMPORT
  WHITE, BLACK; *)
FROM CommonTypes IMPORT
  PolozenieGeo;
FROM StdIO IMPORT
  sprintf;
FROM Timer IMPORT
  Wait;  

  PROCEDURE Trimble2(  );
  TYPE
    str63 = ARRAY[0..63] OF CHAR;
  VAR
    bufor : str63;
    t : CARDINAL;
    ok : BOOLEAN;
    c  : CHAR;

  PROCEDURE GetStrFromGps( VAR s : str63; VAR C: CHAR ) : BOOLEAN;
  BEGIN
    REPEAT
      Wait(MAX(CARDINAL) DIV 5);
    UNTIL FALSE;
    RETURN TRUE;
  END GetStrFromGps;

  BEGIN
    LOOP
      IF GetStrFromGps( bufor, c ) THEN
      ELSE
      END;
    END;
  END Trimble2;

VAR
   sig: SIGNAL;
  pg : PolozenieGeo;
  wyn,gdop,nos,epe : CARDINAL;
  s  : ARRAY[0..100] OF CHAR;
BEGIN
  InitS(sig);
  STARTPROCESS( Trimble2, 0C00H, 0 );
  Wait( MAX(CARDINAL) );
  LOOP
    (*
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
    *)
    Wait( 200 );
  END;
END TstGPSS.