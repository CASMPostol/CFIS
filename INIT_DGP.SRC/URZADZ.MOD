(**********************************************************************
|  Title   : Wybor urzadzenia
|  Author  :
|  System  : LOGITECH MODULA-2/86
|  History :
|  Copyright (C), CAS LODZ POLAND.
|  TEL: 42' 86 58 12, 42' 87 80 44 FAX/TEL: 42' 84 48 40
|
**********************************************************************)
(*.F+ *)

IMPLEMENTATION MODULE URZadz;

FROM TypDanych IMPORT
    MainStates,TypUrzadzenia,ParametryUrzadzenia;
    

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

  PROCEDURE OkP;

  BEGIN
    EndDialog(TRUE);
  END OkP;


PROCEDURE  Urzadzenie (VAR TypUrz          :TypUrzadzenia;
                       VAR ZwracanyKlawisz :MainStates
                       );
                       
                       


     PROCEDURE GlowneMenu;
           
     TYPE

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
    ScreenR        : RECT;
    ParametryURZ  :ParametryUrzadzenia;
    



    
            BEGIN (* GlowneMenu *)
    currState := LOCMenu;
    firsTime := TRUE;
    LOOP
      FillRect(ScreenR, BLACK);
      AssignRect(R, 0, 0, 800, 600);
      hDlg := TworzDialog(R, "pk.bmp", FALSE);
      AssignRect(R, 50, 150, 100, 250);
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
      SetSelection(l1, ORD(TypUrz));
      
      IF Go(hDlg)
      THEN
        currState := VAL(State, GetSelection(l1));
        CASE currState OF
        LOCMenu :
          TypUrz:=LOC;
       |
        GSMenu :
          TypUrz:=GS;
       | 
        VORMenu :
       
          TypUrz:=VOR;
                |
        ADFMenu :
          TypUrz:=ADF;
       |
        VHFMenu :
          TypUrz:=VHF;
      END (* case currState *);
        ZwracanyKlawisz:=PolozenieMS;
        RETURN;
      ELSE
        UsunDialog(hDlg);
        ZwracanyKlawisz:= KoniecMS;
        RETURN;
      END (* if ok *);
      
      UsunDialog(hDlg);
     END (* loop *);
    RETURN;
  END GlowneMenu;

          
           BEGIN
            (* inicjacja zmiennych *)
            (*TypUrz:=LOC;*)
            ZwracanyKlawisz:=KoniecMS;
            GlowneMenu;
           END Urzadzenie;
END URZadz.
