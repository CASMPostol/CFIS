IMPLEMENTATION MODULE LOT_data;

FROM Objects IMPORT
  TRect, DisposeStr, NewStr, PString;
FROM Drivers IMPORT
  TEvent, EventType;
FROM IntInputLines IMPORT
  PIntInputLine;
FROM RealInputLines IMPORT
  PRealInputLine;
FROM InputLines IMPORT
  PInputLine, TInputLine;
FROM StaticTexts IMPORT
  PStaticText;
FROM CheckBoxes IMPORT
  PCheckBoxes;
FROM Clusters IMPORT
  NewSItem;
FROM Dialogs IMPORT
  PDialog, TDialog;
FROM Views IMPORT
  TViewOption, TViewOptions, ofCentered, EnableCommand, DisableCommand;
FROM Labels IMPORT
  PLabel;
FROM Storage IMPORT
  ALLOCATE, DEALLOCATE;
FROM Hist IMPORT
  DefineHistorySubView, SetNotification, LOT_HIST_ID, LOT_FREQ_ID,
  DefineFreqListSubView;
FROM Str IMPORT
  Copy, StrToInt, Compare, StrToCard, StrToReal, Item, CHARSET, Append;
FROM Buttons IMPORT
  PButton, ButtonFlag, ButtonFlags;
FROM Ini IMPORT
  WritePrivateProfileString, GetPrivateProfileString, DeleteSection;
FROM stdio IMPORT
  sprintf, sscanf;
FROM HistList IMPORT
  HistoryAdd, HistoryStr, HistoryCount, HistoryDelete;
FROM Freq IMPORT
  LOCfreqCRT, GSfreqCRT;
FROM Commands IMPORT
  cmOK, cmCancel;
FROM Warn IMPORT
  LockCnt;
FROM DB_utl IMPORT
  UtnijSpacje, CompareBezSpacji;
IMPORT
  Potw;

FROM LOT_GPda IMPORT
   GPS_Dialog;


FROM DB_Common IMPORT
 Blok ,SetBlock1;
  
TYPE
  PLOTD = POINTER TO LOTD;

VAR
  p       : PLOTD;
  Desktop : PGroup;

CONST
  LOT_LIST = "LotnList.ini";

CLASS LOTD( TDialog );
   AktualneLotnisko : ARRAY[0..127] OF CHAR;
   Szerokosc,
   Dlugosc        : Blok;
   OdlegloscGS    : PRealInputLine;
   OdlegloscLOC   : PRealInputLine;
   KierunekPasa   : PIntInputLine;
   Deklinacja     : PRealInputLine;
   Tytul          : PInputLine;
   Czestotliwosc  : PInputLine;
   IsDme          : PCheckBoxes;
   Identyfikator  : PInputLine;
   Kategoria      : PIntInputLine;
   ProgPasa       : PRealInputLine;
   KoniecPasa     : PRealInputLine;
   Marker         : ARRAY[0..2] OF PRealInputLine;
   PnktChar       : ARRAY[0..4] OF PRealInputLine;
   SzerGS         : PRealInputLine;
   KatGS          : PRealInputLine;
   Szer_Sekt      : PRealInputLine;
   Szer_Sekt_W,
   Szer_Sekt_S    : PRealInputLine;
   DME_Szerokosc,
   DME_Dlugosc    : Blok;
   DmeOffset      : PRealInputLine;
   (*
   DmeAzymut      : PRealInputLine;
   DmeOdleglosc   : PRealInputLine;
   *)
   PROCEDURE LOTGPS;
   PROCEDURE Init;
   PROCEDURE ResetValue( VAR s : ARRAY OF CHAR );
   PROCEDURE NoweLotnisko;
   PROCEDURE Zapisz;
   PROCEDURE LoadLotnisko;
   PROCEDURE Odczytaj;
   PROCEDURE UsunZBazy;
   VIRTUAL PROCEDURE Done;
   VIRTUAL PROCEDURE HandleEvent( VAR E : TEvent );
