IMPLEMENTATION MODULE PI_Report;

FROM CommonTypes IMPORT
  Date, Str40, Str99, PolozenieGeo, OdnDlaPomOdlT, NadajnikT,
  GlownyOdbiornikT, NilValC, SignalDsc, TimeAndDate, NilValI,
  OdnDlaPomBleduT;
FROM EventsMng IMPORT
  EventKind, RodzUrzadzenia;
FROM PiszEventy IMPORT
  TypyEventow, PiszNaDrukarce;
FROM H_DataBase IMPORT
  NadajnikVHF;
FROM H_CommonTypes IMPORT
  Procedura, ProceduraT;
FROM H_Oblot IMPORT
  SciezkaDoKataloguOpisu;
FROM RTSMain IMPORT
  Terminate, Status;
FROM Czas IMPORT
  GetTimeAndDate;
FROM NumberConversion IMPORT
  IntToString;
FROM Marks IMPORT
  AngMarksDsc, AngResetContiner, AngAddSample;
FROM H_results IMPORT
  anRes;
FROM FlagAnal IMPORT
  FlagsTable;
FROM FIO IMPORT
  File, Open, Close, CD, Read, GetFileStamp, Write, Create;
FROM Files IMPORT
  ExistDIR, GoHomeDir, GetALfaRefFName;
FROM StdIO IMPORT
  sprintf, sprintf2, sprintf3, sprintf4;
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
  real, entier, sin, cos;
FROM Print IMPORT
  WrPrn, WrPrnLn, WrLn, TextModeOutProc, PASEK, GWIAZDKI, PrnX, PrnY,
  SKALA_Y_90, SKALA_X_90;
IMPORT
  DrawEpson, (* bo kloci sie Close *)
  CommonData,
  FIO;
FROM ASCII IMPORT
  ff;
FROM Dialog IMPORT
  HDLG, WstawButton;
FROM Buttons IMPORT
  Button, ChangeButtonText;
FROM GrafTypes IMPORT
  RECT, AssignRect, MoveRect, WHITE;
FROM ShortCuts IMPORT
  kbAltY, kbCtrlY, kbAltD, kbCtrlD;



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
  pomiar      = TRUE;
  DATA_STR    = "%02d.%02d.%d";

TYPE
  OpisyZasiegow = RECORD
    Wysokosc,
    Zasieg    : CARDINAL;
  END;


  RaportKoncowyDesc = RECORD
    NazwaInspekcji           : Str40;
    Lokalizacja              : Str40;
    Polozenie                : PolozenieGeo;
    Czestotliwosc            : REAL;
    Deklinacja               : REAL;
    Odpowiedzialny           : Str40;
    SamolotPomiarowy         : ARRAY[0..6] OF CHAR;
    DataOstatniejKalibracji  : Date;
    NazwaAparaturyPomiarowej : Str40;
    UrzadzenieOK             : BOOLEAN;
  END;

  FracType = RECORD
    Int  : CARDINAL;
    Frac : CARDINAL;
  END;

VAR
  Dane : RaportKoncowyDesc;

  PROCEDURE WrPrnFmt( At   : INTEGER;
                      Fmt  : ARRAY OF CHAR;
                      Dane : ARRAY OF BYTE ) : BOOLEAN;
    VAR
      str   : ARRAY[0..99] OF CHAR;
    BEGIN
      IF CHAR(Dane[0]) = 0377c THEN
        RETURN WrPrn( At, '******' );
      ELSE
        sprintf( str, Fmt, Dane );
        IF NOT WrPrn( At, str ) THEN
          RETURN FALSE;
        ELSE
          RETURN TRUE;
        END;
      END;
    END WrPrnFmt;

  PROCEDURE WrPrnFmtLn( At   : INTEGER;
                        Fmt  : ARRAY OF CHAR;
                        Dane : ARRAY OF BYTE ) : BOOLEAN;
  BEGIN
    RETURN WrPrnFmt( At, Fmt, Dane ) & WrLn();
  END WrPrnFmtLn;



  PROCEDURE PoczatekWypisywania(  ) : BOOLEAN;
    VAR
      td   : TimeAndDate;
      c    : CHAR;
      n    : NadajnikT;
    BEGIN
