(*%T TV_NoDebug*)
(*# debug(vid=>off)*)
(*%E*)
(*%T InOneSegment *)
(*#call(seg_name=>TV)*)
(*%E*)
IMPLEMENTATION MODULE RadioButtons;

FROM Texts IMPORT
  RadioButton;

  CLASS IMPLEMENTATION TRadioButtons;

    VIRTUAL PROCEDURE Draw;
    BEGIN
      DrawBox( RadioButton, 7C );
    END Draw;

    VIRTUAL PROCEDURE Mark(Item: INTEGER): BOOLEAN;
    BEGIN
      RETURN VAL(CARDINAL, Item) IN Value;
    END Mark;

    VIRTUAL PROCEDURE MovedTo(Item: INTEGER);
    BEGIN
      Value := BITSET{VAL(CARDINAL, Item )};
    END MovedTo;

    VIRTUAL PROCEDURE Press(Item: INTEGER);
    BEGIN
      Value := BITSET{VAL(CARDINAL, Item )};
    END Press;

    VIRTUAL PROCEDURE SetData(VAR Rec : ARRAY OF BYTE);
    BEGIN
      TCluster.SetData(Rec);
      Sel := INTEGER(Value);
    END SetData;

  BEGIN
  END TRadioButtons;


END RadioButtons.