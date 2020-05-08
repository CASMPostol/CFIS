MODULE TVG;

FROM App IMPORT
  TApplication, Desktop;
FROM Objects IMPORT
  TRect;
FROM Menus IMPORT
  NewMenu, NewSubMenu, NewItem, NewLine, NewStatusDef, NewStatusKey;
FROM Drivers IMPORT
  EventType, EventTypes, TEvent, kbF3, kbF4, kbF5, kbF6, kbF10, kbAltF3, kbAltX;
FROM Commands IMPORT
  hcNoContext, cmQuit, cmNext, cmZoom, cmMenu, cmClose;
FROM Winds IMPORT
  TWindow;
FROM Storage IMPORT
  ALLOCATE;
FROM Lib IMPORT
  RANDOM, RANDOMIZE;
IMPORT PMD;

CONST
  cmFileOpen = 100;
  cmNewWin   = 101;

TYPE
  PDemoWindow = POINTER TO TDemoWindow;
  CLASS TDemoWindow ( TWindow );
  END TDemoWindow;

  CLASS TMyApp (TApplication);
    VIRTUAL PROCEDURE InitMenuBar;
    VIRTUAL PROCEDURE InitStatusLine;
    VIRTUAL PROCEDURE HandleEvent(VAR Event: TEvent);
    PROCEDURE NewWindow;
  END TMyApp;

VAR
  WinCount : CARDINAL;
  sh : INTEGER;

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
                        NIL))),
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
          cmNewWin: NewWindow;
        ELSE
          RETURN;
        END;
        ClearEvent(Event);
      END;
    END HandleEvent;

    PROCEDURE NewWindow;
    VAR
      Window: PDemoWindow;
      R: TRect;
    BEGIN
      INC( WinCount );
      R.Assign(0, 0, 26, 7);
      R.Move( RANDOM( 60 ), RANDOM(20));
      INC( sh );
      NEW( Window );
      Window^.Init(R, 'Demo Window', WinCount);
      Desktop^.Insert( Window );
    END NewWindow;

  BEGIN
  END TMyApp;

  CLASS IMPLEMENTATION TDemoWindow;
  BEGIN
  END TDemoWindow;

VAR
  MyApp: TMyApp;

BEGIN
  WinCount := 0;
  sh := 0;
  RANDOMIZE;
  MyApp.Init;
  MyApp.NewWindow;
  MyApp.Run;
  MyApp.Done;
END TVG.