(*
      (* symulacja drukarki *)
      DrukarkaSim := Create( PrnFileName );
      TextModeOutProc := FIOOut;
*)
      PrnX := 0;
      PrnY := 0;
      GetTimeAndDate( td );
      IF NOT WrPrnFmtLn( 0, "RAPORT Z INSPEKCJI VHF WYKONANY O GODZ. %02d:%02d dnia %02d.%02d.%d", td ) THEN
        RETURN FALSE;
      END;
      WITH Dane DO
        IF NOT WrPrn( 0, "Nazwa Inspekcji: " ) OR
            NOT WrPrnLn( 0, NazwaInspekcji )
        THEN
          RETURN FALSE;
        END;
        IF NOT WrPrn( 0, "Lokalizacja: " ) OR
            NOT WrPrnLn( 0, Lokalizacja )
        THEN
          RETURN FALSE;
        END;
        IF NOT WrPrnFmtLn( 0,
                            "Poˆo¾enie geograficzne: %dø%02d'%02dE, %dø%02d'%02dN",
                            Polozenie )
        THEN
          RETURN FALSE;
        END;
        IF NOT WrPrnFmtLn( 0, "Deklinacja: %3.1lfø", Deklinacja ) THEN
          RETURN FALSE;
        END;
        IF NOT WrPrn( 0, "SamolotPomiarowy: " ) OR
            NOT WrPrnLn( 0, SamolotPomiarowy )
        THEN
          RETURN FALSE;
        END;
        IF NOT WrPrn( 0, "Odpowiedzialny za wykonanie pomiaru: " ) THEN
          RETURN FALSE;
        END;
        IF Odpowiedzialny[0] = 0C THEN
          IF NOT WrPrnLn( 0, '** Niezdefiniowany **' ) THEN
            RETURN FALSE;
          END;
        ELSE
          IF NOT WrPrnLn( 0, Odpowiedzialny ) THEN
            RETURN FALSE;
          END;
        END;
        IF NOT WrPrnFmtLn( 0,
                            "Data ostatniej kalibracji: %02d.%02d.%d",
                            DataOstatniejKalibracji )
        THEN
          RETURN FALSE;
        END;
        IF NOT WrPrn( 0, "Nazwa aparatury pomiarowej: " ) OR
            NOT WrPrnLn( 0, NazwaAparaturyPomiarowej )
        THEN
          RETURN FALSE;
        END;
      END;
      IF NOT WrLn() THEN
        RETURN FALSE;
      END;
      RETURN TRUE;
    END PoczatekWypisywania;

  PROCEDURE KoniecWypisywania(  ) : BOOLEAN;
    VAR
      n    : NadajnikT;
    BEGIN
      IF NOT WrLn() OR NOT WrLn() OR NOT WrLn() THEN
        RETURN FALSE;
      END;

      IF Dane.UrzadzenieOK THEN
        IF NOT WrPrnLn( 0, "Urz¥dzenie speˆnia wymagania ICAO" ) THEN
          RETURN FALSE;
        END;
      ELSE
        IF NOT WrPrnLn( 0, "Urz¥dzenie nie speˆnia wymagaä ICAO" ) THEN
          RETURN FALSE;
        END;
      END;
      IF NOT WrLn() OR NOT WrPrnLn(0,"Uwagi") OR NOT WrLn() OR NOT WrLn() OR NOT WrLn() THEN
        RETURN FALSE;
      END;
      IF NOT WrPrnLn( 40, Dane.Odpowiedzialny ) THEN
        RETURN FALSE;
      END;
      IF NOT WrPrn( 0, ff ) THEN
        RETURN FALSE;
      END;
      RETURN TRUE;
    END KoniecWypisywania;

  PROCEDURE RaportKoncowy(  );
    VAR
      void   : CARDINAL;
      file   : File;
      i, f   : INTEGER;
      c      : CHAR;
      n      : NadajnikT;
      dataOk : okTab;
      Nag    : Str99;
    BEGIN
      Dane.NazwaInspekcji := CommonData.NazwaOblotu;
      WITH Dane DO
        IF NOT GetInteractiveData( UrzadzenieOK,
                                   Odpowiedzialny,
                                   SamolotPomiarowy,
                                   Dummy ) THEN
          RETURN;
        END;

        Lokalizacja := CommonData.NazwaUrzadz1;
        Polozenie := NadajnikVHF.Polozenie;
        Deklinacja := NadajnikVHF.Deklinacja;

        file := Open( "Kalibracja.ini" );
        Assert( file # MAX( CARDINAL ));
        WITH DataOstatniejKalibracji DO
          GetFileStamp( file, d, m, y, void, void, void );
        END;
        Close( file );

        IF NOT PoczatekWypisywania() THEN
          RETURN;
        END;

        Procedura := pOrbita;
        FOR n := nA TO nB DO
          CommonData.Nadajnik1 := n;
          SciezkaDoKataloguOpisu();
          LoadData( dataOk );
          GoHomeDir;
          IF dataOk[FALSE] THEN
            i := CARDINAL( anRes.promienLubOrbita ) DIV 500;
            f := CARDINAL( anRes.promienLubOrbita ) MOD 500 DIV 5;
            IF (n = nA) THEN
              c := 'G';
            ELSE
              c := 'Z';
            END;
            sprintf3( Nag,
                      "Wykaz zdarzeä dla lotu na orbicie na prom. %d.%02d NM, Nadajnik %c",
                      i, f, c );
            IF NOT WrPrnLn( 0, Nag ) THEN
              RETURN;
            END;

            PiszNaDrukarce( U_COM,
                            FALSE,
                            TypyEventow{ PoczatekPomiaru..BrakZnacznika} );

          END;
        END;
        Procedura := pPromien;
        FOR i := 0 TO 359 DO (* na chama przegladac wszystkie bo to chyba szybciej *)
          FOR n := nA TO nB DO
            CommonData.Nadajnik1 := n;
            CommonData.Promien := i;
            SciezkaDoKataloguOpisu();
            LoadData( dataOk );
            GoHomeDir;
            IF dataOk[FALSE] THEN
              IF (n = nA) THEN
                c := 'G';
              ELSE
                c := 'Z';
              END;
              sprintf2( Nag,
                        "Wykaz zdarzeä dla lotu na prom. %dø, Nadajnik %c",
                         i, c );
            IF NOT WrPrnLn( 0, Nag ) THEN
              RETURN;
            END;

              PiszNaDrukarce( U_COM,
                              TRUE,
                              TypyEventow{ PoczatekPomiaru..BrakZnacznika} );

            END;
          END;
        END;
        IF NOT KoniecWypisywania() THEN
          RETURN;
        END;
      END;
    END RaportKoncowy;

  PROCEDURE InitDane(  );

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
        (* DataOstatniejKalibracji nieinicjowane *);
        NazwaAparaturyPomiarowej := 'CFIS-1';
        SamolotPomiarowy := 'SP-TPA';
      END;
    END InitDane;

BEGIN
  InitDane;
END PI_Report.
