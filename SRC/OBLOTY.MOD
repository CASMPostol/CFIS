(*.F- *)
(**********************************************************************
|  Title   : Wspolne elementy dla dla obslugi bazy danych oblotow 
|  Author  : M.Postol
|  System  : LOGITECH MODULA-2/86 
|  History :
|    09-10-97: MM
|      Zmienilem definicje SkasujOblot
|    Rel.3.02
|      Przygotowania do budowy SODA
|    Rel.3.14: MPostol
|      - InspekcjeNowyWpis - zmiana definicji - zwraca sukces lub jego brak
|      - Nowe zmienne: Stat_Size_Monitor, Stat_File_Monitor - pozwalajace na 
|        wypisywanie statystyk.
|      - SkasujKartoteke - zwraca rezultat dzialania
|      - Kasuj_DelDir - zwraca rezultat dzialania
|      - InspekcjeNowyWpis - najpier tworzy kartoteke, potem wpisuje dane 
|        inspekcji, aby wyeliminowac brak mozliwosci zapisu na nosniku.
|
|  Copyright (C), CAS LODZ POLAND.
|  TEL: 42' 686 25 47
|  mailto: techsupp@cas.com.pl
|  http: www.cas.com.pl
|
**********************************************************************)
(*.F+ *)
IMPLEMENTATION MODULE Obloty;

FROM Strings IMPORT
  Length, Insert, Assign, CompareStr, ConstAssign, Concat;

FROM Ini IMPORT
  WritePrivateProfileString, GetPrivateProfileString, DeleteSection;

FROM StdIO IMPORT
  sprintf;

FROM FIO IMPORT
  File, MkDir, Delete, CD, GetDir, RmDir, DirQuery, Attr, Attributes,
  Create, Open, Write, ReadExt, Close;

FROM GrafUtil IMPORT
  InfoBeep;

FROM RTSMain IMPORT
  Terminate, Status;

FROM GList IMPORT
  HLIST, DodajDoListy;

FROM NumberConversion IMPORT
  StringToCard, StringToInt, CardToString;

FROM CommonTypes IMPORT
  NilValC;
  
FROM MANAGER IMPORT
  Assert;

FROM SYSTEM IMPORT
  ADR, SIZE;
  
CONST
  WlkNazwy = 65;
  OblotTmp = "Oblot%d";
  BuffSize = 256;
  
TYPE
  T_NazwaStr = ARRAY [0..WlkNazwy-1] OF CHAR;

VAR
  HomeDir              : ARRAY[ 0..15 ] OF CHAR;
  HomeDirNazwaPlikuIni : T_NazwaStr;

  (* Obsluga bazy danych *)
  bd_NazwaPliku        : ARRAY[0..16] OF CHAR;
  bd_Sekcja            : ARRAY[0..10] OF CHAR;
  bd_WpisNazwa         : ARRAY[0..10] OF CHAR;

  (* Obsluga inspekcji *)
  insp_DirTmp          : ARRAY[0..10] OF CHAR;
  stat_Size            : REAL;
  stat_Files           : CARDINAL;
  (* zmienne statystyczne modyfikowane na biezaco w trakcie kopiowania 
     inspekcji *)

PROCEDURE  UstawHomeDir
           (   dir: ARRAY OF CHAR);
BEGIN
  Assign(dir, HomeDir);
  Concat(HomeDir, NazwaPlikuIni, HomeDirNazwaPlikuIni);
END UstawHomeDir;

PROCEDURE  Ile(): INTEGER ;
BEGIN
  RETURN IleInspekcji(HomeDirNazwaPlikuIni);
END Ile;

PROCEDURE IleInspekcji
          ( HomeDirNazwaPlikuIni: ARRAY OF CHAR ) : INTEGER;
VAR
  s  : ARRAY[0..5] OF CHAR;
  i  : CARDINAL;
  ok : BOOLEAN;
  
BEGIN
  GetPrivateProfileString( LISTA,
                           "Ilosc",
                           "0",
                           s,
                           HomeDirNazwaPlikuIni );
  StringToCard( s, i, ok );
  IF NOT ok THEN
    RETURN 0;
  END;
  RETURN i;
END IleInspekcji;

PROCEDURE WymienWszystkie
          (     Callback  : Oblot;
                nazwaBazy : ARRAY OF CHAR );
  (* Wywoluje callback dla kazdej inspekcji wymienionej w sekcji LISTA w
     pliku nazwaBazy.
  *)
  
