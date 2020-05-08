(*%T TV_NoDebug*)
(*# debug(vid=>off)*)
(*%E*)
(*%T InOneSegment *)
(*#call(seg_name=>TV)*)
(*%E*)
IMPLEMENTATION MODULE Dlg;

FROM CheckBoxes IMPORT
  PCheckBoxes;
FROM RadioButtons IMPORT
  PRadioButtons;
FROM Clusters IMPORT
  NewSItem;
FROM Labels IMPORT
  PLabel;
FROM Buttons IMPORT
  PButton, ButtonFlag, ButtonFlags;
FROM InputLines IMPORT
  PInputLine;
(*
FROM Editors IMPORT
  TEditor;
*)
FROM History IMPORT
  THistoryViewer;
(*
FROM StdDlg IMPORT
  TFileDialog;
*)
FROM Views IMPORT
  PView;
FROM Objects IMPORT
  TRect;
FROM Storage IMPORT
  ALLOCATE, DEALLOCATE;
FROM Commands IMPORT
  cmOK, cmCancel;

  PROCEDURE MakeDialog( VAR Data : ARRAY OF BYTE ):PDialog;
  VAR
    CheckBox: PCheckBoxes;
    Button : PButton;
    RadioButton : PRadioButtons;
    InputLine : PInputLine;
    Label : PLabel;
    Dialog: PDialog;
    R: TRect;
    C: CARDINAL;
  BEGIN
    R.Assign(20, 6, 60, 19);
    NEW( Dialog );
    WITH Dialog^ DO
      Init(R, 'Demo Dialog');
      R.Assign(3, 3, 18, 6);
      NEW( CheckBox );
      CheckBox^.Init(R,
                     NewSItem('~H~varti',
                     NewSItem('~T~ilset',
                     NewSItem('~J~arlsberg',
                     NIL)))
                    );
      Insert(CheckBox);
      R.Assign(2, 2, 10, 3);

      NEW( Label );
      Label^.Init( R, 'Cheeses', CheckBox );
      Insert( Label );
      R.Assign(22, 3, 34, 6);

      NEW( RadioButton );
      RadioButton^.Init(R,
                        NewSItem('~S~olid',
                        NewSItem('~R~unny',
                        NewSItem('~M~elted',
                        NIL)))
                       );
      Insert(RadioButton);

      R.Assign(21, 2, 33, 3);
      NEW( Label );
      Label^.Init(R, 'Consistency', RadioButton);
      Insert( Label );

      R.Assign(3, 8, 37, 9);
      NEW( InputLine );
      InputLine^.Init(R, 128);
      Insert(InputLine);

      R.Assign(2, 7, 24, 8);
      NEW( Label );
      Label^.Init(R, 'Delivery instructions', InputLine);
      Insert( Label );

      R.Assign(15, 10, 25, 12);
      NEW( Button );
      Button^.Init(R, '~O~k', cmOK, ButtonFlags{ bfDefault });
      Insert( Button );

      R.Assign(28, 10, 38, 12);
      NEW( Button );
      Button^.Init(R, 'Cancel', cmCancel, ButtonFlags{ bfNormal });
      Insert( Button );

      SetData(Data);
    END;
    RETURN Dialog;
  END MakeDialog;

END Dlg.