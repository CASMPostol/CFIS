(*.F- *)
(**********************************************************************
|  Title   : Kopiowanie inspekcji
|  Author  : M.Postol
|  System  : LOGITECH MODULA-2/86
|  History :
|    Rel.3.11: created
|    Rel.3.14: MPostol
|      Dodalem wypisywanie statystyki 
|
|  Copyright (C), CAS LODZ POLAND.
|  TEL: 42' 686 25 47
|  mailto: techsupp@cas.com.pl
|  http: www.cas.com.pl
|
**********************************************************************)
(*.F+ *)
IMPLEMENTATION MODULE InspMng;

  IMPORT
    ShortCuts, MsgBox, MANAGER;

  FROM GrafTypes IMPORT
    RECT, AssignRect, MoveRect, WHITE, BLUE, MAGENTA, RED, GREEN;

  FROM Timer IMPORT
    TInOneSecond;

  FROM Strings IMPORT
    Length, Insert, ConstAssign, Concat;

  FROM Ini IMPORT
    GetPrivateProfileString;

  FROM MANAGER IMPORT
    STARTPROCESS;

  FROM HiLevGraf IMPORT
    SetPaletteEntry, Wr2fStrXY, WrStrXY, FillRect, FrameRect;

  FROM Obloty IMPORT
    (* PROCEDURE *) WymInspekcjeDlaUrz, 
                    StartInspection, InitListaUrzadzen, KopiujInspekcje,
                    SzczegolowyPlikOpisu, SkasujInspekcje,
    (* TYPE *)  T_InspectionKind,
    (* CONST *) KartDomyslna,
    (* VAR *) Stat_Size_Monitor, Stat_File_Monitor;

  FROM Buttons IMPORT
    Button, EnableButton;

  FROM Dialog IMPORT
    HDLG, EndDialog, TworzDialog, WstawListe, WstawButton, EnableDlg, Go,
    UsunDialog, Redraw, GetDialogDIBHandle, IsBusy;

  FROM GList IMPORT
    HLIST, SetNotificationProc, Sortowana, GetSelection, Skasuj, SetSelection,
    DodajDoListy, Idx2Str, SkasujWszystko, LiczbaElementow;

  FROM CommonTypes IMPORT
    Str40, Str99;

  FROM SYSTEM IMPORT
    ADR, ADDRESS;

  FROM StdIO IMPORT
    sprintf;
  CONST
    LocAStr          = "C:\dane.bak\";
    LocCStr          = "D:\dane.bak\";
    LocEStr          = "E:\dane.bak\";
    WysokoscLiniiTxt = 16;
    
  VAR
    NazwaOblotu         : Str40;
    hDlg                : HDLG;
    RedrawScr           : BOOLEAN;
    ListaLokalizacji    : HLIST;
    ListaOblotowL       : HLIST;
    ListaOblotowP       : HLIST;
    OstatniOblotL       : INTEGER;
    OstatniOblotP       : INTEGER;
    KartBazyL           : Str40;
    KartBazyP           : Str40;
    archLocStrLocBox    : RECT;
    statStrBox          : RECT;
    BT_KopiujInspP      : Button;
    BT_KopiujInspL      : Button;

    
  PROCEDURE Insp_Stat_Size_Monitor
            ( size: REAL);
  VAR
    str     : Str40;
    sizeAdr : ADDRESS;
    
  BEGIN
    WITH statStrBox DO
      sizeAdr := ADR(size);
      sprintf(str, "SKOPIOWANO: %7.0lf BAJTOW", size);
      WrStrXY(str, left+2, top+2+2*WysokoscLiniiTxt, WHITE, BLUE);
    END (* WITH *);
  END Insp_Stat_Size_Monitor;

  PROCEDURE  Insp_Stat_File_Monitor
             ( file_name  : ARRAY OF CHAR;
               numOfFiles : CARDINAL);
  VAR
    str           : ARRAY[ 0 .. 60] OF CHAR;
    idx           : CARDINAL;
    numOfFilesAdr : ADDRESS;
    
  BEGIN
    WITH statStrBox DO
      ConstAssign("NAZWA PLIKU: ", str);
      Concat(str, file_name, str);
      FOR idx := Length(str) TO HIGH(str)  DO
        str[idx] := ' ';
      END (* FOR *);
      WrStrXY(str, left+2, top+2+0*WysokoscLiniiTxt, WHITE, BLUE);
      numOfFilesAdr := ADR(numOfFiles);
      sprintf(str, "SKOPIOWANO: %7u plikow",  numOfFiles);
      WrStrXY(str, left+2, top+2+1*WysokoscLiniiTxt, GREEN, BLUE);
    END (* WITH *);
  END Insp_Stat_File_Monitor;

  PROCEDURE BP_UsunOblotP();

  BEGIN
    DepositeEvent( EV_DeleteR );
  END BP_UsunOblotP;

  PROCEDURE BP_UsunOblotL();

  BEGIN
    DepositeEvent( EV_DeleteL );
  END BP_UsunOblotL;

  PROCEDURE BP_OblotOK();
  BEGIN
    EndDialog(TRUE);
  END BP_OblotOK;

  PROCEDURE BP_VOR();
  BEGIN
    StartInspection(Insp_VOR); 
    Init_ListaLokalizacji;
  END BP_VOR;

  PROCEDURE BP_TRS();
  BEGIN
    StartInspection(Insp_TRS); 
    Init_ListaLokalizacji;
  END BP_TRS;

  PROCEDURE BP_LOC();
  BEGIN
    StartInspection(Insp_LOC); 
    Init_ListaLokalizacji;
  END BP_LOC;

  PROCEDURE BP_GS();
  BEGIN
    StartInspection(Insp_GS); 
    Init_ListaLokalizacji;
  END BP_GS;

  PROCEDURE BP_ADF();
  BEGIN
    StartInspection(Insp_NDB); 
    Init_ListaLokalizacji;
  END BP_ADF;

  PROCEDURE BP_VHF();
  BEGIN
    StartInspection(Insp_VHF);
    Init_ListaLokalizacji;
  END BP_VHF;

  PROCEDURE WriteArchLoc;
  BEGIN
    Redraw(hDlg, archLocStrLocBox);
    FillRect ( archLocStrLocBox, BLUE);
    FrameRect( archLocStrLocBox, MAGENTA);
    WrStrXY  ( KartBazyL, archLocStrLocBox.left+2, archLocStrLocBox.top+2, 
               WHITE,     BLUE);
  END WriteArchLoc;
  
  PROCEDURE  BP_ArchA;
  BEGIN
    ConstAssign( LocAStr, KartBazyL);
    Init_ListaLokalizacji;
    WriteArchLoc;
  END BP_ArchA;
  
  PROCEDURE  BP_ArchC;
  BEGIN
    ConstAssign(LocCStr, KartBazyL);
    Init_ListaLokalizacji;
    WriteArchLoc;
  END BP_ArchC;
  
  PROCEDURE  BP_ArchE;
  BEGIN
    ConstAssign(LocEStr, KartBazyL);
    Init_ListaLokalizacji;
    WriteArchLoc;
  END BP_ArchE;
  
  PROCEDURE BP_KopiujInspL;
  BEGIN
    DepositeEvent(EV_CopyL);
  END BP_KopiujInspL;

  PROCEDURE BP_KopiujInspP;
  BEGIN
    DepositeEvent(EV_CopyR);
  END BP_KopiujInspP;
  
  MODULE  Monitor[0];
  
  FROM MANAGER IMPORT
    Condition, Notify, InitC, WAITC;
  
  
  EXPORT
    T_EventButt, DepositeEvent, GetEvent;
    
  TYPE
    T_EventButt = (EV_CopyL, EV_CopyR, EV_DeleteR, EV_DeleteL, EV_DoNothing);

  VAR
    event     : T_EventButt;
    waitEvent : Condition;
  
  PROCEDURE GetEvent(): T_EventButt;
  VAR
    lEvent: T_EventButt;
  BEGIN
    IF event = EV_DoNothing  THEN
      WAITC(waitEvent);
    END (* IF *);
    lEvent := event;
    event := EV_DoNothing;
    RETURN lEvent;
  END GetEvent;
  
  PROCEDURE DepositeEvent
            ( evnt     : T_EventButt);
  BEGIN
    event := evnt;
    Notify(waitEvent);
  END DepositeEvent;
  
  BEGIN
    event := EV_DoNothing;
    InitC(waitEvent);
  END Monitor;
  
  PROCEDURE  Init_ListaLokalizacji;
  BEGIN
    SkasujWszystko(ListaLokalizacji);
    DodajDoListy(ListaLokalizacji, "* wszystkie *");
    InitListaUrzadzen(ListaLokalizacji);
  END Init_ListaLokalizacji;

