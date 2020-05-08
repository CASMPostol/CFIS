IMPLEMENTATION MODULE Komunikacja;

  (* przechowuje co najwyzej 17 bajtow w obszarze BIOSa dla BASICA *)

FROM SYSTEM IMPORT
  BYTE;


VAR
  BasicArea [40H:110H] : ARRAY [0..16] OF BYTE;
  KBDBuff [040H:1EH] : ARRAY[0..15] OF
                          RECORD
                            Char, Scan : CHAR
                          END;
  KBDHead[040H:1AH] : CARDINAL;
  KBDTail[040H:1CH] : CARDINAL;

PROCEDURE SetCode(     a : ARRAY OF BYTE );
VAR
  i, l : CARDINAL;
BEGIN
  l := HIGH( a );
  IF l > 17 THEN
    l := 17;
  END;
  FOR i := 0 TO l-1 DO
    BasicArea[i] := a[i];
  END;
END SetCode;

PROCEDURE GetCode( VAR a : ARRAY OF BYTE );
VAR
  i, l : CARDINAL;
BEGIN
  l := HIGH( a );
  IF l > 17 THEN
    l := 17;
  END;
  FOR i := 0 TO l-1 DO
    a[i] := BasicArea[i];
  END;
END GetCode;

PROCEDURE Insert( cmd : ARRAY OF CHAR ) : BOOLEAN;
VAR
  i : CARDINAL;
BEGIN
  i := 0;
  WHILE (i <= HIGH(cmd)) & ( cmd[i] # 0C ) DO
    WITH KBDBuff[ (KBDTail - 1EH) DIV 2 ] DO
      Char := cmd[i];
      Scan := cmd[i]; (* troche zle, ale moze nikt nie zauwazy *)
    END;
    INC(KBDTail, 2 );
    IF KBDTail > 3CH THEN
      KBDTail := 1EH;
    END;
    INC( i );
  END;
  RETURN TRUE;
END Insert;

PROCEDURE InsertInKBD( cmd : ARRAY OF CHAR ) : BOOLEAN;
BEGIN
  IF cmd[0] = 0C THEN
    RETURN TRUE;
  END;
  RETURN Insert( cmd ) & Insert ( 15C );
END InsertInKBD;

END Komunikacja.


