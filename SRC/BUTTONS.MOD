(*.F- *)
(**********************************************************************
|  Title   : Buttons mamangement procedures
|  Author  : M.Morawski
|  System  : LOGITECH MODULA-2/86
|  History :
|    24-09-96: M.Postol
|      VAR dodatny w KillButton by zwrocic NIL
|    09-28-96 07:48pm: MM
|      Bylo popierniczone z obsluga eventow od myszy
|    12-04-96 09:59am MM:
|      Dolozona procedura blokujace wszystkie butony
|
|  Copyright (C), CAS LODZ POLAND.
|  TEL: 42' 862 547, 42' 87 80 44 FAX/TEL: 42' 84 48 40
|
**********************************************************************)
(*.F+ *)

IMPLEMENTATION MODULE Buttons;

  IMPORT MANAGER;

  FROM MANAGER IMPORT
    SIGNAL, InitS, Assert;

  FROM GrafTypes IMPORT
    RECT;

  FROM MMMouse IMPORT
    EventSet, Event, ButtonSet, RegisterRegion, UnregisterRegion, Region,
    ShowCursor, HideConditionally;

  IMPORT
    MMMouse;

  FROM Storage IMPORT
    ALLOCATE, DEALLOCATE;

  FROM Strings IMPORT
    Assign, Length;

  FROM Graphics IMPORT
    SetBank, GetBank;

  FROM HiLevGraf IMPORT
    FillRect, LineS, WrStrXY;

  FROM GrafTypes IMPORT
    WHITE, BLACK, GREY, LT_GREY, YELLOW, GREEN, RED, LT_RED;

  FROM ShortCuts IMPORT
    DefineShortCut, DeleteShortCut;

  FROM SYSTEM IMPORT
    ADDRESS;

  CONST
    Alive = 31415;
    Dead  = 27182;

  TYPE
    Button     =
      POINTER TO ButtonDesc;
    ButtonDesc =
      RECORD
        Rect        :
          RECT;
        ShortCut    :
          CARDINAL;
        Reg         :
          Region;
        Text        :
          ARRAY [0 .. 31] OF CHAR;
        Highlighted :
          INTEGER;
        Pressed     :
          BOOLEAN;
        Enabled     :
          BOOLEAN;
        busy   :
          BOOLEAN;
        waiting  :
          SIGNAL;
        CASE Radio : BOOLEAN OF
          FALSE :
            ButtonPROC  : PROC;
          |
          TRUE :
            RButtonProc : RadioButtonProc;
        END;
        Active      :
          CARDINAL;
        Next        :
          Button;
      END;

  VAR
    KbdButton : Button;
    AllEnabled : BOOLEAN;

  MODULE MONITOR [ 0 ];

    IMPORT
      Button, Alive, Region, MMMouse;

    FROM MANAGER IMPORT
      Assert, WAITS, SEND;

    EXPORT
      Insert, RemoveToKill, MarkBut, FindAMark, Unmark;

    VAR
      ButtonList : Button;

    PROCEDURE Insert
              (    butt : Button );

    BEGIN
      WITH butt^ DO
        Next := ButtonList;
        ButtonList := butt;
      END (* with butt *);
    END Insert;

    PROCEDURE RemoveToKill
              (    but : Button );

    PROCEDURE Remove
              (    but : Button );
    VAR
      t : Button;

    BEGIN
      Assert(but^.Active = Alive);
      IF ButtonList = but
      THEN
        ButtonList := ButtonList^.Next;
        IF ButtonList <> NIL  THEN
          Assert(ButtonList^.Active = Alive);
        END;
      ELSE
        t := ButtonList;
        WITH but^  DO
          WHILE (t^.Next # but) AND (t^.Next <> NIL) DO
            t := t^.Next;
            Assert(t^.Active = Alive);
          END (* while *);
          IF t^.Next <> NIL
          THEN
            t^.Next := Next;
          END (* if t *);
        END;
      END (* if ButtonList *);
    END Remove;

    BEGIN
      Remove(but);
      WITH but^ DO
        IF busy
        THEN
          WAITS(waiting);
        END (* if removable *);
        busy := TRUE;
      END (* with but *);
    END RemoveToKill;

    PROCEDURE FindAMark (VAR but: Button): BOOLEAN;
    VAR
      reg : Region;

    BEGIN
      reg := MMMouse.GetRegion();
      but := ButtonList;
      WHILE (but # NIL) & (but^.Reg # reg) DO
        Assert(but^.Active = Alive);
        but := but^.Next;
      END (* while *);
      IF but = NIL  THEN
        RETURN FALSE;
      ELSIF NOT but^.busy THEN
        but^.busy := TRUE;
        RETURN TRUE
      ELSE
        RETURN FALSE;
      END;
    END FindAMark;

    PROCEDURE MarkBut ( but: Button): BOOLEAN;
    BEGIN
      IF but = NIL  THEN
        RETURN FALSE;
      END;
      Assert(but^.Active = Alive);
      IF NOT but^.busy THEN
        but^.busy := TRUE;
        RETURN TRUE
      ELSE
        RETURN FALSE;
      END;
    END MarkBut;

    PROCEDURE Unmark( but: Button);
    BEGIN
      Assert(but^.Active = Alive);
      WITH but^  DO
        busy := FALSE;
        SEND(waiting);
      END;
    END Unmark;

  BEGIN
    ButtonList := NIL;
  END MONITOR;

  PROCEDURE DrawInter
            (    but : Button );
  VAR
    r : RECT;
    x,
    y : INTEGER;
    h : BOOLEAN;
    p : CARDINAL;

    PROCEDURE Dec;

    BEGIN
      INC(r.left);
      INC(r.top);
      DEC(r.right);
      DEC(r.bottom);
    END Dec;
  VAR
    shft : INTEGER;

  BEGIN
    shft := 0;
    WITH but^ DO
      h := HideConditionally(Rect);
      p := GetBank();
      r := Rect;
      Dec;
      IF NOT Pressed
      THEN
        FillRect(r, LT_GREY);
        shft := 1;
        FOR x := 0 TO 2 DO
          LineS(r.left, r.top, r.right, r.top, WHITE, BITSET {0..15});
          LineS(r.left, r.top, r.left, r.bottom, WHITE, BITSET {0..15});
          LineS(r.right, r.bottom, r.left, r.bottom, GREY, BITSET {0..15});
          LineS(r.right, r.top, r.right, r.bottom, GREY, BITSET {0..15});
          Dec;
        END (* for x *);
      ELSE
        FillRect(r, LT_RED);
        shft := 1;
        FOR x := 0 TO 2 DO
          LineS(r.left, r.top, r.right, r.top, GREY, BITSET {0..15});
          LineS(r.left, r.top, r.left, r.bottom, GREY, BITSET {0..15});
          LineS(r.right, r.bottom, r.left, r.bottom, WHITE, BITSET {0..15});
          LineS(r.right, r.top, r.right, r.bottom, WHITE, BITSET {0..15});
          Dec;
        END (* for x *);
      END (* if *);
      x := (Length(Text) * 8) DIV 2;   (* srodek tekstu *)
      x := (Rect.right + Rect.left - 1) DIV 2 - x + shft;
      y := (Rect.bottom + Rect.top - 1) DIV 2 - 4 + shft;
      IF Enabled
      THEN
        WrStrXY(Text, x, y, WHITE, WHITE);
      ELSE
        WrStrXY(Text, x, y, GREY, GREY);
      END (* if Enabled *);
      IF (Highlighted >= 0) & (ORD(Highlighted) < Length(Text))
      THEN
        INC(x, 8 * Highlighted);
        IF Enabled
        THEN
          WrStrXY(Text[Highlighted], x, y, YELLOW, YELLOW);
        ELSE
          WrStrXY(Text[Highlighted], x, y, GREY, GREY);
        END (* if Enabled *);
      END (* if *);
      IF h
      THEN
        ShowCursor();
      END (* if h *);
      SetBank(p);
    END (* with but *);
  END DrawInter;

  PROCEDURE UniversalKBD
            (    ba : ADDRESS );

  BEGIN
    KbdButton := ba;
    MouseHandler(EventSet {LeftDown}, ButtonSet {}, 0, 0);
    (* Wait(TInOneSecond() DIV 10); *)
    MouseHandler(EventSet {LeftUp}, ButtonSet {}, 0, 0);
    KbdButton := NIL;
  END UniversalKBD;


  PROCEDURE MouseHandler
            (    ev : EventSet;
                 bs : ButtonSet;
                 x,
                 y  : INTEGER   );
  VAR
    but : Button;


  (*
  PROCEDURE FrameRectD
            (    r   : RECT;
                 col : BYTE );

  BEGIN
    HiLevGraf.FrameRect(r, col);
    DEC(r.left);
    INC(r.right);
    DEC(r.top);
    INC(r.bottom);
    HiLevGraf.FrameRect(r, col);
  END FrameRectD;
  *)
  BEGIN (* MouseHandler *)
    IF NOT AllEnabled THEN
      RETURN;
    END;
    IF KbdButton = NIL
    THEN
      IF NOT FindAMark(but)  THEN
        RETURN
      END;
    ELSE
      but := KbdButton;
      Assert(but^.Active = Alive);
      IF NOT MarkBut(but) THEN
        RETURN
      END;
    END (* if KbdButton *);
    WITH but^ DO
      Assert(Active = Alive);
      Assert(busy);
      IF NOT Enabled
      THEN
        IF Pressed & NOT Radio
        THEN
          Pressed := FALSE;
          DrawInter(but);
        END (* if Pressed *);
        Unmark (but);
        RETURN;   (* nic nie rob *)
      END (* if *);
      IF LeftDown IN ev
      THEN
        IF Radio AND Pressed THEN
          Unmark(but);
          RETURN;
        END;
        Pressed := TRUE;
        DrawInter(but);
        Assert(Active = Alive);
        IF Radio
        THEN
          RButtonProc(but);
        ELSE
          ButtonPROC;   (* call user defined proc *)
        END (* if Radio *);
      END (* if LeftDown *);
      IF ((LeftUp IN ev) OR (RegionOut IN ev)) & NOT Radio
      THEN
        IF Pressed
        THEN
          Pressed := FALSE;
          DrawInter(but);
        END;
      END;
      Unmark(but);
    END;
  END MouseHandler;

  PROCEDURE ChangeButton
            (    b  : Button;
                 t  : ARRAY OF CHAR; (* text *)
                 k  : INTEGER      );
  VAR
    ok: BOOLEAN;
  BEGIN (* ChangeButton *)
    IF b # NIL
    THEN
      ok := MarkBut(b);
      WITH b^ DO
        Assign(t, Text);
        Highlighted := k;
        Pressed := FALSE;
        DrawInter(b);
      END (* with b *);
      Unmark(b);
    END (* if b *);
  END ChangeButton;

  PROCEDURE ChangeButtonText
            (    b : Button;
                 t : ARRAY OF CHAR );

  BEGIN
    Assert(b^.Active = Alive);
    Assign(t, b^.Text);
    DrawInter(b);
  END ChangeButtonText;

  PROCEDURE DisposeButton
            ( VAR b : Button );

  PROCEDURE KillButton
            ( VAR but : Button );

  BEGIN
    WITH but^ DO
      Assert(Active = Alive);
      UnregisterRegion(Reg);
      DeleteShortCut(ShortCut);
      FillRect(Rect, BLACK);
      Active := Dead;
    END (* with but *);
    DISPOSE(but);
  END KillButton;

  BEGIN
    IF b = NIL
    THEN
      RETURN
    END (* if b *);
    RemoveToKill(b);
    KillButton(b);
  END DisposeButton;

  PROCEDURE PressRadio
            (    b  : Button;
                 On : BOOLEAN );

  BEGIN
    IF (NOT b^.Radio)
    THEN
      HALT;
    END (* if *);
    b^.Pressed := On;
    DrawInter(b);
  END PressRadio;

  PROCEDURE Nic();
  END Nic;

  PROCEDURE CreateButton
            (    R  : RECT;
                 t  : ARRAY OF CHAR; (* text *)
                 k  : INTEGER;
                 sh : CARDINAL; (* shortcut *)
                 P  : PROC          ) : Button;
  VAR
    b : Button;

  BEGIN
    NEW(b);
    WITH b^ DO
      Rect := R;
      ShortCut := sh;
      Assign(t, Text);
      Highlighted := k;
      Pressed := FALSE;
      Enabled := TRUE;
      busy := FALSE;
      InitS(waiting);
      Radio := FALSE;
      ButtonPROC := P;
      Active := Alive;
      Next := NIL;
      DrawInter(b);
      Insert(b);
      DefineShortCut(ShortCut, UniversalKBD, b);
      RegisterRegion(EventSet {(*RegionIn, *)RegionOut, LeftDown, LeftUp},
                            R, MouseHandler, NIL, Reg);
    END (* with b *);
    RETURN b;
  END CreateButton;

  PROCEDURE CreateRadioButton
            (    R  : RECT;
                 t  : ARRAY OF CHAR; (* text *)
                 k  : INTEGER; (* numer wyroznionego znaku w tekscie *)
                 sh : CARDINAL; (* shortcut *)
                 P  : RadioButtonProc ) : Button;
  VAR
    b : Button;

  BEGIN
    b := CreateButton(R, t, k, sh, Nic);
    b^.Radio := TRUE;
    b^.RButtonProc := P;
    RETURN b;
  END CreateRadioButton;

  PROCEDURE EnableButton
            (    b : Button;
                 e : BOOLEAN );

  BEGIN
    IF (b # NIL) & (b^.Enabled # e)
    THEN
      b^.Enabled := e;
      DrawInter(b);
    END (* if *);
  END EnableButton;

  PROCEDURE GetRegion
            (    b : Button ) : Region;

  BEGIN
    RETURN b^.Reg;
  END GetRegion;

  PROCEDURE CallProc
            (    b : Button );

  BEGIN
    UniversalKBD(b);
  END CallProc;

  PROCEDURE EnableDisableAllButtons( Enable : BOOLEAN );
    BEGIN
      AllEnabled := Enable;
    END EnableDisableAllButtons;

BEGIN
  AllEnabled := TRUE;
  KbdButton := NIL;
END Buttons.
