(*.F- *)
(**********************************************************************
|  Title   : Baza danych dla LOC 
|  Author  : M.Morawski
|  System  : LOGITECH MODULA-2/86 
|  History :
|    11-09-96: M.Postol
|      wprowadzono typ MkrId_T
|    16-10-96: M.Postol
|      zmiana def. wartosci czulosci dla LOC_R_czuloscCP ; 
|      nowa nazwa pliku z danymi dla wskaznika wskaznik.ini
|    25-02-97: M.postol
|      dopisalem GsMoveDis, poniewaz dla GS punkt odniesienia powinien byc w 
|      zasadzie w THD
|
|  Copyright (C), CAS LODZ POLAND.
|  TEL: 42' 862 547, 42' 87 80 44 FAX/TEL: 42' 84 48 40
|
**********************************************************************)
(*.F+ *)
IMPLEMENTATION MODULE L_DataBase;

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
FROM CommonTypes  IMPORT
  DisNilVal;
  
IMPORT
  GeoArithmetic, TheodolitRead, CommonTypes;


CONST
  LOTNLIST = "lotnlist.ini";

PROCEDURE SignalError(ok: BOOLEAN);
BEGIN
  Assert(ok);
END SignalError;

PROCEDURE OpisLotniska( VAR Section   : ARRAY OF CHAR;
                        VAR AddDir    : ARRAY OF CHAR;
                            ToJestLoc : BOOLEAN );

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

  PROCEDURE CzytajPolozeniePunktowCharakterystycznych(  );
    VAR
      Zap : ARRAY[0..29] OF CHAR;
      c   : CHAR;
      i   : CARDINAL;
    BEGIN
      FOR i := 0 TO 4 DO
        c := CHR( ORD( 'A' ) + i );
        sprintf( Zap, 'Punkt.Ch.%c', c );
        GetStr( Zap );
        StringToReal( Str, r, OK );
        SignalError(OK);
        Lotnisko.PolozeniePCh[i] := TRUNC( r*500.0 );
      END;
    END CzytajPolozeniePunktowCharakterystycznych;

  PROCEDURE CzytajPolozenieMarkerow(  );
    VAR
      Zap   : ARRAY[0..29] OF CHAR;
      i     : MkrId_T;
      mkrNr : CARDINAL;
    BEGIN
      FOR i := MIN(MkrId_T) TO MAX(MkrId_T) DO
        mkrNr := ORD(i);
        sprintf( Zap, 'Marker.%d', mkrNr );
        GetStr( Zap );
        StringToReal( Str, r, OK );
        SignalError(OK);
        IF r > 0.0 THEN
          Lotnisko.OdlMarkerow[i] := TRUNC( r*500.0 );
        ELSE
          Lotnisko.OdlMarkerow[i] := CommonTypes.NilValC;
        END;
      END;
    END CzytajPolozenieMarkerow;


VAR
  Str, l, SkadBrac  : ARRAY [0..127] OF CHAR;
  OK : BOOLEAN;
  i : INTEGER;
  Skopiowac : BOOLEAN;
  r         : REAL;
  tmp       : CARDINAL;
BEGIN
  WITH Lotnisko DO
    Assign( Section, Nazwa );
    Assign( AddDir, SkadBrac );
    Skopiowac := FALSE;
    WITH Polozenie.Szerokosc DO
      GetStr( "Szerokosc.Stopnie" );
      StringToInt( Str, Stopnie, OK );
      IF NOT OK THEN
        ConstAssign( LOTNLIST, SkadBrac );
        Skopiowac := TRUE;
        GetStr( "Szerokosc.Stopnie" );
        StringToInt( Str, Stopnie, OK );
      END;
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

    GetStr( "Teodolit.Odleglosc.GS" );
    StringToReal( Str, TeodolitGS, OK );
    SignalError(OK);

    GetStr( "Teodolit.Odleglosc.LOC" );
    StringToReal( Str, TeodolitLOC, OK );
    SignalError(OK);

    GetStr( 'Czestotliwosc' );
    StringToCard( Str, Czestotliwosc, OK );
    SignalError(OK);

    GetStr( "Deklinacja" );
    StringToReal( Str, Deklinacja, OK );
    SignalError(OK);

    GetStr( 'KierunekPasa' );
    StringToCard( Str, KierunekPasa, OK );
    SignalError(OK);

    GetStr( "Identyfikator" );
    Assign( Str, Identyfikator );
    Identyfikator[3] := 0C;

    GetStr( 'Kategoria' );
    StringToCard( Str, Kategoria, OK );
    SignalError(OK);
    IF (Kategoria < 1) OR (Kategoria > 3) THEN
      OK := FALSE;
    END;

    GetStr( 'Pas.Start' );
    StringToReal( Str, r, OK );
    SignalError(OK);
    ProgPasa := TRUNC( r*500.0 );

    GetStr( 'Pas.Koniec' );
    StringToReal( Str, r, OK );
    SignalError(OK);
    KoniecPasa := TRUNC( r*500.0 );

    CzytajPolozenieMarkerow;
    CzytajPolozeniePunktowCharakterystycznych;
