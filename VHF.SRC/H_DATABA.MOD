(*.F- *)
(**********************************************************************
|  Title   : Baza danych dla VHF
|  Author  : M.Morawski
|  System  : LOGITECH MODULA-2/86
|  History :
|    08-12-96: created
|    15-12-96: M.Postol
|      zmiana def. GeoArithmetic
|    14-06-00: M.Postol
|      Dostosowalem do nowej definicji Polozenie
|   Rel. 3.14. MPostol
|     - Dostosowalem do nowej defincicji GeoArithmetic - inne wskazywanie 
|       polozen odniesienia
|
|  Copyright (C), CAS LODZ POLAND.
|  TEL: 42' 862 547, 42' 87 80 44 FAX/TEL: 42' 84 48 40
|
**********************************************************************)
(*.F+ *)
IMPLEMENTATION MODULE H_DataBase;

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
  VHFLIST = "vhflist.ini";

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
  WITH NadajnikVHF DO
    Assign( Section, Nazwa );
    Assign( AddDir, SkadBrac );
    Skopiowac := FALSE;
    GetStr( 'Deklinacja' );
    StringToReal( Str, Deklinacja, OK );
    IF NOT OK THEN
      ConstAssign( VHFLIST, SkadBrac );
      Skopiowac := TRUE;
      GetStr( "Deklinacja" );
      StringToReal( Str, Deklinacja, OK );
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
  GetPrivateProfileString( "VHF_SERVICE", name, " ", s, "wskaznik.ini" );
  StringToCard(s, val, ok);
  IF NOT ok  THEN
     val:= def;
  END;
END GetCardinal;

BEGIN
  GetCardinal("VHF_O_czuloscWP",  500, VHF_O_czuloscWP);
  GetCardinal("VHF_O_czuloscCP", 1000, VHF_O_czuloscCP);
  GetCardinal("VHF_R_czuloscWP",  500, VHF_R_czuloscWP);
  GetCardinal("VHF_R_czuloscCP",  500, VHF_R_czuloscCP);
END LoadProgramPar;





VAR
   Blad_podczas_wczytywania_Lotniska : Message;
BEGIN
  LoadProgramPar;
  NewMessage( Blad_podczas_wczytywania_Lotniska,
             "Bˆ¥d podczas wczytywania opisu Lotniska",
              BITSET{0..3,7,8,12..14});
END H_DataBase.
