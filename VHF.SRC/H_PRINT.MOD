(*.F- *)
(**********************************************************************
|  Title   : VHF wykonywanie raportow
|  Author  : M.Morawski
|  System  : LOGITECH MODULA-2/86
|  History :
|   08-12-96: M.Postol
|     bardzo duzo zmian
|
|    31-12-97: TOMEK
|      zmieniono wykresy EPE na GDOP
|
|  Copyright (C), CAS LODZ POLAND.
|  TEL: 42' 862 547, 42' 87 80 44 FAX/TEL: 42' 84 48 40
|
**********************************************************************)
(*.F+ *)

IMPLEMENTATION MODULE H_Print;

  IMPORT
    DrawEpson, SYSTEM, StdIO, PiszEventy, H_Files, Files;

  FROM H_CommonTypes IMPORT
    ProceduraT;

  FROM H_results IMPORT
    anRes;

  FROM EventsMng IMPORT
    EventKind, RodzUrzadzenia;

  FROM CommonTypes IMPORT
    SignalDsc, Str99, OdnDlaPomBleduT, OdnDlaPomOdlT, NadajnikT,
    GetTranName, Com_Aud_flg, Str40;

  FROM SpecConv IMPORT
    ToStringProcT, Int2Str, Card500Str, Ang100Str36;

  FROM Strings IMPORT
    Concat, Insert, Length;

  FROM PrintCntroll IMPORT
    UstalSkalowanie;

  FROM SYSTEM IMPORT
    WORD, ADDRESS, ADR;

  FROM Print IMPORT
    (* CONST *) StyleSep, PASEK, SKALA_X, SKALA_X_90, SKALA_Y_90,
    (* TYPE *) Desc,
    (* VAR *) PolozenieNapisu, PrnX, PrnY,
    (* PROCEDURE *) MaxY, WrPrnLn, InitA, Point, Opis, CloseAll, InitAll,
                    ZnacznikiOdleglosci, EvProc, InitB;

  CONST
    Pomiar         = FALSE;
    DwaOdniesienia = FALSE;
(*
    NagTab         =
  "   Odbiornik                                      ³glowny  ³";
*)

  TYPE
    Descs =
      ARRAY [0 .. 1] OF Desc;
    Str80 =
      ARRAY [0 .. 80] OF CHAR;

  VAR
    header     : Str99;
    NazwaPliku : ARRAY [0 .. 30] OF CHAR;

  PROCEDURE PromienANieOrbita() : BOOLEAN;

  BEGIN
    RETURN anRes.procedure = pPromien;
  END PromienANieOrbita;

  PROCEDURE MakeHeader
            ( VAR str : ARRAY OF CHAR );
  VAR
    k   : CARDINAL;
    l   : CARDINAL;
    Urz : Str40;
    a   : ADDRESS;
  BEGIN
    a := ADR( Urz );
    WITH anRes DO
      GetTranName( Urz, anRes.nadajnik );
      IF PromienANieOrbita()
      THEN
        StdIO.sprintf3(str,
                       " VHF promien %dø %s; Pomiar wyk. o godz. %d:%02d dn. %d.%02d.%d"
                       , promienLubOrbita, a, data);
      ELSE
        k := CARDINAL(promienLubOrbita) DIV 500;
        l := CARDINAL(promienLubOrbita) MOD 500 DIV 5;
        StdIO.sprintf4(str,
                       " VHF orbita %d.%02dNM %s; Pomiar wyk. o godz. %d:%02d dn. %d.%02d.%d"
                       , k, l, a, data);
      END (* if PromienANieOrbita *);
      Insert(nazwa, str, 0);
    END (* with D_results.anRes *);
  END MakeHeader;

  PROCEDURE OpisPomiaru();

    PROCEDURE WrSignalDesc
              (    pocz : WORD;
                   kon  : WORD;
                   d1   : SignalDsc ) : BOOLEAN;

    PROCEDURE IntFrac
              (     pocz : WORD;
                    kon  : WORD;
                VAR str  : ARRAY OF CHAR );

    TYPE
      Str9 =
        ARRAY [0 .. 9] OF CHAR;
    VAR
      s1 : Str9;
      s2 : Str9;
      a1 : SYSTEM.ADDRESS;
      a2 : SYSTEM.ADDRESS;

    BEGIN
      a1 := SYSTEM.ADR(s1);
      a2 := SYSTEM.ADR(s2);
      IF PromienANieOrbita()
      THEN
        Card500Str(CARDINAL(pocz), s1, 5);
        Card500Str(CARDINAL(kon), s2, 5);
        StdIO.sprintf2(str, "Odcinek od %sNM do %sNM ³", a1, a2);
      ELSE
        Ang100Str36(INTEGER(pocz), s1, 6);
        Ang100Str36(INTEGER(kon), s2, 6);
        StdIO.sprintf2(str, " Odcinek od %sø do %sø ³", a1, a2);
      END (* if PromienANieOrbita *);
    END IntFrac;


    TYPE
      Str80 =
        ARRAY [0 .. 80] OF CHAR;
      Str30 =
        ARRAY [0 .. 30] OF CHAR;
    VAR
      str : Str80;
      s   : Str30;

    BEGIN
