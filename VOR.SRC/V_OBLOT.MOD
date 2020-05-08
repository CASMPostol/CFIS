(*.F- *)
(**********************************************************************
|  Title   : Obsluga ekranu definiowanie inspekcji i glowny pomiarowy
|  Author  : M.Morawski
|  System  : LOGITECH MODULA-2/86
|  History :
|    25-06-96: M.Postol
|      Blad w InitLot
|    09-22-96 01:14am: M.Morawski
|      Poprawione stado bledow
|   01-26-97 03:52pm: MM
|     Dodany podzielnik w procedurze Zapisz
|   29-03-97: M.Postol
|     procedura Pokaz nie moze miec parametru FFFFH - bo sie wywala w sound.
|     polskie litery
|   08-05-97: M.Postol
|     zmienilem uklad glownego ekranu pomiarowego
|     zmienilem shortcuts dla raportow koncowych
|   06-01-97 03:45pm: MM
|     Program archiwalny zapisuje ustawienia koncowe odniesien
|   06-20-97 06:29pm: MM
|     Jakas dupa (kto wie moze ja ale najpewniej MP) skasowala nie
|     wiedziec czemu odswiezanie gornej lini na ekranie inspekcji
|   09-10-97 06:58pm: MM
|     Poprawilem zachowanie w czasie obslugi selektywnego wyboru inspekcji
|   Rel. 3.0. Mpostol
|     Przenioslem definicje TimeAndDate do modulu Czas
|     Modul nie ustawia zmiennej DME z modulu CommonData.
|     przy wyswielaniu polozenia musza byc 4 cyfry
|   Rel. 3.02. Mpostol
|     Wydzielenie wspolnych definicji dla stacji SODA
|
|  Copyright (C), CAS LODZ POLAND.
|  TEL: 42' 686 25 47
|  mailto: techsupp@cas.com.pl
|  http: www.cas.com.pl
|
**********************************************************************)
(*.F+ *)
IMPLEMENTATION MODULE V_Oblot;

IMPORT
  Dialog, ShortCuts, InpLine, GList, Buttons, Polozenie, V_Database,
  FIO, Mapa, MsgBox, Files;
FROM  PI_PA IMPORT
  PomiarANieArchiwum;
FROM CommonTypes IMPORT
  NadajnikT, GlownyOdbiornikT, OdnDlaPomBleduT, OdnDlaPomOdlT,
  CoMoznaZrobic, Str40;
FROM V_CommonTypes  IMPORT
  ProceduraT, Procedura;
FROM BlockOps IMPORT
  BlockSet;
FROM GrafTypes IMPORT
  RECT, POINT, AssignPoint, AssignRect, MoveRect, WHITE, LT_RED,
  BLUE, GREEN, BLACK, YELLOW, MAGENTA, RED, CYAN;
FROM Messages IMPORT
  Message, NewMessage, Display, Acknowledge, AcknowledgeFirst;
FROM GrafUtil IMPORT
  Info, InfoBeep;
FROM Sounds IMPORT
  Sound, NoSound;
FROM Timer IMPORT
  Wait, TInOneSecond;
FROM NumberConversion IMPORT
  StringToCard, StringToInt, CardToString;
FROM RealConversions IMPORT
  StringToReal;
FROM Strings IMPORT
  Length, Insert, Copy, Delete, Assign, CompareStr, ConstAssign;
FROM CommonData IMPORT
  OdnDlaPomBledu, OdnDlaPomOdl, SciezkaOpisuPomiaru,
  NazwaOblotu,  NazwaUrzadz1, NazwaPlikuOpisu, Nadajnik1, Nadajnik2,
  GlownyOdbiornik, Promien, Orbita, Predkosc, CisnienieOdniesienia;
FROM Terminal IMPORT
  Read;
FROM HiLevGraf IMPORT
  WrStr, SetPaletteEntry, FillRect, Wr2fStrXY;
FROM RTSMain IMPORT
  Terminate, Status;
FROM Ini IMPORT
  GetPrivateProfileString, WritePrivateProfileString;
FROM StdIO IMPORT
  sprintf, sprintf2, sprintf3, sprintf4;
FROM V_Database IMPORT
  LoadVorData1, CurVor1, DOD_KIERUNKI;

FROM CommonTypes IMPORT
  PolozenieGeo, PolozenieBiegunowe;

FROM FIO IMPORT
  CD, MkDir, GetDir, Rename;

FROM MANAGER IMPORT
  Assert, STARTPROCESS;

FROM SYSTEM IMPORT
  ADR, SIZE, ADDRESS;

FROM Tune IMPORT
  TuneVOR, MaxNAV_Chann_Num, Receiver, TuneDMEforVOR;

FROM Obloty IMPORT
  (* PROCEDURE *) Ile, SkasujOblot, 
                  WymienWszystkiePasujace, FreeSlot, StartInspection, 
                  InitListaUrzadzen,
  (* TYPE *) T_InspectionKind,
  (* VAR *) NazwaPlikuIni,
  (* CONST *) KartDomyslna, LISTA, ParamFile, V_BazaLokalizacji;
  
FROM Czas IMPORT
  TimeAndDate, GetTimeAndDate, ConvertToStr;

FROM SwitchCntrl IMPORT
  SwState, SwitchTo;

FROM Kalibracja IMPORT
  DataOstatniejKalibracji;
  
VAR
  hDlg   : Dialog.HDLG;
  Identyfikacja,
  OrbBlad,
  PromBlad,
  OrbZasieg,
  PromZasieg : 
    RECORD
      A, B : Buttons.Button;
    END;
  GlowOdb, OdnBlad, OdnOdl : Buttons.Button;
  LiniaOrbZasi, LiniaOrbBledu : InpLine.HLINE;
    WykLoty : RECORD
      A, B  : GList.HLIST;
    END;
  ListaOblotow,
  ListaVOR_Ob   : GList.HLIST;
  DodajB, UsunB : Buttons.Button;
  LiniaPredkosc : InpLine.HLINE;
  TestUP,                        (* Test urzadzen pomiarowych *)
  Raport,
  Pomiar        : Buttons.Button;
  CisnienieOdn  : InpLine.HLINE;

VAR
  KierunekA, KierunekB : CARDINAL;
VAR
  OstatniOblot : INTEGER;
  IloscDodatkowychPromieni : INTEGER;
  DodPromienie : ARRAY[0..10] OF CARDINAL;
  Redraw : BOOLEAN;

  Uaktualnij : PROC;


PROCEDURE Nic(  );
  BEGIN

  END Nic;

PROCEDURE InitOblot( ) : BOOLEAN;
CONST
  DX = 56;
  DY = 34;
VAR
  R      : RECT;
  kont   : BOOLEAN;
  b      : Buttons.Button;
  s      : ARRAY[0..11] OF CHAR;
  i      : CARDINAL;
BEGIN
  Redraw := TRUE;
  AssignRect( R, 0, 0, 800, 600 );
  IloscDodatkowychPromieni := 0;
  hDlg := Dialog.TworzDialog( R, "insp.dib", FALSE );
  SetPaletteEntry( Dialog.GetDialogDIBHandle( hDlg ), 2, 127, 127, 255 );

  (* Listy dialogowe *)
  Wr2fStrXY( 'NADAJNIK Gù‡WNY', 30, 50, WHITE, BLUE );
  AssignRect( R, 30, 100, 300, 250 );
  WykLoty.A := Dialog.WstawListe( hDlg, R, FALSE );
(*  GList.SetNotificationProc( WykLoty.A, LotyA );*)
  GList.Sortowana( WykLoty.A, TRUE );

  MoveRect( R, 0, 250 );
  Wr2fStrXY( 'NADAJNIK ZAPASOWY', 30, 300, WHITE, BLUE );
  WykLoty.B := Dialog.WstawListe( hDlg, R, FALSE );
(*  GList.SetNotificationProc( WykLoty.B, LotyB );*)
  GList.Sortowana( WykLoty.B, TRUE );

  AssignRect( R, 500, 100, 770, 200 );
  Wr2fStrXY( ' INSPEKCJE ', 500, 50, WHITE, BLUE );
  ListaOblotow := Dialog.WstawListe( hDlg, R, FALSE );
  GList.SetNotificationProc( ListaOblotow, ZmienOblot );
  GList.Sortowana( ListaOblotow, FALSE );

  AssignRect( R, 500, 310, 770, 500 );
  Wr2fStrXY( ' LOKALIZACJE ', 500, 270, WHITE, BLUE );
  ListaVOR_Ob := Dialog.WstawListe( hDlg, R, FALSE );
  GList.SetNotificationProc( ListaVOR_Ob, WymienPasujaceObloty1 );
  ListaVORow := ListaVOR_Ob;
  ListaPomocnicza := ListaOblotow;
  GList.DodajDoListy( ListaVOR_Ob, "* wszystkie *" );
  InitListaUrzadzen(ListaVORow);

  IF PomiarANieArchiwum THEN
    AssignRect( R, 500, 205, 770, 230 );
    Dialog.WstawButton( hDlg, R, "NOWA INSPEKCJA", 0, ShortCuts.kbAltN,
    NowyOblot, b );

    MoveRect( R, 0, R.bottom-R.top+3 );
    Dialog.WstawButton( hDlg, R, "SKASUJ INSPEKCJ®", 0, ShortCuts.kbAltS,
    UsunOblotP, b );
  END;

  AssignRect( R, 30, 526, 130, 570 );
  Dialog.WstawButton( hDlg, R, "OK", 0, ShortCuts.kbAltO, OblotOK, b );

  AssignRect( R, 200, 526, 300, 570 );
  Dialog.WstawButton( hDlg, R, "KONIEC", 0, ShortCuts.kbAltK, Dialog.AltF4, b );
  MoveRect( R, 0, 100 );
  Dialog.WstawButton( hDlg, R, "", -1, ShortCuts.kbEnter, OblotOK, b );

