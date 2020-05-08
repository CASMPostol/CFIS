(*.F- *)
(**********************************************************************
|  Title   : Raport koncowy dla GS
|  Author  : M.Morawski
|  System  : LOGITECH MODULA-2/86
|  History :
|    20-05-97: M.Postol
|      zle byly podstawiane katy sciezki w procedurach szeroksci sektora
|      bardzo duzo zmian
|
|  Copyright (C), CAS LODZ POLAND.
|  TEL: 42' 862 547, 42' 87 80 44 FAX/TEL: 42' 84 48 40
|
**********************************************************************)
(*.F+ *)
IMPLEMENTATION MODULE PI_Report;

FROM CommonTypes IMPORT
  Date, Str40, Str99, PolozenieGeo, OdnDlaPomBleduT, NadajnikT,
  GlownyOdbiornikT, NilValI, NilValC, SignalDsc, TimeAndDate, DisNilVal;
FROM NumberConversion IMPORT
  IntToString;
FROM Marks IMPORT
  AngMarksDsc, AngResetContiner, AngAddSample;
FROM L_DataBase IMPORT
  Lotnisko, MkrId_T;
FROM G_results IMPORT
  anRes, An_OpisSektoraT, SignalInSecDsc, An_OpisPokryciaT;
FROM FlagAnal IMPORT
  FlagsTable, MinPoczKonDis;
FROM FIO IMPORT
  File, Open, Close, CD, Read, GetFileStamp, Write, Create;
FROM Files IMPORT
  ExistDIR, GoHomeDir, GetALfaRefFName;
FROM G_Files IMPORT
  GetResFileName;
FROM StdIO IMPORT
  sprintf, sprintf2, sprintf3, sprintf4;
FROM CommonData IMPORT
  OdnDlaPomBledu, Promien, SciezkaOpisuPomiaru, NazwaOblotu,
  GlownyOdbiornik, Nadajnik1;
FROM G_Oblot IMPORT
  SciezkaDoKataloguOpisu;
FROM G_CommonTypes IMPORT
  Procedura, ProceduraT, Strona, StronaT, NumStrefy;
FROM L_CommonTypes IMPORT
  MkrLengthT;
FROM Strings IMPORT
  Assign, Length, Insert;
FROM PI_ArchDate IMPORT
  okTab, LoadData;
FROM SYSTEM IMPORT
  ADR, SIZE, BYTE, ADDRESS;
FROM MANAGER IMPORT
  Assert;
FROM GrafUtil IMPORT
  InfoBeep;
FROM Rap_Util IMPORT
  GetInteractiveData, Dummy;
FROM MathLib0 IMPORT
  real, entier;
FROM Print IMPORT
  WrPrn, WrPrnLn, WrLn, TextModeOutProc, PASEK, GWIAZDKI, PrnX, PrnY,
  SKALA_Y_90, SKALA_X_90;
FROM SpecConv IMPORT
  ToStringProcT;
IMPORT
  DrawEpson; (* bo kloci sie Close *)
FROM ASCII IMPORT
  ff;
FROM EventsMng IMPORT
  Events, EventKind;
FROM Czas IMPORT
  GetTimeAndDate;
FROM G_Print IMPORT
  NazwaProcedury;
FROM Tune IMPORT
  ILSfrqString;



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

CONST
  pomiar = FALSE;
  scaleDiv = 100; (* 1 stopien *)

TYPE
  OgrNumStrefy = [ns_toA..ns_BCorT];
  WStrefach = ARRAY OgrNumStrefy OF INTEGER;
  WlasnoscSektora = RECORD
    Symetria : INTEGER;
    Dol      : WStrefach;
    Gora     : WStrefach;
    Kat      : INTEGER;
    KatSciezki : INTEGER;
  END;
  MarkerArray = ARRAY MkrId_T OF INTEGER;
  KategoriaT  = [1..3];

  PomiarNadajnika = RECORD
    CzasyPomiarow                 : ARRAY ProceduraT, StronaT OF Date;
    UstawienieSciezki             : INTEGER;
    UstawienieSciezki_uA          : INTEGER;
    SredniaGlebokoscModulacji     : INTEGER;
    Przekroczenia                 : WStrefach;
    DlugosciMarkerowWgFlagi       : MarkerArray;
    DlugosciMarkerowWgAGC         : MarkerArray;
    AlarmyKata                    : ARRAY StronaT OF INTEGER;
    SzerokoscSektora,
    AlarmSektoraWaski,
    AlarmSektoraSzeroki            : WlasnoscSektora;
    ZasiegNaOsi,
    Zasieg8StZLewej,
    Zasieg8StZPrawej              : INTEGER;
    Wyrazistosc,
    ZabezpieczeniePrzedPrzeszkodami : INTEGER;
  END;

  RaportKoncowyDesc = RECORD
    NazwaInspekcji           : Str40;
    Lokalizacja              : Str40;
    Polozenie                : PolozenieGeo;
    Deklinacja               : REAL;
    Czestotliwosc            : Str40;
    Odpowiedzialny           : Str40;
    SamolotPomiarowy         : ARRAY[0..6] OF CHAR;
    Odbiornik                : GlownyOdbiornikT;
    DataOstatniejKalibracji  : Date;
    NazwaAparaturyPomiarowej : Str40;
    KierunekLadowania        : CARDINAL;
    KatGS                    : REAL;
    Kategoria                : KategoriaT;
    Pomiary                  : ARRAY NadajnikT OF PomiarNadajnika;
    UrzadzenieOK             : BOOLEAN;
  END;


