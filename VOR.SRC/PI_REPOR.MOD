(*.F- *)
(**********************************************************************
|  Title   : Raport koncowy dla VOR
|  Author  : M.Morawski
|  System  : LOGITECH MODULA-2/86
|  History :
|    05-27-97 10:21pm : MM
|      Odwrocony wykres dewiacji
|   06-06-97 11:03am : MM i MP
|      W danych orbity nie byl przygotowany na brak danych (DME jest,
|      VORa nie ma)
|   Rel 3.0. MPostol.
|     zmiany spowodowane przeniesienm OrbitDsc do VORO_avrage.
|     - Program wywalal sie gdy wysokosc < 0 Uzdrowilem przez podstawienie 0
|       w takiej sytuacji
|   Rel 3.02 MPostol
|   - zly format dla polozenia geograficznego w raportach koncowych
|   Rel 3.14: MPostol
|     - Kosmetyczne zmiany - nie byly drukowane odcinki bledu > 2 dla 
|       nadajnika zapasowego.
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
  GlownyOdbiornikT, NilValI, SignalDsc, NilValC, SigNilVal, InitSignalDsc, 
  NumStrefy, flgTab, GetTranName;

FROM Czas IMPORT
  Date, GetTimeAndDate, TimeAndDate;

FROM NumberConversion IMPORT
  IntToString;

FROM Marks IMPORT
  AngMarksDsc, AngResetContiner, AngAddSample, OpisStanuLuku, 
  InicjujOpisStanuLuku, SegZakonczony;

FROM V_Database IMPORT
  IleKierunkow, CurVor1;

FROM V_results IMPORT
  anRes, Parametr, Signals;

FROM FlagAnal IMPORT
  FlagsTable, SumaDlugosciSig;

FROM FIO IMPORT
  File, Open, Close, CD, Read, GetFileStamp, Write, Create;

FROM Files IMPORT
  ExistDIR, GoHomeDir, GetALfaRefFName;

FROM V_Files IMPORT
  GetResFileName;

FROM StdIO IMPORT
  sprintf, sprintf2, sprintf3, sprintf4;

FROM CommonData IMPORT
  OdnDlaPomBledu, Promien, SciezkaOpisuPomiaru, NazwaOblotu,
  GlownyOdbiornik, Nadajnik1, NazwaPlikuOpisu;

FROM V_Oblot IMPORT
  SciezkaDoKataloguOpisuUst;

FROM V_CommonTypes IMPORT
  Procedura, ProceduraT;

FROM Strings IMPORT
  Assign, Length, Insert, Concat;

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
  real;

FROM VORO_avrage IMPORT
  PartIdx, OrbitDsc, OrbitDscClear;

FROM Print IMPORT
  WrPrn, WrPrnLn, WrLn, TextModeOutProc, PASEK, GWIAZDKI, PrnX, PrnY,
  SKALA_Y_90, SKALA_X_90, WrFlagsTableWHeading;

IMPORT
  SpecConv; (* bo nie mozna zaimportowac procedury Sub bo sie kloci z V_results.Sub *)

IMPORT
  DrawEpson; (* bo kloci sie Close *)
FROM ASCII IMPORT
  ff;
FROM EventsMng IMPORT
  Events, EventKind;
FROM Ini IMPORT
  GetPrivateProfileString;
FROM MMA_Cout IMPORT
  AvrDscr, MMA_SignalDsc, Init_MMA_SignalDsc, Count_MMA_SignalDsc, 
  Init_AvrDscr, MinMaxAvr;
  
  FROM WorseBecause IMPORT
    WorseBGreater;

  FROM FlagAnal IMPORT
    FlagErr_Anal, InitFlagErr;

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
  pomiar   = FALSE;
  scaleDiv = 100; (* 1 stopien *)

TYPE
  KazdyPromien = RECORD
    Data       : Date;
    SredniBlad : INTEGER;
    Promien    : CARDINAL;
  END;
  JakiGdzie = RECORD
    val   : INTEGER;
    gdzie : INTEGER; (* promien *)
  END;
  JakiGdzieC = RECORD
    val   : CARDINAL;
    gdzie : INTEGER; (* promien *)
  END;

  IndexLuku4Deg   = [0..360 DIV 4 -1];
  PomiarNadajnika = RECORD
    PromieniePublikowane          : ARRAY [0..IleKierunkow-1] OF KazdyPromien;
    PromienieDodatkowe            : ARRAY [0..IleKierunkow-1] OF KazdyPromien;
    PromieniePublikowaneZas       : ARRAY [0..IleKierunkow-1] OF KazdyPromien;
    PromienieDodatkoweZas         : ARRAY [0..IleKierunkow-1] OF KazdyPromien;
    KiedyOrbitaBlad               : Date;
    KiedyOrbitaZasieg             : Date;
    WysokoscLotuNaOrbicieZas      : CARDINAL;
    WysokoscLotuNaPromieniuZas    : CARDINAL;
    WysokoscLotuNaOrbiciePom      : CARDINAL;
    PromienLotuNaOrbiciePom       : REAL;
    Srednie_REF_Promien,
    Srednie_VAR_Promien,
    Srednie_SUB_Promien           : JakiGdzie;
    Srednie_REF_Orbita,
    Srednie_VAR_Orbita,
    Srednie_SUB_Orbita            : INTEGER;
    MaxFalowanie                  : JakiGdzie;
    MaxUgiecie                    : JakiGdzie;
    PolaryzacjaPrawo,
    PolaryzacjaLewo               : JakiGdzie;
    ZasiegNaPromieniu             : JakiGdzieC;
    ZasiegNaOrbicie               : CARDINAL; (* ilosc odcinkow *)
    RozpietoscBleduNaPromieniach  : INTEGER;
    SredniBladNaOrbicie           : OrbitDsc;
    BladCoStopien                 : ARRAY[0..360] OF INTEGER;
    BladCo4Stopnie                : ARRAY IndexLuku4Deg  OF INTEGER;
    blad3Deg                      : FlagsTable ;
  END;

  RaportKoncowyDesc = RECORD
    NazwaInspekcji           : Str40;
    Lokalizacja              : Str40;
    Polozenie                : PolozenieGeo;
    Deklinacja               : REAL;
    Czestotliwosc            : REAL;
    Odpowiedzialny           : Str40;
    SamolotPomiarowy         : ARRAY[0..6] OF CHAR;
    Odniesienie              : OdnDlaPomBleduT;
    Odbiornik                : GlownyOdbiornikT;
    DataOstatniejKalibracji  : Str40;
    NazwaAparaturyPomiarowej : Str40;
    RoznicaRozpietosci       : SignalDsc;
    RoznicaRozpietosci4Deg   : SignalDsc;
    Pomiary                  : ARRAY NadajnikT OF PomiarNadajnika;
    UrzadzenieOK             : BOOLEAN;
  END;


CONST
  DATA_STR       = "%02d.%02d.%d";
  TOL_28_32      = "28..32%";

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

  PROCEDURE WrJakiGdzie( Tytul      : ARRAY OF CHAR;
                         FmtStr     : ARRAY OF CHAR;
                         podz       : CARDINAL;
                         ConvProc   : SpecConv.ToStringProcT;
                         jgA, jgB   : JakiGdzie;
                         Tolerancja : ARRAY OF CHAR
                       ) : BOOLEAN;
    VAR
      polozenie : Str99;

      PROCEDURE Wr( n : NadajnikT; VAR jg : JakiGdzie ) : BOOLEAN;
        BEGIN
          IF (ConvProc = SpecConv.Int2Str) & (jg.gdzie >= 360) THEN
            polozenie := GWIAZDKI;
          ELSIF (ConvProc = SpecConv.Int100Str) & (jg.gdzie = NilValI) THEN
            polozenie := GWIAZDKI;
          ELSE
            ConvProc( jg.gdzie, polozenie, 4 );
          END;
          IF NOT WrFmtNad( n, jg.val # NilValI, FmtStr, jg.val ) THEN
            RETURN FALSE;
          END;
          IF NOT WrPrn( 0, '/' ) OR
             NOT WrPrn( 0, polozenie ) OR
             NOT WrPrn( 0, "ø" )
          THEN
            RETURN FALSE;
          END;
          RETURN TRUE;
        END Wr;

    BEGIN
      IF NOT WrPrn( 0, Tytul ) THEN
        RETURN FALSE;
      END;
      IF NOT Wr( nA, jgA ) THEN
        RETURN FALSE;
      END;
      IF NOT Wr( nB, jgB ) THEN
        RETURN FALSE;
      END;
      RETURN WrPrn(StartTol, "| " ) & WrPrnLn( StartTol, Tolerancja);
    END WrJakiGdzie;

  PROCEDURE WrJakiGdzieC( Tytul      : ARRAY OF CHAR;
                          jgA, jgB   : JakiGdzieC;
                          Tolerancja : ARRAY OF CHAR
                        ) : BOOLEAN;
    VAR
      polozenie : Str99;

      PROCEDURE Wr( n : NadajnikT; VAR jg : JakiGdzieC ) : BOOLEAN;
        BEGIN
          IF jg.gdzie >= 360 THEN
            polozenie := GWIAZDKI;
          ELSE
            SpecConv.Int2Str( jg.gdzie, polozenie, 4 );
          END;
          IF NOT WrFmtNad( n, jg.val # NilValC, "%xNM", jg.val ) THEN
            RETURN FALSE;
          END;
          IF NOT WrPrn( 0, '/' ) OR
             NOT WrPrn( 0, polozenie ) OR
             NOT WrPrn( 0, "ø" )
          THEN
            RETURN FALSE;
          END;
          RETURN TRUE;
        END Wr;

    BEGIN
      IF NOT WrPrn( 0, Tytul ) THEN
        RETURN FALSE;
      END;
      IF NOT Wr( nA, jgA ) THEN
        RETURN FALSE;
      END;
      IF NOT Wr( nB, jgB ) THEN
        RETURN FALSE;
      END;
      RETURN WrPrn(StartTol, "| " ) & WrPrnLn( StartTol, Tolerancja);
    END WrJakiGdzieC;

  PROCEDURE BledyNaOrbicie(  );
  VAR
    i    : INTEGER;
    n    : NadajnikT;
    p1   : CARDINAL;
    str  : ARRAY[ 0..20 ] OF CHAR;
  
  BEGIN
    WITH Dane DO
      IF NOT WrPrnLn( 0, '—rednie bˆ©dy na orbicie w zakresach stopni:' ) 
      THEN
        RETURN;
      END;
      FOR i := MIN( PartIdx ) TO MAX( PartIdx ) DO
        p1 := i*10;
        sprintf( str, "Dla k¥ta %dø", p1 );
        IF NOT WrPrn( 0, str ) THEN
          RETURN;
        END;
        FOR n := MIN( NadajnikT ) TO MAX( NadajnikT ) DO
          IF NOT WrFmtNad( n,
                           Pomiary[n].SredniBladNaOrbicie[i] # NilValI,
                           "%zø",
                           Pomiary[n].SredniBladNaOrbicie[i] ) THEN
            RETURN
          END;
        END (* n := MIN( NadajnikT ) *);
        IF NOT WrPrnLn(StartTol, '| +/- 3ø') THEN
          RETURN;
        END;
      END (* i := MIN( PartIdx ) *);
      IF NOT WrPrn( 0, "R¢¾nica mi©dzy nad. (co 10ø)" ) THEN
        RETURN;
      END;
      WITH RoznicaRozpietosci DO
        IF NOT WrPrn( StartN[nA], '|        ' ) THEN
          RETURN;
        END;
        IF val # NilValI THEN
          IF NOT WrPrnFmt( StartN[nA], "%zø", val ) THEN
            RETURN;
          END;
          IF NOT WrPrnFmt( StartN[nA], "/%dø", pos ) THEN
            RETURN;
          END;
        ELSE
          IF NOT WrPrn( StartN[nA], 'nie mo¾na wyznaczy†') THEN
            RETURN;
            END;
        END (* val # NilValI *);
        IF NOT WrPrnLn( StartTol, '| 2ø' ) THEN
          RETURN;
        END;
      END (* WITH RoznicaRozpietosci *);
      IF NOT WrPrn( 0, "R¢¾nica mi©dzy nad. (—r. na 4ø)" ) THEN
        RETURN;
      END;
      WITH RoznicaRozpietosci4Deg DO
        IF NOT WrPrn( StartN[nA], '|        ' ) THEN
          RETURN;
        END;
        IF val # NilValI THEN
          IF NOT WrPrnFmt( StartN[nA], "%zø", val ) THEN
            RETURN;
          END;
          IF NOT WrPrnFmt( StartN[nA], "/%dø", pos ) THEN
            RETURN;
          END;
        ELSE
          IF NOT WrPrn( StartN[nA], 'nie mo¾na wyznaczy†') THEN
            RETURN;
          END;
        END (* IF val # NilValI *);
        IF NOT WrPrnLn( StartTol, '| 2ø' ) THEN
          RETURN;
        END;
      END (* WITH RoznicaRozpietosci4Deg *);
      IF NOT WrPrnLn( 0, "Odcinki gdzie bˆ¥d > 2ø" ) THEN
        RETURN;
      END;
      FOR n := MIN( NadajnikT ) TO MAX( NadajnikT ) DO
        GetTranName(str, n);
        Concat(str, '- ', str);
        IF NOT WrFlagsTableWHeading( str, 
                                     Pomiary[n].blad3Deg,
                                     SpecConv.Int2Str )
        THEN
          RETURN;
        END (* IF *);
      END (* FOR *);
    END (* WITH Dane *);
  END BledyNaOrbicie;

  PROCEDURE VarRefSub(  ) : BOOLEAN;
  VAR
    n    : NadajnikT;
  BEGIN
    (* —rednie ref, sub, var *)
    WITH Dane DO
        IF NOT WrJakiGdzie( "—rednie REF na promieniu",
                            "%y",
                            10,
                            SpecConv.Int2Str,
                            Pomiary[nA].Srednie_REF_Promien,
                            Pomiary[nB].Srednie_REF_Promien,
                            "15..17%" )
        THEN
          RETURN FALSE;
        END;
        IF NOT WrJakiGdzie( "—rednie VAR na promieniu",
                            "%y%%",
                            10,
                            SpecConv.Int2Str,
                            Pomiary[nA].Srednie_VAR_Promien,
                            Pomiary[nB].Srednie_VAR_Promien,
                            TOL_28_32 )
        THEN
          RETURN FALSE;
        END;
        IF NOT WrJakiGdzie( "—rednie SUB na promieniu",
                            "%y%%",
                            10,
                            SpecConv.Int2Str,
                            Pomiary[nA].Srednie_SUB_Promien,
                            Pomiary[nB].Srednie_SUB_Promien,
                            TOL_28_32 )
        THEN
          RETURN FALSE;
        END;
        (***** orbita *****)
        IF NOT WrPrn( 0, "—rednie REF na orbicie" ) THEN
          RETURN FALSE;
        END;
        FOR n := MIN( NadajnikT ) TO MAX( NadajnikT ) DO
          IF NOT WrFmtNad( n,
                           Pomiary[n].Srednie_REF_Orbita # NilValI,
                           "%y",
                           Pomiary[n].Srednie_REF_Orbita )
          THEN
            RETURN FALSE;
          END;
        END;
        IF NOT WrPrn(StartTol, "| " ) OR
           NOT WrPrnLn( StartTol, "15..17%")
        THEN
          RETURN FALSE;
        END;
        IF NOT WrPrn( 0, "—rednie VAR na orbicie" ) THEN
          RETURN FALSE;
        END;
        FOR n := MIN( NadajnikT ) TO MAX( NadajnikT ) DO
          IF NOT WrFmtNad( n,
                           Pomiary[n].Srednie_VAR_Orbita # NilValI,
                           "%y%",
                           Pomiary[n].Srednie_VAR_Orbita )
          THEN
            RETURN FALSE;
          END;
        END;
        IF NOT WrPrn(StartTol, "| " ) OR
           NOT WrPrnLn( StartTol, TOL_28_32)
        THEN
          RETURN FALSE;
        END;
        IF NOT WrPrn( 0, "—rednie SUB na orbicie" ) THEN
          RETURN FALSE;
        END;
        FOR n := MIN( NadajnikT ) TO MAX( NadajnikT ) DO
          IF NOT WrFmtNad( n,
                           Pomiary[n].Srednie_SUB_Orbita # NilValI,
                           "%y%%",
                           Pomiary[n].Srednie_SUB_Orbita )
          THEN
            RETURN FALSE;
          END;
        END;
        IF NOT WrPrn(StartTol, "| " ) OR
           NOT WrPrnLn( StartTol, TOL_28_32)
        THEN
          RETURN FALSE;
        END;
      END;
      RETURN TRUE;
    END VarRefSub;

  PROCEDURE RaportKoncowy(  );
    VAR
      c       : CHAR;
      i       : INTEGER;
      n       : NadajnikT;
      td      : TimeAndDate;
      heading : ARRAY[0..4] OF CHAR;

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
     "RAPORT Z INSPEKCJI VOR WYKONANY DNIA: %02d:%02d:%04d O GODZ %02d.%02d", td ) THEN
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
        IF NOT WrPrnFmtLn( 0, "Deklinacja: %3.1lfø", Deklinacja ) THEN
          RETURN;
        END;
        IF NOT WrPrnFmtLn( 0, "Cz©stotliwo˜†: %5.2lfMHz", Czestotliwosc ) THEN
          RETURN;
        END;
        IF NOT WrPrn( 0, "SamolotPomiarowy: " ) OR
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
        IF NOT WrPrn( 0, "Daty wykonania pomiar¢w:" ) OR
           NOT WrPrn( StartN[nA], "| Nad. Gˆ¢wny" )   OR
           NOT WrPrn( StartN[nB], "| Nad. Zapasowy" ) OR
           NOT WrPrnLn( StartTol, "| Tolerancje" )
        THEN
          RETURN;
        END;
        (* Daty wykonania pomiaru bledu na promieniach publikowanych *)
        FOR i := 0 TO HIGH( Pomiary[nA].PromieniePublikowane ) DO
          IF (Pomiary[nA].PromieniePublikowane[i].Data.y # 0 ) OR
             (Pomiary[nB].PromieniePublikowane[i].Data.y # 0 )
          THEN
            IF NOT WrPrnFmt(0,
                            "Promieä %03dø(bˆ¥d)",
                            Pomiary[nA].PromieniePublikowane[i].Promien)
            THEN
              RETURN;
            END;
            FOR n := MIN( NadajnikT ) TO MAX( NadajnikT ) DO
              WITH Pomiary[n].PromieniePublikowane[i] DO
                IF NOT WrFmtNad( n, Data.y # 0, DATA_STR, Data ) THEN
                  RETURN;
                END;
              END;
            END;
            IF NOT WrLn() THEN
              RETURN;
            END;
          END;
        END;
        (* Daty wykonania pomiaru bledu na promieniach dodatkowych *)
        FOR i := 0 TO HIGH( Pomiary[nA].PromienieDodatkowe ) DO
          IF (Pomiary[nA].PromienieDodatkowe[i].Data.y # 0 ) OR
             (Pomiary[nB].PromienieDodatkowe[i].Data.y # 0 )
          THEN
            IF NOT WrPrnFmt(0,
                            "Promieä %03dø(bˆ¥d)",
                            Pomiary[nA].PromienieDodatkowe[i].Promien)
            THEN
              RETURN;
            END;
            FOR n := MIN( NadajnikT ) TO MAX( NadajnikT ) DO
              WITH Pomiary[n].PromienieDodatkowe[i] DO
                IF NOT WrFmtNad( n, Data.y # 0, DATA_STR, Data ) THEN
                  RETURN;
                END;
              END;
            END;
            IF NOT WrLn() THEN
              RETURN;
            END;
          END;
        END;
        (* Daty wykonania pomiaru zasiegu na promieniach publikowanych *)
        FOR i := 0 TO HIGH( Pomiary[nA].PromieniePublikowaneZas ) DO
          IF (Pomiary[nA].PromieniePublikowaneZas[i].Data.y # 0 ) OR
             (Pomiary[nB].PromieniePublikowaneZas[i].Data.y # 0 )
          THEN
            IF NOT WrPrnFmt(0,
                            "Promieä %03dø(zas.)",
                            Pomiary[nA].PromieniePublikowaneZas[i].Promien)
            THEN
              RETURN;
            END;
            FOR n := MIN( NadajnikT ) TO MAX( NadajnikT ) DO
              WITH Pomiary[n].PromieniePublikowaneZas[i] DO
                IF NOT WrFmtNad( n, Data.y # 0, DATA_STR, Data ) THEN
                  RETURN;
                END;
              END;
            END;
            IF NOT WrLn() THEN
              RETURN;
            END;
          END;
        END;
        (* Daty wykonania pomiaru zasiegu na promieniach dodatkowych *)
        FOR i := 0 TO HIGH( Pomiary[nA].PromienieDodatkoweZas ) DO
          IF (Pomiary[nA].PromienieDodatkoweZas[i].Data.y # 0 ) OR
             (Pomiary[nB].PromienieDodatkoweZas[i].Data.y # 0 )
          THEN
            IF NOT WrPrnFmt(0,
                            "Promieä %03dø(zas.)",
                            Pomiary[nA].PromienieDodatkoweZas[i].Promien)
            THEN
              RETURN;
            END;
            FOR n := MIN( NadajnikT ) TO MAX( NadajnikT ) DO
              WITH Pomiary[n].PromienieDodatkoweZas[i] DO
                IF NOT WrFmtNad( n, Data.y # 0, DATA_STR, Data ) THEN
                  RETURN;
                END;
              END;
            END;
            IF NOT WrLn() THEN
              RETURN;
            END;
          END;
        END;
        (* Data wykonania pomiaru bledu na orbicie *)
        IF NOT WrPrn(0, "Orbita (bˆ¥d)") THEN
          RETURN;
        END;
        FOR n := MIN( NadajnikT ) TO MAX( NadajnikT ) DO
          IF NOT WrFmtNad( n,
                           Pomiary[n].KiedyOrbitaBlad.y # 0,
                           DATA_STR,
                           Pomiary[n].KiedyOrbitaBlad ) THEN
            RETURN;
          END;
        END;
        IF NOT WrLn() THEN
          RETURN;
        END;
        (* Data wykonania pomiaru zasiegu na orbicie *)
        IF NOT WrPrn(0, "Orbita (zas.)" ) THEN
          RETURN;
        END;
        FOR n := MIN( NadajnikT ) TO MAX( NadajnikT ) DO
          IF NOT WrFmtNad( n,
                           Pomiary[n].KiedyOrbitaZasieg.y # 0,
                           DATA_STR,
                           Pomiary[n].KiedyOrbitaZasieg ) THEN
            RETURN;
          END;
        END;
        IF NOT WrLn() THEN
          RETURN;
        END;
        (* Wyniki pomiarow *)
        IF NOT WrPrnLn( 0, PASEK ) THEN
          RETURN;
        END;
        (* —redni blad na promieniach publikowanych *)
        FOR i := 0 TO HIGH( Pomiary[nA].PromieniePublikowane ) DO
          IF Pomiary[nA].PromieniePublikowane[i].Promien < 360 THEN
            IF NOT WrPrnFmt(0,
                            "—redni bˆ¥d na promieniu %d",
                            Pomiary[nA].PromieniePublikowane[i].Promien)
            THEN
              RETURN;
            END;
            FOR n := MIN( NadajnikT ) TO MAX( NadajnikT ) DO
              WITH Pomiary[n].PromieniePublikowane[i] DO
                IF NOT WrFmtNad( n, Data.y # 0, "%zø", SredniBlad ) THEN
                  RETURN;
                END;
              END;
            END;
            IF NOT WrLn() THEN
              RETURN;
            END;
          END;
        END;
        (* —redni blad na promieniach dodatkowych *)
        FOR i := 0 TO HIGH( Pomiary[nA].PromienieDodatkowe ) DO
          IF Pomiary[nA].PromienieDodatkowe[i]. Promien < 360 THEN
            IF NOT WrPrnFmt(0,
                            "—redni bˆ¥d na promieniu %d",
                            Pomiary[nA].PromienieDodatkowe[i].Promien)
            THEN
              RETURN;
            END;
            FOR n := MIN( NadajnikT ) TO MAX( NadajnikT ) DO
              WITH Pomiary[n].PromienieDodatkowe[i] DO
                IF NOT WrFmtNad( n, Data.y # 0, "%zø", SredniBlad ) THEN
                  RETURN;
                END;
              END;
            END;
            IF NOT WrLn() THEN
              RETURN;
            END;
          END;
        END;
        (* Wysokosc *)
        IF NOT WrPrn(0, "Wysoko˜† lotu orb. zas." ) THEN
          RETURN;
        END;
        FOR n := MIN( NadajnikT ) TO MAX( NadajnikT ) DO
          WITH Pomiary[n] DO
            IF NOT WrFmtNad( n, WysokoscLotuNaOrbicieZas # NilValC, 
                             "%dft", 
                             WysokoscLotuNaOrbicieZas ) 
            THEN
              RETURN;
            END;
          END;
        END;
        IF NOT WrLn() THEN
          RETURN;
        END;
        (* Promien *)
        IF NOT WrPrn(0, "Promieä lotu na orbicie pom." ) THEN
          RETURN;
        END;
        FOR n := MIN( NadajnikT ) TO MAX( NadajnikT ) DO
          WITH Pomiary[n] DO
            IF NOT WrFmtNad( n, 
                             PromienLotuNaOrbiciePom < 100.0, 
                             "%4.2lfNM", 
                             PromienLotuNaOrbiciePom ) THEN
              RETURN;
            END;
          END;
        END;
        IF NOT WrLn() THEN
          RETURN;
        END;
        IF NOT VarRefSub() THEN
          RETURN;
        END;
        IF NOT WrJakiGdzie( "Max. falowania",
                            "%zø",
                            100,
                            SpecConv.Int2Str,
                            Pomiary[nA].MaxFalowanie,
                            Pomiary[nB].MaxFalowanie,
                            "+/- 3ø" )
        THEN
          RETURN
        END;
        IF NOT WrJakiGdzie( "Max. ugi©cie",
                            "%zø",
                            100,
                            SpecConv.Int2Str,
                            Pomiary[nA].MaxUgiecie,
                            Pomiary[nB].MaxUgiecie,
                            "+/- 3.5ø" )
        THEN
          RETURN
        END;
        IF NOT WrJakiGdzie( "Polaryzacja (prawo)",
                            "%zø",
                            100,
                            SpecConv.Int2Str,
                            Pomiary[nA].PolaryzacjaPrawo,
                            Pomiary[nB].PolaryzacjaPrawo,
                            "+2ø" )
        THEN
          RETURN
        END;
        IF NOT WrJakiGdzie( "Polaryzacja (lewo)",
                            "%zø",
                            100,
                            SpecConv.Int2Str,
                            Pomiary[nA].PolaryzacjaLewo,
                            Pomiary[nB].PolaryzacjaLewo,
                            "-2ø" )
        THEN
          RETURN
        END;
        (* Wysokosc *)
        IF NOT WrPrn(0, "Wysoko˜† lotu prom. zas." ) THEN
          RETURN;
        END;
        FOR n := MIN( NadajnikT ) TO MAX( NadajnikT ) DO
          WITH Pomiary[n] DO
            IF NOT WrFmtNad( n, WysokoscLotuNaPromieniuZas # NilValC, "%dft", WysokoscLotuNaPromieniuZas ) THEN
              RETURN;
            END;
          END;
        END;
        IF NOT WrLn() THEN
          RETURN;
        END;
        IF NOT WrJakiGdzieC( "Zasi©g na promieniu",
                             Pomiary[nA].ZasiegNaPromieniu,
                             Pomiary[nB].ZasiegNaPromieniu,
                             "40 NM/1000ft" )
        THEN
          RETURN
        END;
        IF NOT WrPrn( 0, "Zasi©g na orb. (dluog˜†)" ) THEN
          RETURN;
        END;
        FOR n := MIN( NadajnikT ) TO MAX( NadajnikT ) DO
          IF NOT WrFmtNad( n,
                           Pomiary[n].ZasiegNaOrbicie # NilValC,
                           "%zø ",
                           Pomiary[n].ZasiegNaOrbicie ) THEN
            RETURN
          END;
        END;
        IF NOT WrPrn(StartTol, "| " ) OR
           NOT WrPrnLn( StartTol, "72ø dla SS < 5uV")
        THEN
          RETURN;
        END;
        IF NOT WrPrn( 0, "Rozpi©to˜† bˆ©du na promieniach" ) THEN
          RETURN;
        END;
        FOR n := MIN( NadajnikT ) TO MAX( NadajnikT ) DO
          IF NOT WrFmtNad( n,
                           Pomiary[n].RozpietoscBleduNaPromieniach # NilValI,
                           "%zø",
                           Pomiary[n].RozpietoscBleduNaPromieniach ) THEN
            RETURN
          END;
        END;
        IF NOT WrPrnLn(StartTol, "| +/- 3ø" ) THEN
          RETURN;
        END;
        BledyNaOrbicie;
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
      Wykresy;
    END RaportKoncowy;

  PROCEDURE Wykresy(  );

    PROCEDURE Wykres( VAR pn       : PomiarNadajnika;
                          Nad      : Str40;
                          Pozycja  : INTEGER );

      PROCEDURE AtX( Dewiacja : INTEGER ) : INTEGER;
        VAR
          tmp : INTEGER;
        BEGIN
          tmp := VAL( INTEGER,
                      VAL( LONGINT, Pozycja ) +
                        VAL( LONGINT, Dewiacja )*
                        VAL( LONGINT, PiksliNaStopien ) DIV 100L );
          IF (tmp >= 0) THEN
            RETURN tmp;
          ELSE
            RETURN 0;
          END;
        END AtX;

      PROCEDURE AtPromien( Promien : CARDINAL ) : INTEGER;
        VAR
          tmp : LONGINT;
        BEGIN
          tmp := VAL( LONGINT, Promien ) *
                 VAL( LONGINT, DrawEpson.MaxY() -REZERWA_NA_OPIS -REZERWA_Z_KONCA) DIV
                 360L;
          RETURN REZERWA_NA_OPIS + VAL(CARDINAL, tmp );
        END AtPromien;

      CONST
        REZERWA_NA_OPIS = SKALA_Y_90*2*8;
        REZERWA_Z_KONCA = SKALA_Y_90*8;
        TYPLINII = {0, 2, 4, 6, 8, 10, 12, 14};
      VAR
        PiksliNaStopien : INTEGER;
        i               : INTEGER;
        a               : ADDRESS;
      BEGIN (*  Wykres *)
        PiksliNaStopien := (DrawEpson.MaxX() DIV 3) DIV (* wielkosc obrazka *)
                           6;        (* od -3 do +3 *)
        FOR i := -3 TO 3 DO
          DrawEpson.Line( AtX(i*100),
                          REZERWA_NA_OPIS,
                          AtX(i*100),
                          AtPromien(360),
                          TYPLINII );
          IntToString( i, str, 2 );
          IF i > 0 THEN
            str[0] := '+';
          END;
          DrawEpson.DrawText( str, AtX(i*100)+SKALA_X_90*4, 0 );
        END;
        FOR i := 0 TO 360 BY 30 DO
          DrawEpson.Line( AtX(-300), (* 3 stopnie *)
                          AtPromien(i),
                          AtX(300), (* 3 stopnie *)
                          AtPromien(i),
                          TYPLINII );
          IF i # 0 THEN
            IntToString( i, str, 2 );
            DrawEpson.DrawText( str, 
                                Pozycja-1, 
                                AtPromien(i)-SKALA_Y_90*8 * 3 DIV 2 );
          END;
        END;
        (* a teraz wykres jako taki *)
        FOR i := 0 TO HIGH( pn.BladCoStopien ) -1 DO
          IF pn.BladCoStopien[i+1] # NilValI THEN
            IF pn.BladCoStopien[i] # NilValI THEN (* byla poprzednia probka *)
              DrawEpson.Line( AtX( pn.BladCoStopien[i] ),
                              AtPromien( i ),
                              AtX( pn.BladCoStopien[i+1] ),
                              AtPromien( i+1 ),
                              {0..15}
                            );
            ELSE
              DrawEpson.Point( AtX( pn.BladCoStopien[i+1] ),
                               AtPromien( i+1 ),
                               TRUE
                             );
            END;
          ELSE (* nic nie rob *)
          END;
        END;
        a := ADR( Nad );
        IF pn.WysokoscLotuNaOrbiciePom # NilValC THEN
          sprintf4( str,
                    "Nadajnik %s, promien=%4.2lfNM, wysokosc=%dft, dnia %d.%02d.%d",
                    a,
                    pn.PromienLotuNaOrbiciePom,
                    pn.WysokoscLotuNaOrbiciePom,
                    pn.KiedyOrbitaBlad
                  );
        ELSE
          str := "Brak danych";
        END;
        DrawEpson.DrawText( str, AtX( -300 )- 2*8*SKALA_X_90, AtPromien(20));
      END Wykres;

    VAR
      str : Str99;
    BEGIN
      DrawEpson.Open;
      DrawEpson.SetTextMode(DrawEpson.mtSet);
      DrawEpson.SetDir( DrawEpson.t_90 );
      DrawEpson.Mnoznik(SKALA_X_90, SKALA_Y_90);
      Wykres( Dane.Pomiary[nA], 'gˆ¢wny', DrawEpson.MaxX() * 3 DIV 4 );
      Wykres( Dane.Pomiary[nB], 'zapasowy', DrawEpson.MaxX() * 1 DIV 4 );
      str := "WYKRES B¨DU NAMIARU W POWIETRZU (LOTY OKR¨½NE) VOR -> ";
      Insert( Dane.Lokalizacja, str, 0FFFH );
      DrawEpson.DrawText( str, 1+8*SKALA_X_90, 0 );
      DrawEpson.SetDir( DrawEpson.t_0 );
      IF NOT DrawEpson.Out(DrawEpson.WrProc) THEN
      END (* if *);
      DrawEpson.Close;
    END Wykresy;

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
              IF Wysokosc < 0  THEN
                Wys := 0;
              ELSE
                Wys := Wysokosc;
              END;
            END;
          END;
        END;
      END;
      RETURN Wys;
    END JakaWysokosc;

  PROCEDURE PrzygotujDane(  ) : BOOLEAN;

    PROCEDURE PodstawJakiGdzie( VAR jg            : JakiGdzie;
                                    WartNajlepsza : INTEGER;
                                    sv            : SignalDsc;
                                    prom          : CARDINAL );
      BEGIN
        IF sv.val = NilValI THEN
          RETURN;
        ELSE
          IF (jg.val = NilValI) OR
             (ABS(sv.val-WartNajlepsza) > ABS(jg.val-WartNajlepsza) ) THEN
            jg.val := sv.val;
            jg.gdzie := prom;
          END;
        END;
      END PodstawJakiGdzie;

    PROCEDURE PodstawInteger( VAR jg            : INTEGER;
                                  WartNajlepsza : INTEGER;
                                  sv            : SignalDsc );
      BEGIN
        IF sv.val = NilValI THEN
          RETURN;
        ELSE
          IF (jg = NilValI) OR
             (ABS(sv.val-WartNajlepsza) > ABS(jg-WartNajlepsza) ) THEN
            jg := sv.val;
          END;
        END;
      END PodstawInteger;

    PROCEDURE DanePromieni( VAR pn : PomiarNadajnika;
                            VAR kp : KazdyPromien;
                            VAR bd : CARDINAL;
                                pom: BOOLEAN;
                            VAR mn : INTEGER;
                            VAR mx : INTEGER
                          );

      PROCEDURE ZasiegiNaPromieniu( VAR jg : JakiGdzieC;
                                    VAR ft : FlagsTable
                                  );

        PROCEDURE ProbujWstawic( odl : CARDINAL );
          BEGIN
            IF odl = NilValC THEN
              RETURN;
            ELSE
              IF (jg.val = NilValC) OR (odl < jg.val) THEN
                jg.val := odl;
                jg.gdzie := CARDINAL(bd);
              END;
            END;
          END ProbujWstawic;

        VAR
          i : INTEGER;
        BEGIN
          FOR i := 1 TO ft.w_IleOd DO
            ProbujWstawic( CARDINAL(ft.opis[i].pocz) );
            ProbujWstawic( CARDINAL(ft.opis[i].kon) );
          END;
        END ZasiegiNaPromieniu;

      VAR
        Tmp    : Str99;
        dataOk : okTab;
      BEGIN
        Promien := bd;
        kp.Promien := bd;
        SciezkaDoKataloguOpisuUst();
        Assign( SciezkaOpisuPomiaru, Tmp );
        Tmp[ Length( Tmp ) -1 ] := 0C;
        IF ExistDIR( Tmp ) THEN
          LoadData( dataOk );
          GoHomeDir;
          IF NOT dataOk[FALSE] THEN
            kp.Data.y := 0;
          ELSIF pom THEN
            kp.SredniBlad := anRes.devDet[AV]
                                         [Dane.Odniesienie]
                                         [Dane.Odbiornik]    .val ;
            kp.Data := anRes.dataPomiaru.d;
            PodstawJakiGdzie( pn.Srednie_REF_Promien,
                              160,
                              anRes.signalGen[AV][Ref,Dane.Odbiornik],
                              Promien );
            PodstawJakiGdzie( pn.Srednie_VAR_Promien,
                              300,
                              anRes.signalGen[AV][Var,Dane.Odbiornik],
                              Promien );
            PodstawJakiGdzie( pn.Srednie_SUB_Promien,
                              300,
                              anRes.signalGen[AV][Sub,Dane.Odbiornik],
                              Promien );
            PodstawJakiGdzie( pn.MaxUgiecie,
                              0,
                              anRes.devDet[UGPlus][OdnDlaPomBledu, Dane.Odbiornik],
                              Promien );
            PodstawJakiGdzie( pn.MaxFalowanie,
                              0,
                              anRes.devDet[FAL][OdnDlaPomBledu, Dane.Odbiornik],
                              Promien );
            PodstawJakiGdzie( pn.PolaryzacjaPrawo,
                              0,
                              anRes.devDet[PolPrawo][OdnDlaPomBledu, Dane.Odbiornik],
                              Promien );
            PodstawJakiGdzie( pn.PolaryzacjaLewo,
                              0,
                              anRes.devDet[PolLewo][OdnDlaPomBledu, Dane.Odbiornik],
                              Promien );
            SpecConv.GorszeBoMniejsze(mn, kp.SredniBlad);
            SpecConv.GorszeBoWieksze(mx, kp.SredniBlad);
          ELSE (* lot zasiegowy *)
            ZasiegiNaPromieniu( pn.ZasiegNaPromieniu, anRes.lowSigTab[Dane.Odbiornik] );
            pn.WysokoscLotuNaPromieniuZas := JakaWysokosc();
            kp.Data := anRes.dataPomiaru.d;
          END;
        ELSE (* nie bylo leciane *)
          kp.Data.y := 0;
        END;
      END DanePromieni;

      PROCEDURE DaneOrbity
                ( VAR pn : PomiarNadajnika );
        VAR
          p                   : POINTER TO Date;
          angContiner         : AngMarksDsc;
          angCurrIndex        : INTEGER;
          BladWTymMiejscu,
          Odl                 : INTEGER;
          DistFile,
          ErrFile             : File;
          Tmp                 : Str99;
          dataOk              : okTab;
          dvAVcont            : AvrDscr;
          OSL_continer        : OpisStanuLuku;
          indexZakLuku        : CARDINAL;
          resNaLuku4Deg       : MMA_SignalDsc;
          kompletny           : BOOLEAN;
          
        BEGIN (* DaneOrbity *)
          IF Procedura = pOkragBlad THEN
            p := ADR( pn.KiedyOrbitaBlad );
          ELSE
            p := ADR( pn.KiedyOrbitaZasieg );
          END;
          SciezkaDoKataloguOpisuUst();
          Assign( SciezkaOpisuPomiaru, Tmp );
          Tmp[ Length( Tmp ) -1 ] := 0C;
          IF ExistDIR( Tmp ) THEN
            LoadData( dataOk );
            IF NOT dataOk[ FALSE ] THEN                 (* MM 3.6.97 *)
              GoHomeDir;
              RETURN;
            END;
            GetALfaRefFName(OdnDlaPomBledu, pomiar, Tmp);
            DistFile := Open(Tmp);
(*          Assert(DistFile <> MAX(CARDINAL)); MM 3.6.97 *)
            IF DistFile = MAX(CARDINAL)
            THEN
              (*
              InfoBeep("Nie mo¾na otworzy† pliku ze znacznikami odlegˆo˜ci",
                        3, 500);
              Close( DistFile );
              *)
              RETURN;
            END (* if DistFile *);
            GetResFileName( OdnDlaPomBledu, Dane.Odbiornik, Tmp );
            ErrFile := Open(Tmp);
            Assert(ErrFile <> MAX(CARDINAL));
            GoHomeDir;
            IF NOT dataOk[FALSE] THEN
              p^.y := 0;
            ELSE
              p^ := anRes.dataPomiaru.d;
            END;
            IF (Procedura = pOkragBlad) THEN
              PodstawInteger( pn.Srednie_REF_Orbita,
                              7FFFH,
                              anRes.signalGen[AV][Ref,Dane.Odbiornik] );
              PodstawInteger( pn.Srednie_VAR_Orbita,
                              7FFFH,
                              anRes.signalGen[AV][Var,Dane.Odbiornik] );
              PodstawInteger( pn.Srednie_SUB_Orbita,
                              7FFFH,
                              anRes.signalGen[AV][Sub,Dane.Odbiornik] );
              pn.SredniBladNaOrbicie := anRes.DevOrbit[OdnDlaPomBledu,
                                                       Dane.Odbiornik];
              pn.PromienLotuNaOrbiciePom  :=
                        FLOAT(CARDINAL(anRes.PromienLubOrbita)) / 500.0;
              pn.WysokoscLotuNaOrbiciePom := JakaWysokosc();
              (* teraz BladCoStopien *)
              AngResetContiner(angContiner);
              Init_AvrDscr(dvAVcont, SigNilVal);
              InicjujOpisStanuLuku(OSL_continer, 4.0);
              Init_MMA_SignalDsc(resNaLuku4Deg, SigNilVal);
              LOOP
                IF NOT Read(DistFile, ADR(Odl), SIZE(Odl)) THEN
                  (* Dane sie wyczerpaly *)
                  EXIT;
                END (* if *);
                IF NOT Read(ErrFile, ADR(BladWTymMiejscu), 
                            SIZE(BladWTymMiejscu)) 
                THEN
                  (* nic *)
                END (* if *);
                IF AngAddSample(INTEGER(Odl), angContiner, angCurrIndex, 
                                scaleDiv) 
                THEN
                  (* granica pelnego stopnia *)
                  pn.BladCoStopien[(angCurrIndex DIV 100+360) MOD 360] := BladWTymMiejscu;
                END;
                Line :=1276;
                MinMaxAvr(BladWTymMiejscu, Odl, dvAVcont);
                Line :=1278;
                IF SegZakonczony( INTEGER( Odl ), OSL_continer, kompletny,
                                  indexZakLuku )
                THEN
                  Line :=1282;
                  IF kompletny THEN
                    Count_MMA_SignalDsc(resNaLuku4Deg, dvAVcont);
                    pn.BladCo4Stopnie[indexZakLuku] := resNaLuku4Deg.avr;
                  END;
                  Line :=1287;
                  Init_AvrDscr(dvAVcont, SigNilVal);
                END;
              END; (* LOOP *)
              pn.BladCoStopien[360] := pn.BladCoStopien[0];
            ELSE
              pn.ZasiegNaOrbicie := 
                 SumaDlugosciSig(anRes.lowSigTab[Dane.Odbiornik]); (* ilosc odcinkow *)
              pn.WysokoscLotuNaOrbicieZas := JakaWysokosc();
            END;
            Close(DistFile);
            Close(ErrFile);
          ELSE
            p^.y := 0;
          END;
          GoHomeDir;
        END DaneOrbity;

    VAR
      void        : CARDINAL;
      f           : File;
      i           : INTEGER;
      mn,
      mx          : INTEGER;
      roznica     : INTEGER;
      n           : NadajnikT;
      index       : PartIdx;
      index4      : IndexLuku4Deg;
      blad3DegCon : ARRAY NadajnikT OF BOOLEAN;
      
    BEGIN (* PrzygotujDane *)
      InitDane;
      mx := NilValI;
      mn := NilValI;
      Dane.NazwaInspekcji := NazwaOblotu;
      WITH Dane DO
        IF NOT GetInteractiveData( UrzadzenieOK,
                                   Odpowiedzialny,
                                   SamolotPomiarowy,
                                   Dummy ) THEN
          RETURN FALSE;
        END;
        Deklinacja := CurVor1.Deklinacja;
        Lokalizacja := CurVor1.Nazwa;
        Polozenie := CurVor1.Polozenie;
        Czestotliwosc := real( CurVor1.Czestotliwosc ) / 100.0;
        Odniesienie  := OdnDlaPomBledu;
        Odbiornik := GlownyOdbiornik;
        GetPrivateProfileString( "DataKalibracji", 
                                 "Data", 
                                 "15-09-2000", 
                                 DataOstatniejKalibracji,
                                 NazwaPlikuOpisu );
        FOR n := MIN( NadajnikT ) TO MAX( NadajnikT ) DO
          blad3DegCon[n] := FALSE;
          mx := NilValI;
          mn := NilValI;
          Procedura := pPromienBlad;
          Nadajnik1 := n;
          WITH Pomiary[n] DO
            Line := 1341;
            FOR i := 0 TO CurVor1.IleKierunkow-1 DO
              DanePromieni( Pomiary[n],
                            PromieniePublikowane[i],
                            CurVor1.Kierunki[i],
                            TRUE,
                            mn,
                            mx );
            END;
            Line := 1350;
            FOR i := 0 TO CurVor1.IleKierunkowDodatkowych-1 DO
              Line := 1353;
              DanePromieni( Pomiary[n],
                            PromienieDodatkowe[i],
                            CurVor1.KierunkiDodatkowe[i],
                            TRUE,
                            mn,
                            mx );
            END;
            RozpietoscBleduNaPromieniach := SpecConv.Sub(mx,mn);

            Procedura := pPromienZakres;
            Line := 1364;
            FOR i := 0 TO CurVor1.IleKierunkow-1 DO
              DanePromieni( Pomiary[n],
                            PromieniePublikowaneZas[i],
                            CurVor1.Kierunki[i],
                            FALSE,
                            mn,
                            mx  );
            END;
            Line := 1373;
            FOR i := 0 TO CurVor1.IleKierunkowDodatkowych-1 DO
              DanePromieni( Pomiary[n],
                            PromienieDodatkoweZas[i],
                            CurVor1.KierunkiDodatkowe[i],
                            FALSE,
                            mn,
                            mx   );
            END;

            Procedura := pOkragBlad;
            Line := 1384;
            DaneOrbity( Pomiary[n] );
            Procedura := pOkragZakres;
            Line := 1387;
            DaneOrbity( Pomiary[n] );
          END (* WITH Pomiary[n] *);
        END (* FOR n := MIN( NadajnikT )  *);
        Line := 1385;
        FOR index := MIN(PartIdx) TO MAX(PartIdx) DO
          WorseBGreater
            ( RoznicaRozpietosci,
              ABS( SpecConv.Sub( Pomiary[nA].SredniBladNaOrbicie[index],
                                 Pomiary[nB].SredniBladNaOrbicie[index] )
                  ),
              10 * ORD(index) 
            );
        END (* FOR index *);
        Line := 1397;
        FOR index4 := MIN(IndexLuku4Deg) TO MAX(IndexLuku4Deg) DO
          WorseBGreater(RoznicaRozpietosci4Deg,
                        ABS( SpecConv.Sub( Pomiary[nA].BladCo4Stopnie[index4],
                                           Pomiary[nB].BladCo4Stopnie[index4])
                           ),
                        4 * ORD(index4 )
                       );
          FOR n := MIN( NadajnikT ) TO MAX( NadajnikT ) DO
            WITH Pomiary[n] DO
              IF BladCo4Stopnie[index4] <> SigNilVal THEN
                FlagErr_Anal( blad3DegCon[ n ],  
                              ABS(BladCo4Stopnie[index4]) >= 200, 
                              blad3Deg,  
                              4 * ORD( index4 ), 
                              ns_no );
              END (* IF BladCo4Stopnie[index4]*);
              END;
            END (* Pomiary[n] *);
        END;
      END;
      RETURN TRUE;
    END PrzygotujDane;

  PROCEDURE InitDane(  );

    PROCEDURE InitJakiGdzie( VAR a : JakiGdzie; Promien : BOOLEAN );
      BEGIN
        a.val := NilValI;
        a.gdzie := NilValI;
      END InitJakiGdzie;

    VAR
      n : NadajnikT;
      i : INTEGER;
    BEGIN
      WITH Dane DO
        NazwaInspekcji[0] := 0C;
        Lokalizacja[0] := 0C;
        (*Polozenie :=            Cokolwiek *)
        Czestotliwosc := 0.0;
        Odpowiedzialny[0] := 0C;
        Deklinacja := 0.0;
        Odniesienie := MIN( OdnDlaPomBleduT );
        Odbiornik := MIN( GlownyOdbiornikT );
        (* DataOstatniejKalibracji nieinicjowane *);
        NazwaAparaturyPomiarowej := 'CFIS-1';
        SamolotPomiarowy := 'SP-TPA';
        InitSignalDsc( RoznicaRozpietosci, SigNilVal);
        InitSignalDsc( RoznicaRozpietosci4Deg, SigNilVal);
        FOR n := MIN( NadajnikT ) TO MAX( NadajnikT ) DO
          WITH Pomiary[n] DO
            FOR i := 0 TO IleKierunkow-1 DO
              PromieniePublikowane[i].Promien := 0FFFFH;
              PromienieDodatkowe[i].Promien := 0FFFFH;
              PromieniePublikowaneZas[i].Promien := 0FFFFH;
              PromienieDodatkoweZas[i].Promien := 0FFFFH;
              PromieniePublikowane[i].Data.y := 0;
              PromienieDodatkowe[i].Data.y := 0;
              PromieniePublikowaneZas[i].Data.y := 0;
              PromienieDodatkoweZas[i].Data.y := 0;
            END;
            KiedyOrbitaBlad.y := 0;
            KiedyOrbitaZasieg.y := 0;
            InitJakiGdzie( Srednie_REF_Promien, TRUE );
            InitJakiGdzie( Srednie_VAR_Promien, TRUE );
            InitJakiGdzie( Srednie_SUB_Promien, TRUE );
            Srednie_REF_Orbita := NilValI;
            Srednie_VAR_Orbita := NilValI;
            Srednie_SUB_Orbita := NilValI;
            InitJakiGdzie( MaxFalowanie, TRUE );
            InitJakiGdzie( MaxUgiecie, TRUE );
            InitJakiGdzie( PolaryzacjaPrawo, TRUE );
            InitJakiGdzie( PolaryzacjaLewo, TRUE );
            ZasiegNaPromieniu.val := NilValC;
            ZasiegNaPromieniu.gdzie := NilValI;
            ZasiegNaOrbicie := NilValC;
            RozpietoscBleduNaPromieniach := NilValI;
            WysokoscLotuNaOrbicieZas := NilValC;
            WysokoscLotuNaPromieniuZas:= NilValC;
            WysokoscLotuNaOrbiciePom := NilValC;
            PromienLotuNaOrbiciePom  := 0.0;
            OrbitDscClear(SredniBladNaOrbicie);
            FOR i := 0 TO HIGH(BladCoStopien) DO
              BladCoStopien[i] := SigNilVal;
            END;
            FOR i := MIN(IndexLuku4Deg) TO MAX(IndexLuku4Deg) DO
              BladCo4Stopnie[i] := SigNilVal;
            END;
            InitFlagErr(blad3Deg, TRUE);
          END;
        END;
        UrzadzenieOK := FALSE;
      END;
    END InitDane;
VAR
  Line : CARDINAL;
  
BEGIN
  Line := MAX(CARDINAL);
  StartN[nA] := 32;
  StartN[nB] := 48;
  StartTol   := 64;
  (* InitDane; *)
END PI_Report.
