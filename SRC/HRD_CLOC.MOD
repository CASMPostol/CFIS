(*.F- *)
(**********************************************************************
|  Title   : Obsluga zegara sprzetowego 
|  Author  : M.Postol	
|  System  : LOGITECH MODULA-2/86 
|  History :
|    Rel3.0. Utworzony - bo w starej wersji wystapil problem z 
|    czytaniem
|
|  Copyright (C), CAS LODZ POLAND.
|  TEL: 42' 686 25 47
|  mailto: techsupp@cas.com.pl
|  http: www.cas.com.pl
|
**********************************************************************)
(*.F+ *)

IMPLEMENTATION MODULE HRD_Clock;

FROM SYSTEM IMPORT
  OUTBYTE, INBYTE, SETREG, GETREG, DISABLE, ENABLE;

  FROM MANAGER IMPORT
  Assert;
  FROM Timer  IMPORT Wait;
  
 
  PROCEDURE BCD( VAR a : CARDINAL );
  BEGIN
    a := a MOD 16 + (a DIV 16)*10;
  END BCD;

  PROCEDURE CheckUpdateCycle;
    (* Jesli bit 7 w slowie A (adres 10) jest rowny 0, to przez conajmnie 
       244uS zawartosc zegara nie zostanie zmieniona, 
       jesli jest 1 to nastepuje albo zaraz ( w ciagu 244uS ) nastapi 
       uaktualnienie rejestrow wewnetrznych i nie wolno 
       czytac. Bit ten moze byc w stanie 1 przez 1848uS !!
    *)
  VAR
    RegA : CARDINAL;
  BEGIN
    LOOP
      DISABLE;
      OUTBYTE( 70h, 10 );
      INBYTE( 71h, RegA );
      IF RegA >= 128 THEN
        ENABLE;
        Wait(1);
      ELSE
        EXIT
      END;
    END
  END CheckUpdateCycle;

  PROCEDURE GetGodzina( VAR h, m, s : CARDINAL );
  BEGIN
    OUTBYTE( 70h, 0 );
    INBYTE( 71h, s );
    OUTBYTE( 70h, 2 );
    INBYTE( 71h, m );
    OUTBYTE( 70h, 4 );
    INBYTE( 71h, h );
  END GetGodzina;
  
  PROCEDURE Godzina( VAR h, m, s : CARDINAL );
  BEGIN
    CheckUpdateCycle; 
    GetGodzina( h, m, s);
    ENABLE;
    BCD( h );
    Assert(h <= 23 );
    BCD( m );
    Assert(m <= 59 );
    BCD( s );
    Assert(s <= 59 );
  END Godzina;

PROCEDURE Data( VAR Y, M, D : CARDINAL;
                VAR h, m, s : CARDINAL );
  BEGIN
    CheckUpdateCycle;
    GetGodzina( h, m, s);
    
    OUTBYTE( 70h, 7 );
    INBYTE( 71h, D );
    OUTBYTE( 70h, 8 );
    INBYTE( 71h, M );
    OUTBYTE( 70h, 9 );
    INBYTE( 71h, Y );
    
    ENABLE;
    
    BCD( h );
    Assert(h <= 23 );
    BCD( m );
    Assert(m <= 59 );
    BCD( s );
    Assert(s <= 59 );
    BCD( Y );
    Assert(Y <=99 );
    BCD( M );
    Assert(M <= 12 );
    BCD( D );
    Assert(D <= 31 );
    IF Y < 95 THEN
      INC( Y, 2000 );
    ELSE
      INC( Y, 1900 );
    END;
  END Data;
END HRD_Clock.
