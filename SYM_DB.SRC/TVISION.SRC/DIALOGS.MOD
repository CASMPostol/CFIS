(*%T TV_NoDebug*)
(*# debug(vid=>off)*)
(*%E*)
(*%T InOneSegment *)
(*#call(seg_name=>TV)*)
(*%E*)
IMPLEMENTATION MODULE Dialogs;

FROM Views IMPORT
  PView, TView, TViewGrowModes, TViewGrowMode, PPalette, TViewState,
  TViewStates;
FROM Objects IMPORT
  TRect, String, PString;
FROM Streams IMPORT
  TStream;
FROM Winds IMPORT
  wnNoNumber, WindowFlags, WindowFlag;
FROM Texts IMPORT
  CDialog;
FROM Drivers IMPORT
  TEvent, EventType, EventTypes, kbEsc, kbEnter;
FROM Commands IMPORT
  cmCancel, cmOK, cmDefault, cmYes, cmNo;



  CLASS IMPLEMENTATION TDialog ;

    PROCEDURE Init(VAR Bounds: TRect;
                       ATitle: ARRAY OF CHAR);
    BEGIN
      TWindow.Init( Bounds, ATitle, wnNoNumber );
      GrowMode := TViewGrowModes{};
      Flags := WindowFlags { wfMove, wfClose };
    END Init;

    VIRTUAL PROCEDURE GetPalette(): PPalette;
    BEGIN
      RETURN ADR(CDialog);
    END GetPalette;

    VIRTUAL PROCEDURE HandleEvent(VAR Event: TEvent);
    BEGIN
      TWindow.HandleEvent(Event);
      IF evKeyDown IN Event.What THEN
        CASE Event.KeyCode OF
        | kbEsc:
            Event.What := EventTypes { evCommand };
            Event.Command := cmCancel;
            Event.InfoPtr := NIL;
            PutEvent(Event);
            ClearEvent(Event);
        | kbEnter:
            Event.What := EventTypes { evBroadcast };
            Event.Command := cmDefault;
            Event.InfoPtr := NIL;
            PutEvent(Event);
            ClearEvent(Event);
        END;
      END;
      IF evCommand IN Event.What THEN
        CASE Event.Command OF
        | cmOK, cmCancel, cmYes, cmNo:
            IF sfModal IN State THEN
              EndModal(Event.Command);
              ClearEvent(Event);
            END;
        END;
      END;
    END HandleEvent;

    VIRTUAL PROCEDURE Valid(Command: CARDINAL): BOOLEAN;
    BEGIN
      IF Command = cmCancel THEN
        RETURN TRUE;
      ELSE
        RETURN TGroup.Valid( Command );
      END;
    END Valid;

  BEGIN
  END TDialog;

END Dialogs.