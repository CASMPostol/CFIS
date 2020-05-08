(*.F- *)
(**********************************************************************
|  Title   : Glowny ekran sterujacy dla NDB
|  Author  : M.Morawski
|  System  : LOGITECH MODULA-2/86
|  History :
|   01-26-97 03:52pm: MM
|     Dodany podzielnik w procedurze Zapisz
|   03-13-97 01:05pm: MM
|     Dane, dla ktorych nie wyznaczono rezultatu koncowego zaznaczane sa
|     wykrzyknikami
|   29-03-97: M.Postol
|     zla asercia w Zapisz
|   05-27-97 10:13pm: MM
|     klawisz do raportu koncowego
|   25-02-98: M.Postol
|     blad przy czytaniu czestotliwosci - czestotliwosc w bazie danych
|     powinna buc w KHz, a nie *100 bo sie nie miesci w CARDINAL
|   
|  Copyright (C), CAS LODZ POLAND.
|  TEL: 42' 862 547, 42' 87 80 44 FAX/TEL: 42' 84 48 40
|
**********************************************************************)
(*.F+ *)

IMPLEMENTATION MODULE N_Oblot;

  IMPORT
    ShortCuts, InpLine, Buttons, MsgBox, Files, PI_PA;

  FROM CommonData IMPORT
    SciezkaOpisuPomiaru, NazwaOblotu, NazwaUrzadz1, NazwaPlikuOpisu,
    Nadajnik1, Orbita, Promien, CisnienieOdniesienia, GlownyOdbiornik,
    OdnDlaPomBledu, OdnDlaPomOdl, DME;

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
    InfoBeep;

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

  FROM N_DataBase IMPORT
    OpisNadajnika, NadajnikNDB;

  FROM MANAGER IMPORT
    Assert, STARTPROCESS;

  FROM HiLevGraf IMPORT
    Wr2fStrXY;

  FROM SYSTEM IMPORT
    ADR, ADDRESS;

  FROM Tune IMPORT
    TuneADF, Receiver;

  FROM Czas IMPORT
    GetTimeAndDate;

  FROM MathLib0 IMPORT
    entier, real;

  FROM CommonTypes IMPORT
    OdnDlaPomBleduT, GlownyOdbiornikT, NadajnikT, TimeAndDate, OdnDlaPomOdlT,
    SigNilVal, CoMoznaZrobic, Str40, Str99;

  FROM N_CommonTypes IMPORT
    Procedura, ProceduraT;

  FROM RTSMain IMPORT
    Terminate, Status;

  TYPE
    A_B          =
      RECORD
        A, B :
          Buttons.Button;
      END;

  VAR
    hDlg                 : HDLG;
    bOkrag,
    bPromien             : A_B;
    GlowOdb              : Buttons.Button;
    CisnienieOdn         : InpLine.HLINE;
    OrbitaL,
    PromienL             : InpLine.HLINE;
    TestUP               : Buttons.Button;
    Raport               : Buttons.Button;
    Pomiar               : Buttons.Button;  (* Test urzadzen pomiarowych *)
    Lista                : RECORD
      A, B : HLIST;
    END;
    RedrawScr            : BOOLEAN;

  CONST
    MainSection = "NDB";
    ParamFile   = "pomiar.par";


  PROCEDURE Okrag_A(  );
    BEGIN
      Procedura := pOrbita;
      Nadajnik1 := nA;
      Wlacz_Wylacz();
    END Okrag_A;

  PROCEDURE Okrag_B(  );
    BEGIN
      Procedura := pOrbita;
      Nadajnik1 := nB;
      Wlacz_Wylacz();
    END Okrag_B;

  PROCEDURE Promien_A(  );
    BEGIN
      Procedura := pPromien;
      Nadajnik1 := nA;
      Wlacz_Wylacz();
    END Promien_A;

  PROCEDURE Promien_B(  );
    BEGIN
      Procedura := pPromien;
      Nadajnik1 := nB;
      Wlacz_Wylacz();
    END Promien_B;

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

  PROCEDURE RaportKoncowyP(  );
    BEGIN
      CoRobimy := czRaportKoncowy;
      EndDialog(TRUE);
    END RaportKoncowyP;

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
    Assert( PI_PA.PomiarANieArchiwum );
    InpLine.GetText(l, s);
    StringToReal(s, r, ok);
    Assert(ok);
    RETURN r;
  END RealVal;

  PROCEDURE Pokaz
            (    s   : ARRAY OF CHAR;
                 Snd : CARDINAL      );

  BEGIN
    InfoBeep(s,3,Snd);
  END Pokaz;

  PROCEDURE CzyDobraOrbita
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
      ELSIF (r > 100.0) OR (r < 1.0)
      THEN
        i := "Wprowadzona liczba jest zbyt du¾a lub zbyt maˆa";
        ok := FALSE;
      END (* if *);
      IF NOT ok
      THEN
        Pokaz(i, 2000);
      ELSE
        Orbita := TRUNC( r * 500.0 + 0.5);
      END (* if *);
      RETURN ok;
    ELSE
      RETURN TRUE;
    END (* if KillFocus *);
  END CzyDobraOrbita;

  PROCEDURE CzyDobryPromien
            (     l         : InpLine.HLINE;
              VAR s         : ARRAY OF CHAR;
                  KillFocus : BOOLEAN       ) : BOOLEAN;
  VAR
    p  : CARDINAL;
    ok : BOOLEAN;
    i  : ARRAY [0 .. 99] OF CHAR;

  BEGIN
    IF KillFocus
    THEN
      StringToCard(s, p, ok);
      IF NOT ok
      THEN
        i := "Napis nie jest liczb¥ caˆkowit¥";
      ELSIF p > 359
      THEN
        i := "Wprowadzona liczba jest zbyt du¾a";
        ok := FALSE;
      END (* if *);
      IF NOT ok
      THEN
        Pokaz(i, 2000);
      ELSE
        Promien := p ;
      END (* if *);
      RETURN ok;
    ELSE
      RETURN TRUE;
    END (* if KillFocus *);
  END CzyDobryPromien;

  PROCEDURE ZakonczDlg();

  BEGIN
    EndDialog(TRUE);
  END ZakonczDlg;

  PROCEDURE PomiarP();
  BEGIN
    CoRobimy := czPomiar;
    EndDialog(TRUE);
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

  PROCEDURE RealValid
            (     l         : InpLine.HLINE;
              VAR s         : ARRAY OF CHAR;
                  KillFocus : BOOLEAN       ) : BOOLEAN;
  VAR
    r  : REAL;
    ok : BOOLEAN;
    i  : ARRAY [0 .. 99] OF CHAR;

  BEGIN
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

  PROCEDURE PoprawPromien( Lista : HLIST; sel : INTEGER );
    VAR
      s : Str40;
      ok : BOOLEAN;
    BEGIN
      IF sel < 0 THEN
        RETURN;
      END;
      Idx2Str( Lista, sel, s );
  (*      Terminate( Warning );*)
      s[3] := 0C;
      IF PI_PA.PomiarANieArchiwum THEN
        InpLine.SetText( PromienL, s );
      END;
      StringToCard( s, Promien, ok );
      Assert( ok );
      Wlacz_Wylacz;
    END PoprawPromien;

  PROCEDURE PoprawPromienA( sel : INTEGER );
    BEGIN
      PoprawPromien( Lista.A, sel );
    END PoprawPromienA;

  PROCEDURE PoprawPromienB( sel : INTEGER );
    BEGIN
      PoprawPromien( Lista.B, sel );
    END PoprawPromienB;

  PROCEDURE NadajnikCH() : CHAR;

  BEGIN
    RETURN CHR(ORD(Nadajnik1) + ORD('A'));   (* A lub B *)
  END NadajnikCH;

  PROCEDURE InitLot(  ) : BOOLEAN;

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

    BEGIN
      GetPrivateProfileString(MainSection, "GlownyOdbiornik", "0", s, ParamFile
      );
      StringToCard(s, c, ok);
      IF NOT ok
      THEN
        c := 0;
      END (* if *);
      GlownyOdbiornik := VAL(GlownyOdbiornikT, c);

      (* Cisnienie *)
      IF PI_PA.PomiarANieArchiwum THEN
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
        (* Ostatnia Orbita *)
        GetPrivateProfileString(MainSection, "Orbita", "10.0", s,
                                ParamFile);
        InpLine.SetText(OrbitaL, s);
        IF NOT CzyDobraOrbita(OrbitaL, s, TRUE)
        THEN
          Orbita := 5000;
          InpLine.SetText(OrbitaL, "10.0");
        ELSE
          Orbita := TRUNC(RealVal(OrbitaL)*500.0+0.5);
        END (* if *);
      END;
      LecianePromienie( Lista.B, 'B');
      LecianePromienie( Lista.A, 'A');
    END InitDefault;

    PROCEDURE LecianePromienie( Lista : HLIST; Nad : CHAR );
      VAR
        ok : BOOLEAN;
        s, t : Str40;
        s1 : ARRAY[0..99] OF CHAR;
        i, j, k, Ile : INTEGER;
        p : CARDINAL;
      BEGIN
        s := '0';
        sprintf( t, "IloscPromieni.%c", Nad);
        GetPrivateProfileString( NazwaOblotu, t, '0', s, NazwaPlikuOpisu );
        StringToInt( s, Ile, ok );
        IF NOT ok THEN
          Ile := 0;
        END;
        FOR i := 0 TO Ile-1 DO
          sprintf2( t, "%c.%d", Nad, i );
          GetPrivateProfileString( NazwaOblotu, t, '@@', s, NazwaPlikuOpisu );
          StringToCard( s, p, ok );
          Assert( ok );
          sprintf( s, "%03d", p );
          sprintf2( t, "Promien.%c.%03d", Nad, p );
          GetPrivateProfileString( NazwaOblotu, t, '', s1, NazwaPlikuOpisu );
          j := 0;
          k := 3;
          REPEAT
            s[k] := s1[j];
            INC(k);
            INC(j);
          UNTIL (s[j-1] = 0C) OR (s[j-1] = ')');
          s[j] := 0C;
          DodajDoListy( Lista, s );
        END;
        s[3] := 0C;
        IF PI_PA.PomiarANieArchiwum THEN
          InpLine.SetText( PromienL, s );
        END;
      END LecianePromienie;

    PROCEDURE SaveDefault;
    VAR
      t      : Str40;
      s      : Str40;
      Ile    : INTEGER;
      r      : REAL;
    BEGIN
      CardToString(ORD(GlownyOdbiornik), s, 1);
      WritePrivateProfileString(MainSection, "GlownyOdbiornik", s, ParamFile);
      sprintf(s, "%8.1lf", CisnienieOdniesienia);
      WritePrivateProfileString(MainSection, "CisnienieOdn", s, ParamFile);
      r := FLOAT(Orbita)/500.0;
      sprintf(s, "%lf", r );
      WritePrivateProfileString(MainSection, "Orbita", s, ParamFile);
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
        WrStr(name, R.right+5, R.top, WHITE, WHITE);
      END Make2;

    VAR
      void : Buttons.Button;
    BEGIN (* AssignButt *)
      AssignRect(R, 5, 50, 5 + SZEROKOSC, 70);

      (* po okregu *)
      Make2('Okr¥g', R, bOkrag, Okrag_A, ShortCuts.kbAltO, Okrag_B, ShortCuts.kbCtrlO );
      (* po promieniu *)
      MoveRect(R, 0, DY);
      Make2('Promieä', R, bPromien, Promien_A, ShortCuts.kbAltP,
                                    Promien_B, ShortCuts.kbCtrlP );
      MoveRect(R, 0, 2*DY);
      IF PI_PA.PomiarANieArchiwum THEN
        WstawInpLine(hDlg, R.left, R.top, 12, RealCisnValid, WHITE,
                            MAGENTA, CisnienieOdn);
        WrStr("Ci˜nienie odniesienia", R.right+30, R.top, MAGENTA, MAGENTA);
        MoveRect(R, 0, 2*DY);
        WstawInpLine( hDlg, R.left, R.top,  12, CzyDobraOrbita, WHITE, GREEN, OrbitaL );
        WrStr("Promieä orbity w milach", R.right+30, R.top, MAGENTA, MAGENTA);
        MoveRect(R, 0, DY);
        WstawInpLine( hDlg, R.left, R.top, 12, CzyDobryPromien, WHITE, BLUE, PromienL );
        WrStr("Kierunek promienia w stopniach", R.right+30, R.top, MAGENTA, MAGENTA);
      ELSE
        MoveRect(R, 0, 3*DY);
      END;
      MoveRect(R, 0, 2*DY);
      WstawButton( hDlg, R, "", -1, ShortCuts.kbAltG, GlowOdbP, GlowOdb );
      WrStr( "Gˆ¢wny odbiornik", R.right+5, R.top+2, MAGENTA, MAGENTA );
      (* Guziki wlaczajace *)
      AssignRect(R1, 700, 500, 790, 525);
      AssignRect( R, 10000, 10000, 10000, 10000 );
