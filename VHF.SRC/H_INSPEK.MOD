(*.F- *)
(**********************************************************************
|  Title   : Obsluga inspekcji
|  Author  : M.Morawski
|  System  : LOGITECH MODULA-2/86
|  History :
|    31-03-97: M.Postol
|      polskie litery, klawisz ANULUJ na WYJSCIE
|    09-10-97 06:11pm:
|      Ogolne niedogodnosci zwiazane z selektywnym wyborem inspekcji
|    16-09-97: M.Postol
|      zly szort-cut na klawiszu wyjscie
|   Rel. 3.14. MPostol
|     - Dostosowalem do nowej defincicji Obloty.InspekcjeNowyWpis  - 
|       procedura zwraca rezultat.
|
|  Copyright (C), CAS LODZ POLAND.
|  TEL: 42' 862 547, 42' 87 80 44 FAX/TEL: 42' 84 48 40
|
**********************************************************************)
(*.F+ *)

IMPLEMENTATION MODULE H_Inspekcja;

  IMPORT
    ShortCuts, MsgBox, PA_PA;

  FROM CommonData IMPORT
    NazwaOblotu, NazwaPlikuOpisu, NazwaUrzadz1;

  FROM GrafTypes IMPORT
    RECT, AssignRect, MoveRect, WHITE, BLUE, MAGENTA;

  FROM GrafUtil IMPORT
    Info, InfoBeep;

  FROM Sounds IMPORT
    Sound, NoSound;

  FROM Timer IMPORT
    Wait, TInOneSecond;

  FROM NumberConversion IMPORT
    StringToCard, CardToString;

  FROM Strings IMPORT
    Length, Insert;

  FROM HiLevGraf IMPORT
    WrStr, SetPaletteEntry;

  FROM Ini IMPORT
    GetPrivateProfileString, WritePrivateProfileString;

  FROM StdIO IMPORT
    sprintf;

  FROM H_DataBase IMPORT
    NadajnikVHF, OpisNadajnika;

  FROM MANAGER IMPORT
    STARTPROCESS;

  FROM HiLevGraf IMPORT
    Wr2fStrXY;

  FROM Obloty IMPORT
    (* procedure *) SkasujOblot, WymienWszystkiePasujace,
                    StartInspection, InitListaUrzadzen, ZnajdzInspekcje, 
                    InspekcjeNowyWpis,
    (* TYPE *)      T_InspectionKind,
    (* VAR *)       NazwaPlikuIni, 
    (* CONST *)     ParamFile, H_BazaLokalizacji;

  FROM Czas IMPORT
    GetTimeAndDate, TimeAndDate;

  FROM Buttons IMPORT
    Button;

  FROM Dialog IMPORT
    HDLG, EndDialog, TworzDialog, WstawListe, WstawButton, EnableDlg, Go,
    UsunDialog, Redraw, AltF4, WstawInpLine, GetDialogDIBHandle;

  FROM GList IMPORT
    HLIST, SetNotificationProc, Sortowana, GetSelection, Skasuj, SetSelection,
    DodajDoListy, Idx2Str, SkasujWszystko;

  FROM SYSTEM IMPORT
    ADDRESS, ADR;

  FROM CommonTypes IMPORT
    PolozenieGeo, Str40, Str99;

  FROM InpLine IMPORT
    HLINE, GetText, DoNothing;

  CONST
    MainSection       = "VHF";


  VAR
    hDlg                : HDLG;
    RedrawScr           : BOOLEAN;
    ListaOblotow        : HLIST;
    ListaOblotowBAK     : HLIST;
    ListaLokalizacji    : HLIST;
    ListaLokalizacjiBAK : HLIST;
    OstatniOblot        : INTEGER;

  PROCEDURE Pokaz
            (    s   : ARRAY OF CHAR;
                 Snd : CARDINAL      );

  BEGIN
    Info(s);
    IF Snd # 0FFFFH
    THEN
      Sound(Snd);
    END (* if Snd *);
    Wait(3 * TInOneSecond());
    NoSound;
    Info("");
  END Pokaz;

  PROCEDURE UsunOblot();
  VAR
    poz  : INTEGER;
    name : Str40;
  BEGIN
    IF NOT MsgBox.Info("Jeste˜ pewien, ¾e chcesz usun¥† inspekcj©?")
    THEN
      RETURN;
    END (* if *);
    IF NOT MsgBox.Info("Inspekcja zostanie usuni©ta...")
    THEN
      RETURN;
    END (* if *);
    poz := GetSelection(ListaOblotow);
    Idx2Str( ListaOblotow, poz, name );
    SkasujOblot( name );
    Skasuj(ListaOblotow, poz);
    SetSelection(ListaOblotow, 0);
  END UsunOblot;

  PROCEDURE UsunOblotP();

  BEGIN
    EnableDlg(hDlg, FALSE);
    STARTPROCESS(UsunOblot, 0C00H, TInOneSecond() DIV 5);
  END UsunOblotP;

  PROCEDURE ProbujWstawicOblot();

  BEGIN
    EndDialog(TRUE);
  END ProbujWstawicOblot;

  PROCEDURE ZmienOblot
            (    idx : INTEGER );
  VAR
    s  : ARRAY [0 .. 99] OF CHAR;
    R  : RECT;
    ff : RECORD
           Polozenie  :
             PolozenieGeo;
           Deklinacja :
             REAL;
         END;

  BEGIN
    IF idx < 0 THEN
      RETURN;
    END;
    IF NOT RedrawScr & (idx = OstatniOblot)
    THEN
      RETURN;
    END (* if *);
    RedrawScr := FALSE;
    OstatniOblot := idx;
    Idx2Str(ListaOblotow, idx, NazwaOblotu);
    GetPrivateProfileString(NazwaOblotu, "Kartoteka", ".\", NazwaPlikuOpisu,
                            NazwaPlikuIni);
    IF NazwaPlikuOpisu[Length(NazwaPlikuOpisu) - 1] # '\'
    THEN
      Insert("\", NazwaPlikuOpisu, 0FFFH);
    END (* if NazwaPlikuOpisu *);
    Insert(NazwaPlikuIni, NazwaPlikuOpisu, 0FFFH);
    GetPrivateProfileString(NazwaOblotu, "Nazwa", "", NazwaUrzadz1,
                            NazwaPlikuOpisu);

    IF NazwaUrzadz1[0] = 0C
    THEN
      AssignRect( R, 300, 50, 500, 97 );
      Redraw(hDlg, R);
      AssignRect( R, 0, 0, 790, 30 );
      Redraw(hDlg, R);
      RETURN;
    END (* if NazwaUrzadz1 *);
    OpisNadajnika(NazwaUrzadz1, NazwaPlikuOpisu);

    AssignRect( R, 300, 50, 500, 97 );
    Redraw(hDlg, R);
    Wr2fStrXY(NazwaUrzadz1, 300, 50, WHITE, BLUE);

    AssignRect( R, 0, 0, 790, 30 );
    Redraw(hDlg, R);

    ff.Polozenie := NadajnikVHF.Polozenie;
    ff.Deklinacja := NadajnikVHF.Deklinacja;
    sprintf(s,
            "Poˆo¾enie=%dø%02d'%02dE, %dø%02d'%02dN, ë=%5.1lfø",
            ff);
    WrStr(s, 11, 11, WHITE, WHITE);
  END ZmienOblot;

  PROCEDURE EnumObl
            ( VAR s : ARRAY OF CHAR );

  BEGIN
    DodajDoListy(ListaOblotow, s);
  END EnumObl;

  PROCEDURE WymienPasujaceObloty
            (    i : INTEGER );
  VAR
    Urzadzenie : Str99;

  BEGIN
    SkasujWszystko(ListaOblotow);
    Idx2Str(ListaLokalizacji, i, Urzadzenie);
    WymienWszystkiePasujace(Urzadzenie, EnumObl);
    RedrawScr := TRUE;
    ZmienOblot(0);
  END WymienPasujaceObloty;

  PROCEDURE DodajOblot;
  VAR
    Ask           : HDLG;
    R             : RECT;
    okB           : Button;
    CancelB       : Button;
    s             : Str99;
    inspIdx       : Str99;
    u             : Str99;
    adr           : ADDRESS;
    d_t           : TimeAndDate;
    LiniaLotniska : HLINE;

  BEGIN
    GetTimeAndDate(d_t);
    AssignRect(R, 0, 100, 400, 570);
    Ask := TworzDialog(R, "Ob-loc.bmp", TRUE);
    WstawInpLine(Ask, 10, 5, 30, DoNothing, WHITE, MAGENTA, LiniaLotniska);

    AssignRect(R, 1000, 1000, 1000, 1000);
    WstawButton(Ask, R, "", 0, ShortCuts.kbEnter, ProbujWstawicOblot, okB);
    AssignRect(R, 10, 35, 190, 60);
    WstawButton(Ask, R, "OK", 0, ShortCuts.kbAltO, ProbujWstawicOblot, okB);
    MoveRect(R, 200, 0);
    WstawButton(Ask, R, "WYJ—CIE", 0, ShortCuts.kbAltW, AltF4, CancelB);
    (* tworz liste lokalizacji *)
    AssignRect(R, 10, 70, 390, 250);
    ListaLokalizacji := WstawListe(Ask, R, FALSE);
    SetNotificationProc(ListaLokalizacji, WymienPasujaceObloty);

    MoveRect(R, 0, R.bottom - R.top + 10);
    ListaOblotow := WstawListe(Ask, R, FALSE);
    InitListaUrzadzen(ListaLokalizacji);
    IF Go(Ask)
    THEN
      GetText(LiniaLotniska, s);
      Idx2Str(ListaLokalizacji, GetSelection(ListaLokalizacji), inspIdx);
      IF s[0] = 0C
      THEN
        InfoBeep("No przecie¾ inspekcja musi mie† nazw© ?!!!", 3, 300);
      ELSIF inspIdx[0] = 0C
      THEN
        InfoBeep("Trzeba jeszcze poda† nazw© istniej¥cej lokalizacji", 3, 300);
      ELSIF ZnajdzInspekcje("", s)
      THEN
        InfoBeep("Istnieje ju¾ inspekcja o takiej nazwie", 3, 300);
      ELSE
        GetPrivateProfileString(inspIdx, "Deklinacja", "@", u, 
                                H_BazaLokalizacji);
        IF u[0] = '@'
        THEN
          adr := ADR(inspIdx);
          sprintf(u, "Nie ma lokalizacji o nazwie `%s'", adr);
          InfoBeep(u, 3, 500);
          Wait(3 * TInOneSecond());
        ELSE
          IF InspekcjeNowyWpis("", s, u, TRUE)
          THEN
            WritePrivateProfileString(s, "Nazwa", inspIdx, u);
            sprintf(inspIdx, "%2d.%02d.%d", d_t.d);
            WritePrivateProfileString(s, "DataRozpoczenia",     inspIdx, u);
            WritePrivateProfileString(s, "OstatniaModyfikacja", inspIdx, u);
          ELSE
            InfoBeep("Problem z utworzeniem inspekcji !!!!", 5, 300);
          END (* IF *);
        END (* IF u[0] = '@' *);
      END (* if s *);
    END (* if Go *);
    UsunDialog(Ask);
    ListaLokalizacji := ListaLokalizacjiBAK;
    ListaOblotow     := ListaOblotowBAK;
    WymienPasujaceObloty( GetSelection(ListaLokalizacji) );
  END DodajOblot;

  PROCEDURE NowyOblot;

  BEGIN
    EnableDlg(hDlg, FALSE);
    STARTPROCESS(DodajOblot, 1100H, TInOneSecond() DIV 5);
  END NowyOblot;

  PROCEDURE OblotOK();
  VAR
    s   : Str40;
    sel : INTEGER;

  BEGIN
    s[0] := 0C;
    sel := GetSelection(ListaOblotow);
    IF sel >= 0 THEN
      Idx2Str( ListaOblotow, sel, s );
    END;
    IF s[0] = 0C THEN
      Pokaz("Ale, ale... Inspekcja musi miec nazwe...", 500);
      RETURN;
    END (* if sel *);
    CardToString(sel, s, 1);
(*    Terminate( Warning );*)
    WritePrivateProfileString(MainSection, "OstatniOblot", s, ParamFile);
    EndDialog(TRUE);
  END OblotOK;

  PROCEDURE InspekcjaEP( ) : InspekcjaEvent;
  VAR
    R    : RECT;
    b    : Button;
    s    : ARRAY [0 .. 99] OF CHAR;
    i    : CARDINAL;
    kont : BOOLEAN;

    PROCEDURE SetDefInsp;
    BEGIN
      GetPrivateProfileString(MainSection, "OstatniOblot", "0", s, ParamFile);
      StringToCard(s, i, kont);
      IF NOT kont
      THEN
        i := 0;
      END (* if *);
      ZmienOblot(i);
      SetSelection(ListaOblotow, i);
    END SetDefInsp;

  BEGIN (* InspekcjaEP *)
    RedrawScr := TRUE;
    AssignRect(R, 0, 0, 800, 600 - 17);
    hDlg := TworzDialog(R, "insp.dib", FALSE);
    SetPaletteEntry( GetDialogDIBHandle( hDlg ), 2, 180, 180, 60 );

    (* Listy dialogowe *)
    AssignRect(R, 500, 100, 770, 200);
    Wr2fStrXY(' INSPEKCJE ', 500, 50, WHITE, BLUE);
    ListaOblotowBAK := WstawListe(hDlg, R, FALSE);
    ListaOblotow := ListaOblotowBAK; (* kopia bo dzialamy na danych glob. *)
    SetNotificationProc(ListaOblotow, ZmienOblot);
    Sortowana(ListaOblotow, FALSE);

    AssignRect(R, 500, 310, 770, 500);
    Wr2fStrXY(' LOKALIZACJE ', 500, 270, WHITE, BLUE);
    ListaLokalizacjiBAK := WstawListe(hDlg, R, FALSE);
    ListaLokalizacji := ListaLokalizacjiBAK; (* kopia bo dzialamy na danych glob. *)
    SetNotificationProc(ListaLokalizacji, WymienPasujaceObloty);

    DodajDoListy(ListaLokalizacji, "* wszystkie *");
    InitListaUrzadzen(ListaLokalizacji);

    IF PA_PA.PomiarANieArchiwum THEN
      AssignRect(R, 500, 205, 770, 230);
      WstawButton(hDlg, R, "NOWA INSPEKCJA", 0, ShortCuts.kbAltN, NowyOblot, b);
      MoveRect(R, 0, R.bottom - R.top + 5);
      WstawButton(hDlg, R, "SKASUJ INSPEKCJ¨", 0, ShortCuts.kbAltS, UsunOblotP, b );
    END;

    AssignRect(R, 30, 526, 130, 570);
    WstawButton(hDlg, R, "OK", 0, ShortCuts.kbAltO, OblotOK, b);
    AssignRect(R, 200, 526, 300, 570);
    WstawButton(hDlg, R, "WYJ—CIE", 0, ShortCuts.kbAltW, AltF4, b);
    MoveRect(R, 0, 100);
    WstawButton(hDlg, R, "", -1, ShortCuts.kbEnter, OblotOK, b);
    SetDefInsp;
    RedrawScr := FALSE;
    kont := Go(hDlg);
    UsunDialog( hDlg );
    IF kont & (NazwaOblotu[0] # 0C)
    THEN
      RETURN AkceptIE;
    ELSIF NOT kont
    THEN
      Info("Zaniechano wyboru");
    ELSE
      Info("Zrezygnowano z wyboru inspekcji");
    END (* if kont *);
    RETURN AbortIE;
  END InspekcjaEP;

BEGIN
  StartInspection(Insp_VHF);
  Info("");
  OstatniOblot := MAX(INTEGER);
END H_Inspekcja.
