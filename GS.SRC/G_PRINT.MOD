(*.F- *)
(**********************************************************************
|  Title   : Drukowanie raportow dla GS
|  Author  : M.Morawski
|  System  : LOGITECH MODULA-2/86
|  History :
|    24-07-96:M.Postol
|      bardzo wiele zmian
|    07-11-96: M.Postol
|      bledy OpisSektoraP
|    11-09-97: M.Postol
|      zmienilem skale dla GS.SS i MKR.SS na 5000 zgodnie ze specyfikacja
|      blad w SzSekt
|    31-12-97: TOMEK
|      zmieniono wykresy EPE na GDOP
|    Rel. 3.0: MPostol
|      Dostosowalem do nowej definicji Czas
|    Rel. 3.14: MPostol
|      Kosmetyczne zmiany dla wydruku
|
|  Copyright (C), CAS LODZ POLAND.
|  TEL: 42' 686 25 47
|  mailto: techsupp@cas.com.pl
|  http: www.cas.com.pl
|
**********************************************************************)
(*.F+ *)

IMPLEMENTATION MODULE G_Print;

  FROM EventsMng IMPORT
    EventKind, RodzUrzadzenia;

  IMPORT
    DrawEpson, Strings, SYSTEM, StdIO, PiszEventy, G_results,
    SpecConv, Files, G_CommonTypes;

  FROM G_results IMPORT
    SignalInSecDsc, anRes;

  FROM Print IMPORT
    (* CONST *) StyleSep, PASEK, SKALA_X, SKALA_X_90, SKALA_Y_90,
    (* TYPE *) Desc,
    (* VAR *) PolozenieNapisu, PrnX, PrnY,
    (* PROCEDURE *) MaxY, WrPrn, WrLn, WrPrnLn, InitA, InitB, Point, Opis,
                    CloseAll, InitAll, EvProc, ZnacznikiOdleglosci,
                    WrF_TablicaOdci, WypiszStrefy;

  FROM G_Files IMPORT
    (* TYPE *) Signals, resultT,
    (* PROCEDURE *) GetSigFileName, GetResFileName;

  FROM CommonTypes IMPORT
    OdnDlaPomBleduT, GlownyOdbiornikT, 
    Com_Aud_flg, GPS_flg, GSA_flg, GSB_flg, 
    oMkrFlgPosA, mMkrFlgPosA, iMkrFlgPosA, oMkrFlgPosB, mMkrFlgPosB,
    iMkrFlgPosB, GetTranName, GetRecName;

  FROM L_CommonTypes IMPORT
    NumStrefy, SignalDsc, MkrLengthT;

  FROM PrintCntroll IMPORT
    UstalSkalowanie;

  FROM L_DataBase IMPORT
    Lotnisko;

  FROM Czas IMPORT
    ConvertToStr;
    
  FROM MathLib0 IMPORT
    entier;
    
  TYPE
    Descs  =
      ARRAY [0 .. 18] OF Desc;
    Str100 =
      ARRAY [0 .. 100] OF CHAR;
    str8   =
      ARRAY [0 .. 7] OF CHAR;

  CONST
    agcG_SgMax       = 5000;
    agcM_SgMax       = 5000;
    Pomiar           = FALSE;
    Format360        = FALSE;
    CzyToJestPromien = TRUE;
    locANieGs        = FALSE;

  VAR
    SigNam     : ARRAY Signals, GlownyOdbiornikT OF str8;
    Zestaw     : CARDINAL;
    header     : Str100;
    NazwaPliku : ARRAY [0 .. 30] OF CHAR;

  VAR
    GSG_flg      : CARDINAL;
    GSZ_flg      : CARDINAL;
    Zew_Marker_G : CARDINAL;
    Srd_Marker_G : CARDINAL;
    Wew_Marker_G : CARDINAL;
    Zew_Marker_Z : CARDINAL;
    Srd_Marker_Z : CARDINAL;
    Wew_Marker_Z : CARDINAL;
  VAR
    gOdb,
    zOdb   : GlownyOdbiornikT;
  
  PROCEDURE NazwaProcedury
            (     Procedura : G_CommonTypes.ProceduraT;
                  Strona    : G_CommonTypes.StronaT;
              VAR str       : ARRAY OF CHAR            );
  VAR
    str_str : ARRAY G_CommonTypes.StronaT OF ARRAY [0 .. 31] OF CHAR;
    str_adr : SYSTEM.ADDRESS;

  BEGIN
    str_str[G_CommonTypes.Gora] := 'g¢ra';
    str_str[G_CommonTypes.Dol] := 'd¢ˆ';
    str_adr := SYSTEM.ADR(str_str[Strona]);
    CASE Procedura OF
      G_CommonTypes.pAlarmOsi :
        StdIO.sprintf(str,
                      'Alarm k¥ta %s',
                      str_adr);
      |
      G_CommonTypes.pSzerSektora_pA :
        StdIO.sprintf(str,
                      'Sektor (A) %s',
                      str_adr);
      |
      G_CommonTypes.pAlarmSzeroki_pA :
        StdIO.sprintf(str,
                      'Sektor alarm szeroki (A) %s',
                      str_adr);
      |
      G_CommonTypes.pAlarmWaski_pA :
        StdIO.sprintf(str,
                      'Sektor alarm w¥ski (A) %s',
                      str_adr);
      |
      G_CommonTypes.pUstawienieOsi_Struktura :
        Strings.ConstAssign('K¥t struktura', str);
      |
      G_CommonTypes.pUstawienieOsi_Szer_pA :
        Strings.ConstAssign('K¥t alarm szeroki (A)',
                            str);
      |
      G_CommonTypes.pUstawienieOsi_Waski_pA :
        Strings.ConstAssign('K¥t alarm w¥ski (A)',
                            str);
      |
      G_CommonTypes.pSzer_i_Osi_pB :
        Strings.ConstAssign('K¥t sektor (B)',
                            str);
      |
      G_CommonTypes.pAlarmSzer_pB :
        Strings.ConstAssign('K¥t sektor alarm szeroki (B)',
                            str);
      |
      G_CommonTypes.pAlarmWaski_pB :
        Strings.ConstAssign('K¥t sektor alarm w¥ski i (B)',
                            str);
      |
      G_CommonTypes.pRownowagaModulacji :
        Strings.ConstAssign('R¢wnowaga modulacji',
                            str);
      |
      G_CommonTypes.pFazowanie :
        Strings.ConstAssign('Fazowanie',
                            str);
      |
      G_CommonTypes.pZabezpieczenie :
        Strings.ConstAssign('Zabezpieczenie',
                            str);
      |
      G_CommonTypes.pPokrycieWOsi :
        Strings.ConstAssign('Pokrycie w osi',
                            str);
      |
      G_CommonTypes.pPokrycie8stP :
        Strings.ConstAssign('Pokrycie 8ø z prawej',
                            str);
      |
      G_CommonTypes.pPokrycie8stL :
        Strings.ConstAssign('Pokrycie 8ø z lewej',
                            str);
    END (* case Procedura *);
  END NazwaProcedury;

  PROCEDURE MakeHeader
            ( VAR str : ARRAY OF CHAR );
  VAR
    tmp  : ARRAY [0 .. 50] OF CHAR;
    tmpA : SYSTEM.ADDRESS;
    odbN     : ARRAY [0 .. 15] OF CHAR;
    tmpOdb   : SYSTEM.ADDRESS;
    tranN    : ARRAY [ 0 .. 6] OF CHAR;
    dataStr  : ARRAY [ 0 .. 20] OF CHAR;
    data_adr : SYSTEM.ADDRESS;

  BEGIN
    WITH G_results.anRes DO
      NazwaProcedury(procedure,
                     strona,
                     tmp);
      tmpA := SYSTEM.ADR(tmp);
      GetTranName(tranN, nadajnik);
      GetRecName(odbN, gOdb);
      Strings.Concat(odbN, ' ', odbN);
      Strings.Concat(odbN, tranN, odbN);
      ConvertToStr(data, FALSE, dataStr);
      tmpOdb    := SYSTEM.ADR(odbN);
      data_adr  := SYSTEM.ADR(dataStr);
      StdIO.sprintf3(str,
                     " GS ¯%s® OdbG:%s; Pomiar wyk: %s",
                     tmpA,
                     tmpOdb,
                     data_adr);
      Strings.Insert(Nazwa,
                     str,
                     0);
    END (* if PromienANieOrbita *);
  END MakeHeader;

  PROCEDURE OpisPomiaru();

    PROCEDURE PrintStdValues(  ) : BOOLEAN;
      BEGIN
        IF NOT WrPrnLn( 0, "Wyniki dla caˆego pomiaru" ) THEN
          RETURN FALSE;
        END;
        IF NOT WrSignDesc("Mod minimum [%]",
                          SpecConv.Int10Str,
                          G_results.anRes.modMin_PO)
        THEN
          RETURN FALSE;
        END (* if *);
        IF NOT WrSignDesc("Mod ˜rednia [%]",
                          SpecConv.Int10Str,
                          G_results.anRes.modAv_PO)
        THEN
          RETURN FALSE;
        END (* if *);
        IF NOT WrSignDesc("SS minimum [uV]",
                          SpecConv.Int2Str,
                          G_results.anRes.SSMin_PO)
        THEN
          RETURN FALSE;
        END (* if *);
        IF NOT WrLn() THEN
          RETURN FALSE;
        END;
        RETURN TRUE;
      END PrintStdValues;

    PROCEDURE WrSignDesc1
              (     zapas : BOOLEAN;
                    Conv  : SpecConv.ToStringProcT;
                    str   : ARRAY OF CHAR;
                VAR d     : SignalDsc              ) : BOOLEAN;
    VAR
      s : ARRAY [0 .. 30] OF CHAR;

    BEGIN
      IF NOT zapas
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
      END (* if *);
      Conv(d.val,
           s,
           5);
      IF NOT WrPrn(20,
                   s)
      THEN
        RETURN FALSE;
      END (* if *);
      IF zapas
      THEN
        IF NOT WrLn()
        THEN
          RETURN FALSE;
        END (* if *);
      END (* if zapas *);
      RETURN TRUE;
    END WrSignDesc1;

    PROCEDURE WrSignDesc
              (     str  : ARRAY OF CHAR;
                    Conv : SpecConv.ToStringProcT;
                VAR A    : ARRAY OF SignalDsc     ) : BOOLEAN;
    VAR
      i : BOOLEAN;

    BEGIN
      FOR i := FALSE TO TRUE DO
        IF NOT WrSignDesc1(i,
                           Conv,
                           str,
                           A[ORD(i)])
        THEN
          RETURN FALSE;
        END (* if *);
      END (* for i *);
      RETURN TRUE;
    END WrSignDesc;

    PROCEDURE LstZToBeTraced(  ) : NumStrefy;
      BEGIN
        RETURN ns_BCorT;
      END LstZToBeTraced;

    PROCEDURE WrSectSignDesc
              (     str  : ARRAY OF CHAR;
                    Conv : SpecConv.ToStringProcT;
                VAR ssd  : SignalInSecDsc         ) : BOOLEAN;
    VAR
      nap : ARRAY [0 .. 127] OF CHAR;
      i   : NumStrefy;
      sec : INTEGER;

    BEGIN
      IF NOT WrPrnLn(0,
                     str)
      THEN
        RETURN FALSE;
      END (* if *);
      FOR i := MIN(NumStrefy) TO LstZToBeTraced() DO
        sec := ORD(i) + 1;
        StdIO.sprintf(nap, " Strefa nr. %d", sec);
        IF NOT WrSignDesc(nap, Conv, ssd[i])
        THEN
          RETURN FALSE;
        END (* if *);
      END (* for i *);
      RETURN TRUE;
    END WrSectSignDesc;

    PROCEDURE MarkerLength
              (    mkrLength : MkrLengthT ) : BOOLEAN;

      PROCEDURE WrSignDesc1
                (    Conv : SpecConv.ToStringProcT;
                      str  : ARRAY OF CHAR;
                      d1   : SignalDsc;
                      d2   : SignalDsc              ) : BOOLEAN;
      VAR
        s : ARRAY [0 .. 30] OF CHAR;

      BEGIN
        IF NOT WrPrn(0,
                      str)
        THEN
          RETURN FALSE;
        END (* if *);
        IF NOT WrPrn(17,
                      '³')
        THEN
          RETURN FALSE;
        END (* if *);
        Conv(d1.val,
              s,
              5);
        IF NOT WrPrn(22,
                      s)
        THEN
          RETURN FALSE;
        END (* if *);
        IF NOT WrPrn(35,
                      '³')
        THEN
          RETURN FALSE;
        END (* if *);
        Conv(d2.val,
              s,
              5);
        IF NOT WrPrn(40,
                      s)
        THEN
          RETURN FALSE;
        END (* if *);
        IF NOT WrLn()
        THEN
          RETURN FALSE;
        END (* if *);
        RETURN TRUE;
      END WrSignDesc1;

    BEGIN
      IF NOT WrPrnLn( 0, "Dˆugo˜ci marker¢w [ft]" ) THEN
        RETURN FALSE;
      END;
      WITH mkrLength DO
        IF NOT WrSignDesc1(SpecConv.Feed500Str,
                           '  zewn. flg',
                           oMkrL_OM[goA],
                           oMkrL_OM[goB])
        THEN
          RETURN FALSE;
        END (* if *);
        IF NOT WrSignDesc1(SpecConv.Feed500Str,
                           '  ˜rod. flg',
                           mMkrL_OM[goA],
                           mMkrL_OM[goB])
        THEN
          RETURN FALSE;
        END (* if *);
        IF NOT WrSignDesc1(SpecConv.Feed500Str,
                           '  wewn. flg',
                           iMkrL_OM[goA],
                           iMkrL_OM[goB])
        THEN
          RETURN FALSE;
        END (* if *);
        IF NOT WrSignDesc1(SpecConv.Feed500Str,
                           '  zewn. agc',
                           oMkrA_OM[goA],
                           oMkrA_OM[goB])
        THEN
          RETURN FALSE;
        END (* if *);
        IF NOT WrSignDesc1(SpecConv.Feed500Str,
                           '  ˜rod. agc',
                           mMkrA_OM[goA],
                           mMkrA_OM[goB])
        THEN
          RETURN FALSE;
        END (* if *);
        IF NOT WrSignDesc1(SpecConv.Feed500Str,
                           '  wewn. agc',
                           iMkrA_OM[goA],
                           iMkrA_OM[goB])
        THEN
          RETURN FALSE;
        END (* if *);
      END (* with mkrLength *);
      RETURN TRUE;
    END MarkerLength;

    PROCEDURE OpisOsiP() : BOOLEAN;
    VAR
      sec    : CARDINAL;
      odc    : ARRAY [0 .. 63] OF CHAR;
      strf   : NumStrefy;

    BEGIN
      IF NOT PrintStdValues() THEN
        RETURN FALSE;
      END;
      WITH G_results.anRes.an_OpisOsi DO
        FOR strf := MIN(NumStrefy) TO LstZToBeTraced() DO
          sec := ORD(strf) + 1;
          StdIO.sprintf( odc, "Wyniki dla strefy %d", sec );
          IF NOT WrPrnLn( 0, odc ) THEN
            RETURN FALSE;
          END;
          IF NOT WrSignDesc(  "Bˆ¥d ust.˜r [uA]",
                            SpecConv.Int10Str,
                            difAv_PO[strf])
          THEN
            RETURN FALSE;
          END (* if *);
          StdIO.sprintf( odc, "Bˆ¥d ust.min[uA]", sec );
          IF NOT WrSignDesc(odc,
                            SpecConv.Int10Str,
                            difMin_PO[strf])
          THEN
            RETURN FALSE;
          END (* if *);
          StdIO.sprintf( odc, "Bˆ¥d ust.max[uA]", sec );
          IF NOT WrSignDesc(odc,
                            SpecConv.Int10Str,
                            difMax_PO[strf])
          THEN
            RETURN FALSE;
          END (* if *);
          StdIO.sprintf( odc, "K¥t ˜red.[ø] ", sec );
          IF NOT WrSignDesc(odc,
                            SpecConv.Int100Str,
                            azAv_PO[strf])
          THEN
            RETURN FALSE;
          END (* if *);
          StdIO.sprintf( odc, "K¥t max [ø] ", sec );
          IF NOT WrSignDesc(odc,
                            SpecConv.Int100Str,
                            azMax_PO[strf])
          THEN
            RETURN FALSE;
          END (* if *);
          StdIO.sprintf( odc, "K¥t min [ø] ", sec );
          IF NOT WrSignDesc(odc,
                            SpecConv.Int100Str,
                            azMin_PO[strf])
          THEN
            RETURN FALSE;
          END (* if *);
        END;
        IF NOT WrLn() THEN
          RETURN FALSE;
        END;
        (*
        IF NOT WrSignDesc("Bˆ¥d ustaw. [uA]",
                          SpecConv.Int10Str,
                          alig_PO)
        THEN
          RETURN FALSE;
        END (* if *);
        IF NOT WrLn() THEN
          RETURN FALSE;
        END;
        *)
        IF NOT WrSectSignDesc("Wsp¢ˆczynniki przekroczeä [%]",
                              SpecConv.Int10Str,
                              roughness_PO)
        THEN
          RETURN FALSE;
        END (* if *);
        IF NOT WrPrnLn(0,
                       PASEK)
        THEN
          RETURN FALSE;
        END (* if *);

        IF NOT WrF_TablicaOdci("Zestawienie odcink¢w przekroczeä",
                                G_results.anRes.an_OpisOsi.roughErr_PO,
                                SpecConv.ToStringProcT(SpecConv.Card500Str))
        THEN
          RETURN FALSE;
        END (* if *);
        IF NOT WrLn() THEN
          RETURN FALSE;
        END (* if *);

        IF NOT MarkerLength(mkrLength)
        THEN
          RETURN FALSE;
        END (* if *);
        
        IF NOT WrPrnLn(0,PASEK) THEN
          RETURN FALSE;
        END (*if*);
                    
        IF NOT WrF_TablicaOdci("Zestawienie odcink¢w wyst¥pienia flagi",
                                   G_results.anRes.flagErr,
                                   SpecConv.ToStringProcT(SpecConv.Card500Str))
        THEN
          RETURN FALSE;
        END (* if *);
        IF NOT WypiszStrefy( zonesBeg ,
                             locANieGs ) THEN
          RETURN FALSE;
        END;
        RETURN TRUE;
      END (* with G_results.anRes.an_OpisOsi *);
    END OpisOsiP;

    PROCEDURE OpisSektoraP() : BOOLEAN;

    BEGIN
      IF NOT PrintStdValues() THEN
        RETURN FALSE;
      END;
      WITH G_results.anRes.an_OpisSektora DO
        IF NOT WrSectSignDesc("K¥t sek max [ø]",
                          SpecConv.Int100Str,
                          AzMax_OS)
        THEN
          RETURN FALSE;
        END (* if *);
        IF NOT WrSectSignDesc("K¥t sek min [ø]",
                          SpecConv.Int100Str,
                          AzMin_OS)
        THEN
          RETURN FALSE;
        END (* if *);
        IF NOT WrSectSignDesc("K¥t sek sr  [ø]",
                              SpecConv.Int100Str,
                              AzAv_OS)
        THEN
          RETURN FALSE;
        END (* if *);
        IF NOT WrSignDesc("Szer sekt [ø]",
                          SpecConv.Int100Str,
                          Chi_OS)
        THEN
          RETURN FALSE;
        END (* if *);
        IF NOT WrSignDesc("Sym  sekt.[%]",
                          SpecConv.Int10Str,
                          Phi_OS)
        THEN
          RETURN FALSE;
        END (* if *);
