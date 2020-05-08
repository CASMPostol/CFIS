IMPLEMENTATION MODULE GrafUtil;

FROM GrafTypes IMPORT
  WHITE, MAGENTA, RECT;
FROM Strings IMPORT
  Length;
FROM HiLevGraf IMPORT
  FillRect, WrStr;
FROM Graphics IMPORT
  MaxVer, MaxHor;
FROM Sounds IMPORT
  Sound, NoSound;
FROM Timer IMPORT
  Wait, TInOneSecond;
FROM MANAGER IMPORT
  STARTPROCESS;
FROM Strings IMPORT
  Assign;

VAR
  StatusR : RECT;


PROCEDURE Info( s : ARRAY OF CHAR );
VAR
  l : INTEGER;
BEGIN
  FillRect( StatusR, MAGENTA );
  l := Length( s ) DIV 2;
  WrStr( s,
  	   (StatusR.right-StatusR.left+1) DIV 2 - l*8,
  	   StatusR.top+1,
  	   WHITE,
  	   MAGENTA );
END Info;

VAR
  str : ARRAY[0..99] OF CHAR;
  WaitTime : CARDINAL;
  Tone     : CARDINAL;

PROCEDURE InfoBeep( s : ARRAY OF CHAR; WT : CARDINAL; T : CARDINAL );
BEGIN
  Assign( s, str );
  WaitTime := WT;
  Tone := T;
  STARTPROCESS( DoBeep, 800H, 0 );
END InfoBeep;

PROCEDURE DoBeep;
BEGIN
  Info( str );
  Sound( Tone );
  Wait( WaitTime * TInOneSecond() );
  NoSound;
  Info( "" );
END DoBeep;

BEGIN
  StatusR.left := 0;
  StatusR.top := MaxVer()-17;
  StatusR.right := 620;
  StatusR.bottom := MaxVer()-1;
END GrafUtil.
