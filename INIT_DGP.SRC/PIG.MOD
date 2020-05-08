(*.F- *)
(**********************************************************************
|  Title   : Program inicjacji stacji referencyjnej
|  Author  : 
|  System  : LOGITECH MODULA-2/86
|  History :
|  Rel. 001 21.01.1998: new
|
|  Copyright (C), CAS LODZ POLAND.
|  TEL: 42' 86 58 12, 42' 87 80 44 FAX/TEL: 42' 84 48 40
|
**********************************************************************)
(*.F+ *)
MODULE PK;

  FROM SoftIntHandlingManager IMPORT
    InstPrologueHnd, Template, PrintScreen, BreakChain;

  FROM SYSTEM IMPORT
    ADDRESS, ADR;

  FROM GrafUtil IMPORT
    Info;

  FROM Dialog IMPORT
    HDLG, TworzDialog, UsunDialog, WstawListe, Go, WstawButton, EndDialog, 
    AltF4;

  FROM GList IMPORT
    HLIST, DodajDoListy, GetSelection, SetSelection, SetContents, GetContents,
    HCONTENT, KillContents;

  FROM Buttons IMPORT
    Button;
  
  FROM GrafTypes IMPORT
    WHITE, BLACK, BLUE, GREEN, RECT, AssignRect, MoveRect;

  FROM HiLevGraf IMPORT
    FillRect;

  FROM ShortCuts IMPORT
    kbAltA, kbAltM, kbAltK, kbEnter, kbF1, kbF2, kbF3, kbF4, kbF5, kbF6, 
    kbAltW, kbAltO, kbAltF4;

  FROM DGHInterface IMPORT
    DtaSignType, TurnOn, TurnOff, WaitForNewData, GetBinaryVal;

  IMPORT 
   MANAGER,PI_PA;

  FROM V_Oblot IMPORT
    (* PROCEDURE *) InitOblot, Zapisz;

  VAR
    ScreenR        : RECT;


  PROCEDURE OkP;

  BEGIN
    EndDialog(TRUE);
  END OkP;



    PROCEDURE GlowneMenu;

  TYPE
    inspekcjaEvent =
      ( abortIE,
        AkceptIE );

    MainStates     =
      ( GlownyMS,
        KoniecProgMS );


    State =
      ( LOCMenu,
        GSMenu,
        VORMenu,
        ADFMenu,
        VHFMenu);
  VAR
    hDlg      : HDLG;
    currState : State;
    c1        : HCONTENT;
    but       : Button;
    firsTime  : BOOLEAN;
    R         : RECT;
    l1        : HLIST;

    mainState     : ARRAY BOOLEAN OF MainStates;
    Zestaw        : BOOLEAN;
    

  PROCEDURE InspekcjaEP() : inspekcjaEvent;

  BEGIN
    IF InitOblot(  )
    THEN
      RETURN AkceptIE;
    ELSE
      RETURN abortIE;
    END (* if InitOblot *);
  END InspekcjaEP;


  PROCEDURE DoLOCMenu;
  BEGIN
  ;
  END DoLOCMenu;
  
  PROCEDURE DoGSMenu;
  BEGIN
  ;
  END DoGSMenu;

  PROCEDURE DoVORMenu;
  BEGIN
        CASE InspekcjaEP() OF
          abortIE :
            mainState[Zestaw] := KoniecProgMS;
          |
          AkceptIE :
            mainState[Zestaw] := GlownyMS;
        END (* case InspekcjaEP *);
  END DoVORMenu;

  PROCEDURE DoADFMenu;
  BEGIN
  ;
  END DoADFMenu;

  PROCEDURE DoVHFMenu;
  BEGIN
  ;
  END DoVHFMenu;

  BEGIN (* GlowneMenu *)
    currState := LOCMenu;
    firsTime := TRUE;
    LOOP
      FillRect(ScreenR, BLACK);
      AssignRect(R, 0, 0, 800, 600);
      hDlg := TworzDialog(R, "pk.bmp", FALSE);
      AssignRect(R, 50, 150, 400, 400);
      l1 := WstawListe(hDlg, R, FALSE);
      KillContents(l1, FALSE);
      AssignRect(R, 50, 420, 400, 470);
      WstawButton(hDlg, R, "WYJSCIE", 0, kbAltW, AltF4, but);
      MoveRect(R, 0, 70);
      WstawButton(hDlg, R, "OK", 0, kbAltO, OkP, but);
      Info("Wybierz urz¥dzenie gdzie bedzie zainstalowana stacja referencyjna");
      IF firsTime
      THEN
        DodajDoListy(l1, "LOC");
        DodajDoListy(l1, "GS");
        DodajDoListy(l1, "VOR");
        DodajDoListy(l1, "ADF");
        DodajDoListy(l1, "VHF");
        c1 := GetContents(l1);
      ELSE
        SetContents(l1, c1);
      END (* if firsTime *);
      firsTime := FALSE;
      SetSelection(l1, ORD(currState));
      IF Go(hDlg)
      THEN
        currState := VAL(State, GetSelection(l1));
      ELSE
        UsunDialog(hDlg);
        EXIT;
      END (* if ok *);
      UsunDialog(hDlg);
      CASE currState OF
        LOCMenu :
          DoLOCMenu();
        |
        GSMenu :
          DoGSMenu();
        | 
        VORMenu :
          DoVORMenu();
        |
                |
        ADFMenu :
          DoADFMenu();
        |
        VHFMenu :
          DoVHFMenu();
      END (* case currState *);
    END (* loop *);
  END GlowneMenu;

  
  PROCEDURE PrintScreenProc( a : ADDRESS );
    BEGIN
      Info( 'Nie tˆucz w klawisze bez sensu!!!');
      BreakChain;
    END PrintScreenProc;

VAR
  Tmpl : Template;

BEGIN
  MANAGER.Assert( NOT PI_PA.PomiarANieArchiwum );  
  InstPrologueHnd( PrintScreen, ADR(Tmpl), PrintScreenProc, NIL );
  (*Init;*)
  GlowneMenu;
  (*RTSMain.Terminate(RTSMain.Normal);*)
END PK.
