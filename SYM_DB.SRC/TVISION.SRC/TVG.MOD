MODULE TVG;

FROM App IMPORT
  TApplication, Desktop;
FROM Objects IMPORT
  TRect, String, PString, TPoint, NewStr, DisposeStr;
FROM Menus IMPORT
  NewMenu, NewSubMenu, NewItem, NewLine, NewStatusDef, NewStatusKey;
FROM Drivers IMPORT
  EventType, EventTypes, TEvent, kbF3, kbF4, kbF5, kbF6, kbF10, kbAltF3,
  kbF2, kbAltX, TDrawBuffer, MoveChar, MoveStr;
FROM Commands IMPORT
  hcNoContext, cmQuit, cmNext, cmZoom, cmMenu, cmClose, cmCancel;
FROM Winds IMPORT
  TWindow, wnNoNumber;
FROM Views IMPORT
  TViewOption, TViewGrowModes, TViewGrowMode, PView;
FROM Scroller IMPORT
  TScroller;
FROM ScrollBars IMPORT
  PScrollBar;
FROM Dialogs IMPORT
  PDialog;
FROM Dlg IMPORT
  MakeDialog;
FROM Storage IMPORT
  ALLOCATE, DEALLOCATE;
FROM Lib IMPORT
  RANDOM, RANDOMIZE;
FROM FIO IMPORT
  File, Open, Close, RdStr, EOF;
IMPORT
  Str;
(*
IMPORT PMD;
*)


CONST
  cmFileOpen  = 100;
  cmNewWin    = 101;
  cmDialog    = 102;

CONST
  FileToRead        = 'gps.log';
  MaxLines          = 100;

VAR
  WinCount  : CARDINAL;
  LineCount : INTEGER;
  Lines     : ARRAY[0..MaxLines - 1] OF PString;

TYPE
  DialogData = RECORD
    CheckBoxData : CARDINAL;
    RadioButtonData: CARDINAL;
    InputLineData: ARRAY [0..128-1] OF CHAR;
  END;

  CLASS TMyApp(TApplication);
    VIRTUAL PROCEDURE HandleEvent(VAR Event: TEvent);
    VIRTUAL PROCEDURE InitMenuBar;
    VIRTUAL PROCEDURE InitStatusLine;
    PROCEDURE NewDialog;
    PROCEDURE NewWindow;
  END TMyApp;

TYPE
  PInterior = POINTER TO TInterior;
  PDemoWindow = POINTER TO TDemoWindow;

  CLASS TDemoWindow (TWindow);
    RInterior,
    LInterior: PInterior;

    PROCEDURE Init( Bounds  : TRect;
                    WinTitle: ARRAY OF CHAR;
                    WindowNo: CARDINAL);
    PROCEDURE MakeInterior( Bounds: TRect;
                            Left  : BOOLEAN): PInterior;
    VIRTUAL PROCEDURE SizeLimits(VAR Min, Max: TPoint);
  END TDemoWindow;

  CLASS TInterior(TScroller);
    PROCEDURE Init( VAR Bounds: TRect;
                    AHScrollBar,
                    AVScrollBar: PScrollBar);
    VIRTUAL PROCEDURE Draw;
  END TInterior;

VAR
  DemoDialogData: DialogData;

PROCEDURE ReadFile;
VAR
  F: File;
  S: ARRAY[0..127] OF CHAR;
BEGIN
  LineCount := 0;
  F := Open( FileToRead );
  WHILE NOT EOF AND (LineCount < MaxLines) DO
    RdStr(F, S);
    Lines[LineCount] := NewStr(S);
    INC(LineCount);
  END;
  Close(F);
END ReadFile;

PROCEDURE DoneFile;
VAR
  i : CARDINAL;
BEGIN
  FOR i := 0 TO LineCount - 1 DO
    IF Lines[i] <> NIL THEN
      DisposeStr(Lines[i]);
    END;
  END;
END DoneFile;

CLASS IMPLEMENTATION TMyApp;

  VIRTUAL PROCEDURE InitMenuBar;
  VAR
    R: TRect;
  BEGIN
    R := GetExtent();
    R.B.Y := R.A.Y + 1;
    NEW( MenuBar );
    MenuBar^.Init(R,
                  NewMenu(
                    NewSubMenu('~F~ile', hcNoContext, NewMenu(
                      NewItem('~O~pen', 'F3', kbF3, cmFileOpen, hcNoContext,
                      NewItem('~N~ew', 'F4', kbF4, cmNewWin, hcNoContext,
                      NewLine(
                      NewItem('E~x~it', 'Alt-X', kbAltX, cmQuit, hcNoContext,
                      NIL))))),
                    NewSubMenu('~W~indow', hcNoContext, NewMenu(
                      NewItem('~N~ext', 'F6', kbF6, cmNext, hcNoContext,
                      NewItem('~Z~oom', 'F5', kbF5, cmZoom, hcNoContext,
                      NewLine(
                      NewItem('~D~ialog', 'F2', kbF2, cmDialog, hcNoContext,
                      NIL))))),
                    NIL))
                  ));
  END InitMenuBar;

  VIRTUAL PROCEDURE InitStatusLine;
  VAR
    R: TRect;
  BEGIN
    R := GetExtent();
    R.A.Y := R.B.Y - 1;
    NEW(StatusLine);
    StatusLine^.Init(R,
                     NewStatusDef(0, 0FFFFH,
                       NewStatusKey('', kbF10, cmMenu,
                       NewStatusKey('~Alt-X~ Exit', kbAltX, cmQuit,
                       NewStatusKey('~F4~ New', kbF4, cmNewWin,
                       NewStatusKey('~Alt-F3~ Close', kbAltF3, cmClose,
                       NIL)))),
                     NIL)
                   );
  END InitStatusLine;

  VIRTUAL PROCEDURE HandleEvent( VAR Event : TEvent );
  BEGIN
    TApplication.HandleEvent( Event );
    IF Event.What = EventTypes{ evCommand } THEN
      CASE Event.Command OF
      | cmNewWin : NewWindow;
      | cmDialog : NewDialog;
      ELSE
        RETURN;
      END;
      ClearEvent(Event);
    END;
  END HandleEvent;

  PROCEDURE NewDialog;
  VAR
    Dialog: PDialog;
    C: CARDINAL;
  BEGIN
    Dialog := MakeDialog(DemoDialogData);
    C := Desktop^.ExecView(Dialog);
    IF C <> cmCancel THEN
      Dialog^.GetData(DemoDialogData);
    END;
    Dialog^.Done;
    DISPOSE(Dialog);
  END NewDialog;

  PROCEDURE NewWindow;
  VAR
    Window: PDemoWindow;
    R: TRect;
  BEGIN
    INC(WinCount);
    R.Assign(0, 0, 45, 13);
    R.Move(RANDOM(34), RANDOM(11));
    NEW(Window);
    Window^.Init(R, 'Demo Window', WinCount);
    Desktop^.Insert(Window);
  END NewWindow;

