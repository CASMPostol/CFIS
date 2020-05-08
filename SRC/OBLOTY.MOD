(*
 *  09-10-97 05:02pm : MM
 *      Zmienilem definicje SkasujOblot
 *)

IMPLEMENTATION MODULE Obloty;



FROM Strings IMPORT
  Length, Insert, Assign, CompareStr;
FROM Ini IMPORT
  WritePrivateProfileString, GetPrivateProfileString, DeleteSection;
FROM NumberConversion IMPORT
  StringToCard;
FROM StdIO IMPORT
  sprintf;
FROM FIO IMPORT
  Delete, CD, GetDir, RmDir, DirQuery, Attr, Attributes;
FROM GrafUtil IMPORT
  InfoBeep;
FROM RTSMain IMPORT
  Terminate, Status;


CONST
  WlkNazwy = 65;
  Header   = "Lista oblotow";

(* musi byc wywolane jako pierwsze *)

PROCEDURE Ile( ) : INTEGER;
VAR
  s : ARRAY[0..WlkNazwy-1] OF CHAR;
  i : CARDINAL;
  ok : BOOLEAN;
BEGIN
  GetPrivateProfileString( Header,
                           "Ilosc",
                           "0",
                           s,
                           NazwaPlikuIni );
  StringToCard( s, i, ok );
  IF NOT ok THEN
    i := 0;
  END;
  RETURN i;
END Ile;

PROCEDURE WymienWszystkie( Callback : Oblot );
VAR
  i,
  j : INTEGER;
  s : ARRAY[0..WlkNazwy-1] OF CHAR;
BEGIN
  j := Ile();
  FOR i := 0 TO j-1 DO
    sprintf( s, "Oblot%d", i );
    GetPrivateProfileString( Header,
                             s,
                             "",
                             s,
                             NazwaPlikuIni );
    SzczegolowyPlikOpisu( s, NazwaPlikuZOpisem, TRUE );
    Callback( s );
  END;
END WymienWszystkie;

VAR
  NazwaUrzadzenia : ARRAY[0..WlkNazwy-1] OF CHAR;
  CallBack        : Oblot;

PROCEDURE WymienWszystkiePasujace( NU      : ARRAY OF CHAR;
                                   Callback: Oblot );
BEGIN
  IF NU[0] = '*'  THEN
    WymienWszystkie( Callback );
  ELSE
    CallBack := Callback;
    Assign( NU, NazwaUrzadzenia );
    WymienWszystkie( Dopasuj );
  END;
END WymienWszystkiePasujace;

PROCEDURE SzczegolowyPlikOpisu( VAR NazwaOblotu,
                                    Kartoteka    : ARRAY OF CHAR;
                                    Dopisac      : BOOLEAN );
