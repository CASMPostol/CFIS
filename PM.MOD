(*.F- *)
(**********************************************************************
|  Title   : Pomiar urzadzen nawigacyjnych - Program Glowny 
|  Author  : Mariusz Postol
|  System  : LOGITECH MODULA-2/86 
|  History :
|    12-01-95:
|      zmieniono nazwe z main.mod na pm
|    05-02-97:
|      blokada PrtScr
|    Rel.3.11: MPostol
|      Wprowadzono nowa funkcje inpekcji
|      ReInitialize na niektorych komputerach zwraca FALSE-wywalilem 
|      asercje
|
|  Copyright (C), CAS LODZ POLAND.
|  TEL: 42' 862 547, 42' 87 80 44 FAX/TEL: 42' 84 48 40
|
**********************************************************************)
(*.F+ *)
MODULE PM;
  
 IMPORT DebugPMD, DOSEntry, MANAGER, ErrorMess, ShortCuts, CocpDsp, 
        GrafUtil, PrintScreen, SoftIntHandlingManager;

 FROM GrafTypes IMPORT
    RECT, POINT, AssignPoint, AssignRect, MoveRect, WHITE, LT_RED,
    BLUE, GREEN, BLACK, YELLOW, MAGENTA, RED, CYAN;

 FROM ErrorCode IMPORT
    SetErrorCode, ExitToOS;
  
  FROM Dialog IMPORT
    TworzDialog, WstawRadioButton, AltF4, Go, UsunDialog, EndDialog, HDLG; 
  
  FROM Buttons IMPORT
    Button;

  FROM SoftIntHandlingManager IMPORT
    InstPrologueHnd, Template, BreakChain;

  FROM SYSTEM IMPORT
    ADDRESS, ADR;
    
  FROM MANAGER IMPORT
    Assert, STARTPROCESS;
 
  FROM ARINC IMPORT 
    ReInitialize;  
  
  FROM InspMng IMPORT
    InspekcjaEP;

  FROM Timer IMPORT
    Wait, TInOneSecond;
  VAR
    lastComand : CARDINAL;
    
  PROCEDURE  BdPROC;
  BEGIN
   lastComand := 2;
  END BdPROC;
  
  PROCEDURE PlPROC;
  BEGIN
   lastComand := 3;
  END PlPROC;

  PROCEDURE  PgPROC;
  BEGIN
   lastComand := 4;
  END PgPROC;
  
  PROCEDURE  PvPROC;
  BEGIN
   lastComand := 5;
  END PvPROC;

  PROCEDURE PnPROC;
  BEGIN
   lastComand := 6;
  END PnPROC;
  
  PROCEDURE  PhPROC;
  BEGIN
   lastComand := 7;
  END PhPROC;
  
  PROCEDURE  ServicePROC;
  BEGIN
    lastComand := 8;
  END ServicePROC;

  PROCEDURE  KlPROC;
  BEGIN
   lastComand := 9;
  END KlPROC;
  
    PROCEDURE  VORA_PROC;
    BEGIN
      lastComand := 10;
    END VORA_PROC;
    
    PROCEDURE  LOCA_PROC;
    BEGIN
      lastComand := 11;
    END LOCA_PROC;
    
    PROCEDURE  GSA_PROC;
    BEGIN
      lastComand := 12;
    END GSA_PROC;
    
    PROCEDURE  VORT_PROC;
    BEGIN
      lastComand := 13;
    END VORT_PROC;
    
    PROCEDURE  VORTA_PROC;
    BEGIN
      lastComand := 14;
    END VORTA_PROC;
    
  PROCEDURE  PhAPROC;
  BEGIN
   lastComand := 15;
  END PhAPROC;
  
  PROCEDURE PnAPROC;
  BEGIN
   lastComand := 16;
  END PnAPROC;
  
  PROCEDURE  InspekcjePROC;
  BEGIN
    lastComand := 17;
  END InspekcjePROC;

  PROCEDURE  EnterPROC;
  BEGIN
    EndDialog( TRUE );
  END EnterPROC;
    
  PROCEDURE InitScreen;
    
  VAR
    butons       : ARRAY[0..3], [0..3] OF RECT;
    wykonajButon : RECT;
    screen       : RECT;
    row          : CARDINAL;
    col          : CARDINAL;
    butt         : Button;
    scrHhDlg     : HDLG;
    
  BEGIN
    AssignRect( screen, 0, 0, 800, 600);
    scrHhDlg := TworzDialog( screen, "main.dib", FALSE );
    WITH butons[0, 0]  DO
      left  := 10;
      top   := 290;
      right := 190;
      bottom:= 340;
    END;
    FOR row := 0 TO 3 DO
      FOR col := 0 TO 3 DO
        butons[row,  col] := butons[0,  0];
        MoveRect(butons[row,  col], row*200, col*60);
      END;
    END;
    WITH wykonajButon  DO
      left  := 10;
      top   := 530;
      right := 400;
      bottom:= 580;
    END;

    WstawRadioButton( scrHhDlg, butons[0, 0], "KALIBRACJA",  0, 
                      ShortCuts.kbAltK, KlPROC, butt );
    WstawRadioButton( scrHhDlg, butons[1, 0], "BAZA DANYCH", 0, 
                      ShortCuts.kbAltB, BdPROC, butt );
    WstawRadioButton( scrHhDlg, butons[2, 0], "SERVICE",     0, 
                      ShortCuts.kbAltS, ServicePROC, butt );
    WstawRadioButton( scrHhDlg, butons[3, 0], "INSPEKCJE",  0, 
                      ShortCuts.kbAltI, InspekcjePROC, butt );

    WstawRadioButton( scrHhDlg, butons[0, 1], "V O R",       0, 
                      ShortCuts.kbAltV, PvPROC, butt );
    WstawRadioButton( scrHhDlg, butons[1, 1], "V O R TRS", 4,
                      ShortCuts.kbAltR, VORT_PROC, butt );
    WstawRadioButton( scrHhDlg, butons[2, 1], "V O R ARCH", 0, 
                      ShortCuts.kbCtrlV, VORA_PROC, butt );
    WstawRadioButton( scrHhDlg, butons[3, 1], "V O R TRS ARCH", 4,
                      ShortCuts.kbCtrlR, VORTA_PROC, butt );

    WstawRadioButton( scrHhDlg, butons[0, 2], "L O C",       0, 
                      ShortCuts.kbAltL, PlPROC, butt );
    WstawRadioButton( scrHhDlg, butons[1, 2], "G S",         0, 
                      ShortCuts.kbAltG, PgPROC, butt );
    WstawRadioButton( scrHhDlg, butons[2, 2], "L O C ARCH", 0, 
                      ShortCuts.kbCtrlL, LOCA_PROC, butt );
    WstawRadioButton( scrHhDlg, butons[3, 2], "G S ARCH", 0, 
                      ShortCuts.kbCtrlG, GSA_PROC, butt );

    WstawRadioButton( scrHhDlg, butons[0, 3], "V H F",       2, 
                      ShortCuts.kbAltH, PhPROC, butt ); (* "V H F" *)
    WstawRadioButton( scrHhDlg, butons[1, 3], "N D B",       0, 
                      ShortCuts.kbAltN, PnPROC, butt );(* "N D B" *)
    WstawRadioButton( scrHhDlg, butons[2, 3], "V H F ARCH",       2, 
                      ShortCuts.kbCtrlH, PhAPROC, butt ); (* "V H F" *)
    WstawRadioButton( scrHhDlg, butons[3, 3], "N D B ARCH",       0, 
                      ShortCuts.kbCtrlN, PnAPROC, butt );(* "N D B" *)

    WstawRadioButton( scrHhDlg, wykonajButon, "W Y K O N A J",  -1, 
                      ShortCuts.kbEnter, EnterPROC, butt );

    IF NOT Go(scrHhDlg) THEN
      lastComand := 0;
    END;
    UsunDialog( scrHhDlg );
  END InitScreen;
  
 PROCEDURE PrintScreenProc( a : ADDRESS );
 BEGIN
   BreakChain;
 END PrintScreenProc;
 
PROCEDURE  Process;
BEGIN
  LOOP 
    InitScreen;
    IF lastComand = 17 THEN
      InspekcjaEP;
    ELSE
      EXIT
    END (* IF *);
  END (* loop *);
  running := FALSE;
END Process;

VAR
  Tmpl    : Template;
  running : BOOLEAN;
  voitB   : BOOLEAN;
  
BEGIN
  voitB := ReInitialize();
  lastComand := 0;
  InstPrologueHnd( SoftIntHandlingManager.PrintScreen, ADR(Tmpl), 
                   PrintScreenProc, NIL );
  Process;
  (*
  STARTPROCESS( Process, 2000H, 0);
  running := TRUE;
  WHILE running   DO
    Wait(TInOneSecond());
  END;
  *)
  SetErrorCode(lastComand);
  ExitToOS;
END PM.
