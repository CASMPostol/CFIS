(*%T __DLL__ *)
IMPLEMENTATION
(*%E*)
MODULE Shell;

FROM App IMPORT
  TApplication, Desktop, Application;
FROM Objects IMPORT
  TRect, String, PString, TPoint, NewStr, DisposeStr;
FROM Menus IMPORT
  NewMenu, NewSubMenu, NewItem, NewLine, NewStatusDef, NewStatusKey;
FROM Drivers IMPORT
  EventType, EventTypes, TEvent, kbF3, kbF4, kbF5, kbF6, kbF10, kbAltF3,
  kbF2, kbAltX, TDrawBuffer, MoveChar, MoveStr, kbAltS, kbAltC, kbCtrlT,
  kbCtrlS, kbAltG, kbAltI, kbCtrlO, kbCtrlA, kbCtrlC, kbAltA, evMessage,
  kbCtrlR, kbCtrlP, kbCtrlH, kbCtrlG, kbCtrlE, kbAltV, kbCtrlM, kbCtrlD,
  kbAltE, kbCtrlB, kbAltB, kbAltK, kbAltP, kbAltQ, kbCtrlF7, kbCtrlV;
FROM Commands IMPORT
  hcNoContext, cmQuit, cmNext, cmZoom, cmMenu, cmClose, cmCancel;
FROM Views IMPORT
  TViewOption, TViewGrowModes, TViewGrowMode, PView, Message;
FROM Storage IMPORT
  ALLOCATE, DEALLOCATE;
FROM ShDlg IMPORT
  cmStartVOR, VOR;
FROM ScreenSavers IMPORT
   ScreenSaver, cmAktualnePolozenie;
IMPORT PMD, Lib, FIOR, ShExecute;









TYPE

  CLASS TMyApp(TApplication);
    ScrSaverCounter : CARDINAL;

    VIRTUAL PROCEDURE HandleEvent(VAR Event: TEvent);
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
                    NewSubMenu('~U~rz†dzenia', hcNoContext, NewMenu(
                      NewItem('~V~OR',    'Ctrl+V', kbCtrlV, cmStartVOR, hcNoContext,
                      NewLine(
                      NewItem('~K~oniec', 'Alt+Q', kbAltQ, cmQuit, hcNoContext,
                      NIL )))),
                    NIL )
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
                       NewStatusKey('~Alt+Q~ Koniec', kbAltQ, cmQuit,
                       NewStatusKey('~Ctrl+V~ VOR', kbCtrlV, cmStartVOR,
                       NewStatusKey('~Ctrl+P~ Po’o§enie', kbCtrlP, cmAktualnePolozenie,
                       NewStatusKey('~Alt+F3~ Zamknij', kbAltF3, cmClose,
                       NIL))))),
                     NIL)
                   );
  END InitStatusLine;

  VIRTUAL PROCEDURE HandleEvent( VAR Event : TEvent );
  BEGIN
    IF EventTypes{evMouseDown..evKeyDown}*Event.What # EventTypes{} THEN
      ScrSaverCounter := 0;
    ELSIF evTimer IN Event.What THEN
      INC( ScrSaverCounter );
      IF ScrSaverCounter > 200 THEN (* ok 10s *)
         ScreenSaver;
         ScrSaverCounter := 0;
      END;
    END;
    TApplication.HandleEvent( Event );
    IF Event.What = EventTypes{ evCommand } THEN
      CASE Event.Command OF
      | cmStartVOR:
          VOR( Desktop );
      | cmAktualnePolozenie:
          ScreenSaver;
      ELSE
        RETURN;
      END;
      ClearEvent(Event);
    END;
  END HandleEvent;


BEGIN
   ScrSaverCounter := 0;
END TMyApp;

VAR
  MyApp: TMyApp;

(*%T __DLL__ *)
PROCEDURE Go( a : ADDRESS );
BEGIN
  ShExecute. SetRun( a );
(*%E**)
(*%F __DLL__ *)
BEGIN
(*%E*%*)
  FIOR.ReadRedirectionFile( 'shell.red' );
  MyApp.Init;
  INCL( MyApp.EventMask, evTimer );
  MyApp.Run;
  MyApp.Done;
  Lib.NoSound;
(*%T __DLL__ *)
END Go;
(*%E*)
END Shell.
