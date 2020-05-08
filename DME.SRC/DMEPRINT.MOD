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
|    Rel 3.0. MPostol
|      Drukowanie bledow dme (min, max i sredniego
|    Rel.3.14. MPostol
|      - Wydruk bledu odleglosci jest wykonywany tylko, gdy pomiar jest na 
|        orbicie
|      - 
|  Copyright (C), CAS LODZ POLAND.
|  TEL: 42' 862 547, 42' 87 80 44 FAX/TEL: 42' 84 48 40
|
**********************************************************************)
(*.F+ *)

IMPLEMENTATION MODULE DMEPrint;

  FROM EventsMng IMPORT
    EventKind, RodzUrzadzenia;

  IMPORT
    DrawEpson, SYSTEM, StdIO, D_results, D_Files, Files, D_CommonTypes;

  FROM PiszEventy IMPORT
    EnumEv, PiszNaDrukarce, TypyEventow;

  FROM SpecConv IMPORT
    ToStringProcT, Card500Str, Int2Str, Int100Str, Ang100Str36, Int500Str;

  FROM Czas  IMPORT
    ConvertToStr;
    
  FROM Print IMPORT
    (* CONST *) StyleSep, PASEK, SKALA_X, SKALA_X_90, SKALA_Y_90,
    (* TYPE *) Desc,
    (* VAR *) PolozenieNapisu, PrnX, PrnY,
    (* PROCEDURE *) MaxY, WrPrn, WrPrnLn, InitA, InitB, Point, Opis,
                    CloseAll, InitAll, ZnacznikiOdleglosci, EvProc,
                    WrF_TablicaOdci, WrLn;

  FROM CommonTypes IMPORT
    (* TYPE *) GlownyOdbiornikT, OdnDlaPomBleduT, SignalDsc, Str99,
    (* CONST *) DMEA_trc, DMEB_trc, DMEA_Aud_flg, DMEB_Aud_flg,
                DMEA_mem, DMEB_mem,
    (* PROCEDURE *) GetRecName, GetTranName;

  FROM SYSTEM IMPORT
    WORD;

  FROM Strings IMPORT
    Concat, Insert, Length;

  FROM PrintCntroll IMPORT
    UstalSkalowanie;

  CONST
    Pomiar  = TRUE;
    NagTab1    =
    "ษอออออออออออออออออออออออออออออออหอออออออออออออออออออออออออออออป";
    NagTab2    =
    "บ                               บ           ODBIORNIK         บ";
    NagTab3    =
    "บWarto bฉdu DME wzglฉdem GPS บ      A       บ     B        บ";
    NagTab3deg    =
    "บ                               บ   [NM]/[๘]   บ   [NM]/[๘]   บ";
    NagTab3nm    =
    "บ                               บ   [NM]/[NM]  บ   [NM]/[NM]  บ";
    NagTab4    =
    "ฬอออออออออออออออออออออออออออออออฮออออออออออออออฮออออออออออออออน";
    NagTab5_min    =
    "บBฅd minimalny  / miejsce      บ";
    NagTab6_max    =
    "บBฅd maksymalny / miejsce      บ";
    NagTab7_sre    =
    "บBฅd warto rednia           บ";
    NagTab8    =
    "ศอออออออออออออออออออออออออออออออสออออออออออออออสออออออออออออออผ";
    
    (* Wzorzec tabeli บศป ษสผ ห ฬอฮอน *)

    NagTab  =
    "ษอออออออออออออออออออออออออออออออหอออออออออออออออออออออออออออออป";
    
    NagTab9 =
    "บ  Sia sygnau minimalna       บ     A        บ    B         บ";

    NagTab10 =
    "บ                               บ              บ              บ";

  PROCEDURE Raport;

  TYPE
    Descs =
      ARRAY [0 .. 12] OF Desc;

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
    odbN     : ARRAY [ 0 .. 15  ] OF CHAR;
    tranN    : ARRAY [ 0 .. 15 ] OF CHAR;
    odlStr   : ARRAY [ 0 .. 9  ] OF CHAR;
    tmpOdb   : SYSTEM.ADDRESS;
    dataStr  : ARRAY [ 0 .. 20 ] OF CHAR;
    data_adr : SYSTEM.ADDRESS;
    odlStr_adr : SYSTEM.ADDRESS;

  BEGIN
    WITH D_results.anRes DO
      GetTranName(tranN, Nadajnik1);
      GetRecName(odbN, gOdb);
      Concat(odbN, ' ', odbN);
      Concat(odbN, tranN, odbN);
      ConvertToStr(data, FALSE, dataStr);
      tmpOdb    := SYSTEM.ADR(odbN);
      data_adr  := SYSTEM.ADR(dataStr);
      IF PromienANieOrbita()
      THEN
        StdIO.sprintf3(str,
                       " DME promieไ %d๘ OdbG: %s; Pomiar wyk. %s",
                       PromienLubOrbita, 
                       tmpOdb,
                       data_adr);
      ELSE
        Card500Str( CARDINAL(PromienLubOrbita), odlStr, 9);
        odlStr_adr := SYSTEM.ADR(odlStr);
        StdIO.sprintf3(str,
                      " DME orbita %sNM OdbG: %s; Pomiar wyk. %s",
                       odlStr_adr,
                       tmpOdb,
                       data_adr);
      END (* if PromienANieOrbita *);
      Insert(Nazwa,
             str,
             0);
    END (* with D_results.anRes *);
  END MakeHeader;

  PROCEDURE OpisPomiaru
            (Format360 : BOOLEAN);

  PROCEDURE  OpisBleduDME 
             (    converP    : ToStringProcT;
                  odlBlaSren : D_results.MMA_SignalDscArr ) : BOOLEAN;
    
    PROCEDURE WrSignalDesc
              (     wart        : SignalDsc;
                    ConvertTStr : ToStringProcT ) : BOOLEAN;
    VAR
      s : ARRAY [0 .. 30] OF CHAR;

    BEGIN
      WITH wart DO
        Int500Str(val, s, 6);
        IF NOT WrPrn(0, s)
        THEN
          RETURN FALSE;
        END (* if *);
        IF NOT WrPrn(0,"/")
        THEN
          RETURN FALSE;
        END (* if *);
        ConvertTStr( INTEGER(pos), s, 7 );
        IF NOT WrPrn(0, s)
        THEN
          RETURN FALSE;
        END (* if *);
        IF NOT WrPrn(0,"บ")
        THEN
          RETURN FALSE;
        END (* if *);
        RETURN TRUE;
      END;
    END WrSignalDesc;

    PROCEDURE WrSignalInt
              (     wart : INTEGER  ): BOOLEAN;
    VAR
      s : ARRAY [0 .. 30] OF CHAR;

    BEGIN
      Int500Str(wart, s, 6);
      IF NOT WrPrn(0, s)
      THEN
        RETURN FALSE;
      END (* if *);
      IF NOT WrPrn(0,"        บ")
      THEN
        RETURN FALSE;
      END (* if *);
      RETURN TRUE;
    END WrSignalInt;

    VAR
      odb: GlownyOdbiornikT;
      
  BEGIN (* OpisBleduDME *)
    IF NOT WrPrnLn(0, NagTab1 ) THEN
      RETURN FALSE;
    END;
    IF NOT WrPrnLn(0, NagTab2 ) THEN
      RETURN FALSE;
    END;
    IF NOT WrPrnLn(0, NagTab3 ) THEN
      RETURN FALSE;
    END;
    IF PromienANieOrbita () THEN
      IF NOT WrPrnLn(0, NagTab3nm ) THEN
        RETURN FALSE;
      END;
    ELSE
      IF NOT WrPrnLn(0, NagTab3deg ) THEN
        RETURN FALSE;
      END;
    END;
    IF NOT WrPrnLn(0, NagTab4 ) THEN
      RETURN FALSE;
    END;
    IF NOT WrPrn(0, NagTab5_min) THEN
      RETURN FALSE;
    END;
    FOR odb := MIN(GlownyOdbiornikT) TO MAX(GlownyOdbiornikT) DO
      IF NOT WrSignalDesc( odlBlaSren[odb].min, converP)  THEN
        RETURN FALSE;
      END;
    END; (* FOR *)
    IF NOT WrLn() THEN
      RETURN FALSE;
    END;
    IF NOT WrPrn(0, NagTab6_max) THEN
      RETURN FALSE;
    END;
    FOR odb := MIN(GlownyOdbiornikT) TO MAX(GlownyOdbiornikT) DO
      IF NOT WrSignalDesc( odlBlaSren[odb].max, converP)  THEN
        RETURN FALSE;
      END;
    END; (* FOR *)
    IF NOT WrPrnLn(0, "") THEN
      RETURN FALSE;
    END;
    IF NOT WrPrn(0, NagTab7_sre) THEN
      RETURN FALSE;
    END;
    FOR odb := MIN(GlownyOdbiornikT) TO MAX(GlownyOdbiornikT) DO
      IF NOT WrSignalInt( odlBlaSren[odb].avr)  THEN
        RETURN FALSE;
      END;
    END; (* FOR *)
    IF NOT WrLn() THEN
      RETURN FALSE;
    END;
    IF NOT WrPrnLn(0, NagTab8) THEN
      RETURN FALSE;
    END;
    RETURN TRUE;
  END OpisBleduDME;
  
    PROCEDURE WrSignalDesc
              (    pocz      : WORD;
                   kon       : WORD;
                   d1        : SignalDsc;
                   d2        : SignalDsc;
                   format360 : BOOLEAN ) : BOOLEAN;

    PROCEDURE IntFrac
              (     pocz,
                    kon       : SYSTEM.WORD;
                VAR str       : ARRAY OF CHAR;
                    format360 : BOOLEAN );

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
                       "Odcinek od %sNM do %sNM  บ",
                       a1,
                       a2);
      ELSE
        IF format360 THEN
          Ang100Str36(INTEGER(pocz),
                      s1,
                      6);
          Ang100Str36(INTEGER(kon),
                      s2,
                      6);
        ELSE
          Int100Str(INTEGER(pocz),
                    s1,
                    6);
          Int100Str(INTEGER(kon),
                    s2,
                    6);
        END(*if*);          
        StdIO.sprintf2(str,
                       " Odcinek od %s๘ do %s๘ บ",
                       a1,
                       a2);
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

    BEGIN (* WrSignalDesc *)
      IF NOT WrPrnLn(0,
                     NagTab)
      THEN
        RETURN FALSE;
      END (* if *);
      IF NOT WrPrnLn(0,
                     NagTab2)
      THEN
        RETURN FALSE;
      END(* if *);
      IF NOT WrPrnLn(0,
                     NagTab9)
      THEN
        RETURN FALSE;
      END (* if *);
      IF NOT WrPrnLn(0,
                     NagTab4)
      THEN
        RETURN FALSE;
      END(* if *);
     
      IF NOT WrPrn(0,
                     "บ")
      THEN
        RETURN FALSE;
      END(* if *);

      
      IntFrac(pocz,
              kon,
              str,
              format360
              );
      Int2Str(d1.val,
              s,
              4);
      Concat(str,
             s,
             str);
      Concat(str,
             'dBm       บ',
             str);
      
     Int2Str(d2.val,
              s,
              4);
      Concat(str,
             s,
             str);
      Concat(str,
             'dBm       บ',
             str);
          
       IF NOT WrPrnLn(0,
                     str)
      THEN
        RETURN FALSE;
        
      END (* if *);

 
      IF NOT WrPrnLn(0,
                     NagTab8)
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
    IF NOT WrPrnLn(0,
                   header)
    THEN
      RETURN;
    END (* if *);
    IF PromienANieOrbita() THEN
      converP := ToStringProcT(Card500Str);
    ELSE
      IF Format360 THEN
        converP := Ang100Str36;
      ELSE
        converP := Int100Str;
      END;
      IF NOT OpisBleduDME(converP, D_results.anRes.odlBlaSren) THEN
          RETURN;
      END;
    END;
    
    FOR o_nr := 0 TO D_results.anRes.a_IleOd - 1 DO
      WITH D_results.anRes.analiza[o_nr] DO
        IF NOT WrSignalDesc(pocz,
                            kon,
                            SSmin[goA],
                            SSmin[goB],
                            Format360)
        THEN
          RETURN;
        END (* if *);
        IF NOT WrF_TablicaOdci("Zestawienie odcinkขw wystฅpienia flagi SRC",
                               wykluczenia, converP)
        THEN
          RETURN;
        END (* if *);
      END (* with D_results.anRes.analiza *);
    END (* for o_nr *);
  END OpisPomiaru;

  PROCEDURE Print
            ( Format360 : BOOLEAN ) : BOOLEAN;
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
                          Format360,
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
    IF NOT Print( NOT D_results.anRes.DMEforLOC )
    THEN
      RETURN;
    END (* if *);
    OpisPomiaru( NOT D_results.anRes.DMEforLOC );
    PiszNaDrukarce(U_DME,
                   PromienANieOrbita(),
                   TypyEventow {PoczatekPomiaru..ZnacznikT});
  END Raport;

END DMEPrint.
