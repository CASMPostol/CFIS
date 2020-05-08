(*.F- *)
(**********************************************************************
|  Title   :  
|  Author  : M.Morawski
|  System  : LOGITECH MODULA-2/86 
|  History :
|    10-05-97: M.Postol
|      nie dzilal REZYGNUJ na altR
|
|  Copyright (C), CAS LODZ POLAND.
|  TEL: 42' 862 547, 42' 87 80 44 FAX/TEL: 42' 84 48 40
|
**********************************************************************)
(*.F+ *)
IMPLEMENTATION MODULE ZoomInterface;


FROM MANAGER IMPORT
  WAITS, SEND, InitS, SIGNAL, Assert;
FROM Zoom IMPORT
  Init, Done, Assign, Wykres, Run, ZmienP;
FROM GList IMPORT
  HCONTENT, HLIST, DodajDoListy, GetSelection, GetContents, SetContents,
  SetSelection, SkasujWszystko;
FROM GrafTypes IMPORT
  RECT, AssignRect, MoveRect;
FROM GrafUtil IMPORT
  InfoBeep, Info;
FROM Buttons IMPORT
  Button, ChangeButton, EnableButton;
FROM Dialog IMPORT
  AltF4, TworzDialog, UsunDialog, Go, WstawListe, WstawButton, HDLG,
  EndDialog;
FROM CommonTypes IMPORT
  GlownyOdbiornikT, OdnDlaPomBleduT;
FROM Files IMPORT
  CommSig, GetCommSigFName, GetALfaRefFName, GetDisRefFName;
FROM ShortCuts IMPORT
  kbAltP, kbAltR, kbAltD;
FROM RTSMain IMPORT
  Terminate, Status;
FROM PI_ZoomSpecific IMPORT
  OpisWykresu, Opisy, InitNames, ZmiennaNiezalezna, Sciezka, MAX_NR_WYKR,
  NazwaOdniesienia;
IMPORT
  Strings;


