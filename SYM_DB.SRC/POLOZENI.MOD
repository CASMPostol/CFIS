IMPLEMENTATION MODULE Polozenie;


FROM Views IMPORT
  TViewOption, TViewOptions, ofCentered, PGroup;
FROM Dialogs IMPORT
  TDialog, PDialog;
FROM Buttons IMPORT
  PButton, ButtonFlags, ButtonFlag;
FROM StaticTexts IMPORT
  PStaticText;
FROM MsgBox IMPORT
  MessageBox, MsgOptions, MsgOption;
FROM Labels IMPORT
  PLabel;
FROM Drivers IMPORT
  TEvent, EventType, EventTypes;
FROM Objects IMPORT
  TRect;
FROM InputLines IMPORT
  PInputLine;
FROM IntInputLines IMPORT
  PIntInputLine;
FROM RealInputLines IMPORT
  PRealInputLine;
FROM Ini IMPORT
  GetPrivateProfileString;
FROM Commands IMPORT
  cmOK, cmCancel;
FROM stdio IMPORT
  sprintf, sscanf;
FROM Storage IMPORT
  ALLOCATE;
FROM Str IMPORT
  StrToInt, Compare;
FROM Hist IMPORT
  DefineHistorySubView;
FROM HistList IMPORT
  HistoryAdd, HistoryStr, HistoryCount, HistoryDelete, ValidateProc,
  SetValidateProc;
FROM DB_utl IMPORT
  UtnijSpacje, CompareBezSpacji;
IMPORT
  Data;


CONST
  cmLoadVor = 255;
  cmLoadLotn= 254;
  cmLoadNdb = 253;
  cmLoadVhf = 252;
  VORLIST   = "vorlist.ini";
  LOTNLIST  = "lotnlist.ini";
  NDBLIST   = "ndblist.ini";
  VHFLIST   = "vhflist.ini";
  HIST_ID_V = 10;
  HIST_ID_L = 11;
  HIST_ID_N = 12;
  HIST_ID_H = 13;



TYPE
  POpt            = POINTER TO TOpt;
  ilPolozenieGeo  = RECORD
                      Stopnie,
                      Minuty,
                      Setne    : PIntInputLine;
                    END;


  CLASS TOpt( TDialog );
    ilSzerokosc,
    ilDlugosc    : ilPolozenieGeo;
    ilDeklinacja,
    ilTeoOdl,
    ilTeoKat     : PRealInputLine;

    PROCEDURE Init(  );
    VIRTUAL PROCEDURE HandleEvent( VAR Event : TEvent );
  END TOpt;



VAR
  oldValidate : ValidateProc;

PROCEDURE Validate( id : SHORTCARD; VAR str : ARRAY OF CHAR ) : BOOLEAN;
VAR
  i : CARDINAL;
BEGIN
  IF (id = HIST_ID_V) OR
     (id = HIST_ID_L) OR
     (id = HIST_ID_N) OR
     (id = HIST_ID_H)
  THEN
    IF str[0] = 0C THEN
      RETURN FALSE;
    END;
    UtnijSpacje( str );
    FOR i := 1 TO HistoryCount(id) DO
      IF Compare( HistoryStr( id, i-1 )^, str ) = 0 THEN
        RETURN FALSE;
      END;
    END;
    RETURN TRUE;
  ELSE
    RETURN oldValidate( id, str );
  END;
END Validate;

PROCEDURE Load_Data(    prompt : ARRAY OF CHAR;
                        HistId : SHORTCARD;
                    VAR a      : ARRAY OF BYTE ) : PDialog;
VAR
  Dialog : PDialog;
  tytul  : PInputLine;
  R      : TRect;
  Button : PButton;
