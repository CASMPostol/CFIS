(*.F- *)
(**********************************************************************
|  Title   : Obsluga ekranu analizy po pomiarze
|  Author  : M.Postol
|  System  : LOGITECH MODULA-2/86
|  History :
|
|  Copyright (C), CAS LODZ POLAND.
|  TEL: 42' 862 547, 42' 87 80 44 FAX/TEL: 42' 84 48 40
|
**********************************************************************)

IMPLEMENTATION MODULE PI_Analiza;

  IMPORT
    ShortCuts, GrafTypes, Buttons, MANAGER, L_DisResults, D_DisResults;

  FROM CommonTypes IMPORT
    GlownyOdbiornikT, OdnDlaPomBleduT;

  FROM EventsMng  IMPORT
    EventKind, RodzUrzadzenia;

  FROM PiszEventy IMPORT
    TworzEventy, PiszNaEkranie, STRONA, TypyEventow, IleEventow;

  FROM MsgBox  IMPORT
    Info;

  FROM L_results IMPORT
    anRes;

  FROM L_CommonTypes IMPORT
    CzyToJestPromien;
  TYPE
    DispResultsPT =
      PROCEDURE
            (  GlownyOdbiornikT,
               OdnDlaPomBleduT);
  VAR
    dispResults : DispResultsPT;
    
  MODULE MouseMonitor [ 0 ];

    IMPORT
      ShortCuts;

    FROM MANAGER IMPORT
      Assert, Condition, Notify, WAITC, InitC;

    FROM GrafTypes IMPORT
      RECT, MoveRect;

    FROM Buttons IMPORT
      Button, CreateButton, EnableButton, DisposeButton;

    EXPORT
      Event, InitButtony, GetEvent, DisposeButtons, B_UP, B_DOWN;

    TYPE
      buttonsEvent =
        ( PageUPbut,
          PageDwnBut,
          DrukujBut,
          AkceptacjaBut,
          KoniecBut,
          PrzelaczPomBut );
      MyButtonSet  =
        SET OF buttonsEvent;
      Event        =
        ( AkceptacjaPE,
          KoniecPE,
          DrukujPE,
          PageUpPE,
          PageDownPE,
          PrzelaczPomPE );

    VAR
      currButtonSet : MyButtonSet;
      B_Drukuj      : Button;  (* DRUKUJ *)
      B_Akceptuj    : Button;  (* AKCEPT *)
      B_Abort       : Button;  (* KONIEC *)
      B_UP          : Button;
      B_DOWN        : Button;
      B_XCHG        : Button;
      sthPressed    : Condition;
    PROCEDURE DrukujBP;

    BEGIN
      INCL(currButtonSet, DrukujBut);
      Notify(sthPressed);
    END DrukujBP;

    PROCEDURE ZapamietajBP;

    BEGIN
      INCL(currButtonSet, AkceptacjaBut);
      Notify(sthPressed);
    END ZapamietajBP;

    PROCEDURE PWyjscieZProgramuBP;

    BEGIN
      INCL(currButtonSet, KoniecBut);
      Notify(sthPressed);
    END PWyjscieZProgramuBP;

    PROCEDURE PageUpBP;

    BEGIN
      INCL(currButtonSet, PageUPbut);
      Notify(sthPressed);
    END PageUpBP;

    PROCEDURE PrzelaczPomiaryBP;

    BEGIN
      INCL(currButtonSet, PrzelaczPomBut);
      Notify(sthPressed);
    END PrzelaczPomiaryBP;

    PROCEDURE PageDownBP;

    BEGIN
      INCL(currButtonSet, PageDwnBut);
      Notify(sthPressed);
    END PageDownBP;

    PROCEDURE InitButtony
              (    switcxhAble : BOOLEAN;
                   Zestaw      : BOOLEAN;
                   archData    : BOOLEAN);
    VAR
      r : RECT;

    BEGIN
      r.top := 20;
      r.bottom := 40;
      r.left := 0;
      r.right := 71;
      MoveRect(r, +66 + 20, 0);
      MoveRect(r, +66 + 20, 0);
      B_Drukuj := CreateButton(r, "DRUKUJ", 0, ShortCuts.kbAltD, DrukujBP);
      MoveRect(r, +66 + 20, 0);
      B_Akceptuj := CreateButton(r, "AKCEPT", 0, ShortCuts.kbAltA, ZapamietajBP
                    );
      MoveRect(r, +66 + 20, 0);
      B_Abort := CreateButton(r, "KONIEC", 0, ShortCuts.kbAltK,
                              PWyjscieZProgramuBP);
      IF archData  THEN
        EnableButton(B_Abort, FALSE);
      END;
      MoveRect(r, +66 + 20, 0);
      B_UP := CreateButton(r, CHR(1EH), 0, 4800H, PageUpBP);
      MoveRect(r, +66 + 20, 0);
      B_DOWN := CreateButton(r, CHR(1FH), 0, 5000H, PageDownBP);
      IF switcxhAble
      THEN
        MoveRect(r, +66 + 20, 0);
        IF Zestaw
        THEN   (* jest DME *)
          B_XCHG := CreateButton(r, "N A V", 0, ShortCuts.kbAltN,
                                 PrzelaczPomiaryBP);
        ELSE
          B_XCHG := CreateButton(r, "D M E", 2, ShortCuts.kbAltM,
                                 PrzelaczPomiaryBP);
        END (* if Zestaw *);
      END (* if switcxhAble *);
      currButtonSet := MyButtonSet {};
    END InitButtony;

    PROCEDURE GetEvent() : Event;
    VAR
      currResult : Event;

    BEGIN (* GetEvent *)
      LOOP
        IF currButtonSet # MyButtonSet {}
        THEN
          IF DrukujBut IN currButtonSet
          THEN
            EXCL(currButtonSet, DrukujBut);
            currResult := DrukujPE;
          ELSIF AkceptacjaBut IN currButtonSet
          THEN
            EXCL(currButtonSet, AkceptacjaBut);
            currResult := AkceptacjaPE;
          ELSIF KoniecBut IN currButtonSet
          THEN
            EXCL(currButtonSet, KoniecBut);
            currResult := KoniecPE;
          ELSIF PrzelaczPomBut IN currButtonSet
          THEN
            EXCL(currButtonSet, PrzelaczPomBut);
            currResult := PrzelaczPomPE;
          ELSIF PageUPbut IN currButtonSet
          THEN
            EXCL(currButtonSet, PageUPbut);
            currResult := PageUpPE;
          ELSIF PageDwnBut IN currButtonSet
          THEN
            EXCL(currButtonSet, PageDwnBut);
            currResult := PageDownPE;
          ELSE
            Assert(FALSE);
          END (* if DrukujBut *);
          EXIT;
        ELSE
          WAITC(sthPressed);
        END (* if currButtonSet *);
      END (* loop *);
      RETURN currResult;
    END GetEvent;

    PROCEDURE DisposeButtons
              (    switcxhAble : BOOLEAN );

    BEGIN
      DisposeButton(B_Drukuj);
      DisposeButton(B_Akceptuj);
      DisposeButton(B_Abort);
      DisposeButton(B_UP);
      DisposeButton(B_DOWN);
      IF switcxhAble
      THEN
        DisposeButton(B_XCHG);
      END (* if switcxhAble *);
    END DisposeButtons;

  BEGIN
    currButtonSet := MyButtonSet {};
    B_Drukuj := Button(NIL);
    B_Akceptuj := Button(NIL);
    B_Abort := Button(NIL);
    B_UP := Button(NIL);
    B_DOWN := Button(NIL);
    B_XCHG := Button(NIL);
    InitC(sthPressed)
  END MouseMonitor;

  PROCEDURE AnalizaEP
            (    switcxhAble     : BOOLEAN;
                 archData        : BOOLEAN;
                 Zestaw          : BOOLEAN;
                 GlownyOdbiornik : GlownyOdbiornikT;
                 OdnDlaPomBledu  : OdnDlaPomBleduT) : analizaEvent;
  VAR
    result    : analizaEvent;
    ilosc     : INTEGER;
    polozenie : INTEGER;
    CoRobic   : RodzUrzadzenia;
    refXDIst  : BOOLEAN;
  BEGIN
    InitButtony(switcxhAble, Zestaw, archData);
    IF NOT Zestaw THEN
      CoRobic := U_LOC;
    ELSE
      CoRobic := U_DME;
    END;
    TworzEventy(CoRobic);
    ilosc := IleEventow();
    polozenie := -STRONA;
    Buttons.EnableButton( B_UP, FALSE );
    CASE Zestaw  OF
      FALSE:
       dispResults := L_DisResults.DispResults;
      |
      TRUE:
        dispResults := D_DisResults.DispResults;
    END;
    dispResults(GlownyOdbiornik, OdnDlaPomBledu);
    refXDIst := CzyToJestPromien( anRes.procedure );
    LOOP
      CASE GetEvent() OF
        AkceptacjaPE :
          IF archData THEN
            result := AbortAE;
          ELSE
            result := ZakonczAE;
          END;
          EXIT;
        |
        KoniecPE :
          result := AbortAE;
          IF Info( "Jeste˜ pewien, ¾e chcesz usun¥† dane?" ) THEN
            IF Info( "Dane zostan¥ usuni©te..." ) THEN
              EXIT;
            END;
          END;
        |
        DrukujPE :
          result := DrukujAE;
          EXIT;
        |
        PageUpPE :
          IF polozenie >= 0 THEN
            DEC( polozenie, STRONA );
            IF polozenie < 0 THEN
              dispResults( GlownyOdbiornik, OdnDlaPomBledu);
            ELSE
              PiszNaEkranie(CoRobic,
                            refXDIst,
                            TypyEventow{PoczatekPomiaru..Strefa},
                            polozenie );
            END;
          END;
        |
        PageDownPE :
          INC( polozenie, STRONA );
          PiszNaEkranie( CoRobic,
                         refXDIst,
                         TypyEventow{PoczatekPomiaru..Strefa}, 
                         polozenie );
        |
        PrzelaczPomPE :
          result := SwitchAE;
          EXIT;
      END (* case GetEvent *);
      Buttons.EnableButton( B_UP, polozenie >= 0 );
      Buttons.EnableButton( B_DOWN, polozenie+STRONA < ilosc );
    END (* loop *);
    DisposeButtons(switcxhAble);
    RETURN result;
  END AnalizaEP;

END PI_Analiza.
