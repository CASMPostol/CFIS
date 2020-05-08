
MODULE TstButo2;

  IMPORT
    DebugPMD;

  FROM Terminal IMPORT
    Read;

  FROM GrafTypes IMPORT
    RECT;

  FROM Buttons IMPORT
    Button, CreateButton, DisposeButton;

  FROM ShortCuts IMPORT
    kbAltT;

  FROM MANAGER IMPORT
    Condition, InitC;

  FROM RTSMain IMPORT
    Terminate, Status;

  FROM GrafUtil IMPORT
    Info, InfoBeep;

  VAR
    switched : BOOLEAN;

  PROCEDURE OK;

  BEGIN
    InfoBeep(" Nacisniety", 3, 1500);
    (* switched := TRUE; *)
  END OK;

  PROCEDURE Process;
  TYPE
    butonNum = [0..10];
  VAR
    r  : RECT;
    b  : ARRAY butonNum  OF Button;
    
    PROCEDURE CreateButons;
    VAR
      shortcut: CARDINAL;
      idx     : butonNum;
    BEGIN
      r.left := 100;
      r.right := 300;
      r.top := 10;
      r.bottom := r.top+ 20;
      shortcut := kbAltT;
      FOR idx := MIN(butonNum) TO MAX(butonNum) DO
        b[idx] := CreateButton(r, "To jest test", 0, shortcut, OK);
        WITH r DO
          top := bottom + 10;
          bottom := r.top+ 20;
        END (* with *);
        INC(shortcut);
      END;
    END CreateButons;

    PROCEDURE DisposeButtons;
    VAR
      idx     : butonNum;
    BEGIN
      FOR idx := MAX(butonNum) TO MIN(butonNum) BY -1 DO
        DisposeButton(b[idx]);
      END;
    END DisposeButtons;
    
  BEGIN
    CreateButons;
    switched := FALSE;
    LOOP
      IF switched
      THEN
        DisposeButtons;
        switched := FALSE;
        CreateButons;
      END (* if switched *);
    END (* loop *);
    Terminate(Stopped);
  END Process;

BEGIN
  Process;
END TstButo2.
