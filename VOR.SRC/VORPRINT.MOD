(*.F- *)
(**********************************************************************
|  Title   : VOR wykonywanie raportow
|  Author  : M.Morawski
|  System  : LOGITECH MODULA-2/86
|  History :
|    05-06-96: M.Postol
|      liczne bledy
|    20-07-96:M.Postol
|      zmiana definicji Print
|    29-07-96:M.Postol
|      bardzo duzo zmian
|    20-09-96: M.Postol
|      wypisywanie tablic z flagami i z SYG<5uV
|    04-09-97: M.Postol
|      zmieniono skale dla AGC
|    31-12-97: TOMEK
|      zmieniono wykresy EPE na GDOP
|  Copyright (C), CAS LODZ POLAND.
|  TEL: 42' 862 547, 42' 87 80 44 FAX/TEL: 42' 84 48 40
|
**********************************************************************)
(*.F+ *)

IMPLEMENTATION MODULE VORPrint;

  FROM V_results IMPORT
    Signals, anRes, Parametr;

  FROM EventsMng IMPORT
    EventKind, RodzUrzadzenia;

  FROM CommonTypes IMPORT
    (* TYPE *) SignalDsc, GlownyOdbiornikT, OdnDlaPomBleduT, Str99,
    (* CONST *) NAVA_flg, NAVB_flg, Com_Aud_flg, NAVA_Aud_flg, NAVB_Aud_flg,
    (* PROCEDURE *) GetRecName, GetTranName;

  FROM SpecConv IMPORT
    ToStringProcT, Int100Str, Int2Str, Int10Str, Ang100Str36, Card500Str;

  FROM Strings IMPORT
    Insert, Concat;

  FROM PrintCntroll IMPORT
    UstalSkalowanie;

  IMPORT
    DrawEpson, Strings, SYSTEM, ASCII, StdIO, PiszEventy, V_Files, SpecConv,
    VORO_avrage, Files, V_CommonTypes;

  FROM Print IMPORT
    (* CONST *) StyleSep, PASEK, SKALA_X, SKALA_X_90, SKALA_Y_90,
    (* TYPE *) Desc,
    (* VAR *) PolozenieNapisu, PrnX, PrnY,
    (* PROCEDURE *) MaxY, Wr, WrPrn, WrLn, WrPrnLn, InitA, InitB, Point, Opis,
                    CloseAll, InitAll, ZnacznikiOdleglosci, EvProc,
                    WrF_TablicaOdci;

  CONST
    Pomiar   = FALSE;
    Agc_Max  = 5000;
    
  TYPE
    Descs =
      ARRAY [0 .. 8] OF Desc;
    Str80 =
      ARRAY [0 .. 80] OF CHAR;

  VAR
    Zestaw      : CARDINAL;
    Odniesienie : OdnDlaPomBleduT;
    header      : Str99;
    NazwaPliku  : ARRAY [0 .. 30] OF CHAR;
    gOdb        : GlownyOdbiornikT;
    zOdb        : GlownyOdbiornikT;
    NAVG_flg    : CARDINAL;
    NAVZ_flg    : CARDINAL;
    NAVG_AFlg   : CARDINAL;
    NAVZ_AFlg   : CARDINAL;

  PROCEDURE PromienANieOrbita() : BOOLEAN;

  BEGIN
    RETURN anRes.procedure >= V_CommonTypes.pPromienBlad;
  END PromienANieOrbita;

  PROCEDURE MakeHeader
            ( VAR str : ARRAY OF CHAR );
  VAR
    k      : CARDINAL;
    l      : CARDINAL;
    odbN   : ARRAY [ 0 .. 15  ] OF CHAR;
    tranN  : ARRAY [ 0 .. 15 ] OF CHAR;
    tmpOdb : SYSTEM.ADDRESS;

  BEGIN (* MakeHeader *)
    WITH anRes DO
      GetTranName(tranN, Nadajnik1);
      GetRecName(odbN, gOdb);
      Concat(odbN, ' ', odbN);
      Concat(odbN, tranN, odbN);
      tmpOdb := SYSTEM.ADR(odbN);
      IF PromienANieOrbita()
      THEN
        StdIO.sprintf3(str,
                       " VOR promieä %dø OdbG: %s; Pomiar wyk. o godz. %d:%02d dn. %d.%02d.%d",
                       PromienLubOrbita, tmpOdb, data);
      ELSE
        k := CARDINAL(PromienLubOrbita) DIV 500;
        l := CARDINAL(PromienLubOrbita) MOD 500 DIV 5;
        StdIO.sprintf4(str,
                       " VOR orbita %d.%02dNM OdbG: %s; Pomiar wyk. o godz. %d:%02d dn. %d.%02d.%d",
                       k, l, tmpOdb, data);
      END (* if PromienANieOrbita *);
      Insert(Nazwa, str, 0);
    END (* with D_results.anRes *);
  END MakeHeader;

  PROCEDURE OpisPomiaru();
  VAR
    str,
    co    : ARRAY [0 .. 100] OF CHAR;
    param : Parametr;
    s     : Signals;
    go    : GlownyOdbiornikT;
    opb   : OdnDlaPomBleduT;
    i     : CARDINAL;

    PROCEDURE Wr4Signals
              ( VAR str : ARRAY OF CHAR;
                    d1  : INTEGER;
                    d2  : INTEGER;
                    d3  : INTEGER;
                    d4  : INTEGER       ) : BOOLEAN;
    VAR
      s : ARRAY [0 .. 30] OF CHAR;

    BEGIN
      IF NOT WrPrn(0, str)
      THEN
        RETURN FALSE;
      END (* if *);
      IF NOT WrPrn(15, '³')
      THEN
        RETURN FALSE;
      END (* if *);
      SpecConv.Int100Str(d1, s, 7);
      IF NOT WrPrn(0, s)
      THEN
        RETURN FALSE;
      END (* if *);
      IF NOT WrPrn(30, '³')
      THEN
        RETURN FALSE;
      END (* if *);
      SpecConv.Int100Str(d2, s, 7);
      IF NOT WrPrn(0, s)
      THEN
        RETURN FALSE;
      END (* if *);
      IF NOT WrPrn(45, '³')
      THEN
        RETURN FALSE;
      END (* if *);
      SpecConv.Int100Str(d3, s, 7);
      IF NOT WrPrn(0, s)
      THEN
        RETURN FALSE;
      END (* if *);
      IF NOT WrPrn(60, '³')
      THEN
        RETURN FALSE;
      END (* if *);
      SpecConv.Int100Str(d4, s, 7);
      IF NOT WrPrn(0, s)
      THEN
        RETURN FALSE;
      END (* if *);
      RETURN TRUE;
    END Wr4Signals;

    PROCEDURE WrSignalDesc
              (     At          : CARDINAL;
                VAR str         : ARRAY OF CHAR;
                VAR d           : SignalDsc;
                    ConvertTStr : ToStringProcT ) : BOOLEAN;
    VAR
      s : ARRAY [0 .. 30] OF CHAR;

    BEGIN
      IF At < 30
      THEN
        IF NOT WrPrn(0, str)
        THEN
          RETURN FALSE;
        END (* if *);
        IF NOT WrPrn(20, '³')
        THEN
          RETURN FALSE;
        END (* if *);
      ELSE
        IF NOT WrPrn(40, '³')
        THEN
          RETURN FALSE;
        END (* if *);
      END (* if At *);
      ConvertTStr(d.val, s, 7);
      IF NOT WrPrn(At, s)
      THEN
        RETURN FALSE;
      END (* if *);
      RETURN TRUE;
    END WrSignalDesc;

    PROCEDURE Pomiar2Str
              (     p   : Parametr;
                VAR str : ARRAY OF CHAR;
                    BladNieWart : BOOLEAN;
                    Dodac : ARRAY OF CHAR );

    BEGIN
      CASE p OF
        AV :
          IF BladNieWart THEN
            Strings.ConstAssign("Bˆ¥d ˜r.", str);
          ELSE
            Strings.ConstAssign("Wart.˜r.", str);
          END;
        |
        MP :
          IF BladNieWart THEN
            Strings.ConstAssign("Bˆ¥d max.", str);
          ELSE
            Strings.ConstAssign("Wart.max.", str);
          END;
        |
        MM :
          IF BladNieWart THEN
            Strings.ConstAssign("Bˆ¥d min.", str);
          ELSE
            Strings.ConstAssign("Wart.min.", str);
          END;
        |
        FAL :
          Strings.ConstAssign("Falowanie", str);
        |
        UGPlus :
          Strings.ConstAssign("Ugi©cie max", str);
        |
        UGMinus :
          Strings.ConstAssign("Ugi©cie min", str);
        |
        PolLewo :
          Strings.ConstAssign("Polaryzacja (L)", str);
        |
        PolPrawo :
          Strings.ConstAssign("Polaryzacja (P)", str);
      END (* case p *);
      Insert( Dodac, str, 0FFFH );
    END Pomiar2Str;

    PROCEDURE WriteFlgAndLowSignal
              (    converP : ToStringProcT );

    BEGIN
      WITH anRes DO
        IF NOT WrPrnLn(0, PASEK)
        THEN
          RETURN;
        END (* if *);
        IF NOT WrF_TablicaOdci("Zestawienie odcink¢w dla SYG < 5 uV", lowSigTab
                               , converP)
        THEN
          RETURN;
        END (* if *);
        IF NOT WrPrnLn(0, PASEK)
        THEN
          RETURN;
        END (* if *);
        IF NOT WrF_TablicaOdci("Zestawienie odcink¢w wyst¥pienia flagi",
                               flagTab, converP)
        THEN
          RETURN;
        END (* if *);
      END (* with anRes *);
    END WriteFlgAndLowSignal;
  VAR
    a           : SYSTEM.ADDRESS;
    ConvertTStr : ToStringProcT;

  BEGIN
    a := SYSTEM.ADR(co);
    PrnX := 0;
    PrnY := 0;
    IF NOT WrPrnLn(0, header)
    THEN
      RETURN;
    END (* if *);
    IF NOT WrPrnLn(0, "   Odbiornik        ³ gˆ¢wny            ³ zapasowy")
    THEN
      RETURN;
    END (* if *);
    IF NOT WrPrnLn(0, PASEK)
    THEN
      RETURN;
    END (* if *);
    FOR param := AV TO MM DO
      Pomiar2Str(param, co, FALSE, '');
      a := SYSTEM.ADR(co);
      FOR s := Var TO Agc DO
        CASE s OF
          Var :
            StdIO.sprintf(str, "VAR (%s)[%%]", a);
            ConvertTStr := Int10Str;
          |
          Ref :
            StdIO.sprintf(str, "REF (%s)[ ]", a);
            ConvertTStr := Int10Str;
          |
          Sub :
            StdIO.sprintf(str, "SUB (%s)[%%]", a);
            ConvertTStr := Int10Str;
          |
          Agc :
            StdIO.sprintf(str, "AGC (%s)[uV]", a);
            ConvertTStr := Int2Str;
        END (* case s *);
        FOR go := goA TO goB DO
          IF NOT WrSignalDesc(ORD(go) * 40, str, anRes.signalGen[param][s][go],
                              ConvertTStr)
          THEN
            RETURN;
          END (* if *);
        END (* for go *);
        IF NOT WrLn()
        THEN
          RETURN;
        END (* if *);
      END (* for s *);
    END (* for param *);
    IF NOT WrPrnLn(0, PASEK)
    THEN
      RETURN;
    END (* if *);
    FOR opb := pbTeodolit TO pbGPS DO
      IF opb = pbTeodolit
      THEN
        IF NOT WrPrnLn(5, "Wyniki pomiar¢w - odniesienie Teodolit")
        THEN
          RETURN;
        END (* if *);
      ELSE
        IF NOT WrPrnLn(5, "Wyniki pomiar¢w - odniesienie GPS")
        THEN
          RETURN;
        END (* if *);
      END (* if opb *);
      FOR param := AV TO PolPrawo DO
        Pomiar2Str(param, co, TRUE, '[ø]');
        FOR go := goA TO goB DO
          IF NOT WrSignalDesc(ORD(go) * 40, co, anRes.devDet[param][opb][go],
                              Int100Str)
          THEN
            RETURN;
          END (* if *);
        END (* for go *);
        IF NOT WrLn()
        THEN
          RETURN;
        END (* if *);
      END (* for param *);
    END (* for opb *);
    IF NOT PromienANieOrbita()
    THEN
      IF NOT WrPrnLn(0, PASEK)
      THEN
        RETURN;
      END (* if *);
      IF NOT WrPrnLn(5, "Rozkˆad bˆ©d¢w na orbicie")
      THEN
        RETURN;
      END (* if *);
      IF NOT WrPrnLn(0,
                     "               ³ GPS                         ³ TEODOLIT")
      THEN
        RETURN;
      END (* if *);
      IF NOT WrPrnLn(0,
                     "   Odbiornik   ³ gˆ¢wny       ³ zapasowy     ³ gˆ¢wny       ³ zapasowy     "
         )
      THEN
        RETURN;
      END (* if *);
      IF NOT WrPrnLn(0, PASEK)
      THEN
        RETURN;
      END (* if *);
      FOR i := MIN(VORO_avrage.PartIdx) TO MAX(VORO_avrage.PartIdx) DO
        StdIO.sprintf(str, "Kat %d0ø", i);
        IF NOT Wr4Signals(str, anRes.DevOrbit[pbGPS, goA, i], anRes.DevOrbit[
                          pbGPS, goB, i], anRes.DevOrbit[pbTeodolit, goA, i],
                          anRes.DevOrbit[pbTeodolit, goB, i])
        THEN
          RETURN;
        END (* if *);
        IF NOT WrLn()
        THEN
          RETURN;
        END (* if *);
      END (* for i *);
    END (* if *);
    IF NOT WrPrnLn(0, PASEK)
    THEN
      RETURN;
    END (* if *);
    IF PromienANieOrbita()
    THEN
      WriteFlgAndLowSignal(ToStringProcT(Card500Str));
    ELSE
      WriteFlgAndLowSignal(Ang100Str36);
    END (* if PromienANieOrbita *);
  END OpisPomiaru;

  PROCEDURE Print( dwaOdniesienia : BOOLEAN ) : BOOLEAN;
  VAR
    d      : Descs;
    Start,
    Odstep,
    s,
    idx    : INTEGER;
  VAR
    i,
    j             : INTEGER;
    Num           : ARRAY [0 .. 69] OF CHAR;
    IleStron      : CARDINAL;
    Zestaw        : CARDINAL;
    CoKtoraProbka : CARDINAL;

  BEGIN
    IF NOT UstalSkalowanie(TRUE,
                           dwaOdniesienia,
                           NazwaPliku,
                           IleStron,
                           Odniesienie,
                           Zestaw,
                           CoKtoraProbka)
    THEN
      RETURN FALSE;
    END (* if *);
    IF PromienANieOrbita()
    THEN
      InitAll(d, 1 * 500, Pomiar, CoKtoraProbka);
    ELSE
      InitAll(d, 10 * 100, Pomiar, CoKtoraProbka);
    END (* if PromienANieOrbita *);
    Odstep := (DrawEpson.MaxX() DIV 2) DIV 8;
    IF Zestaw = 1
    THEN
      IF Odniesienie = pbGPS
      THEN
        V_Files.GetResFileName(pbGPS, gOdb, Num);
        InitA(d[0], Num, (* Blad namiaru *) "Bˆ¥d odb G (GPS)",
              DrawEpson.MaxX() * 4 DIV 6, DrawEpson.MaxX() DIV 3, -500, +500,
              FALSE);   (* -5..+5 -> jedn 0.01 *)
        V_Files.GetResFileName(pbGPS, zOdb, Num);
        InitA(d[1], Num, (* Blad namiaru *) "Bˆ¥d odb Z (GPS)",
              DrawEpson.MaxX() * 3 DIV 6, (* zachodzi na siebie *)
              DrawEpson.MaxX() DIV 3, -500, +500, FALSE);
      ELSE
        V_Files.GetResFileName(pbTeodolit, gOdb, Num);
        InitA(d[0], Num, (* Blad namiaru *) "Bˆ¥d odb G (TEO)",
              DrawEpson.MaxX() * 4 DIV 6, DrawEpson.MaxX() DIV 3, -500, +500,
              FALSE);
        V_Files.GetResFileName(pbTeodolit, zOdb, Num);
        InitA(d[1], Num, (* Blad namiaru *) "Bˆ¥d odb Z (TEO)",
              DrawEpson.MaxX() * 3 DIV 6, (* zachodzi na siebie *)
              DrawEpson.MaxX() DIV 3, -500, +500, FALSE);
      END (* if Odniesienie *);
      Start := Odstep DIV 2;
      V_Files.GetSigFileName(Var, gOdb, Num);
      InitA(d[2], Num, "VAR.G", Start, Odstep, 250, 350, FALSE);
      INC(Start, Odstep);
      V_Files.GetSigFileName(Ref, gOdb, Num);
      InitA(d[3], Num, "REF.G", Start, Odstep, 130, 190, FALSE);
      INC(Start, Odstep);
      V_Files.GetSigFileName(Sub, gOdb, Num);
      InitA(d[4], Num, "SCR.G", Start, Odstep, 250, 350, FALSE);
      INC(Start, Odstep);
      V_Files.GetSigFileName(Agc, gOdb, Num);
      InitA(d[5], Num, "SS.G", DrawEpson.MaxX() * 5 DIV 6, DrawEpson.MaxX() DIV
            3, 2, Agc_Max, TRUE);
      InitB(d[6], "V.AD.G", FALSE, Start, Odstep, NAVG_AFlg);
      INC(Start, Odstep);
      InitB(d[7], "FLG.G", TRUE, Start, Odstep, NAVG_flg);
      INC(Start, Odstep);
      InitB(d[8], "VHF.AD", FALSE, Start, Odstep, Com_Aud_flg);
    ELSE   (* ZESTAW 2 *)
      Start := Odstep DIV 2;
      V_Files.GetSigFileName(Var, zOdb, Num);
      InitA(d[0], Num, "VAR.Z", Start, Odstep, 250, 350, FALSE);
      INC(Start, Odstep);
      V_Files.GetSigFileName(Ref, zOdb, Num);
      InitA(d[1], Num, "REF.Z", Start, Odstep, 130, 190, FALSE);
      INC(Start, Odstep);
      V_Files.GetSigFileName(Sub, zOdb, Num);
      InitA(d[2], Num, "SCR.Z", Start, Odstep, 250, 350, FALSE);
      V_Files.GetSigFileName(Agc, zOdb, Num);
      InitA(d[3], Num, "SS.Z", DrawEpson.MaxX() * 5 DIV 6, DrawEpson.MaxX() DIV
            3, 2, Agc_Max, TRUE);
      INC(Start, Odstep);
      InitB(d[4], "V.AD.Z", FALSE, Start, Odstep, NAVZ_AFlg);
      INC(Start, Odstep);
      InitB(d[5], "FLG.Z", TRUE, Start, Odstep, NAVZ_flg);
      INC(Start, Odstep);
      Files.GetCommSigFName(Files.CS_GPS_GDOP, FALSE (* VOR*), Num);
      InitA(d[6], Num, "GDOP", Start, Odstep, 0, 50, FALSE);
      INC(Start, Odstep);
      Files.GetCommSigFName(Files.CS_GPS_NOS, FALSE (* VOR*), Num);
      InitA(d[7], Num, "NOS", Start, Odstep, 0, 10, FALSE);
      INC(Start, Odstep);
      Files.GetCommSigFName(Files.CS_PilError, FALSE (* VOR*), Num);
      IF PromienANieOrbita()
      THEN
        InitA(d[8], Num, "Bˆ¥d pil.", Start, Odstep, -500, 500, FALSE);
      ELSE
        InitA(d[8], Num, "Bˆ¥d pil.", Start, Odstep, -500, 500, FALSE);
      END (* if PromienANieOrbita *);
    END (* if Zestaw *);
    DrawEpson.SetFont(DrawEpson.ft8x8);
    DrawEpson.SetTextMode(DrawEpson.mtOr);
    FOR s := 0 TO IleStron - 1 DO
      DrawEpson.Open;
      DrawEpson.Mnoznik(SKALA_X, 1);
      DrawEpson.SetTextMode(DrawEpson.mtSet);
      FOR j := 0 TO HIGH(d) DO
        Opis(d[j], NOT ODD(j));
      END (* for j *);
      DrawEpson.Line(0, 0, 0, MaxY() - 1, StyleSep);
      (* eventy *)
      i := MaxY() * CoKtoraProbka;
      PolozenieNapisu := DrawEpson.MaxX() * 9 DIV 10;
      DrawEpson.SetDir(DrawEpson.t_90);
      DrawEpson.Mnoznik(SKALA_X_90, SKALA_Y_90);
      PiszEventy.EnumEv(U_TRS, PromienANieOrbita(), s * i, (s + 1) * i - 1,
                        EvProc, s);
      DrawEpson.Mnoznik(SKALA_X, 1);
      DrawEpson.SetDir(DrawEpson.t_0);
      DrawEpson.SetTextMode(DrawEpson.mtSet);
      i := s + 1;
      StdIO.sprintf2(Num, "Strona %d/%d", i, IleStron);
      DrawEpson.DrawText(Num, 0, MaxY());
      DrawEpson.DrawText(header, DrawEpson.MaxX() - SKALA_X * 8 *
                         Strings.Length(header) - 4, MaxY());
      DrawEpson.SetTextMode(DrawEpson.mtXor);
      FOR idx := 0 TO MaxY() - 1 DO
        FOR j := 0 TO HIGH(d) DO
          Point(d[j], idx);
        END (* for j *);
      END (* for idx *);
      (* znaczniki odleglosci *)
      ZnacznikiOdleglosci(anRes.odnDlaPomOdl, Odniesienie, Pomiar, s,
                          PromienANieOrbita(), TRUE, 0);
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

  PROCEDURE Raport( dwaOdniesienia : BOOLEAN );

  BEGIN
    gOdb := anRes.GlownyOdbiornik;
    IF gOdb = goA
    THEN
      zOdb := goB;
      NAVG_flg := NAVA_flg;
      NAVZ_flg := NAVB_flg;
      NAVG_AFlg := NAVA_Aud_flg;
      NAVZ_AFlg := NAVB_Aud_flg;
    ELSE
      zOdb := goA;
      NAVG_flg := NAVB_flg;
      NAVZ_flg := NAVA_flg;
      NAVG_AFlg := NAVB_Aud_flg;
      NAVZ_AFlg := NAVA_Aud_flg;
    END (* if gOdb *);
    Files.GetCommSigFName(Files.CS_GPS_GDOP, Pomiar, NazwaPliku);
    MakeHeader(header);
    IF NOT Print( dwaOdniesienia )
    THEN
      RETURN;
    END (* if *);
    OpisPomiaru;
    PiszEventy.PiszNaDrukarce(U_TRS, PromienANieOrbita(),
                              PiszEventy.TypyEventow {PoczatekPomiaru..
                              ZnacznikT});
  END Raport;

BEGIN
  Zestaw := 0;
END VORPrint.
