(*.F- *)
(**********************************************************************
|  Title   : Baza danych dla VOR'w - skopiowana z TRS
|  Author  : M.Morawski
|  System  : LOGITECH MODULA-2/86
|  History :
|    15-12-96: M.Postol
|      podstawia w GeoArithmetic polozenia dla dwoch VOR'ow
|    14-06-00: M.Postol
|      dopasowlem do nowej definicji PolozenieGeo
|    Rel. 3.14: MPOstol
|      Dostosowalem do nowej definicji GeoArithmetic - inny sposob 
|      indeksowania polozen.
|
|  Copyright (C), CAS LODZ POLAND.
|  TEL: 42' 686 25 47
|  mailto: techsupp@cas.com.pl
|  http: www.cas.com.pl
|
**********************************************************************)
(*.F+ *)
IMPLEMENTATION MODULE V_Database;

FROM SYSTEM IMPORT
  ADDRESS, ADR;
FROM GrafTypes IMPORT
  RECT, YELLOW, BLACK;
FROM Messages IMPORT Message, NewMessage, Display, Acknowledge,
  AcknowledgeFirst;
FROM Ini IMPORT
  GetPrivateProfileString, WritePrivateProfileString;
FROM Strings IMPORT
  Assign, ConstAssign, Delete, Length;
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
FROM CommonTypes IMPORT
  GlownyOdbiornikT;
  
IMPORT
  GeoArithmetic, TheodolitRead;


CONST
  VORLIST = "VORlist.ini";

PROCEDURE LoadVorData( VAR V       : Vor;
                       VAR Section : ARRAY OF CHAR;
                       VAR AddDir  : ARRAY OF CHAR );

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
  Skopiowac, gOK, OK : BOOLEAN;
  tmp : CARDINAL;
  i : INTEGER;
