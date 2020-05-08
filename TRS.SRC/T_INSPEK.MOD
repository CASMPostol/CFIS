(*.F- *)
(**********************************************************************
|  Title   : Obsluga inspekcji
|  Author  : M.Morawski na podstawie T_Oblot
|  System  : LOGITECH MODULA-2/86
|  History :
|    31-03-97: M.Postol
|      Polskie litery
|    09-10-97 07:38pm: MM
|      Poprawiono zachowanie sie w czasie selektywnego wyboru inspekcji
|
|  Copyright (C), CAS LODZ POLAND.
|  TEL: 42' 862 547, 42' 87 80 44 FAX/TEL: 42' 84 48 40
|
**********************************************************************)
(*.F+ *)

IMPLEMENTATION MODULE T_Inspekcja;

  IMPORT
    ShortCuts, MsgBox;

  FROM PA_PA  IMPORT
    PomiarANieArchiwum;

  FROM CommonData IMPORT
    NazwaOblotu, NazwaPlikuOpisu, NazwaUrzadz1,
    NazwaUrzadz2, DME;

  FROM GrafTypes IMPORT
    RECT, AssignRect, MoveRect, WHITE, BLUE, MAGENTA;

  FROM GrafUtil IMPORT
    Info, InfoBeep;

  FROM Sounds IMPORT
    Sound, NoSound;

  FROM Timer IMPORT
    Wait, TInOneSecond;

  FROM NumberConversion IMPORT
    StringToCard, StringToInt, CardToString;

  FROM Strings IMPORT
    Length, Insert, CompareStr;

  FROM HiLevGraf IMPORT
    WrStr, SetPaletteEntry;

  FROM Ini IMPORT
    GetPrivateProfileString, WritePrivateProfileString;

  FROM StdIO IMPORT
    sprintf;

  FROM V_Database IMPORT
    CurVor1, CurVor2, LoadVorData1, LoadVorData2;

  FROM FIO IMPORT
    MkDir;

  FROM MANAGER IMPORT
    STARTPROCESS;

  FROM HiLevGraf IMPORT
    Wr2fStrXY;

  FROM Obloty IMPORT
    (* PROCEDURE *) SkasujOblot, WymienWszystkiePasujace, FreeSlot,
                    StartInspection, InitListaUrzadzen,
    (* TYPE *)      T_InspectionKind,
    (* VAR *)       NazwaPlikuIni, 
    (* CONST *)     KartDomyslna, LISTA, V_BazaLokalizacji, ParamFile;

  FROM Czas IMPORT
    TimeAndDate, GetTimeAndDate;

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

  FROM MANAGER IMPORT
    Assert;

  CONST
    MainSection         = "TRS";


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
    poz : INTEGER;
    s   : Str40;
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
    Idx2Str( ListaOblotow, poz, s );
    SkasujOblot( s );
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
    i  : INTEGER;
    R  : RECT;
    ff : RECORD
           Polozenie1,
           Polozenie2  :
             PolozenieGeo;
           Deklinacja : REAL;
         END;

  BEGIN
    IF idx < 0 THEN
      RETURN;
    END;
    IF NOT RedrawScr & (idx = OstatniOblot)
    THEN
      RETURN;
    END (* if *);

    AssignRect( R, 300, 50, 500, 50+32+5+32+5 );
    Redraw(hDlg, R);
    AssignRect( R, 0, 0, 790, 30 );
    Redraw(hDlg, R);

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
    GetPrivateProfileString(NazwaOblotu, "Nazwa.2", "", NazwaUrzadz2,
                            NazwaPlikuOpisu);

    IF (NazwaUrzadz1[0] = 0C) OR (NazwaUrzadz1[0] = 0C) THEN
      RETURN;
    END (* if NazwaLotniska *);
    LoadVorData1(NazwaUrzadz1, NazwaPlikuOpisu);
    LoadVorData2(NazwaUrzadz2, NazwaPlikuOpisu);

    Wr2fStrXY(NazwaUrzadz1, 300, 50, WHITE, BLUE);
    Wr2fStrXY(NazwaUrzadz2, 300, 50+32+5, WHITE, BLUE);

    ff.Polozenie1 := CurVor1.Polozenie;
    ff.Polozenie2 := CurVor2.Polozenie;
    ff.Deklinacja := CurVor1.Deklinacja;
    sprintf(s,
            "Poˆo¾enie=%dø%02d'%02dE, %dø%02d'%02dN i %dø%02d'%02dE, %dø%02d'%02dN, ë=%3.1lfø",
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
    inspIdx,
    inspIdx_2     : Str99;
    u             : Str99;
    i             : INTEGER;
    ile           : INTEGER;
    ok            : BOOLEAN;
    a             : ADDRESS;
    d_t           : TimeAndDate;
    LiniaLotniska : HLINE;
    ListaLokalizacji_2 : HLIST;

  BEGIN
    GetTimeAndDate(d_t);
    AssignRect(R, 0, 100, 400, 570);
    Ask := TworzDialog(R, "Ob-trs.bmp", TRUE);
    WstawInpLine(Ask, 10, 5, 30, DoNothing, WHITE, MAGENTA, LiniaLotniska);

    AssignRect(R, 1000, 1000, 1000, 1000);
    WstawButton(Ask, R, "", 0, ShortCuts.kbEnter, ProbujWstawicOblot, okB);
    AssignRect(R, 10, 35, 190, 60);
    WstawButton(Ask, R, "OK", 0, ShortCuts.kbAltO, ProbujWstawicOblot, okB);
    MoveRect(R, 200, 0);
    WstawButton(Ask, R, "WYJ—CIE", 1, ShortCuts.kbAltW, AltF4, CancelB);
    (* tworz liste lokalizacji *)
    AssignRect(R, 10, 70, 390, 190);
    ListaLokalizacji := WstawListe(Ask, R, FALSE);
    SetNotificationProc(ListaLokalizacji, WymienPasujaceObloty);
    MoveRect(R, 0, R.bottom - R.top + 10);

    ListaLokalizacji_2 := WstawListe(Ask, R, FALSE);
    MoveRect(R, 0, R.bottom - R.top + 10);

    ListaOblotow := WstawListe(Ask, R, FALSE);
    InitListaUrzadzen( ListaLokalizacji );
    InitListaUrzadzen( ListaLokalizacji_2 );
    IF Go(Ask)
    THEN
      GetText(LiniaLotniska, s);
      Idx2Str(ListaLokalizacji, GetSelection(ListaLokalizacji), inspIdx);
      Idx2Str(ListaLokalizacji_2, GetSelection(ListaLokalizacji_2), inspIdx_2 );
      IF s[0] = 0C
      THEN
        InfoBeep("No przecie§ inspekcja musi mie nazw‘ ?!!!", 3, 300);
      ELSIF (inspIdx[0] = 0C) OR (inspIdx_2[0] = 0C)
      THEN
        InfoBeep("Trzeba jeszcze poda nazw‘ istniejacej lokalizacji", 3, 300);
      ELSIF CompareStr( inspIdx, inspIdx_2 ) = 0 THEN
        InfoBeep( "Trzeba wybra† ROZNE VORy", 3, 300);
      ELSE
        GetPrivateProfileString(LISTA, "Ilosc", "0", u, NazwaPlikuIni);
        StringToInt(u, ile, ok);
        IF NOT ok
        THEN
          ile := 0;
        END (* if *);
        ok := FALSE;
        FOR i := 0 TO ile DO
          sprintf(u, "Oblot%d", i);
          GetPrivateProfileString(LISTA, u, "", u, NazwaPlikuIni);
          ok := ok OR (CompareStr(u, s) = 0);
        END (* for i *);
        IF ok
        THEN
          InfoBeep("Istnieje ju§ inspekcja o takiej nazwie", 3, 300);
        ELSE
          GetPrivateProfileString(inspIdx, "Deklinacja", "@", u, V_BazaLokalizacji);
          IF u[0] = '@'
          THEN
            a := ADR(inspIdx);
            sprintf(u, "Nie ma lokalizacji o nazwie `%s'", a);
            InfoBeep(u, 3, 500);
            Wait(3 * TInOneSecond());
          ELSE
            CardToString(ile + 1, u, 1);
            WritePrivateProfileString(LISTA, "Ilosc", u, NazwaPlikuIni);
            sprintf(u, "Oblot%d", i);
            WritePrivateProfileString(LISTA, u, s, NazwaPlikuIni);
            FreeSlot(KartDomyslna, u);
            WritePrivateProfileString(s, "Kartoteka", u, NazwaPlikuIni);
            IF NOT MkDir(u)
            THEN
              InfoBeep("Problemy z zapisem inicjalizacji !", 3, 800);
            END (* if *);
            Insert("\", u, 0FFFH);
            Insert(NazwaPlikuIni, u, 0FFFH);
            WritePrivateProfileString(s, "Nazwa", inspIdx, u);
            WritePrivateProfileString(s, "Nazwa.2", inspIdx_2, u);
            sprintf(inspIdx, "%2d.%02d.%d", d_t.d);
            WritePrivateProfileString(s, "DataRozpoczenia", inspIdx, u);
            WritePrivateProfileString(s, "OstatniaModyfikacja", inspIdx, u);
          END (* if u *);
        END (* if ok *);
      END (* if s *);
    END (* if Go *);
    UsunDialog(Ask);
    ListaLokalizacji := ListaLokalizacjiBAK;
    ListaOblotow := ListaOblotowBAK;
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
    sel := GetSelection(ListaOblotow);
    IF sel < 0 THEN
      s := 0C
    ELSE
      Idx2Str( ListaOblotow, sel, s );
    END;
    IF s[0] = 0C THEN
      Pokaz("Ale, ale... Inspekcja musi mie† nazw©...", 500);
      RETURN;
    END (* if sel *);
    CardToString(sel, s, 1);
    WritePrivateProfileString(MainSection, "OstatniOblot", s, ParamFile);
    EndDialog(TRUE);
  END OblotOK;

  PROCEDURE InspekcjaEP(  ) : InspekcjaEvent;
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
    SetPaletteEntry( GetDialogDIBHandle( hDlg ), 2, 60, 160, 160 );

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
    InitListaUrzadzen( ListaLokalizacji );

    IF PomiarANieArchiwum THEN
      AssignRect(R, 500, 205, 770, 230);
      WstawButton(hDlg, R, "NOWA INSPEKCJA", 0, ShortCuts.kbAltN, NowyOblot, b);
      MoveRect(R, 0, R.bottom - R.top + 5);
      WstawButton(hDlg, R, "SKASUJ INSPEKCJ¨", 0, ShortCuts.kbAltS, UsunOblotP, b );
    END;

    AssignRect(R, 30, 526, 130, 570);
    WstawButton(hDlg, R, "OK", 0, ShortCuts.kbAltO, OblotOK, b);
    AssignRect(R, 200, 526, 300, 570);
    WstawButton(hDlg, R, "WYJD", 0, ShortCuts.kbAltW, AltF4, b);
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
  StartInspection( Insp_TRS );
  DME := FALSE;
  Info("");
  OstatniOblot := MAX(INTEGER);
END T_Inspekcja.





