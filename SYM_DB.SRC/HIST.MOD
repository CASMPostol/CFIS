IMPLEMENTATION MODULE Hist;

FROM Views IMPORT
  PGroup, TViewState, TViewStates, PPalette;
FROM Objects IMPORT
  TRect, DisposeStr, NewStr;
FROM InputLines IMPORT
  PInputLine, TInputLine;
FROM Dialogs IMPORT
  PDialog, TDialog;
FROM Drivers IMPORT
  TEvent, EventType, evMessage, EventTypes;
FROM History IMPORT
  THistory, PHistory, THistoryWindow, PHistoryWindow;
FROM StaticTexts IMPORT
  PStaticText;
FROM HistList IMPORT
  HistoryCount, HistoryStr, ValidateProc, SetValidateProc;
FROM Views IMPORT
  TViewOption, TViewOptions, ofCentered;
FROM Labels IMPORT
  PLabel;
FROM Freq IMPORT
  LOCfreqCRT, GSfreqCRT;
FROM Str IMPORT
  Compare, Copy;
FROM Storage IMPORT
  ALLOCATE, DEALLOCATE;
FROM stdio IMPORT
  sprintf;
FROM HistList IMPORT
  HistoryAdd, HistorySize;
FROM DB_utl IMPORT
  UtnijSpacje, CompareBezSpacji;


CONST
  InpWlk = 64;

TYPE
  PHist = POINTER TO MyHistory;
  PInp  = POINTER TO MyInputLine;
  PFHist = POINTER TO FreqHistory;
  PFInp  = POINTER TO FreqInputLine;
  PMyHistoryWindow = POINTER TO TMyHistoryWindow;

VAR
  Notify : ARRAY SHORTCARD OF NotificationProc;

CLASS MyInputLine( TInputLine );
   hist_id_w : SHORTCARD;

   PROCEDURE Set_Hist_Id( id : SHORTCARD );
   VIRTUAL PROCEDURE SetState( AState : TViewStates; Enable : BOOLEAN );
END MyInputLine;

CLASS FreqInputLine( TInputLine );
   VIRTUAL PROCEDURE HandleEvent( VAR e : TEvent );
   VIRTUAL PROCEDURE GetPalette(): PPalette;
END FreqInputLine;

CLASS MyHistory( THistory );
   hist_id_w : SHORTCARD;

   PROCEDURE Set_Hist_Id( id : SHORTCARD );
   VIRTUAL PROCEDURE InitHistoryWindow( VAR R : TRect ) : PHistoryWindow;
END MyHistory;

CLASS TMyHistoryWindow( THistoryWindow );
   hist_id_w : SHORTCARD;
   Link      : PInputLine;

   PROCEDURE Set_Hist_Id( id : SHORTCARD; l : PInputLine );

   VIRTUAL PROCEDURE Done;
END TMyHistoryWindow;

CLASS IMPLEMENTATION MyHistory;

   PROCEDURE Set_Hist_Id( id : SHORTCARD );
   BEGIN
     hist_id_w := id;
   END Set_Hist_Id;

   VIRTUAL PROCEDURE InitHistoryWindow( VAR R : TRect ) : PHistoryWindow;
   VAR
     phw : PMyHistoryWindow;
   BEGIN
     NEW(phw);
     phw^.Init ( R, HistoryId );
     phw^.HelpCtx := Link^.HelpCtx;
     phw^.Set_Hist_Id( hist_id_w, Link );
     DisposeStr( phw^.Title );
     phw^.Title := NewStr( "Lista znanych miejsc" );
     RETURN phw;
   END InitHistoryWindow;

BEGIN
  hist_id_w := 255;
END MyHistory;

CLASS IMPLEMENTATION TMyHistoryWindow;

   PROCEDURE Set_Hist_Id( id : SHORTCARD; l : PInputLine );
   BEGIN
     hist_id_w := id;
     Link := l;
   END Set_Hist_Id;

  VIRTUAL PROCEDURE Done;
  VAR
    s : ARRAY [0..255] OF CHAR;
  BEGIN
    Copy( s, Link^.Data^ );
    Notify[hist_id_w]( s );
    THistoryWindow.Done;
  END Done;

BEGIN
  hist_id_w := 255;
END TMyHistoryWindow;

CLASS FreqHistory( THistory );
   VIRTUAL PROCEDURE InitHistoryWindow( VAR R : TRect ) : PHistoryWindow;
END FreqHistory;

CLASS IMPLEMENTATION FreqHistory;

   VIRTUAL PROCEDURE InitHistoryWindow( VAR R : TRect ) : PHistoryWindow;
   VAR
     phw : PHistoryWindow;
   BEGIN
     NEW(phw);
     phw^.Init ( R, HistoryId );
     phw^.HelpCtx := Link^.HelpCtx;
(*     phw^.Set_Hist_Id( LOT_FREQ_ID );*)
     DisposeStr( phw^.Title );
     phw^.Title := NewStr( "Lista kana’¢w" );
     RETURN phw;
   END InitHistoryWindow;

BEGIN
END FreqHistory;



