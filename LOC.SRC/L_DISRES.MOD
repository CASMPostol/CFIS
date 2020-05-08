(*.F- *)
(**********************************************************************
|  Title   : Wyswietla rezultaty analizy dla LOC
|  Author  : M.Postol
|  System  : LOGITECH MODULA-2/86
|  History :
|    23-03-97: M.Postol
|      zmiana napisu w WriteZoneDist
|    24-03-97: M.Postol
|      na ekranie w pomiarach osi jest dodatkowo wypisywany kat osi w 
|      2 strefie
|    07-05-97: M.Postol
|      analiza flagi byla robiona tylko wzgledem odleglosci
|
|  Copyright (C), CAS LODZ POLAND.
|  TEL: 42' 862 547, 42' 87 80 44 FAX/TEL: 42' 84 48 40
|
**********************************************************************)
(*.F+ *)

IMPLEMENTATION MODULE L_DisResults;

  IMPORT
    DisResUtilities;

  FROM DisResUtilities IMPORT
    ColNumT, WrS, INCLine, WrF_TablicaOdci, LineNumT;

  FROM GrafTypes IMPORT
    RECT, YELLOW, RED, BLUE, BROWN, LT_RED, LT_BLUE, GREEN, LT_GREEN, WHITE;

  FROM CommonTypes IMPORT
    GlownyOdbiornikT, OdnDlaPomBleduT, ZoneBoundPt;

  FROM L_CommonTypes IMPORT
    (* TYPE *) SignalsRecDsc, SignalInSecDsc, DevValueTab,
               MkrLengthT, ProceduraT, NumStrefy;

  FROM ILS_ZoneMngmnt IMPORT
    zoneBDisIdx_T, L_LstPToBeTraced, L_LstZToBeTraced;
    
  FROM SpecConv IMPORT
    (* TYPE *) ToStringProcT,
                     Int100Str, Int2Str, Int10Str, Feed500Str,
                     Card500Str;

  FROM L_results IMPORT
    (* VAR *) anRes;

  FROM HiLevGraf IMPORT
    WrStrXY;

  FROM Strings IMPORT
    Insert, ConstAssign;
    
  FROM L_DataBase  IMPORT
    Lotnisko;
    
  FROM ILS_ZoneMngmnt IMPORT
    SetLastPointToBeTraced;
  
  CONST
    kolSN    = 2 * 160 + 30;  (* kolumna srodkowych napisow *)
    kolPT    = 32;  (* kolumna rozpoczecia wypisywania tekstu *)
    deltaKol = 160;  (* odleglosc pomiedzy kolumnami w tabelce *)
    NameStrL = 19;

  TYPE
    colRec =
      ARRAY GlownyOdbiornikT OF ColNumT;
    colRef =
      ARRAY OdnDlaPomBleduT OF colRec;
    NameStr =
      ARRAY [0 .. NameStrL-1] OF CHAR;

  VAR
    colPos  : colRef;
    
  PROCEDURE WriteTab
            (     phase : CARDINAL;
              VAR line  : LineNumT );

  CONST
    Szerokosc  = 16;
    NaglowekPX = 2 * 160;
  VAR
    lineH : LineNumT;
    col   : CARDINAL;

  BEGIN
    DisResUtilities.WriteTab(lineH, line);
    CASE phase OF
      0 :
        WrStrXY("TRWA ANALIZA DANYCH Z POMIARU", NaglowekPX, lineH + 2, YELLOW
                , YELLOW);
      |
      1 :
        WrStrXY("TRWA ANALIZA DANYCH FAZA 2 z 3", NaglowekPX, lineH + 2, YELLOW
                , YELLOW);
      |
      2 :
        WrStrXY("    WYNIKI DLA LOC GOTOWE     ", NaglowekPX, lineH + 2, YELLOW
                , YELLOW);
        WrStrXY("TEO", 11 * 8 + 40, lineH + 2, YELLOW, YELLOW);
        WrStrXY("GPS", 11 * 8 + 40 + 3 * 160, lineH + 2, YELLOW, YELLOW);
        FOR col := 0 TO 1 DO
          WrStrXY("ODB A", 40 + col * (3 * 160), 
                  lineH + Szerokosc * 4 DIV 3,
                  LT_GREEN, LT_GREEN);
          WrStrXY("ODB B", 40 + 8 * 19 + col * (3 * 160), 
                  lineH + Szerokosc * 4 DIV 3, 
                  LT_RED, LT_RED);
        END (* for col *)
    END (* case phase *);
  END WriteTab;

  PROCEDURE DispResults
            (    GlownyOdbiornik : GlownyOdbiornikT;
                 OdnDlaPomBledu  : OdnDlaPomBleduT  );
  VAR
    line : LineNumT;

    PROCEDURE WriteZoneDist
              (    zoneBDisIdx : zoneBDisIdx_T;
               VAR line        : LineNumT      );
    VAR
      znIdx : ZoneBoundPt;
      str   : ARRAY[0..120] OF CHAR;
      tmp   : ARRAY[0..80] OF CHAR;
    BEGIN (* WriteZoneDist *)
      ConstAssign("Odleglo˜† p. A, B, C(TH), D, E od ANT [NM] ", str);
      FOR znIdx := MIN(ZoneBoundPt)  TO L_LstPToBeTraced() DO
        IF znIdx = np_CorT THEN
          tmp := " C(TH)";
        ELSE
          tmp := '  ';
          tmp[1] := CHR(ORD('A')+ORD(znIdx)-1);
        END;
        Insert(tmp, str, 1000);
        Insert(': ', str, 1000);
        Card500Str(zoneBDisIdx[znIdx], tmp, 5);
        Insert(tmp, str, 1000);
      END;
      WrS(str, line, 0);
      INCLine(line);
    END WriteZoneDist;
    
    PROCEDURE Wr_SignalsRecDsc
              (    signal : SignalsRecDsc;
                   proc   : ToStringProcT;
                   line   : LineNumT;
                   col    : colRec        );
    VAR
      rec : GlownyOdbiornikT;
      str : ARRAY [0 .. 50] OF CHAR;

    BEGIN
      FOR rec := goA TO goB DO
        proc(signal[rec].val, str, 5);
        WrS(str, line, col[rec]);
      END (* for rec *);
    END Wr_SignalsRecDsc;

    PROCEDURE Wr_SignalsRecDsc_WL
              (    name   : NameStr;
                   signal : SignalsRecDsc;
                   proc   : ToStringProcT;
               VAR line   : LineNumT;
                   col    : colRec        );
    VAR
      rec : GlownyOdbiornikT;
      str : ARRAY [0 .. 50] OF CHAR;

    BEGIN
      WrS(name, line, kolSN);
      FOR rec := goA TO goB DO
        proc(signal[rec].val, str, 5);
        WrS(str, line, col[rec]);
      END (* for rec *);
      INCLine(line);
    END Wr_SignalsRecDsc_WL;

    PROCEDURE Wr_DevValueTab
              (    signal : DevValueTab;
                   proc   : ToStringProcT;
                   line   : LineNumT      );
    VAR
      ref : OdnDlaPomBleduT;

    BEGIN
      FOR ref := pbTeodolit TO pbGPS DO
        Wr_SignalsRecDsc(signal[ref], proc, line, colPos[ref]);
      END (* for ref *);
    END Wr_DevValueTab;

    PROCEDURE Wr_DevValueTab_WL
              (     name   : NameStr;
                    signal : DevValueTab;
                    proc   : ToStringProcT;
                VAR line   : LineNumT      );
    VAR
      ref : OdnDlaPomBleduT;

    BEGIN
      WrS(name, line, kolSN);
      FOR ref := pbTeodolit TO pbGPS DO
        Wr_SignalsRecDsc(signal[ref], proc, line, colPos[ref]);
      END (* for ref *);
      INCLine(line);
    END Wr_DevValueTab_WL;

    PROCEDURE Wr_SignalInSecDsc_WL
              (     name   : NameStr;
                    signal : SignalInSecDsc;
                    proc   : ToStringProcT;
                VAR line   : LineNumT       );
    VAR
      strefIdx : NumStrefy;

    BEGIN
      FOR strefIdx := MIN(NumStrefy) TO L_LstZToBeTraced() DO
        name[NameStrL - 2] := CHR(ORD(strefIdx) + ORD("1"));
        WrS(name, line, kolSN);
        Wr_DevValueTab(signal[strefIdx], proc, line);
        INCLine(line);
      END (* for strefIdx *);
    END Wr_SignalInSecDsc_WL;

    PROCEDURE An_MkrLength
              (     mkrLength : MkrLengthT;
                VAR line      : LineNumT   );

    BEGIN
      WITH mkrLength DO
        Wr_SignalsRecDsc_WL('Marker zew. flg[ft]', oMkrL_OM, Feed500Str, line,
                            colPos[pbTeodolit]);
        Wr_SignalsRecDsc_WL('Marker ˜rod.flg[ft]', mMkrL_OM, Feed500Str, line,
                            colPos[pbTeodolit]);
        Wr_SignalsRecDsc_WL('Marker wew. flg[ft]', iMkrL_OM, Feed500Str, line,
                            colPos[pbTeodolit]);
        Wr_SignalsRecDsc_WL('Marker zew. agc[ft]', oMkrA_OM, Feed500Str, line,
                            colPos[pbTeodolit]);
        Wr_SignalsRecDsc_WL('Marker ˜rod.agc[ft]', mMkrA_OM, Feed500Str, line,
                            colPos[pbTeodolit]);
        Wr_SignalsRecDsc_WL('Marker wew. agc[ft]', iMkrA_OM, Feed500Str, line,
                            colPos[pbTeodolit]);
      END (* with mkrLength *);
    END An_MkrLength;

    PROCEDURE An_AnalizaDsc
              ( VAR line          : LineNumT;
                    toStringProcT : ToStringProcT );

    BEGIN
      WITH anRes DO
        Wr_SignalsRecDsc_WL('%MOD minimum    [%]', modLocMin_PO, Int10Str, line,
                            colPos[pbTeodolit]);
        Wr_SignalsRecDsc_WL('%MOD ˜rednio    [%]', modLocAv_PO,  Int10Str, line,
                            colPos[pbTeodolit]);
        Wr_SignalsRecDsc_WL('Sygnaˆ min     [uV]', SSMin_PO,     Int2Str, line,
                            colPos[pbTeodolit]);
        WrF_TablicaOdci("Zestawienie odcink¢w wyst¥pienia flagi", flagErr, 
                         line, toStringProcT ); 
      END (* with anRes *);
    END An_AnalizaDsc;

    PROCEDURE An_OpisOsi
              ( VAR line : LineNumT );

    BEGIN
      WITH anRes.an_OpisOsi DO
        Wr_SignalInSecDsc_WL('Bˆ¥d ˜redni[uA] {x}', difAv_PO,     Int10Str, line);
        Wr_DevValueTab_WL(   'Bˆ¥d max   [uA] {2}', difMax_PO[ns_AB], Int10Str, line);
        Wr_DevValueTab_WL(   'Bˆ¥d min   [uA] {2}', difMin_PO[ns_AB], Int10Str, line);
        Wr_DevValueTab_WL(   'Bˆ¥d ustawienia[uA]', alig_PO,          Int10Str, line);
        Wr_DevValueTab_WL(   'K¥t osi     [ø] {2}', AzAv_PO[ns_AB],   Int100Str, line);
        Wr_DevValueTab_WL(   'Bˆ¥d ust.[uA]{1..5}', difAvTotal_PO,Int10Str, line);
        Wr_SignalInSecDsc_WL('Przekrocz.  [%] {x}', roughness_PO, Int10Str, line);
        Wr_DevValueTab_WL(   'Polaryzacja lw [uA]', difAvPolL_PO, Int10Str, line);
        Wr_DevValueTab_WL(   'Polaryzacja pw [uA]', difAvPolR_PO, Int10Str, line);
        WriteZoneDist(zonesBeg, line);
        An_MkrLength(mkrLength, line);
      END (* with anRes.an_OpisOsi *);
    END An_OpisOsi;

    PROCEDURE An_OpisSektora
              ( VAR line : LineNumT );

    BEGIN
      WITH anRes.an_OpisSektora DO
        Wr_SignalInSecDsc_WL('K¥t max    [ø]  {x}', AzMax_OSA, Int100Str, line);
        Wr_SignalInSecDsc_WL('K¥t min    [ø]  {x}', AzMin_OSA, Int100Str, line);
        Wr_SignalInSecDsc_WL('K¥t ˜redni [ø]  {x}', AzAv_OS, Int100Str, line);
        Wr_DevValueTab_WL(   'Szeroko˜† sek.  [ø]', ChiLoc, Int100Str, line);
        Wr_DevValueTab_WL(   'Symetria        [%]', PhiLoc, Int10Str, line);
        WriteZoneDist(zonesBeg, line)
      END (* with anRes.an_OpisSektora *);
    END An_OpisSektora;

    PROCEDURE An_OpisProfilB
              ( VAR line : LineNumT );

    BEGIN
      WITH anRes.an_OpisProfilB DO
        Wr_DevValueTab_WL('Bˆ¥d ustawienia[uA]', difAv0_PB,   Int10Str,  line);
        Wr_DevValueTab_WL('K¥t ust osi    [ ø]', az0_PB,      Int100Str, line);
        Wr_DevValueTab_WL('Sektor/150     [ ø]', az150_150_PB,Int100Str, line);
        Wr_DevValueTab_WL('Sektor/ 90     [ ø]', az150_90_PB, Int100Str, line);
        Wr_DevValueTab_WL('Szeroko˜†      [ ø]', ChiLoc,      Int100Str, line);
        Wr_DevValueTab_WL('Symetria       [ %]', PhiLoc,      Int10Str,  line);
        Wr_DevValueTab_WL('Wyraz. L175Mn  [ ø]', H175Mn,      Int100Str, line);
        Wr_DevValueTab_WL('Wyraz. L175Mx  [ ø]', H175Mx,      Int100Str, line);
        Wr_DevValueTab_WL('Wyraz. L150    [ ø]', H150mn,      Int100Str, line);
        Wr_DevValueTab_WL('Wyraz. P175Mn  [ ø]', HM175Mn,     Int100Str, line);
        Wr_DevValueTab_WL('Wyraz. P175Mx  [ ø]', HM175Mx,     Int100Str, line);
        Wr_DevValueTab_WL('Wyraz. P150    [ ø]', HM150mn,     Int100Str, line);
      END (* with anRes.an_OpisProfilB *);
    END An_OpisProfilB;

    PROCEDURE An_OpisBadDod
              ( VAR line : LineNumT );

    BEGIN
      WITH anRes.an_OpisBadDod DO
        Wr_SignalsRecDsc_WL('Dewiacja ˜red. [uA]', dewAv, Int10Str, line, 
                            colPos[pbTeodolit]);
      END (* with anRes.an_OpisBadDod *);
    END An_OpisBadDod;

    PROCEDURE An_OpisZasieg_do_10
              ( VAR line : LineNumT );

    BEGIN
      WITH anRes.an_OpisZasieg_do_10 DO
        Wr_DevValueTab_WL('Sygn. min+/-10ø[uV]', sS0_Min_ZW, Int2Str, line);
      END (* with anRes.an_OpisZasieg_do_10 *);
    END An_OpisZasieg_do_10;

    PROCEDURE An_OpisZasiegSzer
              ( VAR line : LineNumT );

    BEGIN
      WITH anRes.an_OpisZasiegSzer DO
        Wr_DevValueTab_WL('Sygn. min/150  [uV]', sS150_Min_ZS, Int2Str, line);
        Wr_DevValueTab_WL('Sygn. min/ 90  [uV]', sS90_Min_ZS,  Int2Str, line);
      END (* with anRes.an_OpisZasiegSzer *);
    END An_OpisZasiegSzer;

    PROCEDURE An_OpisMarker
              ( VAR line : LineNumT );

    BEGIN
      WITH anRes.an_OpisMarker DO
        An_MkrLength(mkrLength, line);
      END (* with anRes.an_OpisMarker *);
    END An_OpisMarker;

  BEGIN (* DispResults *)
    SetLastPointToBeTraced( Lotnisko.Kategoria, TRUE );
    WriteTab(2, line);
    WITH anRes DO
      CASE procedure OF
        pUstawienieOsi_Struktura, pAlarmOsi, pUstawienieOsi_Szer_pA,
        pUstawienieOsi_Waski_pA :
          An_OpisOsi(line);
          An_AnalizaDsc(line,  ToStringProcT(Card500Str));
        |
        pSzerSektora_pA, pAlarmSzeroki_pA, pAlarmWaski_pA :
          An_OpisSektora(line);
          An_AnalizaDsc(line,  ToStringProcT(Card500Str));
        |
        pSzer_i_Osi_pB, pAlarmSzer_pB, pAlarmWaski_pB, 
        pWyrazistosc_na_d_katach:
          An_OpisProfilB(line);
          An_AnalizaDsc(line,  Int100Str);
        |
        pRownowagaModulacji, pFazowanie :
          An_OpisBadDod(line);
          An_AnalizaDsc(line,  ToStringProcT(Card500Str));
        |
        pZasieg_do_10 :
          An_OpisZasieg_do_10(line);
          An_AnalizaDsc(line,  Int100Str);
        |
        pZasieg_10_35, pZasieg_ponad_35 :
          An_OpisZasiegSzer(line);
          An_AnalizaDsc(line,  Int100Str);
        |
        pMarker :
          An_OpisMarker(line);
          An_AnalizaDsc(line,  ToStringProcT(Card500Str));
      END (* case procedure *);
    END (* case procedura *);
  END DispResults;

BEGIN
  colPos[pbTeodolit, goA] := kolPT;
  colPos[pbTeodolit, goB] := kolPT + deltaKol;
  colPos[pbGPS, goA] := kolPT + 3 * deltaKol;
  colPos[pbGPS, goB] := colPos[pbGPS, goA] + deltaKol;
END L_DisResults.
