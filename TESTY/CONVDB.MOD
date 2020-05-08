(*.F- *)
(**********************************************************************
|  Title   : Polozenie urzadzenia
|  Author  :
|  System  : LOGITECH MODULA-2/86
|  History :
|  Copyright (C), CAS LODZ POLAND.
|  TEL: 42' 86 58 12, 42' 87 80 44 FAX/TEL: 42' 84 48 40
|
**********************************************************************)
(*.F+ *)

MODULE ConvDB;

  FROM TypDanych IMPORT
    MainStates, TypUrzadzenia, PolozenieBiegunWysokosc, ParametryIdentyf,
    ParametryPlikIni, ParametryUrzadzenia;

  FROM GrafTypes IMPORT
    RECT, AssignRect, MoveRect, WHITE, BLUE, MAGENTA, BLACK, LT_RED;

  FROM Buttons IMPORT
    Button, EnableButton;

  FROM Ini IMPORT
    GetPrivateProfileString, WritePrivateProfileString;

  FROM NumberConversion IMPORT
    StringToCard, StringToInt, CardToString;

  FROM GList IMPORT
    HLIST, SetNotificationProc, Sortowana, GetSelection, Skasuj, SetSelection,
    DodajDoListy, Idx2Str, SkasujWszystko, HCONTENT, KillContents, GetContents,
    SetContents;

  FROM Dialog IMPORT
    HDLG, EndDialog, TworzDialog, WstawListe, WstawButton, EnableDlg, Go,
    UsunDialog, Redraw, AltF4, WstawInpLine, GetDialogDIBHandle;

  FROM CommonTypes IMPORT
    TimeAndDate, PolozenieGeo, PolozenieBiegunowe, Str40, Str99, NilValC;

  FROM CommonData IMPORT
    SciezkaOpisuPomiaru, NazwaOblotu, NazwaUrzadz1;

  FROM Strings IMPORT
    Copy, Length, Insert, CompareStr, Concat;

  FROM HiLevGraf IMPORT
    WrStrXY, Wr2fStrXY;

  FROM StdIO IMPORT
    sprintf5, sprintf4, sprintf3, sprintf2, sprintf;

  FROM HiLevGraf IMPORT
    WrStr, SetPaletteEntry;

  IMPORT
    ShortCuts, MsgBox, PI_PA, InpLine;

  FROM GrafUtil IMPORT
    Info, InfoBeep;

  FROM Sounds IMPORT
    Sound, NoSound;

  FROM Timer IMPORT
    Wait, TInOneSecond;

  FROM MANAGER IMPORT
    STARTPROCESS;

  FROM RealConversions IMPORT
    StringToReal;

  FROM InpLine IMPORT
    HLINE, GetText, DoNothing;

  FROM SYSTEM IMPORT
    ADDRESS, ADR;


  TYPE
    str30 =
      ARRAY [ 0 .. 30 ] OF CHAR;


  TYPE
    State =
      ( LOCMenu,
        GSMenu,
        VORMenu,
        ADFMenu,
        VHFMenu );

  VAR
    GtypURZ         : TypUrzadzenia;
    GmainState      : MainStates;
    GParametryURZ   : ParametryUrzadzenia;
    ListaUrz_Obiekt : HLIST;
    RedrawScr       : BOOLEAN;
    hDlg            : HDLG;
    ParamIdenty     : ParametryIdentyf;
        (* currState :State;*)


  PROCEDURE ZmienUrzadz
            (   );
  VAR  
    idx      : INTEGER;
  
  BEGIN
    (* wybrany typ urzadzenia *)
    FOR idx := 0 TO 4 DO
    
    CASE idx OF
      0 :
        GtypURZ := LOC;
      |
      1 :
        GtypURZ := GS;
      |
      2 :
        GtypURZ := VOR;
      |
      3 :
        GtypURZ := ADF;
      |
      4 :
        GtypURZ := VHF;
      ELSE;
    END (* case idx *);
    ParametryPlikIni( GtypURZ, ParamIdenty );   (* ustawienie nazw plikow nazw
                                                   sekcji dla urzadzenia *)
    WstawObloty;   (* ustawienie obiektow dla typu urzadzenia *)
    INC (idx);
    END;
  END ZmienUrzadz;

  PROCEDURE ZmienOiekt
            ( );

  VAR
    s     : ARRAY [ 0 .. 119 ] OF CHAR;
    bufor : ARRAY [ 0 .. 15 ] OF CHAR;
    nr    : ARRAY [ 0 .. 5 ] OF CHAR;
    R     : RECT;
    okZO  : BOOLEAN;

  BEGIN
    GetPrivateProfileString( ParamIdenty.Nazwa, ParamIdenty.SzerokoscSetne, "",
                             bufor, ParamIdenty.NazwaPlikuOpisu );
    
    StringToCard( bufor, GParametryURZ.Polozenie.Szerokosc.DziesTys, okZO );
    IF (okZO) AND (GParametryURZ.Polozenie.Szerokosc.DziesTys < 99)
    THEN
      GParametryURZ.Polozenie.Szerokosc.DziesTys:=GParametryURZ.Polozenie.Szerokosc.DziesTys*100;
      CardToString(GParametryURZ.Polozenie.Szerokosc.DziesTys,bufor,4);
      WritePrivateProfileString( ParamIdenty.Nazwa, ParamIdenty.SzerokoscSetne,
                             bufor, ParamIdenty.NazwaPlikuOpisu );
    END;
    GetPrivateProfileString( ParamIdenty.Nazwa, ParamIdenty.DlugoscSetne, "",
                             bufor, ParamIdenty.NazwaPlikuOpisu );
    StringToCard( bufor, GParametryURZ.Polozenie.Dlugosc.DziesTys, okZO );

    IF (okZO) AND (GParametryURZ.Polozenie.Dlugosc.DziesTys < 99)
    THEN
      GParametryURZ.Polozenie.Dlugosc.DziesTys:= GParametryURZ.Polozenie.Dlugosc.DziesTys*100;
      CardToString(GParametryURZ.Polozenie.Dlugosc.DziesTys,bufor,4);
      WritePrivateProfileString( ParamIdenty.Nazwa, ParamIdenty.DlugoscSetne,
                             bufor, ParamIdenty.NazwaPlikuOpisu );
    END;

  END ZmienOiekt;

  PROCEDURE WstawObloty();

  VAR
    u,
    sekcja : ARRAY [ 0 .. 99 ] OF CHAR;
    ok     : BOOLEAN;
    ile,
    i      : INTEGER;

  BEGIN
    GetPrivateProfileString( ParamIdenty.Lista, ParamIdenty.Ilosc, "0", u,
                             ParamIdenty.NazwaPlikuOpisu );
    StringToInt( u, ile, ok );
    IF NOT ok
    THEN
      ile := 0;
    END (* if *);
    ok := FALSE;
    FOR i := 0 TO ile - 1 DO
      sprintf( u, "%d", i );
      Concat( ParamIdenty.Urzadz, u, sekcja );
      GetPrivateProfileString( ParamIdenty.Lista, sekcja, "", u,
                               ParamIdenty.NazwaPlikuOpisu );
      Copy(u,0,Length(u),ParamIdenty.Nazwa);
      ZmienOiekt;
    END (* for i *);
  END WstawObloty;



  BEGIN
    Info( "" );   (* komunikat na ekran *)
    ZmienUrzadz;
END ConvDB.
