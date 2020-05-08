MODULE Database;

FROM VOR_data IMPORT
  VORdata, cmVORdatabase;
FROM ODP_data IMPORT
  ODPdata, cmODPdatabase;
FROM LOT_data IMPORT
  LOTdata, cmLOTdatabase;
FROM VHF_data IMPORT
  VHFdata, cmVHFdatabase;
FROM NDB_data IMPORT
  NDBdata, cmNDBdatabase;
FROM App IMPORT
  TApplication, Desktop, Application;
FROM Objects IMPORT
  TRect, String, PString, TPoint, NewStr, DisposeStr;
FROM Menus IMPORT
  NewMenu, NewSubMenu, NewItem, NewLine, NewStatusDef, NewStatusKey;
FROM Drivers IMPORT
  EventType, EventTypes, TEvent, kbF3, kbF4, kbF5, kbF6, kbF10, kbAltF3,
  kbF2, kbAltX, TDrawBuffer, MoveChar, MoveStr, kbCtrlL, kbAltC, kbCtrlT,
  kbCtrlS, kbAltG, kbAltI, kbCtrlO, kbCtrlA, kbCtrlC, kbAltA, evMessage,
  kbCtrlR, kbCtrlP, kbCtrlH, kbCtrlG, kbCtrlE, kbAltV, kbCtrlM, kbCtrlD,
  kbAltE, kbCtrlB, kbAltB, kbAltK, kbAltP, kbAltQ, kbCtrlF7, kbCtrlV, kbCtrlN;
FROM Commands IMPORT
  hcNoContext, cmQuit, cmNext, cmZoom, cmMenu, cmClose, cmCancel;
FROM Winds IMPORT
  TWindow, wnNoNumber;
FROM Views IMPORT
  TViewOption, TViewGrowModes, TViewGrowMode, PView, Message;
FROM Scroller IMPORT
  TScroller;
FROM ScrollBars IMPORT
  PScrollBar;
FROM Dialogs IMPORT
  PDialog;
FROM Storage IMPORT
  ALLOCATE, DEALLOCATE;
FROM Warn IMPORT
  Proceed;
IMPORT
  Lib, Komunikacja;
IMPORT
  PMD;










TYPE

  CLASS TMyApp(TApplication);
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
                    NewSubMenu('U~r~z¥dzenia', hcNoContext, NewMenu(
                      NewItem('~V~OR',      'Ctrl+V', kbCtrlV, cmVORdatabase, hcNoContext,
                      NewItem('~L~otnisko', 'Ctrl+L', kbCtrlL, cmLOTdatabase, hcNoContext,
                      NewItem('V~H~F', 'Ctrl+H', kbCtrlH, cmVHFdatabase, hcNoContext,
                      NewItem('~N~DB', 'Ctrl+N', kbCtrlN, cmNDBdatabase, hcNoContext,
                      NewLine(
                      NewItem('Li~s~ta odpowiedzialnych', 'Ctrl+S', kbCtrlS, cmODPdatabase, hcNoContext,
                      NewLine(
                      NewItem('~K~oniec',   'Alt+Q', kbAltQ, cmQuit, hcNoContext,
                      NIL ))))))))),
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
                       NewStatusKey('~Ctrl+V~ VOR', kbCtrlV, cmVORdatabase,
                       NewStatusKey('~Ctrl+L~ Lotn.', kbCtrlL, cmLOTdatabase,
                       NewStatusKey('~Alt+F3~ Zamknij', kbAltF3, cmClose,
                       NIL))))),
                     NIL)
                   );
  END InitStatusLine;

  VIRTUAL PROCEDURE HandleEvent( VAR Event : TEvent );
  BEGIN
    IF Event.What = EventTypes{ evCommand } THEN
      CASE Event.Command OF
      | cmVORdatabase:
          VORdata( Desktop );
      | cmODPdatabase:
          ODPdata( Desktop );
      | cmLOTdatabase:
          LOTdata( Desktop );
      | cmVHFdatabase:
          VHFdata( Desktop );
      | cmNDBdatabase:
          NDBdata( Desktop );
      | cmQuit:
          IF NOT Proceed() THEN
            ClearEvent( Event );
          END;
      ELSE
      END;
(*      ClearEvent(Event);*)
    END;
    TApplication.HandleEvent( Event );
  END HandleEvent;


BEGIN
END TMyApp;

VAR
  MyApp: TMyApp;

BEGIN
  MyApp.Init;
  MyApp.Run;
  Lib.NoSound;
  MyApp.Done;
(*
  IF NOT Komunikacja.InsertInKBD( "Samolot" ) THEN
  END;
*)
END Database.