(*
        IF NOT WrF_TablicaOdci("Zestawienie odcink¢w wyst¥pienia < -150",
                                   odcinki150,
                                   SpecConv.ToStringProcT(SpecConv.Card500Str))
        THEN
          RETURN FALSE;
        END (* if *);
        IF NOT WrF_TablicaOdci("Zestawienie odcink¥w wyst¥pienia < -180",
                                   odcinki180,
                                   SpecConv.ToStringProcT(SpecConv.Card500Str))
        THEN
          RETURN FALSE;
        END (* if *);
*)
        
        IF NOT WrPrnLn(0,PASEK) THEN
          RETURN FALSE;
        END(*if*);  
        
        IF NOT WrF_TablicaOdci("Zestawienie odcink¢w wyst¥pienia flagi",
                                   G_results.anRes.flagErr,
                                   SpecConv.ToStringProcT(SpecConv.Card500Str))
        THEN
          RETURN FALSE;
        END (* if *);
        IF NOT WypiszStrefy( zonesBeg_OS, 
                             locANieGs ) THEN
          RETURN FALSE;
        END;
        RETURN TRUE;
      END (* with G_results.anRes.an_OpisSektora *);
    END OpisSektoraP;

    PROCEDURE OpisProfB_P() : BOOLEAN;
    VAR
      s : ARRAY [0 .. 30] OF CHAR;

    BEGIN
      IF NOT PrintStdValues() THEN
        RETURN FALSE;
      END;
      WITH G_results.anRes.an_OpisProfilB DO
        IF NOT WrSignDesc("75-90 [uA]",
                          SpecConv.Int100Str,
                          az75_G_PB)
        THEN
          RETURN FALSE;
        END (* if *);
        IF NOT WrSignDesc("75-150 [uA]",
                          SpecConv.Int100Str,
                          az75_D_PB)
        THEN
          RETURN FALSE;
        END (* if *);
        IF NOT WrSignDesc("K¥t ˜cie¾ki [ø]",
                          SpecConv.Int100Str,
                          az0_PB)
        THEN
          RETURN FALSE;
        END (* if *);
        IF NOT WrSignDesc("Szer sekt [ø]",
                          SpecConv.Int100Str,
                          Chi_PB)
        THEN
          RETURN FALSE;
        END (* if *);
        IF NOT WrSignDesc("Sym. sekt [%]",
                          SpecConv.Int10Str,
                          Phi_PB)
        THEN
          RETURN FALSE;
        END (* if *);
        IF NOT WrSignDesc("K¥t 190uA D [ø]",
                          SpecConv.Int100Str,
                          az190_D_PB)
        THEN
          RETURN FALSE;
        END (* if *);
        IF NOT WrSignDesc("K¥t 150uA G [ø]",
                          SpecConv.Int100Str,
                          az150_G_PB)
        THEN
          RETURN FALSE;
        END (* if *);
        
        IF NOT WrPrnLn(0,PASEK) THEN
          RETURN FALSE;
        END(*if*);  

        IF NOT WrF_TablicaOdci("Zestawienie odcink¢w wyst¥pienia flagi",
                               G_results.anRes.flagErr,
                               SpecConv.ToStringProcT(SpecConv.Card500Str))
        THEN
          RETURN FALSE;
        END (* if *);
        IF NOT WrPrn( 0, "Wysoko˜† lotu" ) THEN
          RETURN FALSE;
        END;
        StdIO.sprintf( s, "%dft", WysokoscAv_PB );
        IF NOT WrPrnLn( 15, s ) THEN
          RETURN FALSE;
        END;
        RETURN TRUE;
      END (* with G_results.anRes.an_OpisProfilB *);
    END OpisProfB_P;

    PROCEDURE OpisBadDod_P() : BOOLEAN;

    BEGIN
      IF NOT PrintStdValues() THEN
        RETURN FALSE;
      END;
      WITH G_results.anRes.an_OpisBadDod DO
        IF NOT WrSignDesc("Dew. ˜red. [uA]",
                          SpecConv.Int10Str,
                          dewAv)
        THEN
          RETURN FALSE;
        END (* if *);
      END (* with G_results.anRes.an_OpisBadDod *);
      
      IF NOT WrPrnLn(0,PASEK) THEN
      	RETURN FALSE;
      END(*if*);
      
      IF NOT WrF_TablicaOdci("Zestawienie odcink¢w wyst¥pienia flagi",
                                  G_results.anRes.flagErr,
                                  SpecConv.ToStringProcT(SpecConv.Card500Str))
      THEN
        RETURN FALSE;
      END (* if *);
      RETURN TRUE;
    END OpisBadDod_P;


    PROCEDURE OpisZabezpieczenia_P() : BOOLEAN;

    BEGIN
      IF NOT PrintStdValues() THEN
        RETURN FALSE;
      END;
      WITH G_results.anRes.an_OpisZabezpieczenie DO
        IF NOT WrSectSignDesc("k¥t dew 180uA",
                              SpecConv.Int100Str,
                              az180Av)
        THEN
          RETURN FALSE;
        END (* if *);
        (*
        IF NOT WrF_TablicaOdci("Zestawienie odcink¢w wyst¥pienia 150uA pod ˜cie¾k¥",
                               odcinki150_OZ,
                               SpecConv.ToStringProcT(SpecConv.Card500Str))
        THEN
          RETURN FALSE;
        END (* if *);
        IF NOT WrF_TablicaOdci("Zestawienie odcink¢w wyst¥pienia 180uA pod ˜cie¾k¥",
                               odcinki180_OZ,
                               SpecConv.ToStringProcT(SpecConv.Card500Str))
        THEN
          RETURN FALSE;
        END (* if *);
        *)
        
        IF NOT WrPrnLn(0,PASEK)
        THEN
          RETURN FALSE;
        END(*if*);    
        
        IF NOT WrF_TablicaOdci("Zestawienie odcink¢w wyst¥pienia flagi",
                                   G_results.anRes.flagErr,
                                   SpecConv.ToStringProcT(SpecConv.Card500Str))
        THEN
          RETURN FALSE;
        END (* if *);
       END (* with G_results.anRes.an_OpisZabezpieczenie *);
      RETURN TRUE;
    END OpisZabezpieczenia_P;


    PROCEDURE Pokrycie_P() : BOOLEAN;

    BEGIN
      IF NOT PrintStdValues() THEN
        RETURN FALSE;
      END;
      WITH G_results.anRes.an_OpisPokrycia DO
        IF NOT WrPrnLn(0,PASEK) THEN
          RETURN FALSE;
        END(*if*);
        IF NOT WrF_TablicaOdci("Zestawienie odcink¢w dla AGC < 20uV",
                               odcinki_20uV,
                               SpecConv.ToStringProcT(SpecConv.Card500Str))
        THEN
          RETURN FALSE;
        END (* if *);
        
        IF NOT WrPrnLn(0,PASEK) THEN
          RETURN FALSE;
        END(*if*);  
        
        IF NOT WrF_TablicaOdci("Zestawienie odcink¢w wyst¥pienia flagi",
                                   G_results.anRes.flagErr,
                                   SpecConv.ToStringProcT(SpecConv.Card500Str))
        THEN
          RETURN FALSE;
        END (* if *);

      END (* with G_results.anRes.an_OpisPokrycia *);
      RETURN TRUE;
    END Pokrycie_P;

  BEGIN (* OpisPomiaru *)
    PrnX := 0;
    PrnY := 0;
    IF NOT WrPrnLn(0,
                   header)
    THEN
      RETURN;
    END (* if *);
    
    IF NOT WrLn() THEN
          RETURN ;
        END (*if*);

    IF NOT WrPrnLn(0,
                   "   Odbiornik       A               ³   B")
    THEN
      RETURN;
    END (* if *);
    IF NOT WrPrnLn(0,
                   PASEK)
    THEN
      RETURN;
    END (* if *);
    CASE G_results.anRes.procedure OF
      G_CommonTypes.pUstawienieOsi_Struktura, G_CommonTypes.pAlarmOsi,
      G_CommonTypes.pUstawienieOsi_Szer_pA,
      G_CommonTypes.pUstawienieOsi_Waski_pA :
        IF NOT OpisOsiP()
        THEN
          RETURN;
        END (* if *);
      |
      G_CommonTypes.pSzerSektora_pA, G_CommonTypes.pAlarmSzeroki_pA,
      G_CommonTypes.pAlarmWaski_pA :
        IF NOT OpisSektoraP()
        THEN
          RETURN;
        END (* if *);
      |
      G_CommonTypes.pSzer_i_Osi_pB, G_CommonTypes.pAlarmSzer_pB,
      G_CommonTypes.pAlarmWaski_pB :
        IF NOT OpisProfB_P()
        THEN
          RETURN;
        END (* if *);
      |
      G_CommonTypes.pRownowagaModulacji, G_CommonTypes.pFazowanie :
        IF NOT OpisBadDod_P()
        THEN
          RETURN;
        END (* if *);
      |
      G_CommonTypes.pZabezpieczenie :
        IF NOT OpisZabezpieczenia_P()
        THEN
          RETURN;
        END (* if *);
      |
      G_CommonTypes.pPokrycieWOsi, G_CommonTypes.pPokrycie8stP,
      G_CommonTypes.pPokrycie8stL :
        IF NOT Pokrycie_P()
        THEN
          RETURN;
        END (* if *);
    END (* case G_results.anRes.procedure *);
