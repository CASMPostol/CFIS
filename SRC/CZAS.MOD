(*.F- *)
(**********************************************************************
|  Title   : Czyta date i czas sprzetowo i wypisuje na ekranie 
|  Author  : M.Morawsk
|  System  : LOGITECH MODULA-2/86 
|  History :
|    Rel.3.0.: Mpostol
|      Po wymianie komputera wystapily bledy przy odczycie czasu i daty
|      wprowadzilem kontrole.
|
|  Copyright (C), CAS LODZ POLAND.
|  TEL: 42' 686 25 47
|  mailto: techsupp@cas.com.pl
|  http: www.cas.com.pl
|
**********************************************************************)
(*.F+ *)
IMPLEMENTATION MODULE Czas;

IMPORT
  Graphics, StdIO;
FROM Graphics IMPORT
  MaxHor;
FROM Timer IMPORT
  Wait, TInOneSecond;
FROM GrafTypes IMPORT
  BLACK, LT_GREEN, RECT;
FROM MANAGER IMPORT
  STARTPROCESS, Assert;
FROM StdIO IMPORT
  sprintf;
FROM MMMouse IMPORT
  HideConditionally, ShowCursor;
FROM RTSMain IMPORT
  InstallTermProc;
IMPORT
  SYSTEM, CommonTypes;
FROM HRD_Clock IMPORT 
  Godzina, Data;
FROM SYSTEM IMPORT
  SETREG, GETREG, AX, CX, DX, SWI, ADR, ADDRESS;
  
MODULE BezPrzerwan[0];

IMPORT
  Graphics, LT_GREEN, HideConditionally, ShowCursor, RECT, BLACK, 
  TimeAndDate;

FROM Graphics IMPORT
  GetBank, SetBank, _WrStrXY, MaxHor;

EXPORT
  Write, StringRect, SetTimeAndDate, GetTimeAndDate;


  VAR
    StringRect : RECT;
    SystemTime : TimeAndDate;
  
  PROCEDURE Write( VAR s : ARRAY OF CHAR );
  VAR
    p : CARDINAL;
    h : BOOLEAN;
  BEGIN
    h := HideConditionally( StringRect );
    p := GetBank();
    _WrStrXY( s, StringRect.left, StringRect.top, LT_GREEN, 0 );
    SetBank(p);
    IF h THEN
      ShowCursor;
    END;
  END Write;

  PROCEDURE GetTimeAndDate( VAR Tm : TimeAndDate );
  
  BEGIN
    Tm := SystemTime;
  END GetTimeAndDate;


  PROCEDURE SetTimeAndDate( Tm : TimeAndDate );

  BEGIN
    SystemTime := Tm;
  END SetTimeAndDate;

END BezPrzerwan;

  PROCEDURE WriteTime;
  VAR  
    s   : ARRAY[0..12] OF CHAR;
    tad : TimeAndDate;
  

BEGIN
  StringRect.left := MaxHor()-64;
  StringRect.right := MaxHor();
  StringRect.top := 0;
  StringRect.bottom := 16;
  LOOP
    WITH tad DO
      Data( d.y, d.m, d.d, t.h, t.m, t.s );
    END;
    SetTimeAndDate(tad);
    sprintf( s, "%2d:%02d:%02d", tad.t );
    Write( s );
    Wait( TInOneSecond() );
  END;
END WriteTime;

  PROCEDURE SetTime( h,m,s : CARDINAL );
  BEGIN
    SETREG( DX, s*100H );
    SETREG( CX, h*100H+m);
    SETREG( AX, 2d00h );
    SWI( 21h );
  END SetTime;

  PROCEDURE SetDate( Y,M,D : CARDINAL );
  BEGIN
    SETREG( DX, M*100H+D );
    SETREG( CX, Y );
    SETREG( AX, 02b00h );
    SWI( 21h );
  END SetDate;

  PROCEDURE ConvertToStr
            (     tad : TimeAndDate;
                  sec : BOOLEAN;
              VAR str : ARRAY OF CHAR );
    (* procedura konwersji TimeAndDate na ciag znakow o formacie
        *)
    
  BEGIN
    IF sec THEN
      StdIO.sprintf(str, "%d.%02d.%d %d:%02d:%02d", tad)
    ELSE
      StdIO.sprintf(str, "%d.%02d.%d %d:%02d", tad);
    END;
  END ConvertToStr;
  
  PROCEDURE Terminator; (* bo czas systemowy jest tymczasem nieaktualizowany *)
  VAR
    tad : TimeAndDate;

  BEGIN
    GetTimeAndDate(tad);
    WITH tad DO
      WITH t  DO
        SetTime( h, m, s);
      END;
      WITH d DO
        SetDate( y, m, d);
      END;
    END;
  END Terminator;

BEGIN
  InstallTermProc( Terminator );
  STARTPROCESS( WriteTime, 700H, 0 );
END Czas.