(*
      IF NOT WrPrnLn(0, NagTab)
      THEN
        RETURN FALSE;
      END (* if *);
*)
      IF NOT WrPrnLn(0, PASEK)
      THEN
        RETURN FALSE;
      END (* if *);
      IntFrac(pocz, kon, str);
      Insert("Sila sygnalu Min ³ ", str, 0);
      Int2Str(d1.val, s, 4);
      Concat(str, s, str);
      Concat(str, 'uV', str);
      IF NOT WrPrnLn(0, str)
      THEN
        RETURN FALSE;
      END (* if *);
      IF NOT WrPrnLn(0, PASEK)
      THEN
        RETURN FALSE;
      END (* if *);
      RETURN TRUE;
    END WrSignalDesc;
  VAR
    o_nr    : CARDINAL;
    converP : ToStringProcT;

  BEGIN (* OpisPomiaru *)
    PrnX := 0;
    PrnY := 0;
    IF NOT WrPrnLn(0, header)
    THEN
      RETURN;
    END (* if *);
    IF PromienANieOrbita()
    THEN
      converP := ToStringProcT(Card500Str);
    ELSE
      converP := Ang100Str36;
    END (* if PromienANieOrbita *);
    FOR o_nr := 0 TO anRes.a_IleOd - 1 DO
      WITH anRes.analiza[o_nr] DO
        IF NOT WrSignalDesc(pocz, kon, SSmin)
        THEN
          RETURN;
        END (* if *);
      END (* with D_results.anRes.analiza *);
    END (* for o_nr *);
  END OpisPomiaru;

  PROCEDURE Print() : BOOLEAN;
  VAR
    d      : Descs;
(*
    Start,
    Odstep,
*)
    s,
    idx    : INTEGER;
  VAR
    i,
    j             : INTEGER;
    Num           : ARRAY [0 .. 69] OF CHAR;
    IleStron      : CARDINAL;
    Odniesienie   : OdnDlaPomBleduT;
    Zestaw        : CARDINAL;
    CoKtoraProbka : CARDINAL;

  BEGIN
    IF NOT UstalSkalowanie(FALSE, DwaOdniesienia, NazwaPliku, IleStron,
                           Odniesienie, Zestaw, CoKtoraProbka)
    THEN
      RETURN FALSE;
    END (* if *);
    IF PromienANieOrbita()
    THEN
      InitAll(d, 1 * 500, Pomiar, CoKtoraProbka);
    ELSE
      InitAll(d, 10 * 100, Pomiar, CoKtoraProbka);
    END (* if PromienANieOrbita *);
    H_Files.GetSigFileName(Num);
    InitA(d[0],
           Num,
           "AGC",
           DrawEpson.MaxX() * 5 DIV 6,
           DrawEpson.MaxX() DIV 3,
           1, 5000,
           TRUE);
    InitB( d[1],
           "Audio",
           TRUE,
           0,
           DrawEpson.MaxX() DIV 16,
           Com_Aud_flg );
    DrawEpson.SetFont(DrawEpson.ft8x8);
    DrawEpson.SetTextMode(DrawEpson.mtOr);
    FOR s := 0 TO IleStron - 1 DO
      DrawEpson.Open;
      DrawEpson.Mnoznik(SKALA_X, 1);
      DrawEpson.SetTextMode(DrawEpson.mtSet);
      FOR j := 0 TO HIGH(d) DO
        IF d[j].Uzywane THEN
          Opis(d[j], NOT ODD(j));
        END;
      END (* for j *);
      DrawEpson.Line(0, 0, 0, MaxY() - 1, StyleSep);
      (* eventy *)
      i := MaxY() * CoKtoraProbka;
      PolozenieNapisu := DrawEpson.MaxX() * 9 DIV 10;
      DrawEpson.SetDir(DrawEpson.t_90);
      DrawEpson.Mnoznik(SKALA_X_90, SKALA_Y_90);
      PiszEventy.EnumEv(U_COM, PromienANieOrbita(), s * i, (s + 1) * i - 1,
                        EvProc, s);
      DrawEpson.Mnoznik(SKALA_X, 1);
      DrawEpson.SetDir(DrawEpson.t_0);
      DrawEpson.SetTextMode(DrawEpson.mtSet);
      i := s + 1;
      StdIO.sprintf2(Num, "Strona %d/%d", i, IleStron);
      DrawEpson.DrawText(Num, 0, MaxY());
      DrawEpson.DrawText(header, DrawEpson.MaxX() - SKALA_X * 8 * Length(header
                         ) - 4, MaxY());
      DrawEpson.SetTextMode(DrawEpson.mtXor);
      FOR idx := 0 TO MaxY() - 1 DO
        FOR j := 0 TO HIGH(d) DO
          Point(d[j], idx);
        END (* for j *);
      END (* for idx *);
      (* znaczniki odleglosci *)
      ZnacznikiOdleglosci(poGPS, pbGPS, Pomiar, s, PromienANieOrbita(), TRUE, 0);
      IF NOT DrawEpson.Out(DrawEpson.WrProc)
      THEN
        DrawEpson.Close;
        CloseAll(d);
        RETURN FALSE;
      ELSE
        DrawEpson.Close;
      END (* if *);
    END (* for s *);
    CloseAll(d);
    RETURN TRUE;
  END Print;

  PROCEDURE MakeRaport;

  BEGIN
    Files.GetCommSigFName(Files.CS_GPS_GDOP, Pomiar, NazwaPliku);
    MakeHeader(header);
    IF NOT Print()
    THEN
      RETURN;
    END (* if *);
    OpisPomiaru;
    PiszEventy.PiszNaDrukarce(U_COM, PromienANieOrbita(),
                              PiszEventy.TypyEventow {PoczatekPomiaru..
                              ZnacznikT});
  END MakeRaport;

END H_Print.
