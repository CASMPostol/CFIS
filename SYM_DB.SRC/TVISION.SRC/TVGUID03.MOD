MODULE TVGUID03;

FROM App IMPORT
  TApplication, MenuBar, StatusLine;
FROM Objects IMPORT
  TRect;
FROM Menus IMPORT
  NewMenu, NewSubMenu, NewItem, NewLine, NewStatusDef, NewStatusKey;
FROM Drivers IMPORT
  kbF3, kbF4, kbF5, kbF6, kbF10, kbAltF3, kbAltX;
FROM Views IMPORT
  hcNoContext, cmQuit, cmNext, cmZoom, cmMenu, cmClose;
FROM Storage IMPORT
  ALLOCATE;

CONST
  cmFileOpen = 100;
  cmNewWin   = 101;


  CLASS TMyApp (TApplication);
    VIRTUAL PROCEDURE InitMenuBar;
    VIRTUAL PROCEDURE InitStatusLine;
  END TMyApp;

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

  BEGIN
  END TMyApp;

VAR
  MyApp: TMyApp;

BEGIN
  MyApp.Run;
  MyApp.Done;
END TVGUID03.
