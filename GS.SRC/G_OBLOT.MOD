(*.F- *)
(**********************************************************************
|  Title   : Glowny ekran sterujacy dla LOC
|  Author  : M.Morawski
|  System  : LOGITECH MODULA-2/86
|  History :
|    11-05-96:M.Postol
|       kosmetyka
|    14-07-96: M.Postol
|       wydzielono modul dla obslugi ekranu inspekcji,
|       liczne inne zmiany.
|    30-10-96: M.Postol
|       nie przelaczal na anteny
|    12-23-96 04:48pm: MM
|       Rozne poprawki dotyczace programu archiwalnego
|   01-26-97 03:52pm: MM
|     Dodany podzielnik w procedurze Zapisz
|   03-10-97 09:19pm: MM
|     Najpierw zapisywal dane a potem czytal Cisnienie odniesienia
|     czyli nie zapamietywal go
|   03-13-97 12:59pm: MM
|     Dane, dla ktorych nie wyznaczono rezultatu koncowego zaznaczane sa
|     wykrzyknikami
|   31-03-97: M.Postol
|     POLSKIE LITERY
|   19-05-97: M.Postol
|     brak inicjacji CommonData.OdnDlaPomBledu
|    Rel. 3.0: MPostol
|      Dostosowalem do nowej definicji Czas
|      MKR byl zle strojony 
|
|  Copyright (C), CAS LODZ POLAND.
|  TEL: 42' 686 25 47
|  mailto: techsupp@cas.com.pl
|  http: www.cas.com.pl
|
**********************************************************************)
(*.F+ *)

