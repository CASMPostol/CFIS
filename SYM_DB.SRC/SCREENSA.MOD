IMPLEMENTATION MODULE ScreenSavers;

FROM App IMPORT
  Application;
FROM Drivers IMPORT
  GetKeyEvent, EventTypes, TEvent, smCO80;
IMPORT
  Graph;

PROCEDURE ScreenSaver;
VAR
  e : TEvent;
  ok : BOOLEAN;
BEGIN
  ok := Graph.SetVideoMode( Graph._VRES16COLOR );
  Graph.Disc( 320, 240, 200, 14 );
  REPEAT
    GetKeyEvent( e );
  UNTIL e.What # EventTypes{};
  Application^.SetScreenMode( smCO80 );
END ScreenSaver;

END ScreenSavers.