(*  
    IF NOT WrPrnLn(0,
                   PASEK)
    THEN
      RETURN;
    END (* if *);
    IF NOT WrPrnLn(0,
                   PASEK)
    THEN
      RETURN;
    END (* if *);
*)
(*
    IF Wr(ASCII.ff)
    THEN
    END (* if Wr *);
*)
  END OpisPomiaru;

  PROCEDURE Print( DwaOdniesienia : BOOLEAN ) : BOOLEAN;
  VAR
    d      : Descs;
    Start,
    Odstep : CARDINAL;
    s,
    idx    : INTEGER;
  VAR
    i,
    j                   : INTEGER;
    OdleglosciNaStronie : CARDINAL;
    Num                 : ARRAY [0 .. 99] OF CHAR;
    tr                  : resultT;
    IleStron            : CARDINAL;
    Odniesienie         : OdnDlaPomBleduT;
    Zestaw              : CARDINAL;
    CoKtoraProbka       : CARDINAL;

    PROCEDURE KatSciezki_P();

    BEGIN
      IF Zestaw = 1
      THEN
        GetSigFileName(devG_Sg,
                       gOdb,
                       Num);
        InitA(d[0],
              Num,
              SigNam[devG_Sg, gOdb],
              DrawEpson.MaxX() * 5 DIV 6,
              DrawEpson.MaxX() DIV 3,
              -450,
              +450,
              FALSE);   (* -45..+45 -> jedn 0.1 *)
        FOR tr := Dif TO boundM DO
          GetResFileName(tr,
                         gOdb,
                         Num);
          InitA(d[1 + ORD(tr)],
                Num,
                "Blad sciezki (G)",
                DrawEpson.MaxX() * 2 DIV 3, (* zachodzi *)
                DrawEpson.MaxX() DIV 3,
                -450,
                +450,
                FALSE);   (* -55..+45 -> jedn 0.1 *)
          IF tr # Dif
          THEN
            d[1 + ORD(tr)].Opis[0] := 0C;
          END (* if tr *);
        END (* for tr *);
        Odstep := (DrawEpson.MaxX() DIV 2) DIV 7;
        Start := Odstep DIV 2;
        GetSigFileName(modG_Sg,
                       gOdb,
                       Num);
        InitA(d[5],
              Num,
              SigNam[modG_Sg, gOdb],
              Start,
              Odstep,
              +720,
              +880,
              FALSE);
        INC(Start,
            Odstep);
        GetSigFileName(agcG_Sg,
                       gOdb,
                       Num);
        InitA(d[6],
              Num,
              SigNam[agcG_Sg,
              gOdb],
              Start,
              Odstep,
              2,
              agcG_SgMax,
              TRUE);
        INC(Start,
            Odstep);
        GetSigFileName(agcM_Sg,
                       gOdb,
                       Num);
        InitA(d[7],
              Num,
              SigNam[agcM_Sg,
              gOdb],
              Start,
              Odstep,
              2,
              agcM_SgMax,
              TRUE);
        (* ??? *)
        INC(Start,
            Odstep);
        InitB(d[8],
              "FLG.G",
              FALSE,
              Start,
              Odstep,
              GSG_flg);
        INC(Start,
            Odstep);
        InitB(d[9],
              "M.W.G",
              FALSE,
              Start,
              Odstep,
              Wew_Marker_G);
        INC(Start,
            Odstep);
        InitB(d[10],
              "M.S.G",
              FALSE,
              Start,
              Odstep,
              Srd_Marker_G);
        INC(Start,
            Odstep);
        InitB(d[11],
              "M.Z.G",
              FALSE,
              Start,
              Odstep,
              Zew_Marker_G);
      ELSE   (* zestaw 2 *)
        GetSigFileName(devG_Sg,
                       zOdb,
                       Num);
        InitA(d[0],
              Num,
              SigNam[devG_Sg,
              zOdb],
              DrawEpson.MaxX() * 5 DIV 6,
              DrawEpson.MaxX() DIV 3,
              -450,
              +450,
              FALSE);   (* -45..+45 -> jedn 0.1 *)
        FOR tr := Dif TO boundM DO
          GetResFileName(tr,
                         zOdb,
                         Num);
          InitA(d[1 + ORD(tr)],
                Num,
                "Bˆ¥d ˜cie¾ki(Z)",
                DrawEpson.MaxX() * 2 DIV 3, (* zachodzi *)
                DrawEpson.MaxX() DIV 3,
                -450,
                +450,
                FALSE);
          IF tr # Dif
          THEN
            d[1 + ORD(tr)].Opis[0] := 0C;
          END (* if tr *);
        END (* for tr *);
        Odstep := (DrawEpson.MaxX() DIV 2) DIV 12;
        Start := Odstep DIV 2;
        GetSigFileName(modG_Sg,
                       zOdb,
                       Num);
        InitA(d[5],
              Num,
              SigNam[modG_Sg,
              zOdb],
              Start,
              Odstep,
              +720,
              +880,
              FALSE);
        INC(Start,
            Odstep);
        GetSigFileName(agcG_Sg,
                       zOdb,
                       Num);
        InitA(d[6],
              Num,
              SigNam[agcG_Sg,
              zOdb],
              Start,
              Odstep,
              2,
              agcG_SgMax,
              TRUE);
        (* ??? *)
        INC(Start,
            Odstep);
        GetSigFileName(agcM_Sg,
                       zOdb,
                       Num);
        InitA(d[7],
              Num,
              SigNam[agcM_Sg,
              zOdb],
              Start,
              Odstep,
              2,
              agcM_SgMax,
              TRUE);
        (* ??? *)
        INC(Start,
            Odstep);
        InitB(d[8],
              "FLG.Z",
              FALSE,
              Start,
              Odstep,
              GSZ_flg);
        INC(Start,
            Odstep);
        InitB(d[9],
              "VHF",
              FALSE,
              Start,
              Odstep,
              Com_Aud_flg);
        INC(Start,
            Odstep);
        InitB(d[10],
              "M.W.Z",
              FALSE,
              Start,
              Odstep,
              Wew_Marker_Z);
        INC(Start,
            Odstep);
        InitB(d[11],
              "M.S.Z",
              FALSE,
              Start,
              Odstep,
              Srd_Marker_Z);
        INC(Start,
            Odstep);
        InitB(d[12],
              "M.Z.Z",
              FALSE,
              Start,
              Odstep,
              Zew_Marker_Z);
        INC(Start,
            Odstep);
        Files.GetCommSigFName(Files.CS_GPS_GDOP,
                              Pomiar,
                              Num);
        InitA(d[13],
              Num,
              "GDOP",
              Start,
              Odstep,
              0,
              50,
              FALSE);
        INC(Start,
            Odstep);
        Files.GetCommSigFName(Files.CS_GPS_NOS,
                              Pomiar,
                              Num);
        InitA(d[14],
              Num,
              "NOS",
              Start,
              Odstep,
              0,
              10,
              FALSE);
        INC(Start,
            Odstep);
        InitB(d[15],
              "GPS.F",
              FALSE,
              Start,
              Odstep,
              GPS_flg);
        INC(Start,
            Odstep);
        GetSigFileName(devL_Sg,
                       gOdb,
                       Num);
        InitA(d[16],
              Num,
              SigNam[devL_Sg,
              gOdb],
              Start,
              Odstep,
              -750,
              +750,
              FALSE);   (* ñ75 -> jedn 0.1 *)
        INC(Start,
            Odstep);
      END (* if Zestaw *);
    END KatSciezki_P;

    PROCEDURE ProfB();

    BEGIN
      Odstep := DrawEpson.MaxX() DIV 3;
      GetSigFileName(devG_Sg,
                     gOdb,
                     Num);
      InitA(d[0],
            Num,
            SigNam[devG_Sg, gOdb],
            DrawEpson.MaxX() * 5 DIV 6,
            DrawEpson.MaxX() DIV 3,
            -4000,
            +4000,
            FALSE);
      GetSigFileName(devG_Sg,
                     zOdb,
                     Num);
      InitA(d[1],
            Num,
            SigNam[devG_Sg, zOdb],
            DrawEpson.MaxX() * 4 DIV 6,
            DrawEpson.MaxX() DIV 3,
            -4000,
            +4000,
            FALSE);
      Odstep := (DrawEpson.MaxX() DIV 2) DIV 12;
      Start := Odstep DIV 2;
      GetSigFileName(modG_Sg,
                     gOdb,
                     Num);
      InitA(d[2],
            Num,
            SigNam[modG_Sg,
            gOdb],
            Start,
            Odstep,
            +720,
            +880,
            FALSE);
      (* +32%..+48% -> jedn 0.1 *)
      INC(Start,
          Odstep);
      GetSigFileName(modG_Sg,
                     zOdb,
                     Num);
      InitA(d[3],
            Num,
            SigNam[modG_Sg,
            zOdb],
            Start,
            Odstep,
            +720,
            +880,
            FALSE);
      (* +32%..+48% -> jedn 0.1 *)
      INC(Start,
          Odstep);
      GetSigFileName(agcG_Sg,
                     gOdb,
                     Num);
      InitA(d[4],
            Num,
            SigNam[agcG_Sg,
            gOdb],
            Start,
            Odstep,
            2,
            agcG_SgMax,
            TRUE);
      INC(Start,
          Odstep);
      GetSigFileName(agcG_Sg,
                     zOdb,
                     Num);
      InitA(d[5],
            Num,
            SigNam[agcG_Sg,
            zOdb],
            Start,
            Odstep,
            2,
            agcG_SgMax,
            TRUE);
      (* ??? *)
      INC(Start,
          Odstep);
      InitB(d[6],
            "FLG.G",
            FALSE,
            Start,
            Odstep,
            GSG_flg);
      INC(Start,
          Odstep);
      InitB(d[7],
            "FLG.Z",
            FALSE,
            Start,
            Odstep,
            GSZ_flg);
      INC(Start,
          Odstep);
      GetSigFileName(devL_Sg,
                     gOdb,
                     Num);
      InitA(d[8],
            Num,
            SigNam[devL_Sg,
            gOdb],
            Start,
            Odstep,
            -750,
            +750,
            FALSE);
      (* ñ75 -> jedn 0.1 *)
      INC(Start,
          Odstep);
      InitB(d[9],
            "VHF",
            FALSE,
            Start,
            Odstep,
            Com_Aud_flg);
      INC(Start,
          Odstep);
      Files.GetCommSigFName(Files.CS_GPS_GDOP,
                            Pomiar,
                            Num);
      InitA(d[10],
            Num,
            "GDOP",
            Start,
            Odstep,
            0,
            50,
            FALSE);
      INC(Start,
          Odstep);
      Files.GetCommSigFName(Files.CS_GPS_NOS,
                            Pomiar,
                            Num);
      InitA(d[11],
            Num,
            "NOS",
            Start,
            Odstep,
            0,
            10,
            FALSE);
      INC(Start,
          Odstep);
      InitB(d[12],
            "GPS.F",
            FALSE,
            Start,
            Odstep,
            GPS_flg);
      INC(Start,
          Odstep);
      Files.GetALfaRefFName(pbTeodolit,
                            FALSE (* LOC*),
                            Num);
      InitA(d[13],
            Num,
            "Elew",
            Start,
            Odstep,
            0,
            1000,
            FALSE); (* 0ø-10ø dokl 0.01 *)
    END ProfB;

    PROCEDURE SzSekt();
    VAR
      azOffset : INTEGER;

    BEGIN
      azOffset := entier( G_results.AktualnyKatProcedury () + 0.5 );
      GetSigFileName(devG_Sg,
                     gOdb,
                     Num);
      InitA(d[0],
            Num,
            SigNam[devG_Sg,
            gOdb],
            DrawEpson.MaxX() * 7 DIV 8,
            DrawEpson.MaxX() DIV 4,
            anRes.offset - 750,
            anRes.offset + 750,
            FALSE);   (* -75..+75 -> jedn 0.1 *)
      GetSigFileName(devG_Sg,
                     zOdb,
                     Num);
      InitA(d[1],
            Num,
            SigNam[devG_Sg,
            zOdb],
            DrawEpson.MaxX() * 6 DIV 8,
            DrawEpson.MaxX() DIV 4,
            anRes.offset - 750,
            anRes.offset + 750,
            FALSE);   (* -75..+75 -> jedn 0.1 *)
      GetResFileName(SecWith,
                     gOdb,
                     Num);
      InitA(d[2],
            Num,
            "Kat sektora (G)",
            DrawEpson.MaxX() * 5 DIV 8,
            DrawEpson.MaxX() DIV 4,
            azOffset - 50,
            azOffset + 50,
            FALSE);    (* -0.5..+0.5 -> jedn 0.01 *)
      GetResFileName(SecWith,
                     zOdb,
                     Num);
      InitA(d[3],
            Num,
            "Kat sektora (Z)",
            DrawEpson.MaxX() * 4 DIV 8,
            DrawEpson.MaxX() DIV 4,
            azOffset - 50,
            azOffset + 50,
            FALSE);   (* -0.5..+0.5 -> jedn 0.01 *)
      Odstep := (DrawEpson.MaxX() * 3 DIV 8) DIV 7;
      Start := Odstep DIV 2;
      GetSigFileName(modG_Sg,
                     gOdb,
                     Num);
      InitA(d[4],
            Num,
            SigNam[modG_Sg,
            gOdb],
            Start,
            Odstep,
            +720,
            +880,
            FALSE);
      (* +32%..+48% -> jedn 0.1 *)
      INC(Start,
          Odstep);
      GetSigFileName(modG_Sg,
                     zOdb,
                     Num);
      InitA(d[5],
            Num,
            SigNam[modG_Sg,
            zOdb],
            Start,
            Odstep,
            +720,
            +880,
            FALSE);
      (* +32%..+48% -> jedn 0.1 *)
      INC(Start,
          Odstep);
      GetSigFileName(agcG_Sg,
                     gOdb,
                     Num);
      InitA(d[6],
            Num,
            SigNam[agcG_Sg,
            gOdb],
            Start,
            Odstep,
            2,
            agcG_SgMax,
            TRUE);
      INC(Start,
          Odstep);
      GetSigFileName(agcG_Sg,
                     zOdb,
                     Num);
      InitA(d[7],
            Num,
            SigNam[agcG_Sg,
            zOdb],
            Start,
            Odstep,
            2,
            agcG_SgMax,
            TRUE);
      (* ??? *)
      INC(Start,
          Odstep);
      InitB(d[8],
            "FLG.G",
            FALSE,
            Start,
            Odstep,
            GSG_flg);
      INC(Start,
          Odstep);
      InitB(d[9],
            "FLG.Z",
            FALSE,
            Start,
            Odstep,
            GSZ_flg);
      INC(Start, Odstep);
      Files.GetALfaRefFName(pbTeodolit,
                            FALSE (* LOC*),
                            Num);
      InitA(d[10],
            Num,
            "Elew",
            Start,
            Odstep,
            150,
            450,
            FALSE); (* 1.5ø-4.5ø dokl 0.01 *)
    END SzSekt;

    PROCEDURE RownowagaModulacji();

    BEGIN
      GetSigFileName(devG_Sg,
                     gOdb,
                     Num);
      InitA(d[0],
            Num,
            SigNam[devG_Sg, gOdb],
            DrawEpson.MaxX() * 5 DIV 6,
            DrawEpson.MaxX() DIV 3,
            -450,
            +450,
            FALSE);
      (* -45..+45 -> jedn 0.1 *)
      INC(Start, Odstep DIV 2);
      GetSigFileName(devG_Sg,
                     zOdb,
                     Num);
      InitA(d[1],
            Num,
            SigNam[devG_Sg,  zOdb],
            DrawEpson.MaxX() * 4 DIV 6,
            DrawEpson.MaxX() DIV 3,
            -450,
            +450,
            FALSE);
      (* -45..+45 -> jedn 0.1 *)
      Odstep := (DrawEpson.MaxX() DIV 2) DIV 5;
      Start := Odstep DIV 2;
      GetSigFileName(modG_Sg,
                     gOdb,
                     Num);
      InitA(d[2],
            Num,
            SigNam[modG_Sg,
            gOdb],
            Start,
            Odstep,
            +720,
            +880,
            FALSE);
      (* +32%..+48% -> jedn 0.1 *)
      INC(Start,
          Odstep);
      GetSigFileName(modG_Sg,
                     zOdb,
                     Num);
      InitA(d[3],
            Num,
            SigNam[modG_Sg,
            zOdb],
            Start,
            Odstep,
            +720,
            +880,
            FALSE);
      INC(Start,
          Odstep);
      GetSigFileName(agcG_Sg,
                     gOdb,
                     Num);
      InitA(d[4],
            Num,
            SigNam[agcG_Sg,
            gOdb],
            Start,
            Odstep,
            2,
            agcG_SgMax,
            TRUE);
      (* ??? *)
      INC(Start,
          Odstep);
      GetSigFileName(agcG_Sg,
                     zOdb,
                     Num);
      InitA(d[5],
            Num,
            SigNam[agcG_Sg,
            zOdb],
            Start,
            Odstep,
            2,
            agcG_SgMax,
            TRUE);
      (* ??? *)
      INC(Start,
          Odstep);
      InitB(d[6],
            "FLG.G",
            FALSE,
            Start,
            Odstep,
            GSG_flg);
    END RownowagaModulacji;

    PROCEDURE Pokrycie();

    BEGIN
      GetSigFileName(devG_Sg,
                     gOdb,
                     Num);
      InitA(d[0],
            Num,
            SigNam[devG_Sg,
            gOdb],
            DrawEpson.MaxX() * 5 DIV 6,
            DrawEpson.MaxX() DIV 3,
            -4000,
            +4000,
            FALSE);
      (* -45..+45 -> jedn 0.1 *)
      GetSigFileName(devG_Sg,
                     zOdb,
                     Num);
      InitA(d[1],
            Num,
            SigNam[devG_Sg,
            zOdb],
            DrawEpson.MaxX() * 4 DIV 6,
            DrawEpson.MaxX() DIV 3,
            -4000,
            +4000,
            FALSE);
      (* -45..+45 -> jedn 0.1 *)
      GetSigFileName(modG_Sg,
                     gOdb,
                     Num);
      Odstep := (DrawEpson.MaxX() DIV 2) DIV 7;
      Start := Odstep DIV 2;
      InitA(d[2],
            Num,
            SigNam[modG_Sg, gOdb],
            Start,
            Odstep,
            +720,
            +880,
            FALSE);
      (* +32%..+48% -> jedn 0.1 *)
      INC(Start,
          Odstep);
      GetSigFileName(modG_Sg,
                     zOdb,
                     Num);
      InitA(d[3],
            Num,
            SigNam[modG_Sg,  zOdb],
            Start,
            Odstep,
            +720,
            +880,
            FALSE);
      INC(Start,
          Odstep);
      (* +32%..+48% -> jedn 0.1 *)
      GetSigFileName(agcG_Sg,
                     gOdb,
                     Num);
      InitA(d[4],
            Num,
            SigNam[agcG_Sg,
            gOdb],
            Start,
            Odstep,
            2,
            agcG_SgMax,
            TRUE);
      INC(Start,
          Odstep);
      GetSigFileName(agcG_Sg,
                     zOdb,
                     Num);
      InitA(d[5],
            Num,
            SigNam[agcG_Sg,
            zOdb],
            Start,
            Odstep,
            2,
            agcG_SgMax,
            TRUE);
      (* ??? *)
      INC(Start,
          Odstep);
      InitB(d[8],
            "FLG.G",
            FALSE,
            Start,
            Odstep,
            GSG_flg);
      INC(Start,
          Odstep);
      InitB(d[9],
            "FLG.Z",
            FALSE,
            Start,
            Odstep,
            GSZ_flg);
      INC(Start,
          Odstep);
      Files.GetCommSigFName(Files.CS_Alt_Sg,
                            FALSE (* GS *),
                            Num);
      InitA(d[10],
            Num,
            "wys.",
            Start,
            Odstep,
            0,
            +3000,
            FALSE);   (* 0..+20000 -> jedn 1 *)
      INC(Start,
          Odstep);
    END Pokrycie;

  BEGIN (* Print *)
    CASE G_results.anRes.procedure OF
      G_CommonTypes.pUstawienieOsi_Struktura,
      G_CommonTypes.pUstawienieOsi_Szer_pA,
      G_CommonTypes.pUstawienieOsi_Waski_pA, G_CommonTypes.pAlarmOsi :
        IF NOT UstalSkalowanie(TRUE,
                               DwaOdniesienia,
                               NazwaPliku,
                               IleStron,
                               Odniesienie,
                               Zestaw,
                               CoKtoraProbka)
        THEN
          RETURN FALSE;
        END (* if *);
        InitAll(d,
                1 * 500,
                Pomiar,
                CoKtoraProbka);
        KatSciezki_P;
      |
      G_CommonTypes.pSzerSektora_pA, G_CommonTypes.pAlarmSzeroki_pA,
      G_CommonTypes.pAlarmWaski_pA :
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
        InitAll(d,
                1 * 500,
                Pomiar,
                CoKtoraProbka);
        SzSekt;
      |
      G_CommonTypes.pSzer_i_Osi_pB, G_CommonTypes.pAlarmSzer_pB,
      G_CommonTypes.pAlarmWaski_pB, G_CommonTypes.pRownowagaModulacji,
      G_CommonTypes.pFazowanie :
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
        InitAll(d,
                1 * 500,
                Pomiar,
                CoKtoraProbka);
        CASE G_results.anRes.procedure OF
          G_CommonTypes.pRownowagaModulacji,
          G_CommonTypes.pFazowanie :
            RownowagaModulacji;
        ELSE
          ProfB;
        END;
      |
      G_CommonTypes.pZabezpieczenie :
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
        InitAll(d,
                1 * 500,
                Pomiar,
                CoKtoraProbka);
        SzSekt;
      |
      G_CommonTypes.pPokrycieWOsi, G_CommonTypes.pPokrycie8stP,
      G_CommonTypes.pPokrycie8stL :
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
        InitAll(d,
                1 * 500,
                Pomiar,
                CoKtoraProbka);
        Pokrycie;
    END (* case anRes.procedure *);
    DrawEpson.SetFont(DrawEpson.ft8x8);
    DrawEpson.SetTextMode(DrawEpson.mtOr);
    FOR s := 0 TO IleStron - 1 DO
      DrawEpson.Open;
      DrawEpson.Mnoznik(SKALA_X,
                        1);
      DrawEpson.SetTextMode(DrawEpson.mtSet);
      DrawEpson.Line(0,
                     0,
                     0,
                     MaxY() - 1,
                     StyleSep);
      Start := Odstep DIV 2;
