(*.F- *)
(**********************************************************************
|  Title   : Drukowanie dla DME
|  Author  : M.Morawski
|  System  : LOGITECH MODULA-2/86
|  History :
|    20-07-96: M.Postol
|      Zmiany definicji Print; Liczne bledy.
|    17-10-96: M.Postol
|     procedura IntFrac wypisywala kary w formacie 180
|    07-12-96: M.Postol
|      zmiant spowodowane zmianami w D_result.DEF
|
|    31-112-97: TOMEK
|      zmiana EPE na GDOP 
|  Copyright (C), CAS LODZ POLAND.
|  TEL: 42' 862 547, 42' 87 80 44 FAX/TEL: 42' 84 48 40
|
**********************************************************************)
(*.F+ *)

IMPLEMENTATION MODULE DMEPrint;

  FROM EventsMng IMPORT
    EventKind, RodzUrzadzenia;

  IMPORT
    DrawEpson, SYSTEM, ASCII, StdIO, D_results, D_Files, Files, D_CommonTypes;

  FROM PiszEventy IMPORT
    EnumEv, PiszNaDrukarce, TypyEventow;

  FROM SpecConv IMPORT
    ToStringProcT, Card500Str, Int2Str, Int100Str, Ang100Str36;

  FROM Print IMPORT
    (* CONST *) StyleSep, PASEK, SKALA_X, SKALA_X_90, SKALA_Y_90,
    (* TYPE *) Desc,
    (* VAR *) PolozenieNapisu, PrnX, PrnY,
    (* PROCEDURE *) MaxY, Wr, WrPrn, WrLn, WrPrnLn, InitA, InitB, Point, Opis,
                    CloseAll, InitAll, ZnacznikiOdleglosci, EvProc,
                    WrF_TablicaOdci;

  FROM CommonTypes IMPORT
    (* TYPE *) GlownyOdbiornikT, OdnDlaPomBleduT, SignalDsc, Str99,
    (* CONST *) GPS_flg, DMEA_trc, DMEB_trc, DMEA_Aud_flg, DMEB_Aud_flg,
                DMEA_mem, DMEB_mem,
    (* PROCEDURE *) GetRecName, GetTranName;

  FROM SYSTEM IMPORT
    WORD;

  FROM Strings IMPORT
    Concat, Insert, Length;

  FROM PrintCntroll IMPORT
    UstalSkalowanie;

  CONST
    GPSFLG  = GPS_flg;
    Pomiar  = TRUE;
    NagTab  =
    "   Odbiornik                                      ³glowny  ³zapasowy³";

  TYPE
    Descs =
      ARRAY [0 .. 12] OF Desc;
    Str80 =
      ARRAY [0 .. 80] OF CHAR;

  VAR
    header     : Str99;
    NazwaPliku : ARRAY [0 .. 30] OF CHAR;
    gOdb        : GlownyOdbiornikT;
    zOdb        : GlownyOdbiornikT;
    SRCG_flg    : CARDINAL;
    SRCZ_flg    : CARDINAL;
    MEMG_flg    : CARDINAL;
    MEMZ_flg    : CARDINAL;
    DMEG_AFlg   : CARDINAL;
    DMEZ_AFlg   : CARDINAL;

  PROCEDURE PromienANieOrbita() : BOOLEAN;

  BEGIN
    RETURN D_results.anRes.procedure >= D_CommonTypes.pPromienBlad;
  END PromienANieOrbita;

  PROCEDURE MakeHeader
            ( VAR str : ARRAY OF CHAR );
  VAR
    k      : CARDINAL;
    l      : CARDINAL;
    odbN   : ARRAY [ 0 .. 15  ] OF CHAR;
    tranN  : ARRAY [ 0 .. 15 ] OF CHAR;
    tmpOdb : SYSTEM.ADDRESS;

  BEGIN
    WITH D_results.anRes DO
      GetTranName(tranN, Nadajnik1);
      GetRecName(odbN, gOdb);
      Concat(odbN, ' ', odbN);
      Concat(odbN, tranN, odbN);
      tmpOdb := SYSTEM.ADR(odbN);
      IF PromienANieOrbita()
      THEN
        StdIO.sprintf3(str,
                       " DME promien %dø OdbG: %s; Pomiar wyk. o godz. %d:%02d dn. %d.%02d.%d",
                       PromienLubOrbita, tmpOdb,
                       data);
      ELSE
        k := CARDINAL(PromienLubOrbita) DIV 500;
        l := CARDINAL(PromienLubOrbita) MOD 500 DIV 5;
        StdIO.sprintf4(str,
                       " DME orbita %d.%02dNM OdbG: %s; Pomiar wyk. o godz. %d:%02d dn. %d.%02d.%d",
                       k,
                       l,
                       tmpOdb,
                       data);
      END (* if PromienANieOrbita *);
      Insert(Nazwa,
             str,
             0);
    END (* with D_results.anRes *);
  END MakeHeader;

  PROCEDURE OpisPomiaru();
  VAR
    str : ARRAY [0 .. 99] OF CHAR;
    go  : GlownyOdbiornikT;

    PROCEDURE IntFrac
              (     pocz,
                    kon  : SYSTEM.WORD;
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
        Card500Str(CARDINAL(pocz),
                   s1,
                   5);
        Card500Str(CARDINAL(kon),
                   s2,
                   5);
        StdIO.sprintf2(str,
                       "Odcinek od %sNM do %sNM ³",
                       a1,
                       a2);
      ELSE
        Ang100Str36(INTEGER(pocz),
                  s1,
                  6);
        Ang100Str36(INTEGER(kon),
                  s2,
                  6);
        StdIO.sprintf2(str,
                       " Odcinek od %sø do %sø ³",
                       a1,
                       a2);
      END (* if PromienANieOrbita *);
    END IntFrac;

    PROCEDURE WrSignalDesc
              (    pocz : WORD;
                   kon  : WORD;
                   d1   : SignalDsc;
                   d2   : SignalDsc ) : BOOLEAN;

    TYPE
      Str80 =
        ARRAY [0 .. 80] OF CHAR;
      Str30 =
        ARRAY [0 .. 30] OF CHAR;
    VAR
      str : Str80;
      s   : Str30;

    BEGIN
      IF NOT WrPrnLn(0,
                     NagTab)
      THEN
        RETURN FALSE;
      END (* if *);
      IF NOT WrPrnLn(0,
                     PASEK)
      THEN
        RETURN FALSE;
      END (* if *);
      IntFrac(pocz,
              kon,
              str);
      Insert("Sila sygnalu Min ³ ",
             str,
             0);
      Int2Str(d1.val,
              s,
              4);
      Concat(str,
             s,
             str);
      Concat(str,
             'dBm ³',
             str);
      Int2Str(d2.val,
              s,
              4);
      Concat(str,
             s,
             str);
      Concat(str,
             'dBm ³',
             str);
      IF NOT WrPrnLn(0,
                     str)
      THEN
        RETURN FALSE;
      END (* if *);
      IF NOT WrPrnLn(0,
                     PASEK)
      THEN
        RETURN FALSE;
      END (* if *);
      RETURN TRUE;
    END WrSignalDesc;

    PROCEDURE max
              (    a,
                   b : CARDINAL ) : CARDINAL;

    BEGIN
      IF a > b
      THEN
        RETURN a;
      ELSE
        RETURN b;
      END (* if a *);
    END max;
  VAR
    o_nr   : CARDINAL;
    o_w    : CARDINAL;
   converP : ToStringProcT;

  BEGIN (* OpisPomiaru *)
    PrnX := 0;
    PrnY := 0;
    IF NOT WrPrnLn(0,
                   header)
    THEN
      RETURN;
    END (* if *);
    IF PromienANieOrbita() THEN
      converP := ToStringProcT(Card500Str);
    ELSE
      converP := Ang100Str36;
    END;
    FOR o_nr := 0 TO D_results.anRes.a_IleOd - 1 DO
      WITH D_results.anRes.analiza[o_nr] DO
        IF NOT WrSignalDesc(pocz,
                            kon,
                            SSmin[gOdb],
                            SSmin[zOdb])
        THEN
          RETURN;
        END (* if *);
        IF NOT WrPrnLn(0, PASEK)
        THEN
          RETURN;
        END (* if *);
        IF NOT WrF_TablicaOdci("Zestawienie odcink¢w wyst¥pienia flagi SRC",
                               wykluczenia, converP)
        THEN
          RETURN;
        END (* if *);
      END (* with D_results.anRes.analiza *);
    END (* for o_nr *);
  END OpisPomiaru;

  PROCEDURE Print() : BOOLEAN;
  VAR
    d             : Descs;
    Start         : INTEGER;
    Odstep        : INTEGER;
    s             : INTEGER;
    idx           : INTEGER;
    i,
    j             : INTEGER;
    FileNm        : ARRAY [0 .. 69] OF CHAR;
    IleStron      : CARDINAL;
    Odniesienie   : OdnDlaPomBleduT;
    Zestaw        : CARDINAL;
    CoKtoraProbka : CARDINAL;

  BEGIN
(*    DrawEpson.InitPort;*)
    IF NOT UstalSkalowanie(FALSE,
                           FALSE,
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
      InitAll(d,
              1 * 500,
              Pomiar,
              CoKtoraProbka);
    ELSE
      InitAll(d,
              10 * 100,
              Pomiar,
              CoKtoraProbka);
    END (* if PromienANieOrbita *);
    (* Sila Sygnalu (glowny)*)
    D_Files.GetFileName(D_results.AGC,
                        gOdb,
                        FileNm);
    InitA(d[0],
          FileNm,
          "SS odb G",
          DrawEpson.MaxX() * 5 DIV 6,
          DrawEpson.MaxX() DIV 3,
          -85,
          -30,
          FALSE);
    (* Sila Sygnalu (zapasowy)*)
    D_Files.GetFileName(D_results.AGC,
                        zOdb,
                        FileNm);
    InitA(d[1],
          FileNm,
          "SS odb Z",
          DrawEpson.MaxX() * 2 DIV 3, (* zachodzi *)
          DrawEpson.MaxX() DIV 3,
          -85,
          -30,
          FALSE);
    Odstep := (DrawEpson.MaxX() DIV 2) DIV 8;
    Start := Odstep DIV 2;
    InitB(d[4],
          "SRC.G",
          FALSE,
          Start,
          Odstep,
          SRCG_flg);
    INC(Start,
        Odstep);
    InitB(d[5],
          "SRC.Z",
          FALSE,
          Start,
          Odstep,
          SRCZ_flg);
    INC(Start,
        Odstep);
    D_Files.GetFileName(D_results.Replay,
                        gOdb,
                        FileNm);
    InitA(d[6],
          FileNm,
          "%R.G",
          Start,
          Odstep,
          0,
          1000,
          FALSE);
    INC(Start,
        Odstep);
    D_Files.GetFileName(D_results.Replay,
                        zOdb,
                        FileNm);
    InitA(d[7],
          FileNm,
          "%R.Z",
          Start,
          Odstep,
          0,
          1000,
          FALSE);   (* 0%-100% wyrazone wprost *)
    INC(Start,
        Odstep);
    D_Files.GetFileName(D_results.Squiter,
                        gOdb,
                        FileNm);
    InitA(d[8],
          FileNm,
          "SQ.G",
          Start,
          Odstep,
          0,
          3000,
          FALSE);
    INC(Start,
        Odstep);
    D_Files.GetFileName(D_results.Squiter,
                        zOdb,
                        FileNm);
    InitA(d[9],
          FileNm,
          "SQ.Z",
          Start,
          Odstep,
          0,
          3000,
          FALSE);
    INC(Start,
        Odstep);
    InitB(d[10],
          "MEM.G",
          FALSE,
          Start,
          Odstep,
          MEMG_flg);
    INC(Start,
        Odstep);
    InitB(d[11],
          "MEM.Z",
          FALSE,
          Start,
          Odstep,
          MEMZ_flg);
    DrawEpson.SetFont(DrawEpson.ft8x8);
    DrawEpson.SetTextMode(DrawEpson.mtOr);
    FOR s := 0 TO IleStron - 1 DO
      DrawEpson.Open;
      DrawEpson.Mnoznik(SKALA_X,
                        1);
      DrawEpson.SetTextMode(DrawEpson.mtSet);
      FOR j := 0 TO HIGH(d) DO
        Opis(d[j],
             NOT ODD(j));;
      END (* for j *);
      DrawEpson.Line(0,
                     0,
                     0,
                     MaxY() - 1,
                     StyleSep);
      DrawEpson.Line(DrawEpson.MaxX() - 1,
                     0,
                     DrawEpson.MaxX() - 1,
                     MaxY() - 1,
                     StyleSep);
      (* eventy *)
      i := MaxY() * CoKtoraProbka;
      PolozenieNapisu := DrawEpson.MaxX() * 9 DIV 10;
      DrawEpson.SetDir(DrawEpson.t_90);
      DrawEpson.Mnoznik(SKALA_X_90,
                        SKALA_Y_90);
      EnumEv(U_DME,
             PromienANieOrbita(),
             s * i,
             (s + 1) * i - 1,
             EvProc,
             s);
      DrawEpson.Mnoznik(SKALA_X,
                        1);
      DrawEpson.SetDir(DrawEpson.t_0);
      DrawEpson.SetTextMode(DrawEpson.mtSet);
      i := s + 1;
      StdIO.sprintf2(FileNm,
                     "Strona %d/%d",
                     i,
                     IleStron);
      DrawEpson.DrawText(FileNm,
                         0,
                         MaxY());
      DrawEpson.DrawText(header,
                         DrawEpson.MaxX() - SKALA_X * 8 * Length(header) - 4,
                         MaxY());
      DrawEpson.SetTextMode(DrawEpson.mtXor);
      FOR idx := 0 TO MaxY() - 1 DO
        FOR j := 0 TO HIGH(d) DO
          Point(d[j],
                idx);
        END (* for j *);
      END (* for idx *);
      ZnacznikiOdleglosci(D_results.anRes.odnDlaPomOdl,
                          pbGPS,
                          Pomiar,
                          s,
                          PromienANieOrbita(),
                          TRUE,
                          0);
      IF NOT DrawEpson.Out(DrawEpson.WrProc)
      THEN
        DrawEpson.Close;
        RETURN FALSE;
      END (* if *);
      DrawEpson.Close;
    END (* for s *);
    CloseAll(d);
    RETURN TRUE;
  END Print;

  PROCEDURE Raport;

  BEGIN
    gOdb := D_results.anRes.GlownyOdbiornik;
    IF gOdb = goA
    THEN
      zOdb := goB;
      SRCG_flg  := DMEA_trc;
      SRCZ_flg  := DMEB_trc;
      MEMG_flg  := DMEA_mem;
      MEMZ_flg  := DMEB_mem;
      DMEG_AFlg := DMEA_Aud_flg;
      DMEZ_AFlg := DMEB_Aud_flg;
    ELSE
      zOdb := goA;
      SRCG_flg  := DMEB_trc;
      SRCZ_flg  := DMEA_trc;
      MEMG_flg  := DMEB_mem;
      MEMZ_flg  := DMEA_mem;
      DMEG_AFlg := DMEB_Aud_flg;
      DMEZ_AFlg := DMEA_Aud_flg;
    END (* if gOdb *);
    Files.GetCommSigFName(Files.CS_GPS_GDOP,
                          Pomiar,
                          NazwaPliku);
    MakeHeader(header);
    IF NOT Print()
    THEN
      RETURN;
    END (* if *);
    OpisPomiaru;
    PiszNaDrukarce(U_DME,
                   PromienANieOrbita(),
                   TypyEventow {PoczatekPomiaru..ZnacznikT});
  END Raport;

END DMEPrint.