VAR
  (* dane dla procesu kopiowania *)
  
  PROCEDURE ZmienOblot
            (     idx                 : INTEGER;
                  R                   : RECT;
                  KartBazy            : ARRAY OF CHAR;
                  ListaOblotow        : HLIST;
              VAR OstatniOblot        : INTEGER);
  VAR
    okVoid              : BOOLEAN;
    NazwaPlikuOpisu     : Str40;
    NazwaUrzadz         : Str99;
    OstatniaModyfikacja : Str40;

  BEGIN (* ZmienOblot *)
    IF idx < 0 THEN
      RETURN;
    END;
    IF NOT RedrawScr & (idx = OstatniOblot)
    THEN
      RETURN;
    END (* if *);

    FillRect ( R, BLUE    );
    FrameRect( R, MAGENTA );
    RedrawScr    := FALSE;
    OstatniOblot := idx;
    Idx2Str(ListaOblotow, idx, NazwaOblotu);
    okVoid := SzczegolowyPlikOpisu( KartBazy, NazwaOblotu, NazwaPlikuOpisu, 
                                    TRUE);
    GetPrivateProfileString(NazwaOblotu, "Nazwa", 
                            "", 
                            NazwaUrzadz,
                            NazwaPlikuOpisu);
    Insert(" \ ", NazwaUrzadz, MAX(CARDINAL) );
    GetPrivateProfileString(NazwaOblotu, "OstatniaModyfikacja", 
                            "", 
                            OstatniaModyfikacja,
                            NazwaPlikuOpisu);
    Insert(OstatniaModyfikacja, NazwaUrzadz, MAX(CARDINAL) );
    IF Length(NazwaUrzadz) > 3 THEN
      WrStrXY(NazwaUrzadz, R.left + 2, R.top + 2, WHITE, BLUE);
    END (* IF *);
    AssignRect( R, 0, 0, 790, 30 );
    Redraw(hDlg, R);
  END ZmienOblot;

  PROCEDURE ZmienOblotL
            (    idx : INTEGER );
  VAR
    R                   : RECT;
    
  BEGIN
    AssignRect( R, 500-470, 205, 770-470, 220 );
    ZmienOblot(idx, R, KartBazyL, ListaOblotowL, OstatniOblotL);
  END ZmienOblotL;
  
  PROCEDURE  ZmienOblotP
            (    idx : INTEGER );
  VAR
    R                   : RECT;
    
  BEGIN
    AssignRect( R, 500, 205, 770, 220 );
    ZmienOblot(idx, R, KartBazyP, ListaOblotowP, OstatniOblotP);
  END ZmienOblotP;
  
  PROCEDURE EnumOblP
            ( VAR s : ARRAY OF CHAR );

  BEGIN
    DodajDoListy(ListaOblotowP, s);
  END EnumOblP;

  PROCEDURE EnumOblL
            ( VAR s : ARRAY OF CHAR );

  BEGIN
    DodajDoListy(ListaOblotowL, s);
  END EnumOblL;

  PROCEDURE WymienPasujaceObloty
            (    idx : INTEGER );
  VAR
    Urzadzenie : Str40;

  BEGIN
    SkasujWszystko(ListaOblotowL);
    SkasujWszystko(ListaOblotowP);
    Idx2Str(ListaLokalizacji, idx, Urzadzenie);
    WymInspekcjeDlaUrz(KartBazyP, Urzadzenie, EnumOblP);
    WymInspekcjeDlaUrz(KartBazyL, Urzadzenie, EnumOblL);
    RedrawScr := TRUE;
    ZmienOblotL(0);
    RedrawScr := TRUE;
    ZmienOblotP(0);
    EnableButton( BT_KopiujInspL, LiczbaElementow(ListaOblotowL) <> 0);
    EnableButton( BT_KopiujInspP, LiczbaElementow(ListaOblotowP) <> 0);
  END WymienPasujaceObloty;
  
  PROCEDURE InspekcjaEP();
  TYPE
    T_UrzadzeniaRec = ARRAY[0..2], [0..2] OF RECT;
    
  VAR
    R             : RECT;
    b             : Button;
    kont          : BOOLEAN;
    UrzadzeniaRec : T_UrzadzeniaRec;
    WyjscieRec    : RECT;
    
    PROCEDURE Init_UrzadzeniaRec
              ( VAR  UrzadzeniaRec : T_UrzadzeniaRec;
                VAR  WyjscieRec    : RECT);
    VAR
      idxX, idxY : CARDINAL;
      szer       : CARDINAL;
    CONST
      YPocz    = 270;
      XPocz    =  30;
      XKon     = 500;
      Odstep   =  10;
      Wysokosc =  50;
      
    BEGIN
      szer := (XKon-XPocz) DIV 3;
      FOR idxX := 0 TO 2 DO
        FOR idxY := 0 TO 2  DO
          AssignRect( UrzadzeniaRec[idxX,  idxY], 
                      XPocz + szer     * idxX,
                      YPocz + Wysokosc * idxY, 
                      XPocz + szer     * (idxX +1) - Odstep, 
                      YPocz + Wysokosc * (idxY +1) - Odstep
                    );
        END (* FOR *);
      END (* FOR *);
      AssignRect( WyjscieRec, 
                  XPocz, 
                  YPocz + Wysokosc * 3, 
                  XPocz + szer     * (2 +1) - Odstep, 
                  YPocz + Wysokosc * (3 +1) - Odstep
                    );
    END Init_UrzadzeniaRec;
    
    PROCEDURE SetDefInsp;
    BEGIN
      ZmienOblotL(0);
      ZmienOblotP(0);
      SetSelection(ListaLokalizacji, 0);
    END SetDefInsp;

  BEGIN (* InspekcjaEP *)
    RedrawScr := TRUE;
    AssignRect(R, 0, 0, 800, 600 - 17);
    hDlg := TworzDialog(R, "insp.dib", FALSE);
    SetPaletteEntry( GetDialogDIBHandle( hDlg ), 2, 65, 255, 65 );
    
    (* Przyciski urzadzen *)
    Init_UrzadzeniaRec( UrzadzeniaRec, WyjscieRec );
    WstawButton( hDlg, UrzadzeniaRec[ 0, 0], "VOR",     0, ShortCuts.kbAltV,  
                 BP_VOR, b);
    WstawButton( hDlg, UrzadzeniaRec[ 0, 1], "TRS",     0, ShortCuts.kbAltT,  
                 BP_TRS, b);
    WstawButton( hDlg, UrzadzeniaRec[ 0, 2], "ARCH C:", 5, ShortCuts.kbAltC, 
                 BP_ArchA, b);
    WstawButton( hDlg, UrzadzeniaRec[ 1, 0], "LOC",     0, ShortCuts.kbAltL,  
                 BP_LOC, b);
    WstawButton( hDlg, UrzadzeniaRec[ 1, 1], "GS",      0, ShortCuts.kbAltG,  
                 BP_GS, b);
    WstawButton( hDlg, UrzadzeniaRec[ 1, 2], "ARCH D:", 5, ShortCuts.kbAltD, 
                 BP_ArchC, b);
    WstawButton( hDlg, UrzadzeniaRec[ 2, 0], "ADF",     2, ShortCuts.kbAltF,  
                 BP_ADF, b);
    WstawButton( hDlg, UrzadzeniaRec[ 2, 1], "VHF",     1, ShortCuts.kbAltH,  
                 BP_VHF, b);
    WstawButton( hDlg, UrzadzeniaRec[ 2, 2], "ARCH E:", 5, ShortCuts.kbAltE, 
                 BP_ArchE, b);

    (* Listy dialogowe *)
    AssignRect(R, 500,     100, 770,    200);
    Wr2fStrXY(' INSPEKCJE ', 500, 40, WHITE, BLUE);
    ListaOblotowP := WstawListe(hDlg, R, FALSE);
    SetNotificationProc(ListaOblotowP, ZmienOblotP);
    Sortowana(ListaOblotowP, FALSE);

    AssignRect(R, 500-470, 100, 770-470, 200);
    Wr2fStrXY(' INSPEKCJE ARCHIWUM', 500-470, 40, WHITE, BLUE);
    ListaOblotowL := WstawListe(hDlg, R, FALSE);
    SetNotificationProc(ListaOblotowL, ZmienOblotL);
    Sortowana(ListaOblotowL, FALSE);
    AssignRect(archLocStrLocBox, 500-470, 100-18, 770-470,100-3);
    AssignRect(statStrBox, 500-470, 510, 770, 510 + 3 * WysokoscLiniiTxt + 4);
    
    AssignRect(R, 320, 100, 480, 140);
    WstawButton(hDlg, R, " < < < ", 1, ShortCuts.kbCtrlLeft, 
                BP_KopiujInspP, BT_KopiujInspP);
    MoveRect(R, 0, 50);
    WstawButton(hDlg, R, " > > > ", 1, ShortCuts.kbCtrlRight, 
                BP_KopiujInspL, BT_KopiujInspL);

    AssignRect(R, 500, 310, 770, 500);
    Wr2fStrXY(' LOKALIZACJE ', 500, 270, WHITE, BLUE);
    ListaLokalizacji := WstawListe(hDlg, R, FALSE);
    Sortowana(ListaLokalizacji, FALSE);
    SetNotificationProc(ListaLokalizacji, WymienPasujaceObloty);

    AssignRect(R, 500,     223, 770,     258);
    WstawButton(hDlg, R, "SKASUJ INSPEKCJ®", 0, ShortCuts.kbAltS, 
                BP_UsunOblotP, b );
    AssignRect(R, 500-470, 223, 770-470, 258);
    WstawButton(hDlg, R, "SKASUJ INSPEKCJ®", 1, ShortCuts.kbAltK, 
                BP_UsunOblotL, b );
    AssignRect(R, 30, 530, 770-470, 580);
    WstawButton(hDlg, WyjscieRec, "WYJDç", 0, ShortCuts.kbAltW,  BP_OblotOK, b);
    MoveRect(WyjscieRec, 0, 500);
    WstawButton(hDlg, WyjscieRec, "", -1,     ShortCuts.kbEnter, BP_OblotOK, b);
    BP_ArchE;
    SetDefInsp;
    RedrawScr := FALSE;
    kont := Go(hDlg);
    UsunDialog( hDlg );
    RETURN ;
  END InspekcjaEP;

  PROCEDURE  EventHandler;

  PROCEDURE  KopiujInspProcess
             ( VAR ListaOblotow : HLIST;
                   ZPnaL        : BOOLEAN);
  VAR
    poz       : INTEGER;
    ok        : BOOLEAN;
    inspekcja : Str40;
    info      : Str99;
    
  BEGIN
    poz := GetSelection(ListaOblotow);
    Idx2Str( ListaOblotow, poz, inspekcja);
    ConstAssign("Chcesz skopiowac: ", info);
    Insert(inspekcja, info, MAX(CARDINAL) );
    Insert("?",       info, MAX(CARDINAL) );
    IF NOT MsgBox.Info(info)
    THEN
      (* MsgBox odblokowujw wszystkie klawisze ?! *)
      EnableButton( BT_KopiujInspL, LiczbaElementow(ListaOblotowL) <> 0);
      EnableButton( BT_KopiujInspP, LiczbaElementow(ListaOblotowP) <> 0);
      RETURN;
    END (* if *);
    EnableDlg(hDlg, FALSE);
    FillRect ( statStrBox, BLUE);
    FrameRect( statStrBox, MAGENTA);
    IF ZPnaL  THEN
      ok := KopiujInspekcje(KartBazyP, KartBazyL, inspekcja)
    ELSE
      ok := KopiujInspekcje(KartBazyL, KartBazyP, inspekcja)
    END (* IF *);
    Redraw(hDlg, statStrBox);
    IF  NOT ok THEN
      MsgBox.Warn("Wystapiày bà©dy przy kopiowaniu inspekcji");
    ELSE
      MsgBox.Warn("Inspekcja skopiowana pomyòlnie");
    END (* IF *);
    (* MsgBox odblokowujw wszystkie klawisze ?! *)
    EnableButton( BT_KopiujInspL, LiczbaElementow(ListaOblotowL) <> 0);
    EnableButton( BT_KopiujInspP, LiczbaElementow(ListaOblotowP) <> 0);
    Init_ListaLokalizacji;
  END KopiujInspProcess;
  
  PROCEDURE UsunOblot
            ( VAR ListaOblotow : HLIST;
                  ZPnaL        : BOOLEAN);
  VAR
    poz : INTEGER;
    s   : Str40;
    res : BOOLEAN;
    
  BEGIN
    IF NOT MsgBox.Info("Jesteò pewien, æe chcesz usun•Ü inspekcj©?")
    THEN
      (* MsgBox odblokowujw wszystkie klawisze ?! *)
      EnableButton( BT_KopiujInspL, LiczbaElementow(ListaOblotowL) <> 0);
      EnableButton( BT_KopiujInspP, LiczbaElementow(ListaOblotowP) <> 0);
      RETURN;
    END (* if *);
    IF NOT MsgBox.Info("Inspekcja zostanie usuni©ta...")
    THEN
      (* MsgBox odblokuj wszystkie klawisze ?! *)
      EnableButton( BT_KopiujInspL, LiczbaElementow(ListaOblotowL) <> 0);
      EnableButton( BT_KopiujInspP, LiczbaElementow(ListaOblotowP) <> 0);
      RETURN;
    END (* if *);
    poz := GetSelection( ListaOblotow );
    Idx2Str( ListaOblotow, poz, s );
    IF ZPnaL THEN
      res := SkasujInspekcje( KartBazyP, s);
    ELSE
      res := SkasujInspekcje( KartBazyL, s);
    END (* IF *);
    Skasuj(ListaOblotow, poz);
    SetSelection(ListaOblotow, 0);
    IF res  THEN
      MsgBox.Warn("Inspekcja usuni©ta pomyòlnie");
    ELSE
      MsgBox.Warn("Wyst•piày problemy z usuni©ciem inspekcji !!");
    END (* IF *);
  END UsunOblot;

  BEGIN (* EventHandler *)
    LOOP 
      CASE GetEvent() OF
         EV_CopyL:
         IF IsBusy( hDlg ) OR (LiczbaElementow(ListaOblotowL) = 0) THEN
           EnableButton( BT_KopiujInspL, LiczbaElementow(ListaOblotowL) <> 0);
         ELSE
           EnableDlg(hDlg, FALSE);
           KopiujInspProcess( ListaOblotowL, FALSE );
         END;

      |  EV_CopyR:
         IF IsBusy( hDlg ) OR ( LiczbaElementow(ListaOblotowP) = 0 ) THEN
           EnableButton( BT_KopiujInspP, LiczbaElementow(ListaOblotowP) <> 0);
         ELSE
           EnableDlg(hDlg, FALSE);
           KopiujInspProcess( ListaOblotowP, TRUE );
         END;
      
      |  EV_DeleteR:
         IF NOT IsBusy( hDlg ) THEN
           EnableDlg(hDlg, FALSE);
           UsunOblot(ListaOblotowP, TRUE);
         END;

      |  EV_DeleteL:
         IF NOT IsBusy( hDlg ) THEN
           EnableDlg(hDlg, FALSE);
           UsunOblot( ListaOblotowL, FALSE );
         END;
      
      |  EV_DoNothing:
      
      END (* CASE *);
    END (* loop *);
  END EventHandler;

BEGIN (* InspMng *)
  Stat_Size_Monitor := Insp_Stat_Size_Monitor;
  Stat_File_Monitor := Insp_Stat_File_Monitor;
  StartInspection(Insp_LOC);
  ConstAssign(KartDomyslna,   KartBazyP);
  OstatniOblotL := MAX(INTEGER);
  OstatniOblotP := MAX(INTEGER);
  STARTPROCESS(EventHandler, 4000H, TInOneSecond() DIV 5);
END InspMng.