CLASS IMPLEMENTATION MyInputLine;

   PROCEDURE Set_Hist_Id( id : SHORTCARD );
   BEGIN
     hist_id_w := id;
   END Set_Hist_Id;

   VIRTUAL PROCEDURE SetState( AState : TViewStates; Enable : BOOLEAN );
   VAR
     os : TViewStates;
     s : ARRAY[0..InpWlk-1] OF CHAR;
   BEGIN
     os := State;
     TInputLine.SetState( AState, Enable );
     IF (sfFocused IN os) & NOT(sfFocused IN State) THEN
       GetData( s );
       Notify[hist_id_w]( s );
     END
   END SetState;

BEGIN
  hist_id_w := 255;
END MyInputLine;

CLASS IMPLEMENTATION FreqInputLine;

   VIRTUAL PROCEDURE HandleEvent( VAR e : TEvent );
   BEGIN
(*
     IF evMessage * e.What = EventTypes{} THEN
       ClearEvent( e );
     END;
*)
     TInputLine.HandleEvent( e );
   END HandleEvent;

   VIRTUAL PROCEDURE GetPalette(): PPalette;
   BEGIN
     RETURN ADR(4C+    23C+23C+24C+25C);
   END GetPalette;

BEGIN
END FreqInputLine;



PROCEDURE DefineHistorySubView(     p       : PGroup;
                                    prompt  : ARRAY OF CHAR;
                                    hist_id : SHORTCARD;
                                VAR tytul   : PInputLine );
VAR
  R : TRect;
  h : PHist;
  n : PInp;
  l : PLabel;
BEGIN
  WITH p^ DO

    R.Assign( 2, 2, 30, 3 );
    NEW( n );
    n^.Init( R, InpWlk );
    Insert( n );
    n^.Set_Hist_Id( hist_id );

    R.Assign( 31, 2, 33, 3 );
    NEW( h );
    h^.Init( R, n, ORD(hist_id) );
    h^.Set_Hist_Id( hist_id );
    Insert( h );

    R.Assign( 2, 1, 33, 2 );
    NEW( l );
    l^.Init( R, prompt, n );
    Insert( l );

  END;
  tytul := n;
END DefineHistorySubView;

PROCEDURE DefineFreqListSubView( p : PGroup; hist_id : SHORTCARD; VAR cz: PInputLine );
VAR
  R : TRect;
  h : PFHist;
(*  n : PFInp;*)
  n : PInputLine;
  l : PLabel;
BEGIN
  WITH p^ DO

    R.Assign( 16, 3, 30, 4 );
    NEW( n );
    n^.Init( R, 15 );
    Insert( n );

    R.Assign( 31, 3, 33, 4);
    NEW( h );
    h^.Init( R, n, ORD(hist_id) );
    Insert( h );

    R.Assign( 2, 3, 15, 4 );
    NEW( l );
    l^.Init( R, "Cz©st(ch)M~H~z]", h );
    Insert( l );

  END;
  cz := n;
END DefineFreqListSubView;

PROCEDURE Dummy( VAR a : ARRAY OF CHAR );
END Dummy;

VAR
  oldValidate : ValidateProc;

PROCEDURE Validate( id : SHORTCARD; VAR str : ARRAY OF CHAR ) : BOOLEAN;
VAR
  i : CARDINAL;
BEGIN
  IF (id = VOR_HIST_ID) OR
     (id = LOT_HIST_ID) OR
     (id = GS_FREQ_ID) OR
     (id = VHF_HIST_ID) OR
     (id = NDB_HIST_ID) OR
     (id = LOT_FREQ_ID) THEN
    IF str[0] = 0C THEN
      RETURN FALSE;
    END;
    UtnijSpacje( str );
    FOR i := 1 TO HistoryCount(id) DO
      IF Compare( HistoryStr( id, i-1 )^, str ) = 0 THEN
        RETURN FALSE;
      END;
    END;
    RETURN TRUE;
  ELSE
    RETURN oldValidate( id, str );
  END;
END Validate;

PROCEDURE SetNotification( hist_id : SHORTCARD; np : NotificationProc );
BEGIN
  Notify[ hist_id ] := np;
END SetNotification;

PROCEDURE InitFreqList;
VAR
  i : CARDINAL;
  s : ARRAY [0..10] OF CHAR;
BEGIN
  FOR i := 0 TO HIGH( LOCfreqCRT ) DO
    sprintf( s, "(%02d)%5.2lf", i, LONGREAL(LOCfreqCRT[i])/100.0 );
    HistoryAdd( LOT_FREQ_ID, s );
  END;
(*
  FOR i := 0 TO HIGH( GSfreqCRT ) DO
    sprintf( s, "(%02d)%5.2lf", i, LONGREAL(GSfreqCRT[i])/100.0 );
    HistoryAdd( GS_FREQ_ID, s );
  END;
*)
END InitFreqList;

PROCEDURE InitNotifications;
VAR
  i : SHORTCARD;
BEGIN
  FOR i := 0 TO HIGH( Notify ) DO
    SetNotification( i, Dummy );
  END;
END InitNotifications;

BEGIN
  HistorySize := (*0FFF0H*)4000H;
  InitFreqList;
  InitNotifications;
  SetValidateProc( Validate, oldValidate );
END Hist.
