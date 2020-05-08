MODULE Pop_Gs;

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
  IF Lib.ParamCount() = 1 THEN
    Lib.ParamStr( str, 1 );
    IF Str.Compare( str, 'u' ) = 0 THEN
      Uzup := TRUE;
    ELSE
      Lib.FatalError( "Parametrem moze byc  << u >>" );
    END;
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
  FOR i := 1 TO ORD(FIO.Size( anal )) DO
    FIO.WrChar( dest, FIO.RdChar( anal ));
  END;

  IF Uzup THEN
    FOR i := 610+1 TO 730 DO
      FIO.WrChar( dest, 0C );
    END;
  END;

  FIO.Seek( anal, 09EH-04CH-2 );
  IF FIO.RdBin( anal, wrd, 2 ) # 2 THEN
    Lib.FatalError( 'Do bani....' );
  END;
  IF wrd = 8000H THEN
    wrd := 100H; (* 1 stopien *)
    FIO.Seek( dest, 09EH-04CH );
    FIO.WrBin( dest, wrd, 2 );
  END;

  FIO.Seek( anal, 0A1H-04CH-2 );
  FIO.Seek( dest, 12FH-0D8H );
  FOR i := 0 TO 2 DO
    c := FIO.RdChar( anal );
    IF c > 2C THEN
      c := 0C;
    END;
    FIO.WrChar( dest, c );
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
END Pop_Gs.
