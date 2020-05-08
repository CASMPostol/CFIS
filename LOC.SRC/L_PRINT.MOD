(*.F- *)
(**********************************************************************
|  Title   : Drukowanie dla LOC
|  Author  : M.Morawski
|  System  : LOGITECH MODULA-2/86
|  History :
|    21-07-96:M.Postol
|      liczne zmiany
|    04-11-96:M.Postol
|      blad przy wypisywaniu wyrazistosci
|      wywalilem L. z nazw wykresow
|    07-11-96:
|      OpisSektoraP procety * 10
|      An_MkrLength pisal dla gl i zapasowego.
|      zle ustawiony offfset dla szerokosci w prof A.
|    13-05-97: M.Morawski
|      Blad przy drukowaniu odcinkow wystapienia flagi
|    03-09-97: M.Postol
|      zmienilem skale dla LOC.SS i MKR.SS na 5000 zgodnie ze specyfikacja
|    31-12-97: T.Rozmarynowski
|      zmieniono wykresy EPE na GDOP
|    14-06-00: M.Postol
|      wprowadzilem poprawki uA zamiast stopni z wersii 2.42
|    Rel 3.15: MPostol
|      Zmiany w wydruku
|
|  Copyright (C), CAS LODZ POLAND.
|  TEL: 42' 862 547, 42' 87 80 44 FAX/TEL: 42' 84 48 40
|
**********************************************************************)
(*.F+ *)