IMPLEMENTATION MODULE G_Oblot;

  IMPORT
    ShortCuts, InpLine, Buttons, MsgBox, Files, PA_PA, Mapa;

  FROM CommonData IMPORT
    SciezkaOpisuPomiaru, OdnDlaPomOdl, NazwaOblotu, NazwaUrzadz1,
    NazwaPlikuOpisu, Nadajnik1, GlownyOdbiornik, CisnienieOdniesienia,
    OdnDlaPomBledu;

  FROM SpecConv IMPORT
    Int100Str, Angle100;

  FROM HiLevGraf IMPORT
    WrStr;

  FROM Polozenie IMPORT
    StalyKat;

  FROM Dialog IMPORT
    HDLG, EndDialog, TworzDialog, WstawListe, WstawButton, EnableDlg, Go,
    UsunDialog, Redraw, AltF4, WstawInpLine, WstawRadioButton, IsBusy;

  FROM Obloty IMPORT
    NazwaPlikuIni;

  FROM GrafTypes IMPORT
    RECT, AssignRect, MoveRect, WHITE, BLUE, MAGENTA, BLACK, LT_RED;

  FROM GrafUtil IMPORT
    Info;

  FROM Sounds IMPORT
    Sound, NoSound;

  FROM Timer IMPORT
    Wait, TInOneSecond;

  FROM NumberConversion IMPORT
    StringToCard, CardToString;

  FROM RealConversions IMPORT
    StringToReal, RealToString;

  FROM Strings IMPORT
    Length, Insert, Assign;

  FROM Ini IMPORT
    GetPrivateProfileString, WritePrivateProfileString;

  FROM StdIO IMPORT
    sprintf, sprintf2, sprintf3;

  FROM L_DataBase IMPORT
    Lotnisko, OpisLotniska;

  FROM MANAGER IMPORT
    Assert, STARTPROCESS;

  FROM HiLevGraf IMPORT
    Wr2fStrXY;

  FROM SYSTEM IMPORT
    ADR, ADDRESS;

  FROM Tune IMPORT
    TuneILS, Receiver, TuneDMEforILS, ILSfrqString;

  FROM Czas IMPORT
    GetTimeAndDate, TimeAndDate, ConvertToStr;

  FROM MathLib0 IMPORT
    entier, real;

  FROM CommonTypes IMPORT
    OdnDlaPomBleduT, GlownyOdbiornikT, NadajnikT, OdnDlaPomOdlT,
    SigNilVal, ZoneBoundPt, CoMoznaZrobic, Str40, Str99;

  FROM G_CommonTypes IMPORT
    ProceduraT, StronaT, NumStrefy, Procedura, Strona, Szer_sekt_kier;

  FROM  ILS_ZoneMngmnt IMPORT
    IdentPunktow, IdentPunktowT, Fill_IdPunktowArr_T;

  FROM L_CommonTypes IMPORT
    NumPunktu;

  FROM SwitchCntrl IMPORT
    SwState, SwitchTo;

  FROM Kalibracja IMPORT
    DataOstatniejKalibracji;

  TYPE
    A_B_gora_dol =
      RECORD
        A, B :
          RECORD
            gora, dol  :
              Buttons.Button;
          END;
      END;
    A_B          =
      RECORD
        A, B :
          Buttons.Button;
      END;

  VAR
    hDlg                 : HDLG;
    bAlarmSciezki,
    bSzerSektora_pA,
    bAlarmSzeroki_pA,
    bAlarmWaski_pA       : A_B_gora_dol;
    bKatSciezki,
    bKatSciezki_Szer_pA,
    bKatSciezki_Waski_pA,
    bSzer_i_Osi_pB,
    bAlarmSzer_pB,
    bAlarmWaski_pB,
    bRownowagaModulacji,
    bFazowanie,
    bZabezpieczenie,
    bPokrycieWOsi,
    bPokrycie8stP,
    bPokrycie8stL        : A_B;
    GlowOdb,
    OdnAzymut,
    OdnOdl               : Buttons.Button;
    bIdentPunktow        : ARRAY ZoneBoundPt OF Buttons.Button;
    (* lSzer_sekt_kier      : InpLine.HLINE; *)
    Szer_sekt_kier_AS    : INTEGER;
    Szer_sekt_kier_AW    : INTEGER;
    Szer_sekt_kier_N     : INTEGER;
    CisnienieOdn_L       : InpLine.HLINE;
    TestUP               : Buttons.Button;
    Raport               : Buttons.Button;
    Pomiar               : Buttons.Button;  (* Test urzadzen pomiarowych *)
    RedrawScr            : BOOLEAN;

  CONST
    MainSection = "GS";
    ParamFile   = "pomiar.par";

  PROCEDURE AlarmSciezki_A_G();

  BEGIN
    Procedura := pAlarmOsi;
    Strona := Gora;
    Nadajnik1 := nA;
    Wlacz_Wylacz();
  END AlarmSciezki_A_G;

  PROCEDURE AlarmSciezki_A_D();

  BEGIN
    Procedura := pAlarmOsi;
    Strona := Dol;
    Nadajnik1 := nA;
    Wlacz_Wylacz();
  END AlarmSciezki_A_D;

  PROCEDURE AlarmSciezki_B_G();

  BEGIN
    Procedura := pAlarmOsi;
    Strona := Gora;
    Nadajnik1 := nB;
    Wlacz_Wylacz();
  END AlarmSciezki_B_G;

  PROCEDURE AlarmSciezki_B_D();

  BEGIN
    Procedura := pAlarmOsi;
    Strona := Dol;
    Nadajnik1 := nB;
    Wlacz_Wylacz();
  END AlarmSciezki_B_D;

  PROCEDURE SzerSektora_pA_A_G();

  BEGIN
    Procedura := pSzerSektora_pA;
    Strona := Gora;
    Nadajnik1 := nA;
    Wlacz_Wylacz();
  END SzerSektora_pA_A_G;

  PROCEDURE SzerSektora_pA_A_D();

  BEGIN
    Procedura := pSzerSektora_pA;
    Strona := Dol;
    Nadajnik1 := nA;
    Wlacz_Wylacz();
  END SzerSektora_pA_A_D;

  PROCEDURE SzerSektora_pA_B_G();

  BEGIN
    Procedura := pSzerSektora_pA;
    Strona := Gora;
    Nadajnik1 := nB;
    Wlacz_Wylacz();
  END SzerSektora_pA_B_G;

  PROCEDURE SzerSektora_pA_B_D();

  BEGIN
    Procedura := pSzerSektora_pA;
    Strona := Dol;
    Nadajnik1 := nB;
    Wlacz_Wylacz();
  END SzerSektora_pA_B_D;

  PROCEDURE AlarmSzeroki_pA_A_G();

  BEGIN
    Procedura := pAlarmSzeroki_pA;
    Strona := Gora;
    Nadajnik1 := nA;
    Wlacz_Wylacz();
  END AlarmSzeroki_pA_A_G;

  PROCEDURE AlarmSzeroki_pA_A_D();

  BEGIN
    Procedura := pAlarmSzeroki_pA;
    Strona := Dol;
    Nadajnik1 := nA;
    Wlacz_Wylacz();
  END AlarmSzeroki_pA_A_D;

  PROCEDURE AlarmSzeroki_pA_B_G();

  BEGIN
    Procedura := pAlarmSzeroki_pA;
    Strona := Gora;
    Nadajnik1 := nB;
    Wlacz_Wylacz();
  END AlarmSzeroki_pA_B_G;

  PROCEDURE AlarmSzeroki_pA_B_D();

  BEGIN
    Procedura := pAlarmSzeroki_pA;
    Strona := Dol;
    Nadajnik1 := nB;
    Wlacz_Wylacz();
  END AlarmSzeroki_pA_B_D;

  PROCEDURE AlarmWaski_pA_A_G();

  BEGIN
    Procedura := pAlarmWaski_pA;
    Strona := Gora;
    Nadajnik1 := nA;
    Wlacz_Wylacz();
  END AlarmWaski_pA_A_G;

  PROCEDURE AlarmWaski_pA_A_D();

  BEGIN
    Procedura := pAlarmWaski_pA;
    Strona := Dol;
    Nadajnik1 := nA;
    Wlacz_Wylacz();
  END AlarmWaski_pA_A_D;

  PROCEDURE AlarmWaski_pA_B_G();

  BEGIN
    Procedura := pAlarmWaski_pA;
    Strona := Gora;
    Nadajnik1 := nB;
    Wlacz_Wylacz();
  END AlarmWaski_pA_B_G;

  PROCEDURE AlarmWaski_pA_B_D();

  BEGIN
    Procedura := pAlarmWaski_pA;
    Strona := Dol;
    Nadajnik1 := nB;
    Wlacz_Wylacz();
  END AlarmWaski_pA_B_D;

  PROCEDURE KatSciezki_A();

  BEGIN
    Procedura := pUstawienieOsi_Struktura;
    Nadajnik1 := nA;
    Wlacz_Wylacz();
  END KatSciezki_A;

  PROCEDURE KatSciezki_B();

  BEGIN
    Procedura := pUstawienieOsi_Struktura;
    Nadajnik1 := nB;
    Wlacz_Wylacz();
  END KatSciezki_B;

  PROCEDURE KatSciezki_Szer_pA_A();

  BEGIN
    Procedura := pUstawienieOsi_Szer_pA;
    Nadajnik1 := nA;
    Wlacz_Wylacz();
  END KatSciezki_Szer_pA_A;

  PROCEDURE KatSciezki_Szer_pA_B();

  BEGIN
    Procedura := pUstawienieOsi_Szer_pA;
    Nadajnik1 := nB;
    Wlacz_Wylacz();
  END KatSciezki_Szer_pA_B;

  PROCEDURE KatSciezki_Waski_pA_A();

  BEGIN
    Procedura := pUstawienieOsi_Waski_pA;
    Nadajnik1 := nA;
    Wlacz_Wylacz();
  END KatSciezki_Waski_pA_A;

  PROCEDURE KatSciezki_Waski_pA_B();

  BEGIN
    Procedura := pUstawienieOsi_Waski_pA;
    Nadajnik1 := nB;
    Wlacz_Wylacz();
  END KatSciezki_Waski_pA_B;

  PROCEDURE Szer_i_Osi_pB_A();

  BEGIN
    Procedura := pSzer_i_Osi_pB;
    Nadajnik1 := nA;
    Wlacz_Wylacz();
  END Szer_i_Osi_pB_A;

  PROCEDURE Szer_i_Osi_pB_B();

  BEGIN
    Procedura := pSzer_i_Osi_pB;
    Nadajnik1 := nB;
    Wlacz_Wylacz();
  END Szer_i_Osi_pB_B;

  PROCEDURE AlarmSzer_pB_A();

  BEGIN
    Procedura := pAlarmSzer_pB;
    Nadajnik1 := nA;
    Wlacz_Wylacz();
  END AlarmSzer_pB_A;

  PROCEDURE AlarmSzer_pB_B();

  BEGIN
    Procedura := pAlarmSzer_pB;
    Nadajnik1 := nB;
    Wlacz_Wylacz();
  END AlarmSzer_pB_B;

  PROCEDURE AlarmWaski_pB_A();

  BEGIN
    Procedura := pAlarmWaski_pB;
    Nadajnik1 := nA;
    Wlacz_Wylacz();
  END AlarmWaski_pB_A;

  PROCEDURE AlarmWaski_pB_B();

  BEGIN
    Procedura := pAlarmWaski_pB;
    Nadajnik1 := nB;
    Wlacz_Wylacz();
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

  PROCEDURE Zabezpieczenie_A();

  BEGIN
    Procedura := pZabezpieczenie;
    Nadajnik1 := nA;
    Wlacz_Wylacz();
  END Zabezpieczenie_A;

  PROCEDURE Zabezpieczenie_B();

  BEGIN
    Procedura := pZabezpieczenie;
    Nadajnik1 := nB;
    Wlacz_Wylacz();
  END Zabezpieczenie_B;

  PROCEDURE Pokrycie_w_osi_A();

  BEGIN
    Procedura := pPokrycieWOsi;
    Nadajnik1 := nA;
    Wlacz_Wylacz();
  END Pokrycie_w_osi_A;

  PROCEDURE Pokrycie_w_osi_B();

  BEGIN
    Procedura := pPokrycieWOsi;
    Nadajnik1 := nB;
    Wlacz_Wylacz();
  END Pokrycie_w_osi_B;

  PROCEDURE Pokrycie_8_st_P_A();

  BEGIN
    Procedura := pPokrycie8stP;
    Nadajnik1 := nA;
    Wlacz_Wylacz();
  END Pokrycie_8_st_P_A;

  PROCEDURE Pokrycie_8_st_P_B();

  BEGIN
    Procedura := pPokrycie8stP;
    Nadajnik1 := nB;
    Wlacz_Wylacz();
  END Pokrycie_8_st_P_B;

  PROCEDURE Pokrycie_8_st_L_A();

  BEGIN
    Procedura := pPokrycie8stL;
    Nadajnik1 := nA;
    Wlacz_Wylacz();
  END Pokrycie_8_st_L_A;

  PROCEDURE Pokrycie_8_st_L_B();

  BEGIN
    Procedura := pPokrycie8stL;
    Nadajnik1 := nB;
    Wlacz_Wylacz();
  END Pokrycie_8_st_L_B;

  PROCEDURE IdentPkt
            (    i : NumPunktu );
  VAR
    ip : CARDINAL;
    s  : ARRAY [0 .. 20] OF CHAR;

  BEGIN
    IF NOT RedrawScr
    THEN
      ip := ORD(IdentPunktow[i]);
      IF i <= np_B THEN
        ip := (ip + 1) MOD ORD(MAX(IdentPunktowT));
      ELSE
        ip := (ip + 1) MOD 2;
      END;
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

  PROCEDURE TestUP_PROC;

  BEGIN
    CoRobimy := czTest;
    EndDialog(TRUE);
  END TestUP_PROC;

  PROCEDURE Raport_PROC();

  BEGIN
    CoRobimy := czDrukR;
    EndDialog(TRUE);
  END Raport_PROC;

  PROCEDURE PlayP(  );
    BEGIN
      CoRobimy := czPlay;
      EndDialog(TRUE);
    END PlayP;

  PROCEDURE RaportKoncowy(  );
    BEGIN
      CoRobimy := czRaportKoncowy;
      EndDialog( TRUE );
    END RaportKoncowy;

  PROCEDURE View_PROC(  );
    BEGIN
      CoRobimy := czPreview;
      EndDialog(TRUE);
    END View_PROC;

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

  PROCEDURE Pokaz
            (    s   : ARRAY OF CHAR;
                 Snd : CARDINAL      );

  BEGIN
    Info(s);
    IF Snd # 0FFFFH
    THEN
      Sound(Snd);
    END (* if Snd *);
    Wait(TInOneSecond() * 3);
    NoSound;
    Info("");
  END Pokaz;

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
        i := "Napis nie jest liczb¥ rzeczywist¥";
      ELSIF (r > 1.2) OR (r < 0.4)
      THEN
        i := "Wprowadzona liczba jest zbyt du¾a lub zbyt maˆa";
        ok := FALSE;
      END (* if *);
      IF NOT ok
      THEN
        Pokaz(i, 2000);
      END (* if *);
      RETURN ok;
    ELSE
      RETURN TRUE;
    END (* if KillFocus *);
  END ValidReal;

  PROCEDURE ZakonczDlg();

  BEGIN
    EndDialog(TRUE);
  END ZakonczDlg;

  PROCEDURE Szer_Sekt;
  VAR
    Ask                : HDLG;
    R                  : RECT;
    Rdlg               : RECT;
    okB                : Buttons.Button;
    CancelB            : Buttons.Button;
    s                  : ARRAY [0 .. 99] OF CHAR;
    ok                 : BOOLEAN;
    Linia_Szer_sektora : InpLine.HLINE;
    r                  : REAL;

  BEGIN
    AssignRect(Rdlg, 230, 100, 570, 250);
    Ask := TworzDialog(Rdlg, "sz-sekt.bmp", TRUE);
    AssignRect(R, 1000, 1000, 1000, 1000);
    WstawButton(Ask, R, "", -1, ShortCuts.kbEnter, ZakonczDlg, okB);
    AssignRect(R, 10, 70, 90, 100);
    WstawButton(Ask, R, "OK", 0, ShortCuts.kbAltO, ZakonczDlg, okB);
    MoveRect(R, 100, 0);
    WstawButton(Ask, R, "WYJ—CIE", 0, ShortCuts.kbAltW, AltF4,
                       CancelB);
    WstawInpLine(Ask, 10, 40, 27, ValidReal, WHITE, MAGENTA,
                        Linia_Szer_sektora);
    IF (Procedura = pAlarmOsi) OR (Procedura = pUstawienieOsi_Struktura)
    THEN
      WrStr("Szeroko˜† sektora", Rdlg.left+5, Rdlg.top+5, WHITE, WHITE);
      r := FLOAT(Szer_sekt_kier_N)/100.0;
    ELSIF (Procedura = pUstawienieOsi_Szer_pA)
    THEN
      WrStr("Sektor w alarmie szerokim", Rdlg.left+5, Rdlg.top+5, WHITE, WHITE);
      r := FLOAT(Szer_sekt_kier_AS)/100.0;
    ELSIF (Procedura = pUstawienieOsi_Waski_pA)
    THEN
      WrStr("Sektor w alarmie w¥skim", Rdlg.left+5, Rdlg.top+5, WHITE, WHITE);
      r := FLOAT(Szer_sekt_kier_AW)/100.0;
    END (* if *);
    RealToString(r, 2, 4, s, ok);
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

  BEGIN