(*  WypelnicListeOblotow( );*)
  GetPrivateProfileString( "VOR", "OstatniOblot", "0", s, ParamFile );
  StringToCard( s, i, kont );
  IF NOT kont THEN
    i := 0;
  END;
  ZmienOblot( i );
  GList.SetSelection( ListaOblotow, i );
  Redraw := FALSE;

  kont := Dialog.Go( hDlg );

  Dialog.UsunDialog( hDlg );
  IF kont & ( NazwaOblotu[0] # 0C ) THEN
    RETURN TRUE;
  END;
  IF NOT kont THEN
    Info( "Zaniechano wyboru" );
  ELSE
    Info( "Inspekcja bez nazwy????" );
  END;
  RETURN FALSE;
  Sound( 300 );
  Wait( 3*TInOneSecond());
  NoSound;
  Terminate( Normal );
END InitOblot;

PROCEDURE OblotOK(  );
VAR
  s : Str40;
  sel : INTEGER;
BEGIN
  sel := GList.GetSelection( ListaOblotow );
  IF sel < 0 THEN
    s[0] := 0C;
  ELSE
    GList.Idx2Str( ListaOblotow, sel, s );
  END;
  IF s[0] = 0C THEN
    Pokaz( "Ale, ale... Oblot musi mieÜ nazw©...", 500 );
    RETURN;
  END;
  CardToString( sel, s, 1 );
  WritePrivateProfileString( "VOR", "OstatniOblot", s, ParamFile );
  Dialog.EndDialog( TRUE );
END OblotOK;

PROCEDURE WymienPasujaceObloty1( idx : INTEGER );
  BEGIN
    (*Redraw := TRUE;*)
    OstatniOblot := -1;
    GList.SkasujWszystko( WykLoty.A );
    GList.SkasujWszystko( WykLoty.B );
    WymienPasujaceObloty( idx );
    ZmienOblot(0);
  END WymienPasujaceObloty1;






PROCEDURE InitLot(  ) : BOOLEAN;
CONST
  DX  = 56;
  DY  = 34;
  DX2 = 300;
VAR
  R1, R2 : RECT;
  kont   : BOOLEAN;
  s : ARRAY [0..31] OF CHAR;

  PROCEDURE InitDefault;
  VAR
    c : CARDINAL;
    ok : BOOLEAN;
  BEGIN
    GetPrivateProfileString( "VOR", "OdnDlaPomBledu", "1", s, ParamFile );
    StringToCard( s, c, ok );
    IF NOT ok THEN
      c := 1;
    END;
    OdnDlaPomBledu := VAL( OdnDlaPomBleduT, c );
    GetPrivateProfileString( "VOR", "OdnDlaPomOdl", "0", s, ParamFile );
    StringToCard( s, c, ok );
    IF NOT ok THEN
      c := 0;
    END;
    OdnDlaPomOdl := VAL( OdnDlaPomOdlT, c );
    GetPrivateProfileString( "VOR", "GlownyOdbiornik", "0", s, ParamFile );
    StringToCard( s, c, ok );
    IF NOT ok THEN
      c := 0;
    END;
    GlownyOdbiornik := VAL( GlownyOdbiornikT, c );
    IF PomiarANieArchiwum THEN
      GetPrivateProfileString( "VOR", "Predkosc", "300", s, ParamFile );
      Predkosc := 100.0;
      InpLine.SetText( LiniaPredkosc, s );
      GetPrivateProfileString( "VOR", "CisnienieOdn", "1013.8", s, ParamFile );
      InpLine.SetText( CisnienieOdn, s );
      IF NOT RealCisnValid( CisnienieOdn, s, TRUE ) THEN
        CisnienieOdniesienia := 1013.8;
        InpLine.SetText( CisnienieOdn, "1013.8" );
      ELSE
        CisnienieOdniesienia := RealVal( CisnienieOdn ); (* MP *)
      END;
    END;
(*
    GetPrivateProfileString( "VOR", "Orb.Zas", "63.3", s, ParamFile );
    InpLine.SetText( LiniaOrbZasi, s );
    IF NOT RealValidOrb( LiniaOrbZasi, s, TRUE ) THEN
      InpLine.SetText( LiniaOrbZasi, "63.3" );
    END;
    GetPrivateProfileString( "VOR", "Orb.Blad", "40.0", s, ParamFile );
    InpLine.SetText( LiniaOrbBledu, s );
    IF NOT RealValidOrb( LiniaOrbBledu, s, TRUE ) THEN
      InpLine.SetText( LiniaOrbBledu, "40.0" );
    END;
*)
  END InitDefault;

VAR
  cancel : Buttons.Button;
BEGIN (* InitLot *)
  Redraw := TRUE;
  AssignRect( R1, 0, 0, 800, 600 );

  IF PomiarANieArchiwum THEN
    hDlg := Dialog.TworzDialog( R1, "vor-tyt.bmp", FALSE );
    (* do uzupelniania list *)
    AssignRect( R1, 610, 180, 680, 210 );
    Dialog.WstawButton( hDlg, R1, "DODAJ", 4, ShortCuts.kbAltJ, DodajP, DodajB );
    MoveRect( R1, 75, 0 );
    Dialog.WstawButton( hDlg, R1, "USU„", 1, ShortCuts.kbAltS, UsunP, UsunB);
  ELSE
    hDlg := Dialog.TworzDialog( R1, "vora-tyt.bmp", FALSE );
  END;

  (* Efekt Polaryzacji *)
  AssignRect( R1, 9, 53, 45, 80 );
  R2 := R1;
  MoveRect( R2, DX, 0 );
  FillRect(R1, YELLOW);
  FillRect(R2, YELLOW);

  (* Orbita Blad *)
  MoveRect( R1, 0, DY );
  MoveRect( R2, 0, DY );
  Dialog.WstawRadioButton( hDlg, R1, "", -1, ShortCuts.kbCtrlR,
                           OrbBladA, OrbBlad.A );
  Dialog.WstawRadioButton( hDlg, R2, "", -1, ShortCuts.kbCtrlA, OrbBladB,
                           OrbBlad.B );

  (* Promien Blad *)
  MoveRect( R1, 0, DY );
  MoveRect( R2, 0, DY );
  Dialog.WstawRadioButton( hDlg, R1, "", -1, ShortCuts.kbCtrlP, PromBladA, PromBlad.A );
  Dialog.WstawRadioButton( hDlg, R2, "", -1, ShortCuts.kbCtrlM, PromBladB, PromBlad.B);

  (* Orbita Zasieg *)
  MoveRect( R1, 0, DY );
  MoveRect( R2, 0, DY );
  Dialog.WstawRadioButton( hDlg, R1, "", -1, ShortCuts.kbCtrlO, OrbZasA,
                           OrbZasieg.A);
  Dialog.WstawRadioButton( hDlg, R2, "", -1, ShortCuts.kbCtrlT,
                           OrbZasB,  OrbZasieg.B);

  (* Orbita Zasieg+DME *)
  MoveRect( R1, 0, DY );
  MoveRect( R2, 0, DY );

  (* Promien Zasieg *)
  Dialog.WstawRadioButton( hDlg, R1, "", -1, ShortCuts.kbCtrlZ, PromZasA,
                           PromZasieg.A );
  Dialog.WstawRadioButton( hDlg, R2, "", -1, ShortCuts.kbCtrlI, PromZasB,
                           PromZasieg.B );

  (* Promien Zasieg+DME *)
  MoveRect( R1, 0, DY );
  MoveRect( R2, 0, DY );
  MoveRect( R1, 0, DY );
  MoveRect( R2, 0, DY );

  (* Glowny odbiornik *)
  MoveRect( R1, 0, DY );
  MoveRect( R2, 0, DY );
  R1.right := R2.right;

  Dialog.WstawButton( hDlg, R1, "", -1, ShortCuts.kbCtrlY, GlowOdbP, GlowOdb);

  (* Odniesienie dla pomiaru bledu *)
  MoveRect( R1, 0, DY );
  Dialog.WstawButton( hDlg, R1, "", -1, ShortCuts.kbCtrlN, OdnBladP, OdnBlad );

  (* Odniesienie dla pomiaru odleglosci *)
  MoveRect( R1, 0, DY );
  Dialog.WstawButton( hDlg, R1, "", -1, ShortCuts.kbCtrlL, OdnOdlP, OdnOdl );

  IF PomiarANieArchiwum THEN
    (* Linia dialogowa dla Orbity bledu *)
    MoveRect( R1, 0, DY );
    Dialog.WstawInpLine( hDlg, R1.left, R1.top, 12, RealValidOrb, WHITE,
                         BLUE, LiniaOrbBledu );

    (* Linia dialogowa dla Orbity zasiegu *)
    MoveRect( R1, 0, DY );
    Dialog.WstawInpLine( hDlg, R1.left, R1.top, 12, RealValidOrb, WHITE, GREEN,
                         LiniaOrbZasi);
  END;
  IF PomiarANieArchiwum THEN
    Dialog.WstawInpLine( hDlg, 650, 260, 12, PredkoscValid, WHITE, CYAN, LiniaPredkosc);
    InpLine.SetText( LiniaPredkosc, "300" );
  END;

  (* Listy dialogowe *)
  R2.top := 48;
  R2.right := 800-10;
  R2.left := R2.right - 200;
  R2.bottom := R2.top + 120;
  R1 := R2;

  WykLoty.B := Dialog.WstawListe( hDlg, R2, FALSE );
  GList.SetNotificationProc( WykLoty.B, LotyB );
  GList.Sortowana( WykLoty.B, TRUE );

  MoveRect( R2, -(R2.right-R2.left+10), 0 );

  WykLoty.A := Dialog.WstawListe( hDlg, R2, FALSE );
  GList.SetNotificationProc( WykLoty.A, LotyA );
  GList.Sortowana( WykLoty.A, TRUE );

  AssignRect( R1, 9, 500-20, DX2+9-5, 527-20 );
  R2 := R1;

  IF PomiarANieArchiwum THEN
    Dialog.WstawButton( hDlg, R1, "POMIAR", -1, ShortCuts.kbEnter,
                        PomiarP, Pomiar );
    MoveRect( R1, DX2, 0 );
    Dialog.WstawButton( hDlg, R1, "TEST", 0, ShortCuts.kbAltT,
                        TestUP_PROC, TestUP);
    MoveRect( R2, 0, DY );
    R1 := R2;
    Dialog.WstawButton( hDlg, R1, "RAPORT", 0, ShortCuts.kbAltR,
                        DaneArch_Raport, Raport );
    MoveRect( R1, DX2, 0 );
    Dialog.WstawButton( hDlg, R1, "WYJóCIE", 0, ShortCuts.kbAltW, Dialog.AltF4,
                        cancel);
  ELSE
    Dialog.WstawButton( hDlg, R1, "DANE STATYCZNE", 6, ShortCuts.kbAltT,
                        DaneArch_Stat, TestUP );

    MoveRect( R1, DX2, 0 );
    Dialog.WstawButton( hDlg, R1, "DANE DYNAMICZNE", 0, ShortCuts.kbEnter,
                        DaneArch_Play, Pomiar );
    MoveRect( R2, 0, DY );
    R1 := R2;
    Dialog.WstawButton( hDlg, R1, "RAPORT", 0, ShortCuts.kbAltR,
                        DaneArch_Raport, Raport );
    MoveRect( R1, DX2, 0 );
    Dialog.WstawButton( hDlg, R1, "WYJóCIE", 0, ShortCuts.kbAltW,
                        Dialog.AltF4, cancel);
    MoveRect( R2, 0, DY );
    R1 := R2;
    Dialog.WstawButton( hDlg, R1, "VOR RAP. KO„COWY", 1, ShortCuts.kbAltO,
                        RaportKoncowy, cancel);
    MoveRect( R1, DX2, 0 );
    Dialog.WstawButton( hDlg, R1, "DME RAP. KO„COWY", 1, ShortCuts.kbAltM,
                        RaportKoncowy_DME, cancel);
  END;

  IF PomiarANieArchiwum THEN
    Dialog.WstawInpLine( hDlg, 650, 220, 12, RealCisnValid, BLACK, LT_RED,
                         CisnienieOdn );
    InpLine.SetText( CisnienieOdn, "1013.8" );
  END;
  CoRobimy := czPomiar;

  InitDefault;
  OdnOdlP;
  OdnBladP;
  GlowOdbP;
  FillData;

  Redraw := FALSE;

  GList.SetSelectionNotf( WykLoty.A, WybranyA );
  GList.SetSelectionNotf( WykLoty.B, WybranyB );

  kont := Dialog.Go( hDlg );
  IF PomiarANieArchiwum THEN
    CisnienieOdniesienia := RealVal( CisnienieOdn );
    sprintf( s, "%2.1lf", CisnienieOdniesienia );
    WritePrivateProfileString( "VOR", "CisnienieOdn", s, ParamFile );
    IF Procedura = pOkragZakres THEN
      Orbita    := TRUNC( RealVal( LiniaOrbZasi ) * 500.0 );
    ELSIF Procedura = pOkragBlad THEN
      Orbita    := TRUNC( RealVal( LiniaOrbBledu ) * 500.0 );
    END;
  END;
  Dialog.UsunDialog( hDlg );
(*
  IF OdnDlaPomOdl=poZadanaPredkosc THEN
    OdVora := TRUE;
  END;
*)
  Mapa.CancelProcess;
  IF NOT kont THEN
    (*
    Info( "Zaniechano wyboru" );
    Sound( 300 );
    Wait( 3*TInOneSecond());
    NoSound;
    Terminate( Stopped );
    *)
  END;
  IF OdnDlaPomBledu = pbnieZdef THEN
    Pokaz( "Jako odniesienie dla pom. bà©du przyj©to GPS", 333 );
    OdnDlaPomBledu := pbGPS;
  END;
  RETURN kont;
END InitLot;


PROCEDURE Wlacz_Wylacz( );
  VAR
    Tmp : ARRAY [0..127] OF CHAR;
    en  : BOOLEAN;
  BEGIN
    SciezkaDoKataloguOpisu();
    Assign( SciezkaOpisuPomiaru, Tmp );
    Tmp[ Length( Tmp ) -1 ] := 0C;
    en := Files.ExistDIR( Tmp );
    IF NOT PomiarANieArchiwum THEN
      Buttons.EnableButton( Pomiar, en );
      Buttons.EnableButton( TestUP, en );
    END;
    Buttons.EnableButton( Raport, en );
  END Wlacz_Wylacz;


PROCEDURE WstawDoListyOblotow( VAR nazwa : ARRAY OF CHAR );
BEGIN
  GList.DodajDoListy( ListaOblotow, nazwa );
END WstawDoListyOblotow;

PROCEDURE TestUP_PROC;
BEGIN
  CoRobimy := czTest;
  ZapisanieDodatkowychPromieni;
  Dialog.EndDialog( TRUE );
END TestUP_PROC;

PROCEDURE DaneArch_Play(  );
  BEGIN
    CoRobimy := czPlay;
    ZapisanieDodatkowychPromieni;
    Dialog.EndDialog( TRUE );
  END DaneArch_Play;

PROCEDURE DaneArch_Stat(  );
  BEGIN
    CoRobimy := czPreview;
    ZapisanieDodatkowychPromieni;
    Dialog.EndDialog( TRUE );
  END DaneArch_Stat;

PROCEDURE DaneArch_Raport(  );
  BEGIN
    CoRobimy := czDrukR;
    ZapisanieDodatkowychPromieni;
    Dialog.EndDialog( TRUE );
  END DaneArch_Raport;

PROCEDURE RaportKoncowy(  );
  BEGIN
    CoRobimy := czRaportKoncowy;
    ZapisanieDodatkowychPromieni;
    Dialog.EndDialog( TRUE );
  END RaportKoncowy;

PROCEDURE RaportKoncowy_DME(  );
  BEGIN
    CoRobimy := czRaportKoncowy_DME;
    ZapisanieDodatkowychPromieni;
    Dialog.EndDialog( TRUE );
  END RaportKoncowy_DME;

PROCEDURE RealVal( l : InpLine.HLINE ) : REAL;
VAR
  s : ARRAY[0..99] OF CHAR;
  r : REAL;
  ok : BOOLEAN;
BEGIN
  InpLine.GetText( l, s );
  StringToReal( s, r, ok );
  Assert( ok );
  RETURN r;
END RealVal;

PROCEDURE CardVal( l : GList.HLIST ) : CARDINAL;
VAR
  s : ARRAY[0..99] OF CHAR;
  c : CARDINAL;
  ok : BOOLEAN;
BEGIN
  GList.Idx2Str( l, GList.GetSelection( l ), s );
  s[3] := 0C;
  StringToCard( s, c, ok );
  Assert( ok );
  RETURN c;
END CardVal;

PROCEDURE ToOrbita( On : BOOLEAN );
BEGIN
(*
  IF On THEN
    IF (OdnDlaPomBledu = pbTeodolit) THEN
      OdnBladP;
      InfoBeep( "Odniesienie dla pomiaru bà©du zmienione na GPS", 1, 300 );
    END;
    Buttons.EnableButton( OdnBlad, FALSE );
  ELSE
    Buttons.EnableButton( OdnBlad, TRUE );
  END;
*)
END ToOrbita;

PROCEDURE OrbBladA;
BEGIN
  Procedura := pOkragBlad;
  Nadajnik1  := nA;
(*
  IF PomiarANieArchiwum THEN
    Orbita    := TRUNC( RealVal( LiniaOrbBledu ) * 500.0 );
  END;
*)
  ZapisanieDodatkowychPromieni;
  ToOrbita( TRUE );
  Uaktualnij := OrbBladA;
  Wlacz_Wylacz();
END OrbBladA;

PROCEDURE OrbBladB;
BEGIN
  Procedura := pOkragBlad;
  Nadajnik1  := nB;
(*
  IF PomiarANieArchiwum THEN
    Orbita    := TRUNC( RealVal( LiniaOrbBledu ) * 500.0 );
  END;
*)
  ZapisanieDodatkowychPromieni;
  ToOrbita( TRUE );
  Uaktualnij := OrbBladB;
  Wlacz_Wylacz();
END OrbBladB;

PROCEDURE PromBladA;
BEGIN
  Procedura := pPromienBlad;
  Nadajnik1  := nA;
  Promien   := CardVal( WykLoty.A );
  ZapisanieDodatkowychPromieni;
  ToOrbita( FALSE );
  Uaktualnij := Nic;
  UstawPromienie( WykLoty.A );
  Wlacz_Wylacz();
END PromBladA;

PROCEDURE PromBladB;
BEGIN
  Procedura := pPromienBlad;
  Nadajnik1  := nB;
  Promien   := CardVal( WykLoty.B );
  ZapisanieDodatkowychPromieni;
  ToOrbita( FALSE );
  Uaktualnij := Nic;
  UstawPromienie( WykLoty.B );
  Wlacz_Wylacz();
END PromBladB;

PROCEDURE OrbZasA;
BEGIN
  Procedura := pOkragZakres;
  Nadajnik1  := nA;
  IF PomiarANieArchiwum THEN
    Orbita    := TRUNC( RealVal( LiniaOrbZasi ) * 500.0 );
  END;
  ZapisanieDodatkowychPromieni;
  ToOrbita( TRUE );
  Uaktualnij := OrbZasA;
  Wlacz_Wylacz();
END OrbZasA;

PROCEDURE OrbZasB;
BEGIN
  Procedura := pOkragZakres;
  Nadajnik1  := nB;
  IF PomiarANieArchiwum THEN
    Orbita    := TRUNC( RealVal( LiniaOrbZasi ) * 500.0 );
  END;
  ZapisanieDodatkowychPromieni;
  ToOrbita( TRUE );
  Uaktualnij := OrbZasB;
  Wlacz_Wylacz();
END OrbZasB;

PROCEDURE PromZasA;
BEGIN
  Procedura := pPromienZakres;
  Nadajnik1  := nA;
  Promien   := CardVal( WykLoty.A );
  ZapisanieDodatkowychPromieni;
  ToOrbita( FALSE );
  Uaktualnij := Nic;
  UstawPromienie( WykLoty.A );
  Wlacz_Wylacz();
END PromZasA;

PROCEDURE PromZasB;
BEGIN
  Procedura := pPromienZakres;
  Nadajnik1  := nB;
  Promien   := CardVal( WykLoty.B );
  ZapisanieDodatkowychPromieni;
  ToOrbita( FALSE );
  Uaktualnij := Nic;
  UstawPromienie( WykLoty.B );
  Wlacz_Wylacz();
END PromZasB;

PROCEDURE PomiarP(  );
VAR
  idx : INTEGER;
BEGIN
  IF Nadajnik1 = nA THEN
    Promien   := CardVal( WykLoty.A );
  ELSE
    Promien   := CardVal( WykLoty.B );
  END;
(*  Orbita    := RealVal( LiniaOrbBledu );*)
  ZapisanieDodatkowychPromieni;
  CoRobimy := czPomiar;
  Dialog.EndDialog( TRUE );
END PomiarP;

PROCEDURE GlowOdbP;
VAR
  i : CARDINAL;
BEGIN
  i := ORD( GlownyOdbiornik );
  IF NOT Redraw THEN
    i := (i+1) MOD (ORD(MAX( GlownyOdbiornikT ))+1);
    GlownyOdbiornik := VAL( GlownyOdbiornikT, i );
  END;
  CASE i OF
    0 : Buttons.ChangeButton( GlowOdb, "Odb. `A'", -1 );
  | 1 : Buttons.ChangeButton( GlowOdb, "Odb. `B'", -1 );
  END;
END GlowOdbP;

PROCEDURE OdnBladP;
BEGIN
  IF NOT Redraw THEN
    IF OdnDlaPomBledu = pbGPS  THEN
      OdnDlaPomBledu := pbTeodolit;
    ELSE
      OdnDlaPomBledu := pbGPS;
    END;
  END;
  CASE OdnDlaPomBledu OF
    pbnieZdef  : Buttons.ChangeButton( OdnBlad, "-------", -1 );
  | pbTeodolit : Buttons.ChangeButton( OdnBlad, "Teodolit", -1 );
  | pbGPS      : Buttons.ChangeButton( OdnBlad, "GPS", -1 );
  END;
END OdnBladP;


PROCEDURE UstawPredkosc( VAR s : ARRAY OF CHAR );
VAR
  ok : BOOLEAN;
BEGIN
  StringToReal( s, Predkosc, ok );
  IF NOT ok THEN
    Pokaz( "Musi byÜ podana sensowna pr©dkoòÜ", 800 );
    Predkosc := 0.0; (* tzn. ´le *)
  ELSIF Predkosc <= 0.0 THEN
    Pokaz( "Pr©dkoòÜ musi byÜ liczb• dodatni•", 800 );
    Predkosc := 0.0;
  END;
END UstawPredkosc;

PROCEDURE PodajPredkosc;
VAR
  s : ARRAY[0..99] OF CHAR;
BEGIN
  IF PomiarANieArchiwum THEN
    InpLine.GetText( LiniaPredkosc, s );
    UstawPredkosc( s );
  END;
END PodajPredkosc;

PROCEDURE PredkoscValid( l : InpLine.HLINE; VAR s : ARRAY OF CHAR; KillFocus : BOOLEAN ) : BOOLEAN;
BEGIN
  UstawPredkosc(s);
  IF KillFocus & ( Predkosc <= 50.0 ) THEN
    Pokaz( "Pr©dkoòÜ musi byc wi©ksza niæ 50 w©zà¢w", 800 );
    RETURN FALSE;
  END;
  RETURN TRUE;
END PredkoscValid;

PROCEDURE OdnOdlP;
VAR
  i : CARDINAL;
BEGIN
  i := ORD( OdnDlaPomOdl );
  IF NOT Redraw THEN
    i := (i+1) MOD (ORD(MAX( OdnDlaPomOdlT ))+1);
    IF i = ORD(MAX( OdnDlaPomOdlT )) THEN
      PodajPredkosc;
      IF (Predkosc <= 0.0) OR ( Predkosc > 1000.0 ) THEN
        Pokaz( "Zla pr©dkoòÜ!", 1000 );
        i := 2;
      END;
    END;
    OdnDlaPomOdl := VAL( OdnDlaPomOdlT, i );
  END;
  CASE i OF
    0 : Buttons.ChangeButton( OdnOdl, "DME A", -1 );
  | 1 : Buttons.ChangeButton( OdnOdl, "DME B", -1 );
  | 2 : Buttons.ChangeButton( OdnOdl, "GPS", -1 );
  | 3 : Buttons.ChangeButton( OdnOdl, "Pr©dkoòÜ", -1 );
  END;
END OdnOdlP;

PROCEDURE RealValidOrb(     l         : InpLine.HLINE;
	                VAR s         : ARRAY OF CHAR;
										  KillFocus : BOOLEAN ) : BOOLEAN;
VAR
  r : REAL;
  ok : BOOLEAN;
  i  : ARRAY[0..99] OF CHAR;
BEGIN
  IF KillFocus THEN
    StringToReal( s, r, ok );
    IF NOT ok THEN
      i := "Napis nie jest liczb• rzeczywist•" ;
    ELSIF ((r < 1.0) OR ( r > 70.0)) THEN
      i := "Wprowadzona liczba jest zbyt duæa lub zbyt maàa" ;
      ok := FALSE;
    END;
    IF NOT ok THEN
      Pokaz(i, 5000 );
    ELSE
      Uaktualnij;
    END;
    RETURN ok;
  ELSE
    RETURN TRUE;
  END;
END RealValidOrb;

PROCEDURE RealCisnValid( l : InpLine.HLINE; VAR s : ARRAY OF CHAR; KillFocus : BOOLEAN ) : BOOLEAN;
VAR
  r : REAL;
  ok : BOOLEAN;
  i  : ARRAY[0..99] OF CHAR;
BEGIN
  IF KillFocus THEN
    StringToReal( s, r, ok );
    IF NOT ok THEN
      i := "Napis nie jest liczba rzeczywist•" ;
    ELSIF KillFocus &((r < 700.0) OR ( r > 1200.0)) THEN
      i := "Wprowadzona liczba jest zbyt duæa lub zbyt maàa" ;
      ok := FALSE;
    END;
    IF NOT ok THEN
      Pokaz(i, 5000 );
    END;
    RETURN ok;
  ELSE
    RETURN TRUE;
  END;
END RealCisnValid;

PROCEDURE LotyA( idx : INTEGER );
VAR
  s : ARRAY[0..20] OF CHAR;
  ok : BOOLEAN;
BEGIN
  IF ( idx < 0 ) THEN
    RETURN;
  END;
  IF NOT Redraw THEN
    WybranyA := idx;
  END;
  GList.Idx2Str( WykLoty.A, idx, s );
  s[3] := 0C;
  StringToCard( s, KierunekA, ok );
  Promien := KierunekA;
  Assert( ok );
(*
  IF (Nadajnik1 = nB) THEN
    ZmienNadajnik;
  ELSE
    UstawPromienie;
  END;
*)
  UstawPromienie( WykLoty.A );
  Wlacz_Wylacz;
END LotyA;

PROCEDURE LotyB( idx : INTEGER );
VAR
  s : ARRAY[0..20] OF CHAR;
  ok : BOOLEAN;
BEGIN
  IF ( idx < 0 ) THEN
    RETURN;
  END;
  IF NOT Redraw THEN
    WybranyB := idx;
  END;
  GList.Idx2Str( WykLoty.B, idx, s );
  s[3] := 0C;
  StringToCard( s, KierunekB, ok );
  Promien := KierunekB;
  Assert( ok );
(*
  IF (Nadajnik1 = nA) THEN
    ZmienNadajnik;
  ELSE
    UstawPromienie;
  END;
*)
  UstawPromienie( WykLoty.B );
  Wlacz_Wylacz;
END LotyB;


PROCEDURE NowaLista( Zawartosc : GList.HLIST;
                     suffix    : CHAR;
                     Full      : BOOLEAN;
                     FirstTime : BOOLEAN ) : BOOLEAN;
VAR
  i, j, k, IleObl : INTEGER;
  Tabl : ARRAY[0..V_Database.IleKierunkow-1] OF INTEGER;
  ok, Wszystkie : BOOLEAN;
  w : RECORD
    c : CHAR;
    i : INTEGER;
  END;
  KtoreLeciane : ARRAY[0..V_Database.IleKierunkow-1] OF BOOLEAN;
  s1 : ARRAY[0..5] OF CHAR;
  s  : ARRAY[0..41] OF CHAR;
BEGIN
  FOR i := 0 TO HIGH(KtoreLeciane) DO
    KtoreLeciane[i] := FALSE;
  END;
  LoadVorData1( NazwaUrzadz1, NazwaPlikuOpisu );
  i := -1;
  BlockSet( ADR( Tabl ), SIZE( Tabl ), ADR( i ), SIZE( i ));
  FOR i := 0 TO CurVor1.IleKierunkow-1 DO
    Tabl[i] := CurVor1.Kierunki[i];
  END;

  (* dopisac zdefiniowane *)

  GList.SkasujWszystko( Zawartosc );
  sprintf( s, "IloscLotow.%c", suffix );
  GetPrivateProfileString( NazwaOblotu, s, "0", s, NazwaPlikuOpisu );
  StringToInt( s, IleObl, ok );
  IF NOT ok THEN
    IleObl := 0;
  END;
(*
  IF NOT ok OR ( IleObl = 0 ) THEN
    InfoBeep( "Nie ma listy inspekcji", 5, 1000 );
    Dialog.EndDialog( FALSE ); (* koniec ! *)
    RETURN FALSE;
  END;
*)
  FOR j := 0 TO IleObl-1 DO
    w.c := suffix;
    w.i := j;
    sprintf( s, "Promien.%c.%d", w );
    GetPrivateProfileString( NazwaOblotu, s, "", s, NazwaPlikuOpisu );
    Copy( s, 0, 3, s1 );
    StringToInt( s1, k, ok );
    Assert( ok );
    FOR i := 0 TO CurVor1.IleKierunkow-1 DO
      IF Tabl[i] = k THEN
        Tabl[i] := -1;
      END;
    END;
    FOR i := 0 TO CurVor1.IleKierunkowDodatkowych-1 DO
      IF CurVor1.KierunkiDodatkowe[i] = ORD(k) THEN
        KtoreLeciane[i] := TRUE;
      END;
    END;
    IF NOT Full THEN
      s[14] := 0C;
    END;
    GList.DodajDoListy( Zawartosc, s );
  END;
  Wszystkie := TRUE;
  FOR i := 0 TO CurVor1.IleKierunkow-1 DO
    IF Tabl[i] # -1 THEN
      sprintf( s, "%03d¯", Tabl[i] );
      GList.DodajDoListy( Zawartosc, s );
      Wszystkie := FALSE;
    END;
  END;
  IF FirstTime THEN
    FOR i := 0 TO CurVor1.IleKierunkowDodatkowych-1 DO
      FOR j := 0 TO HIGH( Tabl ) DO
        ok := TRUE;
        IF CurVor1.KierunkiDodatkowe[i] = CARDINAL(Tabl[j]) THEN
          ok := FALSE;
        END;
      END;
      IF ok THEN
        DodPromienie[IloscDodatkowychPromieni] := CurVor1.KierunkiDodatkowe[i];
        INC( IloscDodatkowychPromieni );
      END;
    END;
  END;
  (* trzeba jeszcze dodac te zdefiniowane *)
  FOR i := 0 TO IloscDodatkowychPromieni-1 DO
    IF NOT KtoreLeciane[i] THEN
      sprintf( s, "%03d¯(*)", DodPromienie[i] );
      GList.DodajDoListy( Zawartosc, s );
    END;
  END;
  RETURN Wszystkie;
END NowaLista;

PROCEDURE FillData;

  PROCEDURE UsunSpacje( VAR s : ARRAY OF CHAR );
  BEGIN
    WHILE (s[0] # 0C) & (s[0] = ' ') DO
      Delete( s, 0, 1 );
    END;
  END UsunSpacje;

VAR
  s,l: ARRAY [0..99] OF CHAR;
  i  : CARDINAL;
  j, k : CARDINAL;
  R  : RECT;
  ok : BOOLEAN;
  a  : ADDRESS;
BEGIN
  Mapa.StartProcess;
(*  IloscDodatkowychPromieni := 0;*)

  GetPrivateProfileString( NazwaOblotu, "Kartoteka", ".\", NazwaPlikuOpisu, "obloty.ini" );

  IF NazwaPlikuOpisu[Length(NazwaPlikuOpisu)-1] # '\' THEN
    Insert( "\", NazwaPlikuOpisu, 0FFFH );
  END;
  Insert( "obloty.ini", NazwaPlikuOpisu, 0FFFH );

  GetPrivateProfileString( NazwaOblotu, "Nazwa", "", NazwaUrzadz1, NazwaPlikuOpisu );

(*

  AssignRect( R, 10, 430, 200, 500 );
  Dialog.Redraw( hDlg, R );
  Wr2fStrXY( NazwaUrzadz1, 435, 354, RED, RED );
*)

  i := CurVor1.Czestotliwosc;
  j := i DIV 100;
  k := i MOD 100;
  a := ADR( NazwaUrzadz1 );
  sprintf3( s, "%s(%d.%02d MHz)", a, j, k );
  TuneVOR( AReceiver, i );
  TuneVOR( BReceiver, i );
  TuneDMEforVOR( AReceiver, i );
  TuneDMEforVOR( BReceiver, i );
  IF PomiarANieArchiwum THEN
    SwitchTo(Antena);
  END;

(*  Wr2fStrXY( s, 350, 453, BLACK, BLACK );*)
(*
  AssignRect( R, 10, 430, 200, 500 );
  Dialog.Redraw( hDlg, R );
*)
  Wr2fStrXY( s, 435, 354, RED, RED );


  GetPrivateProfileString( NazwaOblotu, "EfektPolaryzacji.A", "", s, NazwaPlikuOpisu );
  IF s[0] = '1' THEN
    s := "˚";
  ELSE
    s := "-";
  END;
  WrStr( s, 10+10, 44+15, BLACK, YELLOW );

  GetPrivateProfileString( NazwaOblotu, "EfektPolaryzacji.B", "", s, NazwaPlikuOpisu );
  IF s[0] = '1' THEN
    s := "˚";
  ELSE
    s := "-";
  END;
  WrStr( s, 10+10+58, 44+15, BLACK, YELLOW );

  GetPrivateProfileString( NazwaOblotu, "OrbitaRozkladBledu.A", "@@", s, NazwaPlikuOpisu );
  IF s[0] = "@" THEN
    Buttons.ChangeButton( OrbBlad.A, "-", -1 );
    GetPrivateProfileString( NazwaOblotu, "OrbitaRozkladBledu.B", "@@", s,
                             NazwaPlikuOpisu );
    IF s[0] = '@' THEN
      sprintf( s, "%4.2lf", CurVor1.OrbitaBlad );
    END;
  ELSE
    Buttons.ChangeButton( OrbBlad.A, "˚", -1 );
  END;
  UsunSpacje( s );
  StripSPC( s );
  IF PomiarANieArchiwum THEN
    InpLine.SetText( LiniaOrbBledu, s );
  END;

  GetPrivateProfileString( NazwaOblotu, "OrbitaRozkladBledu.B", "@@", s, NazwaPlikuOpisu );
  IF s[0] = "@" THEN
    Buttons.ChangeButton( OrbBlad.B, "-", -1 );
  ELSE
    Buttons.ChangeButton( OrbBlad.B, "˚", -1 );
  END;

  GetPrivateProfileString( NazwaOblotu, "Orbita.Zasieg.A", "@@", s, NazwaPlikuOpisu );
  IF s[0] = "@" THEN
    Buttons.ChangeButton( OrbZasieg.A, "-", -1 );
    GetPrivateProfileString( NazwaOblotu, "Orbita.Zasieg.B", "@@", s, NazwaPlikuOpisu );
    IF s[0] = '@' THEN
      sprintf( s, "%4.2lf", CurVor1.OrbitaZasieg );
    END;
  ELSE
    Buttons.ChangeButton( OrbZasieg.A, "˚", -1 );
    GetPrivateProfileString( NazwaOblotu, "Orbita.Zasieg.A", "@@", s, NazwaPlikuOpisu );
  END;
  UsunSpacje(s);
  StripSPC( s );
  IF PomiarANieArchiwum THEN
    InpLine.SetText( LiniaOrbZasi, s );
  END;

  GetPrivateProfileString( NazwaOblotu, "Orbita.Zasieg.B", "@@", s, NazwaPlikuOpisu );
  IF s[0] = "@" THEN
    Buttons.ChangeButton( OrbZasieg.B, "-", -1 );
  ELSE
    Buttons.ChangeButton( OrbZasieg.B, "˚", -1 );
  END;

  IF NOT NowaLista( WykLoty.A, "A", FALSE, FALSE ) THEN
    Buttons.ChangeButton( PromBlad.A, "-", -1 );
  ELSE
    Buttons.ChangeButton( PromBlad.A, "˚", -1 );
  END;

  IF NOT NowaLista( WykLoty.B, "B", FALSE, FALSE ) THEN
    Buttons.ChangeButton( PromBlad.B, "-", -1 );
  ELSE
    Buttons.ChangeButton( PromBlad.B, "˚", -1 );
  END;

  IF NOT WykonanoWszystkiePromienie( pPromienZakres, goA ) THEN
    Buttons.ChangeButton( PromZasieg.A, "-", -1 );
  ELSE
    Buttons.ChangeButton( PromZasieg.A, "˚", -1 );
  END;

  IF NOT WykonanoWszystkiePromienie( pPromienZakres, goB ) THEN
    Buttons.ChangeButton( PromZasieg.B, "-", -1 );
  ELSE
    Buttons.ChangeButton( PromZasieg.B, "˚", -1 );
  END;
  UstawPromienie( WykLoty.A );
END FillData;

PROCEDURE ZapisanieDodatkowychPromieni(  );
VAR
  s, l : ARRAY[0..99] OF CHAR;
  i    : INTEGER;
BEGIN
  i := ORD( OdnDlaPomBledu );
  sprintf( s, "%d", i );
  WritePrivateProfileString( "VOR", "OdnDlaPomBledu", s, ParamFile );
  i := ORD( OdnDlaPomOdl );
  sprintf( s, "%d", i );
  WritePrivateProfileString( "VOR", "OdnDlaPomOdl", s, ParamFile );
  i := ORD( GlownyOdbiornik );
  sprintf( s, "%d", i );
  WritePrivateProfileString( "VOR", "GlownyOdbiornik", s, ParamFile );
  IF PomiarANieArchiwum THEN
    sprintf( s, "%d", IloscDodatkowychPromieni );
    WritePrivateProfileString( DOD_KIERUNKI, "Ilosc", s, NazwaPlikuOpisu );
    FOR i := 0 TO IloscDodatkowychPromieni-1 DO
      sprintf( l, "Kierunek%d", i );
      sprintf( s, "%d", DodPromienie[i] );
      WritePrivateProfileString( DOD_KIERUNKI, l, s, NazwaPlikuOpisu );
    END;

    sprintf( s, "%3.1lf", Predkosc );
    WritePrivateProfileString( "VOR", "Predkosc", s, ParamFile );
    sprintf( s, "%3.1lf", CisnienieOdniesienia );
    WritePrivateProfileString( "VOR", "CisnienieOdn", s, ParamFile );
    InpLine.GetText( LiniaOrbZasi, s );
    WritePrivateProfileString( "VOR", "Orb.Zas", s, ParamFile );
    InpLine.GetText( LiniaOrbBledu, s );
    WritePrivateProfileString( "VOR", "Orb.Blad", s, ParamFile );
  END;
END ZapisanieDodatkowychPromieni;

PROCEDURE ZmienOblot( idx : INTEGER );
VAR
  s  : ARRAY [0..119] OF CHAR;
  i  : INTEGER;
  R  : RECT;
  ff : RECORD
         Polozenie  : PolozenieGeo;
         Teodolit   : PolozenieBiegunowe;
         Deklinacja : REAL;
         Cal, Set   : CARDINAL;
       END;

BEGIN
  IF idx < 0 THEN
    GList.SkasujWszystko( WykLoty.A );
    GList.SkasujWszystko( WykLoty.B );
    RETURN;
  END;

  IF NOT Redraw & (idx = OstatniOblot) THEN
    RETURN;
  END;
  Redraw := FALSE;

  AssignRect( R, 300, 50, 500, 97 );
  Dialog.Redraw( hDlg, R );
  AssignRect( R, 0, 0, 790, 30 );
  Dialog.Redraw( hDlg, R );

  IF idx # OstatniOblot THEN
(*    ZapisanieDodatkowychPromieni;*)
    IloscDodatkowychPromieni := 0;
  END;

  OstatniOblot := idx;
  GList.Idx2Str( ListaOblotow, idx, NazwaOblotu );
  GetPrivateProfileString( NazwaOblotu, "Kartoteka", ".\", NazwaPlikuOpisu, "obloty.ini" );

  IF NazwaPlikuOpisu[Length(NazwaPlikuOpisu)-1] # '\' THEN
    Insert( "\", NazwaPlikuOpisu, 0FFFH );
  END;
  Insert( "obloty.ini", NazwaPlikuOpisu, 0FFFH );

  GetPrivateProfileString( NazwaOblotu, "Nazwa", "", NazwaUrzadz1, NazwaPlikuOpisu );

  IF NazwaUrzadz1[0] = 0C THEN
    RETURN;
  END;
  LoadVorData1( NazwaUrzadz1, NazwaPlikuOpisu );

  Wr2fStrXY( NazwaUrzadz1, 300, 50, WHITE, BLUE );

  IF NazwaUrzadz1[0] # 0C THEN
    i := CurVor1.Czestotliwosc;
    ff.Polozenie  := CurVor1.Polozenie;
    ff.Teodolit   := CurVor1.Teodolit;
    ff.Teodolit.Odleglosc := ff.Teodolit.Odleglosc * 1852.0;
    ff.Deklinacja := CurVor1.Deklinacja;
    ff.Cal        := CurVor1.Czestotliwosc DIV 100;
    ff.Set        := CurVor1.Czestotliwosc MOD 100;
    sprintf( s,
             "Poàoæenie = %d¯%02d'%04dE, %d¯%02d'%04dN, Teo=%3.1lf¯, %3.1lfm, Î=%3.1lf¯, f=%d.%02dMHz",
             ff );
    WrStr( s, 11,11, WHITE, WHITE );
  ELSE
    WrStr(
      "Polozenie =  ¯  '  N, ¯  '  E, Teo=   ¯,    m, Î=   f¯, f=    .  MHz"
            , 11,11, WHITE, WHITE );
  END;

  IF NOT NowaLista( WykLoty.A, "A", TRUE, TRUE ) THEN
  END;
  IF NOT NowaLista( WykLoty.B, "B", TRUE, FALSE ) THEN
  END;
END ZmienOblot;

PROCEDURE StripSPC( VAR a : ARRAY OF CHAR );
VAR
  i : CARDINAL;
BEGIN
  FOR i := 0 TO HIGH(a) DO
    IF (a[i] = 0C) THEN
      RETURN;
    END;
    IF (a[i] = ' ') THEN
      a[i] := 0C;
      RETURN;
    END;
  END;
END StripSPC;


PROCEDURE UstawPromienie( Lista : GList.HLIST );
VAR
  Do, Wyk : ARRAY [0..30] OF CARDINAL;
  i, di, wi : INTEGER;
  s, s1 : ARRAY[0..30] OF CHAR;
  ok : BOOLEAN;
  c : CARDINAL;
BEGIN
  i := -1;
  BlockSet( ADR( Do ), SIZE( Do ), ADR( i ), SIZE( i ));
  Wyk := Do;
  di := 0;
  wi := 0;
  i := -1;
  LOOP
    INC( i );
    GList.Idx2Str( Lista, i, s );
    IF s[0] = 0C THEN
      EXIT;
    END;
    Copy( s, 0, 3, s1 );
    StringToCard( s1, c, ok );
    Assert( ok );
    IF Length( s ) > 8 THEN
      Wyk[wi] := c;
      INC( wi );
    ELSE
      Do[di] := c;
      INC( di );
    END;
  END;
  IF (Procedura < pPromienBlad) THEN (* orbita *)
    Mapa.Promienie( Do, Wyk, 0FFFFH );
  ELSIF Nadajnik1 = nA THEN
    Mapa.Promienie( Do, Wyk, KierunekA );
  ELSE
    Mapa.Promienie( Do, Wyk, KierunekB );
  END;
END UstawPromienie;




PROCEDURE CardValid( l : InpLine.HLINE; VAR s : ARRAY OF CHAR; KillFocus : BOOLEAN ) : BOOLEAN;
VAR
  c : CARDINAL;
  ok : BOOLEAN;
  s1 : ARRAY[0..99] OF CHAR;
BEGIN
  IF KillFocus THEN
    StringToCard( s, c, ok );
    IF NOT ok THEN
      s1 := "Napis nie jest liczb• caàkowit•";
    ELSIF KillFocus & (c >= 360) THEN
      s1 := "Promie‰ naleæy podaÜ w stopniach czyli w zakresie [0..359]";
      ok := FALSE;
    END;
    IF NOT ok THEN
      Pokaz( s1, 5000 );
    END;
    RETURN ok;
  ELSE
    RETURN TRUE;
  END;
END CardValid;

PROCEDURE ProbujWstawic;
VAR
  s : ARRAY[0..99] OF CHAR;
  idx : INTEGER;
  c, c1 : CARDINAL;
  ok : BOOLEAN;
BEGIN
  InpLine.GetText( LiniaNowegoKierunku, s );
  StringToCard( s, c1, ok );
  IF NOT ok OR (c1 >= 360) THEN
(*    Pokaz( "Promie‰ jesl liczb• caàkowit• z przedziaàu [0..360)", 1000 );*)
    RETURN;
  END;
  idx := -1;
  LOOP
    INC( idx );
    GList.Idx2Str( WykLoty.A, idx, s );
    IF s[0] = 0C THEN
      Dialog.EndDialog( TRUE );
      RETURN;
    END;
    s[3] := 0C;
    StringToCard( s, c, ok );
    Assert( ok );
    IF c1=c THEN
      Pokaz( "Taki promie‰ juæ istnieje", 1000 );
      RETURN;
    END;
  END;
END ProbujWstawic;

VAR
  LiniaNowegoKierunku : InpLine.HLINE;

PROCEDURE DodajPr;
VAR
  Ask : Dialog.HDLG;
  R   : RECT;
  phantomB, okB, CancelB : Buttons.Button;
  s : ARRAY[0..99] OF CHAR;
  c : CARDINAL;
  ok : BOOLEAN;
BEGIN
  AssignRect( R, 300, 200, 500, 350 );
  Ask := Dialog.TworzDialog( R, "wstaw.bmp", TRUE );

  AssignRect( R, 1000, 1000, 1000, 1000 );
  Dialog.WstawButton( Ask, R, "", 0, ShortCuts.kbEnter, ProbujWstawic, okB );
  AssignRect( R, 10, 100, 90, 140 );
  Dialog.WstawButton( Ask, R, "OK", 0, ShortCuts.kbAltO, ProbujWstawic, okB);

  MoveRect( R, 100, 0 );
  Dialog.WstawButton( Ask, R, "WYJóCIE", 0, ShortCuts.kbAltW, Dialog.AltF4,
                      CancelB);

   Dialog.WstawInpLine( Ask,
                        40, 40, 12,
                        CardValid,
                        WHITE, MAGENTA, LiniaNowegoKierunku);
  IF Dialog.Go( Ask ) THEN
    InpLine.GetText( LiniaNowegoKierunku, s );
    IF s[0] # 0C THEN
      StringToCard( s, c, ok );
      Assert( ok );
      DodPromienie[ IloscDodatkowychPromieni ] := c;
      INC( IloscDodatkowychPromieni );
      sprintf( s, "%03d¯(*)", c );
      GList.DodajDoListy( WykLoty.A, s );
      GList.DodajDoListy( WykLoty.B, s );
      IF (Nadajnik1 = nA) THEN
        UstawPromienie( WykLoty.A );
      ELSE
        UstawPromienie( WykLoty.B );
      END;
    END;
  END;
  Dialog.UsunDialog( Ask );
END DodajPr;


PROCEDURE DodajP;
BEGIN
  Dialog.EnableDlg( hDlg, FALSE );
  STARTPROCESS( DodajPr, 1000H, 0 );
END DodajP;

PROCEDURE WymienPasujaceObloty( i : INTEGER );
  VAR
    Urzadzenie : ARRAY[0..99] OF CHAR;
  BEGIN
    GList.SkasujWszystko( ListaPomocnicza );
    GList.Idx2Str( ListaVORow, i, Urzadzenie );
    WymienWszystkiePasujace( Urzadzenie, EnumObl );
  END WymienPasujaceObloty;

PROCEDURE EnumObl( VAR s : ARRAY OF CHAR );
  BEGIN
    GList.DodajDoListy( ListaPomocnicza, s );
  END EnumObl;

VAR
  ListaVORow, ListaPomocnicza : GList.HLIST;



PROCEDURE DodajOblot;
VAR
  Ask : Dialog.HDLG;
  R   : RECT;
  phantomB, okB, CancelB : Buttons.Button;
  s, t, u : ARRAY[0..99] OF CHAR;
  i, ile : INTEGER;
  c : CARDINAL;
  ok : BOOLEAN;
  a : ADDRESS;
  d_t : TimeAndDate;
BEGIN
  GetTimeAndDate( d_t );
  AssignRect( R, 400, 250, 750, 580 );
  Ask := Dialog.TworzDialog( R, "wstawOb.bmp", TRUE );

  AssignRect( R, 1000, 1000, 1000, 1000 );
  Dialog.WstawButton( Ask, R, "", 0, ShortCuts.kbEnter, ProbujWstawicOblot, okB);
  AssignRect( R, 10, 290, 90, 320 );
  Dialog.WstawButton( Ask, R, "OK", 0, ShortCuts.kbAltO, ProbujWstawicOblot, okB);

  MoveRect( R, 100, 0 );
  Dialog.WstawButton( Ask, R, "WYJóCIE", 0, ShortCuts.kbAltW, Dialog.AltF4,
                      CancelB);
  Dialog.WstawInpLine( Ask, 10, 40, 30, InpLine.DoNothing, WHITE, MAGENTA,
                       LiniaNowegoKierunku );
  AssignRect( R, 10, 70, 320, 170 );
  ListaVORow := Dialog.WstawListe( Ask, R, FALSE );
  GList.SetNotificationProc( ListaVORow, WymienPasujaceObloty );

  MoveRect( R, 0, R.bottom-R.top+5 );
  ListaPomocnicza     := Dialog.WstawListe( Ask,
                                            R,
                                            FALSE );

  InitListaUrzadzen(ListaVORow);
  IF Dialog.Go( Ask ) THEN
    InpLine.GetText( LiniaNowegoKierunku, s );
    GList.Idx2Str( ListaVORow, GList.GetSelection( ListaVORow ), t );
    IF s[0] = 0C THEN
      InfoBeep( "No przeciez inspekcja musi miec nawe ?!!!", 3, 300 );
    ELSIF t[0] = 0C THEN
      InfoBeep( "Trzeba jeszcze podac nazwe istniejacego VORa", 3, 300 );
    ELSE
      GetPrivateProfileString( LISTA, "Ilosc", "0", u, NazwaPlikuIni );
      StringToInt( u, ile, ok );
      IF NOT ok THEN
        ile := 0;
      END;
      ok := FALSE;
      FOR i := 0 TO ile DO
        sprintf( u, "Oblot%d", i );
        GetPrivateProfileString( LISTA, u, "", u, NazwaPlikuIni );
        ok := ok OR (CompareStr( u, s ) = 0 );
      END;
      IF ok THEN
        InfoBeep( "Istnieje juz inspekcja o takiej nazwie", 3, 300 );
      ELSE
        GetPrivateProfileString( t, "Teodolit.Kat", "@", u, V_BazaLokalizacji );
        IF u[0] = '@' THEN
          a := ADR( t );
          sprintf( u, "Nie VORa o nazwie `%s'", a );
          InfoBeep( u, 3, 500 );
          Wait( 2*TInOneSecond() );
        ELSE
          CardToString( ile+1, u, 1 );
          WritePrivateProfileString( LISTA, "Ilosc", u, NazwaPlikuIni );
          sprintf( u, "Oblot%d", i );
          WritePrivateProfileString( LISTA, u, s, NazwaPlikuIni );
          FreeSlot( KartDomyslna, u );
          WritePrivateProfileString( s, "Kartoteka", u, NazwaPlikuIni );
          IF NOT MkDir( u ) THEN
            InfoBeep( "Problemy z zapisem inicjalizacji !", 3, 800 );
          END;
          Insert( "\obloty.ini", u, 0FFFH );
          WritePrivateProfileString( s, "Nazwa", t, u );
          WritePrivateProfileString( s, "IloscLotow.A", "0", u );
          WritePrivateProfileString( s, "IloscLotow.B", "0", u );

          sprintf( t, "%2d.%02d.%d", d_t.d );
          WritePrivateProfileString( s, "DataRozpoczenia", t, u );
          WritePrivateProfileString( s, "OstatniaModyfikacja", t, u );
          Redraw := TRUE;
          GList.DodajDoListy( ListaOblotow, s );
          Redraw := FALSE;
        END;
      END;
    END;
  END;
  Dialog.UsunDialog( Ask );
  ListaVORow := ListaVOR_Ob;
  ListaPomocnicza := ListaOblotow;
END DodajOblot;


PROCEDURE ProbujWstawicOblot(  );
BEGIN
  Dialog.EndDialog( TRUE );
END ProbujWstawicOblot;

PROCEDURE NowyOblot;
BEGIN
  Dialog.EnableDlg( hDlg, FALSE );
  STARTPROCESS( DodajOblot, 1000H, 0 );
END NowyOblot;

PROCEDURE Pokaz( s : ARRAY OF CHAR; Snd : CARDINAL );
BEGIN
  InfoBeep( s, 2, Snd );
END Pokaz;

PROCEDURE UsunP;
VAR
  idx : INTEGER;
  s : ARRAY[0..99] OF CHAR;
  i, j : INTEGER;
  c, c1 : CARDINAL;
  ok : BOOLEAN;
BEGIN
  IF IloscDodatkowychPromieni = 0 THEN
    Pokaz( "Nic si© nie da usun•Ü", 1000H );
    RETURN;
  END;
  idx := GList.GetSelection( WykLoty.A );
  GList.Idx2Str( WykLoty.B, idx, s );
  IF s[5] # '*' THEN
    Pokaz( 'Tego promienia nie moæna usun•Ü', 1200 );
    RETURN;
  END;
  GList.Idx2Str( WykLoty.A, idx, s );
  IF s[5] # '*' THEN
    Pokaz( 'Tego promienia nie moæna usun•Ü', 1200 );
    RETURN;
  END;
  s[3] := 0C;
  StringToCard( s, c, ok );
  Assert( ok );
  FOR i := 0 TO IloscDodatkowychPromieni -1 DO
    IF DodPromienie[i] = c THEN
      GList.Skasuj( WykLoty.A, idx );
      idx := -1;
      REPEAT
        INC( idx );
        GList.Idx2Str( WykLoty.B, idx, s );
        s[3] := 0C;
        StringToCard( s, c1, ok );
        Assert( ok );
      UNTIL c1 = c;
      GList.Skasuj( WykLoty.B, idx );
      FOR j := i TO IloscDodatkowychPromieni-1 DO
        DodPromienie[j] := DodPromienie[j+1] ;
      END;
      DEC( IloscDodatkowychPromieni );
      RETURN;
    END;
  END;
  Pokaz( "Ten promie‰ jest zapisany w bazie danych", 1000 );
END UsunP;

PROCEDURE UsunOblotP(  );
  BEGIN
    Dialog.EnableDlg( hDlg, FALSE );
    STARTPROCESS( UsunOblot, 01000H, 0 );
  END UsunOblotP;

PROCEDURE UsunOblot(  );
  VAR
    i  : INTEGER;
    ch : CHAR;
    s  : Str40;
  BEGIN
    IF NOT MsgBox.Info( "Jesteò pewien, æe chcesz usun•Ü inspekcj©?" ) THEN
      RETURN;
    END;
    IF NOT MsgBox.Info( "Inspekcja zostanie usuni©ta..." ) THEN
      RETURN;
    END;
    i := GList.GetSelection( ListaOblotow );
    IF i < 0 THEN
      RETURN;
    END;
    GList.Idx2Str( ListaOblotow, i, s );
    SkasujOblot( s );
    GList.Skasuj( ListaOblotow, i );
    GList.SetSelection( ListaOblotow, i );
  END UsunOblot;

PROCEDURE SciezkaDoKataloguOpisu(  );
  BEGIN
    IF Nadajnik1 = nA THEN
      Promien := KierunekA;
    ELSE
      Promien := KierunekB;
    END;
    SciezkaDoKataloguOpisuUst;
  END SciezkaDoKataloguOpisu;

PROCEDURE SciezkaDoKataloguOpisuUst(  );
  VAR
    c : CHAR;
    Tmp, Tmp1 : ARRAY[0..128] OF CHAR;
  BEGIN
    Assign( NazwaPlikuOpisu, SciezkaOpisuPomiaru );
    SciezkaOpisuPomiaru[ Length( SciezkaOpisuPomiaru ) - 10 ] := 0C; (* skasowana nazwa "obloty.ini" *)
    c := CHR( ORD(Nadajnik1)+ORD('A')); (* A lub B *)
    CASE Procedura OF
      pPromienBlad:
        sprintf2( Tmp, "%03d.%c", Promien, c); (* Kartoteka o postaci 123.A *)
    | pPromienZakres:
        sprintf2( Tmp, "%03d.%c_z", Promien, c ); (* Kartoteka o postaci 123.A_Z *)
    | pOkragBlad:
        sprintf( Tmp, "Blad.%c", c); (* Kartoteka o postaci Blad.A *)
    | pOkragZakres:
        sprintf( Tmp, "Zasieg.%c", c); (* Kartoteka o postaci Zasieg.A *)
    END;
    Insert( Tmp, SciezkaOpisuPomiaru, 0FFFH );
    Insert( '\', SciezkaOpisuPomiaru, 0FFFH );
  END SciezkaDoKataloguOpisuUst;

PROCEDURE ExistDIR( VAR Dir : ARRAY OF CHAR ) : BOOLEAN;
  VAR
    ok : BOOLEAN;
    Tmp : ARRAY[0..127] OF CHAR;
  BEGIN
    GetDir( Tmp );
    ok := CD( Dir );
    IF CD( Tmp ) THEN (* wraca gdzie byl *)
    END;
    RETURN ok;
  END ExistDIR;

  PROCEDURE WykonanoWszystkiePromienie( Procedura : ProceduraT;
                                        go        : GlownyOdbiornikT ) : BOOLEAN;
    VAR
      tk : ARRAY [0..V_Database.IleKierunkow-1] OF BOOLEAN;
      c  : CHAR;
      i,
      k,
      IloscOpisow  : INTEGER;
      pr : CARDINAL;
      Tmp : ARRAY[0..63] OF CHAR;
      ok : BOOLEAN;
    BEGIN
      Assert( Procedura > pPromienBlad ); (* tylko  dla promieni zasiegowych *)
      c := CHR( ORD(go) + ORD( 'A' ));
      FOR i := 0 TO HIGH( tk ) DO
        tk[i] := FALSE;
      END;
      IF Procedura = pPromienZakres THEN
        sprintf( Tmp, "IloscLotow.Zas.%c", c );
      ELSE
        sprintf( Tmp, "IloscLotow.%c", c );
      END;
      GetPrivateProfileString( NazwaOblotu, Tmp, "0", Tmp, NazwaPlikuOpisu );
      StringToInt( Tmp, IloscOpisow, ok );
      IF NOT ok OR (IloscOpisow < 0 ) THEN
        IloscOpisow := 0;
      END;
      FOR i := 0 TO IloscOpisow-1 DO
        IF Procedura = pPromienZakres THEN
          sprintf2( Tmp, "Promien.Zasieg.%c.%d", c, i );
        ELSE
          sprintf2( Tmp, "Promien.%c.%d", c, i );
        END;
        GetPrivateProfileString( NazwaOblotu, Tmp, "", Tmp, NazwaPlikuOpisu );
        Tmp[3] := 0C;
        StringToCard( Tmp, pr, ok );
        IF ok THEN
          FOR k := 0 TO CurVor1.IleKierunkow-1 DO
            IF pr = CurVor1.Kierunki[k] THEN
              tk[k] := TRUE;
            END;
          END;
        END;
      END;
      FOR k := 0 TO CurVor1.IleKierunkow-1 DO
        IF NOT tk[k] THEN
          RETURN FALSE;
        END;
      END;
      RETURN TRUE;
    END WykonanoWszystkiePromienie;

PROCEDURE Zapisz( ZrobionyEfektPolaryzacji : BOOLEAN;
                  ZakodowanyBlad,
                  Podzielnik               : INTEGER );
VAR
  ok : BOOLEAN;
  i, j : INTEGER;
  IloscOpisow : INTEGER;



VAR
  a : ADDRESS;
  r : REAL;
  t_d : TimeAndDate;

  Tmp, Tmp1 : ARRAY [0..127] OF CHAR;
  c : CHAR;
BEGIN
  IF NOT PomiarANieArchiwum THEN
    RETURN;
  END;
  r := FLOAT( Orbita ) / 500.0;
  GetTimeAndDate( t_d );
  c := CHR( ORD(Nadajnik1)+ORD('A')); (* A lub B *)
  SciezkaDoKataloguOpisu();
  IF Procedura >= pPromienBlad THEN
    IF Procedura = pPromienZakres THEN
      sprintf( Tmp, "IloscLotow.Zas.%c", c );
    ELSE
      sprintf( Tmp, "IloscLotow.%c", c );
    END;
    GetPrivateProfileString( NazwaOblotu, Tmp, "0", Tmp, NazwaPlikuOpisu );
    StringToInt( Tmp, IloscOpisow, ok );
    IF NOT ok OR (IloscOpisow < 0 ) THEN
      IloscOpisow := 0;
    END;
    i := 0;
    j := -1000; (* na pewno zle *)
    (* Trzeba poszukac czy aby nie byla uzywana *)
    LOOP
      IF i >= IloscOpisow THEN
        EXIT;
      END;
      IF Procedura = pPromienZakres THEN
        sprintf2( Tmp, "Promien.Zasieg.%c.%d", c, i );
      ELSE
        sprintf2( Tmp, "Promien.%c.%d", c, i );
      END;
      GetPrivateProfileString( NazwaOblotu, Tmp, "", Tmp, NazwaPlikuOpisu );
      Tmp[3] := 0C;
      StringToInt( Tmp, j, ok );
      IF ok & (ORD(j) = Promien ) THEN
        EXIT;
      END;
      INC( i );
    END;
    IF ORD(j) # Promien THEN
      i := IloscOpisow;
      INC( IloscOpisow );
      IF Procedura = pPromienZakres THEN
        sprintf( Tmp, "IloscLotow.Zas.%c", c );
      ELSE
        sprintf( Tmp, "IloscLotow.%c", c );
      END;
      sprintf( Tmp1, "%d", IloscOpisow );
      WritePrivateProfileString( NazwaOblotu, Tmp, Tmp1, NazwaPlikuOpisu );
    END;
    (* pod numerem i znajduje sie zadane "Entry" *)
    IF Procedura = pPromienZakres THEN
      sprintf2( Tmp, "Promien.Zasieg.%c.%d", c, i );
    ELSE
      sprintf2( Tmp, "Promien.%c.%d", c, i );
    END;
    
    IF (ZakodowanyBlad = MIN(INTEGER)) THEN
      sprintf3( Tmp1,
                "%03d¯  (!!!!!) %2d.%02d.%4d %2d:%02d",
                Promien,
                t_d.d,
                t_d.t );
    ELSE
      sprintf4( Tmp1,
                "%03d¯  (%5z¯) %2d.%02d.%4d %2d:%02d",
                Promien,
                ZakodowanyBlad,
                t_d.d,
                t_d.t );
     END;
     WritePrivateProfileString( NazwaOblotu, Tmp, Tmp1, NazwaPlikuOpisu );
     ConvertToStr(DataOstatniejKalibracji, FALSE, Tmp1);
     WritePrivateProfileString( "DataKalibracji", "Data", Tmp1, NazwaPlikuOpisu );
     IF ZrobionyEfektPolaryzacji THEN
       sprintf( Tmp, "EfektPolaryzacji.%c", c );
       Tmp1[0] := '1';
       Tmp1[1] := 0C;
       WritePrivateProfileString( NazwaOblotu, Tmp, Tmp1, NazwaPlikuOpisu );
     END;

  ELSIF Procedura = pOkragBlad THEN
    IF (ZakodowanyBlad = MIN(INTEGER)) THEN
      sprintf3( Tmp1,
                "%6.1lf  (!!!!!) %2d.%02d.%4d %2d:%02d",
                r,
                t_d.d,
                t_d.t );
    ELSE
      sprintf4( Tmp1,
                "%6.1lf  (%5z¯) %2d.%02d.%4d %2d:%02d",
                r,
                ZakodowanyBlad,
                t_d.d,
                t_d.t );
    END;
    sprintf( Tmp, "OrbitaRozkladBledu.%c", c );
    WritePrivateProfileString( NazwaOblotu, Tmp, Tmp1, NazwaPlikuOpisu );
  ELSE (* orbita zasieg *)
    sprintf4( Tmp1,
              "%6.1lf  (%5z¯) %2d.%02d.%4d %2d:%02d",
              r,
              ZakodowanyBlad,
              t_d.d,
              t_d.t );
    sprintf( Tmp, "Orbita.Zasieg.%c", c );
    WritePrivateProfileString( NazwaOblotu, Tmp, Tmp1, NazwaPlikuOpisu );
  END;
  sprintf( Tmp, "%2d.%02d.%4d", t_d.d );
  WritePrivateProfileString( NazwaOblotu, "OstatniaModyfikacja", Tmp, NazwaPlikuOpisu );
END Zapisz;


  VAR
    WybranyA,
    WybranyB : INTEGER;
BEGIN
  StartInspection(Insp_VOR);
  Uaktualnij := Nic;
  Info ("" );
  Orbita  := 0;
  OstatniOblot := 0;
  Predkosc := 100.0;
  Promien := 0;
  NazwaPlikuOpisu[0] := 0C;
  GlownyOdbiornik := MIN(GlownyOdbiornikT);
  OdnDlaPomBledu := pbnieZdef;
  OdnDlaPomOdl := MIN(OdnDlaPomOdlT);
  Nadajnik1 := nA;
  Nadajnik2 := nA;
  Procedura := MIN( ProceduraT );
  WybranyA  := 0;
  WybranyB  := 0;
END V_Oblot.
