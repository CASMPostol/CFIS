(*.F- *)
(**********************************************************************
|  Title   : Polozenie urzadzenia
|  Author  :
|  System  : LOGITECH MODULA-2/86
|  History :
|  Copyright (C), CAS LODZ POLAND.
|  TEL: 42' 86 58 12, 42' 87 80 44 FAX/TEL: 42' 84 48 40
|
**********************************************************************)
(*.F+ *)

IMPLEMENTATION MODULE POLoze1;

  FROM TypDanych IMPORT
    MainStates, TypUrzadzenia;

  FROM GrafTypes IMPORT
    RECT, AssignRect, MoveRect, WHITE, BLUE, MAGENTA;

  FROM Buttons IMPORT
    Button;

  FROM Ini IMPORT
    GetPrivateProfileString, WritePrivateProfileString;

  FROM NumberConversion IMPORT
    StringToCard, StringToInt, CardToString;

  FROM GList IMPORT
    HLIST, SetNotificationProc, Sortowana, GetSelection, Skasuj, SetSelection,
    DodajDoListy, Idx2Str, SkasujWszystko;

  FROM Dialog IMPORT
    HDLG, EndDialog, TworzDialog, WstawListe, WstawButton, EnableDlg, Go,
    UsunDialog, Redraw, AltF4, WstawInpLine, GetDialogDIBHandle;

  FROM CommonTypes IMPORT
    TimeAndDate, PolozenieGeo,PolozenieBiegunowe, Str40, Str99;

  FROM CommonData IMPORT
    SciezkaOpisuPomiaru, NazwaOblotu, NazwaPlikuOpisu, NazwaUrzadz1;

  FROM Obloty IMPORT
    SkasujOblot, WymienWszystkiePasujace, NazwaPlikuIni, FreeSlot;

  FROM Strings IMPORT
    Length, Insert, CompareStr,Concat;

  FROM HiLevGraf IMPORT
    WrStrXY,Wr2fStrXY;

  FROM StdIO IMPORT
    sprintf5,sprintf4,sprintf3,sprintf2,sprintf;

  FROM HiLevGraf IMPORT
    WrStr, SetPaletteEntry;

  IMPORT
    ShortCuts, MsgBox, PI_PA;

  FROM GrafUtil IMPORT
    Info, InfoBeep;

  FROM Sounds IMPORT
    Sound, NoSound;

  FROM Timer IMPORT
    Wait, TInOneSecond;
  FROM MANAGER IMPORT
    STARTPROCESS;

  FROM RealConversions IMPORT
    StringToReal;

  FROM InpLine IMPORT
    HLINE, GetText, DoNothing;

  FROM SYSTEM IMPORT
    ADDRESS, ADR;

FROM V_Database IMPORT
  LoadVorData1, CurVor1, DOD_KIERUNKI;



  FROM FIO IMPORT
    MkDir;

VAR
  ListaVORow, ListaPomocnicza : HLIST;
  ListaVOR_Ob : HLIST;
  lista :ARRAY [0..15] OF CHAR;
  OstatniOblot : INTEGER;

VAR
  hDlg   : HDLG;
  Identyfikacja,
  OrbBlad,
  PromBlad,
  OrbZasieg,
  OrbZasiegDME,
  PromZasieg,
  PromZasiegDME : RECORD
    A, B : Button;
  END;
  GlowOdb, OdnBlad, OdnOdl : Button;
  LiniaOrbZasi, LiniaOrbBledu : HLINE;
  WykLoty : RECORD
    A, B : HLIST;
  END;
  ListaOblotow,
  ListaUrz_O : HLIST;
  DodajB, UsunB : Button;
  RedrawScr : BOOLEAN;
  IloscDodatkowychPromieni : INTEGER;
  urzadz                   : ARRAY [ 0 .. 15 ] OF CHAR;


PROCEDURE WstawObloty(  );
  VAR
    u,sekcja : ARRAY[0..99] OF CHAR;
    ok : BOOLEAN;
    ile, i : INTEGER;
  BEGIN
    GetPrivateProfileString( lista, "Ilosc", "0", u, NazwaPlikuOpisu );
    StringToInt( u, ile, ok );
    IF NOT ok THEN
      ile := 0;
    END;
    ok := FALSE;
    FOR i := 0 TO ile-1 DO
      sprintf(u,"%d",i);
      Concat( urzadz, u, sekcja );  
      GetPrivateProfileString( lista, sekcja, "", u, NazwaPlikuOpisu );
      DodajDoListy( ListaUrz_O, u );
    END;