(*      MoveRect(R1, 800-R1.right-10, 0);*)
      IF PI_PA.PomiarANieArchiwum THEN
        WstawButton(hDlg, R1, "POMIAR", 0, ShortCuts.kbAltP, PomiarP,
                           Pomiar);
        WstawButton(hDlg, R, "", -1, ShortCuts.kbEnter, PomiarP,
                           Pomiar);
        MoveRect(R1, 0, DY);
(*
        WstawButton(hDlg, R1, "TEST", 0, ShortCuts.kbAltT, TestUP_PROC,
                           TestUP);
*)
      ELSE
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
      WstawButton( hDlg, R1, "KONIEC", 0, ShortCuts.kbAltK, AltF4, void );
      WstawButton( hDlg, R, "", -1, ShortCuts.kbAltF4, AltF4,
                          void);
      IF NOT PI_PA.PomiarANieArchiwum THEN
        MoveRect( R1, -( R1.right-R1.left+5), 0 );
        WstawButton( hDlg, R1, "RAP KON", -1, ShortCuts.kbAltF5, RaportKoncowyP, void );
      END;
      AssignRect( R, 10, 300, 200, 500 );
      Lista.A := WstawListe( hDlg, R, FALSE );
      Sortowana( Lista.A, TRUE );
      SetNotificationProc( Lista.A, PoprawPromienA );
      MoveRect( R, R.right-R.left+10, 0 );
      Lista.B := WstawListe( hDlg, R, FALSE );
      Sortowana( Lista.B, TRUE );
      SetNotificationProc( Lista.B, PoprawPromienB );
    END AssignButt;

    PROCEDURE FillData(  );

      PROCEDURE Pr( Mrk : ARRAY OF CHAR; b : Buttons.Button );
        VAR
          Ile : INTEGER;
          ok : BOOLEAN;
        BEGIN
          GetPrivateProfileString( NazwaOblotu, Mrk, '0', s, NazwaPlikuOpisu );
          StringToInt( s, Ile, ok );
          IF NOT ok THEN
            Ile := 0;
          END;
          IF Ile > 0 THEN
            Buttons.ChangeButton( b, 'û', -1 );
          ELSE
            Buttons.ChangeButton( b, '-', -1 );
          END;
        END Pr;

      PROCEDURE Or( Mrk : ARRAY OF CHAR; b : Buttons.Button );
        BEGIN
          GetPrivateProfileString( NazwaOblotu, Mrk, '', s, NazwaPlikuOpisu );
          IF s[0] > ' ' THEN
            Buttons.ChangeButton( b, 'û', -1 );
          ELSE
            Buttons.ChangeButton( b, '-', -1 );
          END;
        END Or;

      VAR
        f, p : CARDINAL;
        a : ADDRESS;
        l : ARRAY[0..63] OF CHAR;
      BEGIN
        OpisNadajnika(NazwaUrzadz1, NazwaPlikuOpisu);
        f := NadajnikNDB.Czestotliwosc;
        TuneADF( AReceiver, f, FALSE, TRUE, FALSE );
        TuneADF( BReceiver, f, FALSE, TRUE, FALSE );
        p := 0;
        a := ADR( NazwaUrzadz1 );
        sprintf3(l, "%s(%dkHz)", a, f, p );
        Wr2fStrXY(l, 380, 20, WHITE, WHITE);
        Pr( "IloscPromieni.A", bPromien.A );
        Pr( "IloscPromieni.B", bPromien.B );
        Or( "Orbita.A", bOkrag.A );
        Or( "Orbita.B", bOkrag.B );
      END FillData;

  BEGIN (* InitLot *)
    RedrawScr := TRUE;
    AssignRect(R, 0, 0, 800, 599);
    hDlg := TworzDialog(R, "ndb-co.bmp", FALSE);
    AssignButt;
    FillData;
    InitDefault;
