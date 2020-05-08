(*.F- *)
(**********************************************************************
|  Title   : NDB wykonywanie raportow
|  Author  : M.Morawski
|  System  : LOGITECH MODULA-2/86
|  History :
|    11-12-96: M.Postol
|
|    31-12-97: TOMEK
|      zmieniono wykresy EPE na GDOP
|    17-08-00: ASzynkowski
|     Dostosowaˆem czas do nowej definicji
|    Rel. 3.14: MPostol
|      - Blad namiaru jest drukowany i kreslony jest dla procedury
|        pomiarowej dla promienia.
|
|  Copyright (C), CAS LODZ POLAND.
|  TEL: 42' 862 547, 42' 87 80 44 FAX/TEL: 42' 84 48 40
|
**********************************************************************)
(*.F+ *)

IMPLEMENTATION MODULE N_Print;

  FROM FlagAnal IMPORT
    F_TablicaOdci;

  FROM N_results IMPORT
    anRes;

  FROM EventsMng IMPORT
    EventKind, RodzUrzadzenia;

  FROM CommonTypes IMPORT
    GlownyOdbiornikT, NDBA_Aud_Flg, NDBB_Aud_Flg, GPS_flg, OdnDlaPomBleduT,
    poGPS, NadajnikT, SignalDsc, Str99, NilValI;

  FROM N_CommonTypes IMPORT
    ProceduraT;

  FROM SpecConv IMPORT
    ToStringProcT, Int100Str, Card500Str, Int2Str, Int10Str;

  FROM Strings IMPORT
    Insert, Concat;

  FROM PrintCntroll IMPORT
    UstalSkalowanie;

  IMPORT
    DrawEpson, Strings, SYSTEM, ASCII, StdIO, PiszEventy,
    N_results, N_Files, SpecConv, Files, N_CommonTypes;

  FROM StdIO IMPORT
    sprintf2, sprintf;

  FROM Print IMPORT
    (* CONST *) StyleSep, PASEK, SKALA_X, SKALA_X_90, SKALA_Y_90,
    (* TYPE *) Desc,
    (* VAR *) PolozenieNapisu, PrnX, PrnY,
    (* PROCEDURE *) MaxY, Wr, WrPrn, WrLn, WrPrnLn, InitA, InitB, Point, Opis,
                    CloseAll, InitAll, ZnacznikiOdleglosci, EvProc,
                    WrF_TablicaOdci;

  FROM Czas IMPORT
    ConvertToStr;

  CONST
    Pomiar = FALSE;
    DwaOdniesienia = FALSE;

  TYPE
    Descs =
      ARRAY [0 .. 8] OF Desc;
    Str80 =
      ARRAY [0 .. 80] OF CHAR;

  VAR
    header          : Str80;
    NazwaPliku      : ARRAY [0 .. 30] OF CHAR;
    Odbiornik       : GlownyOdbiornikT;
    NAVG_Audio_flg,
    NAVZ_Audio_flg  : CARDINAL;

  PROCEDURE MakeHeader
            ( VAR str : ARRAY OF CHAR );
  VAR
    dataStr  : ARRAY [ 0 .. 20 ] OF CHAR;
    data_adr : SYSTEM.ADDRESS;
    k : CARDINAL;
    l : CARDINAL;
    Urz : RECORD
      O, N : CHAR;
    END;

  BEGIN
    WITH anRes DO
      ConvertToStr(data, FALSE, dataStr);
      data_adr  := SYSTEM.ADR(dataStr);
      Urz.O := 'A';
      IF N_results.anRes.glownyOdbiornik = goB THEN
        INC( Urz.O );
      END;
      Urz.N := 'G';
      IF N_results.anRes.nadajnik = nB THEN
        Urz.N := 'Z';
      END;
      IF procedure = N_CommonTypes.pPromien
      THEN
        StdIO.sprintf3(str,
                       " NDB promien %dø OdbG:%c,Nad:%c;Pomiar wyk : %s ",
                       promienLubOrbita,
                       Urz,
                       data_adr);
      ELSE
        k := CARDINAL(promienLubOrbita) DIV 500;
        l := CARDINAL(promienLubOrbita) MOD 500 DIV 5;
        StdIO.sprintf4(str,
                       " NDB orbita %d.%02dNM OdbG:%c,Nad:%c;Pomiar wyk : %s ",
                       k,
                       l,
                       Urz,
                       data_adr);
      END (* if PromienANieOrbita *);
      Insert(Nazwa,
             str,
             0);
    END (* with D_results.anRes *);
  END MakeHeader;

    PROCEDURE WypiszTabBledowNamiaru
              (    converP : ToStringProcT; 
                   blad5   : F_TablicaOdci;
                   blad10  : F_TablicaOdci);
    BEGIN 
      WITH anRes DO
        IF NOT WrLn() THEN
          RETURN;
        END(*if*); 
        IF NOT WrPrnLn(0, PASEK) THEN
          RETURN;
        END (* if *);
        IF NOT WrF_TablicaOdci("Zestawienie odcink¢w dla bˆ©du >= 5ø",
                               blad5, converP)
        THEN
          RETURN;
        END (* if *);
        IF NOT WrPrnLn(0, PASEK) THEN
          RETURN;
        END (* if *);
        IF NOT WrF_TablicaOdci("Zestawienie odcink¢w dla bˆ©du >= 10ø",
                               blad10, converP)
        THEN
          RETURN;
        END (* if *);
      END (* with anRes *);
    END WypiszTabBledowNamiaru;
    
  PROCEDURE OpisPomiaru();
  VAR
    str     : Str99;
    go      : GlownyOdbiornikT;
    i       : CARDINAL;
    converP : ToStringProcT;
    
    PROCEDURE WrSignalDesc
              (     At          : CARDINAL;
                    str         : ARRAY OF CHAR;
                VAR d           : SignalDsc;
                    ConvertTStr : ToStringProcT       ) : BOOLEAN;
    VAR
      s : ARRAY [0 .. 30] OF CHAR;

    BEGIN
      IF At < 30
      THEN
        IF NOT WrPrn(0,
                     str)
        THEN
          RETURN FALSE;
        END (* if *);
        
        
        IF NOT WrPrn(15,
                     '³')
        THEN
          RETURN FALSE;
        END (* if *);
      ELSE
      
        IF NOT WrPrn(35,
                     '³')
        THEN
          RETURN FALSE;
        END (* if *);
      END (* if At *);
      ConvertTStr(d.val,
                  s,
                  7);
      (* Strings.Insert( '(', s, 0FFFH ); IF NOT PromienANieOrbita() THEN IF
         CARDINAL(d.pos) = CommonTypes.NilValC THEN Strings.ConstAssign(
         GWIAZDKI, s1 ); ELSE j := CARDINAL(d.pos) DIV 500; i :=
         CARDINAL(d.pos) MOD 500 DIV 50; StdIO.sprintf2( s1, "%d.%dNM", j, i );
         END; ELSE IF INTEGER(d.pos) = CommonTypes.NilValI THEN
         Strings.ConstAssign( GWIAZDKI, s1 ); ELSE k := INTEGER(d.pos); i :=
         ABS(k) MOD 100 DIV 10; k := k DIV 100; StdIO.sprintf2( s1, "%d.%dø",
         k, i ); END; END; Strings.Insert( s1, s, 0FFFH ); Strings.Insert( ')',
         s, 0FFFH ); *)
     
     Concat(s,'uV',s);
     IF NOT WrPrn(At,s)
       THEN
        RETURN FALSE;
      END (* if *);
      
      RETURN TRUE;
    END WrSignalDesc;

  BEGIN (* OpisPomiaru *)
    PrnX := 0;
    PrnY := 0;
    IF NOT WrPrnLn(0, header) THEN
      RETURN;
    END (* if *);
    IF NOT WrLn() THEN
     RETURN ;
    END(*if*);
    IF NOT WrPrnLn(0,
                   "   Odbiornik   ³       A          ³       B")
    THEN
      RETURN;
    END (* if *);
    IF NOT WrPrnLn(0,
                   PASEK)
    THEN
      RETURN;
    END (* if *);
    WITH anRes DO
      IF procedure = pOrbita THEN
        converP := Int100Str;
      ELSE
        converP := ToStringProcT(Card500Str);
      END;
      FOR go := goA TO goB DO
        IF NOT WrSignalDesc(ORD(go) * 40,
                            'Min SS',
                            SSMin_PO[go],
                            Int2Str)
        THEN
          RETURN;
        END (* if *);
      END (* for go *);
      IF NOT WrLn() THEN
        RETURN;
      END (* if *);
      IF NOT WrPrnLn(0, PASEK) THEN
        RETURN;
      END (* if *);
      IF NOT WrLn() THEN
       RETURN;
      END(*if*);
      IF NOT WrPrnLn( 0, 
        'Minimalna siˆa sygnaˆu na poszczeg¢lnych odcinkach' ) 
      THEN
        RETURN;
      END (* if *);
      IF NOT WrPrnLn(0, PASEK) THEN
        RETURN;
      END (* if *);
      FOR i := 1 TO a_IleOd DO
        WITH analiza[i-1] DO
          IF procedure = pOrbita THEN
            sprintf2( str, '%6zø-%6zø',   pocz, kon );
          ELSE
            sprintf2( str, '%6xNM-%6xNM', pocz, kon );
          END;
          FOR go := goA TO goB DO
            IF NOT WrSignalDesc( ORD(go) * 40, str, SSmin[go], Int2Str )
            THEN
              RETURN;
            END (* if *);
          END (* for go *);
          IF procedure <> pOrbita THEN
            WypiszTabBledowNamiaru ( converP, blad5, blad10);           
            IF NOT WrLn() THEN
              RETURN;
            END (* if *);
          END (* IF *);
        END; (* WITH analiza *)
      END; (* FOR i := 1 TO a_IleOd *)
    END; (* WITH anRes *)
    IF NOT WrLn() THEN
      RETURN;
    END;
  END OpisPomiaru;

  PROCEDURE Print() : BOOLEAN;
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
    Odniesienie   : OdnDlaPomBleduT;
    Zestaw        : CARDINAL;
    CoKtoraProbka : CARDINAL;

  BEGIN
    IF NOT UstalSkalowanie(FALSE,
                           DwaOdniesienia,
                           NazwaPliku,
                           IleStron,
                           Odniesienie,
                           Zestaw,
                           CoKtoraProbka)
    THEN
      RETURN FALSE;
    END (* if *);
    IF anRes.procedure = N_CommonTypes.pPromien
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

    IF anRes.glownyOdbiornik = goA THEN
      NAVG_Audio_flg := NDBA_Aud_Flg;
      NAVZ_Audio_flg := NDBB_Aud_Flg;
    ELSE
      NAVG_Audio_flg := NDBB_Aud_Flg;
      NAVZ_Audio_flg := NDBA_Aud_Flg;
    END;
    IF anRes.glownyOdbiornik = goA THEN
      Odbiornik := goB;
    ELSE
      Odbiornik := goA;
    END;
    N_Files.GetSigFileName(N_Files.agc_Sg,
                           anRes.glownyOdbiornik,
                           Num);
    InitA(d[0],
          Num,
          "SS.G",
          DrawEpson.MaxX() * 7 DIV 8,
          DrawEpson.MaxX() DIV 4,
          1,
          5000,
          TRUE);
    N_Files.GetSigFileName(N_Files.agc_Sg,
                           Odbiornik,
                           Num);
    InitA(d[1],
          Num,
          "SS.Z",
          DrawEpson.MaxX() * 6 DIV 8,
          DrawEpson.MaxX() DIV 4,
          1,
          5000,
          TRUE);

    IF anRes.procedure = pPromien  THEN
      N_Files.GetResFileName(anRes.glownyOdbiornik,
                             Num);
      InitA(d[2],
            Num,
            "Bˆ¥d.G",
            DrawEpson.MaxX() * 5 DIV 8,
            DrawEpson.MaxX() DIV 4,
            -2000,
            +2000,
            FALSE);
      N_Files.GetResFileName(Odbiornik,
                             Num);
      InitA(d[3],
            Num,
            "Bˆ¥d.Z",
            DrawEpson.MaxX() * 4 DIV 8,
            DrawEpson.MaxX() DIV 4,
            -2000,
            +2000,
            FALSE);
    END (* IF *);
    Odstep := (DrawEpson.MaxX() *3 DIV 8) DIV 5;
    Start := Odstep DIV 2;
    InitB(d[4],
          "A.G",
          FALSE,
          Start,
          Odstep,
          NAVG_Audio_flg);
    INC(Start, Odstep);
    InitB(d[5],
          "A.Z",
          FALSE,
          Start,
          Odstep,
          NAVZ_Audio_flg);
    INC(Start, Odstep);
    Files.GetCommSigFName(Files.CS_GPS_GDOP, FALSE , Num);
    InitA(d[6],
          Num,
          "GDOP",
          Start,
          Odstep,
          0,
          50,
          FALSE);
    INC(Start, Odstep);
    Files.GetCommSigFName(Files.CS_GPS_NOS, FALSE, Num);
    InitA(d[7],
          Num,
          "NOS",
          Start,
          Odstep,
          0,
          10,
          FALSE);
    INC(Start, Odstep);
    InitB(d[8],
          "GPS.FLG",
          FALSE,
          Start,
          Odstep,
          GPS_flg );
    INC(Start, Odstep);
    DrawEpson.SetFont(DrawEpson.ft8x8);
    DrawEpson.SetTextMode(DrawEpson.mtOr);
    FOR s := 0 TO IleStron - 1 DO
     DrawEpson.Open;
     DrawEpson.Mnoznik(SKALA_X,
                       1);
     DrawEpson.SetTextMode(DrawEpson.mtSet);
     FOR j := 0 TO HIGH(d) DO
       Opis(d[j],
            NOT ODD(j));
     END (* for j *);
     DrawEpson.Line(0,
                    0,
                    0,
                    MaxY() - 1,
                    StyleSep);
     (* eventy *)
     i := MaxY() * CoKtoraProbka;
     PolozenieNapisu := DrawEpson.MaxX() * 9 DIV 10;
     DrawEpson.SetDir(DrawEpson.t_90);
     DrawEpson.Mnoznik(SKALA_X_90,
                       SKALA_Y_90);
     PiszEventy.EnumEv(U_NDB,
                       anRes.procedure = N_CommonTypes.pPromien,
                       s * i,
                       (s + 1) * i - 1,
                       EvProc,
                       s);
     DrawEpson.Mnoznik(SKALA_X,
                       1);
     DrawEpson.SetDir(DrawEpson.t_0);
     DrawEpson.SetTextMode(DrawEpson.mtSet);
     i := s + 1;
     StdIO.sprintf2(Num,
                    "Strona %d/%d",
                    i,
                    IleStron);
     DrawEpson.DrawText(Num,
                        0,
                        MaxY());
     DrawEpson.DrawText(header,
                        DrawEpson.MaxX()-SKALA_X*8*Strings.Length(header)-4,
                        MaxY());
     DrawEpson.SetTextMode(DrawEpson.mtXor);
     FOR idx := 0 TO MaxY() - 1 DO
       FOR j := 0 TO HIGH(d) DO
         Point(d[j],
               idx);
       END (* for j *);
     END (* for idx *);
     (* znaczniki odleglosci *)
     ZnacznikiOdleglosci(poGPS,
                         pbGPS,
                         Pomiar,
                         s,
                         anRes.procedure = N_CommonTypes.pPromien,
                         TRUE,
                         0);
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
    Files.GetCommSigFName(Files.CS_GPS_GDOP,
                          Pomiar,
                          NazwaPliku);
    MakeHeader(header);
    IF NOT Print()
    THEN
      RETURN;
    END (* if *);
    OpisPomiaru;
    PiszEventy.PiszNaDrukarce(U_NDB,
                              anRes.procedure = N_CommonTypes.pPromien,
                              PiszEventy.TypyEventow {PoczatekPomiaru..
                              ZnacznikT});
  END MakeRaport;

END N_Print.

