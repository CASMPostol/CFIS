(*.F- *)
(**********************************************************************
|  Title   : Screen Utilities device dependent
|  Author  : M.Postol
|  System  : LOGITECH MODULA-2/86
|  History :
|    Rel. 3.0 MPostol
|      Uruchomilem wykres dla pomiaru bledu DME
|
|  Copyright (C), CAS LODZ POLAND.
|  TEL: 42' 686 25 47
|  mailto: techsupp@cas.com.pl
|  http: www.cas.com.pl
|
**********************************************************************)
(*.F+ *)
IMPLEMENTATION MODULE PI_ScrUtility;

  IMPORT
    V_Slupek, D_Slupek;

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
    (* TYPE *) SkalaWpionieOpis, 
    (* VAR *) slLDib_rec, slSDib_rec, slPDib_rec, slLReg_rec, slSReg_rec, 
              slPReg_rec, slL_pnt, slS_pnt, slP_pnt, 
    (* CONST *) Xdib, Ydib;
    
  VAR
    slupki        : ARRAY SlupekNr OF WHandle;
    slupkiAktywne : SET OF SlupekNr;

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
      V_Slupek.ShowScreenDIB(Src, Dest, screeenDIB);
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
      V_Slupek.ShowCursorDIB(Src, Dest);
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
    IF w # Nil()
    THEN   (* potrzebne na poczatku *)
      GetSlupRect(w, r);
      IF Zestaw = FALSE
      THEN   (* zerowa *)
        V_Slupek.UnverslVal(slupek, rec, s, k);
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
      CASE slupek OF
        SlLewy :
          RETURN NowySlup(UniversalLAB, UniversalLBB, D_Slupek.parSlupkow[
                          SlLewy], dib, r, p);
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
          RETURN NowySlup(UniversalLAF, UniversalLBF, V_Slupek.parSlupkow[
                          SlLewy], dib, r, p);
        |
        SlSrodkowy :
          RETURN NowySlup(UniversalSAF, UniversalSBF, V_Slupek.parSlupkow[
                          SlSrodkowy], dib, r, p);
        |
        SlPrawy :
          RETURN NowySlup(UniversalPAF, UniversalPBF, V_Slupek.parSlupkow[
                          SlPrawy], dib, r, p);
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
    INCL(slupkiAktywne, slupek);
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
      V_Slupek.NapiszSygnaly;
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
  END Init_ScrUtility;
  
    PROCEDURE IniSkale
              (VAR skalaWpionie : SkalaWpionieOpis;
                   Zakres : BOOLEAN );

    BEGIN
    IF Zakres  THEN
      D_Slupek.IniSkale(skalaWpionie);
    ELSE
      V_Slupek.IniSkale(skalaWpionie);
    END;
  END IniSkale;
  
  PROCEDURE GetRegionWykG
            (     Zakres : BOOLEAN;
              VAR rec    : RECT    ) : BOOLEAN;
  BEGIN
      rec.top := 600 - 160 + 15;
      rec.bottom := rec.top + 65;
      rec.left := 235;
      rec.right := 396;
      RETURN TRUE;
  END GetRegionWykG;
  
  PROCEDURE GetRegionWyk1
            (     Pomiar : BOOLEAN;
              VAR rec    : RECT    ) : BOOLEAN;
  BEGIN
    rec := slLReg_rec;
    RETURN TRUE;
  END GetRegionWyk1;

  PROCEDURE GetRegionWyk2
            (     Pomiar : BOOLEAN;
              VAR rec    : RECT    ) : BOOLEAN;
  BEGIN
    IF Pomiar  THEN
      rec := slSReg_rec;
    ELSE
      WITH rec  DO
        left := 228 + Xdib;
        top := 96 + Ydib;
        right := 314 + Xdib;
        bottom := 137 + Ydib;
      END;
    END;
    RETURN TRUE;
  END GetRegionWyk2;

  PROCEDURE GetRegionWyk3
            (     Pomiar : BOOLEAN;
              VAR rec    : RECT    ) : BOOLEAN;
  BEGIN
      rec := slPReg_rec;
      RETURN TRUE;
  END GetRegionWyk3;

END PI_ScrUtility.
