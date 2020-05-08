(*.F- *)
(**********************************************************************
|  Title   : Glowny ekran sterujacy dla VORa trasowego
|  Author  : M.Morawski
|  System  : LOGITECH MODULA-2/86
|  History :
|    22-09-96:
|      brak inicjacji wspolnych zmiennych z CommonData.
|      do usuniecia
|         brak inicjacji zmiennej  Promien
|    15-12-96: M.Postol
|      zmiana w FillData - nowa def GeoArithmetic
|   01-26-97 03:52pm: MM
|     Dodany podzielnik w procedurze Zapisz
|   03-13-97 01:05pm: MM
|     Dane, dla ktorych nie wyznaczono rezultatu koncowego zaznaczane sa
|     wykrzyknikami
|   Rel. 3.0. MPostol
|     Przeniesione definicje
|   Rel. 3.14. MPostol
|     - Dostosowalem do nowej defincicji GeoArithmetic - inne wskazywanie 
|       polozen odniesienia
|
|  Copyright (C), CAS LODZ POLAND.
|  TEL: 42' 862 547, 42' 87 80 44 FAX/TEL: 42' 84 48 40
|
**********************************************************************)
(*.F+ *)

IMPLEMENTATION MODULE T_Oblot;

  IMPORT
    ShortCuts, InpLine, Buttons, MsgBox, Files, Mapa, PI_PA;

  FROM V_CommonTypes IMPORT
    ProceduraT, Procedura;

