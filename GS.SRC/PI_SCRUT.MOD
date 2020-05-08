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
    L_Slupek;

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
    SkalaWpionieOpis, slLDib_rec, slSDib_rec, slPDib_rec,
    slL_pnt, slS_pnt, slP_pnt;

  FROM G_results IMPORT
    anRes;

  TYPE
    slupkiAktywneT = SET OF SlupekNr;

  VAR
    slupki        : ARRAY SlupekNr OF WHandle;
    slupkiAktywne : slupkiAktywneT;

  PROCEDURE ShowScreenDIB
            (    Pomiar     : BOOLEAN;
                 Src        : RECT; 
                 Dest       : POINT;
             VAR screeenDIB : HDIB );

  BEGIN
    L_Slupek.ShowScreenDIB(Src, Dest, screeenDIB);
  END ShowScreenDIB;

  PROCEDURE ShowCursorDIB
            (    Pomiar     : BOOLEAN;
                 Src        : RECT; 
                 Dest       : POINT );

  BEGIN
    L_Slupek.ShowCursorDIB(Src, Dest);
  END ShowCursorDIB;

 PROCEDURE UniversalAB
            (    slupek : SlupekNr;
                 rec    : GlownyOdbiornikT;
                 Pomiar : BOOLEAN;
                 w      : WHandle          ) : INTEGER;
  VAR
    r : RECT;
    s : ARRAY [0 .. 5] OF CHAR;
    k : INTEGER;

  BEGIN (* UniversalAB *)
    IF ( w # Nil() ) AND (slupek IN slupkiAktywne)
    THEN   (* potrzebne na poczatku *)
      GetSlupRect(w, r);
      L_Slupek.UnverslVal(slupek, rec, s, k);
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

  PROCEDURE UniversalSAF
            (    w : WHandle ) : INTEGER;

  BEGIN
    RETURN UniversalAB(SlSrodkowy, goA, FALSE, w);
  END UniversalSAF;

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

  PROCEDURE UniversalLAB
            (    w : WHandle ) : INTEGER;

  BEGIN
    RETURN UniversalAB(SlLewy, goA, TRUE, w);
  END UniversalLAB;

  PROCEDURE UniversalPAB
            (    w : WHandle ) : INTEGER;

  BEGIN
    RETURN UniversalAB(SlPrawy, goA, TRUE, w);
  END UniversalPAB;

  PROCEDURE UniversalSBB
            (    w : WHandle ) : INTEGER;

  BEGIN
    RETURN UniversalAB(SlSrodkowy, goB, TRUE, w);
  END UniversalSBB;

  (*.F- *)
  PROCEDURE NowySlup
            (    ZmA      : PInt;
                 ZmB      : PInt;
                 bund     : BoundArray;
                 Tlo      : HDIB;
                 Rect     : RECT; (* polozenie w DIB *)
                 ULCorner : POINT      ) : WHandle;

  BEGIN
    RETURN WykresSlupkowy(ZmA, ZmB, bund[Min], bund[Max], bund[minAlarm], 
                          bund[maxAlarm], Tlo, Rect, ULCorner);
  END NowySlup;
  (*.F+ *)

  PROCEDURE WykSlup
            (    slupek : SlupekNr;
                 Pomiar : BOOLEAN;
                 dib    : HDIB     );

    VAR
      p      : POINT;
      r      : RECT;
    
    PROCEDURE WykSlupF
              (    slupek : SlupekNr;
                   r      : RECT;
                   p      : POINT;
                   dib    : HDIB     ) : WHandle;

    BEGIN
      CASE slupek OF
        SlLewy :
          RETURN WHandle(NIL);
        |
        SlSrodkowy :
          INCL(slupkiAktywne, slupek);
          RETURN NowySlup(UniversalSAF, UniversalSBF, 
                            L_Slupek.parSlupkow[SlSrodkowy], dib, r, p);
        |
        SlPrawy :
          RETURN WHandle(NIL);
      END (* case slupek *);
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
    slupki[slupek] := WykSlupF(slupek, r, p, dib);
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
    L_Slupek.NapiszSygnaly;
  END NapiszSygnaly;
  
  PROCEDURE Init_ScrUtility
            (     Pomiar : BOOLEAN);
  VAR
    sidx: SlupekNr;
    
  BEGIN
    FOR sidx := MIN(SlupekNr) TO MAX(SlupekNr) DO
      slupki[ sidx ] := WHandle(NIL);
    END;
    slupkiAktywne := slupkiAktywneT{};
  END Init_ScrUtility;
  
  PROCEDURE IniSkale
            (VAR skalaWpionie : SkalaWpionieOpis;
                 Pomiar : BOOLEAN );
  BEGIN
    L_Slupek.IniSkale(skalaWpionie);
  END IniSkale;
  
  PROCEDURE GetRegionWykG
            (     Pomiar : BOOLEAN;
              VAR rec    : RECT    ) : BOOLEAN;
  BEGIN
      RETURN L_Slupek.GetRegionWykG(rec);
  END GetRegionWykG;
  
  PROCEDURE GetRegionWyk1
            (     Pomiar : BOOLEAN;
              VAR rec    : RECT    ) : BOOLEAN;
  BEGIN
    RETURN L_Slupek.GetRegionWyk1(rec);
  END GetRegionWyk1;

  PROCEDURE GetRegionWyk2
            (     Pomiar : BOOLEAN;
              VAR rec    : RECT    ) : BOOLEAN;
  BEGIN
    RETURN L_Slupek.GetRegionWyk2(rec);
  END GetRegionWyk2;

  PROCEDURE GetRegionWyk3
            (     Pomiar : BOOLEAN;
              VAR rec    : RECT    ) : BOOLEAN;
  BEGIN
    RETURN L_Slupek.GetRegionWyk3(rec);
  END GetRegionWyk3;

BEGIN
END PI_ScrUtility.
