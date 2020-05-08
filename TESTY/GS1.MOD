MODULE Gs1;

IMPORT
  FIO, Lib, Str;
FROM stdio IMPORT
  sprintf;
(*
   Dostawia numer wersji do plikow z analiza
*)


CONST
  TMP = '()()()()';

VAR
  str,
  tmp1,
  tmp2 : ARRAY [0..100] OF CHAR;
  i    : INTEGER;
  anal,
  dest : FIO.File;
  c    : CHAR;
  wrd  : CARDINAL;
  Uzup : BOOLEAN;
BEGIN
  Uzup := FALSE;
  str := 'analiza0.dat';
  anal := FIO.Open( str );
  IF anal = MAX( CARDINAL ) THEN
    Lib.FatalError('Nie ma takiego pliku!');
  END;
  dest := FIO.Create( TMP );
  IF dest = MAX( CARDINAL ) THEN
    Lib.FatalError('Nie mozna otworzyc pliku tymczasowego!');
  END;
  FIO.WrBin( dest, CARDINAL(140), 2 );
  FIO.Seek( anal, 2 );
  FOR i := 3 TO ORD(FIO.Size( anal )) DO
    FIO.WrChar( dest, FIO.RdChar( anal ));
  END;

  IF Uzup THEN
    FOR i := 610+1 TO 730 DO
      FIO.WrChar( dest, 0C );
    END;
  END;

  IF 730 # FIO.Size(dest) THEN
    Lib.FatalError('Cos sie zle zapisalo');
  END;
  FIO.Close(anal);
  FIO.Close( dest );

  Str.Copy( tmp1, str );
  i := Str.Length( tmp1 );
  WHILE tmp1[i] # '.' DO
    tmp1[i] := 0C;
    DEC(i);
  END;
  i := -1;
  REPEAT
    INC(i);
    sprintf( tmp2, "%s%03d", tmp1, i );
  UNTIL NOT FIO.Exists( tmp2 );
  FIO.Rename( str, tmp2 );
  FIO.Rename( TMP, str );
END Gs1.
