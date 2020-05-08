IMPLEMENTATION MODULE TeoEvent;

FROM Views IMPORT
  TView, TViewState, TViewStates;
FROM Objects IMPORT
  TRect;
FROM Drivers IMPORT
  TEvent, TDrawBuffer, MoveStr, EventTypes, EventType;
FROM App IMPORT
  Application;
FROM Storage IMPORT
  ALLOCATE;
IMPORT
  Data;



CLASS TeoView (TView);

  VIRTUAL PROCEDURE Draw;
  VIRTUAL PROCEDURE HandleEvent( VAR e : TEvent );
  PROCEDURE Init;

END TeoView;

CONST
  ScrollLock = 4;
VAR
  Stats[40H:17H] : SET OF [0..7];

CLASS IMPLEMENTATION TeoView;

  VIRTUAL PROCEDURE Draw;
  VAR
    Color: CARDINAL;
    b    : TDrawBuffer;
  BEGIN
    Color := GetColor(30+50*ORD(Data.TeoEvent));
    MoveStr(b, 0, 'T EV', Color);
    WriteLine(0, 0, Size.X, 1, b);
  END Draw;

  VIRTUAL PROCEDURE HandleEvent( VAR e : TEvent );
  BEGIN
    TView.HandleEvent( e );
    IF (ScrollLock IN Stats) # Data.TeoEvent THEN
      Data.TeoEvent := ScrollLock IN Stats;
      Draw;
    END;
  END HandleEvent;

  PROCEDURE Init;
  VAR
    R : TRect;
  BEGIN
    R.Assign( 76, 24, 80, 25 );
    TView.Init( R );
    SetState( TViewStates{ sfDisabled }, FALSE );
    SetState( TViewStates{ sfExposed, sfActive, sfVisible }, TRUE );
    EventMask := EventTypes{evMouseDown..evBroadcast};
  END Init;

BEGIN
END TeoView;


VAR
  v : POINTER TO TeoView;
  Inserted : BOOLEAN;

PROCEDURE Enable( Enabled : BOOLEAN );
BEGIN
  IF Enabled THEN
    Application^.Insert( v );
    Inserted := TRUE;
  ELSIF Inserted THEN
    Application^.Delete( v );
    Inserted := FALSE;
  END;
END Enable;

BEGIN
  NEW( v );
  v^.Init;
  Inserted := FALSE;
END TeoEvent.