BEGIN
  R.Assign( 0, 0, 36, 7 );
  NEW( Dialog );
  WITH Dialog^ DO
    Options := Options + ofCentered;
    Init(R, 'Baza danych');
    DefineHistorySubView( Dialog, prompt, HistId, tytul );

    R.Assign(18, 4, 34, 6);
    NEW( Button );
    Button^.Init(R, 'WYJóCIE', cmCancel, ButtonFlags{ bfNormal });
    Insert( Button );

    R.Assign(1, 4, 17, 6);
    NEW( Button );
    Button^.Init(R, '~O~k', cmOK, ButtonFlags{ bfDefault });
    Insert( Button );

    tytul^.SetData( HistoryStr( HistId, 0 )^ );
  END;
  RETURN Dialog;
END Load_Data;

PROCEDURE Org_Pnt_Dialog( VAR Data : ARRAY OF BYTE ):PDialog;
VAR
  D : POpt;
BEGIN
  NEW( D );
  WITH D^ DO
    Init;
    SetData( Data );
  END;
  RETURN D;
END Org_Pnt_Dialog;




  CLASS IMPLEMENTATION TOpt;

    PROCEDURE Init;
    VAR
      Button : PButton;
      StaticText  : PStaticText;
      Label : PLabel;
      Dialog: POpt;
      R: TRect;
      C: CARDINAL;

      PROCEDURE PolozenieGeo(     x, y      : CARDINAL;
                              VAR InputLine : ilPolozenieGeo;
                                  Lab,
                                  Side      : ARRAY OF CHAR;
                                  Szerokosc : BOOLEAN );
      BEGIN
        R.Assign(x, y+1, x+5, y+2 );
        NEW( InputLine.Stopnie );
        IF Szerokosc THEN
          InputLine.Stopnie^.Init(R, 4, -89, 89 );
        ELSE
          InputLine.Stopnie^.Init(R, 4, -179, 179 );
        END;
        Insert(InputLine.Stopnie);

        R.Assign(x, y, x+11, y+1);
        NEW( Label );
        Label^.Init(R, Lab, InputLine.Stopnie );
        Insert( Label );

        R.Assign(x+5, y+1, x+6, y+2 );
        NEW( StaticText );
        StaticText^.Init(R, '¯'+0C);
        Insert(StaticText);

        R.Assign(x+6, y+1, x+11, y+2 );
        NEW( InputLine.Minuty );
        InputLine.Minuty^.Init(R, 4, 0, 59);
        InputLine.Minuty^.SetFormat( "%02d" );
        Insert(InputLine.Minuty);

        R.Assign(x+11, y+1, x+12, y+2 );
        NEW( StaticText );
        StaticText^.Init(R, "'"+0C);
        Insert(StaticText);

        R.Assign(x+12, y+1, x+17, y+2 );
        NEW( InputLine.Setne );
        InputLine.Setne^.Init(R, 4, 0, 99);
        InputLine.Setne^.SetFormat( "%02d" );
        Insert(InputLine.Setne );

        R.Assign(x+17, y+1, x+18, y+2 );
        NEW( StaticText );
        StaticText^.Init(R, Side);
        Insert(StaticText);

      END PolozenieGeo;

      PROCEDURE PolozenieReal(    x, y       : CARDINAL;
                               VAR InputLine : PRealInputLine;
                                   Lab       : ARRAY OF CHAR;
                                   UpL       : LONGREAL );
      BEGIN
        R.Assign(x, y+1, x+17, y+2 );
        NEW( InputLine );
        InputLine^.Init(R, 10, 0.0, UpL );
        InputLine^.SetFormat( "%.2lf" );
        Insert(InputLine);

        R.Assign(x, y, x+17, y+1 );
        NEW( Label );
        Label^.Init( R, Lab, InputLine );
        Insert(Label);
      END PolozenieReal;

    BEGIN
      R.Assign(0, 0, 42, 17 );
      Options := Options + ofCentered;
      TDialog.Init( R, 'Poíoßenie punktu odniesienia');

      PolozenieGeo( 2, 1, ilSzerokosc, "~S~zerokoûç", "N"+0C, TRUE );
      PolozenieGeo( 22, 1, ilDlugosc, "~D~íugoûç", "E"+0C, TRUE );
      R.Assign( 2, 4, 40, 6 );
      NEW( StaticText );
      StaticText^.Init( R, 3C+"Poíoßenie teodolitu wzglëdem punktu ----- odniesienia -----" );
      Insert( StaticText );
      PolozenieReal( 2, 6, ilTeoOdl, "Od~l~egíoûç [m]", 3000.0 );
      PolozenieReal( 22, 6, ilTeoKat, "~K~ierunek [¯]", 359.99999999999 );

      R.Assign( 22, 9, 39, 10 );
      NEW( ilDeklinacja );
        ilDeklinacja^.Init( R, 12, -10.0, +10.0 );
        ilDeklinacja^.SetFormat( "%.2lf" );
        Insert( ilDeklinacja );
      R.Assign( 2, 9, 20, 10 );
        NEW( Label );
        Label^.Init( R, "Deklinac~j~a", ilDeklinacja );
        Insert(Label);

      R.Assign( 2, 13, 39, 14 );
        NEW( StaticText );
        StaticText^.Init( R, "Ladowanie z bazy danych dla..." );
        Insert( StaticText );
      R.Assign( 2, 14, 9, 16 );
        NEW( Button );
        Button^.Init(R, '~V~OR', cmLoadVor, ButtonFlags{ bfNormal });
        Insert( Button );
      R.Assign( 9, 14, 21, 16 );
        NEW( Button );
        Button^.Init(R, '~L~otnisko', cmLoadLotn, ButtonFlags{ bfNormal });
        Insert( Button );
      R.Assign( 21, 14, 28, 16 );
        NEW( Button );
        Button^.Init(R, '~N~DB', cmLoadNdb, ButtonFlags{ bfNormal });
        Insert( Button );
      R.Assign( 28, 14, 35, 16 );
        NEW( Button );
        Button^.Init(R, 'V~H~F', cmLoadVhf, ButtonFlags{ bfNormal });
        Insert( Button );

      R.Assign(2, 11, 19, 13);
        NEW( Button );
        Button^.Init(R, '~O~k', cmOK, ButtonFlags{ bfDefault });
        Insert( Button );

      R.Assign(22, 11, 39, 13);
        NEW( Button );
        Button^.Init(R, 'WYJóCIE', cmCancel, ButtonFlags{ bfNormal });
        Insert( Button );
    END Init;

    VIRTUAL PROCEDURE HandleEvent( VAR Event : TEvent );
    VAR
      Nazwa, str : ARRAY[0..127] OF CHAR;

      PROCEDURE GetInt( il    : PIntInputLine;
                        Entry : ARRAY OF CHAR;
                        Skad  : ARRAY OF CHAR );
      VAR
        i : INTEGER;
      BEGIN
        GetPrivateProfileString( Nazwa,
                                 Entry,
                                 "00",
                                 str,
                                 Skad );
        sscanf( str, "%d", ADR( i ));
        il^.SetData( i );
      END GetInt;

      PROCEDURE GetReal( il    : PRealInputLine;
                         Entry : ARRAY OF CHAR;
                         Skad  : ARRAY OF CHAR );
      VAR
        r : LONGREAL;
      BEGIN
        GetPrivateProfileString( Nazwa,
                                 Entry,
                                 "00",
                                 str,
                                 Skad );
        sscanf( str, "%lf", ADR( r ));
        il^.SetData( r );
      END GetReal;

      PROCEDURE LoadGeoData( prompt,
                             PlikIni : ARRAY OF CHAR;
                             HistId  : SHORTCARD );
      VAR
        Dlg       : PDialog;
        C         : CARDINAL;
        r         : LONGREAL;
      BEGIN
        Nazwa := "***";
        Dlg := Load_Data( prompt, HistId, Nazwa );
        C := Owner^.ExecView( Dlg );
        IF C # cmCancel THEN
          Dlg^.GetData( Nazwa );
          GetPrivateProfileString( Nazwa,
                                   "Deklinacja",
                                   "@@",
                                   str,
                                   PlikIni );
          IF str[0] = '@' THEN
            MessageBox( 3C+"Chyba cos sie pomylilo, w bazie danych nie ma takiego VORa", NIL, MsgOptions{mfWarning,mfOKButton} );
          ELSE
            sscanf( str, "%lf", ADR( r ));
            ilDeklinacja^.SetData( r );
            GetInt( ilDlugosc.Stopnie, "Dlugosc.Stopnie", PlikIni );
            GetInt( ilDlugosc.Minuty, "Dlugosc.Minuty", PlikIni );
            GetInt( ilDlugosc.Setne, "Dlugosc.Setne", PlikIni );
            GetInt( ilSzerokosc.Stopnie, "Szerokosc.Stopnie", PlikIni );
            GetInt( ilSzerokosc.Minuty, "Szerokosc.Minuty", PlikIni );
            GetInt( ilSzerokosc.Setne, "Szerokosc.Setne", PlikIni );
            GetReal( ilTeoOdl, "Teodolit.Odleglosc", PlikIni ); (* czasami jest a czasami nie ma *)
            GetReal( ilTeoKat, "Teodolit.Kat", PlikIni );
            GetPrivateProfileString( Nazwa,
                                     "Pas.Start",
                                     "00",
                                     str,
                                     PlikIni );
            sscanf( str, "%lf", ADR( Data.PoczatekPasa ));

          END;
        END;
      END LoadGeoData;

    BEGIN
      IF evCommand IN Event.What THEN
        CASE Event.Command OF
        | cmLoadVor:
            LoadGeoData( "~V~ory", VORLIST, HIST_ID_V );
        | cmLoadLotn:
            LoadGeoData( "~L~otniska", LOTNLIST, HIST_ID_L );
        | cmLoadNdb:
            LoadGeoData( "~N~db", NDBLIST, HIST_ID_N );
        | cmLoadVhf:
            LoadGeoData( "V~h~f", VHFLIST, HIST_ID_H );
        ELSE
        END;
      END;
      TDialog.HandleEvent( Event );
    END HandleEvent;

  BEGIN
  END TOpt;


  PROCEDURE LoadVorNdbVhf( PlikIni : ARRAY OF CHAR;
                           Fmt     : ARRAY OF CHAR;
                           HistId  : SHORTCARD );
  VAR
    s : ARRAY[0..99] OF CHAR;
    i, cnt : INTEGER;
    j  : CARDINAL;
    ok : BOOLEAN;
  BEGIN
    GetPrivateProfileString( "Lista", "Ilosc", "0"+0C, s, PlikIni );
    cnt := VAL(INTEGER, StrToInt( s, 10, ok ));
    IF NOT ok THEN
      cnt := 0;
    END;
    FOR i := 0 TO cnt-1 DO
      sprintf( s, Fmt, i );
      GetPrivateProfileString( "Lista", s, "", s, PlikIni );
      HistoryAdd( HistId, s );
    END;
  END LoadVorNdbVhf;

  PROCEDURE LoadLotn;
  VAR
    s : ARRAY[0..99] OF CHAR;
    i, cnt : INTEGER;
    j  : CARDINAL;
    ok : BOOLEAN;
  BEGIN
    GetPrivateProfileString( "Lotniska", "Ilosc", "0"+0C, s, LOTNLIST );
    cnt := VAL(INTEGER, StrToInt( s, 10, ok ));
    IF NOT ok THEN
      cnt := 0;
    END;
    FOR i := 0 TO cnt-1 DO
      sprintf( s, "Lotnisko_%d", i );
      GetPrivateProfileString( "Lotniska", s, "", s, LOTNLIST );
      HistoryAdd( HIST_ID_L, s );
    END;
  END LoadLotn;


BEGIN
  SetValidateProc( Validate, oldValidate );
  LoadVorNdbVhf( VORLIST, "VOR%d", HIST_ID_V );
  LoadVorNdbVhf( NDBLIST, "NDB%d", HIST_ID_N );
  LoadVorNdbVhf( VHFLIST, "VHF%d", HIST_ID_H );
  LoadLotn;
END Polozenie.
