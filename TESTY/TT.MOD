MODULE TT;
FROM Timer IMPORT Wait, TInOneSecond;
FROM Czas IMPORT Godzina;
FROM Terminal IMPORT WriteString, Write;
FROM StdIO IMPORT sprintf;
FROM SYSTEM IMPORT SETREG,GETREG,AX,BX,CX,DX,SWI;

VAR
    ls : CARDINAL;
    f : RECORD
          h,m,s,dh,dm,ds,ticks,tis : CARDINAL;
        END;
    str : ARRAY [0..79] OF CHAR;
    
    PROCEDURE DosTime(VAR h, m, s : CARDINAL);
    VAR cx,dx : CARDINAL;
    BEGIN
      SETREG(AX,2C00H);
      SWI(21H);
      GETREG(CX,cx);
      GETREG(DX,dx);
      h := cx DIV 100H;
      m := cx MOD 100H;
      s := dx DIV 100H;
    END DosTime;
    
BEGIN
  WITH f DO
  ticks :=0;
  tis := TInOneSecond();
  LOOP 
    Godzina (h,m,s);
    IF ls#s THEN
      DosTime(dh,dm,ds);
      sprintf( str, 
"RTC = %2d:%02d:%02d   DOS = %2d:%02d:%02d    Ticks = %d of %d",f );
      WriteString( str );
      Write(15C);
      Write(12C);
      ls:=s;
      ticks :=0;
    ELSE
      INC(ticks);
    END;  
    Wait(1);
  END;
  END;
END TT.