IMPLEMENTATION MODULE L_Print;

  IMPORT
    DrawEpson, Strings, SYSTEM, StdIO, PiszEventy, L_results, L_Files,
    SpecConv, Files, L_CommonTypes;

  FROM EventsMng IMPORT
    EventKind, RodzUrzadzenia;

  FROM L_results IMPORT
    anRes;

  FROM MathLib0 IMPORT
    real, entier;

  FROM SpecConv IMPORT
    Feed500Str, ToStringProcT, Card500Str, Int100Str;

  FROM L_CommonTypes IMPORT
    Signals, MkrLengthT, SignalDsc, SignalInSecDsc, NumStrefy,
    (* PROCEDURE *) CzyToJestPromien;

  FROM Print IMPORT
    (* CONST *) StyleSep, PASEK, SKALA_X, SKALA_X_90, SKALA_Y_90,
    (* TYPE *) Desc,
    (* VAR *) PolozenieNapisu, PrnX, PrnY,
    (* PROCEDURE *) MaxY, WrPrn, WrLn, WrPrnLn, InitA, InitB, Point, Opis,
                    CloseAll, InitAll, EvProc, ZnacznikiOdleglosci,
                    WrF_TablicaOdci, WypiszStrefy;

  FROM CommonTypes IMPORT
    (* TYPE *)  OdnDlaPomBleduT, GlownyOdbiornikT,
    (* CONST *) NAVA_flg, NAVA_Aud_flg, Com_Aud_flg, iMkrFlgPosA, mMkrFlgPosA,
                oMkrFlgPosA, NAVB_flg, NAVB_Aud_flg, GPS_flg, iMkrFlgPosB,
                mMkrFlgPosB, oMkrFlgPosB, 
    (* PROCEDURE *) GetRecName, GetTranName;

  FROM PrintCntroll IMPORT
    UstalSkalowanie;

  FROM ILS_ZoneMngmnt IMPORT
    L_LstZToBeTraced;

  FROM Czas IMPORT
    ConvertToStr;
    
  TYPE
    Descs  =
      ARRAY [0 .. 18] OF Desc;
    Str100 =
      ARRAY [0 .. 100] OF CHAR;
    str8   =
      ARRAY [0 .. 7] OF CHAR;

  CONST
    agcL_SgMax    = 5000;
    agcM_SgMax    = 5000;
    Pomiar        = FALSE;
    DLA_TEODOLITU = '         Wyniki pomiar¢w - odniesienie teodolit';
    DLA_GPS       = '         Wyniki pomiar¢w - odniesienie GPS';
    Format360     = FALSE;
    locANieGs     = TRUE;

  VAR
    Zestaw      : CARDINAL;
    Odniesienie : OdnDlaPomBleduT;
    header      : Str100;
    NazwaPliku  : ARRAY [0 .. 30] OF CHAR;
    gOdb        : GlownyOdbiornikT;
    zOdb        : GlownyOdbiornikT;
    NAVG_flg    : CARDINAL;
    NAVZ_flg    : CARDINAL;
    NAVG_AFlg   : CARDINAL;
    NAVZ_AFlg   : CARDINAL;
    Zew_Marker_G : CARDINAL;
    Srd_Marker_G : CARDINAL;
    Wew_Marker_G : CARDINAL;
    Zew_Marker_Z : CARDINAL;
    Srd_Marker_Z : CARDINAL;
    Wew_Marker_Z : CARDINAL;
    SigNam      : ARRAY Signals, GlownyOdbiornikT OF str8;

  PROCEDURE NazwaProcedury
            (     Procedura : L_CommonTypes.ProceduraT;
                  Strona    : L_CommonTypes.StronaT;
                  Szczegoly : BOOLEAN;
              VAR str       : ARRAY OF CHAR            );
  VAR
    str_str : ARRAY L_CommonTypes.StronaT OF ARRAY [0 .. 31] OF CHAR;
    str_adr : SYSTEM.ADDRESS;

  BEGIN
    IF Szczegoly THEN
      str_str[L_CommonTypes.sL150] := 'str. lewa 150';
      str_str[L_CommonTypes.sL75] := 'str. lewa 75';
      str_str[L_CommonTypes.sP75] := 'str. prawa 75';
      str_str[L_CommonTypes.sP150] := 'str. prawa 150';
    ELSE
      str_str[L_CommonTypes.sL150] := 'str. lewa';
      str_str[L_CommonTypes.sL75] := 'str. lewa';
      str_str[L_CommonTypes.sP75] := 'str. prawa';
      str_str[L_CommonTypes.sP150] := 'str. prawa';
    END;
    str_adr := SYSTEM.ADR(str_str[Strona]);
    CASE Procedura OF
      L_CommonTypes.pAlarmOsi :
        IF (Strona <= L_CommonTypes.sL75) THEN
          str_str[Strona] := 'str. lewa';
        ELSE
          str_str[Strona] := 'str. prawa';
        END;
        StdIO.sprintf(str,
                      'O˜ - alarm %s',
                      str_adr);
      |
      L_CommonTypes.pSzerSektora_pA :
        StdIO.sprintf(str,
                      'Sektor (A) %s',
                      str_adr);
      |
      L_CommonTypes.pAlarmSzeroki_pA :
        StdIO.sprintf(str,
                      'Sektor alarm szeroki (A) %s',
                      str_adr);
      |
      L_CommonTypes.pAlarmWaski_pA :
        StdIO.sprintf(str,
                      'Sektor alarm waski (A) %s',
                      str_adr);
      |
      L_CommonTypes.pUstawienieOsi_Struktura :
        Strings.ConstAssign('O˜ - struktura (A)',
                            str);
      |
      L_CommonTypes.pUstawienieOsi_Szer_pA :
        Strings.ConstAssign('O˜ alarm szeroki (A)',
                            str);
      |
      L_CommonTypes.pUstawienieOsi_Waski_pA :
        Strings.ConstAssign('O˜ alarm w¥ski (A)',
                            str);
      |
      L_CommonTypes.pSzer_i_Osi_pB :
        Strings.ConstAssign('Sektor/wyrazisto˜† (B)',  str);
      |
      L_CommonTypes.pAlarmSzer_pB :
        Strings.ConstAssign('Sektor alarm szeroki(B)', str);
      |
      L_CommonTypes.pAlarmWaski_pB :
        Strings.ConstAssign('Sektor alarm w¥ski (B)',
                            str);
      |
      L_CommonTypes.pRownowagaModulacji :
        Strings.ConstAssign('R¢wnowaga modulacji',
                            str);
      |
      L_CommonTypes.pFazowanie :
        Strings.ConstAssign('Fazowanie',
                            str);
      |
      L_CommonTypes.pWyrazistosc_na_d_katach :
        Strings.ConstAssign('Wyrazisto˜† na du¾ych k¥tach',
                            str);
      |
      L_CommonTypes.pZasieg_do_10 :
        Strings.ConstAssign('Zasi©g 25 NM',
                            str);
      |
      L_CommonTypes.pZasieg_10_35 :
        Strings.ConstAssign('Zasi©g 17 NM)',
                            str);
      |
      L_CommonTypes.pZasieg_ponad_35 :
        Strings.ConstAssign('Zasi©g 10 NM',
                            str);
      |
      L_CommonTypes.pMarker :
        StdIO.sprintf(str,
                      'Marker +/-75uA %s',
                      str_adr);
    END (* case Procedura *);
  END NazwaProcedury;

  PROCEDURE MakeHeader
            ( VAR str : ARRAY OF CHAR );
  VAR
    tmp      : ARRAY [0 .. 50] OF CHAR;
    tmpA     : SYSTEM.ADDRESS;
    odbN     : ARRAY [0 .. 15] OF CHAR;
    tmpOdb   : SYSTEM.ADDRESS;
    tranN    : ARRAY [ 0 .. 6  ] OF CHAR;
    dataStr  : ARRAY [ 0 .. 20 ] OF CHAR;
    data_adr : SYSTEM.ADDRESS;

  BEGIN
    WITH L_results.anRes DO
      NazwaProcedury(procedure, strona, TRUE, tmp);
      tmpA := SYSTEM.ADR(tmp);
      GetTranName(tranN, Nadajnik);
      GetRecName(odbN, gOdb);
      Strings.Concat(odbN, ' ', odbN);
      Strings.Concat(odbN, tranN, odbN);
      ConvertToStr(data, FALSE, dataStr);
      tmpOdb    := SYSTEM.ADR(odbN);
      data_adr  := SYSTEM.ADR(dataStr);
      StdIO.sprintf3(str,
                     " LOC ¯%s® OdbG:%s; Pomiar wyk: %s",
                     tmpA,
                     tmpOdb,
                     data_adr);
      Strings.Insert(Nazwa,
                     str,
                     0);
    END (* if PromienANieOrbita *);
  END MakeHeader;

  PROCEDURE OpisPomiaru();
  VAR
    PromienANieOrbita : BOOLEAN;
    converP           : ToStringProcT;

    PROCEDURE PrintStdValues( ) : BOOLEAN;
      BEGIN
        IF NOT WrPrnLn( 0, "Wyniki dla caˆego pomiaru" ) THEN
          RETURN FALSE;
        END;

        IF NOT WrSignDesc("Mod min [%]",
                          SpecConv.Int10Str,
                          L_results.anRes.modLocMin_PO)
        THEN
          RETURN FALSE;
        END (* if *);
        IF NOT WrSignDesc("Mod ˜rednio [%]",
                          SpecConv.Int10Str,
                          L_results.anRes.modLocAv_PO)
        THEN
          RETURN FALSE;
        END (* if *);
        IF NOT WrSignDesc("SS Min [uV]",
                          SpecConv.Int2Str,
                          L_results.anRes.SSMin_PO)
        THEN
          RETURN FALSE;
        END (* if *);
        IF NOT WrLn() THEN
          RETURN FALSE;
        END;
        RETURN TRUE;
      END PrintStdValues;

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
      IF NOT WrPrn(15,
                   '³')
      THEN
        RETURN FALSE;
      END (* if *);
      Conv(d1.val,
           s,
           5);
      IF NOT WrPrn(20,
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

    PROCEDURE WrSignDesc
              (     str  : ARRAY OF CHAR;
                    Conv : SpecConv.ToStringProcT;
                VAR A    : ARRAY OF SignalDsc     ) : BOOLEAN;

    BEGIN
      IF NOT WrSignDesc1(Conv,
                         str,
                         A[0],
                         A[1])
      THEN
        RETURN FALSE;
      END (* if *);
      RETURN TRUE;
    END WrSignDesc;

    PROCEDURE An_MkrLength
              (    mkrLength : MkrLengthT ) : BOOLEAN;

    BEGIN
      IF NOT WrPrnLn( 0, "Dˆugo˜ci marker¢w [ft]" ) THEN
        RETURN FALSE;
      END;
      WITH mkrLength DO
        IF NOT WrSignDesc1(Feed500Str,
                           '  zewn. flg',
                           oMkrL_OM[goA],
                           oMkrL_OM[goB])
        THEN
          RETURN FALSE;
        END (* if *);
        IF NOT WrSignDesc1(Feed500Str,
                           '  ˜rod. flg',
                           mMkrL_OM[goA],
                           mMkrL_OM[goB])
        THEN
          RETURN FALSE;
        END (* if *);
        IF NOT WrSignDesc1(Feed500Str,
                           '  wewn. flg',
                           iMkrL_OM[goA],
                           iMkrL_OM[goB])
        THEN
          RETURN FALSE;
        END (* if *);
        IF NOT WrSignDesc1(Feed500Str,
                           '  zewn. agc',
                           oMkrA_OM[goA],
                           oMkrA_OM[goB])
        THEN
          RETURN FALSE;
        END (* if *);
        IF NOT WrSignDesc1(Feed500Str,
                           '  ˜rod. agc',
                           mMkrA_OM[goA],
                           mMkrA_OM[goB])
        THEN
          RETURN FALSE;
        END (* if *);
        IF NOT WrSignDesc1(Feed500Str,
                           '  wewn. agc',
                           iMkrA_OM[goA],
                           iMkrA_OM[goB])
        THEN
          RETURN FALSE;
        END (* if *);
      END (* with mkrLength *);
      RETURN TRUE;
    END An_MkrLength;

    PROCEDURE WrSectSignDesc
              (     str  : ARRAY OF CHAR;
                    Conv : SpecConv.ToStringProcT;
                    pb   : OdnDlaPomBleduT;
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
      FOR i := MIN(L_CommonTypes.NumStrefy) TO L_LstZToBeTraced() DO
        sec := ORD(i) + 1;
        StdIO.sprintf(nap,
                      " Strefa nr. %d",
                      sec);
        IF NOT WrSignDesc(nap,
                          Conv,
                          ssd[i][pb])
        THEN
          RETURN FALSE;
        END (* if *);
      END (* for i *);
      RETURN TRUE;
    END WrSectSignDesc;

    PROCEDURE OpisOsiP() : BOOLEAN;
    VAR
      d_o : RECORD
              i1, f1, i2, f2 :
                CARDINAL;
            END;
      i       : CARDINAL;
      go      : GlownyOdbiornikT;
      pb      : OdnDlaPomBleduT;
      odc     : ARRAY [0 .. 63] OF CHAR;
      sectorC : CARDINAL;
    BEGIN
      WITH L_results.anRes.an_OpisOsi DO
        IF NOT PrintStdValues() THEN
          RETURN FALSE;
        END;
        FOR pb := pbTeodolit TO pbGPS DO
          IF pb = pbTeodolit
          THEN
            IF NOT WrPrnLn(0,
                           DLA_TEODOLITU)
            THEN
              RETURN FALSE;
            END (* if *);
          ELSE
            IF NOT WrPrnLn(0,
                           DLA_GPS)
            THEN
              RETURN FALSE;
            END (* if *);
          END (* if pb *);
          IF NOT WrSectSignDesc("Bˆ¥d ustawienia ˜rednio[uA]",
                                SpecConv.Int10Str,
                                pb,
                                difAv_PO)
          THEN
            RETURN FALSE;
          END (* if *);
          IF NOT WrSectSignDesc("Bˆ¥d ustawienia max[uA]",
                                SpecConv.Int10Str,
                                pb,
                                difMax_PO)
          THEN
            RETURN FALSE;
          END (* if *);
          IF NOT WrSectSignDesc("Bˆ¥d ustawienia min[uA]",
                                SpecConv.Int10Str,
                                pb,
                                difMin_PO)
          THEN
            RETURN FALSE;
          END (* if *);
          IF NOT WrSectSignDesc("Bˆ¥d k¥ta ˜redni[ø]",
                                SpecConv.Int100Str,
                                pb,
                                AzAv_PO)
          THEN
            RETURN FALSE;
          END (* if *);
          IF NOT WrSignDesc("Ustaw. osi[uA]",
                            SpecConv.Int10Str,
                            alig_PO[pb])
          THEN
            RETURN FALSE;
          END (* if *);
          IF NOT WrSignDesc("Bˆ¥d {1-5}[uA]",
                            SpecConv.Int10Str,
                            difAvTotal_PO[pb])
          THEN
            RETURN FALSE;
          END (* if *);
          IF NOT WrSignDesc("Bˆ¥d pol P [%]",
                            SpecConv.Int10Str,
                            difAvPolR_PO[pb])
          THEN
            RETURN FALSE;
          END (* if *);
          IF NOT WrSignDesc("Bˆ¥d pol L [%]",
                            SpecConv.Int10Str,
                            difAvPolL_PO[pb])
          THEN
            RETURN FALSE;
          END (* if *);
          IF NOT WrSectSignDesc("Przekroczenia [%]",
                                SpecConv.Int10Str,
                                pb,
                                roughness_PO)
          THEN
            RETURN FALSE;
          END (* if *);
          FOR go := goA TO goB DO
            WITH roughErr_PO[pb][go] DO
              IF w_IleOd # 0
              THEN
                IF NOT WrPrnLn(0,
                               PASEK)
                THEN
                  RETURN FALSE;
                END (* if *);
                IF pb = pbGPS  THEN
                  IF NOT WrPrnLn(0,
                                 "Przekroczenia dla GPS")
                  THEN
                    RETURN FALSE;
                  END (* if *);
                ELSE
                  IF NOT WrPrnLn(0,
                                 "Przekroczenia dla teodolitu")
                  THEN
                    RETURN FALSE;
                  END (* if *);
                END;
                IF go = gOdb
                THEN
                  IF NOT WrPrnLn(0,
                                 "Przekroczenia dla odbiornika A [NM]")
                  THEN
                    RETURN FALSE;
                  END (* if *);
                ELSE
                  IF NOT WrPrnLn(0,
                                 "Przekroczenia dla odbiornika B")
                  THEN
                    RETURN FALSE;
                  END (* if *);
                END (* if go *);
              
                            
          
                  FOR i := 1 TO w_IleOd DO
                  WITH opis[i ] DO                         (* MM bylo wg starego W_TablicaOdcinkow *)
                    d_o.i1 := CARDINAL(pocz) DIV 500;
                    d_o.i2 := CARDINAL(kon) DIV 500;
                    d_o.f1 := CARDINAL(pocz) MOD 500 DIV 5;
                    d_o.f2 := CARDINAL(kon) MOD 500 DIV 5;
                    sectorC := ORD(sector)+1;
                    StdIO.sprintf3(odc,
                                   "Odcinek %d od %d.%02d do %d.%02d, strefa %d",
                                   i,
                                   d_o,
                                   sectorC );
                    IF NOT WrPrnLn(0,
                                   odc)
                    THEN
                      RETURN FALSE;
                    END (* if *);
                    IF NOT WrPrnLn(0,
                                 " ")
                    THEN
                    RETURN FALSE;
                    END (* if *);

                  END (* with opis *);
                END (* for i *);
              END (* if w_IleOd *);
            END (* with roughErr_PO *);
          END (* for go *);
        END (* for pb *);
        IF NOT WrPrnLn(0,
                       PASEK)
        THEN
          RETURN FALSE;
        END (* if *);
        IF NOT An_MkrLength(mkrLength)
        THEN
          RETURN FALSE;
        END (* if *);
        IF NOT WrPrnLn(0,
                       PASEK)
        THEN
          RETURN FALSE;
        END (* if *);
        IF NOT WypiszStrefy( zonesBeg,
                             locANieGs ) THEN
          RETURN FALSE;
        END;
        RETURN TRUE;
      END (* with L_results.anRes.an_OpisOsi *);
    END OpisOsiP;

    PROCEDURE OpisSektoraP() : BOOLEAN;
    VAR
      pb : OdnDlaPomBleduT;

    BEGIN
      WITH L_results.anRes.an_OpisSektora DO
        IF NOT PrintStdValues() THEN
          RETURN FALSE;
        END;
        FOR pb := pbTeodolit TO pbGPS DO
          IF pb = pbTeodolit
          THEN
            IF NOT WrPrnLn(0,
                           DLA_TEODOLITU)
            THEN
              RETURN FALSE;
            END (* if *);
          ELSE
            IF NOT WrPrnLn(0,
                           DLA_GPS)
            THEN
              RETURN FALSE;
            END (* if *);
          END (* if pb *);
          IF NOT WrSectSignDesc("K¥t maksymalny [ø]",
                                SpecConv.Int100Str,
                                pb,
                                AzMax_OSA)
          THEN
            RETURN FALSE;
          END (* if *);
          IF NOT WrSectSignDesc("K¥t minimalny  [ø]",
                                SpecConv.Int100Str,
                                pb,
                                AzMin_OSA)
          THEN
            RETURN FALSE;
          END (* if *);
          IF NOT WrSectSignDesc("K¥t ˜redni     [ø]",
                                SpecConv.Int100Str,
                                pb,
                                AzAv_OS)
          THEN
            RETURN FALSE;
          END (* if *);
          IF NOT WrSignDesc("Szer. sekt. [ø]",
                            SpecConv.Int100Str,
                            ChiLoc[pb])
          THEN
            RETURN FALSE;
          END (* if *);
          IF NOT WrSignDesc("Symetria sek[%]",
                            SpecConv.Int10Str,
                            PhiLoc[pb])
          THEN
            RETURN FALSE;
          END (* if *);
        END (* for pb *);
        IF NOT WypiszStrefy( zonesBeg ,
                             locANieGs ) THEN
          RETURN FALSE;
        END;
        RETURN TRUE;
      END (* with L_results.anRes.an_OpisSektora *);
    END OpisSektoraP;

    PROCEDURE OpisProfB_P() : BOOLEAN;
    VAR
      pb : OdnDlaPomBleduT;

    BEGIN
      WITH L_results.anRes.an_OpisProfilB DO
        IF NOT PrintStdValues() THEN
          RETURN FALSE;
        END;
        FOR pb := pbTeodolit TO pbGPS DO
          IF pb = pbTeodolit
          THEN
            IF NOT WrPrnLn(0,
                           DLA_TEODOLITU)
            THEN
              RETURN FALSE;
            END (* if *);
          ELSE
            IF NOT WrPrnLn(0,
                           DLA_GPS)
            THEN
              RETURN FALSE;
            END (* if *);
          END (* if pb *);
          IF NOT WrSignDesc('Ustaw. osi [uA]',
                            SpecConv.Int10Str,
                            difAv0_PB[pb])
          THEN
            RETURN FALSE;
          END (* if *);
          IF NOT WrSignDesc('K¥t ust osi[ ø]',
                            SpecConv.Int100Str,
                            az0_PB[pb])
          THEN
            RETURN FALSE;
          END (* if *);
          IF NOT WrSignDesc('150-150 [ ø]',
                            SpecConv.Int100Str,
                            az150_150_PB[pb])
          THEN
            RETURN FALSE;
          END (* if *);
          IF NOT WrSignDesc("75-150 [ ø]",
                            SpecConv.Int100Str,
                            az75_150_PB[pb])
          THEN
            RETURN FALSE;
          END (* if *);
          IF NOT WrSignDesc("150-90 [ ø]",
                            SpecConv.Int100Str,
                            az150_90_PB[pb])
          THEN
            RETURN FALSE;
          END (* if *);
          IF NOT WrSignDesc("75-90 [ ø]",
                            SpecConv.Int100Str,
                            az75_90_PB[pb])
          THEN
            RETURN FALSE;
          END (* if *);
          IF NOT WrSignDesc("Szeroko˜† [ ø]",
                            SpecConv.Int100Str,
                            ChiLoc[pb])
          THEN
            RETURN FALSE;
          END (* if *);
          IF NOT WrSignDesc("Symetria [ %]",
                            SpecConv.Int10Str,
                            PhiLoc[pb])
          THEN
            RETURN FALSE;
          END (* if *);
          IF NOT WrSignDesc("Wyraz.L175Mn[ø]",
                            SpecConv.Int100Str,
                            H175Mn[pb])
          THEN
            RETURN FALSE;
          END (* if *);
          IF NOT WrSignDesc("Wyraz.L175Mx[ø]",
                            SpecConv.Int100Str,
                            H175Mx[pb])
          THEN
            RETURN FALSE;
          END (* if *);
          IF NOT WrSignDesc("Wyraz. L150[ø]",
                            SpecConv.Int100Str,
                            H150mn[pb])
          THEN
            RETURN FALSE;
          END (* if *);
          IF NOT WrSignDesc("Wyraz.P175Mn[ø]",
                            SpecConv.Int100Str,
                            HM175Mn[pb])
          THEN
            RETURN FALSE;
          END (* if *);
          IF NOT WrSignDesc("Wyraz.P175Mx[ø]",
                            SpecConv.Int100Str,
                            HM175Mx[pb])
          THEN
            RETURN FALSE;
          END (* if *);
          IF NOT WrSignDesc("Wyraz. P150[ø]",
                            SpecConv.Int100Str,
                            HM150mn[pb])
          THEN
            RETURN FALSE;
          END (* if *);
        END (* for pb *);
        RETURN TRUE;
      END (* with L_results.anRes.an_OpisProfilB *);
    END OpisProfB_P;

    PROCEDURE OpisBadDod_P() : BOOLEAN;
      (* MP - zmieniono ze wzgledu nz zmaine def dewAv *)

    BEGIN
      WITH L_results.anRes DO
        IF NOT WrSignDesc("Dew. ˜rednio[uA]",
                          SpecConv.Int10Str,
                          an_OpisBadDod.dewAv)
        THEN
          RETURN FALSE;
        END (* if *);
        IF NOT PrintStdValues() THEN
          RETURN FALSE;
        END;
        RETURN TRUE;
      END (* with L_results.anRes.an_OpisBadDod *);
    END OpisBadDod_P;

    PROCEDURE OpisDo10_P() : BOOLEAN;
    VAR
      pb : OdnDlaPomBleduT;

    BEGIN
      WITH L_results.anRes.an_OpisZasieg_do_10 DO
        IF NOT PrintStdValues() THEN
          RETURN FALSE;
        END;
        
        IF NOT WrPrnLn( 0, "Wyniki pomiar¢w dla sektora +/- 10ø" ) THEN
        RETURN FALSE;
        END(*if*);

        FOR pb := pbTeodolit TO pbGPS DO
          IF pb = pbTeodolit
          THEN
            IF NOT WrPrnLn(0,
                           DLA_TEODOLITU)
            THEN
              RETURN FALSE;
            END (* if *);
          ELSE
            IF NOT WrPrnLn(0,
                           DLA_GPS)
            THEN
              RETURN FALSE;
            END (* if *);
          END (* if pb *);
          IF NOT WrSignDesc("SS Min. [uV]",
                            SpecConv.Int2Str,
                            sS0_Min_ZW[pb])
          THEN
            RETURN FALSE;
          END (* if *);
        END (* for pb *);
        RETURN TRUE;
      END (* with L_results.anRes.an_OpisZasieg_do_10 *);
    END OpisDo10_P;

    PROCEDURE Zasieg_Szer_P( Ponad_35 : BOOLEAN ) : BOOLEAN;
    VAR
      pb : OdnDlaPomBleduT;

    BEGIN
       WITH L_results.anRes.an_OpisZasiegSzer DO
        IF Ponad_35 THEN
          IF NOT PrintStdValues() THEN
            RETURN FALSE;
          END;
          IF NOT WrPrnLn( 0, "Wyniki pomiar¢w dla sektora poza +/- 35ø. " ) THEN
            RETURN FALSE;
          END(*if*);
        ELSE
          IF NOT PrintStdValues() THEN
            RETURN FALSE;
          END;
          IF NOT WrPrnLn( 0, "Wyniki pomiar¢w dla sektora +/- 35ø. " ) THEN
            RETURN FALSE;
          END(*if*);
        END;
        
        FOR pb := pbTeodolit TO pbGPS DO
          IF pb = pbTeodolit
          THEN
            IF NOT WrPrnLn(0,
                           DLA_TEODOLITU)
            THEN
              RETURN FALSE;
            END (* if *);
          ELSE
            IF NOT WrPrnLn(0,
                           DLA_GPS)
            THEN
              RETURN FALSE;
            END (* if *);
          END (* if pb *);
          IF NOT WrSignDesc("SS min/150 [uV]",
                            SpecConv.Int2Str,
                            sS150_Min_ZS[pb])
          THEN
            RETURN FALSE;
          END (* if *);
          IF NOT WrSignDesc("SS min/90  [uV]",
                            SpecConv.Int2Str,
                            sS90_Min_ZS[pb])
          THEN
            RETURN FALSE;
          END (* if *);
        END (* for pb *);
      END (* with L_results.anRes.an_OpisZasiegSzer *);
      RETURN TRUE;
    END Zasieg_Szer_P;

    PROCEDURE Marker_P() : BOOLEAN;

    BEGIN
      IF NOT PrintStdValues() THEN
        RETURN FALSE;
      END;
      RETURN An_MkrLength(L_results.anRes.an_OpisMarker.mkrLength);
    END Marker_P;

  BEGIN (* OpisPomiaru *)
    PromienANieOrbita := CzyToJestPromien(anRes.procedure);
    PrnX := 0;
    PrnY := 0;
    IF NOT WrPrnLn(0,
                   header)
    THEN
      RETURN;
    END (* if *);
    IF NOT WrPrnLn(0,
                   "   Odbiornik       A               ³      B" )
    THEN
      RETURN;
    END (* if *);
    IF NOT WrPrnLn(0,
                   PASEK)
    THEN
      RETURN;
    END (* if *);
    CASE L_results.anRes.procedure OF
      L_CommonTypes.pUstawienieOsi_Struktura, L_CommonTypes.pAlarmOsi,
      L_CommonTypes.pUstawienieOsi_Szer_pA,
      L_CommonTypes.pUstawienieOsi_Waski_pA :
        converP := ToStringProcT(Card500Str);
        IF NOT OpisOsiP()
        THEN
          RETURN;
        END (* if *);
      |
      L_CommonTypes.pSzerSektora_pA, L_CommonTypes.pAlarmSzeroki_pA,
      L_CommonTypes.pAlarmWaski_pA :
        converP := ToStringProcT(Card500Str);
        IF NOT OpisSektoraP()
        THEN
          RETURN;
        END (* if *);
      |
      L_CommonTypes.pSzer_i_Osi_pB, L_CommonTypes.pAlarmSzer_pB,
      L_CommonTypes.pAlarmWaski_pB, L_CommonTypes.pWyrazistosc_na_d_katach :
        converP := Int100Str;
        IF NOT OpisProfB_P()
        THEN
          RETURN;
        END (* if *);
      |
      L_CommonTypes.pRownowagaModulacji, L_CommonTypes.pFazowanie :
        converP := ToStringProcT(Card500Str);
        IF NOT OpisBadDod_P()
        THEN
          RETURN;
        END (* if *);
      |
      L_CommonTypes.pZasieg_do_10 :
        converP := Int100Str;
        IF NOT OpisDo10_P()
        THEN
          RETURN;
        END (* if *);
      |
      L_CommonTypes.pZasieg_10_35, L_CommonTypes.pZasieg_ponad_35 :
        converP := Int100Str;
        IF NOT Zasieg_Szer_P( L_results.anRes.procedure = L_CommonTypes.pZasieg_ponad_35)
        THEN
          RETURN;
        END (* if *);
      |
      L_CommonTypes.pMarker :
        converP := ToStringProcT(Card500Str);
        IF NOT Marker_P()
        THEN
          RETURN;
        END (* if *);
    END (* case L_results.anRes.procedure *);
    IF NOT WrPrnLn(0,
                   PASEK)
    THEN
      RETURN;
    END (* if *);
    IF NOT WrF_TablicaOdci("Zestawienie odcink¢w wyst¥pienia flagi",
                               L_results.anRes.flagErr, converP)
    THEN
      RETURN;
    END (* if *);
  END OpisPomiaru;

  PROCEDURE Print(dwaOdniesienia : BOOLEAN) : BOOLEAN;
  VAR
    dscP   : Descs;
    Start,
    Odstep,
    s,
    idx    : INTEGER;
  VAR
    i,
    j                   : INTEGER;
    OdleglosciNaStronie : CARDINAL;
    Num                 : ARRAY [0 .. 99] OF CHAR;
    tr                  : L_Files.resultT;
    IleStron            : CARDINAL;
    Odniesienie         : OdnDlaPomBleduT;
    Zestaw              : CARDINAL;
    CoKtoraProbka       : CARDINAL;

    PROCEDURE Osie_P();
    VAR
      name : ARRAY [0 .. 20] OF CHAR;

    BEGIN
      IF Zestaw = 1
      THEN
        Odstep := DrawEpson.MaxX() DIV 3;
        L_Files.GetSigFileName(devL_Sg,
                               gOdb,
                               Num);
        InitA(dscP[0],
              Num,
              "Dewiacja (G)",
              DrawEpson.MaxX() * 5 DIV 6,
              DrawEpson.MaxX() DIV 3,
              -450,
              +450,
              FALSE);
        IF Odniesienie = pbTeodolit
        THEN
          name := "Blad kierunku (G/TEO)";
        ELSE
          name := "Blad kierunku (G/GPS)";
        END (* if Odniesienie *);
        FOR tr := L_Files.Dif TO L_Files.boundM DO
          L_Files.GetResFileName(tr,
                                 Odniesienie,
                                 gOdb,
                                 Num);
          InitA(dscP[1 + ORD(tr)-ORD(L_Files.Dif)],
                Num,
                name,
                DrawEpson.MaxX() * 2 DIV 3, (* zachodzi *)
                DrawEpson.MaxX() DIV 3,
                -450,
                +450,
                FALSE);
          name[0] := 0C;
        END (* for tr *);
        Odstep := (DrawEpson.MaxX() DIV 2) DIV 9;
        Start := Odstep DIV 2;
        L_Files.GetSigFileName(modL_Sg,
                               gOdb,
                               Num);
        InitA(dscP[5],
              Num,
              SigNam[modL_Sg, gOdb],
              Start,
              Odstep,
              +320,
              +480,
              FALSE);
        INC(Start,
            Odstep);
        L_Files.GetSigFileName(agcL_Sg,
                               gOdb,
                               Num);
        InitA(dscP[6],
              Num,
              SigNam[agcL_Sg, gOdb],
              Start,
              Odstep,
              2,
              agcL_SgMax,
              TRUE);
        INC(Start,
            Odstep);
        L_Files.GetSigFileName(agcM_Sg,
                               gOdb,
                               Num);
        InitA(dscP[7],
              Num,
              SigNam[agcM_Sg, gOdb],
              Start,
              Odstep,
              2,
              agcM_SgMax,
              TRUE);
        INC(Start,
            Odstep);
        InitB(dscP[8],
              "FLG(G)",
              FALSE,
              Start,
              Odstep,
              NAVG_flg);
        INC(Start,
            Odstep);
        InitB(dscP[9],
              "L.A(G)",
              FALSE,
              Start,
              Odstep,
              NAVG_AFlg);
        INC(Start,
            Odstep);
        InitB(dscP[10],
              "VHF",
              FALSE,
              Start,
              Odstep,
              Com_Aud_flg);
        INC(Start,
            Odstep);
        InitB(dscP[11],
              "M.W(G)",
              FALSE,
              Start,
              Odstep,
              Wew_Marker_G);
        INC(Start,
            Odstep);
        InitB(dscP[12],
              "M.S(G)",
              FALSE,
              Start,
              Odstep,
              Srd_Marker_G);
        INC(Start,
            Odstep);
        InitB(dscP[13],
              "M.Z(G)",
              FALSE,
              Start,
              Odstep,
              Zew_Marker_G);
        INC(Start,
            Odstep);
(*
        Files.GetCommSigFName(Files.CS_PilError,
                              FALSE (* LOC*),
                              Num);
        InitA(dscP[14],
              Num,
              "Blad poz.",
              Start,
              Odstep,
              -500,
              500,
              FALSE);
*)
      ELSE   (* zestaw 2 *)
        Odstep := DrawEpson.MaxX() DIV 3;
        L_Files.GetSigFileName(devL_Sg,
                               zOdb,
                               Num);
        InitA(dscP[0],
              Num,
              "Dewiacja (Z)",
              DrawEpson.MaxX() * 5 DIV 6,
              DrawEpson.MaxX() DIV 3,
              -450,
              +450,
              FALSE);
        IF Odniesienie = pbTeodolit
        THEN
          name := "Blad kierunku (Z/TEO)";
        ELSE
          name := "Blad kierunku (Z/GPS)";
        END (* if Odniesienie *);
        FOR tr := L_Files.Dif TO L_Files.boundM DO
          L_Files.GetResFileName(tr,
                                 Odniesienie,
                                 zOdb,
                                 Num);
          InitA(dscP[1 + ORD(tr)],
                Num,
                name,
                DrawEpson.MaxX() * 2 DIV 3, (* zachodzi *)
                DrawEpson.MaxX() DIV 3,
                -450,
                +450,
                FALSE);
          name[0] := 0C;
        END (* for tr *);
        Odstep := (DrawEpson.MaxX() DIV 2) DIV 10;
        Start := Odstep DIV 2;
        L_Files.GetSigFileName(modL_Sg,
                               zOdb,
                               Num);
        InitA(dscP[5],
              Num,
              SigNam[modL_Sg, zOdb],
              Start,
              Odstep,
              +320,
              +480,
              FALSE);
        INC(Start,
            Odstep);
        L_Files.GetSigFileName(agcL_Sg,
                               zOdb,
                               Num);
        InitA(dscP[6],
              Num,
              SigNam[agcL_Sg, zOdb],
              Start,
              Odstep,
              2,
              agcL_SgMax,
              TRUE);
        INC(Start,
            Odstep);
        L_Files.GetSigFileName(agcM_Sg,
                               zOdb,
                               Num);
        InitA(dscP[7],
              Num,
              SigNam[agcM_Sg, zOdb],
              Start,
              Odstep,
              2,
              agcM_SgMax,
              TRUE);   (* ??? *)
        INC(Start,
            Odstep);
        InitB(dscP[8],
              "FLG(Z)",
              FALSE,
              Start,
              Odstep,
              NAVZ_flg);
        INC(Start,
            Odstep);
        InitB(dscP[9],
              "L.A(Z)",
              FALSE,
              Start,
              Odstep,
              NAVZ_AFlg);
        INC(Start,
            Odstep);
        InitB(dscP[10],
              "MRK(Z)",
              FALSE,
              Start,
              Odstep,
              Wew_Marker_Z);
        InitB(dscP[11],
              "",
              FALSE,
              Start,
              Odstep,
              Srd_Marker_Z);
        InitB(dscP[12],
              "",
              FALSE,
              Start,
              Odstep,
              Zew_Marker_Z);
        INC(Start,
            Odstep);
        Files.GetCommSigFName(Files.CS_GPS_GDOP,
                              FALSE (* LOC*),
                              Num);
        InitA(dscP[14],
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
                              FALSE (* LOC*),
                              Num);
        InitA(dscP[15],
              Num,
              "NOS",
              Start,
              Odstep,
              0,
              10,
              FALSE);
        INC(Start,
            Odstep);
        InitB(dscP[16],
              "GPS.F",
              FALSE,
              Start,
              Odstep,
              GPS_flg);
        INC(Start,
            Odstep);
      END (* if Zestaw *);
    END Osie_P;

    PROCEDURE Sekt_P();
    VAR
      azOffset : INTEGER;
      name     : ARRAY [0 .. 20] OF CHAR;

    BEGIN
      Odstep := DrawEpson.MaxX() DIV 3;
      Start := Odstep DIV 2;
      WITH anRes DO
        azOffset := entier(real(secWith DIV 2) * real(offset) / 1500.00);
      END (* with anRes *);
      L_Files.GetSigFileName(devL_Sg,
                             gOdb,
                             Num);
      InitA(dscP[0],
            Num,
            "Dewiacja (G)",
            DrawEpson.MaxX() * 7 DIV 8,
            DrawEpson.MaxX() DIV 4,
            anRes.offset - 450,
            anRes.offset + 450,
            FALSE);
      INC(Start,
          Odstep);
      L_Files.GetSigFileName(devL_Sg,
                             zOdb,
                             Num);
      InitA(dscP[1],
            Num,
            "Dewiacja (Z)",
            DrawEpson.MaxX() * 6 DIV 8,
            DrawEpson.MaxX() DIV 4,
            anRes.offset - 450,
            anRes.offset + 450,
            FALSE);
      INC(Start,
          Odstep);
      L_Files.GetResFileName(L_Files.SecWith,
                             Odniesienie,
                             gOdb,
                             Num);
      IF Odniesienie = pbTeodolit
      THEN
        name := "Kat sektora (G/TEO)";
      ELSE
        name := "Kat sektora (G/GPS)";
      END (* if Odniesienie *);
      InitA(dscP[2],
            Num,
            name,
            DrawEpson.MaxX() * 5 DIV 8, (* zachodzi *)
            DrawEpson.MaxX() DIV 4,
            azOffset - 150,
            azOffset + 150,
            FALSE);
      L_Files.GetResFileName(L_Files.SecWith,
                             Odniesienie,
                             zOdb,
                             Num);
      IF Odniesienie = pbTeodolit
      THEN
        name := "Kat sektora (Z/TEO)";
      ELSE
        name := "Kat sektora (Z/GPS)";
      END (* if Odniesienie *);
      InitA(dscP[3],
            Num,
            name,
            DrawEpson.MaxX() * 4 DIV 8, (* zachodzi *)
            DrawEpson.MaxX() DIV 4,
            azOffset - 150,
            azOffset + 150,
            FALSE);
      Odstep := (DrawEpson.MaxX() * 3 DIV 8) DIV 11;
      Start := Odstep DIV 2;
      L_Files.GetSigFileName(modL_Sg,
                             gOdb,
                             Num);
      InitA(dscP[4],
            Num,
            SigNam[modL_Sg, gOdb],
            Start,
            Odstep,
            +320,
            +480,
            FALSE);
      INC(Start,
          Odstep);
      L_Files.GetSigFileName(modL_Sg,
                             zOdb,
                             Num);
      InitA(dscP[5],
            Num,
            SigNam[modL_Sg, zOdb],
            Start,
            Odstep,
            +320,
            +480,
            FALSE);
      INC(Start,
          Odstep);
      L_Files.GetSigFileName(agcL_Sg,
                             gOdb,
                             Num);
      InitA(dscP[6],
            Num,
            SigNam[agcL_Sg, gOdb],
            Start,
            Odstep,
            2,
            agcL_SgMax,
            TRUE);
      INC(Start,
          Odstep);
      L_Files.GetSigFileName(agcL_Sg,
                             zOdb,
                             Num);
      InitA(dscP[7],
            Num,
            SigNam[agcL_Sg, zOdb],
            Start,
            Odstep,
            2,
            agcL_SgMax,
            TRUE);
      INC(Start,
          Odstep);
      InitB(dscP[8],
            "FLG(G)",
            FALSE,
            Start,
            Odstep,
            NAVG_flg);
      INC(Start,
          Odstep);
      InitB(dscP[9],
            "FLG(Z)",
            FALSE,
            Start,
            Odstep,
            NAVZ_flg);
      INC(Start,
          Odstep);
      InitB(dscP[10],
            "L.A(G)",
            FALSE,
            Start,
            Odstep,
            NAVG_AFlg);
      INC(Start,
          Odstep);
      InitB(dscP[11],
            "V.A",
            FALSE,
            Start,
            Odstep,
            Com_Aud_flg);
      INC(Start,
          Odstep);
      Files.GetCommSigFName(Files.CS_GPS_GDOP,
                            FALSE (* LOC*),
                            Num);
      InitA(dscP[12],
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
                            FALSE (* LOC*),
                            Num);
      InitA(dscP[13],
            Num,
            "NOS",
            Start,
            Odstep,
            0,
            10,
            FALSE);
      INC(Start,
          Odstep);
      InitB(dscP[14],
            "GPS.F",
            FALSE,
            Start,
            Odstep,
            GPS_flg);
      INC(Start,
          Odstep);
    END Sekt_P;

    PROCEDURE ProfB();

    BEGIN
      Odstep := DrawEpson.MaxX() DIV 3;
      L_Files.GetSigFileName(devL_Sg,
                             gOdb,
                             Num);
      InitA(dscP[0],
            Num,
            "Dewiacja (G)",
            DrawEpson.MaxX() * 5 DIV 6,
            DrawEpson.MaxX() DIV 3,
            -4000,
            +4000,
            FALSE);
      L_Files.GetSigFileName(devL_Sg,
                             zOdb,
                             Num);
      InitA(dscP[1],
            Num,
            "Dewiacja (Z)",
            DrawEpson.MaxX() * 4 DIV 6,
            DrawEpson.MaxX() DIV 3,
            -4000,
            +4000,
            FALSE);
      Odstep := (DrawEpson.MaxX() * 2 DIV 3) DIV 13;
      Start := Odstep DIV 2;
      L_Files.GetSigFileName(modL_Sg,
                             gOdb,
                             Num);
      InitA(dscP[2],
            Num,
            SigNam[modL_Sg, gOdb],
            Start,
            Odstep,
            +320,
            +480,
            FALSE);
      INC(Start,
          Odstep);
      L_Files.GetSigFileName(modL_Sg,
                             zOdb,
                             Num);
      InitA(dscP[3],
            Num,
            SigNam[modL_Sg, zOdb],
            Start,
            Odstep,
            +320,
            +480,
            FALSE);
      INC(Start,
          Odstep);
      L_Files.GetSigFileName(agcL_Sg,
                             gOdb,
                             Num);
      InitA(dscP[4],
            Num,
            SigNam[agcL_Sg, gOdb],
            Start,
            Odstep,
            2,
            agcL_SgMax,
            TRUE);
      INC(Start,
          Odstep);
      L_Files.GetSigFileName(agcL_Sg,
                             zOdb,
                             Num);
      InitA(dscP[5],
            Num,
            SigNam[agcL_Sg, zOdb],
            Start,
            Odstep,
            2,
            agcL_SgMax,
            TRUE);
      INC(Start,
          Odstep);
      InitB(dscP[6],
            "FLG(G)",
            FALSE,
            Start,
            Odstep,
            NAVG_flg);
      INC(Start,
          Odstep);
      InitB(dscP[7],
            "FLG(Z)",
            FALSE,
            Start,
            Odstep,
            NAVZ_flg);
      INC(Start,
          Odstep);
      InitB(dscP[8],
            "L.A(G)",
            FALSE,
            Start,
            Odstep,
            NAVG_AFlg);
      INC(Start,
          Odstep);
      InitB(dscP[9],
            "L.A(Z)",
            FALSE,
            Start,
            Odstep,
            NAVZ_AFlg);
      INC(Start,
          Odstep);
      Files.GetCommSigFName(Files.CS_GPS_GDOP,
                            FALSE (* LOC*),
                            Num);
      InitA(dscP[10],
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
                            FALSE (* LOC*),
                            Num);
      InitA(dscP[11],
            Num,
            "NOS",
            Start,
            Odstep,
            0,
            10,
            FALSE);
      INC(Start,
          Odstep);
      InitB(dscP[12],
            "GPS.F",
            FALSE,
            Start,
            Odstep,
            GPS_flg);
    END ProfB;

    PROCEDURE MarkeryP();

    BEGIN
      Odstep := DrawEpson.MaxX() DIV 3;
      L_Files.GetSigFileName(agcM_Sg,
                             gOdb,
                             Num);
      InitA(dscP[0],
            Num,
            SigNam[agcM_Sg, gOdb],
            DrawEpson.MaxX() * 5 DIV 6,
            Odstep,
            2,
            agcM_SgMax,
            TRUE);
      L_Files.GetSigFileName(agcM_Sg,
                             zOdb,
                             Num);
      InitA(dscP[1],
            Num,
            SigNam[agcM_Sg, zOdb],
            DrawEpson.MaxX() * 4 DIV 6,
            Odstep,
            2,
            agcM_SgMax,
            TRUE);
      Odstep := (DrawEpson.MaxX() DIV 2) DIV 10;
      Start := Odstep DIV 2;
      L_Files.GetSigFileName(devL_Sg,
                             gOdb,
                             Num);
      InitA(dscP[2],
            Num,
            "Dew.(G)",
            Start,
            Odstep,
            -450,
            +450,
            FALSE);
      INC(Start, Odstep);
      L_Files.GetSigFileName(devL_Sg,
                             zOdb,
                             Num);
      InitA(dscP[3],
            Num,
            "Dew.(Z)",
            Start,
            Odstep,
            -450,
            +450,
            FALSE);
      INC(Start,
          Odstep);
      InitB(dscP[4],
            "FLG(G)",
            FALSE,
            Start,
            Odstep,
            NAVG_flg);
      INC(Start,
          Odstep);
      InitB(dscP[5],
            "FLG(Z)",
            FALSE,
            Start,
            Odstep,
            NAVZ_flg);
      INC(Start,
          Odstep);
      InitB(dscP[6],
            "M.W(G)",
            FALSE,
            Start,
            Odstep,
            Wew_Marker_G);
      INC(Start,
          Odstep);
      InitB(dscP[7],
            "M.S(G)",
            FALSE,
            Start,
            Odstep,
            Srd_Marker_G);
      INC(Start,
          Odstep);
      InitB(dscP[8],
            "M.Z(G)",
            FALSE,
            Start,
            Odstep,
            Zew_Marker_G);
      INC(Start,
          Odstep);
      InitB(dscP[9],
            "M.W(Z)",
            FALSE,
            Start,
            Odstep,
            Wew_Marker_Z);
      INC(Start,
          Odstep);
      InitB(dscP[10],
            "M.S(Z)",
            FALSE,
            Start,
            Odstep,
            Srd_Marker_Z);
      INC(Start,
          Odstep);
      InitB(dscP[11],
            "M.Z(Z)",
            FALSE,
            Start,
            Odstep,
            Zew_Marker_Z);
      INC(Start,
          Odstep);
    END MarkeryP;

  BEGIN
    CASE L_results.anRes.procedure OF
      L_CommonTypes.pUstawienieOsi_Struktura, L_CommonTypes.pAlarmOsi,
      L_CommonTypes.pUstawienieOsi_Szer_pA,
      L_CommonTypes.pUstawienieOsi_Waski_pA :
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
        InitAll(dscP,
                1 * 500,
                Pomiar,
                CoKtoraProbka);
        Osie_P;
      |
      L_CommonTypes.pSzerSektora_pA, L_CommonTypes.pAlarmSzeroki_pA,
      L_CommonTypes.pAlarmWaski_pA :
        IF NOT UstalSkalowanie(FALSE,
                               dwaOdniesienia,
                               NazwaPliku,
                               IleStron,
                               Odniesienie,
                               Zestaw,
                               CoKtoraProbka)
        THEN
          RETURN FALSE;
        END (* if *);
        InitAll(dscP,
                1 * 500,
                Pomiar,
                CoKtoraProbka);
        Sekt_P;
      |
      L_CommonTypes.pSzer_i_Osi_pB, L_CommonTypes.pAlarmSzer_pB,
      L_CommonTypes.pAlarmWaski_pB, L_CommonTypes.pWyrazistosc_na_d_katach,
      L_CommonTypes.pRownowagaModulacji, L_CommonTypes.pFazowanie,
      L_CommonTypes.pZasieg_do_10, L_CommonTypes.pZasieg_10_35,
      L_CommonTypes.pZasieg_ponad_35 :
        IF NOT UstalSkalowanie(FALSE,
                               dwaOdniesienia,
                               NazwaPliku,
                               IleStron,
                               Odniesienie,
                               Zestaw,
                               CoKtoraProbka)
        THEN
          RETURN FALSE;
        END (* if *);
        CASE L_results.anRes.procedure OF
          L_CommonTypes.pRownowagaModulacji, L_CommonTypes.pFazowanie :
          InitAll(dscP,
                  5 * 100,
                  Pomiar,
                  CoKtoraProbka);
        ELSE
          InitAll(dscP,
                  5 * 100,
                  Pomiar,
                  CoKtoraProbka);
        END;
        ProfB;
      |
      L_CommonTypes.pMarker :
        IF NOT UstalSkalowanie(FALSE,
                               dwaOdniesienia,
                               NazwaPliku,
                               IleStron,
                               Odniesienie,
                               Zestaw,
                               CoKtoraProbka)
        THEN
          RETURN FALSE;
        END (* if *);
        InitAll(dscP,
                1 * 500,
                Pomiar,
                CoKtoraProbka);
        MarkeryP;
    END (* case anRes.procedure *);
    DrawEpson.SetFont(DrawEpson.ft8x8);
    DrawEpson.SetTextMode(DrawEpson.mtSet);
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
      FOR i := 0 TO HIGH(dscP) DO
        WITH dscP[i] DO
          IF Uzywane
          THEN
            DrawEpson.SetTextMode(DrawEpson.mtSet);
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
            DrawEpson.SetTextMode(DrawEpson.mtSet);
(*
            DrawEpson.Line(SklStala - Zakres DIV 2,
                           0,
                           SklStala - Zakres DIV 2,
                           MaxY() - 1,
                           StyleSep);
*)
          END (* if Uzywane *);
        END (* with dscP *);
      END (* for i *);
*)
      (* eventy *)
      i := MaxY() * CoKtoraProbka;
      PolozenieNapisu := DrawEpson.MaxX() * 9 DIV 10;
      DrawEpson.SetDir(DrawEpson.t_90);
      DrawEpson.Mnoznik(SKALA_X_90,
                        SKALA_Y_90);
      PiszEventy.EnumEv(U_LOC,
                        CzyToJestPromien(anRes.procedure),
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
      FOR j := 0 TO HIGH(dscP) DO
        IF dscP[j].Uzywane
        THEN
          Opis(dscP[j],
               NOT ODD(j));
        END (* if dscP *);
      END (* for j *);
      DrawEpson.SetTextMode(DrawEpson.mtSet);
      FOR idx := 0 TO MaxY() - 1 DO
        FOR j := 0 TO HIGH(dscP) DO
          Point(dscP[j],
                idx);
        END (* for j *);
      END (* for idx *);
      (* znaczniki odleglosci *)
      DrawEpson.SetTextMode(DrawEpson.mtOr);
      OdleglosciNaStronie := MaxY() * CoKtoraProbka;
      IF CzyToJestPromien(anRes.procedure)
      THEN
        ZnacznikiOdleglosci(L_results.anRes.odnDlaPomOdl,
                            pbGPS,
                            Pomiar,
                            s,
                            TRUE,
                            Format360,
                            0);
      ELSE
        ZnacznikiOdleglosci(L_results.anRes.odnDlaPomOdl,
                            Odniesienie,
                            Pomiar,
                            s,
                            FALSE,
                            Format360,
                            0);
      END (* if CzyToJestPromien *);
      IF NOT DrawEpson.Out(DrawEpson.WrProc)
      THEN
        CloseAll(dscP);
        DrawEpson.Close;
        RETURN FALSE;
      ELSE
        DrawEpson.Close;
      END (* if *);
    END (* for s *);
    CloseAll(dscP);
    RETURN TRUE;
  END Print;

  PROCEDURE MakeRaport;

  BEGIN (* MakeRaport *)
    gOdb := anRes.glownyOdbiornik;
    IF gOdb = goA
    THEN
      zOdb := goB;
      NAVG_flg := NAVA_flg;
      NAVZ_flg := NAVB_flg;
      NAVG_AFlg := NAVA_Aud_flg;
      NAVZ_AFlg := NAVB_Aud_flg;
      Zew_Marker_G := oMkrFlgPosA;
      Srd_Marker_G := mMkrFlgPosA;
      Wew_Marker_G := iMkrFlgPosA;
      Zew_Marker_Z := oMkrFlgPosB;
      Srd_Marker_Z := mMkrFlgPosB;
      Wew_Marker_Z := iMkrFlgPosB;
    ELSE
      zOdb := goA;
      NAVG_flg := NAVB_flg;
      NAVZ_flg := NAVA_flg;
      NAVG_AFlg := NAVB_Aud_flg;
      NAVZ_AFlg := NAVA_Aud_flg;
      Zew_Marker_G := oMkrFlgPosB;
      Srd_Marker_G := mMkrFlgPosB;
      Wew_Marker_G := iMkrFlgPosB;
      Zew_Marker_Z := oMkrFlgPosA;
      Srd_Marker_Z := mMkrFlgPosA;
      Wew_Marker_Z := iMkrFlgPosA;
    END (* if gOdb *);
    SigNam[devL_Sg, gOdb] := "DEV(G)";
    SigNam[devL_Sg, zOdb] := "DEV(Z)";
    SigNam[modL_Sg, gOdb] := "MOD(G)";
    SigNam[modL_Sg, zOdb] := "MOD(Z)";
    SigNam[agcL_Sg, gOdb] := "SS(G)";
    SigNam[agcL_Sg, zOdb] := "SS(Z)";
    SigNam[agcM_Sg, gOdb] := "M.SS(G)";
    SigNam[agcM_Sg, zOdb] := "M.SS(Z)";
    Files.GetCommSigFName(Files.CS_GPS_GDOP,
                          Pomiar,
                          NazwaPliku);
    MakeHeader(header);

    IF NOT Print(TRUE)
    THEN
      RETURN;
    END (* if *);
    OpisPomiaru();
(*
    IF NOT WrPrnLn(0,
                   header)
    THEN
      RETURN;
    END (* if *);
*)
    PiszEventy.PiszNaDrukarce(U_LOC,
                              CzyToJestPromien(anRes.procedure),
                              PiszEventy.TypyEventow {PoczatekPomiaru..
                              BrakZnacznika});
  END MakeRaport;

BEGIN
  Odniesienie := pbGPS;
  Zestaw := 0;
  SigNam[devL_Sg,  goA] := "DEV(G)";
  SigNam[devL_Sg,  goB] := "DEV(Z)";
  SigNam[modL_Sg,  goA] := "MOD(G)";
  SigNam[modL_Sg,  goB] := "MOD(Z)";
  SigNam[agcL_Sg,  goA] := "SS(G)";
  SigNam[agcL_Sg,  goB] := "SS(Z)";
  SigNam[agcM_Sg,  goA] := "M.SS(G)";
  SigNam[agcM_Sg,  goB] := "M.SS(Z)";
END L_Print.
