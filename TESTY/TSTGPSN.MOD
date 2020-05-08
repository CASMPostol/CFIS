MODULE TstGPSn;


IMPORT
  DebugPMD ,GPSRead;

FROM MANAGER IMPORT
    STARTPROCESS, InitS, InitC, SIGNAL, SEND, WAITS, WAITC, Assert, Condition;

  FROM NumberConversion IMPORT
    StringToCard, StringToInt; 

FROM Terminal IMPORT
  Read, ReadString, Write, WriteLn, KeyPressed;

  FROM DigiRS IMPORT
    WriteString, SetBaudRate;



FROM Graphics IMPORT
  _Wr2fStrXY;
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
  wyn,gdop,nos,epe, data : CARDINAL;
  diffmode :BOOLEAN;
  s : ARRAY[0..100] OF CHAR;
BEGIN

    
  
   REPEAT
    wyn := CARDINAL( GPSRead.GPSReceive( pg, gdop, nos, epe, diffmode, data ) );
    sprintf( s, "Szerokosc: %dø%d'%d                ", pg.Szerokosc );
    _Wr2fStrXY( s, 0,0, WHITE, BLACK );
    sprintf( s, "Dlugosc: %dø%d'%d                  ", pg.Dlugosc );
    _Wr2fStrXY( s, 0,50, WHITE, BLACK );
    gdop:= gdop DIV 500;
    sprintf( s, "GDOP=%d", gdop );
    _Wr2fStrXY( s, 0,100, WHITE, BLACK );
    sprintf( s, "Liczba Satelitow = %d", nos );
    _Wr2fStrXY( s, 0,150, WHITE, BLACK );
    sprintf( s, "EPE=%d", epe );
    _Wr2fStrXY( s, 0,200, WHITE, BLACK );
    IF NOT diffmode THEN
    _Wr2fStrXY( "diffmode = zwykly", 0,300, WHITE, BLACK );
    ELSE
    _Wr2fStrXY( "diffmode = roznic", 0,300, WHITE, BLACK );
    END;
    
    sprintf( s, "Stan = %0d  ", wyn );
    _Wr2fStrXY( s, 0,250, WHITE, BLACK );
    Wait( 200 );
   UNTIL KeyPressed();  
  
END TstGPSn.