END WstawObloty;






PROCEDURE OblotOK( );
VAR
BEGIN
   (*mainState:=InicjacjaMS;  *)
   RETURN;
END OblotOK;







   PROCEDURE  Polozenie(VAR typURZ    :TypUrzadzenia;
                         VAR mainState :MainStates;
                         VAR polozenie :PolozenieGeo;
                         VAR polozebGPS :PolozenieBiegunowe;
                         VAR Czestotliwosc   :INTEGER;
                         VAR Nazwa	:ARRAY OF CHAR
                         ) ;


PROCEDURE ZmienOblot( idx : INTEGER );
VAR
  s,sekcjaZO  : ARRAY [0..119] OF CHAR;
  bufor: ARRAY [0..15] OF CHAR;
  nr : ARRAY [0..5] OF CHAR;
  czestotliwosc  : INTEGER;
  R  : RECT;
  okZO :BOOLEAN;
         polozenie  :PolozenieGeo;
         polozebGPS   : PolozenieBiegunowe;
         Deklinacja : REAL;
         Cal, Set   : CARDINAL;

BEGIN

  IF idx < 0 THEN
    RETURN;
  END;


  IF NOT RedrawScr & (idx = OstatniOblot) THEN
    (*RETURN;*)
  END;
   RedrawScr := FALSE;

    AssignRect( R, 0, 0, 790, 30 );
    Redraw( hDlg, R );


  sprintf(nr,"%d",idx);  (*numer urzadzenia w bazie danych*)
  Concat( urzadz, nr, sekcjaZO );  (*polaczenie nazwy urzadzenia i jego 
                                   numeru*)
  GetPrivateProfileString( lista, sekcjaZO, "", 
                            NazwaOblotu, NazwaPlikuOpisu ); (* pobranie nazwy wlasnej danego 
                                                             urzadzenia*)

  Wr2fStrXY(NazwaOblotu, 300,50, WHITE, BLUE );

  GetPrivateProfileString( NazwaOblotu, "Teodolit.Odleglosc", "",bufor , NazwaPlikuOpisu );
  StringToReal( bufor,polozebGPS.Odleglosc, okZO );
(*  WrStrXY(bufor, 10, 0, WHITE, BLUE );*)
  
  GetPrivateProfileString( NazwaOblotu, "Teodolit.Kat", "",bufor , NazwaPlikuOpisu );
  StringToReal( bufor,polozebGPS.Kat, okZO );
(*  WrStrXY(bufor,  100,0, WHITE, BLUE );*)
  
  GetPrivateProfileString( NazwaOblotu, "Deklinacja", "",bufor , NazwaPlikuOpisu );
  StringToReal( bufor,Deklinacja, okZO );
(*  WrStrXY(bufor, 150,0, WHITE, BLUE );*)

  GetPrivateProfileString( NazwaOblotu, "Szerokosc.Stopnie", "",bufor , NazwaPlikuOpisu );
  StringToInt( bufor,polozenie.Szerokosc.Stopnie, okZO );
(*  WrStrXY(bufor, 200,0, WHITE, BLUE );*)

  GetPrivateProfileString( NazwaOblotu, "Szerokosc.Minuty", "",bufor , NazwaPlikuOpisu );
  StringToCard( bufor,polozenie.Szerokosc.Minuty, okZO );
(*  WrStrXY(bufor, 250,0, WHITE, BLUE );*)
  
  GetPrivateProfileString( NazwaOblotu, "Szerokosc.Setne", "",bufor , NazwaPlikuOpisu );
  StringToCard( bufor,polozenie.Szerokosc.DziesTys, okZO );
(*  WrStrXY(bufor, 300,0, WHITE, BLUE );*)


  GetPrivateProfileString( NazwaOblotu, "Dlugosc.Stopnie", "",bufor , NazwaPlikuOpisu );
  StringToInt( bufor,polozenie.Dlugosc.Stopnie, okZO );
(*  WrStrXY(bufor, 200,0, WHITE, BLUE );*)

  GetPrivateProfileString( NazwaOblotu, "Dlugosc.Minuty", "",bufor , NazwaPlikuOpisu );
  StringToCard( bufor,polozenie.Dlugosc.Minuty, okZO );