(*
      FOR i := 0 TO HIGH(d) DO
        WITH d[i] DO
          IF Uzywane
          THEN
            DrawEpson.Line(SklStala + Zakres DIV 2,
                           0,
                           SklStala + Zakres DIV 2,
                           MaxY() - 1,
                           StyleSep);
            DrawEpson.Line(SklStala,
                           0,
                           SklStala,
                           MaxY() - 1,
                           Style0);
(*
            DrawEpson.Line(SklStala - Zakres DIV 2,
                           0,
                           SklStala - Zakres DIV 2,
                           MaxY() - 1,
                           StyleSep);
*)
          END (* if Uzywane *);
        END (* with d *);
      END (* for i *);
*)
      (* eventy *)
      i := MaxY() * CoKtoraProbka;
      PolozenieNapisu := DrawEpson.MaxX() * 9 DIV 10;
      DrawEpson.SetDir(DrawEpson.t_90);
      DrawEpson.Mnoznik(SKALA_X_90,
                        SKALA_Y_90);
      PiszEventy.EnumEv(U_GS,
                        TRUE,
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
                         DrawEpson.MaxX() - SKALA_X * 8 * Strings.Length(header
                         ) - 4,
                         MaxY());
      DrawEpson.SetTextMode(DrawEpson.mtOr);
      FOR j := 0 TO HIGH(d) DO
        IF d[j].Uzywane
        THEN
          Opis(d[j],
               NOT ODD(j));
        END (* if d *);
      END (* for j *);
      DrawEpson.SetTextMode(DrawEpson.mtSet);
      FOR idx := 0 TO MaxY() - 1 DO
        FOR j := 0 TO HIGH(d) DO
          Point(d[j],
                idx);
        END (* for j *);
      END (* for idx *);
      DrawEpson.SetTextMode(DrawEpson.mtOr);
      (* znaczniki odleglosci *)
      OdleglosciNaStronie := MaxY() * CoKtoraProbka;
      ZnacznikiOdleglosci(G_results.anRes.odnDlaPomOdl,
                          pbGPS,
                          Pomiar,
                          s,
                          TRUE,
                          Format360,
                          Lotnisko.ProgPasa);
      IF NOT DrawEpson.Out(DrawEpson.WrProc)
      THEN
        CloseAll(d);
        DrawEpson.Close;
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
    gOdb := anRes.glownyOdbiornik;
    IF gOdb = goA
    THEN
      zOdb := goB;
      GSG_flg := GSA_flg;
      GSZ_flg := GSB_flg;
      Zew_Marker_G := oMkrFlgPosA;
      Srd_Marker_G := mMkrFlgPosA;
      Wew_Marker_G := iMkrFlgPosA;
      Zew_Marker_Z := oMkrFlgPosB;
      Srd_Marker_Z := mMkrFlgPosB;
      Wew_Marker_Z := iMkrFlgPosB;
    ELSE
      zOdb := goA;
      GSG_flg := GSB_flg;
      GSZ_flg := GSA_flg;
      Zew_Marker_G := oMkrFlgPosB;
      Srd_Marker_G := mMkrFlgPosB;
      Wew_Marker_G := iMkrFlgPosB;
      Zew_Marker_Z := oMkrFlgPosA;
      Srd_Marker_Z := mMkrFlgPosA;
      Wew_Marker_Z := iMkrFlgPosA;
    END (* if gOdb *);
    SigNam[devG_Sg, gOdb] := "DEW.G";
    SigNam[devG_Sg, zOdb] := "DEW.Z";
    SigNam[devL_Sg, gOdb] := "L.DEW.G";
    SigNam[devL_Sg, zOdb] := "L.DEW.Z";
    SigNam[modG_Sg, gOdb] := "MOD.G";
    SigNam[modG_Sg, zOdb] := "MOD.Z";
    SigNam[agcG_Sg, gOdb] := "SS.G";
    SigNam[agcG_Sg, zOdb] := "SS.Z";
    SigNam[agcM_Sg, gOdb] := "M.SS.G";
    SigNam[agcM_Sg, zOdb] := "M.SS.Z";
    Files.GetCommSigFName(Files.CS_GPS_GDOP,
                          Pomiar,
                          NazwaPliku);
    MakeHeader(header);
    IF NOT Print( FALSE )
    THEN
      RETURN;
    END (* if *);
    OpisPomiaru();

    PiszEventy.PiszNaDrukarce(U_GS,
                              CzyToJestPromien,
                              PiszEventy.TypyEventow {PoczatekPomiaru..
                              BrakZnacznika});
  END MakeRaport;

BEGIN
  Zestaw := 0;
END G_Print.