VAR
  i, j         : INTEGER;
  NazInspekcji : T_NazwaStr;

BEGIN
  j := IleInspekcji(nazwaBazy);
  FOR i := 0 TO j-1 DO
    sprintf( NazInspekcji, OblotTmp, i );
    GetPrivateProfileString( LISTA,
                             NazInspekcji,
                             "",
                             NazInspekcji,
                             nazwaBazy );
    Callback( NazInspekcji );
  END;
END WymienWszystkie;

VAR
  NUrzadzDlaDopasuj   : T_NazwaStr;
  HomeDirDlaDopasuj   : T_NazwaStr;
  CallBackDlaDopasuj  : Oblot;
  NazwaPlikuZOpisem   : T_NazwaStr;

PROCEDURE Dopasuj( VAR NazwaOblotu : ARRAY OF CHAR );
VAR
  Nazwa             : ARRAY[ 0..30 ] OF CHAR;

BEGIN (* Dopasuj *)
  IF NOT SzczegolowyPlikOpisu( HomeDirDlaDopasuj, NazwaOblotu, NazwaPlikuZOpisem, 
                               TRUE )
  THEN
    RETURN;
  END (* IF *);
  GetPrivateProfileString( NazwaOblotu,
                           "Nazwa",
                           "",
                           Nazwa,
                           NazwaPlikuZOpisem );
  IF CompareStr( Nazwa, NUrzadzDlaDopasuj ) = 0 THEN
    CallBackDlaDopasuj( NazwaOblotu );
  END;
END Dopasuj;

PROCEDURE WymInspekcjeDlaUrz
          (     KartBazy            : ARRAY OF CHAR; 
                NazwaUrzadzenia     : ARRAY OF CHAR;
                CallBack            : Oblot );
  (* Wywoluje CallBack dla kazdej inspekcji wymienionej w sekcji LISTA w
     pliku KartBazy\NazwaPlikuIni, ktora dotyczy urzadzenia zdefiniowanego 
     przez NazwaUrzadzenia. Jesli pierwszym znakiem w NazwaUrzadzenia 
     jest '*'  CallBack jest wywolywana dla kazdej inspekcji. 
  *)
VAR
  HomeDirNazwaPlikuIni:  T_NazwaStr;
  
BEGIN (* WymInspekcjeDlaUrz *)
  Concat(KartBazy, NazwaPlikuIni, HomeDirNazwaPlikuIni);
  IF NazwaUrzadzenia[0] = '*'  THEN
    WymienWszystkie( CallBack, HomeDirNazwaPlikuIni);
  ELSE
    CallBackDlaDopasuj := CallBack;
    Assign( NazwaUrzadzenia,  NUrzadzDlaDopasuj );
    Assign( KartBazy,         HomeDirDlaDopasuj);
    WymienWszystkie( Dopasuj, HomeDirNazwaPlikuIni);
  END;
END WymInspekcjeDlaUrz;

PROCEDURE WymienWszystkiePasujace
          (     NazwaUrzadzenia     : ARRAY OF CHAR;
                CallBack            : Oblot );
  (* Wywoluje callback dla kazdej inspekcji wymienionej w sekcji LISTA w
     pliku HomeDir\NazwaPlikuIni, ktora dotyczy urzadzenia zdefiniowanego 
     przez NazwaUrzadzenia. Jesli pierwszym znakiem w NazwaUrzadzenia 
     jest '*' callback jest wywolywana dla kazdej inspekcji. 
  *)
BEGIN (* WymienWszystkiePasujace *)
  WymInspekcjeDlaUrz(HomeDir, NazwaUrzadzenia, CallBack);
END WymienWszystkiePasujace;

PROCEDURE SzczegolowyPlikOpisu
          (     KartBazy       : ARRAY OF CHAR;
                NazwaInspekcji : ARRAY OF CHAR;
            VAR Kartoteka      : ARRAY OF CHAR;
                Dopisac        : BOOLEAN ): BOOLEAN;
VAR
  HomeDirNazwaPlikuIni:  T_NazwaStr;
  
