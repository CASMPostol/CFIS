IMPLEMENTATION MODULE ShHist;

FROM Views IMPORT
  PGroup, TViewState, TViewStates;
FROM Objects IMPORT
  TRect, DisposeStr, NewStr;
FROM InputLines IMPORT
  PInputLine, TInputLine;
FROM Dialogs IMPORT
  PDialog, TDialog;
FROM History IMPORT
  THistory, PHistory, PHistoryWindow;
FROM HistList IMPORT
  HistoryCount, HistoryStr, ValidateProc, SetValidateProc;
FROM Views IMPORT
  TViewOption, TViewOptions, ofCentered;
FROM Labels IMPORT
  PLabel;
FROM Str IMPORT
  Compare;
FROM Storage IMPORT
  ALLOCATE, DEALLOCATE;


CONST
  InpWlk = 64;

TYPE
  PHist = POINTER TO MyHistory;
  PInp  = POINTER TO MyInputLine;

VAR
  Notify : NotificationProc;

CLASS MyInputLine( TInputLine );
   VIRTUAL PROCEDURE SetState( AState : TViewStates; Enable : BOOLEAN );
END MyInputLine;

CLASS MyHistory( THistory );
   VIRTUAL PROCEDURE InitHistoryWindow( VAR R : TRect ) : PHistoryWindow;
END MyHistory;

CLASS IMPLEMENTATION MyHistory;

   VIRTUAL PROCEDURE InitHistoryWindow( VAR R : TRect ) : PHistoryWindow;
   VAR
     phw : PHistoryWindow;
   BEGIN
     phw := THistory.InitHistoryWindow( R );
     DisposeStr( phw^.Title );
     phw^.Title := NewStr( "Lista znanych VORow" );
     RETURN phw;
   END InitHistoryWindow;

BEGIN
END MyHistory;



CLASS IMPLEMENTATION MyInputLine;

   VIRTUAL PROCEDURE SetState( AState : TViewStates; Enable : BOOLEAN );
   VAR
     os : TViewStates;
     s : ARRAY[0..InpWlk-1] OF CHAR;
   BEGIN
     os := State;
     TInputLine.SetState( AState, Enable );
     IF (sfFocused IN os) & NOT(sfFocused IN State) THEN
       GetData( s );
       Notify( s );
     END
   END SetState;
BEGIN
END MyInputLine;



PROCEDURE DefineHistorySubView( R : TRect;
                                lab : ARRAY OF CHAR;
                                p : PGroup;
                                VAR tytul : PInputLine );
VAR
  h : PHist;
  n : PInp;
  l : PLabel;
  R1 : TRect;
BEGIN
  WITH p^ DO

    R1 := R;
    NEW( n );
    n^.Init( R, InpWlk );
    Insert( n );

    R.A.X := R.B.X+1;
    R.B.X := R.A.X +2;
    NEW( h );
    h^.Init( R, n, HIST_ID );
    Insert( h );

    R1.Move( 0, -1 );
    NEW( l );
    l^.Init( R1, lab, n );
    Insert( l );

  END;
  tytul := n;
END DefineHistorySubView;

PROCEDURE Dummy( VAR a : ARRAY OF CHAR );
END Dummy;

VAR
  oldValidate : ValidateProc;

PROCEDURE Validate( id : SHORTCARD; VAR str : ARRAY OF CHAR ) : BOOLEAN;
VAR
  i : CARDINAL;
BEGIN
  IF id = HIST_ID THEN
    IF str[0] = 0C THEN
      RETURN FALSE;
    END;
    FOR i := 1 TO HistoryCount(id) DO
      IF Compare( HistoryStr( id, i-1 )^, str ) = 0 THEN
        RETURN FALSE;
      END;
    END;
    RETURN TRUE;
  ELSE
    RETURN oldValidate( id, str );;
  END;
END Validate;

PROCEDURE SetNotification( np : NotificationProc );
BEGIN
  Notify := np;
END SetNotification;

BEGIN
  SetNotification( Dummy );
  SetValidateProc( Validate, oldValidate );
END ShHist.