END LOTD;

PROCEDURE ZmieniloSie( VAR s : ARRAY OF CHAR );
BEGIN
  IF p # NIL THEN
    p^.ResetValue( s );
  END;
END ZmieniloSie;

CLASS IMPLEMENTATION LOTD;

  PROCEDURE Init;
  CONST
    Kolumna2 = 38;

  VAR
    R      : TRect;
    n      : PInputLine;
    l      : PLabel;
    st     : PStaticText;
    Button : PButton;

    PROCEDURE SetReal(     LabelText : ARRAY OF CHAR;
                       VAR p         : PRealInputLine;
                           max       : LONGREAL;
                           dodatnie  : BOOLEAN;
                           x, y      : CARDINAL      );
    BEGIN
      R.Assign( x+13, y, x+30, y+1 );
      NEW( p );
      IF dodatnie THEN
        p^.Init( R, 15, 0.0, max );
      ELSE
        p^.Init( R, 15, -max, max );
      END;
      p^.SetFormat( "%.2lf" );
      Insert( p );

      R.Assign( x, y, x+13, y+1 );
      NEW( l );
      l^.Init( R, LabelText, p );
      Insert( l );

    END SetReal;

    PROCEDURE SetInt1(     LabelText : ARRAY OF CHAR;
                       VAR p         : PIntInputLine;
                           od, do    : INTEGER;
                           x, y      : CARDINAL      );
    BEGIN
      R.Assign( x+13, y, x+30, y+1 );
      NEW( p );
      p^.Init( R, 15, od, do );
      p^.SetFormat( "%03d" );
      Insert( p );

      R.Assign( x, y, x+13, y+1 );
      NEW( l );
      l^.Init( R, LabelText, p );
      Insert( l );

    END SetInt1;

    PROCEDURE SetInt(     LabelText : ARRAY OF CHAR;
                       VAR p         : PIntInputLine;
                           x, y      : CARDINAL      );
    BEGIN
      SetInt1( LabelText, p, -180, 359, x, y );
    END SetInt;

    PROCEDURE PunktyCharakterystyczne;
    VAR
      i : CARDINAL;
      loc_str : ARRAY[0..63] OF CHAR;
    BEGIN
      R.Assign( Kolumna2-1, 12, 71, 18 );
        NEW( st );
        st^.Init( R, "Õ                               Í¸"+15C+12C+
                     "³                                ³"+15C+12C+
                     "³                                ³"+15C+12C+
                     "³                                ³"+15C+12C+
                     "³                                ³"+15C+12C+
                     "À¯Punkty charakterystyczne®ÄÄÄÄÄÄÙ" );
        Insert( st );

      FOR i := 0 TO 4 DO
        sprintf( loc_str, "-=>~%c~", CHR( i+ORD( 'A' )));
        IF i=2 THEN
          Append( loc_str, "(TH)" );
        END;
        SetReal( loc_str, PnktChar[i], 100.0, TRUE, Kolumna2, 12+i );
          R.Assign( 68, 12+i, 70, 12+1+i );
          NEW( st );
          st^.Init( R, "NM" );
          Insert( st );
      END;
    END PunktyCharakterystyczne;


  BEGIN
    INC( LockCnt );
    DisableCommand( cmLOTdatabase );
    R.Assign( 0, 0, 73, 22 );
    TDialog.Init( R, "Baza danych pas¢w lotnisk" );
    Options := Options + ofCentered ;
    DefineHistorySubView( ADR( SELF ), "Zadane Lotnisko (~X~)", LOT_HIST_ID, Tytul );
    DefineFreqListSubView( ADR( SELF ), LOT_FREQ_ID, Czestotliwosc );

    SetNotification( LOT_HIST_ID, ZmieniloSie );

    SetBlock1(SELF, "~S~zeroko˜†", Szerokosc, "N", 2, 4 );
    SetBlock1(SELF, "Dlu~g~o˜†",   Dlugosc,   "E", 2, 5 );

    R.Assign( 15, 6, 32, 7 );
      NEW( Deklinacja );
      Deklinacja^.Init( R, 15, -10.0, +10.0 );
      Deklinacja^.SetFormat( "%.2lf" );
      Insert( Deklinacja );
    R.Assign( 2, 6, 15, 7 );
      NEW( l );
      l^.Init( R, "Deklinac~j~a", Deklinacja );
      Insert( l );
    R.Assign( 32, 6, 33, 7 );
      NEW( st );
      st^.Init( R, "ø" );
      Insert( st );

    R.Assign( 1, 7, 35, 10 );
      NEW( st );
      st^.Init( R, "Õ                               Í¸"+15C+12C+
                   "³                                ³"+15C+12C+
                   "À¯Teodolit®ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ" );
      Insert( st );

    SetReal( "Odl. ~G~S", OdlegloscGS, +100.0, FALSE, 2, 7 );
    R.Assign( 32, 7, 33, 8 );
      NEW( st );
      st^.Init( R, "m" );
      Insert( st );

    SetReal( "Odl. ~L~oc", OdlegloscLOC, +1000.0, FALSE, 2, 8 );
    R.Assign( 32, 8, 33, 9 );
      NEW( st );
      st^.Init( R, "m" );
      Insert( st );

    R.Assign( 1, 10, 35, 14 );
      NEW( st );
      st^.Init( R, "Õ                               Í¸"+15C+12C+
                   "³                                ³"+15C+12C+
                   "³                                ³"+15C+12C+
                   "À¯Pas lotniska®ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ" );
      Insert( st );

    SetInt( "~K~ier.pasa", KierunekPasa, 2, 10 );
    R.Assign( 32, 10, 33, 11 );
      NEW( st );
      st^.Init( R, "ø" );
      Insert( st );
    SetReal( "~P~r¢g", ProgPasa, 40.0, TRUE, 2, 11 );
      R.Assign( 32, 11, 34, 12 );
      NEW( st );
      st^.Init( R, "NM" );
      Insert( st );
    SetReal( "Ko~n~iec", KoniecPasa, 40.0, TRUE, 2, 12 );
      R.Assign( 32, 12, 34, 13 );
      NEW( st );
      st^.Init( R, "NM" );
      Insert( st );

    R.Assign( 1, 14, 35, 18 );
      NEW( st );
      st^.Init( R, "Õ                               Í¸"+15C+12C+
                   "³                                ³"+15C+12C+
                   "³                                ³"+15C+12C+
                   "À¯Poˆo¾enie marker¢w®ÄÄÄÄÄÄÄÄÄÄÄÄÙ" );
      Insert( st );

    SetReal( "~W~ewn©trzny", Marker[0], 100.0, FALSE, 2, 14 );
      R.Assign( 32, 14, 34, 15 );
      NEW( st );
      st^.Init( R, "NM" );
      Insert( st );
    SetReal( "—rodkow~y~", Marker[1], 100.0, FALSE, 2, 15 );
      R.Assign( 32, 15, 34, 16 );
      NEW( st );
      st^.Init( R, "NM" );
      Insert( st );
    SetReal( "~Z~ewn©trzny", Marker[2], 100.0, FALSE, 2, 16 );
      R.Assign( 32, 16, 34, 17 );
      NEW( st );
      st^.Init( R, "NM" );
      Insert( st );

    R.Assign( 1, 18, 35, 21 );
      NEW( st );
      st^.Init( R, "Õ                               Í¸"+15C+12C+
                   "³                                ³"+15C+12C+
                   "À¯—cie¾ka schodzenia®ÄÄÄÄÄÄÄÄÄÄÄÄÙ" );
      Insert( st );

    SetReal( "Sze~r~oko˜†", SzerGS, 180.0, TRUE, 2, 18 );
      R.Assign( 32, 18, 34, 19 );
      NEW( st );
      st^.Init( R, "ø" );
      Insert( st );
    SetReal( "K¥~t~", KatGS, 90.0, TRUE, 2, 19 );
      R.Assign( 32, 19, 34, 20 );
      NEW( st );
      st^.Init( R, "ø" );
      Insert( st );

    SetInt1( "Ka~t~egoria", Kategoria, 1, 3, 36, 1 );
    Kategoria^.SetFormat( "%d" );

    R.Assign( 49, 2, 56, 3 );
      NEW( Identyfikator );
      Identyfikator^.Init( R, 4 );
      Insert( Identyfikator );
    R.Assign( 36, 2, 49, 3 );
      NEW( l );
      l^.Init( R, "Identy~f~.", Identyfikator );
      Insert( l );

    R.Assign( Kolumna2-1, 3, 71, 8 );
      NEW( st );
      st^.Init( R, "Õ                               Í¸"+15C+12C+
                   "³                                ³"+15C+12C+
                   "³                                ³"+15C+12C+
                   "³                                ³"+15C+12C+
                   "À¯Parametry DME®ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ" );
      Insert( st );

    R.Assign( 38, 3, 68, 4 );
      NEW( IsDme );
      IsDme^.Init( R, NewSItem( "D~M~E zainstalowane", NIL ));
      Insert( IsDme );
    SetBlock1(SELF, "~S~zeroko˜†", DME_Szerokosc, "N", Kolumna2, 4 );
    SetBlock1(SELF, "Dlu~g~o˜†",   DME_Dlugosc,   "E", Kolumna2, 5 );
    SetReal( "Offset", DmeOffset, 10.0, TRUE,          Kolumna2, 6 );
      R.Assign( 68, 6, 70, 7 );
      NEW( st );
      st^.Init( R, "NM" );
      Insert( st );
    
    (*
    SetReal( "Azymut", DmeAzymut, 359.999999999999999, TRUE, Kolumna2, 4 );
      R.Assign( 68, 4, 70, 5 );
      NEW( st );
      st^.Init( R, "ø" );
      Insert( st );
    SetReal( "Odleglosc", DmeOdleglosc, 10.0, TRUE, Kolumna2, 6 );
      R.Assign( 68, 6, 70, 7 );
      NEW( st );
      st^.Init( R, "NM" );
      Insert( st );
    *)
    
    SetReal( "Szer.Sekt", Szer_Sekt, 90.0, TRUE, Kolumna2, 8 );
      R.Assign( 68, 8, 70, 9 );
      NEW( st );
      st^.Init( R, "ø" );
      Insert( st );
    R.Assign( Kolumna2-1, 9, 71, 13 );
      NEW( st );
      st^.Init( R, "Õ                               Í¸"+15C+12C+
                   "³                                ³"+15C+12C+
                   "À¯Alarmy szeroko˜ci sektor¢w®ÄÄÄÄÙ" );
      Insert( st );

    SetReal( "W¥ski", Szer_Sekt_W, 90.0, TRUE, Kolumna2, 9 );
      R.Assign( 68, 9, 70, 10 );
      NEW( st );
      st^.Init( R, "ø" );
      Insert( st );
    SetReal( "Szeroki", Szer_Sekt_S, 90.0, TRUE, Kolumna2, 10 );
      R.Assign( 68, 10, 70, 11 );
      NEW( st );
      st^.Init( R, "ø" );
      Insert( st );

    PunktyCharakterystyczne;

    R.Assign( Kolumna2, 18, 70, 20 );
      NEW( Button );
      Button^.Init( R, "Stacja referencyjna GPS",cmLOTGPS, ButtonFlags{bfNormal} );
      Insert( Button );

    R.Assign( Kolumna2, 20, 70, 22 );
      NEW( Button );
      Button^.Init( R, "~U~suä z bazy danych", cmUsunZBazy, ButtonFlags{bfNormal} );
      Insert( Button );

    LoadLotnisko;
    p := ADR( SELF );
    Odczytaj;

  END Init;

  VIRTUAL PROCEDURE HandleEvent( VAR E : TEvent );
  BEGIN
    TDialog.HandleEvent( E );
    IF evCommand IN E.What THEN
      CASE E.Command OF
      | cmUsunZBazy:
          UsunZBazy;
      |   cmLOTGPS:
            LOTGPS;

            
      ELSE
        RETURN;
      END;
    END;
  END HandleEvent;


  PROCEDURE LOTGPS;
  VAR
    Dialog: PDialog;
    C: CARDINAL;
  BEGIN
  
    Dialog := GPS_Dialog( AktualneLotnisko );
    C := Desktop^.ExecView(Dialog);
    IF C <> cmCancel THEN
    END;
    Dialog^.Done;
    DISPOSE(Dialog);
  END LOTGPS;



  PROCEDURE UsunZBazy;
  VAR
    s, s1   : ARRAY[0..49] OF CHAR;
    sp      : PString;
    cnt     : INTEGER;
    i, j, k : INTEGER;
    ok      : BOOLEAN;
  BEGIN
    UtnijSpacje( AktualneLotnisko );
    IF AktualneLotnisko[0] = 0C THEN
      RETURN;
    END;
    IF NOT Potw.UsunZBazy() THEN
      RETURN;
    END;
    GetPrivateProfileString( "Lotniska", "Ilosc", "0"+0C, s, LOT_LIST );
    cnt := VAL(INTEGER, StrToInt( s, 10, ok ));
    IF NOT ok THEN
      cnt := 0;
    END;
    i := 0;
    LOOP
      sprintf( s, "Lotnisko_%d", i );
      GetPrivateProfileString( "Lotniska", s, "", s, LOT_LIST );
      IF CompareBezSpacji( s, AktualneLotnisko ) = 0 THEN
        EXIT;
      END;
      INC( i );
      IF i > cnt THEN
        RETURN; (* nie ma takiego *)
      END;
    END;
    DeleteSection( AktualneLotnisko, LOT_LIST );
    sp := HistoryStr( LOT_HIST_ID, i );
    IF sp # NIL THEN
      HistoryDelete( LOT_HIST_ID, sp^ );
    END;
    k := i;
    WHILE i < cnt DO
      j := i+1;
      sprintf( s, "Lotnisko_%d", j );
      GetPrivateProfileString( "Lotniska", s, "", s1, LOT_LIST );
      sprintf( s, "Lotnisko_%d", i );
      WritePrivateProfileString( "Lotniska", s, s1, LOT_LIST );
      INC( i );
    END;
    j := cnt - 1;
    sprintf( s, "%d", j );
    WritePrivateProfileString( "Lotniska", "Ilosc", s, LOT_LIST );

    (* a teraz, zeby sie pojawilo cos nowego *)
    IF k = cnt-1 THEN
      DEC( k );
    END;
    sprintf( s, "Lotnisko_%d", k );
    GetPrivateProfileString( "Lotniska", s, "", AktualneLotnisko, LOT_LIST );
    Tytul^.SetData( AktualneLotnisko );
    Odczytaj;
  END UsunZBazy;

  PROCEDURE NoweLotnisko;
  VAR
    s : ARRAY[0..99] OF CHAR;
    i, cnt : INTEGER;
    ok : BOOLEAN;
  BEGIN
    UtnijSpacje( AktualneLotnisko );
    IF AktualneLotnisko[0] = 0C THEN
      RETURN;
    END;
    GetPrivateProfileString( "Lotniska", "Ilosc", "0"+0C, s, LOT_LIST );
    cnt := VAL(INTEGER, StrToInt( s, 10, ok ));
    IF NOT ok THEN
      cnt := 0;
    END;
    FOR i := 0 TO cnt-1 DO
      sprintf( s, "Lotnisko_%d", i );
      GetPrivateProfileString( "Lotniska", s, "", s, LOT_LIST );
      IF Compare( s, AktualneLotnisko ) = 0 THEN
        RETURN (* ten vor byl juz w bazie danych *)
      END;
    END;
    sprintf( s, "Lotnisko_%d", cnt );
    WritePrivateProfileString( "Lotniska", s, AktualneLotnisko, LOT_LIST );
    INC( cnt );
    sprintf( s, "%d", cnt );
    WritePrivateProfileString( "Lotniska", "Ilosc", s, LOT_LIST );
  END NoweLotnisko;

  PROCEDURE LoadLotnisko;
  VAR
    s : ARRAY[0..99] OF CHAR;
    i, cnt : INTEGER;
    j  : CARDINAL;
    ok : BOOLEAN;
  BEGIN
    GetPrivateProfileString( "Lotniska", "Ilosc", "0"+0C, s, LOT_LIST );
    cnt := VAL(INTEGER, StrToInt( s, 10, ok ));
    IF NOT ok THEN
      cnt := 0;
    END;
    FOR i := 0 TO cnt-1 DO
      sprintf( s, "Lotnisko_%d", i );
      GetPrivateProfileString( "Lotniska", s, "", s, LOT_LIST );
      HistoryAdd( LOT_HIST_ID, s );
    END;
    IF cnt = 0 THEN
      AktualneLotnisko := '';
    ELSE
      Copy( AktualneLotnisko, HistoryStr( LOT_HIST_ID, 0 )^ );
    END;
    Tytul^.SetData( AktualneLotnisko );
  END LoadLotnisko;

  PROCEDURE Zapisz;
  VAR
    s : ARRAY[0..127] OF CHAR;

    PROCEDURE TextI( il : PIntInputLine; Entry : ARRAY OF CHAR );
    BEGIN
      il^.TInputLine.GetData( s );
      WritePrivateProfileString( AktualneLotnisko,
                                 Entry,
                                 s,
                                 LOT_LIST );
     END TextI;

    PROCEDURE TextR( il : PRealInputLine; Entry : ARRAY OF CHAR );
    BEGIN
      il^.TInputLine.GetData( s );
      WritePrivateProfileString( AktualneLotnisko,
                                 Entry,
                                 s,
                                 LOT_LIST );
     END TextR;

  VAR
    i, j   : CARDINAL;
    str,
    e      : ARRAY[0..20] OF CHAR;
    zn     : BOOLEAN;
  BEGIN