(*
    IF IsBusy( hDlg ) THEN
      RETURN;
    END;
*)
    CoRobimy := czPomiar;
    IF (Procedura = pAlarmOsi) OR (Procedura = pUstawienieOsi_Struktura) OR
       (Procedura = pUstawienieOsi_Szer_pA) OR
       (Procedura = pUstawienieOsi_Waski_pA)
    THEN
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

  PROCEDURE OdnOdlP;
  VAR
    i : CARDINAL;

  BEGIN
    OdnDlaPomOdl := poGPS;
    RETURN;
    i := ORD(OdnDlaPomOdl);
    IF NOT RedrawScr
    THEN
      i := (i + 1) MOD (ORD(MAX(OdnDlaPomOdlT)) + 1);
      OdnDlaPomOdl := VAL(OdnDlaPomOdlT, i);
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
        i := "Napis nie jest liczb¥ rzeczywist¥";
      ELSIF KillFocus & ((r < 0.40) OR (r > 1.2))
      THEN
        i := "Wprowadzona liczba jest zbyt du¾a lub zbyt maˆa";
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
        i := "Napis nie jest liczb¥ rzeczywist¥";
      ELSIF KillFocus & ((r < 700.0) OR (r > 1200.0))
      THEN
        i := "Wprowadzona liczba jest zbyt du¾a lub zbyt maˆa";
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
  END RealCisnValid;

  PROCEDURE StronaCH() : CHAR;

  BEGIN
    IF (Strona = Gora)
    THEN
      RETURN 'G'
    ELSE
      RETURN 'D';
    END (* if *);
  END StronaCH;

  PROCEDURE NadajnikCH() : CHAR;

  BEGIN
    RETURN CHR(ORD(Nadajnik1) + ORD('A'));   (* A lub B *)
  END NadajnikCH;

  PROCEDURE InitLot( ) : BOOLEAN;

  CONST
    DX        = 100;
    DY        = 24;
    SZEROKOSC = 85;
  VAR
    kont : BOOLEAN;
    s    : ARRAY [0 .. 31] OF CHAR;
    R    : RECT;

    PROCEDURE InitDefault;
    VAR
      c      : CARDINAL;
      ok     : BOOLEAN;
      strefa : NumPunktu;
      strefaCard : CARDINAL;
    BEGIN
      GetPrivateProfileString(MainSection, "OdnDlaPomOdl", "0", s, ParamFile);
      StringToCard(s, c, ok);
      IF NOT ok
      THEN
        c := 0;
      END (* if *);
      OdnDlaPomOdl := VAL( OdnDlaPomOdlT, c );
      GetPrivateProfileString(MainSection, "GlownyOdbiornik", "0", s, ParamFile
      );
      StringToCard(s, c, ok);
      IF NOT ok
      THEN
        c := 0;
      END (* if *);
      GlownyOdbiornik := VAL(GlownyOdbiornikT, c);
      (* Identyfikacja punktow charakterystycznych *)
      Fill_IdPunktowArr_T(IdentPunktow);
      FOR strefa := np_A TO np_CorT DO
        strefaCard := ORD(strefa);
        sprintf(s, "IdentPunktow.%d", strefaCard);
        GetPrivateProfileString(MainSection, s, "0", s, ParamFile);
        StringToCard(s, c, ok);
        IF NOT ok
        THEN
          IdentPunktow[strefa] := ipGPS;
        ELSE
          IdentPunktow[strefa] := VAL(IdentPunktowT, c);
        END (* if *);
      END (* for i *);
      (* szerokosc sektora *)
      Szer_sekt_kier    := Lotnisko.Szer_GS;
      Szer_sekt_kier_N  := Szer_sekt_kier;
      Szer_sekt_kier_AS := 85;
      Szer_sekt_kier_AW := 55;

      (*
      Int100Str(Szer_sekt_kier, s, 6);
      InpLine.SetText(lSzer_sekt_kier, s);
      *)
      (* Cisnienie *)
      IF PA_PA.PomiarANieArchiwum THEN
        GetPrivateProfileString(MainSection, "CisnienieOdn", "1013.8", s,
                                ParamFile);
        InpLine.SetText(CisnienieOdn_L, s);
        IF NOT RealCisnValid(CisnienieOdn_L, s, TRUE) THEN
          CisnienieOdniesienia := 1013.8;
          InpLine.SetText(CisnienieOdn_L, "1013.8");
        ELSE
          CisnienieOdniesienia := RealVal(CisnienieOdn_L);   (* MP *)
        END (* if *);
      END;
    END InitDefault;

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

      PROCEDURE CzytajPrmtryABLP
                (    EntryTmp : ARRAY OF CHAR;
                     but      : A_B_gora_dol  );
      VAR
        e,
        s : ARRAY [0 .. 99] OF CHAR;
        a : ADDRESS;

      CONST
        fmt = "%s.%c.%c";

      BEGIN
        Assign(EntryTmp, e);
        a := ADR(e);
        sprintf3(s, fmt, a, 'A', 'G');
        CzytajParametry(s, but.A.gora);
        sprintf3(s, fmt, a, 'A', 'D');
        CzytajParametry(s, but.A.dol);
        sprintf3(s, fmt, a, 'B', 'G');
        CzytajParametry(s, but.B.gora);
        sprintf3(s, fmt, a, 'B', 'D');
        CzytajParametry(s, but.B.dol);
      END CzytajPrmtryABLP;

      PROCEDURE CzytajPrmtryAB
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
      END CzytajPrmtryAB;
    VAR
      s,
      l  : ARRAY [0 .. 99] OF CHAR;
      a1,
      a2 : ADDRESS;

    BEGIN
      a1 := ADR(s);
      a2 := ADR(NazwaUrzadz1);
      OdnDlaPomBledu := pbTeodolit;
      OpisLotniska(NazwaUrzadz1, NazwaPlikuOpisu, FALSE);
      TuneILS(AReceiver, Lotnisko.Czestotliwosc, TRUE);
      TuneILS(BReceiver, Lotnisko.Czestotliwosc, TRUE);
      TuneDMEforILS(AReceiver, Lotnisko.Czestotliwosc);
      TuneDMEforILS(BReceiver, Lotnisko.Czestotliwosc);
      IF PA_PA.PomiarANieArchiwum THEN
        SwitchTo(Antena);
      END;
      ILSfrqString(Lotnisko.Czestotliwosc, s);
      sprintf2(l, "%s(%s)", a2, a1);
      Wr2fStrXY(l, 420, 20, WHITE, WHITE);
      CzytajPrmtryABLP("AlarmSciezki", bAlarmSciezki);
      CzytajPrmtryABLP("SzerSektora_pA", bSzerSektora_pA);
      CzytajPrmtryABLP("AlarmSzeroki_pA", bAlarmSzeroki_pA);
      CzytajPrmtryABLP("AlarmWaski_pA", bAlarmWaski_pA);
      CzytajPrmtryAB("KatSciezki", bKatSciezki);
      CzytajPrmtryAB("KatSciezki_Szer_pA", bKatSciezki_Szer_pA);
      CzytajPrmtryAB("KatSciezki_Waski_pA", bKatSciezki_Waski_pA);
      CzytajPrmtryAB("Szer_i_Osi_pB", bSzer_i_Osi_pB);
      CzytajPrmtryAB("AlarmSzer_pB", bAlarmSzer_pB);
      CzytajPrmtryAB("AlarmWaski_pB", bAlarmWaski_pB);
      CzytajPrmtryAB("RownowagaModulacji", bRownowagaModulacji);
      CzytajPrmtryAB("Fazowanie", bFazowanie);
      CzytajPrmtryAB("Zabezpieczenie", bZabezpieczenie);
      CzytajPrmtryAB("Pokrycie_w_osi", bPokrycieWOsi);
      CzytajPrmtryAB("Pokrycie_8_st_L", bPokrycie8stL);
      CzytajPrmtryAB("Pokrycie_8_st_P", bPokrycie8stP);
    END FillData;

    PROCEDURE SaveDefault;
    VAR
      npt    : NumPunktu;
      nptC   : CARDINAL;
      t      : Str40;
      s      : Str40;
      Prom   : ARRAY[0..0] OF CARDINAL;

    BEGIN
      CardToString(ORD(OdnDlaPomOdl), s, 1);
      WritePrivateProfileString(MainSection, "OdnDlaPomOdl", s, ParamFile);
      CardToString(ORD(GlownyOdbiornik), s, 1);
      WritePrivateProfileString(MainSection, "GlownyOdbiornik", s, ParamFile);
      FOR npt := np_A TO np_CorT DO
        nptC := ORD(npt);
        sprintf(t, "IdentPunktow.%d", nptC);
        CardToString(ORD(IdentPunktow[npt]), s, 1);
        WritePrivateProfileString(MainSection, t, s, ParamFile);
      END (* for i *);
      sprintf(s, "%8.1lf", CisnienieOdniesienia);
      WritePrivateProfileString(MainSection, "CisnienieOdn", s, ParamFile);
      StalyKat := Lotnisko.KierunekPasa+180;
      IF (StalyKat >= 360) THEN
        DEC( StalyKat, 360 );
      END;
      Prom[0] := 0FFFFH;
      Mapa.Promienie( Prom, Prom, StalyKat );
      StalyKat := Angle100( StalyKat );
    END SaveDefault;

    PROCEDURE AssignButt;

    VAR
      R1 : RECT;
      R  : RECT;

      PROCEDURE Make2
                (     name : ARRAY OF CHAR;
                      R  : RECT;
                  VAR ab : A_B;
                      pa : PROC;
                      sa : CARDINAL;
                      pb : PROC;
                      sb : CARDINAL );

      BEGIN
        WstawRadioButton(hDlg, R, "", -1, sa, pa, ab.A);
        MoveRect(R, DX + DX, 0);
        WstawRadioButton(hDlg, R, "", -1, sb, pb, ab.B);
        WrStr(name, R.right+5, R.top+5, WHITE, WHITE);
      END Make2;

      PROCEDURE Make3
                (     name : ARRAY OF CHAR;
                      R    : RECT;
                  VAR it : ARRAY OF Buttons.Button;
                      p1 : PROC;
                      s1 : CARDINAL;
                      p2 : PROC;
                      s2 : CARDINAL;
                      p3 : PROC;
                      s3 : CARDINAL                );

      BEGIN
        R.right := R.left + SZEROKOSC;
        WstawButton(hDlg, R, "", -1, s1, p1, it[0]);
        MoveRect(R, DX, 0);
        WstawButton(hDlg, R, "", -1, s2, p2, it[1]);
        MoveRect(R, DX, 0);
        WstawButton(hDlg, R, "", -1, s3, p3, it[2]);
        WrStr(name, R.right+5, R.top+5, BLACK, BLACK);
      END Make3;

      PROCEDURE Make4
                (     name : ARRAY OF CHAR;
                      R    : RECT;
                  VAR ablp : A_B_gora_dol;
                      pal  : PROC;
                      sal  : CARDINAL;
                      pap  : PROC;
                      sap  : CARDINAL;
                      pbl  : PROC;
                      sbl  : CARDINAL;
                      pbp  : PROC;
                      sbp  : CARDINAL     );

      BEGIN
        WstawRadioButton(hDlg, R, "", -1, sal, pal, ablp.A.gora);
        MoveRect(R, DX, 0);
        WstawRadioButton(hDlg, R, "", -1, sap, pap, ablp.A.dol);
        MoveRect(R, DX, 0);
        WstawRadioButton(hDlg, R, "", -1, sbl, pbl, ablp.B.gora);
        MoveRect(R, DX, 0);
        WstawRadioButton(hDlg, R, "", -1, sbp, pbp, ablp.B.dol);
        WrStr(name, R.right+5, R.top, WHITE, WHITE);
      END Make4;

    VAR
      void : Buttons.Button;
    BEGIN (* AssignButt *)
      AssignRect(R, 5, 50, 5 + SZEROKOSC, 70);
      (* Alarm osi *)
      Make4('', R, bAlarmSciezki, AlarmSciezki_A_G, ShortCuts.kbNoKey,
            AlarmSciezki_A_D, ShortCuts.kbNoKey, AlarmSciezki_B_G,
            ShortCuts.kbNoKey, AlarmSciezki_B_D, ShortCuts.kbNoKey);
      MoveRect(R, 0, DY);
      (* szerokosc sektora w profilu A *)
      Make4('', R, bSzerSektora_pA, SzerSektora_pA_A_G, ShortCuts.kbNoKey,
            SzerSektora_pA_A_D, ShortCuts.kbNoKey, SzerSektora_pA_B_G,
            ShortCuts.kbNoKey, SzerSektora_pA_B_D, ShortCuts.kbNoKey);
      MoveRect(R, 0, DY);
      (* alarm szeroki w profilu A *)
      Make4('', R, bAlarmSzeroki_pA, AlarmSzeroki_pA_A_G, ShortCuts.kbNoKey,
            AlarmSzeroki_pA_A_D, ShortCuts.kbNoKey, AlarmSzeroki_pA_B_G,
            ShortCuts.kbNoKey, AlarmSzeroki_pA_B_D, ShortCuts.kbNoKey);
      MoveRect(R, 0, DY);
      (* alarm waski w profilu A *)
      Make4('', R, bAlarmWaski_pA, AlarmWaski_pA_A_G, ShortCuts.kbNoKey,
            AlarmWaski_pA_A_D, ShortCuts.kbNoKey, AlarmWaski_pA_B_G,
            ShortCuts.kbNoKey, AlarmWaski_pA_B_D, ShortCuts.kbNoKey);
      MoveRect(R, 0, DY);
      INC(R.right, DX);
      (* Kat sciezki *)
      Make2('', R, bKatSciezki, KatSciezki_A, ShortCuts.kbNoKey, KatSciezki_B,
            ShortCuts.kbNoKey);
      MoveRect(R, 0, DY);
      (* Kat sciezki dla Alarmu szerokiego w prof. A *)
      Make2('', R, bKatSciezki_Szer_pA, KatSciezki_Szer_pA_A, ShortCuts.kbNoKey,
            KatSciezki_Szer_pA_B, ShortCuts.kbNoKey);
      MoveRect(R, 0, DY);
      (* Kat sciezki dla Alarmu waskiego w prof. A *)
      Make2('', R, bKatSciezki_Waski_pA, KatSciezki_Waski_pA_A, ShortCuts.kbNoKey,
            KatSciezki_Waski_pA_B, ShortCuts.kbNoKey);
      MoveRect(R, 0, DY);
      (* Pomiar szerokosci sektora, wyrazistosci i ust. osi w prof. B *)
      Make2('', R, bSzer_i_Osi_pB, Szer_i_Osi_pB_A, ShortCuts.kbNoKey,
            Szer_i_Osi_pB_B, ShortCuts.kbNoKey);
      MoveRect(R, 0, DY);
      (* Alarm szeroki ust. osi w prof. B *)
      Make2('', R, bAlarmSzer_pB, AlarmSzer_pB_A, ShortCuts.kbNoKey, AlarmSzer_pB_B
            , ShortCuts.kbNoKey);
      MoveRect(R, 0, DY);
      (* Alarm Waski ust. osi w prof. B *)
      Make2('', R, bAlarmWaski_pB, AlarmWaski_pB_A, ShortCuts.kbNoKey,
            AlarmWaski_pB_B, ShortCuts.kbNoKey);
      MoveRect(R, 0, DY);
      (* Rownowaga modulacji *)
      Make2('', R, bRownowagaModulacji, RownowagaModulacji_A, ShortCuts.kbNoKey,
            RownowagaModulacji_B, ShortCuts.kbNoKey);
      MoveRect(R, 0, DY);
      (* Fazowanie *)
      Make2('', R, bFazowanie, Fazowanie_A, ShortCuts.kbNoKey, Fazowanie_B,
            ShortCuts.kbNoKey);
      MoveRect(R, 0, DY);
      (* zabezpieczenie przed przeszkodami *)
      Make2('', R, bZabezpieczenie, Zabezpieczenie_A, ShortCuts.kbNoKey,
            Zabezpieczenie_B, ShortCuts.kbNoKey);
      MoveRect(R, 0, DY);
      (* pokrycie w osi *)
      Make2('', R, bPokrycieWOsi, Pokrycie_w_osi_A, ShortCuts.kbNoKey,
            Pokrycie_w_osi_B, ShortCuts.kbNoKey);
      MoveRect(R, 0, DY);
      (* pokrycie 8 stopni w prawo *)
      Make2('', R, bPokrycie8stP, Pokrycie_8_st_P_A, ShortCuts.kbNoKey,
            Pokrycie_8_st_P_B, ShortCuts.kbNoKey);
      MoveRect(R, 0, DY);
      (* pokrycie 8 stopni w lewo *)
      Make2('', R, bPokrycie8stL, Pokrycie_8_st_L_A, ShortCuts.kbNoKey,
            Pokrycie_8_st_L_B, ShortCuts.kbNoKey);
      MoveRect(R, 0, DY);
      IF PA_PA.PomiarANieArchiwum THEN
        Make3('Identyfikacja punkt¢w A, B, C(TH)', R,
              bIdentPunktow,
              IdentPkt0, ShortCuts.kbNoKey,
              IdentPkt1, ShortCuts.kbNoKey,
              IdentPkt2, ShortCuts.kbNoKey);
      END;
      MoveRect(R, 0, DY);
      R1 := R;
      MoveRect(R1, DX + DX, 0);
      (* Glowny odbiornik *)
      WstawButton(hDlg, R, "", -1, ShortCuts.kbAltY, GlowOdbP, GlowOdb);
      WrStr("Gˆ¢wny odbiornik", R.right+5, R.top, BLACK, BLACK);
      (*
      MoveRect(R, 0, DY);
      WstawInpLine(hDlg, R.left, R.top, 12, RealValid, WHITE, BLUE,
                          lSzer_sekt_kier);
      WrStr('Szeroko˜† sektora', R.right+5, R.top, BLUE, BLUE);
      *)
      MoveRect(R, 0, DY);
      IF PA_PA.PomiarANieArchiwum THEN
        WstawInpLine(hDlg, R.left, R.top, 12, RealCisnValid, WHITE,
                          MAGENTA, CisnienieOdn_L);
        WrStr("Ci˜nienie odniesienia", R.right+5, R.top, MAGENTA, MAGENTA);
      END;
      (* Guziki wlaczajace *)
      AssignRect(R, 800, 600, 810, 610);
      MoveRect(R1, 800-R1.right-10, 0);
      IF PA_PA.PomiarANieArchiwum THEN
        WstawButton(hDlg, R1, "POMIAR", 0, ShortCuts.kbAltP, PomiarP,
                           Pomiar);
        WstawButton(hDlg, R, "", -1, ShortCuts.kbEnter, PomiarP,
                           Pomiar);
        MoveRect(R1, 0, DY);
        WstawButton(hDlg, R1, "TEST", 0, ShortCuts.kbAltT, TestUP_PROC,
                           TestUP);
      ELSE
        WstawButton(hDlg, R1, "DYNAMICZ", 0, ShortCuts.kbAltD, PlayP,
                           Pomiar);
        MoveRect(R1, 0, DY);
        WstawButton(hDlg, R1, "STATYCZ", 0, ShortCuts.kbAltS, View_PROC,
                           TestUP);
      END;
      MoveRect(R1, 0, DY);
      WstawButton(hDlg, R1, "RAPORT", 0, ShortCuts.kbAltR,
                         Raport_PROC, Raport);
      MoveRect(R1, 0, DY);
      WstawButton( hDlg, R1, "KONIEC", 0, ShortCuts.kbAltK, AltF4, void );
      WstawButton( hDlg, R, "", -1, ShortCuts.kbAltF4, AltF4,
                          void);
      IF NOT PA_PA.PomiarANieArchiwum THEN
        MoveRect( R1, -(R1.right-R1.left+5), 00 );
        WstawButton( hDlg, R1, "RAP. KOã", -1, ShortCuts.kbAltF5,
                            RaportKoncowy, void);
      END;
    END AssignButt;

  BEGIN (* InitLot *)
    RedrawScr := TRUE;
    CoRobimy := czPomiar;
    AssignRect(R, 0, 0, 800, 599);
    hDlg := TworzDialog(R, "gs-co.bmp", FALSE);
    AssignButt;
    FillData;
    InitDefault;
    OdnOdlP;
    GlowOdbP;
    IF PA_PA.PomiarANieArchiwum THEN
      IdentPkt0;
      IdentPkt1;
      IdentPkt2;
    END;
    RedrawScr := FALSE;
    kont := Go(hDlg);
    IF PA_PA.PomiarANieArchiwum THEN
      CisnienieOdniesienia := RealVal(CisnienieOdn_L);
      SaveDefault;
    END;
    UsunDialog(hDlg);
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
      SciezkaOpisuPomiaru[Length(SciezkaOpisuPomiaru) - Length(NazwaPlikuIni)]
      := 0C;
      (* skasowana nazwa "oblt-gs.ini" *)
      nad := NadajnikCH();
      strona := StronaCH();
      IF (Procedura <= pAlarmWaski_pA)
      THEN
        Fmt := '%03d_%c_%c.gs'
      ELSE
        Fmt := '%03d_%c.gs'
      END (* if *);
      i := ORD(Procedura);
      sprintf3(Tmp, Fmt, i, nad, strona);   (* Kartoteka o postaci 001_A_L.gs *)
      Insert(Tmp, SciezkaOpisuPomiaru, 0FFFH);
      Insert('\', SciezkaOpisuPomiaru, 0FFFH);
    END SciezkaDoKataloguOpisu;

  PROCEDURE Wlacz_Wylacz( );
    VAR
      Tmp : ARRAY [0..127] OF CHAR;
      en  : BOOLEAN;
    BEGIN
      SciezkaDoKataloguOpisu();
      Assign( SciezkaOpisuPomiaru, Tmp );
      Tmp[ Length( Tmp ) -1 ] := 0C;
      en := Files.ExistDIR( Tmp );
      IF NOT PA_PA.PomiarANieArchiwum THEN
        Buttons.EnableButton( Pomiar, en );
        Buttons.EnableButton( TestUP, en );
      END;
      Buttons.EnableButton( Raport, en );
    END Wlacz_Wylacz;




  PROCEDURE Zapisz
            (    EfektPolaryzacji : BOOLEAN;
                 ZakodowanyBlad,
                 Podzielnik       : INTEGER );

  TYPE
    str99 =
      ARRAY [0 .. 99] OF CHAR;
  VAR
    Tmp  : str99;
    Tmp1 : str99;
    Fmt  : str99;
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
      IF (Procedura <= pAlarmWaski_pA)
      THEN
        Fmt := '%s.%c.%c';
      ELSE
        Fmt := '%s.%c';
      END (* if *);
      CASE Procedura OF
        pAlarmOsi :
          Tmp := 'AlarmSciezki';
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
          Tmp := "KatSciezki";
        |
        pUstawienieOsi_Szer_pA :
          Tmp := 'KatSciezki_Szer_pA';
        |
        pUstawienieOsi_Waski_pA :
          Tmp := 'KatSciezki_Waski_pA';
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
        pZabezpieczenie :
          Tmp := 'Zabezpieczenie';
        |
        pPokrycieWOsi :
          Tmp := 'Pokrycie_w_osi';
        |
        pPokrycie8stL :
          Tmp := 'Pokrycie_8_st_L';
        |
        pPokrycie8stP :
          Tmp := 'Pokrycie_8_st_P';
      END (* case Procedura *);
      a := ADR(Tmp);
      sprintf3(ident, Fmt, a, nad, strona);
    END ProcIdentifier;

  BEGIN (* Zapisz *)
    GetTimeAndDate(t_d);
    ProcIdentifier(Procedura, Tmp1);
    ConvertToStr(t_d, TRUE, Fmt);
    IF ZakodowanyBlad = SigNilVal
    THEN
      Insert( "(!!!!!)", Fmt, 0 );
      sprintf( Tmp, Fmt, t_d );
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
  GlownyOdbiornik := MIN(GlownyOdbiornikT);
  OdnDlaPomOdl := poGPS;
  Szer_sekt_kier := 300;
  Procedura := MIN(ProceduraT);
  Strona := MIN( StronaT );
END G_Oblot.
