(*.F- *)
(**********************************************************************
|  Title   : Drukowanie opisow znacznikow
|  Author  : M.Morawski
|  System  : LOGITECH MODULA-2/86
|  History :
|     05-06-96: M.Postol
|       zle drukowany parametr znacznika (katy zamiast mil)
|     13-07-96: M.Postol
|       powazne bledy w proc Znacznik
|     09-19-96 00:13am MM: Uwzgledniono Vora trasowego
|     12-08-96:M.postol
|       drobne zmiany dla COM
|     01-26-97 03:38pm: MM:
|       dodana obsluga kata w opisie LOC i GS
|     03-10-97 09:30pm: MM
|       Blad typu `nowoczesny edytor w znacznikach NDB'
|     3/22/97 11:18AM: MM
|       Zmieniony "poczatek strefy" na "koniec strefy" w opisie eventow
|     29-03-97: M.Postol
|       blad przy wipisywaniu znacznikow NDB i VHF, blad przy wypisywaniu 
|       wysokosci
|     22-05-97: M.Postol
|       numeracja znacznikow na ekranie od 1
|     15-06-96: M.Postol
|       dostawilem ")" do znacznikow dla VOR
|     Rel. 3.0: MPostol
|       Zmaina defincij EventType w polu PoczatekPomiaru - wprowadzilem 
|       czs wg defincji ogolenj
|     Rel. 3.14: MPostol
|       Kosmetyczne zmiany - wywqlilem niepotrzbne nowa linie
|
|  Copyright (C), CAS LODZ POLAND.
|  TEL: 42' 862 547, 42' 87 80 44 FAX/TEL: 42' 84 48 40
|
**********************************************************************)
(*.F+ *)

IMPLEMENTATION MODULE PiszEventy;

  IMPORT
    GrafTypes, HiLevGraf, Strings;

  FROM DisResUtilities IMPORT
     ScreenMaxLen;

  FROM EventsMng IMPORT
    Events, EventType, EventKind, RodzUrzadzenia, EventsDsc, LoadDistEvents;

  FROM SYSTEM IMPORT
    ADDRESS, SIZE, ADR, BYTE;

  FROM Storage IMPORT
    ALLOCATE, DEALLOCATE;

  FROM FIO IMPORT
    File, Open, Close, Read, Length;

  FROM StdIO IMPORT
    sprintf, sprintf2, sprintf3, sprintf4, sprintf5;

  FROM ASCII IMPORT
    cr, lf, nul, ff;

  FROM DrawEpson IMPORT
    WrProc;

  FROM GrafTypes IMPORT
    RECT, AssignRect;

  FROM RTSMain IMPORT
    Terminate, Status;

  FROM CommonTypes IMPORT
    SigNilVal, GlownyOdbiornikT;

  FROM SpecConv IMPORT
    Int100Str, Card500Str, Int2Str, Ang100Str36, Int10Str;

  FROM Print IMPORT 
    PASEK;
  
  VAR
    PoczatekStrony : CARDINAL;
    EvPtr          : POINTER TO EventsDsc;

  PROCEDURE Decode
            ( VAR t                 : EventType;
                  CoBadamy          : RodzUrzadzenia;
                  PromienANieOrbita : BOOLEAN;
              VAR s                 : ARRAY OF CHAR  );

  TYPE
    strT =
      ARRAY [0 .. 22] OF CHAR;
  VAR
    addr   : ADDRESS;
    a_o    : ADDRESS;
    str22  : strT;

    PROCEDURE Znacznik
              (    jaki : ARRAY OF CHAR );
    VAR
      j_a : ADDRESS;
      j,
      s1,
      s2,
      s3  : ARRAY [0 .. 19] OF CHAR;
      a1,
      a2,
      a3  : ADDRESS;

    BEGIN
      Strings.Assign(jaki, j);
      j_a := ADR(j);
      a1 := ADR(s1);
      a2 := ADR(s2);
      a3 := ADR(s3);
      CASE CoBadamy OF
        U_DME :
          Int2Str(t.D_SilaSyg, s1, 5);
          IF PromienANieOrbita
          THEN
            sprintf3(s, "Znacznik %s w odl. %sNM (siˆa syg.=%sdBm)", j_a, a_o, a1
            );
          ELSE
            sprintf3(s, "Znacznik %s na prom. %sø (siˆa syg.=%sdBm)", j_a, a_o, a1
            );
          END (* if PromienANieOrbita *);
        |
        U_LOC, U_GS :
          Int10Str(t.L_dev, s1, 7);
          Int10Str(t.L_blad, s2, 7);
          Int100Str(t.L_kat, s3, 6);
          IF PromienANieOrbita
          THEN
            sprintf5(s,
                     "Znacznik %s w odl. %sNM, dew=%suA, bˆ¥d=%suA, k¥t=%sø",
                     j_a,
                     a_o,
                     a1,
                     a2,
                     a3);
          ELSE
            sprintf4(s,
                     "Znacznik %s na prom. %sø dew=%suA, bˆ¥d=%suA",
                     j_a,
                     a_o,
                     a1,
                     a2);
          END;
        |
        U_NDB, U_COM : (* jest zlozenie, ze C_* == N_* *)
          Int2Str(t.C_SilaSyg, s1, 7);
          Int100Str(t.C_kat, s2, 4);
          IF PromienANieOrbita
          THEN
            sprintf4(s,
                     "Znacznik %s w odl. %sNM (siˆa syg.=%suV, k¥t=%sø)",
                     j_a,
                     a_o,
                     a1,
                     a2);
          ELSE
            sprintf4(s,
                     "Znacznik %s na prom. %sø (siˆa syg.=%suV, k¥t=%sø)",
                     j_a,
                     a_o,
                     a1,
                     a2);
          END;
        |
        U_TRS:
          Int100Str(t.T_Par[goA].brG, s1, 7);
          Int100Str(t.T_Par[goA].blad, s2, 7);
          IF PromienANieOrbita
          THEN
            sprintf4(s, "Znacznik %s w odl. %sNM (n1=%sø, b1=%sø, n2 =",
                     j_a, a_o, a1, a2);
          ELSE
            sprintf4(s, "Znacznik %s na prom. %sø (n1=%s, b1=%s, n2 =",
                     j_a, a_o, a1, a2);
          END;
          Int100Str(t.T_Par[goB].brG, s1, 7);
          Strings.Insert( s1, s, 0FFFH );
          Strings.Insert( "ø, b2=", s, 0FFFH );
          Int100Str(t.T_Par[goB].blad, s2, 7);
          Strings.Insert( s2, s, 0FFFH );
          Strings.Insert( "ø)", s, 0FFFH );
      ELSE
      END (* case CoBadamy *);
    END Znacznik;

  BEGIN
    a_o  := ADR( str22 );
    addr := ADR( t.DatICas );
    IF PromienANieOrbita
    THEN
      Card500Str(CARDINAL(t.XRef), str22, 5);
    ELSE
      CASE CoBadamy OF
      | U_DME, U_TRS, U_COM, U_NDB:
        Ang100Str36(INTEGER(t.XRef), str22, 7);
      | U_LOC, U_GS:
        Int100Str(INTEGER(t.XRef), str22, 7);
      END;
    END (* if PromienANieOrbita *);
    CASE t.EventID OF
      PoczatekPomiaru :
        addr := ADR(t.DatICas);
        sprintf(s, 
         "Rejestracja rozpocz©ta dnia %02d.%02d.%04d o godzinie %2d:%02d:%02d", 
         addr^);
      |
      StartPomiaru :
        addr := ADR(t.Wysokosc);
        IF t.Wysokosc = SigNilVal THEN
          Strings.ConstAssign("Pocz¥tek rejestracji na wysoko˜ci **** [ft]", s);
        ELSE
          sprintf(s, "Pocz¥tek rejestracji na wysoko˜ci %d [ft]", addr^);
        END;
      |
      StopPomiaru :
        sprintf(s, "Koniec rejestracji", addr^);
      |
      PolVLewo :
        sprintf(s, "Polaryzacja pionowa (w lewo)", addr^);
      |
      PolVZero :
        sprintf(s, "Polaryzacja pionowa (poziomo)", addr^);
      |
      PolVPrawo :
        sprintf(s, "Polaryzacja pionowa (w prawo)", addr^);
      |
      ZnacznikP :
        Znacznik("pilota");
      |
      ZnacznikK :
        Znacznik("konsoli");
      |
      ZnacznikT :
        Znacznik("teodolitu");
      |
      Strefa:
        sprintf(s, "koniec strefy (odlegˆo˜† = %s [NM])", a_o);
      |
      BrakZnacznika :
        sprintf(s, "wystapiˆ jaki˜ bˆ¥d w procedurze obsˆugi zdarzeä", addr^);
    ELSE
      sprintf(s, "Inny", addr^);
    END (* case t.EventID *);
  END Decode;

  PROCEDURE IleEventow() : INTEGER;

  BEGIN
    RETURN EvPtr^.EventIDX;
  END IleEventow;

  PROCEDURE TworzEventy
            (    zestaw : RodzUrzadzenia );
  VAR
    F : File;
    s : ARRAY [0 .. 30] OF CHAR;
    z : CARDINAL;

  BEGIN
    EvPtr := ADR(Events[zestaw = U_DME]);
  END TworzEventy;

  PROCEDURE PiszNaEkranie
            (    zestaw            : RodzUrzadzenia;
                 PromienANieOrbita : BOOLEAN;
                 t                 : TypyEventow;
                 od                : INTEGER        );
  VAR
    i,
    j         : INTEGER;
    s,
    ds        : ARRAY [0 .. ScreenMaxLen-1] OF CHAR;
    ads       : ADDRESS;
    Prostokat : RECT;

    PROCEDURE WrStr
              (    str : ARRAY OF CHAR;
                   At  : INTEGER;
                   fc  : BYTE          );
    VAR
      bc    : BYTE;
      Pasek : RECT;
      l     : INTEGER;

    BEGIN
      IF ODD(At)
      THEN
        bc := BYTE(GrafTypes.GREEN);
      ELSE
        bc := BYTE(GrafTypes.BLUE);
      END (* if ODD *);
      AssignRect(Pasek, 0, Prostokat.top + 16 * At, 799, Prostokat.top + 16 *
                 At + 15);
      HiLevGraf.FillRect(Pasek, bc);
      l := Strings.Length(str);
      l := 400 - 8 * (l DIV 2);   (* centrowanie *)
      HiLevGraf.WrStr(str, l, Pasek.top, fc, fc);
    END WrStr;
  VAR
    numer: INTEGER;
  BEGIN
    ads := ADR(ds);
    Prostokat.left := 0;
    Prostokat.right := 799;
    Prostokat.top := 56;
    Prostokat.bottom := 599;
    HiLevGraf.FillRect(Prostokat, GrafTypes.BLUE);
    WrStr("Wykaz zdarzen, ktore wystapily w czasie pomiaru", 0,
          GrafTypes.YELLOW);
    i := od;
    FOR j := od TO min(EvPtr^.EventIDX - 1, od + STRONA - 1) DO
      IF EvPtr^.events[j].EventID IN t
      THEN
        Decode(EvPtr^.events[j], zestaw, PromienANieOrbita, ds);
        numer := i+1;
        sprintf2(s, "%2d: %s", numer, ads);
        WrStr(s, i - od, GrafTypes.WHITE);
        INC(i);
      END (* if EvPtr *);
    END (* for j *);
  END PiszNaEkranie;

  PROCEDURE min
            (    a,
                 b : INTEGER ) : INTEGER;

  BEGIN
    IF (a < b)
    THEN
      RETURN a;
    ELSE
      RETURN b;
    END (* if *);
  END min;

  PROCEDURE PiszNaDrukarce
            (    zestaw            : RodzUrzadzenia;
                 PromienANieOrbita : BOOLEAN;
                 t                 : TypyEventow    );
  VAR
    s : ARRAY [0 .. ScreenMaxLen-1 ] OF CHAR;
    i,
    j : CARDINAL;
    z : BOOLEAN;

  BEGIN
    WrStr(0, "");   (* tu powinno byc ustawienie trybu pracy drukarki *)
    TworzEventy(zestaw);
    WrStrLn(0,PASEK);
    WrStrLn(0, "Lista zdarzeä");
    i := 1;
    FOR j := 1 TO EvPtr^.EventIDX DO
      IF EvPtr^.events[j - 1].EventID IN t
      THEN
        z := TRUE;
        sprintf(s, "%2d: ", i);
        WrStr(0, s);
        Decode(EvPtr^.events[j - 1], zestaw, PromienANieOrbita, s);
        WrStrLn(2, s);
        IF i MOD 50 = 0
        THEN
          WrP(ff);
          z := FALSE;
        END (* if i *);
        INC(i);
      END (* if EvPtr *);
    END (* for j *);
    IF z
    THEN
      WrP(ff);
    END (* if z *);
  END PiszNaDrukarce;

  PROCEDURE EnumEv
            (    zestaw            : RodzUrzadzenia;
                 PromienANieOrbita : BOOLEAN;
                 Od,
                 Do                : CARDINAL;
                 proc              : EnumEvT;
                 strona            : INTEGER        );
  VAR
    s : ARRAY [0 .. 60] OF CHAR;
    i,
    j : CARDINAL;

  BEGIN
    TworzEventy(zestaw);
    i := 1;
    FOR j := 1 TO EvPtr^.EventIDX DO
      IF (* EvPtr^[j].EventID IN t*) TRUE
      THEN
        IF (EvPtr^.events[j - 1].atSample >= Od) &
           (EvPtr^.events[j - 1].atSample <= Do)
        THEN
          Decode(EvPtr^.events[j - 1], zestaw, PromienANieOrbita, s);
          proc(EvPtr^.events[j - 1].atSample, i, s, strona);
        END (* if *);
      END (* if TRUE *);
      INC( i );
    END (* for j *);
  END EnumEv;

  PROCEDURE WrStrLn
            (    Offset : CARDINAL;
                 s      : ARRAY OF CHAR );

  BEGIN
    WrStr(Offset, s);
    WrLn;
  END WrStrLn;

  PROCEDURE WrStr
            (    Offset : CARDINAL;
                 s      : ARRAY OF CHAR );
  VAR
    i : CARDINAL;

  BEGIN
    FOR i := 1 TO Offset DO
      WrP(' ');
    END (* for i *);
    i := 0;
    WHILE (i <= HIGH(s)) & (s[i] # nul) DO
      WrP(s[i]);
      INC(i);
    END (* while *);
  END WrStr;

  PROCEDURE WrLn();

  BEGIN
    WrP(cr);
    WrP(lf);
  END WrLn;

  PROCEDURE WrP
            (    c : CHAR );

  BEGIN
    IF WrProc(c)
    THEN
    END (* if WrProc *);
  END WrP;

BEGIN
  PoczatekStrony := 0;
END PiszEventy.
