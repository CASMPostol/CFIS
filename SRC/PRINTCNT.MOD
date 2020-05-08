(*.F- *)
(**********************************************************************
|  Title   : Menu sterujace drukowaniem raportu
|  Author  : M.Postol (na podstawie Pi_print )
|  System  : LOGITECH MODULA-2/86
|  History :
|
|  Copyright (C), CAS LODZ POLAND.
|  TEL: 42' 862 547, 42' 87 80 44 FAX/TEL: 42' 84 48 40
|
**********************************************************************)
(*.F+ *)

IMPLEMENTATION MODULE PrintCntroll;

  IMPORT
    GrafTypes, GrafUtil, FIO, InpLine, NumberConversion, HiLevGraf,
    StdIO, ASCII, Buttons, Dialog, ShortCuts;

  FROM CommonTypes IMPORT
    OdnDlaPomBleduT;

  FROM Print IMPORT
    (* PROCEDURE *) MaxY;

  VAR
    hDlg          : Dialog.HDLG;
    Zestaw        : CARDINAL;
    Odniesienie   : OdnDlaPomBleduT;
    OdnB          : Buttons.Button;
    CoKtoraProbka : CARDINAL;
    IleStron      : CARDINAL;
    IloscProbek   : CARDINAL;
    lPodz         : InpLine.HLINE;

  PROCEDURE CoKtoraPUp();
  VAR
    s : ARRAY [0 .. 19] OF CHAR;

  BEGIN
    NumberConversion.CardToString(CoKtoraProbka + 1, s, 1);
    IF ValidPodz(lPodz, s, FALSE)
    THEN
    (* poprawia liczbeStron *)
    END (* if ValidPodz *);
    UstawLiczbe(lPodz, CoKtoraProbka);
  END CoKtoraPUp;

  PROCEDURE CoKtoraPDn();
  VAR
    s : ARRAY [0 .. 19] OF CHAR;

  BEGIN
    IF CoKtoraProbka = 1
    THEN
      GrafUtil.InfoBeep("Nie istnieje poj©cie uˆamkowej pr¢bki!", 2, 200);
    ELSE
      NumberConversion.CardToString(CoKtoraProbka - 1, s, 1);
      IF ValidPodz(lPodz, s, FALSE)
      THEN
      (* poprawia liczbe stron *)
      END (* if ValidPodz *);
      UstawLiczbe(lPodz, CoKtoraProbka);
    END (* if CoKtoraProbka *);
  END CoKtoraPDn;

  PROCEDURE UstawStrony();
  VAR
    s : ARRAY [0 .. 9] OF CHAR;

  BEGIN
    NumberConversion.CardToString(IleStron, s, 2);
    HiLevGraf.Wr2StrXY(s, 420, 280, GrafTypes.WHITE, GrafTypes.BLUE);
  END UstawStrony;

  PROCEDURE UstawLiczbe
            (    l : InpLine.HLINE;
                 c : CARDINAL      );
  VAR
    s : ARRAY [0 .. 19] OF CHAR;

  BEGIN
    NumberConversion.CardToString(c, s, 1);
    InpLine.SetText(l, s);
  END UstawLiczbe;

  PROCEDURE OkP();

  BEGIN
    Dialog.EndDialog(TRUE);
  END OkP;

  PROCEDURE ValidPodz
            (     l         : InpLine.HLINE;
              VAR s         : ARRAY OF CHAR;
                  KillFocus : BOOLEAN       ) : BOOLEAN;
  VAR
    ok      : BOOLEAN;
    LastNum : CARDINAL;

  BEGIN
    NumberConversion.StringToCard(s, LastNum, ok);
    IF NOT ok
    THEN
      GrafUtil.InfoBeep("Wymagana jest liczba caˆkowita", 2, 200);
    END (* if *);
    IF LastNum = 0
    THEN
      ok := FALSE;
      GrafUtil.InfoBeep("Liczba musi by† wi©ksza od zera", 2, 200)
    END (* if LastNum *);
    IF ok
    THEN
      IF (CoKtoraProbka = 1) & (LastNum < 1) OR (LastNum # 1) & (MaxY() >=
         IloscProbek DIV (LastNum - 1))
      THEN
        GrafUtil.InfoBeep("Wykres si© zmie˜ci na jednej stronie", 2, 200);
        RETURN FALSE;
      END (* if *);
      CoKtoraProbka := LastNum;
      IleStron := (IloscProbek DIV CoKtoraProbka + MaxY() - 1) DIV MaxY();
      UstawStrony();
    ELSE
      RETURN FALSE;
    END (* if ok *);
    RETURN TRUE;
  END ValidPodz;

  PROCEDURE Odn;

  BEGIN
    IF Odniesienie = pbTeodolit
    THEN
      Odniesienie := pbGPS;
      Buttons.ChangeButton(OdnB, "Odn: GPS", 1);
    ELSE
      Odniesienie := pbTeodolit;
      Buttons.ChangeButton(OdnB, "Odn: Teodolit", 1);
    END (* if Odniesienie *);
  END Odn;

  PROCEDURE P1();

  BEGIN
    Zestaw := 1;
    Dialog.EndDialog(TRUE);
  END P1;

  PROCEDURE P2();

  BEGIN
    Zestaw := 2;
    Dialog.EndDialog(TRUE);
  END P2;

  PROCEDURE UstalSkalowanie
            (     dwaZestawy        : BOOLEAN;
                  dwaOdbiesienia    : BOOLEAN;
                  nazwaPliku        : ARRAY OF CHAR;
              VAR aktIleStron       : CARDINAL;
              VAR aktOdniesienie    : OdnDlaPomBleduT;
              VAR aktZestaw         : CARDINAL;
              VAR aktCoKtoraProbka  : CARDINAL        ) : BOOLEAN;
  VAR
    F    : FIO.File;
    b    : Buttons.Button;
    R    : GrafTypes.RECT;
    Druk : BOOLEAN;

  BEGIN
    F := FIO.Open(nazwaPliku);
    IloscProbek := VAL(CARDINAL, FIO.Length(F) DIV VAL(LONGINT, 2));
    FIO.Close(F);
    (* CoKtoraProbka := 1; IleStron := (IloscProbek DIV CoKtoraProbka +
       MaxY()-1 ) DIV MaxY(); *)
    IF IloscProbek > MaxY()
    THEN
      IleStron := 2;
      CoKtoraProbka := ( IloscProbek + MaxY()* IleStron - 1) DIV
                       ( MaxY() * IleStron );
    ELSE
      IleStron := 1;
      CoKtoraProbka := 1;
    END (* if IloscProbek *);
    R.left := 300;
    R.top := 200;
    R.right := 500;
    R.bottom := 400;
    hDlg := Dialog.TworzDialog(R, "Print.dib", TRUE);
    R.left := 85;
    R.right := 105;
    R.top := 65;
    R.bottom := 85;
    Dialog.WstawButton(hDlg, R, CHR(30), 1, ShortCuts.kbUp, CoKtoraPUp, b);
    GrafTypes.MoveRect(R, 0, 25);
    Dialog.WstawButton(hDlg, R, CHR(31), 1, ShortCuts.kbDown, CoKtoraPDn, b);
    R.left := 20;
    R.top := 114;
    R.right := 95 + 85;
    R.bottom := 139;
    Odniesienie := pbGPS;
    IF dwaOdbiesienia THEN
      Dialog.WstawButton(hDlg, R, "Odn: GPS", 1, ShortCuts.kbAltD, Odn, OdnB);
    END;
    IF dwaZestawy
    THEN
      R.left := 20;
      R.top := 140;
      R.right := 95;
      R.bottom := 165;
      Dialog.WstawButton(hDlg, R, "Zestaw1", 6, ShortCuts.kbAlt1, P1, b);
      GrafTypes.MoveRect(R, 85, 0);
      Dialog.WstawButton(hDlg, R, "Zestaw2", 6, ShortCuts.kbAlt2, P2, b);
      R.left := 20;
      R.top := 165;
      R.right := 95 + 85;
      R.bottom := 190;
      Dialog.WstawButton(hDlg, R, "Wr¢†", 0, ShortCuts.kbAltW, Dialog.AltF4, b)
      ;
      GrafTypes.MoveRect(R, 10000, 10000);
    ELSE
      R.left := 20;
      R.top := 165;
      R.right := 95 + 85;
      R.bottom := 190;
      Dialog.WstawButton(hDlg, R, "Wr¢†", 0, ShortCuts.kbAltW, Dialog.AltF4, b)
      ;
      GrafTypes.MoveRect(R, 0, -30);
      Dialog.WstawButton(hDlg, R, "Ok", 0, ShortCuts.kbAltO, OkP, b);
      GrafTypes.AssignRect( R, 10000, 10000, 10000, 10000 );
      Dialog.WstawButton(hDlg, R, "", -1, ShortCuts.kbEnter, OkP, b);
    END (* if DwaZestawy *);
    (* b := Dialog.WstawButton( hDlg, R, "", 1, ShortCuts.kbEnter, OkP ); *)
    (* b := Dialog.WstawButton( hDlg, R, "", 1, ShortCuts.kbEsc, CancelP );*)
    Dialog.WstawInpLine(hDlg, 17, 75, 5, ValidPodz, GrafTypes.WHITE,
                        GrafTypes.BLUE, lPodz);
    UstawLiczbe(lPodz, CoKtoraProbka);
    UstawStrony();
    Druk := Dialog.Go(hDlg);
    Dialog.UsunDialog(hDlg);
    aktIleStron := IleStron;
    aktOdniesienie := Odniesienie;
    aktZestaw := Zestaw;
    aktCoKtoraProbka := CoKtoraProbka;
    RETURN Druk;
  END UstalSkalowanie;

END PrintCntroll.
