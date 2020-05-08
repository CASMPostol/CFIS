(*.F- *)
(**********************************************************************
|  Title   : pomocnicze procedury do pisania po ekranie pomiarowym
|  Author  : M.Postol
|  System  : LOGITECH MODULA-2/86
|  History :
|    04-12-96:M.Postol
|      przerysowywanie ekranu powodowalo przerwe w wykresie
|    09-12-96: M.Postol
|      Kursor nie moze byc na pozycji 0.
|    17-02-97: M.Postol
|      zmiana kolorow wyswietlania przy kursorze
|    22-02-97: M.Postol
|      wprowadzilem zaokraglenie w PokazWgKursora
|    13-03-97: M.Postol
|      w naglowku dla TEO rysowal dwa razy ø
|    21-03-97: M.Postol
|      zmiany wynikajace ze zmainy definicji modulu Wykres.
|    04-05-97: M.Postol
|      NapiszGPS - dane dla GPS_GDOP, GPS_SAT, GPS_PREC byly wypisywane bez
|      wzgledu na to czy przychodzily z GPS'a
|    11-05-97: M.Postol
|      wywalilem odwolanie do Polozenie
|      w NapiszGPS przesuniecie kata GPS bylo tylko dla pomiaru zasadniczego, a
|      OdnDlaPomBledu wziolem z CommonData, a bylo ze ScannerI
|      DrawEvent eliminuje znaczniki z atSample = NIL, poniewaz w prog. arch
|      mogly pojawic sie znaczniki strefy z nie ustalonym polozeniem
|    05-31-97 02:10pm : MM
|      Przystosowanie do nowej definicji "Wykres"
|    21-01-98: T.Rozmarynowski
|      zmiana w wyswietlaniu danych GPS
|      zmienilem kolejnosc sprawdzania bitow w slowie stanu teo
|      wprowadzony napis wyswietlania DGPS lub GPS na podstawie GPS_DIFFMODE
|      wprowadzony napis wyswietlania NDIFF lub DIFF na podstawie TEO_DGPSpoprawki
|    Rel 3.0: M.Postol
|      Modyfikacja modulu do zmian zwiazanych z wprowadzeniem DGPS
|      wywalilem wykorzystanie GPS_DIFFMODE i zastapilem slowem stanu
|
|  Copyright (C), CAS LODZ POLAND.
|  TEL: 42' 862 547, 42' 87 80 44 FAX/TEL: 42' 84 48 40
|
**********************************************************************)
(*.F+ *)