FROM CommonData IMPORT
  OdnDlaPomBledu, OdnDlaPomOdl, SciezkaOpisuPomiaru,
  NazwaOblotu,  NazwaPlikuOpisu, Nadajnik1, Nadajnik2,
  GlownyOdbiornik, Promien, Orbita, Predkosc, CisnienieOdniesienia,
  NazwaUrzadz1, NazwaUrzadz2, DME;

  FROM SpecConv IMPORT
    Int100Str;

  FROM HiLevGraf IMPORT
    WrStr;

  FROM Dialog IMPORT
    HDLG, EndDialog, TworzDialog, WstawListe, WstawButton, EnableDlg, Go,
    UsunDialog, Redraw, AltF4, WstawInpLine, WstawRadioButton;

  FROM GList IMPORT
    HLIST, DodajDoListy, Idx2Str, Sortowana, SetNotificationProc;

  FROM Obloty IMPORT
    NazwaPlikuIni;

  FROM GrafTypes IMPORT
    RECT, AssignRect, MoveRect, WHITE, BLUE, MAGENTA, BLACK, LT_RED, GREEN;

  FROM GrafUtil IMPORT
    Info, InfoBeep;

  FROM GeoArithmetic IMPORT
    Geo2Kat, PolozenieBiegunoweMtx, IndxPolozenia; 

  FROM Sounds IMPORT
    Sound, NoSound;

  FROM Timer IMPORT
    Wait, TInOneSecond;

  FROM NumberConversion IMPORT
    StringToCard, CardToString, StringToInt;

  FROM RealConversions IMPORT
    StringToReal, RealToString;

  FROM Strings IMPORT
    Length, Insert, Assign;

  FROM Ini IMPORT
    GetPrivateProfileString, WritePrivateProfileString;

  FROM StdIO IMPORT
    sprintf, sprintf2, sprintf3;

  FROM V_Database IMPORT
    LoadVorData1, LoadVorData2, CurVor1, CurVor2;

  FROM MANAGER IMPORT
    Assert, STARTPROCESS;

  FROM HiLevGraf IMPORT
    Wr2fStrXY;

  FROM SYSTEM IMPORT
    ADR, ADDRESS;

  FROM Tune IMPORT
    TuneVOR, MaxNAV_Chann_Num, Receiver, TuneDMEforVOR;

  FROM Czas IMPORT
    TimeAndDate, GetTimeAndDate;

  FROM MathLib0 IMPORT
    entier, real;

  FROM CommonTypes IMPORT
    OdnDlaPomBleduT, GlownyOdbiornikT, NadajnikT, OdnDlaPomOdlT,
    SigNilVal, DisNilVal, Str40, Str99;


  FROM RTSMain IMPORT
    Terminate, Status;

  FROM SwitchCntrl IMPORT
    SwState, SwitchTo;

  TYPE
    A_B          =
      RECORD
        A, B :
          Buttons.Button;
      END;

  VAR
    hDlg                 : HDLG;
    bNadajnik            : A_B;
    GlowOdb              : Buttons.Button;
    CisnienieOdn         : InpLine.HLINE;
    TestUP               : Buttons.Button;
    Raport               : Buttons.Button;
    Pomiar, Pomiar1      : Buttons.Button;  (* Test urzadzen pomiarowych *)
    RedrawScr            : BOOLEAN;

  CONST
    MainSection = "TRS";
    ParamFile   = "pomiar.par";

  PROCEDURE NadajnikNaVor1(  );
    VAR
      s : ARRAY[0..10] OF CHAR;
      c : CHAR;
    BEGIN
      IF NOT RedrawScr THEN
        IF Nadajnik1 = nA THEN
          Nadajnik1 := nB;
        ELSE
          Nadajnik1 := nA;
        END;
      END;
      IF (Nadajnik1=nA) THEN
        c := 'G';
      ELSE
        c := 'Z';
      END;
      sprintf( s, "(1) Nad `%c'", c );
      Buttons.ChangeButton( bNadajnik.A, s, 1 );
      Wlacz_Wylacz;
    END NadajnikNaVor1;

  PROCEDURE NadajnikNaVor2(  );
    VAR
      s : ARRAY[0..10] OF CHAR;
      c : CHAR;
    BEGIN
      IF NOT RedrawScr THEN
        IF Nadajnik2 = nA THEN
          Nadajnik2 := nB;
        ELSE
          Nadajnik2 := nA;
        END;
      END;
      IF (Nadajnik2=nA) THEN
        c := 'G';
      ELSE
        c := 'Z';
      END;
      sprintf( s, "(2) Nad `%c'", c );
      Buttons.ChangeButton( bNadajnik.B, s, 1 );
      Wlacz_Wylacz;
    END NadajnikNaVor2;

  PROCEDURE TestUP_PROC();
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
    InfoBeep ( s, 3, Snd );
  END Pokaz;

  PROCEDURE ZakonczDlg();

  BEGIN
    EndDialog(TRUE);
  END ZakonczDlg;

  PROCEDURE PomiarP();
  BEGIN
    CoRobimy := czPomiar;
    EndDialog(TRUE);
  END PomiarP;

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
      ELSIF KillFocus & ((r < 1.0) OR (r > 7.0))
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
        i := "Napis nie jest liczba rzeczywist¥";
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

  PROCEDURE NadajnikCH( n : NadajnikT ) : CHAR;

  BEGIN
    RETURN CHR(ORD(n) + ORD('A'));   (* A lub B *)
  END NadajnikCH;

  PROCEDURE InitLot( ) : BOOLEAN;

  CONST
    DX        = 100;
    DY        = 34;
    SZEROKOSC = 105;
  VAR
    kont : BOOLEAN;
    s    : ARRAY [0 .. 31] OF CHAR;
    R    : RECT;

    PROCEDURE InitDefault;
    VAR
      c      : CARDINAL;
      ok     : BOOLEAN;

    BEGIN
      IF PI_PA.PomiarANieArchiwum THEN
        (* Cisnienie *)
        GetPrivateProfileString(MainSection, "CisnienieOdn", "1013.8", s,
                                ParamFile);
        InpLine.SetText(CisnienieOdn, s);
        IF NOT RealCisnValid(CisnienieOdn, s, TRUE)
        THEN
          CisnienieOdniesienia := 1013.8;
          InpLine.SetText(CisnienieOdn, "1013.8");
        ELSE
          CisnienieOdniesienia := RealVal(CisnienieOdn);   (* MP *)
        END (* if *);
      END;
    END InitDefault;

    PROCEDURE SaveDefault;
    VAR
      s      : Str40;
    BEGIN
      IF PI_PA.PomiarANieArchiwum THEN
        sprintf(s, "%8.1lf", CisnienieOdniesienia);
        WritePrivateProfileString(MainSection, "CisnienieOdn", s, ParamFile);
      END;
    END SaveDefault;

    PROCEDURE AssignButt;
    VAR
      R1 : RECT;
      R  : RECT;
      b  : Buttons.Button;
    BEGIN (* AssignButt *)
      AssignRect(R, 5, 50, 5 + SZEROKOSC, 80);

      WstawRadioButton(hDlg, R, "", 1, ShortCuts.kbAlt1, NadajnikNaVor1, bNadajnik.A);
      WrStr( NazwaUrzadz1, R.left, R.bottom+5, WHITE, WHITE );
      MoveRect(R, DX + DX, 0);
      WstawRadioButton(hDlg, R, "", 1, ShortCuts.kbAlt2, NadajnikNaVor2, bNadajnik.B);
      WrStr( NazwaUrzadz2, R.left, R.bottom+5, WHITE, WHITE );

      MoveRect(R, 0, DY);
      MoveRect(R, 0, 4*DY);
      IF PI_PA.PomiarANieArchiwum THEN
        WstawInpLine(hDlg, R.left, R.top, 12, RealCisnValid, WHITE,
                            MAGENTA, CisnienieOdn);
        WrStr("Ci˜nienie odniesienia", R.right+30, R.top, MAGENTA, MAGENTA);
      END;
      MoveRect(R, 0, 2*DY);

      (* Guziki wlaczajace *)
      AssignRect(R1, 500, 400+DY, 590, 425+DY );
      AssignRect( R, 10000, 10000, 10000, 10000 );