(*  WrStrXY(bufor, 250,0, WHITE, BLUE );*)
  
  GetPrivateProfileString( NazwaOblotu, "Dlugosc.Setne", "",bufor , NazwaPlikuOpisu );
  StringToCard( bufor,polozenie.Dlugosc.DziesTys, okZO );
(*  WrStrXY(bufor, 300,0, WHITE, BLUE );*)

  GetPrivateProfileString( NazwaOblotu, "Czestotliwosc", "",bufor , NazwaPlikuOpisu );
  StringToInt( bufor,czestotliwosc, okZO );
   sprintf3( s,
             "Poˆo¾enie = %dø%02d'%02dE,",
              polozenie.Szerokosc.Stopnie,
              polozenie.Szerokosc.Minuty,
              polozenie.Szerokosc.DziesTys);
   WrStrXY( s, 11,11, WHITE, WHITE );
   sprintf3( s," %dø%02d'%02dN,",
              polozenie.Dlugosc.Stopnie,
              polozenie.Dlugosc.Minuty,
              polozenie.Dlugosc.DziesTys);
   WrStrXY( s, 180,11, WHITE, WHITE );
   sprintf2(s,"ë=%3.1lfø,f=%d",
              Deklinacja,
              czestotliwosc);
              (* Teo=%3.1lfø, %3.1lfm,*)
    WrStrXY( s, 270,11, WHITE, WHITE );
 
END ZmienOblot;

PROCEDURE InitOblot( ) ;
CONST
  DX = 56;
  DY = 34;
VAR
  R      : RECT;
  kont,   
  firsTime: BOOLEAN;
  b      : Button;
  s      : ARRAY[0..11] OF CHAR;
  i      : CARDINAL;
BEGIN
  firsTime := TRUE;
  RedrawScr := TRUE;
  i:=0;

  AssignRect( R, 0, 0, 800, 600 );
  hDlg := TworzDialog( R, "insp.dib", FALSE );
  SetPaletteEntry( GetDialogDIBHandle( hDlg ), 2, 127, 127, 255 );



  AssignRect( R, 500, 310, 770, 500 );
  Wr2fStrXY( ' LOKALIZACJE ', 500, 270, WHITE, BLUE );
  ListaUrz_O := WstawListe( hDlg, R, FALSE );
  WstawObloty;
  SetNotificationProc(ListaUrz_O, ZmienOblot );
  
  AssignRect( R, 30, 526, 130, 570 );
  WstawButton( hDlg, R, "OK", 0, ShortCuts.kbAltO, OblotOK, b );

  AssignRect( R, 200, 526, 300, 570 );
  WstawButton( hDlg, R, "KONIEC", 0, ShortCuts.kbAltK, AltF4, b );
  MoveRect( R, 0, 100 );
  WstawButton( hDlg, R, "", -1, ShortCuts.kbEnter, OblotOK, b );
(*  WypelnicListeOblotow( );*)
(*  GetPrivateProfileString( "VOR", "OstatniOblot", "0", s, "pomiar.par" );
  StringToCard( s, i, kont );*)
  IF NOT kont THEN
    i := 0;
  END;
  ZmienOblot( i );
  SetSelection( ListaUrz_O, i );
  RedrawScr := FALSE;

  kont := Go( hDlg );

  UsunDialog( hDlg );
(*   mainState:=UrzadzenieMS;*)
   mainState:=InicjacjaMS;
  
  RETURN;
END InitOblot;

BEGIN
    Info("");
  OstatniOblot := MAX(INTEGER);
  NazwaPlikuOpisu[0] := 0C;
  CASE typURZ OF
          LOC:
           NazwaPlikuOpisu := "lotnlist.ini";
           urzadz:='Lotnisko_';  
           lista:='Lotniska';        
          
          |
          GS:
           NazwaPlikuOpisu := "lotnlist.ini";
           urzadz:='Lotnisko_';          
           lista:='Lotniska';        
          
          |
          VOR:
           NazwaPlikuOpisu := "vorlist.ini";
           urzadz:='VOR';          
           lista:='Lista';        
          
          |
          ADF:
           NazwaPlikuOpisu := "ndblist.ini";
           urzadz:='NDB';          
           lista:='Lista';        
          
          |
          VHF:
           NazwaPlikuOpisu := "vhflist.ini";
           urzadz:='VHF';          
           lista:='Lista';        
           
  END;
  InitOblot;
END Polozenie;

END POLoze1. 




