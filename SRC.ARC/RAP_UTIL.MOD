(*
  Tworzenie Strony Tytulowej do raportow koncowych
  Michal Morawski
  11-25-96 10:46am
*)

IMPLEMENTATION MODULE Rap_Util;

FROM CommonTypes IMPORT
  Str99;
FROM Dialog IMPORT
  HDLG, TworzDialog, Go, UsunDialog, WstawListe, WstawButton, AltF4,
  EndDialog;
FROM GrafTypes IMPORT
  RECT, AssignRect, MoveRect;
FROM GList IMPORT
  HLIST, Idx2Str, GetSelection, DodajDoListy;
FROM Buttons IMPORT
  Button, CallProc, ChangeButtonText;
FROM NumberConversion IMPORT
  StringToInt;
FROM StdIO IMPORT
  sprintf;
FROM Ini IMPORT
  GetPrivateProfileString;
FROM Strings IMPORT
  Assign;
IMPORT
  ShortCuts;

CONST
  SEKCJA = "Lista odpowiedzialnych";
  NAZWA_PLIKU_INI = "odp.ini";

VAR
  SpelniaWymagania : BOOLEAN;
  SamName          : ARRAY[0..5] OF CHAR;
  Sam              : Button;

PROCEDURE GetInteractiveData( VAR PomiarOK       : BOOLEAN;
                              VAR Odpowiedzialny : ARRAY OF CHAR;
                              VAR SamolotRej     : ARRAY OF CHAR;
                                  DodInfo        : InfoProc ) : BOOLEAN;
  VAR
    hDlg                  : HDLG;
    R                     : RECT;
    ListaOdpowiedzialnych : HLIST;
    b                     : Button;
    s                     : Str99;
    Ilosc, i              : INTEGER;
    ok                    : BOOLEAN;
  BEGIN
    AssignRect( R, 0, 0, 800, 600 );
    hDlg := TworzDialog( R, "RaportK.dib", FALSE );
    AssignRect( R, 50, 50, 350, 350 );
    ListaOdpowiedzialnych := WstawListe( hDlg, R, FALSE );
    AssignRect( R, 50, 370, 350, 400 );
    WstawButton( hDlg,
                 R,
                 "",
                 3,
                 ShortCuts.kbAltT,
                 Samolot,
                 Sam );
    SamName := 'SP-TPB'; (* bravo *)
    Samolot;
                     (* teraz alfa *)
    MoveRect( R, 0, (R.bottom-R.top) * 3 DIV 2 );
    WstawButton( hDlg,
                 R,
                 "SPEùNIA WYMAGANIA ICAO",
                 0,
                 ShortCuts.kbAltS,
                 SpelniaP,
                 b );
    MoveRect( R, 0, (R.bottom-R.top) * 3 DIV 2 );
    WstawButton( hDlg,
                 R,
                 "NIE SPEùNIA WYMAGA„ ICAO",
                 0,
                 ShortCuts.kbAltN,
                 NieSpelniaP,
                 b );
    MoveRect( R, 0, (R.bottom-R.top) * 3 DIV 2 );
    WstawButton( hDlg,
                 R,
                 "REZYGNACJA Z RAPORTU",
                 -1,
                 ShortCuts.kbAltF4,
                 AltF4,
                 b );
    (* wypelnianie listy odpowiedzialnych *)
    GetPrivateProfileString( SEKCJA, "Ilosc", "0", s, NAZWA_PLIKU_INI );
    StringToInt( s, Ilosc, ok );
    IF NOT ok OR (Ilosc < 0) THEN
      Ilosc := 0;
    END;
    FOR i := 0 TO Ilosc-1 DO
      sprintf( s, "Odpowiedzialny_%d", i );
      GetPrivateProfileString( SEKCJA, s, "", s, NAZWA_PLIKU_INI );
      IF s[0] # 0C THEN
        DodajDoListy( ListaOdpowiedzialnych, s );
      END;
    END;
    DodInfo( hDlg );
    ok := Go( hDlg );
    IF ok THEN
      Idx2Str( ListaOdpowiedzialnych,
               GetSelection(ListaOdpowiedzialnych),
               Odpowiedzialny );
      PomiarOK := SpelniaWymagania;
      Assign( SamName, SamolotRej );
    END;
    UsunDialog( hDlg );
    RETURN ok;
  END GetInteractiveData;

PROCEDURE Samolot(  );
  BEGIN
    IF (SamName[5] = 'A') THEN
      SamName[5] := 'B';
    ELSE
      SamName[5] := 'A';
    END;
    ChangeButtonText( Sam, SamName );
  END Samolot;

PROCEDURE SpelniaP(  );
  BEGIN
    SpelniaWymagania := TRUE;
    EndDialog( TRUE );
  END SpelniaP;

PROCEDURE NieSpelniaP(  );
  BEGIN
    SpelniaWymagania := FALSE;
    EndDialog( TRUE );
  END NieSpelniaP;

PROCEDURE Dummy( h : HDLG );
  BEGIN

  END Dummy;

END Rap_Util.

