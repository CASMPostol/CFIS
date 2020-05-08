IMPLEMENTATION MODULE DMEWrite;

FROM SYSTEM IMPORT
  Out;


CONST
  PortA    = 230H;
  PortB    = PortA+1;
  PortC    = PortA+2;
  PortCont = PortA+3;
  Mode     = 80H; (*  9BH *)
(*  Mode     = 200B;(*  233C; *)*)
  WDLimit  = 100H;


  DmeMem = TRUE;
  DmeSearch = TRUE;

PROCEDURE Do100( r : LONGREAL ) : SHORTCARD;
VAR
  c : SHORTCARD;
  l : LONGCARD;
BEGIN
  l := LONGCARD( r );
  RETURN VAL( SHORTCARD, l MOD 100 );
END Do100;

PROCEDURE BCD( s : SHORTCARD ) : SHORTCARD;
BEGIN
  RETURN s MOD 10 + 16 * ( s DIV 10 );
END BCD;

PROCEDURE Write( Odl : LONGREAL );
VAR
  wp : SHORTCARD;
BEGIN
  IF Odl < 0.0 THEN
    Odl := 0.0;
  END;
  wp := Do100( Odl / 100.0 ) + ORD(DmeMem) << 2 + ORD(DmeSearch)<<3;
  Out( PortC, wp );                          (* PC5 = 0 => wpisywanie *)
  Out( PortA, BCD( Do100( Odl * 100.0 )));
  Out( PortB, BCD( Do100( Odl )));
  Out( PortC, wp + 1 << 5 );                      (* ustawiony bit konca zapisu *)
END Write;

BEGIN
  Out( PortCont, Mode );
END DMEWrite.
