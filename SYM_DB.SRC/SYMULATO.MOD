(*#data( stack_size => 16348 )*)
MODULE Symulator;


IMPORT PMD;

IMPORT
  Strategia;
FROM AngleVOR IMPORT
  AngleFlightStart;
FROM CircleVOR IMPORT
  CircleFlightStart;
FROM DMEADF IMPORT
  DME, ADF;
FROM ILSS IMPORT
  GlidingSlopeNach, GlidingSlopeZbocz;
FROM ILSS1 IMPORT
 AcrossGS, AlongGS;
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
  kbAltE, kbCtrlB, kbAltB, kbAltK, kbAltP, kbAltQ, kbCtrlF7;
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
FROM Setup IMPORT
  ILS_Opt_Dialog, GPS_Opt_Dialog, VOR_Dialog, ILS_Dialog;
FROM Polozenie IMPORT
  Org_Pnt_Dialog;
FROM Storage IMPORT
  ALLOCATE, DEALLOCATE;
FROM Data IMPORT
  (*GPSOpt, ILSOpt, *)LoadIni, SaveIni, LatKatowy, PolozenieTeodolitu, Height,
  InnerMarker, MiddleMarker, OuterMarker, MarkerType, GlidingSlope1,
  GlidingSlope2, GlidingSlope3, KierunekPasa, PoPromieniu, Deklinacja;
FROM stdio IMPORT
  sprintf, sscanf;
FROM Geo2Polar IMPORT
  PolozenieOdniesienia, UstawPolozenieOdniesienia, PolozenieGeograficzne,
  PolozenieKatowe, Kat2Geo;
FROM Glos IMPORT
  GlosDlg;
IMPORT
  Send, CommTypes, FC, Lib;

(*
IMPORT GPS_Nadawanie;
*)
FROM LocCommands IMPORT
  cmStartFlight, cmStopFlight, cmAngleFlight, cmCircleFlight, cmGPS_Opt,
  cmILS_Opt, cmOrigin, cmVORFlightSetup, cmILSFlightSetup, doStart,
  doStop, cmILS_GS_ProfB, cmILS_GS_ProfA, cmILS_LOC_ProfA, cmILS_LOC_ProfB,
  cmDMEFlight, cmADFFlight, cmHeapAvail, cmCommFlight;

TYPE

  CLASS TMyApp(TApplication);
    VIRTUAL PROCEDURE HandleEvent(VAR Event: TEvent);
    VIRTUAL PROCEDURE InitMenuBar;
    VIRTUAL PROCEDURE InitStatusLine;
(*
    PROCEDURE GPSOptions;
    PROCEDURE ILSOptions;
*)
    PROCEDURE VORFlight;
    PROCEDURE ILSFlight;
    PROCEDURE GSVPath;
    PROCEDURE GSHPath;
    PROCEDURE GSOrbit;
    PROCEDURE GSHorizontal;
    PROCEDURE Start;
    PROCEDURE Stop;
    PROCEDURE DMEFlight;
    PROCEDURE ADFFlight;
    PROCEDURE SetOriginPoint;
    PROCEDURE StartAngleFlight;
    PROCEDURE StartCircleFlight;
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
                      NewSubMenu( '~V~OR', hcNoContext, NewMenu(
                        NewItem('~P~romie¤', 'Ctrl+P', kbCtrlP, cmAngleFlight, hcNoContext,
                        NewItem('~O~kr†g', 'Ctrl+O', kbCtrlO, cmCircleFlight, hcNoContext,
                        NIL ))),
                      NewSubMenu( '~I~LS', hcNoContext, NewMenu(
                        NewSubMenu('~˜~cie§ka', hcNoContext, NewMenu(
                          NewItem('Profil ~A~', 'Ctrl+A', kbCtrlA, cmILS_GS_ProfA, hcNoContext,
                          NewItem('Profil ~B~', 'Ctrl+B', kbCtrlB, cmILS_GS_ProfB, hcNoContext,
                          NIL ))),
                        NewSubMenu('~K~ierunek', hcNoContext, NewMenu(
                          NewItem('Profil ~A~', 'Alt+A', kbAltA, cmILS_LOC_ProfA, hcNoContext,
                          NewItem('Profil ~B~', 'Alt+B', kbAltB, cmILS_LOC_ProfB, hcNoContext,
                          NIL ))),
                        NIL ))),
                      NewItem('D~M~E', 'Ctrl+M', kbCtrlM, cmDMEFlight, hcNoContext,
                      NewItem('A~D~F + COMM (okrag)', 'Ctrl+D', kbCtrlD, cmADFFlight, hcNoContext,
                      NewItem('~C~OMM + ADF (promien)', 'Ctrl+C', kbCtrlC, cmCommFlight, hcNoContext,
                      NewLine(
                      NewItem('~K~oniec', 'Alt+Q', kbAltQ, cmQuit, hcNoContext,
                      NIL)))))))),
                    NewSubMenu('~O~pcje', hcNoContext, NewMenu(
                      NewItem('~V~OR', 'Alt+V', kbAltV, cmVORFlightSetup, hcNoContext,
                      NewItem('~I~LS', 'Alt+I', kbAltI, cmILSFlightSetup, hcNoContext,
                      NewItem('~P~unkt odniesienia', 'Alt+P', kbAltP, cmOrigin, hcNoContext,
                      NIL)))),
                    NewSubMenu('Op~e~racje', hcNoContext, NewMenu(
                      NewItem('~S~tart', 'Ctrl+S', kbCtrlS, cmStartFlight, hcNoContext,
                      NewItem('S~t~op', 'Ctrl+T', kbCtrlT, cmStopFlight, hcNoContext,
                      NIL ))),
                    NIL)))
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
                       NewStatusKey('', kbCtrlF7, cmHeapAvail,
                       NewStatusKey('~Alt+Q~ Koniec', kbAltQ, cmQuit,
                       NewStatusKey('~Ctrl+S~ Start', kbCtrlS, cmStartFlight,
                       NewStatusKey('~Ctrl+T~ Stop', kbCtrlT, cmStopFlight,
                       NewStatusKey('~Alt+F3~ Zamknij', kbAltF3, cmClose,
                       NIL)))))),
                     NIL)
                   );
  END InitStatusLine;

  VIRTUAL PROCEDURE HandleEvent( VAR Event : TEvent );
  BEGIN
    TApplication.HandleEvent( Event );
    IF Event.What = EventTypes{ evCommand } THEN
      CASE Event.Command OF
      | cmStartFlight:
          Start;
      | cmStopFlight:
          Stop;
      | cmVORFlightSetup:
          VORFlight;
      | cmILSFlightSetup:
          ILSFlight;
