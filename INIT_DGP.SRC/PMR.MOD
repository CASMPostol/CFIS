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
|
|  Copyright (C), CAS LODZ POLAND.
|  TEL: 42' 862 547, 42' 87 80 44 FAX/TEL: 42' 84 48 40
|
**********************************************************************)
(*.F+ *)
MODULE PMR;
  
  IMPORT DebugPMD, DOSEntry, MANAGER, ErrorMess, ShortCuts, CocpDsp, 
         GrafUtil;

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
    InstPrologueHnd, Template, PrintScreen, BreakChain;

  FROM SYSTEM IMPORT
    ADDRESS, ADR;
    
  VAR
    lastComand : CARDINAL;
    
  PROCEDURE  BdPROC;
  BEGIN
   lastComand := 2;
  END BdPROC;
  
    PROCEDURE  ServicePROC;
    BEGIN
      lastComand := 3;
    END ServicePROC;

  PROCEDURE  DGPS_PROC;
  BEGIN
   lastComand := 4;
  END DGPS_PROC ;
  
    PROCEDURE  EnterPROC;
    BEGIN
      EndDialog( TRUE );
    END EnterPROC;
    
    
  PROCEDURE InitScreen;
    
  VAR
    butons   : ARRAY[0..3], [0..3] OF RECT;
    screen   : RECT;
    row      : CARDINAL;
    col      : CARDINAL;
    butt     : Button;
    scrHhDlg : HDLG;
    
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
    WITH butons[3, 0]  DO
      left  := 10;
      top   := 530;
      right := 400;
      bottom:= 580;
    END;


    WstawRadioButton( scrHhDlg, butons[1, 1], "DGPS ST_REF",  0, 
                      ShortCuts.kbAltD, DGPS_PROC, butt );
    WstawRadioButton( scrHhDlg, butons[2, 1], "BAZA DANYCH", 0, 
                      ShortCuts.kbAltB, BdPROC, butt );
    WstawRadioButton( scrHhDlg, butons[1, 2], "SERVICE",     0, 
                      ShortCuts.kbAltS, ServicePROC, butt );
    WstawRadioButton( scrHhDlg, butons[2, 2], "W Y K O N A J",  0, 
                      ShortCuts.kbEnter, EnterPROC, butt );

    IF NOT Go(scrHhDlg) THEN
      lastComand := 0;
    END;
    UsunDialog( scrHhDlg );
  END InitScreen;
  

  PROCEDURE PrintScreenProc( a : ADDRESS );
    BEGIN
      GrafUtil.Info( 'Nie tˆucz w klawisze bez sensu!!!');
      BreakChain;
    END PrintScreenProc;

VAR
  Tmpl : Template;

BEGIN
  lastComand := 0;
  InstPrologueHnd( PrintScreen, ADR(Tmpl), PrintScreenProc, NIL );
  InitScreen;
  SetErrorCode(lastComand);
  ExitToOS;
END PMR.
