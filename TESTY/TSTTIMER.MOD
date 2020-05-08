MODULE TimerTest;

FROM SYSTEM IMPORT
  INBYTE, OUTBYTE;
FROM Terminal IMPORT
  KeyPressed, Write, WriteString;
FROM Timer IMPORT
  Wait;
FROM WeekDays IMPORT 
  DayOfWeek;
FROM WeekSpell IMPORT 
  SpellWeek, SpellForm;
    
IMPORT
  RTSMain;  

VAR
  LicznikZdarzen, k,l : CARDINAL;

  PROCEDURE BCD2BIN(n : CARDINAL) : CARDINAL;
  BEGIN
    RETURN n MOD 16 + n DIV 16 * 10;
  END BCD2BIN;
  
PROCEDURE IleSekund() : CARDINAL;
VAR
  i, j : CARDINAL;
BEGIN
  OUTBYTE( 70H, 0 ); INBYTE( 71H, i ); (* sec *)
  i := BCD2BIN(i); 
  OUTBYTE( 70H, 2 ); INBYTE( 71H, j ); (* min *)
  INC( i, BCD2BIN(j)*60);
  OUTBYTE( 70H, 4 ); INBYTE( 71H, j ); (* h *)
  INC(i, BCD2BIN(j)*3600);
  RETURN i;
END IleSekund;

VAR y,mt,d,h,m,s,nr : CARDINAL;


PROCEDURE TimeDate(VAR y,mt,d,h,m,s,nr : CARDINAL);
VAR i : CARDINAL;
BEGIN
  OUTBYTE( 70H, 0 ); INBYTE( 71H, i ); (* sec *)
  s := BCD2BIN(i); 
  OUTBYTE( 70H, 2 ); INBYTE( 71H, i ); (* min *)
  m := BCD2BIN(i); 
  OUTBYTE( 70H, 4 ); INBYTE( 71H, i ); (* h *)
  h := BCD2BIN(i); 
  OUTBYTE( 70H, 6 ); INBYTE( 71H, i ); (* day of week *)
  nr:= BCD2BIN(i); 
  OUTBYTE( 70H, 7 ); INBYTE( 71H, i ); (* day *)
  d := BCD2BIN(i); 
  OUTBYTE( 70H, 8 ); INBYTE( 71H, i ); (* month *)
  mt:= BCD2BIN(i); 
  OUTBYTE( 70H, 9 ); INBYTE( 71H, i ); (* year *)
  y := BCD2BIN(i); 
END TimeDate;

PROCEDURE WriteTimeDate(y,mt,d,h,m,s,nr : CARDINAL);
VAR
    dn : ARRAY [0..20] OF CHAR;
BEGIN
  WrCard2(h);Write(':');WrCard2(m);Write(':');WrCard2(s);
  SpellWeek(VAL(DayOfWeek,nr),PolLong,dn);
  WriteString(dn); WriteString('    ');
  WrCard2(d);Write('/');WrCard2(mt);Write('/');WrCard2(y);
END WriteTimeDate;

PROCEDURE WrCard( l : CARDINAL);
BEGIN
  IF l>=1000 THEN
    Write("+");
    Write("+");
    Write("+");
  ELSE  
    Write(CHR(l DIV 100+30H));
    l := l MOD 100;
    Write(CHR(l DIV 10+30H));
    Write(CHR(l MOD 10+30H));
  END;  
END WrCard;      

PROCEDURE WrCard2( l : CARDINAL);
BEGIN
  IF l>=100 THEN
    Write("+");
    Write("+");
  ELSE  
    Write(CHR(l DIV 10+30H));
    Write(CHR(l MOD 10+30H));
  END;  
END WrCard2;      

   
BEGIN
  k := IleSekund();
  LOOP
    Wait(1);
    INC( LicznikZdarzen);
    l := IleSekund();
    IF l#k THEN
      WrCard(LicznikZdarzen);
      LicznikZdarzen := 0;
      WriteString(' przerwan na sekunde      '); 
      k := l; 
      TimeDate(y,mt,d,h,m,s,nr);
      WriteTimeDate(y,mt,d,h,m,s,nr);
      Write(15C );
      Write(12C);
    END;
    IF KeyPressed() THEN
      EXIT;
    END;
  END;
  RTSMain.Terminate( RTSMain.Stopped );
END TimerTest.
