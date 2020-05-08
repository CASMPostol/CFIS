(*%T TV_NoDebug*)
(*# debug(vid=>off)*)
(*%E*)
(*%T InOneSegment *)
(*#call(seg_name=>TV)*)
(*%E*)
IMPLEMENTATION MODULE CheckBoxes;

FROM Texts IMPORT
  CheckBoxesButton;

  CLASS IMPLEMENTATION TCheckBoxes;

    VIRTUAL PROCEDURE Draw;
    BEGIN
      DrawBox( CheckBoxesButton, 'X' );
    END Draw;

    VIRTUAL PROCEDURE Mark(Item: INTEGER): BOOLEAN;
    BEGIN
      RETURN VAL(CARDINAL, Item) IN Value;
    END Mark;

    VIRTUAL PROCEDURE Press(Item: INTEGER);
    BEGIN
      Value := Value / { VAL(CARDINAL, Item) };
    END Press;

  BEGIN
  END TCheckBoxes;


END CheckBoxes.