VAR
  Koniec        : SIGNAL;
  FirstTime     : BOOLEAN;
  Zawartosc     : HCONTENT;
  CoRobic       : ARRAY BOOLEAN, Wykres OF INTEGER;
  Lista         : ARRAY Wykres OF HLIST;
  OstatniStan   : BOOLEAN;
  OdnB          : Button;
  MozeBycGlowny : BOOLEAN;
  MozeBycDme    : BOOLEAN;

  PROCEDURE Show( g : BOOLEAN; d : BOOLEAN );
    VAR
      w : Wykres;
      b : BOOLEAN;
    BEGIN
      Assert( g OR d ); (* cos u diabla trzeba wyswietlic! *)
      MozeBycGlowny := g;
      MozeBycDme := d;
      OstatniStan := FALSE;
      ZmienP := RespProc;
      Init;
      OstatniStan := NOT g;
      InitNames( OstatniStan );
      IF NOT ZmiennaNiezalezna( OstatniStan ) THEN
        InfoBeep( "Nie ma danych dla tego pomiaru!!!", 5, 300 );
        RETURN;
      END;
      FOR b := FALSE TO TRUE DO
        FOR w := MIN( Wykres ) TO MAX( Wykres ) DO
          CoRobic[ b ][ w ] := 0;
        END;
      END;
      Run;
      WAITS( Koniec );
    END Show;

  PROCEDURE Load(  );

    PROCEDURE Niepusty( VAR o : OpisWykresu ) : BOOLEAN;
      VAR
        v : CARDINAL;
      BEGIN
        FOR v := 0 TO MAX_NR_WYKR-1 DO
          IF o.NazwaPliku[v][0] # 0C THEN
            RETURN TRUE;
          END;
        END;
        RETURN FALSE;
      END Niepusty;

    VAR
      w : Wykres;
      i : CARDINAL;
    BEGIN
      FOR w := MIN( Wykres ) TO MAX( Wykres ) DO
        SkasujWszystko( Lista[w] );
      END;
      FirstTime := TRUE;
      FOR w := MIN( Wykres ) TO MAX( Wykres ) DO
        IF FirstTime THEN
          FOR i := 0 TO HIGH( Opisy ) DO
            IF Niepusty( Opisy[i] ) THEN
              DodajDoListy( Lista[w], Opisy[i].OpisTekstowy );
            END;
          END;
          Zawartosc := GetContents( Lista[w] );
          FirstTime := FALSE;
        ELSE
          SetContents( Lista[w], Zawartosc );
        END;
        SetSelection( Lista[w], CoRobic[OstatniStan][w] );
      END;
    END Load;

  PROCEDURE RespProc(  );
    VAR
      R : RECT;
      hDlg : HDLG;
      w : Wykres;
      b : Button;
      i : INTEGER;
      FName   : ARRAY[0..99] OF CHAR;
    BEGIN
      AssignRect( R, 20, 40, 630, 500 );
      hDlg := TworzDialog( R, "zoom-dsc.dib", FALSE );

      AssignRect( R, 20, 20, 160, 300 );
      FOR w := MIN( Wykres ) TO MAX( Wykres ) DO
        Lista[w] := WstawListe( hDlg, R, FALSE );
        MoveRect( R, R.right-R.left+5, 0 );
      END;
      AssignRect( R, 20, 320, 190, 360 );
      WstawButton( hDlg, R, "POKAZ", 0, kbAltP, Pokaz, b );
      MoveRect( R, R.right-R.left+5, 0 );
      WstawButton( hDlg, R, "REZYGNUJ", 0, kbAltR, Rezygnuj, b );
      MoveRect( R, R.right-R.left+5, 0 );
      IF MozeBycGlowny & MozeBycDme THEN
        NazwaOdniesienia( OstatniStan, FName );
        WstawButton( hDlg, R, FName, 0, kbAltD, ZmienOdniesienie, OdnB );
      END;

      Load;
      IF Go( hDlg ) THEN
        FOR w := MIN( Wykres ) TO MAX( Wykres ) DO
          CoRobic[OstatniStan][w] := GetSelection( Lista[w] );
        END;
        UsunDialog( hDlg );
        FOR w := MIN( Wykres ) TO MAX( Wykres ) DO
          IF CoRobic[OstatniStan][w] >= 0 THEN
            WITH Opisy[CoRobic[OstatniStan][w]] DO
              FOR i := 0 TO MAX_NR_WYKR-1 DO
                IF NazwaPliku[i][0] # 0C THEN
                  Strings.Assign( Sciezka, FName);
                  Strings.Insert( NazwaPliku[i], FName, 0FFFH );
                  Assign( w, i, FName, OpisTekstowy, FLOAT(Podzielnik), Logarytmiczny );
                END;
              END;
            END;
          END;
        END;
      ELSE
        UsunDialog( hDlg );
        SEND( Koniec );
      END;
    END RespProc;

    PROCEDURE ZmienOdniesienie(  );
      VAR
        Name : ARRAY[0..10] OF CHAR;
      BEGIN
        EnableButton( OdnB, FALSE );
        IF NOT ZmiennaNiezalezna( NOT OstatniStan ) THEN
          InfoBeep( "Nie ma danych dla tego pomiaru!!!",5, 300 );
          EnableButton( OdnB, TRUE );
          RETURN;
        END;
        OstatniStan := NOT OstatniStan;
        InitNames( OstatniStan );
        NazwaOdniesienia( OstatniStan, Name );
        ChangeButton( OdnB, Name, 0 );
        Load;
        EnableButton( OdnB, TRUE );
      END ZmienOdniesienie;

    PROCEDURE Pokaz(  );
      BEGIN
        EndDialog( TRUE );
      END Pokaz;

    PROCEDURE Rezygnuj(  );
      BEGIN
        Done;
        AltF4;
      END Rezygnuj;


BEGIN
  ZmienP := RespProc;
  InitS( Koniec );
END ZoomInterface.

