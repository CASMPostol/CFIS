(*.F- *)
(**********************************************************************
|  Title   : Wyswietla rezultaty analizy dla GS
|  Author  : M.Postol
|  System  : LOGITECH MODULA-2/86
|  History :
|    07-11-96: M.Postol
|      Zabezpieczenia sa zrealizowane tak jak sektor
|    25-01-96: M.Postol
|      modyfikacja napisow, zmiany dla nowego def'a G_results
|    23-03-97: M.Postol
|      zmiana napisu, wywalono odcinki 150 i 180 w zabezpieczeniach 
|    25-03-97: M.Postol
|      polska litera
|
|  Copyright (C), CAS LODZ POLAND.
|  TEL: 42' 862 547, 42' 87 80 44 FAX/TEL: 42' 84 48 40
|
**********************************************************************)
(*.F+ *)

IMPLEMENTATION MODULE G_DisResults;

  IMPORT
    DisResUtilities;

  FROM DisResUtilities IMPORT
    ColNumT, WrS, INCLine, LineNumT, WrSPlus, WrF_TablicaOdci;

  FROM HiLevGraf IMPORT
    FillRect, WrStr;

  FROM GrafTypes IMPORT
    RECT, YELLOW, RED, BLUE, BROWN, LT_RED, LT_BLUE, GREEN, LT_GREEN, WHITE;

  FROM CommonTypes IMPORT
    GlownyOdbiornikT, ZoneBoundPt;

  FROM G_CommonTypes IMPORT
    (* TYPE *) ProceduraT;

  FROM L_CommonTypes IMPORT
    (* TYPE *) NumStrefy, NumPunktu, MkrLengthT,
    (* PROCEDURE *) GetNumStrefyEp;

  FROM ILS_ZoneMngmnt IMPORT
    zoneBDisIdx_T, L_LstPToBeTraced, G_LstZToBeTraced;

  FROM SpecConv IMPORT
    (* TYPE *) ToStringProcT,
    (* PROCEDURES *) Int100Str, Int2Str, Int10Str, Int500Str, Feed500Str,
                     Card500Str;

  FROM G_results IMPORT
    (* VAR *) anRes, SignalInSecDsc, SignalsRecDsc, DevValueTab;

  FROM HiLevGraf IMPORT
    WrStrXY;

  FROM NumberConversion IMPORT
    CardToString;

  FROM Strings IMPORT
    Insert, ConstAssign;

  FROM L_DataBase  IMPORT
    Lotnisko;

  CONST
    kolSN    = 2 * 160 + 30;  (* kolumna srodkowych napisow *)
    kolPT    = 32;  (* kolumna rozpoczecia wypisywania tekstu *)
    deltaKol = 160;  (* odleglosc pomiedzy kolumnami w tabelce *)
    NameStrL = 19;

  TYPE
    NameStr =
      ARRAY [0 .. NameStrL-1] OF CHAR;
    colRec =
      ARRAY GlownyOdbiornikT OF ColNumT;
  VAR
    colPos : colRec;

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
        WrStrXY("    WYNIKI DLA GS GOTOWE     ", NaglowekPX, lineH + 2, YELLOW
                , YELLOW);
        WrStrXY("TEO", 11 * 8 + 40, lineH + 2, YELLOW, YELLOW);
        WrStrXY("GPS", 11 * 8 + 40 + 3 * 160, lineH + 2, YELLOW, YELLOW);
        WrStrXY("ODB A", colPos[goA],
                lineH + Szerokosc * 4 DIV 3,
                LT_GREEN, LT_GREEN);
        WrStrXY("ODB B", colPos[goB],
                lineH + Szerokosc * 4 DIV 3,
                LT_RED, LT_RED);
    END (* case phase *);
  END WriteTab;

  PROCEDURE DispResults
            (    GlownyOdbiornik : GlownyOdbiornikT);
  VAR
    line : LineNumT;

    PROCEDURE WriteZoneDist
              (    zoneBDisIdx : zoneBDisIdx_T;
               VAR line        : LineNumT      );
    VAR
      znIdx : NumPunktu;
      str   : ARRAY[0..120] OF CHAR;
      tmp   : ARRAY[0..80] OF CHAR;
    BEGIN (* WriteZoneDist *)
      ConstAssign("Odlegˆo˜† p. A, B, C(TH) od THLD[NM] ", str);
      FOR znIdx := MIN(ZoneBoundPt) TO L_LstPToBeTraced() DO
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
    BEGIN
      Wr_SignalsRecDsc(signal, proc, line, colPos);
    END Wr_DevValueTab;

    PROCEDURE Wr_DevValueTab_WL
              (     name   : NameStr;
                    signal : DevValueTab;
                    proc   : ToStringProcT;
                VAR line   : LineNumT      );
    BEGIN
      WrS(name, line, kolSN);
      Wr_SignalsRecDsc(signal, proc, line, colPos);
      INCLine(line);
    END Wr_DevValueTab_WL;

    PROCEDURE Wr_Integer_WL
              (     name   : NameStr;
                    signal : INTEGER;
                    proc   : ToStringProcT;
                VAR line   : LineNumT      );
    VAR
      str : ARRAY [0 .. 50] OF CHAR;
    BEGIN
      WrS(name, line, kolSN);
      proc(signal, str, 5);
      WrS(str, line, colPos[goA]);
      INCLine(line);
    END Wr_Integer_WL;

    PROCEDURE Wr_SignalInSecDsc_WL
              (     name   : NameStr;
                    signal : SignalInSecDsc;
                    proc   : ToStringProcT;
                VAR line   : LineNumT       );
    VAR
      strefIdx : NumStrefy;

    BEGIN
      FOR strefIdx := MIN(NumStrefy) TO G_LstZToBeTraced() DO
        name[NameStrL - 2] := CHR(ORD(strefIdx) + ORD("1"));
        WrS(name, line, kolSN);
        Wr_DevValueTab(signal[strefIdx], proc, line);
        INCLine(line);
      END (* for strefIdx *);
    END Wr_SignalInSecDsc_WL;

    PROCEDURE An_AnalizaDsc
              ( VAR line : LineNumT );

    BEGIN
      WITH anRes DO
        Wr_SignalsRecDsc_WL('%MOD minimum    [%]', modMin_PO, Int10Str, line,
                            colPos);
        Wr_SignalsRecDsc_WL('%MOD ˜rednio    [%]', modAv_PO,  Int10Str, line,
                            colPos);
        Wr_SignalsRecDsc_WL('Sygnaˆ minimum [uV]', SSMin_PO,   Int2Str, line,
                            colPos);
        WrF_TablicaOdci("Zestawienie odcink¢w wyst¥pienia flagi [NM]", flagErr, 
                         line, ToStringProcT(Card500Str)); 
      END (* with anRes *);
    END An_AnalizaDsc;

    PROCEDURE An_OpisOsi
              ( VAR line : LineNumT );

    PROCEDURE An_MkrLength
              (     mkrLength : MkrLengthT;
                VAR line      : LineNumT   );

    BEGIN
      WITH mkrLength DO
        Wr_SignalsRecDsc_WL('Marker zew. flg[ft]', oMkrL_OM, Feed500Str, line,
                            colPos);
        Wr_SignalsRecDsc_WL('Marker ˜rod.flg[ft]', mMkrL_OM, Feed500Str, line,
                            colPos);
        Wr_SignalsRecDsc_WL('Marker wew. flg[ft]', iMkrL_OM, Feed500Str, line,
                            colPos);
        (* na podstawie uzgodnien z Pawel Szpakowski 11-08-2000
        Wr_SignalsRecDsc_WL('Marker zew. agc[ft]', oMkrA_OM, Feed500Str, line,
                            colPos);
        Wr_SignalsRecDsc_WL('Marker ˜rod.agc[ft]', mMkrA_OM, Feed500Str, line,
                            colPos);
        Wr_SignalsRecDsc_WL('Marker wew. agc[ft]', iMkrA_OM, Feed500Str, line,
                            colPos);
        *)
      END (* with mkrLength *);
    END An_MkrLength;

    BEGIN
      WITH anRes.an_OpisOsi DO
        Wr_SignalInSecDsc_WL('K¥t ˜redni  [ø] {x}', azAv_PO,      Int100Str, line);
        Wr_SignalInSecDsc_WL('K¥t max     [ø] {x}', azMax_PO,     Int100Str, line);
        Wr_SignalInSecDsc_WL('K¥t min     [ø] {x}', azMin_PO,     Int100Str, line);
        Wr_SignalInSecDsc_WL('Bˆ¥d max   [uA] {x}', difMax_PO,    Int10Str, line);
        Wr_SignalInSecDsc_WL('Bˆ¥d min   [uA] {x}', difMin_PO,    Int10Str, line);
        Wr_DevValueTab_WL(   'Bˆ¥d ustawienia[uA]', alig_PO,      Int10Str,  line);
        Wr_SignalInSecDsc_WL('Przekrocz.  [%] {x}', roughness_PO, Int10Str,  line);
        An_MkrLength(mkrLength, line);
        WriteZoneDist(zonesBeg, line);
      END (* with anRes.an_OpisOsi *);
    END An_OpisOsi;

    PROCEDURE An_OpisSektora
              ( VAR line : LineNumT );

    BEGIN
      WITH anRes.an_OpisSektora DO
        Wr_SignalInSecDsc_WL('K¥t max      [ø]{x}', AzMax_OS, Int100Str, line);
        Wr_SignalInSecDsc_WL('K¥t min      [ø]{x}', AzMin_OS, Int100Str, line);
        Wr_SignalInSecDsc_WL('K¥t ˜redni   [ø]{x}', AzAv_OS,  Int100Str, line);
        Wr_DevValueTab_WL(   'Szer. sektora[ø]{2}', Chi_OS,   Int100Str, line);
        Wr_DevValueTab_WL(   'Symetria     [%]{2}', Phi_OS,   Int10Str,  line);
        WriteZoneDist(zonesBeg_OS, line)
      END (* with anRes.an_OpisSektora *);
    END An_OpisSektora;

    PROCEDURE An_OpisProfilB
              ( VAR line : LineNumT );

    BEGIN
      WITH anRes.an_OpisProfilB DO
        Wr_DevValueTab_WL('K¥t ˜cie¾ki     [ø]', az0_PB,        Int100Str, line);
        Wr_DevValueTab_WL('Gran.sektor/g¢ra[ø]', az75_G_PB,     Int100Str, line);
        Wr_DevValueTab_WL('Gran.sektor/d¢ˆ [ø]', az75_D_PB,     Int100Str, line);
        Wr_DevValueTab_WL('Szeroko˜† sek.  [ø]', Chi_PB,        Int100Str, line);
        Wr_DevValueTab_WL('Symetria  sek.  [%]', Phi_PB,        Int10Str,  line);
        Wr_DevValueTab_WL('K¥t dla 150/g¢ra[ø]', az150_G_PB,    Int100Str,  line);
        Wr_DevValueTab_WL('K¥t dla 190/d¢ˆ [ø]', az190_D_PB,    Int100Str,  line);
        Wr_Integer_WL    ('Wysoko˜† ˜red. [ft]', WysokoscAv_PB, Int2Str, line);
      END (* with anRes.an_OpisProfilB *);
    END An_OpisProfilB;

    PROCEDURE An_OpisBadDod
              ( VAR line : LineNumT );

    BEGIN
      WITH anRes.an_OpisBadDod DO
        Wr_SignalsRecDsc_WL('Dewiacja ˜red. [uA]', dewAv, Int10Str, line, colPos);
      END (* with anRes.an_OpisBadDod *);
    END An_OpisBadDod;

    PROCEDURE An_OpisZabezpieczenie 
              ( VAR line : LineNumT );
    BEGIN
      WITH anRes.an_OpisZabezpieczenie DO
        Wr_SignalInSecDsc_WL('K¥t dla 180/d¢ˆ [ø]', az180Av, Int100Str, line);
        WriteZoneDist(zonesBeg_OZ, line); 
      END;
    END An_OpisZabezpieczenie;
    
    PROCEDURE An_OpisPokrycia
              ( VAR line : LineNumT );

    BEGIN
      WITH anRes.an_OpisPokrycia DO
        WrF_TablicaOdci("Zestawienie odcink¢w dla syg.<20 uV [NM]", odcinki_20uV, 
                         line, ToStringProcT(Card500Str)); 
      END (* with anRes.an_OpisZasiegSzer *);
    END An_OpisPokrycia;

  BEGIN (* DispResults *)
    WriteTab(2, line);
    WITH anRes DO
      CASE procedure OF
        pUstawienieOsi_Struktura, pAlarmOsi, pUstawienieOsi_Szer_pA,
        pUstawienieOsi_Waski_pA :
          An_OpisOsi(line);
        |
        pSzerSektora_pA, pAlarmSzeroki_pA, pAlarmWaski_pA :
          An_OpisSektora(line);
        |
        pSzer_i_Osi_pB, pAlarmSzer_pB, pAlarmWaski_pB:
          An_OpisProfilB(line);
        |
        pRownowagaModulacji, pFazowanie :
          An_OpisBadDod(line);
        |
        pZabezpieczenie:
          An_OpisZabezpieczenie(line);
        |
        pPokrycieWOsi, pPokrycie8stP, pPokrycie8stL :
          An_OpisPokrycia(line);
      END
    END (* case procedura *);
    An_AnalizaDsc(line);
  END DispResults;

BEGIN
  colPos[ goA ] := kolPT;
  colPos[ goB ] := kolPT + deltaKol;
END G_DisResults.