BEGIN
END TMyApp;

CLASS IMPLEMENTATION TDemoWindow;

  PROCEDURE Init( Bounds: TRect; WinTitle: ARRAY OF CHAR ; WindowNo: CARDINAL);
  VAR
    S: String;
    R: TRect;
    ok : BOOLEAN;
  BEGIN
    Str.CardToStr(VAL( LONGCARD, WindowNo), S, 10, ok);
    Str.Insert(S, ' ', 0 );
    Str.Insert(S, WinTitle, 0 );
    TWindow.Init(Bounds, S, wnNoNumber);
    Bounds := GetExtent();
    R.Assign(Bounds.A.X, Bounds.A.Y, Bounds.B.X DIV 2 + 1, Bounds.B.Y);
    LInterior := MakeInterior(R, TRUE);
    LInterior^.GrowMode := TViewGrowModes{ gfGrowHiY };
    Insert(LInterior);
    R.Assign(Bounds.B.X DIV 2, Bounds.A.Y, Bounds.B.X, Bounds.B.Y);
    RInterior := MakeInterior(R, FALSE);
    RInterior^.GrowMode := TViewGrowModes{ gfGrowHiX, gfGrowHiY };
    Insert(RInterior);
  END Init;

  PROCEDURE MakeInterior(Bounds: TRect; Left: BOOLEAN): PInterior;
  VAR
    HScrollBar, VScrollBar: PScrollBar;
    Int : PInterior;
    R: TRect;
  BEGIN
    R.Assign(Bounds.B.X-1, Bounds.A.Y+1, Bounds.B.X, Bounds.B.Y-1);
    NEW(VScrollBar);
    WITH VScrollBar^ DO
      Init(R);
      INCL( Options, ofPostProcess );
      IF Left THEN
        GrowMode := TViewGrowModes{ gfGrowHiY };
      END;
      Insert(VScrollBar);
    END;
    R.Assign(Bounds.A.X+2, Bounds.B.Y-1, Bounds.B.X-2, Bounds.B.Y);
    NEW( HScrollBar );
    WITH HScrollBar^ DO
      Init(R);
      INCL( Options, ofPostProcess );
      IF Left THEN
        GrowMode := TViewGrowModes{ gfGrowHiY + gfGrowLoY };
      END;
      Insert(HScrollBar);
    END;
    Bounds.Grow(-1,-1);
    NEW( Int );
    Int^.Init(Bounds, HScrollBar, VScrollBar);
    RETURN Int;
  END MakeInterior;

  VIRTUAL PROCEDURE SizeLimits(VAR Min, Max: TPoint);
  VAR
    R: TRect;
  BEGIN
    TWindow.SizeLimits(Min, Max);
    Min.X := LInterior^.Size.X + 9;
  END SizeLimits;

BEGIN
END TDemoWindow;

CLASS IMPLEMENTATION TInterior;

  VIRTUAL PROCEDURE Draw;
  VAR
    Color: CARDINAL;
    i, y : INTEGER;
    b    : TDrawBuffer;
    str  : String;
  BEGIN
    Color := GetColor(1);
    FOR y := 0 TO Size.Y - 1 DO
      MoveChar(b, 0, ' ', Color, Size.X);
      i := Delta.Y + y;
      IF (i < LineCount) & (Lines[i] <> NIL) THEN
        Str.Slice( str, Lines[i]^, Delta.X,  Size.X );
        MoveStr(b, 0, str, Color);
      END;
      WriteLine(0, y, Size.X, 1, b);
    END;
  END Draw;

  PROCEDURE Init( VAR Bounds: TRect;
                      AHScrollBar,
                      AVScrollBar: PScrollBar);
  BEGIN
    TScroller.Init(Bounds, AHScrollBar, AVScrollBar);
    INCL( Options, ofFramed );
    SetLimit(128, LineCount);
  END Init;

BEGIN
END TInterior;

VAR
  MyApp: TMyApp;

BEGIN
  WinCount := 0;
  RANDOMIZE;
  WITH DemoDialogData DO
    CheckBoxData := 1;
    RadioButtonData := 2;
    InputLineData := 'Phone home.';
  END;
  ReadFile;
  MyApp.Init;
  MyApp.Run;
  MyApp.Done;
  DoneFile;
END TVG.