CONST
  DATA_STR       = "%02d.%02d.%d";
  TOL_28_32      = "28%..32%";
  Tol17          = '+/-17%';
  Tol33          = '33%..67%';
  Tol42          = '42%..58%';
  Tol7           = '+/-7.5%';
  Tol4           = '+/-4.0%';
  Tol75          = '75%..85%';
(*  Tol_theta      = '+/-0.075 theta';*)
  Tol_10NM       = '10NM';
  Tol_180u       = '180uA';

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

  PROCEDURE WrVal( header : ARRAY OF CHAR;
                   fmt    : ARRAY OF CHAR;
                   podz   : CARDINAL;
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
      IF NOT WrTol(tol1, tol2, tol3) THEN
        RETURN FALSE;
      END;
      RETURN TRUE;
    END WrVal;

    PROCEDURE WartWStrefach( Co   : ARRAY OF CHAR;
                             ws_a,
                             ws_b : WStrefach;
                             skal : INTEGER;
                             Tol1 : ARRAY OF CHAR;
                             Tol2: ARRAY OF CHAR;
                             Tol3 : ARRAY OF CHAR
                              ) : BOOLEAN;
      VAR
        ns : OgrNumStrefy;
        Str : Str99;
        (*
          Tol : ARRAY KategoriaT, OgrNumStrefy OF ARRAY [0..6] OF CHAR;
        *)
      BEGIN
(*
        Tol[1][ns_toA]   := '+/-30uA';
        Tol[2][ns_toA]   := '+/-30uA';
        Tol[3][ns_toA]   := '+/-30uA';
        Tol[1][ns_AB]    := '+/-30uA';
        Tol[2][ns_AB]    := '+/-20uA';
        Tol[3][ns_AB]    := '+/-20uA';
        Tol[1][ns_BCorT] := '+/-30uA';
        Tol[2][ns_BCorT] := '+/-20uA';
        Tol[3][ns_BCorT] := '+/-20uA';
        Tol[1][ns_toA]   := '';
        Tol[2][ns_toA]   := '';
        Tol[3][ns_toA]   := '';
        Tol[1][ns_AB]    := '';
        Tol[2][ns_AB]    := '';
        Tol[3][ns_AB]    := '';
        Tol[1][ns_BCorT] := '';
        Tol[2][ns_BCorT] := '';
        Tol[3][ns_BCorT] := '';
*)

        IF NOT WrPrnLn( 0, Co ) THEN
          RETURN FALSE;
        END;
        FOR ns := MIN(OgrNumStrefy) TO MAX( OgrNumStrefy ) DO
          CASE ns OF
            ns_toA   : Str := 'do pkt. A';
          |
            ns_AB    :
              Str := 'mi©dzy pkt A i B';
          |
            ns_BCorT :
              IF Dane.Kategoria # 1 THEN
                Str := 'mi©dzy pkt B i progiem pasa';
              ELSE
                Str := 'mi©dzy pkt B i C';
              END;
          END;
          Insert( '    ', Str, 0 );
          IF NOT WrVal( Str,
                        "%y",
                        skal,
                        Tol1,
                        Tol2,
                        Tol3,
                        ws_a[ns],
                        ws_b[ns] )

          THEN
            RETURN FALSE;
          END;
        END;
        RETURN TRUE;
      END WartWStrefach;

    PROCEDURE WlasSektora( header : ARRAY OF CHAR;
                           str_kat: ARRAY OF CHAR;
                           ws_a,
                           ws_b   : WlasnoscSektora;
                           alarm  : BOOLEAN ) : BOOLEAN;
      VAR
        Tol : ARRAY KategoriaT OF Str40;
        r1, r2, r3   : REAL;
      BEGIN
        IF NOT WrLn() THEN
          RETURN FALSE;
        END;
        IF NOT WrPrnLn( 0, header ) THEN
          RETURN FALSE;
        END;
        IF NOT WrVal( "Symetria",
                      "%y%%",
                      10,
                      Tol33,
                      Tol42,
                      Tol42,
                      ws_a.Symetria,
                      ws_b.Symetria )

        THEN
          RETURN FALSE;
        END;
        IF NOT alarm THEN
          r1 := 2.0*0.07*Dane.KatGS;
          r2 := 2.0*0.14*Dane.KatGS;
          r3 := 2.0*0.1*Dane.KatGS;
          sprintf2( Tol[1], "%4.2lfø..%4.2lfø", r1, r2 );
          sprintf4( Tol[2], "D:%4.2lf-%4.2lf;G:%4.2lf-%4.2lf", r3, r2, r1, r2 );
          sprintf2( Tol[3], "%4.2lfø..%4.2lfø", r3, r2 );
        ELSE
          r1 := 2.0*(0.12 - 0.0375)*Dane.KatGS;
          r2 := 2.0*(0.12 + 0.0375)*Dane.KatGS;
          sprintf2( Tol[1], "%4.2lfø..%4.2lfø", r1, r2 );
          r1 := 1.25 * 2.0 * 0.12*Dane.KatGS;
          r2 := 0.75 * 2.0 * 0.12*Dane.KatGS;
          sprintf2( Tol[2], "%4.2lfø..%4.2lfø", r1, r2 );
          sprintf2( Tol[3], "%4.2lfø..%4.2lfø", r1, r2 );
        END;
        IF NOT WrVal( str_kat,
                      "%zø",
                      100,
                      Tol[1],
                      Tol[2],
                      Tol[3],
                      ws_a.Kat,
                      ws_b.Kat )

        THEN
          RETURN FALSE;
        END;

        IF NOT WrVal( "K¥t ˜cie¾ki",
                      "%zø",
                      100,
                      "",
                      "",
                      '',
                      ws_a.KatSciezki,
                      ws_b.KatSciezki )

        THEN
          RETURN FALSE;
        END;

        IF NOT alarm THEN
          r1 := (1.0-0.07)*Dane.KatGS;
          r2 := (1.0-0.14)*Dane.KatGS;
          r3 := (1.0-0.10)*Dane.KatGS;
          sprintf2( Tol[1], "%4.2lfø..%4.2lfø", r2, r1 );
          sprintf2( Tol[2], "%4.2lfø..%4.2lfø", r3, r2 );
          sprintf2( Tol[3], "%4.2lfø..%4.2lfø", r3, r2 );
        ELSE
          r1 := 0.0375*Dane.KatGS;
          sprintf( Tol[1], "+/-%4.2lfø", r1);
          Tol[2] := '+/-25%'; (* K0-1.25(K0-K75D) *)
          Tol[2] := '+/-25%'; (* K0-0.75(K0-K75D) *)
        END;

        IF NOT WartWStrefach( 'K¥t 75uA d¢ˆ[ø]', ws_a.Dol, ws_b.Dol, 100,
                              Tol[1],  Tol[2], Tol[3])
        THEN
          RETURN FALSE;
        END;

        IF NOT alarm THEN
          r1 := (1.0+0.07)*Dane.KatGS;
          r2 := (1.0+0.14)*Dane.KatGS;
          r3 := (1.0+0.10)*Dane.KatGS;
          sprintf2( Tol[1], "%4.2lfø..%4.2lfø", r1, r2 );
          sprintf2( Tol[2], "%4.2lfø..%4.2lfø", r1, r2 );
          sprintf2( Tol[3], "%4.2lfø..%4.2lfø", r3, r2 );
        ELSE
          Tol[1] := '';
          Tol[2] := '+/-25%'; (* K0+1.25(K75G-K0) *)
          Tol[2] := '+/-25%'; (* K0+0.75(K75G-K0) *)
        END;
        IF NOT WartWStrefach( 'K¥t 75uA g¢ra[ø]', ws_a.Gora, ws_b.Gora, 100,
                              Tol[1],  Tol[2], Tol[3] )
        THEN
          RETURN FALSE;
        END;

        RETURN TRUE;
      END WlasSektora;

    PROCEDURE WrMarker( header : ARRAY OF CHAR;
                        ma_a,
                        ma_b   : MarkerArray ) : BOOLEAN;

        PROCEDURE ConvMark( VAR nr : INTEGER );
          BEGIN
            IF nr # NilValI THEN
              nr := entier(real(nr) * 6076.1 / 500.0 + 0.5);
            END;
          END ConvMark;

      VAR
        Tol : ARRAY MkrId_T OF  ARRAY[0..11] OF CHAR;
        mt  : MkrId_T;
        Str : Str99;
      BEGIN
        Tol[InMkr] := '326-651ft';
        Tol[MMkr]  := '652-1304ft';
        Tol[OMkr]  := '1305-2609ft';
        IF NOT WrPrnLn( 0, header ) THEN
          RETURN FALSE;
        END;
        FOR mt := MIN( MkrId_T ) TO MAX( MkrId_T ) DO
          CASE mt OF
            InMkr : Str := 'wewn©trzny';
          | MMkr  : Str := '˜rodkowy';
          | OMkr  : Str := 'zewn©trzny';
          END;
          Insert( '  ', Str, 0 );
          ConvMark(ma_a[mt]);
          ConvMark(ma_b[mt]);
          IF NOT WrVal( Str,
                        "%dft",
                        1,
                        Tol[mt],
                        Tol[mt],
                        Tol[mt],
                        ma_a[mt],
                        ma_b[mt] )

          THEN
            RETURN FALSE;
          END;

        END;
        RETURN TRUE;
      END WrMarker;


  PROCEDURE RaportKoncowy(  );
    VAR
      c    : CHAR;
      n    : NadajnikT;
      td   : TimeAndDate;
      p    : ProceduraT;
      s    : StronaT;
      str  : Str99;
      a    : ADDRESS;
      dbl  : BOOLEAN;
      Tol_theta : Str40;
      r    : REAL;
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
      IF NOT WrPrnFmtLn( 0, "RAPORT Z INSPEKCJI ILS GS WYKONANY O GODZ. %02d:%02d DNIA %02d.%02d.%d", td ) THEN
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
                           "Poˆo¾enie geograficzne: %dø%02d'%02dE, %dø%02d'%02dN",
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
        c := CHR( ORD( Odbiornik ) + ORD('A' ));
        IF NOT WrPrnFmtLn( 0,
                           "Wyniki dotycz¥ toru pomiarowego odbiornika ->%c<-",
                           c )
        THEN
          RETURN;
        END;
        IF NOT WrPrnFmtLn( 0,
                           "Data ostatniej kalibracji: %02d.%02d.%d",
                           DataOstatniejKalibracji )
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
                           "K¥t ˜cie¾ki: %4.2lfø",
                           KatGS )
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
           NOT WrPrn( StartN[nB], "| Nad. zapasowy" ) OR
           NOT WrPrnLn( StartTol, "| Tolerancje" )
        THEN
          RETURN;
        END;

        (* daty *)

        FOR p := MIN( ProceduraT ) TO MAX( ProceduraT ) DO
          FOR s := MIN( StronaT ) TO MAX( StronaT ) DO
            FOR n := MIN( NadajnikT ) TO MAX( NadajnikT ) DO
              WITH Pomiary[n].CzasyPomiarow[p][s] DO
                NazwaProcedury( p, s, str );
                dbl := p <= pAlarmWaski_pA;
                IF (s = MIN( StronaT )) OR dbl THEN
                  IF n = MIN( NadajnikT ) THEN
                    IF NOT WrPrn(0, str ) THEN
                      RETURN;
                    END;
                  END;
                  IF NOT WrFmtNad( n, y # 0, DATA_STR, Pomiary[n].CzasyPomiarow[p][s] ) THEN
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

        IF NOT WrVal( "Ust. ˜cie¾ki",
                      "%yuA",
                      10,
                      '',
                      '',
                      '',
                      Pomiary[nA].UstawienieSciezki_uA,
                      Pomiary[nB].UstawienieSciezki_uA )
        THEN
          RETURN;
        END;

        IF NOT WrVal( "K¥t ˜cie¾ki",
                      "%zø",
                      100,
                      Tol7,
                      Tol7,
                      Tol4,
                      Pomiary[nA].UstawienieSciezki,
                      Pomiary[nB].UstawienieSciezki )
        THEN
          RETURN;
        END;

        IF NOT WrVal( "—r. gˆ©boko˜† mod.",
                      "%y%%",
                      10,
                      Tol75,
                      Tol75,
                      Tol75,
                      Pomiary[nA].SredniaGlebokoscModulacji,
                      Pomiary[nB].SredniaGlebokoscModulacji )
        THEN
          RETURN;
        END;

        IF NOT WartWStrefach( "Przekroczenia [%]",
                              Pomiary[nA].Przekroczenia,
                              Pomiary[nB].Przekroczenia,
                              10,
                              '5%',
                              '5%',
                              '5%'
                              )
        THEN
          RETURN
        END;

        r := (1.0-0.075)*KatGS;
        sprintf( Tol_theta, ">%4.2lfø", r );
        IF NOT WrVal( "Alarm k¥ta (d¢ˆ)",
                      "%zø",
                      100,
                      Tol_theta,
                      Tol_theta,
                      Tol_theta,
                      Pomiary[nA].AlarmyKata[Dol],
                      Pomiary[nB].AlarmyKata[Dol] )
        THEN
          RETURN;
        END;

        r := (1.0+0.1)*KatGS;
        sprintf( Tol_theta, "<%4.2lfø", r );
        IF NOT WrVal( "Alarm k¥ta (g¢ra)",
                      "%zø",
                      100,
                      Tol_theta,
                      Tol_theta,
                      Tol_theta,
                      Pomiary[nA].AlarmyKata[Gora],
                      Pomiary[nB].AlarmyKata[Gora] )
        THEN
          RETURN;
        END;

        r := (1.0-0.075)*KatGS;
        sprintf( Tol_theta, ">%4.2lf", r );
        IF NOT WlasSektora( "Szerok. sektora",
                            "Sektor",
                            Pomiary[nA].SzerokoscSektora,
                            Pomiary[nB].SzerokoscSektora,
                            FALSE )
        THEN
          RETURN;
        END;

        IF NOT WlasSektora( "Alarm sekt. w¥ski",
                            "Sektor w alarmie",
                            Pomiary[nA].AlarmSektoraWaski,
                            Pomiary[nB].AlarmSektoraWaski,
                            TRUE )
        THEN
          RETURN;
        END;

        IF NOT WlasSektora( "Alarm sekt. szeroki",
                            "Sektor w alarmie",
                            Pomiary[nA].AlarmSektoraSzeroki,
                            Pomiary[nB].AlarmSektoraSzeroki,
                            TRUE )
        THEN
          RETURN;
        END;

        IF NOT WrMarker( "Dˆug. ˜wiecenia wg flagi",
                         Pomiary[nA].DlugosciMarkerowWgFlagi,
                         Pomiary[nB].DlugosciMarkerowWgFlagi )
        THEN
          RETURN;
        END;

        IF NOT WrMarker( "Dˆug. ˜wiecenia wg AGC",
                         Pomiary[nA].DlugosciMarkerowWgAGC,
                         Pomiary[nB].DlugosciMarkerowWgAGC )
        THEN
          RETURN;
        END;

        IF NOT WrVal( "Zasi©g na osi",
                       "%xNM",
                       500,
                       Tol_10NM,
                       Tol_10NM,
                       Tol_10NM,
                       Pomiary[nA].ZasiegNaOsi,
                       Pomiary[nB].ZasiegNaOsi )
        THEN
          RETURN;
        END;

        IF NOT WrVal( "Zasi©g 8ø z prawej",
                       "%xNM",
                       500,
                       Tol_10NM,
                       Tol_10NM,
                       Tol_10NM,
                       Pomiary[nA].Zasieg8StZPrawej,
                       Pomiary[nB].Zasieg8StZPrawej )
        THEN
          RETURN;
        END;

        IF NOT WrVal( "Zasi©g 8ø z lewej",
                       "%xNM",
                       500,
                       Tol_10NM,
                       Tol_10NM,
                       Tol_10NM,
                       Pomiary[nA].Zasieg8StZLewej,
                       Pomiary[nB].Zasieg8StZLewej )
        THEN
          RETURN;
        END;

        r := 0.3*Dane.KatGS;
        sprintf( Tol_theta, "min %4.2lfø", r );
        IF NOT WrVal( "Wyrazisto˜†",
                      "%zdø",
                      100,
                      Tol_theta,
                      Tol_theta,
                      Tol_theta,
                      Pomiary[nA].Wyrazistosc,
                      Pomiary[nB].Wyrazistosc )
        THEN
          RETURN;
        END;

        IF NOT WrVal( "Zabezpieczenie",
                      "%zø",
                      100,
                      "",
                      "",
                      "",
                      Pomiary[nA].ZabezpieczeniePrzedPrzeszkodami,
                      Pomiary[nB].ZabezpieczeniePrzedPrzeszkodami )
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

  PROCEDURE JakaWysokosc(  ) : CARDINAL;
    VAR
      Wys : CARDINAL;
      i : INTEGER;
    BEGIN
      Wys := NilValC;
      WITH Events[FALSE] DO
        FOR i := 0 TO EventIDX DO
          WITH events[i] DO
            IF EventID = StartPomiaru THEN
              Wys := Wysokosc;
            END;
          END;
        END;
      END;
      RETURN Wys;
    END JakaWysokosc;

  PROCEDURE PrzygotujDane(  ) : BOOLEAN;

(*
    PROCEDURE PodstawJakiGdzie( VAR jg   : JakiGdzie;
                                    sv   : SignalDsc;
                                    prom : CARDINAL );
      BEGIN
        IF sv.val = NilValI THEN
          RETURN;
        ELSE
          IF (jg.val = NilValI) OR (sv.val > jg.val ) THEN
            jg.val := sv.val;
            jg.gdzie := prom;
          END;
        END;
      END PodstawJakiGdzie;
*)

    PROCEDURE UstawSektory( VAR str         : WStrefach;
                                NaPodstawie : SignalInSecDsc );
      VAR
        ns : OgrNumStrefy;
      BEGIN
        WITH Dane DO
          FOR ns := MIN( OgrNumStrefy ) TO MAX( OgrNumStrefy ) DO
            PodstawInteger( str[ns],
                            0,
                            NaPodstawie[ns][Odbiornik] );
          END;
        END;
      END UstawSektory;

    PROCEDURE PodstawWlasnoscSektora( VAR w   : WlasnoscSektora;
                                          sek : An_OpisSektoraT;
                                          s   : StronaT );
      BEGIN
        WITH Dane DO
          PodstawInteger( w.Symetria,
                          500,
                          sek.Phi_OS[Odbiornik]);
          IF (s = Dol) THEN
            UstawSektory( w.Dol, sek.AzAv_OS );
          ELSE
            UstawSektory( w.Gora, sek.AzAv_OS );
          END;
          PodstawInteger( w.Kat,
                          0,
                          sek.Chi_OS[Odbiornik]);
          (* MP to jest kat sektora a nie sciezki
          PodstawInteger( w.KatSciezki,
                          0,
                          sek.AzAv_OS[ns_AB][Odbiornik] );
          *)
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

    PROCEDURE Markery(     m   : MkrLengthT;
                       VAR flg : MarkerArray;
                       VAR agc : MarkerArray);
      BEGIN
        WITH Dane DO
          PodstawInteger( flg[InMkr],
                          7FFFH,
                          m.iMkrL_OM[Odbiornik] );
          PodstawInteger( flg[MMkr],
                          7FFFH,
                          m.mMkrL_OM[Odbiornik] );
          PodstawInteger( flg[OMkr],
                          7FFFH,
                          m.oMkrL_OM[Odbiornik] );
          (*****************************************************)
          PodstawInteger( agc[InMkr],
                          7FFFH,
                          m.iMkrA_OM[Odbiornik] );
          PodstawInteger( agc[MMkr],
                          7FFFH,
                          m.mMkrA_OM[Odbiornik] );
          PodstawInteger( agc[OMkr],
                          7FFFH,
                          m.oMkrA_OM[Odbiornik] );
        END;
      END Markery;

    PROCEDURE Min( a, b : CARDINAL ) : CARDINAL;
      BEGIN
        IF b = MAX( CARDINAL ) THEN
          RETURN a;
        END;
        IF a < b THEN
          RETURN a;
        ELSE
          RETURN b;
        END;
      END Min;

    (*
    PROCEDURE PodstawOdc( VAR dest    : CARDINAL;
                              src     : FlagsTable;
                              WartRat : INTEGER);
      VAR
        min : CARDINAL;
        i : CARDINAL;
      BEGIN
        min := MAX( CARDINAL );
        (* poszukiwanie minimalnej odleglosci *)
        IF src.w_IleOd = 0 THEN
          RETURN;
        END;
        FOR i := 1 TO src.w_IleOd DO
          WITH src.opis[i] DO
            min := Min( min, CARDINAL(pocz) );
            min := Min( min, CARDINAL(kon) );
          END;
        END;
        IF (dest = NilValC) OR (min < dest) THEN
          dest := min;
        END;
        IF dest = NilValC THEN
          dest := WartRat;
        END;
      END PodstawOdc;
      *)

      PROCEDURE  PodstawZasiegi
                 ( VAR SyntResult      : INTEGER;
                       an_OpisPokrycia : An_OpisPokryciaT;
                       glownyOdbiornik : GlownyOdbiornikT);
      VAR
        disRes : CARDINAL;
      BEGIN
        WITH an_OpisPokrycia DO
          disRes := MinPoczKonDis( odcinki_20uV[glownyOdbiornik] );
          IF disRes = DisNilVal
          THEN
            SyntResult := run_Start_OP;
          ELSE
            SyntResult := disRes DIV 5;
          END (* if w_IleOd *);
        END (* with an_OpisPokrycia *);
      END PodstawZasiegi;

    VAR
      n      : NadajnikT;
      f      : File;
      void   : CARDINAL;
      p      : ProceduraT;
      s      : StronaT;
      Tmp    : Str99;
      dataOk : okTab;
    BEGIN
      Dane.NazwaInspekcji := NazwaOblotu;
      WITH Dane DO
        IF NOT GetInteractiveData( UrzadzenieOK,
                                   Odpowiedzialny,
                                   SamolotPomiarowy,
                                   Dummy ) THEN
          RETURN FALSE;
        END;
        Deklinacja := Lotnisko.Deklinacja;
        Lokalizacja := Lotnisko.Nazwa;
        Polozenie := Lotnisko.Polozenie;
        ILSfrqString( Lotnisko.Czestotliwosc, Czestotliwosc );
        Odbiornik := GlownyOdbiornik;
        KierunekLadowania := Lotnisko.KierunekPasa;
        KatGS := FLOAT( Lotnisko.Kat_GS ) / 100.0;
        Kategoria  := Lotnisko.Kategoria;

        f := Open( "Kalibracja.ini" );
        Assert( f # MAX( CARDINAL ));
        WITH DataOstatniejKalibracji DO
          GetFileStamp( f, d, m, y, void, void, void );
        END;
        Close( f );

        FOR p := MIN( ProceduraT ) TO MAX( ProceduraT ) DO
          FOR s := MIN( StronaT ) TO MAX( StronaT ) DO
            FOR n := MIN( NadajnikT ) TO MAX( NadajnikT ) DO
              Strona := s;
              Procedura := p;
              Nadajnik1 := n;
              WITH Pomiary[n] DO
                SciezkaDoKataloguOpisu();
                Assign( SciezkaOpisuPomiaru, Tmp );
                Tmp[ Length( Tmp ) -1 ] := 0C;
                CzasyPomiarow[p][s].y := 0;
                IF ExistDIR( Tmp ) THEN
                  LoadData( dataOk );
                  GoHomeDir;
                  IF dataOk[FALSE] THEN
                    CzasyPomiarow[p][s] := anRes.data.d;
                    CASE p OF
                      pAlarmOsi:
                        Markery( anRes.an_OpisOsi.mkrLength,
                                 DlugosciMarkerowWgFlagi,
                                 DlugosciMarkerowWgAGC);
                        PodstawInteger( AlarmyKata[s],
                                        0,
                                        anRes.an_OpisOsi.azAv_PO[ns_AB, Odbiornik]);
                    | pSzerSektora_pA:
                        PodstawWlasnoscSektora( SzerokoscSektora,
                                                anRes.an_OpisSektora,
                                                s );
                    | pAlarmSzeroki_pA:
                        PodstawWlasnoscSektora( AlarmSektoraSzeroki,
                                                anRes.an_OpisSektora,
                                                s  );
                    | pAlarmWaski_pA:
                        PodstawWlasnoscSektora( AlarmSektoraWaski,
                                                anRes.an_OpisSektora,
                                                s  );
                    | pUstawienieOsi_Struktura:
                        PodstawInteger( SredniaGlebokoscModulacji,
                                        7FFFH,
                                        anRes.modAv_PO[Odbiornik]  );
                        WITH anRes.an_OpisOsi DO
                          Markery( mkrLength,
                                   DlugosciMarkerowWgFlagi,
                                   DlugosciMarkerowWgAGC);
                          PodstawInteger( UstawienieSciezki_uA,
                                          0,
                                          alig_PO[Odbiornik] );
                          PodstawInteger( UstawienieSciezki,
                                          0,
                                          anRes.an_OpisOsi.azAv_PO[ns_AB][Odbiornik] );
                          UstawSektory( Przekroczenia,
                                        roughness_PO );
                          PodstawInteger( SzerokoscSektora.KatSciezki,
                                          0,
                                          azAv_PO[ns_AB][Odbiornik] );
                        END;

                    | pUstawienieOsi_Szer_pA:
                        WITH anRes.an_OpisOsi DO
                          Markery( mkrLength,
                                   DlugosciMarkerowWgFlagi,
                                   DlugosciMarkerowWgAGC);
                          PodstawInteger( AlarmSektoraSzeroki.KatSciezki,
                                          0,
                                          azAv_PO[ns_AB][Odbiornik] );
                        END;

                    | pUstawienieOsi_Waski_pA:
                        WITH anRes.an_OpisOsi DO
                          Markery( anRes.an_OpisOsi.mkrLength,
                                   DlugosciMarkerowWgFlagi,
                                   DlugosciMarkerowWgAGC);
                          PodstawInteger( AlarmSektoraWaski.KatSciezki,
                                          0,
                                          azAv_PO[ns_AB][Odbiornik] );
                        END;
                    | pSzer_i_Osi_pB:
                        WITH anRes.an_OpisProfilB  DO
                          PodstawInteger( Wyrazistosc,
                                          7FFFH,
                                          az190_D_PB[Odbiornik]  );
                          PodstawInteger( Wyrazistosc,
                                          7FFFH,
                                          az75_D_PB[Odbiornik]  );
                        END;
                    | pAlarmSzer_pB:
                    | pAlarmWaski_pB:
                    | pRownowagaModulacji:
                    | pFazowanie:
                    | pZabezpieczenie:
                        PodstawInteger( ZabezpieczeniePrzedPrzeszkodami,
                                        0,
                                        anRes.an_OpisZabezpieczenie.az180Av[ns_AB][Odbiornik]  );
                    | pPokrycieWOsi:
                        PodstawZasiegi( ZasiegNaOsi, anRes.an_OpisPokrycia,
                                        Odbiornik)
                    | pPokrycie8stP:
                        PodstawZasiegi(Zasieg8StZPrawej ,
                                       anRes.an_OpisPokrycia,
                                       Odbiornik)
                    | pPokrycie8stL:
                        PodstawZasiegi( Zasieg8StZLewej,
                                        anRes.an_OpisPokrycia,
                                        Odbiornik)
                    END;
                  END;
                END;
              END;
            END;
          END;
        END;
      END;
      RETURN TRUE;
    END PrzygotujDane;

  PROCEDURE InitDane(  );


      PROCEDURE InitSektory( VAR ws : WStrefach );
        VAR
          ns : OgrNumStrefy;
        BEGIN
          FOR ns := MIN(OgrNumStrefy) TO MAX(OgrNumStrefy) DO
            ws[ns] := NilValI;
          END;
        END InitSektory;

      PROCEDURE InitWlSektora( VAR ws : WlasnoscSektora );
        BEGIN
          WITH ws DO
            Symetria := NilValI;
            InitSektory( Gora );
            InitSektory( Dol );
            Kat      := NilValI;
            KatSciezki := NilValI;
          END;
        END InitWlSektora;

      PROCEDURE InitMarkery( VAR m : MarkerArray );
        VAR
          mt : MkrId_T;
        BEGIN
          FOR mt := MIN(MkrId_T) TO MAX(MkrId_T) DO
            m[mt] := NilValI;
          END;
        END InitMarkery;

    VAR
      n : NadajnikT;
      s : StronaT;
      p : ProceduraT;
    BEGIN
      WITH Dane DO
        NazwaInspekcji[0] := 0C;
        Lokalizacja[0] := 0C;
        (*Polozenie :=            Cokolwiek *)
        Czestotliwosc := '';
        Odpowiedzialny[0] := 0C;
        Deklinacja := 0.0;
        Odbiornik := MIN( GlownyOdbiornikT );
        (* DataOstatniejKalibracji nieinicjowane *);
        NazwaAparaturyPomiarowej := 'CFIS-1';
        SamolotPomiarowy := 'SP-TPA';
        KierunekLadowania := 0;
        KatGS := 0.0;
        Kategoria := 1;
        FOR n := MIN( NadajnikT ) TO MAX( NadajnikT ) DO
          WITH Pomiary[n] DO
            FOR p := MIN( ProceduraT ) TO MAX( ProceduraT ) DO
              FOR s := MIN( StronaT ) TO MAX( StronaT ) DO
                CzasyPomiarow[p][s].y := 0;
              END;
            END;
            UstawienieSciezki             := NilValI;
            UstawienieSciezki_uA          := NilValI;
            SredniaGlebokoscModulacji     := NilValI;;
            InitSektory( Przekroczenia );
            FOR s := MIN( StronaT ) TO MAX( StronaT ) DO
              AlarmyKata[s] := NilValI;
            END;
            InitMarkery( DlugosciMarkerowWgFlagi );
            InitMarkery( DlugosciMarkerowWgAGC );

            InitWlSektora( SzerokoscSektora );
            InitWlSektora( AlarmSektoraSzeroki );
            InitWlSektora( AlarmSektoraWaski );
            ZasiegNaOsi                   := NilValI;
            Zasieg8StZPrawej              := NilValI;
            Zasieg8StZLewej               := NilValI;
            Wyrazistosc                   := NilValI;
            ZabezpieczeniePrzedPrzeszkodami := NilValI;
          END;
        END;
        UrzadzenieOK := FALSE;
      END;
    END InitDane;

BEGIN
  StartN[nA] := 38;
  StartN[nB] := 54;
  StartTol   := 70;
  InitDane;
END PI_Report.
