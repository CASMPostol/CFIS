(*.F- *)
(**********************************************************************
|  Title   : Raport koncowy dla GS 
|  Author  : M.Morawski
|  System  : LOGITECH MODULA-2/86 
|  History :
|    Rel 3.0. MPostol
|     - nowa definicja modulu Czas
|     - Program wywalal sie gdy wysokosc < 0 Uzdrowilem przez podstawienie 0
|       w takiej sytuacji
|
|   Rel 3.02 MPostol
|    - zly format dla polozenia geograficznego w raportach koncowych
|    - W przypadku braku 150 uV wypisuje poza norma, chociaz kat jest 
|      dostatecznie duzy
|   Rel 3.14: MPostol
|    - uwzglednio przy wydruku, ze pomiar wyrazistosci nie byl robiony.
|
|  Copyright (C), CAS LODZ POLAND.
|  TEL: 42' 686 25 47
|  mailto: techsupp@cas.com.pl
|  http: www.cas.com.pl
|
**********************************************************************)
(*.F+ *)

IMPLEMENTATION MODULE PI_Report;

FROM CommonTypes IMPORT
  Str40, Str99, PolozenieGeo, OdnDlaPomBleduT, NadajnikT,
  GlownyOdbiornikT, NilValI, NumStrefy, SignalDsc, SigNilVal;
FROM L_DataBase IMPORT
  Lotnisko;
FROM L_results IMPORT
  anRes, An_OpisSektoraT, An_OpisProfilBT;
FROM Files IMPORT
  ExistDIR, GoHomeDir;
FROM StdIO IMPORT
  sprintf, sprintf2;
FROM CommonData IMPORT
  OdnDlaPomBledu, SciezkaOpisuPomiaru, NazwaOblotu,
  GlownyOdbiornik, Nadajnik1, NazwaPlikuOpisu;
FROM L_Oblot IMPORT
  SciezkaDoKataloguOpisu;
FROM L_CommonTypes IMPORT
  Procedura, ProceduraT, Strona, StronaT, SignalInSecDsc, DevValueTab, 
  Clear175, Clear150;
FROM Strings IMPORT
  Assign, Length, Insert, ConstAssign;
FROM PI_ArchDate IMPORT
  okTab, LoadData;
FROM SYSTEM IMPORT
  ADR, BYTE, ADDRESS;
FROM Rap_Util IMPORT
  GetInteractiveData, Dummy;
FROM MathLib0 IMPORT
  real;
FROM Print IMPORT
  WrPrn, WrPrnLn, WrLn, PASEK, GWIAZDKI, PrnX, PrnY;
FROM SpecConv IMPORT
  entierCheck, GorszeBoMniejsze;
FROM ASCII IMPORT
  ff;
FROM Czas IMPORT
  GetTimeAndDate, TimeAndDate;
FROM L_Print IMPORT
  NazwaProcedury;
FROM Tune IMPORT
  ILSfrqString;
FROM Ini IMPORT
  GetPrivateProfileString;




TYPE
  OgrStronaT = [sL75..sP75];

(*
VAR
  DrukarkaSim : File; (* zamiast pisania na drukarke *)
CONST
  PrnFileName = "\Drukarka.sim";

  PROCEDURE FIOOut( ch : CHAR ) : BOOLEAN;
    BEGIN
      RETURN Write( DrukarkaSim, ADR( ch ), 1 );
    END FIOOut;
*)

TYPE
  KategoriaT   = [1..3];
(*
  JakiGdzie = RECORD
    val   : INTEGER;
    gdzie : INTEGER; (* promien *)
  END;
*)
  WStrefach = ARRAY NumStrefy OF INTEGER;
  WlasnoscSektora = RECORD
    Symetria : INTEGER;
    Lewo     : WStrefach;
    Prawo    : WStrefach;
    Kat      : INTEGER;
    Awar_Os  : INTEGER;
  END;
  T_StanWyrazistosci = ( Warazistosc_NOK, Wtarazistosc_WNormie, 
                         Wtarazistosc_NRobiona );
  PomiarNadajnika = RECORD
    CzasyPomiarow                 : ARRAY ProceduraT, OgrStronaT OF
                                      RECORD
                                        dt : TimeAndDate;
                                        st : StronaT;
                                      END;
    UstawienieOsiKierunku         : INTEGER;
    SredniaGlebokoscModulacji     : INTEGER;
    Przekroczenia                 : WStrefach;
    AlarmyOsi                     : ARRAY OgrStronaT OF INTEGER;
    SzerokoscSektora,
    AlarmSektoraWaski,
    AlarmSektoraSzeroki           : WlasnoscSektora;
    ZasiegDo10,
    ZasiegOd10Do35,
    ZasiegPonad35                 : INTEGER;
    Wyrazistosc,
    WyrazistoscDlaDuzychKatow     : T_StanWyrazistosci;
    EfektPolaryzacjiwPrawo,
    EfektPolaryzacjiwLewo         : INTEGER;
  END;

  RaportKoncowyDesc = RECORD
    NazwaInspekcji           : Str40;
    Lokalizacja              : Str40;
    Polozenie                : PolozenieGeo;
    Deklinacja               : REAL;
    Czestotliwosc            : Str40;
    Odpowiedzialny           : Str40;
    SamolotPomiarowy         : ARRAY[0..6] OF CHAR;
    Odniesienie              : OdnDlaPomBleduT;
    Odbiornik                : GlownyOdbiornikT;
    DataOstatniejKalibracji  : Str40;
    NazwaAparaturyPomiarowej : Str40;
    KierunekLadowania        : CARDINAL;
    Kategoria                : KategoriaT;
    KatILS                   : REAL;
    Pomiary                  : ARRAY NadajnikT OF PomiarNadajnika;
    UrzadzenieOK             : BOOLEAN;
  END;


