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
    L_Slupek, D_Slupek;

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
    slLReg_rec, slSReg_rec, slPReg_rec, slL_pnt, slS_pnt, slP_pnt;
    
  FROM L_CommonTypes IMPORT
    ProceduraT;

  FROM L_results IMPORT
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
    IF Pomiar
    THEN
      D_Slupek.ShowScreenDIB(Src, Dest, screeenDIB);
    ELSE
      L_Slupek.ShowScreenDIB(Src, Dest, screeenDIB);
    END (* if Strona *);
  END ShowScreenDIB;

  PROCEDURE ShowCursorDIB
            (    Pomiar     : BOOLEAN;
                 Src        : RECT; 
                 Dest       : POINT );

  BEGIN
    IF Pomiar
    THEN
      D_Slupek.ShowCursorDIB(Src, Dest);
    ELSE
      L_Slupek.ShowCursorDIB(Src, Dest);
    END (* if Strona *);
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
    IF ( w # Nil() ) AND (slupek IN slupkiAktywne)
    THEN   (* potrzebne na poczatku *)
      GetSlupRect(w, r);
      IF Zestaw = FALSE
      THEN   (* zerowa *)
        L_Slupek.UnverslVal(slupek, rec, s, k);
      ELSE
        D_Slupek.UnverslVal(slupek, rec, s, k);
      END (* if Zestaw *);
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
    
    PROCEDURE WykSlupB
              (    slupek : SlupekNr;
                   r      : RECT;
                   p      : POINT;
                   dib    : HDIB     ) : WHandle;

    BEGIN
      INCL(slupkiAktywne, slupek);
      CASE slupek OF
        SlLewy :
          RETURN NowySlup(UniversalLAB, UniversalLBB, 
                          D_Slupek.parSlupkow[SlLewy], dib, r, p);
        |
        SlSrodkowy :
          RETURN NowySlup(UniversalSAB, UniversalSBB, D_Slupek.parSlupkow[
                          SlSrodkowy], dib, r, p);
        |
        SlPrawy :
          RETURN NowySlup(UniversalPAB, UniversalPBB, D_Slupek.parSlupkow[
                          SlPrawy], dib, r, p);
      END (* case slupek *);
    END WykSlupB;

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
          IF anRes.procedure = pMarker THEN
            RETURN WHandle(NIL);
          ELSE
            INCL(slupkiAktywne, slupek);
            RETURN NowySlup(UniversalSAF, UniversalSBF, 
                            L_Slupek.parSlupkow[SlSrodkowy], dib, r, p);
          END;
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
    IF Pomiar
    THEN
      slupki[slupek] := WykSlupB(slupek, r, p, dib);
    ELSE
      slupki[slupek] := WykSlupF(slupek, r, p, dib);
    END (* if Pomiar *);
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
    IF Pomiar
    THEN   (* Vorowy *)
      D_Slupek.NapiszSygnaly;
    ELSE   (* zestaw DME *)
      L_Slupek.NapiszSygnaly;
    END (* if Pomiar *);
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
                 Zakres : BOOLEAN );
  BEGIN
    IF Zakres  THEN
      D_Slupek.IniSkale(skalaWpionie);
    ELSE
      L_Slupek.IniSkale(skalaWpionie);
    END;
  END IniSkale;
  
  PROCEDURE GetRegionWykG
            (     Zakres : BOOLEAN;
              VAR rec    : RECT    ) : BOOLEAN;
  BEGIN
    IF Zakres  THEN
      rec.top := 600 - 160 + 15;
      rec.bottom := rec.top + 65;
      rec.left := 235;
      rec.right := 396;
      RETURN TRUE;
    ELSE
      RETURN L_Slupek.GetRegionWykG(rec);
    END;
  END GetRegionWykG;
  
  PROCEDURE GetRegionWyk1
            (     Zakres : BOOLEAN;
              VAR rec    : RECT    ) : BOOLEAN;
  BEGIN
    IF Zakres  THEN
      rec := slLReg_rec;
      RETURN FALSE;
    ELSE
      RETURN L_Slupek.GetRegionWyk1(rec);
    END;
  END GetRegionWyk1;

  PROCEDURE GetRegionWyk2
            (     Zakres : BOOLEAN;
              VAR rec    : RECT    ) : BOOLEAN;
  BEGIN
    IF Zakres  THEN
      rec := slSReg_rec;
      RETURN TRUE;
    ELSE
      RETURN L_Slupek.GetRegionWyk2(rec);
    END;
  END GetRegionWyk2;

  PROCEDURE GetRegionWyk3
            (     Zakres : BOOLEAN;
              VAR rec    : RECT    ) : BOOLEAN;
  BEGIN
    IF Zakres  THEN
      rec := slPReg_rec;
      RETURN TRUE;
    ELSE
      RETURN L_Slupek.GetRegionWyk3(rec);
    END;
  END GetRegionWyk3;

BEGIN
END PI_ScrUtility.
