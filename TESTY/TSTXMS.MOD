MODULE TstXMS[7];

IMPORT
  XMSService, Timer;
FROM Strings IMPORT
  Length;
FROM BlockOps IMPORT
  BlockClear;
FROM SYSTEM IMPORT
  ADR, ADDRESS, SIZE;

CONST
  const = '1234567890qwertyuiopasdfghjklzxcvbnm.';
VAR
  a : ARRAY[0..100] OF CHAR;
  from, to : XMSService.ExtMemPtr;
  h : XMSService.XMS_Handle;
  i, s : CARDINAL;
BEGIN
  BlockClear( ADR( a ), SIZE( a ));
  a := const;
  h := XMSService.Allocate( VAL( LONGINT, SIZE(a)));
  from.RealPtr := ADR(a);
  to.ProtectedPtr := 0L;
  s := Length( a );
  XMSService.Copy( 0, from, h, to, s );
  FOR i := 1 TO s DO
    BlockClear( ADR( a ), SIZE( a ));
    from.ProtectedPtr := 0L;
    to.RealPtr := ADR(a);
    XMSService.Copy( h, from, 0, to, i );
  END;
  HALT;
END TstXMS.