BEGIN
  GetPrivateProfileString( NazwaOblotu,
                           "Kartoteka",
                           "",
                           Kartoteka,
                           NazwaPlikuIni );
  IF Dopisac THEN
    IF (Length( Kartoteka ) = 1) OR
       (Kartoteka[ Length(Kartoteka) -1] # '\') THEN
      Insert( '\', Kartoteka, 0FFFH );
    END;
    Insert( NazwaPlikuIni,Kartoteka, 0FFFH );
  ELSE
    IF Kartoteka[ Length( Kartoteka ) -1] = '\' THEN
      Kartoteka[ Length( Kartoteka ) -1] := 0C;
    END;
  END;
END SzczegolowyPlikOpisu;

PROCEDURE Dopasuj( VAR NazwaOblotu : ARRAY OF CHAR );
VAR
  Nazwa : ARRAY [0..WlkNazwy-1] OF CHAR;
BEGIN
  GetPrivateProfileString( NazwaOblotu,
                           "Nazwa",
                           "",
                           Nazwa,
                           NazwaPlikuZOpisem );
  IF CompareStr( Nazwa, NazwaUrzadzenia ) = 0 THEN
    CallBack( NazwaOblotu );
  END;
END Dopasuj;

PROCEDURE Kasuj( file : ARRAY OF CHAR; VAR ok : BOOLEAN );
BEGIN
  Delete( file );
  ok := TRUE;
END Kasuj;

PROCEDURE SkasujKartoteke(  );
  BEGIN
    DirQuery( "*.*", Attributes{}, Kasuj );
    DirQuery( "*.*", Attributes{Subdir}, ZmienISkasuj );
  END SkasujKartoteke;

PROCEDURE ZmienISkasuj( dir : ARRAY OF CHAR; VAR ok : BOOLEAN );
  VAR
    CurrentDir : ARRAY [0..WlkNazwy-1] OF CHAR;
  BEGIN
    ok := TRUE;
    IF dir[0] = '.' THEN
      RETURN;
    END;
    GetDir( CurrentDir );
(*    Terminate( Warning );*)
    IF CD( dir ) THEN
      SkasujKartoteke;
      IF CD( CurrentDir ) THEN
      END;
      RmDir( dir );
    ELSE
      ok := FALSE;
    END;
  END ZmienISkasuj;

PROCEDURE SkasujOblot( VAR NazwaOblotu : ARRAY OF CHAR );
VAR
  e, s, CurrentDir : ARRAY [0..WlkNazwy-1] OF CHAR;
  i, j, NumerOblotu : INTEGER;
BEGIN
  IF NazwaOblotu[0] = 0C THEN
    RETURN;
  END;
  j := Ile();
  IF (j = 0) THEN
    RETURN;
  END;
  NumerOblotu := 0;
  LOOP
    sprintf( e, "Oblot%d", NumerOblotu );
    GetPrivateProfileString( Header,
                           e,
                           "",
                           s,
                           NazwaPlikuIni );
    IF CompareStr( s, NazwaOblotu ) = 0 THEN
      EXIT; (* o ten! *)
    END;
    INC( NumerOblotu );
    IF NumerOblotu = j THEN
      RETURN; (* nie znalazl *)
    END;
  END;
  SzczegolowyPlikOpisu( s, NazwaPlikuZOpisem, FALSE );
  GetDir( CurrentDir );
  IF CD( NazwaPlikuZOpisem ) THEN
    SkasujKartoteke;
  END;
  IF CD( CurrentDir ) THEN
  END;
  RmDir( NazwaPlikuZOpisem );
  DeleteSection( s, NazwaPlikuIni );
  FOR i := NumerOblotu TO Ile()-1 DO
    j := i+1;
    sprintf( e, "Oblot%d", j );
    GetPrivateProfileString( Header,
                             e,
                             "",
                             s,
                             NazwaPlikuIni );
    sprintf( e, "Oblot%d", i );
    WritePrivateProfileString( Header,
                               e,
                               s,
                               NazwaPlikuIni );
  END;
  i := Ile()-1;
  sprintf( s, "%d", i );
  WritePrivateProfileString( Header,
                             "Ilosc",
                             s,
                             NazwaPlikuIni );
END SkasujOblot;

PROCEDURE ExistDIR( VAR Dir : ARRAY OF CHAR ) : BOOLEAN;
  VAR
    Tmp : ARRAY [0..WlkNazwy-1] OF CHAR;
    ok : BOOLEAN;
  BEGIN
    GetDir( Tmp );
    ok := CD( Dir );
    IF CD( Tmp ) THEN (* wraca gdzie byl *)
    END;
    RETURN ok;
  END ExistDIR;

PROCEDURE FreeSlot(     DirTmp : ARRAY OF CHAR;
                    VAR Result : ARRAY OF CHAR );
  VAR
    i : CARDINAL;
  BEGIN
    FOR i := 0 TO 999 DO
      sprintf( Result, DirTmp, i );
      IF NOT ExistDIR(Result) THEN
        RETURN;
      END;
    END;
    InfoBeep( "Przekroczony limit inspekcji. Tak by† nie mo¾e", 3, 555H );
    Terminate( Warning );
  END FreeSlot;

END Obloty.


