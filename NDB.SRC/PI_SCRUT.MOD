(*.F- *)
(**********************************************************************
|  Title   : Screen Utilities device dependent
|  Author  : M.Postol
|  System  : LOGITECH MODULA-2/86
|  History :
|
|  Copyright (C), CAS LODZ POLAND.
|  TEL: 42' 862 547, 42' 87 80 44 FAX/TEL: 42' 84 48 40
|
**********************************************************************)
(*.F+ *)

IMPLEMENTATION MODULE PI_ScrUtility;

  IMPORT
    N_Slupek;

  FROM HiLevGraf IMPORT
    WrStrXY;

  FROM CommonTypes IMPORT
    GlownyOdbiornikT, SlupekNr;

  FROM Slupek IMPORT
    WykresSlupkowy, Dispose, Nil, GetSlupRect, Update,
    (* TYPE *) PInt, WHandle, BoundArray, Baund;

  FROM GrafTypes IMPORT
    RECT, POINT, BLACK, WHITE;

  FROM HiLevGraf IMPORT
    HDIB;

  FROM ScreenCTypes  IMPORT
    SkalaWpionieOpis, slLDib_rec, slSDib_rec, slPDib_rec, Xdib, Ydib,
    slLReg_rec, slSReg_rec, slPReg_rec, slL_pnt, slS_pnt, slP_pnt;

  VAR
    slupki        : ARRAY SlupekNr OF WHandle;
    slupkiAktywne : SET OF SlupekNr;

  PROCEDURE ShowScreenDIB
            (    Pomiar     : BOOLEAN;
                 Src        : RECT;
                 Dest       : POINT;
             VAR screeenDIB : HDIB );

  BEGIN
      N_Slupek.ShowScreenDIB(Src, Dest, screeenDIB);
  END ShowScreenDIB;

  PROCEDURE ShowCursorDIB
            (    Pomiar     : BOOLEAN;
                 Src        : RECT;
                 Dest       : POINT );

  BEGIN
    N_Slupek.ShowCursorDIB(Src, Dest);
  END ShowCursorDIB;

  PROCEDURE UniversalAB
            (    slupek : SlupekNr;
                 rec    : GlownyOdbiornikT;
                 Zestaw : BOOLEAN;
                 w      : WHandle          ) : INTEGER;
  VAR
    r : RECT;
    s : ARRAY [0 .. 5] OF CHAR;
    k : INTEGER;

  BEGIN (* UniversalAB *)
    IF w # Nil()
    THEN   (* potrzebne na poczatku *)
      GetSlupRect(w, r);

      N_Slupek.UnverslVal(slupek, rec, s, k);

      INC(r.left, 11);
      IF rec = goA
      THEN
        INC(r.bottom, 5)
      ELSE
        INC(r.bottom, 26)
      END (* if *);
      WrStrXY(s, r.left, r.bottom, BLACK, WHITE);
    ELSE
      k := 0;
    END (* if w *);
    RETURN k;
  END UniversalAB;

  PROCEDURE UniversalLAF
            (    w : WHandle ) : INTEGER;

  BEGIN
    RETURN UniversalAB(SlLewy, goA, FALSE, w);
  END UniversalLAF;

  PROCEDURE UniversalSAF
            (    w : WHandle ) : INTEGER;

  BEGIN
    RETURN UniversalAB(SlSrodkowy, goA, FALSE, w);
  END UniversalSAF;

  PROCEDURE UniversalPAF
            (    w : WHandle ) : INTEGER;

  BEGIN
    RETURN UniversalAB(SlPrawy, goA, FALSE, w);
  END UniversalPAF;

  PROCEDURE UniversalLBF
            (    w : WHandle ) : INTEGER;

  BEGIN
    RETURN UniversalAB(SlLewy, goB, FALSE, w);
  END UniversalLBF;

  PROCEDURE UniversalSBF
            (    w : WHandle ) : INTEGER;

  BEGIN
    RETURN UniversalAB(SlSrodkowy, goB, FALSE, w);
  END UniversalSBF;

  PROCEDURE UniversalPBF
            (    w : WHandle ) : INTEGER;

  BEGIN
    RETURN UniversalAB(SlPrawy, goB, FALSE, w);
  END UniversalPBF;

  PROCEDURE UniversalLAB
            (    w : WHandle ) : INTEGER;

  BEGIN
    RETURN UniversalAB(SlLewy, goA, TRUE, w);
  END UniversalLAB;

  PROCEDURE UniversalSAB
            (    w : WHandle ) : INTEGER;

  BEGIN
    RETURN UniversalAB(SlSrodkowy, goA, TRUE, w);
  END UniversalSAB;

  PROCEDURE UniversalPAB
            (    w : WHandle ) : INTEGER;

  BEGIN
    RETURN UniversalAB(SlPrawy, goA, TRUE, w);
  END UniversalPAB;

  PROCEDURE UniversalLBB
            (    w : WHandle ) : INTEGER;

  BEGIN
    RETURN UniversalAB(SlLewy, goB, TRUE, w);
  END UniversalLBB;

  PROCEDURE UniversalSBB
            (    w : WHandle ) : INTEGER;

  BEGIN
    RETURN UniversalAB(SlSrodkowy, goB, TRUE, w);
  END UniversalSBB;

  PROCEDURE UniversalPBB
            (    w : WHandle ) : INTEGER;

  BEGIN
    RETURN UniversalAB(SlPrawy, goB, TRUE, w);
  END UniversalPBB;

  PROCEDURE NowySlup
            (    ZmA      : PInt;
                 ZmB      : PInt;
                 bund     : BoundArray;
                 Tlo      : HDIB;
                 Rect     : RECT; (* polozenie w DIB *)
                 ULCorner : POINT      ) : WHandle;

  BEGIN
    RETURN WykresSlupkowy(ZmA, ZmB, bund[Min], bund[Max], bund[minAlarm], bund[
                          maxAlarm], Tlo, Rect, ULCorner);
  END NowySlup;

  PROCEDURE WykSlup
            (    slupek : SlupekNr;
                 Pomiar : BOOLEAN;
                 dib    : HDIB     );

    VAR
                 p      : POINT;
                 r      : RECT;

    PROCEDURE WykSlupB
              (    slupek : SlupekNr;
                   r      : RECT;
                   p      : POINT;
                   dib    : HDIB     ) : WHandle;

    BEGIN
      RETURN WHandle(NIL);
    END WykSlupB;

    PROCEDURE WykSlupF
              (    slupek : SlupekNr;
                   r      : RECT;
                   p      : POINT;
                   dib    : HDIB     ) : WHandle;

    BEGIN
      RETURN WHandle(NIL);
    END WykSlupF;

  BEGIN
    CASE slupek  OF
        SlLewy :
          r := slLDib_rec;
          p := slL_pnt;
        |
        SlSrodkowy :
          r := slSDib_rec;
          p := slS_pnt;
        |
        SlPrawy :
          r := slPDib_rec;
          p := slP_pnt;
    END;
    IF Pomiar
    THEN
      slupki[slupek] := WykSlupB(slupek, r, p, dib);
    ELSE
      slupki[slupek] := WykSlupF(slupek, r, p, dib);
    END (* if Pomiar *);
    IF slupki[slupek] = WHandle(NIL) THEN
      EXCL(slupkiAktywne, slupek);
    ELSE
      INCL(slupkiAktywne, slupek);
    END;
  END WykSlup;

  PROCEDURE UpdateSlupki;
  VAR
    curr : SlupekNr;

  BEGIN
    FOR curr := MIN(SlupekNr) TO MAX(SlupekNr) DO
      IF curr IN slupkiAktywne
      THEN
        Update(slupki[curr]);
      END (* if curr *);
    END (* for curr *);
  END UpdateSlupki;

  PROCEDURE DisposeSlupki;
  VAR
    curr : SlupekNr;

  BEGIN
    FOR curr := MIN(SlupekNr) TO MAX(SlupekNr) DO
      IF curr IN slupkiAktywne
      THEN
        Dispose(slupki[curr]);
      END (* if curr *);
    END (* for curr *);
  END DisposeSlupki;

  PROCEDURE NapiszSygnaly
            (    Pomiar : BOOLEAN );

  BEGIN
    N_Slupek.NapiszSygnaly;
  END NapiszSygnaly;

  PROCEDURE Init_ScrUtility
            (     Pomiar : BOOLEAN);

  VAR
    sidx: SlupekNr;
  BEGIN
    FOR sidx := MIN(SlupekNr) TO MAX(SlupekNr) DO
      slupki[ sidx ] := WHandle(NIL);
    END;
  END Init_ScrUtility;

  PROCEDURE IniSkale
              (VAR skalaWpionie : SkalaWpionieOpis;
                   Zakres : BOOLEAN );

    BEGIN
      N_Slupek.IniSkale(skalaWpionie);
    END IniSkale;

  PROCEDURE GetRegionWykG
            (     Zakres : BOOLEAN;
              VAR rec    : RECT    ) : BOOLEAN;
  BEGIN
    WITH rec  DO
      left := 228 + Xdib;
      top := 96 + Ydib;
      right := 314 + Xdib;
      bottom := 137 + Ydib;
    END;
    RETURN TRUE;
  END GetRegionWykG;

  PROCEDURE GetRegionWyk1
            (     Zakres : BOOLEAN;
              VAR rec    : RECT    ) : BOOLEAN;
  BEGIN
    WITH rec  DO
      top := 600 - 160 + 15;
      bottom := rec.top + 65;
      left := 235;
      right := 396;
    END;
    RETURN TRUE;
  END GetRegionWyk1;

  PROCEDURE GetRegionWyk2
            (     Zakres : BOOLEAN;
              VAR rec    : RECT    ) : BOOLEAN;
  BEGIN
    RETURN FALSE;
  END GetRegionWyk2;

  PROCEDURE GetRegionWyk3
            (     Zakres : BOOLEAN;
              VAR rec    : RECT    ) : BOOLEAN;
  BEGIN
    RETURN FALSE;
  END GetRegionWyk3;

END PI_ScrUtility.