(*    OdnOdlP;*)
    GlowOdbP;
    RedrawScr := FALSE;
    kont := Go(hDlg);
    IF PI_PA.PomiarANieArchiwum THEN
      CisnienieOdniesienia := RealVal(CisnienieOdn);
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
      (* skasowana nazwa "oblt-ndb.ini" *)
      nad := NadajnikCH();
      IF (Procedura = pOrbita )
      THEN
        Fmt := 'Okrag.%c';
        sprintf(Tmp, Fmt, nad );   (* Kartoteka o postaci Okrag.A *)
      ELSE
        Fmt := '%03d.%c';
        sprintf2(Tmp, Fmt, Promien, nad );   (* Kartoteka o postaci 002.A *)
      END (* if *);
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
    nad  : CHAR;

    PROCEDURE ProcIdentifier
              (     Procedura : ProceduraT;
                VAR ident     : ARRAY OF CHAR );
    VAR
      a      : ADDRESS;
      Fmt    : ARRAY [0 .. 10] OF CHAR;
      Tmp    : ARRAY [0 .. 40] OF CHAR;

    BEGIN
      IF Procedura = pPromien THEN
        sprintf2( ident, "Promien.%c.%03d", nad, Promien );
      ELSE
        sprintf( ident, "Orbita.%c", nad );
      END;
    END ProcIdentifier;

    PROCEDURE Zaznacz(  );
      VAR
        ok : BOOLEAN;
        s, t : Str40;
        i, Ile : INTEGER;
        p : CARDINAL;
      BEGIN
        s := '0';
        sprintf( t, "IloscPromieni.%c", nad);
        GetPrivateProfileString( NazwaOblotu, t, '0', s, NazwaPlikuOpisu );
        StringToInt( s, Ile, ok );
        IF NOT ok THEN
          Ile := 0;
        END;
        FOR i := 0 TO Ile-1 DO
          sprintf2( t, "%c.%d", nad, i );
          GetPrivateProfileString( NazwaOblotu, t, '@@', s, NazwaPlikuOpisu );
          StringToCard( s, p, ok );
          Assert( ok );
          IF p = Promien THEN
            RETURN; (* juz zaznaczone *)
          END;
        END;
        sprintf( s, "%d", Promien );
        sprintf2( t, "%c.%d", nad, Ile );
        WritePrivateProfileString( NazwaOblotu, t, s, NazwaPlikuOpisu );
        INC( Ile );
        sprintf( s, "%d", Ile );
        sprintf( t, "IloscPromieni.%c", nad);
        WritePrivateProfileString( NazwaOblotu, t, s, NazwaPlikuOpisu );
      END Zaznacz;

  BEGIN (* Zapisz *)
    nad := NadajnikCH();
    GetTimeAndDate(t_d);
    Assert( Podzielnik = 1 );
    ProcIdentifier(Procedura, Tmp1);
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
    IF Procedura = pPromien THEN
      Zaznacz();
    END;
  END Zapisz;

BEGIN
  GlownyOdbiornik := MIN(GlownyOdbiornikT);
  OdnDlaPomBledu  := pbGPS;
  OdnDlaPomOdl    := poGPS;
  Procedura := MIN(ProceduraT);
  Nadajnik1 := MIN(NadajnikT);
  DME := FALSE;
END N_Oblot.