BEGIN
  WITH V DO
    Assign( Section, Nazwa );
    Assign( AddDir, SkadBrac );
    Skopiowac := FALSE;
    WITH Polozenie.Szerokosc DO
      GetStr( "Szerokosc.Stopnie" );
      StringToInt( Str, Stopnie, gOK );
      IF NOT gOK THEN
        ConstAssign( VORLIST, SkadBrac );
        Skopiowac := TRUE;
        GetStr( "Szerokosc.Stopnie" );
        StringToInt( Str, Stopnie, gOK );
      END;
      GetStr( "Szerokosc.Minuty" );
      StringToCard( Str, Minuty, OK );
      gOK := gOK & OK;
      GetStr( "Szerokosc.DTysieczne" );
      StringToCard( Str, DziesTys, OK );
      gOK := gOK & OK;
    END;
    WITH Polozenie.Dlugosc DO
      GetStr( "Dlugosc.Stopnie" );
      StringToInt( Str, Stopnie, OK );
      gOK := gOK & OK;
      GetStr( "Dlugosc.Minuty" );
      StringToCard( Str, Minuty, OK );
      gOK := gOK & OK;
      GetStr( "Dlugosc.DTysieczne" );
      StringToCard( Str, DziesTys, OK );
      gOK := gOK & OK;
    END;
    GetStr( "Teodolit.Kat" );
    StringToReal( Str, Teodolit.Kat, OK );
    gOK := gOK & OK;

    GetStr( "Teodolit.Odleglosc" );
    StringToReal( Str, Teodolit.Odleglosc, OK );
    IF OK  THEN
      Teodolit.Odleglosc := Teodolit.Odleglosc / 1852.0;
    END;
    gOK := gOK & OK;

    GetStr( "Dme" );
    StringToCard( Str, tmp, OK );
    IF NOT OK THEN
      tmp := 0;
    END;
    CzyJestDME := tmp # 0;

    GetStr( "IloscKierunkow" );
    StringToInt( Str, IleKierunkow, OK );
    gOK := gOK & OK;

    GetStr( "Deklinacja" );
    StringToReal( Str, Deklinacja, OK );
    gOK := gOK & OK;

    GetStr( "Czestotliwosc" );
    StringToCard( Str, Czestotliwosc, OK );
    gOK := gOK & OK;

    GetStr( "Orbita.Zasiegowa" );
    StringToReal( Str, OrbitaZasieg, OK );
    gOK := gOK & OK;

    GetStr( "Orbita.Pomiarowa" );
    StringToReal( Str, OrbitaBlad, OK );
    gOK := gOK & OK;

    GetStr( "Identyfikator" );
    Assign( Str, Identyfikator );
    Identyfikator[3] := 0C;


    IF gOK & ( IleKierunkow <= HIGH( Kierunki )) & ( IleKierunkow # 0 ) THEN
      FOR i := 0 TO IleKierunkow -1 DO
        sprintf( l, "Kierunek%d", i );
        GetStr( l );
        StringToCard( Str, Kierunki[i], OK );
        gOK := gOK & OK;
      END;
      IF gOK THEN
        GetPrivateProfileString( DOD_KIERUNKI, "Ilosc", "0", Str, AddDir );
        StringToInt( Str, IleKierunkowDodatkowych, gOK );
        IF NOT gOK THEN
          IleKierunkowDodatkowych := 0;
        END;
        gOK := TRUE;
        FOR i := 0 TO IleKierunkowDodatkowych-1 DO
          sprintf( l, "Kierunek%d", i );
          GetPrivateProfileString( DOD_KIERUNKI, l, "", Str, AddDir );
          StringToCard( Str, KierunkiDodatkowe[i], OK );
          gOK := gOK & OK;
        END;
        IF gOK THEN
          RETURN;
        END;
      END;
    END;
  END;
  Display(Blad_podczas_wczytywania_opisu_VORa);
  Wait( 5*TInOneSecond());
  Terminate( Warning );
END LoadVorData;

PROCEDURE LoadVorData1( VAR NazwaVORa              : ARRAY OF CHAR;
                        VAR PlikZOpisemDodatkowych : ARRAY OF CHAR );
BEGIN
  LoadVorData( CurVor1, NazwaVORa, PlikZOpisemDodatkowych );
  WITH CurVor1  DO
    GeoArithmetic.Deklinacja := Deklinacja;
    GeoArithmetic.AssignOdniesienie(Polozenie, 0);
    TheodolitRead.PolozenieTeodolitu := Teodolit;
  END;
END LoadVorData1;

PROCEDURE LoadVorData2( VAR NazwaVORa              : ARRAY OF CHAR;
                        VAR PlikZOpisemDodatkowych : ARRAY OF CHAR );
BEGIN
  LoadVorData( CurVor2, NazwaVORa, PlikZOpisemDodatkowych );
  GeoArithmetic.AssignOdniesienie( CurVor2.Polozenie, 1);
  twoLocations := TRUE;
END LoadVorData2;

PROCEDURE  LoadProgramPar;

PROCEDURE GetCardinal(  name: ARRAY OF CHAR;
                        def: CARDINAL; VAR val: CARDINAL);
VAR
  s : ARRAY [0..20] OF CHAR;
  ok : BOOLEAN;
BEGIN
  GetPrivateProfileString( "VOR_SERVICE", name, " ", s, "wskaznik.ini" );
  StringToCard(s, val, ok);
  IF NOT ok  THEN
     val:= def;
  END;
END GetCardinal;

BEGIN
  GetCardinal("VOR_O_czuloscWP",  500, VOR_O_czuloscWP);
  GetCardinal("VOR_O_czuloscCP", 1000, VOR_O_czuloscCP);
  GetCardinal("VOR_R_czuloscWP",  500, VOR_R_czuloscWP);
  GetCardinal("VOR_R_czuloscCP",  500, VOR_R_czuloscCP);
END LoadProgramPar;

VAR
   Blad_podczas_wczytywania_opisu_VORa : Message;
BEGIN
  twoLocations := FALSE;
  LoadProgramPar;
  NewMessage( Blad_podczas_wczytywania_opisu_VORa,
             "Bˆ¥d podczas wczytywania opisu VORa",
              BITSET{0..3,7,8,12..14});
END V_Database.
