(*.F- *)
(**********************************************************************
|  Title   : Glowny ekran sterujacy dla LOC
|  Author  : M.Morawski
|  System  : LOGITECH MODULA-2/86
|  History :
|    11-05-96:M.Postol
|       kosmetyka
|    15-06-96:M.Postol
|       blad przy kopiowaniu plikow po akceptacji,
|    21-06-96: M.Postol
|       zmieniona Wyrazistosc_na_d_katach_A
|   01-09-96:
|       zmiany na ekranie pomiarowym
|   05-11-96: M.Postol
|       blad przy konwersji Kierunekpasa
|   12-12-96: M.Morawski i M.Postol
|     zainicjowano Promien
|   12-18-96 05:01pm: MM:
|     Wywalono inspekcje z programow archiwalnego
|   01-26-97 03:52pm: MM
|     Dodany podzielnik w procedurze Zapisz
|   17-02-97: M.Postol
|     Blad zmiana typu z CARDINAL NA INTEGER
|   03-13-97 01:04pm: MM
|     Dane, dla ktorych nie wyznaczono rezultatu koncowego zaznaczane sa
|     wykrzyknikami
|   31-03-97: M.POSTOL
|     POLSKIE LITERY
|   13-05-97: M.Postol
|     blad przy inicjowaniu kata kietunku pasa w prog arch
|     zmiana ulozenia klawiszy na ekranie
|   22-05-97: M.Postol
|     wywalilem wszystkie niepotrzebne importy
|   Rel 3.0. MPostol
|      Blad przy strojeniu, nie byl ustawiny w Lowsence
|      MKR byl zle strojony 
|   Rel 3.14: MPostol
|     - Zmienilem sposob wyswietlania danych dotyczacych inspekcji
|       dodatkowo wyswietlane jest polozenie DME
|
|  Copyright (C), CAS LODZ POLAND.
|  TEL: 42' 686 25 47
|  mailto: techsupp@cas.com.pl
|  http: www.cas.com.pl
|
**********************************************************************)
(*.F+ *)
IMPLEMENTATION MODULE L_Oblot;

  IMPORT
    ShortCuts, InpLine, GList, Buttons, MsgBox, Files, PI_PA, Mapa;

  FROM GrafTypes IMPORT
    RECT, AssignRect, MoveRect, WHITE, BLUE, MAGENTA, BROWN;

  FROM GrafUtil IMPORT
    Info, InfoBeep;

  FROM Polozenie IMPORT
    StalyKat;

  FROM Sounds IMPORT
    Sound, NoSound;

  FROM Timer IMPORT
    Wait, TInOneSecond;

  FROM NumberConversion IMPORT
    StringToCard, StringToInt, CardToString;

  FROM RealConversions IMPORT
    StringToReal, RealToString;

  FROM Strings IMPORT
    Length, Insert, Assign, CompareStr;

  FROM HiLevGraf IMPORT
    WrStr;

  FROM Dialog IMPORT
    HDLG, EndDialog, TworzDialog, WstawListe, WstawButton, EnableDlg, Go,
    UsunDialog, Redraw, AltF4, WstawInpLine, WstawRadioButton;

  FROM Ini IMPORT
    GetPrivateProfileString, WritePrivateProfileString;

  FROM StdIO IMPORT
    sprintf, sprintf2, sprintf3;

  FROM L_DataBase IMPORT
    Lotnisko, OpisLotniska, MkrId_T;

  FROM FIO IMPORT
    MkDir;

  FROM MANAGER IMPORT
    Assert, STARTPROCESS;

  FROM HiLevGraf IMPORT
    Wr2fStrXY;

  FROM SYSTEM IMPORT
    ADDRESS, ADR;

  FROM CommonData IMPORT
    OdnDlaPomBledu, OdnDlaPomOdl, GlownyOdbiornik,
    CisnienieOdniesienia, NazwaOblotu, NazwaUrzadz1, NazwaUrzadz2,
    Nadajnik1, SciezkaOpisuPomiaru, NazwaPlikuOpisu;

  FROM Tune IMPORT
    TuneILS, Receiver, TuneDMEforILS, ILSfrqString;

  FROM Obloty IMPORT
    (* PROCEDURE *) SkasujOblot, WymienWszystkiePasujace, FreeSlot,
                    StartInspection, InitListaUrzadzen,
    (* TYPE *)  T_InspectionKind,
    (* VAR *) NazwaPlikuIni,
    (* CONST *) KartDomyslna, LISTA, L_BazaLokalizacji, ParamFile; 

  FROM Czas IMPORT
    GetTimeAndDate, ConvertToStr, TimeAndDate;

  FROM CommonTypes IMPORT
    OdnDlaPomBleduT, GlownyOdbiornikT, NadajnikT, Str40,
    PolozenieGeo, DisNilVal, ZoneBoundPt, CoMoznaZrobic;

  FROM MathLib0 IMPORT
    entier, real;

  FROM L_CommonTypes IMPORT
    Procedura, Strona, ProceduraT, L_OdnDlaPomOdlT, StronaT, NumPunktu,
    Szer_sekt_kier, Odl_dla_pom_pB;

  FROM ILS_ZoneMngmnt IMPORT
    IdentPunktowT, IdentPunktow;

  FROM SpecConv IMPORT
    Card500Str, Angle100;

  FROM SwitchCntrl IMPORT
    SwState, SwitchTo;

  FROM Kalibracja IMPORT
    DataOstatniejKalibracji;

  TYPE
    A_B_lewa_prawa =
      RECORD
        A, B :
          RECORD
            lewa, prawa :
              Buttons.Button;
          END;
      END;
    A_B            =
      RECORD
        A, B :
          Buttons.Button;
      END;

  CONST
    MainSection       = "LOC";
    LOTNISKA          = "Lotniska";

  VAR
    hDlg                     : HDLG;
    bAlarmOsi,
    bSzerSektora_pA,
    bAlarmSzeroki_pA,
    bAlarmWaski_pA,
    bMarker                  : A_B_lewa_prawa;
    bUstawienieOsi_Struktura,
    bUstawienieOsi_Szer_pA,
    bUstawienieOsi_Waski_pA,
    bSzer_i_Osi_pB,
    bAlarmSzer_pB,
    bAlarmWaski_pB,
    bRownowagaModulacji,
    bFazowanie,
    bWyrazistosc_na_d_katach,
    bZasieg_do_10,
    bZasieg_10_35,
    bZasieg_ponad_35         : A_B;
    GlowOdb,
    OdnAzymut,
    OdnOdl                   : Buttons.Button;
    bIdentPunktow            : ARRAY ZoneBoundPt OF Buttons.Button;
    lOdl_dla_pom_pB          : InpLine.HLINE;
    (* lSzer_sekt_kier          : InpLine.HLINE; *)
    lCisnienieOdn            : InpLine.HLINE;
    ListaOblotow             : GList.HLIST;
    TestUP,
    Raport,
    Pomiar                   : Buttons.Button;  (* Test urzadzen pomiarowych *)
    RedrawScr                : BOOLEAN;
    OstatniOblot             : INTEGER;
    ListaLotn_Ob             : GList.HLIST;
        (* VAR OstatniOblot : INTEGER; IloscDodatkowychPromieni : INTEGER;
           DodPromienie : ARRAY[0..10] OF CARDINAL; Redraw : BOOLEAN; *)
    ListaLotnisk,
    ListaPomocnicza          : GList.HLIST;
    outMkrStr                : ARRAY[0..9] OF CHAR;

  PROCEDURE InitOblot() : BOOLEAN;
  VAR
    R    : RECT;
    b    : Buttons.Button;
    s    : ARRAY [0 .. 99] OF CHAR;
    i    : CARDINAL;
    kont : BOOLEAN;

  BEGIN
    RedrawScr := TRUE;
    AssignRect(R, 0, 0, 800, 599);
    hDlg := TworzDialog(R, "insp.dib", FALSE);   (* w kolorach
                                                           naturalnych *)
    (* Listy dialogowe *)
    AssignRect(R, 500, 100, 770, 200);
    Wr2fStrXY(' INSPEKCJE ', 500, 50, WHITE, BLUE);
    ListaOblotow := WstawListe(hDlg, R, FALSE);
    GList.SetNotificationProc(ListaOblotow, ZmienOblot);
    GList.Sortowana(ListaOblotow, FALSE);
    AssignRect(R, 500, 310, 770, 500);
    Wr2fStrXY(' LOKALIZACJE ', 500, 270, WHITE, BLUE);
    ListaLotn_Ob := WstawListe(hDlg, R, FALSE);
    GList.SetNotificationProc(ListaLotn_Ob, WymienPasujaceObloty);
    ListaLotnisk := ListaLotn_Ob;
    ListaPomocnicza := ListaOblotow;
    GList.DodajDoListy(ListaLotn_Ob, "* wszystkie *");
    InitListaUrzadzen(ListaLotnisk);
    IF PI_PA.PomiarANieArchiwum THEN
      AssignRect(R, 500, 205, 770, 230);
      WstawButton(hDlg, R, "NOWA INSPEKCJA", 0, ShortCuts.kbAltN,
                         NowyOblot, b);
      MoveRect(R, 0, R.bottom - R.top + 3);
      WstawButton(hDlg, R, "SKASUJ INSPEKCJ®", 0, ShortCuts.kbAltS,
                         UsunOblotP, b);
    END;
    AssignRect(R, 30, 526, 130, 570);
    WstawButton(hDlg, R, "OK", 0, ShortCuts.kbAltO, OblotOK, b);
    AssignRect(R, 200, 526, 300, 570);
    WstawButton(hDlg, R, "WYJDç", 0, ShortCuts.kbAltW, AltF4, b);
    MoveRect(R, 0, 100);
    WstawButton(hDlg, R, "", -1, ShortCuts.kbEnter, OblotOK, b);
    GetPrivateProfileString(MainSection, "OstatniOblot", "0", s, ParamFile);
    StringToCard(s, i, kont);
    IF NOT kont
    THEN
      i := 0;
    END (* if *);
    ZmienOblot(i);
    GList.SetSelection(ListaOblotow, i);
    RedrawScr := FALSE;
    kont := Go(hDlg);
    UsunDialog(hDlg);
    IF kont & (NazwaOblotu[0] # 0C)
    THEN
      RETURN TRUE;
    END (* if kont *);
    IF NOT kont
    THEN
      Info("Zaniechano wyboru");
    ELSE
      Info("Zrezygnowano z wyboru inspekcji");
    END (* if *);
    RETURN kont;
  END InitOblot;

  PROCEDURE WymienPasujaceObloty
            (    i : INTEGER );
  VAR
    Urzadzenie : ARRAY [0 .. 99] OF CHAR;

  BEGIN
    OstatniOblot := -1;
    GList.SkasujWszystko(ListaPomocnicza);
    GList.Idx2Str(ListaLotnisk, i, Urzadzenie);
    WymienWszystkiePasujace(Urzadzenie, EnumObl);
    ZmienOblot(0);
  END WymienPasujaceObloty;

  PROCEDURE EnumObl
            ( VAR s : ARRAY OF CHAR );

  BEGIN
    GList.DodajDoListy(ListaPomocnicza, s);
  END EnumObl;

  PROCEDURE OblotOK();
  VAR
    s   : Str40;
    sel : INTEGER;

  BEGIN
    sel := GList.GetSelection(ListaOblotow);
    IF sel < 0 THEN
      s[0] := 0C;
    ELSE
      GList.Idx2Str( ListaOblotow, sel, s );
    END;
    IF s[0] = 0C THEN
      Pokaz("Ale, ale... Inspekcja musi mieÜ nazw©...", 500);
      RETURN;
    END (* if sel *);
    CardToString(sel, s, 1);
    WritePrivateProfileString(MainSection, "OstatniOblot", s, ParamFile);
    EndDialog(TRUE);
  END OblotOK;

  PROCEDURE UsunOblotP();

  BEGIN
    EnableDlg(hDlg, FALSE);
    STARTPROCESS(UsunOblot, 0D00H, 0);
  END UsunOblotP;

  PROCEDURE UsunOblot();
  VAR
    i : INTEGER;
    s : Str40;

  BEGIN
    IF NOT MsgBox.Info("Jesteò pewien, æe chcesz usun•Ü inspekcj©?")
    THEN
      RETURN;
    END (* if *);
    IF NOT MsgBox.Info("Inspekcja zostanie usuni©ta...")
    THEN
      RETURN;
    END (* if *);
    i := GList.GetSelection(ListaOblotow);
    GList.Idx2Str( ListaOblotow, i, s );
    SkasujOblot(s);
    GList.Skasuj(ListaOblotow, i);
    GList.SetSelection(ListaOblotow, i);
  END UsunOblot;

  PROCEDURE RealCisnValid
            (     l         : InpLine.HLINE;
              VAR s         : ARRAY OF CHAR;
                  KillFocus : BOOLEAN       ) : BOOLEAN;
  VAR
    r  : REAL;
    ok : BOOLEAN;
    i  : ARRAY [0 .. 99] OF CHAR;

  BEGIN
    IF KillFocus THEN
      StringToReal(s, r, ok);
      IF NOT ok
      THEN
        i := "Napis nie jest liczba rzeczywist•";
      ELSIF KillFocus & ((r < 700.0) OR (r > 1200.0))
      THEN
        i := "Wprowadzona liczba jest zbyt duæa lub zbyt maàa";
        ok := FALSE;
      END (* if *);
      IF NOT ok
      THEN
        Pokaz(i, 5000);
      END (* if *);
      RETURN ok;
    ELSE
      RETURN TRUE;
    END
  END RealCisnValid;

  PROCEDURE StronaCH() : CHAR;

  BEGIN
    IF (Strona = sL75) OR (Strona = sL150)
    THEN
      RETURN 'L';
    ELSE
      RETURN 'P';
    END (* if *);
  END StronaCH;

  PROCEDURE NadajnikCH() : CHAR;

  BEGIN
    RETURN CHR(ORD(Nadajnik1) + ORD('A'));   (* A lub B *)
  END NadajnikCH;

  PROCEDURE InitLot
            () : BOOLEAN;

  CONST
    DX        = 100;
    DY        = 24;
    SZEROKOSC = 85;
  VAR
    kont : BOOLEAN;
    s    : ARRAY [0 .. 31] OF CHAR;

    PROCEDURE InitDefault;
    VAR
      c   : CARDINAL;
      pt  : NumPunktu;
      ptC : CARDINAL;
      ok  : BOOLEAN;

    BEGIN
      GetPrivateProfileString(MainSection, "OdnDlaPomAzymutu", "1", s,
                              ParamFile);
      StringToCard(s, c, ok);
      IF NOT ok
      THEN
        c := 1;
      END (* if *);
      OdnDlaPomBledu := VAL(OdnDlaPomBleduT, c);
      GetPrivateProfileString(MainSection, "OdnDlaPomOdl", "0", s, ParamFile);
      StringToCard(s, c, ok);
      IF NOT ok
      THEN
        c := 0;
      END (* if *);
      OdnDlaPomOdl := VAL(L_OdnDlaPomOdlT, c);
      GetPrivateProfileString(MainSection, "GlownyOdbiornik", "0", s, ParamFile
      );
      StringToCard(s, c, ok);
      IF NOT ok
      THEN
        c := 0;
      END (* if *);
      GlownyOdbiornik := VAL(GlownyOdbiornikT, c);
      IF PI_PA.PomiarANieArchiwum THEN
        FOR pt := np_A TO np_E DO
          ptC := ORD(pt);
          sprintf(s, "IdentPunktow.%d", ptC);
          GetPrivateProfileString(MainSection, s, "0", s, ParamFile);
          StringToCard(s, c, ok);
          IF NOT ok
          THEN
            IdentPunktow[pt] := ipGPS;
          ELSE
            IdentPunktow[pt] := VAL(IdentPunktowT, c);
          END (* if *);
        END (* for i *);
        (* szerokosc sektora *)
        Szer_sekt_kier := Lotnisko.Szer_Sekt;
        (*
        RealToString(FLOAT(Szer_sekt_kier) / 100.0, 2, 7, s, ok);
        InpLine.SetText(lSzer_sekt_kier, s);
        *)
        (* Cisnienie *)
        GetPrivateProfileString(MainSection, "CisnienieOdn", "1013.8", s,
                                ParamFile);
        InpLine.SetText(lCisnienieOdn, s);
        IF NOT RealCisnValid(lCisnienieOdn, s, TRUE)
        THEN
          CisnienieOdniesienia := 1013.8;
          InpLine.SetText(lCisnienieOdn, "1013.8");
        ELSE
          CisnienieOdniesienia := RealVal(lCisnienieOdn);   (* MP *)
        END (* if *);
        (* odleglosc w profilu B *)
        GetPrivateProfileString(MainSection, "OdlegDlaPB", '500', s, ParamFile);
        StringToCard(s, Odl_dla_pom_pB, ok);
        IF NOT ok
        THEN
          Odl_dla_pom_pB := 500;
        END (* if *);
        RealToString(FLOAT(Odl_dla_pom_pB) / 500.0, 2, 7, s, ok);
        InpLine.SetText(lOdl_dla_pom_pB, s);
      END;
    END InitDefault;

    PROCEDURE SaveDefault;
    VAR
      npt  : NumPunktu;
      nptC : CARDINAL;
      t    : ARRAY [0 .. 99] OF CHAR;
      s    : Str40;

    BEGIN
      CardToString(ORD(OdnDlaPomBledu), s, 1);
      WritePrivateProfileString(MainSection, "OdnDlaPomAzymutu", s, ParamFile);
      CardToString(ORD(OdnDlaPomOdl), s, 1);
      WritePrivateProfileString(MainSection, "OdnDlaPomOdl", s, ParamFile);
      CardToString(ORD(GlownyOdbiornik), s, 1);
      WritePrivateProfileString(MainSection, "GlownyOdbiornik", s, ParamFile);
      FOR npt := np_A TO np_E DO
        nptC := ORD(npt);
        sprintf(t, "IdentPunktow.%d", nptC);
        CardToString(ORD(IdentPunktow[npt]), s, 2);
        WritePrivateProfileString(MainSection, t, s, ParamFile);
      END (* for i *);
      sprintf(s, "%8.1lf", CisnienieOdniesienia);
      WritePrivateProfileString(MainSection, "CisnienieOdn", s, ParamFile);
      CardToString(Odl_dla_pom_pB, s, 1);
      WritePrivateProfileString(MainSection, "OdlegDlaPB", s, ParamFile);
      (*
      CardToString(Szer_sekt_kier, s, 1);
      WritePrivateProfileString(MainSection, "SzerokoscSektoraKierunku", s,
                                ParamFile);
      *)
    END SaveDefault;


  VAR
    R      : RECT;
    RDummy : RECT;
    i      : ZoneBoundPt;

    PROCEDURE AssignButt;

      PROCEDURE Make4
                (     R    : RECT;
                  VAR ablp : A_B_lewa_prawa;
                      pal  : PROC;
                      sal  : CARDINAL;
                      pap  : PROC;
                      sap  : CARDINAL;
                      pbl  : PROC;
                      sbl  : CARDINAL;
                      pbp  : PROC;
                      sbp  : CARDINAL       );

      BEGIN
        WstawRadioButton(hDlg, R, "", -1, sal, pal, ablp.A.lewa);
        MoveRect(R, DX, 0);
        WstawRadioButton(hDlg, R, "", -1, sap, pap, ablp.A.prawa);
        MoveRect(R, DX, 0);
        WstawRadioButton(hDlg, R, "", -1, sbl, pbl, ablp.B.lewa);
        MoveRect(R, DX, 0);
        WstawRadioButton(hDlg, R, "", -1, sbp, pbp, ablp.B.prawa);
      END Make4;

      PROCEDURE Make2
                (     R  : RECT;
                  VAR ab : A_B;
                      pa : PROC;
                      sa : CARDINAL;
                      pb : PROC;
                      sb : CARDINAL );

      BEGIN
        WstawRadioButton(hDlg, R, "", -1, sa, pa, ab.A);
        MoveRect(R, DX + DX, 0);
        WstawRadioButton(hDlg, R, "", -1, sb, pb, ab.B);
      END Make2;

      PROCEDURE Make5
                (     name : ARRAY OF CHAR;
                      R    : RECT;
                  VAR it   : ARRAY OF Buttons.Button;
                      p1   : PROC;
                      s1   : CARDINAL;
                      p2   : PROC;
                      s2   : CARDINAL;
                      p3   : PROC;
                      s3   : CARDINAL;
                      p4   : PROC;
                      s4   : CARDINAL;
                      p5   : PROC;
                      s5   : CARDINAL                );

      BEGIN
        R.right := R.left + SZEROKOSC;
        WstawButton(hDlg, R, "", -1, s1, p1, it[0]);
        MoveRect(R, DX, 0);
        WstawButton(hDlg, R, "", -1, s2, p2, it[1]);
        MoveRect(R, DX, 0);
        WstawButton(hDlg, R, "", -1, s3, p3, it[2]);
        MoveRect(R, DX, 0);
        WstawButton(hDlg, R, "", -1, s4, p4, it[3]);
        MoveRect(R, DX, 0);
        WstawButton(hDlg, R, "", -1, s5, p5, it[4]);
        WrStr(name, R.right + 5, R.top + 5, BROWN, BROWN);
      END Make5;

  VAR
    R      : RECT;
    R1     : RECT;
    RDummy : RECT;
    void   : Buttons.Button;

    BEGIN (* AssignButt *)
      (* Alarm osi *)
      AssignRect(R, 5, 50, 5 + SZEROKOSC, 70);
      Make4(R, bAlarmOsi, AlarmOsi_A_L, ShortCuts.kbNoKey, AlarmOsi_A_P,
            ShortCuts.kbNoKey, AlarmOsi_B_L, ShortCuts.kbNoKey, AlarmOsi_B_P,
            ShortCuts.kbNoKey);
      MoveRect(R, 0, DY);
      (* szerokosc sektora w profilu A *)
      Make4(R, bSzerSektora_pA, SzerSektora_pA_A_L, ShortCuts.kbNoKey,
            SzerSektora_pA_A_P, ShortCuts.kbNoKey, SzerSektora_pA_B_L,
            ShortCuts.kbNoKey, SzerSektora_pA_B_P, ShortCuts.kbNoKey);
      MoveRect(R, 0, DY);
      (* alarm szeroki w profilu A *)
      Make4(R, bAlarmSzeroki_pA, AlarmSzeroki_pA_A_L, ShortCuts.kbNoKey,
            AlarmSzeroki_pA_A_P, ShortCuts.kbNoKey, AlarmSzeroki_pA_B_L,
            ShortCuts.kbNoKey, AlarmSzeroki_pA_B_P, ShortCuts.kbNoKey);
      MoveRect(R, 0, DY);
      (* alarm waski w profilu A *)
      Make4(R, bAlarmWaski_pA, AlarmWaski_pA_A_L, ShortCuts.kbNoKey,
            AlarmWaski_pA_A_P, ShortCuts.kbNoKey, AlarmWaski_pA_B_L,
            ShortCuts.kbNoKey, AlarmWaski_pA_B_P, ShortCuts.kbNoKey);
      MoveRect(R, 0, DY);
      (* Markery *)
      Make4(R, bMarker, Marker_A_L, ShortCuts.kbNoKey, Marker_A_P,
            ShortCuts.kbNoKey, Marker_B_L, ShortCuts.kbNoKey, Marker_B_P,
            ShortCuts.kbNoKey);
      MoveRect(R, 0, DY);
      INC(R.right, DX);
      (* Ustawienie Osi, struktura *)
      Make2(R, bUstawienieOsi_Struktura, UstawienieOsi_Struktura_A,
            ShortCuts.kbNoKey, UstawienieOsi_Struktura_B, ShortCuts.kbNoKey);
      MoveRect(R, 0, DY);
      (* Ustawienie Osi dla Alarmu szerokiego w prof. A *)
      Make2(R, bUstawienieOsi_Szer_pA, UstawienieOsi_Szer_pA_A,
            ShortCuts.kbNoKey, UstawienieOsi_Szer_pA_B, ShortCuts.kbNoKey);
      MoveRect(R, 0, DY);
      (* Ustawienie Osi dla Alarmu waskiego w prof. A *)
      Make2(R, bUstawienieOsi_Waski_pA, UstawienieOsi_Waski_pA_A,
            ShortCuts.kbNoKey, UstawienieOsi_Waski_pA_B, ShortCuts.kbNoKey);
      MoveRect(R, 0, DY);
      (* Pomiar szerokosci sektora, wyrazistosci i ust. osi w prof. B *)
      Make2(R, bSzer_i_Osi_pB, Szer_i_Osi_pB_A, ShortCuts.kbNoKey,
            Szer_i_Osi_pB_B, ShortCuts.kbNoKey);
      MoveRect(R, 0, DY);
      (* Alarm szeroki ust. osi w prof. B *)
      Make2(R, bAlarmSzer_pB, AlarmSzer_pB_A, ShortCuts.kbNoKey, AlarmSzer_pB_B
            , ShortCuts.kbNoKey);
      MoveRect(R, 0, DY);
      (* Alarm Waski ust. osi w prof. B *)
      Make2(R, bAlarmWaski_pB, AlarmWaski_pB_A, ShortCuts.kbNoKey,
            AlarmWaski_pB_B, ShortCuts.kbNoKey);
      MoveRect(R, 0, DY);
      (* Rownowaga modulacji *)
      Make2(R, bRownowagaModulacji, RownowagaModulacji_A, ShortCuts.kbNoKey,
            RownowagaModulacji_B, ShortCuts.kbNoKey);
      MoveRect(R, 0, DY);
      (* Fazowanie *)
      Make2(R, bFazowanie, Fazowanie_A, ShortCuts.kbNoKey, Fazowanie_B,
            ShortCuts.kbNoKey);
      MoveRect(R, 0, DY);
      (* Wyrazistosc na duzych katach *)
      Make2(R, bWyrazistosc_na_d_katach, Wyrazistosc_na_d_katach_A,
            ShortCuts.kbNoKey, Wyrazistosc_na_d_katach_B, ShortCuts.kbNoKey);
      MoveRect(R, 0, DY);
      (* Zasieg do 10 stopni *)
      Make2(R, bZasieg_do_10, Zasieg_do_10_A, ShortCuts.kbNoKey, Zasieg_do_10_B
            , ShortCuts.kbNoKey);
      MoveRect(R, 0, DY);
      (* Zasieg od 10 do 35 stopni *)
      Make2(R, bZasieg_10_35, Zasieg_10_35_A, ShortCuts.kbNoKey, Zasieg_10_35_B
            , ShortCuts.kbNoKey);
      MoveRect(R, 0, DY);
      (* Zasieg ponad 35 stopni *)
      Make2(R, bZasieg_ponad_35, Zasieg_ponad_35_A, ShortCuts.kbNoKey,
            Zasieg_ponad_35_B, ShortCuts.kbNoKey);
      MoveRect(R, 0, DY);
      IF PI_PA.PomiarANieArchiwum THEN
        Make5('Punkty A, B, C(TH), D, E', R, bIdentPunktow, IdentPkt0,
              ShortCuts.kbNoKey, IdentPkt1, ShortCuts.kbNoKey, IdentPkt2,
              ShortCuts.kbNoKey, IdentPkt3, ShortCuts.kbNoKey, IdentPkt4,
              ShortCuts.kbNoKey);
      END;
      MoveRect(R, 0, DY);
      R1 := R;
      (* Glowny odbiornik *)
      WstawButton(hDlg, R, "", -1, ShortCuts.kbAltY, GlowOdbP, GlowOdb);
      (* Odniesiebie dla pomiaru bledu *)
      MoveRect(R, 0, DY);
      WstawButton(hDlg, R, "", -1, ShortCuts.kbAltA, OdnAzymutP,
                         OdnAzymut);
      (* Odniesiebie dla pomiaru odleglosci MoveRect( R, 0, DY );
         WstawButton( hDlg, R, "", -1, ShortCuts.kbAltL, OdnOdlP, OdnOdl
         ); *)
      MoveRect(R, 0, DY);
      IF PI_PA.PomiarANieArchiwum THEN
        WstawInpLine(hDlg, R.left, R.top, 12, RealValid, WHITE, BLUE,
                            lOdl_dla_pom_pB);
        WrStr("OdlegàoòÜ dla profilu B [NM]", R.right + 5, R.top + 3, BROWN,
              BROWN);
      END;
      (*
      MoveRect(R, 0, DY);
      WstawInpLine(hDlg, R.left, R.top, 12, RealValid, WHITE, BLUE,
                          lSzer_sekt_kier);
      WrStr("SzerokoòÜ sektora", R.right + 5, R.top + 3, BROWN, BROWN);
      *)
      MoveRect(R, 0, DY);
      IF PI_PA.PomiarANieArchiwum THEN
        WstawInpLine(hDlg, R.left, R.top, 12, RealCisnValid, WHITE,
                            MAGENTA, lCisnienieOdn);
        WrStr("Ciònienie odniesienia", R.right+5, R.top, MAGENTA, MAGENTA);
      END;
      MoveRect(R1, 4 * DX, 0);
      (* Guzik wlaczajacy *)
      AssignRect(RDummy, 800, 600, 810, 610);
      R := R1;
      IF PI_PA.PomiarANieArchiwum
      THEN
        WstawButton(hDlg, R1, "POMIAR", 0, ShortCuts.kbAltP, PomiarP,
                           Pomiar);
        WstawButton(hDlg, RDummy, "", -1, ShortCuts.kbEnter, PomiarP,
                           Pomiar);
        MoveRect(R1, 2 * DX, 0);
        WstawButton(hDlg, R1, "TEST", 0, ShortCuts.kbAltT, TestUP_PROC,
                           TestUP);
      ELSE
        WstawButton(hDlg, R1, "DYNAMICZ", 0, ShortCuts.kbAltD, DrukDynaP
                           , Pomiar);
        MoveRect(R1, 2 * DX, 0);
        WstawButton(hDlg, R1, "STATYCZ", 1, ShortCuts.kbAltT, DrukStatP,
                           TestUP);
      END (* if PomiarNieArchiwum *);
      MoveRect(R, 0, DY);
      R1 := R;
      WstawButton(hDlg, R1, "RAPORT", 0, ShortCuts.kbAltR, DrukRaportP,
                         Raport);
      MoveRect(R1, 2 * DX, 0);
      WstawButton(hDlg, R1, "KONIEC", 0, ShortCuts.kbAltK, AltF4,
                         void);
      WstawButton(hDlg, RDummy, "", -1, ShortCuts.kbAltF4, AltF4,
                         void);
      IF NOT PI_PA.PomiarANieArchiwum THEN
        MoveRect(R, 0, DY);
        R1 := R;
        WstawButton( hDlg, R1, "LOC RAP. KO„COWY", -1, ShortCuts.kbAltF5,
                            RaportKoncowy, void );
        MoveRect( R1, 2 * DX, 0 );
        WstawButton( hDlg, R1, "DME RAP. KO„COWY", -1, ShortCuts.kbAltF6,
                            RaportKoncowy_DME, void );
      END;
    END AssignButt;

  VAR
    r    : REAL;
    Prom : ARRAY [0..0] OF CARDINAL;
  BEGIN (* InitLot *)
    IF Lotnisko.OdlMarkerow[OMkr] = DisNilVal  THEN
      outMkrStr := ' 5.00'
    ELSE
      Card500Str(Lotnisko.OdlMarkerow[OMkr]+Lotnisko.ProgPasa, outMkrStr, 7);
    END;
    RedrawScr := TRUE;
    AssignRect(R, 0, 0, 800, 599);
    hDlg := TworzDialog(R, "loc-co.bmp", FALSE);
    AssignButt;
    CoRobimy := czPomiar;
    (* WypelnicListeOblotow;*)
    (* ZmienOblot(0);*)
    FillData;
    InitDefault;
    IF PI_PA.PomiarANieArchiwum THEN
      FOR i := MIN(ZoneBoundPt) TO MAX(ZoneBoundPt) DO
        IdentPkt(i);
      END (* for i *);
    END;
    OdnOdlP;
    OdnAzymutP;
    GlowOdbP;
    (* FillData; *)
    RedrawScr := FALSE;
    kont := Go(hDlg);
    IF PI_PA.PomiarANieArchiwum THEN
      r := RealVal(lOdl_dla_pom_pB);
      Odl_dla_pom_pB := TRUNC( r * 500.0 + 0.5);
      CisnienieOdniesienia := RealVal(lCisnienieOdn);
      SaveDefault;
    END;
    StalyKat := Lotnisko.KierunekPasa+180;
    IF (StalyKat >= 360) THEN
      DEC( StalyKat, 360 );
    END;
    Prom[0] := 0FFFFH;
    Mapa.Promienie( Prom, Prom, StalyKat );
    StalyKat := Angle100( StalyKat );
    UsunDialog(hDlg);
    Assert(OdnDlaPomBledu <> pbnieZdef);
    SciezkaDoKataloguOpisu();
    RETURN kont;
  END InitLot;

  PROCEDURE SciezkaDoKataloguOpisu();
  VAR
    nad,
    strona : CHAR;
    Fmt,
    Tmp    : ARRAY [0 .. 128] OF CHAR;
    i      : CARDINAL;

  BEGIN
    Assign(NazwaPlikuOpisu, SciezkaOpisuPomiaru);
    SciezkaOpisuPomiaru[Length(SciezkaOpisuPomiaru) - 12] := 0C;   (* skasowana
                                                                      nazwa
                                                                      "oblt-loc.ini"
                                                                   *)
    nad := NadajnikCH();
    strona := StronaCH();
    IF (Procedura <= pAlarmWaski_pA) OR (Procedura = pMarker)
    THEN
      Fmt := '%03d_%c_%c.loc'
    ELSE
      Fmt := '%03d_%c.loc'
    END (* if *);
    i := ORD(Procedura);
    sprintf3(Tmp, Fmt, i, nad, strona);   (* Kartoteka o postaci 1_A_L.loc *)
    Insert(Tmp, SciezkaOpisuPomiaru, 0FFFH);
    Insert('\', SciezkaOpisuPomiaru, 0FFFH);
  END SciezkaDoKataloguOpisu;

  PROCEDURE Wlacz_Wylacz();
  VAR
    Tmp : ARRAY [0 .. 127] OF CHAR;
    en  : BOOLEAN;

  BEGIN
    SciezkaDoKataloguOpisu();
    Assign(SciezkaOpisuPomiaru, Tmp);
    Tmp[Length(Tmp) - 1] := 0C;
    en := Files.ExistDIR(Tmp);
    IF NOT PI_PA.PomiarANieArchiwum
    THEN
      Buttons.EnableButton(Pomiar, en);
      Buttons.EnableButton(TestUP, en);
    END (* if *);
    Buttons.EnableButton(Raport, en);
  END Wlacz_Wylacz;

  (*
  PROCEDURE WstawDoListyOblotow
            ( VAR nazwa : ARRAY OF CHAR );

  BEGIN
    GList.DodajDoListy(ListaOblotow, nazwa);
  END WstawDoListyOblotow;
  *)

  PROCEDURE AlarmOsi_A_L();

  BEGIN
    Procedura := pAlarmOsi;
    Strona := sL75;
    Nadajnik1 := nA;
    Wlacz_Wylacz();
  END AlarmOsi_A_L;

  PROCEDURE AlarmOsi_A_P();

  BEGIN
    Procedura := pAlarmOsi;
    Strona := sP75;
    Nadajnik1 := nA;
    Wlacz_Wylacz();
  END AlarmOsi_A_P;

  PROCEDURE AlarmOsi_B_L();

  BEGIN
    Procedura := pAlarmOsi;
    Strona := sL75;
    Nadajnik1 := nB;
    Wlacz_Wylacz();
  END AlarmOsi_B_L;

  PROCEDURE AlarmOsi_B_P();

  BEGIN
    Procedura := pAlarmOsi;
    Strona := sP75;
    Nadajnik1 := nB;
    Wlacz_Wylacz();
  END AlarmOsi_B_P;

  PROCEDURE SzerSektora_pA_A_L();

  BEGIN
    Procedura := pSzerSektora_pA;
    Strona := sL75;
    Nadajnik1 := nA;
    Wlacz_Wylacz();
  END SzerSektora_pA_A_L;

  PROCEDURE SzerSektora_pA_A_P();

  BEGIN
    Procedura := pSzerSektora_pA;
    Strona := sP75;
    Nadajnik1 := nA;
    Wlacz_Wylacz();
  END SzerSektora_pA_A_P;

  PROCEDURE SzerSektora_pA_B_L();

  BEGIN
    Procedura := pSzerSektora_pA;
    Strona := sL75;
    Nadajnik1 := nB;
    Wlacz_Wylacz();
  END SzerSektora_pA_B_L;

  PROCEDURE SzerSektora_pA_B_P();

  BEGIN
    Procedura := pSzerSektora_pA;
    Strona := sP75;
    Nadajnik1 := nB;
    Wlacz_Wylacz();
  END SzerSektora_pA_B_P;

  PROCEDURE AlarmSzeroki_pA_A_L();

  BEGIN
    Procedura := pAlarmSzeroki_pA;
    Strona := sL75;
    Nadajnik1 := nA;
    Wlacz_Wylacz();
  END AlarmSzeroki_pA_A_L;

  PROCEDURE AlarmSzeroki_pA_A_P();

  BEGIN
    Procedura := pAlarmSzeroki_pA;
    Strona := sP75;
    Nadajnik1 := nA;
    Wlacz_Wylacz();
  END AlarmSzeroki_pA_A_P;

  PROCEDURE AlarmSzeroki_pA_B_L();

  BEGIN
    Procedura := pAlarmSzeroki_pA;
    Strona := sL75;
    Nadajnik1 := nB;
    Wlacz_Wylacz();
  END AlarmSzeroki_pA_B_L;

  PROCEDURE AlarmSzeroki_pA_B_P();

  BEGIN
    Procedura := pAlarmSzeroki_pA;
    Strona := sP75;
    Nadajnik1 := nB;
    Wlacz_Wylacz();
  END AlarmSzeroki_pA_B_P;

  PROCEDURE AlarmWaski_pA_A_L();

  BEGIN
    Procedura := pAlarmWaski_pA;
    Strona := sL75;
    Nadajnik1 := nA;
    Wlacz_Wylacz();
  END AlarmWaski_pA_A_L;

  PROCEDURE AlarmWaski_pA_A_P();

  BEGIN
    Procedura := pAlarmWaski_pA;
    Strona := sP75;
    Nadajnik1 := nA;
    Wlacz_Wylacz();
  END AlarmWaski_pA_A_P;

  PROCEDURE AlarmWaski_pA_B_L();

  BEGIN
    Procedura := pAlarmWaski_pA;
    Strona := sL75;
    Nadajnik1 := nB;
    Wlacz_Wylacz();
  END AlarmWaski_pA_B_L;

  PROCEDURE AlarmWaski_pA_B_P();

  BEGIN
    Procedura := pAlarmWaski_pA;
    Strona := sP75;
    Nadajnik1 := nB;
    Wlacz_Wylacz();
  END AlarmWaski_pA_B_P;

  PROCEDURE UstawienieOsi_Struktura_A();

  BEGIN
    Procedura := pUstawienieOsi_Struktura;
    Nadajnik1 := nA;
    Wlacz_Wylacz();
  END UstawienieOsi_Struktura_A;

  PROCEDURE UstawienieOsi_Struktura_B();

  BEGIN
    Procedura := pUstawienieOsi_Struktura;
    Nadajnik1 := nB;
    Wlacz_Wylacz();
  END UstawienieOsi_Struktura_B;

  PROCEDURE UstawienieOsi_Szer_pA_A();

  BEGIN
    Procedura := pUstawienieOsi_Szer_pA;
    Nadajnik1 := nA;
    Wlacz_Wylacz();
  END UstawienieOsi_Szer_pA_A;

  PROCEDURE UstawienieOsi_Szer_pA_B();

  BEGIN
    Procedura := pUstawienieOsi_Szer_pA;
    Nadajnik1 := nB;
    Wlacz_Wylacz();
  END UstawienieOsi_Szer_pA_B;

  PROCEDURE UstawienieOsi_Waski_pA_A();

  BEGIN
    Procedura := pUstawienieOsi_Waski_pA;
    Nadajnik1 := nA;
    Wlacz_Wylacz();
  END UstawienieOsi_Waski_pA_A;

  PROCEDURE UstawienieOsi_Waski_pA_B();

  BEGIN
    Procedura := pUstawienieOsi_Waski_pA;
    Nadajnik1 := nB;
    Wlacz_Wylacz();
  END UstawienieOsi_Waski_pA_B;

  PROCEDURE Szer_i_Osi_pB_A();

  BEGIN
    Procedura := pSzer_i_Osi_pB;
    Nadajnik1 := nA;
    Wlacz_Wylacz();
    IF PI_PA.PomiarANieArchiwum THEN
      InpLine.SetText(lOdl_dla_pom_pB, outMkrStr);
    END;
  END Szer_i_Osi_pB_A;

  PROCEDURE Szer_i_Osi_pB_B();

  BEGIN
    Procedura := pSzer_i_Osi_pB;
    Nadajnik1 := nB;
    Wlacz_Wylacz();
    IF PI_PA.PomiarANieArchiwum THEN
      InpLine.SetText(lOdl_dla_pom_pB, outMkrStr);
    END;
  END Szer_i_Osi_pB_B;

  PROCEDURE AlarmSzer_pB_A();

  BEGIN
    Procedura := pAlarmSzer_pB;
    Nadajnik1 := nA;
    Wlacz_Wylacz();
    IF PI_PA.PomiarANieArchiwum THEN
      InpLine.SetText(lOdl_dla_pom_pB, outMkrStr);
    END;
  END AlarmSzer_pB_A;

  PROCEDURE AlarmSzer_pB_B();

  BEGIN
    Procedura := pAlarmSzer_pB;
    Nadajnik1 := nB;
    Wlacz_Wylacz();
    IF PI_PA.PomiarANieArchiwum THEN
      InpLine.SetText(lOdl_dla_pom_pB, outMkrStr);
    END;
  END AlarmSzer_pB_B;

  PROCEDURE AlarmWaski_pB_A();

  BEGIN
    Procedura := pAlarmWaski_pB;
    Nadajnik1 := nA;
    Wlacz_Wylacz();
    IF PI_PA.PomiarANieArchiwum THEN
      InpLine.SetText(lOdl_dla_pom_pB, outMkrStr);
    END;
  END AlarmWaski_pB_A;

  PROCEDURE AlarmWaski_pB_B();

  BEGIN
    Procedura := pAlarmWaski_pB;
    Nadajnik1 := nB;
    Wlacz_Wylacz();
    IF PI_PA.PomiarANieArchiwum THEN
      InpLine.SetText(lOdl_dla_pom_pB, outMkrStr);
    END;
  END AlarmWaski_pB_B;

  PROCEDURE RownowagaModulacji_A();

  BEGIN
    Procedura := pRownowagaModulacji;
    Nadajnik1 := nA;
    Wlacz_Wylacz();
  END RownowagaModulacji_A;

  PROCEDURE RownowagaModulacji_B();

  BEGIN
    Procedura := pRownowagaModulacji;
    Nadajnik1 := nB;
    Wlacz_Wylacz();
  END RownowagaModulacji_B;

  PROCEDURE Fazowanie_A();

  BEGIN
    Procedura := pFazowanie;
    Nadajnik1 := nA;
    Wlacz_Wylacz();
  END Fazowanie_A;

  PROCEDURE Fazowanie_B();

  BEGIN
    Procedura := pFazowanie;
    Nadajnik1 := nB;
    Wlacz_Wylacz();
  END Fazowanie_B;

  PROCEDURE Wyrazistosc_na_d_katach_A();
    (* MP procedura byla pusta *)

  BEGIN
    Procedura := pWyrazistosc_na_d_katach;
    Nadajnik1 := nA;
    Wlacz_Wylacz();
    IF PI_PA.PomiarANieArchiwum THEN
      InpLine.SetText(lOdl_dla_pom_pB, outMkrStr);
    END;
  END Wyrazistosc_na_d_katach_A;

  PROCEDURE Wyrazistosc_na_d_katach_B();

  BEGIN
    Procedura := pWyrazistosc_na_d_katach;
    Nadajnik1 := nB;
    Wlacz_Wylacz();
    IF PI_PA.PomiarANieArchiwum THEN
      InpLine.SetText(lOdl_dla_pom_pB, outMkrStr);
    END;
  END Wyrazistosc_na_d_katach_B;

  PROCEDURE Zasieg_do_10_A();

  BEGIN
    Procedura := pZasieg_do_10;
    Nadajnik1 := nA;
    Wlacz_Wylacz();
    IF PI_PA.PomiarANieArchiwum THEN
      InpLine.SetText(lOdl_dla_pom_pB, '   25.00');
    END;
  END Zasieg_do_10_A;

  PROCEDURE Zasieg_do_10_B();

  BEGIN
    Procedura := pZasieg_do_10;
    Nadajnik1 := nB;
    Wlacz_Wylacz();
    IF PI_PA.PomiarANieArchiwum THEN
      InpLine.SetText(lOdl_dla_pom_pB, '   25.00');
    END;
  END Zasieg_do_10_B;

  PROCEDURE Zasieg_10_35_A();

  BEGIN
    Procedura := pZasieg_10_35;
    Nadajnik1 := nA;
    Wlacz_Wylacz();
    IF PI_PA.PomiarANieArchiwum THEN
      InpLine.SetText(lOdl_dla_pom_pB, '   17.00');
    END;
  END Zasieg_10_35_A;

  PROCEDURE Zasieg_10_35_B();

  BEGIN
    Procedura := pZasieg_10_35;
    Nadajnik1 := nB;
    Wlacz_Wylacz();
    IF PI_PA.PomiarANieArchiwum THEN
      InpLine.SetText(lOdl_dla_pom_pB, '   17.00');
    END;
  END Zasieg_10_35_B;

  PROCEDURE Zasieg_ponad_35_A();

  BEGIN
    Procedura := pZasieg_ponad_35;
    Nadajnik1 := nA;
    Wlacz_Wylacz();
    IF PI_PA.PomiarANieArchiwum THEN
      InpLine.SetText(lOdl_dla_pom_pB, '   10.00');
    END;
  END Zasieg_ponad_35_A;

  PROCEDURE Zasieg_ponad_35_B();

  BEGIN
    Procedura := pZasieg_ponad_35;
    Nadajnik1 := nB;
    Wlacz_Wylacz();
    IF PI_PA.PomiarANieArchiwum THEN
      InpLine.SetText(lOdl_dla_pom_pB, '   10.00');
    END;
  END Zasieg_ponad_35_B;

  PROCEDURE Marker_A_L();

  BEGIN
    Procedura := pMarker;
    Strona := sL75;
    Nadajnik1 := nA;
    Wlacz_Wylacz();
  END Marker_A_L;

  PROCEDURE Marker_A_P();

  BEGIN
    Procedura := pMarker;
    Strona := sP75;
    Nadajnik1 := nA;
    Wlacz_Wylacz();
  END Marker_A_P;

  PROCEDURE Marker_B_L();

  BEGIN
    Procedura := pMarker;
    Strona := sL75;
    Nadajnik1 := nB;
    Wlacz_Wylacz();
  END Marker_B_L;

  PROCEDURE Marker_B_P();

  BEGIN
    Procedura := pMarker;
    Strona := sP75;
    Nadajnik1 := nB;
    Wlacz_Wylacz();
  END Marker_B_P;

  PROCEDURE IdentPkt
            (    i : NumPunktu );
  VAR
    ip : CARDINAL;
    s  : ARRAY [0 .. 20] OF CHAR;

  BEGIN
    IF NOT RedrawScr
    THEN
      ip := ORD(IdentPunktow[i]);
      IF i <= np_B
      THEN
        ip := (ip + 1) MOD (ORD(MAX(IdentPunktowT)));
      ELSE
        ip := (ip + 1) MOD 2;
      END (* if i *);
      IdentPunktow[i] := VAL(IdentPunktowT, ip);
    END (* if *);
    CASE IdentPunktow[i] OF
      ipGPS :
        s := 'GPS';
      |
      ipZnacznikiPilota :
        s := 'ZNACZNIK';
      |
      ipMarkery :
        s := 'MARKER';
    END (* case IdentPunktow *);
    Buttons.ChangeButtonText(bIdentPunktow[i], s);
  END IdentPkt;

  PROCEDURE IdentPkt0();

  BEGIN
    IdentPkt(np_A);
  END IdentPkt0;

  PROCEDURE IdentPkt1();

  BEGIN
    IdentPkt(np_B);
  END IdentPkt1;

  PROCEDURE IdentPkt2();

  BEGIN
    IdentPkt(np_CorT);
  END IdentPkt2;

  PROCEDURE IdentPkt3();

  BEGIN
    IdentPkt(np_D);
  END IdentPkt3;

  PROCEDURE IdentPkt4();

  BEGIN
    IdentPkt(np_E);
  END IdentPkt4;

  PROCEDURE TestUP_PROC;

  BEGIN
    CoRobimy := czTest;
    EndDialog(TRUE);
  END TestUP_PROC;

  PROCEDURE DrukStatP();

  BEGIN
    CoRobimy := czPreview;
    EndDialog(TRUE);
  END DrukStatP;

  PROCEDURE DrukRaportP();

  BEGIN
    CoRobimy := czDrukR;
    EndDialog(TRUE);
  END DrukRaportP;

  PROCEDURE DrukDynaP();

  BEGIN
    CoRobimy := czPlay;
    EndDialog(TRUE);
  END DrukDynaP;

  PROCEDURE RaportKoncowy(  );
    BEGIN
      CoRobimy := czRaportKoncowy;
      EndDialog( TRUE );
    END RaportKoncowy;

  PROCEDURE RaportKoncowy_DME(  );
    BEGIN
      CoRobimy := czRaportKoncowy_DME;
      EndDialog( TRUE );
    END RaportKoncowy_DME;

  PROCEDURE RealVal
            (    l : InpLine.HLINE ) : REAL;
  VAR
    s  : ARRAY [0 .. 99] OF CHAR;
    r  : REAL;
    ok : BOOLEAN;

  BEGIN
    InpLine.GetText(l, s);
    StringToReal(s, r, ok);
    Assert(ok);
    RETURN r;
  END RealVal;

  PROCEDURE Sz_Sekt;
  VAR
    s : ARRAY [0 .. 2] OF CARDINAL;
    t : ARRAY [0 .. 2] OF MsgBox.But_Napis;
    r : CARDINAL;

  BEGIN
    t[0] := "75";
    t[1] := "150";
    t[2] := "Zadna";
    s[0] := ShortCuts.kbAlt7;
    s[1] := ShortCuts.kbAlt1;
    s[2] := ShortCuts.kbAltZ;
    r := MsgBox.AdvInfo("Z jak• szerokoòci• sektora", 3, t, s, 2);
    Assert((Strona = sL75) OR (Strona = sP75));
    CASE r OF
      2 :
        RETURN;
      |
      1 :
        IF Strona = sL75
        THEN
          Strona := sL150;
        ELSE
          Strona := sP150;
        END (* if Strona *);
      |
      0 :
      (* nic nie trzeba *)
    END (* case r *);
    EndDialog(TRUE);
  END Sz_Sekt;

  PROCEDURE ValidReal
            (     l         : InpLine.HLINE;
              VAR s         : ARRAY OF CHAR;
                  KillFocus : BOOLEAN       ) : BOOLEAN;
  VAR
    r  : REAL;
    ok : BOOLEAN;
    i  : ARRAY [0 .. 99] OF CHAR;

  BEGIN
    IF KillFocus
    THEN
      StringToReal(s, r, ok);
      IF NOT ok
      THEN
        i := "Napis nie jest liczb• rzeczywist•";
      ELSIF ABS(r) > 180.0
      THEN
        i := "Wprowadzona liczba jest zbyt duæa lub zbyt maàa";
        ok := FALSE;
      END (* if *);
      IF NOT ok
      THEN
        Pokaz(i, 5000);
      END (* if *);
      RETURN ok;
    ELSE
      RETURN TRUE;
    END (* if KillFocus *);
  END ValidReal;

  PROCEDURE Szer_Sekt;
  VAR
    Ask                : HDLG;
    R                  : RECT;
    Rdlg               : RECT;
    okB                : Buttons.Button;
    s                  : ARRAY [0 .. 99] OF CHAR;
    ok                 : BOOLEAN;
    Linia_Szer_sektora : InpLine.HLINE;
    r                  : REAL;

  BEGIN
    AssignRect(Rdlg, 230, 100, 570, 250);
    Ask := TworzDialog(Rdlg, "sz-sekt.bmp", TRUE);
    AssignRect(R, 1000, 1000, 1000, 1000);
    WstawButton(Ask, R, "", 0, ShortCuts.kbEnter, ProbujWstawicOblot,
                       okB);
    AssignRect(R, 10, 70, 90, 100);
    WstawButton(Ask, R, "OK", 0, ShortCuts.kbAltO, ProbujWstawicOblot,
                       okB);
    MoveRect(R, 100, 0);
    WstawButton(Ask, R, "WYJóCIE", 0, ShortCuts.kbAltW, AltF4,
                       okB);
    WstawInpLine(Ask, 10, 40, 27, ValidReal, WHITE, MAGENTA,
                        Linia_Szer_sektora);
    IF (Procedura = pAlarmOsi) OR (Procedura = pUstawienieOsi_Struktura)
    THEN
      WrStr("SzerokoòÜ sektora", Rdlg.left + 5, Rdlg.top + 5, WHITE, WHITE);
      r := real(Lotnisko.Szer_Sekt) / 100.0 + 0.001;
         (* przy konwersji na str brakowalo czasami 0.01 - to moze byc blad 
            biblioteki albo reprezentacji *)
    ELSIF (Procedura = pUstawienieOsi_Szer_pA)
    THEN
      WrStr("Sektor w alarmie szerokim", Rdlg.left + 5, Rdlg.top + 5, WHITE,
            WHITE);
      r := real(Lotnisko.Szer_Sekt_Szer) / 100.0;   (* Szer_Sekt * 1.14*)
    ELSIF (Procedura = pUstawienieOsi_Waski_pA)
    THEN
      WrStr("Sektor w alarmie w•skim", Rdlg.left + 5, Rdlg.top + 5, WHITE,
            WHITE);
      r := real(Lotnisko.Szer_Sekt_Waski) / 100.0;   (* Szer_Sekt * 0.86*)
    END (* if *);
    RealToString(r, 2, 6, s, ok);
    InpLine.SetText(Linia_Szer_sektora, s);
    Assert(ok);
    IF Go(Ask)
    THEN
      InpLine.GetText(Linia_Szer_sektora, s);
      StringToReal(s, r, ok);
      Assert(ok);
      Szer_sekt_kier := entier(r * 100.0);
      UsunDialog(Ask);
      EndDialog(TRUE);   (* dialog macierzysty *)
    ELSE
      UsunDialog(Ask);
    END (* if Go *);
  END Szer_Sekt;

  PROCEDURE PomiarP();
  VAR

  BEGIN
    CoRobimy := czPomiar;
    IF (Procedura = pSzerSektora_pA) OR (Procedura = pAlarmSzeroki_pA) OR
       (Procedura = pAlarmWaski_pA)
    THEN
      EnableDlg(hDlg, FALSE);
      STARTPROCESS(Sz_Sekt, 0D00H, 0);
    ELSIF (Procedura = pAlarmOsi) OR (Procedura = pUstawienieOsi_Struktura) OR
          (Procedura = pUstawienieOsi_Szer_pA) OR
          (Procedura = pUstawienieOsi_Waski_pA)
    THEN
    (* IF (Procedura = pAlarmOsi ) OR (Procedura = pUstawienieOsi_Struktura)
       THEN Szer_sekt_kier := Lotnisko.AlarmOsi; ELSIF (Procedura =
       pUstawienieOsi_Szer_pA) THEN Szer_sekt_kier := Lotnisko.Szer_Sekt_Szer;
       ELSIF (Procedura = pUstawienieOsi_Waski_pA) THEN Szer_sekt_kier :=
       Lotnisko.Szer_Sekt_Waski; END; EndDialog( TRUE ); *)
      EnableDlg(hDlg, FALSE);
      STARTPROCESS(Szer_Sekt, 01000H, 0);
    ELSE
      EndDialog(TRUE);
    END (* if *);
  END PomiarP;

  PROCEDURE GlowOdbP;
  VAR
    i : CARDINAL;

  BEGIN
    i := ORD(GlownyOdbiornik);
    IF NOT RedrawScr
    THEN
      i := (i + 1) MOD (ORD(MAX(GlownyOdbiornikT)) + 1);
      GlownyOdbiornik := VAL(GlownyOdbiornikT, i);
    END (* if *);
    CASE i OF
      0 :
        Buttons.ChangeButton(GlowOdb, "Odb. `A'", -1);
      |
      1 :
        Buttons.ChangeButton(GlowOdb, "Odb. `B'", -1);
    END (* case i *);
  END GlowOdbP;

  PROCEDURE OdnAzymutP;
  VAR
    i : CARDINAL;

  BEGIN
    i := ORD(OdnDlaPomBledu);
    IF NOT RedrawScr
    THEN
      i := (i + 1) MOD (ORD(MAX(OdnDlaPomBleduT)) + 1);
      IF i = 0
      THEN
        INC(i);
      END (* if i *);
      OdnDlaPomBledu := VAL(OdnDlaPomBleduT, i);
    END (* if *);
    CASE i OF
      0 :
        Buttons.ChangeButton(OdnAzymut, " ------------------", -1);
      |
      1 :
        Buttons.ChangeButton(OdnAzymut, "Odniesienie Teodolit", -1);
      |
      2 :
        Buttons.ChangeButton(OdnAzymut, "Odniesienie GPS", -1);
    END (* case i *);
  END OdnAzymutP;

  PROCEDURE OdnOdlP;
  VAR
    i : CARDINAL;

  BEGIN
    OdnDlaPomOdl := poGPS;
    RETURN;
    i := ORD(OdnDlaPomOdl);
    IF NOT RedrawScr
    THEN
      i := (i + 1) MOD (ORD(MAX(L_OdnDlaPomOdlT)) + 1);
      OdnDlaPomOdl := VAL(L_OdnDlaPomOdlT, i);
    END (* if *);
    CASE i OF
      0 :
        Buttons.ChangeButton(OdnOdl, "DME `A'", -1);
      |
      1 :
        Buttons.ChangeButton(OdnOdl, "DME `B'", -1);
      |
      2 :
        Buttons.ChangeButton(OdnOdl, "GPS", -1);
      |
      3 :
        Buttons.ChangeButton(OdnOdl, "Markery", -1);
    END (* case i *);
  END OdnOdlP;

  PROCEDURE RealValid
            (     l         : InpLine.HLINE;
              VAR s         : ARRAY OF CHAR;
                  KillFocus : BOOLEAN       ) : BOOLEAN;
  VAR
    r  : REAL;
    ok : BOOLEAN;
    i  : ARRAY [0 .. 99] OF CHAR;

  BEGIN
    IF KillFocus THEN
      StringToReal(s, r, ok);
      IF NOT ok
      THEN
        i := "Napis nie jest liczb• rzeczywist•";
      ELSIF KillFocus & ((r < 1.0) OR (r > 70.0))
      THEN
        i := "Wprowadzona liczba jest zbyt duæa lub zbyt maàa";
        ok := FALSE;
      END (* if *);
      IF NOT ok
      THEN
        Pokaz(i, 5000);
      END (* if *);
      RETURN ok;
    ELSE
      RETURN TRUE;
    END;
  END RealValid;

  PROCEDURE FillData;

    PROCEDURE CzytajParametry
              ( VAR Entry : ARRAY OF CHAR;
                    but   : Buttons.Button );
    VAR
      s : ARRAY [0 .. 99] OF CHAR;

    BEGIN
      GetPrivateProfileString(NazwaOblotu, Entry, "@@", s, NazwaPlikuOpisu);
      IF s[0] = '@'
      THEN
        s := '----';
      ELSE
        s[7] := 0C;
      END (* if s *);
      Buttons.ChangeButtonText(but, s);
    END CzytajParametry;

    PROCEDURE CzytajParametryABLP
              (    EntryTmp : ARRAY OF CHAR;
                   but      : A_B_lewa_prawa );
    VAR
      e,
      s : ARRAY [0 .. 99] OF CHAR;
      a : ADDRESS;

    CONST
      fmt = "%s.%c.%c";

    BEGIN
      Assign(EntryTmp, e);
      a := ADR(e);
      sprintf3(s, fmt, a, 'A', 'L');
      CzytajParametry(s, but.A.lewa);
      sprintf3(s, fmt, a, 'A', 'P');
      CzytajParametry(s, but.A.prawa);
      sprintf3(s, fmt, a, 'B', 'L');
      CzytajParametry(s, but.B.lewa);
      sprintf3(s, fmt, a, 'B', 'P');
      CzytajParametry(s, but.B.prawa);
    END CzytajParametryABLP;

    PROCEDURE CzytajParametryAB
              (    EntryTmp : ARRAY OF CHAR;
                   but      : A_B           );
    VAR
      e,
      s : ARRAY [0 .. 99] OF CHAR;
      a : ADDRESS;

    CONST
      fmt = "%s.%c";

    BEGIN
      Assign(EntryTmp, e);
      a := ADR(e);
      sprintf2(s, fmt, a, 'A');
      CzytajParametry(s, but.A);
      sprintf2(s, fmt, a, 'B');
      CzytajParametry(s, but.B);
    END CzytajParametryAB;
  VAR
    s,
    l  : ARRAY [0 .. 99] OF CHAR;
    ok : BOOLEAN;
    a1,
    a2 : ADDRESS;

  BEGIN
    NazwaUrzadz2 := '';
    a1 := ADR(s);
    a2 := ADR(NazwaUrzadz1);
    OpisLotniska(NazwaUrzadz1, NazwaPlikuOpisu, TRUE);
    IF PI_PA.PomiarANieArchiwum THEN
      TuneILS(AReceiver, Lotnisko.Czestotliwosc, TRUE);
      TuneILS(BReceiver, Lotnisko.Czestotliwosc, TRUE);
      TuneDMEforILS(AReceiver, Lotnisko.Czestotliwosc);
      TuneDMEforILS(BReceiver, Lotnisko.Czestotliwosc);
      SwitchTo(Antena);
    END;
    ILSfrqString(Lotnisko.Czestotliwosc, s);
    sprintf2(l, "%s(%s)", a2, a1);
    Wr2fStrXY(l, 415, 10, BROWN, BROWN);
    CzytajParametryABLP("AlarmOsi", bAlarmOsi);
    CzytajParametryABLP("SzerSektora_pA", bSzerSektora_pA);
    CzytajParametryABLP("AlarmSzeroki_pA", bAlarmSzeroki_pA);
    CzytajParametryABLP("AlarmWaski_pA", bAlarmWaski_pA);
    CzytajParametryAB("UstawienieOsi_Struktura", bUstawienieOsi_Struktura);
    CzytajParametryAB("UstawienieOsi_Szer_pA", bUstawienieOsi_Szer_pA);
    CzytajParametryAB("UstawienieOsi_Waski_pA", bUstawienieOsi_Waski_pA);
    CzytajParametryAB("Szer_i_Osi_pB", bSzer_i_Osi_pB);
    CzytajParametryAB("AlarmSzer_pB", bAlarmSzer_pB);
    CzytajParametryAB("AlarmWaski_pB", bAlarmWaski_pB);
    CzytajParametryAB("RownowagaModulacji", bRownowagaModulacji);
    CzytajParametryAB("Fazowanie", bFazowanie);
    CzytajParametryAB("Wyrazistosc_na_d_katach", bWyrazistosc_na_d_katach);
    CzytajParametryAB("Zasieg_do_10", bZasieg_do_10);
    CzytajParametryAB("Zasieg_10_35", bZasieg_10_35);
    CzytajParametryAB("Zasieg_ponad_35", bZasieg_ponad_35);
    CzytajParametryABLP("Marker", bMarker);
  END FillData;

  PROCEDURE ZmienOblot
            (    idx : INTEGER );
  VAR
    s  : ARRAY [0 .. 99] OF CHAR;
    i  : INTEGER;
    R  : RECT;
    ff : RECORD
           Polozenie     : PolozenieGeo;
           Teodolit      : REAL;
           Deklinacja    : REAL;
           DMEPolozenie  : PolozenieGeo;
           Cal           : ARRAY [0 .. 15] OF CHAR;
         END;

  BEGIN (* ZmienOblot *)
    IF idx < 0
    THEN
      RETURN;
    END (* if idx *);
    IF NOT RedrawScr & (idx = OstatniOblot)
    THEN
      RETURN;
    END (* if *);

    AssignRect(R, 300, 50, 500, 97);
    Redraw(hDlg, R);
    AssignRect(R, 0, 0, 790, 30);
    Redraw(hDlg, R);

    OstatniOblot := idx;
    GList.Idx2Str(ListaOblotow, idx, NazwaOblotu);
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
      RETURN;
    END (* if NazwaUrzadz1 *);
    OpisLotniska(NazwaUrzadz1, NazwaPlikuOpisu, TRUE);
    Wr2fStrXY(NazwaUrzadz1, 300, 50, WHITE, BLUE);
    IF NazwaUrzadz1[0] # 0C
    THEN
      i := Lotnisko.Czestotliwosc;
      ff.Polozenie := Lotnisko.Polozenie;
      ff.Teodolit := Lotnisko.TeodolitLOC;
      ff.Deklinacja := Lotnisko.Deklinacja;
      ff.DMEPolozenie := Lotnisko.Dme_Polozenie;
      ILSfrqString(Lotnisko.Czestotliwosc, ff.Cal);
      IF Lotnisko.CzyJestDME THEN
        sprintf(s,
"LOC=%d¯%02d'%04dE/%d¯%02d'%04dN, TEO=%3.1lfm, Î=%5.1lf¯, DME=%d¯%02d'%04dE/%d¯%02d'%04dN, f="
              , ff);
      ELSE
        sprintf(s,
"LOC=%d¯%02d'%04dE/%d¯%02d'%04dN, TEO=%3.1lfm, Î=%5.1lf¯, f="
              , ff);
      END (* IF *);
      Insert(ff.Cal, s, 0FFFH);
      WrStr(s, 11, 11, WHITE, WHITE);
    END (* if NazwaUrzadz1 *);
  END ZmienOblot;

  VAR
    LiniaLotniska : InpLine.HLINE;
    ListaNazw     : GList.HLIST;

  PROCEDURE DodajOblot;
  VAR
    Ask     : HDLG;
    R       : RECT;
    okB,
    CancelB : Buttons.Button;
    s,
    t,
    u       : ARRAY [0 .. 99] OF CHAR;
    i,
    ile     : INTEGER;
    ok      : BOOLEAN;
    a       : ADDRESS;
    d_t     : TimeAndDate;

  BEGIN
    GetTimeAndDate(d_t);
    AssignRect(R, 400, 250, 750, 580);
    Ask := TworzDialog(R, "Ob-loc.bmp", TRUE);
    AssignRect(R, 1000, 1000, 1000, 1000);
    WstawButton(Ask, R, "", 0, ShortCuts.kbEnter, ProbujWstawicOblot,
                       okB);
    AssignRect(R, 10, 290, 90, 320);
    WstawButton(Ask, R, "OK", 0, ShortCuts.kbAltO, ProbujWstawicOblot,
                       okB);
    MoveRect(R, 100, 0);
    WstawButton(Ask, R, "WYJDç", 1, ShortCuts.kbAltW, AltF4,
                       CancelB);
    WstawInpLine(Ask, 10, 40, 30, InpLine.DoNothing, WHITE, MAGENTA,
                        LiniaLotniska);
    AssignRect(R, 10, 70, 320, 270);
    ListaNazw := WstawListe(Ask, R, FALSE);
    InitListaUrzadzen(ListaNazw);
    IF Go(Ask)
    THEN
      InpLine.GetText(LiniaLotniska, s);
      GList.Idx2Str(ListaNazw, GList.GetSelection(ListaNazw), t);
      IF s[0] = 0C
      THEN
        InfoBeep("No przecieæ inspekcja musi mieÜ nazw© ?!!!", 3, 300);
      ELSIF t[0] = 0C
      THEN
        InfoBeep("Trzeba jeszcze podaÜ nazw© istniejacego lotniska", 3, 300);
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
          InfoBeep("Istnieje juæ inspekcja o takiej nazwie", 3, 300);
        ELSE
          GetPrivateProfileString(t, "Dme", "@", u, L_BazaLokalizacji);
          IF u[0] = '@'
          THEN
            a := ADR(t);
            sprintf(u, "Nie ma lotniska o nazwie `%s'", a);
            InfoBeep(u, 3, 500);
            Wait(2 * TInOneSecond());
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
            WritePrivateProfileString(s, "Nazwa", t, u);
            sprintf(t, "%2d.%02d.%d", d_t.d);
            WritePrivateProfileString(s, "DataRozpoczenia", t, u);
            WritePrivateProfileString(s, "OstatniaModyfikacja", t, u);
(*
            RedrawScr := TRUE;
            GList.DodajDoListy(ListaOblotow, s);
            RedrawScr := FALSE;
*)
            WymienPasujaceObloty(GList.GetSelection(ListaLotn_Ob));
          END (* if u *);
        END (* if ok *);
      END (* if s *);
    END (* if Go *);
    UsunDialog(Ask);
  END DodajOblot;

  PROCEDURE ProbujWstawicOblot();

  BEGIN
    EndDialog(TRUE);
  END ProbujWstawicOblot;

  PROCEDURE NowyOblot;

  BEGIN
    STARTPROCESS(DodajOblot, 1000H, 0);
  END NowyOblot;

  PROCEDURE Pokaz
            (    s   : ARRAY OF CHAR;
                 Snd : CARDINAL      );

  BEGIN
    Info(s);
    IF Snd # 0FFFFH
    THEN
      Sound(Snd);
    END (* if Snd *);
    Wait(TInOneSecond());
    NoSound;
    Info("");
  END Pokaz;

  PROCEDURE Zapisz
            (    EfektPolaryzacji : BOOLEAN;
                 ZakodowanyBlad,
                 Podzielnik       : INTEGER );
  VAR
    Tmp  : ARRAY [0 .. 40] OF CHAR;
    Tmp1 : ARRAY [0 .. 40] OF CHAR;
    Fmt  : ARRAY [0 .. 40] OF CHAR;
    i    : CARDINAL;
    t_d  : TimeAndDate;

    PROCEDURE ProcIdentifier
              (     Procedura : ProceduraT;
                VAR ident     : ARRAY OF CHAR );
    VAR
      a      : ADDRESS;
      Tmp    : ARRAY [0 .. 40] OF CHAR;
      nad    : CHAR;
      strona : CHAR;

    BEGIN
      nad := NadajnikCH();
      strona := StronaCH();
      IF (Procedura <= pAlarmWaski_pA) OR (Procedura = pMarker)
      THEN
        Fmt := '%s.%c.%c';
      ELSE
        Fmt := '%s.%c';
      END (* if *);
      CASE Procedura OF
        pAlarmOsi :
          Tmp := 'AlarmOsi';
        |
        pSzerSektora_pA :
          Tmp := 'SzerSektora_pA';
        |
        pAlarmSzeroki_pA :
          Tmp := 'AlarmSzeroki_pA';
        |
        pAlarmWaski_pA :
          Tmp := 'AlarmWaski_pA';
        |
        pUstawienieOsi_Struktura :
          Tmp := "UstawienieOsi_Struktura";
        |
        pUstawienieOsi_Szer_pA :
          Tmp := 'UstawienieOsi_Szer_pA';
        |
        pUstawienieOsi_Waski_pA :
          Tmp := 'UstawienieOsi_Waski_pA';
        |
        pSzer_i_Osi_pB :
          Tmp := 'Szer_i_Osi_pB';
        |
        pAlarmSzer_pB :
          Tmp := 'AlarmSzer_pB';
        |
        pAlarmWaski_pB :
          Tmp := 'AlarmWaski_pB';
        |
        pRownowagaModulacji :
          Tmp := 'RownowagaModulacji';
        |
        pFazowanie :
          Tmp := 'Fazowanie';
        |
        pWyrazistosc_na_d_katach :
          Tmp := 'Wyrazistosc_na_d_katach';
        |
        pZasieg_do_10 :
          Tmp := 'Zasieg_do_10';
        |
        pZasieg_10_35 :
          Tmp := 'Zasieg_10_35';
        |
        pZasieg_ponad_35 :
          Tmp := 'Zasieg_ponad_35';
        |
        pMarker :
          Tmp := 'Marker';
      END (* case Procedura *);
      a := ADR(Tmp);
      sprintf3(ident, Fmt, a, nad, strona);
    END ProcIdentifier;

  BEGIN (* Zapisz *)
    ProcIdentifier(Procedura, Tmp1);
    GetTimeAndDate(t_d);
    ConvertToStr(t_d, TRUE, Fmt);
    IF ZakodowanyBlad = MIN(INTEGER)
    THEN
      Insert( "(!!!!!)", Fmt, 0 );
    ELSE
      CASE Podzielnik OF
        1:   Insert( "(%5d)", Fmt, 0 );
      | 10:  Insert( "(%5y)", Fmt, 0 );
      | 100: Insert( "(%5z)", Fmt, 0 );
      | 500: Insert( "(%5x)", Fmt, 0 );
      ELSE
        Assert( FALSE );
      END;
    END;
    sprintf(Tmp, Fmt, ZakodowanyBlad);
    WritePrivateProfileString(NazwaOblotu, Tmp1, Tmp, NazwaPlikuOpisu);
    ConvertToStr(DataOstatniejKalibracji, FALSE, Tmp);
    WritePrivateProfileString( "DataKalibracji", "Data", Tmp, NazwaPlikuOpisu );
    sprintf(Tmp, "%2d.%02d.%4d", t_d.d);
    WritePrivateProfileString(NazwaOblotu, "OstatniaModyfikacja", Tmp,
                              NazwaPlikuOpisu);
  END Zapisz;

BEGIN
  StartInspection(Insp_LOC);
  Info("");
  OstatniOblot := 0;
  GlownyOdbiornik := MIN(GlownyOdbiornikT);
  OdnDlaPomBledu := MIN(OdnDlaPomBleduT);
  OdnDlaPomOdl := MIN(L_OdnDlaPomOdlT);
  Odl_dla_pom_pB := 0;
  Szer_sekt_kier := 0;
  Procedura := MIN(ProceduraT);
END L_Oblot.