CONST
  DATA_STR       = "%02d.%02d.%4d";
  Tol_5Prc       = "+/-5%";
  Tol_45_55      = "45%..55%";

VAR
  StartN : ARRAY NadajnikT OF CARDINAL;
  StartTol : CARDINAL;
VAR
  Dane : RaportKoncowyDesc;


  PROCEDURE WrPrnFmt( At   : INTEGER;
                      Fmt  : ARRAY OF CHAR;
                      Dane : ARRAY OF BYTE ) : BOOLEAN;
    VAR
      str   : ARRAY[0..99] OF CHAR;
    BEGIN
      sprintf( str, Fmt, Dane );
      IF NOT WrPrn( At, str ) THEN
        RETURN FALSE;
      ELSE
        RETURN TRUE;
      END;
    END WrPrnFmt;

  PROCEDURE WrFmtNad( Nad      : NadajnikT;
                      Valid    : BOOLEAN;
                      Fmt      : ARRAY OF CHAR;
                      Dane     : ARRAY OF BYTE ) : BOOLEAN;
    VAR
      str   : ARRAY[0..99] OF CHAR;
    BEGIN
      IF Valid THEN
        sprintf( str, Fmt, Dane );
      ELSE
        str := GWIAZDKI;
      END;
      IF NOT WrPrn( StartN[Nad], '| ' ) OR NOT WrPrn( StartN[Nad], str ) THEN
        RETURN FALSE;
      ELSE
        RETURN TRUE;
      END;
    END WrFmtNad;


  PROCEDURE WrPrnFmtLn( At   : INTEGER;
                        Fmt  : ARRAY OF CHAR;
                        Dane : ARRAY OF BYTE ) : BOOLEAN;
  BEGIN
    RETURN WrPrnFmt( At, Fmt, Dane ) & WrLn();
  END WrPrnFmtLn;

  PROCEDURE WrTol( VAR Kat1,
                       Kat2,
                       Kat3 : ARRAY OF CHAR )  : BOOLEAN;
    BEGIN
      IF NOT WrPrn( StartTol, "| " )   THEN
        RETURN FALSE;
      END;
      CASE Dane.Kategoria OF
        1:
        IF NOT WrPrnLn( 0, Kat1 ) THEN
          RETURN FALSE;
        END;
      | 2:
        IF NOT WrPrnLn( 0, Kat2 ) THEN
          RETURN FALSE;
        END;
      | 3:
        IF NOT WrPrnLn( 0, Kat3 ) THEN
          RETURN FALSE;
        END;
      END;
      RETURN TRUE;
    END WrTol;

  PROCEDURE WrValS( header : ARRAY OF CHAR;
                    war1   : BOOLEAN;
                    war2   : BOOLEAN;
                    val_a,
                    val_b  : ARRAY OF CHAR ) : BOOLEAN;
    VAR
      t : ARRAY[0..1] OF CHAR;
    BEGIN
      t[0] := 0C;
      IF NOT WrPrn(0, header ) THEN
        RETURN FALSE;
      END;
      IF NOT war1 THEN
        ConstAssign( "******", val_a );
      END;
      IF NOT war2 THEN
        ConstAssign( "******", val_b );
      END;
      IF NOT WrPrn( StartN[nA], '| ' ) OR NOT WrPrn( StartN[nA], val_a ) THEN
        RETURN FALSE;
      END;
      IF NOT WrPrn( StartN[nB], '| ' ) OR NOT WrPrn( StartN[nB], val_b ) THEN
        RETURN FALSE;
      END;
      IF NOT WrTol(t, t, t ) THEN
        RETURN FALSE;
      END;
      RETURN TRUE;
    END WrValS;

  PROCEDURE WrVal( header : ARRAY OF CHAR;
                   fmt    : ARRAY OF CHAR;
                   tol1,
                   tol2,
                   tol3   : ARRAY OF CHAR;
                   val_a,
                   val_b  : INTEGER ) : BOOLEAN;
    BEGIN
      IF NOT WrPrn(0, header ) THEN
        RETURN FALSE;
      END;
      IF NOT WrFmtNad( nA, val_a # NilValI, fmt, val_a ) THEN
        RETURN FALSE;
      END;
      IF NOT WrFmtNad( nB, val_b # NilValI, fmt, val_b ) THEN
        RETURN FALSE;
      END;
      IF NOT WrTol(tol1, tol2, tol3 ) THEN
        RETURN FALSE;
      END;
      RETURN TRUE;
    END WrVal;

    PROCEDURE WartWStrefach( Co   : ARRAY OF CHAR;
                             ws_a,
                             ws_b : WStrefach ) : BOOLEAN;
      VAR
        ns : NumStrefy;
        OstStrefa : NumStrefy;
        Str : Str99;
      BEGIN
        IF NOT WrPrnLn( 0, Co ) THEN
          RETURN FALSE;
        END;
        IF Dane.Kategoria # 3 THEN
          OstStrefa := ns_BCorT;
        ELSE
          OstStrefa := ns_DE;
        END;
        FOR ns := MIN(NumStrefy) TO OstStrefa DO
          CASE ns OF
            ns_toA : Str := 'do pkt. A';
          |
            ns_AB  : Str := 'mi©dzy pkt A i B'
          |
            ns_BCorT:
              IF Dane.Kategoria # 1 THEN
                Str := 'mi©dzy pkt B i progiem pasa';
              ELSE
                Str := 'mi©dzy pkt B i C';
              END;
          |
            ns_CorTD : Str := 'mi©dzy progiem pasa i pkt D';
          |
            ns_DE    : Str := 'mi©dzy pkt D i E';
          END;
          Insert( '    ', Str, 0 );
          IF NOT WrVal( Str,
                        "%zø",
                        Tol_5Prc,
                        Tol_5Prc,
                        Tol_5Prc,
                        ws_a[ns],
                        ws_b[ns] )

          THEN
            RETURN FALSE;
          END;
        END;
        RETURN TRUE;
      END WartWStrefach;

    PROCEDURE WlasSektora( header : ARRAY OF CHAR;
                           kat_str: ARRAY OF CHAR;
                           sw     : CARDINAL;
                           ws_a,
                           ws_b   : WlasnoscSektora ) : BOOLEAN;
      VAR
        Tol : ARRAY KategoriaT OF Str40;
        r1, r2, r3, r4 : REAL;
      BEGIN
        IF NOT WrLn() THEN
          RETURN FALSE;
        END;
        IF NOT WrPrnLn( 0, header ) THEN
          RETURN FALSE;
        END;
        IF NOT WrVal( "Symetria",
                      "%y%%",
                      Tol_45_55,
                      Tol_45_55,
                      Tol_45_55,
                      ws_a.Symetria,
                      ws_b.Symetria )

        THEN
          RETURN FALSE;
        END;
        CASE sw OF
          0 :
            r1 := 0.83*Dane.KatILS;
            r2 := 0.90*Dane.KatILS;
            r3 := 1.17*Dane.KatILS;
            r4 := 1.10*Dane.KatILS;
            sprintf2( Tol[1], "%4.2lfø..%4.2lfø", r1, r3 );
            sprintf2( Tol[2], "%4.2lfø..%4.2lfø", r1, r3 );
            sprintf2( Tol[3], "%4.2lfø..%4.2lfø", r2, r4 );
        | 1:
            r1 := 0.83*Dane.KatILS;
            r2 := 0.90*Dane.KatILS;
            sprintf( Tol[1], "%4.2lfø", r1 );
            sprintf( Tol[2], "%4.2lfø", r1 );
            sprintf( Tol[3], "%4.2lfø", r2 );
        | 2:
            r1 := 1.17*Dane.KatILS;
            r2 := 1.10*Dane.KatILS;
            sprintf( Tol[1], "%4.2lfø", r1 );
            sprintf( Tol[2], "%4.2lfø", r1 );
            sprintf( Tol[3], "%4.2lfø", r2 );
        END;
        IF NOT WrVal( kat_str,
                      "%zø",
                      Tol[1],
                      Tol[2],
                      Tol[3],
                      ws_a.Kat,
                      ws_b.Kat )

        THEN
          RETURN FALSE;
        END;

        IF NOT WartWStrefach( '  z lewej', ws_a.Lewo, ws_b.Lewo ) THEN
          RETURN FALSE;
        END;

        IF NOT WartWStrefach( '  z prawej', ws_a.Prawo, ws_b.Prawo ) THEN
          RETURN FALSE;
        END;

        RETURN TRUE;
      END WlasSektora;


  PROCEDURE RaportKoncowy(  );
    VAR
      c    : CHAR;
      n    : NadajnikT;
      td   : TimeAndDate;
      p    : ProceduraT;
      s    : OgrStronaT;
      str  : Str99;
      dbl  : BOOLEAN;
      Wyr  : ARRAY NadajnikT OF Str40;
      a    : ADDRESS;
    BEGIN
      IF NOT PrzygotujDane() THEN
        RETURN;
      END;

      (* symulacja drukarki *)
(*
      DrukarkaSim := Create( PrnFileName );
      TextModeOutProc := FIOOut;
*)
      PrnX := 0;
      PrnY := 0;
      GetTimeAndDate( td );
      IF NOT WrPrnFmtLn( 0, 
      "RAPORT Z INSPEKCJI ILS LOC WYKONANY DNIA. %02d:%02d:%04d O GODZ %02d.%02d", td ) THEN
        RETURN;
      END;
      WITH Dane DO
        IF NOT WrPrn( 0, "Nazwa Inspekcji: " ) OR
           NOT WrPrnLn( 0, NazwaInspekcji )
        THEN
          RETURN;
        END;
        IF NOT WrPrn( 0, "Lokalizacja: " ) OR
           NOT WrPrnLn( 0, Lokalizacja )
        THEN
          RETURN;
        END;
        IF NOT WrPrnFmtLn( 0,
              "Poˆo¾enie geograficzne: %dø%02d.%04d'E, %dø%02d.%04d'N",
                           Polozenie )
        THEN
          RETURN;
        END;
        IF NOT WrPrnFmtLn( 0, "Deklinacja: %3.1lf", Deklinacja ) THEN
          RETURN;
        END;
        a := ADR(Czestotliwosc);
        IF NOT WrPrnFmtLn( 0, "Cz©stotliwo˜†: %s", a ) THEN
          RETURN;
        END;
        IF NOT WrPrn( 0, "Samolot pomiarowy: " ) OR
           NOT WrPrnLn( 0, SamolotPomiarowy )
        THEN
          RETURN;
        END;
        IF NOT WrPrn( 0, "Odpowiedzialny za wykonanie pomiaru: " ) THEN
          RETURN;
        END;
        IF Odpowiedzialny[0] = 0C THEN
          IF NOT WrPrnLn( 0, '** Niezdefiniowany **' ) THEN
            RETURN;
          END;
        ELSE
          IF NOT WrPrnLn( 0, Odpowiedzialny ) THEN
            RETURN;
          END;
        END;
        IF NOT WrPrn( 0, "Odniesieniem dla pomiarow bˆ©du jest " ) THEN
          RETURN;
        END;
        IF Odniesienie = pbGPS THEN
          IF NOT WrPrnLn( 0, "GPS" ) THEN
            RETURN;
          END;
        ELSE
          IF NOT WrPrnLn( 0, "Teodolit" ) THEN
            RETURN;
          END;
        END;
        c := CHR( ORD( Odbiornik ) + ORD('A' ));
        IF NOT WrPrnFmtLn( 0,
                           "Wyniki dotycz¥ toru pomiarowego odbiornika ->%c<-",
                           c )
        THEN
          RETURN;
        END;
        IF NOT WrPrn( 0, "Data ostatniej kalibracji : " ) OR
           NOT WrPrnLn( 0,  DataOstatniejKalibracji)
        THEN
          RETURN;
        END;
        IF NOT WrPrn( 0, "Nazwa aparatury pomiarowej: " ) OR
           NOT WrPrnLn( 0, NazwaAparaturyPomiarowej )
        THEN
          RETURN;
        END;
        IF NOT WrPrnFmtLn( 0,
                           "Kierunek l¥dowania: %03d",
                           KierunekLadowania )
        THEN
          RETURN;
        END;
        IF NOT WrPrnFmtLn( 0,
                           "Kategoria ILS: %d",
                           Kategoria )
        THEN
          RETURN;
        END;
        IF NOT WrPrn( 0, "Daty wykonania pomiar¢w:" ) OR
           NOT WrPrn( StartN[nA], "| Nad. Gˆ¢wny" )   OR
           NOT WrPrn( StartN[nB], "| Nad. Zapasowy" ) OR
           NOT WrPrnLn( StartTol, "| Tolerancje" )
        THEN
          RETURN;
        END;

        (* daty *)

        FOR p := MIN( ProceduraT ) TO MAX( ProceduraT ) DO
          FOR s := MIN( OgrStronaT ) TO MAX( OgrStronaT ) DO
            FOR n := MIN( NadajnikT ) TO MAX( NadajnikT ) DO
              WITH Pomiary[n].CzasyPomiarow[p][s] DO
                NazwaProcedury( p, s, FALSE, str );
                dbl := (p <= pAlarmWaski_pA) OR (p = pMarker);
                IF (s = MIN( OgrStronaT )) OR dbl THEN
                  IF n = MIN( NadajnikT ) THEN
                    IF NOT WrPrn(0, str ) THEN
                      RETURN;
                    END;
                  END;
                  IF NOT WrFmtNad( n, dt.d.y # 0, DATA_STR, dt.d ) THEN
                    RETURN;
                  END;
                END;
              END;
            END;
            IF dbl THEN
              IF NOT WrLn() THEN
                RETURN
              END;
            END;
          END;
          IF NOT dbl & NOT WrLn() THEN
            RETURN
          END;
        END;

        (* Wyniki pomiarow *)
        IF NOT WrPrnLn( 0, PASEK ) THEN
          RETURN;
        END;

        IF NOT WrVal( "Ust. osi kierunku",
                      "%yuA",
                      "+/-14.8uA",
                      "+/-10.6uA",
                      "+/-4.2uA",
                      Pomiary[nA].UstawienieOsiKierunku,
                      Pomiary[nB].UstawienieOsiKierunku )
        THEN
          RETURN;
        END;

        IF NOT WrVal( "—r. gˆ©boko˜† mod.",
                      "%y%%",
                      "36..44%",
                      "36..44%",
                      "36..44%",
                      Pomiary[nA].SredniaGlebokoscModulacji,
                      Pomiary[nB].SredniaGlebokoscModulacji )
        THEN
          RETURN;
        END;

        IF NOT WartWStrefach( "Przekroczenia",
                              Pomiary[nA].Przekroczenia,
                              Pomiary[nB].Przekroczenia )
        THEN
          RETURN
        END;

        IF NOT WrVal( "Alarm osi (lewa strona)",
                      "%yuA",
                      "+/-14.8uA",
                      "+/-10.6uA",
                      "+/-8.5uA",
                      Pomiary[nA].AlarmyOsi[sL75],
                      Pomiary[nB].AlarmyOsi[sL75] )
        THEN
          RETURN;
        END;

        IF NOT WrVal( "Alarm osi (prawa strona)",
                      "%yuA",
                      "+/-14.8uA",
                      "+/-10.6uA",
                      "+/-8.5uA",
                      Pomiary[nA].AlarmyOsi[sP75],
                      Pomiary[nB].AlarmyOsi[sP75] )
        THEN
          RETURN;
        END;

        IF NOT WlasSektora( "Szerok. sektora",
                            "Sektor",
                            0,
                            Pomiary[nA].SzerokoscSektora,
                            Pomiary[nB].SzerokoscSektora )
        THEN
          RETURN;
        END;

        IF NOT WlasSektora( "Alarm sekt. w¥ski",
                            "Alarm",
                            1,
                            Pomiary[nA].AlarmSektoraWaski,
                            Pomiary[nB].AlarmSektoraWaski )
        THEN
          RETURN;
        END;

        IF NOT WlasSektora( "Alarm sekt. szeroki",
                            "Alarm",
                            2,
                            Pomiary[nA].AlarmSektoraSzeroki,
                            Pomiary[nB].AlarmSektoraSzeroki )
        THEN
          RETURN;
        END;

        IF NOT WrVal( "Zasi©g do +/-10ø",
                      "%duV",
                      "5uV",
                      "5uV",
                      "5uV",
                      Pomiary[nA].ZasiegDo10,
                      Pomiary[nB].ZasiegDo10 )
        THEN
          RETURN;
        END;

        IF NOT WrVal( "Zasi©g od +/-10ø do +/-35ø",
                      "%duV",
                      "5uV",
                      "5uV",
                      "5uV",
                      Pomiary[nA].ZasiegOd10Do35,
                      Pomiary[nB].ZasiegOd10Do35 )
        THEN
          RETURN;
        END;

        IF NOT WrVal( "Zasi©g ponad +/-35ø",
                      "%duV",
                      "5uV",
                      "5uV",
                      "5uV",
                      Pomiary[nA].ZasiegPonad35,
                      Pomiary[nB].ZasiegPonad35 )
        THEN
          RETURN;
        END;
        FOR n := nA TO nB DO
          CASE Pomiary[n].Wyrazistosc  OF
            Warazistosc_NOK :
              Wyr[n] := 'poza norm¥';
            |
            Wtarazistosc_WNormie :
              Wyr[n] := 'w normie';
            |
            Wtarazistosc_NRobiona :
              Wyr[n] := 'nie spr.';
          END;
        END;
        IF NOT WrValS( "Wyrazisto˜†",
             Dane.Pomiary[nA].CzasyPomiarow[pSzer_i_Osi_pB][sL75].dt.d.y # 0,
             Dane.Pomiary[nB].CzasyPomiarow[pSzer_i_Osi_pB][sL75].dt.d.y # 0,
                       Wyr[nA],
                       Wyr[nB] )
        THEN
          RETURN;
        END;

        FOR n := nA TO nB DO
          CASE Pomiary[n].WyrazistoscDlaDuzychKatow OF
            Warazistosc_NOK :
              Wyr[n] := 'poza norm¥';
            |
            Wtarazistosc_WNormie :
              Wyr[n] := 'w normie';
            |
            Wtarazistosc_NRobiona :
              Wyr[n] := 'nie spr.';
          END;
        END;
        IF NOT WrValS( "Wyrazisto˜† dla du¾ych k¥t¢w",
   Dane.Pomiary[nA].CzasyPomiarow[pWyrazistosc_na_d_katach][sL75].dt.d.y # 0,
   Dane.Pomiary[nB].CzasyPomiarow[pWyrazistosc_na_d_katach][sL75].dt.d.y # 0,
                       Wyr[nA],
                       Wyr[nB] )
        THEN
          RETURN;
        END;

        IF NOT WrVal( "Polaryzacja (w lewo)",
                      "%yuA",
                      "15uA",
                      "8uA",
                      "5uA",
                      Pomiary[nA].EfektPolaryzacjiwLewo,
                      Pomiary[nB].EfektPolaryzacjiwLewo )
        THEN
          RETURN;
        END;

        IF NOT WrVal( "Polaryzacja (w prawo)",
                      "%yuA",
                      "15uA",
                      "8uA",
                      "5uA",
                      Pomiary[nA].EfektPolaryzacjiwPrawo,
                      Pomiary[nB].EfektPolaryzacjiwPrawo )
        THEN
          RETURN;
        END;

        (* koniec *)
        IF NOT WrLn() THEN
          RETURN;
        END;
        IF UrzadzenieOK THEN
          IF NOT WrPrnLn( 0, "Urz¥dzenie speˆnia wymagania ICAO" ) THEN
            RETURN;
          END;
        ELSE
          IF NOT WrPrnLn( 0, "Urz¥dzenie nie speˆnia wymagaä ICAO" ) THEN
            RETURN;
          END;
        END;
        IF NOT WrLn() OR NOT WrPrnLn(0,"Uwagi") OR NOT WrLn() OR NOT WrLn() OR NOT WrLn() THEN
          RETURN;
        END;
        IF NOT WrPrnLn( 40, Odpowiedzialny ) THEN
          RETURN;
        END;
      END;
      IF NOT WrPrn( 0, ff ) THEN
        RETURN;
      END;
    END RaportKoncowy;

CONST
  StrefaPomSek = ns_AB;

    PROCEDURE AwaryjnaSzerokoscSektora( VAR ass : WlasnoscSektora );
    BEGIN
      IF ass.Kat = NilValI THEN
        IF (ass.Lewo[StrefaPomSek] # NilValI) &
           (ass.Prawo[StrefaPomSek] # NilValI )
        THEN
          ass.Kat := ass.Lewo[StrefaPomSek]+ass.Prawo[StrefaPomSek];
        END;
      END;
    END AwaryjnaSzerokoscSektora;

    PROCEDURE AwaryjnaSymetria( VAR ass : WlasnoscSektora );
    VAR
      OsR     : REAL;
      PolR    : REAL;
      SektR   : REAL;
    BEGIN
      IF ass.Symetria = NilValI THEN
        IF (ass.Awar_Os # NilValI ) & ( ass.Lewo[StrefaPomSek] # NilValI ) THEN
          OsR := real(ass.Awar_Os);
          PolR := real(ass.Lewo[StrefaPomSek]);
          SektR := real(ass.Kat);
          IF NOT entierCheck(ABS((PolR - OsR) / SektR * 1000.0) + 0.5,
                              ass.Symetria)
          THEN
            ass.Symetria := NilValI;
          END (* if *);
        END;
      END;
    END AwaryjnaSymetria;

  PROCEDURE WartosciAwaryjne( VAR ass : WlasnoscSektora );
    BEGIN
      AwaryjnaSzerokoscSektora( ass );
      AwaryjnaSymetria( ass );
    END WartosciAwaryjne;

  PROCEDURE PrzygotujDane(  ) : BOOLEAN;
  VAR
    minimum: INTEGER;

    PROCEDURE UstawSektory( VAR str         : WStrefach;
                                NaPodstawie : SignalInSecDsc );
      VAR
        ns : NumStrefy;
      BEGIN
        WITH Dane DO
          FOR ns := MIN( NumStrefy ) TO MAX( NumStrefy ) DO
            PodstawInteger( str[ns], 0, NaPodstawie[ns][Odniesienie][Odbiornik] );
          END;
        END;
      END UstawSektory;

    PROCEDURE PodstawWlasnoscSektora( VAR w   : WlasnoscSektora;
                                          sek : An_OpisSektoraT;
                                          s   : OgrStronaT );
      BEGIN
        WITH Dane DO
          PodstawInteger( w.Symetria,
                          500,
                          sek.PhiLoc[Odniesienie][Odbiornik]);
          IF (s = sL75) THEN
            UstawSektory( w.Lewo, sek.AzAv_OS );
          ELSE
            UstawSektory( w.Prawo, sek.AzAv_OS );
          END;
          PodstawInteger( w.Kat,
                          0,
                          sek.ChiLoc[Odniesienie][Odbiornik]);
        END;
      END PodstawWlasnoscSektora;

    PROCEDURE PodstawInteger( VAR jg            : INTEGER;
                                  WartNajlepsza : INTEGER;
                                  sv            : SignalDsc );
      BEGIN
        IF sv.val = NilValI THEN
          RETURN;
        ELSE
          IF (jg = NilValI) OR
             (ABS(sv.val-WartNajlepsza) > ABS(jg-WartNajlepsza) )
          THEN
            jg := sv.val;
          END;
        END;
      END PodstawInteger;

      PROCEDURE WiekszeNiz( dvt : INTEGER; n : INTEGER ) : BOOLEAN;
      BEGIN
        IF dvt = SigNilVal THEN
          RETURN FALSE;
        END;
        RETURN ABS( dvt ) > n;
      END WiekszeNiz;

      PROCEDURE MniejszeNiz( dvt : INTEGER; n : INTEGER ) : BOOLEAN;
      BEGIN
        IF dvt = SigNilVal THEN
          RETURN FALSE;
        END;
        RETURN ABS( dvt ) <= n;
      END MniejszeNiz;

      PROCEDURE Wyraz_Wyznacz 
                (    an_OpisProfilB : An_OpisProfilBT; 
                     Odniesienie    : OdnDlaPomBleduT;
                     Odbiornik      : GlownyOdbiornikT): T_StanWyrazistosci;
      BEGIN
        WITH an_OpisProfilB DO
          IF ( H150mn[Odniesienie][Odbiornik].val = SigNilVal ) OR
             ( H150mn[Odniesienie][Odbiornik].val = SigNilVal )
          THEN
            RETURN Wtarazistosc_NRobiona;
          ELSE  
            IF MniejszeNiz( H175Mn [Odniesienie][Odbiornik].val, Clear175 ) &
               MniejszeNiz( HM175Mn[Odniesienie][Odbiornik].val, Clear175 ) 
            THEN
              (* warunki rozbite na if bo kompilator sobie nie radz *)
              IF WiekszeNiz( H150mn[Odniesienie][Odbiornik ].val, Clear150 ) &
                 WiekszeNiz( HM150mn[Odniesienie][Odbiornik].val, Clear150 )  
              THEN
                RETURN Wtarazistosc_WNormie;
              END (* IF *);
            END (* IF WiekszeNiz *);
          END (* IF *);
        END (* WITH an_OpisProfilB *);
        RETURN Warazistosc_NOK;
      END Wyraz_Wyznacz;

      PROCEDURE  PDane_pSzer_i_Osi_pB
                 ( VAR Pom: PomiarNadajnika);
      BEGIN
        WITH Dane  DO
          WITH Pom DO
            WITH anRes.an_OpisProfilB DO
              Wyrazistosc := Wyraz_Wyznacz( anRes.an_OpisProfilB, 
                                            Odniesienie, 
                                            Odbiornik);
              WITH SzerokoscSektora  DO
                IF (Kat = SigNilVal) AND 
                   (
                   (Lewo[StrefaPomSek]  = SigNilVal) OR 
                   (Prawo[StrefaPomSek] = SigNilVal)  
                   )
                THEN
                  Kat := ChiLoc[Odniesienie][Odbiornik].val;
                END;
                IF ( Symetria = SigNilVal ) AND
                   (
                   (Lewo[StrefaPomSek]  = SigNilVal) OR 
                   (Prawo[StrefaPomSek] = SigNilVal) OR  
                   (Awar_Os             = SigNilVal)
                   )
                THEN
                  Symetria := PhiLoc[Odniesienie][Odbiornik].val;
                END (* IF ( Symetria = SigNilVal ) *);
              END (* WITH SzerokoscSektora *);
            END (* WITH anRes.an_OpisProfilB *);
          END (* WITH *);
        END (* WITH *);
      END PDane_pSzer_i_Osi_pB;

    VAR
      n      : NadajnikT;
      p      : ProceduraT;
      s      : OgrStronaT;
      Tmp    : Str99;
      dataOk : okTab;

    BEGIN
      InitDane;
      Dane.NazwaInspekcji := NazwaOblotu;
      WITH Dane DO
        IF NOT GetInteractiveData( UrzadzenieOK,
                                   Odpowiedzialny,
                                   SamolotPomiarowy,
                                   Dummy ) THEN
          RETURN FALSE;
        END;
        Deklinacja := Lotnisko.Deklinacja;
        KatILS     := real(Lotnisko.Szer_Sekt)/100.0;
        Lokalizacja := Lotnisko.Nazwa;
        Polozenie := Lotnisko.Polozenie;
        ILSfrqString( Lotnisko.Czestotliwosc, Czestotliwosc );
        Odniesienie  := OdnDlaPomBledu;
        Odbiornik := GlownyOdbiornik;
        KierunekLadowania := Lotnisko.KierunekPasa;
        Kategoria  := Lotnisko.Kategoria;
        GetPrivateProfileString( "DataKalibracji", 
                                 "Data", 
                                 "15-09-2000", 
                                 DataOstatniejKalibracji,
                                 NazwaPlikuOpisu );
        FOR p := MIN( ProceduraT ) TO MAX( ProceduraT ) DO
          FOR s := MIN( OgrStronaT ) TO MAX( OgrStronaT ) DO
            FOR n := MIN( NadajnikT ) TO MAX( NadajnikT ) DO
              Strona := s;
              Procedura := p;
              Nadajnik1 := n;
              WITH Pomiary[n] DO
                SciezkaDoKataloguOpisu();
                Assign( SciezkaOpisuPomiaru, Tmp );
                Tmp[ Length( Tmp ) -1 ] := 0C;
                CzasyPomiarow[p][s].dt.d.y := 0;
                IF ExistDIR( Tmp ) THEN
                  LoadData( dataOk );
                  GoHomeDir;
                  IF dataOk[FALSE] THEN
                    WITH CzasyPomiarow[p][s] DO
                      dt := anRes.data;
                      st := anRes.strona;
                    END;
                    CASE p OF
                      pAlarmOsi:
                        PodstawInteger( AlarmyOsi[s],
                                        0,
                                        anRes.an_OpisOsi.alig_PO[Odniesienie][Odbiornik]);
                    | pSzerSektora_pA:
                        PodstawWlasnoscSektora( SzerokoscSektora,
                                                anRes.an_OpisSektora,
                                                s );
                    | pAlarmWaski_pA:
                        PodstawWlasnoscSektora( AlarmSektoraWaski,
                                                anRes.an_OpisSektora,
                                                s  );
                    | pAlarmSzeroki_pA:
                        PodstawWlasnoscSektora( AlarmSektoraSzeroki,
                                                anRes.an_OpisSektora,
                                                s  );
                    | pUstawienieOsi_Struktura:
                        PodstawInteger( SredniaGlebokoscModulacji,
                                        7FFFH,
                                        anRes.modLocAv_PO[Odbiornik]  );
                        PodstawInteger( UstawienieOsiKierunku,
                                        0,
                                        anRes.an_OpisOsi.alig_PO[Odniesienie][Odbiornik] );
                        UstawSektory( Przekroczenia,
                                      anRes.an_OpisOsi.roughness_PO );
                        PodstawInteger( EfektPolaryzacjiwPrawo,
                                        0,
                                        anRes.an_OpisOsi.difAvPolR_PO[Odniesienie][Odbiornik]  );
                        PodstawInteger( EfektPolaryzacjiwLewo,
                                        0,
                                        anRes.an_OpisOsi.difAvPolL_PO[Odniesienie][Odbiornik]  );
                        PodstawInteger( SzerokoscSektora.Awar_Os,
                                        0,
                                        anRes.an_OpisOsi.AzAv_PO[StrefaPomSek][Odniesienie][Odbiornik] );
                    | pUstawienieOsi_Szer_pA:
                        PodstawInteger( AlarmSektoraSzeroki.Awar_Os,
                                        0,
                                        anRes.an_OpisOsi.AzAv_PO[StrefaPomSek][Odniesienie][Odbiornik] );
                    | pUstawienieOsi_Waski_pA:
                        PodstawInteger( AlarmSektoraWaski.Awar_Os,
                                        0,
                                        anRes.an_OpisOsi.AzAv_PO[StrefaPomSek][Odniesienie][Odbiornik] );
                    | pSzer_i_Osi_pB:
                        PDane_pSzer_i_Osi_pB(Pomiary[n]);
                    | pAlarmSzer_pB:
                        WITH anRes.an_OpisProfilB DO
                          WITH AlarmSektoraSzeroki DO
                            IF (Kat = SigNilVal) AND 
                               (
                               (Lewo[StrefaPomSek]  = SigNilVal) OR 
                               (Prawo[StrefaPomSek] = SigNilVal)  
                               )
                            THEN
                               Kat := ChiLoc[Odniesienie][Odbiornik].val;
                            END;
                            IF ( Symetria = SigNilVal ) AND
                               (
                               (Lewo[StrefaPomSek]  = SigNilVal) OR 
                               (Prawo[StrefaPomSek] = SigNilVal) OR  
                               (Awar_Os             = SigNilVal)
                               )
                            THEN
                              Symetria := PhiLoc[Odniesienie][Odbiornik].val;
                            END;
                          END;
                        END;
                    | pAlarmWaski_pB:
                        WITH anRes.an_OpisProfilB DO
                          WITH AlarmSektoraWaski  DO
                            IF (Kat = SigNilVal) AND 
                               (
                               (Lewo[StrefaPomSek]  = SigNilVal) OR 
                               (Prawo[StrefaPomSek] = SigNilVal)  
                               )
                            THEN
                               Kat := ChiLoc[Odniesienie][Odbiornik].val;
                            END;
                            IF ( Symetria = SigNilVal ) AND
                               (
                               (Lewo[StrefaPomSek]  = SigNilVal) OR 
                               (Prawo[StrefaPomSek] = SigNilVal) OR  
                               (Awar_Os             = SigNilVal)
                               )
                            THEN
                              Symetria := PhiLoc[Odniesienie][Odbiornik].val;
                            END;
                          END;
                        END;
                    | pRownowagaModulacji:
                    | pFazowanie:
                    | pWyrazistosc_na_d_katach:
                      WyrazistoscDlaDuzychKatow := Wyraz_Wyznacz
                                                     ( anRes.an_OpisProfilB, 
                                                       Odniesienie, 
                                                       Odbiornik);
                    | pZasieg_do_10:
                        ZasiegDo10 := 
                          anRes.an_OpisZasieg_do_10.sS0_Min_ZW[Odniesienie][Odbiornik].val;
                    | pZasieg_10_35:
                        WITH anRes.an_OpisZasiegSzer DO
                          ZasiegOd10Do35 := 
                                     sS150_Min_ZS[Odniesienie][Odbiornik].val;
                          GorszeBoMniejsze(ZasiegOd10Do35,  
                                     sS90_Min_ZS[Odniesienie][Odbiornik].val);
                        END (* with *);
                    | pZasieg_ponad_35:
                WITH  anRes.an_OpisZasiegSzer DO
                  ZasiegPonad35 := sS150_Min_ZS[Odniesienie][Odbiornik].val;
                  GorszeBoMniejsze( ZasiegPonad35,    
                                    sS90_Min_ZS[Odniesienie][Odbiornik].val);
                END (* with *);
                    | pMarker:
                    END;
                  END;
                END;
              END;
            END;
          END;
        END;
        FOR n := MIN( NadajnikT ) TO MAX( NadajnikT ) DO
          WITH Pomiary[n] DO
            WartosciAwaryjne( SzerokoscSektora );
            WartosciAwaryjne( AlarmSektoraWaski );
            WartosciAwaryjne( AlarmSektoraSzeroki );
          END;
        END;
      END;
      RETURN TRUE;
    END PrzygotujDane;

  PROCEDURE InitDane(  );


      PROCEDURE InitSektory( VAR ws : WStrefach );
        VAR
          ns : NumStrefy;
        BEGIN
          FOR ns := MIN(NumStrefy) TO MAX(NumStrefy) DO
            ws[ns] := NilValI;
          END;
        END InitSektory;

      PROCEDURE InitWlSektora( VAR ws : WlasnoscSektora );
        BEGIN
          WITH ws DO
            Symetria := NilValI;
            InitSektory( Lewo );
            InitSektory( Prawo );
            Kat      := NilValI;
            Awar_Os  := NilValI;
          END;
        END InitWlSektora;

    VAR
      n : NadajnikT;
      s : OgrStronaT;
      p : ProceduraT;
    BEGIN
      WITH Dane DO
        NazwaInspekcji[0] := 0C;
        Lokalizacja[0] := 0C;
        (*Polozenie :=            Cokolwiek *)
        Czestotliwosc[0] := 0C;
        Odpowiedzialny[0] := 0C;
        Deklinacja := 0.0;
        KatILS := 0.0;
        Odniesienie := MIN( OdnDlaPomBleduT );
        Odbiornik := MIN( GlownyOdbiornikT );
        (* DataOstatniejKalibracji nieinicjowane *);
        NazwaAparaturyPomiarowej := 'CFIS-1';
        SamolotPomiarowy := 'SP-TPA';
        KierunekLadowania := 0;
        Kategoria := 1;
        FOR n := MIN( NadajnikT ) TO MAX( NadajnikT ) DO
          WITH Pomiary[n] DO
            FOR p := MIN( ProceduraT ) TO MAX( ProceduraT ) DO
              FOR s := MIN( OgrStronaT ) TO MAX( OgrStronaT ) DO
                WITH CzasyPomiarow[p][s] DO
                  dt.d.y := 0;
                  st := MIN( StronaT );
                END;
              END;
            END;
            UstawienieOsiKierunku         := NilValI;
            SredniaGlebokoscModulacji     := NilValI;;
            InitSektory( Przekroczenia );
            FOR s := MIN( OgrStronaT ) TO MAX( OgrStronaT ) DO
              AlarmyOsi[s] := NilValI;
            END;
            InitWlSektora( SzerokoscSektora );
            InitWlSektora( AlarmSektoraWaski );
            InitWlSektora( AlarmSektoraSzeroki );
            ZasiegDo10                    := NilValI;
            ZasiegOd10Do35                := NilValI;
            ZasiegPonad35                 := NilValI;
            Wyrazistosc                   := Warazistosc_NOK;
            WyrazistoscDlaDuzychKatow     := Warazistosc_NOK;
            EfektPolaryzacjiwPrawo        := NilValI;
            EfektPolaryzacjiwLewo         := NilValI;
          END;
        END;
        UrzadzenieOK := FALSE;
      END;
    END InitDane;

BEGIN
  StartN[nA] := 38;
  StartN[nB] := 54;
  StartTol   := 70;
  (* InitDane; W VOR sie wywalal tu nie potrzebne *)
END PI_Report.