(*      MoveRect(R1, 800-R1.right-10, 0);*)
      IF PI_PA.PomiarANieArchiwum THEN
        WstawButton(hDlg, R1, "POMIAR", 0, ShortCuts.kbAltP, PomiarP,
                           Pomiar1);
        WstawButton(hDlg, R, "", -1, ShortCuts.kbEnter, PomiarP,
                           Pomiar);
        MoveRect(R1, 0, DY);
        WstawButton(hDlg, R1, "TEST", 0, ShortCuts.kbAltT, TestUP_PROC,
                           TestUP);
      ELSE
        WstawButton(hDlg, R, "", -1, ShortCuts.kbEnter, PlayP,
                           Pomiar1);
        WstawButton(hDlg, R1, "DYNA.", 0, ShortCuts.kbAltD, PlayP,
                           Pomiar);
        MoveRect(R1, 0, DY);
        WstawButton(hDlg, R1, "STAT", 0, ShortCuts.kbAltS, View_PROC,
                           TestUP);
      END;
      MoveRect(R1, 0, DY);
      WstawButton(hDlg, R1, "RAPORT", 0, ShortCuts.kbAltR,
                         Raport_PROC, Raport);
      MoveRect(R1, 0, DY);
      WstawButton( hDlg, R1, "KONIEC", 0, ShortCuts.kbAltK, AltF4, b );
      WstawButton( hDlg, R, "", -1, ShortCuts.kbAltF4, AltF4,
                          b);
      AssignRect( R, 10, 300, 200, 500 );
    END AssignButt;

    PROCEDURE FillData(  );
      VAR
        f : RECORD
          a1 : ADDRESS;
          int1,
          part1 : CARDINAL;
          a2 : ADDRESS;
          int2,
          part2 : CARDINAL;
        END;
        s : ARRAY[0..99] OF CHAR;
        pk : PolozenieBiegunoweMtx;
        cc : ARRAY[0..0] OF CARDINAL;
      BEGIN
        Mapa.StartProcess;
        f.int1 := CurVor1.Czestotliwosc DIV 100;
        f.part1 := CurVor1.Czestotliwosc MOD 100;
        f.a1 := ADR( NazwaUrzadz1 );
        f.int2 := CurVor2.Czestotliwosc DIV 100;
        f.part2 := CurVor2.Czestotliwosc MOD 100;
        f.a2 := ADR( NazwaUrzadz2 );
        sprintf( s, "%s(%d.%02d MHz) i %s(%d.%02d MHz)", f );
        Wr2fStrXY( s, 5, 300, WHITE, WHITE );
        Geo2Kat( CurVor2.Polozenie, pk);
        Promien := TRUNC(pk[MIN(IndxPolozenia)].Kat+CurVor1.Deklinacja+0.5 );
        sprintf( s, "Kierunek lotu=%dø", Promien );
        Wr2fStrXY( s, 5, 350, WHITE, WHITE );
        TuneVOR( AReceiver, CurVor1.Czestotliwosc );
        TuneVOR( BReceiver, CurVor2.Czestotliwosc );
        TuneDMEforVOR( AReceiver, CurVor1.Czestotliwosc );
        TuneDMEforVOR( BReceiver, CurVor2.Czestotliwosc );
        SwitchTo(Antena);
        NadajnikNaVor2;
        cc[0] := MAX( CARDINAL );
        Mapa.Promienie( cc, cc, Promien );
      END FillData;

  BEGIN (* InitLot *)
    RedrawScr := TRUE;
    DME := CurVor1.CzyJestDME OR CurVor2.CzyJestDME;
    AssignRect(R, 0, 0, 800, 599);
    hDlg := TworzDialog(R, "trs-co.bmp", FALSE);
    AssignButt;
    FillData;
    InitDefault;