(*    Tytul^.GetData( AktualnyVOR );*)
    IF AktualneLotnisko[0] = 0C THEN
      RETURN;
    END;
    TextI( Szerokosc.Stopnie,     "Szerokosc.Stopnie" );
    TextI( Szerokosc.Minuty,      "Szerokosc.Minuty" );
    TextI( Szerokosc.Setne,       "Szerokosc.DTysieczne" );
    TextI( Dlugosc.Stopnie,       "Dlugosc.Stopnie" );
    TextI( Dlugosc.Minuty,        "Dlugosc.Minuty" );
    TextI( Dlugosc.Setne,         "Dlugosc.DTysieczne" );
    TextR( OdlegloscGS,           "Teodolit.Odleglosc.GS" );
    TextR( OdlegloscLOC,          "Teodolit.Odleglosc.LOC" );
    TextR( Deklinacja,            "Deklinacja" );
    TextI( KierunekPasa,          "KierunekPasa" );
    TextI( Kategoria,             "Kategoria" );
    TextR( ProgPasa,              "Pas.Start" );
    TextR( KoniecPasa,            "Pas.Koniec" );
    TextR( SzerGS,                "Szerokosc.GS" );
    TextR( KatGS,                 "Kat.GS" );
    TextR( Szer_Sekt_W,           "Szerokosc.Sektora-A.Waski" );
    TextR( Szer_Sekt,             "Szerokosc.Sektora.N" );
    TextR( Szer_Sekt_S,           "Szerokosc.Sektora-A.Szeroki" );
    TextI( DME_Szerokosc.Stopnie, "DME.Szerokosc.Stopnie" );
    TextI( DME_Szerokosc.Minuty,  "DME.Szerokosc.Minuty" );
    TextI( DME_Szerokosc.Setne,   "DME.Szerokosc.DTysieczne" );
    TextI( DME_Dlugosc.Stopnie,   "DME.Dlugosc.Stopnie" );
    TextI( DME_Dlugosc.Minuty,    "DME.Dlugosc.Minuty" );
    TextI( DME_Dlugosc.Setne,     "DME.Dlugosc.DTysieczne" );
    (*
    TextR( DmeAzymut,         "DME.Azymut" );
    TextR( DmeOdleglosc,      "DME.Odleglosc" );
    *)
    TextR( DmeOffset,         "DME.Offset" );
    FOR i := 0 TO 2 DO
      sprintf( e, "Marker.%d", i );
      TextR( Marker[i], e );
    END;
    FOR i := 0 TO 4 DO
      sprintf( e, "Punkt.Ch.%c", CHR( i+ORD( 'A' ) ) );
      TextR( PnktChar[i], e );
    END;

    Identyfikator^.GetData( str );
    WritePrivateProfileString( AktualneLotnisko,
                               "Identyfikator",
                               str,
                               LOT_LIST );
    IsDme^.GetData( i );
    sprintf( str, "%d", i );
    WritePrivateProfileString( AktualneLotnisko,
                               "Dme",
                               str,
                               LOT_LIST );
    (* czestotliwosc *)
    Czestotliwosc^.GetData( s );
    zn := FALSE;
    FOR i := 0 TO HistoryCount( LOT_FREQ_ID )-1 DO
      Copy( str, HistoryStr( LOT_FREQ_ID, i )^ );
      IF Compare( str, s ) = 0 THEN
        zn := TRUE;
        sprintf(s, "%d", i );
        WritePrivateProfileString( AktualneLotnisko,
                                   "Czestotliwosc",
                                   s,
                                   LOT_LIST );
      END;
    END;
    IF NOT zn THEN
      WritePrivateProfileString( AktualneLotnisko,
                                 "Czestotliwosc",
                                 "0",
                                 LOT_LIST );
    END;
    NoweLotnisko;
  END Zapisz;

  PROCEDURE Odczytaj;
  VAR
    s : ARRAY[0..127] OF CHAR;
    CalkowitaIlosc, i, j : INTEGER;
    ok : BOOLEAN;
    sp : PString;

    PROCEDURE TextI( il : PIntInputLine; Entry : ARRAY OF CHAR );
    VAR
      i : INTEGER;
    BEGIN
      GetPrivateProfileString( AktualneLotnisko,
                               Entry,
                               "00",
                               s,
                               LOT_LIST );
      Item( s, s, CHARSET{' '}, 0 );
      i := VAL( INTEGER, StrToInt( s, 10, ok ));
      IF NOT ok THEN
        i := 0;
      END;
      il^.SetData( i );
    END TextI;

    PROCEDURE TextR( il : PRealInputLine; Entry : ARRAY OF CHAR );
    VAR
      r : LONGREAL;
    BEGIN
      GetPrivateProfileString( AktualneLotnisko,
                               Entry,
                               "00",
                               s,
                               LOT_LIST );
      Item( s, s, CHARSET{' '}, 0 );
      r := StrToReal( s, ok );
      IF NOT ok THEN
        r := 0.0;
      END;
      il^.SetData( r );
    END TextR;

  VAR
    fi : INTEGER;
    str,
    e  : ARRAY[0..20] OF CHAR;
  BEGIN
