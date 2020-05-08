IMPLEMENTATION MODULE MsgBox;


FROM Strings IMPORT
  Length, Assign;
FROM Dialog IMPORT
  TworzDialog, WstawButton, Go, UsunDialog, HDLG, EndDialog;
FROM Buttons IMPORT
  Button;
FROM GrafTypes IMPORT
  MoveRect, RECT, WHITE;
FROM HiLevGraf IMPORT
  Wr2fStrXY;
FROM ShortCuts IMPORT
  kbAltN, kbAltT;

CONST
  ILOSC_LINI   = 3;
  ILOSC_ZNAKOW = 40;


PROCEDURE Info( Text : ARRAY OF CHAR ) : BOOLEAN; (* T/N *)
  VAR
    s : ARRAY[0..1] OF CARDINAL;
    t : ARRAY[0..1] OF But_Napis;
  BEGIN
    s[0] := kbAltT;
    s[1] := kbAltN;
    t[0] := "Tak";
    t[1] := "Nie";
    RETURN AdvInfo( Text, 2, t, s, 1 ) = 0;
  END Info;

PROCEDURE AdvInfo(     Text   : ARRAY OF CHAR;
                       IleNap : CARDINAL;
                   VAR Nap    : ARRAY OF But_Napis;
                   VAR Sh     : ARRAY OF CARDINAL;
                       Esc    : CARDINAL ) : CARDINAL;
  VAR
    LinieTekstu : ARRAY [0..ILOSC_LINI-1] OF ARRAY [0..ILOSC_ZNAKOW] OF CHAR;
    IleLini     : INTEGER;
    MaxDlug     : INTEGER;
    i, j, l     : INTEGER;
    R1, R2      : RECT;
    b           : Button;
    Szer        : INTEGER;
  BEGIN
    Szer := 1;
    FOR i := 0 TO IleNap-1 DO
      j := Length( Nap[i] );
      IF j > Szer THEN
        Szer := j;
      END;
    END;
    Szer := (Szer+2)*8;
    (* najpierw trzeba podzielic tekst na linie *)
    l := Length( Text );
    IleLini := 1;
    FOR i := 0 TO ILOSC_LINI-1 DO
      LinieTekstu[i][0] := 0C;
    END;
    IF (*l <= ILOSC_ZNAKOW*) TRUE THEN
      Assign( Text, LinieTekstu[0] );
    ELSE
    END;
    MaxDlug := Length( LinieTekstu[0] );
    FOR i := 1 TO IleLini-1 DO
      j := Length( LinieTekstu[i] );
      IF j > MaxDlug THEN
        MaxDlug := j;
      END;
    END;
    i := 16*MaxDlug + 20;
    j := 32*IleLini + 30 + 20;
    R1.left   := 400 - i DIV 2;
    R1.right  := 400 + i DIV 2;
    R1.top    := 300 - j DIV 2;
    R1.bottom := 300 + j DIV 2;
    hDlg := TworzDialog( R1, "", TRUE );
    R2.right := 400 - (VAL(INTEGER, IleNap) DIV 2) *3 - VAL(INTEGER, IleNap)*Szer DIV 2;
    R2.left  := R2.right - Szer;
    R2.top   := 32*IleLini+20;
    R2.bottom:= R2.top+20;
    FOR i := 0 TO IleNap-1 DO
      WstawButton( hDlg, R2, Nap[i], 0, Sh[i], P_A[i], b );
      MoveRect( R2, Szer+6, 0 );
    END;
    FOR i := 0 TO IleLini-1 DO
      Wr2fStrXY( LinieTekstu[i], R1.left+10, R1.top+10+32*i, WHITE, WHITE );
    END;
    IF NOT Go( hDlg ) THEN
      ret := Esc;
    END;
    UsunDialog( hDlg );
    RETURN ret;
  END AdvInfo;

  PROCEDURE P0(  );
    BEGIN
      ret := 0;
      EndDialog( TRUE );
    END P0;

  PROCEDURE P1(  );
    BEGIN
      ret := 1;
      EndDialog( TRUE );
    END P1;

  PROCEDURE P2(  );
    BEGIN
      ret := 2;
      EndDialog( TRUE );
    END P2;

  PROCEDURE P3(  );
    BEGIN
      ret := 3;
      EndDialog( TRUE );
    END P3;

(*
  PROCEDURE GoP(  );
    BEGIN
    END GoP;
*)

VAR
  hDlg        : HDLG;
  ret         : CARDINAL;
  P_A         : ARRAY[0..3] OF PROC;

  PROCEDURE Init(  );
    BEGIN
      P_A[0] := P0;
      P_A[1] := P1;
      P_A[2] := P2;
      P_A[3] := P3;
    END Init;

BEGIN
  Init;
END MsgBox.