(*
      | cmGPS_Opt:
          GPSOptions;
      | cmILS_Opt:
          ILSOptions;
*)
      | cmCommFlight:
          Send.SetType( CommTypes.ptComm );
          PoPromieniu := TRUE;
          GlosDlg( Desktop );
      | cmOrigin:
          SetOriginPoint;
      | cmHeapAvail:
          FC.Heap;
      | cmAngleFlight:
          PoPromieniu := TRUE;
          StartAngleFlight;
      | cmCircleFlight:
          PoPromieniu := FALSE;
          StartCircleFlight;
      | cmILS_GS_ProfA:
          PoPromieniu := TRUE;
          GSVPath;
      | cmILS_GS_ProfB:
          PoPromieniu := TRUE;
          GSHorizontal;
      | cmILS_LOC_ProfA:
          PoPromieniu := TRUE;
          GSHPath;
      | cmILS_LOC_ProfB:
          PoPromieniu := FALSE;
          GSOrbit;
      | cmDMEFlight:
          PoPromieniu := TRUE;
          DMEFlight;
      | cmADFFlight:
          PoPromieniu := FALSE;
          ADFFlight;
      ELSE
        RETURN;
      END;
      ClearEvent(Event);
    END;
  END HandleEvent;

(*
  PROCEDURE GPSOptions;
  VAR
    Dialog: PDialog;
    C: CARDINAL;
  BEGIN
    Dialog := GPS_Opt_Dialog(GPSOpt);
    C := Desktop^.ExecView(Dialog);
    IF C <> cmCancel THEN
      Dialog^.GetData(GPSOpt);
    END;
    Dialog^.Done;
    DISPOSE(Dialog);
  END GPSOptions;
*)


  PROCEDURE SetOriginPoint;
  VAR
    Dialog: PDialog;
    C: CARDINAL;
    Dane : RECORD
      pg         : PolozenieGeograficzne;
      pk         : PolozenieKatowe;
      deklinacja : LONGREAL;
    END;
  BEGIN
    Dane.pg := PolozenieOdniesienia();
    Dane.pk := PolozenieTeodolitu;
    Dane.pk.Odleglosc := Dane.pk.Odleglosc * 1852.0;
    Dane.deklinacja := Deklinacja;
    Dialog := Org_Pnt_Dialog( Dane );
    C := Desktop^.ExecView(Dialog);
    IF C <> cmCancel THEN
      Dialog^.GetData( Dane );
      UstawPolozenieOdniesienia( Dane.pg );
      PolozenieTeodolitu := Dane.pk;
      PolozenieTeodolitu.Odleglosc := PolozenieTeodolitu.Odleglosc / 1852.0;
      Deklinacja         := Dane.deklinacja;
    END;
    Dialog^.Done;
    DISPOSE(Dialog);
  END SetOriginPoint;

