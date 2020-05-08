(*%T TV_NoDebug*)
(*# debug(vid=>off)*)
(*%E*)
(*%T InOneSegment *)
(*#call(seg_name=>TV)*)
(*%E*)
(*#call(o_a_copy=>off)*)
IMPLEMENTATION MODULE MsgBox;

FROM Objects IMPORT
  TRect, PString, String;
FROM App IMPORT
  Desktop;
FROM Dialogs IMPORT
  PDialog;
FROM StaticTexts IMPORT
   PStaticText;
FROM Buttons IMPORT
  PButton, ButtonFlag, ButtonFlags, bfNormal;
FROM InputLines IMPORT
  PInputLine;
FROM Labels IMPORT
  PLabel;
FROM Texts IMPORT
  WarningText, ErrorText, InformationText, ConfirmText, YesText, NoText,
  OkText, CancelText;
FROM Storage IMPORT
  ALLOCATE, DEALLOCATE;
FROM stdio IMPORT
  sprintf;
FROM Commands IMPORT
  cmOK, cmCancel, cmYes, cmNo;
FROM Views IMPORT
  PView;
FROM Drivers IMPORT
  CStrLen;

PROCEDURE MessageBox( (*VAR*) Msg: ARRAY OF CHAR;
                          Params: ADDRESS;
                          AOptions: MsgOptions) : CARDINAL;
VAR
  R: TRect;
BEGIN
  R.Assign(0, 0, 40, 9);
  R.Move((Desktop^.Size.X - R.B.X) DIV 2, (Desktop^.Size.Y - R.B.Y) DIV 2);
  RETURN MessageBoxRect(R, Msg, Params, AOptions);
END MessageBox;

PROCEDURE MessageBoxRect(VAR R: Objects.TRect;
                             Msg: ARRAY OF CHAR;
                             Params: ADDRESS;
                             AOptions: MsgOptions): CARDINAL;
TYPE
  BN = ARRAY [mfYesButton..mfCancelButton] OF PString;
  CS = ARRAY [mfYesButton..mfCancelButton] OF CARDINAL;
CONST
  ButtonName = BN( ADR(YesText), ADR(NoText), ADR(OkText), ADR(CancelText));
  Commands   = CS( cmYes, cmNo, cmOK, cmCancel );
VAR
  i, x, ButtonCount: INTEGER;
  Dialog: PDialog;
  StText: PStaticText;
  Button : PButton;
  str : String;
  T: TRect;
  ButtonList: ARRAY [0..3] OF PButton;
  S: PString;
  o : MsgOption;
  Ret : CARDINAL;
BEGIN
  IF mfWarning IN AOptions THEN
    S := ADR( WarningText );
  ELSIF mfError IN AOptions THEN
    S := ADR( ErrorText );
  ELSIF mfInformation IN AOptions THEN
    S := ADR( InformationText );
  ELSIF mfConfirmation IN AOptions THEN
    S := ADR( ConfirmText );
  ELSE
    S := ADR(0C+0C);
  END;
  NEW( Dialog );
  WITH Dialog^ DO
    Dialog^.Init( R, S^ );
    R.Assign(3, 2, Size.X - 2, Size.Y - 3);
(*#save, check(nil_ptr=>off)*)
    sprintf(str, Msg, Params^);
(*#restore*)
    NEW( StText );
    StText^.Init(R, str);
    Insert( StText );
    x := -2;
    ButtonCount := 0;
    FOR o := mfYesButton TO mfCancelButton DO
      IF o IN AOptions THEN
        R.Assign(0, 0, 10, 2);
        NEW( Button );
        Button^.Init(R, ButtonName[o]^, Commands[o], ButtonFlags{bfNormal});
        INC(x, Button^.Size.X + 2);
        ButtonList[ButtonCount] := Button;
        INC( ButtonCount );
      END;
    END;
    x := (Size.X - x) >> 1;
    FOR i := 0 TO ButtonCount - 1 DO
      Button := ButtonList[i];
      Insert( Button );
      Button^.MoveTo(x, Size.Y - 3);
      INC(x, Button^.Size.X + 2);
    END;
    SelectNext( FALSE );
  END;
  Ret := Desktop^.ExecView(Dialog);
  Dialog^.Done;
  DISPOSE( Dialog );
  RETURN Ret;
END MessageBoxRect;

PROCEDURE InputBox( VAR Title: ARRAY OF CHAR;
                    VAR ALabel: ARRAY OF CHAR;
                    VAR S: ARRAY OF CHAR;
                        Limit: SHORTCARD): CARDINAL;

VAR
  R: TRect;
BEGIN
  R.Assign(0, 0, 60, 8);
  R.Move((Desktop^.Size.X - R.B.X) DIV 2, (Desktop^.Size.Y - R.B.Y) DIV 2);
  RETURN InputBoxRect(R, Title, ALabel, S, Limit);
END InputBox;

PROCEDURE InputBoxRect( VAR Bounds: Objects.TRect;
                        VAR Title: ARRAY OF CHAR;
                        VAR ALabel: ARRAY OF CHAR;
                        VAR S: ARRAY OF CHAR;
                            Limit: SHORTCARD): CARDINAL;
VAR
  Dialog: PDialog;
  InputLine : PInputLine;
  Label : PLabel;
  Button : PButton;
  R: TRect;
  C: CARDINAL;
BEGIN
  NEW(Dialog);
  WITH Dialog^ DO
    Init( Bounds, PString(ADR(Title))^);
    R.Assign(4 + CStrLen( ALabel ), 2, Size.X - 3, 3);
    NEW( InputLine );
    InputLine^.Init( R, ORD(Limit) );
    Insert( InputLine );
    R.Assign(2, 2, 3 + CStrLen(ALabel), 3);
    NEW( Label );
    Label^.Init(R, ALabel, InputLine);
    Insert( Label );
    R.Assign(Size.X - 24, Size.Y - 4, Size.X - 14, Size.Y - 2);
    NEW( Button );
    Button^.Init( R, OkText, cmOK, ButtonFlags{bfDefault} );
    Insert( Button );
    INC(R.A.X, 12);
    INC(R.B.X, 12);
    NEW( Button );
    Button^.Init( R, CancelText, cmCancel, ButtonFlags{bfNormal} );
    Insert( Button );
    SelectNext( FALSE );
    SetData( S );
  END;
  C := Desktop^.ExecView( Dialog );
  IF C <> cmCancel THEN
    Dialog^.GetData( S );
  END;
  Dialog^.Done;
  DISPOSE( Dialog );
  RETURN C;
END InputBoxRect;

END MsgBox.
