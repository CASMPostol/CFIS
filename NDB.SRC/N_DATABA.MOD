(*.F- *)
(**********************************************************************
|  Title   : Obsluga bazy danych dla NDB 
|  Author  : M.Morawski
|  System  : LOGITECH MODULA-2/86 
|  History :
|     25-02-98: M.Postol
|       blad przy czytaniu czestotliwosci - czestotliwosc w bazie danych
|       powinna buc w KHz, a nie *100 bo sie nie miesci w CARDINAL
|     17-05-98: M.Postol
|       blad przy czytaniu czestotliwosci - przy braku czestotliwosci
|       w inspekcji czytane jest z bazy i tam tez musi byc korekta.
|     14-06-00: M.Postol
|       Dostosowalem do nowej definicji Polozenie
|     Rel. 3.0. MPostol
|       zmiana reprezentacji polozenia geograficznego w bazie
|     Rel. 3.14: MPostol
|       - dostosowaelm do nowej definicji GeoArithmetic - mozliwe 
|         osobne polozenie dla dwoch urzadzen.
|
|  Copyright (C), CAS LODZ POLAND.
|  TEL: 42' 686 25 47
|  mailto: techsupp@cas.com.pl
|  http: www.cas.com.pl
|
**********************************************************************)
(*.F+ *)
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
    IF Length(Str) >= 3  THEN
      Str[Length(Str) - 2] := 0C;
    END;
    StringToCard( Str, Czestotliwosc, OK );
    
    IF NOT OK THEN
      ConstAssign( NDBLIST, SkadBrac );
      Skopiowac := TRUE;
      GetStr( "Czestotliwosc" );
      IF Length(Str) >= 3  THEN
        Str[Length(Str) - 2] := 0C;
      END;
      StringToCard( Str, Czestotliwosc, OK );
    END;

    WITH Polozenie.Szerokosc DO
      GetStr( "Szerokosc.Stopnie" );
      StringToInt( Str, Stopnie, OK );
      GetStr( "Szerokosc.Minuty" );
      StringToCard( Str, Minuty, OK );
      SignalError(OK);
      GetStr( "Szerokosc.DTysieczne" );
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
      GetStr( "Dlugosc.DTysieczne" );
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
      GeoArithmetic.AssignOdniesienie( Polozenie, 0 );
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
             "B��d podczas wczytywania opisu Lotniska",
              BITSET{0..3,7,8,12..14});
END N_DataBase.