(*
  PROCEDURE ILSOptions;
  END ILSOptions;
*)

  PROCEDURE VORFlight;
  VAR
    Dialog: PDialog;
    C: CARDINAL;
    s : RECORD
      pg : PolozenieGeograficzne;
      pk : PolozenieKatowe;
      v  : LONGREAL;
      h  : LONGREAL;
    END;
  BEGIN
    s.pk := LatKatowy.pk;
    s.v  := LatKatowy.Predkosc;
    s.h  := Height*1852.0;
    Kat2Geo( s.pk, s.pg );
    Dialog := VOR_Dialog(s);
    C := Desktop^.ExecView(Dialog);
    IF C <> cmCancel THEN
      Dialog^.GetData(s);
      LatKatowy.pk := s.pk;
      LatKatowy.Predkosc := s.v;
      Height := s.h/1852.0;
    END;
    Dialog^.Done;
    DISPOSE(Dialog);
  END VORFlight;

  PROCEDURE ILSFlight;
  VAR
    Dialog: PDialog;
    C: CARDINAL;
    s : RECORD
      pg : PolozenieGeograficzne;
      pk : PolozenieKatowe;
      v  : LONGREAL;
      h  : LONGREAL;
      i, m, o : MarkerType;
      gsi, gsm, gso  : LONGREAL;
      p : LONGREAL;
    END;
  BEGIN
    s.pk := LatKatowy.pk;
    s.v  := LatKatowy.Predkosc;
    s.h  := Height*1852.0;
    s.i := InnerMarker;
    s.m := MiddleMarker;
    s.o := OuterMarker;
    s.p := KierunekPasa;
    s.gsi := GlidingSlope1;
    s.gsm := GlidingSlope2;
    s.gso := GlidingSlope3;

    Kat2Geo( s.pk, s.pg );
    Dialog := ILS_Dialog(s);
    C := Desktop^.ExecView(Dialog);
    IF C <> cmCancel THEN
      Dialog^.GetData(s);
      LatKatowy.pk := s.pk;
      LatKatowy.Predkosc := s.v;
      Height := s.h/1852.0;
      InnerMarker := s.i;
      MiddleMarker := s.m;
      OuterMarker := s.o;
      GlidingSlope1 := s.gsi;
      GlidingSlope2 := s.gsm;
      GlidingSlope3 := s.gso;
      KierunekPasa := s.p;
    END;
    Dialog^.Done;
    DISPOSE(Dialog);
  END ILSFlight;

  PROCEDURE Start;
  BEGIN
    Message( Desktop, evMessage, doStart, ADR( SELF ));
  END Start;

  PROCEDURE Stop;
  BEGIN
    Message( Desktop, evMessage, doStop, ADR( SELF ));
  END Stop;

  PROCEDURE StartAngleFlight();
  BEGIN
    Send.SetType( CommTypes.ptVORRadial );
    AngleFlightStart( Desktop );
  END StartAngleFlight;

  PROCEDURE StartCircleFlight();
  BEGIN
    IF LatKatowy.pk.Odleglosc = 0.0 THEN
      FC.Odleglosc0;
    ELSE
      Send.SetType( CommTypes.ptVOROrbit );
      CircleFlightStart( Desktop );
    END;
  END StartCircleFlight;

  PROCEDURE GSVPath;
  BEGIN
    Send.SetType( CommTypes.ptGSPath );
    GlidingSlopeNach( Desktop );
  END GSVPath;

  PROCEDURE GSHPath;
  BEGIN
    Send.SetType( CommTypes.ptLOCPath );
    GlidingSlopeZbocz( Desktop );
  END GSHPath;

  PROCEDURE GSOrbit;
  VAR
    pk : PolozenieKatowe;
  BEGIN
    pk := FC.TheodolitView( LatKatowy.pk );
    IF pk.Odleglosc = 0.0 THEN
      FC.Odleglosc0;
    ELSE
      Send.SetType( CommTypes.ptLOCAngle );
      AcrossGS( Desktop );
    END;
  END GSOrbit;

  PROCEDURE GSHorizontal;
  BEGIN
    Send.SetType( CommTypes.ptGSAngle );
    AlongGS( Desktop );
  END GSHorizontal;

  PROCEDURE DMEFlight;
  BEGIN
    Send.SetType( CommTypes.ptDME );
    DME( Desktop );
  END DMEFlight;

  PROCEDURE ADFFlight;
  BEGIN
    IF LatKatowy.pk.Odleglosc = 0.0 THEN
      FC.Odleglosc0;
    ELSE
      Send.SetType( CommTypes.ptADF );
      ADF( Desktop );
    END;
  END ADFFlight;

BEGIN
END TMyApp;

VAR
  MyApp: TMyApp;

BEGIN
  MyApp.Init;
  LoadIni;
  Send.Insert( Application );
  FC.EnableCmds( (*Desktop,*) TRUE );
  MyApp.Run;
  Lib.NoSound;
  Send.Delete;
  SaveIni;
  MyApp.Done;
END Symulator.
