(*.F- *)
(**********************************************************************
|  Title   : Szybki test kanalow pomiarowych dla GS
|  Author  : M.Morawski
|  System  : LOGITECH MODULA-2/86
|  History :
|
|  Copyright (C), CAS LODZ POLAND.
|  TEL: 42' 862 547, 42' 87 80 44 FAX/TEL: 42' 84 48 40
|
**********************************************************************)
(*.F+ *)

IMPLEMENTATION MODULE PI_Qcheck;
(* szybkie sprawdzanie tor¢w pomiarowych dla warto˜ci standardowych *)

  IMPORT
    HiLevGraf, GrafTypes, SYSTEM, MathLib0, StdIO, GrafUtil, Terminal, Timer,
    N_Odb;

  FROM CommonTypes IMPORT
    GlownyOdbiornikT, SigNilVal;

  FROM SpecConv IMPORT
    ToStringProcT, Int100Str, Int10Str, Int2Str;

  CONST
    ILE_POZYCJI = 2;
    TEKST       = 2;
    OCZEK       = 120;
    ODCZ        = OCZEK + 90;
    BLAD        = ODCZ + 90;
    SZER        = BLAD + 90 - ODCZ;
    Y           = 1;

  VAR
    ST : ARRAY [0 .. ILE_POZYCJI - 1] OF RECORD
                                           Tekst   :
                                             ARRAY [0 .. 12] OF CHAR;
                                           Oczek   :
                                             INTEGER; (* wartosc
                                                         oczekiwana/ustawiona
                                                      *)
                                           dgh     :
                                             ARRAY [0 .. 1] OF INTEGER;
                                           convert :
                                             ToStringProcT;
                                         END;

  PROCEDURE Sprawdz;

    PROCEDURE Tlo
              (    r : GrafTypes.RECT );
    VAR
      i : CARDINAL;

    BEGIN
      FOR i := 0 TO 3 DO
        DEC(r.left);
        DEC(r.top);
        INC(r.right);
        INC(r.bottom);
        HiLevGraf.FrameRect(r, GrafTypes.YELLOW);
      END (* for i *);
    END Tlo;

    PROCEDURE WrStr
              (    x,
                   y  : INTEGER;
                   s  : ARRAY OF CHAR;
                   fc,
                   bc : SYSTEM.BYTE   );

    BEGIN
      x := x + R.left;
      y := y * 16 + R.top;
      HiLevGraf.WrStr(s, x, y, fc, bc);
    END WrStr;

    PROCEDURE WrInt
              (    x,
                   y   : INTEGER;
                   w   : INTEGER;
                   fmt : CARDINAL );
    VAR
      s  : ARRAY [0 .. 12] OF CHAR;
      w2 : CARDINAL;
      w1 : INTEGER;

    BEGIN
      IF ODD(y)
      THEN
        col := SYSTEM.BYTE(GrafTypes.BLUE);
      ELSE
        col := SYSTEM.BYTE(GrafTypes.LT_BLUE);
      END (* if ODD *);
      ST[fmt].convert(w, s, 6);
      WrStr(x, y, s, GrafTypes.WHITE, col);
    END WrInt;

    PROCEDURE WrPrc
              (    x,
                   y : INTEGER;
                   r : REAL    );
    VAR
      s  : ARRAY [0 .. 12] OF CHAR;
      t  : INTEGER;

    BEGIN
      IF ODD(y)
      THEN
        col := SYSTEM.BYTE(GrafTypes.BLUE);
      ELSE
        col := SYSTEM.BYTE(GrafTypes.LT_BLUE);
      END (* if ODD *);
      IF ABS(r) > 100.0
      THEN
        s := "??????";
        col := SYSTEM.BYTE(GrafTypes.RED);
      ELSE
        IF ABS(r) > 2.0
        THEN
          col := SYSTEM.BYTE(GrafTypes.RED);
        END (* if ABS *);
        t := MathLib0.entier(r * 10.0);
        StdIO.sprintf(s, "%4y%%  ", t);
      END (* if ABS *);
      s[7] := 0C;
      WrStr(x, y, s, GrafTypes.WHITE, col);
    END WrPrc;
  VAR
    R,
    R1  : GrafTypes.RECT;
    i,
    j   : CARDINAL;
    col : SYSTEM.BYTE;
    ch  : CHAR;
    r   : REAL;
    ok  : BOOLEAN;

  BEGIN (* Sprawdz *)
    N_Odb.IniData();
    N_Odb.Start;
    R.left := 100;
    R.top := 50;
    R.right := 700;
    R.bottom := R.top + 16 * (ILE_POZYCJI + 1);
    Tlo(R);
    R1 := R;
    R1.bottom := R1.top + 15;
    FOR i := 0 TO ILE_POZYCJI DO
      IF i = 0
      THEN
        col := SYSTEM.BYTE(GrafTypes.GREEN);
      ELSIF ODD(i)
      THEN
        col := SYSTEM.BYTE(GrafTypes.BLUE);
      ELSE
        col := SYSTEM.BYTE(GrafTypes.LT_BLUE);
      END (* if i *);
      HiLevGraf.FillRect(R1, col);
      GrafTypes.MoveRect(R1, 0, 16);
    END (* for i *);
    WrStr(TEKST, 0, "Sygnaˆ", GrafTypes.WHITE, GrafTypes.WHITE);
    WrStr(OCZEK, 0, "Oczek.", GrafTypes.WHITE, GrafTypes.WHITE);
    WrStr(ODCZ, 0, "Kanaˆ A", GrafTypes.WHITE, GrafTypes.WHITE);
    WrStr(ODCZ + SZER, 0, "Kanaˆ B", GrafTypes.WHITE, GrafTypes.WHITE);
    WrStr(BLAD, 0, "Bˆ¥d A", GrafTypes.WHITE, GrafTypes.WHITE);
    WrStr(BLAD + SZER, 0, "Bˆ¥d B", GrafTypes.WHITE, GrafTypes.WHITE);
    FOR i := 0 TO ILE_POZYCJI - 1 DO
      WrStr(TEKST, Y + i, ST[i].Tekst, GrafTypes.WHITE, GrafTypes.WHITE);
      WrInt(OCZEK, Y + i, ST[i].Oczek, i);
    END (* for i *);
    LOOP
      GrafUtil.Info("Ustaw generator na ¾¥dane warto˜ci i wci˜nij spacj©");
      Terminal.Read(ch);
      IF ch = 33C
      THEN
        GrafUtil.InfoBeep("U¾ytkownik przerwaˆ szybki test urz¥dzeä", 3, 300);
        RETURN;
      ELSIF ch = ' '
      THEN
        EXIT;
      ELSE
        GrafUtil.InfoBeep("Wci˜nij albo Spacj© albo ESC", 3, 300);
      END (* if ch *);
    END (* loop *);
    GrafUtil.Info("");
    LOOP
      ST[0].dgh[0] := N_Odb.berN[goA];
      ST[0].dgh[1] := N_Odb.berN[goB];
      ST[1].dgh[0] := N_Odb.agc[goA];
      ST[1].dgh[1] := N_Odb.agc[goB];
      FOR i := 0 TO ILE_POZYCJI - 1 DO
        WITH ST[i] DO
          FOR j := 0 TO 1 DO
            WrInt(ODCZ + j * SZER, Y + i, dgh[j], i);
            IF dgh[j] = SigNilVal
            THEN
              WrPrc(BLAD + j * SZER, Y + i, 1.0e100);
            ELSIF Oczek = 0
            THEN
              WrInt(BLAD + j * SZER, Y + i, dgh[j] - Oczek, 0);
            ELSE
              WrPrc(BLAD + j * SZER, Y + i, MathLib0.real(dgh[j] - Oczek) *
                    100.0 / MathLib0.real(Oczek));
            END (* if dgh *);
          END (* for j *);
        END (* with ST *);
      END (* for i *);
      IF Terminal.KeyPressed()
      THEN
        Terminal.Read(ch);   (* zeby sie pozbyl tego znaku z bufora *)
        EXIT;
      END (* if Terminal.KeyPressed *);
      Timer.Wait(Timer.TInOneSecond() DIV 2);
      (* DGHInterface.WaitForNewData( ds );*)
    END (* loop *);
  END Sprawdz;

  PROCEDURE Init();

  BEGIN
    ST[0].Tekst := "ADF";
    ST[1].Tekst := "Siˆa synaˆu G";
    ST[0].Oczek := 0;
    ST[1].Oczek := 800;
    ST[0].convert := Int100Str;
    ST[1].convert := Int10Str;
  END Init;

BEGIN
  Init;
END PI_Qcheck.