(*    OdnOdlP;*)
    RedrawScr := FALSE;
    NadajnikNaVor1; (* bo bedzie jeszcze wywolany przez Go *)
    kont := Go(hDlg);
    IF PI_PA.PomiarANieArchiwum THEN
      CisnienieOdniesienia := RealVal(CisnienieOdn);
      SaveDefault;
    END;
    UsunDialog(hDlg);
    SciezkaDoKataloguOpisu();
    Mapa.CancelProcess;
    RETURN kont;
  END InitLot;

  PROCEDURE SciezkaDoKataloguOpisu();
    VAR
      nad1,
      nad2 : CHAR;
      Tmp  : ARRAY [0 .. 128] OF CHAR;

    BEGIN
      Assign(NazwaPlikuOpisu, SciezkaOpisuPomiaru);
      SciezkaOpisuPomiaru[Length(SciezkaOpisuPomiaru) - Length(NazwaPlikuIni)]
      := 0C;
      (* skasowana nazwa "oblt-trs.ini" *)
      nad1 := NadajnikCH( Nadajnik1 );
      nad2 := NadajnikCH( Nadajnik2 );
      sprintf2( Tmp, "%c.%c", nad1, nad2 );
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
      IF NOT PI_PA.PomiarANieArchiwum THEN
        Buttons.EnableButton( Pomiar, en );
        Buttons.EnableButton( Pomiar1, en );
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
    t_d  : TimeAndDate;
    nad1,
    nad2  : CHAR;

  BEGIN (* Zapisz *)
    nad1 := NadajnikCH(Nadajnik1);
    nad2 := NadajnikCH(Nadajnik2);
    GetTimeAndDate(t_d);
    Assert( Podzielnik = 100 );
    Tmp1 := "Blad";
    IF ZakodowanyBlad = SigNilVal
    THEN
      sprintf(Tmp, "(!!!!!) godz.%2d:%02d dn.%2d.%02d.%4d ", t_d);
    ELSE
      sprintf2(Tmp, "(%5z) godz.%2d:%02d dn.%2d.%02d.%4d ", ZakodowanyBlad, t_d);
    END;
    WritePrivateProfileString(NazwaOblotu, Tmp1, Tmp, NazwaPlikuOpisu);
    sprintf(Tmp, "%2d.%02d.%4d", t_d.d);
    WritePrivateProfileString(NazwaOblotu, "OstatniaModyfikacja", Tmp,
                              NazwaPlikuOpisu);
(*
    IF Procedura = pPromien THEN
      Zaznacz();
    END;
*)
  END Zapisz;

BEGIN
  Promien := 0;
  Orbita  := DisNilVal;
  Predkosc := 1.0e308;
  Procedura := pPromienZakres;
  OdnDlaPomBledu := pbGPS;
  OdnDlaPomOdl := poGPS;
  GlownyOdbiornik := goA;
  Nadajnik1 := nA;
  Nadajnik2 := nA;
END T_Oblot.
