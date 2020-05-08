IMPLEMENTATION MODULE N_DataBase;

FROM MANAGER IMPORT
  Assert;

FROM SYSTEM IMPORT
  ADDRESS, ADR;
FROM GrafTypes IMPORT
  RECT, YELLOW, BLACK;
FROM Messages IMPORT Message, NewMessage, Display, Acknowledge,
  AcknowledgeFirst;
FROM Ini IMPORT
  GetPrivateProfileString, WritePrivateProfileString;
FROM Strings IMPORT
  Assign, Delete, Length, ConstAssign;
FROM NumberConversion IMPORT
  StringToCard, StringToInt;
FROM RealConversions IMPORT
  StringToReal;
FROM StdIO IMPORT
  sprintf;
FROM Timer IMPORT
  Wait, TInOneSecond;
FROM Sounds IMPORT
  Sound, NoSound;
FROM RTSMain IMPORT
  Terminate, Status;
FROM MathLib0 IMPORT
  entier;
IMPORT
  GeoArithmetic, TheodolitRead, CommonTypes;

CONST
  NDBLIST = "ndblist.ini";

PROCEDURE SignalError(ok: BOOLEAN);
BEGIN
  Assert(ok);
END SignalError;

PROCEDURE OpisNadajnika( VAR Section   : ARRAY OF CHAR;
                         VAR AddDir    : ARRAY OF CHAR );

  PROCEDURE GetStr( Entry : ARRAY OF CHAR );
  VAR
    i : INTEGER;
  BEGIN
    GetPrivateProfileString( Section, Entry, "", Str, SkadBrac );
    i := 0;
    WHILE (i <= HIGH( Str)) & (Str[i] = ' ' ) DO
      INC( i );
    END;
    Delete( Str, 0, i );
    i := Length( Str );
    DEC( i );
    WHILE (i >= 0) & (Str[i]=' ') DO
      Str[i] := 0C;
      DEC(i);
    END;
    IF Skopiowac THEN
      WritePrivateProfileString( Section, Entry, Str, AddDir );
    END;
  END GetStr;

VAR
  Str, l, SkadBrac  : ARRAY [0..127] OF CHAR;
  OK : BOOLEAN;
  i : INTEGER;
  Skopiowac : BOOLEAN;
  r         : REAL;
  tmp       : CARDINAL;
BEGIN
  WITH NadajnikNDB DO
    Assign( Section, Nazwa );
    Assign( AddDir, SkadBrac );
    Skopiowac := FALSE;
    GetStr( 'Czestotliwosc' );
    StringToCard( Str, Czestotliwosc, OK );
    IF NOT OK THEN
      ConstAssign( NDBLIST, SkadBrac );
      Skopiowac := TRUE;
      GetStr( "Czestotliwosc" );
      StringToCard( Str, Czestotliwosc, OK );
    END;

    WITH Polozenie.Szerokosc DO
      GetStr( "Szerokosc.Stopnie" );
      StringToInt( Str, Stopnie, OK );
      GetStr( "Szerokosc.Minuty" );
      StringToCard( Str, Minuty, OK );
      SignalError(OK);
      GetStr( "Szerokosc.Setne" );
      StringToCard( Str, DziesTys, OK );
      SignalError(OK);
    END;
    WITH Polozenie.Dlugosc DO
      GetStr( "Dlugosc.Stopnie" );
      SignalError(OK);
      StringToInt( Str, Stopnie, OK );
      GetStr( "Dlugosc.Minuty" );
      SignalError(OK);
      StringToCard( Str, Minuty, OK );
      GetStr( "Dlugosc.Setne" );
      SignalError(OK);
      StringToCard( Str, DziesTys, OK );
    END;

    GetStr( "Deklinacja" );
    StringToReal( Str, Deklinacja, OK );
    SignalError(OK);

    GetStr( "Identyfikator" );
    Assign( Str, Identyfikator );
    Identyfikator[3] := 0C;

    IF OK THEN
      GeoArithmetic.Deklinacja := Deklinacja;
      GeoArithmetic.Odniesienie[CommonTypes.goA] := Polozenie;
(*
      TheodolitRead.PolozenieTeodolitu.Odleglosc := TeodolitGS;
      TheodolitRead.PolozenieTeodolitu.Kat := 0.0;
*)
      RETURN;
    END;
  END;
  Display(Blad_podczas_wczytywania_Lotniska);
  Wait( 5*TInOneSecond());
  Terminate( Warning );
END OpisNadajnika;


PROCEDURE  LoadProgramPar;

PROCEDURE GetCardinal(  name: ARRAY OF CHAR;
                        def: CARDINAL; VAR val: CARDINAL);
VAR
  s : ARRAY [0..20] OF CHAR;
  ok : BOOLEAN;
BEGIN
  GetPrivateProfileString( "NDB_SERVICE", name, " ", s, "wskaznik.ini" );
  StringToCard(s, val, ok);
  IF NOT ok  THEN
     val:= def;
  END;
END GetCardinal;

BEGIN
  GetCardinal("NDB_O_czuloscWP",  500, NDB_O_czuloscWP);
  GetCardinal("NDB_O_czuloscCP", 1000, NDB_O_czuloscCP);
  GetCardinal("NDB_R_czuloscWP",  500, NDB_R_czuloscWP);
  GetCardinal("NDB_R_czuloscCP",  500, NDB_R_czuloscCP);
END LoadProgramPar;





VAR
   Blad_podczas_wczytywania_Lotniska : Message;
BEGIN
  LoadProgramPar;
  NewMessage( Blad_podczas_wczytywania_Lotniska,
             "Bˆ¥d podczas wczytywania opisu Lotniska",
              BITSET{0..3,7,8,12..14});
END N_DataBase.