(*
    GetStr( 'Dlugosc.Pasa' );
    StringToReal( Str, r, OK );
    DlugoscPasa := TRUNC( r*500.0 );
    gOK := gOK & OK;
*)
    DlugoscPasa := ProgPasa-KoniecPasa;

    GetStr( 'Szerokosc.Sektora.N' );
    StringToReal( Str, r, OK );
    SignalError(OK);
    Szer_Sekt := entier( r*100.0 );

    GetStr( 'Szerokosc.Sektora-A.Szeroki' );
    StringToReal( Str, r, OK );
    SignalError(OK);
    Szer_Sekt_Szer := entier( r*100.0 );

    GetStr( 'Szerokosc.Sektora-A.Waski' );
    StringToReal( Str, r, OK );
    SignalError(OK);
    Szer_Sekt_Waski := entier( r*100.0 );

    GetStr( 'Kat.GS' );
    StringToReal( Str, r, OK );
    SignalError(OK);
    Kat_GS := entier( r*100.0 );

    GetStr( 'Szerokosc.GS' );
    StringToReal( Str, r, OK );
    SignalError(OK);
    Szer_GS := entier( r*100.0 );

    GetStr( "Dme" );
    StringToCard( Str, tmp, OK );
    SignalError(OK);
    IF NOT OK THEN
      tmp := 0;
    END;
    CzyJestDME := tmp # 0;

    IF CzyJestDME THEN
      GetStr( 'DME.Azymut' );
      StringToReal( Str, r, OK );
      SignalError(OK);
      Dme_Azymut := entier( r*100.0 );

      GetStr( 'DME.Odleglosc' );
      StringToReal( Str, r, OK );
      SignalError(OK);
      Dme_Odleglosc := TRUNC( r*500.0 );

      GetStr( 'DME.Offset' );
      StringToReal( Str, r, OK );
      SignalError(OK);
      Dme_Offset := TRUNC( r*500.0 );

    END;

    IF OK THEN
      GeoArithmetic.Deklinacja := Deklinacja;
      GeoArithmetic.Odniesienie[CommonTypes.goA] := Polozenie;
      IF ToJestLoc THEN
        TheodolitRead.PolozenieTeodolitu.Odleglosc := TeodolitGS;
      ELSE
        TheodolitRead.PolozenieTeodolitu.Odleglosc := TeodolitGS;
      END;
      TheodolitRead.PolozenieTeodolitu.Kat := 0.0;
      RETURN;
    END;
  END;
  Display(Blad_podczas_wczytywania_Lotniska);
  Wait( 5*TInOneSecond());
  Terminate( Warning );
END OpisLotniska;


PROCEDURE  LoadProgramPar;

PROCEDURE GetCardinal(  name : ARRAY OF CHAR;
                        def  : CARDINAL; VAR val: CARDINAL);
VAR
  s : ARRAY [0..20] OF CHAR;
  ok : BOOLEAN;
BEGIN
  GetPrivateProfileString( "LOC_SERVICE", name, " ", s, "wskaznik.ini" );
  StringToCard(s, val, ok);
  IF NOT ok  THEN
     val:= def;
  END;
END GetCardinal;

BEGIN
  GetCardinal("LOC_O_czuloscWP",  500, LOC_O_czuloscWP);
  GetCardinal("LOC_O_czuloscCP", 1000, LOC_O_czuloscCP);
  GetCardinal("LOC_R_czuloscWP",  500, LOC_R_czuloscWP);
  GetCardinal("LOC_R_czuloscCP", 1500, LOC_R_czuloscCP);
  (* dane dla GS *)
  GetCardinal("LOC_Az_czuloscCP",  200, LOC_Az_czuloscCP);
  GetCardinal("LOC_Az_czuloscWP",  200, LOC_Az_czuloscWP);
  GetCardinal("GS_El_czuloscCP",   100, GS_El_czuloscCP);
END LoadProgramPar;

  PROCEDURE GsMoveDis
           (    refDisCV : CARDINAL): CARDINAL;
  BEGIN
    WITH Lotnisko DO
      IF refDisCV = DisNilVal  THEN
        RETURN DisNilVal
      END;
      IF refDisCV > ProgPasa  THEN
        RETURN refDisCV - ProgPasa;
      ELSE
        RETURN ProgPasa - refDisCV;
      END;
    END;
  END GsMoveDis;




VAR
   Blad_podczas_wczytywania_Lotniska : Message;
BEGIN
  LoadProgramPar;
  NewMessage( Blad_podczas_wczytywania_Lotniska,
             "Bˆ¥d podczas wczytywania opisu Lotniska",
              BITSET{0..3,7,8,12..14});
END L_DataBase.