BEGIN
  Concat(KartBazy, NazwaPlikuIni, HomeDirNazwaPlikuIni);
  GetPrivateProfileString( NazwaInspekcji,
                           "Kartoteka",
                           "",
                           Kartoteka,
                           HomeDirNazwaPlikuIni );
  IF Length(Kartoteka) < 2  THEN
    RETURN FALSE;
  END (* IF *);
  Concat( KartBazy, Kartoteka,  Kartoteka);
  IF Dopisac THEN
    IF Kartoteka[ Length(Kartoteka) -1] # '\' THEN
      Insert( '\', Kartoteka, 0FFFH );
    END;
    Concat( Kartoteka, NazwaPlikuIni, Kartoteka);
  ELSE
    IF Kartoteka[ Length( Kartoteka ) -1] = '\' THEN
      Kartoteka[ Length( Kartoteka ) -1] := 0C;
    END;
  END;
  RETURN TRUE;
END SzczegolowyPlikOpisu;

PROCEDURE Kasuj
          (    file    : ARRAY OF CHAR; 
               fAttrib : Attributes;
           VAR ok      : BOOLEAN );
BEGIN
  Delete( file );
END Kasuj;

PROCEDURE ZmienISkasuj
          (     dir     : ARRAY OF CHAR;
                fAttrib : Attributes;
            VAR ok      : BOOLEAN );
VAR
  CurrentDir : ARRAY [0..WlkNazwy-1] OF CHAR;

BEGIN
  IF dir[0] = '.' THEN
    RETURN;
  END;
  GetDir( CurrentDir );
  IF CD( dir ) THEN
    ok := SkasujKartoteke();
    IF CD( CurrentDir ) THEN END;
    RmDir( dir );
  ELSE
    ok := FALSE;
  END;
END ZmienISkasuj;

PROCEDURE SkasujKartoteke(  ): BOOLEAN;
BEGIN
  RETURN DirQuery( "*.*", Attributes{}, Kasuj, FALSE ) AND
         DirQuery( "*.*", Attributes{Subdir}, ZmienISkasuj, FALSE );
END SkasujKartoteke;

PROCEDURE SkasujOblot
          ( VAR NazwaOblotu : ARRAY OF CHAR );
VAR
  InspPath           : ARRAY[ 0..WlkNazwy ] OF CHAR;
  inspNum            : ARRAY[ 0..15] OF CHAR; 
  s, CurrentDir      : ARRAY [0..WlkNazwy-1] OF CHAR;
  NumerOblotu        : CARDINAL;
  i, j               : INTEGER;
  ile                : INTEGER;
  
BEGIN (* SkasujOblot *)
  IF Length(NazwaOblotu) = 0 THEN
    RETURN;
  END; 
  NumerOblotu := ZnajdzNumInspekcji(KartDomyslna, NazwaOblotu);
  IF NumerOblotu = NilValC THEN
    RETURN;
  END (* IF *);
  Assert(SzczegolowyPlikOpisu( KartDomyslna, NazwaOblotu, InspPath, FALSE ));
  GetDir( CurrentDir );
  IF CD( InspPath ) AND SkasujKartoteke() THEN
  END;
  IF CD( CurrentDir ) THEN
  END;
  RmDir( InspPath );
  DeleteSection( NazwaOblotu, HomeDirNazwaPlikuIni );
  ile := IleInspekcji(HomeDirNazwaPlikuIni);
  FOR i := NumerOblotu TO  ile - 2 DO
    j := i+1;
    sprintf( inspNum, OblotTmp, j );
    GetPrivateProfileString( LISTA,
                             inspNum,
                             "",
                             s,
                             HomeDirNazwaPlikuIni );
    sprintf( inspNum, OblotTmp, i );
    WritePrivateProfileString( LISTA,
                               inspNum,
                               s,
                               HomeDirNazwaPlikuIni );
  END;
  DEC(ile);
  Assert( ile >= 0);
  sprintf( s, "%d", ile );
  WritePrivateProfileString( LISTA,
                             "Ilosc",
                             s,
                             HomeDirNazwaPlikuIni );
END SkasujOblot;

VAR
  DelDir: T_NazwaStr;

PROCEDURE KasujPodkartoteke
          (     pkartoteka : ARRAY OF CHAR; 
                fAttrib    : Attributes;
            VAR ok         : BOOLEAN );
VAR
  DelDirEnd: CARDINAL;
  
  PROCEDURE KasujPlik
            (     file : ARRAY OF CHAR );
  VAR
    DirEnd : CARDINAL;
  
  BEGIN
    DirEnd := Length(DelDir);
    Insert('\',  DelDir, MAX( CARDINAL ) );
    Insert(file, DelDir, MAX( CARDINAL ) );
    Delete( DelDir );
    DelDir[ DirEnd ] := 0C;
  END KasujPlik;

BEGIN (* KasujPodkartoteke *)
  IF pkartoteka[0] = '.' THEN
    RETURN
  END (* IF *);
  IF Subdir IN fAttrib THEN
    DelDirEnd := Length(DelDir);
    Insert('\',  DelDir, MAX(CARDINAL));
    Insert(pkartoteka, DelDir, MAX(CARDINAL));
    ok := Kasuj_DelDir();
    DelDir[DelDirEnd] := 0C;
    RmDir(DelDir);
  ELSE
    KasujPlik(pkartoteka);
  END (* IF *);
END KasujPodkartoteke;

PROCEDURE Kasuj_DelDir(): BOOLEAN;
VAR
  nameToQuery: T_NazwaStr;
  
BEGIN
  Assign( DelDir, nameToQuery);
  Insert( '\',    nameToQuery, MAX(CARDINAL));
  Insert( "*.*",  nameToQuery, MAX(CARDINAL));
  RETURN DirQuery( nameToQuery, Attributes{ Subdir }, KasujPodkartoteke, 
                   FALSE );
END Kasuj_DelDir;

PROCEDURE SkasujInspekcje
          (     KartBazyZrodlo  : ARRAY OF CHAR;
            VAR NazwaInspekcji  : ARRAY OF CHAR ): BOOLEAN;
  (* Szuka inspekcji w KartBazyZrodlo i jesli znajdzie kasuje ja i 
     wszystkie jej pliki. Na koncu zmienia numery inspekcji tak by wypelnic 
     luke. Nie sa natomiast zmieniane nazwy kartotek, gdzie przechowywane sa 
     pliki z danymi.
  *)
VAR
  inspNum              : ARRAY[ 0..15] OF CHAR; 
  s                    : ARRAY[ 0..WlkNazwy-1] OF CHAR;
  NumerOblotu          : CARDINAL;
  idx, jdx             : INTEGER;
  ile                  : INTEGER;
  HomeDirNazwaPlikuIni : T_NazwaStr;
  kasKartOK            : BOOLEAN;
  
BEGIN
  IF Length(NazwaInspekcji) = 0 THEN
    RETURN FALSE;
  END; 
  NumerOblotu := ZnajdzNumInspekcji(KartBazyZrodlo, NazwaInspekcji);
  IF NumerOblotu = NilValC THEN
    RETURN FALSE;
  END (* IF *);
  IF NOT SzczegolowyPlikOpisu( KartBazyZrodlo, NazwaInspekcji, DelDir,  FALSE)
  THEN
    RETURN FALSE;
  END (* IF *);
  kasKartOK := Kasuj_DelDir();
  IF kasKartOK  THEN
    RmDir( DelDir );
  END (* IF *);
  Assign( KartBazyZrodlo, HomeDirNazwaPlikuIni);
  Insert(NazwaPlikuIni, HomeDirNazwaPlikuIni, MAX(CARDINAL) );
  DeleteSection( NazwaInspekcji, HomeDirNazwaPlikuIni );
  ile := IleInspekcji(HomeDirNazwaPlikuIni);
  FOR idx := NumerOblotu TO ile - 2 DO
    jdx := idx + 1;
    sprintf( inspNum, OblotTmp, jdx );
    GetPrivateProfileString( LISTA,
                             inspNum,
                             "",
                             s,
                             HomeDirNazwaPlikuIni );
    sprintf( inspNum, OblotTmp, idx );
    WritePrivateProfileString( LISTA,
                               inspNum,
                               s,
                               HomeDirNazwaPlikuIni );
  END;
  DEC(ile);
  Assert( ile >= 0);
  sprintf( s, "%d", ile );
  WritePrivateProfileString( LISTA,
                             "Ilosc",
                             s,
                             HomeDirNazwaPlikuIni );
  RETURN kasKartOK;
END SkasujInspekcje;

PROCEDURE FreeSlot
          (     KartBazy : ARRAY OF CHAR;  
            VAR Result   : ARRAY OF CHAR );
VAR
  path : T_NazwaStr;
  i    : CARDINAL;

  PROCEDURE ExistDIR
            ( VAR Dir : ARRAY OF CHAR ) : BOOLEAN;
  VAR
    Tmp : T_NazwaStr;
    ok  : BOOLEAN;
  BEGIN
    GetDir( Tmp );
    ok := CD( Dir );
    IF CD( Tmp ) THEN 
      (* wraca gdzie byl *)
    END;
    RETURN ok;
  END ExistDIR;
  

BEGIN (* FreeSlot *)
  FOR i := 0 TO 999 DO
    sprintf( Result, insp_DirTmp, i );
    Concat(KartBazy, Result, path);
    IF NOT ExistDIR(path) THEN
      RETURN;
    END;
  END;
  InfoBeep( "Przekroczony limit inspekcji.", 15, 555H );
  Terminate( Warning );
END FreeSlot;

PROCEDURE ZnajdzNumInspekcji
          (     KartBazy  : ARRAY OF CHAR;
                NazwaInsp : ARRAY OF CHAR ): CARDINAL;
VAR
  BazaInspekcji: T_NazwaStr;
  str          : T_NazwaStr;
  ile          : INTEGER;
  idx          : INTEGER;
  ok           : BOOLEAN;
  
BEGIN
  Concat(KartBazy, NazwaPlikuIni, BazaInspekcji);
  GetPrivateProfileString(LISTA, "Ilosc", "0", str, BazaInspekcji);
  StringToInt(str, ile, ok);
  IF (NOT ok) OR (ile = 0)
  THEN
    RETURN NilValC;
  END (* if *);
  FOR idx := 0 TO ile - 1 DO
    sprintf(str, OblotTmp, idx);
    GetPrivateProfileString(LISTA, str, "", str, BazaInspekcji);
    IF CompareStr(NazwaInsp, str) = 0  THEN
      RETURN idx;
    END (* IF *);
  END (* FOR idx := 0 *);
  RETURN NilValC;
END ZnajdzNumInspekcji;

PROCEDURE ZnajdzInspekcje
          (     KartBazy  : ARRAY OF CHAR;
                NazwaInsp : ARRAY OF CHAR ): BOOLEAN;
BEGIN
  RETURN ZnajdzNumInspekcji(KartBazy, NazwaInsp) < NilValC;
END ZnajdzInspekcje;

PROCEDURE InspekcjeNowyWpis
          (     KartBazy            : ARRAY OF CHAR;
                NazwaInsp           : ARRAY OF CHAR;
            VAR SzczegOpisInspekcji : ARRAY OF CHAR;
                DopisacNazwePliku   : BOOLEAN ): BOOLEAN;
VAR
  BazaInspekcji: T_NazwaStr;
  ile          : INTEGER;
  ileStr       : ARRAY[0.. 3] OF CHAR;
  OblotId      : ARRAY[0.. 8] OF CHAR;
  DirID        : ARRAY[0..10] OF CHAR;
  
BEGIN (* InspekcjeNowyWpis *)
  Concat(KartBazy, NazwaPlikuIni, BazaInspekcji);
  ile := IleInspekcji(BazaInspekcji);
  sprintf(OblotId, "Oblot%d", ile);
  FreeSlot( KartBazy,  DirID);
  Concat(KartBazy, DirID, SzczegOpisInspekcji);
  IF NOT MkDir(SzczegOpisInspekcji)
  THEN
    InfoBeep("Problemy z zapisem inicjalizacji !", 10, 800);
    RETURN FALSE;
  END (* if *);
  INC(ile);
  WritePrivateProfileString(LISTA, OblotId, NazwaInsp, BazaInspekcji);
  WritePrivateProfileString(NazwaInsp, "Kartoteka", DirID, BazaInspekcji);
  CardToString(ile, ileStr, 1);
  WritePrivateProfileString(LISTA, "Ilosc", ileStr, BazaInspekcji);
  IF DopisacNazwePliku THEN
    Insert("\", SzczegOpisInspekcji, 0FFFH);
    Insert(NazwaPlikuIni, SzczegOpisInspekcji, 0FFFH);
  END (* IF *);
  RETURN TRUE;
END InspekcjeNowyWpis;

VAR
  SrcDir: T_NazwaStr;
  DstDir: T_NazwaStr;
  
PROCEDURE KopiujPodkartoteke
          (     pkartoteka : ARRAY OF CHAR; 
                fAttrib    : Attributes;
            VAR ok         : BOOLEAN );
VAR
  SrcDirEnd : CARDINAL;
  DstDirEnd : CARDINAL;

PROCEDURE KopiujPlik
          (     file : ARRAY OF CHAR;
            VAR   ok : BOOLEAN );
VAR
  Buffer    : ARRAY[0..BuffSize-1] OF CHAR;
  SrcFile   : File;
  DesFile   : File;
  SrcDirEnd : CARDINAL;
  DstDirEnd : CARDINAL;
  rSize     : CARDINAL;
  
BEGIN
  SrcDirEnd := Length(SrcDir);
  Insert('\',  SrcDir, MAX(CARDINAL));
  Insert(file, SrcDir, MAX(CARDINAL));
  DstDirEnd := Length(DstDir);
  Insert('\',  DstDir, MAX(CARDINAL));
  Insert(file, DstDir, MAX(CARDINAL));

  INC(stat_Files);
  Stat_File_Monitor(SrcDir, stat_Files);

  SrcFile := Open(SrcDir);
  DesFile := Create(DstDir);
  SrcDir[SrcDirEnd] := 0C;
  DstDir[DstDirEnd] := 0C;
  
  IF SrcFile >= 255  THEN
    RETURN;
  END (* IF *);
  IF DesFile >= 255  THEN
    RETURN;
  END (* IF *);
  LOOP 
    IF ReadExt(SrcFile, ADR(Buffer), SIZE(Buffer), rSize) <> 0 THEN
      ok := FALSE;
      RETURN;
    END (* IF *);
    IF NOT Write(DesFile, ADR(Buffer), rSize) THEN
      ok := FALSE;
      RETURN;
    END (* IF *);
    stat_Size := stat_Size + FLOAT(rSize);
    Stat_Size_Monitor(stat_Size);
    IF rSize < SIZE(Buffer) THEN
      EXIT
    END (* IF *);
  END (* loop *);
  Close(SrcFile);
  Close(DesFile);
END KopiujPlik;

BEGIN
  IF pkartoteka[0] = '.' THEN
    RETURN
  END (* IF *);
  IF Subdir IN  fAttrib THEN
    SrcDirEnd := Length(SrcDir);
    Insert('\',        SrcDir, MAX(CARDINAL));
    Insert(pkartoteka, SrcDir, MAX(CARDINAL));

    DstDirEnd := Length(DstDir);
    Insert('\',        DstDir, MAX(CARDINAL));
    Insert(pkartoteka, DstDir, MAX(CARDINAL));

    IF CD(DstDir) OR MkDir(DstDir) THEN
      ok := KopiujKartoteke();
    ELSE
      ok := FALSE;
      RETURN
    END (* IF *);
    SrcDir[SrcDirEnd] := 0C;
    DstDir[DstDirEnd] := 0C;
  ELSE
    KopiujPlik(pkartoteka, ok);
  END (* IF *);
END KopiujPodkartoteke;

PROCEDURE  KopiujKartoteke(): BOOLEAN;
VAR
  nameToQuery: T_NazwaStr;
  
BEGIN
  Assign( SrcDir, nameToQuery);
  Insert( '\',    nameToQuery, MAX(CARDINAL));
  Insert( "*.*",  nameToQuery, MAX(CARDINAL));
  RETURN DirQuery( nameToQuery, Attributes{Subdir}, KopiujPodkartoteke, 
                   FALSE );
END KopiujKartoteke;

PROCEDURE KopiujInspekcje
          (     KartBazyZrodlo  : ARRAY OF CHAR;
                KartBazyDoclwa  : ARRAY OF CHAR;
                NazwaInspekcji  : ARRAY OF CHAR ): BOOLEAN;
VAR
  CurrentDir         : T_NazwaStr;
  KopiujKartotekeRes : BOOLEAN;
  
BEGIN (* KopiujInspekcje *)
  stat_Size            := 0.0;
  stat_Files           := 0;
  IF Length( NazwaInspekcji ) = 0 THEN
    RETURN FALSE;
  END;
  IF NOT SzczegolowyPlikOpisu( KartBazyZrodlo, NazwaInspekcji, SrcDir, 
                               FALSE ) 
  THEN
    RETURN FALSE;
  END (* IF *);
  IF NOT SzczegolowyPlikOpisu( KartBazyDoclwa, NazwaInspekcji, DstDir, 
                               FALSE ) 
  THEN
    IF NOT InspekcjeNowyWpis(KartBazyDoclwa, NazwaInspekcji, DstDir, FALSE)
    THEN
      RETURN FALSE;
    END (* IF *);
  END (* IF *);
  GetDir( CurrentDir );
  IF CD(SrcDir) THEN
    KopiujKartotekeRes := KopiujKartoteke();
  ELSE
    RETURN FALSE;
  END (* IF *);
  IF NOT CD(CurrentDir) THEN
    RETURN FALSE;
  END (* IF *);
  RETURN KopiujKartotekeRes;
END KopiujInspekcje;

PROCEDURE StartInspection
          (   fac: T_InspectionKind);
BEGIN
  CASE fac OF
      Insp_VOR:
      ConstAssign("VOR%d", bd_WpisNazwa);
      ConstAssign("Lista", bd_Sekcja);
      ConstAssign("obloty.ini", NazwaPlikuIni);
      ConstAssign(V_BazaLokalizacji, bd_NazwaPliku);
      ConstAssign("vor\\%03d", insp_DirTmp);

    | Insp_TRS:
      ConstAssign("VOR%d", bd_WpisNazwa);
      ConstAssign("Lista", bd_Sekcja);
      ConstAssign("oblt-TRS.ini", NazwaPlikuIni);
      ConstAssign(V_BazaLokalizacji, bd_NazwaPliku);
      ConstAssign("TRS\\%03d", insp_DirTmp);

    | Insp_LOC:
      ConstAssign("Lotnisko_%d", bd_WpisNazwa);
      ConstAssign("Lotniska", bd_Sekcja);
      ConstAssign("oblt-loc.ini", NazwaPlikuIni); 
      ConstAssign(L_BazaLokalizacji, bd_NazwaPliku);
      ConstAssign("ils\\%03d", insp_DirTmp);

    | Insp_GS:
      ConstAssign("Lotnisko_%d", bd_WpisNazwa);
      ConstAssign("Lotniska", bd_Sekcja);
      ConstAssign("oblt-gs.ini",     NazwaPlikuIni);
      ConstAssign(L_BazaLokalizacji, bd_NazwaPliku);
      ConstAssign("gs\\%03d", insp_DirTmp);

    | Insp_NDB:
      ConstAssign("NDB%d", bd_WpisNazwa);
      ConstAssign("Lista", bd_Sekcja);
      ConstAssign("oblt-ndb.ini", NazwaPlikuIni);
      ConstAssign(N_BazaLokalizacji, bd_NazwaPliku);
      ConstAssign("NDB\\%03d", insp_DirTmp);

    | Insp_VHF:
      ConstAssign("VHF%d", bd_WpisNazwa);
      ConstAssign("Lista", bd_Sekcja);
      ConstAssign("oblt-VHF.ini",    NazwaPlikuIni);
      ConstAssign(H_BazaLokalizacji, bd_NazwaPliku);
      ConstAssign("VHF\\%03d", insp_DirTmp);
  END (* CASE *);
  UstawHomeDir('');
END StartInspection;

PROCEDURE InitListaUrzadzen
          ( VAR listaLokalizacji : HLIST);
VAR
  u               : ARRAY [0..20] OF CHAR;
  ok              : BOOLEAN;
  ile, i          : INTEGER;
    
BEGIN
  GetPrivateProfileString(bd_Sekcja, "Ilosc", "0", u, bd_NazwaPliku);
  StringToInt(u, ile, ok);
  IF NOT ok
  THEN
    ile := 0;
  END (* if *);
  ok := FALSE;
  FOR i := 0 TO ile - 1 DO
    sprintf(u, bd_WpisNazwa, i);
    GetPrivateProfileString(bd_Sekcja, u, 
                            "Blad w bazie !!!", 
                            u, 
                            bd_NazwaPliku);
    DodajDoListy(listaLokalizacji, u);
  END (* for i *);
END InitListaUrzadzen;
  
PROCEDURE Dum_Stat_Size_Monitor
          ( size: REAL);
BEGIN
  
END Dum_Stat_Size_Monitor;

PROCEDURE  Dum_Stat_File_Monitor
           ( file_name  : ARRAY OF CHAR;
             numOfFiles : CARDINAL);
BEGIN

END Dum_Stat_File_Monitor;

BEGIN
  Stat_Size_Monitor    := Dum_Stat_Size_Monitor;
  Stat_File_Monitor    := Dum_Stat_File_Monitor;
  HomeDir              := '';
  HomeDirNazwaPlikuIni := '';
  bd_NazwaPliku        := '';
  bd_Sekcja            := '';
  bd_WpisNazwa         := '';
END Obloty.