(*    Tytul^.GetData( AktualnyVOR );*)
    IF AktualneLotnisko[0] = 0C THEN
      RETURN;
    END;
    TextI( Szerokosc.Stopnie,     "Szerokosc.Stopnie" );
    TextI( Szerokosc.Minuty,      "Szerokosc.Minuty" );
    TextI( Szerokosc.Setne,       "Szerokosc.DTysieczne" );
    TextI( Dlugosc.Stopnie,       "Dlugosc.Stopnie" );
    TextI( Dlugosc.Minuty,        "Dlugosc.Minuty" );
    TextI( Dlugosc.Setne,         "Dlugosc.DTysieczne" );
    TextR( Deklinacja,            "Deklinacja" );
    TextR( OdlegloscGS,           "Teodolit.Odleglosc.GS" );
    TextR( OdlegloscLOC,          "Teodolit.Odleglosc.LOC" );
    TextI( KierunekPasa,          "KierunekPasa" );
    TextI( Kategoria,             "Kategoria" );
    TextR( ProgPasa,              "Pas.Start" );
    TextR( KoniecPasa,            "Pas.Koniec" );
    TextR( SzerGS,                "Szerokosc.GS" );
    TextR( KatGS,                 "Kat.GS" );
    TextR( Szer_Sekt,             "Szerokosc.Sektora.N" );
    TextR( Szer_Sekt_W,           "Szerokosc.Sektora-A.Waski" );
    TextR( Szer_Sekt_S,           "Szerokosc.Sektora-A.Szeroki" );
    TextI( DME_Szerokosc.Stopnie, "DME.Szerokosc.Stopnie" );
    TextI( DME_Szerokosc.Minuty,  "DME.Szerokosc.Minuty" );
    TextI( DME_Szerokosc.Setne,   "DME.Szerokosc.DTysieczne" );
    TextI( DME_Dlugosc.Stopnie,   "DME.Dlugosc.Stopnie" );
    TextI( DME_Dlugosc.Minuty,    "DME.Dlugosc.Minuty" );
    TextI( DME_Dlugosc.Setne,     "DME.Dlugosc.DTysieczne" );
    (*
    TextR( DmeAzymut,             "DME.Azymut" );
    TextR( DmeOdleglosc,          "DME.Odleglosc" );
    *)
    TextR( DmeOffset,             "DME.Offset" );
    FOR i := 0 TO 2 DO
      sprintf( e, "Marker.%d", i );
      TextR( Marker[i], e );
    END;
    FOR i := 0 TO 4 DO
      sprintf( e, "Punkt.Ch.%c", CHR( i+ORD( 'A' ) ) );
      TextR( PnktChar[i], e );
    END;

    GetPrivateProfileString( AktualneLotnisko,
                             "Identyfikator",
                             "***",
                             str,
                             LOT_LIST );
    Identyfikator^.SetData( str );
    GetPrivateProfileString( AktualneLotnisko,
                             "Dme",
                             "00",
                             str,
                             LOT_LIST );
    sscanf( str, "%d", ADR(i) );
    IsDme^.SetData( i );

    (* czestotliwosc *)
    GetPrivateProfileString( AktualneLotnisko, "Czestotliwosc", "0", s, LOT_LIST );
    sscanf( s, "%d", ADR( fi ));
    Czestotliwosc^.SetData( HistoryStr( LOT_FREQ_ID, fi )^ );
  END Odczytaj;

  PROCEDURE ResetValue( VAR s : ARRAY OF CHAR );
  BEGIN
    Zapisz;
    Copy( AktualneLotnisko, s );
    Odczytaj;
  END ResetValue;

  VIRTUAL PROCEDURE Done;
  VAR
    s : ARRAY[0..1] OF CHAR;
    i : INTEGER;
  BEGIN
    DEC( LockCnt );
    s[0] := 0C;
    Tytul^.GetData( AktualneLotnisko );
    ResetValue( s );
    EnableCommand( cmLOTdatabase );
    FOR i := 0 TO VAL( INTEGER, HistoryCount( LOT_HIST_ID ))-1 DO
      HistoryDelete( LOT_HIST_ID, HistoryStr( LOT_HIST_ID, 0 )^ );
    END;
    TDialog.Done;
  END Done;

BEGIN
  AktualneLotnisko[0] := 0C;
END LOTD;


PROCEDURE LOTdata( g : PGroup );
VAR
  d : PLOTD;
BEGIN
  NEW( d );
  Desktop := g;
  WITH d^ DO
    Init;
    g^.Insert( d );
  END;
END LOTdata;

BEGIN
  p := NIL;
END LOT_data.