IMPLEMENTATION MODULE Screen;

  FROM SYSTEM IMPORT
    WORD;

  IMPORT
    DataCollect, ScannerI, SpecConv, Mapa, SYSTEM, NumberConversion,
    MMMouse, ShortCuts, HiLevGraf, GrafTypes, Wykres, CommonTypes, Graphics;

  FROM Buttons IMPORT
    Button, CreateButton, DisposeButton, EnableButton;

  FROM CommonTypes IMPORT
    (* TYPE *) OdnDlaPomBleduT, GlownyOdbiornikT, NilValI, SlupekNr, 
    DisNilVal;

  FROM ScannerI IMPORT
    (* VAR *) TEO_A, TEO_E, GPS_A, GPS_R, GPS_OK, TEO_OK, 
    (* TYPE *) StanyGPS, TeoState;

  FROM SYSTEM IMPORT
    BYTE, ADR;

  FROM MathLib0 IMPORT
    real, entier;

  FROM StdIO IMPORT
    sprintf;

  FROM DataCollect IMPORT
    (* TYPE *) CardTab23,
    (* PROCEDURE *) GetNextAMark, ResetMarks_A, GetNextDMark, ResetMarks_D;

  FROM EventsMng IMPORT
    Events, EventKind;

  FROM HiLevGraf IMPORT
    FillRect, HDIB, WrStrXY;

  FROM Graphics IMPORT
    MaxVer, MaxHor;

  FROM GrafTypes IMPORT
    RECT, BLACK, MAGENTA, GREEN, LT_GREEN, YELLOW, RED, BROWN, LT_RED, WHITE,
    MoveRect, POINT, GREY;

  FROM Wykres IMPORT
    Draw;

  FROM MMMouse IMPORT
    Region, RegisterRegion, UnregisterRegion, Event, EventSet, EventHandler,
    GetRegionRect;

  FROM PI_ScrUtility IMPORT
    (* PROCEDURE *) ShowScreenDIB, WykSlup, DisposeSlupki, UpdateSlupki,
                    NapiszSygnaly, Init_ScrUtility, IniSkale, GetRegionWykG,
                    GetRegionWyk1, GetRegionWyk2, GetRegionWyk3, ShowCursorDIB;

  FROM SYSTEM IMPORT
    ADDRESS;

  FROM ScreenCTypes IMPORT
    RodzWykr, SkalaWpionieOpis;

  FROM CommonData IMPORT
    OdnDlaPomBledu;

  CONST
    spac5             = '     ';
    szerWykresu       = 200;
    screenDIBHeight   = 160;
    DolnyWykresTl_Col = BROWN;
    GornyWykresTl_Col = GREY;
    WykresNapisy_Col  = WHITE;
    WykresKanA_Col    = LT_GREEN;
    WykresKanB_Col    = LT_RED;
  TYPE
    ZbiorWykr   =
      SET OF RodzWykr;
    DataPointer =
      POINTER TO CardTab23;

  VAR
    VAL1              : DataPointer;
    VAL2              : DataPointer;
    VAL3              : DataPointer;
    VAL4              : DataPointer;
    Zestaw            : BOOLEAN;
    aktPromien        : WORD;
    aktPromienOdAnt   : REAL;
    pomPromieniowy    : BOOLEAN;
    aktFormat360      : BOOLEAN;
    devDistR          : REAL;
        (* dane, ostatnie, wprowadzone *)
    by23              : CARDINAL;
    LastDTidx,
    ThisDTidx         : CARDINAL;
    samplediv         : CARDINAL;
    NextRedraw        : BOOLEAN;
    LastEventIDX,
    KrokOpisuOsi      : CARDINAL;
    Predrawmarksreq   : RredrawMarksReqPT;
    Predrawreq        : RedrawReqPT;
    currConsoleEv     : PROC;
    RegionWykG        : Region;
    RegionWykGCreated : BOOLEAN;
    RegionWyk1        : Region;
    RegionWyk1Created : BOOLEAN;
    RegionWyk2        : Region;
    RegionWyk2Created : BOOLEAN;
    RegionWyk3        : Region;
    RegionWyk3Created : BOOLEAN;
    RegionWykresow    : Region;
    B_CURSOR          : Button;
    B_LEFT            : Button;
    B_RIGHT           : Button;
    B_UP              : Button;
    B_DOWN            : Button;
    screenDIB         : HDIB;

  PROCEDURE RectWykresy
            ( VAR r : RECT;
                  i : INTEGER );
    (* 1=gorny;2=dolny;0=oba *)

  BEGIN
    r.left := 0;
    r.right := MaxHor();
    r.top := 40;
    r.bottom := r.top + szerWykresu;
    IF i = 2
    THEN
      MoveRect(r, 0, szerWykresu);
    ELSIF i = 1
    THEN
      ;
    ELSE
      r.bottom := r.bottom + szerWykresu;
    END (* if i *);
  END RectWykresy;

  MODULE Dialog [ 0 ];

    IMPORT
      (* TYPE *) RodzWykr, ZbiorWykr, ThisDTidx, SkalaWpionieOpis, DataPointer,
      (* MODULE*) SpecConv,
      (* CONST *) spac5, DolnyWykresTl_Col, GornyWykresTl_Col,
                  WykresNapisy_Col,
      (* PROCEDURE *) RectWykresy, Predrawreq, entier, IniSkale, ShowCursorDIB,
      (* VAR *) aktPromien, by23, NextRedraw, Zestaw, VAL1, VAL2, VAL3, VAL4,
                pomPromieniowy, samplediv, RegionWykG,
                RegionWyk1, RegionWyk2, RegionWyk3, RegionWykresow,
                aktFormat360;

    FROM CommonTypes IMPORT
      GlownyOdbiornikT, NilValI;

    FROM GrafTypes IMPORT
      RECT, GREEN, YELLOW, RED, WHITE, BROWN, GREY, MoveRect, POINT, BLUE;

    FROM Wykres IMPORT
      Opis, OpisLog;

    FROM ScannerI IMPORT
      RefDis;

    FROM Mapa IMPORT
      PokazKatyLotu;

    FROM DataCollect IMPORT
      Samp2Dis, Samp2Kat;

    FROM SYSTEM IMPORT
      ADDRESS;

    FROM HiLevGraf IMPORT
      FrameRect, WrStrXY;

    FROM MMMouse IMPORT
      Region, RegisterRegion, UnregisterRegion, Event, EventSet, ButtonSet,
      GetRegionRect, ShowCursor, HideCursor;

    FROM Graphics IMPORT
      MaxHor, InvertW;

    EXPORT
      Xchg, InitDialog, RuszKursor, UpdateMap, InitWykr, KursorOnOffBP,
      KursorLewoBP, KursorPrawoBP, SkalaPlusBP, SkalaMinusBP, KursorLewoButton,
      KursorPrawoPar, RegionWyk1Event, RegionWyk2Event, RegionWyk3Event,
      RegionWykGEvent, RegionWykGButton, RegionWyk1Button, RegionWyk2Button,
      RegionWyk3Button, DisposeKursor, KursoffOff, KursoffOn;

    CONST
      HideBarOnScreen = 0FFFFH;

    VAR
      RysSytMaxDis       : REAL;
      CursorMode         : BOOLEAN;
      JakijedenWykres    : RodzWykr;
      JedenWykres        : BOOLEAN;
      JakieWykr          : ZbiorWykr;
      popJakieWykr       : ZbiorWykr;
      CursorPos          : INTEGER;
      OileKursor         : INTEGER;
      ZmianaSkaliWpionie : BOOLEAN;
      BarOnScreen        : CARDINAL;
      skalaWpionie       : SkalaWpionieOpis;
      ChangeKursorMode   : BOOLEAN;

    PROCEDURE UniversalEvent
              (    cr : Region;
                   e  : EventSet;
                   b  : ButtonSet;
                   x,
                   y  : INTEGER   );
    VAR
      r : RECT;

    BEGIN
      GetRegionRect(cr, r);
      DEC(r.left);
      DEC(r.top);
      INC(r.right);
      INC(r.bottom);
      IF RegionIn IN e
      THEN
        FrameRect(r, YELLOW);
      ELSIF RegionOut IN e
      THEN
        FrameRect(r, RED);
      END (* if RegionIn *);
    END UniversalEvent;

    (* *********************** DEV *********************************)

    PROCEDURE RegionWykGEvent
              (    e : EventSet;
                   b : ButtonSet;
                   x,
                   y : INTEGER   );

    BEGIN
      UniversalEvent(RegionWykG, e, b, x, y);
      IF LeftDown IN e
      THEN
        RegionWykGButton(NIL);
      END (* if LeftDown *);
    END RegionWykGEvent;

    PROCEDURE RegionWykGButton
              (    a : ADDRESS );

    BEGIN
      IF (WykMain IN JakieWykr) & NOT JedenWykres
      THEN
        JakieWykr := ZbiorWykr {WykMain};
        JakijedenWykres := WykMain;
        JedenWykres := TRUE;
      ELSIF NOT (WykMain IN JakieWykr)
      THEN
        INCL(JakieWykr, WykMain);
        JedenWykres := FALSE;
      END (* if *);
    END RegionWykGButton;

    (* *********************** VAR *********************************)

    PROCEDURE RegionWyk1Event
              (    e : EventSet;
                   b : ButtonSet;
                   x,
                   y : INTEGER   );

    BEGIN
      UniversalEvent(RegionWyk1, e, b, x, y);
      IF LeftDown IN e
      THEN
        RegionWyk1Button(NIL);
      END (* if LeftDown *);
    END RegionWyk1Event;

    PROCEDURE RegionWyk1Button
              (    a : ADDRESS );

    BEGIN
      IF (Wyk1 IN JakieWykr) & NOT JedenWykres
      THEN
        JakieWykr := ZbiorWykr {Wyk1};
        JakijedenWykres := Wyk1;
        JedenWykres := TRUE;
      ELSE
        JakieWykr := ZbiorWykr {WykMain, Wyk1};
        JedenWykres := FALSE;
      END (* if *);
    END RegionWyk1Button;

    (* *********************** REF *********************************)

    PROCEDURE RegionWyk2Event
              (    e : EventSet;
                   b : ButtonSet;
                   x,
                   y : INTEGER   );

    BEGIN
      UniversalEvent(RegionWyk2, e, b, x, y);
      IF LeftDown IN e
      THEN
        RegionWyk2Button(NIL);
      END (* if LeftDown *);
    END RegionWyk2Event;

    PROCEDURE RegionWyk2Button
              (    a : ADDRESS );

    BEGIN
      IF (Wyk2 IN JakieWykr) & NOT JedenWykres
      THEN
        JakieWykr := ZbiorWykr {Wyk2};
        JakijedenWykres := Wyk2;
        JedenWykres := TRUE;
      ELSE
        JakieWykr := ZbiorWykr {WykMain, Wyk2};
        JedenWykres := FALSE;
      END (* if *);
    END RegionWyk2Button;

    (* *********************** SUBCAR *********************************)

    PROCEDURE RegionWyk3Event
              (    e : EventSet;
                   b : ButtonSet;
                   x,
                   y : INTEGER   );

    BEGIN
      UniversalEvent(RegionWyk3, e, b, x, y);
      IF LeftDown IN e
      THEN
        RegionWyk3Button(NIL);
      END (* if LeftDown *);
    END RegionWyk3Event;

    PROCEDURE RegionWyk3Button
              (    a : ADDRESS );

    BEGIN
      IF (Wyk3 IN JakieWykr) & NOT JedenWykres
      THEN
        JakieWykr := ZbiorWykr {Wyk3};
        JakijedenWykres := Wyk3;
        JedenWykres := TRUE;
      ELSE
        JakieWykr := ZbiorWykr {WykMain, Wyk3};
        JedenWykres := FALSE;
      END (* if *);
    END RegionWyk3Button;

    PROCEDURE PokazWgKursora
              (    JakieWykr : ZbiorWykr;
                   redraw    : BOOLEAN   );
    VAR
      nr       : GlownyOdbiornikT;
      idx,
      xpos     : CARDINAL;
      tmp      : INTEGER;
      p1       : POINT;
      rect     : RECT;
      str      : ARRAY [0 .. 9] OF CHAR;
      snr      : CARDINAL;
      currVAL  : DataPointer;
      currWykr : RodzWykr;

    BEGIN (* PokazWgKursora *)
      p1.y := 500;
      p1.x := VAL(INTEGER, MaxHor()) - 180;
      IF redraw
      THEN
        rect.top := 0;
        rect.bottom := 25 * 2;
        rect.left := 0;
        rect.right := 584 - 405;
        ShowCursorDIB(Zestaw, rect, p1);
      END (* if redraw *);
      idx := CursorPos;
      xpos := p1.x + 11;
      snr := idx * samplediv;
      IF pomPromieniowy
      THEN
        snr := Samp2Dis(Zestaw, snr);
        SpecConv.Card500Str(snr, str, 4);
      ELSE
        IF NOT aktFormat360
        THEN
          SpecConv.Int100Str(Samp2Kat(Zestaw, snr), str, 7);
        ELSE
          SpecConv.Ang100Str36(Samp2Kat(Zestaw, snr), str, 7);
        END (* if *);
      END (* if pomPromieniowy *);
      WrStrXY(str, xpos + 60, p1.y + 50, RED, WHITE);
      FOR nr := goA TO goB DO
        IF (WykMain IN JakieWykr)
        THEN
          tmp := VAL1^[by23, nr, idx];
          WITH skalaWpionie[WykMain] DO
            IF tmp <> NilValI
            THEN
              tmp := tmp + entier(currOffset * magni + 0.5);
            END (* if tmp *);
            convertProc(tmp, str, 5);
          END (* with skalaWpionie *);
        ELSE
          str := spac5;   (* lub nic *)
        END (* if *);
        IF nr = goA
        THEN
          WrStrXY(str, xpos, p1.y + 10, GREEN, WHITE);
        ELSE
          WrStrXY(str, xpos + 127, p1.y + 10, RED, WHITE);
        END (* if nr *);
      END (* for nr *);
      xpos := p1.x + 11;
      IF NOT JedenWykres OR (JakijedenWykres <> WykMain)
      THEN
        currWykr := Wyk1;
        LOOP
          IF currWykr IN JakieWykr
          THEN
            EXIT
          END (* if currWykr *);
          INC(currWykr);
        END (* loop *);
        FOR nr := goA TO goB DO
          CASE currWykr OF
            Wyk1 :
              currVAL := VAL2;
            |
            Wyk2 :
              currVAL := VAL3;
            |
            Wyk3 :
              currVAL := VAL4;
          END (* case currWykr *);
          tmp := currVAL^[by23, nr, idx];
          WITH skalaWpionie[currWykr] DO
            IF tmp <> NilValI
            THEN
              tmp := tmp + entier(currOffset * magni + 0.5);
            END (* if tmp *);
            convertProc(tmp, str, 5);
          END (* with skalaWpionie *);
          IF nr = goA
          THEN
            WrStrXY(str, xpos, p1.y + 32, GREEN, WHITE);
          ELSE
            WrStrXY(str, xpos + 127, p1.y + 32, RED, WHITE);
          END (* if nr *);
        END (* for nr *);
      ELSE
        str := spac5;
        WrStrXY(str, xpos, p1.y + 32, GREEN, WHITE);
        WrStrXY(str, xpos + 127, p1.y + 32, RED, WHITE);
      END (* if tmp *);
    END PokazWgKursora;

    PROCEDURE WykrEvent
              (    e : EventSet;
                   b : ButtonSet;
                   x,
                   y : INTEGER   );
    VAR
      NoweDaneKursora : BOOLEAN;

    BEGIN
      IF x >= INTEGER(ThisDTidx)
      THEN
        CursorPos := ThisDTidx;
      ELSE
        CursorPos := x;
      END (* if x *);
      ShowBarCursor(CursorPos, NoweDaneKursora);
      IF NoweDaneKursora
      THEN
        PokazWgKursora(JakieWykr, FALSE);
      END (* if NoweDaneKursora *);
    END WykrEvent;

    PROCEDURE KursorLewoButton
              (    d : ADDRESS );

    BEGIN
      KursorLewoBP;
    END KursorLewoButton;

    PROCEDURE KursorPrawoPar
              (    d : ADDRESS );

    BEGIN
      KursorPrawoBP;
    END KursorPrawoPar;

    PROCEDURE Xchg
              ( VAR jakieWykr       : ZbiorWykr;
                VAR jedenWykres     : BOOLEAN;
                VAR jakijedenWykres : RodzWykr;
                VAR aktSkalaWpionie : SkalaWpionieOpis;
                VAR redraw          : BOOLEAN          );

      PROCEDURE RedrawRqs() : BOOLEAN;

      BEGIN
        IF Predrawreq(ThisDTidx, by23, samplediv) OR (JakieWykr # popJakieWykr)
           OR NextRedraw OR ZmianaSkaliWpionie
        THEN
          popJakieWykr := JakieWykr;
          ZmianaSkaliWpionie := FALSE;
          NextRedraw := FALSE;
          RETURN TRUE;
        END (* if Predrawreq *);
        RETURN FALSE;
      END RedrawRqs;

    BEGIN (* Xchg *)
      redraw := RedrawRqs();
      aktSkalaWpionie := skalaWpionie;
      jakieWykr := JakieWykr;
      jedenWykres := JedenWykres;
      jakijedenWykres := JakijedenWykres;
    END Xchg;

    (* -------------------- KURSOR -------------------- *)

    PROCEDURE ShowBarCursor
              (     pos             : CARDINAL;
                VAR NoweDaneKursora : BOOLEAN  );

    BEGIN
      IF pos # BarOnScreen
      THEN
        HideCursor();
        IF BarOnScreen # HideBarOnScreen
        THEN
          InvertW(BarOnScreen, 42, BarOnScreen, 442);
          NoweDaneKursora := FALSE;
        END (* if BarOnScreen *);
        BarOnScreen := pos;
        IF pos # HideBarOnScreen
        THEN
          InvertW(pos, 42, pos, 442);
          NoweDaneKursora := TRUE;
        END (* if pos *);
        ShowCursor;
      END (* if pos *);
    END ShowBarCursor;

    PROCEDURE KursorOnOffBP;

    BEGIN (* KursorOnOffBP *)
      ChangeKursorMode := TRUE;
    END KursorOnOffBP;

    PROCEDURE SkalaPlusBP;
    VAR

    BEGIN
      IF JedenWykres
      THEN
        WITH skalaWpionie[JakijedenWykres] DO
          IF poziom = 2  THEN
            RETURN
          END;
          INC(poziom);
          IF mantysa <= 0.1
          THEN
            RETURN
          END (* if mantysa *);
          IF cecha = 5
          THEN
            cecha := 2;
          ELSIF cecha = 2
          THEN
            cecha := 1;
          ELSIF cecha = 1
          THEN
            cecha := 5;
            mantysa := mantysa / 10.0;
          END (* if *);
        END (* with skalaWpionie *);
        ZmianaSkaliWpionie := TRUE;
      END (* if JedenWykres *);
    END SkalaPlusBP;

    PROCEDURE SkalaMinusBP;

    BEGIN
      IF JedenWykres
      THEN
        WITH skalaWpionie[JakijedenWykres] DO
          IF poziom = 0 THEN
            RETURN
          END;
          DEC(poziom);
          IF mantysa > 1.0E4
          THEN
            RETURN
          END (* if mantysa *);
          IF cecha = 1
          THEN
            cecha := 2;
          ELSIF cecha = 2
          THEN
            cecha := 5;
          ELSIF cecha = 5
          THEN
            cecha := 1;
            mantysa := mantysa * 10.0;
          END (* if *);
        END (* with skalaWpionie *);
        ZmianaSkaliWpionie := TRUE;
      END (* if jedenWykres *);
    END SkalaMinusBP;

    PROCEDURE KursorPrawoBP;

    BEGIN
      IF CursorMode
      THEN
        INC(OileKursor);
      END (* if CursorMode *);
    END KursorPrawoBP;

    PROCEDURE KursorLewoBP;

    BEGIN
      IF CursorMode
      THEN
        DEC(OileKursor);
      END (* if CursorMode *);
    END KursorLewoBP;

    PROCEDURE UpdateMap;
    BEGIN
      IF NOT CursorMode
      THEN
        PokazKatyLotu(FALSE);
      END (* if *);
    END UpdateMap;

    PROCEDURE RuszKursor;
    VAR
      NoweDaneKursora : BOOLEAN;

      PROCEDURE CurrCursorMode() : BOOLEAN;
      VAR
        WykR            : RECT;
        NoweDaneKursora : BOOLEAN;

      BEGIN
        IF ChangeKursorMode
        THEN
          ChangeKursorMode := FALSE;
          CursorMode := NOT CursorMode;
          IF CursorMode
          THEN
            CursorPos := ThisDTidx;
            OileKursor := 0;
            RectWykresy(WykR, 0);
            RegisterRegion(EventSet {LeftDown}, WykR, WykrEvent, NIL,
                           RegionWykresow);
            ShowBarCursor(CursorPos, NoweDaneKursora);
            PokazWgKursora(JakieWykr, TRUE);
          ELSE
            UnregisterRegion(RegionWykresow);
            ShowBarCursor(HideBarOnScreen, NoweDaneKursora);
            PokazKatyLotu(TRUE);
          END (* if CursorMode *);
        END (* if CursorMode *);
        RETURN CursorMode;
      END CurrCursorMode;

    BEGIN (* RuszKursor *)
      IF CurrCursorMode()
      THEN
        IF OileKursor # 0
        THEN
          CASE ABS(OileKursor) OF
            1 :
            |
            2 :
              OileKursor := OileKursor * 3;
            |
            3, 4 :
              OileKursor := OileKursor * 5;
            |
            5 :
              OileKursor := OileKursor * 10;
          ELSE
            OileKursor := OileKursor * 20;
          END (* case ABS *);
          CursorPos := CursorPos + OileKursor;
        END (* if OileKursor *);
        IF CursorPos <= 0
        THEN
          CursorPos := 1;
        ELSIF CursorPos > INTEGER(ThisDTidx)
        THEN
          CursorPos := INTEGER(ThisDTidx);
        END (* if CursorPos *);
        ShowBarCursor(CursorPos, NoweDaneKursora);
        IF NoweDaneKursora
        THEN
          PokazWgKursora(JakieWykr, FALSE);
        END (* if NoweDaneKursora *);
      END (* if CursorMode *);
      OileKursor := 0;
    END RuszKursor;

    PROCEDURE InitWykr
              (    skalaWpionie : SkalaWpionieOpis;
                   jakieWykr    : ZbiorWykr;
                   jedenWykres  : BOOLEAN          );
    VAR
      currRecta : RECT;
      count     : CARDINAL;
      wi        : RodzWykr;

      PROCEDURE OpisDla
                (    wyk : RodzWykr );
      VAR
        ys       : ARRAY [1 .. 6] OF REAL;
        ysNum    : REAL;
        ysIdx    : CARDINAL;
        rtmp,
        subSkala : REAL;

        PROCEDURE CurrDistance
                  (    RysSytMaxDis : REAL ) : REAL;
        VAR
          RysSytCurDis : REAL;

        BEGIN
          RysSytCurDis := 110.0;
          IF RefDis # 0FFFFH
          THEN
            IF RefDis < 50999
            THEN
              RysSytCurDis := FLOAT(RefDis) / 500.0;
            ELSE
              RysSytCurDis := 110.0;
            END (* if RefDis *);
            IF (RysSytCurDis >= RysSytMaxDis + 1.0) OR
               (RysSytCurDis <= RysSytMaxDis - 11.0)
            THEN
              WHILE (RysSytCurDis >= RysSytMaxDis) DO
                RysSytMaxDis := RysSytMaxDis + 10.0;
              END (* while *);
              WHILE RysSytMaxDis > RysSytCurDis + 11.0 DO
                RysSytMaxDis := RysSytMaxDis - 10.0;
              END (* while RysSytMaxDis *);
            END (* if *);
          END (* if RefDis *);
          RETURN RysSytMaxDis;
        END CurrDistance;
      VAR
        col : CARDINAL;

      BEGIN (* OpisDla *)
        RysSytMaxDis := CurrDistance(RysSytMaxDis);
        col := DolnyWykresTl_Col;
        IF wyk = WykMain
        THEN
          col := GornyWykresTl_Col;
        END (* if wyk *);
        WITH skalaWpionie[wyk] DO
          rtmp := FLOAT(cecha) * mantysa;
          IF NOT log  THEN
            IF cecha = 2
            THEN
              subSkala := 0.75;
            ELSE
              subSkala := 0.7;
            END (* if cecha *);
            (* kolory opisow wykresow *)
            ys[1] := currOffset + subSkala * rtmp;
            ys[2] := currOffset - subSkala * rtmp;
            ys[3] := currOffset;
            Opis(currRecta, 0.0, RysSytMaxDis, currOffset - rtmp, currOffset +
                 rtmp, ys, 0, ys, 3, FALSE, col, WykresNapisy_Col, TRUE);
          ELSE
            ysNum := 1.0;
            ysIdx := 1;
            REPEAT
              ys[ysIdx] := ysNum;
              ysNum := ysNum * 10.0;
              INC(ysIdx);
            UNTIL  rtmp / ysNum < 1.0;
            OpisLog(currRecta, 0.0, RysSytMaxDis, 1.0, rtmp,
                    ys, 0, ys, ysIdx-1, FALSE, col, WykresNapisy_Col, FALSE, TRUE, TRUE);
          END;
        END (* with skalaWpionie *);
      END OpisDla;
    VAR
      NoweDaneKursora   : BOOLEAN;

    BEGIN (* InitWykr *)
      (* os X wspolna *)
      RectWykresy(currRecta, 1);
      IF jedenWykres
      THEN
        RectWykresy(currRecta, 0);
        count := 1;
      ELSE
        RectWykresy(currRecta, 1);
        count := 0;
      END (* if jedenWykres *);
      wi := WykMain;
      LOOP
        IF wi IN jakieWykr
        THEN
          OpisDla(wi);
          IF count = 1
          THEN
            EXIT
          END (* if i *);
          INC(count);
          RectWykresy(currRecta, 2);
        END (* if wi *);
        INC(wi);
      END (* loop *);
    END InitWykr;

    PROCEDURE InitDialog;
    BEGIN
      RysSytMaxDis := 40.0;   (* poczatkowo 40 NM *)
      CursorMode := FALSE;
      JakijedenWykres := WykMain;
      JedenWykres := TRUE;
      JakieWykr := ZbiorWykr {WykMain};
      popJakieWykr := ZbiorWykr {WykMain};
      CursorPos := 0;
      OileKursor := 0;
      BarOnScreen := HideBarOnScreen;
      IniSkale(skalaWpionie, Zestaw);
      PokazKatyLotu(TRUE);
      ChangeKursorMode := FALSE;
    END InitDialog;

    PROCEDURE DisposeKursor;

    BEGIN
      IF CursorMode
      THEN
        UnregisterRegion(RegionWykresow);
      END (* if CursorMode *);
    END DisposeKursor;

    PROCEDURE  KursoffOff;
    VAR
      NoweDaneKursora: BOOLEAN;
    BEGIN
      ShowBarCursor(HideBarOnScreen, NoweDaneKursora);
    END KursoffOff;

    PROCEDURE  KursoffOn;
    VAR
      NoweDaneKursora: BOOLEAN;
    BEGIN
      ShowBarCursor(BarOnScreen, NoweDaneKursora);
    END KursoffOn;

  END Dialog;

  PROCEDURE ConEventButton
            (    a : ADDRESS );

  BEGIN
    currConsoleEv;
  END ConEventButton;

  PROCEDURE SetButtons
            (    enable : BOOLEAN );

  BEGIN
    EnableButton(B_CURSOR, enable);
    EnableButton(B_LEFT, enable);
    EnableButton(B_RIGHT, enable);
    EnableButton(B_UP, enable);
    EnableButton(B_DOWN, enable);
  END SetButtons;

  PROCEDURE InitButtony;
  VAR
    r : RECT;

  BEGIN
    r.top := 19;
    r.bottom := 40;
    r.left := 0;
    r.right := 71;
    MoveRect(r, (+66 + 20) * 6, 0);
    r.right := r.left + 20;
    B_CURSOR := CreateButton(r, "K", 0, 2500H + ORD('k'), KursorOnOffBP);
    MoveRect(r, + 20 + 10, 0);
    B_LEFT := CreateButton(r, CHR(11H), 0, 0FFFFH, KursorLewoBP);
    MoveRect(r, +20 + 7, 0);
    B_RIGHT := CreateButton(r, CHR(10H), 0, 0FFFFH, KursorPrawoBP);
    MoveRect(r, +20 + 10, 0);
    B_UP := CreateButton(r, CHR(1EH), 0, 4800H, SkalaPlusBP);
    MoveRect(r, +20 + 7, 0);
    B_DOWN := CreateButton(r, CHR(1FH), 0, 5000H, SkalaMinusBP);
    (* osobno shortcuty zeby nie rysowac na przyciskow *)
    ShortCuts.DefineShortCut(4B00H, KursorLewoButton, NIL);
    ShortCuts.DefineShortCut(4D00H, KursorPrawoPar, NIL);
  END InitButtony;

  PROCEDURE InitSlupki
            (     Zestaw    : BOOLEAN;
              VAR screenDIB : HDIB    );

    PROCEDURE ShowCurrDIB
              ( VAR screenDIB : HDIB );
    VAR
      r : RECT;
      p : POINT;

    BEGIN
      r.left := 0;
      r.right := 620;
      r.bottom := screenDIBHeight;
      r.top := 0;
      p.x := 0;
      p.y := VAL(INTEGER, MaxVer()) - screenDIBHeight;
      ShowScreenDIB(Zestaw, r, p, screenDIB);
    END ShowCurrDIB;
  VAR
    r  : RECT;
    p1 : POINT;

    PROCEDURE Define
              (     RegR      : RECT;
                    EventProc : EventHandler;
                VAR reg       : Region       );

    BEGIN
      RegisterRegion(EventSet {LeftDown, RegionIn, RegionOut}, RegR, EventProc,
                     NIL, reg);
    END Define;

  BEGIN (* InitSlupki *)
    ShowCurrDIB(screenDIB);
    WykSlup(SlLewy, Zestaw, screenDIB);
    WykSlup(SlSrodkowy, Zestaw, screenDIB);
    WykSlup(SlPrawy, Zestaw, screenDIB);
    IF GetRegionWykG(Zestaw, r)
    THEN
      Define(r, RegionWykGEvent, RegionWykG);
      ShortCuts.DefineShortCut(ShortCuts.kbAlt1, RegionWykGButton, NIL);
      RegionWykGCreated := TRUE;
    ELSE
      RegionWykGCreated := FALSE;
    END (* if GetRegionWykG *);
    IF GetRegionWyk1(Zestaw, r)
    THEN
      Define(r, RegionWyk1Event, RegionWyk1);
      ShortCuts.DefineShortCut(ShortCuts.kbAlt2, RegionWyk1Button, NIL);
      RegionWyk1Created := TRUE;
    ELSE
      RegionWyk1Created := FALSE;
    END (* if GetRegionWyk1 *);
    IF GetRegionWyk2(Zestaw, r)
    THEN
      Define(r, RegionWyk2Event, RegionWyk2);
      ShortCuts.DefineShortCut(ShortCuts.kbAlt3, RegionWyk2Button, NIL);
      RegionWyk2Created := TRUE;
    ELSE
      RegionWyk2Created := FALSE;
    END (* if GetRegionWyk2 *);
    IF GetRegionWyk3(Zestaw, r)
    THEN
      Define(r, RegionWyk3Event, RegionWyk3);
      ShortCuts.DefineShortCut(ShortCuts.kbAlt4, RegionWyk3Button, NIL);
      RegionWyk3Created := TRUE;
    ELSE
      RegionWyk3Created := FALSE;
    END (* if GetRegionWyk3 *);
    ShortCuts.DefineShortCut(ShortCuts.kbF2, ConEventButton, NIL);
  END InitSlupki;

    PROCEDURE InitKrokOpisuOsi;
    BEGIN
      IF pomPromieniowy
      THEN
        KrokOpisuOsi := 500;   (* 1.0 NM *)
      ELSE
        KrokOpisuOsi := 200;   (* 2ø *)
      END (* if promien *);
    END InitKrokOpisuOsi;

  PROCEDURE Init
            (    myZestaw          : BOOLEAN;
                 myPredrawreq      : RedrawReqPT;
                 myPredrawmarksreq : RredrawMarksReqPT;
                 ConsoleEv         : PROC;
                 promien           : BOOLEAN;
                 katPromienia      : WORD;
                 currDistOff       : CARDINAL;
                 currAlfaOff       : REAL;
                 format360         : BOOLEAN           );

  BEGIN
    Init_ScrUtility(myZestaw);
    Zestaw := myZestaw;
    VAL1 := ADR(DataCollect.VAL1[Zestaw]);
    VAL2 := ADR(DataCollect.VAL2[Zestaw]);
    VAL3 := ADR(DataCollect.VAL3[Zestaw]);
    VAL4 := ADR(DataCollect.VAL4[Zestaw]);
    pomPromieniowy := promien;
    aktPromien := katPromienia;
    aktPromienOdAnt := currAlfaOff;
    devDistR := FLOAT(currDistOff) / 500.0;
    aktFormat360 := format360;
    by23 := 0;
    LastDTidx := 0;
    ThisDTidx := 0;
    samplediv := 0;
    NextRedraw := TRUE;
    LastEventIDX := 0;
    InitKrokOpisuOsi;
    Predrawmarksreq := myPredrawmarksreq;
    Predrawreq := myPredrawreq;
    currConsoleEv := ConsoleEv;
    RegionWykGCreated := FALSE;
    RegionWyk1Created := FALSE;
    RegionWyk2Created := FALSE;
    RegionWyk3Created := FALSE;
    InitButtony;
    InitSlupki(Zestaw, screenDIB);
    InitDialog;
  END Init;

  PROCEDURE Update
            (    kind : Term );
  VAR
    JakieWykr       : ZbiorWykr;
    jedenWykres     : BOOLEAN;
    JakijedenWykres : RodzWykr;
    redraw          : BOOLEAN;
    skalaWpionie    : SkalaWpionieOpis;

    PROCEDURE UpdateWykr
              (     skalaWpionie : SkalaWpionieOpis;
                    jakieWykr    : ZbiorWykr;
                    jedenWykres  : BOOLEAN;
                VAR LastDTidx    : CARDINAL;
                    redraw       : BOOLEAN          );
    VAR
      r              : RECT;
      maxY           : REAL;
      minY           : REAL;
      redrawmarksreq : BOOLEAN;

      PROCEDURE ShowMarks
                (     points     : CARDINAL;
                      redraw     : BOOLEAN;
                  VAR NextRedraw : BOOLEAN  );

        PROCEDURE WriteText
                  (    str  : ARRAY OF CHAR;
                       xpos : CARDINAL;
                       event      : BOOLEAN      );
        VAR
          yDisp : INTEGER;
        BEGIN
          IF event  THEN
            yDisp :=  25
          ELSE
            yDisp :=  48
          END;
          IF (xpos > 8) AND (xpos < 800)
          THEN
            DEC(xpos, 4);   (* pixel,pixel,pixel,pixel,znak,pixel... taka jest
                               kreska *)
            IF jedenWykres
            THEN
              WrStrXY(str, xpos - 4, yDisp + 200, WykresNapisy_Col, WykresNapisy_Col);   (*
              color=color=> transparent *)
              WrStrXY('³', xpos, 37 + 200, WykresNapisy_Col, WykresNapisy_Col);
            ELSE
              WrStrXY(str, xpos - 4, yDisp + 100, WykresNapisy_Col,
                      WykresNapisy_Col);
              WrStrXY('³', xpos, 37 + 100, WykresNapisy_Col,
                      WykresNapisy_Col);
              WrStrXY(str, xpos - 4, yDisp + 300, WykresNapisy_Col,
                      WykresNapisy_Col);
              WrStrXY('³', xpos, 37 + 300, WykresNapisy_Col,
                      WykresNapisy_Col);
            END (* if jedenWykres *);
          END (* if *);
        END WriteText;

        PROCEDURE DrawEvent
                  (    pomiar : BOOLEAN;
                       ix     : CARDINAL );
        VAR
          str  : CHAR;
          xpos : INTEGER;

        BEGIN
          WITH Events[pomiar].events[ix] DO
            IF ( EventID < BrakZnacznika) AND (atSample <> MAX(CARDINAL))
            THEN
              xpos := atSample DIV samplediv;
              CASE EventID OF
                StopPomiaru :
                  str := '';
                |
                StartPomiaru :
                  str := '';
                |
                PolVLewo :
                  str := '';
                |
                PolVZero :
                  str := '';
                |
                PolVPrawo :
                  str := '';
                |
                ZnacznikP :
                  str := 'P';
                |
                ZnacznikK :
                  str := 'K';
                |
                ZnacznikT :
                  str := 'T';
                |
                Strefa :
                  str := '';
              ELSE
                str := '';
              END (* case EventID *);
              WriteText(str, xpos, TRUE);
            END (* if Events *);
          END (* with Events *);
        END DrawEvent;

          PROCEDURE ZwKrokOpisuOsi(VAR KrokOpisuOsi   : CARDINAL;
                                       pomPromieniowy : BOOLEAN);
          BEGIN
            IF NOT pomPromieniowy
            THEN
              CASE KrokOpisuOsi OF
                100, 500, 1000 :
                  KrokOpisuOsi := KrokOpisuOsi * 2;   (* 2ø, 10ø, 20ø *)
                |
                200 :
                  KrokOpisuOsi := 500; (* 5ø *)
                |
                2000 :
                  KrokOpisuOsi := 4500; (* 45ø *)
              ELSE
                KrokOpisuOsi := KrokOpisuOsi * 2;   (* 90ø, 180ø, 360ø *)
              END (* case KrokOpisuOsi *);
            ELSE
              IF KrokOpisuOsi = 1000
              THEN
                KrokOpisuOsi := 2500; (* 5 NM *)
              ELSE
                KrokOpisuOsi := KrokOpisuOsi * 2;   (* 2, 10, 20 NM*)
              END (* if KrokOpisuOsi *);
            END (* if *);
          END ZwKrokOpisuOsi;

      CONST
        MinMarksDist = 800 DIV 10;
      VAR
        ix            : CARDINAL;
        scrIx         : CARDINAL;
        lastIx        : CARDINAL;
        markStr       : ARRAY[0..2] OF CHAR;

      BEGIN (* showmarks *)
        ix := 0;
        lastIx := 0;
        scrIx  := 0;
        IF NOT pomPromieniowy
        THEN
          ResetMarks_A;
          WHILE GetNextAMark(Zestaw, ix, markStr, KrokOpisuOsi, aktFormat360)
          DO
            scrIx := ix DIV samplediv;
            WriteText(markStr, scrIx, FALSE);
            IF ((scrIx - lastIx) < MinMarksDist) AND ( lastIx > 0)  THEN
              ZwKrokOpisuOsi(KrokOpisuOsi, pomPromieniowy);
              NextRedraw := TRUE;
              RETURN;
            END;
            lastIx := scrIx;
          END (* while *);
        ELSE
          ResetMarks_D;
          WHILE GetNextDMark(Zestaw, ix, markStr, KrokOpisuOsi)
          DO
            scrIx := ix DIV samplediv;
            WriteText(markStr, scrIx, FALSE);
            IF ((scrIx - lastIx) < MinMarksDist) AND ( lastIx > 0)  THEN
              ZwKrokOpisuOsi(KrokOpisuOsi, pomPromieniowy);
              NextRedraw := TRUE;
              RETURN;
            END;
            lastIx := scrIx;
          END (* while *);
        END;
        IF redraw
        THEN
          ix := 0;
        ELSE
          ix := LastEventIDX;
        END (* if redraw *);
        WHILE ix < Events[Zestaw].EventIDX DO
          DrawEvent(Zestaw, ix);
          LastEventIDX := ix;
          INC(ix);
        END (* while ix *);
      END ShowMarks;

    BEGIN (* UpdateWykr *)
      IF redraw
      THEN
        LastDTidx := 0;
      END (* if redraw *);
      IF jedenWykres
      THEN
        RectWykresy(r, 0);
      ELSE
        RectWykresy(r, 1);
      END (* if jedenWykres *);
      IF WykMain IN jakieWykr
      THEN
        WITH skalaWpionie[WykMain] DO
          maxY := magni * real(cecha) * mantysa;
          IF log THEN
            minY := 1.0;
          ELSE
            minY := -maxY;
          END;
          Draw(VAL1^[by23, goA], LastDTidx, ThisDTidx, r, maxY, minY, WykresKanA_Col,
               log);
          Draw(VAL1^[by23, goB], LastDTidx, ThisDTidx, r, maxY, minY, WykresKanB_Col,
               log);
        END (* with skalaWpionie *);
      END (* if WykMain *);
      IF jakieWykr * ZbiorWykr {Wyk1..Wyk3} # ZbiorWykr {}
      THEN
        IF NOT jedenWykres
        THEN
          RectWykresy(r, 2);
        END (* if *);
        IF Wyk1 IN jakieWykr (* VAR *)
        THEN
          WITH skalaWpionie[Wyk1] DO
            maxY := magni * real(cecha) * mantysa;
            IF log THEN
              minY := 1.0;
            ELSE
              minY := -maxY;
            END;
            Draw(VAL2^[by23, goA], LastDTidx, ThisDTidx, r, maxY, minY, WykresKanA_Col,
                 log);
            Draw(VAL2^[by23, goB], LastDTidx, ThisDTidx, r,  maxY, minY, WykresKanB_Col,
                 log);
          END (* with skalaWpionie *);
        ELSIF Wyk2 IN jakieWykr (* REF *)
        THEN
          WITH skalaWpionie[Wyk2] DO
            maxY := magni * real(cecha) * mantysa;
            IF log THEN
              minY := 1.0;
            ELSE
              minY := -maxY;
            END;
            Draw(VAL3^[by23, goA], LastDTidx, ThisDTidx, r, maxY, minY, WykresKanA_Col,
                 log);
            Draw(VAL3^[by23, goB], LastDTidx, ThisDTidx, r, maxY, minY, WykresKanB_Col,
                 log);
          END (* with skalaWpionie *);
        ELSIF Wyk3 IN jakieWykr (* SUB *)
        THEN
          WITH skalaWpionie[Wyk3] DO
            maxY := magni * real(cecha) * mantysa;
            IF log THEN
              minY := 1.0;
            ELSE
              minY := -maxY;
            END;
            Draw(VAL4^[by23, goA], LastDTidx, ThisDTidx, r, maxY, minY, WykresKanA_Col,
                 log);
            Draw(VAL4^[by23, goB], LastDTidx, ThisDTidx, r, maxY, minY, WykresKanB_Col,
                 log);
          END (* with skalaWpionie *);
        END (* if Wyk1 *);
      END (* if JakW *);
      LastDTidx := ThisDTidx;
      WITH Events[Zestaw]  DO
        IF (EventIDX > 0)  AND (EventIDX-1 <> LastEventIDX) THEN
          redrawmarksreq := TRUE;
        END;
      END;
      redrawmarksreq := redrawmarksreq OR Predrawmarksreq(KrokOpisuOsi);
      IF redraw OR redrawmarksreq
      THEN
        redrawmarksreq := FALSE;
        ShowMarks(ThisDTidx, redraw, NextRedraw);
      END (* if redraw *);
    END UpdateWykr;

    PROCEDURE WskazWykresy
              (    JakieWykr : ZbiorWykr );

      PROCEDURE MarkDraw
                (    RegionWyk : Region;
                     wyk       : RodzWykr );
      VAR
        rRec : RECT;
        col  : CARDINAL;

      BEGIN
        GetRegionRect(RegionWyk, rRec);
        WITH rRec DO
          top := bottom;
          INC(bottom, 3);
        END (* with rRec *);
        IF wyk IN JakieWykr
        THEN
          col := YELLOW;
        ELSE
          col := RED;
        END (* if idx *);
        FillRect(rRec, CHR(col));
      END MarkDraw;

    BEGIN
      IF RegionWykGCreated
      THEN
        MarkDraw(RegionWykG, WykMain);
      END (* if RegionWykGCreated *);
      IF RegionWyk1Created
      THEN
        MarkDraw(RegionWyk1, Wyk1);
      END (* if RegionWyk1Created *);
      IF RegionWyk2Created
      THEN
        MarkDraw(RegionWyk2, Wyk2);
      END (* if RegionWyk2Created *);
      IF RegionWyk3Created
      THEN
        MarkDraw(RegionWyk3, Wyk3);
      END (* if RegionWyk3Created *);
    END WskazWykresy;

    PROCEDURE UpdateNapisy
              (    redraw,
                   Zestaw : BOOLEAN );
    CONST
      GDOP_pos = 600;
      
    
    VAR
      str : ARRAY [0 .. 10] OF CHAR;

      PROCEDURE NapiszGPS
                (    face : SYSTEM.BYTE );
      VAR
        str   : ARRAY [0 .. 10] OF CHAR;
        alfa  : REAL;
        currR : REAL;

      PROCEDURE NapiszGPSFlg(str: ARRAY OF CHAR);
      BEGIN
        WrStrXY(str, 453, 2, WHITE, LT_RED);
        WrStrXY(str, 533, 2, WHITE, LT_RED);
        WrStrXY(str, GDOP_pos, 2, BROWN, LT_RED);
      END NapiszGPSFlg;

      BEGIN
        IF redraw
        THEN
          WrStrXY("a=      ø", 437, 2, BROWN, 0);
          WrStrXY("r=       ", 513, 2, BROWN, 0);
          WrStrXY("NM", 576, 2, BROWN, 0);
        END (* if redraw *);
        IF InDiffMode IN GPS_OK THEN
           WrStrXY("DGPS", 382, 2, face, 0);
        ELSE
           WrStrXY(" GPS", 382, 2, face, 0);
        END;
        IF NieMaTransmisji IN GPS_OK
        THEN
          NapiszGPSFlg(" -NOT-");
        ELSIF BledyWTransmisji IN GPS_OK
        THEN
          NapiszGPSFlg(" -ERR-");
        ELSIF Flaga IN GPS_OK
        THEN
          NapiszGPSFlg(" -FLG-");
        ELSE
          alfa := GPS_A;
          alfa := SpecConv.SubAng360(alfa, aktPromienOdAnt);
          IF aktFormat360
          THEN
            IF alfa < 0.0
            THEN
              alfa := alfa + 360.0
            END (* if alfa *);
            IF alfa > 359.9
            THEN
              alfa := 0.0
            END (* if alfa *);
          END (* if *);
          sprintf(str, "%6.1g", alfa);      (*tu buly procenty*)
          WrStrXY(str, 453, 2, YELLOW, 0);
          currR := GPS_R - devDistR;
          sprintf(str, "%6.1g", currR);
          WrStrXY(str, 533, 2, YELLOW, 0);
          IF ScannerI.GPS_GDOP < 9999 THEN
            SpecConv.Int100Str(ScannerI.GPS_GDOP, str, 6);
          ELSE
            SpecConv.Int100Str(CommonTypes.SigNilVal, str, 6);
          END;
          WrStrXY(str, GDOP_pos, 2, BROWN, 0);
        END (* if NoTrans_Warning *);
        SpecConv.Int2Str(ScannerI.GPS_SAT, str, 3);        
        WrStrXY(str, 655, 2, GREEN, 0);
        SpecConv.Card500Str(ScannerI.GPS_PREC, str, 3);        
        WrStrXY(str, 690, 2, BROWN, 0);
      END NapiszGPS;

      PROCEDURE NapiszTEO
                (    face : SYSTEM.BYTE );
      VAR
        back : SYSTEM.BYTE;
        str  : ARRAY [0 .. 10] OF CHAR;

      BEGIN
        IF redraw
        THEN
          WrStrXY("TEO", 160, 2, face, 0);
          WrStrXY("A=        ø", 194, 2, BROWN, 0);
          WrStrXY("E=        ø", 291, 2, BROWN, 0);
        END (* if redraw *);
        IF ScannerI.TEO_DGPSpoprawki  THEN (*wypisanieczy transmitowane sa poprawki z referencyjnej 
                       stacji DGPS*)
          WrStrXY(" DIFF", 750, 21, YELLOW, 0);
        ELSE
          WrStrXY("NDIFF", 750, 21, YELLOW, 0);
        END;
        IF tRSZepsuty IN TEO_OK
        THEN
          str := " -NOT- ";
          back := BYTE(LT_RED);
          face := BYTE(WHITE);
        ELSIF tFlaga IN TEO_OK
        THEN
          str := " -FLG- ";
          back := BYTE(BLACK);
          face := BYTE(YELLOW);
        ELSIF tBledy IN TEO_OK (* OR (NoTrans_Warning IN TEO_OK) *)
        THEN
          str := " -ERR- ";
          back := BYTE(MAGENTA);
          face := BYTE(BLACK);
        ELSE
          IF NOT aktFormat360
          THEN
            SpecConv.Int100Str(entier(TEO_A * 100.0 + 0.5), str, 7);
          ELSE
            SpecConv.Ang100Str36(entier(TEO_A * 100.0 + 0.5), str, 7);
          END (* if *);
          WrStrXY(str, 210, 2, YELLOW, 0);
          sprintf(str, "%7.2g", TEO_E); (* tu byly procenty *)
          WrStrXY(str, 310, 2, YELLOW, 0);
          RETURN;
        END (* if NoTrans_Warning *);
        WrStrXY(str, 210, 2, face, back);
        WrStrXY(str, 310, 2, face, back);
      END NapiszTEO;

    BEGIN (* UpdateNapisy *)
      NapiszSygnaly(Zestaw);
      IF redraw
      THEN
        IF pomPromieniowy
        THEN
        (* gora ekranu == w 2 linii *)
          WrStrXY("PROMIEã      ø", 10, 2, YELLOW, 0);
          NumberConversion.CardToString(INTEGER(aktPromien), str, 3);
          WrStrXY(str, 10 + 9 * 8, 2, YELLOW, 0);
        ELSE
        (* gora ekranu == w 2 linii *)
          WrStrXY("OKR¤G        NM", 10, 2, YELLOW, 0);
          SpecConv.Card500Str(CARDINAL(aktPromien), str, 5);
          WrStrXY(str, 10 + 7 * 8, 2, YELLOW, 0);
        END (* if *);
      END (* if redraw *);
      IF OdnDlaPomBledu = pbTeodolit
      THEN
        NapiszTEO(WHITE);
        NapiszGPS(BROWN);
      ELSE
        NapiszTEO(BROWN);
        NapiszGPS(WHITE);
      END (* if OdnDlaPomBledu *);
      IF ScannerI.ABOVESL = NilValI
      THEN
        str := '-ERR-';
      ELSE
        NumberConversion.IntToString(ScannerI.ABOVESL, str, 5);
      END (* if ScannerI.ABOVESL *);
      WrStrXY(str, 690, 21, YELLOW, 0);
    END UpdateNapisy;

  BEGIN (* Update *)
    Xchg(JakieWykr, jedenWykres, JakijedenWykres, skalaWpionie, redraw);
    (* pobierz parametry wykresow *)
    IF redraw
    THEN
      kind := Redraw;
    END (* if redraw *);
    LOOP
      CASE kind OF
        Short :
          UpdateSlupki;   (* 3x na sekunde *)
          RuszKursor;
          EXIT;
        |
        Long :
          UpdateNapisy(FALSE, Zestaw);
          UpdateMap;
          UpdateWykr(skalaWpionie, JakieWykr, jedenWykres, LastDTidx, FALSE);
          kind := Short;
        |
        Redraw :
          KursoffOff;
          InitWykr(skalaWpionie, JakieWykr, jedenWykres);
          UpdateWykr(skalaWpionie, JakieWykr, jedenWykres, LastDTidx, TRUE);
          KursoffOn;
          WskazWykresy(JakieWykr);
          UpdateNapisy(TRUE, Zestaw);
          UpdateMap;
          kind := Short;
      END (* case kind *);
    END (* loop *);
  END Update;

  PROCEDURE  ScreenStart;
  BEGIN
    InitKrokOpisuOsi;
  END ScreenStart;
  
  PROCEDURE Done;

    PROCEDURE KasujSlupki;

    BEGIN
      DisposeSlupki;
      IF RegionWykGCreated
      THEN
        UnregisterRegion(RegionWykG);
        ShortCuts.DeleteShortCut(ShortCuts.kbAlt1);
        RegionWykGCreated := FALSE;
      END (* if RegionWykGCreated *);
      IF RegionWyk1Created
      THEN
        UnregisterRegion(RegionWyk1);
        ShortCuts.DeleteShortCut(ShortCuts.kbAlt2);
        RegionWyk1Created := FALSE;
      END (* if RegionWyk1Created *);
      IF RegionWyk2Created
      THEN
        UnregisterRegion(RegionWyk2);
        ShortCuts.DeleteShortCut(ShortCuts.kbAlt3);
        RegionWyk2Created := FALSE;
      END (* if RegionWyk2Created *);
      IF RegionWyk3Created
      THEN
        UnregisterRegion(RegionWyk3);
        ShortCuts.DeleteShortCut(ShortCuts.kbAlt4);
        RegionWyk3Created := FALSE;
      END (* if RegionWyk3Created *);
      DisposeKursor;
    END KasujSlupki;

    PROCEDURE DisposeButtons;

    BEGIN
      ShortCuts.DeleteShortCut(4B00H);
      ShortCuts.DeleteShortCut(4D00H);
      DisposeButton(B_CURSOR);
      DisposeButton(B_LEFT);
      DisposeButton(B_RIGHT);
      DisposeButton(B_UP);
      DisposeButton(B_DOWN);
    END DisposeButtons;

  BEGIN
    DisposeButtons;
    KasujSlupki;
  END Done;

BEGIN
  pomPromieniowy := FALSE;
  screenDIB := HDIB(NIL);
END Screen.
