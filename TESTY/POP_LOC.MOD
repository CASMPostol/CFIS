MODULE Pop_Loc;

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
BEGIN
  IF Lib.ParamCount() # 0 THEN
    Lib.FatalError( 'Paramaterem jest plik: analiza0.dat');
  END;
  str := 'analiza0.dat';
  anal := FIO.Open( str );
  IF anal = MAX( CARDINAL ) THEN
    Lib.FatalError('Nie ma takiego pliku!');
  END;
  dest := FIO.Create( TMP );
  IF dest = MAX( CARDINAL ) THEN
    Lib.FatalError('Nie mozna otworzyc pliku tymczasowego!');
  END;
  FIO.WrBin( dest, CARDINAL(110), 2 );
  FIO.WrBin( dest, CARDINAL(5555), 2 );
  FOR i := 1 TO ORD(FIO.Size( anal )) DO
    FIO.WrChar( dest, FIO.RdChar( anal ));
  END;
  FIO.Seek( anal, 12FH-0D8H-4 );
  c := FIO.RdChar( anal );
  IF c > 2C THEN
    FIO.Seek(dest, 12FH-0D8H );
    FIO.WrChar( dest, 0C );
  END;
  IF FIO.Size(anal)+4 # FIO.Size(dest) THEN
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
END Pop_Loc.