MODULE WKolko;

FROM rs IMPORT
  Init, Send, Install, Even, TxCount;
FROM FIO IMPORT
  File, RdBin, Size, Open;
IMPORT
  IO;

VAR
  s : CARDINAL;
  F : File;
  Buff : ARRAY[0..20000] OF CHAR;
BEGIN
  Install( 2);
  Init( 1200, 7, Even, FALSE, FALSE );
  F := Open( '\tttt.log' );
  s := ORD(Size( F ));
  IF RdBin( F, Buff, s ) = s THEN
  END;
  LOOP
    Send( Buff, s );
    IO.WrChar('*');
    REPEAT
      IF IO.KeyPressed() THEN
        EXIT;
      END;
    UNTIL TxCount() = 0;
  END;
END WKolko.